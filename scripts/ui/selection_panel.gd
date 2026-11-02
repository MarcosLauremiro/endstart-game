class_name SelectionPanel
extends PanelContainer
## Canto inferior esquerdo, com a seleção por arraste (MultiSelect): vários colonos (lista com o que
## cada um faz; clicar num nome seleciona só ele), as árvores, rochas e plantas do retângulo (com
## Cortar, Minerar e Colher) ou uma área (o que há nela). Em cima, as opções que valem para todos.

signal colonist_chosen(colonist_id: int)

const _WIDTH := 270
const _MAX_LIST_HEIGHT := 150
## As opções de uma área percorrem todos os tiles dela: recalcula poucas vezes por segundo e,
## acima de _BIG_AREA tiles, só quando a seleção muda ou uma opção é usada.
const _REFRESH_MSEC := 400
const _BIG_AREA := 1500

var _title: Label
var _actions: ActionBar
var _summary: Label
var _scroll: ScrollContainer
var _list: VBoxContainer
var _signature := ""
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
	_summary = Label.new()
	_summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(_summary)
	_scroll = ScrollContainer.new()
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	column.add_child(_scroll)
	_list = VBoxContainer.new()
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scroll.add_child(_list)


func show_colonists(simulation: Simulation, ids: Array[int]) -> void:
	if not _due("colonists:%s" % [ids]):
		return
	var state := simulation.state
	_title.text = "%d colonos selecionados" % ids.size()
	_actions.show_options(simulation, MultiSelect.colonist_options(simulation, ids))
	_summary.visible = false
	_scroll.visible = true
	for child in _list.get_children():
		_list.remove_child(child)
		child.queue_free()
	for id in ids:
		var colonist := state.colonist_by_id(id)
		if colonist == null:
			continue
		var button := Button.new()
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.clip_text = true
		button.focus_mode = Control.FOCUS_NONE
		var doing := colonist.action.label() if colonist.action else "nada"
		button.text = "%s%s · %s" % [colonist.display_name, " (convocado)" if colonist.drafted else "", doing.to_lower()]
		button.tooltip_text = "Selecionar só %s" % colonist.display_name
		button.pressed.connect(func() -> void: colonist_chosen.emit(id))
		_list.add_child(button)
	_scroll.custom_minimum_size.y = minf(_list.get_combined_minimum_size().y, _MAX_LIST_HEIGHT)


## resources: árvores, rochas e plantas selecionadas no retângulo (vazio = a área inteira).
func show_area(simulation: Simulation, area: Rect2i, resources: Array[Vector2i] = []) -> void:
	var cells := resources if not resources.is_empty() else MultiSelect.area_cells(simulation.state, area)
	if not _due("area:%s:%d" % [area, resources.size()], cells.size() <= _BIG_AREA):
		return
	if resources.is_empty():
		_title.text = "Área %d×%d" % [area.size.x, area.size.y]
	else:
		_title.text = "%d selecionados" % resources.size()
	_actions.show_options(simulation, MultiSelect.options_for_cells(simulation, cells, not resources.is_empty()))
	_summary.visible = true
	_summary.text = MultiSelect.summary(simulation.state, cells)
	_scroll.visible = false


## A seleção mudou, uma opção foi usada ou passou o intervalo de atualização (periodic)?
func _due(signature: String, periodic := true) -> bool:
	var now := Time.get_ticks_msec()
	if signature == _signature and now < _next_refresh_msec:
		return false
	_signature = signature
	_next_refresh_msec = now + _REFRESH_MSEC if periodic else 1 << 62
	return true
