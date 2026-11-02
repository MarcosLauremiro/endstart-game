class_name Balance
extends RefCounted
## Parâmetros centrais de tempo, mapa e câmera. Valores do GDD (seções "Tempo" e "Mapa").
## Nenhum script deve repetir estes números: alterar aqui muda o jogo inteiro.

# --- Tempo (GDD: Balanceamento e cálculos > Tempo) ---
const TICKS_PER_SECOND := 60
const TICKS_PER_HOUR := 1800
const HOURS_PER_DAY := 24
const TICKS_PER_DAY := TICKS_PER_HOUR * HOURS_PER_DAY
## Velocidades como no RimWorld: normal 1×, rápida 3×, muito rápida 6× (teclas 1, 2, 3).
const SPEED_MULTIPLIERS := [1, 3, 6]
## Ultrarrápida 15× (tecla 4), só em build de desenvolvimento, como o modo dev do RimWorld.
const DEBUG_SPEED_MULTIPLIER := 15
## Calendário do GDD: ano de 60 dias, 4 estações de 15 dias, começando na primavera.
## No MVP as estações só mudam a arte (GDD: estações e clima ficam fora do MVP).
const DAYS_PER_SEASON := 15
## Dia e noite (GDD): latitude temperada, A = 3 h; amanhecer e anoitecer levam 1 h.
const DAYLIGHT_AMPLITUDE_HOURS := 3.0
const TWILIGHT_HOURS := 1.0
const SEASONS_PER_YEAR := 4
## Limite de ticks executados num quadro, para evitar espiral de atraso após travamentos.
const MAX_TICKS_PER_FRAME := 120

# --- Mapa (GDD: Mapa jogável > Proporções) ---
const TILE_SIZE := 16
const MAP_SIZE := Vector2i(128, 128)
const DEFAULT_SEED := 20261030
## A partida começa às 6 h da manhã do dia 1 (início do bloco Trabalhar da agenda padrão).
const START_HOUR := 6

# --- Geração do terreno (valores provisórios de M0) ---
const TERRAIN_NOISE_FREQUENCY := 0.04
const TALL_GRASS_NOISE_THRESHOLD := 0.25
const DIRT_NOISE_THRESHOLD := -0.25
const RIVER_HALF_WIDTH := 2
const RIVER_CORE_HALF_WIDTH := 1
## Trechos rasos que permitem atravessar o rio (pontes estão fora do MVP).
const RIVER_FORD_COUNT := 3
const RIVER_FORD_LENGTH := 3
const MOUNTAIN_MIN_RADIUS := 6
const MOUNTAIN_MAX_RADIUS := 9

# --- Colonos e IA (GDD: IA dos colonos) ---
const STARTING_COLONISTS := 3
## Cada colono reavalia a cada 30 ticks, em ticks diferentes dos outros (GDD: pensamento escalonado).
const THINK_INTERVAL_TICKS := 30
const DECISION_HISTORY_SIZE := 12
## Quantos arbustos (os mais próximos em linha reta) recebem cálculo de caminho ao procurar comida.
const FOOD_CANDIDATES_EVALUATED := 6
const WANDER_CHANCE := 0.3
const WANDER_RADIUS := 5
const IDLE_TICKS := 120
## Velocidade base: 3 tiles por segundo de jogo em terreno 100%.
const MOVE_TILES_PER_TICK := 3.0 / TICKS_PER_SECOND

# --- Necessidades (limiares do GDD; ritmos provisórios, sem número no GDD) ---
const NEED_MAX := 100.0
const FOOD_FREE_TIME_THRESHOLD := 30.0
const FOOD_CRITICAL_THRESHOLD := 15.0
const REST_FREE_TIME_THRESHOLD := 20.0
const REST_CRITICAL_THRESHOLD := 8.0
const FOOD_DECAY_PER_TICK := NEED_MAX / (30.0 * TICKS_PER_HOUR)
const REST_DECAY_PER_TICK := NEED_MAX / (32.0 * TICKS_PER_HOUR)
const REST_GROUND_RECOVERY_PER_TICK := 10.0 / TICKS_PER_HOUR
const EAT_UNTIL := 90.0
## Ordem "dormir agora" só aparece com sono abaixo disto.
const SLEEP_ORDER_MAX_REST := 90.0

