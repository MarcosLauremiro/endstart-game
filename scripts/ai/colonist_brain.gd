class_name ColonistBrain
extends RefCounted
## Escolhe a próxima ação seguindo as camadas do GDD, em ordem:
## 1 reações, 2 necessidades críticas, 3 ordens diretas, 4 agenda, 5 trabalho, 6 tempo livre.
## Só avalia camadas mais altas que a da ação atual: quem está trabalhando não reavalia o quadro
## de tarefas a cada meio segundo, só verifica se algo mais urgente apareceu.
## Não reserva nem move nada. Cada motivo escrito no registro é o motivo real usado.

## Camada fictícia abaixo de todas: "nada em andamento".
const _NO_LAYER := Action.Layer.FREE_TIME + 1

var selector := TaskSelector.new()


## Devolve a ação candidata, ou null se nada supera a atual.
func decide(colonist: Colonist, state: WorldState, record: DecisionRecord) -> Action:
	var limit := _layer_limit(colonist)
	var needs := colonist.needs

	# 1. Reações urgentes
	if needs.rest <= 0.0 and limit > Action.Layer.REACTION:
		return Action.make(Action.Kind.SLEEP, Action.Layer.REACTION, colonist.cell,
			"Desmaiou de exaustão: sono chegou a 0%")

	# 2. Necessidades críticas
	if limit <= Action.Layer.CRITICAL_NEED:
		return null
	if needs.food < Balance.FOOD_CRITICAL_THRESHOLD:
		var why := "Fome em %d%%, abaixo de %d%%: crítica, interrompe outras atividades" % [
			needs.food, Balance.FOOD_CRITICAL_THRESHOLD]
		var eat := _find_food(colonist, state, record, Action.Layer.CRITICAL_NEED, why)
		if eat:
			return eat
	if needs.rest < Balance.REST_CRITICAL_THRESHOLD:
		return _sleep(colonist, state, record, Action.Layer.CRITICAL_NEED,
			"Sono em %d%%, abaixo de %d%%: crítico" % [needs.rest, Balance.REST_CRITICAL_THRESHOLD])

	# 3. Ordens diretas do jogador
	if limit <= Action.Layer.ORDER:
		return null
	if colonist.direct_order:
		return colonist.direct_order

	# 4. Agenda (GDD: Dormir, Trabalhar, Livre)
	if limit <= Action.Layer.SCHEDULE:
		return null
	var block := colonist.block_at(state.clock.tick)
	var hour := (state.clock.tick / Balance.TICKS_PER_HOUR) % Balance.HOURS_PER_DAY
	var working_now := colonist.action != null and colonist.action.layer == Action.Layer.WORK
	if block != Schedule.Block.WORK and working_now:
		if colonist.has_trait(Traits.HARDWORKING):
			# Esforçado termina a tarefa mesmo fora do bloco de Trabalho.
			return null
		var stop := Action.make(Action.Kind.IDLE, Action.Layer.SCHEDULE, colonist.cell,
			"Agenda: às %02d:00 começa o bloco %s; para de trabalhar" % [hour, Schedule.name_of(block)])
		stop.title = "Fim do trabalho"
		return stop
	if block == Schedule.Block.SLEEP and needs.rest < Balance.SCHEDULE_SLEEP_BELOW:
		return _sleep(colonist, state, record, Action.Layer.SCHEDULE,
			"Agenda: bloco Dormir (%02d:00) e sono em %d%%" % [hour, needs.rest])

	# 5. Trabalho (só no bloco Trabalhar)
	if limit <= Action.Layer.WORK:
		return null
	if block != Schedule.Block.WORK:
		record.rejected.append("Trabalho: fora do bloco Trabalhar (agora é %s)" % Schedule.name_of(block))
		return _free_time(colonist, state, record)
	if colonist.has_trait(Traits.LAZY) and colonist.work_ticks_since_break >= Balance.LAZY_BREAK_EVERY_TICKS:
		var pause := Action.make(Action.Kind.BREAK, Action.Layer.WORK, colonist.cell,
			"Preguiçoso: pausa de 15 min a cada 2 h de trabalho")
		pause.title = "Pausa (preguiçoso)"
		return pause
	var work := selector.choose(colonist, state, record)
	if work:
		var tool := _better_tool(colonist, work, state, record)
		return tool if tool else work
	return _free_time(colonist, state, record)


