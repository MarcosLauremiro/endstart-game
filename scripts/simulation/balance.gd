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
const SEASONS_PER_YEAR := 4
## Limite de ticks executados num quadro, para evitar espiral de atraso após travamentos.
const MAX_TICKS_PER_FRAME := 120

# --- Mapa (GDD: Mapa jogável > Proporções) ---
const TILE_SIZE := 16
const MAP_SIZE := Vector2i(128, 128)
const DEFAULT_SEED := 20261030

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
## Caça com arma simples improvisada: atira a até 7 tiles, uma vez a cada 1,5 s de jogo.
## Arco e lança mudam alcance e dano quando o equipamento entrar (M5) e o combate (M7).
const HUNT_RANGE_TILES := 7
const HUNT_AIM_TICKS := 90
const HUNT_DAMAGE := 10.0
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

# --- Início da partida (GDD: BALANÇA, comida para ~15 dias) ---
const STARTING_FOOD_DAYS := 15.0
const STARTING_WOOD := 100
const STARTING_CRATES := 2
## Recursos × (1 + 0,15 × (5 − colonos)).
const STARTING_BONUS_PER_MISSING_COLONIST := 0.15
const MAX_STARTING_COLONISTS := 5
const DAILY_FOOD_NEED := FOOD_DECAY_PER_TICK * TICKS_PER_DAY

# --- Câmera (GDD: O que cabe na tela) ---
## Escalas fixas da câmera, em múltiplos inteiros da arte. 1.0 mostra ~40×22 tiles em 640×360.
const ZOOM_LEVELS := [0.5, 1.0, 2.0]
const DEFAULT_ZOOM_INDEX := 1
const CAMERA_PAN_SPEED := 240.0
