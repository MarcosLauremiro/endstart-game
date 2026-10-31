class_name TestProduction
extends TestCase
## Produção (M4): bancadas, fila de pedidos com "fazer até X", "fazer N" e pausa, ingredientes
## entregues de verdade (nada some ao apagar o pedido ou desmontar a bancada), abate e a escolha
## da melhor comida.

const _SEED := 12345


func test_campfire_cooks_until_the_target() -> void:
	var simulation := Simulation.new(_SEED, 1)
	var state := simulation.state
	SimHelpers.remove_wild_and_stored_food(simulation)
	var origin := SimHelpers.clear_area(simulation, Vector2i(3, 3))
	var campfire := SimHelpers.build_now(simulation, &"campfire", origin + Vector2i(1, 1))
	SimHelpers.stock(simulation, origin + Vector2i(0, 3), &"berries", 10)
	var bill := simulation.add_bill(campfire.id, &"simple_meal")
	simulation.set_bill_mode(bill, Bill.Mode.UNTIL, 3)
	var done := SimHelpers.run_until(simulation, func() -> bool: return state.total_count(&"simple_meal") >= 3, 12000)
	expect(done, "A fogueira faz refeições até ter 3 (tem %d)" % state.total_count(&"simple_meal"))
	expect_equal(state.total_count(&"berries"), 10 - 3 * 2, "Cada refeição gasta exatamente 2 porções cruas")
	SimHelpers.run_until(simulation, func() -> bool: return false, 3000)
	expect_equal(state.total_count(&"simple_meal"), 3, "Com a meta atingida, a fogueira para")
	expect_equal(bill.condition_problem(state), "já há 3 de 3 refeição simples", "O pedido explica por que parou")


func test_count_mode_and_pause() -> void:
	var simulation := Simulation.new(_SEED, 1)
	var state := simulation.state
	var origin := SimHelpers.clear_area(simulation, Vector2i(5, 3))
	var bench := SimHelpers.build_now(simulation, &"crafting_bench", origin + Vector2i(1, 1))
	SimHelpers.stock(simulation, origin + Vector2i(0, 3), &"stone_raw", 20)
	var bill := simulation.add_bill(bench.id, &"stone_blocks")
	simulation.set_bill_mode(bill, Bill.Mode.COUNT, 2)
	simulation.set_bill_paused(bill, true)
	SimHelpers.run_until(simulation, func() -> bool: return false, 2000)
	expect_equal(state.total_count(&"stone_block"), 0, "Pedido pausado não é feito")
	var task := state.task_board.craft_for_bench(bench.id)
	expect(simulation.explain_task(state.colonists[0], task).contains("pausado"), "O motivo da espera é a pausa")
	simulation.set_bill_paused(bill, false)
	var done := SimHelpers.run_until(simulation, func() -> bool: return bill.done >= 2, 20000)
	expect(done, "Faz o pedido 2 vezes")
	SimHelpers.run_until(simulation, func() -> bool: return false, 4000)
	expect_equal(state.total_count(&"stone_block"), 8, "2 vezes × 4 blocos, e para")
	expect_equal(state.total_count(&"stone_raw"), 12, "Gasta exatamente 8 de pedra bruta")


func test_bill_with_two_ingredients_from_two_places() -> void:
	var simulation := Simulation.new(_SEED, 1)
	var state := simulation.state
	var origin := SimHelpers.clear_area(simulation, Vector2i(5, 3))
	var bench := SimHelpers.build_now(simulation, &"crafting_bench", origin + Vector2i(1, 1))
	state.drop_items(origin + Vector2i(4, 3), &"fiber", 2)
	var wood_before := state.total_count(&"wood")
	var bill := simulation.add_bill(bench.id, &"bow")
	simulation.set_bill_mode(bill, Bill.Mode.COUNT, 1)
	var done := SimHelpers.run_until(simulation, func() -> bool: return state.total_count(&"bow") >= 1, 20000)
	expect(done, "O arco fica pronto com madeira do caixote e fibra do chão")
	expect_equal(state.total_count(&"wood"), wood_before - 3, "Arco gasta 3 de madeira")
	expect_equal(state.total_count(&"fiber"), 0, "Arco gasta 2 de fibra")