## 6. Tempo livre: comer ou dormir abaixo dos limites do GDD; senão vagar ou ficar à toa.
func _free_time(colonist: Colonist, state: WorldState, record: DecisionRecord) -> Action:
	var needs := colonist.needs
	if needs.food < Balance.FOOD_FREE_TIME_THRESHOLD:
		var why := "Sem tarefa e com fome em %d%%, abaixo de %d%%: come no tempo livre" % [
			needs.food, Balance.FOOD_FREE_TIME_THRESHOLD]
		var eat := _find_food(colonist, state, record, Action.Layer.FREE_TIME, why)
		if eat:
			return eat
	if needs.rest < Balance.REST_FREE_TIME_THRESHOLD:
		return _sleep(colonist, state, record, Action.Layer.FREE_TIME,
			"Sem tarefa e com sono em %d%%, abaixo de %d%%: dorme no tempo livre" % [
				needs.rest, Balance.REST_FREE_TIME_THRESHOLD])
	return _free_time_filler(colonist, state, record)


## Comer, para ordens do jogador: mesma escolha da IA, na camada pedida (null se não há comida).
func food_action(colonist: Colonist, state: WorldState, record: DecisionRecord, layer: Action.Layer, why: String) -> Action:
	return _find_food(colonist, state, record, layer, why)


## Dormir, para ordens do jogador: mesma escolha de cama da IA, na camada pedida.
func sleep_action(colonist: Colonist, state: WorldState, record: DecisionRecord, layer: Action.Layer, why: String) -> Action:
	return _sleep(colonist, state, record, layer, why)


## Dorme na cama livre mais perto (por custo de caminho); sem cama alcançável, dorme no chão onde está.
func _sleep(colonist: Colonist, state: WorldState, record: DecisionRecord, layer: Action.Layer, why: String) -> Action:
	var beds := state.beds()
	if beds.is_empty():
		return Action.make(Action.Kind.SLEEP, layer, colonist.cell, "%s; não há cama construída, dorme no chão" % why)
	beds.sort_custom(func(a: Structure, b: Structure) -> bool:
		return a.origin.distance_squared_to(colonist.cell) < b.origin.distance_squared_to(colonist.cell))
	var best: Structure
	var best_path: Array[Vector2i] = []
	var best_cost := INF
	for bed in beds.slice(0, Balance.BED_CANDIDATES_EVALUATED):
		var owner := state.reservations.owner_of(Reservations.bed_key(bed.id))
		if owner != 0 and owner != colonist.id:
			record.rejected.append("Cama #%d: ocupada por %s" % [bed.id, state.colonist_name(owner)])
			continue
		var path := state.navigation.find_path(colonist.cell, bed.origin)
		if path.is_empty():
			record.rejected.append("Cama #%d: sem caminho" % bed.id)
			continue
		var cost := state.navigation.path_cost(path)
		if cost < best_cost:
			best = bed
			best_path = path
			best_cost = cost
	if best == null:
		return Action.make(Action.Kind.SLEEP, layer, colonist.cell, "%s; nenhuma cama livre, dorme no chão" % why)
	var action := Action.make(Action.Kind.SLEEP, layer, best.origin, "%s; dorme na cama #%d (custo %.0f)" % [why, best.id, best_cost])
	action.target_id = best.id
	action.path = best_path
	action.title = "Dormir na cama #%d" % best.id
	return action


func _layer_limit(colonist: Colonist) -> int:
	var current := colonist.action
	if current == null or current.is_filler():
		return _NO_LAYER
	return current.layer


