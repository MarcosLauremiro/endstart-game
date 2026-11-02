class_name TaskBoard
extends RefCounted
## Quadro central de tarefas, compartilhado por todos os colonos. Indexado por tipo de trabalho
## (cada colono só olha os tipos que tem ligados), por célula (designações) e por pilha (transporte).
## Quem reservou cada tarefa fica em Reservations, que é a fonte única das reservas.

var _next_id: int = 1
var _by_id := {}
## WorkType.Id → Array[Task]
var _by_type := {}
## Vector2i → Task (cortar, minerar, colher: no máximo uma por célula)
var _designation_by_cell := {}
## id da pilha → Task de Carregar
var _haul_by_stack := {}
## id da obra → Task de Construir
var _construct_by_site := {}
## id da estrutura ou contêiner → Task de Desmontar
var _deconstruct_by_target := {}
## id da bancada → Task da bancada
var _craft_by_bench := {}
## id do animal → Task de Caçar
var _hunt_by_animal := {}
## id da sala da ruína → Task de Investigar
var _investigate_by_room := {}
## id do colono caído → Task de Socorrer / de Tratar
var _rescue_by_patient := {}
var _tend_by_patient := {}


## work_type = -1 usa o tipo padrão do tipo de tarefa (bancadas informam o seu).
func create(task_kind: Task.Kind, cell: Vector2i, target_id: int, work_required: float, tick: int, work_type: int = -1) -> Task:
	var task := Task.new()
	task.id = _next_id
	_next_id += 1
	task.kind = task_kind
	task.work_type = Task.work_type_of(task_kind) if work_type < 0 else work_type
	task.cell = cell
	task.target_id = target_id
	task.work_required = work_required
	task.created_tick = tick
	_by_id[task.id] = task
	if not _by_type.has(task.work_type):
		_by_type[task.work_type] = []
	_by_type[task.work_type].append(task)
	_index(task).set(_index_key(task), task)
	return task


## Tira a tarefa do quadro. Quem estiver nela percebe na próxima execução e solta tudo.
func remove(task: Task, final_status: Task.Status) -> void:
	if not _by_id.has(task.id):
		return
	task.status = final_status
	_by_id.erase(task.id)
	_by_type[task.work_type].erase(task)
	_index(task).erase(_index_key(task))


func get_task(id: int) -> Task:
	return _by_id.get(id)


func tasks_of(work_type: int) -> Array:
	return _by_type.get(work_type, [])


func designation_at(cell: Vector2i) -> Task:
	return _designation_by_cell.get(cell)


func haul_for_stack(stack_id: int) -> Task:
	return _haul_by_stack.get(stack_id)


func construction_for_site(site_id: int) -> Task:
	return _construct_by_site.get(site_id)


func deconstruction_for(target_id: int) -> Task:
	return _deconstruct_by_target.get(target_id)


func craft_for_bench(bench_id: int) -> Task:
	return _craft_by_bench.get(bench_id)


func hunt_for(animal_id: int) -> Task:
	return _hunt_by_animal.get(animal_id)


func investigation_for(room_id: int) -> Task:
	return _investigate_by_room.get(room_id)


func rescue_for(patient_id: int) -> Task:
	return _rescue_by_patient.get(patient_id)


func tend_for(patient_id: int) -> Task:
	return _tend_by_patient.get(patient_id)


func all_tasks() -> Array:
	return _by_id.values()


func count() -> int:
	return _by_id.size()


func _index(task: Task) -> Dictionary:
	match task.kind:
		Task.Kind.HAUL:
			return _haul_by_stack
		Task.Kind.CONSTRUCT:
			return _construct_by_site
		Task.Kind.DECONSTRUCT:
			return _deconstruct_by_target
		Task.Kind.CRAFT:
			return _craft_by_bench
		Task.Kind.HUNT:
			return _hunt_by_animal
		Task.Kind.INVESTIGATE:
			return _investigate_by_room
		Task.Kind.RESCUE:
			return _rescue_by_patient
		Task.Kind.TEND:
			return _tend_by_patient
	return _designation_by_cell


## Designações são indexadas pela célula; as outras tarefas, pelo id do alvo.
func _index_key(task: Task) -> Variant:
	match task.kind:
		Task.Kind.CUT, Task.Kind.MINE, Task.Kind.HARVEST, Task.Kind.SOW, Task.Kind.REAP:
			return task.cell
	return task.target_id
