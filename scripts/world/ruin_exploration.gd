class_name RuinExploration
extends RefCounted
## Explorar a ruína (GDD: Quanto cada ação rende). O jogador manda investigar; cada sala vira uma
## tarefa de Pesquisar. Investigar rende 2 V e o que a sala guarda; achar o artefato rende 15 V e
## revela o ramo Redescoberta (no MVP o gatilho é encontrar o artefato; ver GDD).


## Cria as tarefas de investigar as salas que faltam. Devolve quantas criou.
static func designate(state: WorldState, ruin: Ruin) -> int:
	var created := 0
	for room in ruin.rooms:
		if room["investigated"] or state.task_board.investigation_for(room["id"]):
			continue
		var task := state.task_board.create(Task.Kind.INVESTIGATE, room["center"], room["id"],
			Balance.RUIN_INVESTIGATE_TICKS, state.clock.tick)
		task.title = "Investigar a %s da ruína" % room["name"].to_lower()
		created += 1
	return created


static func investigate(state: WorldState, room_id: int, colonist: Colonist) -> void:
	var room := state.ruin_room(room_id)
	if room.is_empty() or room["investigated"]:
		return
	room["investigated"] = true
	var research := state.research
	var gained := research.add_points(Research.Points.RELIC, Balance.RUIN_ROOM_RELIC, colonist)
	var found := PackedStringArray()
	for item in room["loot"]:
		state.drop_items(room["center"], item, room["loot"][item])
		found.append("%d %s" % [room["loot"][item], Defs.item(item).display_name.to_lower()])
	if room["artifact"]:
		state.drop_items(room["center"], &"artifact", 1)
		gained += research.add_points(Research.Points.RELIC, Balance.ARTIFACT_FOUND_RELIC, colonist)
		found.append("um artefato")
	var who := colonist.display_name if colonist else "Alguém"
	state.post_message("%s investigou a %s da ruína: +%d V%s" % [who, room["name"].to_lower(), roundi(gained),
		"; achou " + ", ".join(found) if not found.is_empty() else ""])
	if room["artifact"]:
		var branch := research.fire_trigger(&"artifact_found")
		if not branch.is_empty():
			state.post_message("Um artefato antigo! Novo ramo de pesquisa: %s" % branch)
