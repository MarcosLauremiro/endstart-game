# Lista de assets

Gerado por `tools/generate_placeholder_assets.gd` a partir de `scripts/assets/asset_catalog.gd`. Não edite à mão.

- Substitua o PNG mantendo **o mesmo nome e o mesmo tamanho**; o teste `test_asset_catalog.gd` confere os tamanhos.
- Para um asset novo, adicione a entrada no catálogo e rode o gerador de novo: ele só cria o que falta.
- Molduras `ui/frames` são 9-slice: os cantos indicados não esticam.
- Folhas de sprites (coluna Quadros): grade de quadros iguais, lida da esquerda para a direita e de cima para baixo. Linhas de estação seguem primavera, verão, outono, inverno.
- Fonte: coloque uma fonte pixel monoespaçada com acentos em `ui/fonts/main.ttf` (8 px lógicos). Sem ela, o jogo usa a fonte padrão.

## assets/tiles/terrain/

| Arquivo | Tamanho (px) | Quadros | Uso |
| --- | --- | --- | --- |
| `grass.png` | 16×16 | — | Terreno: grama |
| `dirt.png` | 16×16 | — | Terreno: solo |
| `tall_grass.png` | 16×16 | — | Terreno: grama alta |
| `shallow_water.png` | 16×16 | — | Terreno: água rasa |
| `deep_water.png` | 16×16 | — | Terreno: água funda |
| `rock.png` | 16×16 | — | Terreno: rocha (montanha, minerável) |

## assets/tiles/floors/

| Arquivo | Tamanho (px) | Quadros | Uso |
| --- | --- | --- | --- |
| `wood_floor.png` | 16×16 | — | Piso de madeira |

## assets/structures/

| Arquivo | Tamanho (px) | Quadros | Uso |
| --- | --- | --- | --- |
| `wall_wood.png` | 16×24 | — | Parede de madeira |
| `wall_stone.png` | 16×24 | — | Parede de pedra |
| `door_simple.png` | 16×24 | — | Porta simples |
| `bed_rustic.png` | 16×32 | — | Cama rústica (1×2 tiles) |
| `campfire.png` | 16×16 | — | Fogueira |
| `table.png` | 32×16 | — | Mesa simples (2×1 tiles) |

## assets/workstations/

| Arquivo | Tamanho (px) | Quadros | Uso |
| --- | --- | --- | --- |
| `crafting_bench.png` | 48×16 | — | Bancada de produção rústica (3×1) |
| `cooking_bench.png` | 48×16 | — | Bancada de cozinha (3×1) |
| `study_desk.png` | 32×32 | — | Mesa de estudos (2×2) |
| `analysis_table.png` | 32×16 | — | Mesa de análise (2×1) |

## assets/containers/

| Arquivo | Tamanho (px) | Quadros | Uso |
| --- | --- | --- | --- |
| `crate.png` | 16×16 | — | Caixote |
| `chest_rustic.png` | 16×16 | — | Baú rústico |
| `material_yard.png` | 32×32 | — | Pátio de materiais (2×2) |

## assets/plants/

