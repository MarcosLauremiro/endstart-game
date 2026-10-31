class_name ColonistsView
extends Node2D
## Desenha os colonos a partir dos dados da simulação. Um Sprite2D por colono, criado pelo id.
## Não guarda estado de jogo: posição, sono e seleção vêm de Colonist a cada quadro.

## A arte tem 16×24: sobe 4 px para os pés ficarem na base do tile.
const _SPRITE_OFFSET := Vector2(0, -4)
const _SLEEP_ROTATION := PI / 2.0

## id do colono → Sprite2D
var _sprites := {}
var _selection: Sprite2D


func _ready() -> void:
	y_sort_enabled = true
	_selection = Sprite2D.new()
	_selection.texture = AssetCatalog.texture("ui/selection/bracket")
	_selection.z_index = 1
	_selection.visible = false
	add_child(_selection)


func sync(colonists: Array[Colonist], selected_id: int) -> void:
	var alive := {}
	for colonist in colonists:
		alive[colonist.id] = true
		var sprite: Sprite2D = _sprites.get(colonist.id)
		if sprite == null:
			sprite = Sprite2D.new()
			sprite.texture = AssetCatalog.texture("characters/colonists/colonist")
			sprite.offset = _SPRITE_OFFSET
			add_child(sprite)
			_sprites[colonist.id] = sprite
		sprite.position = cell_center(colonist)
		sprite.rotation = _SLEEP_ROTATION if colonist.is_sleeping() else 0.0
		if colonist.id == selected_id:
			_selection.position = sprite.position
	for id in _sprites.keys():
		if not alive.has(id):
			_sprites[id].queue_free()
			_sprites.erase(id)
	_selection.visible = selected_id != 0 and alive.has(selected_id)


static func cell_center(colonist: Colonist) -> Vector2:
	var from := Vector2(colonist.cell)
	var to := Vector2(colonist.next_cell())
	var half_tile := Vector2.ONE * Balance.TILE_SIZE * 0.5
	return from.lerp(to, colonist.move_progress) * Balance.TILE_SIZE + half_tile
