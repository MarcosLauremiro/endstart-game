class_name Wildlife
extends RefCounted
## Comportamento dos animais (GDD: Fauna). Presas pastam e fogem de colonos e predadores por perto;
## o predador caça presas de tempos em tempos. Abaixo da população da espécie, outros animais
## migram pelas bordas do mapa, uma vez por dia. Animais pensam escalonados, como os colonos.
## No MVP o predador não ataca colonos: a ameaça do MVP são só os saqueadores (GDD).

const _NO_CELL := Vector2i(-1, -1)
const _SPAWN_ATTEMPTS := 200
const _DIAGONAL_LENGTH := 1.41421356


## Animais iniciais, longe do ponto de chegada dos colonos.
static func populate(state: WorldState) -> void:
	for def in Defs.animals():
		for _i in def.population:
			var cell := _random_wild_cell(state)
			if cell != _NO_CELL:
				add_animal(state, def, cell)


static func add_animal(state: WorldState, def: AnimalDef, cell: Vector2i) -> Animal:
	var animal := Animal.new(state.next_id(), def, cell)
	state.animals[animal.id] = animal
	if state.auto_hunt.get(def.id, false):
		designate_hunt(state, animal)
	return animal


static func tick(state: WorldState) -> void:
	var tick_now := state.clock.tick
	var new_hour := tick_now % Balance.TICKS_PER_HOUR == 0
	for animal in state.animals.values():
		if not state.animals.has(animal.id):
			continue
		if new_hour:
			animal.hours_since_meal += 1
		if (tick_now + animal.think_offset) % Balance.ANIMAL_THINK_TICKS == 0:
			_think(state, animal)
		_move(state, animal)
	if tick_now % Balance.TICKS_PER_DAY == 0:
		_migrate(state)


## Marca o animal para caça. Predadores não: criaturas ficam fora do combate do MVP.
static func designate_hunt(state: WorldState, animal: Animal) -> bool:
	if animal.def.is_predator or state.task_board.hunt_for(animal.id):
		return false
	var task := state.task_board.create(Task.Kind.HUNT, animal.cell, animal.id, animal.def.max_health, state.clock.tick)
	task.title = "Caçar %s #%d" % [animal.def.display_name.to_lower(), animal.id]
	task.progress = animal.def.max_health - animal.health
	return true


## Caça automática da espécie: marca os que já estão no mapa e os que chegarem.
static func set_auto_hunt(state: WorldState, species: StringName, enabled: bool) -> void:
	state.auto_hunt[species] = enabled
	if not enabled:
		return
	for animal in state.animals.values():
		if animal.def.id == species:
			designate_hunt(state, animal)


## Ferido por um caçador: perde vida e foge (presas). Devolve se morreu.
static func hurt(state: WorldState, animal: Animal, damage: float, from_cell: Vector2i) -> bool:
	animal.health = maxf(animal.health - damage, 0.0)
	if not animal.is_alive():
		return true
	if not animal.def.is_predator:
		_flee_from(state, animal, from_cell)
	return false


## Tira o animal do mapa. Morto pela caça deixa a carcaça; comido por um predador, nada.
static func kill(state: WorldState, animal: Animal, leaves_carcass: bool) -> void:
	state.animals.erase(animal.id)
	var hunt := state.task_board.hunt_for(animal.id)
	if hunt:
		state.task_board.remove(hunt, Task.Status.DONE if leaves_carcass else Task.Status.CANCELLED)
	if leaves_carcass and animal.def.carcass_item != &"":
		state.drop_items(animal.cell, animal.def.carcass_item, 1)
		state.research.record_first("caça:%s" % animal.def.id)
		var branch := state.research.fire_trigger(&"first_hunt")
		if not branch.is_empty():
			state.post_message("Primeira caça! Novo ramo de pesquisa: %s" % branch)


static func _think(state: WorldState, animal: Animal) -> void:
	match animal.mode:
		Animal.Mode.EAT:
			animal.timer -= Balance.ANIMAL_THINK_TICKS
			if animal.timer > 0:
				return
			animal.mode = Animal.Mode.WANDER
		Animal.Mode.FLEE:
			animal.timer -= Balance.ANIMAL_THINK_TICKS
			if animal.timer > 0 and not animal.path.is_empty():
				return
			animal.mode = Animal.Mode.WANDER
	if animal.def.is_predator:
		if animal.mode == Animal.Mode.HUNT or animal.hours_since_meal >= animal.def.hunt_interval_hours:
			if _hunt(state, animal):
				return
	else:
		var threat := _nearest_threat(state, animal)
		if threat != _NO_CELL:
			_flee_from(state, animal, threat)
			return
	if animal.path.is_empty() and state.rng.randf() < Balance.ANIMAL_WANDER_CHANCE:
		_wander(state, animal)


## Colono ou predador mais perto dentro do raio de fuga, ou _NO_CELL.
static func _nearest_threat(state: WorldState, animal: Animal) -> Vector2i:
	var radius := animal.def.flee_radius
	var best := _NO_CELL
	var best_distance := radius * radius
	for colonist in state.colonists:
		var distance := float(colonist.cell.distance_squared_to(animal.cell))
		if distance <= best_distance:
			best = colonist.cell
			best_distance = distance
	for other in state.animals.values():
		if other.def.is_predator and other.def.prey.has(animal.def.id):
			var distance := float(other.cell.distance_squared_to(animal.cell))
			if distance <= best_distance:
				best = other.cell
				best_distance = distance
	return best


