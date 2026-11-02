class_name Injury
extends RefCounted
## Um ferimento: tipo, dano que ainda falta curar e se já foi tratado.
## Cortes e perfurações sangram até serem tratados; contusões não sangram.

enum Kind { CUT, STAB, BRUISE }
const KIND_NAMES := {Kind.CUT: "Corte", Kind.STAB: "Perfuração", Kind.BRUISE: "Contusão"}
## Chave usada nos recursos (.tres) das armas.
const KEYS := {&"cut": Kind.CUT, &"stab": Kind.STAB, &"blunt": Kind.BRUISE}

var kind: Kind
var damage: float
var tended: bool = false


## Argumentos opcionais: o carregamento (SaveGame) cria a instância vazia e preenche os campos.
func _init(new_kind: Kind = Kind.CUT, new_damage: float = 0.0) -> void:
	kind = new_kind
	damage = new_damage


func bleeds() -> bool:
	return kind != Kind.BRUISE and not tended


func label() -> String:
	var text := "%s (%d)" % [KIND_NAMES[kind], ceili(damage)]
	if bleeds():
		text += ", sangrando"
	elif tended:
		text += ", tratado"
	return text


static func kind_from_key(key: StringName) -> Kind:
	return KEYS.get(key, Kind.BRUISE)
