class_name ColonistLooks
extends RefCounted
## Aparência dos colonos montada em camadas a partir das folhas em assets/characters/colonists
## (fonte .aseprite; PNG exportado por tools/export_characters.sh):
## - character_base.png: corpo branco de contorno preto, quadros de 16×24. Linha 0: parado de
##   frente (1 quadro); linhas 1 a 4: caminhada de 8 quadros de frente, de costas, para a esquerda
##   e para a direita.
## - hair.png (20 estilos) e clothing.png (4 peças de cima e 3 de baixo): uma linha por estilo ou
##   peça, com os mesmos 33 quadros em sequência (parado de frente e as 4 caminhadas). Assim o
##   mesmo quadro da base vale para todas as camadas, e elas nunca desalinham.
## A pele é a cor que tinge o branco da base; cabelo e roupa trocam a rampa indexada de 4 cores
## desenhada na folha (shaders/palette_swap.gdshader). O gerador escolhe o cabelo pela idade.

enum Facing { FRONT, BACK, LEFT, RIGHT }

const BASE_SHEET := "characters/colonists/character_base"
const HAIR_SHEET := "characters/colonists/hair"
const CLOTHING_SHEET := "characters/colonists/clothing"
const FRAME_SIZE := Vector2i(16, 24)
const WALK_FRAMES := 8
## Ticks por quadro da caminhada: 10 quadros por segundo na velocidade normal.
const WALK_TICKS_PER_FRAME := 6

## Tons de pele, do mais claro ao mais escuro (tingem o branco da base).
const SKIN_TONES: Array[Color] = [
	Color("f6dcc4"), Color("eac09c"), Color("d6a079"), Color("b98057"),
	Color("96603d"), Color("6e4329"), Color("4f2e1c"),
]

## Rampa de 4 cores desenhada nas folhas (do escuro ao claro); é ela que o shader troca.
const HAIR_SOURCE_RAMP: Array[Color] = [Color("2b1810"), Color("5c341e"), Color("915832"), Color("c9905c")]
const CLOTHING_SOURCE_RAMP: Array[Color] = [Color("1f2a3a"), Color("3a5070"), Color("5f7fa6"), Color("9db6d3")]

## Cores de cabelo: nome e rampa do escuro ao claro. Grisalho e branco ficam para os mais velhos.
const HAIR_COLORS: Array[Dictionary] = [
	{"name": "preto", "ramp": [Color("0f0d0e"), Color("1f1a1c"), Color("35302f"), Color("4f4846")]},
	{"name": "castanho-escuro", "ramp": [Color("1e120c"), Color("3d2617"), Color("5c3a22"), Color("7d5332")]},
	{"name": "castanho", "ramp": [Color("2b1810"), Color("5c341e"), Color("915832"), Color("c9905c")]},
	{"name": "loiro", "ramp": [Color("6b4e1e"), Color("a07a32"), Color("d1ad52"), Color("f2dc8c")]},
	{"name": "ruivo", "ramp": [Color("4a1c0e"), Color("8a3418"), Color("c25a26"), Color("e88c48")]},
	{"name": "grisalho", "ramp": [Color("3a3a3e"), Color("66666b"), Color("9a9aa0"), Color("c8c8cc")]},
	{"name": "branco", "ramp": [Color("6e6e74"), Color("a8a8ae"), Color("d6d6da"), Color("f4f4f6")]},
]
const GRAY := 5
const WHITE := 6
## Cores naturais (não grisalhas) e o peso de cada uma no sorteio.
const NATURAL_HAIR_WEIGHTS := {0: 3, 1: 3, 2: 3, 3: 2, 4: 1}

## Estilos de cabelo na ordem das linhas de hair.png, com a faixa de idade em que combinam.
const HAIR_STYLES: Array[Dictionary] = [
	{"name": "Curto crespo", "min_age": 16, "max_age": 70},
	{"name": "Curto liso", "min_age": 16, "max_age": 70},
	{"name": "Espetado", "min_age": 16, "max_age": 35},
	{"name": "Moicano", "min_age": 16, "max_age": 30},
	{"name": "Repartido", "min_age": 16, "max_age": 70},
	{"name": "Tigela", "min_age": 16, "max_age": 30},
	{"name": "Chanel", "min_age": 16, "max_age": 70},
	{"name": "Longo com franja", "min_age": 16, "max_age": 45},
	{"name": "Longo liso", "min_age": 16, "max_age": 45},
	{"name": "Longo cacheado", "min_age": 16, "max_age": 45},
	{"name": "Cacheado médio", "min_age": 16, "max_age": 70},
	{"name": "Volumoso", "min_age": 16, "max_age": 60},
	{"name": "Curto texturizado", "min_age": 16, "max_age": 70},
	{"name": "Rabo de cavalo", "min_age": 16, "max_age": 50},
	{"name": "Rabos laterais", "min_age": 16, "max_age": 35},
	{"name": "Coque baixo", "min_age": 16, "max_age": 70},
	{"name": "Dois coques", "min_age": 16, "max_age": 30},
	{"name": "Longo com mechas", "min_age": 16, "max_age": 45},
	{"name": "Longo ondulado", "min_age": 16, "max_age": 45},
	{"name": "Calvo", "min_age": 45, "max_age": 70},
]

