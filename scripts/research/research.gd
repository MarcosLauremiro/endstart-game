class_name Research
extends RefCounted
## Conhecimento da comunidade (GDD: Conhecimento e pesquisa). Ações geram pontos de Prática (P) e
## Vestígio (V), que são da comunidade inteira; ações-gatilho revelam ramos da árvore; com os pontos
## e uma Mesa de estudos, a pesquisa é liberada na hora. No MVP: P e V, 6 pesquisas, sem provas.

enum Points { PRACTICE, RELIC }

const POINT_NAMES := {Points.PRACTICE: "Prática", Points.RELIC: "Vestígio"}
const POINT_LETTERS := {Points.PRACTICE: "P", Points.RELIC: "V"}
## Ramos do MVP, na ordem do GDD, com o gatilho que os revela ("" = desde o início).
const BRANCHES := {
	&"survival": {"name": "Sobrevivência", "trigger": &""},
	&"agriculture": {"name": "Agricultura e alimentação", "trigger": &""},
	&"construction": {"name": "Construção", "trigger": &""},
	&"defense": {"name": "Defesa e armas", "trigger": &"first_hunt"},
	&"rediscovery": {"name": "Redescoberta", "trigger": &"artifact_found"},
}
## Como revelar um ramo escondido (o painel mostra "???" com a dica).
const TRIGGER_HINTS := {
	&"first_hunt": "caçar o primeiro animal (ou sofrer o primeiro ataque)",
	&"artifact_found": "encontrar um artefato numa ruína",
}

var points := {Points.PRACTICE: 0.0, Points.RELIC: 0.0}
## id da pesquisa → true
var unlocked := {}
## gatilho → true
var triggers := {}
## O que a comunidade já fez pela primeira vez (GDD: +3 P).
var firsts := {}
## id do colono → ticks de trabalho produtivo ainda não convertidos em P.
var _work_ticks := {}


func is_unlocked(research_id: StringName) -> bool:
	return unlocked.has(research_id)


func is_branch_revealed(branch: StringName) -> bool:
	var trigger: StringName = BRANCHES[branch]["trigger"]
	return trigger == &"" or triggers.has(trigger)


## Dispara um gatilho. Devolve o nome do ramo revelado agora, ou "".
func fire_trigger(trigger: StringName) -> String:
	if triggers.has(trigger):
		return ""
	triggers[trigger] = true
	for branch in BRANCHES:
		if BRANCHES[branch]["trigger"] == trigger:
			return BRANCHES[branch]["name"]
	return ""


## Soma pontos (GDD: Curioso +25% em todos os pontos que gera).
func add_points(kind: Points, amount: float, colonist: Colonist = null) -> float:
	var gained := amount
	if colonist and colonist.has_trait(Traits.CURIOUS):
		gained *= Balance.CURIOUS_POINTS_FACTOR
	points[kind] += gained
	return gained


## Um tick de trabalho produtivo do colono (GDD: a cada 3 horas, 1 P).
func work_tick(colonist: Colonist) -> void:
	var ticks: int = _work_ticks.get(colonist.id, 0) + 1
	if ticks >= Balance.PRACTICE_POINT_WORK_TICKS:
		ticks = 0
		add_points(Points.PRACTICE, 1.0, colonist)
	_work_ticks[colonist.id] = ticks


## Primeira vez que a comunidade faz algo (GDD: +3 P). Devolve se foi a primeira.
func record_first(key: String) -> bool:
	if firsts.has(key):
		return false
	firsts[key] = true
	add_points(Points.PRACTICE, Balance.FIRST_TIME_PRACTICE)
	return true


## Por que a pesquisa não pode ser liberada agora, ou "".
func unlock_problem(definition: ResearchDef, has_study_desk: bool) -> String:
	if is_unlocked(definition.id):
		return "já liberada"
	if not is_branch_revealed(definition.branch):
		return "ramo ainda escondido"
	for required in definition.requires:
		if not is_unlocked(required):
			return "precisa de %s" % Defs.research(required).display_name
	if not has_study_desk:
		return "construa uma Mesa de estudos"
	var missing := PackedStringArray()
	if points[Points.PRACTICE] < definition.cost_practice:
		missing.append("%d P" % ceili(definition.cost_practice - points[Points.PRACTICE]))
	if points[Points.RELIC] < definition.cost_relic:
		missing.append("%d V" % ceili(definition.cost_relic - points[Points.RELIC]))
	if not missing.is_empty():
		return "faltam %s" % ", ".join(missing)
	return ""


func unlock(definition: ResearchDef) -> void:
	points[Points.PRACTICE] -= definition.cost_practice
	points[Points.RELIC] -= definition.cost_relic
	unlocked[definition.id] = true


## Pesquisa que libera a estrutura, se ainda falta; null se já está disponível.
func missing_for_structure(structure_id: StringName) -> ResearchDef:
	for definition in Defs.researches():
		if definition.unlocks_structures.has(structure_id) and not is_unlocked(definition.id):
			return definition
	return null


func missing_for_recipe(recipe_id: StringName) -> ResearchDef:
	for definition in Defs.researches():
		if definition.unlocks_recipes.has(recipe_id) and not is_unlocked(definition.id):
			return definition
	return null


## Libera tudo (cenários de teste que testam o uso, não a pesquisa).
func unlock_all() -> void:
	for definition in Defs.researches():
		unlocked[definition.id] = true
	for branch in BRANCHES:
		var trigger: StringName = BRANCHES[branch]["trigger"]
		if trigger != &"":
			triggers[trigger] = true
