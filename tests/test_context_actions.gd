class_name TestContextActions
extends TestCase
## Opções do que foi clicado: árvore (cortar e cancelar), construção (desmontar), animal (caçar;
## predador não), plantação (trocar o cultivo, remover), chão livre (criar plantação), colono
## (comer, dormir, cancelar ordem). E os três cultivos com suas fases de arte.

const _SEED := 12345


func test_tree_offers_cut_then_cancel() -> void:
	var simulation := Simulation.new(_SEED, 1)
	var tree: WildTree = simulation.state.trees.values()[0]
	var options := ContextActions.for_cell(simulation, tree.cell)
	expect_equal(_labels(options), ["Cortar"], "Árvore: cortar")
	_run(options, "Cortar")
	var task := simulation.state.task_board.designation_at(tree.cell)
	expect(task != null and task.kind == Task.Kind.CUT, "Cortar cria a tarefa de corte")
	options = ContextActions.for_cell(simulation, tree.cell)
	expect_equal(_labels(options), ["Cancelar corte"], "Marcada, a opção vira cancelar")
	_run(options, "Cancelar corte")
	expect(simulation.state.task_board.designation_at(tree.cell) == null, "Cancelar tira a tarefa")


func test_bed_offers_deconstruct() -> void:
	var simulation := Simulation.new(_SEED, 1)
	var origin := SimHelpers.clear_area(simulation, Vector2i(1, 2))
	var bed := SimHelpers.build_now(simulation, &"bed_rustic", origin)
	var options := ContextActions.for_cell(simulation, origin + Vector2i(0, 1))
	expect_equal(_labels(options), ["Desmontar: Cama rústica"], "Cama: desmontar (clicando em qualquer tile dela)")
	_run(options, "Desmontar: Cama rústica")
	expect(simulation.state.task_board.deconstruction_for(bed.id) != null, "Desmontar cria a tarefa")
	expect_equal(_labels(ContextActions.for_cell(simulation, origin)), ["Cancelar desmontagem"], "Depois, cancelar")


func test_site_offers_cancel_with_refund() -> void:
	var simulation := Simulation.new(_SEED, 1)
	var state := simulation.state
	var origin := SimHelpers.clear_area(simulation, Vector2i(1, 1))
	var site := Construction.place(state, Defs.structure(&"wall_wood"), origin)
	site.delivered[&"wood"] = 3
	var wood_before := state.total_count(&"wood")
	_run(ContextActions.for_cell(simulation, origin), "Cancelar obra: Parede de madeira")
	expect(state.sites.is_empty(), "A obra sai")
	expect_equal(state.total_count(&"wood"), wood_before + 3, "O material entregue volta")


func test_animals_offer_hunt_but_not_predators() -> void:
	var simulation := Simulation.new(_SEED, 1)
	var state := simulation.state
	for animal in state.animals.values():
		var options := ContextActions.for_cell(simulation, animal.cell)
		var mine := options.filter(func(o: Dictionary) -> bool: return o["label"].ends_with(animal.def.display_name))
		expect(not mine.is_empty(), "%s tem opção de caça" % animal.def.display_name)
		if mine.is_empty():
			continue
		expect_equal(mine[0]["enabled"], not animal.def.is_predator, "%s: caçar só se não for predador" % animal.def.display_name)
	var hare: Animal
	for animal in state.animals.values():
		if animal.def.id == &"hare":
			hare = animal
	_run(ContextActions.for_cell(simulation, hare.cell), "Caçar: Lebre")
	expect(state.task_board.hunt_for(hare.id) != null, "Caçar marca a lebre")


func test_zone_offers_crops_and_removal() -> void:
	var simulation := Simulation.new(_SEED, 1)
	var state := simulation.state
	var origin := SimHelpers.clear_area(simulation, Vector2i(1, 1))
	_run(ContextActions.for_cell(simulation, origin), "Criar plantação aqui")
	var zone: GrowZone = state.zone_by_cell.get(origin)
	expect(zone != null and zone.crop.id == &"carrot", "Plantação nova planta cenoura")
	var options := ContextActions.for_cell(simulation, origin)
	expect_equal(_labels(options), ["Plantar cenoura", "Plantar cogumelo", "Plantar trigo", "Remover plantação"], "Opções da plantação")
	expect_equal(options[0]["enabled"], false, "O cultivo atual fica desligado")
	_run(options, "Plantar trigo")
	expect_equal(zone.crop.id, &"wheat", "Agora planta trigo")
	var sow := state.task_board.designation_at(origin)
	expect(sow != null and sow.title.contains("trigo"), "A tarefa de semear é refeita com o trigo")
	_run(ContextActions.for_cell(simulation, origin), "Remover plantação")
	expect(not state.zone_by_cell.has(origin), "Remover tira o tile da plantação")


func test_colonist_orders() -> void:
	var simulation := Simulation.new(_SEED, 1)
	var colonist := simulation.state.colonists[0]
	var options := ContextActions.for_colonist(simulation, colonist)
	expect_equal(_labels(options), ["Comer agora", "Dormir agora"], "Opções do colono")
	expect(not options[0]["enabled"] and not options[1]["enabled"], "Satisfeito e descansado: as duas desligadas")
	colonist.needs.rest = 50.0
	_run(ContextActions.for_colonist(simulation, colonist), "Dormir agora")
	SimHelpers.run_until(simulation, func() -> bool: return colonist.is_sleeping(), 2000)
	expect(colonist.is_sleeping(), "Com a ordem, ele dorme")
	expect_equal(colonist.action.layer, Action.Layer.ORDER, "É uma ordem direta")
	_run(ContextActions.for_colonist(simulation, colonist), "Cancelar ordem")
	expect(colonist.direct_order == null and not colonist.is_sleeping(), "Cancelar a ordem acorda e esquece")
	colonist.needs.food = 50.0
	_run(ContextActions.for_colonist(simulation, colonist), "Comer agora")
	SimHelpers.run_until(simulation, func() -> bool: return colonist.needs.food >= Balance.EAT_UNTIL, 4000)
	expect(colonist.needs.food >= Balance.EAT_UNTIL, "Com a ordem, ele come")


func test_crop_stages_follow_each_sheet() -> void:
	for crop_id in [&"carrot", &"wheat", &"mushroom"]:
		var def := Defs.crop(crop_id)
		expect_equal(def.stages, AssetCatalog.frame_grid(def.asset).x, "%s: uma coluna da arte por fase" % def.display_name)
		var crop := Crop.new(1, def, Vector2i.ZERO)
		expect_equal(crop.stage(), 0, "%s recém-semeado: primeira fase" % def.display_name)
		crop.growth_hours = def.grow_hours() - 0.5
		expect_equal(crop.stage(), def.stages - 2, "%s quase pronto: penúltima fase" % def.display_name)
		crop.growth_hours = def.grow_hours()
		expect_equal(crop.stage(), def.stages - 1, "%s maduro: última fase" % def.display_name)
		expect(Defs.item(def.product).has_tag(&"raw_food"), "%s serve de porção crua para refeições" % def.display_name)


func _labels(options: Array[Dictionary]) -> Array:
	return options.map(func(o: Dictionary) -> String: return o["label"])


func _run(options: Array[Dictionary], label: String) -> void:
	for option in options:
		if option["label"] == label:
			option["run"].call()
			return
	failures.append("Opção ausente: %s (havia %s)" % [label, _labels(options)])
