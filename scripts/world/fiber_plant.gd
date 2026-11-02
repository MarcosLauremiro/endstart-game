class_name FiberPlant
extends RefCounted
## Vegetação rasteira que rende Fibra. Só pode ser colhida crescida; depois volta a ser pequena.

var id: int
var cell: Vector2i
var growth_hours: int = Balance.FIBER_GROWTH_HOURS


## Argumentos opcionais: o carregamento (SaveGame) cria a instância vazia e preenche os campos.
func _init(new_id: int = 0, new_cell := Vector2i.ZERO) -> void:
	id = new_id
	cell = new_cell


func is_mature() -> bool:
	return growth_hours >= Balance.FIBER_GROWTH_HOURS


func grow_hour() -> void:
	if not is_mature():
		growth_hours += 1


func harvest() -> void:
	growth_hours = 0
