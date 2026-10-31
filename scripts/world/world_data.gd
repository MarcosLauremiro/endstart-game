class_name WorldData
extends RefCounted
## Grade de terreno da região. Guarda apenas dados; a aparência fica em WorldView.

const _FNV_OFFSET := 2166136261
const _FNV_PRIME := 16777619
const _MASK_32 := 0xFFFFFFFF

var size: Vector2i
var _cells: PackedByteArray


func _init(new_size: Vector2i) -> void:
	assert(new_size.x > 0 and new_size.y > 0, "Tamanho de mapa inválido: %s" % new_size)
	size = new_size
	_cells.resize(size.x * size.y)


func contains(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.y >= 0 and cell.x < size.x and cell.y < size.y


func get_terrain(cell: Vector2i) -> int:
	assert(contains(cell), "Célula fora do mapa: %s" % cell)
	return _cells[_index(cell)]


func set_terrain(cell: Vector2i, kind: int) -> void:
	assert(contains(cell), "Célula fora do mapa: %s" % cell)
	assert(Terrain.is_valid(kind), "Terreno inválido: %d" % kind)
	_cells[_index(cell)] = kind


## Impressão digital do terreno (FNV-1a de 32 bits). Estável entre execuções; usada nos testes de seed.
func fingerprint() -> int:
	var hash_value := _FNV_OFFSET
	for value in _cells:
		hash_value = ((hash_value ^ value) * _FNV_PRIME) & _MASK_32
	return hash_value


func _index(cell: Vector2i) -> int:
	return cell.y * size.x + cell.x
