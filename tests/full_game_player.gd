class_name FullGamePlayer
extends RefCounted
## Jogador automático da partida completa (tests/full_game.gd): faz o que um jogador atento faria,
## sempre pela API da simulação, uma vez por hora de jogo. No começo: fogueira, bancada de
## produção, mesa de estudos, um baú e uma cama por colono perto da chegada; corte de árvores,
## colheita (fibra para a mesa) e mineração em volta; uma plantação. Depois: pesquisas na ordem que
## destrava a cozinha e as armas, refeições "até ter", caça automática só com a cozinha pronta
## (sem ela as carcaças não têm uso e enchem os contêineres), abate, blocos e lanças; um baú novo quando aparece o alerta "Sem lugar"
## (no máximo um por dia); convoca todos no ataque e dispensa depois.

const _RESEARCH_ORDER: Array[StringName] = [&"stone_masonry", &"cooking_bench", &"primitive_weapons", &"stone_tools", &"storage"]
const _BASE_RADIUS := 12
const _CUT_RADIUS := 10
const _ZONE_SIZE := Vector2i(6, 5)
## Colheita (frutas e fibra) marcada de novo uma vez por dia, neste raio: plantas amadurecem depois.
const _HARVEST_RADIUS := 20

var _simulation: Simulation
var _state: WorldState
var _base: Vector2i
var _started := false
## Bancadas que já ganharam pedidos: id da estrutura → true.
var _billed := {}
var _cooking_bench_placed := false
var _weapons_billed := false
var _last_chest_day := 0
var _hunting := false
var _last_harvest_day := 0


func _init(simulation: Simulation) -> void:
	_simulation = simulation
	_state = simulation.state
	_base = _state.colonists[0].cell


func act() -> void:
	if _state.clock.tick % Balance.TICKS_PER_HOUR != 0:
		return
	if not _started:
		_started = true
		_setup()
	_harvest()
	_research()
	_buildings()
	_bills()
	_storage()
	_defense()


func _setup() -> void:
	_place(&"campfire")
	_place(&"crafting_bench")
	_place(&"study_desk")
	_place(&"chest_rustic")
	for _i in _state.colonists.size():
		_place(&"bed_rustic")
	var around := Rect2i(_base - Vector2i.ONE * _CUT_RADIUS, Vector2i.ONE * (_CUT_RADIUS * 2 + 1))
	_simulation.designate(Designations.Tool.CUT, around)
	var rock := _nearest(func(cell: Vector2i) -> bool: return _state.world.get_terrain(cell) == Terrain.Kind.ROCK, 30)
	if rock != Alerts.NO_CELL:
		_simulation.designate(Designations.Tool.MINE, Rect2i(rock - Vector2i(2, 2), Vector2i(5, 5)))
	var field := _nearest(func(cell: Vector2i) -> bool: return _field_fits(cell), _BASE_RADIUS * 2)
	if field != Alerts.NO_CELL:
		_simulation.designate(Designations.Tool.GROW_ZONE, Rect2i(field, _ZONE_SIZE))


func _harvest() -> void:
	var day := _state.clock.day()
	if day != _last_harvest_day:
		_last_harvest_day = day
		_simulation.designate(Designations.Tool.HARVEST, Rect2i(_base - Vector2i.ONE * _HARVEST_RADIUS, Vector2i.ONE * (_HARVEST_RADIUS * 2 + 1)))


func _research() -> void:
	for research_id in _RESEARCH_ORDER:
		if not _state.research.is_unlocked(research_id):
			_simulation.unlock_research(research_id)


func _buildings() -> void:
	if not _cooking_bench_placed and _state.research.is_unlocked(&"cooking_bench"):
		_cooking_bench_placed = _place(&"cooking_bench")


