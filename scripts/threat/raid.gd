class_name Raid
extends RefCounted
## Um ataque, do aviso ao fim: pontos, grupo, lado de chegada e o que aconteceu.

enum Phase { WARNED, ACTIVE, OVER }
const SIDE_NAMES := ["norte", "sul", "oeste", "leste"]
## "Fumaça no horizonte ao sul".
const SIDE_TOWARDS := ["ao norte", "ao sul", "a oeste", "a leste"]

var id: int
var phase: Phase = Phase.WARNED
var points: int
## Tipos dos saqueadores comprados com os pontos (Raider.KINDS).
var group: Array[StringName] = []
## 0 norte, 1 sul, 2 oeste, 3 leste.
var side: int
## Célula da borda por onde chegam e por onde fogem.
var entry: Vector2i
## Onde a fumaça do aviso aparece.
var smoke_cell: Vector2i
var warned_tick: int
var arrival_tick: int
var started_tick: int = 0
var colonists_at_start: int = 0
var colonists_lost: int = 0
var raiders_killed: int = 0
var raiders_fled: int = 0
var raiders_looted: int = 0
var retreating: bool = false


func side_name() -> String:
	return SIDE_NAMES[side]


func side_towards() -> String:
	return SIDE_TOWARDS[side]


func cost() -> int:
	var total := 0
	for raider_kind in group:
		total += Raider.cost_of(raider_kind)
	return total


## Quantos já saíram do combate: mortos, fugidos feridos ou que já saquearam.
func spent() -> int:
	return raiders_killed + raiders_fled + raiders_looted
