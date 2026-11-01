class_name TestDaylight
extends TestCase
## Dia e noite (GDD): horas de luz pela fórmula da latitude temperada e luz suave ao longo do dia.


func test_hours_of_light_follow_the_seasons() -> void:
	var middle := Balance.DAYS_PER_SEASON / 2 + 1
	expect(absf(Daylight.hours_of_light(middle) - 12.0) < 0.3, "Meio da primavera: ~12 h")
	expect(absf(Daylight.hours_of_light(middle + Balance.DAYS_PER_SEASON) - 15.0) < 0.3, "Meio do verão: ~15 h")
	expect(absf(Daylight.hours_of_light(middle + 3 * Balance.DAYS_PER_SEASON) - 9.0) < 0.3, "Meio do inverno: ~9 h")


func test_light_through_the_day() -> void:
	var day_start := 0
	expect_equal(Daylight.light_at(day_start + 2 * Balance.TICKS_PER_HOUR), 0.0, "02 h: noite")
	expect_equal(Daylight.light_at(day_start + 12 * Balance.TICKS_PER_HOUR), 1.0, "Meio-dia: dia claro")
	var dusk := Daylight.light_at(day_start + roundi(Daylight.sunset_hour(1) * Balance.TICKS_PER_HOUR))
	expect(dusk > 0.0 and dusk < 1.0, "No pôr do sol, meia-luz (%.2f)" % dusk)
	expect_equal(Daylight.light_at(day_start + 23 * Balance.TICKS_PER_HOUR), 0.0, "23 h: noite")
