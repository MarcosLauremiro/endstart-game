extends SceneTree
## Partida completa headless (GDD M8: uma partida de 30 dias roda do começo ao fim). Uso:
##   godot --headless --path . -s res://tests/full_game.gd -- --days=30 --colonists=5 --seed=12345 [--player]
## Imprime um resumo por dia e, no fim, o tempo por tick (média, p99, pior) e o que aconteceu.
## --player faz o que um jogador faria no começo (FullGamePlayer): camas, bancadas, pedidos,
## plantação, armas antes dos ataques.

func _init() -> void:
	var options := {"days": 30, "colonists": 5, "seed": 12345, "player": false}
	for argument in OS.get_cmdline_user_args():
		if argument == "--player":
			options["player"] = true
		elif argument.begins_with("--") and argument.contains("="):
			var parts := argument.trim_prefix("--").split("=")
			options[parts[0]] = int(parts[1])
	var simulation := Simulation.new(options["seed"], options["colonists"])
	var state := simulation.state
	var messages: Array[String] = []
	# A função guarda só o relógio: guardar a simulação dentro do próprio sinal dela seria um ciclo.
	var clock := simulation.clock
	simulation.message_posted.connect(func(text: String) -> void: messages.append("Dia %d %02dh: %s" % [clock.day(), clock.hour(), text]))
	var player: FullGamePlayer = FullGamePlayer.new(simulation) if options["player"] else null
	var durations := PackedFloat32Array()
	var last_tick: int = simulation.clock.tick + options["days"] * Balance.TICKS_PER_DAY
	var day := simulation.clock.day()
	while simulation.clock.tick < last_tick and not state.colonists.is_empty():
		if player:
			player.act()
		var start := Time.get_ticks_usec()
		simulation.step()
		durations.append((Time.get_ticks_usec() - start) / 1000.0)
		if simulation.clock.day() != day:
			day = simulation.clock.day()
			print(_day_line(simulation))
	var sorted := durations.duplicate()
	sorted.sort()
	var total := 0.0
	var slow := 0
	for value in durations:
		total += value
		if value > 2.0:
			slow += 1
	print("\nTicks: %d · média %.3f ms · p99 %.3f ms · pior %.2f ms · acima de 2 ms: %d" % [durations.size(), total / durations.size(),
		sorted[int(sorted.size() * 0.99)], sorted[-1], slow])
	print("Tempo real a 3×: %.1f%% de um quadro de 60 fps em média" % [total / durations.size() * Balance.TICKS_PER_SECOND * 3 / (1000.0 / 60.0) / 60.0 * 100.0])
	print("Colonos vivos: %d de %d · ataques sobrevividos: %d" % [state.colonists.size(), options["colonists"], state.threats.raids_survived])
	print("\nMensagens marcantes:")
	for message in messages:
		if ["morreu", "Ataque", "caiu", "saqueador", "Sem lugar", "Fumaça", "pesquisa", "Pesquisa", "fome"].any(func(word: String) -> bool: return message.contains(word)):
			print("  ", message)
	quit()


static func _day_line(simulation: Simulation) -> String:
	var state := simulation.state
	var daily := Balance.DAILY_FOOD_NEED * maxi(state.colonists.size(), 1)
	var food := 0.0
	var mood := 0.0
	var hurt := 0
	for colonist in state.colonists:
		food += colonist.needs.food
		mood += colonist.mood.value
		if colonist.health.is_hurt():
			hurt += 1
	var count := maxi(state.colonists.size(), 1)
	var alerts := Alerts.compute(state).map(func(a: Dictionary) -> String: return a["text"])
	return "Dia %2d · colonos %d (feridos %d) · fome média %3.0f%% · humor médio %3.0f · comida guardada %.1f d · madeira %d · refeições %d · camas %d · alertas: %s" % [
		simulation.clock.day(), state.colonists.size(), hurt, food / count, mood / count, state.stored_nutrition() / daily,
		state.total_count(&"wood"), state.total_count(&"simple_meal"), state.beds().size(), ", ".join(alerts)]
