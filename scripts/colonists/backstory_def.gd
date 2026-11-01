class_name BackstoryDef
extends Resource
## Infância ou vida adulta (GDD: Histórias). Um .tres por história em res://resources/backstories/.
## No MVP só contam os bônus nas 6 habilidades do MVP e na Força; incapacidades e fobias ficam
## para depois do MVP.

enum Stage { CHILDHOOD, ADULTHOOD }

@export var id: StringName
@export var display_name: String
@export var stage: Stage = Stage.CHILDHOOD
## Chave da habilidade (Skills.KEYS) → bônus de nível.
@export var skill_bonus: Dictionary = {}
@export var strength_bonus: int = 0
