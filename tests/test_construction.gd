class_name TestConstruction
extends TestCase
## Construção e armazenamento (M3): regras de colocação, obra consumindo o material exato,
## abrigo completo sem microgerência, equipe na mesma obra, falta de material, cancelar devolvendo,
## desmontar, pátio de materiais, piso, árvore no local, colono no lugar da parede e cama.

const _SEED := 12345


func test_placement_rules_explain_refusals() -> void:
	var simulation := Simulation.new(_SEED, 1)
	var wall := Defs.structure(&"wall_wood")
	var rock := _first_cell_of(simulation, Terrain.Kind.ROCK)
	expect(simulation.placement_problem(wall, rock).begins_with("Rocha"), "Rocha não aceita parede")
	var free := _clear_area(simulation, Vector2i(1, 1))
	expect_equal(simulation.placement_problem(wall, free), "", "Grama livre aceita parede")
	Construction.place(simulation.state, wall, free)
	expect_equal(simulation.placement_problem(wall, free), "já há uma planta aqui", "Não empilha plantas")
	expect_equal(simulation.placement_problem(Defs.structure(&"floor_wood"), free), "", "Piso divide o tile com a parede")
	var crate: StorageContainer = simulation.state.containers.values()[0]
	expect_equal(simulation.placement_problem(wall, crate.cell), "já há uma construção aqui", "Não constrói em cima do caixote")


func test_builds_a_wall_with_the_exact_material() -> void:
	var simulation := Simulation.new(_SEED, 1)
	var cell := _clear_area(simulation, Vector2i(1, 1))
	var wood_before := simulation.state.total_count(&"wood")
	Construction.place(simulation.state, Defs.structure(&"wall_wood"), cell)
	_run_until(simulation, func() -> bool: return simulation.state.buildings_by_cell.has(cell), 8000)
	expect(simulation.state.buildings_by_cell.has(cell), "A parede deve ficar pronta")
	expect(not simulation.state.navigation.is_walkable(cell), "Parede bloqueia a passagem")
	expect_equal(simulation.state.total_count(&"wood"), wood_before - 3, "A parede consome exatamente 3 de madeira")


func test_colonists_build_a_shelter_on_their_own() -> void:
	var simulation := Simulation.new(_SEED, 3)
	var state := simulation.state
	var origin := _clear_area(simulation, Vector2i(5, 5))
	var wood_before := state.total_count(&"wood")
	var door := origin + Vector2i(2, 4)
	simulation.place_structures(Defs.structure(&"door_simple"), [door])
	var outline: Array[Vector2i] = []
	for y in 5:
		for x in 5:
			if x == 0 or x == 4 or y == 0 or y == 4:
				outline.append(origin + Vector2i(x, y))
	var walls: Dictionary = simulation.place_structures(Defs.structure(&"wall_wood"), outline)
	expect_equal(walls["placed"], 15, "15 paredes (o lugar da porta já tem planta)")
	simulation.place_structures(Defs.structure(&"bed_rustic"), [origin + Vector2i(1, 1)])
	var built := _run_until(simulation, func() -> bool: return state.sites.is_empty(), 40000)
	expect(built, "O abrigo deve ficar pronto sem ordens além das plantas (faltam %d obras)" % state.sites.size())
	var finished := state.structures.values().filter(func(structure: Structure) -> bool: return structure.def.buildable)
	expect_equal(finished.size(), 17, "15 paredes, 1 porta e 1 cama")
	expect_equal(state.total_count(&"wood"), wood_before - (15 * 3 + 5 + 12), "Madeira gasta = custo exato do abrigo")
	var outside := origin + Vector2i(2, 6)
	expect(state.navigation.can_reach(outside, origin + Vector2i(2, 2)), "Dá para entrar pela porta")
	var sleeper := state.colonists[0]
	sleeper.needs.rest = 15.0
	_run_until(simulation, func() -> bool: return sleeper.is_sleeping(), 4000)
	expect(sleeper.is_sleeping_in_bed(), "Com sono, o colono procura a cama construída")


