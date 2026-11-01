class_name WorldState
extends RefCounted
## Todo o estado simulado da partida, num só lugar. A IA e o executor recebem este objeto;
## eles não conhecem Simulation nem a cena. Itens só existem em pilhas, contêineres ou nas mãos
## de um colono: as contagens da interface somam exatamente esses três lugares.

signal message_posted(text: String)

var world_seed: int
var world: WorldData
var navigation: NavigationGrid
var clock := GameClock.new()
var reservations := Reservations.new()
var task_board := TaskBoard.new()
## RNG da simulação (decisões aleatórias como vagar). Separado do RNG do mapa.
var rng := RandomNumberGenerator.new()
var colonists: Array[Colonist] = []
var bushes: Array[BerryBush] = []
var bushes_by_cell := {}
## id → WildTree, e célula → WildTree
var trees := {}
var trees_by_cell := {}
## id → Stump, e célula → Stump
var stumps := {}
var stumps_by_cell := {}
## id → FiberPlant, e célula → FiberPlant
var fiber_plants := {}
var fiber_plants_by_cell := {}
## id → StorageContainer, e célula → StorageContainer
var containers := {}
var containers_by_cell := {}
## id → ItemStack, e célula → ItemStack
var stacks := {}
var stacks_by_cell := {}
## id → ConstructionSite; célula → obra, por camada (estrutura e piso podem dividir o tile)
var sites := {}
var building_sites_by_cell := {}
var floor_sites_by_cell := {}
## id → Structure; célula → estrutura pronta, por camada
var structures := {}
var buildings_by_cell := {}
var floors_by_cell := {}
## id da estrutura → Workbench (bancadas prontas, com a fila de pedidos)
var workbenches := {}
## id → Animal
var animals := {}
## Espécies com caça automática: id da espécie → true
var auto_hunt := {}
## id → GrowZone, e célula → GrowZone
var zones := {}
var zone_by_cell := {}
## id → Crop, e célula → Crop
var crops := {}
var crops_by_cell := {}
var _next_id: int = 1


func _init(new_world: WorldData, new_world_seed: int) -> void:
	world = new_world
	world_seed = new_world_seed
	navigation = NavigationGrid.new(world)
	rng.seed = hash([new_world_seed, "simulation"])


## Ids estáveis para colonos e objetos; nunca se repetem na partida.
func next_id() -> int:
	_next_id += 1
	return _next_id - 1


func colonist_by_id(id: int) -> Colonist:
	for colonist in colonists:
		if colonist.id == id:
			return colonist
	return null


func colonist_at(cell: Vector2i) -> Colonist:
	for colonist in colonists:
		if colonist.cell == cell:
			return colonist
	return null


func colonist_name(id: int) -> String:
	var colonist := colonist_by_id(id)
	return colonist.display_name if colonist else "#%d" % id


func add_bush(cell: Vector2i) -> BerryBush:
	var bush := BerryBush.new(next_id(), cell)
	bushes.append(bush)
	bushes_by_cell[cell] = bush
	return bush


func bush_by_id(id: int) -> BerryBush:
	for bush in bushes:
		if bush.id == id:
			return bush
	return null


func bush_at(cell: Vector2i) -> BerryBush:
	return bushes_by_cell.get(cell)


func remove_bush(bush: BerryBush) -> void:
	bushes.erase(bush)
	bushes_by_cell.erase(bush.cell)


func add_tree(cell: Vector2i) -> WildTree:
	var tree := WildTree.new(next_id(), cell)
	trees[tree.id] = tree
	trees_by_cell[cell] = tree
	return tree


func remove_tree(tree: WildTree) -> void:
	trees.erase(tree.id)
	trees_by_cell.erase(tree.cell)


func add_stump(cell: Vector2i, from_adult: bool) -> Stump:
	var stump := Stump.new(next_id(), cell, from_adult)
	stumps[stump.id] = stump
	stumps_by_cell[cell] = stump
	return stump


func remove_stump(stump: Stump) -> void:
	stumps.erase(stump.id)
	stumps_by_cell.erase(stump.cell)


func add_fiber_plant(cell: Vector2i) -> FiberPlant:
	var plant := FiberPlant.new(next_id(), cell)
	fiber_plants[plant.id] = plant
	fiber_plants_by_cell[cell] = plant
	return plant


func remove_fiber_plant(plant: FiberPlant) -> void:
	fiber_plants.erase(plant.id)
	fiber_plants_by_cell.erase(plant.cell)


## Há planta, árvore, toco, cultivo, contêiner, estrutura ou planta de estrutura na célula?
## (Pisos não contam: ficam por baixo e aceitam itens e móveis.)
func has_object_at(cell: Vector2i) -> bool:
	return trees_by_cell.has(cell) or bushes_by_cell.has(cell) or fiber_plants_by_cell.has(cell) \
		or stumps_by_cell.has(cell) or crops_by_cell.has(cell) or containers_by_cell.has(cell) \
		or buildings_by_cell.has(cell) or building_sites_by_cell.has(cell)


