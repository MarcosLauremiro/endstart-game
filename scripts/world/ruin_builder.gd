class_name RuinBuilder
extends RefCounted
## Coloca a ruína do MVP no mapa: um prédio de 13×5 com 3 salas de 3×3 em fila, porta de entrada
## na primeira sala e portas internas entre elas. O artefato fica na última sala; as outras guardam
## sucata. Fica longe da chegada dos colonos, em terra firme, sempre no mesmo lugar para a mesma seed.

const SIZE := Vector2i(13, 5)
## Colunas das paredes internas e da entrada (relativas à origem).
const _INNER_WALLS := [4, 8]
const _ENTRANCE := Vector2i(2, 4)
const _ROOM_NAMES := ["Antessala", "Galeria", "Câmara"]
const _ATTEMPTS := 400


static func place(state: WorldState) -> Ruin:
	var origin := _find_site(state)
	if origin == Vector2i(-1, -1):
		push_warning("Sem lugar para a ruína neste mapa")
		return null
	_clear_site(state, origin)
	var ruin := Ruin.new()
	ruin.id = state.next_id()
	ruin.origin = origin
	for y in SIZE.y:
		for x in SIZE.x:
			var cell := origin + Vector2i(x, y)
			var local := Vector2i(x, y)
			var on_edge := x == 0 or y == 0 or x == SIZE.x - 1 or y == SIZE.y - 1
			var inner_wall := _INNER_WALLS.has(x)
			var door := local == _ENTRANCE or (inner_wall and y == SIZE.y / 2)
			if door:
				_build(state, &"ruin_door", cell)
			elif on_edge or inner_wall:
				_build(state, &"ruin_wall", cell)
			if door or not (on_edge or inner_wall):
				_build(state, &"ruin_floor", cell)
	var left := 1
	for index in _ROOM_NAMES.size():
		var cells: Array[Vector2i] = []
		for y in range(1, SIZE.y - 1):
			for x in range(left, left + 3):
				cells.append(origin + Vector2i(x, y))
		var last := index == _ROOM_NAMES.size() - 1
		var loot := {} if last else {&"scrap": Balance.RUIN_ROOM_SCRAP}
		ruin.rooms.append({"id": state.next_id(), "name": _ROOM_NAMES[index], "cells": cells,
			"center": origin + Vector2i(left + 1, SIZE.y / 2), "investigated": false, "artifact": last, "loot": loot})
		left += 4
	state.ruins.append(ruin)
	return ruin


static func _build(state: WorldState, def_id: StringName, cell: Vector2i) -> void:
	state.add_structure(Structure.new(state.next_id(), Defs.structure(def_id), cell))


## Área de terra firme (grama, solo ou grama alta) com uma volta livre, entre 20 e 40 tiles da chegada.
static func _find_site(state: WorldState) -> Vector2i:
	var center := state.world.size / 2
	for _i in _ATTEMPTS:
		var angle := state.rng.randf() * TAU
		var distance := state.rng.randf_range(Balance.RUIN_MIN_DISTANCE, Balance.RUIN_MAX_DISTANCE)
		var origin := center + Vector2i(Vector2(cos(angle), sin(angle)) * distance) - SIZE / 2
		if _site_is_free(state, origin):
			return origin
	return Vector2i(-1, -1)


static func _site_is_free(state: WorldState, origin: Vector2i) -> bool:
	for y in range(-1, SIZE.y + 1):
		for x in range(-1, SIZE.x + 1):
			var cell := origin + Vector2i(x, y)
			if not state.world.contains(cell):
				return false
			var kind := state.world.get_terrain(cell)
			if kind != Terrain.Kind.GRASS and kind != Terrain.Kind.DIRT and kind != Terrain.Kind.TALL_GRASS:
				return false
			if state.containers_by_cell.has(cell) or state.buildings_by_cell.has(cell) or state.colonist_at(cell):
				return false
	return true


static func _clear_site(state: WorldState, origin: Vector2i) -> void:
	for y in range(-1, SIZE.y + 1):
		for x in range(-1, SIZE.x + 1):
			var cell := origin + Vector2i(x, y)
			if state.trees_by_cell.has(cell):
				state.remove_tree(state.trees_by_cell[cell])
			if state.bushes_by_cell.has(cell):
				state.remove_bush(state.bushes_by_cell[cell])
			if state.fiber_plants_by_cell.has(cell):
				state.remove_fiber_plant(state.fiber_plants_by_cell[cell])
			if state.stumps_by_cell.has(cell):
				state.remove_stump(state.stumps_by_cell[cell])
