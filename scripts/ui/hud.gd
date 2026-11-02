class_name Hud
extends CanvasLayer
## Interface sobre o mapa. Segue as posições fixas do GDD (Interface > Tela principal):
## recursos no topo esquerdo, tempo no topo direito, inspeção embaixo à esquerda, ordens na base,
## mensagens embaixo à direita e janelas no centro.
## Só lê a simulação; ordens do jogador passam pelas APIs da simulação.

signal tool_selected(tool: Designations.Tool)
signal structure_selected(def: StructureDef)
signal container_focused(cell: Vector2i)

## O menu de construção abre logo acima da barra de baixo.
const _ABOVE_BOTTOM_BAR := 40
## O painel da bancada fica abaixo do painel de tempo.
const _BELOW_TIME_PANEL := 36

var _resource_bar: ResourceBar
var _time_panel: TimePanel
var _inspect_panel: InspectPanel
var _tile_panel: TilePanel
var _message_log: MessageLog
var _bottom_bar: BottomBar
var _work_window: WorkPriorityWindow
var _schedule_window: ScheduleWindow
var _research_window: ResearchWindow
var _build_menu: BuildMenu
var _storage_panel: StoragePanel
var _workbench_panel: WorkbenchPanel
var _simulation: Simulation
var _theme: Theme
var _root: Control


func _ready() -> void:
	_root = Control.new()
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_theme = UiTheme.build()
	_root.theme = _theme
	add_child(_root)
	_fit_to_window()
	get_viewport().size_changed.connect(_fit_to_window)

	_resource_bar = ResourceBar.new()
	_root.add_child(_resource_bar)
	_pin(_resource_bar, 0.0, 0.0)

	_time_panel = TimePanel.new()
	_root.add_child(_time_panel)
	_pin(_time_panel, 1.0, 0.0)

	_inspect_panel = InspectPanel.new()
	_inspect_panel.visible = false
	_root.add_child(_inspect_panel)
	_pin(_inspect_panel, 0.0, 1.0)

	_tile_panel = TilePanel.new()
	_tile_panel.visible = false
	_root.add_child(_tile_panel)
	_pin(_tile_panel, 0.0, 1.0)

	_message_log = MessageLog.new()
	_root.add_child(_message_log)
	_pin(_message_log, 1.0, 1.0)

	_bottom_bar = BottomBar.new()
	_root.add_child(_bottom_bar)
	_pin(_bottom_bar, 0.5, 1.0)
	_bottom_bar.tool_selected.connect(func(tool: Designations.Tool) -> void: tool_selected.emit(tool))
	_bottom_bar.work_window_toggled.connect(toggle_work_window)
	_bottom_bar.build_menu_toggled.connect(toggle_build_menu)
	_bottom_bar.storage_panel_toggled.connect(toggle_storage_panel)
	_bottom_bar.schedule_window_toggled.connect(toggle_schedule_window)
	_bottom_bar.research_window_toggled.connect(toggle_research_window)

	_work_window = WorkPriorityWindow.new()
	_work_window.visible = false
	_root.add_child(_work_window)
	_pin(_work_window, 0.5, 0.5)

	_schedule_window = ScheduleWindow.new()
	_schedule_window.visible = false
	_root.add_child(_schedule_window)
	_pin(_schedule_window, 0.5, 0.5)

	_research_window = ResearchWindow.new()
	_research_window.visible = false
	_root.add_child(_research_window)
	_pin(_research_window, 0.5, 0.5)

	_build_menu = BuildMenu.new()
	_build_menu.visible = false
	_root.add_child(_build_menu)
	_pin(_build_menu, 0.5, 1.0)
	_build_menu.offset_top -= _ABOVE_BOTTOM_BAR
	_build_menu.offset_bottom -= _ABOVE_BOTTOM_BAR
	_build_menu.structure_selected.connect(func(def: StructureDef) -> void:
		_build_menu.visible = false
		structure_selected.emit(def))

	_storage_panel = StoragePanel.new()
	_storage_panel.visible = false
	_root.add_child(_storage_panel)
	_pin(_storage_panel, 1.0, 0.5)
	_storage_panel.container_focused.connect(func(cell: Vector2i) -> void: container_focused.emit(cell))

	_workbench_panel = WorkbenchPanel.new()
	_workbench_panel.visible = false
	_root.add_child(_workbench_panel)
	_pin(_workbench_panel, 1.0, 0.0)
	_workbench_panel.offset_top += _BELOW_TIME_PANEL
	_workbench_panel.offset_bottom += _BELOW_TIME_PANEL


