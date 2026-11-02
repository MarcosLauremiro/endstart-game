class_name TestTerrainTiles
extends TestCase
## Arte do terreno (TerrainTiles e WorldView): as folhas seguem o bloco de 6×3 da grade dupla,
## o atlas tem borda para todo terreno, cada vértice desenha o terreno de baixo inteiro e só a
## borda dos de cima, as paredes seguem os vizinhos e a rocha escavada é redesenhada.

const _CORNER_PIXELS: Array[Vector2i] = [Vector2i(0, 0), Vector2i(15, 0), Vector2i(0, 15), Vector2i(15, 15)]


func test_sheets_follow_the_dual_grid_block() -> void:
	var used := {}
	for kind in TerrainTiles.KIND_ART:
		used[TerrainTiles.KIND_ART[kind]] = true
	for sheet in TerrainTiles.SHEETS:
		var image := TerrainTiles.sheet_image(sheet)
		var variants: Array = TerrainTiles.SHEETS[sheet]
		expect_equal(image.get_height(), variants.size() * TerrainTiles.BLOCK.y * TerrainTiles.TILE, "%s: uma variante por bloco de 48 px" % sheet)
		for variant in variants.size():
			var inner := _tile(image, variant, TerrainTiles.MASK_TILES[TerrainTiles.FULL])
			var outer := _tile(image, variant, TerrainTiles.OUTER_FILL)
			# Canto fora da máscara é sempre o terreno de fora (sem costura); dentro, o de dentro
			# (cobrado só nas variantes em uso: a grama viçosa tem um brilho de 1 pixel no canto).
			var strict := used.has([sheet, variant])
			for mask in TerrainTiles.MASK_TILES:
				var tile := _tile(image, variant, TerrainTiles.MASK_TILES[mask])
				for index in _CORNER_PIXELS.size():
					var at := _CORNER_PIXELS[index]
					var covered: bool = (mask >> index) & 1 == 1
					if not covered and tile.get_pixel(at.x, at.y) != outer.get_pixel(at.x, at.y):
						failures.append("%s %s máscara %d: canto %d devia ser o terreno de fora" % [sheet, variants[variant], mask, index])
					if covered and strict and tile.get_pixel(at.x, at.y) != inner.get_pixel(at.x, at.y):
						failures.append("%s %s máscara %d: canto %d devia ser o terreno de dentro" % [sheet, variants[variant], mask, index])


func test_pairs_drawn_by_hand() -> void:
	expect_equal(TerrainTiles.drawn_pair(Terrain.Kind.GRASS, Terrain.Kind.DIRT), TerrainTiles.COMMON_DIRT, "Grama sobre terra")
	expect_equal(TerrainTiles.drawn_pair(Terrain.Kind.GRASS, Terrain.Kind.SHALLOW_WATER), ["water_variants", 3], "Grama sobre água rasa")
	expect_equal(TerrainTiles.drawn_pair(Terrain.Kind.TALL_GRASS, Terrain.Kind.DIRT), ["grass_variants", 2], "Grama alta sobre terra")
	expect(TerrainTiles.drawn_pair(Terrain.Kind.TALL_GRASS, Terrain.Kind.GRASS).is_empty(), "Grama sobre grama não tem desenho")
	expect(TerrainTiles.drawn_pair(Terrain.Kind.DIRT, Terrain.Kind.SHALLOW_WATER).is_empty(), "Terra sobre água não tem desenho")
	expect_equal(TerrainTiles.drawn_pair(Terrain.Kind.GRASS, Terrain.Kind.ROCK), TerrainTiles.COMMON_DIRT, "Embaixo da rocha é terra")


func test_atlas_has_every_edge() -> void:
	var tiles := WorldView.tiles()
	for kind in TerrainTiles.GROUND_ORDER:
		for mask in range(1, 16):
			var at := tiles.tile_for(kind, -1, mask, 5)
			var region := tiles.atlas.get_region(Rect2i(at * TerrainTiles.TILE, Vector2i(16, 16)))
			for index in _CORNER_PIXELS.size():
				var pixel := _CORNER_PIXELS[index]
				var alpha := region.get_pixel(pixel.x, pixel.y).a
				if ((mask >> index) & 1 == 1) != (alpha == 1.0):
					failures.append("%s máscara %d canto %d: alfa %.1f" % [Terrain.display_name(kind), mask, index, alpha])
	var drawn := tiles.tile_for(Terrain.Kind.GRASS, Terrain.Kind.SHALLOW_WATER, 3, 0)
	expect(drawn.y != tiles.tile_for(Terrain.Kind.GRASS, -1, 3, 0).y or drawn != tiles.tile_for(Terrain.Kind.GRASS, Terrain.Kind.DIRT, 3, 0),
		"Grama sobre água usa a margem desenhada, não a de terra")
	var fills := {}
	for vertex in 200:
		fills[tiles.tile_for(Terrain.Kind.GRASS, -1, TerrainTiles.FULL, vertex).x] = true
	expect_equal(fills.size(), 3, "Preenchimento liso e os dois com detalhe aparecem")


