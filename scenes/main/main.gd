extends Node2D
## Ponto de entrada. Liga a simulação ao terreno, aos objetos, aos colonos, à câmera e à interface,
## e traduz a entrada do jogador em comandos da simulação.
## Argumento opcional: godot --path . -- --seed=12345 (sem argumento, a seed é sorteada).

const _SEED_ARGUMENT_PREFIX := "--seed="
const _KEY_PAUSE := KEY_SPACE
## Mapa novo é atalho de desenvolvimento.
const _KEY_NEW_MAP := KEY_F5
const _KEY_RESEARCH := KEY_R
const _KEY_BACK := KEY_ESCAPE
const _KEY_WORK_WINDOW := KEY_W
const _KEY_BUILD_MENU := KEY_B
const _KEY_STORAGE := KEY_I
const _KEY_FULLSCREEN := KEY_F11
const _KEY_SCHEDULE := KEY_A
## tecla → índice em Balance.SPEED_MULTIPLIERS (como no RimWorld: 1, 2, 3)
const _SPEED_KEYS := {KEY_1: 0, KEY_2: 1, KEY_3: 2}
const _KEY_DEBUG_SPEED := KEY_4
const _TOOL_KEYS := {
	KEY_C: Designations.Tool.CUT,
	KEY_M: Designations.Tool.MINE,
	KEY_H: Designations.Tool.HARVEST,
	KEY_K: Designations.Tool.HUNT,
	KEY_P: Designations.Tool.GROW_ZONE,
	KEY_D: Designations.Tool.DECONSTRUCT,
	KEY_X: Designations.Tool.CANCEL,
}
const _NO_DRAG := Vector2i(-1, -1)

var simulation: Simulation
var selected_colonist_id: int = 0
## Tile selecionado quando o clique não pegou nenhum colono.
var selected_cell := Vector2i.ZERO
var has_selected_cell := false

var _world_view: WorldView
var _objects_view: ObjectsView
var _colonists_view: ColonistsView
var _camera: CameraController
var _daylight: DaylightView
var _hud: Hud
var _tool: Designations.Tool = Designations.Tool.NONE
## Estrutura escolhida no menu de construção (null = não está construindo).
var _build_def: StructureDef
var _drag_start := _NO_DRAG


func _ready() -> void:
	_world_view = WorldView.new()
	add_child(_world_view)
	_objects_view = ObjectsView.new()
	add_child(_objects_view)
	_colonists_view = ColonistsView.new()
	add_child(_colonists_view)
	_daylight = DaylightView.new()
	add_child(_daylight)
	_camera = CameraController.new()
	add_child(_camera)
	_hud = Hud.new()
	add_child(_hud)
	_hud.tool_selected.connect(_toggle_tool)
	_hud.structure_selected.connect(_start_building)
	_hud.container_focused.connect(func(cell: Vector2i) -> void:
		_camera.focus(cell)
		_select_at(cell))
	start_new_game(_read_seed_argument())


func start_new_game(world_seed: int) -> void:
	simulation = Simulation.new(world_seed)
	simulation.clock.allow_debug_speed = OS.is_debug_build()
	_clear_selection()
	_set_tool(Designations.Tool.NONE)
	_world_view.show_world(simulation.world)
	_objects_view.bind(simulation.state)
	_camera.set_map_bounds(simulation.world.size * Balance.TILE_SIZE)
	_hud.bind(simulation)
	_refresh_views()


func _process(delta: float) -> void:
	simulation.advance(delta)
	_refresh_views()


func _refresh_views() -> void:
	var dragging_area := _drag_start != _NO_DRAG and _build_def == null
	_objects_view.set_drag_area(_drag_area(_mouse_cell()) if dragging_area else Rect2i())
	_refresh_build_preview()
	_objects_view.refresh()
	_daylight.show_light(Daylight.light_at(simulation.clock.tick))
	_objects_view.set_selected_cell(selected_cell, has_selected_cell)
	_colonists_view.sync(simulation.state.colonists, selected_colonist_id)
	_hud.refresh(selected_colonist_id, selected_cell, has_selected_cell, _tool, _build_def != null)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		_handle_mouse_button(event)
	elif event is InputEventKey and event.pressed and not event.echo:
		_handle_key(event.keycode)


func _handle_mouse_button(event: InputEventMouseButton) -> void:
	var cell := _mouse_cell()
	if event.button_index == MOUSE_BUTTON_LEFT and _build_def:
		if event.pressed:
			_drag_start = cell
		elif _drag_start != _NO_DRAG:
			_place(_build_origins(cell))
			_drag_start = _NO_DRAG
		return
	if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed and _build_def:
		_set_tool(Designations.Tool.NONE)
		return
	if event.button_index == MOUSE_BUTTON_LEFT:
		if _tool != Designations.Tool.NONE:
			if event.pressed:
				_drag_start = cell
			elif _drag_start != _NO_DRAG:
				_apply_tool(_drag_area(cell))
				_drag_start = _NO_DRAG
		elif event.pressed:
			_select_at(cell)
	elif event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		if _tool != Designations.Tool.NONE:
			_set_tool(Designations.Tool.NONE)
		elif selected_colonist_id != 0:
			# Botão direito numa tarefa = priorizar; em chão livre = ir até lá.
			if simulation.task_at(cell):
				simulation.order_task(selected_colonist_id, cell)
			else:
				simulation.order_move(selected_colonist_id, cell)


