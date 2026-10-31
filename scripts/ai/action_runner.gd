class_name ActionRunner
extends RefCounted
## Executa a ação do colono tick a tick: reserva, caminha, executa, aplica o resultado e libera.
## Toda saída (conclusão, falha, interrupção) libera as reservas do colono, larga no chão o que
## estiver nas mãos e anota o motivo. Assim nada fica preso e nenhum item some.

const _DIAGONAL_LENGTH := 1.41421356


func start(colonist: Colonist, action: Action, state: WorldState) -> void:
	if colonist.action:
		abort(colonist, state, "trocou para: %s" % action.label())
	colonist.state = Colonist.State.CHOOSING
	colonist.action = action
	var problem := _reserve(colonist, action, state)
	if not problem.is_empty():
		_fail(colonist, state, problem)
		return
	_travel(colonist, action, state, action.path)


func step(colonist: Colonist, state: WorldState) -> void:
	match colonist.state:
		Colonist.State.MOVING:
			_move(colonist, state)
		Colonist.State.EXECUTING:
			_execute(colonist, state)
		Colonist.State.FINISHING:
			_finish(colonist, state)


## Interrupção por uma camada mais alta ou reserva expirada. O progresso fica na tarefa
## e a ordem direta fica guardada para ser retomada.
func abort(colonist: Colonist, state: WorldState, why: String) -> void:
	_close(colonist, state, "interrompida: %s" % why)


## Reservas exclusivas que pertencem à ação atual do colono.
func keys_of(colonist: Colonist) -> Array[String]:
	var keys: Array[String] = []
	var action := colonist.action
	if action == null:
		return keys
	if not action.reservation_key.is_empty():
		keys.append(action.reservation_key)
	if action.kind == Action.Kind.SLEEP and action.target_id != 0:
		keys.append(Reservations.bed_key(action.target_id))
	if action.kind == Action.Kind.EAT and action.item_source == Action.ItemSource.BUSH:
		keys.append(Reservations.bush_key(action.target_id))
	return keys


## Marca avanço só nas reservas da ação atual: uma reserva esquecida em outro lugar continua envelhecendo.
func _touch(colonist: Colonist, state: WorldState) -> void:
	for key in keys_of(colonist):
		state.reservations.touch(key, state.clock.tick)


func _reserve(colonist: Colonist, action: Action, state: WorldState) -> String:
	var tick := state.clock.tick
	match action.kind:
		Action.Kind.EAT:
			match action.item_source:
				Action.ItemSource.BUSH:
					if not state.reservations.try_reserve(Reservations.bush_key(action.target_id), colonist.id, tick):
						return "o arbusto foi reservado por outro"
				Action.ItemSource.CONTAINER:
					var container: StorageContainer = state.containers.get(action.target_id)
					action.count = container.reserve_take(colonist.id, action.item_id, action.count) if container else 0
					if action.count <= 0:
						return "a comida do contêiner já foi reservada"
				Action.ItemSource.STACK:
					var stack: ItemStack = state.stacks.get(action.target_id)
					action.count = stack.reserve_take(colonist.id, action.count) if stack else 0
					if action.count <= 0:
						return "a comida da pilha já foi reservada"
		Action.Kind.SLEEP:
			if action.target_id != 0 and not state.reservations.try_reserve(Reservations.bed_key(action.target_id), colonist.id, tick):
				return "a cama foi ocupada por outro"
		Action.Kind.WORK, Action.Kind.HUNT:
			var task := state.task_board.get_task(action.task_id)
			if task == null or not state.reservations.try_reserve(action.reservation_key, colonist.id, tick):
				return "a tarefa foi reservada por outro"
			if task.kind == Task.Kind.CRAFT:
				var bench: Workbench = state.workbenches.get(task.target_id)
				if bench == null or not bench.has_all_ingredients():
					return "faltam ingredientes na bancada"
				task.work_required = bench.job.recipe.work_ticks()
		Action.Kind.DELIVER:
			return _reserve_delivery(colonist, action, state)
		Action.Kind.HAUL:
			var task := state.task_board.get_task(action.task_id)
			var stack: ItemStack = state.stacks.get(action.target_id)
			var destination: StorageContainer = state.containers.get(action.destination_id)
			if task == null or stack == null or destination == null:
				return "a pilha ou o contêiner não existem mais"
			if not state.reservations.try_reserve(action.reservation_key, colonist.id, tick):
				return "a tarefa foi reservada por outro"
			var wanted := mini(stack.available(), colonist.carry_units(stack.item))
			var space := destination.reserve_space(colonist.id, stack.item, wanted)
			action.count = stack.reserve_take(colonist.id, space)
			if action.count <= 0:
				return "sem itens livres ou sem espaço no destino"
			if action.count < space:
				# Pegou menos do que o espaço reservado: refaz a reserva de espaço no tamanho certo.
				destination.release_owner(colonist.id)
				destination.reserve_space(colonist.id, stack.item, action.count)
	return ""


