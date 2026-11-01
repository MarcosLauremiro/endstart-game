# ENDSTART — Arquitetura técnica

Documento vivo. Atualizar sempre que uma decisão arquitetural mudar.

## Ambiente

- **Godot:** 4.7.2 stable (build Steam), `godot.windows.opt.tools.64.exe`.
- **Linguagem:** GDScript com tipagem estática (avisos de tipo inferido de Variant são tratados como erro).
- **Renderização:** Forward Plus, driver D3D12 no Windows.
- **Testes:** executor próprio em `tests/` (sem frameworks externos).

## Princípio central

A simulação roda em ticks fixos e guarda todo o estado da partida. A apresentação só lê esse estado e desenha.
Nada visual é fonte de verdade: nós da cena nunca guardam dados de colonos, tarefas, itens ou terreno.

## Estado atual (M0 a M5 — Colonos completos)

### Simulação

| Área | Arquivo | Responsabilidade |
| --- | --- | --- |
| Parâmetros | `scripts/simulation/balance.gd` | Constantes de tempo, mapa, IA, necessidades, trabalho, personalidade, início e câmera. Único lugar com esses números. |
| Relógio | `scripts/simulation/game_clock.gd` | Tempo real → ticks, pausa, velocidades, limite por quadro, dia e hora. |
| Estado | `scripts/simulation/world_state.gd` | Todo o estado simulado: mapa, navegação, relógio, reservas, quadro de tarefas, RNG, colonos, árvores, arbustos, contêineres, pilhas. Largar itens, achar armazenamento, somar estoques, soltar reservas. |
| Partida | `scripts/simulation/simulation.gd` | Orquestra o tick (plantas, expiração e auditoria de reservas, necessidades, pensamento escalonado, execução). Comandos do jogador: mover, priorizar tarefa, designar, mudar prioridade. |
| Terreno | `scripts/world/terrain.gd` | Tipos de terreno e fator de movimento do GDD. Valores gravados no mapa: não reordenar. |
| Mapa | `scripts/world/world_data.gd` | Grade de terreno (`PackedByteArray`) e impressão digital FNV-1a. |
| Geração | `scripts/world/world_generator.gd` | Terreno por seed: base por ruído, rio com vaus, uma montanha. |
| População | `scripts/world/world_populator.gd` | Arbustos, árvores, plantas de fibra (parte jovem), ponto de chegada e caixotes com os recursos iniciais. |
| Plantas | `scripts/world/berry_bush.gd`, `wild_tree.gd`, `fiber_plant.gd`, `stump.gd` | Arbusto (muda → com frutas, que voltam a crescer), árvore (jovem → adulta, rende madeira), planta de fibra (pequena → colhível, volta a crescer), toco do corte (some com o tempo). Crescem uma vez por hora de jogo. |
| Navegação | `scripts/navigation/navigation_grid.gd` | `AStarGrid2D` com custo por terreno; sólido para rocha, água funda e contêineres. Regiões conectadas para descartar destinos inalcançáveis sem A*, mantidas aos poucos. Caminho até célula vizinha. |
| Itens | `scripts/inventory/item_def.gd` + `resources/items/*.tres` | Definição de cada item (categoria, peso, pilha, valor, nutrição, equipamento, ícone) como `Resource`. Categorias: alimentos, carcaças, recursos básicos, recursos avançados, ferramentas, armas, roupas, artefatos. |
| Contêineres | `scripts/inventory/container_def.gd` + `resources/containers/*.tres`, `storage_container.gd` | Espaços com tamanho de pilha; o que o tipo pode guardar e o filtro do jogador por categoria; reservas de retirada e de espaço por colono. |
| Pilhas | `scripts/inventory/item_stack.gd` | Pilha solta no chão, com reserva de retirada. Cada pilha gera uma tarefa de Carregar. |
| Definições | `scripts/inventory/defs.gd` | Carrega os `.tres` e entrega por id. |
| Tipos de trabalho | `scripts/jobs/work_type.gd` | Colunas da grade na ordem do GDD (Cozinhar, Caçar, Construir, Cultivar, Minerar, Cortar plantas, Artesanato, Carregar). |
| Tarefa | `scripts/jobs/task.gd` | Id, tipo, local, alvo, urgência, progresso, trabalho necessário, estado, motivo e prazo de bloqueio. |
| Quadro | `scripts/jobs/task_board.gd` | Lista central indexada por tipo de trabalho, por célula e por pilha. |
| Designações | `scripts/jobs/designations.gd` | Cortar, minerar, colher, caçar, plantação e cancelar por área; cada célula (ou animal) vira uma tarefa. |
| Efeitos | `scripts/jobs/task_effects.gd` | Validade das tarefas e resultado no mundo (itens reais no chão, rocha vira solo). |
| Reservas | `scripts/jobs/reservations.gd` | Dono único de tarefas e arbustos, com o último tick de avanço para a expiração. |
| Colono | `scripts/colonists/colonist.gd` | Identidade, histórias, Força, traços, habilidades, prioridades, agenda, equipamento, célula, caminho, necessidades, humor, estado, ação, ordem, carga, histórico, opções avaliadas. Velocidade de trabalho (habilidade × traços × Força × ferramenta), XP, carga e movimento. |
| Traços | `scripts/colonists/traits.gd` | Os 8 do MVP com efeito, raridade (comum 10, incomum 4) e espectro (Esforçado/Preguiçoso, Otimista/Pessimista); sorteio de 1 a 3. |
| Habilidades | `scripts/colonists/skills.gd`, `skill_state.gd` | As 6 do MVP, afinidades, velocidade por nível (GDD), XP para subir, título; por colono: nível, XP, afinidade, limite diário e esquecimento. |
| Histórias | `scripts/colonists/backstory_def.gd` + `resources/backstories/*.tres` | Infâncias e vidas adultas do GDD com os bônus nas habilidades do MVP e na Força. |
| Agenda | `scripts/colonists/schedule.gd` | Bloco por hora: Dormir, Trabalhar, Livre. |
| Equipamento | `scripts/colonists/equipment.gd` | Espaços Camisa, Calça e Mão; peso; o item equipado conta nos totais. |
| Fábrica | `scripts/colonists/colonist_factory.gd` | Gerador do GDD no escopo do MVP: idade 16–70, histórias, Força, habilidades 0–3 + bônus + 1 a cada 10 anos, afinidades, traços, teto de 70, túnica e calça. |
| Necessidades | `scripts/needs/needs.gd`, `mood.gd` | Fome e sono, 0–100 (Glutão perde fome 1,3× mais rápido). Humor 0–100 indo ~12 por dia ao alvo (50 + pensamentos − expectativa), com estados do GDD e o efeito no XP. |
| Ação | `scripts/ai/action.gd` | O que o colono vai fazer, camada de decisão, alvo, tarefa, fonte de comida, etapa e progresso. |
| Cérebro | `scripts/ai/colonist_brain.gd` | Camadas de decisão do GDD, avaliando só as mais altas que a atual. Escreve os motivos reais. |
| Seletor | `scripts/ai/task_selector.gd` | Prioridade → coluna → pontuação do GDD. Validação com motivo (reservada, bloqueada, sem caminho, sem espaço, prioridade desligada) e as 5 melhores opções. |
| Executor | `scripts/ai/action_runner.gd` | Reserva, caminha, executa (comer, trabalhar, carregar em duas etapas, pausar), aplica o resultado e libera. Falhas liberam tudo e largam o que estiver nas mãos. |
| Registro | `scripts/ai/decision_record.gd` | Escolha, motivo, alternativas descartadas e resultado. |

