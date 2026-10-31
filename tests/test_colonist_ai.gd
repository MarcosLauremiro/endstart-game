class_name TestColonistAi
extends TestCase
## Cenários de IA sem interação manual: sobrevivência, interrupção e retomada,
## concorrência por comida, falta de comida, desmaio, ordens impossíveis e reprodutibilidade.

const _SEED := 12345


func test_colonist_survives_three_days_alone() -> void:
	var simulation := Simulation.new(_SEED, 1)
	var colonist := simulation.state.colonists[0]
	var min_food := Balance.NEED_MAX
	var min_rest := Balance.NEED_MAX
	var meals := 0
	var sleeps := 0
	var was_sleeping := false
	var previous_food := colonist.needs.food
	var started := Time.get_ticks_msec()
	for _i in 3 * Balance.TICKS_PER_DAY:
		simulation.step()
		min_food = minf(min_food, colonist.needs.food)
		min_rest = minf(min_rest, colonist.needs.rest)
		if colonist.needs.food > previous_food + 1.0:
			meals += 1
		previous_food = colonist.needs.food
		if colonist.is_sleeping() and not was_sleeping:
			sleeps += 1
		was_sleeping = colonist.is_sleeping()
	print("      3 dias simulados em %d ms; fome mínima %.0f%%, sono mínimo %.0f%%, %d porções, %d sonos" % [
		Time.get_ticks_msec() - started, min_food, min_rest, meals, sleeps])
	expect(min_food > 0.0, "A fome não pode zerar em 3 dias com comida acessível")
	expect(min_rest > 0.0, "O sono não pode zerar em 3 dias")
	expect(meals >= 3, "Deve comer várias vezes em 3 dias (comeu %d porções)" % meals)
	expect(sleeps >= 2, "Deve dormir pelo menos 2 vezes em 3 dias (dormiu %d)" % sleeps)


func test_critical_hunger_interrupts_order_then_order_resumes() -> void:
	var simulation := Simulation.new(_SEED, 1)
	var colonist := simulation.state.colonists[0]
	var target := _far_walkable_cell(simulation, colonist.cell, 30)
	expect(simulation.order_move(colonist.id, target), "A ordem de mover deve ser aceita")
	_run(simulation, 60)
	expect_equal(colonist.state, Colonist.State.MOVING, "Colono deve estar indo cumprir a ordem")
	colonist.needs.food = 10.0
	var ticks := 0
	while colonist.direct_order != null and ticks < 30000:
		simulation.step()
		ticks += 1
	expect(colonist.direct_order == null, "A ordem deve terminar depois de comer")
	expect_equal(colonist.cell, target, "O colono deve chegar ao destino da ordem")
	expect(colonist.needs.food > 50.0, "O colono deve ter comido (fome em %.0f%%)" % colonist.needs.food)
	var interrupted_order := false
	var critical_meal := false
	for record in colonist.history:
		if record.chosen.begins_with("Ir até") and record.outcome.begins_with("interrompida"):
			interrupted_order = true
		if record.chosen.begins_with("Comer") and record.reason.begins_with("Necessidade crítica"):
			critical_meal = true
	expect(interrupted_order, "O histórico deve mostrar a ordem interrompida")
	expect(critical_meal, "O histórico deve mostrar a refeição como necessidade crítica")


func test_two_colonists_never_eat_from_the_same_bush() -> void:
	var simulation := Simulation.new(_SEED, 2)
	var first := simulation.state.colonists[0]
	var second := simulation.state.colonists[1]
	_remove_stored_food(simulation)
	var only_bush := _keep_only_nearest_bush(simulation, first.cell)
	first.needs.food = 20.0
	second.needs.food = 20.0
	var saw_rejection := false
	for _i in 5000:
		simulation.step()
		var eating := 0
		for colonist in [first, second]:
			if colonist.action and colonist.action.kind == Action.Kind.EAT and colonist.state == Colonist.State.EXECUTING:
				eating += 1
		expect(eating <= 1, "Dois colonos nunca comem do mesmo arbusto ao mesmo tempo")
		if eating > 1:
			return
		# O histórico guarda só as últimas decisões: verificar a cada tick.
		saw_rejection = saw_rejection or _any_rejection(first, "reservado por") or _any_rejection(second, "reservado por")
	expect(saw_rejection, "Um dos dois deve ter registrado o arbusto como reservado pelo outro")
	expect(first.needs.food > 60.0 and second.needs.food > 60.0,
		"Os dois devem comer, um depois do outro (%.0f%% e %.0f%%)" % [first.needs.food, second.needs.food])
	expect(only_bush.portions < Balance.BERRY_BUSH_MAX_PORTIONS, "As porções saem do arbusto de verdade")


func test_without_food_hunger_is_not_restored() -> void:
	var simulation := Simulation.new(_SEED, 1)
	var colonist := simulation.state.colonists[0]
	_remove_stored_food(simulation)
	for bush in simulation.state.bushes:
		bush.portions = 0
	colonist.needs.food = 20.0
	_run(simulation, 600)
	expect(colonist.needs.food < 20.0, "Sem comida a fome continua caindo")
	expect(_any_rejection(colonist, "nenhum arbusto tem frutas"), "O motivo deve explicar que não há frutas")