## Entrega de material: reserva a entrega da obra ou bancada, as unidades na origem e a chegada.
## Numa bancada parada, a primeira entrega começa o pedido escolhido.
func _reserve_delivery(colonist: Colonist, action: Action, state: WorldState) -> String:
	var receiver: Object = state.delivery_receiver(action.destination_id)
	if receiver == null:
		return "a obra ou a bancada não existe mais"
	if not state.reservations.try_reserve(action.reservation_key, colonist.id, state.clock.tick):
		return "outro colono já está trazendo o material"
	if receiver is Workbench:
		var bench: Workbench = receiver
		if not bench.bills.has(action.bill):
			return "o pedido foi apagado"
		if bench.job == null:
			bench.start_job(action.bill)
		elif bench.job != action.bill:
			return "a bancada já começou outro pedido"
	var granted := 0
	if action.item_source == Action.ItemSource.CONTAINER:
		var container: StorageContainer = state.containers.get(action.target_id)
		granted = container.reserve_take(colonist.id, action.item_id, action.count) if container else 0
	else:
		var stack: ItemStack = state.stacks.get(action.target_id)
		granted = stack.reserve_take(colonist.id, action.count) if stack else 0
	if granted <= 0:
		return "o material já foi reservado por outro"
	action.count = granted
	receiver.reserve_incoming(colonist.id, action.item_id, granted)
	return ""


func _travel(colonist: Colonist, action: Action, state: WorldState, precomputed: Array[Vector2i]) -> void:
	var path := precomputed
	if path.is_empty() or path[0] != colonist.cell:
		path = _path_for(colonist, action, state)
	if path.is_empty():
		_block_task(action, state, "sem caminho")
		_fail(colonist, state, "sem caminho até (%d, %d)" % [action.target_cell.x, action.target_cell.y])
		return
	colonist.path = path.slice(1)
	colonist.move_progress = 0.0
	colonist.state = Colonist.State.MOVING if not colonist.path.is_empty() else Colonist.State.EXECUTING


func _path_for(colonist: Colonist, action: Action, state: WorldState) -> Array[Vector2i]:
	if action.adjacent:
		return state.navigation.path_to_adjacent(colonist.cell, action.target_cell)
	return state.navigation.find_path(colonist.cell, action.target_cell)


func _move(colonist: Colonist, state: WorldState) -> void:
	if colonist.path.is_empty():
		colonist.state = Colonist.State.EXECUTING
		return
	var next := colonist.path[0]
	if not state.navigation.is_walkable(next):
		var replanned := _path_for(colonist, colonist.action, state)
		if replanned.is_empty():
			_block_task(colonist.action, state, "caminho bloqueado")
			_fail(colonist, state, "caminho bloqueado")
			return
		colonist.path = replanned.slice(1)
		colonist.move_progress = 0.0
		return
	var step := next - colonist.cell
	var length := _DIAGONAL_LENGTH if step.x != 0 and step.y != 0 else 1.0
	var factor := state.navigation.speed_factor(next)
	colonist.move_progress += Balance.MOVE_TILES_PER_TICK * factor / length
	_touch(colonist, state)
	if colonist.move_progress < 1.0:
		return
	colonist.move_progress = 0.0
	colonist.cell = next
	colonist.path.remove_at(0)
	if colonist.action.kind == Action.Kind.HUNT:
		_hunter_step(colonist, state)
		return
	if colonist.path.is_empty():
		colonist.state = Colonist.State.EXECUTING


