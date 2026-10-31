class_name Needs
extends RefCounted
## Necessidades do colono, de 0 (vazia) a 100 (satisfeita). Só mudam com o tempo ou com uma ação
## válida (comer, dormir): nada é restaurado de graça.

var food: float = Balance.NEED_MAX
var rest: float = Balance.NEED_MAX


func tick(sleeping: bool, in_bed: bool = false) -> void:
	food = maxf(food - Balance.FOOD_DECAY_PER_TICK, 0.0)
	if sleeping:
		var recovery := Balance.REST_BED_RECOVERY_PER_TICK if in_bed else Balance.REST_GROUND_RECOVERY_PER_TICK
		rest = minf(rest + recovery, Balance.NEED_MAX)
	else:
		rest = maxf(rest - Balance.REST_DECAY_PER_TICK, 0.0)


func eat(nutrition: float) -> void:
	food = minf(food + nutrition, Balance.NEED_MAX)
