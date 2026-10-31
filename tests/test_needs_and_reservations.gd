class_name TestNeedsAndReservations
extends TestCase
## Ritmo das necessidades e regras de reserva.


func test_needs_decay_while_awake() -> void:
	var needs := Needs.new()
	for _i in Balance.TICKS_PER_HOUR:
		needs.tick(false)
	expect(absf(needs.food - (100.0 - 100.0 / 30.0)) < 0.01, "Fome deve cair 1/30 por hora (está em %.3f)" % needs.food)
	expect(absf(needs.rest - (100.0 - 100.0 / 32.0)) < 0.01, "Sono deve cair 1/32 por hora (está em %.3f)" % needs.rest)


func test_sleep_recovers_rest_but_not_food() -> void:
	var needs := Needs.new()
	needs.rest = 50.0
	for _i in Balance.TICKS_PER_HOUR:
		needs.tick(true)
	expect(absf(needs.rest - 60.0) < 0.01, "Dormir no chão recupera 10 de sono por hora (está em %.3f)" % needs.rest)
	expect(needs.food < 100.0, "Dormir não alimenta")


func test_needs_are_clamped() -> void:
	var needs := Needs.new()
	needs.food = 0.0
	needs.rest = 0.0
	needs.tick(false)
	expect_equal(needs.food, 0.0, "Fome não fica negativa")
	expect_equal(needs.rest, 0.0, "Sono não fica negativo")
	needs.eat(500.0)
	expect_equal(needs.food, Balance.NEED_MAX, "Comer não passa do máximo")


func test_reservation_has_single_owner() -> void:
	var reservations := Reservations.new()
	var key := Reservations.bush_key(7)
	expect(reservations.try_reserve(key, 1), "Primeiro colono reserva")
	expect(reservations.try_reserve(key, 1), "Reservar de novo para o mesmo dono é permitido")
	expect(not reservations.try_reserve(key, 2), "Outro colono não pode reservar")
	reservations.release(key, 2)
	expect_equal(reservations.owner_of(key), 1, "Só o dono pode liberar")
	reservations.release_all(1)
	expect_equal(reservations.owner_of(key), 0, "release_all solta tudo do dono")
	expect(reservations.try_reserve(key, 2), "Depois de liberada, outro pode reservar")


func test_bush_regrows_over_time() -> void:
	var bush := BerryBush.new(1, Vector2i.ZERO)
	bush.portions = 0
	for _hour in Balance.BERRY_REGROW_HOURS:
		bush.grow_hour()
	expect_equal(bush.portions, 1, "Uma porção volta a cada %d horas" % Balance.BERRY_REGROW_HOURS)
	expect(bush.take_portion(), "Pode colher a porção que cresceu")
	expect(not bush.take_portion(), "Arbusto vazio não dá porção")
