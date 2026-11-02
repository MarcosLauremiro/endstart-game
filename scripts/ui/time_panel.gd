class_name TimePanel
extends PanelContainer
## Topo direito da tela (GDD > Interface > Tela principal): dia, hora e velocidade do tempo.
## Os botões e os atalhos de teclado agem sobre o mesmo GameClock.

const _SPEED_NAMES := ["Normal", "Rápida", "Muito rápida"]

var _clock: GameClock
var _state: WorldState
var _date_label: Label
var _threat_label: Label
var _pause_button: Button
## multiplicador de velocidade → botão
var _speed_buttons := {}


func _ready() -> void:
	var row := HBoxContainer.new()
	add_child(row)
	_date_label = Label.new()
	_date_label.mouse_filter = Control.MOUSE_FILTER_PASS
	row.add_child(_date_label)
	_threat_label = Label.new()
	_threat_label.add_theme_color_override("font_color", UiTheme.DANGER)
	row.add_child(_threat_label)

	_pause_button = _make_button("ui/icons/time/pause", "Pausar (Espaço)")
	_pause_button.pressed.connect(func() -> void: _clock.toggle_pause())
	row.add_child(_pause_button)
	for index in Balance.SPEED_MULTIPLIERS.size():
		var speed: int = Balance.SPEED_MULTIPLIERS[index]
		var tooltip := "%s %d× (%d)" % [_SPEED_NAMES[index], speed, index + 1]
		var button := _make_button("ui/icons/time/speed_%d" % (index + 1), tooltip)
		button.pressed.connect(func() -> void: _clock.set_speed(speed))
		row.add_child(button)
		_speed_buttons[speed] = button


func bind(clock: GameClock, world_seed: int, state: WorldState = null) -> void:
	_clock = clock
	_state = state
	_date_label.tooltip_text = "Seed %d" % world_seed


func refresh() -> void:
	var text := "Dia %d · %s · %02d:00" % [_clock.day(), _clock.season_name(), _clock.hour()]
	if not _clock.paused and not _speed_buttons.has(_clock.speed):
		text += "  %d×" % _clock.speed
	_date_label.text = text
	_threat_label.text = threat_text(_state) if _state else ""
	_pause_button.set_pressed_no_signal(_clock.paused)
	for speed in _speed_buttons:
		_speed_buttons[speed].set_pressed_no_signal(not _clock.paused and _clock.speed == speed)


## "Ataque em 20 h (leste)" depois do aviso; "Ataque! 3 saqueadores" durante.
static func threat_text(state: WorldState) -> String:
	var raid := state.threats.raid
	if raid == null:
		return ""
	if raid.phase == Raid.Phase.WARNED:
		return "Ataque em %s (%s)" % [ThreatDirector.time_text(raid.arrival_tick - state.clock.tick), raid.side_name()]
	return "Ataque! %d saqueador(es)" % state.threats.raiders.size()


func _make_button(icon_id: String, tooltip: String) -> Button:
	var button := Button.new()
	button.icon = AssetCatalog.texture(icon_id)
	button.tooltip_text = tooltip
	button.toggle_mode = true
	# Sem foco: a barra de espaço deve pausar, não "clicar" o último botão usado.
	button.focus_mode = Control.FOCUS_NONE
	return button