## Melhor comida por perto (GDD: "escolhe a melhor refeição disponível por perto"): contêineres,
## pilhas no chão e arbustos. Pontuação = nutrição ÷ (1 + custo do caminho ÷ 30): uma refeição
## cozida vale a caminhada a mais que frutas cruas. O humor de cada comida entra no M5.
func _find_food(colonist: Colonist, state: WorldState, record: DecisionRecord, layer: Action.Layer, why: String) -> Action:
	var candidates: Array[Dictionary] = []
	for container in state.containers.values():
		var best_item := _best_food_in(container)
		if best_item != &"":
			candidates.append({"source": Action.ItemSource.CONTAINER, "id": container.id, "cell": container.cell,
				"item": best_item, "adjacent": true, "label": "%s #%d" % [container.def.display_name, container.id]})
	for stack in state.stacks.values():
		if Defs.item(stack.item).is_edible() and stack.available() > 0:
			candidates.append({"source": Action.ItemSource.STACK, "id": stack.id, "cell": stack.cell,
				"item": stack.item, "adjacent": false, "label": "pilha no chão"})
	for bush in state.bushes:
		if bush.portions <= 0:
			continue
		if state.task_board.designation_at(bush.cell):
			continue
		var owner := state.reservations.owner_of(Reservations.bush_key(bush.id))
		if owner != 0 and owner != colonist.id:
			record.rejected.append("Arbusto #%d: reservado por %s" % [bush.id, state.colonist_name(owner)])
			continue
		candidates.append({"source": Action.ItemSource.BUSH, "id": bush.id, "cell": bush.cell,
			"item": &"berries", "adjacent": true, "label": "arbusto #%d" % bush.id})
	if candidates.is_empty():
		record.rejected.append("Precisa comer, mas não há comida guardada e nenhum arbusto tem frutas")
		return null
	candidates.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return a["cell"].distance_squared_to(colonist.cell) < b["cell"].distance_squared_to(colonist.cell))

	var best: Dictionary = {}
	var best_cost := INF
	var best_score := -1.0
	for candidate in _food_shortlist(candidates):
		var path: Array[Vector2i]
		if candidate["adjacent"]:
			path = state.navigation.path_to_adjacent(colonist.cell, candidate["cell"])
		else:
			path = state.navigation.find_path(colonist.cell, candidate["cell"])
		var food_name := Defs.item(candidate["item"]).display_name.to_lower()
		if path.is_empty():
			record.rejected.append("%s em %s: sem caminho" % [food_name.capitalize(), candidate["label"]])
			continue
		var cost := state.navigation.path_cost(path)
		var food_score := Defs.item(candidate["item"]).nutrition / (1.0 + cost / Balance.TASK_DISTANCE_DIVISOR)
		if food_score > best_score:
			if not best.is_empty():
				record.rejected.append("%s em %s: pontuação %.1f menor" % [
					Defs.item(best["item"]).display_name, best["label"], best_score])
			best = candidate
			best["path"] = path
			best_cost = cost
			best_score = food_score
		else:
			record.rejected.append("%s em %s: pontuação %.1f menor" % [food_name.capitalize(), candidate["label"], food_score])
	if best.is_empty():
		record.rejected.append("Precisa comer, mas nenhuma comida próxima está alcançável")
		return null

	var food := Defs.item(best["item"])
	var action := Action.make(Action.Kind.EAT, layer, best["cell"],
		"%s; %s em %s tem a melhor pontuação: nutrição %.0f ÷ (1 + custo %.0f ÷ %.0f) = %.1f" % [
			why, food.display_name, best["label"], food.nutrition, best_cost, Balance.TASK_DISTANCE_DIVISOR, best_score])
	action.item_source = best["source"]
	action.target_id = best["id"]
	action.item_id = food.id
	action.adjacent = best["adjacent"]
	action.path = best["path"]
	action.count = maxi(1, floori((Balance.EAT_UNTIL - colonist.needs.food) / food.nutrition))
	action.title = "Comer %s (%s)" % [food.display_name, best["label"]]
	return action


## Candidatas que recebem cálculo de caminho: as mais perto em linha reta e, de cada tipo de
## comida, a mais perto (para uma refeição um pouco mais longe não ser ignorada).
func _food_shortlist(candidates: Array[Dictionary]) -> Array[Dictionary]:
	var result: Array[Dictionary] = candidates.slice(0, Balance.FOOD_CANDIDATES_EVALUATED)
	var seen := {}
	for candidate in result:
		seen[candidate["item"]] = true
	for candidate in candidates:
		if not seen.has(candidate["item"]):
			seen[candidate["item"]] = true
			result.append(candidate)
	return result