func test_vertex_fills_the_lowest_and_edges_the_rest() -> void:
	var world := _flat_world(Terrain.Kind.GRASS)
	world.set_terrain(Vector2i(2, 2), Terrain.Kind.SHALLOW_WATER)
	var view := WorldView.new()
	view.show_world(world)
	var water := view.ground_layer(Terrain.Kind.SHALLOW_WATER)
	var grass := view.ground_layer(Terrain.Kind.GRASS)
	# Vértice (3, 3): canto de cima à esquerda é a água; os outros três, grama.
	expect_equal(water.get_cell_atlas_coords(Vector2i(3, 3)).x in [15, 16, 17], true, "Água embaixo, inteira")
	var tiles := WorldView.tiles()
	expect_equal(grass.get_cell_atlas_coords(Vector2i(3, 3)), tiles.tile_for(Terrain.Kind.GRASS, Terrain.Kind.SHALLOW_WATER,
		TerrainTiles.TOP_RIGHT | TerrainTiles.BOTTOM_LEFT | TerrainTiles.BOTTOM_RIGHT, 0), "Grama por cima, com o canto da água aberto")
	expect_equal(water.get_cell_source_id(Vector2i(0, 0)), -1, "Longe da água, a camada da água fica vazia")
	expect_equal(grass.get_used_cells().size(), 6 * 6, "Grama em todos os vértices (5×5 células → 6×6)")
	view.free()


func test_walls_follow_neighbors_and_mining_redraws() -> void:
	var world := _flat_world(Terrain.Kind.GRASS)
	for cell in [Vector2i(1, 1), Vector2i(2, 1), Vector2i(1, 2), Vector2i(2, 2)]:
		world.set_terrain(cell, Terrain.Kind.ROCK)
	var view := WorldView.new()
	view.show_world(world)
	var walls := view.wall_layer()
	expect_equal(walls.get_cell_atlas_coords(Vector2i(1, 1)), TerrainTiles.wall_tile(false, true, true, false), "Canto de cima à esquerda")
	expect_equal(walls.get_cell_atlas_coords(Vector2i(2, 2)), TerrainTiles.wall_tile(true, false, false, true), "Canto de baixo à direita")
	expect_equal(view.shadow_layer().get_cell_atlas_coords(Vector2i(1, 3)), TerrainTiles.wall_shadow(), "Sombra embaixo da face")
	expect_equal(view.ground_layer(Terrain.Kind.DIRT).get_cell_source_id(Vector2i(2, 2)), 0, "Terra embaixo da rocha")
	world.set_terrain(Vector2i(2, 2), Terrain.Kind.DIRT)
	view.sync(world)
	expect_equal(walls.get_cell_source_id(Vector2i(2, 2)), -1, "Rocha escavada some")
	expect_equal(walls.get_cell_atlas_coords(Vector2i(2, 1)), TerrainTiles.wall_tile(false, false, false, true), "A vizinha perde a ligação")
	expect_equal(view.shadow_layer().get_cell_atlas_coords(Vector2i(2, 2)), TerrainTiles.wall_shadow(), "A face nova faz sombra")
	var edge := _flat_world(Terrain.Kind.ROCK)
	view.show_world(edge)
	expect_equal(walls.get_cell_atlas_coords(Vector2i.ZERO), TerrainTiles.wall_tile(true, true, true, true), "A rocha continua além da borda")
	view.free()


func test_real_map_draws_fast() -> void:
	var simulation := Simulation.new(12345, 1)
	var view := WorldView.new()
	var start := Time.get_ticks_msec()
	view.show_world(simulation.world)
	var elapsed := Time.get_ticks_msec() - start
	expect(elapsed < 2000, "Mapa 128×128 desenhado em %d ms" % elapsed)
	var unchanged := Time.get_ticks_usec()
	view.sync(simulation.world)
	expect(Time.get_ticks_usec() - unchanged < 1000, "Sem mudança, sync não refaz nada")
	view.free()


static func _tile(image: Image, variant: int, at: Vector2i) -> Image:
	return image.get_region(Rect2i((TerrainTiles.block_origin(variant) + at) * TerrainTiles.TILE, Vector2i(16, 16)))


static func _flat_world(kind: int) -> WorldData:
	var world := WorldData.new(Vector2i(5, 5))
	for y in 5:
		for x in 5:
			world.set_terrain(Vector2i(x, y), kind)
	return world