# --- Crescimento das plantas (provisório; o GDD não define) ---
const TREE_YOUNG_FRACTION := 0.25
const TREE_GROWTH_HOURS := 15 * HOURS_PER_DAY
const TREE_YOUNG_WOOD_YIELD := 5
const TREE_YOUNG_CUT_WORK_TICKS := 675
## O toco do corte some sozinho depois deste tempo.
const STUMP_DECAY_HOURS := 10 * HOURS_PER_DAY
const BUSH_YOUNG_FRACTION := 0.2
const BUSH_GROWTH_HOURS := 5 * HOURS_PER_DAY
## Planta de fibra (vegetação rasteira): colhida volta a ser pequena e cresce de novo.
const FIBER_PLANT_DENSITY := 0.03
const FIBER_GROWTH_HOURS := 3 * HOURS_PER_DAY
const FIBER_YIELD := 5
const FIBER_HARVEST_WORK_TICKS := 300

# --- Frutas silvestres (provisório) ---
const BERRY_BUSH_COUNT := 30
const BERRY_BUSH_MAX_PORTIONS := 10
const BERRY_REGROW_HOURS := 8
const BERRY_NUTRITION := 20.0
const EAT_PORTION_TICKS := 150

# --- Quadro de tarefas (GDD: Como o colono escolhe a tarefa / Trabalho em conjunto) ---
## Reserva sem avanço por 30 s de jogo expira.
const RESERVATION_TIMEOUT_TICKS := 30 * TICKS_PER_SECOND
const TASK_DISTANCE_DIVISOR := 30.0
const MAX_WORK_PRIORITY := 4
const DEFAULT_WORK_PRIORITY := 3
## Por tipo de trabalho, quantas tarefas (as mais próximas em linha reta) recebem cálculo de caminho.
const TASK_PATHS_EVALUATED := 6
## Por tipo de trabalho, quantas tarefas são examinadas no total (reservadas e bloqueadas incluídas).
const TASK_SCAN_LIMIT := 40
## Tarefa bloqueada (sem caminho, sem espaço) volta a ser tentada depois deste tempo.
const TASK_BLOCK_RETRY_TICKS := TICKS_PER_HOUR
## Tempos de trabalho e rendimentos (provisórios; o GDD não define).
const CUT_WORK_TICKS := 1350
const MINE_WORK_TICKS := 2700
const HARVEST_WORK_TICKS := 450
const TREE_WOOD_YIELD := 10
const ROCK_STONE_YIELD := 4
const TREE_DENSITY_TALL_GRASS := 0.35
const TREE_DENSITY_GRASS := 0.04
const SPAWN_CLEAR_RADIUS := 4
## Aviso "sem lugar para guardar" do mesmo item no máximo a cada 6 h de jogo.
const NO_STORAGE_ALERT_TICKS := 6 * TICKS_PER_HOUR
## Urgência de uma pilha que o jogador mandou guardar (GDD: alta 2 = pedido marcado pelo jogador).
const URGENCY_PLAYER := 2
## Raio de busca de lugar livre ao largar itens no chão.
const DROP_SEARCH_RADIUS := 8

# --- Construção e armazenamento (GDD: Trabalho em conjunto, Tipos de contêiner) ---
## Velocidade total da equipe na mesma obra: 1 colono ×1, 2 colonos ×1,8, 3 colonos ×2,4.
const TEAM_WORK_TOTALS := [1.0, 1.8, 2.4]
## Espaço grande do pátio de materiais guarda até 300 de material.
const LARGE_SLOT_STACK := 300
## Desmontar leva metade do tempo de construir e devolve metade do material (provisório; o GDD não define).
const DECONSTRUCT_WORK_FRACTION := 0.5
const DECONSTRUCT_REFUND := 0.5
## Dormir na cama recupera o sono mais rápido que no chão (provisório; o GDD não define).
const REST_BED_RECOVERY_PER_TICK := 15.0 / TICKS_PER_HOUR
## Quantas camas (as mais próximas) recebem cálculo de caminho ao procurar onde dormir.
const BED_CANDIDATES_EVALUATED := 4