## Peças na ordem das linhas de clothing.png: as 4 primeiras são de cima, as outras de baixo.
const CLOTHING_NAMES: Array[String] = ["Camisa", "Regata", "Casaco", "Top", "Calça", "Short", "Saia"]
const FIRST_BOTTOM_ROW := 4
const CLOTHING_COLORS: Array[Dictionary] = [
	{"name": "azul", "ramp": [Color("1f2a3a"), Color("3a5070"), Color("5f7fa6"), Color("9db6d3")]},
	{"name": "verde", "ramp": [Color("1f3326"), Color("365a3f"), Color("5a8a5f"), Color("9cc39a")]},
	{"name": "marrom", "ramp": [Color("2e2018"), Color("553a28"), Color("80593c"), Color("b08a64")]},
	{"name": "vermelho", "ramp": [Color("3a1414"), Color("6e2626"), Color("a14040"), Color("d27a6e")]},
	{"name": "cinza", "ramp": [Color("222226"), Color("44444a"), Color("6e6e76"), Color("a6a6ae")]},
	{"name": "ocre", "ramp": [Color("3e3014"), Color("6e5620"), Color("a6852f"), Color("d6b866")]},
	{"name": "roxo", "ramp": [Color("2a1f3a"), Color("4a3866"), Color("705a96"), Color("a493c6")]},
]

## id do asset → Image da folha (compose)
static var _sheets := {}

## Chance de cabelo grisalho e de branco por faixa de idade: [idade mínima, grisalho, branco].
const GRAYING := [[60, 0.40, 0.45], [50, 0.50, 0.10], [40, 0.20, 0.0]]


## Aparência aleatória coerente com a idade.
static func generate(rng: RandomNumberGenerator, age: int) -> ColonistAppearance:
	var looks := ColonistAppearance.new()
	looks.skin_tone = rng.randi_range(0, SKIN_TONES.size() - 1)
	var styles := styles_for_age(age)
	looks.hair_style = styles[rng.randi_range(0, styles.size() - 1)]
	looks.hair_color = _hair_color(rng, age)
	looks.top = rng.randi_range(0, FIRST_BOTTOM_ROW - 1)
	looks.bottom = rng.randi_range(FIRST_BOTTOM_ROW, CLOTHING_NAMES.size() - 1)
	looks.top_color = rng.randi_range(0, CLOTHING_COLORS.size() - 1)
	looks.bottom_color = rng.randi_range(0, CLOTHING_COLORS.size() - 1)
	return looks


## Gerador próprio do colono, derivado da semente da partida e do id: a aparência não consome o
## gerador da simulação, então o resto da partida continua igual com a mesma seed.
static func rng_for(simulation_rng: RandomNumberGenerator, colonist_id: int) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash([simulation_rng.seed, colonist_id, "aparência"])
	return rng


## Estilos de cabelo (linhas de hair.png) que combinam com a idade.
static func styles_for_age(age: int) -> Array[int]:
	var result: Array[int] = []
	for index in HAIR_STYLES.size():
		var style: Dictionary = HAIR_STYLES[index]
		if age >= style["min_age"] and age <= style["max_age"]:
			result.append(index)
	return result


static func _hair_color(rng: RandomNumberGenerator, age: int) -> int:
	for band in GRAYING:
		if age >= band[0]:
			var roll := rng.randf()
			if roll < band[2]:
				return WHITE
			if roll < band[2] + band[1]:
				return GRAY
			break
	var total := 0
	for weight: int in NATURAL_HAIR_WEIGHTS.values():
		total += weight
	var pick := rng.randi_range(1, total)
	for color: int in NATURAL_HAIR_WEIGHTS:
		pick -= NATURAL_HAIR_WEIGHTS[color]
		if pick <= 0:
			return color
	return 0


## Direção do passo de from para to (parado: null → quem chama mantém a anterior).
static func facing_of(from: Vector2i, to: Vector2i) -> Variant:
	var delta := to - from
	if delta == Vector2i.ZERO:
		return null
	if absi(delta.x) >= absi(delta.y):
		return Facing.RIGHT if delta.x > 0 else Facing.LEFT
	return Facing.FRONT if delta.y > 0 else Facing.BACK


