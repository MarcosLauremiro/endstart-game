class_name Raider
extends RefCounted
## Um saqueador no mapa (GDD: Ameaça do MVP, saqueadores com lança e arco). Só dados:
## o comportamento está em RaiderAI.

enum Mode { ATTACK, LOOT, FLEE }
const MODE_NAMES := {Mode.ATTACK: "atacando", Mode.LOOT: "saqueando", Mode.FLEE: "fugindo"}

## Tipos do MVP: custo em pontos (GDD), arma e arte.
const KINDS := {
	&"spear": {"name": "Saqueador com lança", "cost": 50, "weapon": &"wooden_spear", "asset": "characters/enemies/raider_spear"},
	&"archer": {"name": "Arqueiro", "cost": 65, "weapon": &"bow", "asset": "characters/enemies/raider_archer"},
}

var id: int
var kind: StringName
var raid_id: int
var cell: Vector2i
var path: Array[Vector2i] = []
var move_progress: float = 0.0
var health := Health.new()
var weapon: StringName
var melee_level: int = Balance.RAIDER_MELEE_MIN
var strength: int = Balance.ATTRIBUTE_AVERAGE
var mode: Mode = Mode.ATTACK
## Colono ou contêiner visado (0 = nenhum).
var target_id: int = 0
var attack_cooldown: int = 0
var loot_item: StringName = &""
var loot_count: int = 0
## Para onde o caminho atual leva (refeito quando o alvo se afasta disso).
var path_goal := Vector2i(-1, -1)
## Já contado como fora do combate no ataque: "fled" (ferido) ou "looted".
var counted_as: StringName = &""
var think_offset: int = 0


func _init(new_id: int, new_kind: StringName, new_cell: Vector2i) -> void:
	id = new_id
	kind = new_kind
	cell = new_cell
	weapon = KINDS[kind]["weapon"]
	think_offset = new_id % Balance.RAIDER_THINK_TICKS


func display_name() -> String:
	return KINDS[kind]["name"]


func asset() -> String:
	return KINDS[kind]["asset"]


func next_cell() -> Vector2i:
	return path[0] if not path.is_empty() else cell


## Ferido demais, foge (GDD: atacantes não lutam até o último).
func wants_to_flee() -> bool:
	return health.damage() >= Balance.RAIDER_FLEE_DAMAGE or health.blood_loss >= Balance.DOWNED_BLOOD_LOSS


func mode_name() -> String:
	return MODE_NAMES[mode]


static func cost_of(raider_kind: StringName) -> int:
	return KINDS[raider_kind]["cost"]
