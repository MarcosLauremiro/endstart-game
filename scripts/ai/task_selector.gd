class_name TaskSelector
extends RefCounted
## Escolhe a tarefa do quadro para um colono, como no GDD:
## 1) prioridade 1 → 4; 2) ordem das colunas; 3) dentro do tipo, a maior pontuação
##    pontuação = urgência × habilidade × afinidade × traços ÷ (1 + distância ÷ 30).
## Tarefa que o colono não pode fazer nem entra na conta; o motivo vai para o registro.
## Só avalia: reservar é trabalho do ActionRunner.

## O que o colono faria na tarefa: trabalhar no local, carregar uma pilha ou levar material para a obra.
enum Mode { WORK, HAUL, DELIVER }

const _OPTIONS_SHOWN := 5
const _REJECTIONS_PER_TYPE := 4
## Afinidade e traços que mudam a pontuação chegam no M5 (afinidades, Curioso etc.).
const _AFFINITY_NEUTRAL := 1.0
const _TRAITS_NEUTRAL := 1.0


## Pontuação do GDD. A habilidade vale 0,5 + nível ÷ 20.
static func score(urgency: int, skill_level: int, path_cost: float) -> float:
	var skill := 0.5 + skill_level / 20.0
	return urgency * skill * _AFFINITY_NEUTRAL * _TRAITS_NEUTRAL / (1.0 + path_cost / Balance.TASK_DISTANCE_DIVISOR)


func choose(colonist: Colonist, state: WorldState, record: DecisionRecord) -> Action:
	var options: Array[Dictionary] = []
	var chosen: Action
	for priority in range(1, Balance.MAX_WORK_PRIORITY + 1):
		for work_type in WorkType.COLUMNS:
			if colonist.priority_of(work_type) != priority:
				continue
			var tasks := state.task_board.tasks_of(work_type)
			if tasks.is_empty():
				continue
			chosen = _best_of_type(colonist, state, tasks, record, options)
			if chosen:
				chosen.reason = "Prioridade %d em %s (primeira coluna com tarefa possível); %s" % [
					priority, WorkType.name_of(work_type), chosen.reason]
				break
		if chosen:
			break
	for work_type in WorkType.COLUMNS:
		if colonist.priority_of(work_type) == 0 and not state.task_board.tasks_of(work_type).is_empty():
			record.rejected.append("%s: prioridade desligada" % WorkType.name_of(work_type))
	options.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a["score"] > b["score"])
	colonist.last_options.clear()
	for option in options.slice(0, _OPTIONS_SHOWN):
		colonist.last_options.append("%s — %.2f" % [option["label"], option["score"]])
	return chosen


