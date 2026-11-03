class_name Structure
extends RefCounted
## Estrutura pronta no mapa (parede, porta, piso, cama, mesa, fogueira).
## Contêineres prontos viram StorageContainer, não Structure.

var id: int
var def: StructureDef
var origin: Vector2i
## Direção da arte e do tamanho (StructureDef.footprint_for); 0 para o que não gira.
var rotation := 0


## Argumentos opcionais: o carregamento (SaveGame) cria a instância vazia e preenche os campos.
func _init(new_id: int = 0, new_def: StructureDef = null, new_origin := Vector2i.ZERO, new_rotation := 0) -> void:
	id = new_id
	def = new_def
	origin = new_origin
	rotation = new_rotation if new_def and new_def.rotatable else 0


func cells() -> Array[Vector2i]:
	return def.cells_at(origin, rotation)


func footprint() -> Vector2i:
	return def.footprint_for(rotation)
