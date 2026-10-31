class_name Stump
extends RefCounted
## Toco deixado pelo corte de uma árvore. Não bloqueia a passagem e some sozinho com o tempo.

var id: int
var cell: Vector2i
## true = toco de árvore adulta (arte maior).
var from_adult: bool
var age_hours: int = 0


func _init(new_id: int, new_cell: Vector2i, adult: bool) -> void:
	id = new_id
	cell = new_cell
	from_adult = adult


func age_hour() -> void:
	age_hours += 1


func has_decayed() -> bool:
	return age_hours >= Balance.STUMP_DECAY_HOURS
