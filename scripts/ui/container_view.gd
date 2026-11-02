class_name ContainerView
extends VBoxContainer
## Interior de um contêiner no painel do tile (GDD: Tipos de contêiner): a grade de espaços, cada um
## com o ícone do item e a quantidade, como um baú. Abaixo, o botão Configurar abre o filtro por
## categoria (GDD: Organização), que antes ficava solto nas opções.

## Avisa depois de mudar o filtro, para o painel se atualizar na hora.
signal filter_changed

const COLUMNS := 5
const SLOT_SIZE := 20
const _ICON_SIZE := 16
const _SLOT_BACKGROUND := Color("121115")

var _simulation: Simulation
var _container: StorageContainer
var _grid: GridContainer
## Um por espaço: {"panel": Panel, "icon": TextureRect, "count": Label}
var _slots: Array[Dictionary] = []
var _configure: Button
var _settings: VBoxContainer
## Rótulos e estados do filtro mostrado, para só remontar os botões quando mudam.
var _settings_signature := ""


func _ready() -> void:
	_grid = GridContainer.new()
	_grid.columns = COLUMNS
	_grid.add_theme_constant_override("h_separation", 1)
	_grid.add_theme_constant_override("v_separation", 1)
	add_child(_grid)
	_configure = Button.new()
	_configure.focus_mode = Control.FOCUS_NONE
	_configure.toggle_mode = true
	_configure.tooltip_text = "Filtro: quais categorias este contêiner guarda"
	_configure.toggled.connect(func(on: bool) -> void:
		_settings.visible = on
		_refresh_button())
	add_child(_configure)
	_settings = VBoxContainer.new()
	_settings.visible = false
	add_child(_settings)


## Mostra o contêiner. Trocar de contêiner fecha a configuração.
func show_container(simulation: Simulation, container: StorageContainer) -> void:
	_simulation = simulation
	if container != _container:
		_container = container
		_configure.set_pressed_no_signal(false)
		_settings.visible = false
		_settings_signature = ""
	if _slots.size() != container.slots.size():
		_build_slots(container.slots.size())
	for index in container.slots.size():
		_show_slot(_slots[index], container, index)
	_refresh_button()
	if _settings.visible:
		_refresh_settings()


## Texto do número no canto do espaço: nada para espaço vazio ou com 1 item.
static func count_text(count: int) -> String:
	return str(count) if count > 1 else ""


## Dica do espaço: item, quantidade, quanto cabe, reservas e entregas a caminho.
static func slot_tooltip(container: StorageContainer, index: int) -> String:
	var slot := container.slots[index]
	var item: StringName = slot["item"]
	if item == &"":
		return "Espaço vazio"
	var definition := Defs.item(item)
	var text := "%s: %d de %d" % [definition.display_name, slot["count"], container.def.stack_size_for(definition)]
	if slot["pending"] > 0:
		text += "\n%d a caminho" % slot["pending"]
	var reserved := container.count_of(item) - container.available(item)
	if reserved > 0:
		text += "\n%d reservados para retirada" % reserved
	return text


## Categorias que o tipo de contêiner pode guardar: [{"category": int, "name": String, "on": bool}].
static func filter_entries(container: StorageContainer) -> Array[Dictionary]:
	var entries: Array[Dictionary] = []
	for category in ItemDef.CATEGORY_NAMES:
		if container.def.can_hold(category):
			entries.append({"category": category, "name": ItemDef.CATEGORY_NAMES[category],
				"on": container.allowed.get(category, false)})
	return entries


func _build_slots(count: int) -> void:
	for child in _grid.get_children():
		_grid.remove_child(child)
		child.queue_free()
	_slots.clear()
	var style := StyleBoxFlat.new()
	style.bg_color = _SLOT_BACKGROUND
	style.border_color = UiTheme.FRAME
	style.set_border_width_all(1)
	for _i in count:
		var panel := Panel.new()
		panel.custom_minimum_size = Vector2(SLOT_SIZE, SLOT_SIZE)
		panel.add_theme_stylebox_override("panel", style)
		var icon := TextureRect.new()
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		icon.position = Vector2.ONE * (SLOT_SIZE - _ICON_SIZE) / 2.0
		icon.size = Vector2(_ICON_SIZE, _ICON_SIZE)
		panel.add_child(icon)
		var label := Label.new()
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
		label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		label.offset_right = -1
		label.add_theme_color_override("font_outline_color", _SLOT_BACKGROUND)
		label.add_theme_constant_override("outline_size", 2)
		panel.add_child(label)
		_grid.add_child(panel)
		_slots.append({"panel": panel, "icon": icon, "count": label})


func _show_slot(view: Dictionary, container: StorageContainer, index: int) -> void:
	var slot := container.slots[index]
	var item: StringName = slot["item"]
	var icon: TextureRect = view["icon"]
	icon.texture = AssetCatalog.texture(Defs.item(item).icon) if item != &"" else null
	# Espaço só reservado (entrega a caminho) aparece apagado.
	icon.modulate.a = 1.0 if slot["count"] > 0 else 0.35
	(view["count"] as Label).text = count_text(slot["count"])
	(view["panel"] as Panel).tooltip_text = slot_tooltip(container, index)


func _refresh_button() -> void:
	var used := 0
	for slot in _container.slots:
		if slot["item"] != &"":
			used += 1
	_configure.text = "%s Configurar (%d/%d espaços)" % ["v" if _configure.button_pressed else ">", used, _container.slots.size()]


func _refresh_settings() -> void:
	var entries := filter_entries(_container)
	var signature := "|".join(entries.map(func(e: Dictionary) -> String: return "%d:%s" % [e["category"], e["on"]]))
	if signature == _settings_signature:
		return
	_settings_signature = signature
	for child in _settings.get_children():
		child.queue_free()
	var header := Label.new()
	header.text = "Guardar aqui:"
	header.add_theme_color_override("font_color", UiTheme.TEXT_SECONDARY)
	_settings.add_child(header)
	var flow := HFlowContainer.new()
	_settings.add_child(flow)
	for entry in entries:
		var button := Button.new()
		button.focus_mode = Control.FOCUS_NONE
		var on: bool = entry["on"]
		button.text = "[%s] %s" % ["x" if on else " ", entry["name"]]
		button.tooltip_text = "%s %s; o que sair vai para o chão e é levado a outro contêiner" % [
			"Parar de guardar" if on else "Guardar", (entry["name"] as String).to_lower()]
		var category: int = entry["category"]
		var container_id := _container.id
		button.pressed.connect(func() -> void: _toggle(container_id, category, not on))
		flow.add_child(button)


func _toggle(container_id: int, category: int, allowed: bool) -> void:
	var message := _simulation.set_container_filter(container_id, category, allowed)
	if not message.is_empty():
		_simulation.state.post_message(message)
	_settings_signature = ""
	filter_changed.emit()
