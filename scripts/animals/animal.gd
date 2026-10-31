class_name Animal
extends RefCounted
## Um animal no mapa. Só dados: o comportamento está em Wildlife.

enum Mode { WANDER, FLEE, HUNT, EAT }
const MODE_NAMES := {
	Mode.WANDER: "pastando",
	Mode.FLEE: "fugindo",
	Mode.HUNT: "caçando",
	Mode.EAT: "comendo a presa",
}

var id: int
var def: AnimalDef
var cell: Vector2i
var path: Array[Vector2i] = []
var move_progress: float = 0.0
var health: float
var mode: Mode = Mode.WANDER
## Ticks restantes do modo atual (fuga, refeição).
var timer: int = 0
## Presa perseguida (predador).
var target_id: int = 0
var hours_since_meal: int = 0
var think_offset: int = 0


func _init(new_id: int, new_def: AnimalDef, new_cell: Vector2i) -> void:
	id = new_id
	def = new_def
	cell = new_cell
	health = def.max_health
	think_offset = new_id % Balance.ANIMAL_THINK_TICKS


func next_cell() -> Vector2i:
	return path[0] if not path.is_empty() else cell


func is_alive() -> bool:
	return health > 0.0


func mode_name() -> String:
	return MODE_NAMES[mode]
