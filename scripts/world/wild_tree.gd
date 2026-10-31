class_name WildTree
extends RefCounted
## Árvore do mapa. Cresce de jovem para adulta; cortada, rende madeira e deixa um toco.

var id: int
var cell: Vector2i
var growth_hours: int = Balance.TREE_GROWTH_HOURS


func _init(new_id: int, new_cell: Vector2i) -> void:
	id = new_id
	cell = new_cell


func is_adult() -> bool:
	return growth_hours >= Balance.TREE_GROWTH_HOURS


func grow_hour() -> void:
	if not is_adult():
		growth_hours += 1


func wood_yield() -> int:
	return Balance.TREE_WOOD_YIELD if is_adult() else Balance.TREE_YOUNG_WOOD_YIELD


func cut_work_ticks() -> int:
	return Balance.CUT_WORK_TICKS if is_adult() else Balance.TREE_YOUNG_CUT_WORK_TICKS
