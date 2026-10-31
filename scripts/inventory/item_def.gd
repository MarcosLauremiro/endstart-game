class_name ItemDef
extends Resource
## Definição de um tipo de item (dados do GDD: pesos, pilhas e valores).
## Um arquivo .tres por item em res://resources/items/; adicionar item não exige código.

enum Category { MATERIAL, FOOD, TOOL, WEAPON, ARTIFACT }

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
## Id do ícone no AssetCatalog.
@export var icon: String


func is_edible() -> bool:
	return nutrition > 0.0


func has_tag(tag: StringName) -> bool:
	return tags.has(tag)
