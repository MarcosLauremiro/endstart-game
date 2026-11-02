class_name TestFullGame
extends TestCase
## Partida completa curta (GDD M8; a de 30 dias roda com tests/full_game.gd): 2 dias com o
## jogador automático. A colônia se organiza sozinha a partir das ordens, ninguém morre e salvar
## no meio continua igual.

const _SEED := 12345


func test_two_days_with_an_attentive_player() -> void:
	var simulation := Simulation.new(_SEED, 3)
	var state := simulation.state
	var player := FullGamePlayer.new(simulation)
	var last_tick := simulation.clock.tick + 2 * Balance.TICKS_PER_DAY
	var worst_ms := 0.0
	while simulation.clock.tick < last_tick:
		player.act()
		var start := Time.get_ticks_usec()
		simulation.step()
		worst_ms = maxf(worst_ms, (Time.get_ticks_usec() - start) / 1000.0)
	expect_equal(state.colonists.size(), 3, "Ninguém morre em 2 dias")
	expect(state.beds().size() >= 3, "Uma cama por colono (havia %d)" % state.beds().size())
	var benches := state.workbenches.values().map(func(b: Workbench) -> StringName: return b.def().id)
	expect(benches.has(&"campfire") and benches.has(&"crafting_bench"), "Fogueira e bancada prontas (havia %s)" % [benches])
	expect(state.has_study_desk(), "Mesa de estudos pronta")
	expect(state.total_count(&"wood") > 0 and state.total_count(&"simple_meal") > 0, "Ainda há madeira e refeições")
	expect(worst_ms < 50.0, "Nenhum tick trava o jogo (pior %.1f ms)" % worst_ms)
	var copy := Simulation.from_state(SaveGame.restore(SaveGame.snapshot(state)))
	for _i in 3000:
		simulation.step()
		copy.step()
	expect(SaveGame.snapshot(copy.state) == SaveGame.snapshot(state), "Salvar no meio da partida continua igual")
