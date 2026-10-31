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

const FONT_SIZE := 8
const FONT_PATH := "res://assets/ui/fonts/main.ttf"
const PANEL_CORNER := 16
const PANEL_PADDING := 6
const BUTTON_CORNER := 8
const BUTTON_PADDING := 4
const SCREEN_MARGIN := 4


static func build() -> Theme:
	var theme := Theme.new()
	theme.default_font_size = FONT_SIZE
	if ResourceLoader.exists(FONT_PATH):
		theme.default_font = load(FONT_PATH)

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


static func _nine_slice(asset_id: String, corner: int, padding: int) -> StyleBoxTexture:
	var style := StyleBoxTexture.new()
	style.texture = AssetCatalog.texture(asset_id)
	for side in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
		style.set_texture_margin(side, corner)
		style.set_content_margin(side, padding)
	return style
