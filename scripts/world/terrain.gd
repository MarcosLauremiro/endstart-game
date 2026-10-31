class_name Terrain
extends RefCounted
## Tipos de terreno do MVP. Os valores do enum são os índices gravados em WorldData
## e os tiles do atlas provisório (ver WorldView). Não altere a ordem sem migrar saves.

enum Kind { GRASS, DIRT, TALL_GRASS, SHALLOW_WATER, DEEP_WATER, ROCK }


static func is_valid(kind: int) -> bool:
	return kind >= 0 and kind < Kind.size()


## Fator de movimento do GDD (Dificuldade do terreno). 0 = intransponível.
static func move_factor(kind: int) -> float:
	match kind:
		Kind.GRASS, Kind.DIRT:
			return 1.0
		Kind.TALL_GRASS:
			return 0.9
		Kind.SHALLOW_WATER:
			return 0.4
		Kind.DEEP_WATER, Kind.ROCK:
			return 0.0
	push_error("Terreno desconhecido: %d" % kind)
	return 0.0


## Fertilidade do GDD (Dificuldade do terreno); -1 = não cultivável. Grama comum segue o Solo.
static func fertility(kind: int) -> float:
	match kind:
		Kind.GRASS, Kind.DIRT, Kind.TALL_GRASS:
			return 1.0
	return -1.0


## Se dá para construir, pela tabela do GDD.
static func build_rule(kind: int) -> String:
	match kind:
		Kind.GRASS, Kind.DIRT, Kind.TALL_GRASS:
			return "sim"
		Kind.SHALLOW_WATER:
			return "só pontes"
		Kind.DEEP_WATER:
			return "não"
		Kind.ROCK:
			return "depois de escavar"
	return "?"


static func is_passable(kind: int) -> bool:
	return move_factor(kind) > 0.0


static func display_name(kind: int) -> String:
	match kind:
		Kind.GRASS:
			return "Grama"
		Kind.DIRT:
			return "Solo"
		Kind.TALL_GRASS:
			return "Grama alta"
		Kind.SHALLOW_WATER:
			return "Água rasa"
		Kind.DEEP_WATER:
			return "Água funda"
		Kind.ROCK:
			return "Rocha"
	push_error("Terreno desconhecido: %d" % kind)
	return "?"
