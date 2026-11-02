class_name ColonistFactory
extends RefCounted
## Gera colonos seguindo o GDD (Geração e raridade), no escopo do MVP:
## 1) idade 16–70, a maioria entre 20 e 45; 2) infância e vida adulta; 3) Força (curva normal);
## 4) habilidades 0–3 + bônus das histórias + 1 a cada 10 anos nas da vida adulta;
## 5) de 1 a 3 interesses ou paixões e de 0 a 2 aversões; 6) de 1 a 3 traços; 7) teto de 70 na soma.
## Cultura de origem, incapacidades e fobias ficam fora do MVP.

const _NAMES := [
	"Ana", "Bento", "Caio", "Dara", "Elio", "Fia", "Gael", "Iara",
	"Joá", "Lia", "Nilo", "Otto", "Rui", "Tali", "Vina", "Zeca",
]
const _MAX_POSITIVE_AFFINITIES := 3
const _MAX_AVERSIONS := 2


static func create(id: int, cell: Vector2i, rng: RandomNumberGenerator, taken_names: Array[String]) -> Colonist:
	var colonist := Colonist.new()
	colonist.id = id
	colonist.cell = cell
	colonist.think_offset = id % Balance.THINK_INTERVAL_TICKS
	var available := _NAMES.filter(func(name: String) -> bool: return not taken_names.has(name))
	if available.is_empty():
		available = _NAMES
	colonist.display_name = available[rng.randi_range(0, available.size() - 1)]
	colonist.age = clampi(roundi(rng.randfn(Balance.COLONIST_AGE_MEAN, Balance.COLONIST_AGE_DEVIATION)),
		Balance.COLONIST_MIN_AGE, Balance.COLONIST_MAX_AGE)
	colonist.childhood = _pick(Defs.backstories(BackstoryDef.Stage.CHILDHOOD), rng)
	colonist.adulthood = _pick(Defs.backstories(BackstoryDef.Stage.ADULTHOOD), rng)
	colonist.traits = Traits.roll(rng)

	var rolled := roundi(rng.randfn(Balance.ATTRIBUTE_AVERAGE, Balance.ATTRIBUTE_DEVIATION))
	rolled += colonist.childhood.strength_bonus + colonist.adulthood.strength_bonus
	if colonist.has_trait(Traits.STRONG):
		rolled += Balance.STRONG_STRENGTH_BONUS
	colonist.strength = clampi(rolled, Balance.ATTRIBUTE_MIN, Balance.ATTRIBUTE_MAX)

	_roll_skills(colonist, rng)
	_roll_affinities(colonist, rng)
	for work_type in WorkType.COLUMNS:
		colonist.work_priorities[work_type] = Balance.DEFAULT_WORK_PRIORITY
	colonist.work_priorities[WorkType.Id.EMERGENCY] = Balance.DEFAULT_EMERGENCY_PRIORITY
	colonist.equipment.equip(&"tunic")
	colonist.equipment.equip(&"trousers")
	return colonist


static func _roll_skills(colonist: Colonist, rng: RandomNumberGenerator) -> void:
	var adult_years := maxi(0, colonist.age - Balance.ADULT_SKILL_FROM_AGE)
	for skill_id in Skills.ALL:
		colonist.skills[skill_id].level = rng.randi_range(0, Balance.SKILL_START_MAX)
	for story in [colonist.childhood, colonist.adulthood]:
		for key in story.skill_bonus:
			var state: SkillState = colonist.skills[Skills.from_key(key)]
			state.level += story.skill_bonus[key]
			if story == colonist.adulthood:
				state.level += adult_years / Balance.ADULT_SKILL_YEARS_PER_LEVEL
	# Teto do GDD: reduz as menores até a soma caber.
	var by_level: Array = Skills.ALL.duplicate()
	while _skill_sum(colonist) > Balance.SKILL_SUM_CAP:
		by_level.sort_custom(func(a: int, b: int) -> bool: return colonist.skills[a].level < colonist.skills[b].level)
		for skill_id in by_level:
			if colonist.skills[skill_id].level > 0:
				colonist.skills[skill_id].level -= 1
				break
	for skill_id in Skills.ALL:
		colonist.skills[skill_id].level = clampi(colonist.skills[skill_id].level, 0, Balance.SKILL_MAX_LEVEL)


## Interesses e paixões puxam para as habilidades das histórias; aversões, para as outras.
static func _roll_affinities(colonist: Colonist, rng: RandomNumberGenerator) -> void:
	var story_skills: Array[int] = []
	for story in [colonist.childhood, colonist.adulthood]:
		for key in story.skill_bonus:
			story_skills.append(Skills.from_key(key))
	var pool: Array = Skills.ALL.duplicate()
	var positives := rng.randi_range(1, _MAX_POSITIVE_AFFINITIES)
	for _i in positives:
		var choices := pool.filter(func(skill_id: int) -> bool: return story_skills.has(skill_id))
		if choices.is_empty() or rng.randf() >= Balance.STORY_AFFINITY_BIAS:
			choices = pool
		var skill_id: int = choices[rng.randi_range(0, choices.size() - 1)]
		pool.erase(skill_id)
		var passion := rng.randf() < Balance.PASSION_CHANCE
		colonist.skills[skill_id].affinity = Skills.Affinity.PASSION if passion else Skills.Affinity.INTEREST
	var aversions := rng.randi_range(0, _MAX_AVERSIONS)
	for _i in aversions:
		var choices := pool.filter(func(skill_id: int) -> bool: return not story_skills.has(skill_id))
		if choices.is_empty():
			break
		var skill_id: int = choices[rng.randi_range(0, choices.size() - 1)]
		pool.erase(skill_id)
		colonist.skills[skill_id].affinity = Skills.Affinity.AVERSION


static func _skill_sum(colonist: Colonist) -> int:
	var total := 0
	for skill_id in Skills.ALL:
		total += colonist.skills[skill_id].level
	return total


static func _pick(options: Array[BackstoryDef], rng: RandomNumberGenerator) -> BackstoryDef:
	return options[rng.randi_range(0, options.size() - 1)]
