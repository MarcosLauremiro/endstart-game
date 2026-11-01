class_name SimHelpers
extends RefCounted
## Ajudantes dos cenários headless: avançar até uma condição, achar área livre e construir na hora.


## Avança até a condição valer ou o limite; devolve se a condição valeu.
static func run_until(simulation: Simulation, condition: Callable, limit: int) -> bool:
	for _i in limit:
		if condition.call():
			return true
		simulation.step()
	return condition.call()


## Área livre perto do primeiro colono (grama ou solo, sem contêiner, pilha ou colono), alcançável.
## Plantas silvestres dentro dela (e na borda) são retiradas.
static func clear_area(simulation: Simulation, size: Vector2i) -> Vector2i:
	var state := simulation.state
	var start := state.colonists[0].cell
	for radius in range(2, 30):
		for y in range(start.y - radius, start.y + radius + 1):
			for x in range(start.x - radius, start.x + radius + 1):
				var origin := Vector2i(x, y)
				if _area_is_free(simulation, origin, size):
					_clear_plants(state, origin, size)
					return origin
	push_error("Nenhuma área livre de %s" % size)
	return start


## Constrói a estrutura na hora, sem colonos (para cenários que testam o uso, não a obra nem a
## pesquisa: todas as pesquisas ficam liberadas).
static func build_now(simulation: Simulation, structure_id: StringName, origin: Vector2i) -> Structure:
	var state := simulation.state
	state.research.unlock_all()
	var site := Construction.place(state, Defs.structure(structure_id), origin)
	TaskEffects.complete(state.task_board.construction_for_site(site.id), state)
	return state.buildings_by_cell.get(origin)


## Coloca itens num contêiner novo construído na hora ao lado da origem.
static func stock(simulation: Simulation, cell: Vector2i, item: StringName, amount: int) -> StorageContainer:
	var state := simulation.state
	var container: StorageContainer = state.containers_by_cell.get(cell)
	if container == null:
		container = state.add_container(&"chest_rustic", cell)
	container.add_items(item, amount)
	return container


## Tira toda a comida guardada e os arbustos: a colônia depende só do que produzir.
static func remove_wild_and_stored_food(simulation: Simulation) -> void:
	var state := simulation.state
	for container in state.containers.values():
		for definition in Defs.items():
			if definition.is_edible():
				container.take_all(definition.id)
	for bush in state.bushes.duplicate():
		state.remove_bush(bush)


static func _area_is_free(simulation: Simulation, origin: Vector2i, size: Vector2i) -> bool:
	var state := simulation.state
	var anchor := state.colonists[0].cell
	for y in range(-1, size.y + 1):
		for x in range(-1, size.x + 1):
			var cell := origin + Vector2i(x, y)
			if not state.world.contains(cell):
				return false
			var kind := state.world.get_terrain(cell)
			if kind != Terrain.Kind.GRASS and kind != Terrain.Kind.DIRT:
				return false
			if state.containers_by_cell.has(cell) or state.colonist_at(cell) or state.stacks_by_cell.has(cell) \
					or state.buildings_by_cell.has(cell) or state.zone_by_cell.has(cell):
				return false
	return state.navigation.can_reach(anchor, origin + Vector2i(0, -1))


static func _clear_plants(state: WorldState, origin: Vector2i, size: Vector2i) -> void:
	for y in range(-1, size.y + 1):
		for x in range(-1, size.x + 1):
			var cell := origin + Vector2i(x, y)
			if state.trees_by_cell.has(cell):
				state.remove_tree(state.trees_by_cell[cell])
			if state.bushes_by_cell.has(cell):
				state.remove_bush(state.bushes_by_cell[cell])
			if state.fiber_plants_by_cell.has(cell):
				state.remove_fiber_plant(state.fiber_plants_by_cell[cell])
			if state.stumps_by_cell.has(cell):
				state.remove_stump(state.stumps_by_cell[cell])
