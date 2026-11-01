class_name Crop
extends RefCounted
## Uma planta semeada num tile de plantação. Cresce por hora conforme a fertilidade do solo.

var id: int
var def: CropDef
var cell: Vector2i
var growth_hours: float = 0.0


func _init(new_id: int, new_def: CropDef, new_cell: Vector2i) -> void:
	id = new_id
	def = new_def
	cell = new_cell


func grow_hour(fertility: float) -> void:
	growth_hours = minf(growth_hours + fertility, def.grow_hours())


func is_mature() -> bool:
	return growth_hours >= def.grow_hours()


func fraction() -> float:
	return growth_hours / def.grow_hours()


## Coluna da arte: as fases de crescimento dividem o tempo por igual; a última só quando madura.
func stage() -> int:
	var last := def.stages - 1
	if is_mature():
		return last
	return mini(floori(fraction() * last), last - 1)


func hours_left(fertility: float) -> int:
	return ceili((def.grow_hours() - growth_hours) / maxf(fertility, 0.01))
