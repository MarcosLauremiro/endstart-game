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
const _KEY_DRAFT := KEY_V
## Com Ctrl: salvamento rápido.
const _KEY_QUICK_SAVE := KEY_S
const _QUICK_SAVE_NAME := "rapido"
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
## Seleção por arraste: vários colonos (dois ou mais) ou, sem colonos no retângulo, uma área com as
## árvores, rochas e plantas dela (selected_resources; vazio = tudo o que há na área).
var selected_group: Array[int] = []
var selected_area := Rect2i()
var selected_resources: Array[Vector2i] = []

var _world_view: WorldView
var _objects_view: ObjectsView
var _colonists_view: ColonistsView
var _trees_view: TreesView
var _structures_view: StructuresView
var _camera: CameraController
var _daylight: DaylightView
var _hud: Hud
var _tool: Designations.Tool = Designations.Tool.NONE
## Estrutura escolhida no menu de construção (null = não está construindo).
var _build_def: StructureDef
var _drag_start := _NO_DRAG
## Último dia com salvamento automático (às 6h de cada dia novo).
var _autosaved_day := 0


func _ready() -> void:
	_world_view = WorldView.new()
	add_child(_world_view)
	_objects_view = ObjectsView.new()
	add_child(_objects_view)
	# Árvores e colonos sob o mesmo nó ordenado pela altura: a copa esconde quem está atrás.
	var actors := Node2D.new()
	actors.y_sort_enabled = true
	add_child(actors)
	_trees_view = TreesView.new()
	actors.add_child(_trees_view)
	_structures_view = StructuresView.new()
	actors.add_child(_structures_view)
	_colonists_view = ColonistsView.new()
	actors.add_child(_colonists_view)
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
	_hud.colonist_chosen.connect(func(id: int) -> void:
		_clear_selection()
		selected_colonist_id = id)
	_hud.alert_chosen.connect(func(cell: Vector2i, colonist_id: int) -> void:
		if colonist_id != 0 and simulation.state.colonist_by_id(colonist_id):
			_clear_selection()
			selected_colonist_id = colonist_id
			_camera.focus(simulation.state.colonist_by_id(colonist_id).cell)
		elif cell != Alerts.NO_CELL:
			_camera.focus(cell)
			_select_at(cell))
	_hud.colonist_focused.connect(func(id: int) -> void:
		var colonist := simulation.state.colonist_by_id(id)
		if colonist:
			_clear_selection()
			selected_colonist_id = id
			_camera.focus(colonist.cell))
	_hud.save_requested.connect(_save)
	_hud.load_requested.connect(_load)
	_hud.new_game_requested.connect(func() -> void:
		_hud.set_menu_open(false)
		start_new_game(_random_seed()))
	_hud.quit_requested.connect(func() -> void: get_tree().quit())
	start_new_game(_read_seed_argument())


func start_new_game(world_seed: int) -> void:
	_start(Simulation.new(world_seed))


func _start(new_simulation: Simulation) -> void:
	simulation = new_simulation
	simulation.clock.allow_debug_speed = OS.is_debug_build()
	_autosaved_day = simulation.clock.day()
	_clear_selection()
	_set_tool(Designations.Tool.NONE)
	_world_view.show_world(simulation.world)
	_objects_view.bind(simulation.state)
	_trees_view.clear()
	_structures_view.clear()
	_camera.set_map_bounds(simulation.world.size * Balance.TILE_SIZE)
	_hud.bind(simulation)
	_refresh_views()


func _process(delta: float) -> void:
	simulation.advance(delta)
	_autosave()
	# Arraste de seleção solto em cima da interface: o botão já não está apertado, então desiste.
	if _selecting() and not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		_drag_start = _NO_DRAG
	_refresh_views()


