class_name ColonistFactory
extends RefCounted
## Gera colonos. Por enquanto: nome, idade, Força (curva normal do GDD), no máximo um traço de trabalho
## e prioridades padrão. O gerador completo do GDD (histórias, habilidades, afinidades, 1 a 3 traços)
## entra no M5 e substitui este.

const _NAMES := [
	"Ana", "Bento", "Caio", "Dara", "Elio", "Fia", "Gael", "Iara",
	"Joá", "Lia", "Nilo", "Otto", "Rui", "Tali", "Vina", "Zeca",
]
const _MIN_AGE := 20
const _MAX_AGE := 45
## Sorteio do traço de trabalho: nenhum, Esforçado ou Preguiçoso, com a mesma chance.
const _WORK_TRAIT_OPTIONS := [&"", Traits.HARDWORKING, Traits.LAZY]


static func create(id: int, cell: Vector2i, rng: RandomNumberGenerator, taken_names: Array[String]) -> Colonist:
	var colonist := Colonist.new()
	colonist.id = id
	colonist.cell = cell
	colonist.age = rng.randi_range(_MIN_AGE, _MAX_AGE)
	colonist.think_offset = id % Balance.THINK_INTERVAL_TICKS
	var available := _NAMES.filter(func(name: String) -> bool: return not taken_names.has(name))
	if available.is_empty():
		available = _NAMES
	colonist.display_name = available[rng.randi_range(0, available.size() - 1)]
	var rolled := roundi(rng.randfn(Balance.ATTRIBUTE_AVERAGE, Balance.ATTRIBUTE_DEVIATION))
	colonist.strength = clampi(rolled, Balance.ATTRIBUTE_MIN, Balance.ATTRIBUTE_MAX)
	var work_trait: StringName = _WORK_TRAIT_OPTIONS[rng.randi_range(0, _WORK_TRAIT_OPTIONS.size() - 1)]
	if work_trait != &"":
		colonist.traits.append(work_trait)
	for work_type in WorkType.COLUMNS:
		colonist.work_priorities[work_type] = Balance.DEFAULT_WORK_PRIORITY
	return colonist