func test_team_builds_a_bed_faster_than_one_colonist() -> void:
	var ticks := {}
	var most_workers := 0
	for count in [1, 3]:
		var simulation := Simulation.new(_SEED, count)
		for colonist in simulation.state.colonists:
			colonist.traits.clear()
			colonist.strength = Balance.ATTRIBUTE_AVERAGE
		var origin := _clear_area(simulation, Vector2i(1, 2))
		var site := Construction.place(simulation.state, Defs.structure(&"bed_rustic"), origin)
		site.delivered[&"wood"] = 12
		var task := simulation.state.task_board.construction_for_site(site.id)
		var elapsed := 0
		while simulation.state.sites.has(site.id) and elapsed < 20000:
			simulation.step()
			elapsed += 1
			var workers := 0
			for colonist in simulation.state.colonists:
				if colonist.action and colonist.action.task_id == task.id and colonist.state == Colonist.State.EXECUTING:
					workers += 1
			most_workers = maxi(most_workers, workers)
		ticks[count] = elapsed
	expect(most_workers >= 2, "Mais de um colono deve trabalhar na mesma cama (máximo visto: %d)" % most_workers)
	expect(ticks[3] < ticks[1] * 0.8, "Em equipe deve ser bem mais rápido (%d contra %d ticks)" % [ticks[3], ticks[1]])


func test_missing_material_blocks_with_reason() -> void:
	var simulation := Simulation.new(_SEED, 1)
	for container in simulation.state.containers.values():
		container.take_all(&"wood")
	var cell := _clear_area(simulation, Vector2i(1, 1))
	var site := Construction.place(simulation.state, Defs.structure(&"wall_wood"), cell)
	_run(simulation, Balance.THINK_INTERVAL_TICKS * 2)
	var task := simulation.state.task_board.construction_for_site(site.id)
	expect(task.block_reason.begins_with("faltam materiais: 3 madeira"), "Motivo: %s" % task.block_reason)


func test_cancel_returns_delivered_material() -> void:
	var simulation := Simulation.new(_SEED, 1)
	var state := simulation.state
	var wood_before := state.total_count(&"wood")
	var origin := _clear_area(simulation, Vector2i(1, 2))
	var site := Construction.place(state, Defs.structure(&"bed_rustic"), origin)
	_run_until(simulation, func() -> bool: return site.delivered.get(&"wood", 0) > 0, 6000)
	expect(site.delivered.get(&"wood", 0) > 0, "Algum material deve ter sido entregue")
	simulation.designate(Designations.Tool.CANCEL, Rect2i(origin, Vector2i.ONE))
	_run(simulation, 5)
	expect(not state.sites.has(site.id), "A planta some")
	expect_equal(state.total_count(&"wood"), wood_before, "Todo o material entregue volta (nada some)")


func test_deconstruct_returns_half_and_drops_contents() -> void:
	var simulation := Simulation.new(_SEED, 1)
	var state := simulation.state
	var crate: StorageContainer = state.containers.values()[0]
	var meals_before := state.total_count(&"simple_meal")
	var wood_before := state.total_count(&"wood")
	expect(simulation.designate(Designations.Tool.DECONSTRUCT, Rect2i(crate.cell, Vector2i.ONE)) == 1, "Caixote marcado para desmontar")
	_run_until(simulation, func() -> bool: return not state.containers.has(crate.id), 6000)
	expect(not state.containers.has(crate.id), "O caixote deve ser desmontado")
	expect_equal(state.total_count(&"simple_meal"), meals_before, "O conteúdo vai para o chão, sem sumir")
	var refund := floori(5 * Balance.DECONSTRUCT_REFUND)
	expect_equal(state.total_count(&"wood"), wood_before + refund, "Devolve %d de madeira" % refund)


func test_material_yard_holds_only_materials_in_large_slots() -> void:
	var yard := StorageContainer.new(1, Defs.container(&"material_yard"), Vector2i.ZERO)
	expect_equal(yard.free_space(&"wood"), 4 * Balance.LARGE_SLOT_STACK, "4 espaços grandes de 300")
	expect_equal(yard.free_space(&"simple_meal"), 0, "Comida não entra no pátio")
	expect_equal(yard.cells().size(), 4, "O pátio ocupa 2×2")


func test_wooden_floor_speeds_up_walking() -> void:
	var simulation := Simulation.new(_SEED, 1)
	var cell := _clear_area(simulation, Vector2i(1, 1))
	var before := simulation.state.navigation.speed_factor(cell)
	simulation.state.add_structure(Structure.new(simulation.state.next_id(), Defs.structure(&"floor_wood"), cell))
	expect(absf(simulation.state.navigation.speed_factor(cell) - before * 1.1) < 0.001, "Piso de madeira: movimento 110%")


