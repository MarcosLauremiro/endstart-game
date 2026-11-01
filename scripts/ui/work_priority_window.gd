class_name WorkPriorityWindow
extends PanelContainer
## Janela de Trabalho (GDD: Prioridades de trabalho): uma linha por colono, uma coluna por tipo,
## prioridade 1 (mais alta) a 4, ou desligado. Clique esquerdo sobe a prioridade; direito desce.

const _OFF_TEXT := "–"
const _CELL_WIDTH := 28

var _simulation: Simulation
var _grid: GridContainer
## Button → [id do colono, tipo de trabalho]
var _cells := {}
## Button → id da espécie (caça automática)
var _hunt_toggles := {}


func _ready() -> void:
	var column := VBoxContainer.new()
	add_child(column)
	var title := Label.new()
	title.text = "Trabalho — prioridade 1 é a mais alta; com prioridades iguais vale a ordem das colunas"
	title.add_theme_color_override("font_color", UiTheme.COMMUNITY)
	column.add_child(title)
	_grid = GridContainer.new()
	_grid.columns = 1 + WorkType.COLUMNS.size()
	column.add_child(_grid)
	var hint := Label.new()
	hint.text = "Clique: sobe a prioridade · botão direito: desce · W fecha"
	hint.add_theme_color_override("font_color", UiTheme.TEXT_SECONDARY)
	column.add_child(hint)
	var hunting := HBoxContainer.new()
	column.add_child(hunting)
	var hunting_label := Label.new()
	hunting_label.text = "Caça automática (marca os que estão no mapa e os que chegarem):"
	hunting.add_child(hunting_label)
	for def in Defs.animals():
		if def.is_predator:
			continue
		var toggle := Button.new()
		toggle.text = def.display_name
		toggle.toggle_mode = true
		toggle.focus_mode = Control.FOCUS_NONE
		toggle.toggled.connect(func(on: bool) -> void: _simulation.set_auto_hunt(def.id, on))
		hunting.add_child(toggle)
		_hunt_toggles[toggle] = def.id


func bind(simulation: Simulation) -> void:
	_simulation = simulation
	_rebuild()


func refresh() -> void:
	for button in _cells:
		var colonist := _simulation.state.colonist_by_id(_cells[button][0])
		var priority := colonist.priority_of(_cells[button][1]) if colonist else 0
		button.text = str(priority) if priority > 0 else _OFF_TEXT
		if colonist:
			button.tooltip_text = _skill_hint(colonist, _cells[button][1])
	for toggle in _hunt_toggles:
		toggle.set_pressed_no_signal(_simulation.state.auto_hunt.get(_hunt_toggles[toggle], false))


func _rebuild() -> void:
	for child in _grid.get_children():
		child.queue_free()
	_cells.clear()
	_grid.add_child(Label.new())
	for work_type in WorkType.COLUMNS:
		var header := Label.new()
		header.text = WorkType.name_of(work_type)
		_grid.add_child(header)
	for colonist in _simulation.state.colonists:
		var name_label := Label.new()
		var trait_names := colonist.traits.map(func(t: StringName) -> String: return Traits.name_of(t))
		name_label.text = colonist.display_name if trait_names.is_empty() else "%s (%s)" % [colonist.display_name, ", ".join(trait_names)]
		_grid.add_child(name_label)
		for work_type in WorkType.COLUMNS:
			var button := Button.new()
			button.custom_minimum_size.x = _CELL_WIDTH
			button.focus_mode = Control.FOCUS_NONE
			button.gui_input.connect(_on_cell_input.bind(button))
			_grid.add_child(button)
			_cells[button] = [colonist.id, work_type]
	refresh()


## Dica da célula: habilidade usada, nível e afinidade do colono nela.
static func _skill_hint(colonist: Colonist, work_type: int) -> String:
	var skill_id := Skills.for_work(work_type)
	if skill_id < 0:
		return "%s: %s (sem habilidade)" % [colonist.display_name, WorkType.name_of(work_type)]
	var state: SkillState = colonist.skills[skill_id]
	return "%s: %s %d (%s), afinidade: %s" % [colonist.display_name, Skills.name_of(skill_id), state.level,
		Skills.title_of(state.level), Skills.AFFINITY_NAMES[state.affinity]]


func _on_cell_input(event: InputEvent, button: Button) -> void:
	if not event is InputEventMouseButton or not event.pressed:
		return
	var step := 0
	if event.button_index == MOUSE_BUTTON_LEFT:
		step = -1
	elif event.button_index == MOUSE_BUTTON_RIGHT:
		step = 1
	if step == 0:
		return
	button.accept_event()
	var colonist_id: int = _cells[button][0]
	var work_type: int = _cells[button][1]
	var colonist := _simulation.state.colonist_by_id(colonist_id)
	# Ciclo 1 → 2 → 3 → 4 → desligado; "subir" é ir para um número menor.
	var levels := Balance.MAX_WORK_PRIORITY + 1
	var current := colonist.priority_of(work_type)
	var position := (current - 1 + levels) % levels
	var next := (position + step + levels) % levels
	_simulation.set_work_priority(colonist_id, work_type, (next + 1) % levels)
	refresh()
