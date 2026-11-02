class_name ColonistsView
extends Node2D
## Desenha os colonos a partir dos dados da simulação. Um Sprite2D por colono, criado pelo id.
## Não guarda estado de jogo: posição, sono e seleção vêm de Colonist a cada quadro.

## A arte tem 16×24: sobe 4 px para os pés ficarem na base do tile.
const _SPRITE_OFFSET := Vector2(0, -4)
const _SLEEP_ROTATION := PI / 2.0
## Ícone de estado (convocado, ferido) acima da cabeça, em meio tamanho.
const _STATUS_OFFSET := Vector2(0, -22)
const _STATUS_SCALE := Vector2(0.5, 0.5)

## id do colono → Sprite2D
var _sprites := {}
## Marcas de seleção, reaproveitadas (uma por colono selecionado).
var _brackets: Array[Sprite2D] = []


func _ready() -> void:
	y_sort_enabled = true


## selected_ids: os colonos selecionados (um ou vários, na seleção por arraste).
func sync(colonists: Array[Colonist], selected_ids: Array[int]) -> void:
	var alive := {}
	for colonist in colonists:
		alive[colonist.id] = true
		var sprite: Sprite2D = _sprites.get(colonist.id)
		if sprite == null:
			sprite = Sprite2D.new()
			sprite.texture = AssetCatalog.texture("characters/colonists/colonist")
			sprite.offset = _SPRITE_OFFSET
			var status := Sprite2D.new()
			status.name = "Status"
			status.position = _STATUS_OFFSET
			status.scale = _STATUS_SCALE
			sprite.add_child(status)
			add_child(sprite)
			_sprites[colonist.id] = sprite
		sprite.position = cell_center(colonist)
		sprite.rotation = _SLEEP_ROTATION if colonist.is_lying() or colonist.carried_by != 0 else 0.0
		var icon: Sprite2D = sprite.get_node("Status")
		icon.texture = _status_texture(colonist)
		icon.rotation = -sprite.rotation
	for id in _sprites.keys():
		if not alive.has(id):
			_sprites[id].queue_free()
			_sprites.erase(id)
	var shown := 0
	for id in selected_ids:
		if not _sprites.has(id):
			continue
		if shown == _brackets.size():
			var bracket := Sprite2D.new()
			bracket.texture = AssetCatalog.texture("ui/selection/bracket")
			bracket.z_index = 1
			add_child(bracket)
			_brackets.append(bracket)
		_brackets[shown].position = _sprites[id].position
		_brackets[shown].visible = true
		shown += 1
	for index in range(shown, _brackets.size()):
		_brackets[index].visible = false


static func _status_texture(colonist: Colonist) -> Texture2D:
	if colonist.health.is_downed() or colonist.health.is_bleeding():
		return AssetCatalog.texture("ui/icons/status/injured")
	if colonist.drafted:
		return AssetCatalog.texture("ui/icons/status/drafted")
	return null


static func cell_center(colonist: Colonist) -> Vector2:
	var from := Vector2(colonist.cell)
	var to := Vector2(colonist.next_cell())
	var half_tile := Vector2.ONE * Balance.TILE_SIZE * 0.5
	return from.lerp(to, colonist.move_progress) * Balance.TILE_SIZE + half_tile
