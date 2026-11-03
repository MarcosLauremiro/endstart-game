class_name StructureDef
extends Resource
## Definição de uma estrutura construível (GDD: Construções, Bancadas, Tipos de contêiner).
## Um .tres por estrutura em res://resources/structures/.

## Camada da construção: pisos ficam por baixo e podem dividir o tile com uma estrutura.
enum Layer { BUILDING, FLOOR }
## Como o jogador coloca: um por clique, área cheia arrastando, ou contorno do retângulo (paredes).
enum Placement { SINGLE, AREA, OUTLINE }

@export var id: StringName
@export var display_name: String
@export var layer: Layer = Layer.BUILDING
@export var placement: Placement = Placement.SINGLE
@export var footprint: Vector2i = Vector2i.ONE
## Materiais: id do item → quantidade.
@export var costs: Dictionary = {}
@export var work_hours: float = 0.5
## Até quantos colonos trabalham juntos (GDD: ajuda mútua, até 3 em construções grandes).
@export var max_workers: int = 1
@export var blocks_movement: bool = false
## Fator de movimento de quem pisa (GDD: piso construído 110%).
@export var move_factor: float = 1.0
## Resistência do GDD (usada a partir do M7).
@export var hit_points: int = 100
@export var is_bed: bool = false
## Se concluída vira um contêiner com este id de ContainerDef (vazio = não).
@export var container_def: StringName = &""
## Bancada: tipo de trabalho de quem opera ("cook" ou "craft"; vazio = não é bancada).
@export var bench_work: StringName = &""
## Velocidade da bancada (GDD: rústica ×0,8).
@export var bench_speed: float = 1.0
## Aparece no menu de construção (estruturas da ruína já vêm prontas no mapa).
@export var buildable: bool = true
## Id da arte no AssetCatalog.
@export var asset: String
## A arte tem 16 quadros, um por combinação de vizinhos que ligam (N=1, L=2, S=4, O=8): paredes.
@export var wall_tiles: bool = false
## Paredes vizinhas se ligam a esta (paredes, portas e as peças da ruína).
@export var joins_walls: bool = false


## Tiles ocupados a partir da célula de origem (canto superior esquerdo).
func cells_at(origin: Vector2i) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for y in footprint.y:
		for x in footprint.x:
			result.append(origin + Vector2i(x, y))
	return result


func is_workbench() -> bool:
	return bench_work != &""


func work_ticks() -> float:
	return work_hours * Balance.TICKS_PER_HOUR


func cost_text() -> String:
	var parts := PackedStringArray()
	for item in costs:
		parts.append("%d %s" % [costs[item], Defs.item(item).display_name.to_lower()])
	return ", ".join(parts)
