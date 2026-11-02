class_name ItemStack
extends RefCounted
## Pilha solta no chão (GDD: o chão é só um estado temporário). Gera uma tarefa de Carregar.
## Retiradas são reservadas por colono antes de acontecer.

var id: int
var cell: Vector2i
var item: StringName
var count: int
## id do colono → unidades reservadas
var _takes := {}


## Argumentos opcionais: o carregamento (SaveGame) cria a instância vazia e preenche os campos.
func _init(new_id: int = 0, new_cell := Vector2i.ZERO, new_item: StringName = &"", new_count: int = 0) -> void:
	id = new_id
	cell = new_cell
	item = new_item
	count = new_count


func available() -> int:
	var reserved := 0
	for amount in _takes.values():
		reserved += amount
	return count - reserved


func reserve_take(owner_id: int, amount: int) -> int:
	var granted := mini(amount, available())
	if granted > 0:
		_takes[owner_id] = _takes.get(owner_id, 0) + granted
	return granted


## Retira o que o colono reservou e devolve a quantidade.
func take(owner_id: int) -> int:
	var amount: int = mini(_takes.get(owner_id, 0), count)
	_takes.erase(owner_id)
	count -= amount
	return amount


func release_owner(owner_id: int) -> void:
	_takes.erase(owner_id)


func has_reservation_of(owner_id: int) -> bool:
	return _takes.has(owner_id)