func _handle_key(keycode: Key) -> void:
	if keycode == _KEY_PAUSE:
		simulation.clock.toggle_pause()
	elif keycode == _KEY_NEW_MAP and OS.is_debug_build():
		start_new_game(_random_seed())
	elif keycode == _KEY_WORK_WINDOW:
		_hud.toggle_work_window()
	elif keycode == _KEY_BUILD_MENU:
		_hud.toggle_build_menu()
	elif keycode == _KEY_STORAGE:
		_hud.toggle_storage_panel()
	elif keycode == _KEY_RESEARCH:
		_hud.toggle_research_window()
	elif keycode == _KEY_SCHEDULE:
		_hud.toggle_schedule_window()
	elif keycode == _KEY_FULLSCREEN:
		_toggle_fullscreen()
	elif keycode == _KEY_BACK:
		if _tool != Designations.Tool.NONE or _build_def:
			_set_tool(Designations.Tool.NONE)
		elif not _hud.close_top_window():
			_clear_selection()
	elif _TOOL_KEYS.has(keycode):
		_toggle_tool(_TOOL_KEYS[keycode])
	elif _SPEED_KEYS.has(keycode):
		simulation.clock.set_speed(Balance.SPEED_MULTIPLIERS[_SPEED_KEYS[keycode]])
	elif keycode == _KEY_DEBUG_SPEED and simulation.clock.allow_debug_speed:
		simulation.clock.set_speed(Balance.DEBUG_SPEED_MULTIPLIER)


## F11: tela cheia ↔ janela maximizada (a janela já abre maximizada, ver project.godot).
func _toggle_fullscreen() -> void:
	var window := get_window()
	if window.mode == Window.MODE_FULLSCREEN:
		window.mode = Window.MODE_MAXIMIZED
	else:
		window.mode = Window.MODE_FULLSCREEN


## Clique esquerdo: um colono ali vira a seleção; senão, o próprio tile (GDD: Painel de inspeção).
func _select_at(cell: Vector2i) -> void:
	# A arte do colono passa 8 px acima do tile: clicar na cabeça também seleciona.
	var colonist := simulation.state.colonist_at(cell)
	if colonist == null:
		colonist = simulation.state.colonist_at(cell + Vector2i.DOWN)
	_clear_selection()
	if colonist:
		selected_colonist_id = colonist.id
	elif simulation.world.contains(cell):
		selected_cell = cell
		has_selected_cell = true


func _clear_selection() -> void:
	selected_colonist_id = 0
	has_selected_cell = false


func _toggle_tool(tool: Designations.Tool) -> void:
	_set_tool(Designations.Tool.NONE if _tool == tool else tool)


func _set_tool(tool: Designations.Tool) -> void:
	_tool = tool
	_build_def = null
	_drag_start = _NO_DRAG


func _start_building(def: StructureDef) -> void:
	_set_tool(Designations.Tool.NONE)
	_build_def = def


## Origens das plantas para o arraste atual: um ponto, a área cheia ou o contorno.
func _build_origins(end: Vector2i) -> Array[Vector2i]:
	var origins: Array[Vector2i] = []
	if _build_def.placement == StructureDef.Placement.SINGLE or _drag_start == _NO_DRAG:
		origins.append(end)
		return origins
	var area := _drag_area(end)
	for y in range(area.position.y, area.end.y):
		for x in range(area.position.x, area.end.x):
			var on_edge := x == area.position.x or x == area.end.x - 1 or y == area.position.y or y == area.end.y - 1
			if _build_def.placement == StructureDef.Placement.AREA or on_edge:
				origins.append(Vector2i(x, y))
	return origins


func _place(origins: Array[Vector2i]) -> void:
	var result := simulation.place_structures(_build_def, origins)
	var placed: int = result["placed"]
	var refused := origins.size() - placed
	if refused == 0:
		_hud.post_message("%s: %d plantas colocadas" % [_build_def.display_name, placed])
	else:
		_hud.post_message("%s: %d colocadas, %d recusadas (%s)" % [_build_def.display_name, placed, refused, result["problem"]])


func _refresh_build_preview() -> void:
	if _build_def == null:
		_objects_view.set_build_preview(null, [], [])
		return
	var valid: Array[Vector2i] = []
	var invalid: Array[Vector2i] = []
	for origin in _build_origins(_mouse_cell()):
		if simulation.placement_problem(_build_def, origin).is_empty():
			valid.append(origin)
		else:
			invalid.append(origin)
	_objects_view.set_build_preview(_build_def, valid, invalid)


func _apply_tool(area: Rect2i) -> void:
	var changed := simulation.designate(_tool, area)
	var verb := "canceladas" if _tool == Designations.Tool.CANCEL else "marcadas"
	if changed == 0:
		_hud.post_message("%s: nada nessa área" % Designations.TOOL_NAMES[_tool])
	elif _tool == Designations.Tool.GROW_ZONE:
		_hud.post_message("Plantação: %d tiles cultiváveis; os colonos semeiam sozinhos" % changed)
	else:
		_hud.post_message("%s: %d tarefas %s" % [Designations.TOOL_NAMES[_tool], changed, verb])


func _drag_area(end: Vector2i) -> Rect2i:
	var top_left := Vector2i(mini(_drag_start.x, end.x), mini(_drag_start.y, end.y))
	var bottom_right := Vector2i(maxi(_drag_start.x, end.x), maxi(_drag_start.y, end.y))
	return Rect2i(top_left, bottom_right - top_left + Vector2i.ONE)


func _mouse_cell() -> Vector2i:
	return Vector2i((get_global_mouse_position() / Balance.TILE_SIZE).floor())


static func _read_seed_argument() -> int:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with(_SEED_ARGUMENT_PREFIX):
			return argument.trim_prefix(_SEED_ARGUMENT_PREFIX).to_int()
	return _random_seed()


static func _random_seed() -> int:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	return rng.randi()
