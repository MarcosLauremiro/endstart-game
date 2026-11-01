class_name StoragePanel
extends PanelContainer
## Painel de armazenamento (GDD: Interface de armazenamento, versão do MVP com totais e busca).
## Totais por item somados dos itens reais; lista de contêineres com ocupação. Clicar num contêiner
## centraliza a câmera nele. A busca filtra os itens e mostra só os contêineres que os têm.

signal container_focused(cell: Vector2i)

const _WIDTH := 300
const _REFRESH_MSEC := 300

var _simulation: Simulation
var _search: LineEdit
var _totals: Label
var _list: VBoxContainer
var _next_refresh_msec := 0


func _ready() -> void:
	custom_minimum_size.x = _WIDTH
	var column := VBoxContainer.new()
	add_child(column)
	var title := Label.new()
	title.text = "Armazém (I)"
	title.add_theme_color_override("font_color", UiTheme.COMMUNITY)
	column.add_child(title)
	_search = LineEdit.new()
	_search.placeholder_text = "Buscar item…"
	_search.text_changed.connect(func(_text: String) -> void: _next_refresh_msec = 0)
	column.add_child(_search)
	_totals = Label.new()
	_totals.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(_totals)
	var header := Label.new()
	header.text = "Contêineres"
	header.add_theme_color_override("font_color", UiTheme.TEXT_SECONDARY)
	column.add_child(header)
	_list = VBoxContainer.new()
	column.add_child(_list)


func bind(simulation: Simulation) -> void:
	_simulation = simulation
	_next_refresh_msec = 0


func refresh() -> void:
	var now := Time.get_ticks_msec()
	if now < _next_refresh_msec:
		return
	_next_refresh_msec = now + _REFRESH_MSEC
	var state := _simulation.state
	var wanted := _matching_items()
	var lines := PackedStringArray()
	for item in wanted:
		var total := state.total_count(item)
		if total <= 0 and _search.text.is_empty():
			continue
		var stored := 0
		for container in state.containers.values():
			stored += container.count_of(item)
		var ground := 0
		for stack in state.stacks.values():
			if stack.item == item:
				ground += stack.count
		lines.append("%s: %d (contêineres %d · chão %d · mãos %d)" % [
			Defs.item(item).display_name, total, stored, ground, total - stored - ground])
	var daily := Balance.DAILY_FOOD_NEED * maxi(state.colonists.size(), 1)
	lines.append("Comida guardada: %.1f dias" % (state.stored_nutrition() / daily))
	_totals.text = "\n".join(lines)
	_rebuild_list(state, wanted)


## Itens cujo nome contém o texto buscado (todos, se a busca estiver vazia).
func _matching_items() -> Array[StringName]:
	var query := _search.text.strip_edges().to_lower()
	var result: Array[StringName] = []
	for definition in Defs.items():
		if query.is_empty() or definition.display_name.to_lower().contains(query):
			result.append(definition.id)
	return result


func _rebuild_list(state: WorldState, wanted: Array[StringName]) -> void:
	for child in _list.get_children():
		child.queue_free()
	var filtering := not _search.text.strip_edges().is_empty()
	for container in state.containers.values():
		var contents: Dictionary = container.contents()
		var shown := PackedStringArray()
		for item in contents:
			if wanted.has(item):
				shown.append("%d %s" % [contents[item], Defs.item(item).display_name.to_lower()])
		if filtering and shown.is_empty():
			continue
		var used := 0
		for slot in container.slots:
			if slot["item"] != &"":
				used += 1
		var button := Button.new()
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.clip_text = true
		button.focus_mode = Control.FOCUS_NONE
		button.text = "%s #%d (%d, %d) · %d/%d espaços%s" % [
			container.def.display_name, container.id, container.cell.x, container.cell.y, used, container.slots.size(),
			" · " + ", ".join(shown) if not shown.is_empty() else ""]
		button.tooltip_text = button.text
		var cell: Vector2i = container.cell
		button.pressed.connect(func() -> void: container_focused.emit(cell))
		_list.add_child(button)
