class_name GrowZone
extends RefCounted
## Zona de plantação desenhada pelo jogador. Cada tile livre vira uma tarefa de semear;
## cada planta madura, uma tarefa de colher (Cultivar).

var id: int
var crop: CropDef
## Vector2i → true
var cells := {}


func _init(new_id: int, new_crop: CropDef) -> void:
	id = new_id
	crop = new_crop
