class_name UiTheme
extends RefCounted
## Paleta e tema "rust punk" do GDD (Interface > Estilo visual). Cada cor tem um significado fixo.

const PANEL_BACKGROUND := Color("1b1a1f")
const FRAME := Color("7a4a32")
const TEXT := Color("e8dcc0")
const TEXT_SECONDARY := Color("9a9285")
const COMMUNITY := Color("f2a541")
const ANCIENT := Color("3fe0d0")
const POSITIVE := Color("7bc96f")
const DANGER := Color("e5534b")
const LORE := Color("9b7bd8")

## Fonte pixel "Determination": desenhada numa grade de 12 px por em. Com a escala inteira da
## janela (×2, ×3...) e o oversampling do Godot, ela fica nítida quando tamanho × escala é
## múltiplo de 12. O tamanho é escolhido pela escala (font_size_for), perto deste alvo.
const FONT_SIZE := 8
const FONT_GRID := 12
const FONT_PATH := "res://assets/ui/fonts/determination.ttf"
const PANEL_CORNER := 16
const PANEL_PADDING := 6
const BUTTON_CORNER := 8
const BUTTON_PADDING := 4
const SCREEN_MARGIN := 4


static func build() -> Theme:
	var theme := Theme.new()
	theme.default_font_size = FONT_SIZE
	if ResourceLoader.exists(FONT_PATH):
		theme.default_font = pixel_font()

	var panel := _nine_slice("ui/frames/panel", PANEL_CORNER, PANEL_PADDING)
	theme.set_stylebox("panel", "PanelContainer", panel)
	theme.set_stylebox("panel", "TooltipPanel", panel)

	var button_normal := _nine_slice("ui/frames/button", BUTTON_CORNER, BUTTON_PADDING)
	var button_pressed := _nine_slice("ui/frames/button_pressed", BUTTON_CORNER, BUTTON_PADDING)
	theme.set_stylebox("normal", "Button", button_normal)
	theme.set_stylebox("hover", "Button", _nine_slice("ui/frames/button_hover", BUTTON_CORNER, BUTTON_PADDING))
	theme.set_stylebox("pressed", "Button", button_pressed)
	theme.set_stylebox("hover_pressed", "Button", button_pressed)
	theme.set_stylebox("focus", "Button", StyleBoxEmpty.new())

	var bar_background := StyleBoxFlat.new()
	bar_background.bg_color = PANEL_BACKGROUND.lightened(0.15)
	theme.set_stylebox("background", "ProgressBar", bar_background)
	var bar_fill := StyleBoxFlat.new()
	bar_fill.bg_color = POSITIVE
	theme.set_stylebox("fill", "ProgressBar", bar_fill)
	theme.set_color("font_color", "ProgressBar", TEXT)

	for type_name in ["Label", "Button", "TooltipLabel"]:
		theme.set_color("font_color", type_name, TEXT)
	theme.set_color("font_hover_color", "Button", TEXT)
	theme.set_color("font_pressed_color", "Button", COMMUNITY)
	return theme


## Tamanho da fonte (em pixels da arte) para a escala inteira da janela: o mais perto de
## FONT_SIZE entre os que caem na grade da fonte; no empate, o menor.
static func font_size_for(scale: int) -> int:
	var safe_scale := maxi(scale, 1)
	var best := 0
	var step := 1
	while step * FONT_GRID <= FONT_SIZE * safe_scale * 2:
		if step * FONT_GRID % safe_scale == 0:
			var size := step * FONT_GRID / safe_scale
			if best == 0 or absi(size - FONT_SIZE) < absi(best - FONT_SIZE):
				best = size
		step += 1
	return best if best > 0 else FONT_SIZE


## Escala inteira que o Godot aplica à tela base de 640×360 nesta janela.
static func screen_scale(window_size: Vector2i) -> int:
	var base := Vector2i(
		ProjectSettings.get_setting("display/window/size/viewport_width"),
		ProjectSettings.get_setting("display/window/size/viewport_height"))
	return maxi(1, mini(window_size.x / base.x, window_size.y / base.y))


## A fonte da interface sem suavização nem hinting, para os pixels não borrarem.
static func pixel_font() -> Font:
	var font: FontFile = load(FONT_PATH)
	font.antialiasing = TextServer.FONT_ANTIALIASING_NONE
	font.hinting = TextServer.HINTING_NONE
	font.subpixel_positioning = TextServer.SUBPIXEL_POSITIONING_DISABLED
	font.generate_mipmaps = false
	return font


static func _nine_slice(asset_id: String, corner: int, padding: int) -> StyleBoxTexture:
	var style := StyleBoxTexture.new()
	style.texture = AssetCatalog.texture(asset_id)
	for side in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
		style.set_texture_margin(side, corner)
		style.set_content_margin(side, padding)
	return style
