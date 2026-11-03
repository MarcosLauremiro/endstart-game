class_name StructuresView
extends Node2D
## Construções prontas (paredes, portas, móveis, bancadas) e contêineres como sprites ordenados
## pela altura junto com colonos e árvores (os três ficam sob o mesmo nó com y_sort). Quem está
## atrás (ao norte) de uma parede fica escondido pelo topo dela; quem está na frente passa por cima.
## Pisos e plantas de construção continuam no ObjectsView. Só lê o WorldState.

## Ordenação no centro da linha, um pouco acima do colono naquela linha (como as árvores).
const _SORT_NUDGE := -1.0

## "s<id>" (estrutura) ou "c<id>" (contêiner) → Sprite2D
var _sprites := {}


func _ready() -> void:
	y_sort_enabled = true


func sync(state: WorldState) -> void:
	var alive := {}
	for structure: Structure in state.structures.values():
		if structure.def.layer != StructureDef.Layer.BUILDING:
			continue
		var key := "s%d" % structure.id
		alive[key] = true
		var sprite := _sprite(key, structure.def.asset, structure.origin, structure.def.footprint, structure.def.blocks_movement)
		sprite.region_rect = StructureArt.region(state, structure.def, structure.origin)
	for container: StorageContainer in state.containers.values():
		var key := "c%d" % container.id
		alive[key] = true
		_sprite(key, container.def.asset, container.cell, container.def.footprint, true)
	for key in _sprites.keys():
		if not alive.has(key):
			_sprites[key].queue_free()
			_sprites.erase(key)


func sprite_count() -> int:
	return _sprites.size()


## Sprite da construção, para testes.
func sprite_of(key: String) -> Sprite2D:
	return _sprites.get(key)


## Mapa novo: os ids recomeçam, então os sprites antigos saem.
func clear() -> void:
	for sprite in _sprites.values():
		sprite.queue_free()
	_sprites.clear()


## A arte fica apoiada na base do footprint (paredes de 16×24 sobem 8 px acima do tile). O que
## bloqueia ordena pela última linha; o que se pisa (cama, porta) pela primeira, para quem está
## em cima aparecer por cima.
func _sprite(key: String, asset: String, origin: Vector2i, footprint: Vector2i, blocks: bool) -> Sprite2D:
	var sprite: Sprite2D = _sprites.get(key)
	if sprite:
		return sprite
	var tile := Balance.TILE_SIZE
	var texture := AssetCatalog.texture(asset)
	var frame := AssetCatalog.frame_size(asset)
	sprite = Sprite2D.new()
	sprite.texture = texture
	sprite.centered = false
	sprite.region_enabled = true
	sprite.region_rect = Rect2(Vector2.ZERO, Vector2(frame))
	var sort_row := origin.y + footprint.y - 1 if blocks else origin.y
	sprite.position = Vector2(origin.x * tile + footprint.x * tile / 2.0, sort_row * tile + tile / 2.0 + _SORT_NUDGE)
	var top_left := Vector2(origin.x * tile, (origin.y + footprint.y) * tile - frame.y)
	sprite.offset = top_left - sprite.position
	add_child(sprite)
	_sprites[key] = sprite
	return sprite