func _refresh_views() -> void:
	var dragging_area := _drag_start != _NO_DRAG and _build_def == null
	_objects_view.set_drag_area(_drag_area(_mouse_cell()) if dragging_area else Rect2i())
	_refresh_build_preview()
	_objects_view.refresh()
	_world_view.sync(simulation.world)
	_daylight.show_light(Daylight.light_at(simulation.clock.tick))
	_objects_view.set_selected_cell(selected_cell, has_selected_cell)
	_prune_group()
	_prune_resources()
	_objects_view.set_selected_area(selected_area, selected_resources)
	_trees_view.sync(simulation.state)
	_structures_view.sync(simulation.state)
	_colonists_view.sync(simulation.state.colonists, _selected_ids(), simulation.clock.tick)
	_hud.refresh(selected_colonist_id, selected_cell, has_selected_cell, _tool, _build_def != null, selected_group, selected_area, selected_resources)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		_handle_mouse_button(event)
	elif event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == _KEY_QUICK_SAVE and event.ctrl_pressed:
			_save(_QUICK_SAVE_NAME)
		else:
			_handle_key(event.keycode)


func _handle_mouse_button(event: InputEventMouseButton) -> void:
	var cell := _mouse_cell()
	if event.button_index == MOUSE_BUTTON_MIDDLE and event.pressed:
		_copy_structure_at(cell)
		return
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
			_drag_start = cell
		elif _drag_start != _NO_DRAG:
			# Soltar no mesmo tile é um clique; arrastar seleciona tudo no retângulo.
			if cell == _drag_start:
				_select_at(cell)
			else:
				_select_area(_drag_area(cell))
			_drag_start = _NO_DRAG
	elif event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		if _tool != Designations.Tool.NONE:
			_set_tool(Designations.Tool.NONE)
		elif selected_group.size() > 1:
			var message := MultiSelect.order_group(simulation, selected_group, cell)
			if not message.is_empty():
				_hud.post_message(message)
		elif selected_colonist_id != 0:
			# Botão direito num saqueador = atacar; numa tarefa = priorizar; em chão livre = ir até lá.
			var raider := RaiderAI.raider_at(simulation.state, cell)
			if raider == null:
				raider = RaiderAI.raider_at(simulation.state, cell + Vector2i.DOWN)
			if raider:
				_hud.post_message(simulation.order_attack(selected_colonist_id, raider.id))
			elif simulation.task_at(cell):
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
	elif keycode == _KEY_DRAFT:
		_toggle_draft()
	elif keycode == _KEY_FULLSCREEN:
		_toggle_fullscreen()
	elif keycode == _KEY_BACK:
		if _tool != Designations.Tool.NONE or _build_def:
			_set_tool(Designations.Tool.NONE)
		elif _hud.close_top_window():
			pass
		elif selected_colonist_id != 0 or has_selected_cell or not selected_group.is_empty() or selected_area.has_area():
			_clear_selection()
		else:
			_hud.toggle_menu()
	elif _TOOL_KEYS.has(keycode):
		_toggle_tool(_TOOL_KEYS[keycode])
	elif _SPEED_KEYS.has(keycode):
		simulation.clock.set_speed(Balance.SPEED_MULTIPLIERS[_SPEED_KEYS[keycode]])
	elif keycode == _KEY_DEBUG_SPEED and simulation.clock.allow_debug_speed:
		simulation.clock.set_speed(Balance.DEBUG_SPEED_MULTIPLIER)


func _save(save_name: String) -> void:
	var error := SaveGame.save(simulation, save_name)
	_hud.post_message("Partida salva: %s" % save_name if error == OK else "Não deu para salvar %s (erro %d)" % [save_name, error])


## Carrega a partida; ela começa pausada (Espaço continua).
func _load(save_name: String) -> void:
	var loaded := SaveGame.load_simulation(save_name)
	if loaded == null:
		_hud.post_message("Não deu para carregar %s: arquivo de outra versão ou corrompido" % save_name)
		return
	_hud.set_menu_open(false)
	if not loaded.clock.paused:
		loaded.clock.toggle_pause()
	_start(loaded)
	_hud.post_message("Partida carregada: %s (pausada; Espaço continua)" % save_name)


