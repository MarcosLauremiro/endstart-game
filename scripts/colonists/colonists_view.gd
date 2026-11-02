class_name ColonistsView
extends Node2D
## Desenha os colonos a partir dos dados da simulação. Um Node2D por colono, criado pelo id, com as
## camadas de ColonistLooks na ordem corpo, roupa de baixo, roupa de cima e cabelo: todas usam o
## mesmo quadro (direção do passo e quadro da caminhada), então ficam sempre alinhadas.
## A roupa só aparece com a peça vestida no espaço Camisa ou Calça.
## Não guarda estado de jogo: posição, sono e seleção vêm de Colonist a cada quadro; só lembra para
## que lado cada um olhava, para continuar virado assim quando para.

## A arte tem 16×24: sobe 4 px para os pés ficarem na base do tile.
const _SPRITE_OFFSET := Vector2(0, -4)
const _PALETTE_SHADER := "res://shaders/palette_swap.gdshader"
const _LAYERS := ["Base", "Bottom", "Top", "Hair"]
const _SLEEP_ROTATION := PI / 2.0
## Ícone de estado (convocado, ferido) acima da cabeça, em meio tamanho.
const _STATUS_OFFSET := Vector2(0, -22)
const _STATUS_SCALE := Vector2(0.5, 0.5)

## id do colono → Node2D com as camadas
var _sprites := {}
## id do colono → ColonistLooks.Facing (o último lado para onde andou)
var _facing := {}
## "hair:<cor>" ou "cloth:<cor>" → ShaderMaterial (um por rampa, dividido entre os colonos)
var _materials := {}
## Marcas de seleção, reaproveitadas (uma por colono selecionado).
var _brackets: Array[Sprite2D] = []


func _ready() -> void:
	y_sort_enabled = true


## selected_ids: os colonos selecionados (um ou vários, na seleção por arraste); tick anima a caminhada.
func sync(colonists: Array[Colonist], selected_ids: Array[int], tick: int = 0) -> void:
	var alive := {}
	for colonist in colonists:
		alive[colonist.id] = true
		var figure: Node2D = _sprites.get(colonist.id)
		if figure == null:
			figure = _make_figure(colonist)
			add_child(figure)
			_sprites[colonist.id] = figure
		figure.position = cell_center(colonist)
		var lying := colonist.is_lying() or colonist.carried_by != 0
		figure.rotation = _SLEEP_ROTATION if lying else 0.0
		_pose(figure, colonist, tick, lying)
		var icon: Sprite2D = figure.get_node("Status")
		icon.texture = _status_texture(colonist)
		icon.rotation = -figure.rotation
	for id in _sprites.keys():
		if not alive.has(id):
			_sprites[id].queue_free()
			_sprites.erase(id)
			_facing.erase(id)
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


## Camadas na ordem de desenho; cabelo e roupa com a troca de paleta da cor escolhida.
func _make_figure(colonist: Colonist) -> Node2D:
	var looks := colonist.appearance
	var figure := Node2D.new()
	for layer_name: String in _LAYERS:
		var layer := Sprite2D.new()
		layer.name = layer_name
		layer.offset = _SPRITE_OFFSET
		layer.region_enabled = true
		figure.add_child(layer)
	var base: Sprite2D = figure.get_node("Base")
	base.texture = AssetCatalog.texture(ColonistLooks.BASE_SHEET)
	base.modulate = ColonistLooks.SKIN_TONES[looks.skin_tone]
	for layer_name in ["Bottom", "Top"]:
		(figure.get_node(layer_name) as Sprite2D).texture = AssetCatalog.texture(ColonistLooks.CLOTHING_SHEET)
	(figure.get_node("Bottom") as Sprite2D).material = _material("cloth", looks.bottom_color)
	(figure.get_node("Top") as Sprite2D).material = _material("cloth", looks.top_color)
	var hair: Sprite2D = figure.get_node("Hair")
	hair.texture = AssetCatalog.texture(ColonistLooks.HAIR_SHEET)
	hair.material = _material("hair", looks.hair_color)
	var status := Sprite2D.new()
	status.name = "Status"
	status.position = _STATUS_OFFSET
	status.scale = _STATUS_SCALE
	figure.add_child(status)
	return figure


## Mesmo quadro em todas as camadas: lado do passo (ou o último), caminhada pelo tick.
func _pose(figure: Node2D, colonist: Colonist, tick: int, lying: bool) -> void:
	var looks := colonist.appearance
	var next := colonist.next_cell()
	var moving := next != colonist.cell and not lying
	var step: Variant = ColonistLooks.facing_of(colonist.cell, next)
	if step != null and not lying:
		_facing[colonist.id] = step
	var facing: ColonistLooks.Facing = ColonistLooks.Facing.FRONT if lying else _facing.get(colonist.id, ColonistLooks.Facing.FRONT)
	var frame := ColonistLooks.walk_frame(tick, colonist.id)
	(figure.get_node("Base") as Sprite2D).region_rect = ColonistLooks.base_region(facing, frame, moving)
	var hair: Sprite2D = figure.get_node("Hair")
	hair.region_rect = ColonistLooks.layer_region(looks.hair_style, facing, frame, moving)
	var top: Sprite2D = figure.get_node("Top")
	top.visible = colonist.equipment.in_slot(Equipment.Slot.SHIRT) != &""
	top.region_rect = ColonistLooks.layer_region(looks.top, facing, frame, moving)
	var bottom: Sprite2D = figure.get_node("Bottom")
	bottom.visible = colonist.equipment.in_slot(Equipment.Slot.PANTS) != &""
	bottom.region_rect = ColonistLooks.layer_region(looks.bottom, facing, frame, moving)


func _material(kind: String, color: int) -> ShaderMaterial:
	var key := "%s:%d" % [kind, color]
	if _materials.has(key):
		return _materials[key]
	var material := ShaderMaterial.new()
	material.shader = load(_PALETTE_SHADER)
	var hair := kind == "hair"
	material.set_shader_parameter("source_ramp", PackedColorArray(ColonistLooks.HAIR_SOURCE_RAMP if hair else ColonistLooks.CLOTHING_SOURCE_RAMP))
	var palette: Array[Dictionary] = ColonistLooks.HAIR_COLORS if hair else ColonistLooks.CLOTHING_COLORS
	material.set_shader_parameter("target_ramp", PackedColorArray(palette[color]["ramp"]))
	_materials[key] = material
	return material


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
