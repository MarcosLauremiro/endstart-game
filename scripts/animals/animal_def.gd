class_name AnimalDef
extends Resource
## Espécie de animal (GDD: Fauna; MVP: 2 caçáveis, um pequeno e um grande, e 1 predador).
## Um .tres por espécie em res://resources/animals/. Números provisórios: o GDD não os define.

@export var id: StringName
@export var display_name: String
@export var max_health: float = 20.0
@export var move_tiles_per_second: float = 3.0
## Foge quando um colono chega a esta distância (tiles). 0 = não foge de colonos.
@export var flee_radius: float = 4.0
## Quantos tiles corre ao fugir.
@export var flee_distance: int = 8
@export var wander_radius: int = 6
## Item deixado ao morrer pela caça (carcaça para abater na cozinha).
@export var carcass_item: StringName = &""
@export var is_predator: bool = false
## Espécies que o predador caça.
@export var prey: Array[StringName] = []
## Horas entre caçadas do predador.
@export var hunt_interval_hours: int = 36
## Quantos animais da espécie o mapa sustenta; abaixo disso, outros migram pelas bordas.
@export var population: int = 6
## Id da arte no AssetCatalog.
@export var asset: String


func move_per_tick() -> float:
	return move_tiles_per_second / Balance.TICKS_PER_SECOND
