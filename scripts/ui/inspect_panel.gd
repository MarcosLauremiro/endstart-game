class_name InspectPanel
extends PanelContainer
## Ficha do colono (GDD: Interface do MVP > Ficha do colono), no canto inferior esquerdo.
## Abas: Geral (história, traços, necessidades, humor e pensamentos), Habilidades (nível, título,
## afinidade e XP), Equipamento (Camisa, Calça, Mão e carga) e Por quê (o motivo real da IA,
## as melhores tarefas avaliadas e as decisões recentes).

enum Tab { GENERAL, SKILLS, EQUIPMENT, WHY }

const _WIDTH := 260
const _HISTORY_SHOWN := 3
const _REJECTIONS_SHOWN := 3
const _TAB_NAMES := {
	Tab.GENERAL: "Geral",
	Tab.SKILLS: "Habilidades",
	Tab.EQUIPMENT: "Equipamento",
	Tab.WHY: "Por quê",
}

var _title: Label
var _actions: ActionBar
var _tab := Tab.GENERAL
## Tab → Button
var _tab_buttons := {}
## Tab → VBoxContainer
var _sections := {}
var _profile: Label
var _traits: Label
var _doing: Label
var _food_bar: ProgressBar
var _rest_bar: ProgressBar
var _mood_bar: ProgressBar
var _thoughts: Label
var _skills: Label
var _equipment: Label
var _why: Label
var _options: Label
var _history: Label
var _bar_styles := {}


func _ready() -> void:
	custom_minimum_size.x = _WIDTH
	var column := VBoxContainer.new()
	add_child(column)
	_title = _add_label(column, UiTheme.COMMUNITY)
	_actions = ActionBar.new()
	column.add_child(_actions)
	var tabs := HBoxContainer.new()
	column.add_child(tabs)
	for tab in _TAB_NAMES:
		var button := Button.new()
		button.text = _TAB_NAMES[tab]
		button.toggle_mode = true
		button.focus_mode = Control.FOCUS_NONE
		button.pressed.connect(func() -> void: _select_tab(tab))
		tabs.add_child(button)
		_tab_buttons[tab] = button
		var section := VBoxContainer.new()
		column.add_child(section)
		_sections[tab] = section

	var general: VBoxContainer = _sections[Tab.GENERAL]
	_profile = _add_label(general, UiTheme.TEXT_SECONDARY)
	_traits = _add_label(general, UiTheme.TEXT)
	_traits.mouse_filter = Control.MOUSE_FILTER_PASS
	_doing = _add_label(general, UiTheme.TEXT)
	_food_bar = _add_bar_row(general, "ui/icons/needs/hunger", "Fome")
	_rest_bar = _add_bar_row(general, "ui/icons/needs/sleep", "Sono")
	_mood_bar = _add_bar_row(general, "ui/icons/needs/mood", "Humor")
	_thoughts = _add_label(general, UiTheme.TEXT_SECONDARY)

	_skills = _add_label(_sections[Tab.SKILLS], UiTheme.TEXT)
	_equipment = _add_label(_sections[Tab.EQUIPMENT], UiTheme.TEXT)

	var why: VBoxContainer = _sections[Tab.WHY]
	_why = _add_label(why, UiTheme.TEXT_SECONDARY)
	_add_label(why, UiTheme.TEXT).text = "Melhores tarefas avaliadas"
	_options = _add_label(why, UiTheme.TEXT_SECONDARY)
	_add_label(why, UiTheme.TEXT).text = "Decisões recentes"
	_history = _add_label(why, UiTheme.TEXT_SECONDARY)
	for color_name in ["ok", "warn", "danger"]:
		var style := StyleBoxFlat.new()
		style.bg_color = {"ok": UiTheme.POSITIVE, "warn": UiTheme.COMMUNITY, "danger": UiTheme.DANGER}[color_name]
		_bar_styles[color_name] = style
	_select_tab(Tab.GENERAL)


func show_colonist(colonist: Colonist, simulation: Simulation) -> void:
	var state := simulation.state
	_title.text = "%s, %d anos" % [colonist.display_name, colonist.age]
	_actions.show_options(simulation, ContextActions.for_colonist(simulation, colonist))
	match _tab:
		Tab.GENERAL:
			_show_general(colonist, state)
		Tab.SKILLS:
			_skills.text = _skills_text(colonist)
		Tab.EQUIPMENT:
			_equipment.text = _equipment_text(colonist)
		Tab.WHY:
			_why.text = "Por quê: %s" % (colonist.action.reason if colonist.action else "aguardando a próxima decisão")
			_options.text = "\n".join(colonist.last_options) if not colonist.last_options.is_empty() else "nenhuma tarefa possível"
			_history.text = _history_text(colonist)


