class_name ColonistBar
extends HBoxContainer
## Topo da tela (GDD: barra de colonos no topo, com retrato e alertas): um botão por colono com o
## retrato (o próprio colono montado por ColonistLooks, parado de frente) e o nome. Vermelho quando caído ou sangrando, laranja quando convocado. A dica diz o que
## está fazendo e por quê. Clicar seleciona o colono e leva a câmera até ele.

signal colonist_focused(colonist_id: int)

const _REFRESH_MSEC := 250

## id do colono → Button
var _buttons := {}
var _next_refresh_msec := 0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func refresh(state: WorldState, selected_ids: Array[int]) -> void:
	var now := Time.get_ticks_msec()
	if now < _next_refresh_msec:
		return
	_next_refresh_msec = now + _REFRESH_MSEC
	var alive := {}
	for colonist in state.colonists:
		alive[colonist.id] = true
		var button: Button = _buttons.get(colonist.id)
		if button == null:
			button = _make_button(colonist)
			_buttons[colonist.id] = button
		button.text = colonist.display_name
		button.tooltip_text = tooltip(colonist)
		button.set_pressed_no_signal(selected_ids.has(colonist.id))
		var color := UiTheme.TEXT
		if colonist.health.is_downed() or colonist.health.is_bleeding():
			color = UiTheme.DANGER
		elif colonist.drafted:
			color = UiTheme.COMMUNITY
		button.add_theme_color_override("font_color", color)
	for id in _buttons.keys():
		if not alive.has(id):
			_buttons[id].queue_free()
			_buttons.erase(id)


static func portrait(colonist: Colonist) -> Texture2D:
	var image := ColonistLooks.compose(colonist.appearance, ColonistLooks.Facing.FRONT, 0, false,
		colonist.equipment.in_slot(Equipment.Slot.SHIRT) != &"", colonist.equipment.in_slot(Equipment.Slot.PANTS) != &"")
	return ImageTexture.create_from_image(image)


## "Ana · Convocado\nFazendo: cortar árvore\nPor quê: …"
static func tooltip(colonist: Colonist) -> String:
	var doing := colonist.action.label() if colonist.action else "nada"
	var why := colonist.action.reason if colonist.action else "aguardando a próxima decisão"
	var status := PackedStringArray([colonist.state_name()])
	if colonist.drafted:
		status.append("convocado")
	if colonist.health.is_hurt():
		status.append(colonist.health.status_text().to_lower())
	return "%s · %s\nFazendo: %s\nPor quê: %s" % [colonist.display_name, ", ".join(status), doing.to_lower(), why]


func _make_button(colonist: Colonist) -> Button:
	var id := colonist.id
	var button := Button.new()
	button.icon = portrait(colonist)
	button.toggle_mode = true
	button.focus_mode = Control.FOCUS_NONE
	button.pressed.connect(func() -> void: colonist_focused.emit(id))
	add_child(button)
	return button
