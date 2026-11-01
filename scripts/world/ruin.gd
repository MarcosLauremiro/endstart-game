class_name Ruin
extends RefCounted
## Ruína pequena do mundo antigo (GDD: Exploração no MVP: 1 ruína com 3 salas e 1 artefato).
## Cada sala é investigada uma vez (tarefa de Pesquisar): rende Vestígio e o que estiver lá dentro.

var id: int
## Canto superior esquerdo do prédio.
var origin: Vector2i
## Cada sala: {"id": int, "name": String, "cells": Array[Vector2i], "center": Vector2i,
##             "investigated": bool, "artifact": bool, "loot": Dictionary}
var rooms: Array[Dictionary] = []


func room_by_id(room_id: int) -> Dictionary:
	for room in rooms:
		if room["id"] == room_id:
			return room
	return {}


func room_at(cell: Vector2i) -> Dictionary:
	for room in rooms:
		if room["cells"].has(cell):
			return room
	return {}


func investigated_count() -> int:
	var total := 0
	for room in rooms:
		if room["investigated"]:
			total += 1
	return total


func is_explored() -> bool:
	return investigated_count() == rooms.size()
