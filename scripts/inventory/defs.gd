class_name Defs
extends RefCounted
## Carrega as definições de conteúdo (.tres) uma vez e as entrega pelo id.

const ITEMS_DIR := "res://resources/items/"
const CONTAINERS_DIR := "res://resources/containers/"
const STRUCTURES_DIR := "res://resources/structures/"
const RECIPES_DIR := "res://resources/recipes/"
const ANIMALS_DIR := "res://resources/animals/"
const CROPS_DIR := "res://resources/crops/"

static var _items := {}
static var _containers := {}
static var _structures := {}
static var _recipes := {}
static var _animals := {}
static var _crops := {}


static func item(id: StringName) -> ItemDef:
	_ensure_loaded()
	assert(_items.has(id), "Item sem definição: %s" % id)
	return _items[id]


static func items() -> Array:
	_ensure_loaded()
	return _items.values()


static func container(id: StringName) -> ContainerDef:
	_ensure_loaded()
	assert(_containers.has(id), "Contêiner sem definição: %s" % id)
	return _containers[id]


static func structure(id: StringName) -> StructureDef:
	_ensure_loaded()
	assert(_structures.has(id), "Estrutura sem definição: %s" % id)
	return _structures[id]


## Estruturas na ordem do menu de construção (pela ordem dos nomes de arquivo).
static func structures() -> Array:
	_ensure_loaded()
	return _structures.values()


static func recipe(id: StringName) -> RecipeDef:
	_ensure_loaded()
	assert(_recipes.has(id), "Receita sem definição: %s" % id)
	return _recipes[id]


## Receitas feitas na bancada, na ordem dos arquivos.
static func recipes_for(workbench_id: StringName) -> Array[RecipeDef]:
	_ensure_loaded()
	var result: Array[RecipeDef] = []
	for definition in _recipes.values():
		if definition.workbenches.has(workbench_id):
			result.append(definition)
	return result


static func animal(id: StringName) -> AnimalDef:
	_ensure_loaded()
	assert(_animals.has(id), "Animal sem definição: %s" % id)
	return _animals[id]


static func animals() -> Array:
	_ensure_loaded()
	return _animals.values()


static func crop(id: StringName) -> CropDef:
	_ensure_loaded()
	assert(_crops.has(id), "Cultivo sem definição: %s" % id)
	return _crops[id]


static func crops() -> Array:
	_ensure_loaded()
	return _crops.values()


static func _ensure_loaded() -> void:
	if not _items.is_empty():
		return
	_items = _load_folder(ITEMS_DIR)
	_containers = _load_folder(CONTAINERS_DIR)
	_structures = _load_folder(STRUCTURES_DIR)
	_recipes = _load_folder(RECIPES_DIR)
	_animals = _load_folder(ANIMALS_DIR)
	_crops = _load_folder(CROPS_DIR)


static func _load_folder(directory: String) -> Dictionary:
	var result := {}
	for file in DirAccess.get_files_at(directory):
		# Em builds exportados os recursos aparecem com o sufixo .remap.
		var file_name := file.trim_suffix(".remap")
		if not file_name.ends_with(".tres"):
			continue
		var definition: Resource = load(directory + file_name)
		if definition == null or result.has(definition.id):
			push_error("Definição inválida ou repetida: %s" % (directory + file_name))
			continue
		result[definition.id] = definition
	return result
