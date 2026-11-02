class_name TerrainTiles
extends RefCounted
## Arte do terreno e transições (assets/tiles/terrain). Só lê PNGs; nunca toca na simulação.
##
## Folhas de chão (*_variants.png): cada variante é um bloco de 6 × 3 tiles (96×48) com as 16
## combinações de cantos da grade dupla: um terreno "de dentro" (sempre a grama padrão, ou as
## gramas da folha de grama) sobre um terreno "de fora". O desenho só existe para esses pares;
## os outros encontros usam a mesma silhueta da grama recortando o preenchimento do terreno
## de cima (borda genérica), então qualquer par de terrenos se conecta.
##
## Paredes de montanha (rock_walls.png): 13 materiais em blocos de 4 × 5 tiles; os 16 primeiros
## tiles seguem os vizinhos nas 4 direções e a última linha tem chão de caverna, sombra e entulho.

## Bits dos cantos de um tile da grade dupla. Cada canto é uma célula do mapa.
const TOP_LEFT := 1
const TOP_RIGHT := 2
const BOTTOM_LEFT := 4
const BOTTOM_RIGHT := 8
const FULL := 15

const TILE := 16
const BLOCK := Vector2i(6, 3)
## Máscara (cantos cobertos pelo terreno de dentro) → posição do tile no bloco da variante.
const MASK_TILES := {
	8: Vector2i(0, 0), 12: Vector2i(1, 0), 4: Vector2i(2, 0),
	10: Vector2i(0, 1), 15: Vector2i(1, 1), 5: Vector2i(2, 1),
	2: Vector2i(0, 2), 3: Vector2i(1, 2), 1: Vector2i(2, 2),
	7: Vector2i(3, 0), 11: Vector2i(4, 0), 13: Vector2i(3, 1), 14: Vector2i(4, 1),
	6: Vector2i(3, 2), 9: Vector2i(4, 2),
}
## Terreno de fora liso, e os dois preenchimentos com detalhe do terreno que varia na folha
## (na folha de grama, a grama de dentro; nas outras, o terreno de fora).
const OUTER_FILL := Vector2i(5, 1)
const DETAIL_FILLS: Array[Vector2i] = [Vector2i(5, 0), Vector2i(5, 2)]
const GRASS_SHEET := "grass_variants"

## Variantes de cada folha, na ordem das linhas. Os nomes seguem as camadas do .aseprite
## (grama e água não têm camadas nomeadas; os nomes vêm da cor).
const SHEETS := {
	"grass_variants": ["light_grass", "grass", "dark_grass", "olive_grass", "straw_grass",
		"teal_grass", "lush_grass", "burnt_grass", "frosted_grass", "withered_grass"],
	"dirt_variants": ["common_dirt", "dark_dirt", "fertile_soil", "barren_soil", "packed_dirt",
		"dry_dirt", "cracked_dirt", "damp_dirt", "soaked_dirt", "burnt_dirt"],
	"water_variants": ["shallow_water", "deep_water", "lake_water", "river_water", "murky_water",
		"swamp_water", "icy_water", "lagoon_water", "river_water_rocks", "lake_beach"],
	"sand_variants": ["light_sand", "yellow_sand", "dark_sand", "fine_sand", "packed_sand",
		"dunes", "wet_sand", "stony_sand"],
	"mud_swamp_variants": ["mud", "dark_mud", "deep_mud", "flooded_soil", "peat", "swamp_soil", "marsh_weeds"],
	"snow_ice_variants": ["light_snow", "snow", "deep_snow", "packed_snow", "melting_snow",
		"thin_ice", "thick_ice", "cracked_ice", "ice_over_water"],
	"stone_variants": ["smooth_stone", "rough_stone", "exposed_rock", "gravel", "cobbles",
		"dark_rock", "light_rock", "volcanic_rock"],
	"special_variants": ["moss", "dark_moss", "fungal_soil", "volcanic_soil", "ash",
		"radioactive_soil", "crystallized_soil", "underground_soil"],
}
## Variante da folha de grama que é a grama de dentro de todas as outras folhas.
const STANDARD_GRASS := 1
## Terra que fica embaixo das gramas da folha de grama (igual a dirt_variants 0).
const COMMON_DIRT := ["dirt_variants", 0]

