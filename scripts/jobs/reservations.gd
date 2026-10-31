class_name Reservations
extends RefCounted
## Reservas exclusivas da colônia: tarefas e arbustos têm no máximo um dono.
## Quantidades de itens e de espaço são reservadas nas próprias pilhas e contêineres.
## Uma reserva que fica tempo demais sem avançar expira (GDD: 30 s de jogo).

## chave → id do colono dono
var _owners := {}
## chave → último tick em que o dono avançou
var _touched := {}


static func bush_key(bush_id: int) -> String:
	return "bush:%d" % bush_id


static func bed_key(bed_id: int) -> String:
	return "bed:%d" % bed_id


func try_reserve(key: String, owner_id: int, tick: int = 0) -> bool:
	var current: int = _owners.get(key, 0)
	if current != 0 and current != owner_id:
		return false
	_owners[key] = owner_id
	_touched[key] = tick
	return true


## Dono atual, ou 0 se livre.
func owner_of(key: String) -> int:
	return _owners.get(key, 0)


## Libera só se o pedido vier do próprio dono.
func release(key: String, owner_id: int) -> void:
	if _owners.get(key, 0) == owner_id:
		_owners.erase(key)
		_touched.erase(key)


func release_all(owner_id: int) -> void:
	for key in _owners.keys():
		if _owners[key] == owner_id:
			_owners.erase(key)
			_touched.erase(key)


## Marca que o dono avançou (andou, trabalhou, dormiu) nesta reserva.
func touch(key: String, tick: int) -> void:
	if _owners.has(key):
		_touched[key] = tick


## Chaves sem avanço há mais de timeout ticks.
func expired(tick: int, timeout: int) -> Array[String]:
	var result: Array[String] = []
	for key in _touched:
		if tick - _touched[key] > timeout:
			result.append(key)
	return result


func count_for(owner_id: int) -> int:
	var total := 0
	for key in _owners:
		if _owners[key] == owner_id:
			total += 1
	return total
