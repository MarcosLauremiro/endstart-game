class_name TestNavigation
extends TestCase
## Caminhos: obstáculos, inalcançável, custo do terreno e travessia do rio pelos vaus.


func test_path_goes_around_obstacle() -> void:
	var world := _grass_world(Vector2i(5, 5))
	for y in 4:
		world.set_terrain(Vector2i(2, y), Terrain.Kind.ROCK)
	var navigation := NavigationGrid.new(world)
	var path := navigation.find_path(Vector2i(0, 0), Vector2i(4, 0))
	expect(not path.is_empty(), "Deve existir caminho pela abertura da parede")
	for cell in path:
		expect(world.get_terrain(cell) != Terrain.Kind.ROCK, "O caminho não pode passar pela rocha (%s)" % cell)


func test_blocked_destination_has_no_path() -> void:
	var world := _grass_world(Vector2i(5, 5))
	for y in 5:
		world.set_terrain(Vector2i(2, y), Terrain.Kind.DEEP_WATER)
	var navigation := NavigationGrid.new(world)
	expect(navigation.find_path(Vector2i(0, 0), Vector2i(4, 0)).is_empty(), "Água funda contínua deve impedir o caminho")


func test_impassable_cells_are_not_walkable() -> void:
	var world := _grass_world(Vector2i(3, 1))
	world.set_terrain(Vector2i(1, 0), Terrain.Kind.ROCK)
	var navigation := NavigationGrid.new(world)
	expect(not navigation.is_walkable(Vector2i(1, 0)), "Rocha não é caminhável")
	expect(not navigation.is_walkable(Vector2i(-1, 0)), "Fora do mapa não é caminhável")
	expect(navigation.is_walkable(Vector2i(0, 0)), "Grama é caminhável")


func test_shallow_water_costs_more() -> void:
	var dry := _grass_world(Vector2i(3, 1))
	var wet := _grass_world(Vector2i(3, 1))
	wet.set_terrain(Vector2i(1, 0), Terrain.Kind.SHALLOW_WATER)
	var dry_nav := NavigationGrid.new(dry)
	var wet_nav := NavigationGrid.new(wet)
	var dry_cost := dry_nav.path_cost(dry_nav.find_path(Vector2i(0, 0), Vector2i(2, 0)))
	var wet_cost := wet_nav.path_cost(wet_nav.find_path(Vector2i(0, 0), Vector2i(2, 0)))
	expect(wet_cost > dry_cost, "Atravessar água rasa deve custar mais (%.2f contra %.2f)" % [wet_cost, dry_cost])


func test_generated_map_is_connected_through_fords() -> void:
	for world_seed in [1, 2, 3, 4, 5]:
		var simulation := Simulation.new(world_seed, 1)
		var navigation := simulation.state.navigation
		var start := simulation.state.colonists[0].cell
		var reached := _flood(navigation, simulation.world.size, start)
		var walkable := 0
		for y in simulation.world.size.y:
			for x in simulation.world.size.x:
				if navigation.is_walkable(Vector2i(x, y)):
					walkable += 1
		var ratio := float(reached) / walkable
		expect(ratio > 0.95, "Seed %d: só %.0f%% do mapa é alcançável a partir do início" % [world_seed, ratio * 100])


func test_blocking_a_corridor_splits_regions() -> void:
	var world := _grass_world(Vector2i(5, 3))
	for x in 5:
		world.set_terrain(Vector2i(x, 0), Terrain.Kind.ROCK)
		world.set_terrain(Vector2i(x, 2), Terrain.Kind.ROCK)
	var navigation := NavigationGrid.new(world)
	expect(navigation.can_reach(Vector2i(0, 1), Vector2i(4, 1)), "O corredor aberto liga as pontas")
	navigation.set_blocked(Vector2i(2, 1), true)
	expect(not navigation.can_reach(Vector2i(0, 1), Vector2i(4, 1)), "Bloquear o corredor separa as pontas")
	navigation.set_blocked(Vector2i(2, 1), false)
	expect(navigation.can_reach(Vector2i(0, 1), Vector2i(4, 1)), "Desbloquear volta a ligar")


func test_incremental_regions_match_full_rebuild() -> void:
	var simulation := Simulation.new(4242, 1)
	var navigation := simulation.state.navigation
	var rng := RandomNumberGenerator.new()
	rng.seed = 99
	var center := simulation.state.colonists[0].cell
	var changed: Array[Vector2i] = []
	for _i in 300:
		var cell := center + Vector2i(rng.randi_range(-12, 12), rng.randi_range(-12, 12))
		if simulation.world.contains(cell) and cell != center:
			navigation.set_blocked(cell, rng.randf() < 0.7)
			changed.append(cell)
	var fresh := NavigationGrid.new(simulation.world)
	for cell in changed:
		fresh.set_blocked(cell, not navigation.is_walkable(cell) and Terrain.is_passable(simulation.world.get_terrain(cell)))
	var mismatches := 0
	for _i in 400:
		var target := center + Vector2i(rng.randi_range(-20, 20), rng.randi_range(-20, 20))
		if simulation.world.contains(target) and navigation.can_reach(center, target) != fresh.can_reach(center, target):
			mismatches += 1
	expect_equal(mismatches, 0, "As regiões mantidas aos poucos devem dar o mesmo alcance que um recálculo completo")


func _grass_world(size: Vector2i) -> WorldData:
	var world := WorldData.new(size)
	for y in size.y:
		for x in size.x:
			world.set_terrain(Vector2i(x, y), Terrain.Kind.GRASS)
	return world


## Preenchimento em 4 direções: subestima o alcance real (que também usa diagonais).
func _flood(navigation: NavigationGrid, size: Vector2i, start: Vector2i) -> int:
	var seen := {start: true}
	var queue: Array[Vector2i] = [start]
	while not queue.is_empty():
		var cell: Vector2i = queue.pop_back()
		for direction in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			var next: Vector2i = cell + direction
			if not seen.has(next) and navigation.is_walkable(next):
				seen[next] = true
				queue.append(next)
	return seen.size()
