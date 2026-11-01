class_name ActionBar
extends HFlowContainer
## Linha de botões com as opções do que está selecionado (ContextActions).
## Só remonta os botões quando a lista muda, para um clique nunca cair num botão recém-trocado.

## Avisa depois de executar uma opção, para o painel se atualizar na hora.
signal option_used

var _simulation: Simulation
## Rótulos e estados da última lista mostrada.
var _signature := ""


func show_options(simulation: Simulation, options: Array[Dictionary]) -> void:
	_simulation = simulation
	var signature := "|".join(options.map(func(o: Dictionary) -> String: return "%s:%s" % [o["label"], o["enabled"]]))
	visible = not options.is_empty()
	if signature == _signature:
		return
	_signature = signature
	for child in get_children():
		child.queue_free()
	for option in options:
		var button := Button.new()
		button.text = option["label"]
		button.tooltip_text = option["tooltip"]
		button.disabled = not option["enabled"]
		button.focus_mode = Control.FOCUS_NONE
		var run: Callable = option["run"]
		button.pressed.connect(func() -> void: _use(run))
		add_child(button)


func _use(run: Callable) -> void:
	var message: String = run.call()
	if not message.is_empty():
		_simulation.state.post_message(message)
	_signature = ""
	option_used.emit()