### Construção (M3)

| Área | Arquivo | Responsabilidade |
| --- | --- | --- |
| Definição | `scripts/construction/structure_def.gd` + `resources/structures/*.tres` | Estrutura construível: camada (construção ou piso), colocação (clique, área, contorno), footprint, custo, horas, equipe máxima, bloqueio, fator de movimento, resistência, cama, contêiner que vira. |
| Obra | `scripts/construction/construction_site.gd` | Planta colocada: materiais entregues (existem de verdade até concluir ou cancelar) e entregas a caminho reservadas por colono. |
| Estrutura | `scripts/construction/structure.gd` | Estrutura pronta (parede, porta, piso, cama, mesa, fogueira). Contêineres prontos viram `StorageContainer`. |
| Regras | `scripts/construction/construction.gd` | Onde dá para colocar (com motivo), colocar (árvore no local é marcada para corte), concluir (limpa plantas rasteiras, tira colono e itens do lugar de estrutura sólida), cancelar (devolve tudo), desmontar (devolve parte e larga o conteúdo). |
| Contêineres | `resources/containers/*.tres` | Caixote (6 espaços), baú rústico (10), pátio de materiais (2×2, 4 espaços grandes de 300, só materiais). |

### Produção e comida (M4)

| Área | Arquivo | Responsabilidade |
| --- | --- | --- |
| Receita | `scripts/production/recipe_def.gd` + `resources/recipes/*.tres` | Bancadas onde se faz, ingredientes (item exato ou marca, como "porções cruas"), produtos, horas, meta inicial. |
| Pedido | `scripts/production/bill.gd` | Fila "fazer N", "fazer até ter X" (conta contêineres, chão e mãos) ou "sempre"; pausa; motivo de não rodar. |
| Bancada | `scripts/production/workbench.gd` | Fila de pedidos, pedido em andamento, ingredientes separados (reais, voltam ao chão se o pedido sumir) e entregas a caminho. Uma tarefa no quadro por bancada, do tipo de trabalho dela. |
| Espécie | `scripts/animals/animal_def.gd` + `resources/animals/*.tres` | Lebre (pequena), cervo (grande), lobo-espinho (predador): vida, velocidade, fuga, carcaça, presas, população. |
| Animal | `scripts/animals/animal.gd`, `wildlife.gd` | Pastar, fugir de colonos e predadores, predador caça presas, migração diária pelas bordas, caça automática por espécie, ferimento e morte (carcaça no chão). |
| Cultivo | `scripts/farming/crop_def.gd` + `resources/crops/*.tres`, `crop.gd`, `grow_zone.gd`, `farming.gd` | Cenoura (3 fases), trigo (4 fases) e cogumelo (2 fases). Zona de plantação com um cultivo escolhido; tiles livres viram tarefas de semear, plantas crescem por hora × fertilidade, maduras viram tarefas de colher; o tile volta a ser semeado sozinho. |