## Antes de trabalhar: há ferramenta melhor guardada por perto para este trabalho? (GDD: "pega a
## melhor ferramenta para a tarefa no rack ou baú mais próximo"). Devolve a ação de pegá-la, ou null.
func _better_tool(colonist: Colonist, work: Action, state: WorldState, record: DecisionRecord) -> Action:
	var task := state.task_board.get_task(work.task_id)
	if task == null:
		return null
	var current := _tool_value(colonist.equipment.hand(), task.work_type)
	var best: Dictionary = {}
	var best_value := current
	var limit_squared := Balance.TOOL_SEARCH_MAX_DISTANCE * Balance.TOOL_SEARCH_MAX_DISTANCE
	for container in state.containers.values():
		if container.cell.distance_squared_to(colonist.cell) > limit_squared:
			continue
		for item in container.contents():
			var value := _tool_value(item, task.work_type)
			if value > best_value and container.available(item) > 0:
				best_value = value
				best = {"source": Action.ItemSource.CONTAINER, "id": container.id, "cell": container.cell, "item": item, "adjacent": true}
	for stack in state.stacks.values():
		var value := _tool_value(stack.item, task.work_type)
		if value > best_value and stack.available() > 0 and stack.cell.distance_squared_to(colonist.cell) <= limit_squared:
			best_value = value
			best = {"source": Action.ItemSource.STACK, "id": stack.id, "cell": stack.cell, "item": stack.item, "adjacent": false}
	if best.is_empty():
		return null
	var path: Array[Vector2i]
	if best["adjacent"]:
		path = state.navigation.path_to_adjacent(colonist.cell, best["cell"])
	else:
		path = state.navigation.find_path(colonist.cell, best["cell"])
	var tool_name := Defs.item(best["item"]).display_name
	if path.is_empty():
		record.rejected.append("%s: sem caminho até ela" % tool_name)
		return null
	var action := Action.make(Action.Kind.EQUIP, Action.Layer.WORK, best["cell"],
		"Vai %s; antes pega %s, que é melhor para %s" % [work.label().to_lower(), tool_name.to_lower(), WorkType.name_of(task.work_type)])
	action.item_source = best["source"]
	action.target_id = best["id"]
	action.item_id = best["item"]
	action.adjacent = best["adjacent"]
	action.path = path
	action.title = "Pegar %s" % tool_name.to_lower()
	return action


## Quanto o item ajuda no trabalho: bônus de velocidade, ou valor de caça para Caçar. 1 = nada.
static func _tool_value(item: StringName, work_type: int) -> float:
	if item == &"" or not Equipment.is_equippable(item):
		return 1.0
	var definition := Defs.item(item)
	if work_type == WorkType.Id.HUNT:
		var unarmed := Balance.UNARMED_HUNT_DAMAGE * (1.0 + Balance.UNARMED_HUNT_RANGE / 10.0)
		return maxf(definition.hunting_value() / unarmed, definition.work_bonus.get(&"hunt", 1.0))
	if definition.equip_slot != &"hand":
		return 1.0
	return definition.work_bonus.get(WorkType.key_of(work_type), 1.0)


## Comida com mais nutrição disponível no contêiner, ou vazio.
func _best_food_in(container: StorageContainer) -> StringName:
	var best: StringName = &""
	var best_nutrition := 0.0
	for item in container.contents():
		var definition := Defs.item(item)
		if definition.is_edible() and container.available(item) > 0 and definition.nutrition > best_nutrition:
			best = item
			best_nutrition = definition.nutrition
	return best


func _free_time_filler(colonist: Colonist, state: WorldState, record: DecisionRecord) -> Action:
	record.rejected.append("Sem ordens nem tarefa; fome %d%% e sono %d%% acima dos limites" % [colonist.needs.food, colonist.needs.rest])
	var curious := colonist.has_trait(Traits.CURIOUS)
	var radius := Balance.CURIOUS_WANDER_RADIUS if curious else Balance.WANDER_RADIUS
	if state.rng.randf() < (Balance.CURIOUS_WANDER_CHANCE if curious else Balance.WANDER_CHANCE):
		var target := colonist.cell + Vector2i(state.rng.randi_range(-radius, radius), state.rng.randi_range(-radius, radius))
		var path := state.navigation.find_path(colonist.cell, target)
		if path.size() > 1:
			var why := "Curioso: no tempo livre vai olhar um lugar mais longe" if curious \
				else "Tempo livre sem nada a fazer: dá uma volta por perto"
			var wander := Action.make(Action.Kind.WANDER, Action.Layer.FREE_TIME, target, why)
			wander.path = path
			return wander
	return Action.make(Action.Kind.IDLE, Action.Layer.FREE_TIME, colonist.cell,
		"Tempo livre sem nada a fazer: descansa parado")
