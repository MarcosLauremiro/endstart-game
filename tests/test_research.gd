class_name TestResearch
extends TestCase
## Pesquisa e ruína (M6): pontos de Prática e Vestígio, ramos revelados por gatilhos, as 6 pesquisas
## do MVP liberadas na Mesa de estudos, travas de construção e receita, a ruína com 3 salas e o
## artefato. Aceite: explorar a ruína libera uma pesquisa.

const _SEED := 12345


func test_map_has_a_reachable_ruin_with_three_rooms() -> void:
	var simulation := Simulation.new(_SEED, 1)
	var state := simulation.state
	expect_equal(state.ruins.size(), 1, "Uma ruína no mapa")
	var ruin := state.ruins[0]
	expect_equal(ruin.rooms.size(), 3, "Com 3 salas")
	expect_equal(ruin.rooms.filter(func(room: Dictionary) -> bool: return room["artifact"]).size(), 1, "E 1 artefato")
	expect(not state.navigation.is_walkable(ruin.origin), "As paredes antigas bloqueiam")
	for room in ruin.rooms:
		expect(state.navigation.can_reach(state.colonists[0].cell, room["center"]), "Dá para chegar na %s" % room["name"])
	var distance := Vector2(ruin.origin + RuinBuilder.SIZE / 2).distance_to(Vector2(state.world.size / 2))
	expect(distance >= Balance.RUIN_MIN_DISTANCE - RuinBuilder.SIZE.x, "Longe da chegada (%.0f tiles)" % distance)


func test_mvp_research_tree() -> void:
	var research := Research.new()
	expect_equal(Defs.researches().size(), 6, "As 6 pesquisas do MVP")
	expect(research.is_branch_revealed(&"survival") and research.is_branch_revealed(&"agriculture") \
		and research.is_branch_revealed(&"construction"), "Sobrevivência, Agricultura e Construção desde o início")
	expect(not research.is_branch_revealed(&"defense"), "Defesa e armas escondido até a primeira caça")
	expect(not research.is_branch_revealed(&"rediscovery"), "Redescoberta escondida até achar um artefato")
	var tools := Defs.research(&"stone_tools")
	expect_equal(research.unlock_problem(tools, false), "construa uma Mesa de estudos", "Sem mesa não libera")
	expect_equal(research.unlock_problem(tools, true), "faltam 15 P", "Sem pontos não libera")


func test_work_and_first_times_give_practice() -> void:
	var research := Research.new()
	var colonist := Colonist.new()
	colonist.id = 1
	for _t in Balance.PRACTICE_POINT_WORK_TICKS:
		research.work_tick(colonist)
	expect_equal(research.points[Research.Points.PRACTICE], 1.0, "3 h de trabalho: 1 P")
	expect(research.record_first("construção:wall_wood"), "Primeira parede conta")
	expect(not research.record_first("construção:wall_wood"), "A segunda não")
	expect_equal(research.points[Research.Points.PRACTICE], 4.0, "Primeira vez: +3 P")
	var curious := Colonist.new()
	curious.id = 2
	curious.traits = [Traits.CURIOUS]
	expect_equal(research.add_points(Research.Points.RELIC, 2.0, curious), 2.5, "Curioso: +25% nos pontos")


func test_research_locks_structures_and_recipes() -> void:
	var simulation := Simulation.new(_SEED, 1)
	var state := simulation.state
	var desk_origin := SimHelpers.clear_area(simulation, Vector2i(2, 2))
	expect_equal(simulation.placement_problem(Defs.structure(&"study_desk"), desk_origin), "", "Mesa de estudos desde o início")
	var site := Construction.place(state, Defs.structure(&"study_desk"), desk_origin)
	TaskEffects.complete(state.task_board.construction_for_site(site.id), state)
	var origin := SimHelpers.clear_area(simulation, Vector2i(3, 1))
	expect_equal(simulation.placement_problem(Defs.structure(&"cooking_bench"), origin),
		"precisa da pesquisa Bancada de cozinha", "Cozinha travada até a pesquisa")
	expect_equal(simulation.placement_problem(Defs.structure(&"ruin_wall"), origin), "não se constrói", "Parede antiga não se constrói")
	expect(state.has_study_desk(), "Mesa de estudos pronta")
	state.research.points[Research.Points.PRACTICE] = 20.0
	var message := simulation.unlock_research(&"cooking_bench")
	expect_equal(message, "Pesquisa liberada: Bancada de cozinha (bancada de cozinha e abate de animais)", "Libera na hora")
	expect_equal(state.research.points[Research.Points.PRACTICE], 0.0, "Gasta os 20 P")
	expect_equal(simulation.placement_problem(Defs.structure(&"cooking_bench"), origin), "", "Agora a cozinha pode ser construída")
	var bench := Construction.place(state, Defs.structure(&"crafting_bench"), origin + Vector2i(0, -3))
	if bench:
		TaskEffects.complete(state.task_board.construction_for_site(bench.id), state)
		var structure: Structure = state.buildings_by_cell.get(origin + Vector2i(0, -3))
		expect(simulation.add_bill(structure.id, &"bow") == null, "Arco travado até Armas primitivas")


