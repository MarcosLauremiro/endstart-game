class_name NavigationGrid
extends RefCounted
## Caminhos na grade com AStarGrid2D. Terreno intransponível e objetos sólidos (contêineres) viram
## células sólidas; terreno lento ganha peso maior (1 ÷ fator de movimento).
## Mantém regiões conectadas para descartar destinos inalcançáveis sem rodar o A* (GDD: Movimento).

const _DIAGONAL_LENGTH := 1.41421356
const _NEIGHBORS_4 := [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]
const _NEIGHBORS_8 := [
	Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN,
	Vector2i(-1, -1), Vector2i(1, -1), Vector2i(-1, 1), Vector2i(1, 1),
]
## Anel de vizinhos em sentido horário, começando no norte: N, NE, L, SE, S, SO, O, NO.
const _RING := [
	Vector2i(0, -1), Vector2i(1, -1), Vector2i(1, 0), Vector2i(1, 1),
	Vector2i(0, 1), Vector2i(-1, 1), Vector2i(-1, 0), Vector2i(-1, -1),
]
const _NO_REGION := -1

var _grid := AStarGrid2D.new()
var _world: WorldData
var _blocked := {}
## Fator de movimento do piso construído na célula (GDD: piso 110%).
var _floor_factor := {}
## Região de cada célula caminhável (_NO_REGION para sólidas).
var _regions := PackedInt32Array()
var _regions_dirty := true
var _next_region := 0


## Argumentos opcionais: o carregamento (SaveGame) cria a instância vazia e preenche os campos.
func _init(world: WorldData = null) -> void:
	_world = world
	if world == null:
		return
	_setup_grid()
	for y in world.size.y:
		for x in world.size.x:
			refresh_cell(Vector2i(x, y))
	_ensure_regions()


## O AStarGrid2D não vai para o arquivo salvo: é refeito do terreno, das células bloqueadas e dos
## pisos. As regiões salvas continuam valendo (SaveGame).
func save_skip() -> PackedStringArray:
	return ["_grid"]


func after_load() -> void:
	_grid = AStarGrid2D.new()
	_setup_grid()
	for y in _world.size.y:
		for x in _world.size.x:
			var cell := Vector2i(x, y)
			var factor := Terrain.move_factor(_world.get_terrain(cell))
			_grid.set_point_solid(cell, factor <= 0.0 or _blocked.has(cell))
			if factor > 0.0:
				_grid.set_point_weight_scale(cell, 1.0 / (factor * _floor_factor.get(cell, 1.0)))


func _setup_grid() -> void:
	_grid.region = Rect2i(Vector2i.ZERO, _world.size)
	_grid.cell_size = Vector2.ONE
	_grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	_grid.default_compute_heuristic = AStarGrid2D.HEURISTIC_OCTILE
	_grid.default_estimate_heuristic = AStarGrid2D.HEURISTIC_OCTILE
	_grid.update()


## Reaplica a passagem de uma célula. Chamar sempre que terreno ou objeto sólido mudar.
func refresh_cell(cell: Vector2i) -> void:
	var was_solid := _grid.is_point_solid(cell)
	var factor := Terrain.move_factor(_world.get_terrain(cell))
	var solid := factor <= 0.0 or _blocked.has(cell)
	_grid.set_point_solid(cell, solid)
	if factor > 0.0:
		_grid.set_point_weight_scale(cell, 1.0 / (factor * _floor_factor.get(cell, 1.0)))
	if solid != was_solid and not _regions_dirty:
		_update_region_incrementally(cell, solid)


## Objetos que ocupam a célula (contêineres, no M3 paredes e móveis).
func set_blocked(cell: Vector2i, blocked: bool) -> void:
	if blocked:
		_blocked[cell] = true
	else:
		_blocked.erase(cell)
	refresh_cell(cell)


func set_floor(cell: Vector2i, factor: float) -> void:
	if is_equal_approx(factor, 1.0):
		_floor_factor.erase(cell)
	else:
		_floor_factor[cell] = factor
	refresh_cell(cell)


## Fator de velocidade de quem pisa na célula: terreno × piso.
func speed_factor(cell: Vector2i) -> float:
	return Terrain.move_factor(_world.get_terrain(cell)) * _floor_factor.get(cell, 1.0)


func is_walkable(cell: Vector2i) -> bool:
	return _world.contains(cell) and not _grid.is_point_solid(cell)


func can_reach(from: Vector2i, to: Vector2i) -> bool:
	if not is_walkable(from) or not is_walkable(to):
		return false
	_ensure_regions()
	return _regions[_index(from)] == _regions[_index(to)]


## Caminho incluindo a célula de partida. Vazio = sem caminho; [from] = já está no destino.
func find_path(from: Vector2i, to: Vector2i) -> Array[Vector2i]:
	if not can_reach(from, to):
		return []
	return _grid.get_id_path(from, to)