### Apresentação

| Área | Arquivo | Responsabilidade |
| --- | --- | --- |
| Mapa | `scripts/world/world_view.gd` | `TileMapLayer`; uma fonte do TileSet por tipo de terreno. |
| Objetos | `scripts/world/objects_view.gd` | Plantações e cultivos (4 fases), árvores, arbustos, construções e bancadas, caixotes, pilhas com quantidade, animais (interpolados), designações com barra de progresso (vermelhas se bloqueadas; a caça segue o animal), retângulo de arraste. |
| Dia e noite | `scripts/simulation/daylight.gd`, `scripts/world/daylight_view.gd` | Horas de luz pela fórmula do GDD e luz de 0 a 1 por tick; um `CanvasModulate` escurece só o mapa à noite (a interface não). |
| Colonos | `scripts/colonists/colonists_view.gd` | Um `Sprite2D` por colono, interpolado entre células; deitado quando dorme; marcador de seleção. |
| Câmera | `scripts/world/camera_controller.gd` | Panorâmica e três níveis de zoom fixos. |
| Catálogo de arte | `scripts/assets/asset_catalog.gd` | Lista única de assets: caminho, tamanho, uso. Fallback provisório. |
| Arte provisória | `scripts/assets/placeholder_painter.gd`, `tools/generate_placeholder_assets.gd` | Provisórios no tamanho final; o gerador nunca sobrescreve. |
| Tema | `scripts/ui/ui_theme.gd` | Paleta "rust punk" do GDD, molduras 9-slice, barras, fonte pixel Dogica Pixel sem suavização, escala da interface e tamanho da fonte. |
| Recursos | `scripts/ui/resource_bar.gd` | Topo esquerdo: comida em dias, madeira, pedra, carne crua, vegetais, frutas — somados dos itens reais. |
| Tempo | `scripts/ui/time_panel.gd` | Topo direito: dia, hora, pausa e velocidades. |
| Ficha | `scripts/ui/inspect_panel.gd` | Canto inferior esquerdo, em abas. Geral: histórias, Força, agenda agora, traços (efeitos na dica), o que faz, fome, sono, humor e pensamentos. Habilidades: nível, afinidade, título, % para o próximo nível e velocidade. Equipamento: Camisa, Calça, Mão (com bônus) e carga. Por quê: motivo real, melhores tarefas, decisões recentes. |
| Ordens | `scripts/ui/bottom_bar.gd` | Base: construir, cortar (C), minerar (M), colher (H), caçar (K), plantação (P), desmontar (D), cancelar (X), Trabalho e Armazém. |
| Trabalho | `scripts/ui/work_priority_window.gd` | Grade de prioridades 1–4/desligado por colono e tipo (dica com a habilidade, nível e afinidade); caça automática por espécie. |
| Agenda | `scripts/ui/schedule_window.gd` | Uma linha por colono e uma coluna por hora; escolha Dormir, Trabalhar ou Livre e clique ou arraste (A). |
| Bancada | `scripts/ui/workbench_panel.gd` | Ao selecionar uma bancada (canto superior direito): pedido em andamento com ingredientes, por que está parada, motivo de cada colono, fila com modo, meta (±1, botão direito ±10), pausa, subir e apagar, e botões de novo pedido. |
| Tile | `scripts/ui/tile_info.gd`, `scripts/ui/tile_panel.gd` | Clique num tile sem colono: terreno (movimento, fertilidade, construção do GDD), plantas, toco, caixote com conteúdo e reservas, pilha, tarefa com progresso/reserva/bloqueio e o motivo de cada colono fazer ou não (mesmo seletor da IA, em modo consulta). Atualiza 4× por segundo. |
| Construir | `scripts/ui/build_menu.gd` | Menu com custo e tempo de cada estrutura (B). Prévia verde/vermelha na colocação; plantas aparecem em azul translúcido. |
| Armazém | `scripts/ui/storage_panel.gd` | Totais por item (contêineres, chão, mãos), comida em dias, busca, contêineres com ocupação; clicar centraliza a câmera (I). |
| Opções | `scripts/ui/context_actions.gd`, `scripts/ui/action_bar.gd` | Botões do que foi clicado, no topo do painel do tile ou do colono. Árvore: cortar; planta: colher; rocha: minerar; obra: cancelar (devolve o material); construção, contêiner ou bancada: desmontar; animal: caçar (predador desligado, com motivo); plantação: plantar cenoura, trigo ou cogumelo, remover; chão livre: criar plantação; colono: comer agora, dormir agora, cancelar ordem. Marcado vira "cancelar". |
| Mensagens | `scripts/ui/message_log.gd` | Canto inferior direito: mensagens que somem sozinhas. |
| Entrada | `scenes/main/main.gd` + `main.tscn` | Liga tudo e traduz mouse e teclado em comandos. |

### Ciclo de um tick

