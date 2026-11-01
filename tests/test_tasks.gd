class_name TestTasks
extends TestCase
## Quadro de tarefas (M2): pontuação do GDD, divisão sem conflito, conservação de itens, prioridades,
## interrupção com progresso preservado, perda de acesso, expiração de reservas, transporte,
## contêiner cheio, cancelamento, personalidade e desempenho.

const _SEED := 12345


func test_score_follows_gdd_formula() -> void:
	expect(absf(TaskSelector.score(2, 0, 30.0) - 0.5) < 0.0001, "2 × 0,5 ÷ (1 + 30/30) = 0,5")
	expect(absf(TaskSelector.score(1, 10, 0.0) - 1.0) < 0.0001, "1 × (0,5 + 10/20) ÷ 1 = 1,0")
	expect(TaskSelector.score(1, 0, 10.0) > TaskSelector.score(1, 0, 40.0), "Mais perto pontua mais")


func test_three_colonists_divide_cutting_without_conflict() -> void:
	var simulation := Simulation.new(_SEED, 3)
	var trees := _nearest_trees(simulation, 6)
	var wood_before := simulation.state.total_count(&"wood")
	for tree in trees:
		simulation.designate(Designations.Tool.CUT, Rect2i(tree.cell, Vector2i.ONE))
	var workers := {}
	var ticks := 0
	while _open_tasks(simulation, WorkType.Id.CUT) > 0 and ticks < 30000:
		simulation.step()
		ticks += 1
		var working_on := {}
		for colonist in simulation.state.colonists:
			if colonist.action and colonist.action.kind == Action.Kind.WORK and colonist.state == Colonist.State.EXECUTING:
				expect(not working_on.has(colonist.action.task_id), "Dois colonos na mesma árvore ao mesmo tempo")
				working_on[colonist.action.task_id] = true
				workers[colonist.id] = true
	expect_equal(_open_tasks(simulation, WorkType.Id.CUT), 0, "As 6 árvores devem ser cortadas")
	expect(workers.size() >= 2, "O trabalho deve se dividir entre colonos (trabalharam %d)" % workers.size())
	expect_equal(simulation.state.total_count(&"wood"), wood_before + 6 * Balance.TREE_WOOD_YIELD,
		"A madeira gerada deve ser exatamente 6 × rendimento, sem duplicar nem sumir")


func test_single_tree_gets_a_single_worker() -> void:
	var simulation := Simulation.new(_SEED, 3)
	var tree: WildTree = _nearest_trees(simulation, 1)[0]
	simulation.designate(Designations.Tool.CUT, Rect2i(tree.cell, Vector2i.ONE))
	var saw_rejection := false
	for _i in 600:
		simulation.step()
		var on_tree := 0
		for colonist in simulation.state.colonists:
			if colonist.action and colonist.action.kind == Action.Kind.WORK:
				on_tree += 1
			saw_rejection = saw_rejection or _any_rejection(colonist, "reservada por")
		expect(on_tree <= 1, "Só um colono pode pegar a única árvore")
		if on_tree > 1:
			return
	expect(saw_rejection, "Os outros devem registrar que a tarefa está reservada")


func test_interrupted_work_keeps_progress_and_resumes() -> void:
	var simulation := Simulation.new(_SEED, 1)
	var colonist := simulation.state.colonists[0]
	var tree: WildTree = _nearest_trees(simulation, 1)[0]
	simulation.designate(Designations.Tool.CUT, Rect2i(tree.cell, Vector2i.ONE))
	var task := simulation.state.task_board.designation_at(tree.cell)
	var ticks := 0
	while task.progress < 400.0 and ticks < 5000:
		simulation.step()
		ticks += 1
	expect(task.progress >= 400.0, "O colono deve ter começado a cortar")
	colonist.needs.food = 10.0
	var progress_at_interruption := task.progress
	_run(simulation, Balance.THINK_INTERVAL_TICKS + 1)
	expect(colonist.action != null and colonist.action.kind == Action.Kind.EAT, "Fome crítica deve interromper o corte")
	expect_equal(simulation.state.reservations.owner_of(task.key()), 0, "A árvore deve ser liberada durante a refeição")
	expect(task.progress >= progress_at_interruption, "O progresso não pode voltar para trás")
	var lowest := task.progress
	while task.is_open() and ticks < 20000:
		simulation.step()
		ticks += 1
		lowest = minf(lowest, task.progress) if task.is_open() else lowest
	expect(not task.is_open(), "Depois de comer, o corte deve ser retomado e concluído")
	expect(lowest >= progress_at_interruption, "O trabalho continuou de onde parou")


