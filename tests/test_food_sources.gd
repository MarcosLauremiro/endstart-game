class_name TestFoodSources
extends TestCase
## Comida (M4): caça (presas fogem, o caçador persegue, a carcaça fica no chão), predador que caça
## presas, migração, plantação (semear, crescer, colher, semear de novo) e o aceite do M4:
## "A comida vem de caça e cozinha, sem intervenção constante".

const _SEED := 12345


func test_map_has_the_mvp_species() -> void:
	var simulation := Simulation.new(_SEED, 1)
	var counts := _species_counts(simulation.state)
	expect(counts.get(&"hare", 0) > 0 and counts.get(&"deer", 0) > 0, "Há caça pequena e grande no mapa")
	expect(counts.get(&"thornwolf", 0) > 0, "Há um predador no mapa")
	var center := simulation.world.size / 2
	for animal in simulation.state.animals.values():
		expect(animal.cell.distance_to(center) >= Balance.ANIMAL_SPAWN_MIN_DISTANCE, "Animais nascem longe da chegada")
		break


func test_hunter_kills_a_hare_and_leaves_a_carcass() -> void:
	var simulation := Simulation.new(_SEED, 1)
	var state := simulation.state
	var hare := _nearest_animal(state, &"hare")
	var area := Rect2i(hare.cell, Vector2i.ONE)
	expect_equal(simulation.designate(Designations.Tool.HUNT, area), 1, "A lebre é marcada para caça")
	var hunt := state.task_board.hunt_for(hare.id)
	expect(hunt != null and hunt.work_type == WorkType.Id.HUNT, "A caça é do tipo Caçar")
	var done := SimHelpers.run_until(simulation, func() -> bool: return not state.animals.has(hare.id), 20000)
	expect(done, "O colono caça a lebre (vida %.0f)" % hare.health)
	expect_equal(state.total_count(&"small_game_carcass"), 1, "A lebre vira uma carcaça")
	expect(state.task_board.hunt_for(hare.id) == null, "A tarefa de caça sai do quadro")


func test_hunted_prey_flees_from_the_hunter() -> void:
	var simulation := Simulation.new(_SEED, 1)
	var state := simulation.state
	var hare := _nearest_animal(state, &"hare")
	var colonist := state.colonists[0]
	var start := hare.cell
	Wildlife.hurt(state, hare, 1.0, start + Vector2i(1, 0))
	expect_equal(hare.mode, Animal.Mode.FLEE, "Ferida, a lebre foge")
	SimHelpers.run_until(simulation, func() -> bool: return hare.path.is_empty(), 600)
	expect(hare.cell.x < start.x, "Foge para longe de quem atacou (de %s para %s)" % [start, hare.cell])
	colonist.cell = hare.cell + Vector2i(2, 0)
	colonist.path.clear()
	hare.mode = Animal.Mode.WANDER
	SimHelpers.run_until(simulation, func() -> bool: return hare.mode == Animal.Mode.FLEE, 120)
	expect_equal(hare.mode, Animal.Mode.FLEE, "Um colono perto assusta a lebre")


func test_predator_cannot_be_designated() -> void:
	var simulation := Simulation.new(_SEED, 1)
	var wolf := _nearest_animal(simulation.state, &"thornwolf")
	expect_equal(simulation.designate(Designations.Tool.HUNT, Rect2i(wolf.cell, Vector2i.ONE)), 0, "Predador não é marcado")
	expect(simulation.state.task_board.hunt_for(wolf.id) == null, "Sem tarefa de caça para o predador")


func test_predator_hunts_prey() -> void:
	var simulation := Simulation.new(_SEED, 1)
	var state := simulation.state
	var wolf := _nearest_animal(state, &"thornwolf")
	var hare := _nearest_animal(state, &"hare", wolf.cell)
	wolf.hours_since_meal = wolf.def.hunt_interval_hours
	hare.cell = state.nearest_walkable(wolf.cell + Vector2i(3, 0))
	hare.path.clear()
	var eaten := SimHelpers.run_until(simulation, func() -> bool: return not state.animals.has(hare.id), 6000)
	expect(eaten, "O predador caça a lebre por perto")
	expect_equal(wolf.mode, Animal.Mode.EAT, "Depois come a presa")
	expect_equal(state.total_count(&"small_game_carcass"), 0, "Presa comida não deixa carcaça")


func test_animals_migrate_back() -> void:
	var simulation := Simulation.new(_SEED, 1)
	var state := simulation.state
	for animal in state.animals.values():
		if animal.def.id == &"hare":
			Wildlife.kill(state, animal, false)
	expect_equal(_species_counts(state).get(&"hare", 0), 0, "Sem lebres")
	SimHelpers.run_until(simulation, func() -> bool: return _species_counts(state).get(&"hare", 0) > 0, Balance.TICKS_PER_DAY + 10)
	expect_equal(_species_counts(state).get(&"hare", 0), 1, "Uma lebre migra pela borda num dia")


func test_auto_hunt_marks_arrivals() -> void:
	var simulation := Simulation.new(_SEED, 1)
	var state := simulation.state
	simulation.set_auto_hunt(&"deer", true)
	for animal in state.animals.values():
		if animal.def.id == &"deer":
			expect(state.task_board.hunt_for(animal.id) != null, "Todo cervo no mapa fica marcado")
	var arrival := Wildlife.add_animal(state, Defs.animal(&"deer"), state.nearest_walkable(Vector2i(2, 2)))
	expect(state.task_board.hunt_for(arrival.id) != null, "Quem chega também é marcado")


