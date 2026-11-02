class_name RaiderAI
extends RefCounted
## Comportamento dos saqueadores (GDD: inimigos com objetivo). Entram pela borda e vão saquear o
## contêiner ou a pilha mais perto, fugindo com o que pegaram. No caminho, atacam quem chega perto
## ou quem os ataca, e largam quem foge para longe. Ferido demais, cada um foge; o grupo inteiro recua quando metade já
## saiu do combate (morto, fugido ou com o saque) ou depois de 12 h no mapa. Ninguém luta até o último.
## Caídos não são atacados. Pensam escalonados, como os colonos; andam e golpeiam a cada tick.

const _DIAGONAL_LENGTH := 1.41421356
## O caminho é refeito quando o alvo se afasta mais que isso do destino.
const _REPATH_DRIFT_SQUARED := 4


static func tick(state: WorldState) -> void:
	var threats := state.threats
	if threats.raiders.is_empty():
		return
	var now := state.clock.tick
	for raider: Raider in threats.raiders.values():
		if not threats.raiders.has(raider.id):
			continue
		if raider.health.is_dead():
			die(state, raider)
			continue
		if raider.attack_cooldown > 0:
			raider.attack_cooldown -= 1
		if (now + raider.think_offset) % Balance.RAIDER_THINK_TICKS == 0:
			_think(state, raider)
		if not threats.raiders.has(raider.id):
			continue
		_attack(state, raider)
		_move(state, raider)
	ThreatDirector.check_raid_over(state)


## Morto: larga a arma (fica para a colônia) e o que tinha saqueado.
static func die(state: WorldState, raider: Raider) -> void:
	state.threats.raiders.erase(raider.id)
	state.drop_items(raider.cell, raider.weapon, 1)
	if raider.loot_count > 0:
		state.drop_items(raider.cell, raider.loot_item, raider.loot_count)
	var raid := state.threats.raid
	if raid and raid.id == raider.raid_id:
		if raider.counted_as == &"fled":
			raid.raiders_fled -= 1
		elif raider.counted_as == &"looted":
			raid.raiders_looted -= 1
		raid.raiders_killed += 1
	state.post_message("%s morreu; deixou %s no chão" % [raider.display_name(), Defs.item(raider.weapon).display_name.to_lower()])


static func raider_at(state: WorldState, cell: Vector2i) -> Raider:
	for raider: Raider in state.threats.raiders.values():
		if raider.cell == cell or raider.next_cell() == cell:
			return raider
	return null


static func _think(state: WorldState, raider: Raider) -> void:
	var raid := state.threats.raid
	if raider.mode != Raider.Mode.FLEE:
		if raider.wants_to_flee():
			_flee(state, raider, &"fled")
			state.post_message("%s foge ferido" % raider.display_name())
		elif raid == null or raid.retreating \
				or state.clock.tick - raid.started_tick > Balance.RAIDER_MAX_HOURS * Balance.TICKS_PER_HOUR:
			_flee(state, raider, &"")
	match raider.mode:
		Raider.Mode.FLEE:
			_think_flee(state, raider, raid)
		_:
			var target := _attack_target(state, raider)
			if target:
				raider.mode = Raider.Mode.ATTACK
				raider.target_id = target.id
				if Combat.in_reach(raider.weapon, raider.cell, target.cell):
					_stop(raider)
				else:
					_go(state, raider, target.cell)
			else:
				_think_loot(state, raider)
	_check_retreat(state)


static func _think_flee(state: WorldState, raider: Raider, raid: Raid) -> void:
	var size := state.world.size
	var on_edge := raider.cell.x == 0 or raider.cell.y == 0 or raider.cell.x == size.x - 1 or raider.cell.y == size.y - 1
	var exit := raid.entry if raid else raider.cell
	if on_edge or raider.cell == exit:
		_escape(state, raider)
		return
	if raider.path.is_empty():
		_go(state, raider, exit)
		if raider.path.is_empty():
			_escape(state, raider)


