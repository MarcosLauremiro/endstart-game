class_name AssetCatalog
extends RefCounted
## Lista única de toda a arte do MVP: caminho, tamanho esperado e uso.
## O jogo carrega texturas por aqui. tools/generate_placeholder_assets.gd cria os PNGs provisórios
## que faltarem e gera assets/LISTA_DE_ASSETS.md. Para trocar uma arte, substitua o PNG
## mantendo o mesmo nome e o mesmo tamanho.

const ROOT := "res://assets/"
const LIST_PATH := "res://assets/LISTA_DE_ASSETS.md"
const FONT_DIR := "res://assets/ui/fonts/"

## id (caminho sem extensão, relativo a assets/) → tamanho, cor provisória, uso e desenho provisório.
## "frames" (colunas × linhas) marca uma folha de sprites; cada quadro tem tamanho ÷ frames.
const ENTRIES := {
	# --- Terreno (TileMapLayer Terreno) ---
	# Folhas de chão: cada variante é um bloco de 6×3 tiles (96×48) com as 16 combinações de cantos
	# da grade dupla, grama por cima do terreno da folha (ver TerrainTiles).
	"tiles/terrain/grass_variants": {"size": Vector2i(96, 480), "frames": Vector2i(6, 30), "color": "468135",
		"use": "Chão: 10 gramas sobre a terra comum (a 2ª é a grama padrão; a 3ª é a grama alta)"},
	"tiles/terrain/dirt_variants": {"size": Vector2i(96, 480), "frames": Vector2i(6, 30), "color": "745b48",
		"use": "Chão: grama sobre 10 terras (a 1ª é o solo e o chão embaixo da rocha)"},
	"tiles/terrain/water_variants": {"size": Vector2i(96, 480), "frames": Vector2i(6, 30), "color": "497a9e",
		"use": "Chão: grama sobre 10 águas (a 4ª é a água rasa, a 2ª a funda)"},
	"tiles/terrain/sand_variants": {"size": Vector2i(96, 384), "frames": Vector2i(6, 24), "color": "e0cea7",
		"use": "Chão: grama sobre 8 areias (fora do MVP)"},
	"tiles/terrain/mud_swamp_variants": {"size": Vector2i(96, 336), "frames": Vector2i(6, 21), "color": "6e5139",
		"use": "Chão: grama sobre 7 lamas e solos de pântano (fora do MVP)"},
	"tiles/terrain/snow_ice_variants": {"size": Vector2i(96, 432), "frames": Vector2i(6, 27), "color": "dee5ed",
		"use": "Chão: grama sobre 9 neves e gelos (fora do MVP)"},
	"tiles/terrain/stone_variants": {"size": Vector2i(96, 384), "frames": Vector2i(6, 24), "color": "95958f",
		"use": "Chão: grama sobre 8 pedras e cascalhos (fora do MVP)"},
	"tiles/terrain/special_variants": {"size": Vector2i(96, 384), "frames": Vector2i(6, 24), "color": "5d8539",
		"use": "Chão: grama sobre 8 terrenos especiais: musgo, fungos, vulcânico, cinzas, radioativo... (fora do MVP)"},
	"tiles/terrain/rock_walls": {"size": Vector2i(256, 320), "frames": Vector2i(16, 20), "color": "6b6b6b",
		"use": "Paredes de montanha: 13 materiais em blocos de 4×5 (16 tiles pelos vizinhos N/L/S/O, chão de caverna, sombra, entulho). Usa a 8ª (parede natural)"},
	"tiles/terrain/ore_deposits": {"size": Vector2i(112, 128), "frames": Vector2i(7, 8), "color": "b0623a",
		"use": "Minérios (fora do MVP). Linhas: ferro, cobre, ouro, prata, carvão, cristais, quartzo, enxofre. Colunas: escondido, exposto, rico, espalhado, meio extraído, esgotado, pilha"},
	"tiles/terrain/mining_props": {"size": Vector2i(128, 64), "frames": Vector2i(8, 4), "color": "6a6a6a",
		"use": "Mineração (fora do MVP): estágios da rocha, entulho, trilhos, carrinhos; entrada de caverna e vigas em 32×32"},
	"tiles/terrain/ground_overlays": {"size": Vector2i(128, 160), "frames": Vector2i(8, 10), "color": "8a9a6a",
		"use": "Detalhes sobre o chão (fora do MVP): 30 de 16×16 (pedrinhas, flores, folhas, pegadas, poças...) e 10 de 32×32"},
	# --- Pisos ---
	"tiles/floors/wood_floor": {"size": Vector2i(16, 16), "color": "9a6b3f", "use": "Piso de madeira", "draw": "speckle"},
	# --- Estruturas (1 tile de base; paredes e portas sobem 8 px acima do tile) ---
	"structures/wall_wood": {"size": Vector2i(256, 24), "frames": Vector2i(16, 1), "color": "8a5a32",
		"use": "Parede de madeira: 16 quadros de 16×24, um por vizinhos que ligam (quadro = N 1 + L 2 + S 4 + O 8); a face só aparece com o sul aberto"},
	"structures/wall_stone": {"size": Vector2i(256, 24), "frames": Vector2i(16, 1), "color": "8c8a85",
		"use": "Parede de pedra: 16 quadros de 16×24, um por vizinhos que ligam (quadro = N 1 + L 2 + S 4 + O 8); a face só aparece com o sul aberto"},
	"structures/door_simple": {"size": Vector2i(16, 24), "color": "a8763f", "use": "Porta simples"},
	"structures/bed_rustic": {"size": Vector2i(16, 32), "color": "b0805a", "use": "Cama rústica (1×2 tiles)"},
	"structures/campfire": {"size": Vector2i(16, 16), "color": "e0782f", "use": "Fogueira"},
	"structures/table": {"size": Vector2i(32, 16), "color": "9a6b3f", "use": "Mesa simples (2×1 tiles)"},
	# --- Bancadas ---
	"workstations/crafting_bench": {"size": Vector2i(48, 16), "color": "7d5a3c", "use": "Bancada de produção rústica (3×1)"},
	"workstations/cooking_bench": {"size": Vector2i(48, 16), "color": "8c6a4a", "use": "Bancada de cozinha (3×1)"},
	"workstations/study_desk": {"size": Vector2i(32, 32), "color": "6e5038", "use": "Mesa de estudos (2×2)"},
	"workstations/analysis_table": {"size": Vector2i(32, 16), "color": "4f6f73", "use": "Mesa de análise (2×1)"},
	# --- Contêineres ---
	"containers/crate": {"size": Vector2i(16, 16), "color": "a07a4a", "use": "Caixote"},
	"containers/chest_rustic": {"size": Vector2i(16, 16), "color": "7a4a32", "use": "Baú rústico"},
	"containers/material_yard": {"size": Vector2i(32, 32), "color": "6a5a48", "use": "Pátio de materiais (2×2)"},
	# --- Plantas (folhas de sprites 16×16; linhas = estações na ordem de GameClock.Season) ---
	"plants/trees": {"size": Vector2i(128, 128), "frames": Vector2i(4, 4), "color": "2f5a2a",
		"use": "Árvore em quadros de 32×32 (maior que o colono), apoiada no tile pela base. Colunas: toco da jovem, toco da adulta, jovem, adulta. Linhas: primavera, verão, outono, inverno"},
	"plants/berry_bushs": {"size": Vector2i(48, 64), "frames": Vector2i(3, 4), "color": "5a7a3a",
		"use": "Arbusto de frutas. Colunas: muda, sem frutas, com frutas. Linhas: estações"},
	"plants/low_growing_vegetation": {"size": Vector2i(32, 64), "frames": Vector2i(2, 4), "color": "8a9a4a",
		"use": "Planta de fibra. Colunas: pequena, crescida (colhível). Linhas: estações"},
	"plants/Wheatfield": {"size": Vector2i(64, 16), "frames": Vector2i(4, 1), "color": "c8b060",
		"use": "Trigo na plantação. Colunas: 4 fases de crescimento, a última é madura"},
	"plants/carrot": {"size": Vector2i(48, 16), "frames": Vector2i(3, 1), "color": "e08a3a",
		"use": "Cenoura na plantação. Colunas: 3 fases de crescimento, a última é madura"},
	"plants/mushroom": {"size": Vector2i(32, 16), "frames": Vector2i(2, 1), "color": "a07850",
		"use": "Cogumelo na plantação. Colunas: 2 fases de crescimento, a última é madura"},
	"plants/Rocks": {"size": Vector2i(48, 64), "frames": Vector2i(3, 4), "color": "9a9a9a",
		"use": "Pedras soltas, 3 variações. Linhas: estações (ainda sem uso)"},
	"plants/DeadTrees": {"size": Vector2i(64, 16), "frames": Vector2i(4, 1), "color": "c09060",
		"use": "Árvore seca: 2 tocos e 2 árvores (fora do MVP)"},
	"plants/WinterDeadTrees": {"size": Vector2i(64, 16), "frames": Vector2i(4, 1), "color": "a09080",
		"use": "Árvore seca com neve: 2 tocos e 2 árvores (fora do MVP)"},
	"plants/Cactus": {"size": Vector2i(64, 32), "frames": Vector2i(4, 2), "color": "6ab04a",
		"use": "Cactos, 8 variações (bioma deserto, fora do MVP)"},
	"plants/CoconutTrees": {"size": Vector2i(96, 16), "frames": Vector2i(6, 1), "color": "7ab04a",
		"use": "Coqueiros: 2 tocos e 4 variações (litoral, fora do MVP)"},
	# --- Objetos do mapa ---
	"objects/scrap_pile": {"size": Vector2i(16, 16), "color": "6f6a62", "use": "Monte de sucata"},
	# --- Ruína ---
	"ruins/ruin_wall": {"size": Vector2i(16, 24), "color": "5a6a6e", "use": "Parede da ruína"},
	"ruins/ruin_floor": {"size": Vector2i(16, 16), "color": "4a5458", "use": "Piso da ruína", "draw": "speckle"},
	"ruins/ruin_door": {"size": Vector2i(16, 24), "color": "3fe0d0", "use": "Porta da ruína"},
	# --- Itens (ícones e pilhas no chão) ---
	"items/wood": {"size": Vector2i(16, 16), "color": "8a5a32", "use": "Madeira"},
	"items/stone_raw": {"size": Vector2i(16, 16), "color": "7a7a7a", "use": "Pedra bruta"},
	"items/stone_block": {"size": Vector2i(16, 16), "color": "a0a0a0", "use": "Blocos de pedra"},
	"items/fiber": {"size": Vector2i(16, 16), "color": "b0b06a", "use": "Fibra"},
	"items/raw_meat": {"size": Vector2i(16, 16), "color": "b04a4a", "use": "Carne crua"},
	"items/carrot": {"size": Vector2i(16, 16), "color": "e08a3a", "use": "Cenoura (colhida)"},
	"items/wheat": {"size": Vector2i(16, 16), "color": "d8c070", "use": "Trigo (colhido)"},
	"items/mushroom": {"size": Vector2i(16, 16), "color": "a07850", "use": "Cogumelo (colhido)"},
	"items/berries": {"size": Vector2i(16, 16), "color": "8a3a6a", "use": "Frutas silvestres"},
	"items/simple_meal": {"size": Vector2i(16, 16), "color": "e0b060", "use": "Refeição simples"},
	"items/scrap": {"size": Vector2i(16, 16), "color": "6f6a62", "use": "Sucata"},
	"items/stone_knife": {"size": Vector2i(16, 16), "color": "9a9285", "use": "Faca de pedra"},
	"items/stone_axe": {"size": Vector2i(16, 16), "color": "8a8275", "use": "Machado de pedra"},
	"items/stone_pickaxe": {"size": Vector2i(16, 16), "color": "7a7265", "use": "Picareta de pedra"},
	"items/wooden_spear": {"size": Vector2i(16, 16), "color": "a8763f", "use": "Lança de madeira"},
	"items/bow": {"size": Vector2i(16, 16), "color": "9a6b3f", "use": "Arco"},
	"items/arrows": {"size": Vector2i(16, 16), "color": "c8a070", "use": "Flechas"},
	"items/hide": {"size": Vector2i(16, 16), "color": "b08a5a", "use": "Pele"},
	"items/fat": {"size": Vector2i(16, 16), "color": "e8d8a0", "use": "Gordura"},
	"items/small_game_carcass": {"size": Vector2i(16, 16), "color": "8a6a4a", "use": "Carcaça de lebre (caça pequena)"},
	"items/large_game_carcass": {"size": Vector2i(16, 16), "color": "6a4a3a", "use": "Carcaça de cervo (caça grande)"},
	"items/tunic": {"size": Vector2i(16, 16), "color": "a89a7a", "use": "Túnica simples (roupa inicial, espaço Camisa)"},
	"items/trousers": {"size": Vector2i(16, 16), "color": "6a5a48", "use": "Calça de pano (roupa inicial, espaço Calça)"},
	"items/artifact": {"size": Vector2i(16, 16), "color": "3fe0d0", "use": "Artefato da ruína"},
	# --- Personagens ---
	"characters/colonists/colonist": {"size": Vector2i(16, 24), "color": "d0a070", "use": "Colono provisório (fora de uso: o colono é montado das três folhas abaixo)"},
	"characters/colonists/character_base": {"size": Vector2i(128, 120), "frames": Vector2i(8, 5), "color": "ffffff",
		"use": "Corpo do colono (branco, tingido pela pele). Linha 0: parado de frente; linhas 1-4: caminhada de 8 quadros de frente, costas, esquerda e direita. Fonte: character_base.aseprite"},
	"characters/colonists/hair": {"size": Vector2i(528, 480), "frames": Vector2i(33, 20), "color": "915832",
		"use": "Cabelos: uma linha por estilo (20), 33 quadros na ordem parado de frente + caminhadas de frente, costas, esquerda e direita. Rampa indexada de 4 marrons. Fonte: hair.aseprite"},
	"characters/colonists/clothing": {"size": Vector2i(528, 168), "frames": Vector2i(33, 7), "color": "5f7fa6",
		"use": "Roupas: camisa, regata, casaco, top, calça, short e saia, mesmos 33 quadros do cabelo. Rampa indexada de 4 azuis. Fonte: clothing.aseprite"},
	"characters/animals/small_game": {"size": Vector2i(16, 16), "color": "a08060", "use": "Lebre (caça pequena)"},
	"characters/animals/large_game": {"size": Vector2i(32, 24), "color": "8a6a4a", "use": "Cervo (caça grande), pés no tile de base"},
	"characters/animals/predator": {"size": Vector2i(32, 24), "color": "5a5a5a", "use": "Lobo-espinho (predador), pés no tile de base"},
	"characters/enemies/raider_spear": {"size": Vector2i(16, 24), "color": "b04a3a", "use": "Saqueador com lança"},
	"characters/enemies/raider_archer": {"size": Vector2i(16, 24), "color": "a05a3a", "use": "Saqueador arqueiro"},
	# --- Efeitos ---
	"effects/arrow_projectile": {"size": Vector2i(8, 8), "color": "c8a070", "use": "Flecha em voo"},
	# --- Interface: molduras 9-slice ---
	"ui/frames/panel": {"size": Vector2i(48, 48), "color": "7a4a32", "use": "Moldura de painel 9-slice, cantos de 16 px", "draw": "frame", "corner": 16},
	"ui/frames/button": {"size": Vector2i(24, 24), "color": "7a4a32", "use": "Botão normal 9-slice, cantos de 8 px", "draw": "frame", "corner": 8},
	"ui/frames/button_hover": {"size": Vector2i(24, 24), "color": "a8663f", "use": "Botão com mouse em cima, 9-slice", "draw": "frame", "corner": 8},
	"ui/frames/button_pressed": {"size": Vector2i(24, 24), "color": "f2a541", "use": "Botão ativo/pressionado, 9-slice", "draw": "frame", "corner": 8},
	# --- Interface: ícones ---
	"ui/icons/time/pause": {"size": Vector2i(16, 16), "color": "e8dcc0", "use": "Pausar", "draw": "pause"},
	"ui/icons/time/speed_1": {"size": Vector2i(16, 16), "color": "e8dcc0", "use": "Velocidade normal (1×)", "draw": "play", "count": 1},
	"ui/icons/time/speed_2": {"size": Vector2i(16, 16), "color": "e8dcc0", "use": "Velocidade rápida (3×)", "draw": "play", "count": 2},
	"ui/icons/time/speed_3": {"size": Vector2i(16, 16), "color": "e8dcc0", "use": "Velocidade muito rápida (6×)", "draw": "play", "count": 3},
	"ui/icons/needs/hunger": {"size": Vector2i(16, 16), "color": "e0b060", "use": "Necessidade: fome"},
	"ui/icons/needs/sleep": {"size": Vector2i(16, 16), "color": "6a7ab0", "use": "Necessidade: sono"},
	"ui/icons/needs/mood": {"size": Vector2i(16, 16), "color": "7bc96f", "use": "Humor"},
	"ui/icons/status/sleeping": {"size": Vector2i(16, 16), "color": "6a7ab0", "use": "Estado: dormindo"},
	"ui/icons/status/injured": {"size": Vector2i(16, 16), "color": "e5534b", "use": "Estado: ferido"},
	"ui/icons/status/crisis": {"size": Vector2i(16, 16), "color": "9b7bd8", "use": "Estado: em crise"},
	"ui/icons/status/drafted": {"size": Vector2i(16, 16), "color": "f2a541", "use": "Estado: convocado"},
	"ui/icons/orders/cut": {"size": Vector2i(16, 16), "color": "8a5a32", "use": "Ordem: cortar plantas"},
	"ui/icons/orders/mine": {"size": Vector2i(16, 16), "color": "7a7a7a", "use": "Ordem: minerar"},
	"ui/icons/orders/harvest": {"size": Vector2i(16, 16), "color": "7bc96f", "use": "Ordem: colher"},
	"ui/icons/orders/hunt": {"size": Vector2i(16, 16), "color": "e5534b", "use": "Ordem: caçar"},
	"ui/icons/orders/grow_zone": {"size": Vector2i(16, 16), "color": "7bc96f", "use": "Ordem: zona de plantação"},
	"ui/icons/orders/prioritize": {"size": Vector2i(16, 16), "color": "f2a541", "use": "Ordem: priorizar tarefa"},
	"ui/icons/orders/deconstruct": {"size": Vector2i(16, 16), "color": "a8663f", "use": "Ordem: desmontar"},
	"ui/icons/orders/cancel": {"size": Vector2i(16, 16), "color": "9a9285", "use": "Ordem: cancelar"},
	"ui/icons/tabs/build": {"size": Vector2i(16, 16), "color": "f2a541", "use": "Aba Construir"},
	"ui/icons/tabs/orders": {"size": Vector2i(16, 16), "color": "f2a541", "use": "Aba Ordens"},
	"ui/icons/tabs/work": {"size": Vector2i(16, 16), "color": "f2a541", "use": "Aba Trabalho"},
	"ui/icons/tabs/schedule": {"size": Vector2i(16, 16), "color": "f2a541", "use": "Aba Agenda"},
	"ui/icons/tabs/colonists": {"size": Vector2i(16, 16), "color": "f2a541", "use": "Aba Colonos"},
	"ui/icons/tabs/storage": {"size": Vector2i(16, 16), "color": "f2a541", "use": "Aba Armazém"},
	"ui/icons/tabs/research": {"size": Vector2i(16, 16), "color": "3fe0d0", "use": "Aba Pesquisa"},
	"ui/icons/tabs/diary": {"size": Vector2i(16, 16), "color": "9b7bd8", "use": "Aba Diário"},
	"ui/icons/tabs/menu": {"size": Vector2i(16, 16), "color": "9a9285", "use": "Aba Menu"},
	"ui/icons/alerts/warning": {"size": Vector2i(16, 16), "color": "f2a541", "use": "Alerta comum"},
	"ui/icons/alerts/danger": {"size": Vector2i(16, 16), "color": "e5534b", "use": "Alerta de perigo"},
	"ui/portraits/colonist_placeholder": {"size": Vector2i(24, 24), "color": "d0a070", "use": "Retrato de colono na barra do topo"},
	"ui/selection/bracket": {"size": Vector2i(16, 16), "color": "e8dcc0", "use": "Marcador de seleção (cantos)", "draw": "bracket"},
}