func _bills() -> void:
	var meals := 4 * _state.colonists.size()
	for bench: Workbench in _state.workbenches.values():
		if _billed.has(bench.id):
			continue
		match bench.def().id:
			&"campfire":
				_bill(bench, &"simple_meal", Bill.Mode.UNTIL, meals)
				_billed[bench.id] = true
			&"cooking_bench":
				if not _hunting:
					_hunting = true
					for species in [&"hare", &"deer"]:
						_simulation.set_auto_hunt(species, true)
				_bill(bench, &"butcher_small", Bill.Mode.FOREVER, 0)
				_bill(bench, &"butcher_large", Bill.Mode.FOREVER, 0)
				_bill(bench, &"simple_meal", Bill.Mode.UNTIL, meals)
				_billed[bench.id] = true
			&"crafting_bench":
				if _state.research.is_unlocked(&"stone_masonry"):
					_bill(bench, &"stone_blocks", Bill.Mode.UNTIL, 10)
					_billed[bench.id] = true
	if not _weapons_billed and _state.research.is_unlocked(&"primitive_weapons"):
		for bench: Workbench in _state.workbenches.values():
			if bench.def().id == &"crafting_bench":
				_bill(bench, &"wooden_spear", Bill.Mode.UNTIL, _state.colonists.size())
				_weapons_billed = true


func _storage() -> void:
	var day := _state.clock.day()
	if day == _last_chest_day:
		return
	if Alerts.compute(_state).any(func(a: Dictionary) -> bool: return a["key"] == "no_storage"):
		if _place(&"chest_rustic"):
			_last_chest_day = day


## Saqueadores atacando: todos convocados; quando só restam os que fogem, todos dispensados (para
## socorrer os caídos).
func _defense() -> void:
	var fighting := _state.threats.raiders.values().any(func(r: Raider) -> bool: return r.mode == Raider.Mode.ATTACK)
	for colonist in _state.colonists:
		if colonist.drafted != fighting and not colonist.health.is_downed():
			_simulation.set_drafted(colonist.id, fighting)


func _bill(bench: Workbench, recipe_id: StringName, mode: Bill.Mode, target: int) -> void:
	var bill := _simulation.add_bill(bench.id, recipe_id)
	if bill:
		_simulation.set_bill_mode(bill, mode, target)


## Coloca a estrutura no lugar livre mais perto da base. Devolve se conseguiu.
func _place(structure_id: StringName) -> bool:
	var def := Defs.structure(structure_id)
	var origin := _nearest(func(cell: Vector2i) -> bool:
		return _simulation.placement_problem(def, cell).is_empty() and _clear_around(def, cell), _BASE_RADIUS)
	if origin == Alerts.NO_CELL:
		return false
	var origins: Array[Vector2i] = [origin]
	return _simulation.place_structures(def, origins)["placed"] > 0


## Deixa um tile livre em volta, para as obras não fecharem o caminho umas das outras.
func _clear_around(def: StructureDef, origin: Vector2i) -> bool:
	for y in range(origin.y - 1, origin.y + def.footprint.y + 1):
		for x in range(origin.x - 1, origin.x + def.footprint.x + 1):
			var cell := Vector2i(x, y)
			if _state.has_object_at(cell) or _state.site_at(cell, StructureDef.Layer.BUILDING) or not _state.navigation.is_walkable(cell):
				return false
	return true


func _field_fits(origin: Vector2i) -> bool:
	for y in _ZONE_SIZE.y:
		for x in _ZONE_SIZE.x:
			if not Farming.zone_problem(_state, origin + Vector2i(x, y)).is_empty():
				return false
	return true


## Célula mais perto da base (em anéis) que passa no teste.
func _nearest(test: Callable, radius: int) -> Vector2i:
	for ring in range(2, radius + 1):
		for y in range(_base.y - ring, _base.y + ring + 1):
			for x in range(_base.x - ring, _base.x + ring + 1):
				if maxi(absi(x - _base.x), absi(y - _base.y)) != ring:
					continue
				var cell := Vector2i(x, y)
				if _state.world.contains(cell) and test.call(cell):
					return cell
	return Alerts.NO_CELL