```
Simulation.step()
  ├─ a cada hora: plantas silvestres e cultivos crescem; tarefas de semear e colher são criadas
  ├─ a cada 30 ticks: reservas sem avanço há 30 s expiram; colono sem ação não segura reserva
  └─ para cada colono:
	   ├─ Needs.tick(dormindo?)
	   ├─ se for a vez dele (tick + offset) % 30 == 0, ou force_think:
	   │    ColonistBrain.decide (só camadas mais altas que a atual) → Action + DecisionRecord
	   │    ActionRunner.start → reserva → caminho → INDO ou EXECUTANDO
	   └─ ActionRunner.step → mover / executar / concluir
  └─ Wildlife.tick: animais pensam a cada 60 ticks (escalonados) e andam; uma vez por dia, migração
```

### Fluxo de uma tarefa

`Designar → tarefa no quadro → seletor avalia (prioridade, coluna, pontuação, validade) → reserva → caminha → executa (progresso fica na tarefa) → aplica o resultado (itens no chão) → libera → nova tarefa de Carregar → reserva itens e espaço → leva ao caixote → libera`.

### Camadas de decisão

| Camada | O que existe hoje |
| --- | --- |
| 1. Reação | Desmaio: sono em 0% → dorme onde está, sem poder ser interrompido. |
| 2. Necessidade crítica | Fome < 15% → comer; sono < 8% → dormir no chão. Interrompe o trabalho. |
| 3. Ordem direta | Mover ou priorizar uma tarefa. Interrompida por 1 e 2, fica guardada e é retomada. |
| 4. Agenda | Bloco Dormir com sono < 90% → dorme; fim do bloco Trabalhar interrompe o trabalho (Esforçado termina a tarefa). Trabalho só no bloco Trabalhar. |
| 5. Trabalho | Quadro de tarefas. Preguiçoso pausa 15 min a cada 2 h de trabalho. |
| 6. Tempo livre | Sem tarefa possível: fome < 30% → comer; sono < 20% → dormir; senão vagar ou ficar ocioso. |

## Decisões registradas