func test_unreachable_rock_is_blocked_with_reason() -> void:
	var simulation := Simulation.new(_SEED, 1)
	var colonist := simulation.state.colonists[0]
	var inner := _inner_rock(simulation)
	expect(inner != Vector2i(-1, -1), "O mapa deve ter rocha cercada de rocha")
	simulation.designate(Designations.Tool.MINE, Rect2i(inner, Vector2i.ONE))
	var task := simulation.state.task_board.designation_at(inner)
	_run(simulation, Balance.THINK_INTERVAL_TICKS * 2)
	expect(task.is_blocked(simulation.clock.tick), "Rocha sem acesso deve ficar bloqueada")
	expect_equal(task.block_reason, "sem caminho", "O motivo do bloqueio deve aparecer")
	expect_equal(simulation.state.reservations.count_for(colonist.id), 0, "Nada fica reservado")
	expect(_any_rejection(colonist, "sem caminho"), "O colono deve registrar o motivo")


func test_losing_access_on_the_way_releases_everything() -> void:
	var simulation := Simulation.new(_SEED, 1)
	var colonist := simulation.state.colonists[0]
	var tree := _tree_at_distance(simulation, colonist.cell, 15)
	simulation.designate(Designations.Tool.CUT, Rect2i(tree.cell, Vector2i.ONE))
	var task := simulation.state.task_board.designation_at(tree.cell)
	var ticks := 0
	while colonist.state != Colonist.State.MOVING and ticks < 200:
		simulation.step()
		ticks += 1
	expect_equal(colonist.state, Colonist.State.MOVING, "O colono deve estar a caminho da árvore")
	# Um fosso de água funda surge em volta da árvore.
	for y in range(-2, 3):
		for x in range(-2, 3):
			if absi(x) == 2 or absi(y) == 2:
				var cell: Vector2i = tree.cell + Vector2i(x, y)
				if simulation.world.contains(cell):
					simulation.world.set_terrain(cell, Terrain.Kind.DEEP_WATER)
					simulation.state.navigation.refresh_cell(cell)
	# O colono só percebe ao chegar no fosso; o caminho passa por um vau lento.
	_run(simulation, 2000)
	expect(colonist.action == null or colonist.action.task_id != task.id, "O colono deve desistir da árvore inalcançável")
	expect_equal(simulation.state.reservations.owner_of(task.key()), 0, "A reserva da árvore deve ser liberada")
	expect(task.is_open(), "A tarefa continua no quadro para quando houver acesso")
	expect(task.block_reason.contains("caminho"), "A tarefa deve guardar o motivo: %s" % task.block_reason)


func test_stale_reservation_expires() -> void:
	var simulation := Simulation.new(_SEED, 1)
	var colonist := simulation.state.colonists[0]
	var tree: WildTree = _nearest_trees(simulation, 1)[0]
	simulation.designate(Designations.Tool.CUT, Rect2i(tree.cell, Vector2i.ONE))
	var task := simulation.state.task_board.designation_at(tree.cell)
	simulation.set_work_priority(colonist.id, WorkType.Id.CUT, 0)
	colonist.needs.rest = 5.0
	_run(simulation, Balance.THINK_INTERVAL_TICKS + 1)
	expect(colonist.is_sleeping(), "O colono deve estar dormindo")
	# Uma reserva esquecida, sem ninguém trabalhando nela.
	simulation.state.reservations.try_reserve(task.key(), colonist.id, simulation.clock.tick)
	_run(simulation, Balance.RESERVATION_TIMEOUT_TICKS + Balance.THINK_INTERVAL_TICKS * 2)
	expect_equal(simulation.state.reservations.owner_of(task.key()), 0, "Reserva sem avanço deve expirar")


