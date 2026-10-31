class_name BerryBush
extends RefCounted
## Arbusto de frutas silvestres: começa como muda; crescido, dá porções reais que acabam
## e voltam a crescer com o tempo.

var id: int
var cell: Vector2i
var portions: int = Balance.BERRY_BUSH_MAX_PORTIONS
var growth_hours: int = Balance.BUSH_GROWTH_HOURS
var _hours_growing: int = 0


func _init(new_id: int, new_cell: Vector2i) -> void:
	id = new_id
	cell = new_cell


func is_mature() -> bool:
	return growth_hours >= Balance.BUSH_GROWTH_HOURS


## Muda só cresce; arbusto crescido refaz as frutas.
func grow_hour() -> void:
	if not is_mature():
		growth_hours += 1
		return
	if portions >= Balance.BERRY_BUSH_MAX_PORTIONS:
		_hours_growing = 0
		return
	_hours_growing += 1
	if _hours_growing >= Balance.BERRY_REGROW_HOURS:
		_hours_growing = 0
		portions += 1


func take_portion() -> bool:
	if portions <= 0:
		return false
	portions -= 1
	return true
