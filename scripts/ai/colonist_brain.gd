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

	# 1. Reações urgentes: cair ferido vence tudo; depois desmaiar e fugir de saqueadores.
	if colonist.health.is_downed():
		if colonist.action and colonist.action.kind == Action.Kind.DOWNED:
			return null
		var downed := _in_place(Action.Kind.DOWNED, Action.Layer.REACTION, colonist,
			"Caiu ferido: %d de dano, %d%% de sangue perdido" % [roundi(colonist.health.damage()), roundi(colonist.health.blood_loss)])
		downed.title = "Caído (ferido)"
		return downed
	if needs.rest <= 0.0 and limit > Action.Layer.REACTION:
		return Action.make(Action.Kind.SLEEP, Action.Layer.REACTION, colonist.cell,
			"Desmaiou de exaustão: sono chegou a 0%")
	if limit > Action.Layer.REACTION:
		var flee := _flee(colonist, state)
		if flee:
			return flee

	# 2. Necessidades críticas (convocado, ele ignora: segue as ordens até ser dispensado)
	if limit <= Action.Layer.CRITICAL_NEED:
		return null
	if colonist.drafted:
		return _drafted(colonist, limit)
	if colonist.health.needs_tending():
		var tend := _in_place(Action.Kind.TEND_SELF, Action.Layer.CRITICAL_NEED, colonist,
			"Sangrando (%d%% de sangue por hora): estanca os próprios ferimentos" % roundi(colonist.health.bleeding_per_hour()))
		tend.title = "Tratar os próprios ferimentos"
		return tend
	if needs.food < Balance.FOOD_CRITICAL_THRESHOLD:
		var why := "Fome em %d%%, abaixo de %d%%: crítica, interrompe outras atividades" % [
			needs.food, Balance.FOOD_CRITICAL_THRESHOLD]
		var eat := _find_food(colonist, state, record, Action.Layer.CRITICAL_NEED, why)
		if eat:
			return eat
	if needs.rest < Balance.REST_CRITICAL_THRESHOLD:
		return _sleep(colonist, state, record, Action.Layer.CRITICAL_NEED,
			"Sono em %d%%, abaixo de %d%%: crítico" % [needs.rest, Balance.REST_CRITICAL_THRESHOLD])
	if colonist.health.damage() >= Balance.REST_DAMAGE:
		var rest := _sleep(colonist, state, record, Action.Layer.CRITICAL_NEED,
			"Ferido (%d de dano, a partir de %d): repousa até baixar de %d" % [
				roundi(colonist.health.damage()), roundi(Balance.REST_DAMAGE), roundi(Balance.REST_UNTIL_DAMAGE)])
		rest.kind = Action.Kind.REST
		rest.title = "Repousar ferido" + (" na cama #%d" % rest.target_id if rest.target_id != 0 else " no chão")
		return rest

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


## Ação parada no lugar (caído, tratar-se, segurar a posição): o caminho é só a célula atual.
static func _in_place(kind: Action.Kind, layer: Action.Layer, colonist: Colonist, why: String) -> Action:
	var action := Action.make(kind, layer, colonist.cell, why)
	action.path = [colonist.cell]
	return action


## Convocado: cumpre a ordem do jogador (ir até um lugar, atacar alguém) ou segura a posição,
## atacando quem chegar ao alcance da arma.
func _drafted(colonist: Colonist, limit: int) -> Action:
	if colonist.direct_order:
		return colonist.direct_order
	if limit <= Action.Layer.ORDER:
		return null
	var weapon := colonist.weapon()
	var reach := "arco, alcance %d" % Combat.range_of(weapon) if Combat.is_ranged(weapon) \
		else "corpo a corpo, vai até inimigos a %d tiles" % Balance.DRAFTED_MELEE_ENGAGE
	var stance := _in_place(Action.Kind.FIGHT, Action.Layer.ORDER, colonist, "Convocado pelo jogador: segura a posição (%s)" % reach)
	stance.title = "Convocado"
	return stance


## Fugir de saqueadores: quem não está convocado foge se um chega perto (o Covarde, de mais longe);
## o Covarde convocado foge quando já está ferido (GDD: pode fugir em combate).
func _flee(colonist: Colonist, state: WorldState) -> Action:
	var coward := colonist.has_trait(Traits.COWARD)
	if colonist.drafted and not (coward and colonist.health.damage() >= Balance.COWARD_BREAK_DAMAGE):
		return null
	var radius := Balance.COWARD_FLEE_RAIDER_RADIUS if coward else Balance.FLEE_RAIDER_RADIUS
	var threat: Raider
	var best := radius * radius
	for raider: Raider in state.threats.raiders.values():
		if raider.mode == Raider.Mode.FLEE:
			continue
		var distance := raider.cell.distance_squared_to(colonist.cell)
		if distance <= best:
			best = distance
			threat = raider
	if threat == null:
		return null
	var away := Vector2(colonist.cell - threat.cell)
	if away == Vector2.ZERO:
		away = Vector2.RIGHT
	var target := colonist.cell + Vector2i((away.normalized() * Balance.FLEE_DISTANCE).round())
	target = state.nearest_walkable(target.clamp(Vector2i.ZERO, state.world.size - Vector2i.ONE))
	var path := state.navigation.find_path(colonist.cell, target)
	if path.size() <= 1:
		return null
	var why := "%s a %d tiles" % [threat.display_name(), roundi(sqrt(float(best)))]
	if colonist.drafted:
		why = "Covarde e ferido: abandona o combate; %s" % why
	elif coward:
		why = "Covarde: foge de longe; %s" % why
	else:
		why = "Não está convocado: foge; %s" % why
	var flee := Action.make(Action.Kind.FLEE, Action.Layer.REACTION, target, why)
	flee.path = path
	flee.title = "Fugir de %s" % threat.display_name().to_lower()
	return flee


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
	if state.rng.randf() < Balance.WANDER_CHANCE:
		var target := colonist.cell + Vector2i(
			state.rng.randi_range(-Balance.WANDER_RADIUS, Balance.WANDER_RADIUS),
			state.rng.randi_range(-Balance.WANDER_RADIUS, Balance.WANDER_RADIUS),
		)
		var path := state.navigation.find_path(colonist.cell, target)
		if path.size() > 1:
			var wander := Action.make(Action.Kind.WANDER, Action.Layer.FREE_TIME, target,
				"Tempo livre sem nada a fazer: dá uma volta por perto")
			wander.path = path
			return wander
	return Action.make(Action.Kind.IDLE, Action.Layer.FREE_TIME, colonist.cell,
		"Tempo livre sem nada a fazer: descansa parado")
