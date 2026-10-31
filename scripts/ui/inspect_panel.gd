class_name InspectPanel
extends PanelContainer
## Canto inferior esquerdo (GDD > Interface): o colono selecionado, suas necessidades,
## o que está fazendo e por quê. O texto vem dos DecisionRecord reais da IA.

const _WIDTH := 250
const _HISTORY_SHOWN := 3
const _REJECTIONS_SHOWN := 3

var _title: Label
var _profile: Label
var _doing: Label
var _why: Label
var _food_bar: ProgressBar
var _rest_bar: ProgressBar
var _options: Label
var _history: Label
var _bar_styles := {}


func _ready() -> void:
	custom_minimum_size.x = _WIDTH
	var column := VBoxContainer.new()
	add_child(column)
	_title = _add_label(column, UiTheme.COMMUNITY)
	_profile = _add_label(column, UiTheme.TEXT_SECONDARY)
	_doing = _add_label(column, UiTheme.TEXT)
	_why = _add_label(column, UiTheme.TEXT_SECONDARY)
	_food_bar = _add_need_row(column, "ui/icons/needs/hunger", "Fome")
	_rest_bar = _add_need_row(column, "ui/icons/needs/sleep", "Sono")
	_add_label(column, UiTheme.TEXT).text = "Melhores tarefas avaliadas"
	_options = _add_label(column, UiTheme.TEXT_SECONDARY)
	_add_label(column, UiTheme.TEXT).text = "Decisões recentes"
	_history = _add_label(column, UiTheme.TEXT_SECONDARY)
	for color_name in ["ok", "warn", "danger"]:
		var style := StyleBoxFlat.new()
		style.bg_color = {"ok": UiTheme.POSITIVE, "warn": UiTheme.COMMUNITY, "danger": UiTheme.DANGER}[color_name]
		_bar_styles[color_name] = style


func show_colonist(colonist: Colonist, state: WorldState) -> void:
	_title.text = "%s, %d anos" % [colonist.display_name, colonist.age]
	var trait_names := colonist.traits.map(func(t: StringName) -> String: return Traits.name_of(t))
	var profile := "Força %d · %s" % [colonist.strength, ", ".join(trait_names) if not trait_names.is_empty() else "sem traço de trabalho"]
	if colonist.carrying_count > 0:
		profile += " · carrega %d %s" % [colonist.carrying_count, Defs.item(colonist.carrying_item).display_name]
	_profile.text = profile
	var doing := colonist.action.label() if colonist.action else "nada"
	_doing.text = "%s — %s" % [colonist.state_name(), doing]
	_why.text = "Por quê: %s" % (colonist.action.reason if colonist.action else "aguardando a próxima decisão")
	_set_need(_food_bar, colonist.needs.food, Balance.FOOD_FREE_TIME_THRESHOLD, Balance.FOOD_CRITICAL_THRESHOLD)
	_set_need(_rest_bar, colonist.needs.rest, Balance.REST_FREE_TIME_THRESHOLD, Balance.REST_CRITICAL_THRESHOLD)
	_options.text = "\n".join(colonist.last_options) if not colonist.last_options.is_empty() else "nenhuma tarefa possível"
	_history.text = _history_text(colonist, state)


func _history_text(colonist: Colonist, state: WorldState) -> String:
	var lines := PackedStringArray()
	for record in colonist.history.slice(0, _HISTORY_SHOWN):
		var hour: int = (record.tick / Balance.TICKS_PER_HOUR) % Balance.HOURS_PER_DAY
		var minute: int = (record.tick % Balance.TICKS_PER_HOUR) * 60 / Balance.TICKS_PER_HOUR
		var outcome: String = " (%s)" % record.outcome if not record.outcome.is_empty() else " (em andamento)"
		lines.append("%02d:%02d %s%s" % [hour, minute, record.chosen, outcome])
		for rejection in record.rejected.slice(0, _REJECTIONS_SHOWN):
			lines.append("   não: %s" % rejection)
	return "\n".join(lines)


func _set_need(bar: ProgressBar, value: float, warn_below: float, danger_below: float) -> void:
	bar.value = value
	var key := "ok"
	if value < danger_below:
		key = "danger"
	elif value < warn_below:
		key = "warn"
	bar.add_theme_stylebox_override("fill", _bar_styles[key])


func _add_label(parent: Control, color: Color) -> Label:
	var label := Label.new()
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_color_override("font_color", color)
	parent.add_child(label)
	return label


func _add_need_row(parent: Control, icon_id: String, tooltip: String) -> ProgressBar:
	var row := HBoxContainer.new()
	row.tooltip_text = tooltip
	parent.add_child(row)
	var icon := TextureRect.new()
	icon.texture = AssetCatalog.texture(icon_id)
	row.add_child(icon)
	var bar := ProgressBar.new()
	bar.max_value = Balance.NEED_MAX
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(bar)
	return bar