## Salvamento automático às 6h de cada dia novo, no arquivo "automatico".
func _autosave() -> void:
	var clock := simulation.clock
	if clock.day() > _autosaved_day and clock.hour() >= Balance.START_HOUR:
		_autosaved_day = clock.day()
		var error := SaveGame.save(simulation, SaveGame.AUTOSAVE_NAME)
		if error != OK:
			_hud.post_message("Salvamento automático falhou (erro %d)" % error)


## V: convoca ou dispensa o colono selecionado (ou o grupo); sem seleção, todos de uma vez.
func _toggle_draft() -> void:
	if selected_group.size() > 1:
		_hud.post_message(MultiSelect.draft_group(simulation, selected_group))
		return
	var colonist := simulation.state.colonist_by_id(selected_colonist_id) if selected_colonist_id != 0 else null
	var message := simulation.set_drafted(colonist.id, not colonist.drafted) if colonist else simulation.toggle_draft_all()
	if not message.is_empty():
		_hud.post_message(message)


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


## Fim do arraste sem ferramenta: os colonos do retângulo (um vira a seleção comum); sem colonos,
## as árvores, rochas e plantas dele; sem nada disso, a área inteira (MultiSelect).
func _select_area(area: Rect2i) -> void:
	_clear_selection()
	var ids := MultiSelect.colonists_in(simulation.state, area)
	if ids.size() == 1:
		selected_colonist_id = ids[0]
	elif ids.size() > 1:
		selected_group = ids
	else:
		selected_area = area.intersection(Rect2i(Vector2i.ZERO, simulation.world.size))
		selected_resources = MultiSelect.resources_in(simulation.state, selected_area)


func _clear_selection() -> void:
	selected_colonist_id = 0
	has_selected_cell = false
	selected_group = []
	selected_area = Rect2i()
	selected_resources = []


## Quem morreu sai do grupo; sobrando um, ele vira a seleção comum.
func _prune_group() -> void:
	if selected_group.is_empty():
		return
	var alive: Array[int] = []
	for id in selected_group:
		if simulation.state.colonist_by_id(id) != null:
			alive.append(id)
	selected_group = alive
	if selected_group.size() == 1:
		selected_colonist_id = selected_group[0]
		selected_group = []


## Árvore cortada, rocha minerada: sai da seleção; sem nenhuma, a seleção acaba.
func _prune_resources() -> void:
	if selected_resources.is_empty():
		return
	var left: Array[Vector2i] = []
	for cell in selected_resources:
		if MultiSelect.is_resource(simulation.state, cell):
			left.append(cell)
	selected_resources = left
	if left.is_empty():
		_clear_selection()


func _selected_ids() -> Array[int]:
	if selected_group.size() > 1:
		return selected_group
	var ids: Array[int] = []
	if selected_colonist_id != 0:
		ids.append(selected_colonist_id)
	return ids


func _selecting() -> bool:
	return _drag_start != _NO_DRAG and _tool == Designations.Tool.NONE and _build_def == null


func _toggle_tool(tool: Designations.Tool) -> void:
	_set_tool(Designations.Tool.NONE if _tool == tool else tool)


func _set_tool(tool: Designations.Tool) -> void:
	_tool = tool
	_build_def = null
	_drag_start = _NO_DRAG


func _start_building(def: StructureDef) -> void:
	_set_tool(Designations.Tool.NONE)
	_build_def = def


## Botão do meio numa construção: entra no modo de construir a mesma (mesmo tipo e material).
func _copy_structure_at(cell: Vector2i) -> void:
	if not simulation.world.contains(cell):
		return
	var def := Construction.def_at(simulation.state, cell)
	if def == null:
		return
	var problem := Construction.availability_problem(simulation.state, def)
	if not problem.is_empty():
		_hud.post_message("%s: %s" % [def.display_name, problem])
		return
	_start_building(def)
	_hud.post_message("Copiado: %s (clique para colocar, botão direito cancela)" % def.display_name)


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