func test_missing_ingredient_is_explained() -> void:
	var simulation := Simulation.new(_SEED, 1)
	var state := simulation.state
	var origin := SimHelpers.clear_area(simulation, Vector2i(5, 3))
	var bench := SimHelpers.build_now(simulation, &"crafting_bench", origin + Vector2i(1, 1))
	simulation.add_bill(bench.id, &"stone_blocks")
	var task := state.task_board.craft_for_bench(bench.id)
	var why := simulation.explain_task(state.colonists[0], task)
	expect(why.contains("faltam 4 pedra bruta"), "Sem pedra, o motivo diz o que falta (obtido: %s)" % why)
	var empty := SimHelpers.build_now(simulation, &"campfire", origin + Vector2i(0, 3))
	var idle := simulation.explain_task(state.colonists[0], state.task_board.craft_for_bench(empty.id))
	expect_equal(idle, "sem pedidos na fila", "Bancada sem pedidos explica a espera")


func test_removing_a_bill_returns_the_staged_ingredients() -> void:
	var simulation := Simulation.new(_SEED, 1)
	var state := simulation.state
	var origin := SimHelpers.clear_area(simulation, Vector2i(5, 3))
	var bench_structure := SimHelpers.build_now(simulation, &"crafting_bench", origin + Vector2i(1, 1))
	var bench: Workbench = state.workbenches[bench_structure.id]
	state.drop_items(origin + Vector2i(4, 3), &"fiber", 2)
	var wood_before := state.total_count(&"wood")
	var bill := simulation.add_bill(bench.id, &"bow")
	var staged := SimHelpers.run_until(simulation, func() -> bool:
		return bench.job != null and not bench.staged_text().begins_with("0/3"), 8000)
	expect(staged, "Algum ingrediente chega à bancada")
	simulation.remove_bill(bench.id, bill)
	SimHelpers.run_until(simulation, func() -> bool: return state.colonists[0].action == null or state.colonists[0].carrying_count == 0, 2000)
	expect(bench.job == null, "Sem pedido em andamento")
	expect_equal(state.total_count(&"wood"), wood_before, "A madeira separada volta (nada some)")
	expect_equal(state.total_count(&"fiber"), 2, "A fibra separada volta (nada some)")


func test_deconstructing_a_bench_returns_staged_ingredients() -> void:
	var simulation := Simulation.new(_SEED, 1)
	var state := simulation.state
	var origin := SimHelpers.clear_area(simulation, Vector2i(5, 3))
	var bench_structure := SimHelpers.build_now(simulation, &"crafting_bench", origin + Vector2i(1, 1))
	var bench: Workbench = state.workbenches[bench_structure.id]
	var stone_before := state.total_count(&"stone_raw")
	SimHelpers.stock(simulation, origin + Vector2i(0, 3), &"stone_raw", 4)
	simulation.add_bill(bench.id, &"stone_blocks")
	SimHelpers.run_until(simulation, func() -> bool: return bench.has_all_ingredients(), 8000)
	expect(bench.has_all_ingredients(), "A pedra chega à bancada")
	Construction.deconstruct(state, bench.id)
	expect(not state.workbenches.has(bench.id), "A bancada some")
	expect(state.task_board.craft_for_bench(bench.id) == null, "A tarefa da bancada sai do quadro")
	var refund := floori(Defs.structure(&"crafting_bench").costs[&"stone_raw"] * Balance.DECONSTRUCT_REFUND)
	expect_equal(state.total_count(&"stone_raw"), stone_before + 4 + refund, "A pedra separada volta ao chão (mais o reembolso da bancada)")


