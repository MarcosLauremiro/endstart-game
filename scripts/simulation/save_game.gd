class_name SaveGame
extends RefCounted
## Salvar e carregar (GDD: Salvamento livre; o estado da simulação é serializado inteiro, nada
## visual é salvo). Percorre o grafo de objetos do WorldState pelas variáveis de script, então um
## campo novo em qualquer classe entra no arquivo sem código extra. Cada objeto vira um registro
## {script, props}; referências viram {"__ref": índice} (objetos compartilhados, como o contêiner
## que está em containers e em containers_by_cell, continuam sendo um só). Definições (.tres)
## viram o caminho do arquivo; o gerador aleatório, semente e estado.
## Ganchos opcionais nas classes: save_skip() lista campos que não vão para o arquivo e
## after_load() refaz o que eles guardavam (NavigationGrid refaz o AStarGrid2D).
## Para carregar, toda classe salva precisa poder ser criada sem argumentos.

const VERSION := 1
const DIR := "user://saves/"
const EXTENSION := ".save"
const AUTOSAVE_NAME := "automatico"

const _REF := "__ref"
const _RES := "__res"
const _RNG := "__rng"

## id da instância → índice do registro (durante o salvamento)
var _indices := {}
var _records: Array = []
## Registros → objetos (durante o carregamento)
var _objects: Array = []


## Estado inteiro como dados simples (dicionários, arrays, números, vetores). Dois snapshots
## iguais = dois estados iguais.
static func snapshot(state: WorldState) -> Dictionary:
	var writer := SaveGame.new()
	var root: Variant = writer._encode(state)
	return {"root": root, "objects": writer._records}


static func restore(data: Dictionary) -> WorldState:
	var reader := SaveGame.new()
	return reader._restore(data)


## Grava a partida em user://saves/<nome>.save. Devolve OK ou o erro.
static func save(simulation: Simulation, save_name: String) -> Error:
	DirAccess.make_dir_recursive_absolute(DIR)
	var file := FileAccess.open_compressed(path_of(save_name), FileAccess.WRITE, FileAccess.COMPRESSION_ZSTD)
	if file == null:
		return FileAccess.get_open_error()
	file.store_var({"header": header(simulation), "state": snapshot(simulation.state)})
	file.close()
	return OK


## Lê a partida salva; null se o arquivo não existe, é de outra versão ou está corrompido.
static func load_simulation(save_name: String) -> Simulation:
	var data := _read(path_of(save_name))
	if data.is_empty() or data["header"].get("version", 0) != VERSION:
		return null
	return Simulation.from_state(restore(data["state"]))


## Resumo para a lista de partidas: versão, dia, hora, colonos, seed e quando foi salvo.
static func header(simulation: Simulation) -> Dictionary:
	var clock := simulation.clock
	return {
		"version": VERSION,
		"seed": simulation.world_seed,
		"tick": clock.tick,
		"day": clock.day(),
		"hour": clock.hour(),
		"colonists": simulation.state.colonists.size(),
		"saved_at": Time.get_datetime_string_from_system(false, true),
	}


## Partidas salvas, a mais recente primeiro: [{"name": String, "header": Dictionary}].
static func list_saves() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var dir := DirAccess.open(DIR)
	if dir == null:
		return result
	for file_name in dir.get_files():
		if not file_name.ends_with(EXTENSION):
			continue
		var save_name := file_name.trim_suffix(EXTENSION)
		var data := _read(path_of(save_name))
		if not data.is_empty():
			result.append({"name": save_name, "header": data["header"],
				"modified": FileAccess.get_modified_time(path_of(save_name))})
	result.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a["modified"] > b["modified"])
	return result


static func delete_save(save_name: String) -> Error:
	return DirAccess.remove_absolute(path_of(save_name))


static func path_of(save_name: String) -> String:
	return DIR + save_name + EXTENSION


## Nome livre de caracteres que não cabem num nome de arquivo.
static func clean_name(text: String) -> String:
	var cleaned := text.strip_edges().validate_filename()
	return cleaned if not cleaned.is_empty() else "partida"


