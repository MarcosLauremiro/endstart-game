class_name MultiSelect
extends RefCounted
## Seleção por arraste (GDD: Interface > Seleção). Arrastar com o botão esquerdo seleciona os colonos
## dentro do retângulo; sem colonos, as árvores, rochas e plantas de colher (cada uma com sua marca),
## com as opções Cortar, Minerar e Colher; sem nada disso, tudo o que há na área. Opções de vários
## alvos viram uma só ("Cortar (12)"), que vale para todos. Só lê o estado; ordens passam pela simulação.

## Opções que não fazem sentido para uma área inteira.
const _SKIPPED_LABELS := ["Criar plantação aqui"]
## Opções dos recursos naturais selecionados, nesta ordem.
const RESOURCE_LABELS := ["Cortar", "Cancelar corte", "Minerar", "Cancelar mineração", "Colher", "Cancelar colheita"]
## Até quantos tiles a busca de lugares em volta do destino olha, para espalhar o grupo.
const _SPREAD_SEARCH_LIMIT := 400


static func colonists_in(state: WorldState, area: Rect2i) -> Array[int]:
	var ids: Array[int] = []
	for colonist in state.colonists:
		if area.has_point(colonist.cell):
			ids.append(colonist.id)
	return ids


## Árvores, rochas, arbustos e plantas de fibra do retângulo: o que se corta, minera ou colhe.
static func resources_in(state: WorldState, area: Rect2i) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for cell in area_cells(state, area):
		if is_resource(state, cell):
			cells.append(cell)
	return cells


static func is_resource(state: WorldState, cell: Vector2i) -> bool:
	return state.trees_by_cell.has(cell) or state.bush_at(cell) != null or state.fiber_plants_by_cell.has(cell) 		or state.world.get_terrain(cell) == Terrain.Kind.ROCK


## Tiles do retângulo dentro do mapa.
static func area_cells(state: WorldState, area: Rect2i) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for y in range(area.position.y, area.end.y):
		for x in range(area.position.x, area.end.x):
			if state.world.contains(Vector2i(x, y)):
				cells.append(Vector2i(x, y))
	return cells


## O que há nos tiles, para o painel: "5 árvores, 2 pilhas (30 itens), 1 caixote".
static func summary(state: WorldState, cells: Array[Vector2i]) -> String:
	var counts := {}
	var stacked := 0
	var seen := {}
	for cell in cells:
		if state.trees_by_cell.has(cell):
			_count(counts, "árvore", "árvores")
		if state.bush_at(cell):
			_count(counts, "arbusto", "arbustos")
		if state.fiber_plants_by_cell.has(cell):
			_count(counts, "planta de fibra", "plantas de fibra")
		if state.world.get_terrain(cell) == Terrain.Kind.ROCK:
			_count(counts, "rocha", "rochas")
		var stack: ItemStack = state.stacks_by_cell.get(cell)
		if stack:
			_count(counts, "pilha", "pilhas")
			stacked += stack.count
		if state.zone_by_cell.has(cell):
			_count(counts, "tile de plantação", "tiles de plantação")
		for target in [state.containers_by_cell.get(cell), state.buildings_by_cell.get(cell), state.floors_by_cell.get(cell)]:
			if target and not seen.has(target.id):
				seen[target.id] = true
				_count_named(counts, target.def.display_name)
		for layer in [StructureDef.Layer.BUILDING, StructureDef.Layer.FLOOR]:
			var site := state.site_at(cell, layer)
			if site and not seen.has(site.id):
				seen[site.id] = true
				_count(counts, "obra", "obras")
		for animal in state.animals_at(cell):
			_count_named(counts, animal.def.display_name)
		var raider := RaiderAI.raider_at(state, cell)
		if raider and raider.cell == cell:
			_count(counts, "saqueador", "saqueadores")
	var parts := PackedStringArray()
	for key in counts:
		var entry: Dictionary = counts[key]
		var text := "%d %s" % [entry["count"], entry["plural"] if entry["count"] > 1 else key]
		if key == "pilha":
			text += " (%d itens)" % stacked
		parts.append(text)
	return ", ".join(parts) if not parts.is_empty() else "Nada aqui"


## Opções de todos os tiles juntas por rótulo. Cada uma executa a opção em todos os alvos.
## only_resources: só Cortar, Minerar e Colher (e os cancelamentos), nessa ordem.
static func options_for_cells(simulation: Simulation, cells: Array[Vector2i], only_resources := false) -> Array[Dictionary]:
	var groups := {}
	var order: Array[String] = []
	for cell in cells:
		for option in ContextActions.for_cell(simulation, cell):
			var label: String = option["label"]
			if _SKIPPED_LABELS.has(label) or (only_resources and not RESOURCE_LABELS.has(label)):
				continue
			if not groups.has(label):
				groups[label] = {"tooltip": option["tooltip"], "runs": [], "keys": {}, "count": 0}
				order.append(label)
			var group: Dictionary = groups[label]
			if option.has("key"):
				if group["keys"].has(option["key"]):
					continue
				group["keys"][option["key"]] = true
			group["count"] += 1
			if option["enabled"]:
				group["runs"].append(option["run"])
	if only_resources:
		order.sort_custom(func(a: String, b: String) -> bool: return RESOURCE_LABELS.find(a) < RESOURCE_LABELS.find(b))
	var options: Array[Dictionary] = []
	for label in order:
		var group: Dictionary = groups[label]
		var runs: Array = group["runs"]
		var count: int = runs.size() if not runs.is_empty() else group["count"]
		options.append({
			"label": "%s (%d)" % [label, count] if count > 1 else label,
			"tooltip": group["tooltip"] if count <= 1 else "%s · vale para os %d" % [group["tooltip"], count],
			"enabled": not runs.is_empty(),
			"run": func() -> String: return _run_all(label, runs),
		})
	return options