func test_kitchen_butchers_a_carcass() -> void:
	var simulation := Simulation.new(_SEED, 1)
	var state := simulation.state
	var origin := SimHelpers.clear_area(simulation, Vector2i(5, 3))
	var kitchen := SimHelpers.build_now(simulation, &"cooking_bench", origin + Vector2i(1, 1))
	SimHelpers.stock(simulation, origin + Vector2i(0, 3), &"small_game_carcass", 1)
	var bill := simulation.add_bill(kitchen.id, &"butcher_small")
	var done := SimHelpers.run_until(simulation, func() -> bool: return bill.done >= 1, 8000)
	expect(done, "A cozinha abate a lebre")
	expect_equal(state.total_count(&"small_game_carcass"), 0, "A carcaça é usada")
	expect_equal(state.total_count(&"raw_meat"), 6, "Animal pequeno rende 6 de carne (GDD)")
	expect_equal(state.total_count(&"hide"), 1, "e 1 pele")


func test_campfire_cannot_butcher() -> void:
	var simulation := Simulation.new(_SEED, 1)
	var origin := SimHelpers.clear_area(simulation, Vector2i(2, 2))
	var campfire := SimHelpers.build_now(simulation, &"campfire", origin)
	var recipes := Defs.recipes_for(&"campfire").map(func(r: RecipeDef) -> StringName: return r.id)
	expect_equal(recipes, [&"simple_meal"], "A fogueira só faz refeição simples")
	expect(simulation.add_bill(campfire.id, &"butcher_small") == null, "Abater é só na cozinha (GDD)")


func test_cooking_uses_cook_priority() -> void:
	var simulation := Simulation.new(_SEED, 1)
	var state := simulation.state
	var origin := SimHelpers.clear_area(simulation, Vector2i(3, 3))
	var campfire := SimHelpers.build_now(simulation, &"campfire", origin + Vector2i(1, 1))
	SimHelpers.stock(simulation, origin + Vector2i(0, 3), &"berries", 4)
	simulation.add_bill(campfire.id, &"simple_meal")
	var task := state.task_board.craft_for_bench(campfire.id)
	expect_equal(task.work_type, WorkType.Id.COOK, "Fogueira é trabalho de Cozinhar")
	simulation.set_work_priority(state.colonists[0].id, WorkType.Id.COOK, 0)
	expect_equal(simulation.explain_task(state.colonists[0], task), "prioridade de Cozinhar desligada", "Sem Cozinhar, não cozinha")


func test_prefers_a_meal_over_nearer_berries() -> void:
	var simulation := Simulation.new(_SEED, 1)
	var state := simulation.state
	SimHelpers.remove_wild_and_stored_food(simulation)
	var colonist := state.colonists[0]
	var origin := SimHelpers.clear_area(simulation, Vector2i(6, 2))
	state.drop_items(origin + Vector2i(1, 0), &"berries", 5)
	SimHelpers.stock(simulation, origin + Vector2i(5, 1), &"simple_meal", 2)
	colonist.cell = origin
	colonist.needs.food = 10.0
	SimHelpers.run_until(simulation, func() -> bool: return colonist.action and colonist.action.kind == Action.Kind.EAT, 200)
	expect(colonist.action != null and colonist.action.item_id == &"simple_meal", "Prefere a refeição cozida (nutrição 50) às frutas ao lado")
	expect(colonist.action != null and colonist.action.reason.contains("pontuação"), "O motivo mostra a pontuação da comida")


func test_tile_panel_describes_bench_and_animals() -> void:
	var simulation := Simulation.new(_SEED, 1)
	var state := simulation.state
	var origin := SimHelpers.clear_area(simulation, Vector2i(5, 3))
	var kitchen := SimHelpers.build_now(simulation, &"cooking_bench", origin + Vector2i(1, 1))
	simulation.add_bill(kitchen.id, &"simple_meal")
	var text := "\n".join(TileInfo.describe(simulation, origin + Vector2i(2, 1)))
	expect(text.contains("Bancada: 1 pedidos na fila"), "O tile da bancada mostra a fila")
	var hare: Animal
	for animal in state.animals.values():
		if animal.def.id == &"hare":
			hare = animal
			break
	simulation.designate(Designations.Tool.HUNT, Rect2i(hare.cell, Vector2i.ONE))
	var animal_text := "\n".join(TileInfo.describe(simulation, hare.cell))
	expect(animal_text.contains("Lebre") and animal_text.contains("marcado para caça"), "O tile do animal mostra espécie e caça")
	expect(simulation.task_at(hare.cell) != null, "A tarefa de caça é achada pelo tile do animal")
