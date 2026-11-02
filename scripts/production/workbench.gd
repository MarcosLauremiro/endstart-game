class_name Workbench
extends RefCounted
## Bancada pronta com a fila de pedidos (GDD: Bancadas). Cada bancada tem uma tarefa no quadro:
## quem a pega traz os ingredientes do pedido em andamento, um por vez, e depois trabalha.
## Os ingredientes entregues ficam separados na bancada até a receita terminar; se o pedido
## for apagado ou a bancada desmontada, eles voltam ao chão. Nada some.

## Usa o mesmo id da estrutura.
var id: int
var structure: Structure
var bills: Array[Bill] = []
## Pedido em andamento (já tem ingredientes separados ou vai receber agora); null = nenhum.
var job: Bill
## Por ingrediente da receita do pedido: item → quantidade separada.
var staged: Array[Dictionary] = []
## id do colono → {"item": StringName, "count": int, "index": int}
var _incoming := {}


## Argumentos opcionais: o carregamento (SaveGame) cria a instância vazia e preenche os campos.
func _init(new_structure: Structure = null) -> void:
	structure = new_structure
	id = structure.id if structure else 0


func def() -> StructureDef:
	return structure.def


func work_type() -> int:
	return WorkType.from_key(structure.def.bench_work)


## Onde o operador trabalha e entrega: ao lado do meio da bancada.
func work_cell() -> Vector2i:
	return structure.origin + Vector2i(structure.def.footprint.x / 2, structure.def.footprint.y / 2)


func delivery_cell() -> Vector2i:
	return work_cell()


func label() -> String:
	return "%s (%d, %d)" % [structure.def.display_name, structure.origin.x, structure.origin.y]


## O pedido que o operador faria agora: {"bill": Bill} ou {"reason": String}.
## O pedido em andamento tem preferência, para não desperdiçar ingredientes separados.
func next_bill(state: WorldState) -> Dictionary:
	if job and bills.has(job):
		if job.paused:
			return {"reason": "o pedido em andamento (%s) está pausado" % job.recipe.display_name}
		var missing := _missing_text(job, state)
		if not missing.is_empty():
			return {"reason": "%s: faltam %s" % [job.recipe.display_name, missing]}
		return {"bill": job}
	if bills.is_empty():
		return {"reason": "sem pedidos na fila"}
	var reasons := PackedStringArray()
	for bill in bills:
		var problem := bill.condition_problem(state)
		if problem.is_empty():
			problem = _missing_text(bill, state)
			if problem.is_empty():
				return {"bill": bill}
			problem = "faltam %s" % problem
		reasons.append("%s: %s" % [bill.recipe.display_name, problem])
	return {"reason": "; ".join(reasons)}


## Começa a separar ingredientes para o pedido.
func start_job(bill: Bill) -> void:
	job = bill
	staged.clear()
	for _i in bill.recipe.ingredients.size():
		staged.append({})


## O que falta trazer para o pedido, descontando o que já está a caminho.
## Cada item: {"index": int, "items": Array[StringName], "count": int}.
func needs(bill: Bill) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var recipe := bill.recipe
	for index in recipe.ingredients.size():
		var remaining: int = recipe.ingredients[index]["count"]
		if bill == job:
			remaining -= _staged_count(index) + _incoming_count(index)
		if remaining > 0:
			result.append({"index": index, "items": recipe.items_for(index), "count": remaining})
	return result


func has_all_ingredients() -> bool:
	if job == null:
		return false
	for index in job.recipe.ingredients.size():
		if _staged_count(index) < job.recipe.ingredients[index]["count"]:
			return false
	return true


func incoming_owners() -> Array:
	return _incoming.keys()


func reserve_incoming(owner_id: int, item: StringName, amount: int) -> void:
	for need in needs(job):
		if job.recipe.accepts(need["index"], item):
			_incoming[owner_id] = {"item": item, "count": amount, "index": need["index"]}
			return


## Recebe a entrega reservada. Devolve quanto entrou; o excesso fica com quem trouxe.
func deliver(owner_id: int, item: StringName, amount: int) -> int:
	if not _incoming.has(owner_id) or job == null:
		return 0
	var entry: Dictionary = _incoming[owner_id]
	_incoming.erase(owner_id)
	var index: int = entry["index"]
	if entry["item"] != item:
		return 0
	var needed: int = job.recipe.ingredients[index]["count"] - _staged_count(index)
	var stored := clampi(amount, 0, needed)
	staged[index][item] = staged[index].get(item, 0) + stored
	return stored


func release_owner(owner_id: int) -> void:
	_incoming.erase(owner_id)


func has_reservation_of(owner_id: int) -> bool:
	return _incoming.has(owner_id)


## Receita pronta: os ingredientes separados viram os produtos, largados ao lado da bancada.
func finish_job(state: WorldState) -> void:
	var recipe := job.recipe
	job.done += 1
	state.research.record_first("receita:%s" % recipe.id)
	if recipe.relic_points > 0:
		state.research.add_points(Research.Points.RELIC, recipe.relic_points)
		state.post_message("%s: +%d V" % [recipe.display_name, recipe.relic_points])
	job = null
	staged.clear()
	for item in recipe.products:
		state.drop_items(work_cell(), item, recipe.products[item])


## Devolve ao chão os ingredientes separados e encerra o pedido em andamento.
func drop_staged(state: WorldState) -> void:
	for portion in staged:
		for item in portion:
			if portion[item] > 0:
				state.drop_items(work_cell(), item, portion[item])
	job = null
	staged.clear()
	_incoming.clear()


func staged_text() -> String:
	if job == null:
		return ""
	var parts := PackedStringArray()
	for index in job.recipe.ingredients.size():
		parts.append("%d/%d %s" % [_staged_count(index), job.recipe.ingredients[index]["count"], job.recipe.ingredient_name(index)])
	return ", ".join(parts)


## Ingredientes que não existem livres em contêineres e no chão, ou "" se dá para fazer.
func _missing_text(bill: Bill, state: WorldState) -> String:
	var parts := PackedStringArray()
	for need in needs(bill):
		var available := 0
		for item in need["items"]:
			available += state.available_count(item)
		if available < need["count"]:
			parts.append("%d %s" % [need["count"] - available, bill.recipe.ingredient_name(need["index"])])
	return ", ".join(parts)


func _staged_count(index: int) -> int:
	if index >= staged.size():
		return 0
	var total := 0
	for item in staged[index]:
		total += staged[index][item]
	return total


func _incoming_count(index: int) -> int:
	var total := 0
	for entry in _incoming.values():
		if entry["index"] == index:
			total += entry["count"]
	return total
