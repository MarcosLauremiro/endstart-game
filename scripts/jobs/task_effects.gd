class_name TaskEffects
extends RefCounted
## Validade e resultado das tarefas no mundo. O resultado só é aplicado quando o trabalho termina:
## a coleta gera itens reais no chão, que viram tarefas de Carregar.

const _NEIGHBORS := [
	Vector2i(-1, -1), Vector2i(0, -1), Vector2i(1, -1), Vector2i(-1, 0),
	Vector2i(1, 0), Vector2i(-1, 1), Vector2i(0, 1), Vector2i(1, 1),
]


static func is_still_valid(task: Task, state: WorldState) -> bool:
	if not task.is_open():
		return false
	match task.kind:
		Task.Kind.CUT:
			return state.trees.has(task.target_id)
		Task.Kind.MINE:
			return state.world.get_terrain(task.cell) == Terrain.Kind.ROCK
		Task.Kind.HARVEST:
			var fiber: FiberPlant = state.fiber_plants.get(task.target_id)
			if fiber:
				return fiber.is_mature()
			var bush := state.bush_by_id(task.target_id)
			return bush != null and bush.portions > 0
		Task.Kind.HAUL:
			var stack: ItemStack = state.stacks.get(task.target_id)
			return stack != null and stack.count > 0
		Task.Kind.CONSTRUCT:
			return state.sites.has(task.target_id)
		Task.Kind.DECONSTRUCT:
			return Construction.deconstruct_target_exists(state, task.target_id)
		Task.Kind.CRAFT:
			return state.workbenches.has(task.target_id)
		Task.Kind.HUNT:
			return state.animals.has(task.target_id)
		Task.Kind.SOW:
			return Farming.sow_problem(state, task.cell).is_empty()
		Task.Kind.REAP:
			return state.crops.has(task.target_id)
	return false


static func complete(task: Task, state: WorldState) -> void:
	match task.kind:
		Task.Kind.CUT:
			var tree: WildTree = state.trees.get(task.target_id)
			if tree:
				var wood := tree.wood_yield()
				state.remove_tree(tree)
				state.add_stump(task.cell, tree.is_adult())
				state.drop_items(task.cell, &"wood", wood)
		Task.Kind.MINE:
			state.world.set_terrain(task.cell, Terrain.Kind.DIRT)
			state.navigation.refresh_cell(task.cell)
			state.drop_items(task.cell, &"stone_raw", Balance.ROCK_STONE_YIELD)
			# A rocha aberta pode ter liberado acesso às vizinhas que estavam bloqueadas.
			for offset in _NEIGHBORS:
				var neighbor := state.task_board.designation_at(task.cell + offset)
				if neighbor:
					neighbor.unblock()
		Task.Kind.HARVEST:
			var fiber: FiberPlant = state.fiber_plants.get(task.target_id)
			if fiber and fiber.is_mature():
				fiber.harvest()
				state.drop_items(task.cell, &"fiber", Balance.FIBER_YIELD)
			var bush := state.bush_by_id(task.target_id)
			if bush and bush.portions > 0:
				var amount := bush.portions
				bush.portions = 0
				state.drop_items(task.cell, &"berries", amount)
		Task.Kind.CONSTRUCT:
			var site: ConstructionSite = state.sites.get(task.target_id)
			if site:
				Construction.complete(state, site)
		Task.Kind.DECONSTRUCT:
			Construction.deconstruct(state, task.target_id)
		Task.Kind.CRAFT:
			# A tarefa da bancada fica no quadro: só o pedido em andamento termina.
			var bench: Workbench = state.workbenches.get(task.target_id)
			if bench and bench.job:
				bench.finish_job(state)
			task.progress = 0.0
			return
		Task.Kind.HUNT:
			var animal: Animal = state.animals.get(task.target_id)
			if animal:
				Wildlife.kill(state, animal, true)
		Task.Kind.SOW:
			Farming.sow(state, task.cell, task.target_id)
		Task.Kind.REAP:
			Farming.reap(state, task.target_id)
	state.task_board.remove(task, Task.Status.DONE)
	if task.kind == Task.Kind.REAP:
		# O tile colhido volta a ser semeado (quando os itens forem levados embora).
		Farming.update_tasks(state)