# --- Animais e caça (provisório; o GDD não define números de fauna nem de caça) ---
## Animais pensam a cada segundo de jogo, escalonados pelo id.
const ANIMAL_THINK_TICKS := 60
const ANIMAL_WANDER_CHANCE := 0.25
## Quanto tempo a presa corre antes de se acalmar.
const ANIMAL_FLEE_TICKS := 5 * TICKS_PER_SECOND
## Animais iniciais nascem longe do ponto de chegada dos colonos.
const ANIMAL_SPAWN_MIN_DISTANCE := 20
const PREDATOR_SIGHT_RADIUS := 25
const PREDATOR_KILL_DISTANCE := 1.5
const PREDATOR_EAT_TICKS := 2 * TICKS_PER_HOUR
## Caça: atira uma vez a cada 1,5 s de jogo; alcance e dano vêm da arma na mão (ou da improvisada).
const HUNT_AIM_TICKS := 90
const HUNT_HIT_CHANCE := 0.85
const HUNT_HIT_FALLOFF_PER_TILE := 0.05
const HUNT_MIN_HIT_CHANCE := 0.3
## O caçador refaz o caminho quando o animal se afasta mais de 3 tiles do destino.
const HUNT_REPATH_DRIFT_SQUARED := 9

# --- Atributos, carga e personalidade (GDD) ---
const ATTRIBUTE_AVERAGE := 5
const ATTRIBUTE_MIN := 1
const ATTRIBUTE_MAX := 10
const ATTRIBUTE_DEVIATION := 1.5
## Cada ponto acima ou abaixo de 5 muda o efeito em 6%.
const ATTRIBUTE_STEP := 0.06
## Capacidade de carga = 15 kg + 5 kg × Força.
const BASE_CARRY_KG := 15.0
const CARRY_KG_PER_STRENGTH := 5.0
const HARDWORKING_SPEED := 1.15
const LAZY_SPEED := 0.8
## Preguiçoso: pausa de 15 min a cada 2 h de trabalho.
const LAZY_BREAK_EVERY_TICKS := 2 * TICKS_PER_HOUR
const LAZY_BREAK_TICKS := TICKS_PER_HOUR / 4

# --- Habilidades e XP (GDD: Habilidades, Ganho de XP) ---
const SKILL_MAX_LEVEL := 20
## 150 XP por hora de trabalho na atividade.
const SKILL_XP_PER_HOUR := 150.0
const SKILL_XP_PER_TICK := SKILL_XP_PER_HOUR / TICKS_PER_HOUR
## XP para subir do nível n = 1.000 + 75 × n².
const SKILL_XP_BASE_TO_LEVEL := 1000.0
const SKILL_XP_PER_LEVEL_SQUARED := 75.0
## Acima de 4.000 XP no mesmo dia, numa habilidade, o ganho cai para ×0,2.
const SKILL_DAILY_XP_SOFT_CAP := 4000.0
const SKILL_OVER_CAP_XP_FACTOR := 0.2
## Esquecimento: acima do nível 12 sem praticar, −40 XP por dia (−80 acima do 16).
const SKILL_FORGET_FROM_LEVEL := 12
const SKILL_FORGET_FAST_FROM_LEVEL := 16
const SKILL_FORGET_XP_PER_DAY := 40.0
const SKILL_FORGET_FAST_XP_PER_DAY := 80.0
## Idade: até 17 anos ×1,3; de 60 em diante ×0,7.
const XP_YOUNG_MAX_AGE := 17
const XP_YOUNG_FACTOR := 1.3
const XP_OLD_MIN_AGE := 60
const XP_OLD_FACTOR := 0.7
## Humor: contente ou melhor ×1,1; instável ou pior ×0,8.
const XP_CONTENT_FACTOR := 1.1
const XP_UNSTABLE_FACTOR := 0.8

