class_name TestSimulation
extends TestCase
## Estado da partida: avanço por tempo real, sinal de tick e reprodutibilidade do mundo.


func test_advance_runs_ticks_and_emits_signal() -> void:
	var simulation := Simulation.new(7)
	var emitted: Array[int] = []
	simulation.ticked.connect(func(tick: int) -> void: emitted.append(tick))
	simulation.advance(0.5)
	var start := Balance.START_HOUR * Balance.TICKS_PER_HOUR
	expect_equal(simulation.clock.tick, start + 30, "Meio segundo a 1× deve avançar 30 ticks")
	expect_equal(emitted.size(), 30, "Cada tick deve emitir o sinal ticked")
	expect_equal(emitted.back(), start + 30, "O último sinal deve trazer o tick atual")


func test_paused_simulation_keeps_world_static() -> void:
	var simulation := Simulation.new(7)
	simulation.clock.toggle_pause()
	simulation.advance(5.0)
	expect_equal(simulation.clock.tick, Balance.START_HOUR * Balance.TICKS_PER_HOUR, "Partida pausada não deve avançar")
	expect_equal(simulation.clock.hour(), Balance.START_HOUR, "A partida começa às 6 h")


func test_same_seed_gives_same_world() -> void:
	var first := Simulation.new(99)
	var second := Simulation.new(99)
	expect_equal(first.world.fingerprint(), second.world.fingerprint(), "Mesma seed deve dar o mesmo mundo")
