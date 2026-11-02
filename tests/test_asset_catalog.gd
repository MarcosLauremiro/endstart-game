class_name TestAssetCatalog
extends TestCase
## Catálogo de arte: cada asset existe em disco com o tamanho esperado, e todo terreno tem tile.
## Se você trocar uma arte por outra de tamanho diferente, este teste aponta qual.


func test_every_asset_file_exists() -> void:
	for id in AssetCatalog.ENTRIES:
		expect(ResourceLoader.exists(AssetCatalog.path_of(id)), "Arquivo ausente: %s" % AssetCatalog.path_of(id))


func test_every_asset_has_expected_size() -> void:
	for id in AssetCatalog.ENTRIES:
		var path := AssetCatalog.path_of(id)
		if not ResourceLoader.exists(path):
			continue
		var texture: Texture2D = load(path)
		var actual := Vector2i(texture.get_width(), texture.get_height())
		expect_equal(actual, AssetCatalog.expected_size(id), "Tamanho de %s" % path)


func test_sprite_sheets_split_into_whole_frames() -> void:
	for id in AssetCatalog.ENTRIES:
		var size := AssetCatalog.expected_size(id)
		var grid := AssetCatalog.frame_grid(id)
		expect(size.x % grid.x == 0 and size.y % grid.y == 0, "%s: %s não divide em %s quadros" % [id, size, grid])


func test_every_terrain_kind_has_a_tile() -> void:
	for kind in Terrain.Kind.size():
		var art: Array = TerrainTiles.KIND_ART.get(kind, [])
		expect(not art.is_empty() and AssetCatalog.ENTRIES.has("tiles/terrain/" + art[0]),
			"Terreno %s sem arte no catálogo" % Terrain.display_name(kind))


func test_placeholder_matches_catalog_size() -> void:
	for id in AssetCatalog.ENTRIES:
		var image := PlaceholderPainter.paint(AssetCatalog.ENTRIES[id])
		expect_equal(image.get_size(), AssetCatalog.expected_size(id), "Provisório de %s" % id)
