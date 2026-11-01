class_name TestColonists
extends TestCase
## Colonos completos (M5): gerador, habilidades e XP, afinidades, humor, agenda, traços,
## equipamento e carga. Aceite: dois colonos com traços diferentes se comportam de forma
## visivelmente diferente.

const _SEED := 12345


func test_generator_follows_the_gdd_rules() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 99
	var taken: Array[String] = []
	for i in 200:
		var colonist := ColonistFactory.create(i + 1, Vector2i.ZERO, rng, taken)
		expect(colonist.age >= Balance.COLONIST_MIN_AGE and colonist.age <= Balance.COLONIST_MAX_AGE, "Idade de 16 a 70")
		expect(colonist.traits.size() >= 1 and colonist.traits.size() <= 3, "De 1 a 3 traços")
		expect(not (colonist.has_trait(Traits.HARDWORKING) and colonist.has_trait(Traits.LAZY)), "Esforçado e Preguiçoso não juntos")
		expect(not (colonist.has_trait(Traits.OPTIMIST) and colonist.has_trait(Traits.PESSIMIST)), "Otimista e Pessimista não juntos")
		var total := 0
		var positives := 0
		var aversions := 0
		for skill_id in Skills.ALL:
			var state: SkillState = colonist.skills[skill_id]
			total += state.level
			if state.affinity == Skills.Affinity.INTEREST or state.affinity == Skills.Affinity.PASSION:
				positives += 1
			elif state.affinity == Skills.Affinity.AVERSION:
				aversions += 1
		expect(total <= Balance.SKILL_SUM_CAP, "Soma das habilidades até 70")
		expect(positives >= 1 and positives <= 3, "De 1 a 3 interesses ou paixões")
		expect(aversions <= 2, "No máximo 2 aversões")
		expect_equal(colonist.equipment.in_slot(Equipment.Slot.SHIRT), &"tunic", "Começa de túnica")
		expect_equal(colonist.equipment.in_slot(Equipment.Slot.PANTS), &"trousers", "e calça")
		if not failures.is_empty():
			return
	var again := RandomNumberGenerator.new()
	again.seed = 99
	var first := ColonistFactory.create(1, Vector2i.ZERO, again, taken)
	rng.seed = 99
	var second := ColonistFactory.create(1, Vector2i.ZERO, rng, taken)
	expect_equal(first.traits, second.traits, "Mesma seed, mesmo colono")


func test_skill_curve_and_xp_table() -> void:
	expect(is_equal_approx(Skills.speed_at(0), 0.4), "Nível 0: 40%")
	expect(is_equal_approx(Skills.speed_at(3), 0.7), "Nível 3: 70%")
	expect(is_equal_approx(Skills.speed_at(7), 1.0), "Nível 7: 100%")
	expect(is_equal_approx(Skills.speed_at(20), 1.8), "Lenda: 180%")
	expect_equal(Skills.xp_to_next(0), 1000.0, "Do 0 para o 1: 1.000 XP")
	expect_equal(Skills.xp_to_next(10), 8500.0, "Do 10 para o 11: 8.500 XP")
	expect_equal(Skills.for_work(WorkType.Id.HAUL), -1, "Carregar não usa habilidade")


func test_work_teaches_and_interest_feels_good() -> void:
	var colonist := _plain_colonist()
	colonist.skills[Skills.Id.MINING].affinity = Skills.Affinity.INTEREST
	var hours := 7
	var raised := -1
	for _t in hours * Balance.TICKS_PER_HOUR:
		var result := colonist.learn(WorkType.Id.MINE, 1)
		if result >= 0:
			raised = result
	expect_equal(colonist.skills[Skills.Id.MINING].level, 1, "~7 h com interesse sobem do 0 para o 1 (GDD)")
	expect_equal(raised, Skills.Id.MINING, "learn avisa a subida")
	colonist.mood.refresh(colonist, 0)
	expect(_has_thought(colonist, "Trabalhou no que gosta", 6), "Interesse: +1 por hora, até +6")
	var averse := _plain_colonist()
	averse.skills[Skills.Id.MINING].affinity = Skills.Affinity.AVERSION
	averse.learn(WorkType.Id.MINE, hours * Balance.TICKS_PER_HOUR)
	expect(averse.skills[Skills.Id.MINING].xp < 1000.0 * 0.25, "Aversão aprende ×0,2")
	averse.mood.refresh(averse, 0)
	expect(_has_thought(averse, "Trabalhou no que detesta", -10), "Aversão pesa no humor")


