class_name Task
extends RefCounted
## Uma unidade indivisível de trabalho no quadro. Quem reservou fica em Reservations (chave key());
## o progresso fica aqui, então quem voltar continua de onde parou.

enum Kind { CUT, MINE, HARVEST, HAUL, CONSTRUCT, DECONSTRUCT, CRAFT, HUNT, SOW, REAP, INVESTIGATE }
enum Status { OPEN, DONE, CANCELLED }

## GDD: normal 1; alta 2 (pedido marcado pelo jogador); crítica 3.
const URGENCY_NORMAL := 1

var id: int
var kind: Kind
var work_type: int
## Célula do alvo (árvore, rocha, arbusto, pilha, bancada; na caça, onde o animal está agora).
var cell: Vector2i
## Id do objeto alvo (árvore, arbusto, pilha, obra, bancada, animal, zona ou planta); 0 para rocha.
var target_id: int = 0
var urgency: int = URGENCY_NORMAL
var progress: float = 0.0
var work_required: float = 0.0
var status: Status = Status.OPEN
var block_reason: String = ""
var blocked_until: int = 0
var created_tick: int = 0
## Quantos colonos podem trabalhar juntos (GDD: ajuda mútua). Cada vaga tem sua reserva.
var max_workers: int = 1
## Texto da tarefa quando o tipo sozinho não diz o que é (construções).
var title: String = ""


func key() -> String:
	return "task:%d" % id


## Reserva de cada vaga da equipe; a vaga 0 é a própria key().
func slot_key(slot: int) -> String:
	return key() if slot == 0 else "%s#%d" % [key(), slot]


## Reserva de quem está levando material para a obra (uma entrega por vez).
func delivery_key() -> String:
	return "%s:entrega" % key()


func is_open() -> bool:
	return status == Status.OPEN


func is_blocked(tick: int) -> bool:
	return blocked_until > tick


func block(tick: int, reason: String) -> void:
	block_reason = reason
	blocked_until = tick + Balance.TASK_BLOCK_RETRY_TICKS


func unblock() -> void:
	block_reason = ""
	blocked_until = 0


func label() -> String:
	if not title.is_empty():
		return title
	match kind:
		Kind.CUT:
			return "Cortar árvore (%d, %d)" % [cell.x, cell.y]
		Kind.MINE:
			return "Minerar rocha (%d, %d)" % [cell.x, cell.y]
		Kind.HARVEST:
			return "Colher planta (%d, %d)" % [cell.x, cell.y]
		Kind.HAUL:
			return "Carregar pilha (%d, %d)" % [cell.x, cell.y]
	return "?"


static func work_type_of(task_kind: Kind) -> int:
	match task_kind:
		Kind.CUT:
			return WorkType.Id.CUT
		Kind.MINE:
			return WorkType.Id.MINE
		Kind.HARVEST:
			return WorkType.Id.GROW
		Kind.CONSTRUCT, Kind.DECONSTRUCT:
			return WorkType.Id.CONSTRUCT
		Kind.HUNT:
			return WorkType.Id.HUNT
		Kind.SOW, Kind.REAP:
			return WorkType.Id.GROW
		Kind.INVESTIGATE:
			return WorkType.Id.RESEARCH
	return WorkType.Id.HAUL
