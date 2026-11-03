class_name ObjectsView
extends Node2D
## Desenha o que está sobre o terreno: pisos, plantações, tocos, arbustos, plantas de construção,
## pilhas no chão e animais. Árvores (TreesView) e construções prontas e contêineres
## (StructuresView) ficam ordenados pela altura junto com os colonos.
## Numa camada por cima de árvores e colonos (_overlay): designações com o progresso das tarefas,
## barras de vida, fumaça, prévia de construção, seleção e o arraste das ordens.
## Só lê o WorldState; nada aqui é fonte de verdade.

const _TREES := "plants/trees"
const _BUSHES := "plants/berry_bushs"
const _FIBER := "plants/low_growing_vegetation"
## Colunas das folhas de sprites (ver AssetCatalog).
const _TREE_STUMP_YOUNG := 0
const _TREE_STUMP_ADULT := 1
const _BUSH_SEEDLING := 0
const _BUSH_EMPTY := 1
const _BUSH_WITH_BERRIES := 2
const _FIBER_SMALL := 0
const _FIBER_GROWN := 1
const _DESIGNATION_TINT := Color(1, 1, 1, 0.75)
const _BLOCKED_TINT := Color(1, 0.4, 0.4, 0.75)
## Números das pilhas: a fonte pixel no tamanho nativo (8), nítida em qualquer escala inteira.
const _COUNT_FONT_SIZE := UiTheme.FONT_GRID
const _PROGRESS_HEIGHT := 2
const _DRAG_FILL := Color(0.95, 0.65, 0.25, 0.15)
const _DRAG_BORDER := Color(0.95, 0.65, 0.25, 0.9)
const _DESIGNATION_ICONS := {
	Task.Kind.CUT: "ui/icons/orders/cut",
	Task.Kind.MINE: "ui/icons/orders/mine",
	Task.Kind.HARVEST: "ui/icons/orders/harvest",
	Task.Kind.DECONSTRUCT: "ui/icons/orders/deconstruct",
	Task.Kind.HUNT: "ui/icons/orders/hunt",
	Task.Kind.INVESTIGATE: "ui/icons/tabs/research",
}
## Tarefas que não marcam o tile com ícone nem com vermelho quando esperam (a própria arte mostra).
const _SILENT_TASKS := [Task.Kind.HAUL, Task.Kind.SOW, Task.Kind.REAP, Task.Kind.CRAFT, Task.Kind.RESCUE, Task.Kind.TEND]
## Barra de vida sob quem está ferido; fumaça cinza do aviso de ataque.
const _HEALTH_BAR_HEIGHT := 2
const _HEALTH_BAR_BACK := Color(0.1, 0.05, 0.05, 0.8)
const _HEALTH_BAR_FILL := Color(0.9, 0.3, 0.3)
const _SMOKE := Color(0.6, 0.6, 0.62, 0.7)
const _ZONE_FILL := Color(0.48, 0.79, 0.44, 0.12)
const _ZONE_BORDER := Color(0.48, 0.79, 0.44, 0.45)
## Planta de construção: a arte da estrutura em azul translúcido; prévia válida em verde, inválida em vermelho.
const _BLUEPRINT_TINT := Color(0.55, 0.8, 1.0, 0.5)
const _PREVIEW_TINT := Color(0.6, 1.0, 0.6, 0.6)
const _INVALID_FILL := Color(0.9, 0.3, 0.3, 0.35)

## Acima das árvores e dos colonos (z 0) e das marcas de seleção dos colonos (z 1).
const _OVERLAY_Z := 2

var _state: WorldState
var _overlay: Node2D
var _drag_area := Rect2i()
## Área selecionada por arraste (contorno que fica depois de soltar) e, nela, as árvores, rochas e
## plantas selecionadas (uma marca em cada; com elas, o contorno não aparece).
var _selected_area := Rect2i()
var _selected_cells: Array[Vector2i] = []
var _selected_cell := Vector2i.ZERO
var _has_selected_cell := false
var _preview_def: StructureDef
var _preview_valid: Array[Vector2i] = []
var _preview_invalid: Array[Vector2i] = []
var _preview_rotation := 0


func _ready() -> void:
	_overlay = Node2D.new()
	_overlay.z_index = _OVERLAY_Z
	_overlay.draw.connect(_draw_overlay)
	add_child(_overlay)


func bind(state: WorldState) -> void:
	_state = state
	queue_redraw()


func set_drag_area(area: Rect2i) -> void:
	_drag_area = area


func set_selected_area(area: Rect2i, cells: Array[Vector2i]) -> void:
	_selected_area = area
	_selected_cells = cells


func set_selected_cell(cell: Vector2i, has_cell: bool) -> void:
	_selected_cell = cell
	_has_selected_cell = has_cell


## Prévia da colocação: origens válidas e inválidas da estrutura escolhida (def null = sem prévia).
func set_build_preview(def: StructureDef, valid: Array[Vector2i], invalid: Array[Vector2i], rotation := 0) -> void:
	_preview_def = def
	_preview_rotation = rotation
	_preview_valid = valid
	_preview_invalid = invalid