func test_daily_cap_and_forgetting() -> void:
	var state := SkillState.new(13)
	state.add_xp(5000.0)
	var before := state.xp
	state.add_xp(100.0)
	expect(is_equal_approx(state.xp - before, 20.0), "Acima de 4.000 XP no dia, ganho ×0,2")
	state.end_day()
	var unpracticed := SkillState.new(13)
	unpracticed.xp = 100.0
	unpracticed.end_day()
	expect(is_equal_approx(unpracticed.xp, 60.0), "Nível 13 sem prática perde 40 XP por dia")
	var low := SkillState.new(5)
	low.xp = 100.0
	low.end_day()
	expect_equal(low.xp, 100.0, "Até o nível 12 não esquece")


func test_skill_level_changes_work_speed() -> void:
	var novice := _plain_colonist()
	var expert := _plain_colonist()
	expert.skills[Skills.Id.MINING].level = 15
	expect(is_equal_approx(novice.work_speed(WorkType.Id.MINE), 0.4), "Iniciante minera a 40%")
	expect(is_equal_approx(expert.work_speed(WorkType.Id.MINE), 1.5), "Especialista nível 15 minera a 150%")
	expect(is_equal_approx(novice.work_speed(WorkType.Id.HAUL), 1.0), "Carregar não depende de habilidade")


func test_mood_moves_toward_thoughts() -> void:
	var optimist := _plain_colonist()
	optimist.traits = [Traits.OPTIMIST]
	var pessimist := _plain_colonist()
	pessimist.traits = [Traits.PESSIMIST]
	pessimist.needs.food = 20.0
	optimist.mood.refresh(optimist, 0)
	pessimist.mood.refresh(pessimist, 0)
	expect_equal(optimist.mood.target(), 56.0, "Otimista: 50 + 6")
	expect_equal(pessimist.mood.target(), 38.0, "Pessimista com fome: 50 - 6 - 6")
	for _t in Balance.TICKS_PER_DAY / 2:
		optimist.mood.tick()
	expect(is_equal_approx(optimist.mood.value, 56.0), "Anda até 12 por dia: chega em 56 em meio dia")
	expect_equal(optimist.mood.state_name(), "Neutro", "56 é neutro")


func test_sleeping_on_the_ground_is_remembered() -> void:
	var simulation := Simulation.new(_SEED, 1)
	var colonist := simulation.state.colonists[0]
	colonist.needs.rest = 85.0
	simulation.order_sleep(colonist.id)
	SimHelpers.run_until(simulation, func() -> bool: return colonist.is_sleeping(), 600)
	SimHelpers.run_until(simulation, func() -> bool: return colonist.action == null or colonist.action.kind != Action.Kind.SLEEP, 3 * Balance.TICKS_PER_HOUR)
	colonist.mood.refresh(colonist, simulation.clock.tick)
	expect(_has_thought(colonist, "Dormiu no chão", roundi(Balance.SLEPT_ON_GROUND_MOOD)), "Sem cama, lembra de ter dormido no chão")


func test_schedule_sleeps_at_night_and_stops_work() -> void:
	var simulation := Simulation.new(_SEED, 1)
	var state := simulation.state
	var colonist := state.colonists[0]
	colonist.traits.clear()
	var tree := _nearest_tree(state, colonist.cell)
	simulation.designate(Designations.Tool.CUT, Rect2i(tree.cell, Vector2i.ONE))
	SimHelpers.run_until(simulation, func() -> bool: return colonist.action and colonist.action.kind == Action.Kind.WORK, 3000)
	expect(colonist.action != null and colonist.action.kind == Action.Kind.WORK, "De dia, trabalha")
	state.clock.tick = (state.clock.day()) * Balance.TICKS_PER_DAY - (Balance.HOURS_PER_DAY - Balance.SCHEDULE_FREE_START) * Balance.TICKS_PER_HOUR
	colonist.needs.rest = 50.0
	SimHelpers.run_until(simulation, func() -> bool: return colonist.action == null or colonist.action.kind != Action.Kind.WORK, 120)
	expect(colonist.action == null or colonist.action.kind != Action.Kind.WORK, "No bloco Livre, para de trabalhar")
	state.clock.tick = (state.clock.day()) * Balance.TICKS_PER_DAY - (Balance.HOURS_PER_DAY - Balance.SCHEDULE_SLEEP_START) * Balance.TICKS_PER_HOUR
	var slept := SimHelpers.run_until(simulation, func() -> bool: return colonist.is_sleeping(), 1200)
	expect(slept, "No bloco Dormir, com sono abaixo de 90%, dorme")
	expect_equal(colonist.action.layer, Action.Layer.SCHEDULE, "Dormir vem da agenda (camada 4)")