- **Tile 16×16 e 1 tile ≈ 1 m**, conforme o GDD.
- **Resolução base 640×360**, escala inteira `canvas_items`/`integer` com aspecto `expand` (a tela ocupa a janela toda, mostrando mais mapa nas sobras), filtro `Nearest`, snap de transformações e vértices em pixel. A janela abre maximizada; F11 alterna tela cheia. Fora do maximizado, 1280×720 (escala 2×).
- **Zoom fixo** em `[0.5, 1.0, 2.0]`: 0.5 mostra ~80×45 tiles, 1.0 ~40×22 tiles.
- **60 ticks por segundo** a 1×; `MAX_TICKS_PER_FRAME = 120` descarta tempo excedente para não travar após um quadro longo.
- **Velocidades como no RimWorld:** 1×, 3× e 6× (teclas 1–3, Espaço pausa); 15× na tecla 4 só em build de desenvolvimento. Ainda falta: forçar 1× quando chega uma ameaça (M7) e acelerar quando todos dormem.
- **Arte trocável:** todo asset passa pelo `AssetCatalog`. Substitua o PNG em `assets/` com o mesmo nome e tamanho; `test_asset_catalog.gd` acusa tamanhos diferentes.
- **Escolhas de tamanho não definidas no GDD:** mesa 2×1 (32×16), mesa de estudos 2×2, mesa de análise 2×1, retrato 24×24, flecha em voo 8×8, porta 16×24.
- **Tempo independente do FPS** e **geração determinística** (mapa e simulação usam RNGs com a seed; a mesma seed reproduz o mesmo comportamento).
- **Rio com vaus:** água funda é intransponível (GDD) e pontes estão fora do MVP, então o rio tem 3 trechos rasos.
- **Estado separado da orquestração:** cérebro, seletor e executor recebem `WorldState`, não `Simulation`, para não haver dependência circular.
- **Sinais sem lambda entre objetos de simulação:** uma lambda guardaria o dono dentro do estado e criaria ciclo de referência (vazamento).
- **Ritmos provisórios (o GDD só define os limiares):** fome esvazia em 30 h, sono em 32 h acordado, dormir no chão recupera 10/h, fruta dá 20 de fome e refeição simples 50, o colono come até 90%, arbusto tem 10 porções e recupera 1 a cada 8 h, colono anda 3 tiles/s em terreno 100%.
- **Comida:** contêineres, pilhas no chão e arbustos entram na mesma escolha por pontuação (ver Escolha da comida). Arbusto designado para colheita não é usado para comer.
- **Recursos iniciais (GDD: BALANÇA):** 2 caixotes com refeições para 15 dias e 100 de madeira, × (1 + 0,15 × (5 − colonos)). É o destino do Carregar até o M3 permitir construir contêineres.
- **Pesos e valores assumidos** (o GDD não define): pedra bruta 1,0 kg, fibra 0,2 kg, frutas e vegetal 0,5 kg e valor 1. Carne crua não se come crua (nutrição 0) até a cozinha do M4.
- **Uma tarefa por célula:** uma área designada se divide sozinha, porque cada célula é uma unidade indivisível no quadro.
- **Reservas em duas formas:** chave exclusiva (tarefa, arbusto) em `Reservations`, com expiração; quantidades (itens a retirar, espaço a ocupar) nas pilhas e contêineres. Toda saída de ação solta as duas e larga o que estiver nas mãos, então nenhum item some nem fica preso.
- **Carregar em duas etapas:** ao pegar os itens, o colono solta a tarefa da pilha (outro pode levar o resto) e mantém só a reserva de espaço no destino.
- **Tarefa bloqueada** (sem caminho, sem espaço) volta a ser tentada depois de 1 h de jogo; minerar uma rocha desbloqueia as vizinhas na hora.
- **Pontuação do GDD implementada inteira:** habilidade (0,5 + nível ÷ 20) e afinidade (paixão 1,3, interesse 1,1, aversão 0,7) já valem; o fator de traços fica neutro no MVP (Curioso com artefatos e Nômade chegam com seus sistemas).
- **Força** já é sorteada (curva normal, média 5, desvio 1,5) e afeta carga (15 kg + 5 kg × Força) e velocidade de mineração (6% por ponto).
- **Regiões de navegação mantidas aos poucos:** célula que abre se junta à região vizinha; célula que fecha só força recálculo se um teste local (anel de vizinhos) indicar que pode ter dividido a região. Isso tirou um pico de 39 ms por tick para 1 ms.
- **Cérebro avalia só camadas acima da atual:** quem está trabalhando não reavalia o quadro inteiro a cada meio segundo.
- **Três colonos no início** (dentro dos 2 a 5 do GDD). Escolha de 2 a 5 virá com a criação de partida.
- **Estações só visuais no MVP:** calendário do GDD (ano de 60 dias, 4 estações de 15 dias, começa na primavera) em `GameClock.season()`. A estação escolhe a linha das folhas de sprites e aparece no painel de tempo; crescimento, temperatura e colheita não mudam até a fase de clima (fora do MVP pelo GDD).
- **Folhas de sprites das plantas** (arte do jogador): grade de 16×16; colunas = fases, linhas = primavera, verão, outono, inverno. Árvore: toco da jovem, toco da adulta, jovem, adulta. Arbusto: muda, sem frutas, com frutas. Planta de fibra: pequena, crescida. O catálogo guarda a grade (`frames`) e o `ObjectsView` recorta o quadro.
- **Vegetação rasteira = planta de fibra:** colher rende Fibra (recurso do MVP). `Wheatfield` (4 fases) fica registrado para a plantação de vegetais do M4.
- **Registrados sem uso ainda:** pedras soltas (`Rocks`), árvores secas, cactos e coqueiros (biomas fora do MVP).
- **Construção pelo quadro de tarefas:** cada planta vira uma tarefa de Construir. Enquanto falta material, quem pega a tarefa leva material (uma entrega por vez por obra, reservada); com tudo entregue, até `max_workers` colonos constroem juntos, cada um numa vaga de reserva própria.
- **Entrega de material é do tipo Construir:** o GDD lista "levar materiais para construções" entre as tarefas de transporte sem dizer a coluna; como no RimWorld, quem constrói busca o próprio material.
- **Cama e mesa construídas direto:** no GDD são receitas da bancada de produção (12 e 10 de madeira, 3 h e 2,5 h). Instalar móveis feitos na bancada não está no MVP, então continuam sendo construção com o mesmo custo e tempo.
- **Tempos assumidos** (o GDD não dá): fogueira e caixote 0,5 h, baú 1 h, pátio 0,5 h.
- **Equipe:** cama, mesa e pátio aceitam até 3 colonos; paredes, portas e pisos, 1 (cada tile já é uma tarefa separada).
- **Desmontar** leva metade do tempo de construir e devolve 50% do material (provisório). **Cancelar** uma planta devolve 100% do que foi entregue.
- **Cama:** recupera 15 de sono por hora contra 10 no chão (provisório). O colono reserva a cama livre mais perto; sem cama alcançável, dorme no chão. A mesa e a fogueira ainda não têm efeito (humor no M5, cozinha no M4).
- **Reservas renovadas só pela própria ação:** andar, trabalhar, comer e dormir renovam só as reservas da ação atual; uma reserva esquecida em outro lugar expira sozinha sem interromper o colono.
- **Pisos:** camada separada; aceleram o movimento (110%) e entram no custo do caminho.
- **Bancada de produção custa pedra bruta:** o GDD pede 20 madeira e 10 blocos de pedra, mas os blocos só saem da própria bancada. A versão rústica custa 20 madeira e 10 pedra bruta. A cozinha mantém o custo do GDD (15 madeira, 5 blocos), então a ordem é minerar → bancada de produção → blocos → cozinha.
- **Bancadas:** fogueira (Cozinhar, ×1,0), bancada de cozinha e bancada de produção rústicas (×0,8, GDD). Tempo de construção assumido: 2 h para as bancadas de 3×1, com até 3 colonos.
- **Abater só na cozinha** (GDD: "a cozinha faz tudo o que envolve comida"); a fogueira faz só refeição simples. O abate de animal grande (30 carne, 4 pele, 2 gordura) entra além das receitas do MVP porque o cervo é caça do MVP.
- **Quem opera a bancada busca os ingredientes:** o GDD prevê uma tarefa de Carregar e o artesão buscando depois de 10 s; no MVP o operador já busca, um ingrediente por vez, como na obra. Ingredientes separados não entram nos totais até virarem produto ou voltarem ao chão.
- **Fila:** o primeiro pedido possível da fila é feito; o pedido em andamento tem preferência para não desperdiçar ingredientes. Meta inicial: 10 do produto (60 de carne nos abates). Bancada sem ingrediente não fica bloqueada: a falta é conferida a cada pensamento.
- **Escolha da comida:** pontuação = nutrição ÷ (1 + custo ÷ 30), entre as 6 mais perto e a mais perto de cada tipo de comida. Refeição (50) vence frutas (20) mesmo um pouco mais longe. Carne crua não se come crua.
- **Caça sem combate (até o M7):** o caçador chega ao alcance da arma e atira a cada 1,5 s (85% de acerto, −5% por tile, mínimo 30%, dano × velocidade de trabalho). Sem arma: improvisada, alcance 6, dano 8; lança: 6 e 14; arco: 12 e 12 (provisório). A presa ferida foge; o caçador persegue. Morta, vira carcaça no chão (lebre 3 kg; cervo 40 kg, carregado um por vez mesmo acima da capacidade).
- **Predador não ataca colonos nem pode ser caçado** até o M7 (sem combate seria injusto). Ele caça lebres e cervos a cada 36 h; presas fogem dele.
- **Animais (provisório):** lebre 20 de vida, 3,6 tiles/s, 10 no mapa; cervo 60, 3,3 tiles/s, 5; lobo-espinho 80, 4,2 tiles/s, 2. Abaixo da população, um animal por espécie migra pela borda a cada dia. **Caça automática** por espécie (janela de Trabalho) marca os que estão no mapa e os que chegarem.
- **Cultivos (provisório; o GDD não define):** cenoura 5 dias, rende 5 (nutrição 20 crua); trigo 8 dias, rende 10 (não se come cru, nutrição 0, mas serve de porção crua na refeição simples); cogumelo 3 dias, rende 3 (nutrição 15). Os três contam como "porção crua". Semear 0,25 h e colher 0,3 h. A arte tem uma coluna por fase (`stages` no `.tres`) e a última é a madura. Planta silvestre ou itens no tile impedem semear, com motivo. Apagar a zona ou trocar o cultivo não destrói o que já foi semeado.
- **Cenoura e cogumelo substituem o "vegetal" genérico** do GDD (o item `vegetable` saiu): são os vegetais do MVP. Zona nova planta cenoura; o cultivo é trocado pelas opções do tile.
- **Fonte Dogica Pixel e escala própria da interface:** a fonte tem grade de 8 px por em, então só é nítida quando tamanho × escala na tela é múltiplo de 8. Com o HUD na escala do mapa isso não existe em ×3 (tela cheia 1080p), então a `CanvasLayer` do HUD tem escala própria (`UiTheme.ui_scale_for`: ×2 do 720p ao 1440p, ×4 em 4K) e a fonte usa 4 unidades (8 px na tela). A raiz do HUD é dimensionada à mão para cobrir a tela nessas unidades. Os números das pilhas no mapa usam a mesma fonte em 8. Sem suavização, sem hinting, sem posição subpixel. A seta "→" não existe na fonte: os textos usam "->". O menu de construção usa 3 colunas e o painel do tile rola acima de 150 px.
- **Opções do clique são atalhos para as mesmas ordens:** cortar, minerar, colher, desmontar, caçar e plantação usam as designações; "Comer agora" e "Dormir agora" são ordens diretas (camada 3), com a mesma escolha de comida e cama da IA.
- **Velocidade por nível (GDD):** curva contínua passando pelas pontas das faixas: 0 → 40%, 3 → 70%, 7 → 100%, 11 → 125%, 15 → 150%, 19 → 175%, 20 → 180%. Carregar não usa habilidade (100%). Cortar plantas usa Cultivo; a caça usa Corpo a corpo (Pontaria está fora do MVP).
- **XP (GDD):** 150 XP por hora × afinidade (0,2 / 0,35 / 1,0 / 1,5) × idade (até 17 ×1,3; 60+ ×0,7) × humor (contente ×1,1; instável ou pior ×0,8). Para subir do nível n: 1.000 + 75n². Acima de 4.000 XP no dia, ×0,2. Acima do nível 12 sem praticar, −40 XP por dia (−80 acima do 16). Ensino e cultura ficam fora do MVP.
- **Histórias:** 6 infâncias e 7 vidas adultas do GDD, só com os bônus nas 6 habilidades do MVP e na Força. Incapacidades, fobias e cultura de origem ficam fora do MVP. Interesses puxam (50%) para as habilidades das histórias; aversões, para as outras.
- **Traços (efeitos no MVP):** Esforçado +15% e termina a tarefa depois do fim do bloco Trabalhar; Preguiçoso −20% e pausa 15 min a cada 2 h; Otimista +6 e Pessimista −6 no humor; Forte +2 de Força; Glutão perde fome 1,3× mais rápido; Covarde recusa tarefas a até 10 tiles de um predador, com o motivo; Curioso (o efeito do GDD é sobre conhecimento e artefatos, M6) por enquanto vaga mais longe no tempo livre. Chance de ter 1, 2 ou 3 traços: 50%, 35%, 15% (provisório).
- **Humor (pensamentos do MVP, provisórios):** com fome −6 (faminto −12), cansado −5 (exausto −10), Otimista +6, Pessimista −6, dormiu no chão −4 por 12 h, sentimento pelo trabalho (interesse +1/h até +6, paixão +2/h até +10, aversão −2/h até −10; some 0,25 por hora sem trabalhar). Expectativa de assentamento: 0. Crises e inspirações ficam para depois do MVP (Fase 1 do GDD).
- **Agenda padrão:** dormir das 22 às 6, livre das 20 às 22, trabalhar das 6 às 20. A partida começa às 6 h do dia 1.
- **Equipamento (MVP: Camisa, Calça, Mão):** todos começam de túnica e calça de pano (sem efeito enquanto a temperatura é fixa). Antes de trabalhar, o colono pega no contêiner ou no chão (até 40 tiles) a ferramenta melhor para aquele trabalho e deixa no lugar a que tinha. Faca de pedra: Cozinhar e Caçar ×1,1 (faca do GDD); machado de pedra: Cortar plantas ×1,25 (provisório, o GDD só cita picareta e martelo); lança e arco: armas de caça. O item na mão pesa na carga e conta nos totais.
- **Carga:** acima de 100% da capacidade, movimento −20%; acima de 125%, −50%. O GDD trava o colono acima de 150%, mas no MVP isso só ocorre arrastando uma carcaça grande, então ele segue a −50%.
- **Dia e noite (por enquanto só visual):** latitude temperada (A = 3): ~12 h de luz na primavera e no outono, 15 h no verão, 9 h no inverno, centradas no meio-dia; amanhecer e anoitecer levam 1 h. À noite o mapa fica azul-escuro. As regras do GDD sem luz (trabalho −20%, plantas param, visão −50%) entram junto com tochas e iluminação.
- **Categorias e filtro (GDD: Organização):** o filtro do MVP é por categoria, nas opções do contêiner. O que deixa de ser permitido sai na hora para o chão ao lado (só o que não está reservado) e vira tarefa de Carregar para outro contêiner. O pátio de materiais aceita só recursos básicos. Os números do enum de categoria ficam gravados nos `.tres`: categorias novas entram no fim.
- **Guardar pelo clique:** a tarefa de Carregar da pilha vira urgência 2 (pedido do jogador, GDD). Sem contêiner que aceite, a opção diz o motivo; o transporte travado por falta de lugar avisa sozinho, no máximo uma vez a cada 6 h por item.
- **Registro no GDD:** desde o armazenamento por categoria, tudo o que é feito além do GDD também é escrito no `GDD.md`, na seção certa; este documento guarda as decisões técnicas.
- **Crescimento provisório** (o GDD não define): árvore leva 15 dias para ficar adulta e, jovem, rende 5 de madeira em metade do tempo de corte; toco some em 10 dias; arbusto muda leva 5 dias; planta de fibra leva 3 dias e rende 5 fibras. No início, 25% das árvores e 20% dos arbustos são jovens.

