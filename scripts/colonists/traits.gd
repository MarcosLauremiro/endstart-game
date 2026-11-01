class_name Traits
extends RefCounted
## Os 8 traços do MVP (GDD: Conteúdo exato do MVP) com nome, efeito, raridade e espectro.
## Só um traço de cada espectro por pessoa. Raridade: comum peso 10, incomum 4, raro 1.

const HARDWORKING := &"hardworking"
const LAZY := &"lazy"
const OPTIMIST := &"optimist"
const PESSIMIST := &"pessimist"
const CURIOUS := &"curious"
const STRONG := &"strong"
const GLUTTON := &"glutton"
const COWARD := &"coward"

const COMMON := 10
const UNCOMMON := 4

## id → {name, effect, weight, spectrum}
const ALL := {
	HARDWORKING: {"name": "Esforçado", "weight": COMMON, "spectrum": &"work",
		"effect": "Trabalha 15% mais rápido; termina a tarefa mesmo quando o bloco de Trabalho acaba"},
	LAZY: {"name": "Preguiçoso", "weight": COMMON, "spectrum": &"work",
		"effect": "Trabalha 20% mais devagar; pausa de 15 min a cada 2 h de trabalho"},
	OPTIMIST: {"name": "Otimista", "weight": COMMON, "spectrum": &"outlook",
		"effect": "Humor base +6"},
	PESSIMIST: {"name": "Pessimista", "weight": COMMON, "spectrum": &"outlook",
		"effect": "Humor base -6"},
	CURIOUS: {"name": "Curioso", "weight": COMMON, "spectrum": &"past",
		"effect": "+25% nos pontos de conhecimento que gera; prefere tarefas com artefatos (×1,3)"},
	STRONG: {"name": "Forte", "weight": UNCOMMON, "spectrum": &"",
		"effect": "Força +2"},
	GLUTTON: {"name": "Glutão", "weight": COMMON, "spectrum": &"",
		"effect": "Come 30% a mais (a fome cai mais rápido)"},
	COWARD: {"name": "Covarde", "weight": COMMON, "spectrum": &"",
		"effect": "Evita tarefas perto de predadores"},
}


static func name_of(trait_id: StringName) -> String:
	return ALL[trait_id]["name"] if ALL.has(trait_id) else String(trait_id)


static func effect_of(trait_id: StringName) -> String:
	return ALL[trait_id]["effect"] if ALL.has(trait_id) else ""


## Sorteia de 1 a 3 traços pelos pesos, respeitando os espectros.
static func roll(rng: RandomNumberGenerator) -> Array[StringName]:
	var count := 1
	var roll_count := rng.randf()
	if roll_count < Balance.TRAIT_THREE_CHANCE:
		count = 3
	elif roll_count < Balance.TRAIT_THREE_CHANCE + Balance.TRAIT_TWO_CHANCE:
		count = 2
	var result: Array[StringName] = []
	for _i in count:
		var candidates: Array[StringName] = []
		var total := 0
		for trait_id in ALL:
			if _allowed(trait_id, result):
				candidates.append(trait_id)
				total += ALL[trait_id]["weight"]
		if candidates.is_empty():
			break
		var pick := rng.randi_range(1, total)
		for trait_id in candidates:
			pick -= ALL[trait_id]["weight"]
			if pick <= 0:
				result.append(trait_id)
				break
	return result


static func _allowed(trait_id: StringName, chosen: Array[StringName]) -> bool:
	if chosen.has(trait_id):
		return false
	var spectrum: StringName = ALL[trait_id]["spectrum"]
	if spectrum == &"":
		return true
	for other in chosen:
		if ALL[other]["spectrum"] == spectrum:
			return false
	return true
