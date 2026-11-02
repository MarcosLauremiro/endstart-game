class_name Combat
extends RefCounted
## Regras do combate do MVP (GDD: corpo a corpo e arco). Colonos e saqueadores usam as mesmas:
## a arma na mão define dano, alcance, intervalo entre golpes e o ferimento; o acerto depende da
## distância e do nível de Corpo a corpo; a Força aumenta o dano corpo a corpo (6% por ponto).

const _UNARMED := &""


static func damage_of(weapon: StringName) -> float:
	if weapon != _UNARMED and Defs.item(weapon).attack_damage > 0.0:
		return Defs.item(weapon).attack_damage
	return Balance.UNARMED_ATTACK_DAMAGE


static func range_of(weapon: StringName) -> int:
	if weapon != _UNARMED and Defs.item(weapon).attack_damage > 0.0:
		return Defs.item(weapon).attack_range
	return 1


static func is_ranged(weapon: StringName) -> bool:
	return range_of(weapon) > 1


static func cooldown_of(weapon: StringName) -> int:
	return Balance.RANGED_ATTACK_TICKS if is_ranged(weapon) else Balance.MELEE_ATTACK_TICKS


static func injury_of(weapon: StringName) -> Injury.Kind:
	if weapon != _UNARMED and Defs.item(weapon).attack_damage > 0.0:
		return Injury.kind_from_key(Defs.item(weapon).attack_kind)
	return Injury.Kind.BRUISE


## Corpo a corpo alcança os 8 vizinhos; à distância, um círculo do alcance da arma.
static func in_reach(weapon: StringName, from: Vector2i, to: Vector2i) -> bool:
	var reach := range_of(weapon)
	if reach <= 1:
		return absi(from.x - to.x) <= 1 and absi(from.y - to.y) <= 1
	return from.distance_squared_to(to) <= reach * reach


static func hit_chance(weapon: StringName, distance: float, melee_level: int) -> float:
	var chance: float
	if is_ranged(weapon):
		chance = Balance.RANGED_HIT_BASE - Balance.RANGED_HIT_FALLOFF_PER_TILE * distance + Balance.RANGED_HIT_PER_LEVEL * melee_level
	else:
		chance = Balance.MELEE_HIT_BASE + Balance.MELEE_HIT_PER_LEVEL * melee_level
	return clampf(chance, Balance.HIT_CHANCE_MIN, Balance.HIT_CHANCE_MAX)


## Um golpe ou disparo. Devolve o dano causado (0 = errou).
static func strike(state: WorldState, weapon: StringName, melee_level: int, strength: int,
		from: Vector2i, to: Vector2i, target: Health) -> float:
	var distance := Vector2(from).distance_to(Vector2(to))
	if state.rng.randf() >= hit_chance(weapon, distance, melee_level):
		return 0.0
	var amount := damage_of(weapon) * state.rng.randf_range(1.0 - Balance.DAMAGE_SPREAD, 1.0 + Balance.DAMAGE_SPREAD)
	if not is_ranged(weapon):
		amount *= 1.0 + Balance.ATTRIBUTE_STEP * (strength - Balance.ATTRIBUTE_AVERAGE)
	target.add_injury(injury_of(weapon), amount)
	return amount
