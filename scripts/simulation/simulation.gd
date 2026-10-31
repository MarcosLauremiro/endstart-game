class_name Simulation
extends RefCounted
## Orquestra a partida: avança os ticks, atualiza necessidades, faz os colonos pensarem
## (escalonados), executa as ações e mantém as reservas saudáveis. Recebe os comandos do jogador.
## Não conhece cena, câmera ou interface.

signal ticked(tick: int)
signal message_posted(text: String)

var state: WorldState
## Atalhos para o estado, usados pela apresentação.
var world_seed: int
var world: WorldData
var clock: GameClock

var _brain := ColonistBrain.new()
var _runner := ActionRunner.new()


func _init(new_world_seed: int, colonist_count: int = Balance.STARTING_COLONISTS) -> void:
	world_seed = new_world_seed
	state = WorldState.new(WorldGenerator.generate(world_seed, Balance.MAP_SIZE), world_seed)
	world = state.world
	clock = state.clock
	# Conexão direta ao sinal, sem lambda: uma lambda guardaria a Simulation dentro do estado (ciclo).
	state.message_posted.connect(message_posted.emit)
	WorldPopulator.place_berry_bushes(state)
	WorldPopulator.place_trees(state)
	WorldPopulator.place_fiber_plants(state)
	var taken_names: Array[String] = []
	for cell in WorldPopulator.spawn_cells(state, colonist_count):
		var colonist := ColonistFactory.create(state.next_id(), cell, state.rng, taken_names)
		taken_names.append(colonist.display_name)
		state.colonists.append(colonist)
	WorldPopulator.place_starting_supplies(state, colonist_count)
	Wildlife.populate(state)
	# Regiões de navegação prontas antes do primeiro tick, não durante o jogo.
	state.navigation.prepare()


## Executa os ticks devidos para o tempo real decorrido neste quadro.
func advance(delta_seconds: float) -> void:
	var due := clock.advance(delta_seconds)
	for _i in due:
		step()


## Um tick de simulação. Público para testes e cenários sem interface.
func step() -> void:
	clock.register_tick()
	var tick := clock.tick
	if tick % Balance.TICKS_PER_HOUR == 0:
		state.grow_plants_hour()
		Farming.grow_hour(state)
	if tick % Balance.THINK_INTERVAL_TICKS == 0:
		_expire_stale_reservations()
		_release_orphan_reservations()
	for colonist in state.colonists:
		colonist.needs.tick(colonist.is_sleeping(), colonist.is_sleeping_in_bed())
		if colonist.force_think or (tick + colonist.think_offset) % Balance.THINK_INTERVAL_TICKS == 0:
			_think(colonist)
		_runner.step(colonist, state)
	Wildlife.tick(state)
	ticked.emit(tick)


## Ordem de mover (camada 3). Retorna false, com mensagem, se o destino for impossível.
func order_move(colonist_id: int, cell: Vector2i) -> bool:
	var colonist := state.colonist_by_id(colonist_id)
	if colonist == null:
		return false
	if not state.navigation.is_walkable(cell):
		var what := "fora do mapa"
		if world.contains(cell):
			what = "ocupado" if state.containers_by_cell.has(cell) else Terrain.display_name(world.get_terrain(cell))
		state.post_message("%s não pode ir até lá: %s" % [colonist.display_name, what])
		return false
	var path := state.navigation.find_path(colonist.cell, cell)
	if path.is_empty():
		state.post_message("%s não pode ir até lá: sem caminho" % colonist.display_name)
		return false
	var order := Action.make(Action.Kind.MOVE, Action.Layer.ORDER, cell, "Ordem do jogador: ir até (%d, %d)" % [cell.x, cell.y])
	order.path = path
	_give_order(colonist, order)
	return true


## "Priorizar esta tarefa" (camada 3): o colono faz a tarefa da célula, mesmo fora das prioridades.
## Retorna false, com o motivo, se ele não puder.
func order_task(colonist_id: int, cell: Vector2i) -> bool:
	var colonist := state.colonist_by_id(colonist_id)
	var task := task_at(cell)
	if colonist == null or task == null:
		return false
	var evaluation := _brain.selector.evaluate(colonist, task, state)
	if not evaluation["ok"]:
		state.post_message("%s não pode %s: %s" % [colonist.display_name, task.label().to_lower(), evaluation["reason"]])
		return false
	var order := _brain.selector.make_action(colonist, task, evaluation, Action.Layer.ORDER, state)
	order.reason = "Ordem do jogador: priorizar %s" % task.label().to_lower()
	_give_order(colonist, order)
	return true


## A tarefa ligada à célula: designação, caça, obra, bancada, desmontagem ou transporte da pilha.
func task_at(cell: Vector2i) -> Task:
	var board := state.task_board
	var task := board.designation_at(cell)
	if task:
		return task
	for animal in state.animals_at(cell):
		if board.hunt_for(animal.id):
			return board.hunt_for(animal.id)
	for layer in [StructureDef.Layer.BUILDING, StructureDef.Layer.FLOOR]:
		var site := state.site_at(cell, layer)
		if site:
			return board.construction_for_site(site.id)
	for target in [state.buildings_by_cell.get(cell), state.containers_by_cell.get(cell), state.floors_by_cell.get(cell)]:
		if target and board.deconstruction_for(target.id):
			return board.deconstruction_for(target.id)
	var bench := state.workbench_at(cell)
	if bench:
		return board.craft_for_bench(bench.id)
	var stack: ItemStack = state.stacks_by_cell.get(cell)
	return board.haul_for_stack(stack.id) if stack else null


