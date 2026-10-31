class_name WorldGenerator
extends RefCounted
## Gera o terreno a partir da seed. Mesma seed e mesmo tamanho produzem exatamente o mesmo mapa.
## Ordem: base por ruído, depois rio (que corta de cima a baixo) e por fim uma pequena montanha.


static func generate(world_seed: int, size: Vector2i) -> WorldData:
	var world := WorldData.new(size)
	var rng := RandomNumberGenerator.new()
	rng.seed = world_seed
	var noise := FastNoiseLite.new()
	noise.seed = world_seed
	noise.frequency = Balance.TERRAIN_NOISE_FREQUENCY

	_fill_base(world, noise)
	_carve_river(world, rng)
	_raise_mountain(world, rng, noise)
	return world


static func _fill_base(world: WorldData, noise: FastNoiseLite) -> void:
	for y in world.size.y:
		for x in world.size.x:
			var value := noise.get_noise_2d(x, y)
			var kind := Terrain.Kind.GRASS
			if value > Balance.TALL_GRASS_NOISE_THRESHOLD:
				kind = Terrain.Kind.TALL_GRASS
			elif value < Balance.DIRT_NOISE_THRESHOLD:
				kind = Terrain.Kind.DIRT
			world.set_terrain(Vector2i(x, y), kind)


## Rio vertical: começa perto do centro no topo e serpenteia até a base.
## Em alguns trechos (vaus) o leito é todo raso, para o mapa não ficar dividido.
static func _carve_river(world: WorldData, rng: RandomNumberGenerator) -> void:
	var ford_rows := {}
	var segment := world.size.y / Balance.RIVER_FORD_COUNT
	for index in Balance.RIVER_FORD_COUNT:
		var start := rng.randi_range(index * segment, (index + 1) * segment - Balance.RIVER_FORD_LENGTH)
		for row in range(start, start + Balance.RIVER_FORD_LENGTH):
			ford_rows[row] = true

	var center_x := rng.randi_range(world.size.x / 4, world.size.x * 3 / 4)
	for y in world.size.y:
		center_x = clampi(center_x + rng.randi_range(-1, 1), 0, world.size.x - 1)
		for offset in range(-Balance.RIVER_HALF_WIDTH, Balance.RIVER_HALF_WIDTH + 1):
			var cell := Vector2i(center_x + offset, y)
			if not world.contains(cell):
				continue
			var is_core := absi(offset) <= Balance.RIVER_CORE_HALF_WIDTH and not ford_rows.has(y)
			world.set_terrain(cell, Terrain.Kind.DEEP_WATER if is_core else Terrain.Kind.SHALLOW_WATER)


## Montanha: um bloco de rocha com borda irregular. Nunca substitui água.
static func _raise_mountain(world: WorldData, rng: RandomNumberGenerator, noise: FastNoiseLite) -> void:
	var center := Vector2i(
		rng.randi_range(world.size.x / 8, world.size.x * 3 / 8),
		rng.randi_range(world.size.y / 8, world.size.y / 3),
	)
	var radius := rng.randi_range(Balance.MOUNTAIN_MIN_RADIUS, Balance.MOUNTAIN_MAX_RADIUS)
	for y in range(center.y - radius - 1, center.y + radius + 2):
		for x in range(center.x - radius - 1, center.x + radius + 2):
			var cell := Vector2i(x, y)
			if not world.contains(cell) or _is_water(world.get_terrain(cell)):
				continue
			var jitter := noise.get_noise_2d(x + 1000, y + 1000) * radius * 0.3
			if Vector2(cell).distance_to(Vector2(center)) < radius + jitter:
				world.set_terrain(cell, Terrain.Kind.ROCK)


static func _is_water(kind: int) -> bool:
	return kind == Terrain.Kind.SHALLOW_WATER or kind == Terrain.Kind.DEEP_WATER