## Sem colono à vista: vai ao contêiner ou pilha com itens mais perto e leva até 25 kg do que vale mais.
static func _think_loot(state: WorldState, raider: Raider) -> void:
	raider.mode = Raider.Mode.LOOT
	var best_cell := Vector2i(-1, -1)
	var best_container: StorageContainer
	var best_stack: ItemStack
	var best_distance := INF
	for container in state.containers.values():
		if _most_valuable(container.contents().keys(), func(item: StringName) -> int: return container.available(item)) == &"":
			continue
		var distance := float(container.cell.distance_squared_to(raider.cell))
		if distance < best_distance:
			best_distance = distance
			best_container = container
			best_stack = null
			best_cell = container.cell
	for stack in state.stacks.values():
		if stack.available() <= 0 or stack.item == raider.weapon:
			continue
		var distance := float(stack.cell.distance_squared_to(raider.cell))
		if distance < best_distance:
			best_distance = distance
			best_stack = stack
			best_container = null
			best_cell = stack.cell
	if best_container == null and best_stack == null:
		_flee(state, raider, &"")
		return
	var close := absi(best_cell.x - raider.cell.x) <= 1 and absi(best_cell.y - raider.cell.y) <= 1
	if not close:
		# Contêineres bloqueiam o tile: vão até o vizinho.
		_go(state, raider, best_cell, best_container != null)
		return
	if best_container:
		var item := _most_valuable(best_container.contents().keys(), func(it: StringName) -> int: return best_container.available(it))
		var amount := _loot_units(item, best_container.available(item))
		raider.loot_count = best_container.remove_items(item, amount)
		raider.loot_item = item
	else:
		var amount := _loot_units(best_stack.item, best_stack.available())
		best_stack.count -= amount
		raider.loot_item = best_stack.item
		raider.loot_count = amount
		state.remove_stack_if_empty(best_stack)
	state.post_message("%s pegou %d %s e foge" % [raider.display_name(), raider.loot_count, Defs.item(raider.loot_item).display_name.to_lower()])
	_flee(state, raider, &"looted")


static func _loot_units(item: StringName, available: int) -> int:
	return clampi(floori(Balance.RAIDER_LOOT_KG / maxf(Defs.item(item).weight_kg, 0.01)), 1, available)


## O item de maior valor por kg entre os que têm unidades livres.
static func _most_valuable(items: Array, available: Callable) -> StringName:
	var best: StringName = &""
	var best_value := -1.0
	for item in items:
		if available.call(item) <= 0:
			continue
		var definition := Defs.item(item)
		var value := definition.value / maxf(definition.weight_kg, 0.01)
		if value > best_value:
			best_value = value
			best = item
	return best


static func _flee(state: WorldState, raider: Raider, counted_as: StringName) -> void:
	var raid := state.threats.raid
	if raid and raid.id == raider.raid_id and raider.counted_as == &"" and counted_as != &"":
		raider.counted_as = counted_as
		if counted_as == &"fled":
			raid.raiders_fled += 1
		else:
			raid.raiders_looted += 1
	raider.mode = Raider.Mode.FLEE
	raider.target_id = 0
	_stop(raider)


## Fugiu pela borda: sai do mapa com o que levou.
static func _escape(state: WorldState, raider: Raider) -> void:
	state.threats.raiders.erase(raider.id)
	if raider.loot_count > 0:
		state.post_message("%s escapou com %d %s" % [raider.display_name(), raider.loot_count, Defs.item(raider.loot_item).display_name.to_lower()])


static func _check_retreat(state: WorldState) -> void:
	var raid := state.threats.raid
	if raid == null or raid.retreating or raid.phase != Raid.Phase.ACTIVE:
		return
	if raid.spent() * 2 >= raid.group.size():
		raid.retreating = true
		state.post_message("Os saqueadores recuam!")