## Motivo de não poder construir ali, ou "" se pode.
func placement_problem(def: StructureDef, origin: Vector2i) -> String:
	return Construction.placement_problem(state, def, origin)


## Coloca plantas de construção. Devolve quantas entraram e o primeiro motivo de recusa (se houver).
func place_structures(def: StructureDef, origins: Array[Vector2i]) -> Dictionary:
	var placed := 0
	var problem := ""
	for origin in origins:
		var why := Construction.placement_problem(state, def, origin)
		if why.is_empty():
			Construction.place(state, def, origin)
			placed += 1
		elif problem.is_empty():
			problem = why
	return {"placed": placed, "problem": problem}


## Motivo real de o colono fazer ou não a tarefa (somente leitura, para a interface).
func explain_task(colonist: Colonist, task: Task) -> String:
	return _brain.selector.explain(colonist, task, state)


func designate(tool: Designations.Tool, area: Rect2i) -> int:
	return Designations.apply(state, tool, area)


## Novo pedido no fim da fila da bancada. Devolve o pedido, ou null se a receita não é dela.
func add_bill(bench_id: int, recipe_id: StringName) -> Bill:
	var bench: Workbench = state.workbenches.get(bench_id)
	var recipe := Defs.recipe(recipe_id)
	if bench == null or not recipe.workbenches.has(bench.def().id):
		push_error("Receita %s não é feita na bancada %d" % [recipe_id, bench_id])
		return null
	var bill := Bill.new(state.next_id(), recipe)
	bench.bills.append(bill)
	return bill


## Apaga o pedido. Se ele estava em andamento, os ingredientes separados voltam ao chão.
func remove_bill(bench_id: int, bill: Bill) -> void:
	var bench: Workbench = state.workbenches.get(bench_id)
	if bench == null or not bench.bills.has(bill):
		return
	if bench.job == bill:
		bench.drop_staged(state)
		var task := state.task_board.craft_for_bench(bench.id)
		if task:
			task.progress = 0.0
	bench.bills.erase(bill)


## Sobe (-1) ou desce (+1) o pedido na fila: o primeiro possível da fila é o que se faz.
func move_bill(bench_id: int, bill: Bill, offset: int) -> void:
	var bench: Workbench = state.workbenches.get(bench_id)
	if bench == null or not bench.bills.has(bill):
		return
	var index := bench.bills.find(bill)
	var target := clampi(index + offset, 0, bench.bills.size() - 1)
	bench.bills.remove_at(index)
	bench.bills.insert(target, bill)


func set_bill_mode(bill: Bill, mode: Bill.Mode, target: int) -> void:
	bill.mode = mode
	bill.target = maxi(target, 1)


func set_bill_paused(bill: Bill, paused: bool) -> void:
	bill.paused = paused


## Caça automática de uma espécie (os animais que já estão no mapa e os que chegarem).
func set_auto_hunt(species: StringName, enabled: bool) -> void:
	Wildlife.set_auto_hunt(state, species, enabled)


func set_work_priority(colonist_id: int, work_type: int, priority: int) -> void:
	var colonist := state.colonist_by_id(colonist_id)
	if colonist == null or priority < 0 or priority > Balance.MAX_WORK_PRIORITY:
		push_error("Prioridade inválida: colono %d, tipo %d, valor %d" % [colonist_id, work_type, priority])
		return
	colonist.work_priorities[work_type] = priority


func _give_order(colonist: Colonist, order: Action) -> void:
	colonist.direct_order = order
	colonist.force_think = true


func _think(colonist: Colonist) -> void:
	colonist.force_think = false
	var record := DecisionRecord.new(clock.tick)
	var candidate := _brain.decide(colonist, state, record)
	if candidate == null:
		return
	var current := colonist.action
	if current and (current.same_goal(candidate) or not current.interruptible_by(candidate)):
		return
	record.chosen = candidate.label()
	record.reason = "%s — %s" % [Action.LAYER_NAMES[candidate.layer], candidate.reason]
	candidate.record = record
	colonist.remember(record)
	_runner.start(colonist, candidate, state)


## GDD: reservas expiram se o colono ficar 30 s de jogo sem avançar.
func _expire_stale_reservations() -> void:
	for key in state.reservations.expired(clock.tick, Balance.RESERVATION_TIMEOUT_TICKS):
		var owner_id := state.reservations.owner_of(key)
		var colonist := state.colonist_by_id(owner_id)
		if colonist and _runner.keys_of(colonist).has(key):
			_runner.abort(colonist, state, "reserva expirou: 30 s sem avançar")
			colonist.force_think = true
		else:
			# Reserva solta, que não é da ação atual: só ela é liberada.
			state.reservations.release(key, owner_id)


## Rede de segurança: colono sem ação não pode segurar nada reservado.
func _release_orphan_reservations() -> void:
	for colonist in state.colonists:
		if colonist.action == null and state.has_any_reservation(colonist.id):
			push_warning("%s estava sem ação mas com reservas; liberadas." % colonist.display_name)
			state.release_all_for(colonist.id)
