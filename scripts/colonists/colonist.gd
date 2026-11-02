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
var childhood: BackstoryDef
var adulthood: BackstoryDef
## Atributo do MVP (1 a 10, média 5), já com histórias e traços.
var strength: int = Balance.ATTRIBUTE_AVERAGE
var traits: Array[StringName] = []
## Skills.Id → SkillState (as 6 habilidades do MVP).
var skills := {}
## WorkType.Id → prioridade 1 a 4, ou 0 = desligado.
var work_priorities := {}
var schedule := Schedule.new()
var equipment := Equipment.new()
var cell: Vector2i
## Próximas células do caminho (sem a atual).
var path: Array[Vector2i] = []
## Fração do passo até path[0], de 0 a 1.
var move_progress: float = 0.0
var needs := Needs.new()
var mood := Mood.new()
var health := Health.new()
## Convocado para o combate (GDD: ordens diretas): não trabalha, segura a posição e luta.
var drafted: bool = false
## Quem o carrega para a cama (socorro), ou 0.
var carried_by: int = 0
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


func _init() -> void:
	for skill in Skills.ALL:
		skills[skill] = SkillState.new()


func next_cell() -> Vector2i:
	return path[0] if not path.is_empty() else cell


func is_sleeping() -> bool:
	return action != null and action.kind == Action.Kind.SLEEP and state == State.EXECUTING


## Dormindo numa cama reservada (a ação de sono tem a cama como alvo).
func is_sleeping_in_bed() -> bool:
	return is_sleeping() and action.target_id != 0


## Deitado: dormindo, caído ou repousando ferido (o sono se recupera e a arte fica deitada).
func is_lying() -> bool:
	if action == null or state != State.EXECUTING:
		return false
	return action.kind == Action.Kind.SLEEP or action.kind == Action.Kind.DOWNED or action.kind == Action.Kind.REST


## Deitado numa cama reservada (cura mais rápido e descansa como na cama).
func is_in_bed() -> bool:
	return is_lying() and action.target_id != 0


func weapon() -> StringName:
	return equipment.hand()


func melee_level() -> int:
	return skills[Skills.Id.MELEE].level

func has_trait(trait_id: StringName) -> bool:
	return traits.has(trait_id)


func priority_of(work_type: int) -> int:
	return work_priorities.get(work_type, 0)


func skill(skill_id: int) -> SkillState:
	return skills[skill_id]


## Nível da habilidade do tipo de trabalho (0 para trabalhos sem habilidade, como Carregar).
func skill_level(work_type: int) -> int:
	var skill_id := Skills.for_work(work_type)
	return skills[skill_id].level if skill_id >= 0 else 0


func affinity_for(work_type: int) -> Skills.Affinity:
	var skill_id := Skills.for_work(work_type)
	return skills[skill_id].affinity if skill_id >= 0 else Skills.Affinity.NONE


## Bloco da agenda agora.
func block_at(tick: int) -> Schedule.Block:
	return schedule.block_at((tick / Balance.TICKS_PER_HOUR) % Balance.HOURS_PER_DAY)


## Multiplicador de velocidade de trabalho: habilidade (GDD: Níveis), traços, Força onde o GDD
## liga e a ferramenta na mão.
func work_speed(work_type: int) -> float:
	var speed := 1.0
	var skill_id := Skills.for_work(work_type)
	if skill_id >= 0:
		speed *= Skills.speed_at(skills[skill_id].level)
	if has_trait(Traits.HARDWORKING):
		speed *= Balance.HARDWORKING_SPEED
	if has_trait(Traits.LAZY):
		speed *= Balance.LAZY_SPEED
	if WorkType.uses_strength(work_type):
		speed *= 1.0 + Balance.ATTRIBUTE_STEP * (strength - Balance.ATTRIBUTE_AVERAGE)
	speed *= tool_bonus(work_type)
	return speed * health.pain_factor()


## Bônus da ferramenta na mão para o tipo de trabalho (GDD: ferramentas na mão).
func tool_bonus(work_type: int) -> float:
	var hand := equipment.hand()
	if hand == &"":
		return 1.0
	return Defs.item(hand).work_bonus.get(WorkType.key_of(work_type), 1.0)


## Alcance e dano da caça com o que está na mão (ou a arma improvisada).
func hunt_range() -> int:
	var hand := equipment.hand()
	if hand != &"" and Defs.item(hand).hunt_range > 0:
		return Defs.item(hand).hunt_range
	return Balance.UNARMED_HUNT_RANGE


func hunt_damage() -> float:
	var hand := equipment.hand()
	if hand != &"" and Defs.item(hand).hunt_damage > 0.0:
		return Defs.item(hand).hunt_damage
	return Balance.UNARMED_HUNT_DAMAGE


## Ganha XP por ticks de trabalho (GDD: XP = base × afinidade × idade × traços × humor).
## Devolve a habilidade se subiu de nível, ou -1.
func learn(work_type: int, ticks: int) -> int:
	var skill_id := Skills.for_work(work_type)
	if skill_id < 0:
		return -1
	return learn_skill(skill_id, ticks)


## XP direto numa habilidade (o combate treina Corpo a corpo sem ser um tipo de trabalho).
func learn_skill(skill_id: int, ticks: int) -> int:
	var state_of: SkillState = skills[skill_id]
	var amount: float = Balance.SKILL_XP_PER_TICK * ticks * Skills.AFFINITY_XP[state_of.affinity] * _age_xp_factor() * mood.xp_factor()
	for _t in ticks:
		mood.feel_work(state_of.affinity)
	return skill_id if state_of.add_xp(amount) > 0 else -1


func _age_xp_factor() -> float:
	if age <= Balance.XP_YOUNG_MAX_AGE:
		return Balance.XP_YOUNG_FACTOR
	if age >= Balance.XP_OLD_MIN_AGE:
		return Balance.XP_OLD_FACTOR
	return 1.0


## Glutão: a fome cai 30% mais rápido.
func hunger_factor() -> float:
	return Balance.GLUTTON_HUNGER_FACTOR if has_trait(Traits.GLUTTON) else 1.0


func carry_capacity_kg() -> float:
	return Balance.BASE_CARRY_KG + Balance.CARRY_KG_PER_STRENGTH * strength


## Quantas unidades do item cabem nas mãos. Algo mais pesado que a capacidade (carcaça grande)
## ainda vai, uma unidade por vez, arrastado.
func carry_units(item: StringName) -> int:
	var free := carry_capacity_kg() - equipment.weight_kg()
	return maxi(1, floori(free / Defs.item(item).weight_kg))


## Peso carregado: o que leva nas mãos mais o equipamento.
func load_kg() -> float:
	var total := equipment.weight_kg()
	if carrying_count > 0:
		total += carrying_count * Defs.item(carrying_item).weight_kg
	return total


## GDD: até 100% sem penalidade; até 125% movimento -20%; acima, -50%. O GDD trava o colono acima de
## 150%, mas no MVP isso só acontece arrastando uma carcaça grande, então ele segue a -50%.
func load_move_factor() -> float:
	var ratio := load_kg() / carry_capacity_kg()
	if ratio <= Balance.LOAD_SLOW_RATIO:
		return 1.0
	if ratio <= Balance.LOAD_SLOWER_RATIO:
		return Balance.LOAD_SLOW_FACTOR
	return Balance.LOAD_SLOWER_FACTOR


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