| Arquivo | Tamanho (px) | Quadros | Uso |
| --- | --- | --- | --- |
| `trees.png` | 64×64 | 4 × 4 de 16×16 | Árvore. Colunas: toco da jovem, toco da adulta, jovem, adulta. Linhas: primavera, verão, outono, inverno |
| `berry_bushs.png` | 48×64 | 3 × 4 de 16×16 | Arbusto de frutas. Colunas: muda, sem frutas, com frutas. Linhas: estações |
| `low_growing_vegetation.png` | 32×64 | 2 × 4 de 16×16 | Planta de fibra. Colunas: pequena, crescida (colhível). Linhas: estações |
| `Wheatfield.png` | 64×16 | 4 × 1 de 16×16 | Trigo na plantação. Colunas: 4 fases de crescimento, a última é madura |
| `carrot.png` | 48×16 | 3 × 1 de 16×16 | Cenoura na plantação. Colunas: 3 fases de crescimento, a última é madura |
| `mushroom.png` | 32×16 | 2 × 1 de 16×16 | Cogumelo na plantação. Colunas: 2 fases de crescimento, a última é madura |
| `Rocks.png` | 48×64 | 3 × 4 de 16×16 | Pedras soltas, 3 variações. Linhas: estações (ainda sem uso) |
| `DeadTrees.png` | 64×16 | 4 × 1 de 16×16 | Árvore seca: 2 tocos e 2 árvores (fora do MVP) |
| `WinterDeadTrees.png` | 64×16 | 4 × 1 de 16×16 | Árvore seca com neve: 2 tocos e 2 árvores (fora do MVP) |
| `Cactus.png` | 64×32 | 4 × 2 de 16×16 | Cactos, 8 variações (bioma deserto, fora do MVP) |
| `CoconutTrees.png` | 96×16 | 6 × 1 de 16×16 | Coqueiros: 2 tocos e 4 variações (litoral, fora do MVP) |

## assets/objects/

| Arquivo | Tamanho (px) | Quadros | Uso |
| --- | --- | --- | --- |
| `scrap_pile.png` | 16×16 | — | Monte de sucata |

## assets/ruins/

| Arquivo | Tamanho (px) | Quadros | Uso |
| --- | --- | --- | --- |
| `ruin_wall.png` | 16×24 | — | Parede da ruína |
| `ruin_floor.png` | 16×16 | — | Piso da ruína |
| `ruin_door.png` | 16×24 | — | Porta da ruína |

## assets/items/

| Arquivo | Tamanho (px) | Quadros | Uso |
| --- | --- | --- | --- |
| `wood.png` | 16×16 | — | Madeira |
| `stone_raw.png` | 16×16 | — | Pedra bruta |
| `stone_block.png` | 16×16 | — | Blocos de pedra |
| `fiber.png` | 16×16 | — | Fibra |
| `raw_meat.png` | 16×16 | — | Carne crua |
| `carrot.png` | 16×16 | — | Cenoura (colhida) |
| `wheat.png` | 16×16 | — | Trigo (colhido) |
| `mushroom.png` | 16×16 | — | Cogumelo (colhido) |
| `berries.png` | 16×16 | — | Frutas silvestres |
| `simple_meal.png` | 16×16 | — | Refeição simples |
| `scrap.png` | 16×16 | — | Sucata |
| `stone_knife.png` | 16×16 | — | Faca de pedra |
| `stone_axe.png` | 16×16 | — | Machado de pedra |
| `stone_pickaxe.png` | 16×16 | — | Picareta de pedra |
| `wooden_spear.png` | 16×16 | — | Lança de madeira |
| `bow.png` | 16×16 | — | Arco |
| `arrows.png` | 16×16 | — | Flechas |
| `hide.png` | 16×16 | — | Pele |
| `fat.png` | 16×16 | — | Gordura |
| `small_game_carcass.png` | 16×16 | — | Carcaça de lebre (caça pequena) |
| `large_game_carcass.png` | 16×16 | — | Carcaça de cervo (caça grande) |
| `artifact.png` | 16×16 | — | Artefato da ruína |

## assets/characters/colonists/

| Arquivo | Tamanho (px) | Quadros | Uso |
| --- | --- | --- | --- |
| `colonist.png` | 16×24 | — | Colono (corpo; a cabeça passa do tile) |

## assets/characters/animals/

| Arquivo | Tamanho (px) | Quadros | Uso |
| --- | --- | --- | --- |
| `small_game.png` | 16×16 | — | Lebre (caça pequena) |
| `large_game.png` | 32×24 | — | Cervo (caça grande), pés no tile de base |
| `predator.png` | 32×24 | — | Lobo-espinho (predador), pés no tile de base |

## assets/characters/enemies/

| Arquivo | Tamanho (px) | Quadros | Uso |
| --- | --- | --- | --- |
| `raider_spear.png` | 16×24 | — | Saqueador com lança |
| `raider_archer.png` | 16×24 | — | Saqueador arqueiro |

