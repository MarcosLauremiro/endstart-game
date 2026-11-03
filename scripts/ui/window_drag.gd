class_name WindowDrag
extends RefCounted
## Janela solta que o jogador arrasta pelo título (Trabalho, Agenda, Pesquisa, Armazém).
## No primeiro arraste a janela sai da âncora do HUD e passa a ficar onde foi solta, presa
## dentro da tela. A posição vale enquanto o jogo estiver aberto.

const HINT := "Arraste o título para mover a janela"


## Liga o arraste: `handle` (o título) passa a mover `window`.
static func attach(window: Control, handle: Control) -> void:
	handle.mouse_filter = Control.MOUSE_FILTER_STOP
	handle.mouse_default_cursor_shape = Control.CURSOR_MOVE
	handle.tooltip_text = HINT
	handle.gui_input.connect(func(event: InputEvent) -> void: _on_handle_input(window, event))


static func _on_handle_input(window: Control, event: InputEvent) -> void:
	if event is InputEventMouseMotion and event.button_mask & MOUSE_BUTTON_MASK_LEFT:
		move_by(window, event.relative)
		window.accept_event()


## Move a janela (soltando-a da âncora na primeira vez), sem sair da tela.
static func move_by(window: Control, delta: Vector2) -> void:
	if not is_detached(window):
		var at := window.position
		window.set_anchors_preset(Control.PRESET_TOP_LEFT)
		window.grow_horizontal = Control.GROW_DIRECTION_END
		window.grow_vertical = Control.GROW_DIRECTION_END
		window.position = at
	window.position = clamp_inside(window, window.position + delta)


static func is_detached(window: Control) -> bool:
	return window.anchor_left == 0.0 and window.anchor_top == 0.0 and window.anchor_right == 0.0 \
		and window.grow_horizontal == Control.GROW_DIRECTION_END and window.grow_vertical == Control.GROW_DIRECTION_END


static func clamp_inside(window: Control, at: Vector2) -> Vector2:
	var parent := window.get_parent_control()
	if parent == null:
		return at
	var limit := (parent.size - window.size).max(Vector2.ZERO)
	return at.clamp(Vector2.ZERO, limit)
