class_name TileInfo
extends RefCounted
## Texto do painel de inspeção de um tile (GDD: Painel de inspeção > Tile).
## Só lê o estado. As explicações de tarefa vêm do mesmo seletor que a IA usa para decidir.
## Temperatura e beleza entram quando esses sistemas existirem.


static func title(cell: Vector2i) -> String:
	return "Tile (%d, %d)" % [cell.x, cell.y]


static func describe(simulation: Simulation, cell: Vector2i) -> PackedStringArray:
	var state := simulation.state
	var lines := PackedStringArray()
	if not state.world.contains(cell):
		lines.append("Fora do mapa")
		return lines
	lines.append(_terrain_line(state.world.get_terrain(cell)))
	_describe_objects(state, cell, lines)
	for colonist in state.colonists:
		if colonist.cell == cell:
			lines.append("Aqui está %s" % colonist.display_name)
	var task := simulation.task_at(cell)
	if task:
		_describe_task(simulation, task, lines)
	return lines


static func _terrain_line(kind: int) -> String:
	var move := Terrain.move_factor(kind)
	var fertility := Terrain.fertility(kind)
	return "%s · movimento %s · fertilidade %s · construir: %s" % [
		Terrain.display_name(kind),
		"%d%%" % roundi(move * 100) if move > 0.0 else "intransponível",
		"%d%%" % roundi(fertility * 100) if fertility >= 0.0 else "—",
		Terrain.build_rule(kind),
	]


static func _describe_objects(state: WorldState, cell: Vector2i, lines: PackedStringArray) -> void:
	var tree: WildTree = state.trees_by_cell.get(cell)
	if tree:
		if tree.is_adult():
			lines.append("Árvore adulta · rende %d de madeira" % tree.wood_yield())
		else:
			lines.append("Árvore jovem · rende %d de madeira · adulta em %d h" % [
				tree.wood_yield(), Balance.TREE_GROWTH_HOURS - tree.growth_hours])
	var stump: Stump = state.stumps_by_cell.get(cell)
	if stump:
		lines.append("Toco de árvore %s · some em %d h" % [
			"adulta" if stump.from_adult else "jovem", Balance.STUMP_DECAY_HOURS - stump.age_hours])
	var bush := state.bush_at(cell)
	if bush:
		if not bush.is_mature():
			lines.append("Arbusto de frutas (muda) · dá frutas em %d h" % (Balance.BUSH_GROWTH_HOURS - bush.growth_hours))
		else:
			var line := "Arbusto de frutas · %d/%d porções" % [bush.portions, Balance.BERRY_BUSH_MAX_PORTIONS]
			var eater := state.reservations.owner_of(Reservations.bush_key(bush.id))
			if eater != 0:
				line += " · %s está comendo" % state.colonist_name(eater)
			lines.append(line)
	var fiber: FiberPlant = state.fiber_plants_by_cell.get(cell)
	if fiber:
		if fiber.is_mature():
			lines.append("Planta de fibra crescida · rende %d de fibra" % Balance.FIBER_YIELD)
		else:
			lines.append("Planta de fibra pequena · colhível em %d h" % (Balance.FIBER_GROWTH_HOURS - fiber.growth_hours))
	var zone: GrowZone = state.zone_by_cell.get(cell)
	if zone:
		var problem := Farming.sow_problem(state, cell)
		lines.append("Plantação de %s%s" % [zone.crop.display_name.to_lower(),
			"" if problem.is_empty() or problem == "já está semeado" else " · não dá para semear: %s" % problem])
	var crop: Crop = state.crops_by_cell.get(cell)
	if crop:
		var fertility := Terrain.fertility(state.world.get_terrain(cell))
		if crop.is_mature():
			lines.append("%s maduras · rende %d %s" % [crop.def.display_name, crop.def.harvest_yield, Defs.item(crop.def.product).display_name.to_lower()])
		else:
			lines.append("%s %d%% · maduras em %d h" % [crop.def.display_name, roundi(crop.fraction() * 100), crop.hours_left(fertility)])
	for animal in state.animals_at(cell):
		var hunted := " · marcado para caça" if state.task_board.hunt_for(animal.id) else ""
		lines.append("%s #%d · vida %.0f/%.0f · %s%s%s" % [animal.def.display_name, animal.id, animal.health,
			animal.def.max_health, animal.mode_name(), " · predador" if animal.def.is_predator else "", hunted])
	var ruin := state.ruin_at(cell)
	if ruin:
		var room := ruin.room_at(cell)
		var where := "%s · " % room["name"] if not room.is_empty() else ""
		var status := "investigada" if not room.is_empty() and room["investigated"] else "não investigada"
		lines.append("Ruína antiga · %s%s · %d de %d salas investigadas" % [where, status if not room.is_empty() else "", ruin.investigated_count(), ruin.rooms.size()])
	var bench := state.workbench_at(cell)
	if bench:
		lines.append("Bancada: %d pedidos na fila%s" % [bench.bills.size(),
			" · fazendo %s" % bench.job.recipe.display_name if bench.job else ""])
	var container: StorageContainer = state.containers_by_cell.get(cell)
	if container:
		_describe_container(container, lines)
	for structure in [state.floors_by_cell.get(cell), state.buildings_by_cell.get(cell)]:
		if structure:
			lines.append("%s%s" % [structure.def.display_name,
				" · resistência %d" % structure.def.hit_points if structure.def.blocks_movement else ""])
	for layer in [StructureDef.Layer.BUILDING, StructureDef.Layer.FLOOR]:
		var site := state.site_at(cell, layer)
		if site:
			lines.append("Planta: %s · materiais %s" % [site.def.display_name, site.materials_text()])
	var stack: ItemStack = state.stacks_by_cell.get(cell)
	if stack:
		var reserved := stack.count - stack.available()
		lines.append("Pilha no chão: %d %s%s" % [
			stack.count, Defs.item(stack.item).display_name, " (%d reservados)" % reserved if reserved > 0 else ""])