func refresh() -> void:
	queue_redraw()
	_overlay.queue_redraw()


func _draw() -> void:
	if _state == null:
		return
	var tile := Balance.TILE_SIZE
	_draw_layer(StructureDef.Layer.FLOOR)
	_draw_zones(tile)
	for crop in _state.crops.values():
		_draw_frame(crop.def.asset, crop.stage(), 0, crop.cell)
	# Folhas de sprites das plantas: a coluna é a fase, a linha é a estação do calendário.
	var season := _state.clock.season()
	for stump in _state.stumps.values():
		_draw_frame(_TREES, _TREE_STUMP_ADULT if stump.from_adult else _TREE_STUMP_YOUNG, season, stump.cell)
	for plant in _state.fiber_plants.values():
		_draw_frame(_FIBER, _FIBER_GROWN if plant.is_mature() else _FIBER_SMALL, season, plant.cell)
	for bush in _state.bushes:
		var column := _BUSH_SEEDLING
		if bush.is_mature():
			column = _BUSH_WITH_BERRIES if bush.portions > 0 else _BUSH_EMPTY
		_draw_frame(_BUSHES, column, season, bush.cell)
	_draw_layer(StructureDef.Layer.BUILDING)
	var font := UiTheme.pixel_font()
	for stack in _state.stacks.values():
		var origin := Vector2(stack.cell * tile)
		draw_texture(AssetCatalog.texture(Defs.item(stack.item).icon), origin)
		draw_string_outline(font, origin + Vector2(1, tile - 1), str(stack.count), HORIZONTAL_ALIGNMENT_LEFT, -1, _COUNT_FONT_SIZE, 2, UiTheme.PANEL_BACKGROUND)
		draw_string(font, origin + Vector2(1, tile - 1), str(stack.count), HORIZONTAL_ALIGNMENT_LEFT, -1, _COUNT_FONT_SIZE, UiTheme.TEXT)
	_draw_animals(tile)
	_draw_raiders(tile)


func _draw_overlay() -> void:
	if _state == null:
		return
	var tile := Balance.TILE_SIZE
	_draw_designations(tile)
	_draw_health_bars(tile)
	_draw_smoke(tile)
	_draw_preview()
	if _has_selected_cell:
		_overlay.draw_texture(AssetCatalog.texture("ui/selection/bracket"), Vector2(_selected_cell * tile))
	for cell in _selected_cells:
		_overlay.draw_texture(AssetCatalog.texture("ui/selection/bracket"), Vector2(cell * tile))
	if _selected_area.has_area() and _selected_cells.is_empty():
		_overlay.draw_rect(Rect2(Vector2(_selected_area.position * tile), Vector2(_selected_area.size * tile)), _DRAG_BORDER, false, 1.0)
	if _drag_area.has_area():
		var area := Rect2(Vector2(_drag_area.position * tile), Vector2(_drag_area.size * tile))
		_overlay.draw_rect(area, _DRAG_FILL)
		_overlay.draw_rect(area, _DRAG_BORDER, false, 1.0)


## Pisos prontos (as outras construções prontas ficam no StructuresView) e plantas de construção.
func _draw_layer(layer: StructureDef.Layer) -> void:
	if layer == StructureDef.Layer.FLOOR:
		for structure in _state.structures.values():
			if structure.def.layer == layer:
				_draw_built(structure.def, structure.origin, Color.WHITE)
	for site in _state.sites.values():
		if site.def.layer == layer:
			_draw_built(site.def, site.origin, _BLUEPRINT_TINT, self, {}, site.rotation)


## A arte fica alinhada pela base do footprint: paredes de 16×24 sobem 8 px acima do tile.
## Paredes escolhem o quadro pelos vizinhos (StructureArt); `extra` são células da prévia.
## Girada, a arte gira em volta do centro do footprint já girado.
func _draw_built(def: StructureDef, origin: Vector2i, tint: Color, canvas: CanvasItem = self, extra := {}, rotation := 0) -> void:
	var region := StructureArt.region(_state, def, origin, extra)
	var tile := Balance.TILE_SIZE
	var texture := AssetCatalog.texture(def.asset)
	if rotation == 0:
		var position := Vector2(origin * tile) + Vector2(0, def.footprint.y * tile - region.size.y)
		canvas.draw_texture_rect_region(texture, Rect2(position, region.size), region, tint)
		return
	var center := Vector2(origin * tile) + Vector2(def.footprint_for(rotation) * tile) / 2.0
	canvas.draw_set_transform(center, rotation * PI / 2.0)
	canvas.draw_texture_rect_region(texture, Rect2(-region.size / 2.0, region.size), region, tint)
	canvas.draw_set_transform(Vector2.ZERO)


func _draw_preview() -> void:
	if _preview_def == null:
		return
	var extra := {}
	if _preview_def.joins_walls:
		for origin in _preview_valid:
			extra[origin] = true
	for origin in _preview_valid:
		_draw_built(_preview_def, origin, _PREVIEW_TINT, _overlay, extra, _preview_rotation)
	var tile := Balance.TILE_SIZE
	for origin in _preview_invalid:
		_overlay.draw_rect(Rect2(Vector2(origin * tile), Vector2(_preview_def.footprint_for(_preview_rotation) * tile)), _INVALID_FILL)


