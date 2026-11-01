class_name ResearchDef
extends Resource
## Uma pesquisa da árvore (GDD: Árvore de pesquisa). Um .tres por pesquisa em res://resources/research/.
## Custa pontos da comunidade e é liberada na hora na Mesa de estudos; libera construções e receitas.

@export var id: StringName
@export var display_name: String
## Ramo da árvore (Research.BRANCHES).
@export var branch: StringName
@export var level: int = 1
## Custo em pontos: Prática (P) e Vestígio (V).
@export var cost_practice: int = 0
@export var cost_relic: int = 0
## Pesquisas que precisam estar liberadas antes.
@export var requires: Array[StringName] = []
## Ids das estruturas e receitas que ficam disponíveis.
@export var unlocks_structures: Array[StringName] = []
@export var unlocks_recipes: Array[StringName] = []
## O que libera, em palavras (painel de pesquisa).
@export var unlocks_text: String


func cost_text() -> String:
	var parts := PackedStringArray()
	if cost_practice > 0:
		parts.append("%d P" % cost_practice)
	if cost_relic > 0:
		parts.append("%d V" % cost_relic)
	return ", ".join(parts)
