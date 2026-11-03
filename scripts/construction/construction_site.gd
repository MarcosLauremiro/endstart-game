class_name ConstructionSite
extends RefCounted
## Planta de construção colocada pelo jogador. Guarda os materiais já entregues (que existem de verdade
## até a obra terminar ou ser cancelada) e as entregas a caminho, reservadas por colono.

var id: int
var def: StructureDef
var origin: Vector2i
## Direção da arte e do tamanho (StructureDef.footprint_for); 0 para o que não gira.
var rotation := 0
## item → quantidade entregue
var delivered := {}
## id do colono → {"item": StringName, "count": int}
var _incoming := {}


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


## O que ainda falta, descontando o que já está a caminho: item → quantidade.
func missing() -> Dictionary:
	var result := {}
	for item in def.costs:
		var amount: int = def.costs[item] - delivered.get(item, 0) - _incoming_of(item)
		if amount > 0:
			result[item] = amount
	return result


## O que falta no formato comum às entregas (obra e bancada): {"index", "items", "count"}.
func needs() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var missing_now := missing()
	for item in missing_now:
		var items: Array[StringName] = [item]
		result.append({"index": 0, "items": items, "count": missing_now[item]})
	return result


func delivery_cell() -> Vector2i:
	return origin


func has_all_materials() -> bool:
	for item in def.costs:
		if delivered.get(item, 0) < def.costs[item]:
			return false
	return true


## Quem está trazendo material agora (para explicar a espera).
func incoming_owners() -> Array:
	return _incoming.keys()


func reserve_incoming(owner_id: int, item: StringName, amount: int) -> void:
	_incoming[owner_id] = {"item": item, "count": amount}


## Recebe a entrega reservada. Devolve quanto entrou; o excesso fica com quem trouxe.
func deliver(owner_id: int, item: StringName, amount: int) -> int:
	var needed: int = def.costs.get(item, 0) - delivered.get(item, 0)
	var stored := clampi(amount, 0, needed)
	delivered[item] = delivered.get(item, 0) + stored
	_incoming.erase(owner_id)
	return stored


func release_owner(owner_id: int) -> void:
	_incoming.erase(owner_id)


func has_reservation_of(owner_id: int) -> bool:
	return _incoming.has(owner_id)


func materials_text() -> String:
	var parts := PackedStringArray()
	for item in def.costs:
		parts.append("%d/%d %s" % [delivered.get(item, 0), def.costs[item], Defs.item(item).display_name.to_lower()])
	return ", ".join(parts)


func _incoming_of(item: StringName) -> int:
	var total := 0
	for entry in _incoming.values():
		if entry["item"] == item:
			total += entry["count"]
	return total
