class_name ContainerDef
extends Resource
## Definição de um tipo de contêiner (GDD: Tipos de contêiner). Um .tres por tipo em res://resources/containers/.
## O id é o mesmo da StructureDef que o constrói.

@export var id: StringName
@export var display_name: String
@export var slot_count: int
## Tiles ocupados (pátio de materiais: 2×2).
@export var footprint: Vector2i = Vector2i.ONE
## Espaços grandes (GDD: pátio de materiais guarda até 300 de material por espaço).
@export var large_slots: bool = false
## Categorias de ItemDef aceitas; vazio = aceita tudo.
@export var accepted_categories: Array[int] = []
## Id da arte no AssetCatalog.
@export var asset: String


func accepts(definition: ItemDef) -> bool:
	return accepted_categories.is_empty() or accepted_categories.has(definition.category)


func stack_size_for(definition: ItemDef) -> int:
	if large_slots and definition.category == ItemDef.Category.MATERIAL:
		return Balance.LARGE_SLOT_STACK
	return definition.stack_size