# --- Geração de colonos (GDD: Geração e raridade) ---
const COLONIST_MIN_AGE := 16
const COLONIST_MAX_AGE := 70
## A maioria entre 20 e 45 anos.
const COLONIST_AGE_MEAN := 32.0
const COLONIST_AGE_DEVIATION := 9.0
## Habilidades começam entre 0 e 3, mais os bônus das histórias.
const SKILL_START_MAX := 3
## Adultos ganham +1 a cada 10 anos (depois dos 20) nas habilidades da vida adulta.
const ADULT_SKILL_YEARS_PER_LEVEL := 10
const ADULT_SKILL_FROM_AGE := 20
## Teto: a soma de todos os níveis não passa de 70.
const SKILL_SUM_CAP := 70
## De 1 a 3 interesses ou paixões (1 em 3 é paixão), de 0 a 2 aversões.
const PASSION_CHANCE := 1.0 / 3.0
## Chance de cada interesse cair numa habilidade das histórias do colono (provisório).
const STORY_AFFINITY_BIAS := 0.5
## Traços: 1 a 3 (provisório: 50% um, 35% dois, 15% três).
const TRAIT_TWO_CHANCE := 0.35
const TRAIT_THREE_CHANCE := 0.15
const STRONG_STRENGTH_BONUS := 2
## Glutão come 30% a mais: a fome cai 1,3× mais rápido.
const GLUTTON_HUNGER_FACTOR := 1.3
## Covarde recusa tarefas a até 10 tiles de um predador.
const COWARD_DANGER_RADIUS := 10

# --- Humor (GDD: Humor; pensamentos do MVP provisórios) ---
const MOOD_MAX := 100.0
const MOOD_START := 50.0
## Abaixo de 35 o colono fica instável; abaixo de 25, em crise (GDD: Humor > Faixa).
const MOOD_UNSTABLE_BELOW := 35.0
const MOOD_CRISIS_BELOW := 25.0
## O humor anda cerca de 12 pontos por dia em direção ao alvo.
const MOOD_SPEED_PER_TICK := 12.0 / TICKS_PER_DAY
## Expectativa de um assentamento (porte inicial).
const MOOD_EXPECTATION_SETTLEMENT := 0.0
const OPTIMIST_MOOD := 6.0
const PESSIMIST_MOOD := -6.0
const HUNGRY_MOOD := -6.0
const STARVING_MOOD := -12.0
const TIRED_MOOD := -5.0
const EXHAUSTED_MOOD := -10.0
## Dormir no chão pesa por 12 h depois de acordar.
const SLEPT_ON_GROUND_MOOD := -4.0
const SLEPT_ON_GROUND_HOURS := 12
## Afinidade ao trabalhar: interesse +1/h (até +6), paixão +2/h (até +10), aversão -2/h (até -10).
## O sentimento some devagar sem trabalhar na habilidade (provisório: 0,25 por hora).
const WORK_FEELING_PER_HOUR := {Skills.Affinity.INTEREST: 1.0, Skills.Affinity.PASSION: 2.0, Skills.Affinity.AVERSION: -2.0}
const WORK_FEELING_CAP := {Skills.Affinity.INTEREST: 6.0, Skills.Affinity.PASSION: 10.0, Skills.Affinity.AVERSION: -10.0}
const WORK_FEELING_DECAY_PER_HOUR := 0.25

# --- Agenda (GDD: Agenda; padrão provisório) ---
## Horas de cada bloco padrão: dormir das 22 às 6, livre das 20 às 22, trabalhar no resto.
const SCHEDULE_SLEEP_START := 22
const SCHEDULE_SLEEP_END := 6
const SCHEDULE_FREE_START := 20
## No bloco Dormir, vai dormir se o sono estiver abaixo disto.
const SCHEDULE_SLEEP_BELOW := 90.0

# --- Equipamento e carga (GDD: Inventário e carga, Equipamento) ---
## Acima de 100% da capacidade o movimento cai 20%; acima de 125%, 50%.
const LOAD_SLOW_RATIO := 1.0
const LOAD_SLOWER_RATIO := 1.25
const LOAD_SLOW_FACTOR := 0.8
const LOAD_SLOWER_FACTOR := 0.5
## Arma improvisada de caça (pedras, galhos) quando a mão está vazia.
const UNARMED_HUNT_RANGE := 6
const UNARMED_HUNT_DAMAGE := 8.0
## Ferramenta melhor só é buscada se estiver a até este custo de caminho.
const TOOL_SEARCH_MAX_DISTANCE := 40