func test_hauling_stores_items_without_duplication() -> void:
	var simulation := Simulation.new(_SEED, 3)
	var colonist := simulation.state.colonists[0]
	var before := simulation.state.total_count(&"stone_raw")
	simulation.state.drop_items(colonist.cell + Vector2i(3, 3), &"stone_raw", 30)
	expect_equal(simulation.state.total_count(&"stone_raw"), before + 30, "Os itens largados devem existir")
	var ticks := 0
	while (_ground_count(simulation, &"stone_raw") > 0 or _carried(simulation, &"stone_raw") > 0) and ticks < 6000:
		simulation.step()
		ticks += 1
		expect_equal(simulation.state.total_count(&"stone_raw"), before + 30, "Total constante durante o transporte")
		if simulation.state.total_count(&"stone_raw") != before + 30:
			return
	expect_equal(_ground_count(simulation, &"stone_raw"), 0, "Toda a pedra deve ir para os caixotes")
	var stored := 0
	for container in simulation.state.containers.values():
		stored += container.count_of(&"stone_raw")
		for slot in container.slots:
			if slot["item"] != &"":
				expect(slot["count"] <= Defs.item(slot["item"]).stack_size, "Nenhum espaço passa do tamanho da pilha")
	expect_equal(stored, before + 30, "A pedra guardada é exatamente a que foi largada")


func test_full_storage_blocks_hauling_with_reason() -> void:
	var simulation := Simulation.new(_SEED, 1)
	var colonist := simulation.state.colonists[0]
	for container in simulation.state.containers.values():
		container.add_items(&"scrap", 1000)
	simulation.state.drop_items(colonist.cell + Vector2i(2, 2), &"stone_raw", 10)
	_run(simulation, 600)
	expect_equal(_ground_count(simulation, &"stone_raw"), 10, "Sem espaço, a pedra fica no chão")
	var stack: ItemStack = simulation.state.stacks_by_cell.values().filter(func(s: ItemStack) -> bool: return s.item == &"stone_raw")[0]
	var task := simulation.state.task_board.haul_for_stack(stack.id)
	expect_equal(task.block_reason, "nenhum contêiner com espaço aceita pedra bruta (recursos básicos)", "O motivo do bloqueio deve aparecer")


func test_priority_off_is_respected_and_explained() -> void:
	var simulation := Simulation.new(_SEED, 1)
	var colonist := simulation.state.colonists[0]
	simulation.set_work_priority(colonist.id, WorkType.Id.CUT, 0)
	for tree in _nearest_trees(simulation, 3):
		simulation.designate(Designations.Tool.CUT, Rect2i(tree.cell, Vector2i.ONE))
	for _i in 1500:
		simulation.step()
		expect(colonist.action == null or colonist.action.kind != Action.Kind.WORK, "Com Cortar desligado ele não corta")
		if colonist.action and colonist.action.kind == Action.Kind.WORK:
			return
	expect(_any_rejection(colonist, "Cortar plantas: prioridade desligada"), "O motivo deve aparecer no registro")


func test_higher_priority_wins_over_distance() -> void:
	var simulation := Simulation.new(_SEED, 1)
	var colonist := simulation.state.colonists[0]
	var tree: WildTree = _nearest_trees(simulation, 1)[0]
	var rock := _reachable_rock_farther_than(simulation, colonist.cell, tree.cell.distance_to(colonist.cell))
	simulation.designate(Designations.Tool.CUT, Rect2i(tree.cell, Vector2i.ONE))
	simulation.designate(Designations.Tool.MINE, Rect2i(rock, Vector2i.ONE))
	simulation.set_work_priority(colonist.id, WorkType.Id.MINE, 1)
	_run(simulation, Balance.THINK_INTERVAL_TICKS + 1)
	expect(colonist.action != null and colonist.action.kind == Action.Kind.WORK, "Deve estar trabalhando")
	var task := simulation.state.task_board.get_task(colonist.action.task_id) if colonist.action else null
	expect(task != null and task.kind == Task.Kind.MINE, "Minerar com prioridade 1 vem antes da árvore mais perto")
	expect(colonist.history[0].reason.contains("Prioridade 1 em Minerar"), "O motivo cita a prioridade: %s" % colonist.history[0].reason)


