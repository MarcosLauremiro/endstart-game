class_name Colonist
extends RefCounted
## Dados de um colono. É a única fonte de verdade: IA, interface e (no M8) o save leem daqui.
## O nó visual só desenha estes dados.

## Estados de execução do GDD: LIVRE → ESCOLHENDO → INDO → EXECUTANDO → CONCLUINDO → LIVRE.
enum State { IDLE, CHOOSING, MOVING, EXECUTING, FINISHING }
const STATE_NAMES := ["Livre", "Escolhendo", "Indo", "Executando", "Concluindo"]

var id: int
var display_name: String
var age: int
## Atributo do MVP (1 a 10, média 5).
var strength: int = Balance.ATTRIBUTE_AVERAGE
var traits: Array[StringName] = []
## Nível por habilidade. O gerador e a experiência chegam no M5; até lá fica vazio (nível 0).
var skills := {}
## WorkType.Id → prioridade 1 a 4, ou 0 = desligado.
var work_priorities := {}
var cell: Vector2i
## Próximas células do caminho (sem a atual).
var path: Array[Vector2i] = []
## Fração do passo até path[0], de 0 a 1.
var move_progress: float = 0.0
var needs := Needs.new()
var state: State = State.IDLE
var action: Action
## Ordem do jogador ainda não cumprida. Sobrevive a interrupções, para ser retomada depois.
var direct_order: Action
## Item nas mãos (transporte ou comida). Nunca some: ao parar, é largado no chão.
var carrying_item: StringName = &""
var carrying_count: int = 0
var work_ticks_since_break: int = 0
## Desloca o tick de pensamento para os colonos não pensarem todos juntos.
var think_offset: int = 0
var force_think: bool = false
## Mais recente primeiro.
var history: Array[DecisionRecord] = []
## As melhores opções de tarefa da última avaliação, já com a pontuação (painel "por quê").
var last_options: PackedStringArray = []


func next_cell() -> Vector2i:
	return path[0] if not path.is_empty() else cell


func is_sleeping() -> bool:
	return action != null and action.kind == Action.Kind.SLEEP and state == State.EXECUTING


## Dormindo numa cama reservada (a ação de sono tem a cama como alvo).
func is_sleeping_in_bed() -> bool:
	return is_sleeping() and action.target_id != 0


func has_trait(trait_id: StringName) -> bool:
	return traits.has(trait_id)


func priority_of(work_type: int) -> int:
	return work_priorities.get(work_type, 0)


func skill_level(work_type: int) -> int:
	return skills.get(work_type, 0)


## Multiplicador de velocidade de trabalho: traços do GDD e, onde o GDD liga, a Força.
func work_speed(work_type: int) -> float:
	var speed := 1.0
	if has_trait(Traits.HARDWORKING):
		speed *= Balance.HARDWORKING_SPEED
	if has_trait(Traits.LAZY):
		speed *= Balance.LAZY_SPEED
	if WorkType.uses_strength(work_type):
		speed *= 1.0 + Balance.ATTRIBUTE_STEP * (strength - Balance.ATTRIBUTE_AVERAGE)
	return speed


func carry_capacity_kg() -> float:
	return Balance.BASE_CARRY_KG + Balance.CARRY_KG_PER_STRENGTH * strength


## Quantas unidades do item cabem nas mãos. Algo mais pesado que a capacidade (carcaça grande)
## ainda vai, uma unidade por vez, arrastado.
func carry_units(item: StringName) -> int:
	return maxi(1, floori(carry_capacity_kg() / Defs.item(item).weight_kg))


func carry(item: StringName, amount: int) -> void:
	assert(carrying_count == 0 or carrying_item == item, "Já carrega outro item")
	carrying_item = item
	carrying_count += amount


func clear_carry() -> void:
	carrying_item = &""
	carrying_count = 0


func remember(record: DecisionRecord) -> void:
	history.push_front(record)
	if history.size() > Balance.DECISION_HISTORY_SIZE:
		history.resize(Balance.DECISION_HISTORY_SIZE)


func state_name() -> String:
	return STATE_NAMES[state]