func test_hardworking_finishes_the_task_after_the_work_block() -> void:
	var simulation := Simulation.new(_SEED, 1)
	var state := simulation.state
	var colonist := state.colonists[0]
	colonist.traits = [Traits.HARDWORKING]
	var tree := _nearest_tree(state, colonist.cell)
	simulation.designate(Designations.Tool.CUT, Rect2i(tree.cell, Vector2i.ONE))
	SimHelpers.run_until(simulation, func() -> bool: return colonist.action and colonist.action.kind == Action.Kind.WORK, 3000)
	state.clock.tick = (state.clock.day()) * Balance.TICKS_PER_DAY - (Balance.HOURS_PER_DAY - Balance.SCHEDULE_FREE_START) * Balance.TICKS_PER_HOUR
	SimHelpers.run_until(simulation, func() -> bool: return false, 120)
	expect(colonist.action != null and colonist.action.kind == Action.Kind.WORK, "Esforçado continua a tarefa no bloco Livre")


func test_glutton_gets_hungry_faster() -> void:
	var normal := _plain_colonist()
	var glutton := _plain_colonist()
	glutton.traits = [Traits.GLUTTON]
	for _t in Balance.TICKS_PER_HOUR * 10:
		normal.needs.tick(false, false, normal.hunger_factor())
		glutton.needs.tick(false, false, glutton.hunger_factor())
	var normal_loss := Balance.NEED_MAX - normal.needs.food
	var glutton_loss := Balance.NEED_MAX - glutton.needs.food
	expect(is_equal_approx(glutton_loss, normal_loss * Balance.GLUTTON_HUNGER_FACTOR), "Glutão come 30% a mais")


func test_coward_refuses_work_near_a_predator() -> void:
	var simulation := Simulation.new(_SEED, 2)
	var state := simulation.state
	var coward := state.colonists[0]
	var brave := state.colonists[1]
	coward.traits = [Traits.COWARD]
	brave.traits.clear()
	var tree := _nearest_tree(state, coward.cell)
	simulation.designate(Designations.Tool.CUT, Rect2i(tree.cell, Vector2i.ONE))
	var wolf: Animal
	for animal in state.animals.values():
		if animal.def.is_predator:
			wolf = animal
	wolf.cell = state.nearest_walkable(tree.cell + Vector2i(4, 0))
	var task := state.task_board.designation_at(tree.cell)
	expect(simulation.explain_task(coward, task).begins_with("Covarde: lobo-espinho"), "O covarde recusa e diz por quê")
	expect(simulation.explain_task(brave, task).begins_with("pode fazer"), "O outro faz")


func test_picks_up_a_better_tool_before_cutting() -> void:
	var simulation := Simulation.new(_SEED, 1)
	var state := simulation.state
	var colonist := state.colonists[0]
	var origin := SimHelpers.clear_area(simulation, Vector2i(1, 1))
	SimHelpers.stock(simulation, origin, &"stone_axe", 1)
	var tree := _nearest_tree(state, colonist.cell)
	simulation.designate(Designations.Tool.CUT, Rect2i(tree.cell, Vector2i.ONE))
	var equipped := SimHelpers.run_until(simulation, func() -> bool: return colonist.equipment.hand() == &"stone_axe", 3000)
	expect(equipped, "Pega o machado no baú antes de cortar")
	expect(is_equal_approx(colonist.tool_bonus(WorkType.Id.CUT), 1.25), "Machado: Cortar plantas ×1,25")
	expect_equal(state.total_count(&"stone_axe"), 1, "O machado na mão continua contado (nada some ou duplica)")
	simulation.drop_hand(colonist.id)
	expect_equal(colonist.equipment.hand(), &"", "Largar esvazia a mão")
	expect_equal(state.total_count(&"stone_axe"), 1, "e o machado vai para o chão")