func test_cancel_stops_the_worker_cleanly() -> void:
	var simulation := Simulation.new(_SEED, 1)
	var colonist := simulation.state.colonists[0]
	var tree: WildTree = _nearest_trees(simulation, 1)[0]
	simulation.designate(Designations.Tool.CUT, Rect2i(tree.cell, Vector2i.ONE))
	var ticks := 0
	while not (colonist.action and colonist.action.kind == Action.Kind.WORK and colonist.state == Colonist.State.EXECUTING) and ticks < 3000:
		simulation.step()
		ticks += 1
	simulation.designate(Designations.Tool.CANCEL, Rect2i(tree.cell, Vector2i.ONE))
	_run(simulation, 5)
	expect(colonist.action == null or colonist.action.kind != Action.Kind.WORK, "O corte cancelado deve parar")
	expect_equal(simulation.state.reservations.count_for(colonist.id), 0, "Nenhuma reserva presa")
	expect(simulation.state.trees.has(tree.id), "A árvore continua de pé")


func test_eats_from_starting_crate() -> void:
	var simulation := Simulation.new(_SEED, 1)
	var colonist := simulation.state.colonists[0]
	var meals_before := simulation.state.total_count(&"simple_meal")
	colonist.needs.food = 25.0
	_run(simulation, 1200)
	expect_equal(simulation.state.total_count(&"simple_meal"), meals_before - 1, "Deve comer uma refeição do caixote")
	expect(colonist.needs.food > 60.0, "A fome deve subir com a refeição (%.0f%%)" % colonist.needs.food)


func test_hardworking_outworks_lazy_and_lazy_takes_breaks() -> void:
	var progress := {}
	for trait_id in [Traits.HARDWORKING, Traits.LAZY]:
		var simulation := Simulation.new(_SEED, 1)
		var colonist := simulation.state.colonists[0]
		colonist.traits.clear()
		colonist.traits.append(trait_id)
		var trees := _nearest_trees(simulation, 12)
		for tree in trees:
			simulation.designate(Designations.Tool.CUT, Rect2i(tree.cell, Vector2i.ONE))
		simulation.set_work_priority(colonist.id, WorkType.Id.HAUL, 0)
		var took_break := false
		for _i in 4 * Balance.TICKS_PER_HOUR:
			simulation.step()
			took_break = took_break or (colonist.action != null and colonist.action.kind == Action.Kind.BREAK)
		progress[trait_id] = _total_cut_progress(simulation, trees.size())
		if trait_id == Traits.LAZY:
			expect(took_break, "Preguiçoso deve fazer pausa depois de 2 h de trabalho")
			expect(_any_reason(colonist, "Preguiçoso"), "A pausa deve ser explicada pelo traço")
		else:
			expect(not took_break, "Esforçado não faz pausas")
	expect(progress[Traits.HARDWORKING] > progress[Traits.LAZY] * 1.3,
		"Esforçado deve render bem mais que Preguiçoso (%.0f contra %.0f)" % [progress[Traits.HARDWORKING], progress[Traits.LAZY]])


func test_ai_cost_stays_small_with_many_tasks() -> void:
	var simulation := Simulation.new(_SEED, 5)
	var center := simulation.state.colonists[0].cell
	simulation.designate(Designations.Tool.CUT, Rect2i(center - Vector2i(30, 30), Vector2i(60, 60)))
	simulation.designate(Designations.Tool.MINE, Rect2i(Vector2i.ZERO, simulation.world.size))
	var tasks := simulation.state.task_board.count()
	var worst := 0
	var worst_tick := 0
	var slow_ticks := 0
	var started := Time.get_ticks_usec()
	var steps := Balance.TICKS_PER_DAY / 4
	for _i in steps:
		var before := Time.get_ticks_usec()
		simulation.step()
		var spent := Time.get_ticks_usec() - before
		if spent > 2000:
			slow_ticks += 1
		if spent > worst:
			worst = spent
			worst_tick = simulation.clock.tick
	var average := float(Time.get_ticks_usec() - started) / steps
	print("      %d tarefas, 5 colonos, 6 h de jogo: média %.3f ms/tick, pior %.1f ms (tick %d), %d ticks acima de 2 ms" % [
		tasks, average / 1000.0, worst / 1000.0, worst_tick, slow_ticks])
	expect(tasks > 300, "O cenário deve ter muitas tarefas (%d)" % tasks)
	expect(average < 1000.0, "A média por tick deve ficar abaixo de 1 ms (%.3f ms)" % (average / 1000.0))


