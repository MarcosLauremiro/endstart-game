class_name SkillState
extends RefCounted
## Nível, XP e afinidade de um colono numa habilidade, com o controle diário do GDD
## (limite de 4.000 XP por dia e esquecimento acima do nível 12 sem prática).

var level: int = 0
var xp: float = 0.0
var affinity: Skills.Affinity = Skills.Affinity.NONE
var xp_today: float = 0.0
var practiced_today: bool = false


func _init(start_level: int = 0, start_affinity: Skills.Affinity = Skills.Affinity.NONE) -> void:
	level = start_level
	affinity = start_affinity


## Soma XP (já com os multiplicadores) e sobe de nível. Devolve quantos níveis subiu.
func add_xp(amount: float) -> int:
	practiced_today = true
	if xp_today >= Balance.SKILL_DAILY_XP_SOFT_CAP:
		amount *= Balance.SKILL_OVER_CAP_XP_FACTOR
	xp_today += amount
	xp += amount
	var gained := 0
	while level < Balance.SKILL_MAX_LEVEL and xp >= Skills.xp_to_next(level):
		xp -= Skills.xp_to_next(level)
		level += 1
		gained += 1
	if level >= Balance.SKILL_MAX_LEVEL:
		xp = 0.0
	return gained


## Virada do dia: zera o limite diário e aplica o esquecimento (GDD). Devolve se perdeu nível.
func end_day() -> bool:
	var lost_level := false
	if not practiced_today and level > Balance.SKILL_FORGET_FROM_LEVEL:
		var loss := Balance.SKILL_FORGET_XP_PER_DAY
		if level > Balance.SKILL_FORGET_FAST_FROM_LEVEL:
			loss = Balance.SKILL_FORGET_FAST_XP_PER_DAY
		xp -= loss
		if xp < 0.0:
			level -= 1
			xp += Skills.xp_to_next(level)
			lost_level = true
	xp_today = 0.0
	practiced_today = false
	return lost_level


func progress() -> float:
	if level >= Balance.SKILL_MAX_LEVEL:
		return 1.0
	return xp / Skills.xp_to_next(level)
