class_name TreesView
extends Node2D
## Árvores de 32×32 como sprites, ordenadas pela altura no mapa junto com os colonos (os dois ficam
## sob o mesmo nó com y_sort): quem está atrás (ao norte) da árvore fica escondido pela copa, quem
## está na frente passa por cima. Um Sprite2D por árvore, criado pelo id; só lê o WorldState.

const _SHEET := "plants/trees"
## Colunas da folha (ver AssetCatalog).
const _YOUNG := 2
const _ADULT := 3
## A posição de ordenação é o centro do tile, um pouco acima do colono no mesmo tile: colono ao
## lado, na mesma linha, fica na frente da árvore.
const _SORT_NUDGE := -1.0

## id da árvore → Sprite2D
var _sprites := {}


func _ready() -> void:
	y_sort_enabled = true


func sync(state: WorldState) -> void:
	var season := state.clock.season()
	var alive := {}
	for tree: WildTree in state.trees.values():
		alive[tree.id] = true
		var sprite: Sprite2D = _sprites.get(tree.id)
		if sprite == null:
			sprite = _make_sprite(tree.cell)
			_sprites[tree.id] = sprite
		sprite.region_rect = AssetCatalog.frame_region(_SHEET, _ADULT if tree.is_adult() else _YOUNG, season)
	for id in _sprites.keys():
		if not alive.has(id):
			_sprites[id].queue_free()
			_sprites.erase(id)


## Sprite com a base do quadro na base do tile, centrado na largura.
func _make_sprite(cell: Vector2i) -> Sprite2D:
	var tile := Balance.TILE_SIZE
	var frame := AssetCatalog.frame_size(_SHEET)
	var sprite := Sprite2D.new()
	sprite.texture = AssetCatalog.texture(_SHEET)
	sprite.region_enabled = true
	sprite.position = Vector2(cell * tile) + Vector2(tile / 2.0, tile / 2.0 + _SORT_NUDGE)
	sprite.offset = Vector2(0, tile / 2.0 - _SORT_NUDGE - frame.y / 2.0)
	add_child(sprite)
	return sprite


func sprite_count() -> int:
	return _sprites.size()


## Mapa novo: os ids recomeçam, então os sprites antigos saem.
func clear() -> void:
	for sprite in _sprites.values():
		sprite.queue_free()
	_sprites.clear()
