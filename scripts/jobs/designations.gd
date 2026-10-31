class_name Designations
extends RefCounted
## Ordens de área do jogador (GDD: cortar, minerar, colher, caçar) e zonas de plantação.
## Cada célula (ou animal) vira uma tarefa no quadro, então uma área grande se divide sozinha entre
## os colonos. Ninguém é escolhido aqui: a IA decide quem faz.

enum Tool { NONE, CUT, MINE, HARVEST, DECONSTRUCT, CANCEL, HUNT, GROW_ZONE }

const TOOL_NAMES := {
	Tool.CUT: "Cortar plantas",
	Tool.MINE: "Minerar",
	Tool.HARVEST: "Colher",
	Tool.HUNT: "Caçar",
	Tool.GROW_ZONE: "Plantação",
	Tool.DECONSTRUCT: "Desmontar",
	Tool.CANCEL: "Cancelar",
}


## Aplica a ferramenta na área e devolve quantas tarefas foram criadas ou canceladas.
static func apply(state: WorldState, tool: Tool, area: Rect2i) -> int:
	var board := state.task_board
	var tick := state.clock.tick
	var changed := 0
	if tool == Tool.HUNT:
		return _hunt_in(state, area)
	if tool == Tool.GROW_ZONE:
		return Farming.create_zone(state, area)
	if tool == Tool.CANCEL:
		changed += _cancel_hunts_in(state, area) + Farming.remove_cells(state, area)
	var clipped := area.intersection(Rect2i(Vector2i.ZERO, state.world.size))
	for y in range(clipped.position.y, clipped.end.y):
		for x in range(clipped.position.x, clipped.end.x):
			var cell := Vector2i(x, y)
			var existing := board.designation_at(cell)
			if tool == Tool.CANCEL:
				changed += _cancel_at(state, cell)
				continue
			if tool == Tool.DECONSTRUCT:
				if Construction.designate_deconstruct(state, cell):
					changed += 1
				continue
			if existing:
				continue
			match tool:
				Tool.CUT:
					var tree: WildTree = state.trees_by_cell.get(cell)
					if tree:
						board.create(Task.Kind.CUT, cell, tree.id, tree.cut_work_ticks(), tick)
						changed += 1
				Tool.MINE:
					if state.world.get_terrain(cell) == Terrain.Kind.ROCK:
						board.create(Task.Kind.MINE, cell, 0, Balance.MINE_WORK_TICKS, tick)
						changed += 1
				Tool.HARVEST:
					var bush := state.bush_at(cell)
					var fiber: FiberPlant = state.fiber_plants_by_cell.get(cell)
					if bush and bush.portions > 0:
						board.create(Task.Kind.HARVEST, cell, bush.id, Balance.HARVEST_WORK_TICKS, tick)
						changed += 1
					elif fiber and fiber.is_mature():
						board.create(Task.Kind.HARVEST, cell, fiber.id, Balance.FIBER_HARVEST_WORK_TICKS, tick)
						changed += 1
	return changed


## Marca para caça os animais na área. Predadores ficam de fora, com aviso.
static func _hunt_in(state: WorldState, area: Rect2i) -> int:
	var changed := 0
	var refused_predator := ""
	for animal in state.animals.values():
		if not area.has_point(animal.cell):
			continue
		if animal.def.is_predator:
			refused_predator = animal.def.display_name
		elif Wildlife.designate_hunt(state, animal):
			changed += 1
	if not refused_predator.is_empty():
		state.post_message("%s: predador perigoso demais para caçar sem armas de combate" % refused_predator)
	return changed


static func _cancel_hunts_in(state: WorldState, area: Rect2i) -> int:
	var changed := 0
	for animal in state.animals.values():
		var hunt := state.task_board.hunt_for(animal.id)
		if hunt and area.has_point(animal.cell):
			state.task_board.remove(hunt, Task.Status.CANCELLED)
			changed += 1
	return changed


## Cancela tudo o que o jogador marcou na célula: designação, planta de construção (o material
## entregue volta ao chão) e desmontagem.
static func _cancel_at(state: WorldState, cell: Vector2i) -> int:
	var board := state.task_board
	var changed := 0
	var existing := board.designation_at(cell)
	if existing:
		board.remove(existing, Task.Status.CANCELLED)
		changed += 1
	for layer in [StructureDef.Layer.BUILDING, StructureDef.Layer.FLOOR]:
		var site := state.site_at(cell, layer)
		if site:
			Construction.cancel(state, site)
			changed += 1
	for target in [state.buildings_by_cell.get(cell), state.floors_by_cell.get(cell), state.containers_by_cell.get(cell)]:
		if target == null:
			continue
		var deconstruction := board.deconstruction_for(target.id)
		if deconstruction:
			board.remove(deconstruction, Task.Status.CANCELLED)
			changed += 1
	return changed
