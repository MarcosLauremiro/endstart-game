class_name GrowZone
extends RefCounted
## Zona de plantação desenhada pelo jogador. Cada tile livre vira uma tarefa de semear;
## cada planta madura, uma tarefa de colher (Cultivar).

var id: int
var crop: CropDef
## Vector2i → true
var cells := {}


## Argumentos opcionais: o carregamento (SaveGame) cria a instância vazia e preenche os campos.
func _init(new_id: int = 0, new_crop: CropDef = null) -> void:
	id = new_id
	crop = new_crop
