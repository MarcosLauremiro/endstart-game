class_name WorldView
extends TileMapLayer
## Desenha a grade de terreno em uma TileMapLayer. Só lê WorldData; nunca altera a simulação.
## Cada tipo de terreno usa o PNG do AssetCatalog como uma fonte do TileSet (id da fonte = tipo).

const TERRAIN_ASSETS := {
	Terrain.Kind.GRASS: "tiles/terrain/grass",
	Terrain.Kind.DIRT: "tiles/terrain/dirt",
	Terrain.Kind.TALL_GRASS: "tiles/terrain/tall_grass",
	Terrain.Kind.SHALLOW_WATER: "tiles/terrain/shallow_water",
	Terrain.Kind.DEEP_WATER: "tiles/terrain/deep_water",
	Terrain.Kind.ROCK: "tiles/terrain/rock",
}


func _ready() -> void:
	tile_set = _build_tile_set()


func show_world(world: WorldData) -> void:
	clear()
	for y in world.size.y:
		for x in world.size.x:
			var cell := Vector2i(x, y)
			set_cell(cell, world.get_terrain(cell), Vector2i.ZERO)


func _build_tile_set() -> TileSet:
	var tile_size := Vector2i(Balance.TILE_SIZE, Balance.TILE_SIZE)
	var result := TileSet.new()
	result.tile_size = tile_size
	for kind in Terrain.Kind.size():
		var source := TileSetAtlasSource.new()
		source.texture = AssetCatalog.texture(TERRAIN_ASSETS[kind])
		source.texture_region_size = tile_size
		source.create_tile(Vector2i.ZERO)
		result.add_source(source, kind)
	return result
