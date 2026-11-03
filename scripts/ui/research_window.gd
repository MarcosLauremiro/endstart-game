class_name ResearchWindow
extends PanelContainer
## Janela de Pesquisa (GDD: Janelas > Pesquisa). Pontos no topo; ramos revelados com as pesquisas,
## o custo, o que liberam e o botão de liberar; ramos escondidos aparecem como "???" com a dica.
## Liberar é imediato (GDD), desde que haja uma Mesa de estudos e os pontos.

const _REFRESH_MSEC := 250

var _simulation: Simulation
var _points: Label
var _list: VBoxContainer
var _next_refresh_msec := 0
## Assinatura do último estado mostrado, para só remontar quando algo muda.
var _signature := ""


func _ready() -> void:
	var column := VBoxContainer.new()
	add_child(column)
	var title := Label.new()
	title.text = "Pesquisa (R) — ações geram pontos; com uma Mesa de estudos, a pesquisa é liberada na hora"
	title.add_theme_color_override("font_color", UiTheme.ANCIENT)
	column.add_child(title)
	WindowDrag.attach(self, title)
	_points = Label.new()
	column.add_child(_points)
	_list = VBoxContainer.new()
	column.add_child(_list)


func bind(simulation: Simulation) -> void:
	_simulation = simulation
	_signature = ""
	_next_refresh_msec = 0


func refresh() -> void:
	var now := Time.get_ticks_msec()
	if now < _next_refresh_msec:
		return
	_next_refresh_msec = now + _REFRESH_MSEC
	var state := _simulation.state
	var research := state.research
	var desk := state.has_study_desk()
	_points.text = "Prática: %d P · Vestígio: %d V · Mesa de estudos: %s" % [
		floori(research.points[Research.Points.PRACTICE]), floori(research.points[Research.Points.RELIC]),
		"pronta" if desk else "falta construir"]
	var rows: Array[Dictionary] = []
	for branch in Research.BRANCHES:
		if not research.is_branch_revealed(branch):
			var trigger: StringName = Research.BRANCHES[branch]["trigger"]
			rows.append({"header": "??? — ramo escondido: %s" % Research.TRIGGER_HINTS[trigger]})
			continue
		rows.append({"header": Research.BRANCHES[branch]["name"]})
		for definition in Defs.researches():
			if definition.branch == branch:
				rows.append({"research": definition, "problem": research.unlock_problem(definition, desk)})
	var signature := str(rows.map(func(row: Dictionary) -> String: return "%s%s" % [row.get("header", ""), row.get("problem", "")]))
	if signature == _signature:
		return
	_signature = signature
	for child in _list.get_children():
		child.queue_free()
	for row in rows:
		if row.has("header"):
			var header := Label.new()
			header.text = row["header"]
			header.add_theme_color_override("font_color", UiTheme.COMMUNITY)
			_list.add_child(header)
			continue
		_list.add_child(_research_row(row["research"], row["problem"]))


func _research_row(definition: ResearchDef, problem: String) -> Control:
	var row := HBoxContainer.new()
	var label := Label.new()
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.text = "%s (nível %d) — %s — libera: %s" % [definition.display_name, definition.level, definition.cost_text(), definition.unlocks_text]
	row.add_child(label)
	var button := Button.new()
	button.focus_mode = Control.FOCUS_NONE
	if problem == "já liberada":
		button.text = "Liberada"
		button.disabled = true
	else:
		button.text = "Liberar"
		button.disabled = not problem.is_empty()
		button.tooltip_text = problem if not problem.is_empty() else "Gasta %s" % definition.cost_text()
		button.pressed.connect(func() -> void:
			_simulation.state.post_message(_simulation.unlock_research(definition.id))
			_next_refresh_msec = 0)
	row.add_child(button)
	return row