## Plano de testes

Executar na raiz do projeto:

```bash
godot --headless --path . --import
godot --headless --path . -s res://tests/test_runner.gd
```

| Suíte | Cobre |
| --- | --- |
| `test_game_clock.gd` | Pausa, velocidades, acúmulo entre quadros, limite por quadro, independência do FPS, dia/hora. |
| `test_world_generator.gd` | Tamanho 128×128, validade dos tiles, reprodutibilidade por seed, rio de borda a borda, montanha. |
| `test_simulation.gd` | Avanço por tempo real, sinal `ticked`, pausa, mundo reproduzível. |
| `test_asset_catalog.gd` | Todo asset existe com o tamanho do catálogo; folhas de sprites dividem em quadros inteiros; todo terreno tem tile. |
| `test_tile_info.gd` | Terreno com valores do GDD, conteúdo real do caixote, motivo de cada colono para a tarefa do tile, consulta sem alterar a simulação. |
| `test_construction.gd` | **Aceite do M3** (3 colonos erguem um cômodo 5×5 com porta e cama sozinhos, madeira gasta = custo exato, dá para entrar pela porta, colono com sono usa a cama), regras de colocação com motivo, parede com material exato, equipe mais rápida na cama, falta de material com motivo, cancelar devolve tudo, desmontar devolve metade e larga o conteúdo, pátio só aceita materiais, piso acelera, árvore no local é cortada antes, colono sai do lugar da parede, cama recupera 15/h. |
| `test_production.gd` | Fogueira cozinha até a meta e para (2 porções cruas por refeição, exato), "fazer N" e pausa, receita com dois ingredientes de lugares diferentes, falta de ingrediente explicada, apagar o pedido devolve os ingredientes, desmontar a bancada devolve os ingredientes, cozinha abate (6 carne e 1 pele), fogueira não abate, Cozinhar desligado, refeição preferida a frutas mais perto. |
| `test_food_sources.gd` | **Aceite do M4** (sem comida guardada nem frutas silvestres, 3 colonos vivem 4 dias de caça automática, abate, cozinha e plantação, sem ordem nova), espécies do MVP no mapa, caça deixa carcaça, presa ferida e colono perto fazem fugir, predador não é marcado, predador caça presa, migração, caça automática marca quem chega, plantação semeia, cresce, colhe e semeia de novo, água não vira plantação, cancelar apaga zona e caça. |
| `test_context_actions.gd` | Opções do clique: árvore cortar e cancelar, cama desmontar (qualquer tile dela), obra cancelada devolve o material, caçar animais mas não o predador, plantação criar, trocar o cultivo (tarefa refeita) e remover, colono dormir, cancelar ordem e comer; cada cultivo com uma coluna de arte por fase. |
| `test_colonists.gd` | **Aceite do M5** (Esforçada e Otimista × Preguiçoso, Pessimista e Glutão, com os mesmos níveis: trabalho, pausas, comida e humor diferentes), regras do gerador, curva de velocidade e tabela de XP, trabalho ensina e afinidade muda o humor, limite diário e esquecimento, nível muda a velocidade, humor anda até o alvo, dormir no chão é lembrado, agenda (para no Livre, dorme no Dormir), Esforçado termina a tarefa, Glutão, Covarde, pegar ferramenta melhor e largar, carga pesada. |
| `test_daylight.gd` | Horas de luz por estação (12, 15 e 9 h), noite, dia e meia-luz no pôr do sol. |
| `test_storage.gd` | Toda categoria com nome, categorias de alguns itens, pátio só com recursos básicos, filtro tira a comida e ela vai para o outro caixote, Guardar prioriza a pilha, sem lugar diz o motivo e avisa sozinho. |
| `test_ui_theme.gd` | Escala da interface por tamanho de tela e fonte sempre na grade de 8 px; escala inteira da janela. |
| `test_plants.gd` | Calendário das estações, uma linha de arte por estação, árvore jovem cresce, corte deixa toco que some, muda não dá frutas, colheita de fibra rende e volta a crescer, mapa com plantas jovens e adultas. |
| `test_navigation.gd` | Desvio de obstáculo, destino bloqueado, custo da água rasa, mapa conectado pelos vaus, corredor bloqueado divide regiões, regiões incrementais iguais a um recálculo completo. |
| `test_needs_and_reservations.gd` | Ritmo e limites das necessidades, dono único da reserva, rebrota dos arbustos. |
| `test_colonist_ai.gd` | **Aceite do M1** (3 dias sozinho), fome crítica interrompe e retoma ordem, sem conflito no mesmo arbusto, sem comida a fome não volta, reserva liberada, desmaio, ordem impossível, motivo real, mesma seed → mesmo comportamento. |
| `test_tasks.gd` | **Aceite do M2** (3 colonos dividem o corte sem conflito e a madeira bate exatamente), árvore única com um só trabalhador, interrupção para comer com progresso preservado e retomado, rocha sem acesso bloqueada com motivo, perda de acesso no caminho, reserva esquecida expira, transporte sem duplicar, caixotes cheios, prioridade desligada, prioridade vence distância, cancelamento limpo, comer do caixote, Esforçado × Preguiçoso, desempenho com 366 tarefas e 5 colonos. |

