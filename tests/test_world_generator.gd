class_name TestWorldGenerator
extends TestCase
## Geração do mapa: tamanho, validade dos tiles, reprodutibilidade por seed e presença de rio e montanha.


func test_map_has_expected_size() -> void:
	var world := WorldGenerator.generate(42, Balance.MAP_SIZE)
	expect_equal(world.size, Vector2i(128, 128), "O mapa local deve ter 128×128 tiles")


func test_same_seed_produces_same_map() -> void:
	var first := WorldGenerator.generate(42, Balance.MAP_SIZE)
	var second := WorldGenerator.generate(42, Balance.MAP_SIZE)
	expect_equal(first.fingerprint(), second.fingerprint(), "A mesma seed deve gerar exatamente o mesmo mapa")


func test_different_seed_produces_different_map() -> void:
	var first := WorldGenerator.generate(42, Balance.MAP_SIZE)
	var second := WorldGenerator.generate(43, Balance.MAP_SIZE)
	expect(first.fingerprint() != second.fingerprint(), "Seeds diferentes devem gerar mapas diferentes")


func test_every_cell_holds_a_valid_terrain() -> void:
	var world := WorldGenerator.generate(7, Balance.MAP_SIZE)
	var invalid := 0
	for y in world.size.y:
		for x in world.size.x:
			if not Terrain.is_valid(world.get_terrain(Vector2i(x, y))):
				invalid += 1
	expect_equal(invalid, 0, "Nenhuma célula pode ter terreno inválido")


func test_river_reaches_top_and_bottom_edges() -> void:
	for world_seed in [1, 2, 3, 4, 5]:
		var world := WorldGenerator.generate(world_seed, Balance.MAP_SIZE)
		var top_has_water := _row_has_water(world, 0)
		var bottom_has_water := _row_has_water(world, world.size.y - 1)
		expect(top_has_water and bottom_has_water, "Seed %d: o rio deve atravessar o mapa de cima a baixo" % world_seed)


func test_mountain_of_rock_is_present() -> void:
	for world_seed in [1, 2, 3, 4, 5]:
		var world := WorldGenerator.generate(world_seed, Balance.MAP_SIZE)
		expect(_count(world, Terrain.Kind.ROCK) > 0, "Seed %d: deve existir uma montanha de rocha" % world_seed)


func _row_has_water(world: WorldData, row: int) -> bool:
	for x in world.size.x:
		var kind := world.get_terrain(Vector2i(x, row))
		if kind == Terrain.Kind.SHALLOW_WATER or kind == Terrain.Kind.DEEP_WATER:
			return true
	return false


func _count(world: WorldData, kind: int) -> int:
	var total := 0
	for y in world.size.y:
		for x in world.size.x:
			if world.get_terrain(Vector2i(x, y)) == kind:
				total += 1
	return total