const WALLS := "rock_walls"
const WALL_MATERIALS: Array[String] = ["granite", "limestone", "marble", "sandstone", "schist", "basalt",
	"volcanic_rock", "natural_wall", "worn_wall", "cracked_wall", "mossy_wall", "crystal_wall", "frozen_wall"]
const WALL_BLOCK := Vector2i(4, 5)
const WALL_BLOCKS_PER_ROW := 4
## Última linha do bloco de parede: chão de caverna (2), sombra embaixo da face e entulho.
const WALL_SHADOW := Vector2i(2, 4)

## Arte de cada tipo de terreno do mapa: [folha, variante]. Rocha tem chão de terra embaixo da parede.
const KIND_ART := {
	Terrain.Kind.GRASS: ["grass_variants", STANDARD_GRASS],
	Terrain.Kind.DIRT: COMMON_DIRT,
	Terrain.Kind.TALL_GRASS: ["grass_variants", 2],
	Terrain.Kind.SHALLOW_WATER: ["water_variants", 3],
	Terrain.Kind.DEEP_WATER: ["water_variants", 1],
	Terrain.Kind.ROCK: COMMON_DIRT,
}
const WALL_MATERIAL := 7
## Ordem de desenho do chão, de baixo para cima: a borda de cada terreno cobre os de baixo.
const GROUND_ORDER: Array[int] = [Terrain.Kind.DEEP_WATER, Terrain.Kind.SHALLOW_WATER, Terrain.Kind.DIRT,
	Terrain.Kind.GRASS, Terrain.Kind.TALL_GRASS]
## Um preenchimento com detalhe a cada tantos tiles cheios, em média, para cada um dos dois.
const DETAIL_ONE_IN := 12

## Colunas de cada faixa do atlas gerado: 0–15 pela máscara (15 = preenchimento liso), 16–17 detalhes.
const STRIP_COLUMNS := 18

## Faixa do atlas: chave → linha. Chaves: "kind:N" (borda genérica) e "pair:N:M" (par desenhado).
var strips := {}
var atlas: Image


## Chão de cada célula: rocha conta como a terra que fica embaixo dela.
static func ground_kind(kind: int) -> int:
	return Terrain.Kind.DIRT if kind == Terrain.Kind.ROCK else kind


static func rank(kind: int) -> int:
	return GROUND_ORDER.find(ground_kind(kind))


## Bloco de uma variante na folha, em tiles.
static func block_origin(variant: int) -> Vector2i:
	return Vector2i(0, variant * BLOCK.y)


## Variante cuja transição desenhada tem `upper` por cima de `lower`, ou [] se não houver.
static func drawn_pair(upper: int, lower: int) -> Array:
	var top: Array = KIND_ART[ground_kind(upper)]
	var bottom: Array = KIND_ART[ground_kind(lower)]
	if top[0] != GRASS_SHEET or bottom[0] == GRASS_SHEET:
		return []
	if top[1] == STANDARD_GRASS:
		return bottom
	if bottom == COMMON_DIRT:
		return top
	return []


## Tile da parede pelos vizinhos que também são rocha (N, L, S, O).
static func wall_tile(north: bool, east: bool, south: bool, west: bool, material := WALL_MATERIAL) -> Vector2i:
	var origin := Vector2i((material % WALL_BLOCKS_PER_ROW) * WALL_BLOCK.x, (material / WALL_BLOCKS_PER_ROW) * WALL_BLOCK.y)
	return origin + Vector2i(int(north) + 2 * int(east), int(south) + 2 * int(west))


static func wall_shadow(material := WALL_MATERIAL) -> Vector2i:
	return wall_tile(false, false, false, false, material) + WALL_SHADOW


## Folha como Image RGBA8.
static func sheet_image(sheet: String) -> Image:
	var image := AssetCatalog.texture("tiles/terrain/" + sheet).get_image()
	if image.is_compressed():
		image.decompress()
	image.convert(Image.FORMAT_RGBA8)
	return image