static func _flee_from(state: WorldState, animal: Animal, threat: Vector2i) -> void:
	var away := Vector2(animal.cell - threat)
	if away == Vector2.ZERO:
		away = Vector2.RIGHT.rotated(state.rng.randf() * TAU)
	var target := animal.cell + Vector2i((away.normalized() * animal.def.flee_distance).round())
	target = target.clamp(Vector2i.ZERO, state.world.size - Vector2i.ONE)
	if not state.navigation.is_walkable(target):
		target = state.nearest_walkable(target)
	_set_path(state, animal, target)
	animal.mode = Animal.Mode.FLEE
	animal.timer = Balance.ANIMAL_FLEE_TICKS


## Persegue a presa escolhida; ao alcançá-la, mata e come. Devolve se está caçando.
static func _hunt(state: WorldState, animal: Animal) -> bool:
	var prey: Animal = state.animals.get(animal.target_id)
	if prey == null:
		prey = _nearest_prey(state, animal)
		if prey == null:
			animal.mode = Animal.Mode.WANDER
			animal.target_id = 0
			return false
		animal.target_id = prey.id
	animal.mode = Animal.Mode.HUNT
	if Vector2(animal.cell).distance_to(Vector2(prey.cell)) <= Balance.PREDATOR_KILL_DISTANCE:
		kill(state, prey, false)
		animal.mode = Animal.Mode.EAT
		animal.timer = Balance.PREDATOR_EAT_TICKS
		animal.hours_since_meal = 0
		animal.target_id = 0
		animal.path.clear()
		return true
	if not _set_path(state, animal, prey.cell):
		animal.mode = Animal.Mode.WANDER
		animal.target_id = 0
		return false
	return true


static func _nearest_prey(state: WorldState, animal: Animal) -> Animal:
	var best: Animal
	var best_distance := float(Balance.PREDATOR_SIGHT_RADIUS * Balance.PREDATOR_SIGHT_RADIUS)
	for other in state.animals.values():
		if not animal.def.prey.has(other.def.id):
			continue
		var distance := float(other.cell.distance_squared_to(animal.cell))
		if distance <= best_distance:
			best = other
			best_distance = distance
	return best


static func _wander(state: WorldState, animal: Animal) -> void:
	var radius := animal.def.wander_radius
	var target := animal.cell + Vector2i(state.rng.randi_range(-radius, radius), state.rng.randi_range(-radius, radius))
	if state.navigation.is_walkable(target):
		_set_path(state, animal, target)


static func _set_path(state: WorldState, animal: Animal, target: Vector2i) -> bool:
	var path := state.navigation.find_path(animal.cell, target)
	if path.size() <= 1:
		return false
	animal.path = path.slice(1)
	animal.move_progress = 0.0
	return true


static func _move(state: WorldState, animal: Animal) -> void:
	if animal.path.is_empty():
		return
	var next := animal.path[0]
	if not state.navigation.is_walkable(next):
		animal.path.clear()
		animal.move_progress = 0.0
		return
	var step := next - animal.cell
	var length := _DIAGONAL_LENGTH if step.x != 0 and step.y != 0 else 1.0
	animal.move_progress += animal.def.move_per_tick() * state.navigation.speed_factor(next) / length
	if animal.move_progress < 1.0:
		return
	animal.move_progress = 0.0
	animal.cell = next
	animal.path.remove_at(0)
	var hunt := state.task_board.hunt_for(animal.id)
	if hunt:
		hunt.cell = animal.cell


static func _migrate(state: WorldState) -> void:
	var counts := {}
	for animal in state.animals.values():
		counts[animal.def.id] = counts.get(animal.def.id, 0) + 1
	for def in Defs.animals():
		if counts.get(def.id, 0) >= def.population:
			continue
		var cell := _random_edge_cell(state)
		if cell != _NO_CELL:
			add_animal(state, def, cell)


static func _random_wild_cell(state: WorldState) -> Vector2i:
	var center := state.world.size / 2
	var min_distance := Balance.ANIMAL_SPAWN_MIN_DISTANCE * Balance.ANIMAL_SPAWN_MIN_DISTANCE
	for _i in _SPAWN_ATTEMPTS:
		var cell := Vector2i(state.rng.randi_range(0, state.world.size.x - 1), state.rng.randi_range(0, state.world.size.y - 1))
		if cell.distance_squared_to(center) >= min_distance and _is_dry_walkable(state, cell):
			return cell
	return _NO_CELL


static func _random_edge_cell(state: WorldState) -> Vector2i:
	var size := state.world.size
	for _i in _SPAWN_ATTEMPTS:
		var along := state.rng.randi_range(0, size.x - 1)
		var cell: Vector2i
		match state.rng.randi_range(0, 3):
			0:
				cell = Vector2i(along, 0)
			1:
				cell = Vector2i(along, size.y - 1)
			2:
				cell = Vector2i(0, along % size.y)
			_:
				cell = Vector2i(size.x - 1, along % size.y)
		if _is_dry_walkable(state, cell):
			return cell
	return _NO_CELL


static func _is_dry_walkable(state: WorldState, cell: Vector2i) -> bool:
	return state.navigation.is_walkable(cell) and state.world.get_terrain(cell) != Terrain.Kind.SHALLOW_WATER
