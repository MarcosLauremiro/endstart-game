class_name TilePanel
extends PanelContainer
## Canto inferior esquerdo, quando o jogador clica num tile sem colono:
## terreno, objetos, conteúdo, tarefa e por que cada colono a faria ou não.

const _WIDTH := 250
## Recalcula as explicações algumas vezes por segundo, não a cada quadro (elas usam caminhos).
const _REFRESH_MSEC := 250

var _title: Label
var _body: Label
var _cell := Vector2i(-1, -1)
var _next_refresh_msec := 0


func _ready() -> void:
	custom_minimum_size.x = _WIDTH
	var column := VBoxContainer.new()
	add_child(column)
	_title = Label.new()
	_title.add_theme_color_override("font_color", UiTheme.COMMUNITY)
	column.add_child(_title)
	_body = Label.new()
	_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(_body)


func show_tile(simulation: Simulation, cell: Vector2i) -> void:
	var now := Time.get_ticks_msec()
	if cell == _cell and now < _next_refresh_msec:
		return
	_cell = cell
	_next_refresh_msec = now + _REFRESH_MSEC
	_title.text = TileInfo.title(cell)
	_body.text = "\n".join(TileInfo.describe(simulation, cell))
