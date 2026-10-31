class_name Traits
extends RefCounted
## Traços de personalidade já ligados à simulação. Os oito do MVP chegam no M5;
## por enquanto Esforçado e Preguiçoso mudam a velocidade e as pausas de trabalho.

const HARDWORKING := &"hardworking"
const LAZY := &"lazy"

const NAMES := {
	HARDWORKING: "Esforçado",
	LAZY: "Preguiçoso",
}


static func name_of(trait_id: StringName) -> String:
	return NAMES.get(trait_id, String(trait_id))