## Quadro da caminhada pelo tick (cada colono com sua fase, para não andarem em sincronia).
static func walk_frame(tick: int, colonist_id: int) -> int:
	return ((tick + colonist_id * 7) / WALK_TICKS_PER_FRAME) % WALK_FRAMES


## Recorte do corpo na folha da base. Parado de frente usa a linha 0; parado de lado ou de costas,
## o primeiro quadro da caminhada daquela direção.
static func base_region(facing: Facing, frame: int, moving: bool) -> Rect2:
	if not moving and facing == Facing.FRONT:
		return Rect2(Vector2.ZERO, Vector2(FRAME_SIZE))
	return Rect2(Vector2((frame if moving else 0) * FRAME_SIZE.x, (1 + facing) * FRAME_SIZE.y), Vector2(FRAME_SIZE))


## Recorte da mesma pose numa camada (cabelo ou roupa): a coluna segue a sequência da base.
static func layer_region(row: int, facing: Facing, frame: int, moving: bool) -> Rect2:
	var column := 0
	if moving or facing != Facing.FRONT:
		column = 1 + facing * WALK_FRAMES + (frame if moving else 0)
	return Rect2(Vector2(column * FRAME_SIZE.x, row * FRAME_SIZE.y), Vector2(FRAME_SIZE))


## A mesma composição das camadas, feita na CPU: imagem 16×24 de uma pose. Serve para o retrato
## da barra de colonos e para conferir o alinhamento nos testes (o jogo desenha com o shader).
static func compose(looks: ColonistAppearance, facing: Facing, frame: int, moving: bool,
		shirt := true, pants := true) -> Image:
	var image := _sheet(BASE_SHEET).get_region(Rect2i(base_region(facing, frame, moving)))
	var skin := SKIN_TONES[looks.skin_tone]
	for y in image.get_height():
		for x in image.get_width():
			var pixel := image.get_pixel(x, y)
			if pixel.a > 0.0:
				image.set_pixel(x, y, Color(pixel.r * skin.r, pixel.g * skin.g, pixel.b * skin.b, pixel.a))
	var layers := []
	if pants:
		layers.append([CLOTHING_SHEET, looks.bottom, CLOTHING_SOURCE_RAMP, CLOTHING_COLORS[looks.bottom_color]["ramp"]])
	if shirt:
		layers.append([CLOTHING_SHEET, looks.top, CLOTHING_SOURCE_RAMP, CLOTHING_COLORS[looks.top_color]["ramp"]])
	layers.append([HAIR_SHEET, looks.hair_style, HAIR_SOURCE_RAMP, HAIR_COLORS[looks.hair_color]["ramp"]])
	for layer: Array in layers:
		var part := _sheet(layer[0]).get_region(Rect2i(layer_region(layer[1], facing, frame, moving)))
		_swap(part, layer[2], layer[3])
		image.blend_rect(part, Rect2i(Vector2i.ZERO, FRAME_SIZE), Vector2i.ZERO)
	return image


## Troca da rampa de 4 cores, igual ao shaders/palette_swap.gdshader.
static func _swap(image: Image, source: Array, target: Array) -> void:
	for y in image.get_height():
		for x in image.get_width():
			var pixel := image.get_pixel(x, y)
			if pixel.a <= 0.0:
				continue
			for index in source.size():
				var from: Color = source[index]
				if Vector3(pixel.r - from.r, pixel.g - from.g, pixel.b - from.b).length() < 0.02:
					var to: Color = target[index]
					image.set_pixel(x, y, Color(to.r, to.g, to.b, pixel.a))
					break


## Folha como Image, lida uma vez só.
static func _sheet(asset_id: String) -> Image:
	if _sheets.has(asset_id):
		return _sheets[asset_id]
	var image := AssetCatalog.texture(asset_id).get_image()
	if image.is_compressed():
		image.decompress()
	image.convert(Image.FORMAT_RGBA8)
	_sheets[asset_id] = image
	return image


## "cabelo chanel castanho · camisa azul · calça cinza" (ficha do colono).
static func describe(looks: ColonistAppearance) -> String:
	return "cabelo %s %s · %s %s · %s %s" % [
		(HAIR_STYLES[looks.hair_style]["name"] as String).to_lower(), HAIR_COLORS[looks.hair_color]["name"],
		CLOTHING_NAMES[looks.top].to_lower(), CLOTHING_COLORS[looks.top_color]["name"],
		CLOTHING_NAMES[looks.bottom].to_lower(), CLOTHING_COLORS[looks.bottom_color]["name"]]
