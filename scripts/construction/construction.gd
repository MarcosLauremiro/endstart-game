class_name Construction
extends RefCounted
## Regras de construção: onde dá para colocar, criar a planta, concluir, cancelar e desmontar.
## O jogador decide o que construir; os colonos fazem pelo quadro de tarefas (entregar e construir).


## Motivo de não poder colocar a estrutura com origem na célula, ou "" se pode.
static func placement_problem(state: WorldState, def: StructureDef, origin: Vector2i) -> String:
	var unavailable := availability_problem(state, def)
	if not unavailable.is_empty():
		return unavailable
	for cell in def.cells_at(origin):
		if not state.world.contains(cell):
			return "fora do mapa"
		var kind := state.world.get_terrain(cell)
		if Terrain.build_rule(kind) != "sim":
			return "%s: construir %s" % [Terrain.display_name(kind), Terrain.build_rule(kind)]
		if state.site_at(cell, def.layer):
			return "já há uma planta aqui"
		if def.layer == StructureDef.Layer.FLOOR:
			if state.floors_by_cell.has(cell):
				return "já tem piso"
		elif state.buildings_by_cell.has(cell) or state.containers_by_cell.has(cell):
			return "já há uma construção aqui"
	return ""


## Motivo de a estrutura não estar disponível para construir (ruína, pesquisa), ou "" se está.
static func availability_problem(state: WorldState, def: StructureDef) -> String:
	if not def.buildable:
		return "não se constrói"
	var research := state.research.missing_for_structure(def.id)
	if research:
		return "precisa da pesquisa %s" % research.display_name
	return ""


## Construção do tile para copiar (botão do meio): pronta ou em planta, a de cima antes do piso.
## null se não há nenhuma.
static func def_at(state: WorldState, cell: Vector2i) -> StructureDef:
	var structure: Structure = state.buildings_by_cell.get(cell)
	if structure:
		return structure.def
	var container: StorageContainer = state.containers_by_cell.get(cell)
	if container:
		return Defs.structure(container.def.id)
	for layer in [StructureDef.Layer.BUILDING, StructureDef.Layer.FLOOR]:
		var site := state.site_at(cell, layer)
		if site:
			return site.def
		if layer == StructureDef.Layer.FLOOR and state.floors_by_cell.has(cell):
			return state.floors_by_cell[cell].def
	return null


## Coloca a planta e cria a tarefa de Construir. Árvores no local são marcadas para corte.
static func place(state: WorldState, def: StructureDef, origin: Vector2i) -> ConstructionSite:
	if not placement_problem(state, def, origin).is_empty():
		return null
	var site := ConstructionSite.new(state.next_id(), def, origin)
	state.add_site(site)
	var task := state.task_board.create(Task.Kind.CONSTRUCT, origin, site.id, def.work_ticks(), state.clock.tick)
	task.max_workers = def.max_workers
	task.title = "Construir %s (%d, %d)" % [def.display_name, origin.x, origin.y]
	if def.layer == StructureDef.Layer.BUILDING:
		Designations.apply(state, Designations.Tool.CUT, Rect2i(origin, def.footprint))
	return site


## Uma árvore ainda ocupa o local? (a obra espera o corte)
static func tree_in_the_way(state: WorldState, site: ConstructionSite) -> bool:
	if site.def.layer == StructureDef.Layer.FLOOR:
		return false
	for cell in site.cells():
		if state.trees_by_cell.has(cell):
			return true
	return false


## Cancela a planta: todo material entregue volta ao chão.
static func cancel(state: WorldState, site: ConstructionSite) -> void:
	var task := state.task_board.construction_for_site(site.id)
	if task:
		state.task_board.remove(task, Task.Status.CANCELLED)
	state.remove_site(site)
	for item in site.delivered:
		if site.delivered[item] > 0:
			state.drop_items(site.origin, item, site.delivered[item])


## Conclui a obra: os materiais entregues viram a estrutura (ou o contêiner).
static func complete(state: WorldState, site: ConstructionSite) -> void:
	state.remove_site(site)
	var def := site.def
	state.research.record_first("construção:%s" % def.id)
	if def.layer == StructureDef.Layer.BUILDING:
		_clear_plants(state, site.cells())
	if def.container_def != &"":
		state.add_container(def.container_def, site.origin)
	else:
		var structure := Structure.new(state.next_id(), def, site.origin)
		state.add_structure(structure)
		if def.is_workbench():
			_open_workbench(state, structure)
	if def.blocks_movement:
		_move_out_of_the_way(state, site.cells())