func test_heavy_load_slows_down() -> void:
	var colonist := _plain_colonist()
	colonist.strength = 1
	expect_equal(colonist.load_move_factor(), 1.0, "Leve: sem penalidade")
	colonist.carry(&"large_game_carcass", 1)
	expect_equal(colonist.load_move_factor(), Balance.LOAD_SLOWER_FACTOR, "Carcaça de cervo com Força 1: -50%")


## Aceite do M5: mesmos níveis, agenda e tarefas; só os traços mudam.
## Ana (Esforçada, Otimista) e Bento (Preguiçoso, Pessimista, Glutão) cortam árvores por dois dias.
func test_two_colonists_with_different_traits_behave_differently() -> void:
	var simulation := Simulation.new(_SEED, 2)
	var state := simulation.state
	var eager := state.colonists[0]
	var lazy := state.colonists[1]
	for colonist in [eager, lazy]:
		colonist.strength = Balance.ATTRIBUTE_AVERAGE
		for skill_id in Skills.ALL:
			colonist.skills[skill_id] = SkillState.new(5)
	eager.traits = [Traits.HARDWORKING, Traits.OPTIMIST]
	lazy.traits = [Traits.LAZY, Traits.PESSIMIST, Traits.GLUTTON]
	var trees: Array = state.trees.values().filter(func(tree: WildTree) -> bool: return tree.is_adult())
	trees.sort_custom(func(a: WildTree, b: WildTree) -> bool:
		return a.cell.distance_squared_to(eager.cell) < b.cell.distance_squared_to(eager.cell))
	for tree in trees.slice(0, 40):
		simulation.designate(Designations.Tool.CUT, Rect2i(tree.cell, Vector2i.ONE))
	var work_ticks := {eager.id: 0, lazy.id: 0}
	var breaks := {eager.id: 0, lazy.id: 0}
	var eaten := {eager.id: 0.0, lazy.id: 0.0}
	var days := 2
	for _t in days * Balance.TICKS_PER_DAY:
		var food_before := {eager.id: eager.needs.food, lazy.id: lazy.needs.food}
		simulation.step()
		for colonist in [eager, lazy]:
			eaten[colonist.id] += maxf(colonist.needs.food - food_before[colonist.id], 0.0)
			var action: Action = colonist.action
			if action == null:
				continue
			if action.kind == Action.Kind.WORK and colonist.state == Colonist.State.EXECUTING:
				work_ticks[colonist.id] += 1
			if action.kind == Action.Kind.BREAK and action.progress_ticks == 1:
				breaks[colonist.id] += 1
	print("      aceite M5: trabalho %d × %d ticks, pausas %d × %d, nutrição comida %.0f × %.0f, humor %.0f × %.0f" % [
		work_ticks[eager.id], work_ticks[lazy.id], breaks[eager.id], breaks[lazy.id],
		eaten[eager.id], eaten[lazy.id], eager.mood.value, lazy.mood.value])
	expect(work_ticks[eager.id] > work_ticks[lazy.id], "A Esforçada trabalha mais tempo que o Preguiçoso")
	expect(breaks[lazy.id] >= 2 and breaks[eager.id] == 0, "Só o Preguiçoso faz pausas")
	expect(eaten[lazy.id] > eaten[eager.id] * 1.15, "O Glutão come bem mais")
	expect(eager.mood.value - lazy.mood.value >= 5.0, "A Otimista fica de humor bem melhor")


func _plain_colonist() -> Colonist:
	var colonist := Colonist.new()
	colonist.id = 1
	colonist.age = 30
	return colonist


func _has_thought(colonist: Colonist, label: String, value: int) -> bool:
	for thought in colonist.mood.thoughts:
		if thought["label"] == label and roundi(thought["value"]) == value:
			return true
	return false


func _nearest_tree(state: WorldState, from: Vector2i) -> WildTree:
	var best: WildTree
	for tree in state.trees.values():
		if best == null or tree.cell.distance_squared_to(from) < best.cell.distance_squared_to(from):
			best = tree
	return best