func bind(simulation: Simulation) -> void:
	_simulation = simulation
	_time_panel.bind(simulation.clock, simulation.world_seed, simulation.state)
	_work_window.bind(simulation)
	_schedule_window.bind(simulation)
	_research_window.bind(simulation)
	_build_menu.bind(simulation)
	_storage_panel.bind(simulation)
	_workbench_panel.bind(simulation)
	simulation.message_posted.connect(_message_log.add_message)


## Mostra o colono selecionado; se não houver, o tile selecionado (has_tile = false: nenhum),
## e o painel da bancada quando o tile tem uma.
func refresh(selected_id: int, tile: Vector2i, has_tile: bool, tool: Designations.Tool, building: bool) -> void:
	_resource_bar.refresh(_simulation.state)
	_time_panel.refresh()
	_bottom_bar.show_tool(tool, building or _build_menu.visible)
	if _storage_panel.visible:
		_storage_panel.refresh()
	if _research_window.visible:
		_research_window.refresh()
	if _build_menu.visible:
		_build_menu.refresh()
	var colonist := _simulation.state.colonist_by_id(selected_id) if selected_id != 0 else null
	_inspect_panel.visible = colonist != null
	if colonist:
		_inspect_panel.show_colonist(colonist, _simulation)
	_tile_panel.visible = colonist == null and has_tile
	if _tile_panel.visible:
		_tile_panel.show_tile(_simulation, tile)
	var bench := _simulation.state.workbench_at(tile) if _tile_panel.visible else null
	_workbench_panel.visible = bench != null
	if bench:
		_workbench_panel.show_bench(bench)


## A interface tem escala própria na tela (UiTheme.ui_scale_for), independente da do mapa:
## a camada encolhe ou cresce para isso, e a raiz ocupa a tela inteira nessas unidades.
func _fit_to_window() -> void:
	var screen := UiTheme.screen_scale(get_window().size)
	var ui := UiTheme.ui_scale_for(screen)
	scale = Vector2.ONE * float(ui) / screen
	_root.position = Vector2.ZERO
	_root.size = get_viewport().get_visible_rect().size * screen / ui
	_theme.default_font_size = UiTheme.font_size_for(ui)


func toggle_work_window() -> void:
	_work_window.visible = not _work_window.visible
	if _work_window.visible:
		_work_window.refresh()


func toggle_research_window() -> void:
	_research_window.visible = not _research_window.visible


func toggle_schedule_window() -> void:
	_schedule_window.visible = not _schedule_window.visible
	if _schedule_window.visible:
		_schedule_window.refresh()


func is_work_window_open() -> bool:
	return _work_window.visible


func toggle_build_menu() -> void:
	_build_menu.visible = not _build_menu.visible


func toggle_storage_panel() -> void:
	_storage_panel.visible = not _storage_panel.visible


## Fecha a janela aberta de cima (Esc). Devolve se havia alguma.
func close_top_window() -> bool:
	for window in [_build_menu, _storage_panel, _research_window, _schedule_window, _work_window]:
		if window.visible:
			window.visible = false
			return true
	return false


func post_message(text: String) -> void:
	_message_log.add_message(text)


## Prende o controle a um ponto da tela (0 = esquerda/topo, 0,5 = centro, 1 = direita/base);
## ele cresce para dentro da tela.
func _pin(control: Control, anchor_x: float, anchor_y: float) -> void:
	var margin := UiTheme.SCREEN_MARGIN
	control.anchor_left = anchor_x
	control.anchor_right = anchor_x
	control.anchor_top = anchor_y
	control.anchor_bottom = anchor_y
	var offset_x: float = 0.0 if anchor_x == 0.5 else (-margin if anchor_x > 0.5 else margin)
	var offset_y: float = 0.0 if anchor_y == 0.5 else (-margin if anchor_y > 0.5 else margin)
	control.offset_left = offset_x
	control.offset_right = offset_x
	control.offset_top = offset_y
	control.offset_bottom = offset_y
	control.grow_horizontal = _grow_for(anchor_x)
	control.grow_vertical = _grow_for(anchor_y)


static func _grow_for(anchor: float) -> Control.GrowDirection:
	if anchor == 0.5:
		return Control.GROW_DIRECTION_BOTH
	return Control.GROW_DIRECTION_BEGIN if anchor > 0.5 else Control.GROW_DIRECTION_END