## Marca para desmontar a estrutura ou o contêiner que ocupa a célula. Devolve se criou a tarefa.
static func designate_deconstruct(state: WorldState, cell: Vector2i) -> bool:
	var target := _built_at(state, cell)
	if target.is_empty() or state.task_board.deconstruction_for(target["id"]):
		return false
	if not target["def"].buildable:
		# Peças da ruína não se desmontam no MVP.
		return false
	var def: StructureDef = target["def"]
	var task := state.task_board.create(Task.Kind.DECONSTRUCT, target["origin"], target["id"],
		def.work_ticks() * Balance.DECONSTRUCT_WORK_FRACTION, state.clock.tick)
	task.title = "Desmontar %s (%d, %d)" % [def.display_name, target["origin"].x, target["origin"].y]
	return true


static func deconstruct_target_exists(state: WorldState, target_id: int) -> bool:
	return state.structures.has(target_id) or state.containers.has(target_id)


## Desmonta: devolve parte do material (GDD não define; ver Balance) e larga o conteúdo de contêineres.
static func deconstruct(state: WorldState, target_id: int) -> void:
	var def: StructureDef
	var origin: Vector2i
	if state.structures.has(target_id):
		var structure: Structure = state.structures[target_id]
		def = structure.def
		origin = structure.origin
		_close_workbench(state, target_id)
		state.remove_structure(structure)
	elif state.containers.has(target_id):
		var container: StorageContainer = state.containers[target_id]
		def = Defs.structure(container.def.id)
		origin = container.cell
		var contents := container.contents()
		state.remove_container(container)
		for item in contents:
			state.drop_items(origin, item, contents[item])
	else:
		return
	for item in def.costs:
		var refund := floori(def.costs[item] * Balance.DECONSTRUCT_REFUND)
		if refund > 0:
			state.drop_items(origin, item, refund)


## {id, def, origin} da construção na célula (estrutura ou contêiner), ou vazio.
static func _built_at(state: WorldState, cell: Vector2i) -> Dictionary:
	var structure: Structure = state.buildings_by_cell.get(cell, state.floors_by_cell.get(cell))
	if structure:
		return {"id": structure.id, "def": structure.def, "origin": structure.origin}
	var container: StorageContainer = state.containers_by_cell.get(cell)
	if container:
		return {"id": container.id, "def": Defs.structure(container.def.id), "origin": container.cell}
	return {}


## Bancada pronta: ganha a fila de pedidos e a tarefa no quadro, do tipo de trabalho dela.
static func _open_workbench(state: WorldState, structure: Structure) -> void:
	var bench := Workbench.new(structure)
	state.workbenches[bench.id] = bench
	var task := state.task_board.create(Task.Kind.CRAFT, bench.work_cell(), bench.id, 0.0, state.clock.tick, bench.work_type())
	task.title = "Trabalhar: %s" % bench.label()


## Bancada desmontada: os ingredientes separados voltam ao chão e a tarefa sai do quadro.
static func _close_workbench(state: WorldState, structure_id: int) -> void:
	var bench: Workbench = state.workbenches.get(structure_id)
	if bench == null:
		return
	bench.drop_staged(state)
	var task := state.task_board.craft_for_bench(bench.id)
	if task:
		state.task_board.remove(task, Task.Status.CANCELLED)
	state.workbenches.erase(bench.id)


## Plantas rasteiras, tocos e cultivos saem para dar lugar à obra (árvores já foram cortadas antes).
static func _clear_plants(state: WorldState, cells: Array[Vector2i]) -> void:
	for cell in cells:
		var crop: Crop = state.crops_by_cell.get(cell)
		if crop:
			state.remove_crop(crop)
		var bush := state.bush_at(cell)
		if bush:
			state.remove_bush(bush)
		var fiber: FiberPlant = state.fiber_plants_by_cell.get(cell)
		if fiber:
			state.remove_fiber_plant(fiber)
		var stump: Stump = state.stumps_by_cell.get(cell)
		if stump:
			state.remove_stump(stump)
		var designation := state.task_board.designation_at(cell)
		if designation:
			state.task_board.remove(designation, Task.Status.CANCELLED)


## Quem estava no lugar de uma estrutura sólida sai para o lado; itens no chão são largados ao lado.
static func _move_out_of_the_way(state: WorldState, cells: Array[Vector2i]) -> void:
	for cell in cells:
		var stack: ItemStack = state.stacks_by_cell.get(cell)
		if stack:
			var amount := stack.count
			var item := stack.item
			stack.count = 0
			state.remove_stack_if_empty(stack)
			state.drop_items(cell, item, amount)
		for colonist in state.colonists:
			if colonist.cell == cell:
				colonist.cell = state.nearest_walkable(cell)
				colonist.path.clear()
				colonist.move_progress = 0.0