# --- Pesquisa e ruína (GDD: Quanto cada ação rende) ---
## A cada 3 horas de trabalho produtivo, 1 P.
const PRACTICE_POINT_WORK_TICKS := 3 * TICKS_PER_HOUR
## Fazer algo pela primeira vez: +3 P.
const FIRST_TIME_PRACTICE := 3.0
## Investigar uma sala de ruína: 2 V. Encontrar artefato: 5 a 15 V (o do MVP vale 15).
const RUIN_ROOM_RELIC := 2.0
const ARTIFACT_FOUND_RELIC := 15.0
## Curioso: +25% em todos os pontos que gera; ×1,3 na pontuação de tarefas com artefatos.
const CURIOUS_POINTS_FACTOR := 1.25
const CURIOUS_ARTIFACT_SCORE := 1.3
## Investigar uma sala leva 1 h (provisório). As salas sem artefato guardam sucata.
const RUIN_INVESTIGATE_TICKS := TICKS_PER_HOUR
const RUIN_ROOM_SCRAP := 4
## A ruína fica entre 20 e 40 tiles da chegada.
const RUIN_MIN_DISTANCE := 20.0
const RUIN_MAX_DISTANCE := 40.0

# --- Início da partida (GDD: BALANÇA, comida para ~15 dias) ---
const STARTING_FOOD_DAYS := 15.0
const STARTING_WOOD := 100
const STARTING_CRATES := 2
## Recursos × (1 + 0,15 × (5 - colonos)).
const STARTING_BONUS_PER_MISSING_COLONIST := 0.15
const MAX_STARTING_COLONISTS := 5
const DAILY_FOOD_NEED := FOOD_DECAY_PER_TICK * TICKS_PER_DAY

# --- Câmera (GDD: O que cabe na tela) ---
## Escalas fixas da câmera, em múltiplos inteiros da arte. 1.0 mostra ~40×22 tiles em 640×360.
const ZOOM_LEVELS := [0.5, 1.0, 2.0]
const DEFAULT_ZOOM_INDEX := 1
const CAMERA_PAN_SPEED := 240.0

# --- Saúde e ferimentos (M7; números provisórios, o GDD não os define) ---
const HEALTH_MAX := 100.0
## Caído a partir de 60 de dano ou 50% de perda de sangue; morto com 100 de dano ou 100% de sangue.
const DOWNED_DAMAGE := 60.0
const DOWNED_BLOOD_LOSS := 50.0
const MAX_BLOOD_LOSS := 100.0
## Cada ponto de dano de um ferimento que sangra (sem tratar) tira 0,5% de sangue por hora.
const BLEED_PER_DAMAGE_HOUR := 0.5
## Sem sangrar, o sangue volta 4% por hora.
const BLOOD_RECOVERY_PER_HOUR := 4.0
## Cura por hora de cada ferimento: sem tratar, tratado; deitado numa cama, ×1,5.
const HEAL_UNTENDED_PER_HOUR := 0.5
const HEAL_TENDED_PER_HOUR := 2.0
const HEAL_BED_FACTOR := 1.5
## A dor reduz trabalho e movimento: até -50% com o dano no máximo.
const PAIN_SPEED_LOSS := 0.5
## Com 30 de dano ou mais, o colono vai repousar numa cama até baixar de 15.
const REST_DAMAGE := 30.0
const REST_UNTIL_DAMAGE := 15.0
## Tratar os próprios ferimentos (45 min) ou os de um caído (30 min, Emergência).
const TEND_SELF_TICKS := TICKS_PER_HOUR * 3 / 4
const TEND_TICKS := TICKS_PER_HOUR / 2
## Socorrer e tratar: urgência alta e crítica no quadro (GDD: paciente em risco).
const RESCUE_URGENCY := 2
const TEND_URGENCY := 3
const DEFAULT_EMERGENCY_PRIORITY := 1
## Humor: dor (-1 a cada 10 de dano) e morte de alguém da comunidade (-8 por 3 dias).
const PAIN_MOOD_PER_DAMAGE := -0.1
const COLONIST_DIED_MOOD := -8.0
const COLONIST_DIED_HOURS := 72

