class_name RecipeDef
extends Resource
## Receita de bancada (GDD: Receitas iniciais). Um .tres por receita em res://resources/recipes/.
## Cada ingrediente é um item exato ou qualquer item com uma marca ("2 porções cruas").

## Nome de cada marca de ingrediente, para a interface.
const TAG_NAMES := {
	&"raw_food": "porções cruas",
}

@export var id: StringName
@export var display_name: String
## Ids das estruturas (bancadas) onde a receita é feita.
@export var workbenches: Array[StringName] = []
## Cada ingrediente: {"item": id, "count": n} ou {"tag": marca, "count": n}.
@export var ingredients: Array[Dictionary] = []
## Produtos: id do item → quantidade.
@export var products: Dictionary = {}
@export var work_hours: float = 1.0
## Meta inicial de um pedido novo ("fazer até ter X" do produto principal).
@export var default_target: int = 10
## Pontos de Vestígio que a receita rende ao terminar (GDD: analisar artefato, 5 a 20 V).
@export var relic_points: int = 0


func work_ticks() -> float:
	return work_hours * Balance.TICKS_PER_HOUR


## O item que o "fazer até X" conta: o primeiro produto.
func main_product() -> StringName:
	return products.keys()[0]


func accepts(ingredient_index: int, item: StringName) -> bool:
	var ingredient: Dictionary = ingredients[ingredient_index]
	if ingredient.has("item"):
		return ingredient["item"] == item
	return Defs.item(item).has_tag(ingredient["tag"])


## Itens que servem para o ingrediente.
func items_for(ingredient_index: int) -> Array[StringName]:
	var result: Array[StringName] = []
	var ingredient: Dictionary = ingredients[ingredient_index]
	if ingredient.has("item"):
		result.append(ingredient["item"])
		return result
	for definition in Defs.items():
		if definition.has_tag(ingredient["tag"]):
			result.append(definition.id)
	return result


func ingredient_name(ingredient_index: int) -> String:
	var ingredient: Dictionary = ingredients[ingredient_index]
	if ingredient.has("item"):
		return Defs.item(ingredient["item"]).display_name.to_lower()
	return TAG_NAMES.get(ingredient["tag"], String(ingredient["tag"]))


func ingredients_text() -> String:
	var parts := PackedStringArray()
	for index in ingredients.size():
		parts.append("%d %s" % [ingredients[index]["count"], ingredient_name(index)])
	return ", ".join(parts)


func products_text() -> String:
	var parts := PackedStringArray()
	for item in products:
		parts.append("%d %s" % [products[item], Defs.item(item).display_name.to_lower()])
	return ", ".join(parts)

