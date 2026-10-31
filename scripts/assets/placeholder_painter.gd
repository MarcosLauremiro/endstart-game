class_name PlaceholderPainter
extends RefCounted
## Desenha a arte provisória de uma entrada do AssetCatalog: formas simples na cor de referência,
## no tamanho final, para o jogo funcionar antes da arte definitiva.

const _BORDER_DARKEN := 0.35
const _HIGHLIGHT_LIGHTEN := 0.2
const _SPECKLE_DARKEN := 0.12
const _SPECKLE_PERIOD := 5
const _PANEL_ALPHA := 0.9


static func paint(entry: Dictionary) -> Image:
	var size: Vector2i = entry["size"]
	var color := Color(entry["color"] as String)
	if entry.has("frames"):
		return _paint_sheet(size, entry["frames"], color)
	var image := Image.create_empty(size.x, size.y, false, Image.FORMAT_RGBA8)
	match entry.get("draw", ""):
		"speckle":
			_speckle(image, color)
		"frame":
			_frame(image, color, entry["corner"])
		"pause":
			_pause(image, color)
		"play":
			_play(image, color, entry["count"])
		"bracket":
			_bracket(image, color)
		_:
			_box(image, color)
	return image


## Folha de sprites: um quadro provisório por posição, escurecendo a cada linha para distinguir.
static func _paint_sheet(size: Vector2i, grid: Vector2i, color: Color) -> Image:
	var sheet := Image.create_empty(size.x, size.y, false, Image.FORMAT_RGBA8)
	var frame_size := size / grid
	for row in grid.y:
		for column in grid.x:
			var frame := Image.create_empty(frame_size.x, frame_size.y, false, Image.FORMAT_RGBA8)
			_box(frame, color.darkened(0.1 * row))
			sheet.blit_rect(frame, Rect2i(Vector2i.ZERO, frame_size), Vector2i(column, row) * frame_size)
	return sheet


static func _box(image: Image, color: Color) -> void:
	image.fill(color)
	_outline(image, color.darkened(_BORDER_DARKEN), 1)
	for x in range(1, image.get_width() - 1):
		image.set_pixel(x, 1, color.lightened(_HIGHLIGHT_LIGHTEN))


static func _speckle(image: Image, color: Color) -> void:
	var speckle := color.darkened(_SPECKLE_DARKEN)
	for y in image.get_height():
		for x in image.get_width():
			image.set_pixel(x, y, speckle if (x * 7 + y * 13) % _SPECKLE_PERIOD == 0 else color)


## Moldura 9-slice: fundo grafite quase opaco, borda na cor da entrada e rebites nos cantos.
static func _frame(image: Image, color: Color, corner: int) -> void:
	var background := UiTheme.PANEL_BACKGROUND
	background.a = _PANEL_ALPHA
	image.fill(background)
	var thickness := maxi(1, corner / 8)
	_outline(image, color, thickness)
	var rivet := color.lightened(_HIGHLIGHT_LIGHTEN)
	var inset := corner / 4
	var far_x := image.get_width() - inset - 2
	var far_y := image.get_height() - inset - 2
	for origin in [Vector2i(inset, inset), Vector2i(far_x, inset), Vector2i(inset, far_y), Vector2i(far_x, far_y)]:
		image.fill_rect(Rect2i(origin, Vector2i(2, 2)), rivet)


static func _pause(image: Image, color: Color) -> void:
	image.fill_rect(Rect2i(4, 3, 3, 10), color)
	image.fill_rect(Rect2i(9, 3, 3, 10), color)


## Um a três triângulos de "play" lado a lado.
static func _play(image: Image, color: Color, count: int) -> void:
	var width := mini(8, 12 / count)
	var start_x := (image.get_width() - width * count) / 2
	var middle := image.get_height() / 2
	for index in count:
		for column in width:
			var half := ceili((width - column) * 5.0 / width)
			for y in range(middle - half, middle + half):
				image.set_pixel(start_x + index * width + column, y, color)


static func _bracket(image: Image, color: Color) -> void:
	var w := image.get_width()
	var h := image.get_height()
	var arm := 4
	for corner in [Vector2i(0, 0), Vector2i(w - arm, 0), Vector2i(0, h - 1), Vector2i(w - arm, h - 1)]:
		image.fill_rect(Rect2i(corner, Vector2i(arm, 1)), color)
	for corner in [Vector2i(0, 0), Vector2i(w - 1, 0), Vector2i(0, h - arm), Vector2i(w - 1, h - arm)]:
		image.fill_rect(Rect2i(corner, Vector2i(1, arm)), color)


static func _outline(image: Image, color: Color, thickness: int) -> void:
	var w := image.get_width()
	var h := image.get_height()
	image.fill_rect(Rect2i(0, 0, w, thickness), color)
	image.fill_rect(Rect2i(0, h - thickness, w, thickness), color)
	image.fill_rect(Rect2i(0, 0, thickness, h), color)
	image.fill_rect(Rect2i(w - thickness, 0, thickness, h), color)