## Verifica se o colono pode fazer a tarefa agora. Devolve {ok, reason} e, se ok, {mode, key, path, cost, score, ...}.
## record_block = false só consulta, sem marcar a tarefa como bloqueada (usado pela interface).
func evaluate(colonist: Colonist, task: Task, state: WorldState, record_block: bool = true) -> Dictionary:
	if not TaskEffects.is_still_valid(task, state):
		return _no("o alvo não existe mais")
	var mode := _mode_of(task, state)
	var key := _free_key(colonist, task, mode, state)
	if key.has("reason"):
		return _no(key["reason"])
	var tick := state.clock.tick
	if task.is_blocked(tick):
		return _no("bloqueada: %s" % task.block_reason)
	var result := {"ok": true, "mode": mode, "key": key["key"]}
	var path: Array[Vector2i] = []
	match mode:
		Mode.HAUL:
			var stack: ItemStack = state.stacks[task.target_id]
			if stack.available() <= 0:
				return _no("itens já reservados por outro")
			var destination := state.find_storage_for(stack.item, stack.cell)
			if destination == null:
				if record_block:
					task.block(tick, "sem espaço nos contêineres")
				return _no("sem espaço nos contêineres")
			result["destination"] = destination
			path = state.navigation.find_path(colonist.cell, stack.cell)
		Mode.DELIVER:
			var needs: Array[Dictionary] = []
			var receiver: Object = state.delivery_receiver(task.target_id)
			if task.kind == Task.Kind.CRAFT:
				var choice: Dictionary = receiver.next_bill(state)
				if not choice.has("bill"):
					return _no(choice["reason"])
				result["bill"] = choice["bill"]
				needs = receiver.needs(choice["bill"])
			else:
				needs = receiver.needs()
			if needs.is_empty():
				var names: Array = receiver.incoming_owners().map(func(id: int) -> String: return state.colonist_name(id))
				return _no("materiais a caminho com %s" % ", ".join(names))
			var pick := _nearest_material(needs, colonist, state)
			if pick.is_empty():
				var need: Dictionary = needs[0]
				var why := "faltam materiais: %d %s" % [need["count"], _need_name(need)]
				# Bancadas não ficam bloqueadas: a falta de ingrediente é conferida a cada pensamento.
				if record_block and task.kind == Task.Kind.CONSTRUCT:
					task.block(tick, why)
				return _no(why)
			var source: Dictionary = pick["source"]
			var item: StringName = pick["item"]
			result["source"] = source
			result["item"] = item
			result["count"] = mini(pick["count"], colonist.carry_units(item))
			if source["adjacent"]:
				path = state.navigation.path_to_adjacent(colonist.cell, source["cell"])
			else:
				path = state.navigation.find_path(colonist.cell, source["cell"])
		Mode.WORK:
			if task.kind == Task.Kind.HARVEST:
				var bush_owner := state.reservations.owner_of(Reservations.bush_key(task.target_id))
				if bush_owner != 0 and bush_owner != colonist.id:
					return _no("%s está comendo no arbusto" % state.colonist_name(bush_owner))
			if task.kind == Task.Kind.CONSTRUCT and Construction.tree_in_the_way(state, state.sites[task.target_id]):
				return _no("árvore no local: aguardando o corte")
			if task.kind == Task.Kind.CRAFT and state.workbenches[task.target_id].job.paused:
				return _no("o pedido em andamento está pausado")
			if _stands_on_target(task):
				path = state.navigation.find_path(colonist.cell, task.cell)
			else:
				path = state.navigation.path_to_adjacent(colonist.cell, task.cell)
	result["pathed"] = true
	if path.is_empty():
		if record_block:
			task.block(tick, "sem caminho")
		return {"ok": false, "reason": "sem caminho", "pathed": true}
	var cost := state.navigation.path_cost(path)
	result["path"] = path
	result["cost"] = cost
	result["score"] = score(task.urgency, colonist.skill_level(task.work_type), cost)
	return result


## Por que o colono faria ou não esta tarefa agora (GDD: "por que ele não está fazendo isso?").
## Usa as mesmas regras da escolha real e não altera nada.
func explain(colonist: Colonist, task: Task, state: WorldState) -> String:
	if colonist.action and colonist.action.task_id == task.id:
		return "está fazendo"
	var priority := colonist.priority_of(task.work_type)
	if priority == 0:
		return "prioridade de %s desligada" % WorkType.name_of(task.work_type)
	var evaluation := evaluate(colonist, task, state, false)
	if not evaluation["ok"]:
		return evaluation["reason"]
	var doing := "levaria ingrediente ou material" if evaluation["mode"] == Mode.DELIVER else "pode fazer"
	return "%s (prioridade %d, pontuação %.2f)" % [doing, priority, evaluation["score"]]


## Monta a ação a partir de uma avaliação ok.
func make_action(colonist: Colonist, task: Task, evaluation: Dictionary, layer: Action.Layer, state: WorldState) -> Action:
	var action: Action
	match evaluation["mode"]:
		Mode.HAUL:
			var stack: ItemStack = state.stacks[task.target_id]
			var destination: StorageContainer = evaluation["destination"]
			action = Action.make(Action.Kind.HAUL, layer, stack.cell, "")
			action.target_id = stack.id
			action.item_id = stack.item
			action.destination_id = destination.id
			action.title = "Carregar %s para o %s #%d" % [Defs.item(stack.item).display_name, destination.def.display_name, destination.id]
		Mode.DELIVER:
			var source: Dictionary = evaluation["source"]
			action = Action.make(Action.Kind.DELIVER, layer, source["cell"], "")
			action.adjacent = source["adjacent"]
			action.item_source = source["source"]
			action.target_id = source["id"]
			action.item_id = evaluation["item"]
			action.count = evaluation["count"]
			action.destination_id = task.target_id
			action.bill = evaluation.get("bill")
			var goal := task.label() if action.bill == null else "%s (%s)" % [task.label(), action.bill.recipe.display_name]
			action.title = "Levar %s para %s" % [Defs.item(action.item_id).display_name.to_lower(), goal]
		_:
			var kind := Action.Kind.HUNT if task.kind == Task.Kind.HUNT else Action.Kind.WORK
			action = Action.make(kind, layer, task.cell, "")
			action.adjacent = not _stands_on_target(task)
			action.target_id = task.target_id
			action.title = task.label()
			if task.kind == Task.Kind.CRAFT:
				action.title = "%s: %s" % [task.label(), state.workbenches[task.target_id].job.recipe.display_name]
	action.task_id = task.id
	action.reservation_key = evaluation["key"]
	action.path = evaluation["path"]
	action.reason = "pontuação %.2f = urgência %d × habilidade %.2f × afinidade %.1f × traços %.1f ÷ (1 + %.0f ÷ %.0f)" % [
		evaluation["score"], task.urgency, 0.5 + colonist.skill_level(task.work_type) / 20.0,
		_AFFINITY_NEUTRAL, _TRAITS_NEUTRAL, evaluation["cost"], Balance.TASK_DISTANCE_DIVISOR]
	return action