## Caminho até uma célula vizinha do alvo (para trabalhar em rocha, árvore ou contêiner).
func path_to_adjacent(from: Vector2i, target: Vector2i) -> Array[Vector2i]:
	var options: Array[Vector2i] = []
	for offset in _NEIGHBORS_8:
		var neighbor: Vector2i = target + offset
		if can_reach(from, neighbor):
			options.append(neighbor)
	options.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
		return a.distance_squared_to(from) < b.distance_squared_to(from))
	for neighbor in options:
		var path := find_path(from, neighbor)
		if not path.is_empty():
			return path
	return []


## Custo do caminho em tiles, já ponderado pelo terreno (é a "distância" da pontuação do GDD).
func path_cost(path: Array[Vector2i]) -> float:
	var cost := 0.0
	for index in range(1, path.size()):
		var step := path[index] - path[index - 1]
		var length := _DIAGONAL_LENGTH if step.x != 0 and step.y != 0 else 1.0
		cost += length * _grid.get_point_weight_scale(path[index])
	return cost


## Uma célula que abriu (rocha minerada) se junta à região vizinha; se unir regiões diferentes,
## as regiões são recalculadas na próxima consulta. Uma célula que fechou (contêiner, parede)
## só obriga a recalcular se puder ter dividido a região.
func _update_region_incrementally(cell: Vector2i, became_solid: bool) -> void:
	if became_solid:
		_regions[_index(cell)] = _NO_REGION
		if _may_split(cell):
			_regions_dirty = true
		return
	var found := {}
	for offset in _NEIGHBORS_4:
		var neighbor: Vector2i = cell + offset
		if _is_open(neighbor):
			found[_regions[_index(neighbor)]] = true
	if found.size() > 1:
		_regions_dirty = true
	elif found.size() == 1:
		_regions[_index(cell)] = found.keys()[0]
	else:
		_regions[_index(cell)] = _next_region
		_next_region += 1


## Teste local: os vizinhos caminháveis em volta da célula continuam ligados pelo anel de vizinhos?
## Cada sequência contínua de vizinhos abertos no anel é conectada; se só uma delas toca as direções
## cardeais, fechar a célula não separa ninguém. Em caso de dúvida, responde que pode dividir.
func _may_split(cell: Vector2i) -> bool:
	var open: Array[bool] = []
	for offset in _RING:
		open.append(_is_open(cell + offset))
	var start := open.find(false)
	if start == -1:
		return false
	var runs_touching_cardinal := 0
	var in_run := false
	var touches_cardinal := false
	for step in range(1, _RING.size() + 1):
		var index := (start + step) % _RING.size()
		if open[index]:
			in_run = true
			touches_cardinal = touches_cardinal or index % 2 == 0
		elif in_run:
			if touches_cardinal:
				runs_touching_cardinal += 1
			in_run = false
			touches_cardinal = false
	return runs_touching_cardinal > 1


func _is_open(cell: Vector2i) -> bool:
	return _world.contains(cell) and not _grid.is_point_solid(cell)


## Busca em largura em 4 direções sobre índices. Como o A* só anda na diagonal com os dois lados
## livres, estar na mesma região em 4 direções é o mesmo que ter caminho.
func _ensure_regions() -> void:
	if not _regions_dirty:
		return
	_regions_dirty = false
	var width := _world.size.x
	var height := _world.size.y
	var total := width * height
	var solid := PackedByteArray()
	solid.resize(total)
	for y in height:
		for x in width:
			solid[y * width + x] = 1 if _grid.is_point_solid(Vector2i(x, y)) else 0
	_regions.resize(total)
	_regions.fill(_NO_REGION)
	_next_region = 0
	var queue := PackedInt32Array()
	queue.resize(total)
	for start in total:
		if _regions[start] != _NO_REGION or solid[start] == 1:
			continue
		var region := _next_region
		_next_region += 1
		_regions[start] = region
		var head := 0
		var tail := 0
		queue[tail] = start
		tail += 1
		while head < tail:
			var current := queue[head]
			head += 1
			var x := current % width
			if x > 0 and solid[current - 1] == 0 and _regions[current - 1] == _NO_REGION:
				_regions[current - 1] = region
				queue[tail] = current - 1
				tail += 1
			if x < width - 1 and solid[current + 1] == 0 and _regions[current + 1] == _NO_REGION:
				_regions[current + 1] = region
				queue[tail] = current + 1
				tail += 1
			if current >= width and solid[current - width] == 0 and _regions[current - width] == _NO_REGION:
				_regions[current - width] = region
				queue[tail] = current - width
				tail += 1
			if current < total - width and solid[current + width] == 0 and _regions[current + width] == _NO_REGION:
				_regions[current + width] = region
				queue[tail] = current + width
				tail += 1


## Deixa as regiões prontas agora (ao criar ou carregar a partida), fora do tempo de jogo.
func prepare() -> void:
	_ensure_regions()


func _index(cell: Vector2i) -> int:
	return cell.y * _world.size.x + cell.x
