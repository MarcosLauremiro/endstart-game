class_name Skills
extends RefCounted
## As 6 habilidades do MVP (GDD: Conteúdo exato do MVP), as afinidades e as regras de nível e XP.

enum Id { CONSTRUCTION, MINING, GROWING, COOKING, CRAFTING, MELEE }
## GDD: Aversão, Nenhuma, Interesse, Paixão.
enum Affinity { AVERSION, NONE, INTEREST, PASSION }

const ALL := [Id.CONSTRUCTION, Id.MINING, Id.GROWING, Id.COOKING, Id.CRAFTING, Id.MELEE]
const NAMES := {
	Id.CONSTRUCTION: "Construção",
	Id.MINING: "Mineração",
	Id.GROWING: "Cultivo",
	Id.COOKING: "Cozinha",
	Id.CRAFTING: "Artesanato",
	Id.MELEE: "Corpo a corpo",
}
## Chave usada nos recursos (.tres) para não depender do número do enum.
const KEYS := {
	&"construction": Id.CONSTRUCTION,
	&"mining": Id.MINING,
	&"growing": Id.GROWING,
	&"cooking": Id.COOKING,
	&"crafting": Id.CRAFTING,
	&"melee": Id.MELEE,
}
const AFFINITY_NAMES := {
	Affinity.AVERSION: "aversão",
	Affinity.NONE: "nenhuma",
	Affinity.INTEREST: "interesse",
	Affinity.PASSION: "paixão",
}
## Marca curta na ficha (só ASCII: a fonte pixel não tem símbolos).
const AFFINITY_MARKS := {
	Affinity.AVERSION: "x",
	Affinity.NONE: "",
	Affinity.INTEREST: "+",
	Affinity.PASSION: "++",
}
## GDD: multiplicador de XP por afinidade.
const AFFINITY_XP := {
	Affinity.AVERSION: 0.2,
	Affinity.NONE: 0.35,
	Affinity.INTEREST: 1.0,
	Affinity.PASSION: 1.5,
}
## GDD: fator de afinidade na pontuação das tarefas.
const AFFINITY_SCORE := {
	Affinity.AVERSION: 0.7,
	Affinity.NONE: 1.0,
	Affinity.INTEREST: 1.1,
	Affinity.PASSION: 1.3,
}
## GDD (Níveis): velocidade por nível nas pontas de cada faixa; entre elas, linear.
## 0–3 iniciante 40%–70%, 4–7 competente 70%–100%, 8–11 habilidoso 100%–125%,
## 12–15 especialista 125%–150%, 16–19 mestre 150%–175%, 20 lenda 180%.
const SPEED_POINTS := [
	Vector2(0, 0.4), Vector2(3, 0.7), Vector2(7, 1.0), Vector2(11, 1.25),
	Vector2(15, 1.5), Vector2(19, 1.75), Vector2(20, 1.8),
]
const TITLES := [
	[0, "Iniciante"], [4, "Competente"], [8, "Habilidoso"], [12, "Especialista"], [16, "Mestre"], [20, "Lenda"],
]


## Habilidade usada em cada tipo de trabalho; -1 = nenhuma (Carregar).
## Cortar plantas é Cultivo; no MVP a caça usa Corpo a corpo (Pontaria fica fora do MVP).
static func for_work(work_type: int) -> int:
	match work_type:
		WorkType.Id.CONSTRUCT:
			return Id.CONSTRUCTION
		WorkType.Id.MINE:
			return Id.MINING
		WorkType.Id.GROW, WorkType.Id.CUT:
			return Id.GROWING
		WorkType.Id.COOK:
			return Id.COOKING
		WorkType.Id.CRAFT:
			return Id.CRAFTING
		WorkType.Id.HUNT:
			return Id.MELEE
	return -1


static func name_of(skill: int) -> String:
	return NAMES.get(skill, "?")


static func from_key(key: StringName) -> int:
	assert(KEYS.has(key), "Habilidade desconhecida: %s" % key)
	return KEYS[key]


## Velocidade (e, no futuro, qualidade) pelo nível.
static func speed_at(level: int) -> float:
	var clamped := clampi(level, 0, Balance.SKILL_MAX_LEVEL)
	for i in range(1, SPEED_POINTS.size()):
		var high: Vector2 = SPEED_POINTS[i]
		if clamped <= high.x:
			var low: Vector2 = SPEED_POINTS[i - 1]
			return lerpf(low.y, high.y, (clamped - low.x) / (high.x - low.x))
	return SPEED_POINTS[-1].y


## GDD: XP para subir do nível n = 1.000 + 75 × n².
static func xp_to_next(level: int) -> float:
	return Balance.SKILL_XP_BASE_TO_LEVEL + Balance.SKILL_XP_PER_LEVEL_SQUARED * level * level


static func title_of(level: int) -> String:
	var title: String = TITLES[0][1]
	for entry in TITLES:
		if level >= entry[0]:
			title = entry[1]
	return title