## Quem atacar: o alvo atual (quem chegou perto ou o atacou) enquanto estiver de pé e a até 14
## tiles (quem foge, só até 7); senão, o colono de pé mais perto a até 7 tiles (o arqueiro: ao
## alcance do arco).
static func _attack_target(state: WorldState, raider: Raider) -> Colonist:
	var engage := maxi(Balance.RAIDER_ENGAGE_RADIUS, Combat.range_of(raider.weapon))
	var current := state.colonist_by_id(raider.target_id)
	if current and not current.health.is_downed():
		var distance := current.cell.distance_squared_to(raider.cell)
		# Quem foge só é seguido enquanto está perto: o objetivo deles é o saque.
		var fleeing := current.action != null and current.action.kind == Action.Kind.FLEE
		var limit := engage if fleeing else Balance.RAIDER_SIGHT
		if distance <= limit * limit:
			return current
	raider.target_id = 0
	return _nearest_standing_colonist(state, raider, engage)


static func _nearest_standing_colonist(state: WorldState, raider: Raider, radius: int) -> Colonist:
	var best: Colonist
	var best_distance := radius * radius
	for colonist in state.colonists:
		if colonist.health.is_downed() or colonist.health.is_dead():
			continue
		var distance := colonist.cell.distance_squared_to(raider.cell)
		if distance <= best_distance:
			best = colonist
			best_distance = distance
	return best


## Golpeia o alvo se ele está no alcance e o golpe anterior já passou.
static func _attack(state: WorldState, raider: Raider) -> void:
	if raider.mode != Raider.Mode.ATTACK or raider.attack_cooldown > 0:
		return
	var target := state.colonist_by_id(raider.target_id)
	if target == null or target.health.is_downed() or not Combat.in_reach(raider.weapon, raider.cell, target.cell):
		return
	raider.attack_cooldown = Combat.cooldown_of(raider.weapon)
	var was_downed := target.health.is_downed()
	var damage := Combat.strike(state, raider.weapon, raider.melee_level, raider.strength, raider.cell, target.cell, target.health)
	if damage <= 0.0:
		return
	target.force_think = true
	if not was_downed and target.health.is_downed() and not target.health.is_dead():
		state.post_message("%s caiu ferido! Precisa de socorro (Emergência)" % target.display_name)


static func _go(state: WorldState, raider: Raider, goal: Vector2i, adjacent: bool = false) -> void:
	if not raider.path.is_empty() and raider.path_goal.distance_squared_to(goal) <= _REPATH_DRIFT_SQUARED:
		return
	var path := state.navigation.path_to_adjacent(raider.cell, goal) if adjacent else state.navigation.find_path(raider.cell, goal)
	if path.size() <= 1:
		_stop(raider)
		return
	raider.path = path.slice(1)
	raider.path_goal = goal
	raider.move_progress = 0.0


static func _stop(raider: Raider) -> void:
	raider.path.clear()
	raider.move_progress = 0.0
	raider.path_goal = Vector2i(-1, -1)


static func _move(state: WorldState, raider: Raider) -> void:
	if raider.path.is_empty():
		return
	var next := raider.path[0]
	if not state.navigation.is_walkable(next):
		_stop(raider)
		return
	var step := next - raider.cell
	var length := _DIAGONAL_LENGTH if step.x != 0 and step.y != 0 else 1.0
	raider.move_progress += Balance.RAIDER_MOVE_TILES_PER_TICK * state.navigation.speed_factor(next) \
		* raider.health.pain_factor() / length
	if raider.move_progress < 1.0:
		return
	raider.move_progress = 0.0
	raider.cell = next
	raider.path.remove_at(0)
	# Chegou ao alcance do alvo: para e luta.
	if raider.mode == Raider.Mode.ATTACK:
		var target := state.colonist_by_id(raider.target_id)
		if target and Combat.in_reach(raider.weapon, raider.cell, target.cell):
			_stop(raider)