func add_crop(crop: Crop) -> void:
	crops[crop.id] = crop
	crops_by_cell[crop.cell] = crop


func remove_crop(crop: Crop) -> void:
	crops.erase(crop.id)
	crops_by_cell.erase(crop.cell)
	var reap := task_board.designation_at(crop.cell)
	if reap and reap.kind == Task.Kind.REAP:
		task_board.remove(reap, Task.Status.CANCELLED)


func animals_at(cell: Vector2i) -> Array[Animal]:
	var result: Array[Animal] = []
	for animal in animals.values():
		if animal.cell == cell:
			result.append(animal)
	return result


## Bancada que ocupa a célula, ou null.
func workbench_at(cell: Vector2i) -> Workbench:
	var structure: Structure = buildings_by_cell.get(cell)
	return workbenches.get(structure.id) if structure else null


## Quem recebe entregas de material: obra ou bancada.
func delivery_receiver(id: int) -> Object:
	if sites.has(id):
		return sites[id]
	return workbenches.get(id)


func add_site(site: ConstructionSite) -> void:
	sites[site.id] = site
	var by_cell := _sites_by_cell(site.def.layer)
	for cell in site.cells():
		by_cell[cell] = site


func remove_site(site: ConstructionSite) -> void:
	sites.erase(site.id)
	var by_cell := _sites_by_cell(site.def.layer)
	for cell in site.cells():
		by_cell.erase(cell)


func site_at(cell: Vector2i, layer: StructureDef.Layer) -> ConstructionSite:
	return _sites_by_cell(layer).get(cell)


func add_structure(structure: Structure) -> void:
	structures[structure.id] = structure
	var is_floor := structure.def.layer == StructureDef.Layer.FLOOR
	for cell in structure.cells():
		if is_floor:
			floors_by_cell[cell] = structure
			navigation.set_floor(cell, structure.def.move_factor)
		else:
			buildings_by_cell[cell] = structure
			if structure.def.blocks_movement:
				navigation.set_blocked(cell, true)


func remove_structure(structure: Structure) -> void:
	structures.erase(structure.id)
	var is_floor := structure.def.layer == StructureDef.Layer.FLOOR
	for cell in structure.cells():
		if is_floor:
			floors_by_cell.erase(cell)
			navigation.set_floor(cell, 1.0)
		else:
			buildings_by_cell.erase(cell)
			if structure.def.blocks_movement:
				navigation.set_blocked(cell, false)


func beds() -> Array[Structure]:
	var result: Array[Structure] = []
	for structure in structures.values():
		if structure.def.is_bed:
			result.append(structure)
	return result


## Célula caminhável mais perto (para tirar alguém de onde surgiu uma parede).
func nearest_walkable(from: Vector2i) -> Vector2i:
	for radius in range(1, Balance.DROP_SEARCH_RADIUS + 1):
		for y in range(from.y - radius, from.y + radius + 1):
			for x in range(from.x - radius, from.x + radius + 1):
				var cell := Vector2i(x, y)
				if navigation.is_walkable(cell):
					return cell
	return from


## Onde pegar um item: o contêiner ou pilha mais perto (em linha reta) com unidades livres.
## Devolve {source: Action.ItemSource, id, cell, adjacent} ou vazio.
func find_item_source(item: StringName, from: Vector2i) -> Dictionary:
	var best: Dictionary = {}
	var best_distance := INF
	for container in containers.values():
		if container.available(item) > 0:
			var distance := float(container.cell.distance_squared_to(from))
			if distance < best_distance:
				best_distance = distance
				best = {"source": Action.ItemSource.CONTAINER, "id": container.id, "cell": container.cell, "adjacent": true}
	for stack in stacks.values():
		if stack.item == item and stack.available() > 0:
			var distance := float(stack.cell.distance_squared_to(from))
			if distance < best_distance:
				best_distance = distance
				best = {"source": Action.ItemSource.STACK, "id": stack.id, "cell": stack.cell, "adjacent": false}
	return best


## Unidades livres do item em contêineres e no chão.
func available_count(item: StringName) -> int:
	var total := 0
	for container in containers.values():
		total += container.available(item)
	for stack in stacks.values():
		if stack.item == item:
			total += stack.available()
	return total


## Crescimento e decomposição, uma vez por hora de jogo.
func grow_plants_hour() -> void:
	for bush in bushes:
		bush.grow_hour()
	for tree in trees.values():
		tree.grow_hour()
	for plant in fiber_plants.values():
		plant.grow_hour()
	for stump in stumps.values():
		stump.age_hour()
		if stump.has_decayed():
			remove_stump(stump)


func add_container(def_id: StringName, cell: Vector2i) -> StorageContainer:
	var container := StorageContainer.new(next_id(), Defs.container(def_id), cell)
	containers[container.id] = container
	for occupied in container.cells():
		containers_by_cell[occupied] = container
		navigation.set_blocked(occupied, true)
	return container


