class_name ScheduleWindow
extends PanelContainer
## Janela de Agenda (GDD: Agenda; MVP: Dormir, Trabalhar e Livre). Uma linha por colono e uma
## coluna por hora. Escolha o bloco em cima e clique (ou arraste) nas horas para pintar.

const _CELL_SIZE := Vector2(12, 14)
const _BLOCK_COLORS := {
	Schedule.Block.SLEEP: Color("4a5a8a"),
	Schedule.Block.WORK: Color("a8663f"),
	Schedule.Block.FREE: Color("5a8a4a"),
}

var _simulation: Simulation
var _brush: Schedule.Block = Schedule.Block.WORK
var _grid: GridContainer
## ColorRect → [id do colono, hora]
var _cells := {}
## Bloco → Button do pincel
var _brush_buttons := {}
var _painting := false


func _ready() -> void:
	var column := VBoxContainer.new()
	add_child(column)
	var title := Label.new()
	title.text = "Agenda (A) — escolha o bloco e clique ou arraste nas horas"
	title.add_theme_color_override("font_color", UiTheme.COMMUNITY)
	column.add_child(title)
	WindowDrag.attach(self, title)
	var brushes := HBoxContainer.new()
	column.add_child(brushes)
	for block in _BLOCK_COLORS:
		var button := Button.new()
		button.text = Schedule.name_of(block)
		button.toggle_mode = true
		button.focus_mode = Control.FOCUS_NONE
		button.add_theme_color_override("font_color", _BLOCK_COLORS[block].lightened(0.4))
		button.pressed.connect(func() -> void: _set_brush(block))
		brushes.add_child(button)
		_brush_buttons[block] = button
	_grid = GridContainer.new()
	_grid.columns = 1 + Balance.HOURS_PER_DAY
	_grid.add_theme_constant_override("h_separation", 1)
	_grid.add_theme_constant_override("v_separation", 1)
	column.add_child(_grid)
	_set_brush(Schedule.Block.WORK)


func bind(simulation: Simulation) -> void:
	_simulation = simulation
	_rebuild()


func refresh() -> void:
	for cell in _cells:
		var colonist := _simulation.state.colonist_by_id(_cells[cell][0])
		if colonist:
			cell.color = _BLOCK_COLORS[colonist.schedule.block_at(_cells[cell][1])]


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		_painting = false


func _set_brush(block: Schedule.Block) -> void:
	_brush = block
	for key in _brush_buttons:
		_brush_buttons[key].set_pressed_no_signal(key == block)


func _rebuild() -> void:
	for child in _grid.get_children():
		child.queue_free()
	_cells.clear()
	_grid.add_child(Label.new())
	for hour in Balance.HOURS_PER_DAY:
		var header := Label.new()
		header.text = str(hour)
		header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		header.custom_minimum_size.x = _CELL_SIZE.x
		_grid.add_child(header)
	for colonist in _simulation.state.colonists:
		var name_label := Label.new()
		name_label.text = colonist.display_name
		_grid.add_child(name_label)
		for hour in Balance.HOURS_PER_DAY:
			var cell := ColorRect.new()
			cell.custom_minimum_size = _CELL_SIZE
			cell.tooltip_text = "%s, %02d:00" % [colonist.display_name, hour]
			cell.gui_input.connect(_on_cell_input.bind(cell))
			cell.mouse_entered.connect(func() -> void:
				if _painting:
					_paint(cell))
			_grid.add_child(cell)
			_cells[cell] = [colonist.id, hour]
	refresh()


func _on_cell_input(event: InputEvent, cell: ColorRect) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_painting = true
		_paint(cell)
		cell.accept_event()


func _paint(cell: ColorRect) -> void:
	_simulation.set_schedule_block(_cells[cell][0], _cells[cell][1], _brush)
	cell.color = _BLOCK_COLORS[_brush]
