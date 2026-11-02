class_name MenuWindow
extends PanelContainer
## Janela do Menu (GDD: abas da barra inferior > Menu; Salvamento livre). Salvar com um nome,
## carregar ou apagar uma partida da lista, mapa novo e sair. Só emite sinais: quem salva e
## carrega é a cena principal. Apagar pede um segundo clique.

signal save_requested(save_name: String)
signal load_requested(save_name: String)
signal new_game_requested
signal quit_requested

const _WIDTH := 320
const _MAX_LIST_HEIGHT := 160

var _simulation: Simulation
var _name: LineEdit
var _list: VBoxContainer
## Partida que espera o segundo clique para ser apagada ("" = nenhuma).
var _confirm_delete := ""


func _ready() -> void:
	custom_minimum_size.x = _WIDTH
	var column := VBoxContainer.new()
	add_child(column)
	var title := Label.new()
	title.text = "Menu (Esc)"
	title.add_theme_color_override("font_color", UiTheme.COMMUNITY)
	column.add_child(title)
	var save_row := HBoxContainer.new()
	column.add_child(save_row)
	_name = LineEdit.new()
	_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_name.placeholder_text = "Nome da partida"
	_name.text_submitted.connect(func(_text: String) -> void: _save())
	save_row.add_child(_name)
	save_row.add_child(_button("Salvar", "Grava a partida com este nome (Ctrl+S salva rápido)", _save))
	var header := Label.new()
	header.text = "Partidas salvas"
	header.add_theme_color_override("font_color", UiTheme.TEXT_SECONDARY)
	column.add_child(header)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.custom_minimum_size.y = _MAX_LIST_HEIGHT
	column.add_child(scroll)
	_list = VBoxContainer.new()
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_list)
	var bottom := HBoxContainer.new()
	column.add_child(bottom)
	bottom.add_child(_button("Mapa novo", "Começa outra partida (a atual se perde se não foi salva)",
		func() -> void: new_game_requested.emit()))
	bottom.add_child(_button("Sair do jogo", "Fecha o jogo (o salvamento automático é diário, às 6h)",
		func() -> void: quit_requested.emit()))


func bind(simulation: Simulation) -> void:
	_simulation = simulation


## Ao abrir: sugere um nome com o dia e a hora e relê a lista do disco.
func refresh() -> void:
	_confirm_delete = ""
	if _simulation:
		_name.text = default_name(_simulation)
	_rebuild_list()


static func default_name(simulation: Simulation) -> String:
	return "Dia %d, %02dh" % [simulation.clock.day(), simulation.clock.hour()]


## "Dia 5, 13h · 3 colonos · salvo em 2026-11-02 14:03"
static func describe(header: Dictionary) -> String:
	return "Dia %d, %02dh · %d colonos · salvo em %s" % [header.get("day", 0), header.get("hour", 0),
		header.get("colonists", 0), String(header.get("saved_at", "")).replace("T", " ").left(16)]


func _save() -> void:
	save_requested.emit(SaveGame.clean_name(_name.text))
	_rebuild_list()


func _rebuild_list() -> void:
	for child in _list.get_children():
		_list.remove_child(child)
		child.queue_free()
	var saves := SaveGame.list_saves()
	if saves.is_empty():
		var empty := Label.new()
		empty.text = "Nenhuma partida salva"
		empty.add_theme_color_override("font_color", UiTheme.TEXT_SECONDARY)
		_list.add_child(empty)
	for entry in saves:
		var save_name: String = entry["name"]
		var row := HBoxContainer.new()
		_list.add_child(row)
		var label := Label.new()
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		label.clip_text = true
		label.text = save_name
		label.tooltip_text = describe(entry["header"])
		label.mouse_filter = Control.MOUSE_FILTER_PASS
		row.add_child(label)
		row.add_child(_button("Carregar", describe(entry["header"]), func() -> void: load_requested.emit(save_name)))
		var confirming := _confirm_delete == save_name
		var delete := _button("Confirmar" if confirming else "Apagar",
			"Clique de novo para apagar de vez" if confirming else "Apaga o arquivo da partida", func() -> void: _delete(save_name))
		if confirming:
			delete.add_theme_color_override("font_color", UiTheme.DANGER)
		row.add_child(delete)


func _delete(save_name: String) -> void:
	if _confirm_delete != save_name:
		_confirm_delete = save_name
	else:
		SaveGame.delete_save(save_name)
		_confirm_delete = ""
	_rebuild_list()


func _button(text: String, tooltip: String, action: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.tooltip_text = tooltip
	button.focus_mode = Control.FOCUS_NONE
	button.pressed.connect(action)
	return button
