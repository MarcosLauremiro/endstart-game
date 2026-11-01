class_name ItemDef
extends Resource
## Definição de um tipo de item (dados do GDD: pesos, pilhas e valores).
## Um arquivo .tres por item em res://resources/items/; adicionar item não exige código.

enum Category { MATERIAL, FOOD, TOOL, WEAPON, ARTIFACT, APPAREL }

@export var id: StringName
@export var display_name: String
@export var category: Category
@export var weight_kg: float
@export var stack_size: int
@export var value: float
## Fome restaurada por unidade; 0 = não se come.
@export var nutrition: float = 0.0
## Marcas usadas pelas receitas (ex.: "raw_food" = porção crua para cozinhar).
@export var tags: Array[StringName] = []
## Espaço de equipamento: "hand", "shirt" ou "pants" (vazio = não se equipa).
@export var equip_slot: StringName = &""
## Ferramenta na mão: chave do tipo de trabalho (WorkType.KEYS) → multiplicador de velocidade.
@export var work_bonus: Dictionary = {}
## Arma de caça na mão: alcance em tiles e dano por acerto (0 = não serve para caçar).
@export var hunt_range: int = 0
@export var hunt_damage: float = 0.0
## Id do ícone no AssetCatalog.
@export var icon: String


func is_edible() -> bool:
	return nutrition > 0.0


## Valor do item como arma de caça: dano × (1 + alcance ÷ 10). 0 = não caça.
func hunting_value() -> float:
	return hunt_damage * (1.0 + hunt_range / 10.0)


func has_tag(tag: StringName) -> bool:
	return tags.has(tag)