func _mode_of(task: Task, state: WorldState) -> Mode:
	match task.kind:
		Task.Kind.HAUL:
			return Mode.HAUL
		Task.Kind.CONSTRUCT:
			if not state.sites[task.target_id].has_all_materials():
				return Mode.DELIVER
		Task.Kind.CRAFT:
			if not state.workbenches[task.target_id].has_all_ingredients():
				return Mode.DELIVER
	return Mode.WORK


## Semear, colher plantação e caçar acontecem no próprio tile (a caça segue o animal);
## o resto, de um tile vizinho.
static func _stands_on_target(task: Task) -> bool:
	return task.kind == Task.Kind.SOW or task.kind == Task.Kind.REAP or task.kind == Task.Kind.HUNT


## A origem mais perto (em linha reta) de algum material que falta: {source, item, count} ou vazio.
func _nearest_material(needs: Array[Dictionary], colonist: Colonist, state: WorldState) -> Dictionary:
	var best: Dictionary = {}
	var best_distance := INF
	for need in needs:
		for item in need["items"]:
			var source := state.find_item_source(item, colonist.cell)
			if source.is_empty():
				continue
			var distance := float(source["cell"].distance_squared_to(colonist.cell))
			if distance < best_distance:
				best_distance = distance
				best = {"source": source, "item": item, "count": need["count"]}
	return best


static func _need_name(need: Dictionary) -> String:
	var items: Array = need["items"]
	if items.size() == 1:
		return Defs.item(items[0]).display_name.to_lower()
	return "porções (%s)" % ", ".join(items.map(func(item: StringName) -> String: return Defs.item(item).display_name.to_lower()))


## A reserva que o colono usaria: a entrega da obra, ou uma vaga livre da equipe.
## Devolve {key} ou {reason} quando não há vaga.
func _free_key(colonist: Colonist, task: Task, mode: Mode, state: WorldState) -> Dictionary:
	if mode == Mode.DELIVER:
		var owner := state.reservations.owner_of(task.delivery_key())
		if owner != 0 and owner != colonist.id:
			return {"reason": "material sendo trazido por %s" % state.colonist_name(owner)}
		return {"key": task.delivery_key()}
	var free_key := ""
	var holders := PackedStringArray()
	for slot in task.max_workers:
		var key := task.slot_key(slot)
		var owner := state.reservations.owner_of(key)
		if owner == colonist.id:
			return {"key": key}
		if owner == 0:
			if free_key.is_empty():
				free_key = key
		else:
			holders.append(state.colonist_name(owner))
	if not free_key.is_empty():
		return {"key": free_key}
	if task.max_workers == 1:
		return {"reason": "reservada por %s" % holders[0]}
	return {"reason": "equipe cheia (%s)" % ", ".join(holders)}


func _no(reason: String) -> Dictionary:
	return {"ok": false, "reason": reason}


func _best_of_type(colonist: Colonist, state: WorldState, tasks: Array, record: DecisionRecord, options: Array[Dictionary]) -> Action:
	var sorted := tasks.duplicate()
	sorted.sort_custom(func(a: Task, b: Task) -> bool:
		return a.cell.distance_squared_to(colonist.cell) < b.cell.distance_squared_to(colonist.cell))
	var best_task: Task
	var best: Dictionary = {}
	var paths_left := Balance.TASK_PATHS_EVALUATED
	var rejections := 0
	for task in sorted.slice(0, Balance.TASK_SCAN_LIMIT):
		if paths_left <= 0:
			break
		var evaluation := evaluate(colonist, task, state)
		if evaluation.get("pathed", false):
			paths_left -= 1
		if not evaluation["ok"]:
			if rejections < _REJECTIONS_PER_TYPE:
				record.rejected.append("%s: %s" % [task.label(), evaluation["reason"]])
			rejections += 1
			continue
		options.append({"label": task.label(), "score": evaluation["score"]})
		if best_task == null or evaluation["score"] > best["score"]:
			best_task = task
			best = evaluation
	if best_task == null:
		return null
	return make_action(colonist, best_task, best, Action.Layer.WORK, state)