func _run(simulation: Simulation, ticks: int) -> void:
	for _i in ticks:
		simulation.step()


func _nearest_trees(simulation: Simulation, amount: int) -> Array:
	var center := simulation.state.colonists[0].cell
	var trees := simulation.state.trees.values().filter(func(tree: WildTree) -> bool:
		return simulation.state.navigation.can_reach(center, tree.cell))
	trees.sort_custom(func(a: WildTree, b: WildTree) -> bool:
		return a.cell.distance_squared_to(center) < b.cell.distance_squared_to(center))
	var chosen := trees.slice(0, amount)
	# Árvores adultas: rendimento e tempo de corte fixos, sem crescer durante o teste.
	for tree in chosen:
		tree.growth_hours = Balance.TREE_GROWTH_HOURS
	return chosen


func _tree_at_distance(simulation: Simulation, from: Vector2i, distance: float) -> WildTree:
	for tree in _nearest_trees(simulation, 400):
		if tree.cell.distance_to(from) >= distance:
			return tree
	push_error("Nenhuma árvore a %.0f tiles" % distance)
	return null


func _carried(simulation: Simulation, item: StringName) -> int:
	var total := 0
	for colonist in simulation.state.colonists:
		if colonist.carrying_item == item:
			total += colonist.carrying_count
	return total


func _open_tasks(simulation: Simulation, work_type: int) -> int:
	return simulation.state.task_board.tasks_of(work_type).size()


func _ground_count(simulation: Simulation, item: StringName) -> int:
	var total := 0
	for stack in simulation.state.stacks.values():
		if stack.item == item:
			total += stack.count
	return total


## Trabalho de corte feito: progresso das tarefas abertas + trabalho inteiro das concluídas.
func _total_cut_progress(simulation: Simulation, designated: int) -> float:
	var open_tasks := simulation.state.task_board.tasks_of(WorkType.Id.CUT)
	var total := 0.0
	for task in open_tasks:
		total += task.progress
	return total + (designated - open_tasks.size()) * Balance.CUT_WORK_TICKS


func _inner_rock(simulation: Simulation) -> Vector2i:
	for y in range(1, simulation.world.size.y - 1):
		for x in range(1, simulation.world.size.x - 1):
			var cell := Vector2i(x, y)
			if simulation.world.get_terrain(cell) != Terrain.Kind.ROCK:
				continue
			var enclosed := true
			for dy in range(-1, 2):
				for dx in range(-1, 2):
					if simulation.world.get_terrain(cell + Vector2i(dx, dy)) != Terrain.Kind.ROCK:
						enclosed = false
			if enclosed:
				return cell
	return Vector2i(-1, -1)


func _reachable_rock_farther_than(simulation: Simulation, from: Vector2i, distance: float) -> Vector2i:
	var rocks: Array[Vector2i] = []
	for y in simulation.world.size.y:
		for x in simulation.world.size.x:
			var cell := Vector2i(x, y)
			if simulation.world.get_terrain(cell) == Terrain.Kind.ROCK and cell.distance_to(from) > distance:
				rocks.append(cell)
	rocks.sort_custom(func(a: Vector2i, b: Vector2i) -> bool: return a.distance_squared_to(from) < b.distance_squared_to(from))
	for cell in rocks:
		if not simulation.state.navigation.path_to_adjacent(from, cell).is_empty():
			return cell
	return Vector2i(-1, -1)


func _any_rejection(colonist: Colonist, text: String) -> bool:
	for record in colonist.history:
		for rejection in record.rejected:
			if rejection.contains(text):
				return true
	return false


func _any_reason(colonist: Colonist, text: String) -> bool:
	for record in colonist.history:
		if record.reason.contains(text):
			return true
	return false