Depois de adicionar entradas ao catálogo, gere os provisórios que faltam:

```bash
godot --headless --path . -s res://tools/generate_placeholder_assets.gd
```

## Ordem de implementação (próximos marcos)

1. **M6 — Pesquisa e ruína.**
2. **M7 — Ameaça e combate.**
3. **M8 — Salvar/carregar, painéis, balanceamento, testes de partida completa.**

## Limitações conhecidas

- Fome em 0% derruba o humor, mas ainda não fere: saúde entra no M7.
- Estruturas não giram: a cama é sempre vertical (1×2) e a mesa horizontal (2×1).
- Pesquisas que liberam construções (Alvenaria de pedra, Armazenamento) entram no M6; por enquanto tudo do MVP está liberado.
- Não há detecção de cômodos nem teto: qualidade de sala e beleza ficam para depois do MVP.
- O colono só percebe que o caminho foi bloqueado quando chega no trecho bloqueado.
- A busca de comida e de tarefas calcula caminho só para as mais próximas em linha reta (6 por tipo); uma opção mais longe em linha reta mas com caminho mais curto pode ser ignorada.
- O painel do tile ainda não mostra temperatura nem beleza: esses sistemas não existem no MVP atual.
- A grade de Trabalho ainda não tem a coluna Pesquisar (M6).
- Comida não estraga e o abate não suja a cozinha: deterioração, limpeza e intoxicação ficam para depois do MVP.
- Qualidade dos itens (ruim a obra-prima) ainda não existe: a habilidade só muda a velocidade.
- Sem crises nem inspirações de humor (Fase 1 do GDD); sem lazer, convívio, Estudo e Ritual na agenda.
- Sem escolha de colonos no início da partida (2 a 5 com sorteio): entra com a criação de partida.
- A caça não testa linha de visão; o caçador atira através de árvores.
- Bancadas não têm níveis, anexos, ligação com contêineres nem ambiente (luz, limpeza, temperatura): fora do MVP pelo GDD.
- Uma só cultura (hortaliças) e sem estações no crescimento, conforme o escopo do MVP.
- Sem salvamento: o estado ainda não é serializado (os dados já usam ids estáveis, sem referência a nós).
- Árvores, arbustos e plantas de fibra já usam a arte final; o resto ainda é provisório. Os números das pilhas no chão ainda usam a fonte padrão (a Determination em 12 px não cabe num tile).
- Estações não afetam a simulação (só a arte), conforme o escopo do MVP.
- Árvores e arbustos não se espalham sozinhos: o mapa só perde árvores com o corte.
- A validação visual é manual; os testes automatizados cobrem a lógica.
