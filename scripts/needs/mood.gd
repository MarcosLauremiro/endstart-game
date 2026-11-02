class_name Mood
extends RefCounted
## Humor de 0 a 100 (GDD: Humor). Anda cerca de 12 pontos por dia em direção ao humor-alvo:
## 50 + soma dos pensamentos - expectativa. Pensamentos do MVP: fome, sono, traços (Otimista,
## Pessimista), lembranças com prazo (dormir no chão) e o sentimento pelo trabalho (afinidade).
## A lista é refeita a cada pensamento do colono; o valor anda a cada tick.

enum State { EXTREME_CRISIS, CRISIS, UNSTABLE, NEUTRAL, CONTENT, INSPIRED }

## Limite inferior de cada estado (GDD: Faixa).
const STATE_FLOORS := [
	[85.0, State.INSPIRED], [65.0, State.CONTENT], [35.0, State.NEUTRAL],
	[25.0, State.UNSTABLE], [10.0, State.CRISIS], [0.0, State.EXTREME_CRISIS],
]
const STATE_NAMES := {
	State.EXTREME_CRISIS: "Crise extrema",
	State.CRISIS: "Crise",
	State.UNSTABLE: "Instável",
	State.NEUTRAL: "Neutro",
	State.CONTENT: "Contente",
	State.INSPIRED: "Inspirado",
}

var value: float = Balance.MOOD_START
## Pensamentos atuais: {"label": String, "value": float}
var thoughts: Array[Dictionary] = []
## Lembranças com prazo: id → {"label", "value", "until_tick"}
var memories := {}
## Sentimento pelo trabalho por afinidade (interesse, paixão, aversão), com teto e decaimento.
var work_feelings := {}


func target() -> float:
	var total := 50.0 - Balance.MOOD_EXPECTATION_SETTLEMENT
	for thought in thoughts:
		total += thought["value"]
	return clampf(total, 0.0, Balance.MOOD_MAX)


func tick() -> void:
	value = move_toward(value, target(), Balance.MOOD_SPEED_PER_TICK)


## Refaz os pensamentos a partir do estado do colono.
func refresh(colonist: Colonist, tick_now: int) -> void:
	thoughts.clear()
	var needs := colonist.needs
	if needs.food < Balance.FOOD_CRITICAL_THRESHOLD:
		_add("Faminto", Balance.STARVING_MOOD)
	elif needs.food < Balance.FOOD_FREE_TIME_THRESHOLD:
		_add("Com fome", Balance.HUNGRY_MOOD)
	if needs.rest < Balance.REST_CRITICAL_THRESHOLD:
		_add("Exausto", Balance.EXHAUSTED_MOOD)
	elif needs.rest < Balance.REST_FREE_TIME_THRESHOLD:
		_add("Cansado", Balance.TIRED_MOOD)
	var damage := colonist.health.damage()
	if damage >= 1.0:
		_add("Com dor", roundf(damage * Balance.PAIN_MOOD_PER_DAMAGE))
	if colonist.has_trait(Traits.OPTIMIST):
		_add("Otimista", Balance.OPTIMIST_MOOD)
	if colonist.has_trait(Traits.PESSIMIST):
		_add("Pessimista", Balance.PESSIMIST_MOOD)
	for id in memories.keys():
		var memory: Dictionary = memories[id]
		if memory["until_tick"] <= tick_now:
			memories.erase(id)
		else:
			_add(memory["label"], memory["value"])
	for affinity in work_feelings:
		var feeling: float = work_feelings[affinity]
		if absf(feeling) >= 0.5:
			_add(_feeling_label(affinity), feeling)


func remember(id: StringName, label: String, mood: float, hours: int, tick_now: int) -> void:
	memories[id] = {"label": label, "value": mood, "until_tick": tick_now + hours * Balance.TICKS_PER_HOUR}


func forget(id: StringName) -> void:
	memories.erase(id)


## Um tick de trabalho numa habilidade com afinidade (GDD: humor ao trabalhar).
func feel_work(affinity: Skills.Affinity) -> void:
	if not Balance.WORK_FEELING_PER_HOUR.has(affinity):
		return
	var step: float = Balance.WORK_FEELING_PER_HOUR[affinity] / Balance.TICKS_PER_HOUR
	var cap: float = Balance.WORK_FEELING_CAP[affinity]
	var current: float = work_feelings.get(affinity, 0.0)
	work_feelings[affinity] = minf(current + step, cap) if cap > 0.0 else maxf(current + step, cap)


## Uma hora de jogo: os sentimentos de trabalho somem devagar.
func hour_passed() -> void:
	for affinity in work_feelings.keys():
		work_feelings[affinity] = move_toward(work_feelings[affinity], 0.0, Balance.WORK_FEELING_DECAY_PER_HOUR)


func state() -> State:
	for entry in STATE_FLOORS:
		if value >= entry[0]:
			return entry[1]
	return State.EXTREME_CRISIS


func state_name() -> String:
	return STATE_NAMES[state()]


## GDD: contente ou melhor ×1,1; instável ou pior ×0,8.
func xp_factor() -> float:
	var current := state()
	if current >= State.CONTENT:
		return Balance.XP_CONTENT_FACTOR
	if current <= State.UNSTABLE:
		return Balance.XP_UNSTABLE_FACTOR
	return 1.0


func _add(label: String, mood: float) -> void:
	thoughts.append({"label": label, "value": mood})


static func _feeling_label(affinity: int) -> String:
	match affinity:
		Skills.Affinity.PASSION:
			return "Trabalhou no que ama"
		Skills.Affinity.INTEREST:
			return "Trabalhou no que gosta"
	return "Trabalhou no que detesta"
