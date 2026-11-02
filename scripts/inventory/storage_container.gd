class_name StorageContainer
extends RefCounted
## Contêiner com espaços (GDD: Armazenamento). Cada espaço guarda um tipo de item até o tamanho da pilha.
## Entregas reservam espaço e retiradas reservam itens antes de acontecer, então dois colonos
## nunca disputam o mesmo item nem o mesmo espaço.

var id: int
var def: ContainerDef
## Célula de origem (canto superior esquerdo do footprint).
var cell: Vector2i
## Cada espaço: {"item": StringName (vazio = livre), "count": int, "pending": int (entregas reservadas)}
var slots: Array[Dictionary] = []
## Filtro do jogador (GDD: Organização > Filtro por categoria): categoria → permitida.
## Começa com tudo o que o tipo de contêiner aceita.
var allowed := {}
## id do colono → {"item": StringName, "count": int}
var _takes := {}
## id do colono → Array de {"slot": int, "count": int}
var _incoming := {}


## Argumentos opcionais: o carregamento (SaveGame) cria a instância vazia e preenche os campos.
func _init(new_id: int = 0, new_def: ContainerDef = null, new_cell := Vector2i.ZERO) -> void:
	id = new_id
	def = new_def
	cell = new_cell
	if def == null:
		return
	for _i in def.slot_count:
		slots.append({"item": &"", "count": 0, "pending": 0})
	for category in ItemDef.CATEGORY_NAMES:
		if def.can_hold(category):
			allowed[category] = true


## O tipo aceita e o filtro permite?
func accepts(definition: ItemDef) -> bool:
	return def.accepts(definition) and allowed.get(definition.category, false)


func set_allowed(category: int, value: bool) -> void:
	if def.can_hold(category):
		allowed[category] = value


func cells() -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for y in def.footprint.y:
		for x in def.footprint.x:
			result.append(cell + Vector2i(x, y))
	return result


func count_of(item: StringName) -> int:
	var total := 0
	for slot in slots:
		if slot["item"] == item:
			total += slot["count"]
	return total


func available(item: StringName) -> int:
	var reserved := 0
	for entry in _takes.values():
		if entry["item"] == item:
			reserved += entry["count"]
	return count_of(item) - reserved


func free_space(item: StringName) -> int:
	var definition := Defs.item(item)
	if not accepts(definition):
		return 0
	var stack_size := def.stack_size_for(definition)
	var total := 0
	for slot in slots:
		if slot["item"] == item or slot["item"] == &"":
			total += stack_size - slot["count"] - slot["pending"]
	return total


## Itens presentes, sem repetir: {item: quantidade}.
func contents() -> Dictionary:
	var result := {}
	for slot in slots:
		if slot["item"] != &"" and slot["count"] > 0:
			result[slot["item"]] = result.get(slot["item"], 0) + slot["count"]
	return result


## Reserva espaço para uma entrega. Usa primeiro espaços com o mesmo item, depois espaços livres.
func reserve_space(owner_id: int, item: StringName, amount: int) -> int:
	var definition := Defs.item(item)
	if not accepts(definition):
		return 0
	var stack_size := def.stack_size_for(definition)
	var remaining := amount
	var entries: Array = _incoming.get(owner_id, [])
	for same_item_pass in [true, false]:
		for index in slots.size():
			if remaining <= 0:
				break
			var slot := slots[index]
			if same_item_pass and slot["item"] != item:
				continue
			if not same_item_pass and slot["item"] != &"":
				continue
			var room: int = stack_size - slot["count"] - slot["pending"]
			if room <= 0:
				continue
			var granted := mini(room, remaining)
			slot["item"] = item
			slot["pending"] += granted
			remaining -= granted
			entries.append({"slot": index, "count": granted})
	if not entries.is_empty():
		_incoming[owner_id] = entries
	return amount - remaining


## Entrega o que foi reservado. Devolve quanto entrou; o excesso fica com quem trouxe.
func deposit(owner_id: int, item: StringName, amount: int) -> int:
	var remaining := amount
	for entry in _incoming.get(owner_id, []):
		var slot := slots[entry["slot"]]
		var stored := mini(entry["count"], remaining)
		if slot["item"] == item:
			slot["count"] += stored
			remaining -= stored
		slot["pending"] -= entry["count"]
	_incoming.erase(owner_id)
	_clear_unused_slots()
	return amount - remaining


func reserve_take(owner_id: int, item: StringName, amount: int) -> int:
	var granted := mini(amount, available(item))
	if granted > 0:
		_takes[owner_id] = {"item": item, "count": granted}
	return granted


## Retira o que o colono reservou e devolve a quantidade.
func take(owner_id: int) -> int:
	if not _takes.has(owner_id):
		return 0
	var entry: Dictionary = _takes[owner_id]
	_takes.erase(owner_id)
	var remaining: int = entry["count"]
	for slot in slots:
		if remaining <= 0:
			break
		if slot["item"] != entry["item"]:
			continue
		var removed := mini(slot["count"], remaining)
		slot["count"] -= removed
		remaining -= removed
	_clear_unused_slots()
	return entry["count"] - remaining


## Coloca itens sem reserva (preparação da partida). Devolve quanto coube.
func add_items(item: StringName, amount: int) -> int:
	var granted := reserve_space(0, item, amount)
	return deposit(0, item, granted)


## Tira unidades livres (não reservadas) do item, sem reserva. Devolve quanto saiu.
func remove_items(item: StringName, amount: int) -> int:
	var remaining := mini(amount, available(item))
	var removed := 0
	for slot in slots:
		if remaining <= 0:
			break
		if slot["item"] != item:
			continue
		var taken := mini(slot["count"], remaining)
		slot["count"] -= taken
		remaining -= taken
		removed += taken
	_clear_unused_slots()
	return removed


## Esvazia o item do contêiner e devolve quanto havia (uso em testes e cenários).
func take_all(item: StringName) -> int:
	var removed := 0
	for slot in slots:
		if slot["item"] == item:
			removed += slot["count"]
			slot["count"] = 0
	_clear_unused_slots()
	return removed


func release_owner(owner_id: int) -> void:
	for entry in _incoming.get(owner_id, []):
		slots[entry["slot"]]["pending"] -= entry["count"]
	_incoming.erase(owner_id)
	_takes.erase(owner_id)
	_clear_unused_slots()


func has_reservation_of(owner_id: int) -> bool:
	return _takes.has(owner_id) or _incoming.has(owner_id)


func _clear_unused_slots() -> void:
	for slot in slots:
		if slot["count"] <= 0 and slot["pending"] <= 0:
			slot["item"] = &""
			slot["count"] = 0
			slot["pending"] = 0