func test_tree_in_the_way_is_cut_first() -> void:
	var simulation := Simulation.new(_SEED, 1)
	var colonist := simulation.state.colonists[0]
	var tree: WildTree
	for candidate in simulation.state.trees.values():
		if simulation.state.navigation.can_reach(colonist.cell, candidate.cell):
			tree = candidate
			break
	var site := Construction.place(simulation.state, Defs.structure(&"wall_wood"), tree.cell)
	expect(simulation.state.task_board.designation_at(tree.cell) != null, "A árvore é marcada para corte")
	site.delivered[&"wood"] = 3
	var task := simulation.state.task_board.construction_for_site(site.id)
	expect_equal(simulation.explain_task(colonist, task), "árvore no local: aguardando o corte", "A obra explica a espera")


func test_colonist_standing_where_a_wall_appears_is_moved_out() -> void:
	var simulation := Simulation.new(_SEED, 1)
	var colonist := simulation.state.colonists[0]
	var cell := colonist.cell
	var site := ConstructionSite.new(simulation.state.next_id(), Defs.structure(&"wall_wood"), cell)
	simulation.state.add_site(site)
	Construction.complete(simulation.state, site)
	expect(colonist.cell != cell, "O colono sai do lugar da parede")
	expect(simulation.state.navigation.is_walkable(colonist.cell), "E vai para um lugar caminhável")


func test_bed_recovers_rest_faster_than_the_ground() -> void:
	var simulation := Simulation.new(_SEED, 1)
	var colonist := simulation.state.colonists[0]
	var cell := _clear_area(simulation, Vector2i(1, 2))
	simulation.state.add_structure(Structure.new(simulation.state.next_id(), Defs.structure(&"bed_rustic"), cell))
	colonist.needs.rest = 15.0
	_run_until(simulation, func() -> bool: return colonist.is_sleeping_in_bed(), 3000)
	expect(colonist.is_sleeping_in_bed(), "Deve dormir na cama")
	var start := colonist.needs.rest
	_run(simulation, Balance.TICKS_PER_HOUR)
	var gained := colonist.needs.rest - start
	expect(absf(gained - 15.0) < 0.5, "Cama recupera 15 de sono por hora (recuperou %.1f)" % gained)


func _run(simulation: Simulation, ticks: int) -> void:
	for _i in ticks:
		simulation.step()


## Avança até a condição valer ou o limite; devolve se a condição valeu.
func _run_until(simulation: Simulation, condition: Callable, limit: int) -> bool:
	for _i in limit:
		if condition.call():
			return true
		simulation.step()
	return condition.call()


## Área livre perto do primeiro colono (grama ou solo, sem contêiner, obra ou colono), alcançável.
## Árvores, arbustos e plantas de fibra dentro dela são retirados para o teste contar a madeira exata.
func _clear_area(simulation: Simulation, size: Vector2i) -> Vector2i:
	var state := simulation.state
	var start := state.colonists[0].cell
	for radius in range(2, 30):
		for y in range(start.y - radius, start.y + radius + 1):
			for x in range(start.x - radius, start.x + radius + 1):
				var origin := Vector2i(x, y)
				if _area_is_free(simulation, origin, size):
					_clear_plants(state, origin, size)
					return origin
	push_error("Nenhuma área livre de %s" % size)
	return start


func _area_is_free(simulation: Simulation, origin: Vector2i, size: Vector2i) -> bool:
	var state := simulation.state
	var anchor := state.colonists[0].cell
	for y in range(-1, size.y + 1):
		for x in range(-1, size.x + 1):
			var cell := origin + Vector2i(x, y)
			if not state.world.contains(cell):
				return false
			var kind := state.world.get_terrain(cell)
			if kind != Terrain.Kind.GRASS and kind != Terrain.Kind.DIRT:
				return false
			if state.containers_by_cell.has(cell) or state.colonist_at(cell) or state.stacks_by_cell.has(cell):
				return false
	return state.navigation.can_reach(anchor, origin + Vector2i(0, -1))


func _clear_plants(state: WorldState, origin: Vector2i, size: Vector2i) -> void:
	for y in range(-1, size.y + 1):
		for x in range(-1, size.x + 1):
			var cell := origin + Vector2i(x, y)
			if state.trees_by_cell.has(cell):
				state.remove_tree(state.trees_by_cell[cell])
			if state.bushes_by_cell.has(cell):
				state.remove_bush(state.bushes_by_cell[cell])
			if state.fiber_plants_by_cell.has(cell):
				state.remove_fiber_plant(state.fiber_plants_by_cell[cell])


func _first_cell_of(simulation: Simulation, kind: int) -> Vector2i:
	for y in simulation.world.size.y:
		for x in simulation.world.size.x:
			if simulation.world.get_terrain(Vector2i(x, y)) == kind:
				return Vector2i(x, y)
	return Vector2i.ZERO
