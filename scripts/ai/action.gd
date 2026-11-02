class_name Action
extends RefCounted
## Uma atividade que o colono decidiu fazer, com a camada de decisão que a originou.
## A camada define quem interrompe quem (GDD: Camadas de decisão).

enum Kind { MOVE, EAT, SLEEP, WANDER, IDLE, WORK, HAUL, BREAK, DELIVER, HUNT, EQUIP, FIGHT, FLEE, DOWNED, REST, TEND_SELF, RESCUE }
## Ordem do GDD: número menor vence.
enum Layer { REACTION = 1, CRITICAL_NEED = 2, ORDER = 3, SCHEDULE = 4, WORK = 5, FREE_TIME = 6 }
## De onde vem o item de uma ação (comida para EAT, material para DELIVER, ferramenta para EQUIP).
enum ItemSource { NONE, CONTAINER, STACK, BUSH }

const LAYER_NAMES := {
	Layer.REACTION: "Reação",
	Layer.CRITICAL_NEED: "Necessidade crítica",
	Layer.ORDER: "Ordem direta",
	Layer.SCHEDULE: "Agenda",
	Layer.WORK: "Trabalho",
	Layer.FREE_TIME: "Tempo livre",
}

var kind: Kind
var layer: Layer
var target_cell: Vector2i
## true = trabalha de uma célula vizinha (rocha, árvore, contêiner); false = pisa no alvo.
var adjacent: bool = false
## Id do objeto alvo (arbusto ou pilha) ou 0.
var target_id: int = 0
## Tarefa do quadro (WORK, HAUL) ou 0.
var task_id: int = 0
var item_source: ItemSource = ItemSource.NONE
var item_id: StringName = &""
var count: int = 0
## Destino: contêiner (HAUL), obra ou bancada (DELIVER).
var destination_id: int = 0
## Pedido da bancada para o qual o ingrediente vai (DELIVER numa bancada).
var bill: Bill
## Chave da reserva exclusiva desta ação no quadro (vaga da equipe, entrega ou tarefa).
var reservation_key: String = ""
## Etapa da ação em várias partes (HAUL: 0 = buscar, 1 = entregar; EAT: 0 = pegar, 1 = comer).
var phase: int = 0
var title: String = ""
var reason: String = ""
## Caminho já calculado na decisão, reaproveitado ao iniciar (inclui a célula de partida).
var path: Array[Vector2i] = []
## Progresso da execução em ticks; fica na ação para não recomeçar do zero.
var progress_ticks: int = 0
var record: DecisionRecord


static func make(new_kind: Kind, new_layer: Layer, cell: Vector2i, why: String) -> Action:
	var action := Action.new()
	action.kind = new_kind
	action.layer = new_layer
	action.target_cell = cell
	action.reason = why
	return action


func label() -> String:
	if not title.is_empty():
		return title
	match kind:
		Kind.MOVE:
			return "Ir até (%d, %d)" % [target_cell.x, target_cell.y]
		Kind.SLEEP:
			return "Dormir no chão"
		Kind.WANDER:
			return "Vagar"
		Kind.IDLE:
			return "Ocioso"
		Kind.BREAK:
			return "Pausa"
		Kind.FIGHT:
			return "Convocado: segura a posição"
		Kind.FLEE:
			return "Fugir"
		Kind.DOWNED:
			return "Caído"
		Kind.REST:
			return "Repousar"
		Kind.TEND_SELF:
			return "Tratar os próprios ferimentos"
	return "?"


## Ocioso e vagar só preenchem o tempo: qualquer atividade de verdade os substitui.
func is_filler() -> bool:
	return kind == Kind.IDLE or kind == Kind.WANDER


func same_goal(other: Action) -> bool:
	return other != null and kind == other.kind and target_cell == other.target_cell \
		and target_id == other.target_id and task_id == other.task_id


func interruptible_by(other: Action) -> bool:
	# Cair ferido interrompe tudo, até outra reação (fugir); nada interrompe quem está caído.
	if other.kind == Kind.DOWNED or kind == Kind.DOWNED:
		return other.kind == Kind.DOWNED and kind != Kind.DOWNED
	if other.layer < layer:
		return true
	return is_filler() and not other.is_filler()