# --- Combate (M7) ---
## Sem arma: soco, alcance 1, dano 5, sem sangrar.
const UNARMED_ATTACK_DAMAGE := 5.0
const MELEE_ATTACK_TICKS := TICKS_PER_SECOND
const RANGED_ATTACK_TICKS := 2 * TICKS_PER_SECOND
## Acerto corpo a corpo: 55% + 3,5% por nível de Corpo a corpo (30% a 95%).
const MELEE_HIT_BASE := 0.55
const MELEE_HIT_PER_LEVEL := 0.035
## Acerto à distância: 80% - 4% por tile + 2% por nível (25% a 95%).
const RANGED_HIT_BASE := 0.8
const RANGED_HIT_FALLOFF_PER_TILE := 0.04
const RANGED_HIT_PER_LEVEL := 0.02
const HIT_CHANCE_MIN := 0.25
const HIT_CHANCE_MAX := 0.95
## Dano varia ±20% a cada golpe.
const DAMAGE_SPREAD := 0.2
## Convocado com arma corpo a corpo vai até inimigos a até 6 tiles.
const DRAFTED_MELEE_ENGAGE := 6
## Não convocado foge de saqueadores a até 8 tiles (Covarde: 12), correndo 12 tiles.
const FLEE_RAIDER_RADIUS := 8
const COWARD_FLEE_RAIDER_RADIUS := 12
const FLEE_DISTANCE := 12
## Covarde convocado foge com 25 de dano ou mais (GDD: pode fugir em combate).
const COWARD_BREAK_DAMAGE := 25.0
## Cada golpe de combate dá XP de Corpo a corpo como este tanto de ticks de trabalho.
const COMBAT_XP_TICKS := 120

# --- Ameaça (GDD: Pontos de ameaça, Parâmetros das IAs; MVP: BALANÇA fixa) ---
const AI_MULTIPLIER := 1.0
const THREAT_POINTS_CAP := 6000
const THREAT_POINTS_MIN := 35
## Riqueza → P_riqueza (interpolação linear).
const WEALTH_POINTS := [Vector2(10000, 0), Vector2(100000, 600), Vector2(300000, 1800), Vector2(600000, 3000), Vector2(1000000, 4000)]
## Pontos por colono capaz de lutar, por faixa (1 a 5, 6 a 10, 11 a 20, 21+). Feridos contam 25%.
const COLONIST_POINTS := [[5, 25], [10, 45], [20, 70], [1000000, 100]]
const WOUNDED_FIGHTER_SHARE := 0.25
## M_início = mín(1; 0,3 + 0,07 × dia).
const START_FACTOR_BASE := 0.3
const START_FACTOR_PER_DAY := 0.07
## M_adaptação: -0,15 por morte (mínimo 0,5); +0,01 por dia sem perdas, até o teto de 1,15.
const ADAPTATION_DEATH_LOSS := 0.15
const ADAPTATION_MIN := 0.5
const ADAPTATION_DAILY_GAIN := 0.01
const ADAPTATION_CAP := 1.15
## O primeiro ataque chega no dia 6; depois, a cada 5 a 9 dias (média 7, BALANÇA).
const FIRST_RAID_DAY := 6
const RAID_INTERVAL_MIN_DAYS := 5
const RAID_INTERVAL_MAX_DAYS := 9
## Chegam entre 8 h e 18 h. Aviso base de 1,5 dia (BALANÇA).
const RAID_EARLIEST_HOUR := 8
const RAID_LATEST_HOUR := 18
const RAID_WARNING_TICKS := TICKS_PER_DAY * 3 / 2
## Calma depois da crise = (2 + 10 × perdidos ÷ total) dias × fator de recuperação 1,0.
const CALM_BASE_DAYS := 2.0
const CALM_DAYS_PER_LOSS_SHARE := 10.0
const RECOVERY_FACTOR := 1.0
## Saqueadores: perseguem colonos até 14 tiles; fogem com 50 de dano; levam até 25 kg;
## o grupo recua quando metade foi perdida ou já saqueou; desiste depois de 12 h no mapa.
const RAIDER_SIGHT := 14
## Com objetivo (saquear), só atacam quem chega a 7 tiles (o arqueiro, ao alcance do arco) ou
## quem os atacou; largam o alvo que fugir para além de 14 tiles.
const RAIDER_ENGAGE_RADIUS := 7
const RAIDER_FLEE_DAMAGE := 50.0
const RAIDER_LOOT_KG := 25.0
const RAIDER_MAX_HOURS := 12
const RAIDER_THINK_TICKS := 30
const RAIDER_MOVE_TILES_PER_TICK := 2.8 / TICKS_PER_SECOND
const RAIDER_MELEE_MIN := 3
const RAIDER_MELEE_MAX := 7
## A fumaça do aviso aparece a 6 tiles da borda.
const SMOKE_INSET := 6