## A cada tile andado na caça: com o animal no alcance, para e mira; se ele se afastou do destino, refaz o caminho.
func _hunter_step(colonist: Colonist, state: WorldState) -> void:
	var animal: Animal = state.animals.get(colonist.action.target_id)
	if animal == null or _in_hunting_range(colonist.cell, animal.cell):
		colonist.path.clear()
		colonist.state = Colonist.State.EXECUTING
		return
	if colonist.path.is_empty() or animal.cell.distance_squared_to(colonist.action.target_cell) > Balance.HUNT_REPATH_DRIFT_SQUARED:
		_chase(colonist, state, animal)


func _execute(colonist: Colonist, state: WorldState) -> void:
	var action := colonist.action
	match action.kind:
		Action.Kind.MOVE, Action.Kind.WANDER:
			colonist.state = Colonist.State.FINISHING
		Action.Kind.IDLE:
			_wait(colonist, Balance.IDLE_TICKS)
		Action.Kind.BREAK:
			_wait(colonist, Balance.LAZY_BREAK_TICKS)
		Action.Kind.SLEEP:
			# Dormir é avançar: a reserva da cama não expira enquanto ele dorme.
			_touch(colonist, state)
			if colonist.needs.rest >= Balance.NEED_MAX:
				colonist.state = Colonist.State.FINISHING
		Action.Kind.EAT:
			_eat(colonist, state)
		Action.Kind.WORK:
			_work(colonist, state)
		Action.Kind.HAUL:
			_haul(colonist, state)
		Action.Kind.DELIVER:
			_deliver(colonist, state)
		Action.Kind.HUNT:
			_hunt(colonist, state)


func _wait(colonist: Colonist, duration: int) -> void:
	colonist.action.progress_ticks += 1
	if colonist.action.progress_ticks >= duration:
		colonist.state = Colonist.State.FINISHING


func _eat(colonist: Colonist, state: WorldState) -> void:
	var action := colonist.action
	if action.item_source == Action.ItemSource.BUSH:
		_eat_from_bush(colonist, state)
		return
	if action.phase == 0:
		var taken := 0
		if action.item_source == Action.ItemSource.CONTAINER:
			var container: StorageContainer = state.containers.get(action.target_id)
			taken = container.take(colonist.id) if container else 0
		else:
			var stack: ItemStack = state.stacks.get(action.target_id)
			if stack:
				taken = stack.take(colonist.id)
				state.remove_stack_if_empty(stack)
		if taken <= 0:
			_fail(colonist, state, "a comida não estava mais lá")
			return
		colonist.carry(action.item_id, taken)
		action.phase = 1
	action.progress_ticks += 1
	_touch(colonist, state)
	if action.progress_ticks < Balance.EAT_PORTION_TICKS:
		return
	action.progress_ticks = 0
	colonist.carrying_count -= 1
	colonist.needs.eat(Defs.item(action.item_id).nutrition)
	if colonist.carrying_count <= 0:
		colonist.clear_carry()
		colonist.state = Colonist.State.FINISHING
	elif colonist.needs.food >= Balance.EAT_UNTIL:
		colonist.state = Colonist.State.FINISHING


func _eat_from_bush(colonist: Colonist, state: WorldState) -> void:
	var action := colonist.action
	var bush := state.bush_by_id(action.target_id)
	if bush == null or bush.portions <= 0:
		_fail(colonist, state, "arbusto #%d ficou sem frutas" % action.target_id)
		return
	action.progress_ticks += 1
	_touch(colonist, state)
	if action.progress_ticks < Balance.EAT_PORTION_TICKS:
		return
	action.progress_ticks = 0
	bush.take_portion()
	colonist.needs.eat(Balance.BERRY_NUTRITION)
	if colonist.needs.food >= Balance.EAT_UNTIL or bush.portions <= 0:
		colonist.state = Colonist.State.FINISHING


