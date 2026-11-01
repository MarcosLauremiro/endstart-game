class_name BottomBar
extends PanelContainer
## Base da tela (GDD > Interface): construir, ordens de área e as janelas de Trabalho e Armazém.
## Só emite sinais; quem aplica a ordem é a cena principal, pela simulação.

signal tool_selected(tool: Designations.Tool)
signal build_menu_toggled
signal work_window_toggled
signal storage_panel_toggled
signal schedule_window_toggled

## ferramenta → [ícone, atalho]
const _TOOLS := {
	Designations.Tool.CUT: ["ui/icons/orders/cut", "C"],
	Designations.Tool.MINE: ["ui/icons/orders/mine", "M"],
	Designations.Tool.HARVEST: ["ui/icons/orders/harvest", "H"],
	Designations.Tool.HUNT: ["ui/icons/orders/hunt", "K"],
	Designations.Tool.GROW_ZONE: ["ui/icons/orders/grow_zone", "P"],
	Designations.Tool.DECONSTRUCT: ["ui/icons/orders/deconstruct", "D"],
	Designations.Tool.CANCEL: ["ui/icons/orders/cancel", "X"],
}

## ferramenta → Button
var _tool_buttons := {}
var _build_button: Button


func _ready() -> void:
	var row := HBoxContainer.new()
	add_child(row)
	_build_button = _make_button("ui/icons/tabs/build", "Construir (B)")
	_build_button.toggle_mode = true
	_build_button.pressed.connect(func() -> void: build_menu_toggled.emit())
	row.add_child(_build_button)
	row.add_child(VSeparator.new())
	for tool in _TOOLS:
		var button := _make_button(_TOOLS[tool][0], "%s (%s): arraste no mapa" % [Designations.TOOL_NAMES[tool], _TOOLS[tool][1]])
		button.toggle_mode = true
		button.pressed.connect(func() -> void: tool_selected.emit(tool))
		row.add_child(button)
		_tool_buttons[tool] = button
	row.add_child(VSeparator.new())
	var work := _make_button("ui/icons/tabs/work", "Trabalho: prioridades (W)")
	work.pressed.connect(func() -> void: work_window_toggled.emit())
	row.add_child(work)
	var schedule := _make_button("ui/icons/tabs/schedule", "Agenda: Dormir, Trabalhar e Livre por hora (A)")
	schedule.pressed.connect(func() -> void: schedule_window_toggled.emit())
	row.add_child(schedule)
	var storage := _make_button("ui/icons/tabs/storage", "Armazém: estoque e contêineres (I)")
	storage.pressed.connect(func() -> void: storage_panel_toggled.emit())
	row.add_child(storage)


func show_tool(active: Designations.Tool, building: bool) -> void:
	for tool in _tool_buttons:
		_tool_buttons[tool].set_pressed_no_signal(tool == active)
	_build_button.set_pressed_no_signal(building)


func _make_button(icon_id: String, tooltip: String) -> Button:
	var button := Button.new()
	button.icon = AssetCatalog.texture(icon_id)
	button.tooltip_text = tooltip
	button.focus_mode = Control.FOCUS_NONE
	return button
