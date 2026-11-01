class_name WorkbenchPanel
extends PanelContainer
## Painel da bancada (GDD: Painel de inspeção > Bancada: fila de pedidos com condições).
## Aparece quando o tile selecionado tem uma bancada. Cada pedido: modo (fazer N, até ter X, sempre),
## meta (clique ±1, botão direito ±10), pausar, subir na fila e apagar. O primeiro pedido possível
## da fila é o que se faz. O motivo de cada colono fica no painel do tile. Ordens passam pelas APIs da simulação.

const _WIDTH := 290
const _REFRESH_MSEC := 250
const _BIG_STEP := 10
const _MODE_ORDER := [Bill.Mode.UNTIL, Bill.Mode.COUNT, Bill.Mode.FOREVER]

var _simulation: Simulation
var _bench_id := 0
var _title: Label
var _status: Label
var _rows: VBoxContainer
var _recipes: HFlowContainer
## Pedidos mostrados na última montagem, para saber quando remontar.
var _shown_bills: Array[Bill] = []
## Label → Bill
var _bill_labels := {}
var _next_refresh_msec := 0


func _ready() -> void:
	custom_minimum_size.x = _WIDTH
	var column := VBoxContainer.new()
	add_child(column)
	_title = Label.new()
	_title.add_theme_color_override("font_color", UiTheme.COMMUNITY)
	column.add_child(_title)
	_status = Label.new()
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(_status)
	var queue_header := Label.new()
	queue_header.text = "Fila de pedidos (o primeiro possível é feito)"
	queue_header.add_theme_color_override("font_color", UiTheme.TEXT_SECONDARY)
	column.add_child(queue_header)
	_rows = VBoxContainer.new()
	column.add_child(_rows)
	var add_header := Label.new()
	add_header.text = "Novo pedido:"
	add_header.add_theme_color_override("font_color", UiTheme.TEXT_SECONDARY)
	column.add_child(add_header)
	_recipes = HFlowContainer.new()
	column.add_child(_recipes)


func bind(simulation: Simulation) -> void:
	_simulation = simulation
	_bench_id = 0


func show_bench(bench: Workbench) -> void:
	if bench.id != _bench_id:
		_bench_id = bench.id
		_rebuild_recipes(bench)
		_next_refresh_msec = 0
	if _shown_bills != bench.bills:
		_rebuild_rows(bench)
		_next_refresh_msec = 0
	var now := Time.get_ticks_msec()
	if now < _next_refresh_msec:
		return
	_next_refresh_msec = now + _REFRESH_MSEC
	var state := _simulation.state
	_title.text = "%s · %s · velocidade ×%s" % [
		bench.def().display_name, WorkType.name_of(bench.work_type()), str(bench.def().bench_speed).replace(".", ",")]
	_status.text = _status_text(bench, state)
	for label in _bill_labels:
		label.text = _bill_labels[label].describe(state)


func _status_text(bench: Workbench, state: WorldState) -> String:
	var task := state.task_board.craft_for_bench(bench.id)
	var lines := PackedStringArray()
	if bench.job:
		var line := "Em andamento: %s · ingredientes %s" % [bench.job.recipe.display_name, bench.staged_text()]
		if task and task.progress > 0.0 and task.work_required > 0.0:
			line += " · %d%% feito" % roundi(task.progress / task.work_required * 100)
		lines.append(line)
	var next := bench.next_bill(state)
	if next.has("bill"):
		lines.append("Próximo: %s" % next["bill"].recipe.display_name)
	else:
		lines.append("Parada: %s" % next["reason"])
	return "\n".join(lines)


func _rebuild_recipes(bench: Workbench) -> void:
	for child in _recipes.get_children():
		child.queue_free()
	for recipe in Defs.recipes_for(bench.def().id):
		var button := Button.new()
		button.text = "+ %s" % recipe.display_name
		button.tooltip_text = "%s -> %s, %s h" % [recipe.ingredients_text(), recipe.products_text(), str(recipe.work_hours).replace(".", ",")]
		button.focus_mode = Control.FOCUS_NONE
		button.pressed.connect(func() -> void: _simulation.add_bill(_bench_id, recipe.id))
		_recipes.add_child(button)


func _rebuild_rows(bench: Workbench) -> void:
	for child in _rows.get_children():
		child.queue_free()
	_bill_labels.clear()
	_shown_bills = bench.bills.duplicate()
	if bench.bills.is_empty():
		var empty := Label.new()
		empty.text = "   (vazia)"
		empty.add_theme_color_override("font_color", UiTheme.TEXT_SECONDARY)
		_rows.add_child(empty)
	for bill in bench.bills:
		var row := HBoxContainer.new()
		_rows.add_child(row)
		var label := Label.new()
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		label.clip_text = true
		row.add_child(label)
		_bill_labels[label] = bill
		row.add_child(_small_button("modo", "Trocar o modo: até ter X -> fazer N -> sempre", func() -> void: _cycle_mode(bill)))
		var minus := _small_button("-", "Meta -1 (botão direito: -%d)" % _BIG_STEP, Callable())
		minus.gui_input.connect(_on_step_input.bind(minus, bill, -1))
		row.add_child(minus)
		var plus := _small_button("+", "Meta +1 (botão direito: +%d)" % _BIG_STEP, Callable())
		plus.gui_input.connect(_on_step_input.bind(plus, bill, 1))
		row.add_child(plus)
		row.add_child(_small_button("||", "Pausar ou retomar", func() -> void: _simulation.set_bill_paused(bill, not bill.paused)))
		row.add_child(_small_button("^", "Subir na fila", func() -> void: _simulation.move_bill(_bench_id, bill, -1)))
		row.add_child(_small_button("x", "Apagar o pedido (ingredientes separados voltam ao chão)",
			func() -> void: _simulation.remove_bill(_bench_id, bill)))


func _small_button(text: String, tooltip: String, action: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.tooltip_text = tooltip
	button.focus_mode = Control.FOCUS_NONE
	if action.is_valid():
		button.pressed.connect(action)
	return button


func _cycle_mode(bill: Bill) -> void:
	var next: Bill.Mode = _MODE_ORDER[(_MODE_ORDER.find(bill.mode) + 1) % _MODE_ORDER.size()]
	_simulation.set_bill_mode(bill, next, bill.target)
	_next_refresh_msec = 0


func _on_step_input(event: InputEvent, button: Button, bill: Bill, direction: int) -> void:
	if not event is InputEventMouseButton or not event.pressed:
		return
	var amount := 0
	if event.button_index == MOUSE_BUTTON_LEFT:
		amount = 1
	elif event.button_index == MOUSE_BUTTON_RIGHT:
		amount = _BIG_STEP
	if amount == 0:
		return
	button.accept_event()
	_simulation.set_bill_mode(bill, bill.mode, bill.target + direction * amount)
	_next_refresh_msec = 0