static func _read(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open_compressed(path, FileAccess.READ, FileAccess.COMPRESSION_ZSTD)
	if file == null:
		return {}
	var data: Variant = file.get_var()
	file.close()
	if typeof(data) != TYPE_DICTIONARY or not data.has("header") or not data.has("state"):
		return {}
	return data


func _encode(value: Variant) -> Variant:
	match typeof(value):
		TYPE_OBJECT:
			if value == null:
				return null
			if value is Resource:
				assert(not value.resource_path.is_empty(), "Recurso sem arquivo não pode ser salvo")
				return {_RES: value.resource_path}
			if value is RandomNumberGenerator:
				return {_RNG: [value.seed, value.state]}
			assert(value.get_script() != null, "Objeto sem script não pode ser salvo: %s" % value)
			return {_REF: _index_of(value)}
		TYPE_ARRAY:
			var items: Array = []
			for item: Variant in value:
				items.append(_encode(item))
			return items
		TYPE_DICTIONARY:
			var entries := {}
			for key: Variant in value:
				entries[_encode(key)] = _encode(value[key])
			return entries
		TYPE_CALLABLE, TYPE_SIGNAL:
			assert(false, "Callable e Signal não podem ser salvos")
			return null
	return value


func _index_of(object: Object) -> int:
	var instance := object.get_instance_id()
	if _indices.has(instance):
		return _indices[instance]
	var index := _records.size()
	_indices[instance] = index
	_records.append(null)
	var skip: PackedStringArray = object.call("save_skip") if object.has_method("save_skip") else PackedStringArray()
	var props := {}
	for property in object.get_property_list():
		var property_name: String = property["name"]
		if property["usage"] & PROPERTY_USAGE_SCRIPT_VARIABLE and not skip.has(property_name):
			props[property_name] = _encode(object.get(property_name))
	_records[index] = {"script": (object.get_script() as Script).resource_path, "props": props}
	return index


func _restore(data: Dictionary) -> WorldState:
	var records: Array = data["objects"]
	for record: Dictionary in records:
		var script: GDScript = load(record["script"])
		_objects.append(script.new())
	for index in records.size():
		var object: Object = _objects[index]
		var props: Dictionary = records[index]["props"]
		for property_name: String in props:
			_assign(object, property_name, _decode(props[property_name]))
	for object: Object in _objects:
		if object.has_method("after_load"):
			object.call("after_load")
	return _decode(data["root"])


func _decode(value: Variant) -> Variant:
	match typeof(value):
		TYPE_ARRAY:
			var items: Array = []
			for item: Variant in value:
				items.append(_decode(item))
			return items
		TYPE_DICTIONARY:
			if value.size() == 1:
				if value.has(_REF):
					return _objects[value[_REF]]
				if value.has(_RES):
					return load(value[_RES])
				if value.has(_RNG):
					var rng := RandomNumberGenerator.new()
					rng.seed = value[_RNG][0]
					rng.state = value[_RNG][1]
					return rng
			var entries := {}
			for key: Variant in value:
				entries[_decode(key)] = _decode(value[key])
			return entries
	return value


## Arrays e dicionários tipados recebem os itens no próprio tipo do campo.
func _assign(object: Object, property_name: String, value: Variant) -> void:
	var current: Variant = object.get(property_name)
	if current is Array and (current as Array).is_typed() and value is Array:
		var typed := Array([], current.get_typed_builtin(), current.get_typed_class_name(), current.get_typed_script())
		typed.assign(value)
		object.set(property_name, typed)
	elif current is Dictionary and (current as Dictionary).is_typed() and value is Dictionary:
		var typed_dict := Dictionary({}, current.get_typed_key_builtin(), current.get_typed_key_class_name(), current.get_typed_key_script(),
			current.get_typed_value_builtin(), current.get_typed_value_class_name(), current.get_typed_value_script())
		typed_dict.assign(value)
		object.set(property_name, typed_dict)
	else:
		object.set(property_name, value)