func _work(colonist: Colonist, state: WorldState) -> void:
	var task := state.task_board.get_task(colonist.action.task_id)
	if task == null or not TaskEffects.is_still_valid(task, state):
		_fail(colonist, state, "a tarefa foi cancelada ou o alvo sumiu")
		return
	if task.kind == Task.Kind.CONSTRUCT and not state.sites[task.target_id].has_all_materials():
		_fail(colonist, state, "faltam materiais na obra")
		return
	var place_speed := 1.0
	if task.kind == Task.Kind.CRAFT:
		var bench: Workbench = state.workbenches[task.target_id]
		if not bench.has_all_ingredients():
			_fail(colonist, state, "faltam ingredientes na bancada")
			return
		place_speed = bench.def().bench_speed
	task.progress += colonist.work_speed(task.work_type) * place_speed * _team_share(task, state)
	colonist.work_ticks_since_break += 1
	_touch(colonist, state)
	if task.progress >= task.work_required:
		TaskEffects.complete(task, state)
		colonist.state = Colonist.State.FINISHING


## Parte de cada colono na velocidade da equipe (GDD: ×1, ×1,8 e ×2,4 com 1, 2 e 3 colonos).
func _team_share(task: Task, state: WorldState) -> float:
	if task.max_workers <= 1:
		return 1.0
	var workers := 0
	for other in state.colonists:
		if other.action and other.action.kind == Action.Kind.WORK and other.action.task_id == task.id \
				and other.state == Colonist.State.EXECUTING:
			workers += 1
	workers = clampi(workers, 1, Balance.TEAM_WORK_TOTALS.size())
	return Balance.TEAM_WORK_TOTALS[workers - 1] / workers


## Caçar: chega perto o bastante e atira de longe, de tempos em tempos (GDD: caça com arma simples).
## O animal ferido foge; o caçador vai atrás. Morto, vira carcaça no chão, para Carregar.
func _hunt(colonist: Colonist, state: WorldState) -> void:
	var action := colonist.action
	var task := state.task_board.get_task(action.task_id)
	var animal: Animal = state.animals.get(action.target_id)
	if task == null or animal == null:
		_fail(colonist, state, "o animal sumiu")
		return
	if not _in_hunting_range(colonist.cell, animal.cell):
		_chase(colonist, state, animal)
		return
	_touch(colonist, state)
	action.progress_ticks += 1
	if action.progress_ticks < Balance.HUNT_AIM_TICKS:
		return
	action.progress_ticks = 0
	colonist.work_ticks_since_break += Balance.HUNT_AIM_TICKS
	var distance := Vector2(colonist.cell).distance_to(Vector2(animal.cell))
	var chance := clampf(Balance.HUNT_HIT_CHANCE - Balance.HUNT_HIT_FALLOFF_PER_TILE * distance, Balance.HUNT_MIN_HIT_CHANCE, 1.0)
	if state.rng.randf() >= chance:
		return
	var damage := Balance.HUNT_DAMAGE * colonist.work_speed(task.work_type)
	task.progress = minf(task.progress + damage, task.work_required)
	if Wildlife.hurt(state, animal, damage, colonist.cell):
		TaskEffects.complete(task, state)
		state.post_message("%s caçou um(a) %s" % [colonist.display_name, animal.def.display_name.to_lower()])
		colonist.state = Colonist.State.FINISHING


## Persegue o animal: novo caminho até onde ele está agora.
func _chase(colonist: Colonist, state: WorldState, animal: Animal) -> void:
	var action := colonist.action
	action.target_cell = animal.cell
	var path := state.navigation.find_path(colonist.cell, animal.cell)
	if path.size() <= 1:
		_block_task(action, state, "sem caminho até o animal")
		_fail(colonist, state, "sem caminho até o animal")
		return
	colonist.path = path.slice(1)
	colonist.move_progress = 0.0
	colonist.state = Colonist.State.MOVING


static func _in_hunting_range(from: Vector2i, to: Vector2i) -> bool:
	return from.distance_squared_to(to) <= Balance.HUNT_RANGE_TILES * Balance.HUNT_RANGE_TILES