## Monta o atlas: uma faixa de borda genérica por tipo de chão e uma por par desenhado.
func build() -> void:
	var images := {}
	for sheet in SHEETS:
		images[sheet] = sheet_image(sheet)
	var keys: Array[String] = []
	for kind in GROUND_ORDER:
		keys.append("kind:%d" % kind)
	for upper in GROUND_ORDER:
		for lower in GROUND_ORDER:
			if rank(lower) < rank(upper) and not drawn_pair(upper, lower).is_empty():
				keys.append("pair:%d:%d" % [upper, lower])
	atlas = Image.create_empty(STRIP_COLUMNS * TILE, keys.size() * TILE, false, Image.FORMAT_RGBA8)
	for row in keys.size():
		strips[keys[row]] = row
		var parts := keys[row].split(":")
		if parts[0] == "kind":
			_paint_kind_strip(images, int(parts[1]), row)
		else:
			_paint_pair_strip(images, drawn_pair(int(parts[1]), int(parts[2])), row)


## Tile do atlas para o terreno `kind` nos cantos `mask`, com `below` como o terreno mais alto
## embaixo da borda (-1 se não houver). `variation` escolhe os preenchimentos com detalhe.
func tile_for(kind: int, below: int, mask: int, variation: int) -> Vector2i:
	if mask == FULL:
		var pick := variation % DETAIL_ONE_IN
		return Vector2i(16 + pick if pick < DETAIL_FILLS.size() else FULL, int(strips["kind:%d" % kind]))
	var pair_key := "pair:%d:%d" % [kind, below]
	return Vector2i(mask, int(strips.get(pair_key, strips["kind:%d" % kind])))


## Recorte 16×16 de uma folha, em tiles do bloco da variante.
static func _tile(image: Image, variant: int, at: Vector2i) -> Image:
	var origin := (block_origin(variant) + at) * TILE
	return image.get_region(Rect2i(origin, Vector2i(TILE, TILE)))


## Preenchimento liso do terreno: o de dentro na folha de grama, o de fora nas outras.
static func _fill(images: Dictionary, art: Array) -> Image:
	var at: Vector2i = MASK_TILES[FULL] if art[0] == GRASS_SHEET else OUTER_FILL
	return _tile(images[art[0]], art[1], at)


## Borda desenhada à mão: o tile da folha, com o terreno de fora transparente.
func _paint_pair_strip(images: Dictionary, art: Array, row: int) -> void:
	var image: Image = images[art[0]]
	var outer := _tile(image, art[1], OUTER_FILL)
	for mask in MASK_TILES:
		if mask == FULL:
			continue
		var source := _tile(image, art[1], MASK_TILES[mask])
		for y in TILE:
			for x in TILE:
				var pixel := source.get_pixel(x, y)
				if pixel != outer.get_pixel(x, y):
					atlas.set_pixel(mask * TILE + x, row * TILE + y, pixel)


## Borda genérica: a silhueta da grama sobre a terra comum recorta o preenchimento do terreno.
## Os pixels de contorno da grama viram o preenchimento escurecido na mesma proporção.
func _paint_kind_strip(images: Dictionary, kind: int, row: int) -> void:
	var art: Array = KIND_ART[kind]
	var fill := _fill(images, art)
	var reference: Image = images[COMMON_DIRT[0]]
	var inner := _tile(reference, COMMON_DIRT[1], MASK_TILES[FULL])
	var outer := _tile(reference, COMMON_DIRT[1], OUTER_FILL)
	for mask in MASK_TILES:
		var source := _tile(reference, COMMON_DIRT[1], MASK_TILES[mask])
		for y in TILE:
			for x in TILE:
				var pixel := source.get_pixel(x, y)
				var color := Color.TRANSPARENT
				if mask == FULL or pixel == inner.get_pixel(x, y):
					color = fill.get_pixel(x, y)
				elif pixel != outer.get_pixel(x, y):
					var shade := clampf(pixel.get_luminance() / maxf(inner.get_pixel(x, y).get_luminance(), 0.05), 0.35, 1.25)
					var base := fill.get_pixel(x, y)
					color = Color(base.r * shade, base.g * shade, base.b * shade, 1.0)
				atlas.set_pixel(mask * TILE + x, row * TILE + y, color)
	var image: Image = images[art[0]]
	for index in DETAIL_FILLS.size():
		atlas.blit_rect(_tile(image, art[1], DETAIL_FILLS[index]), Rect2i(0, 0, TILE, TILE),
			Vector2i((16 + index) * TILE, row * TILE))
