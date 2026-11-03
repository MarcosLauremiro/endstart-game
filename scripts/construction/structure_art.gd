class_name StructureArt
extends RefCounted
## Recorte da arte de uma construção. Paredes com `wall_tiles` têm 16 quadros de 16×24, um por
## combinação de vizinhos que ligam: quadro = N 1 + L 2 + S 4 + O 8. Ligam as estruturas prontas
## e as plantas com `joins_walls` (paredes, portas, peças da ruína). A face da parede só aparece
## com o sul aberto. Só lê o WorldState.

const NORTH := 1
const EAST := 2
const SOUTH := 4
const WEST := 8
const _SIDES := {NORTH: Vector2i.UP, EAST: Vector2i.RIGHT, SOUTH: Vector2i.DOWN, WEST: Vector2i.LEFT}


## Recorte da textura para a construção em `origin`. `extra` são células que também ligam
## (a prévia das paredes que o jogador está arrastando).
static func region(state: WorldState, def: StructureDef, origin: Vector2i, extra := {}) -> Rect2:
	if not def.wall_tiles:
		return Rect2(Vector2.ZERO, AssetCatalog.texture(def.asset).get_size())
	return AssetCatalog.frame_region(def.asset, wall_mask(state, origin, extra), 0)


static func wall_mask(state: WorldState, cell: Vector2i, extra := {}) -> int:
	var mask := 0
	for bit in _SIDES:
		if joins_at(state, cell + _SIDES[bit], extra):
			mask |= bit
	return mask


## Há na célula uma estrutura ou planta à qual as paredes se ligam?
static func joins_at(state: WorldState, cell: Vector2i, extra := {}) -> bool:
	if extra.has(cell):
		return true
	var structure: Structure = state.buildings_by_cell.get(cell)
	if structure and structure.def.joins_walls:
		return true
	var site: ConstructionSite = state.building_sites_by_cell.get(cell)
	return site != null and site.def.joins_walls
