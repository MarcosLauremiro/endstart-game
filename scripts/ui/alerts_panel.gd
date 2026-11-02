class_name AlertsPanel
extends VBoxContainer
## Lateral direita (GDD: alertas com limite): até 5 alertas por urgência, cada um com o motivo na
## dica e um clique que leva até o problema; o resto vira "+N alertas".

## Clique num alerta: a célula para centralizar e o colono para selecionar (0 = nenhum).
signal alert_chosen(cell: Vector2i, colonist_id: int)

const MAX_VISIBLE := 5
const _WIDTH := 150
const _REFRESH_MSEC := 500

var _more: Label
## Texto dos alertas mostrados, para só remontar os botões quando mudam.
var _signature := ""
var _next_refresh_msec := 0


func _ready() -> void:
	custom_minimum_size.x = _WIDTH
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_more = Label.new()
	_more.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_more.mouse_filter = Control.MOUSE_FILTER_PASS
	_more.add_theme_color_override("font_color", UiTheme.TEXT_SECONDARY)
	add_child(_more)


func refresh(state: WorldState) -> void:
	var now := Time.get_ticks_msec()
	if now < _next_refresh_msec:
		return
	_next_refresh_msec = now + _REFRESH_MSEC
	show_alerts(Alerts.compute(state))


func show_alerts(alerts: Array[Dictionary]) -> void:
	var shown := alerts.slice(0, MAX_VISIBLE)
	var signature := "|".join(alerts.map(func(a: Dictionary) -> String: return "%s:%s:%s" % [a["text"], a["cell"], a["colonist_id"]]))
	if signature == _signature:
		return
	_signature = signature
	for child in get_children():
		if child != _more:
			remove_child(child)
			child.queue_free()
	for alert in shown:
		var button := Button.new()
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.clip_text = true
		button.focus_mode = Control.FOCUS_NONE
		button.icon = AssetCatalog.texture("ui/icons/alerts/danger" if alert["danger"] else "ui/icons/alerts/warning")
		button.text = alert["text"]
		button.tooltip_text = "%s\n%s" % [alert["text"], alert["tooltip"]]
		if alert["danger"]:
			button.add_theme_color_override("font_color", UiTheme.DANGER)
		var cell: Vector2i = alert["cell"]
		var colonist_id: int = alert["colonist_id"]
		button.disabled = cell == Alerts.NO_CELL and colonist_id == 0
		button.pressed.connect(func() -> void: alert_chosen.emit(cell, colonist_id))
		add_child(button)
	move_child(_more, -1)
	var hidden := alerts.slice(MAX_VISIBLE)
	_more.visible = not hidden.is_empty()
	_more.text = "+%d alertas" % hidden.size()
	_more.tooltip_text = "\n".join(hidden.map(func(a: Dictionary) -> String: return a["text"]))


func shown_count() -> int:
	return get_child_count() - 1