## Levar material: pega na origem (etapa 0) e entrega na obra ou bancada (etapa 1).
func _deliver(colonist: Colonist, state: WorldState) -> void:
	var action := colonist.action
	if action.phase == 0:
		var taken := 0
		if action.item_source == Action.ItemSource.CONTAINER:
			var container: StorageContainer = state.containers.get(action.target_id)
			taken = container.take(colonist.id) if container else 0
		else:
			var stack: ItemStack = state.stacks.get(action.target_id)
			if stack:
				taken = stack.take(colonist.id)
				state.remove_stack_if_empty(stack)
		if taken <= 0:
			_fail(colonist, state, "o material não estava mais lá")
			return
		colonist.carry(action.item_id, taken)
		var receiver: Object = state.delivery_receiver(action.destination_id)
		if receiver == null:
			_fail(colonist, state, "a obra ou a bancada não existe mais")
			return
		action.phase = 1
		action.target_cell = receiver.delivery_cell()
		action.adjacent = true
		colonist.work_ticks_since_break += 1
		_travel(colonist, action, state, [])
		return
	var destination: Object = state.delivery_receiver(action.destination_id)
	if destination == null:
		_fail(colonist, state, "a obra ou a bancada não existe mais")
		return
	var stored: int = destination.deliver(colonist.id, colonist.carrying_item, colonist.carrying_count)
	colonist.carrying_count -= stored
	if colonist.carrying_count <= 0:
		colonist.clear_carry()
	colonist.state = Colonist.State.FINISHING


func _haul(colonist: Colonist, state: WorldState) -> void:
	var action := colonist.action
	if action.phase == 0:
		var stack: ItemStack = state.stacks.get(action.target_id)
		var taken := stack.take(colonist.id) if stack else 0
		if taken <= 0:
			_fail(colonist, state, "a pilha não estava mais lá")
			return
		colonist.carry(stack.item, taken)
		state.remove_stack_if_empty(stack)
		# Pegou a parte dele: o resto da pilha fica livre para outro carregador.
		state.reservations.release(action.reservation_key, colonist.id)
		var destination: StorageContainer = state.containers.get(action.destination_id)
		if destination == null:
			_fail(colonist, state, "o contêiner de destino não existe mais")
			return
		action.phase = 1
		action.target_cell = destination.cell
		action.adjacent = true
		colonist.work_ticks_since_break += 1
		_travel(colonist, action, state, [])
		return
	var destination: StorageContainer = state.containers.get(action.destination_id)
	if destination == null:
		_fail(colonist, state, "o contêiner de destino não existe mais")
		return
	var stored := destination.deposit(colonist.id, colonist.carrying_item, colonist.carrying_count)
	colonist.carrying_count -= stored
	if colonist.carrying_count <= 0:
		colonist.clear_carry()
	colonist.state = Colonist.State.FINISHING


func _finish(colonist: Colonist, state: WorldState) -> void:
	var action := colonist.action
	if action == colonist.direct_order:
		colonist.direct_order = null
	if action.kind == Action.Kind.BREAK:
		colonist.work_ticks_since_break = 0
	_close(colonist, state, "concluída")
	colonist.force_think = true


func _fail(colonist: Colonist, state: WorldState, why: String) -> void:
	if colonist.action == colonist.direct_order:
		colonist.direct_order = null
		state.post_message("%s não pôde cumprir a ordem: %s" % [colonist.display_name, why])
	_close(colonist, state, "falhou: %s" % why)


func _block_task(action: Action, state: WorldState, why: String) -> void:
	if action == null or action.task_id == 0:
		return
	var task := state.task_board.get_task(action.task_id)
	if task:
		task.block(state.clock.tick, why)


func _close(colonist: Colonist, state: WorldState, outcome: String) -> void:
	var action := colonist.action
	if action and action.record and action.record.outcome.is_empty():
		action.record.outcome = outcome
	if colonist.carrying_count > 0:
		state.drop_items(colonist.cell, colonist.carrying_item, colonist.carrying_count)
		colonist.clear_carry()
	colonist.action = null
	colonist.path.clear()
	colonist.move_progress = 0.0
	colonist.state = Colonist.State.IDLE
	# Toda reserva do colono pertence à ação atual: soltar tudo evita reservas presas.
	state.release_all_for(colonist.id)
