class_name Needs
extends RefCounted
## Necessidades do colono, de 0 (vazia) a 100 (satisfeita). Só mudam com o tempo ou com uma ação
## válida (comer, dormir): nada é restaurado de graça.

var food: float = Balance.NEED_MAX
var rest: float = Balance.NEED_MAX


## hunger_factor: Glutão come 30% a mais (a fome cai 1,3× mais rápido).
func tick(sleeping: bool, in_bed: bool = false, hunger_factor: float = 1.0) -> void:
	food = maxf(food - Balance.FOOD_DECAY_PER_TICK * hunger_factor, 0.0)
	if sleeping:
		var recovery := Balance.REST_BED_RECOVERY_PER_TICK if in_bed else Balance.REST_GROUND_RECOVERY_PER_TICK
		rest = minf(rest + recovery, Balance.NEED_MAX)
	else:
		rest = maxf(rest - Balance.REST_DECAY_PER_TICK, 0.0)


func eat(nutrition: float) -> void:
	food = minf(food + nutrition, Balance.NEED_MAX)