## Tiles das plantações: fundo verde claro com borda, sob as plantas.
func _draw_zones(tile: int) -> void:
	for cell in _state.zone_by_cell:
		var rect := Rect2(Vector2(cell * tile), Vector2(tile, tile))
		draw_rect(rect, _ZONE_FILL)
		draw_rect(rect.grow(-0.5), _ZONE_BORDER, false, 1.0)


## Animais na posição interpolada do passo, com os pés na base do tile (arte maior centralizada).
func _draw_animals(tile: int) -> void:
	for animal in _state.animals.values():
		var texture := AssetCatalog.texture(animal.def.asset)
		var at := Vector2(animal.cell).lerp(Vector2(animal.next_cell()), animal.move_progress) * tile
		var position := at + Vector2((tile - texture.get_width()) / 2.0, tile - texture.get_height())
		draw_texture(texture, position.round())


## Saqueadores na posição interpolada (a barra de vida fica na camada de cima).
func _draw_raiders(tile: int) -> void:
	for raider: Raider in _state.threats.raiders.values():
		var texture := AssetCatalog.texture(raider.asset())
		var at := Vector2(raider.cell).lerp(Vector2(raider.next_cell()), raider.move_progress) * tile
		var position := at + Vector2((tile - texture.get_width()) / 2.0, tile - texture.get_height())
		draw_texture(texture, position.round())


## Barras de vida sob colonos e saqueadores feridos.
func _draw_health_bars(tile: int) -> void:
	for colonist in _state.colonists:
		var at := Vector2(colonist.cell).lerp(Vector2(colonist.next_cell()), colonist.move_progress) * tile
		_draw_health_bar(at, colonist.health, tile)
	for raider: Raider in _state.threats.raiders.values():
		var at := Vector2(raider.cell).lerp(Vector2(raider.next_cell()), raider.move_progress) * tile
		_draw_health_bar(at, raider.health, tile)


func _draw_health_bar(at: Vector2, health: Health, tile: int) -> void:
	if not health.is_hurt():
		return
	var origin := (at + Vector2(0, tile)).round()
	_overlay.draw_rect(Rect2(origin, Vector2(tile, _HEALTH_BAR_HEIGHT)), _HEALTH_BAR_BACK)
	_overlay.draw_rect(Rect2(origin, Vector2(tile * health.percent() / 100.0, _HEALTH_BAR_HEIGHT)), _HEALTH_BAR_FILL)


## Aviso de ataque (GDD: sinais antes da ameaça): uma coluna de fumaça perto da borda.
func _draw_smoke(tile: int) -> void:
	var raid := _state.threats.raid
	if raid == null or raid.phase != Raid.Phase.WARNED:
		return
	var base := Vector2(raid.smoke_cell * tile) + Vector2(tile / 2.0, tile)
	var drift := sin(_state.clock.tick / 40.0) * 2.0
	for i in 4:
		_overlay.draw_circle(base + Vector2(drift * i, -6.0 * i), 4.0 + i, _SMOKE)


## Quadro maior que o tile (árvore de 32×32) fica centrado no tile e apoiado na base dele.
func _draw_frame(asset_id: String, column: int, row: int, cell: Vector2i) -> void:
	var frame := AssetCatalog.frame_size(asset_id)
	var tile := Balance.TILE_SIZE
	var offset := Vector2((tile - frame.x) / 2.0, tile - frame.y)
	var destination := Rect2(Vector2(cell * tile) + offset, Vector2(frame))
	draw_texture_rect_region(AssetCatalog.texture(asset_id), destination, AssetCatalog.frame_region(asset_id, column, row))


func _draw_designations(tile: int) -> void:
	var tick := _state.clock.tick
	for task in _state.task_board.all_tasks():
		if task.kind == Task.Kind.HAUL:
			continue
		var origin := Vector2(task.cell * tile)
		var tint := _BLOCKED_TINT if task.is_blocked(tick) else _DESIGNATION_TINT
		if _DESIGNATION_ICONS.has(task.kind):
			_overlay.draw_texture(AssetCatalog.texture(_DESIGNATION_ICONS[task.kind]), origin, tint)
		elif task.is_blocked(tick) and not _SILENT_TASKS.has(task.kind):
			_overlay.draw_rect(Rect2(origin, Vector2(tile, tile)), _INVALID_FILL)
		if task.progress > 0.0 and task.work_required > 0.0:
			var fraction := clampf(task.progress / task.work_required, 0.0, 1.0)
			_overlay.draw_rect(Rect2(origin + Vector2(0, tile - _PROGRESS_HEIGHT), Vector2(tile, _PROGRESS_HEIGHT)), UiTheme.PANEL_BACKGROUND)
			_overlay.draw_rect(Rect2(origin + Vector2(0, tile - _PROGRESS_HEIGHT), Vector2(tile * fraction, _PROGRESS_HEIGHT)), UiTheme.COMMUNITY)