func test_bush_running_out_releases_reservation() -> void:
	var simulation := Simulation.new(_SEED, 1)
	var colonist := simulation.state.colonists[0]
	_remove_stored_food(simulation)
	var bush := _keep_only_nearest_bush(simulation, colonist.cell)
	bush.portions = 1
	colonist.needs.food = 20.0
	var ticks := 3000
	_run(simulation, ticks)
	expect_equal(bush.portions, 0, "A única porção deve ter sido comida")
	expect_equal(simulation.state.reservations.count_for(colonist.id), 0, "Nenhuma reserva pode ficar presa")
	var expected := 20.0 + Balance.BERRY_NUTRITION - Balance.FOOD_DECAY_PER_TICK * ticks
	expect(absf(colonist.needs.food - expected) < 0.5, "Comeu exatamente uma porção (fome %.2f, esperado %.2f)" % [colonist.needs.food, expected])


func test_exhaustion_forces_sleep_on_the_spot() -> void:
	var simulation := Simulation.new(_SEED, 1)
	var colonist := simulation.state.colonists[0]
	colonist.needs.rest = 0.0
	_run(simulation, Balance.THINK_INTERVAL_TICKS + 1)
	expect(colonist.is_sleeping(), "Com sono em 0% o colono desmaia e dorme")
	expect_equal(colonist.action.layer, Action.Layer.REACTION, "Desmaio é uma reação urgente")
	_run(simulation, Balance.TICKS_PER_HOUR)
	expect(colonist.needs.rest > 5.0, "Dormindo, o sono se recupera")


func test_order_to_impassable_cell_is_rejected() -> void:
	var simulation := Simulation.new(_SEED, 1)
	var colonist := simulation.state.colonists[0]
	var rock := _first_cell_of(simulation, Terrain.Kind.ROCK)
	var messages: Array[String] = []
	simulation.message_posted.connect(func(text: String) -> void: messages.append(text))
	expect(not simulation.order_move(colonist.id, rock), "Ordem para rocha deve ser recusada")
	expect(colonist.direct_order == null, "Nenhuma ordem fica pendente")
	expect(messages.size() == 1 and messages[0].contains("Rocha"), "O jogador recebe o motivo")


func test_decision_reason_names_the_layer_and_need() -> void:
	var simulation := Simulation.new(_SEED, 1)
	var colonist := simulation.state.colonists[0]
	colonist.needs.food = 25.5
	_run(simulation, Balance.THINK_INTERVAL_TICKS + 1)
	expect(colonist.action != null and colonist.action.kind == Action.Kind.EAT, "Com fome abaixo de 30% vai comer")
	expect(colonist.history[0].reason.begins_with("Tempo livre"), "Motivo deve citar a camada: %s" % colonist.history[0].reason)
	expect(colonist.history[0].reason.to_lower().contains("fome em 25%"), "Motivo deve citar a fome real: %s" % colonist.history[0].reason)


func test_same_seed_gives_same_behavior() -> void:
	var first := Simulation.new(777)
	var second := Simulation.new(777)
	_run(first, 5000)
	_run(second, 5000)
	for index in first.state.colonists.size():
		var a := first.state.colonists[index]
		var b := second.state.colonists[index]
		expect_equal(a.cell, b.cell, "Colono %d na mesma célula" % index)
		expect_equal(a.needs.food, b.needs.food, "Colono %d com a mesma fome" % index)


## Esvazia a comida dos caixotes iniciais, para testar a busca de comida nos arbustos.
func _remove_stored_food(simulation: Simulation) -> void:
	for container in simulation.state.containers.values():
		for slot in container.slots:
			if slot["item"] != &"" and Defs.item(slot["item"]).is_edible():
				slot["item"] = &""
				slot["count"] = 0


func _run(simulation: Simulation, ticks: int) -> void:
	for _i in ticks:
		simulation.step()


func _far_walkable_cell(simulation: Simulation, from: Vector2i, distance: int) -> Vector2i:
	var navigation := simulation.state.navigation
	for radius in range(distance, distance + 20):
		for offset in [Vector2i(radius, 0), Vector2i(-radius, 0), Vector2i(0, radius), Vector2i(0, -radius)]:
			var cell: Vector2i = from + offset
			if navigation.is_walkable(cell) and not navigation.find_path(from, cell).is_empty():
				return cell
	push_error("Nenhuma célula distante alcançável")
	return from


func _keep_only_nearest_bush(simulation: Simulation, near: Vector2i) -> BerryBush:
	var nearest: BerryBush
	for bush in simulation.state.bushes:
		if nearest == null or bush.cell.distance_squared_to(near) < nearest.cell.distance_squared_to(near):
			nearest = bush
	for bush in simulation.state.bushes:
		bush.portions = Balance.BERRY_BUSH_MAX_PORTIONS if bush == nearest else 0
	return nearest


func _first_cell_of(simulation: Simulation, kind: int) -> Vector2i:
	for y in simulation.world.size.y:
		for x in simulation.world.size.x:
			if simulation.world.get_terrain(Vector2i(x, y)) == kind:
				return Vector2i(x, y)
	push_error("Terreno ausente: %d" % kind)
	return Vector2i.ZERO


func _any_rejection(colonist: Colonist, text: String) -> bool:
	for record in colonist.history:
		for rejection in record.rejected:
			if rejection.contains(text):
				return true
	return false
