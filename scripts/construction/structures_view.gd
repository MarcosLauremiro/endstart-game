class_name StructuresView
extends Node2D
## Construções prontas (paredes, portas, móveis, bancadas) e contêineres como sprites ordenados
## pela altura junto com colonos e árvores (os três ficam sob o mesmo nó com y_sort). Quem está
## atrás (ao norte) de uma parede fica escondido pelo topo dela; quem está na frente passa por cima.
## Pisos e plantas de construção continuam no ObjectsView. Só lê o WorldState.

## Ordenação no centro da linha, um pouco acima do colono naquela linha (como as árvores).
const _SORT_NUDGE := -1.0

## "s<id>" (estrutura) ou "c<id>" (contêiner) → Sprite2D. Cada sprite fica dentro de um Node2D
## no ponto de ordenação; o sprite vai centrado na arte e gira com a construção.
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
		var sprite := _sprite(key, structure.def.asset, structure.origin, structure.footprint(), structure.def.blocks_movement, structure.rotation)
		sprite.region_rect = StructureArt.region(state, structure.def, structure.origin)
	for container: StorageContainer in state.containers.values():
		var key := "c%d" % container.id
		alive[key] = true
		_sprite(key, container.def.asset, container.cell, container.def.footprint, true, 0)
	for key in _sprites.keys():
		if not alive.has(key):
			_sprites[key].get_parent().queue_free()
			_sprites.erase(key)


func sprite_count() -> int:
	return _sprites.size()


## Sprite da construção, para testes.
func sprite_of(key: String) -> Sprite2D:
	return _sprites.get(key)


## Mapa novo: os ids recomeçam, então os sprites antigos saem.
func clear() -> void:
	for sprite in _sprites.values():
		sprite.get_parent().queue_free()
	_sprites.clear()


## Ponto de ordenação do sprite (o Node2D em volta dele).
func sort_position(key: String) -> Vector2:
	return (_sprites[key] as Sprite2D).get_parent().position


## A arte fica apoiada na base do footprint (paredes de 16×24 sobem 8 px acima do tile). O que
## bloqueia ordena pela última linha; o que se pisa (cama, porta) pela primeira, para quem está
## em cima aparecer por cima. Girada, a arte (desenhada na direção 0) gira em volta do centro
## do footprint já girado.
func _sprite(key: String, asset: String, origin: Vector2i, footprint: Vector2i, blocks: bool, rotation_steps: int) -> Sprite2D:
	var sprite: Sprite2D = _sprites.get(key)
	if sprite:
		return sprite
	var tile := Balance.TILE_SIZE
	var frame := Vector2(AssetCatalog.frame_size(asset))
	var holder := Node2D.new()
	var sort_row := origin.y + footprint.y - 1 if blocks else origin.y
	holder.position = Vector2(origin.x * tile + footprint.x * tile / 2.0, sort_row * tile + tile / 2.0 + _SORT_NUDGE)
	sprite = Sprite2D.new()
	sprite.texture = AssetCatalog.texture(asset)
	sprite.region_enabled = true
	sprite.region_rect = Rect2(Vector2.ZERO, frame)
	var bottom := float((origin.y + footprint.y) * tile)
	var center := Vector2(origin.x * tile + footprint.x * tile / 2.0, bottom - frame.y / 2.0)
	if rotation_steps != 0:
		center.y = origin.y * tile + footprint.y * tile / 2.0
	sprite.position = center - holder.position
	sprite.rotation = rotation_steps * PI / 2.0
	holder.add_child(sprite)
	add_child(holder)
	_sprites[key] = sprite
	return sprite
