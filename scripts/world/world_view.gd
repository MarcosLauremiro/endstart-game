class_name WorldView
extends Node2D
## Desenha o terreno. Só lê WorldData; nunca altera a simulação.
##
## Chão em grade dupla (TerrainTiles): cada tile fica deslocado meio tile e seus 4 cantos são
## 4 células do mapa. Uma TileMapLayer por tipo de chão, de baixo para cima em GROUND_ORDER:
## o terreno mais baixo do tile é preenchido inteiro e cada um acima desenha só a sua borda.
## Por cima, as paredes de montanha (uma por célula de rocha, pelos 4 vizinhos) e a sombra
## que a face da parede deixa no chão logo abaixo.

const _CORNERS: Array[Vector2i] = [Vector2i(-1, -1), Vector2i(0, -1), Vector2i(-1, 0), Vector2i(0, 0)]
const _GROUND_SOURCE := 0
const _WALL_SOURCE := 1

## Atlas montado uma vez só (as folhas não mudam durante o jogo).
static var _tiles: TerrainTiles
static var _tile_set: TileSet

var _world: WorldData
## Cópia do terreno já desenhado, para redesenhar só o que mudou.
var _drawn := PackedByteArray()
var _drawn_revision := -1
## Terrain.Kind → TileMapLayer
var _ground := {}
var _shadows: TileMapLayer
var _walls: TileMapLayer


func _init() -> void:
	var tile_set := shared_tile_set()
	for kind in TerrainTiles.GROUND_ORDER:
		_ground[kind] = _add_layer("Ground%d" % kind, tile_set, Vector2(-Balance.TILE_SIZE / 2.0, -Balance.TILE_SIZE / 2.0))
	_shadows = _add_layer("Shadows", tile_set, Vector2.ZERO)
	_walls = _add_layer("Walls", tile_set, Vector2.ZERO)


static func tiles() -> TerrainTiles:
	if _tiles == null:
		_tiles = TerrainTiles.new()
		_tiles.build()
	return _tiles


static func shared_tile_set() -> TileSet:
	if _tile_set:
		return _tile_set
	var tile_size := Vector2i(Balance.TILE_SIZE, Balance.TILE_SIZE)
	_tile_set = TileSet.new()
	_tile_set.tile_size = tile_size
	var ground := TileSetAtlasSource.new()
	ground.texture = ImageTexture.create_from_image(tiles().atlas)
	ground.texture_region_size = tile_size
	_tile_set.add_source(ground, _GROUND_SOURCE)
	var walls := TileSetAtlasSource.new()
	walls.texture = AssetCatalog.texture("tiles/terrain/" + TerrainTiles.WALLS)
	walls.texture_region_size = tile_size
	_tile_set.add_source(walls, _WALL_SOURCE)
	for source in [ground, walls] as Array[TileSetAtlasSource]:
		var grid := source.get_atlas_grid_size()
		for y in grid.y:
			for x in grid.x:
				source.create_tile(Vector2i(x, y))
	return _tile_set


func show_world(world: WorldData) -> void:
	_world = world
	_drawn = world.cells().duplicate()
	_drawn_revision = world.revision
	for layer in _layers():
		layer.clear()
	for y in world.size.y + 1:
		for x in world.size.x + 1:
			_draw_vertex(Vector2i(x, y))
	for y in world.size.y:
		for x in world.size.x:
			_draw_wall(Vector2i(x, y))


## Redesenha as células que mudaram desde o último desenho (ex.: rocha escavada).
func sync(world: WorldData) -> void:
	if world != _world:
		show_world(world)
		return
	if world.revision == _drawn_revision:
		return
	_drawn_revision = world.revision
	var cells := world.cells()
	for index in cells.size():
		if cells[index] == _drawn[index]:
			continue
		_drawn[index] = cells[index]
		var cell := Vector2i(index % world.size.x, index / world.size.x)
		for offset in _CORNERS:
			_draw_vertex(cell - offset)
		for y in range(-1, 2):
			for x in range(-1, 2):
				_draw_wall(cell + Vector2i(x, y))


## Camada de chão de um tipo de terreno (testes e depuração).
func ground_layer(kind: int) -> TileMapLayer:
	return _ground[kind]


func wall_layer() -> TileMapLayer:
	return _walls


func shadow_layer() -> TileMapLayer:
	return _shadows


## Tile da grade dupla no vértice `vertex`: os cantos são as 4 células em volta.
func _draw_vertex(vertex: Vector2i) -> void:
	var corners: Array[int] = []
	for offset in _CORNERS:
		corners.append(TerrainTiles.ground_kind(_terrain(vertex + offset)))
	var variation := _variation(vertex)
	for kind in TerrainTiles.GROUND_ORDER:
		var layer: TileMapLayer = _ground[kind]
		if not corners.has(kind):
			layer.erase_cell(vertex)
			continue
		var level := TerrainTiles.rank(kind)
		var mask := 0
		var below := -1
		for index in corners.size():
			var corner_rank := TerrainTiles.rank(corners[index])
			if corner_rank >= level:
				mask |= 1 << index
			elif below == -1 or corner_rank > TerrainTiles.rank(below):
				below = corners[index]
		layer.set_cell(vertex, _GROUND_SOURCE, tiles().tile_for(kind, below, mask, variation))


func _draw_wall(cell: Vector2i) -> void:
	if not _world.contains(cell):
		return
	if not _is_rock(cell):
		_walls.erase_cell(cell)
		if _is_rock(cell + Vector2i.UP):
			_shadows.set_cell(cell, _WALL_SOURCE, TerrainTiles.wall_shadow())
		else:
			_shadows.erase_cell(cell)
		return
	_shadows.erase_cell(cell)
	_walls.set_cell(cell, _WALL_SOURCE, TerrainTiles.wall_tile(_is_rock(cell + Vector2i.UP), _is_rock(cell + Vector2i.RIGHT),
		_is_rock(cell + Vector2i.DOWN), _is_rock(cell + Vector2i.LEFT)))


## Terreno da célula; fora do mapa vale a célula mais próxima da borda.
func _terrain(cell: Vector2i) -> int:
	return _world.get_terrain(cell.clamp(Vector2i.ZERO, _world.size - Vector2i.ONE))


## A rocha continua além da borda do mapa.
func _is_rock(cell: Vector2i) -> bool:
	return _terrain(cell) == Terrain.Kind.ROCK


## Número estável por vértice para sortear os preenchimentos com detalhe.
static func _variation(vertex: Vector2i) -> int:
	return absi(hash(vertex))


func _layers() -> Array[TileMapLayer]:
	var result: Array[TileMapLayer] = []
	for kind in TerrainTiles.GROUND_ORDER:
		result.append(_ground[kind])
	result.append(_shadows)
	result.append(_walls)
	return result


func _add_layer(layer_name: String, tile_set: TileSet, offset: Vector2) -> TileMapLayer:
	var layer := TileMapLayer.new()
	layer.name = layer_name
	layer.tile_set = tile_set
	layer.position = offset
	add_child(layer)
	return layer