## assets/effects/

| Arquivo | Tamanho (px) | Quadros | Uso |
| --- | --- | --- | --- |
| `arrow_projectile.png` | 8×8 | — | Flecha em voo |

## assets/ui/frames/

| Arquivo | Tamanho (px) | Quadros | Uso |
| --- | --- | --- | --- |
| `panel.png` | 48×48 | — | Moldura de painel 9-slice, cantos de 16 px |
| `button.png` | 24×24 | — | Botão normal 9-slice, cantos de 8 px |
| `button_hover.png` | 24×24 | — | Botão com mouse em cima, 9-slice |
| `button_pressed.png` | 24×24 | — | Botão ativo/pressionado, 9-slice |

## assets/ui/icons/time/

| Arquivo | Tamanho (px) | Quadros | Uso |
| --- | --- | --- | --- |
| `pause.png` | 16×16 | — | Pausar |
| `speed_1.png` | 16×16 | — | Velocidade normal (1×) |
| `speed_2.png` | 16×16 | — | Velocidade rápida (3×) |
| `speed_3.png` | 16×16 | — | Velocidade muito rápida (6×) |

## assets/ui/icons/needs/

| Arquivo | Tamanho (px) | Quadros | Uso |
| --- | --- | --- | --- |
| `hunger.png` | 16×16 | — | Necessidade: fome |
| `sleep.png` | 16×16 | — | Necessidade: sono |
| `mood.png` | 16×16 | — | Humor |

## assets/ui/icons/status/

| Arquivo | Tamanho (px) | Quadros | Uso |
| --- | --- | --- | --- |
| `sleeping.png` | 16×16 | — | Estado: dormindo |
| `injured.png` | 16×16 | — | Estado: ferido |
| `crisis.png` | 16×16 | — | Estado: em crise |
| `drafted.png` | 16×16 | — | Estado: convocado |

## assets/ui/icons/orders/

| Arquivo | Tamanho (px) | Quadros | Uso |
| --- | --- | --- | --- |
| `cut.png` | 16×16 | — | Ordem: cortar plantas |
| `mine.png` | 16×16 | — | Ordem: minerar |
| `harvest.png` | 16×16 | — | Ordem: colher |
| `hunt.png` | 16×16 | — | Ordem: caçar |
| `grow_zone.png` | 16×16 | — | Ordem: zona de plantação |
| `prioritize.png` | 16×16 | — | Ordem: priorizar tarefa |
| `deconstruct.png` | 16×16 | — | Ordem: desmontar |
| `cancel.png` | 16×16 | — | Ordem: cancelar |

## assets/ui/icons/tabs/

| Arquivo | Tamanho (px) | Quadros | Uso |
| --- | --- | --- | --- |
| `build.png` | 16×16 | — | Aba Construir |
| `orders.png` | 16×16 | — | Aba Ordens |
| `work.png` | 16×16 | — | Aba Trabalho |
| `schedule.png` | 16×16 | — | Aba Agenda |
| `colonists.png` | 16×16 | — | Aba Colonos |
| `storage.png` | 16×16 | — | Aba Armazém |
| `research.png` | 16×16 | — | Aba Pesquisa |
| `diary.png` | 16×16 | — | Aba Diário |
| `menu.png` | 16×16 | — | Aba Menu |

## assets/ui/icons/alerts/

| Arquivo | Tamanho (px) | Quadros | Uso |
| --- | --- | --- | --- |
| `warning.png` | 16×16 | — | Alerta comum |
| `danger.png` | 16×16 | — | Alerta de perigo |

## assets/ui/portraits/

| Arquivo | Tamanho (px) | Quadros | Uso |
| --- | --- | --- | --- |
| `colonist_placeholder.png` | 24×24 | — | Retrato de colono na barra do topo |

## assets/ui/selection/

| Arquivo | Tamanho (px) | Quadros | Uso |
| --- | --- | --- | --- |
| `bracket.png` | 16×16 | — | Marcador de seleção (cantos) |
