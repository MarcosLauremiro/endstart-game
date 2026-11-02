class_name WorkType
extends RefCounted
## Tipos de trabalho da grade de prioridades (GDD: Prioridades de trabalho).
## Só os tipos que já têm tarefas existem aqui; os outros entram com seus marcos.

enum Id { CONSTRUCT, GROW, MINE, CUT, HAUL, COOK, HUNT, CRAFT, RESEARCH, EMERGENCY }

## Ordem das colunas do GDD: com prioridades iguais, vale esta ordem.
const COLUMNS := [Id.EMERGENCY, Id.COOK, Id.HUNT, Id.CONSTRUCT, Id.GROW, Id.MINE, Id.CUT, Id.CRAFT, Id.HAUL, Id.RESEARCH]
const NAMES := {
	Id.EMERGENCY: "Emergência",
	Id.COOK: "Cozinhar",
	Id.HUNT: "Caçar",
	Id.CONSTRUCT: "Construir",
	Id.GROW: "Cultivar",
	Id.MINE: "Minerar",
	Id.CUT: "Cortar plantas",
	Id.CRAFT: "Artesanato",
	Id.HAUL: "Carregar",
	Id.RESEARCH: "Pesquisar",
}
## Chave usada nos recursos (.tres) para não depender do número do enum.
const KEYS := {
	&"cook": Id.COOK,
	&"hunt": Id.HUNT,
	&"construct": Id.CONSTRUCT,
	&"grow": Id.GROW,
	&"mine": Id.MINE,
	&"cut": Id.CUT,
	&"craft": Id.CRAFT,
	&"haul": Id.HAUL,
	&"research": Id.RESEARCH,
	&"emergency": Id.EMERGENCY,
}


static func name_of(work_type: int) -> String:
	return NAMES.get(work_type, "?")


static func key_of(work_type: int) -> StringName:
	return KEYS.find_key(work_type)


static func from_key(key: StringName) -> int:
	assert(KEYS.has(key), "Tipo de trabalho desconhecido: %s" % key)
	return KEYS[key]


## GDD: Força muda a velocidade de construção e mineração.
static func uses_strength(work_type: int) -> bool:
	return work_type == Id.MINE or work_type == Id.CONSTRUCT
