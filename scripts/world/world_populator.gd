class_name WorldPopulator
extends RefCounted
## Coloca no mapa o que não é terreno: arbustos, árvores, ponto de chegada dos colonos e
## os caixotes com os recursos iniciais. Usa o RNG da simulação: a mesma seed dá o mesmo resultado.

const _MAX_ATTEMPTS_PER_BUSH := 50
const _SPAWN_SEARCH_RADIUS := 24


static func place_berry_bushes(state: WorldState) -> void:
	var attempts := 0
	while state.bushes.size() < Balance.BERRY_BUSH_COUNT and attempts < Balance.BERRY_BUSH_COUNT * _MAX_ATTEMPTS_PER_BUSH:
		attempts += 1
		var cell := Vector2i(
			state.rng.randi_range(0, state.world.size.x - 1),
			state.rng.randi_range(0, state.world.size.y - 1),
		)
		var kind := state.world.get_terrain(cell)
		if state.bushes_by_cell.has(cell) or (kind != Terrain.Kind.GRASS and kind != Terrain.Kind.TALL_GRASS):
			continue
		var bush := state.add_bush(cell)
		if state.rng.randf() < Balance.BUSH_YOUNG_FRACTION:
			bush.growth_hours = state.rng.randi_range(0, Balance.BUSH_GROWTH_HOURS - 1)
			bush.portions = 0


## Floresta temperada: árvores densas na grama alta e esparsas na grama, longe do ponto de chegada.
static func place_trees(state: WorldState) -> void:
	var center := state.world.size / 2
	var clear_radius_squared := Balance.SPAWN_CLEAR_RADIUS * Balance.SPAWN_CLEAR_RADIUS
	for y in state.world.size.y:
		for x in state.world.size.x:
			var cell := Vector2i(x, y)
			var kind := state.world.get_terrain(cell)
			var density := 0.0
			if kind == Terrain.Kind.TALL_GRASS:
				density = Balance.TREE_DENSITY_TALL_GRASS
			elif kind == Terrain.Kind.GRASS:
				density = Balance.TREE_DENSITY_GRASS
			if state.rng.randf() >= density:
				continue
			if state.bushes_by_cell.has(cell) or cell.distance_squared_to(center) <= clear_radius_squared:
				continue
			var tree := state.add_tree(cell)
			if state.rng.randf() < Balance.TREE_YOUNG_FRACTION:
				tree.growth_hours = state.rng.randi_range(0, Balance.TREE_GROWTH_HOURS - 1)


## Vegetação rasteira que rende Fibra, espalhada pela grama livre; parte já está crescida.
static func place_fiber_plants(state: WorldState) -> void:
	for y in state.world.size.y:
		for x in state.world.size.x:
			var cell := Vector2i(x, y)
			var kind := state.world.get_terrain(cell)
			if kind != Terrain.Kind.GRASS and kind != Terrain.Kind.TALL_GRASS:
				continue
			if state.rng.randf() >= Balance.FIBER_PLANT_DENSITY or state.has_object_at(cell):
				continue
			var plant := state.add_fiber_plant(cell)
			plant.growth_hours = state.rng.randi_range(0, Balance.FIBER_GROWTH_HOURS)


## As células em terra firme mais próximas do centro do mapa.
static func spawn_cells(state: WorldState, count: int) -> Array[Vector2i]:
	var center := state.world.size / 2
	var candidates: Array[Vector2i] = []
	for y in range(center.y - _SPAWN_SEARCH_RADIUS, center.y + _SPAWN_SEARCH_RADIUS + 1):
		for x in range(center.x - _SPAWN_SEARCH_RADIUS, center.x + _SPAWN_SEARCH_RADIUS + 1):
			var cell := Vector2i(x, y)
			if state.world.contains(cell) and _is_free_dry_land(state, cell):
				candidates.append(cell)
	candidates.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
		return a.distance_squared_to(center) < b.distance_squared_to(center))
	return candidates.slice(0, count)


## Caixotes com os recursos iniciais (GDD: BALANÇA, ~15 dias de comida e material para o primeiro abrigo),
## ajustados pelo número de colonos. O que não couber fica no chão, com tarefa de Carregar.
static func place_starting_supplies(state: WorldState, colonist_count: int) -> void:
	var missing := Balance.MAX_STARTING_COLONISTS - colonist_count
	var factor := 1.0 + Balance.STARTING_BONUS_PER_MISSING_COLONIST * missing
	var meal := Defs.item(&"simple_meal")
	var meals := ceili(Balance.STARTING_FOOD_DAYS * colonist_count * Balance.DAILY_FOOD_NEED * factor / meal.nutrition)
	var wood := roundi(Balance.STARTING_WOOD * factor)

	var taken := {}
	for colonist in state.colonists:
		taken[colonist.cell] = true
	var crates: Array[StorageContainer] = []
	for cell in spawn_cells(state, colonist_count + Balance.STARTING_CRATES * 4):
		if crates.size() >= Balance.STARTING_CRATES:
			break
		if taken.has(cell):
			continue
		crates.append(state.add_container(&"crate", cell))
		taken[cell] = true

	var spawn := state.colonists[0].cell if not state.colonists.is_empty() else state.world.size / 2
	for supply in [[meal.id, meals], [&"wood", wood]]:
		var remaining: int = supply[1]
		for crate in crates:
			remaining -= crate.add_items(supply[0], remaining)
		if remaining > 0:
			state.drop_items(spawn, supply[0], remaining)


static func _is_free_dry_land(state: WorldState, cell: Vector2i) -> bool:
	var kind := state.world.get_terrain(cell)
	return Terrain.is_passable(kind) and kind != Terrain.Kind.SHALLOW_WATER \
		and not state.has_object_at(cell)
