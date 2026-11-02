class_name Stump
extends RefCounted
## Toco deixado pelo corte de uma árvore. Não bloqueia a passagem e some sozinho com o tempo.

var id: int
var cell: Vector2i
## true = toco de árvore adulta (arte maior).
var from_adult: bool
var age_hours: int = 0


## Argumentos opcionais: o carregamento (SaveGame) cria a instância vazia e preenche os campos.
func _init(new_id: int = 0, new_cell := Vector2i.ZERO, adult: bool = false) -> void:
	id = new_id
	cell = new_cell
	from_adult = adult


func age_hour() -> void:
	age_hours += 1


func has_decayed() -> bool:
	return age_hours >= Balance.STUMP_DECAY_HOURS