## Tira o contêiner do mapa. Quem largar o conteúdo é quem chama (desmontar).
func remove_container(container: StorageContainer) -> void:
	containers.erase(container.id)
	for occupied in container.cells():
		containers_by_cell.erase(occupied)
		navigation.set_blocked(occupied, false)


## Larga itens no chão perto de uma célula, juntando com pilhas iguais e respeitando o tamanho da pilha.
## Cada pilha nova ganha uma tarefa de Carregar. Nada se perde: se não houver lugar, a pilha excede o limite.
func drop_items(near: Vector2i, item: StringName, amount: int) -> void:
	var stack_size := Defs.item(item).stack_size
	var remaining := amount
	for cell in _drop_cells(near):
		if remaining <= 0:
			return
		var stack: ItemStack = stacks_by_cell.get(cell)
		if stack == null:
			var placed := mini(remaining, stack_size)
			_create_stack(cell, item, placed)
			remaining -= placed
		elif stack.item == item and stack.count < stack_size:
			var added := mini(remaining, stack_size - stack.count)
			stack.count += added
			remaining -= added
	if remaining > 0:
		push_warning("Sem lugar livre perto de %s: %d %s empilhados acima do limite" % [near, remaining, item])
		var existing: ItemStack = stacks_by_cell.get(near)
		if existing and existing.item == item:
			existing.count += remaining
		else:
			_create_stack(near, item, remaining)


func remove_stack_if_empty(stack: ItemStack) -> void:
	if stack.count > 0:
		return
	stacks.erase(stack.id)
	stacks_by_cell.erase(stack.cell)
	var haul := task_board.haul_for_stack(stack.id)
	if haul:
		task_board.remove(haul, Task.Status.DONE)


## Contêiner mais próximo (em linha reta) com espaço livre para o item.
func find_storage_for(item: StringName, from: Vector2i) -> StorageContainer:
	var best: StorageContainer
	for container in containers.values():
		if container.free_space(item) <= 0:
			continue
		if best == null or container.cell.distance_squared_to(from) < best.cell.distance_squared_to(from):
			best = container
	return best


## Total real do item: contêineres + chão + mãos e equipamento dos colonos.
func total_count(item: StringName) -> int:
	var total := 0
	for container in containers.values():
		total += container.count_of(item)
	for stack in stacks.values():
		if stack.item == item:
			total += stack.count
	for colonist in colonists:
		if colonist.carrying_item == item:
			total += colonist.carrying_count
		total += colonist.equipment.count_of(item)
	return total


## Fome total que a comida guardada pode restaurar (contêineres, chão e mãos; não conta arbustos).
func stored_nutrition() -> float:
	var total := 0.0
	for definition in Defs.items():
		if definition.is_edible():
			total += total_count(definition.id) * definition.nutrition
	return total


## Solta tudo o que o colono reservou: tarefas, arbustos, itens e espaço em contêineres.
func release_all_for(owner_id: int) -> void:
	reservations.release_all(owner_id)
	for container in containers.values():
		container.release_owner(owner_id)
	for stack in stacks.values():
		stack.release_owner(owner_id)
	for site in sites.values():
		site.release_owner(owner_id)
	for bench in workbenches.values():
		bench.release_owner(owner_id)


func has_any_reservation(owner_id: int) -> bool:
	if reservations.count_for(owner_id) > 0:
		return true
	for container in containers.values():
		if container.has_reservation_of(owner_id):
			return true
	for stack in stacks.values():
		if stack.has_reservation_of(owner_id):
			return true
	for site in sites.values():
		if site.has_reservation_of(owner_id):
			return true
	for bench in workbenches.values():
		if bench.has_reservation_of(owner_id):
			return true
	return false


func post_message(text: String) -> void:
	message_posted.emit(text)


func _create_stack(cell: Vector2i, item: StringName, amount: int) -> void:
	var stack := ItemStack.new(next_id(), cell, item, amount)
	stacks[stack.id] = stack
	stacks_by_cell[cell] = stack
	task_board.create(Task.Kind.HAUL, cell, stack.id, 0.0, clock.tick)


## Células livres para largar itens, da mais perto para a mais longe.
func _drop_cells(near: Vector2i) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	var radius := Balance.DROP_SEARCH_RADIUS
	for y in range(near.y - radius, near.y + radius + 1):
		for x in range(near.x - radius, near.x + radius + 1):
			var cell := Vector2i(x, y)
			if navigation.is_walkable(cell) and not has_object_at(cell):
				result.append(cell)
	result.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
		return a.distance_squared_to(near) < b.distance_squared_to(near))
	return result


func _sites_by_cell(layer: StructureDef.Layer) -> Dictionary:
	return floor_sites_by_cell if layer == StructureDef.Layer.FLOOR else building_sites_by_cell
