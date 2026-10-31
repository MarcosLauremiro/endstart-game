class_name Structure
extends RefCounted
## Estrutura pronta no mapa (parede, porta, piso, cama, mesa, fogueira).
## Contêineres prontos viram StorageContainer, não Structure.

var id: int
var def: StructureDef
var origin: Vector2i


func _init(new_id: int, new_def: StructureDef, new_origin: Vector2i) -> void:
	id = new_id
	def = new_def
	origin = new_origin


func cells() -> Array[Vector2i]:
	return def.cells_at(origin)
