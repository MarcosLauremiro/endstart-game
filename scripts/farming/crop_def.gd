class_name CropDef
extends Resource
## Planta cultivável numa zona de plantação. Um .tres por cultivo em res://resources/crops/.
## Números provisórios: o GDD não define tempo de crescimento nem colheita.

@export var id: StringName
@export var display_name: String
## Item colhido.
@export var product: StringName
@export var harvest_yield: int = 6
## Dias até amadurecer com fertilidade 100%.
@export var grow_days: float = 6.0
@export var sow_hours: float = 0.25
@export var harvest_hours: float = 0.3
## Folha de sprites com 4 fases (plantada, broto, amadurecendo, madura).
@export var asset: String


func grow_hours() -> float:
	return grow_days * Balance.HOURS_PER_DAY


func sow_ticks() -> float:
	return sow_hours * Balance.TICKS_PER_HOUR


func harvest_ticks() -> float:
	return harvest_hours * Balance.TICKS_PER_HOUR
