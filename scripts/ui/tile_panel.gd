class_name TilePanel
extends PanelContainer
## Canto inferior esquerdo, quando o jogador clica num tile sem colono:
## opções do que há ali (cortar, desmontar, caçar...), terreno, objetos, conteúdo, tarefa
## e por que cada colono a faria ou não.

const _WIDTH := 270
## Acima desta altura o texto rola, para o painel caber na tela.
const _MAX_BODY_HEIGHT := 150
const _SCROLLBAR_ROOM := 10
## Recalcula as explicações algumas vezes por segundo, não a cada quadro (elas usam caminhos).
const _REFRESH_MSEC := 250

var _title: Label
var _actions: ActionBar
var _body: Label
var _scroll: ScrollContainer
var _cell := Vector2i(-1, -1)
var _next_refresh_msec := 0


func _ready() -> void:
	custom_minimum_size.x = _WIDTH
	var column := VBoxContainer.new()
	add_child(column)
	_title = Label.new()
	_title.add_theme_color_override("font_color", UiTheme.COMMUNITY)
	column.add_child(_title)
	_actions = ActionBar.new()
	_actions.option_used.connect(func() -> void: _next_refresh_msec = 0)
	column.add_child(_actions)
	_scroll = ScrollContainer.new()
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	column.add_child(_scroll)
	_body = Label.new()
	_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_body.custom_minimum_size.x = _WIDTH - 2 * UiTheme.PANEL_PADDING - _SCROLLBAR_ROOM
	_scroll.add_child(_body)


func show_tile(simulation: Simulation, cell: Vector2i) -> void:
	var now := Time.get_ticks_msec()
	if cell == _cell and now < _next_refresh_msec:
		return
	_cell = cell
	_next_refresh_msec = now + _REFRESH_MSEC
	_title.text = TileInfo.title(cell)
	_actions.show_options(simulation, ContextActions.for_cell(simulation, cell))
	_body.text = "\n".join(TileInfo.describe(simulation, cell))
	_scroll.custom_minimum_size.y = minf(_body.get_minimum_size().y, _MAX_BODY_HEIGHT)