func test_grow_zone_sows_grows_and_reaps_again() -> void:
	var simulation := Simulation.new(_SEED, 1)
	var state := simulation.state
	var origin := SimHelpers.clear_area(simulation, Vector2i(2, 2))
	expect_equal(simulation.designate(Designations.Tool.GROW_ZONE, Rect2i(origin, Vector2i(2, 2))), 4, "4 tiles de plantação")
	var sown := SimHelpers.run_until(simulation, func() -> bool: return state.crops.size() == 4, 8000)
	expect(sown, "O colono semeia os 4 tiles (semeados %d)" % state.crops.size())
	for crop in state.crops.values():
		crop.growth_hours = crop.def.grow_hours() - 1.0
	var reaped := SimHelpers.run_until(simulation, func() -> bool: return state.total_count(&"vegetable") >= 4 * 6, 3 * Balance.TICKS_PER_HOUR)
	expect(reaped, "Maduras, as plantas são colhidas (vegetais %d)" % state.total_count(&"vegetable"))
	var resown := SimHelpers.run_until(simulation, func() -> bool: return state.crops.size() == 4, 3 * Balance.TICKS_PER_HOUR)
	expect(resown, "Depois da colheita, os tiles são semeados de novo")


func test_zone_refuses_water_and_explains() -> void:
	var simulation := Simulation.new(_SEED, 1)
	var state := simulation.state
	var water := Vector2i(-1, -1)
	for y in state.world.size.y:
		for x in state.world.size.x:
			if state.world.get_terrain(Vector2i(x, y)) == Terrain.Kind.SHALLOW_WATER:
				water = Vector2i(x, y)
	expect(Farming.zone_problem(state, water).contains("não é cultivável"), "Água rasa não vira plantação")
	expect_equal(simulation.designate(Designations.Tool.GROW_ZONE, Rect2i(water, Vector2i.ONE)), 0, "Nenhum tile entra")


func test_cancel_removes_zone_and_hunt() -> void:
	var simulation := Simulation.new(_SEED, 1)
	var state := simulation.state
	var origin := SimHelpers.clear_area(simulation, Vector2i(2, 2))
	simulation.designate(Designations.Tool.GROW_ZONE, Rect2i(origin, Vector2i(2, 2)))
	simulation.designate(Designations.Tool.CANCEL, Rect2i(origin, Vector2i(2, 2)))
	expect(state.zones.is_empty(), "Cancelar apaga a plantação")
	var hare := _nearest_animal(state, &"hare")
	simulation.designate(Designations.Tool.HUNT, Rect2i(hare.cell, Vector2i.ONE))
	simulation.designate(Designations.Tool.CANCEL, Rect2i(hare.cell, Vector2i.ONE))
	expect(state.task_board.hunt_for(hare.id) == null, "Cancelar desmarca a caça")


## Aceite do M4: sem comida guardada e sem frutas silvestres, 3 colonos com cozinha, fogueira,
## caça automática e uma plantação vivem 4 dias sem nenhuma ordem nova. A comida que comeram
## veio de caça, abate, cozinha e colheita.
func test_food_comes_from_hunting_and_cooking() -> void:
	var simulation := Simulation.new(_SEED, 3)
	var state := simulation.state
	SimHelpers.remove_wild_and_stored_food(simulation)
	var origin := SimHelpers.clear_area(simulation, Vector2i(5, 3))
	var kitchen := SimHelpers.build_now(simulation, &"cooking_bench", origin + Vector2i(1, 0))
	var campfire := SimHelpers.build_now(simulation, &"campfire", origin + Vector2i(2, 2))
	simulation.add_bill(kitchen.id, &"butcher_small")
	simulation.add_bill(kitchen.id, &"butcher_large")
	simulation.add_bill(campfire.id, &"simple_meal")
	simulation.add_bill(kitchen.id, &"simple_meal")
	simulation.set_auto_hunt(&"hare", true)
	simulation.set_auto_hunt(&"deer", true)
	var field := SimHelpers.clear_area(simulation, Vector2i(4, 4))
	simulation.designate(Designations.Tool.GROW_ZONE, Rect2i(field, Vector2i(4, 4)))

	var lowest_food := Balance.NEED_MAX
	var meals_eaten := 0
	var days := 4
	for _i in days * Balance.TICKS_PER_DAY:
		simulation.step()
		for colonist in state.colonists:
			lowest_food = minf(lowest_food, colonist.needs.food)
			var action := colonist.action
			if action and action.kind == Action.Kind.EAT and action.item_id == &"simple_meal" \
					and action.phase == 1 and action.progress_ticks == 1:
				meals_eaten += 1
	print("      aceite M4: %d dias, fome mínima %.0f%%, refeições comidas %d, carne %d, carcaças %d, crops %d" % [
		days, lowest_food, meals_eaten, state.total_count(&"raw_meat"),
		state.total_count(&"small_game_carcass") + state.total_count(&"large_game_carcass"), state.crops.size()])
	expect(lowest_food > 0.0, "Ninguém chega a 0%% de fome (mínima %.0f%%)" % lowest_food)
	expect(meals_eaten >= days * 3, "Comem refeições cozidas (%d)" % meals_eaten)
	expect(state.total_count(&"hide") > 0, "Houve abate na cozinha (pele produzida)")
	expect(state.crops.size() > 0, "A plantação foi semeada sem ordem nova")


func _species_counts(state: WorldState) -> Dictionary:
	var counts := {}
	for animal in state.animals.values():
		counts[animal.def.id] = counts.get(animal.def.id, 0) + 1
	return counts


func _nearest_animal(state: WorldState, species: StringName, from: Vector2i = Vector2i(-1, -1)) -> Animal:
	var anchor := state.colonists[0].cell if from == Vector2i(-1, -1) else from
	var best: Animal
	for animal in state.animals.values():
		if animal.def.id != species:
			continue
		if best == null or animal.cell.distance_squared_to(anchor) < best.cell.distance_squared_to(anchor):
			best = animal
	return best
