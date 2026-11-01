class_name Farming
extends RefCounted
## Plantações (GDD: plantação liberada desde o início; Cultivo é habilidade do MVP).
## O jogador desenha a zona uma vez; daí em diante os colonos semeiam, as plantas crescem
## e, maduras, viram tarefas de colher. Depois da colheita o tile volta a ser semeado sozinho.

## Cultivo de uma zona nova; o jogador troca pelas opções do tile.
const DEFAULT_CROP := &"carrot"


## Cria uma zona com os tiles cultiváveis da área. Devolve quantos tiles entraram.
static func create_zone(state: WorldState, area: Rect2i) -> int:
	var zone := GrowZone.new(state.next_id(), Defs.crop(DEFAULT_CROP))
	var clipped := area.intersection(Rect2i(Vector2i.ZERO, state.world.size))
	for y in range(clipped.position.y, clipped.end.y):
		for x in range(clipped.position.x, clipped.end.x):
			var cell := Vector2i(x, y)
			if zone_problem(state, cell).is_empty():
				zone.cells[cell] = true
				state.zone_by_cell[cell] = zone
	if zone.cells.is_empty():
		return 0
	state.zones[zone.id] = zone
	update_tasks(state)
	return zone.cells.size()


## Motivo de o tile não poder entrar numa plantação, ou "".
static func zone_problem(state: WorldState, cell: Vector2i) -> String:
	if state.zone_by_cell.has(cell):
		return "já é plantação"
	var kind := state.world.get_terrain(cell)
	if Terrain.fertility(kind) <= 0.0 or kind == Terrain.Kind.SHALLOW_WATER:
		return "%s não é cultivável" % Terrain.display_name(kind)
	if state.buildings_by_cell.has(cell) or state.containers_by_cell.has(cell) or state.building_sites_by_cell.has(cell):
		return "há uma construção"
	return ""


## Tira os tiles da área das plantações. As plantas já semeadas continuam até a colheita.
static func remove_cells(state: WorldState, area: Rect2i) -> int:
	var removed := 0
	for y in range(area.position.y, area.end.y):
		for x in range(area.position.x, area.end.x):
			var cell := Vector2i(x, y)
			var zone: GrowZone = state.zone_by_cell.get(cell)
			if zone == null:
				continue
			zone.cells.erase(cell)
			state.zone_by_cell.erase(cell)
			removed += 1
			var task := state.task_board.designation_at(cell)
			if task and task.kind == Task.Kind.SOW:
				state.task_board.remove(task, Task.Status.CANCELLED)
			if zone.cells.is_empty():
				state.zones.erase(zone.id)
	return removed


## Uma hora de jogo: as plantas crescem e as tarefas de semear e colher são atualizadas.
static func grow_hour(state: WorldState) -> void:
	for crop in state.crops.values():
		crop.grow_hour(Terrain.fertility(state.world.get_terrain(crop.cell)))
	update_tasks(state)


## Cria as tarefas que faltam: semear tiles livres das zonas e colher plantas maduras.
static func update_tasks(state: WorldState) -> void:
	var board := state.task_board
	var tick := state.clock.tick
	for zone in state.zones.values():
		for cell in zone.cells:
			if board.designation_at(cell) == null and sow_problem(state, cell).is_empty():
				var task := board.create(Task.Kind.SOW, cell, zone.id, zone.crop.sow_ticks(), tick)
				task.title = "Semear %s (%d, %d)" % [zone.crop.display_name.to_lower(), cell.x, cell.y]
	for crop in state.crops.values():
		if crop.is_mature() and board.designation_at(crop.cell) == null:
			var task := board.create(Task.Kind.REAP, crop.cell, crop.id, crop.def.harvest_ticks(), tick)
			task.title = "Colher %s (%d, %d)" % [crop.def.display_name.to_lower(), crop.cell.x, crop.cell.y]


## Motivo de não dar para semear o tile agora, ou "".
static func sow_problem(state: WorldState, cell: Vector2i) -> String:
	if not state.zone_by_cell.has(cell):
		return "não é plantação"
	if state.crops_by_cell.has(cell):
		return "já está semeado"
	if state.trees_by_cell.has(cell) or state.bushes_by_cell.has(cell) or state.fiber_plants_by_cell.has(cell) \
			or state.stumps_by_cell.has(cell):
		return "planta silvestre no lugar: corte ou colha antes"
	if state.buildings_by_cell.has(cell) or state.containers_by_cell.has(cell) or state.building_sites_by_cell.has(cell):
		return "há uma construção"
	if state.stacks_by_cell.has(cell):
		return "itens no chão"
	return ""


## Troca o que a zona planta. O que já foi semeado continua até a colheita; as tarefas de semear
## abertas são refeitas com o cultivo novo.
static func set_zone_crop(state: WorldState, zone: GrowZone, crop: CropDef) -> void:
	zone.crop = crop
	for cell in zone.cells:
		var task := state.task_board.designation_at(cell)
		if task and task.kind == Task.Kind.SOW:
			state.task_board.remove(task, Task.Status.CANCELLED)
	update_tasks(state)


static func sow(state: WorldState, cell: Vector2i, zone_id: int) -> void:
	var zone: GrowZone = state.zones.get(zone_id)
	if zone == null or not sow_problem(state, cell).is_empty():
		return
	state.add_crop(Crop.new(state.next_id(), zone.crop, cell))


static func reap(state: WorldState, crop_id: int) -> void:
	var crop: Crop = state.crops.get(crop_id)
	if crop == null or not crop.is_mature():
		return
	state.remove_crop(crop)
	state.drop_items(crop.cell, crop.def.product, crop.def.harvest_yield)
	state.research.record_first("colheita:%s" % crop.def.id)