static var _cache := {}


static func path_of(id: String) -> String:
	return ROOT + id + ".png"


static func expected_size(id: String) -> Vector2i:
	return ENTRIES[id]["size"]


## Colunas × linhas da folha de sprites (1 × 1 para imagem simples).
static func frame_grid(id: String) -> Vector2i:
	return ENTRIES[id].get("frames", Vector2i.ONE)


static func frame_size(id: String) -> Vector2i:
	return expected_size(id) / frame_grid(id)


## Recorte de um quadro da folha, para desenhar com draw_texture_rect_region.
static func frame_region(id: String, column: int, row: int) -> Rect2:
	var frame := frame_size(id)
	return Rect2(Vector2(column * frame.x, row * frame.y), Vector2(frame))


## Textura do asset. Se o PNG não existir, usa o desenho provisório em memória e avisa no log.
static func texture(id: String) -> Texture2D:
	if _cache.has(id):
		return _cache[id]
	assert(ENTRIES.has(id), "Asset não catalogado: %s" % id)
	var path := path_of(id)
	var result: Texture2D
	if ResourceLoader.exists(path):
		result = load(path)
	else:
		push_warning("Asset ausente, usando provisório em memória: %s" % path)
		result = ImageTexture.create_from_image(PlaceholderPainter.paint(ENTRIES[id]))
	_cache[id] = result
	return result