func test_first_hunt_reveals_defense() -> void:
	var simulation := Simulation.new(_SEED, 1)
	var state := simulation.state
	var hare: Animal
	for animal in state.animals.values():
		if animal.def.id == &"hare":
			hare = animal
	Wildlife.kill(state, hare, true)
	expect(state.research.is_branch_revealed(&"defense"), "A primeira caça revela Defesa e armas")
	expect(state.research.firsts.has("caça:hare"), "e conta como primeira vez")


func test_curious_prefers_artifact_tasks() -> void:
	var simulation := Simulation.new(_SEED, 1)
	var state := simulation.state
	var ruin := state.ruins[0]
	simulation.investigate_ruin(ruin)
	var task := state.task_board.investigation_for(ruin.rooms[0]["id"])
	var curious := state.colonists[0]
	curious.traits = [Traits.CURIOUS]
	expect_equal(TaskSelector.traits_factor(curious, task), Balance.CURIOUS_ARTIFACT_SCORE, "Curioso ×1,3 ao investigar")
	curious.traits.clear()
	expect_equal(TaskSelector.traits_factor(curious, task), 1.0, "Sem o traço, neutro")


## Aceite do M6: um colono investiga as 3 salas sozinho depois de uma ordem. A última guarda o
## artefato, que revela o ramo Redescoberta e dá Vestígio suficiente para liberar a Mesa de análise.
func test_exploring_the_ruin_unlocks_a_research() -> void:
	var simulation := Simulation.new(_SEED, 1)
	var state := simulation.state
	var colonist := state.colonists[0]
	colonist.traits.clear()
	simulation.set_work_priority(colonist.id, WorkType.Id.RESEARCH, 1)
	var ruin := state.ruins[0]
	expect_equal(simulation.investigate_ruin(ruin), "Ruína: 3 salas para investigar (Pesquisar)", "Ordem de investigar")
	var explored := SimHelpers.run_until(simulation, func() -> bool: return ruin.is_explored(), 3 * Balance.TICKS_PER_DAY)
	expect(explored, "As 3 salas são investigadas (%d de 3)" % ruin.investigated_count())
	expect_equal(state.total_count(&"artifact"), 1, "O artefato aparece")
	expect_equal(state.total_count(&"scrap"), 2 * Balance.RUIN_ROOM_SCRAP, "As outras salas guardavam sucata")
	expect(state.research.is_branch_revealed(&"rediscovery"), "Achar o artefato revela Redescoberta")
	expect(state.research.points[Research.Points.RELIC] >= 3 * Balance.RUIN_ROOM_RELIC + Balance.ARTIFACT_FOUND_RELIC,
		"Vestígio: 2 por sala + 15 do artefato")
	var analysis := Defs.research(&"analysis_table")
	expect_equal(state.research.unlock_problem(analysis, true), "", "Com uma Mesa de estudos, a Mesa de análise já pode ser liberada")
	var desk_origin := SimHelpers.clear_area(simulation, Vector2i(2, 2))
	var site := Construction.place(state, Defs.structure(&"study_desk"), desk_origin)
	TaskEffects.complete(state.task_board.construction_for_site(site.id), state)
	simulation.unlock_research(&"analysis_table")
	expect(state.research.is_unlocked(&"analysis_table"), "Explorar a ruína liberou uma pesquisa")


func test_analyzing_the_artifact_gives_relic_points() -> void:
	var simulation := Simulation.new(_SEED, 1)
	var state := simulation.state
	var origin := SimHelpers.clear_area(simulation, Vector2i(4, 3))
	var table := SimHelpers.build_now(simulation, &"analysis_table", origin + Vector2i(1, 1))
	SimHelpers.stock(simulation, origin + Vector2i(0, 3), &"artifact", 1)
	simulation.set_work_priority(state.colonists[0].id, WorkType.Id.RESEARCH, 1)
	var before: float = state.research.points[Research.Points.RELIC]
	var bill := simulation.add_bill(table.id, &"analyze_artifact")
	var done := SimHelpers.run_until(simulation, func() -> bool: return bill.done >= 1, 12000)
	expect(done, "O artefato é analisado na Mesa de análise")
	expect_equal(state.research.points[Research.Points.RELIC], before + 10.0, "Analisar rende 10 V")
	expect_equal(state.total_count(&"artifact_studied"), 1, "Vira artefato estudado (não se analisa de novo)")