func _select_tab(tab: Tab) -> void:
	_tab = tab
	for key in _sections:
		_sections[key].visible = key == tab
		_tab_buttons[key].set_pressed_no_signal(key == tab)


func _show_general(colonist: Colonist, state: WorldState) -> void:
	_profile.text = "%s / %s · Força %d · agenda agora: %s" % [colonist.childhood.display_name, colonist.adulthood.display_name,
		colonist.strength, Schedule.name_of(colonist.block_at(state.clock.tick))]
	var names := colonist.traits.map(func(t: StringName) -> String: return Traits.name_of(t))
	_traits.text = "Traços: %s" % ", ".join(names)
	_traits.tooltip_text = "\n".join(colonist.traits.map(func(t: StringName) -> String:
		return "%s: %s" % [Traits.name_of(t), Traits.effect_of(t)]))
	var doing := colonist.action.label() if colonist.action else "nada"
	_doing.text = "%s — %s" % [colonist.state_name(), doing]
	_set_bar(_food_bar, colonist.needs.food, Balance.FOOD_FREE_TIME_THRESHOLD, Balance.FOOD_CRITICAL_THRESHOLD)
	_set_bar(_rest_bar, colonist.needs.rest, Balance.REST_FREE_TIME_THRESHOLD, Balance.REST_CRITICAL_THRESHOLD)
	_set_bar(_mood_bar, colonist.mood.value, Balance.MOOD_UNSTABLE_BELOW, Balance.MOOD_CRISIS_BELOW)
	var lines := PackedStringArray(["Humor %d (%s) -> alvo %d" % [
		roundi(colonist.mood.value), colonist.mood.state_name(), roundi(colonist.mood.target())]])
	for thought in colonist.mood.thoughts:
		lines.append("   %+d %s" % [roundi(thought["value"]), thought["label"]])
	_thoughts.text = "\n".join(lines)


static func _skills_text(colonist: Colonist) -> String:
	var lines := PackedStringArray()
	for skill_id in Skills.ALL:
		var state: SkillState = colonist.skills[skill_id]
		var mark: String = Skills.AFFINITY_MARKS[state.affinity]
		lines.append("%s %d%s · %s · %d%% · velocidade %d%%" % [Skills.name_of(skill_id), state.level,
			" " + mark if not mark.is_empty() else "", Skills.title_of(state.level), roundi(state.progress() * 100),
			roundi(Skills.speed_at(state.level) * 100)])
	lines.append("++ paixão · + interesse · x aversão")
	return "\n".join(lines)


static func _equipment_text(colonist: Colonist) -> String:
	var lines := PackedStringArray()
	for slot in Equipment.SLOT_NAMES:
		var item: StringName = colonist.equipment.in_slot(slot)
		var text := "vazio"
		if item != &"":
			var definition := Defs.item(item)
			text = definition.display_name
			var bonuses := PackedStringArray()
			for key in definition.work_bonus:
				bonuses.append("%s ×%s" % [WorkType.name_of(WorkType.from_key(key)), str(definition.work_bonus[key]).replace(".", ",")])
			if definition.hunt_damage > 0.0:
				bonuses.append("caça: alcance %d, dano %d" % [definition.hunt_range, roundi(definition.hunt_damage)])
			if not bonuses.is_empty():
				text += " (%s)" % ", ".join(bonuses)
		lines.append("%s: %s" % [Equipment.SLOT_NAMES[slot], text])
	if colonist.carrying_count > 0:
		lines.append("Carregando: %d %s" % [colonist.carrying_count, Defs.item(colonist.carrying_item).display_name.to_lower()])
	var ratio := colonist.load_kg() / colonist.carry_capacity_kg()
	lines.append("Carga: %.1f / %.0f kg (%d%%)%s" % [colonist.load_kg(), colonist.carry_capacity_kg(), roundi(ratio * 100),
		" · mais lento" if colonist.load_move_factor() < 1.0 else ""])
	return "\n".join(lines)


func _history_text(colonist: Colonist) -> String:
	var lines := PackedStringArray()
	for record in colonist.history.slice(0, _HISTORY_SHOWN):
		var hour: int = (record.tick / Balance.TICKS_PER_HOUR) % Balance.HOURS_PER_DAY
		var minute: int = (record.tick % Balance.TICKS_PER_HOUR) * 60 / Balance.TICKS_PER_HOUR
		var outcome: String = " (%s)" % record.outcome if not record.outcome.is_empty() else " (em andamento)"
		lines.append("%02d:%02d %s%s" % [hour, minute, record.chosen, outcome])
		for rejection in record.rejected.slice(0, _REJECTIONS_SHOWN):
			lines.append("   não: %s" % rejection)
	return "\n".join(lines)


func _set_bar(bar: ProgressBar, value: float, warn_below: float, danger_below: float) -> void:
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


func _add_bar_row(parent: Control, icon_id: String, tooltip: String) -> ProgressBar:
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
