class_name Daylight
extends RefCounted
## Luz do dia (GDD: Dia e noite). Horas de luz = 12 + A × sen(2π × (dia − 7,5) / 60), com o dia
## claro centrado no meio-dia. O MVP é floresta temperada: A = 3 (9 h de luz no inverno, 15 h no
## verão). Amanhecer e anoitecer passam de escuro a claro ao longo de uma hora.
## Por enquanto só a arte usa a luz; as regras do GDD sem luz (trabalho -20%, plantas sem crescer)
## ficam para quando houver iluminação artificial.


## Horas de luz no dia do ano (dia 1 = início da primavera).
static func hours_of_light(day: int) -> float:
	var day_of_year := float((day - 1) % (Balance.DAYS_PER_SEASON * Balance.SEASONS_PER_YEAR)) + 1.0
	var year_days := float(Balance.DAYS_PER_SEASON * Balance.SEASONS_PER_YEAR)
	return 12.0 + Balance.DAYLIGHT_AMPLITUDE_HOURS * sin(TAU * (day_of_year - 7.5) / year_days)


static func sunrise_hour(day: int) -> float:
	return 12.0 - hours_of_light(day) / 2.0


static func sunset_hour(day: int) -> float:
	return 12.0 + hours_of_light(day) / 2.0


## Luz de 0 (noite) a 1 (dia) no tick, com transição suave no amanhecer e no anoitecer.
static func light_at(tick: int) -> float:
	var day := tick / Balance.TICKS_PER_DAY + 1
	var hour := float(tick % Balance.TICKS_PER_DAY) / Balance.TICKS_PER_HOUR
	var half := Balance.TWILIGHT_HOURS / 2.0
	var dawn := clampf((hour - (sunrise_hour(day) - half)) / Balance.TWILIGHT_HOURS, 0.0, 1.0)
	var dusk := clampf(((sunset_hour(day) + half) - hour) / Balance.TWILIGHT_HOURS, 0.0, 1.0)
	return smoothstep(0.0, 1.0, minf(dawn, dusk))
