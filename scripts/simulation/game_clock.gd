class_name GameClock
extends RefCounted
## Relógio da simulação. Converte o tempo real decorrido em ticks fixos, então a simulação
## não depende do FPS. Não conhece cena nem interface.

## Ordem das estações = ordem das linhas nas folhas de sprites das plantas.
enum Season { SPRING, SUMMER, AUTUMN, WINTER }
const SEASON_NAMES := ["Primavera", "Verão", "Outono", "Inverno"]

var tick: int = 0
var paused: bool = false
var speed: int = Balance.SPEED_MULTIPLIERS[0]
## Libera a velocidade ultrarrápida (Balance.DEBUG_SPEED_MULTIPLIER).
var allow_debug_speed: bool = false

## Tempo real acumulado em ticks ainda não executados.
var _pending_ticks: float = 0.0


## Converte o tempo real de um quadro em uma quantidade de ticks a executar agora.
## Ticks além de Balance.MAX_TICKS_PER_FRAME são descartados (a simulação desacelera em vez de travar).
func advance(delta_seconds: float) -> int:
	if paused:
		return 0
	_pending_ticks += delta_seconds * speed * Balance.TICKS_PER_SECOND
	var due := int(_pending_ticks)
	_pending_ticks -= due
	return mini(due, Balance.MAX_TICKS_PER_FRAME)


func toggle_pause() -> void:
	paused = not paused


## Define a velocidade e retoma a simulação se estiver pausada.
## Retorna false, sem alterar nada, se o valor não for uma velocidade disponível.
func set_speed(value: int) -> bool:
	if not is_speed_available(value):
		push_error("Velocidade inválida: %d" % value)
		return false
	speed = value
	paused = false
	return true


func is_speed_available(value: int) -> bool:
	if Balance.SPEED_MULTIPLIERS.has(value):
		return true
	return allow_debug_speed and value == Balance.DEBUG_SPEED_MULTIPLIER


func register_tick() -> void:
	tick += 1


## Dia da colônia, começando em 1.
func day() -> int:
	return tick / Balance.TICKS_PER_DAY + 1


## Hora do dia, de 0 a 23.
func hour() -> int:
	return (tick / Balance.TICKS_PER_HOUR) % Balance.HOURS_PER_DAY


## Estação do calendário (no MVP só muda a arte).
func season() -> Season:
	return (((day() - 1) / Balance.DAYS_PER_SEASON) % Balance.SEASONS_PER_YEAR) as Season


func season_name() -> String:
	return SEASON_NAMES[season()]