static func _describe_container(container: StorageContainer, lines: PackedStringArray) -> void:
	var used := 0
	for slot in container.slots:
		if slot["item"] != &"":
			used += 1
	lines.append("%s #%d · %d/%d espaços ocupados" % [container.def.display_name, container.id, used, container.slots.size()])
	var kept := PackedStringArray()
	for category in ItemDef.CATEGORY_NAMES:
		if container.allowed.get(category, false):
			kept.append(ItemDef.CATEGORY_NAMES[category].to_lower())
	lines.append("   guarda: %s" % (", ".join(kept) if not kept.is_empty() else "nada (filtro vazio)"))
	var contents := container.contents()
	if contents.is_empty():
		lines.append("   vazio")
	for item in contents:
		var reserved: int = contents[item] - container.available(item)
		lines.append("   %s: %d%s" % [
			Defs.item(item).display_name, contents[item], " (%d reservados)" % reserved if reserved > 0 else ""])


static func _describe_task(simulation: Simulation, task: Task, lines: PackedStringArray) -> void:
	var state := simulation.state
	var line := "Tarefa: %s" % task.label()
	if task.work_required > 0.0:
		line += " · %d%% feito" % roundi(clampf(task.progress / task.work_required, 0.0, 1.0) * 100)
	var owner := state.reservations.owner_of(task.key())
	if owner != 0:
		line += " · reservada por %s" % state.colonist_name(owner)
	var tick := state.clock.tick
	if task.is_blocked(tick):
		var minutes := (task.blocked_until - tick) * 60 / Balance.TICKS_PER_HOUR
		line += " · bloqueada: %s (tenta de novo em %d min)" % [task.block_reason, minutes]
	lines.append(line)
	lines.append("Quem faria:")
	for colonist in state.colonists:
		lines.append("   %s: %s" % [colonist.display_name, simulation.explain_task(colonist, task)])
