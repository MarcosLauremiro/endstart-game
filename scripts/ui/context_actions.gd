class_name ContextActions
extends RefCounted
## Opções do que o jogador clicou (GDD: Painel de inspeção). Cada opção é
## {"label": String, "tooltip": String, "enabled": bool, "run": Callable}; run() executa pela API da
## simulação e devolve a mensagem para o registro (ou ""). Só lê o estado para montar a lista.


static func for_cell(simulation: Simulation, cell: Vector2i) -> Array[Dictionary]:
	var state := simulation.state
	var options: Array[Dictionary] = []
	if not state.world.contains(cell):
		return options
	var board := state.task_board
	var designation := board.designation_at(cell)
	var one_cell := Rect2i(cell, Vector2i.ONE)

	var tree: WildTree = state.trees_by_cell.get(cell)
	if tree:
		options.append(_toggle_designation(simulation, designation, Task.Kind.CUT, "Cortar", "Cancelar corte",
			"Marca a árvore para corte (Cortar plantas)", one_cell, Designations.Tool.CUT))
	var bush := state.bush_at(cell)
	var fiber: FiberPlant = state.fiber_plants_by_cell.get(cell)
	if bush or fiber:
		var has_yield := (bush and bush.portions > 0) or (fiber and fiber.is_mature())
		var option := _toggle_designation(simulation, designation, Task.Kind.HARVEST, "Colher", "Cancelar colheita",
			"Marca a planta para colheita (Cultivar)", one_cell, Designations.Tool.HARVEST)
		if not has_yield and not (designation and designation.kind == Task.Kind.HARVEST):
			option["enabled"] = false
			option["tooltip"] = "Ainda não há o que colher"
		options.append(option)
	if state.world.get_terrain(cell) == Terrain.Kind.ROCK:
		options.append(_toggle_designation(simulation, designation, Task.Kind.MINE, "Minerar", "Cancelar mineração",
			"Marca a rocha para minerar", one_cell, Designations.Tool.MINE))

	for layer in [StructureDef.Layer.BUILDING, StructureDef.Layer.FLOOR]:
		var site := state.site_at(cell, layer)
		if site:
			options.append(_option("Cancelar obra: %s" % site.def.display_name,
				"Tira a planta de construção; o material entregue volta ao chão",
				func() -> String: return simulation.cancel_task(board.construction_for_site(site.id))))
	for target in [state.buildings_by_cell.get(cell), state.containers_by_cell.get(cell), state.floors_by_cell.get(cell)]:
		if target == null:
			continue
		var title: String = target.def.display_name
		var deconstruction := board.deconstruction_for(target.id)
		if deconstruction:
			options.append(_option("Cancelar desmontagem", "Desmarca %s" % title.to_lower(),
				func() -> String: return simulation.cancel_task(deconstruction)))
		else:
			options.append(_option("Desmontar: %s" % title, "Devolve metade do material; contêineres largam o conteúdo",
				func() -> String: return _designated(simulation, Designations.Tool.DECONSTRUCT, Rect2i(target_cell(target), Vector2i.ONE), title)))

	for animal in state.animals_at(cell):
		var hunt := board.hunt_for(animal.id)
		if hunt:
			options.append(_option("Cancelar caça: %s" % animal.def.display_name, "Desmarca o animal",
				func() -> String: return simulation.cancel_task(hunt)))
		else:
			var option := _option("Caçar: %s" % animal.def.display_name, "Marca o animal para caça (Caçar)",
				func() -> String: return simulation.hunt_animal(animal.id))
			if animal.def.is_predator:
				option["enabled"] = false
				option["tooltip"] = "Predador perigoso demais para caçar sem armas de combate"
			options.append(option)

	var zone: GrowZone = state.zone_by_cell.get(cell)
	if zone:
		for crop in Defs.crops():
			var option := _option("Plantar %s" % crop.display_name.to_lower(),
				"%d dias até madura, rende %d %s" % [roundi(crop.grow_days), crop.harvest_yield, Defs.item(crop.product).display_name.to_lower()],
				func() -> String: return simulation.set_zone_crop(zone.id, crop.id))
			if crop == zone.crop:
				option["enabled"] = false
				option["tooltip"] = "Esta plantação já planta %s" % crop.display_name.to_lower()
			options.append(option)
		options.append(_option("Remover plantação", "Tira o tile da plantação; o que já foi semeado continua até a colheita",
			func() -> String: return simulation.remove_zone_cells(one_cell)))
	elif options.is_empty() and Farming.zone_problem(state, cell).is_empty() and not state.has_object_at(cell):
		options.append(_option("Criar plantação aqui", "Para uma área maior, use a ordem Plantação (P) e arraste",
			func() -> String: return _designated(simulation, Designations.Tool.GROW_ZONE, one_cell, "Plantação")))
	return options


static func for_colonist(simulation: Simulation, colonist: Colonist) -> Array[Dictionary]:
	var options: Array[Dictionary] = []
	var id := colonist.id
	var eat := _option("Comer agora", "Ordem direta: come a melhor comida por perto",
		func() -> String: return simulation.order_eat(id))
	if colonist.needs.food >= Balance.EAT_UNTIL:
		eat["enabled"] = false
		eat["tooltip"] = "Está satisfeito (fome acima de %d%%)" % Balance.EAT_UNTIL
	options.append(eat)
	var sleep := _option("Dormir agora", "Ordem direta: dorme na cama livre mais perto (ou no chão)",
		func() -> String: return simulation.order_sleep(id))
	if colonist.needs.rest >= Balance.SLEEP_ORDER_MAX_REST:
		sleep["enabled"] = false
		sleep["tooltip"] = "Está descansado (sono acima de %d%%)" % Balance.SLEEP_ORDER_MAX_REST
	options.append(sleep)
	if colonist.direct_order:
		options.append(_option("Cancelar ordem", "Esquece a ordem direta: %s" % colonist.direct_order.label().to_lower(),
			func() -> String: return simulation.cancel_order(id)))
	return options


## Origem da construção (estrutura ou contêiner), para desmontar pela célula certa.
static func target_cell(target: Object) -> Vector2i:
	return target.cell if target is StorageContainer else target.origin


static func _toggle_designation(simulation: Simulation, designation: Task, kind: Task.Kind, label: String,
		cancel_label: String, tooltip: String, area: Rect2i, tool: Designations.Tool) -> Dictionary:
	if designation and designation.kind == kind:
		return _option(cancel_label, "Desmarca a tarefa", func() -> String: return simulation.cancel_task(designation))
	return _option(label, tooltip, func() -> String: return _designated(simulation, tool, area, label))


static func _designated(simulation: Simulation, tool: Designations.Tool, area: Rect2i, what: String) -> String:
	if simulation.designate(tool, area) > 0:
		return "%s: marcado" % what
	return "%s: nada para marcar aqui" % what


static func _option(label: String, tooltip: String, run: Callable) -> Dictionary:
	return {"label": label, "tooltip": tooltip, "enabled": true, "run": run}
