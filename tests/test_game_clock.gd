class_name TestGameClock
extends TestCase
## Relógio: ticks independentes do FPS, pausa, velocidades, limite por quadro, dia e hora.


func test_paused_clock_runs_no_ticks() -> void:
	var clock := GameClock.new()
	clock.toggle_pause()
	expect_equal(clock.advance(1.0), 0, "Relógio pausado não deve gerar ticks")


func test_normal_speed_runs_sixty_ticks_per_second() -> void:
	var clock := GameClock.new()
	expect_equal(clock.advance(0.5), 30, "Meio segundo a 1× deve gerar 30 ticks")


func test_triple_speed_multiplies_ticks() -> void:
	var clock := GameClock.new()
	expect(clock.set_speed(3), "Velocidade 3 deve ser aceita")
	expect_equal(clock.advance(0.25), 45, "Um quarto de segundo a 3× deve gerar 45 ticks")


func test_speeds_follow_rimworld() -> void:
	var clock := GameClock.new()
	expect_equal(Balance.SPEED_MULTIPLIERS, [1, 3, 6], "Velocidades devem ser 1×, 3× e 6×")
	expect(clock.set_speed(6), "Velocidade 6 deve ser aceita")
	expect_equal(clock.advance(0.25), 90, "Um quarto de segundo a 6× deve gerar 90 ticks")
	expect(not clock.set_speed(2), "2× não existe no modelo do RimWorld")


func test_debug_speed_requires_permission() -> void:
	var clock := GameClock.new()
	expect(not clock.set_speed(Balance.DEBUG_SPEED_MULTIPLIER), "15× deve ser recusada sem modo de desenvolvimento")
	clock.allow_debug_speed = true
	expect(clock.set_speed(Balance.DEBUG_SPEED_MULTIPLIER), "15× deve ser aceita com modo de desenvolvimento")
	expect_equal(clock.advance(1.0 / 16.0), 56, "1/16 s a 15× deve gerar 56 ticks")


func test_fractional_ticks_accumulate_across_frames() -> void:
	var clock := GameClock.new()
	var total := 0
	for _frame in 4:
		total += clock.advance(0.25)
	expect_equal(total, 60, "Quatro quadros de 0,25 s a 1× devem somar 60 ticks")


func test_frame_cap_drops_excess_time() -> void:
	var clock := GameClock.new()
	expect_equal(clock.advance(10.0), Balance.MAX_TICKS_PER_FRAME, "Um quadro longo deve ser limitado")
	expect_equal(clock.advance(0.0), 0, "O excesso de tempo não deve ser cobrado nos quadros seguintes")


func test_invalid_speed_is_rejected() -> void:
	var clock := GameClock.new()
	expect(not clock.set_speed(5), "Velocidade 5 não deve ser aceita")
	expect_equal(clock.speed, 1, "Velocidade deve permanecer em 1× após valor inválido")


func test_set_speed_resumes_paused_clock() -> void:
	var clock := GameClock.new()
	clock.toggle_pause()
	clock.set_speed(3)
	expect(not clock.paused, "Escolher uma velocidade deve retomar a simulação")


func test_similar_total_time_at_different_frame_rates() -> void:
	var sixty_fps := GameClock.new()
	var thirty_fps := GameClock.new()
	var ticks_sixty := 0
	var ticks_thirty := 0
	for _i in 60:
		ticks_sixty += sixty_fps.advance(1.0 / 60.0)
	for _i in 30:
		ticks_thirty += thirty_fps.advance(1.0 / 30.0)
	expect(absi(ticks_sixty - ticks_thirty) <= 1, "Um segundo de jogo deve render o mesmo número de ticks em qualquer FPS")


func test_day_and_hour_come_from_tick() -> void:
	var clock := GameClock.new()
	clock.tick = Balance.TICKS_PER_DAY + 2 * Balance.TICKS_PER_HOUR
	expect_equal(clock.day(), 2, "O tick de dois dias deve estar no dia 2")
	expect_equal(clock.hour(), 2, "Duas horas após a meia-noite devem marcar 02h")