## Opções do grupo de colonos selecionados.
static func colonist_options(simulation: Simulation, ids: Array[int]) -> Array[Dictionary]:
	var options: Array[Dictionary] = []
	var drafting := _any_free(simulation.state, ids)
	options.append({"label": "Convocar todos (V)" if drafting else "Dispensar todos (V)",
		"tooltip": "Convoca os selecionados para o combate" if drafting else "Voltam à rotina de trabalho",
		"enabled": true, "run": func() -> String: return draft_group(simulation, ids)})
	var with_orders := ids.filter(func(id: int) -> bool:
		var colonist := simulation.state.colonist_by_id(id)
		return colonist != null and colonist.direct_order != null)
	if not with_orders.is_empty():
		options.append({"label": "Cancelar ordens", "tooltip": "Esquecem as ordens diretas", "enabled": true,
			"run": func() -> String:
				for id: int in with_orders:
					simulation.cancel_order(id)
				return "%d ordem(ns) cancelada(s)" % with_orders.size()})
	return options


## V com vários selecionados: convoca todos se algum está livre; senão dispensa todos.
static func draft_group(simulation: Simulation, ids: Array[int]) -> String:
	var drafting := _any_free(simulation.state, ids)
	var count := 0
	var refused := ""
	for id in ids:
		var message := simulation.set_drafted(id, drafting)
		var colonist := simulation.state.colonist_by_id(id)
		if colonist and colonist.drafted == drafting and not message.is_empty():
			count += 1
		elif not message.is_empty():
			refused = message
	var text := "%d colono(s) %s" % [count, "convocados" if drafting else "dispensados"]
	return text + (" · " + refused if not refused.is_empty() else "")


## Botão direito com vários colonos: num saqueador, todos atacam; numa tarefa, o mais perto que puder
## a faz; no chão, cada um vai para um tile livre em volta do ponto.
static func order_group(simulation: Simulation, ids: Array[int], cell: Vector2i) -> String:
	var state := simulation.state
	var raider := RaiderAI.raider_at(state, cell)
	if raider == null:
		raider = RaiderAI.raider_at(state, cell + Vector2i.DOWN)
	if raider:
		var attackers := 0
		for id in ids:
			if not simulation.order_attack(id, raider.id).is_empty() and state.colonist_by_id(id).drafted:
				attackers += 1
		return "%d colono(s) vão atacar %s" % [attackers, raider.display_name().to_lower()]
	if simulation.task_at(cell):
		var by_distance := ids.duplicate()
		by_distance.sort_custom(func(a: int, b: int) -> bool:
			return _distance(state, a, cell) < _distance(state, b, cell))
		for id: int in by_distance:
			if simulation.order_task(id, cell):
				return ""
		return ""
	if not state.navigation.is_walkable(cell):
		simulation.order_move(ids[0], cell)
		return ""
	var cells := spread_cells(state, cell, ids.size())
	for index in mini(ids.size(), cells.size()):
		simulation.order_move(ids[index], cells[index])
	return ""


## Os count tiles livres mais perto do centro (busca em largura pelos tiles andáveis).
static func spread_cells(state: WorldState, center: Vector2i, count: int) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	var visited := {center: true}
	var queue: Array[Vector2i] = [center]
	var head := 0
	while head < queue.size() and result.size() < count and visited.size() < _SPREAD_SEARCH_LIMIT:
		var cell := queue[head]
		head += 1
		if not state.navigation.is_walkable(cell):
			continue
		result.append(cell)
		for offset in [Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT, Vector2i.UP]:
			var next: Vector2i = cell + offset
			if not visited.has(next) and state.world.contains(next):
				visited[next] = true
				queue.append(next)
	return result


static func _run_all(label: String, runs: Array) -> String:
	var last := ""
	for run: Callable in runs:
		var message: String = run.call()
		if not message.is_empty():
			last = message
	return "%s: %d" % [label, runs.size()] if runs.size() > 1 else last


static func _any_free(state: WorldState, ids: Array[int]) -> bool:
	for id in ids:
		var colonist := state.colonist_by_id(id)
		if colonist and not colonist.drafted and not colonist.health.is_downed():
			return true
	return false


static func _distance(state: WorldState, id: int, cell: Vector2i) -> float:
	var colonist := state.colonist_by_id(id)
	return Vector2(colonist.cell).distance_to(Vector2(cell)) if colonist else INF


## Plural simples em português, só das palavras antes de "de": "parede antiga" -> "paredes antigas",
## "pátio de materiais" -> "pátios de materiais".
static func plural(name: String) -> String:
	var parts := name.split(" de ", true, 1)
	var words := PackedStringArray()
	for word in parts[0].split(" "):
		words.append(_plural_word(word))
	parts[0] = " ".join(words)
	return " de ".join(parts)


static func _plural_word(word: String) -> String:
	if word.ends_with("ão"):
		return word.trim_suffix("ão") + "ões"
	if word.ends_with("l"):
		return word.trim_suffix("l") + "is"
	if word.ends_with("r") or word.ends_with("z") or word.ends_with("s"):
		return word + ("es" if not word.ends_with("s") else "")
	if word.ends_with("m"):
		return word.trim_suffix("m") + "ns"
	return word + "s"


static func _count_named(counts: Dictionary, display_name: String) -> void:
	var singular := display_name.to_lower()
	_count(counts, singular, plural(singular))


static func _count(counts: Dictionary, singular: String, plural: String) -> void:
	if not counts.has(singular):
		counts[singular] = {"count": 0, "plural": plural}
	counts[singular]["count"] += 1
