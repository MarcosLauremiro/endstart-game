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

## Estado atual (M0 a M8 — Fechamento do MVP)

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

### Pesquisa e ruína (M6)

| Área | Arquivo | Responsabilidade |
| --- | --- | --- |
| Pesquisa | `scripts/research/research_def.gd` + `resources/research/*.tres` | As 6 pesquisas do MVP: ramo, nível, custo em P e V, requisitos, estruturas e receitas que libera. |
| Conhecimento | `scripts/research/research.gd` | Pontos da comunidade (P e V), gatilhos que revelam ramos, primeiras vezes, Prática por trabalho, motivo de não poder liberar, liberar, o que falta para uma estrutura ou receita. |
| Ruína | `scripts/world/ruin.gd`, `ruin_builder.gd`, `ruin_exploration.gd` | Prédio antigo de 13×5 com 3 salas, colocado longe da chegada; investigar sala (tarefa de Pesquisar) rende Vestígio, sucata e, na última, o artefato, que revela Redescoberta. |

### Ameaça e combate (M7)

| Área | Arquivo | Responsabilidade |
| --- | --- | --- |
| Saúde | `scripts/combat/health.gd`, `injury.gd` | Ferimentos (corte, perfuração, contusão), perda de sangue, caído e morto, dor, sangramento e cura por hora, tratar. Usada por colonos e saqueadores. |
| Combate | `scripts/combat/combat.gd` | Regras de um golpe: dano, alcance e intervalo da arma na mão (`ItemDef.attack_*`), chance de acerto, Força no corpo a corpo, ferimento causado. |
| Socorro e morte | `scripts/combat/medical.gd` | Mantém as tarefas de Emergência (Socorrer até uma cama livre, Tratar) seguindo o paciente; morte permanente (itens no chão, humor, adaptação). |
| Ameaça | `scripts/threat/threats.gd`, `raid.gd`, `threat_director.gd` | Estado (próximo ataque, ataque avisado ou em andamento, saqueadores, adaptação); pontos de ameaça do GDD, compra do grupo, aviso com fumaça 1,5 dia antes, chegada pela borda, fim e calma. |
| Saqueadores | `scripts/threat/raider.gd`, `raider_ai.gd` | Dados e comportamento: saquear o contêiner ou a pilha mais perto, atacar quem chega perto ou os ataca, fugir ferido, recuo do grupo, arma no chão ao morrer. Pensam a cada 30 ticks (escalonados), andam e golpeiam a cada tick. |

### Salvar e carregar (M8)

| Área | Arquivo | Responsabilidade |
| --- | --- | --- |
| Salvamento | `scripts/simulation/save_game.gd` | Serializa o grafo de objetos do `WorldState` pelas variáveis de script (`PROPERTY_USAGE_SCRIPT_VARIABLE`): cada objeto vira um registro `{script, props}`, referências viram `{"__ref": índice}` (objetos compartilhados continuam um só), definições `.tres` viram o caminho e o `RandomNumberGenerator` vira semente e estado. Grava com `store_var` comprimido (ZSTD) em `user://saves/<nome>.save`, com cabeçalho (versão, dia, hora, colonos, data). Ganchos: `save_skip()` e `after_load()` (a `NavigationGrid` não salva o `AStarGrid2D` e o refaz). `Simulation.from_state` continua a partida carregada. |

### Apresentação

| Área | Arquivo | Responsabilidade |
| --- | --- | --- |
| Mapa | `scripts/world/world_view.gd`, `scripts/world/terrain_tiles.gd` | Chão em grade dupla: uma `TileMapLayer` por tipo de terreno, deslocada meio tile, na ordem de cima para baixo; o terreno mais baixo do tile é preenchido e os de cima desenham a borda (desenhada na folha quando o par existe, senão a silhueta da grama recortando o preenchimento). `TerrainTiles` monta o atlas uma vez a partir das folhas `*_variants`. Paredes de montanha por célula pelos 4 vizinhos, com sombra embaixo da face. `WorldData.revision` avisa mudanças e `sync` redesenha só as células alteradas (rocha escavada). |
| Objetos | `scripts/world/objects_view.gd` | Plantações e cultivos (4 fases), tocos, arbustos, construções e bancadas, caixotes, pilhas com quantidade, animais e saqueadores (interpolados), e, numa camada por cima de árvores e colonos (z 2): barras de vida de quem está ferido, fumaça do aviso de ataque, designações com barra de progresso (vermelhas se bloqueadas; a caça segue o animal), retângulo de arraste. |
| Árvores | `scripts/world/trees_view.gd` | Um `Sprite2D` por árvore (quadros de 32×32, centrados no tile e apoiados na base), sob o mesmo nó com `y_sort` dos colonos: a copa esconde quem está atrás (ao norte), e quem está na frente ou ao lado passa por cima. |
| Construções | `scripts/construction/structures_view.gd`, `scripts/construction/structure_art.gd` | Um `Sprite2D` por construção pronta (fora os pisos) e por contêiner, no mesmo nó com `y_sort` dos colonos e árvores: o que bloqueia ordena pela última linha, o que se pisa (cama, porta) pela primeira. `StructureArt` escolhe o quadro das paredes (`wall_tiles`) pelos vizinhos com `joins_walls`, prontos ou em planta; o `ObjectsView` usa o mesmo recorte nas plantas e na prévia. Botão do meio: `Construction.def_at` acha a construção do tile e a cena entra no modo de construir a mesma. |
| Dia e noite | `scripts/simulation/daylight.gd`, `scripts/world/daylight_view.gd` | Horas de luz pela fórmula do GDD e luz de 0 a 1 por tick; um `CanvasModulate` escurece só o mapa à noite (a interface não). |
| Colonos | `scripts/colonists/colonists_view.gd`, `colonist_looks.gd`, `colonist_appearance.gd`, `shaders/palette_swap.gdshader` | Um `Node2D` por colono com 4 camadas (corpo tingido pela pele, roupa de baixo, de cima e cabelo), todas no mesmo quadro: lado do passo (lembra o último quando para) e caminhada de 8 quadros pelo tick. Cabelo e roupa trocam a rampa indexada de 4 cores com um `ShaderMaterial` por cor (dividido entre colonos). `ColonistLooks` tem as tabelas, o gerador pela idade, os recortes e a mesma composição na CPU (retrato da barra e testes). A aparência é dado do colono e vai para o arquivo salvo. Interpolado entre células; deitado quando dorme, cai, repousa ou é carregado; ícone de convocado ou ferido acima da cabeça; marcador de seleção. |
| Câmera | `scripts/world/camera_controller.gd` | Panorâmica e três níveis de zoom fixos. |
| Catálogo de arte | `scripts/assets/asset_catalog.gd` | Lista única de assets: caminho, tamanho, uso. Fallback provisório. |
| Arte provisória | `scripts/assets/placeholder_painter.gd`, `tools/generate_placeholder_assets.gd` | Provisórios no tamanho final; o gerador nunca sobrescreve. |
| Tema | `scripts/ui/ui_theme.gd` | Paleta "rust punk" do GDD, molduras 9-slice, barras, fonte pixel Dogica Pixel sem suavização, escala da interface e tamanho da fonte. |
| Recursos | `scripts/ui/resource_bar.gd` | Topo esquerdo: comida em dias, madeira, pedra, carne crua, vegetais, frutas — somados dos itens reais. |
| Tempo | `scripts/ui/time_panel.gd` | Topo direito: dia, hora, pausa e velocidades; em vermelho, quanto falta para o ataque avisado ou quantos saqueadores estão no mapa. |
| Ficha | `scripts/ui/inspect_panel.gd` | Canto inferior esquerdo, em abas. Geral: histórias, Força, agenda agora, traços (efeitos na dica), o que faz (e se está convocado), saúde com ferimentos e sangramento, fome, sono, humor e pensamentos. Habilidades: nível, afinidade, título, % para o próximo nível e velocidade. Equipamento: Camisa, Calça, Mão (com bônus) e carga. Por quê: motivo real, melhores tarefas, decisões recentes. |
| Ordens | `scripts/ui/bottom_bar.gd` | Base: construir, cortar (C), minerar (M), colher (H), caçar (K), plantação (P), desmontar (D), cancelar (X), Trabalho e Armazém. |
| Trabalho | `scripts/ui/work_priority_window.gd` | Grade de prioridades 1–4/desligado por colono e tipo (dica com a habilidade, nível e afinidade); caça automática por espécie. |
| Pesquisa | `scripts/ui/research_window.gd` | Pontos, ramos revelados com custo, o que libera e Liberar (ou o motivo); ramos escondidos como "???" com a dica (R). Construções e receitas travadas aparecem desligadas no menu e no painel da bancada. |
| Agenda | `scripts/ui/schedule_window.gd` | Uma linha por colono e uma coluna por hora; escolha Dormir, Trabalhar ou Livre e clique ou arraste (A). |
| Bancada | `scripts/ui/workbench_panel.gd` | Ao selecionar uma bancada (canto superior direito): pedido em andamento com ingredientes, por que está parada, motivo de cada colono, fila com modo, meta (±1, botão direito ±10), pausa, subir e apagar, e botões de novo pedido. |
| Tile | `scripts/ui/tile_info.gd`, `scripts/ui/tile_panel.gd`, `scripts/ui/container_view.gd` | Clique num tile sem colono: terreno (movimento, fertilidade, construção do GDD), plantas, toco, contêiner com a grade de espaços (ícone e quantidade, dica com reservas) e o botão Configurar que abre o filtro, pilha, tarefa com progresso/reserva/bloqueio e o motivo de cada colono fazer ou não (mesmo seletor da IA, em modo consulta). Atualiza 4× por segundo. |
| Construir | `scripts/ui/build_menu.gd` | Menu com custo e tempo de cada estrutura (B). Prévia verde/vermelha na colocação; plantas aparecem em azul translúcido. |
| Armazém | `scripts/ui/storage_panel.gd` | Totais por item (contêineres, chão, mãos), comida em dias, busca, contêineres com ocupação; clicar centraliza a câmera (I). |
| Opções | `scripts/ui/context_actions.gd`, `scripts/ui/action_bar.gd` | Botões do que foi clicado, no topo do painel do tile ou do colono. Árvore: cortar; planta: colher; rocha: minerar; obra: cancelar (devolve o material); construção, contêiner ou bancada: desmontar; animal: caçar (predador desligado, com motivo); plantação: plantar cenoura, trigo ou cogumelo, remover; chão livre: criar plantação; colono: convocar ou dispensar, comer agora, dormir agora, cancelar ordem. Marcado vira "cancelar". |
| Mensagens | `scripts/ui/message_log.gd` | Canto inferior direito: mensagens que somem sozinhas. |
| Alertas | `scripts/ui/alerts.gd`, `scripts/ui/alerts_panel.gd` | Lateral direita: um alerta por tipo (ataque, caído, sangrando, aviso de ataque com os armados, faminto, pouca comida, em crise, exausto, sem cama, item sem lugar), até 5 por urgência e "+N alertas"; clicar leva a câmera ao problema e seleciona o colono. O Armazém os cobre enquanto aberto. |
| Barra de colonos | `scripts/ui/colonist_bar.gd` | Topo centro: retrato e nome de cada colono (vermelho caído ou sangrando, laranja convocado); a dica diz estado, o que faz e por quê; clicar seleciona e leva a câmera. |
| Menu | `scripts/ui/menu_window.gd` | Esc sem nada selecionado ou botão Menu: pausa; salvar com nome, lista de partidas com Carregar e Apagar (segundo clique confirma), Mapa novo e Sair. Ctrl+S salva rápido; salvamento automático às 6h de cada dia novo. |
| Entrada | `scenes/main/main.gd` + `main.tscn` | Liga tudo e traduz mouse e teclado em comandos. V convoca o selecionado ou o grupo (sem seleção, todos); botão direito num saqueador manda atacar. Arrastar sem ferramenta seleciona vários colonos ou uma área (o clique comum acontece ao soltar). |
| Seleção múltipla | `scripts/ui/multi_select.gd`, `scripts/ui/selection_panel.gd` | Colonos no retângulo; senão as árvores, rochas e plantas dele (marca em cada uma, só Cortar, Minerar e Colher, saem da seleção quando somem); senão a área inteira, com as opções juntas por rótulo (a chave `key` das ContextActions evita repetir um alvo de vários tiles); resumo do que há na área; convocar, cancelar e mandar o grupo (tiles espalhados em volta do destino). O painel recalcula áreas grandes (mais de 1.500 tiles) só quando a seleção muda ou uma opção é usada. |

### Ciclo de um tick

```
Simulation.step()
  ├─ a cada hora: plantas silvestres e cultivos crescem; tarefas de semear e colher são criadas;
  │    ferimentos sangram e curam; ThreatDirector avisa ou traz o ataque
  ├─ a cada 30 ticks: reservas sem avanço há 30 s expiram; colono sem ação não segura reserva;
  │    Medical.sync cria, segue e tira as tarefas de Emergência
  └─ para cada colono:
	   ├─ Needs.tick(dormindo?)
	   ├─ se for a vez dele (tick + offset) % 30 == 0, ou force_think:
	   │    ColonistBrain.decide (só camadas mais altas que a atual) → Action + DecisionRecord
	   │    ActionRunner.start → reserva → caminho → INDO ou EXECUTANDO
	   └─ ActionRunner.step → mover / executar / concluir
  └─ Wildlife.tick: animais pensam a cada 60 ticks (escalonados) e andam; uma vez por dia, migração
  └─ RaiderAI.tick: saqueadores pensam, golpeiam e andam; fim do ataque quando nenhum resta
  └─ mortos (dano ou sangue no limite) saem da partida
```

### Fluxo de uma tarefa

`Designar → tarefa no quadro → seletor avalia (prioridade, coluna, pontuação, validade) → reserva → caminha → executa (progresso fica na tarefa) → aplica o resultado (itens no chão) → libera → nova tarefa de Carregar → reserva itens e espaço → leva ao caixote → libera`.

### Camadas de decisão

| Camada | O que existe hoje |
| --- | --- |
| 1. Reação | Caído (vence tudo, até outra reação; nada o interrompe). Desmaio: sono em 0% → dorme onde está. Fugir de saqueador a 8 tiles (Covarde: 12) se não está convocado; Covarde convocado foge com 25 de dano. |
| 2. Necessidade crítica | Sangrando → estanca os próprios ferimentos; fome < 15% → comer; sono < 8% → dormir; 30 de dano ou mais → repousar na cama até 15. Interrompe o trabalho. O convocado pula esta camada. |
| 3. Ordem direta | Mover, priorizar uma tarefa, atacar um saqueador; convocado sem ordem segura a posição e luta. Uma ordem nova substitui a anterior. Interrompida por 1 e 2, fica guardada e é retomada. |
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
- **Categorias e filtro (GDD: Organização):** o filtro do MVP é por categoria, no botão Configurar embaixo da grade de espaços do contêiner. O que deixa de ser permitido sai na hora para o chão ao lado (só o que não está reservado) e vira tarefa de Carregar para outro contêiner. O pátio de materiais aceita só recursos básicos. Os números do enum de categoria ficam gravados nos `.tres`: categorias novas entram no fim.
- **Guardar pelo clique:** a tarefa de Carregar da pilha vira urgência 2 (pedido do jogador, GDD). Sem contêiner que aceite, a opção diz o motivo; o transporte travado por falta de lugar avisa sozinho, no máximo uma vez a cada 6 h por item.
- **Registro no GDD:** desde o armazenamento por categoria, tudo o que é feito além do GDD também é escrito no `GDD.md`, na seção certa; este documento guarda as decisões técnicas.
- **Pontos (GDD):** 1 P a cada 3 h de trabalho produtivo (trabalhar numa tarefa ou caçar; carregar não conta), +3 P na primeira vez de cada receita, construção, caça por espécie e colheita por cultivo; 2 V por sala de ruína, 15 V pelo artefato, 10 V por artefato analisado. Curioso: +25% nos pontos que gera e ×1,3 na pontuação de tarefas de Pesquisar. A habilidade Pesquisa (multiplicador da análise) fica fora do MVP.
- **Travas de pesquisa:** cozinha e abate (Bancada de cozinha), parede de pedra e blocos (Alvenaria de pedra), pátio de materiais (Armazenamento), faca e machado (Ferramentas de pedra), lança, arco e flechas (Armas primitivas), Mesa de análise e analisar artefato (Mesa de análise). A bancada de produção, a fogueira e a Mesa de estudos estão liberadas desde o início (GDD). Contêineres e estruturas colocados direto pelo código (início da partida, testes) não passam pela trava.
- **Gatilhos no MVP:** Defesa e armas na primeira caça (ainda não há ataques); Redescoberta ao achar o artefato (o gatilho do GDD, "primeiro artefato analisado", depende da própria Mesa de análise).
- **Mesas com materiais do MVP:** Mesa de estudos 20 madeira e 5 fibra (o GDD pede couro); Mesa de análise 15 madeira e 5 sucata (o GDD pede vidro).
- **Curioso:** o efeito provisório do M5 (vagar mais longe) saiu; ficou o do GDD.
- **Atalhos:** R abre a Pesquisa; o mapa novo passou para F5 e só em build de desenvolvimento.
- **Combate do MVP** (números provisórios, registrados no GDD): saúde 100, caído com 60 de dano ou 50% de sangue, morto com 100 ou 100%; sangramento 0,5%/h por ponto de dano sem tratar; cura 0,5/h, 2/h tratado, ×1,5 na cama. Acerto, dano e armas na tabela do GDD (Combate no MVP). O arco não gasta flechas no MVP.
- **Ataques do MVP:** IA BALANÇA fixa; primeiro ataque no dia 6, depois a cada 5 a 9 dias; aviso 1,5 dia antes. Os pontos seguem a fórmula do GDD e, no MVP, a riqueza fica abaixo de 10.000 (P\_riqueza 0): os ataques têm 1 a 2 saqueadores com 2 a 5 colonos.
- **Saqueadores com objetivo:** vão ao saque e só atacam quem chega a 7 tiles ou os ataca; sem isso, colonos que fogem eram perseguidos pelo mapa inteiro e o ataque não acontecia.
- **Emergência** é um tipo de trabalho novo (primeira coluna, prioridade 1 por padrão) para Socorrer e Tratar. Não há habilidade de Medicina no MVP: tratar sempre funciona e leva 30 min.
- **Morte:** o colono sai de `state.colonists`; quem guarda o id (saqueador, tarefa, carregador) confere com `colonist_by_id`. Sem corpo nem funeral no MVP.
- **Testes:** `test_runner.gd -- --only=texto` roda só as suítes cujo caminho contém o texto.
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
| `test_structures_view.gd` | Quadro da parede pelos vizinhos (porta, planta, prévia), construções ordenadas com os colonos (atrás some, cama por cima), desmontar reabre a ponta, toda construção sólida bloqueia o caminho e o botão do meio copia a construção exata do tile. |
| `test_terrain_tiles.gd` | Toda folha de chão segue o bloco 6×3 (cantos sem costura), pares desenhados à mão, atlas com borda para todo terreno, vértice com o terreno de baixo inteiro e a borda dos de cima, paredes pelos vizinhos, sombra, rocha escavada redesenhada e mapa real desenhado rápido. |
| `test_asset_catalog.gd` | Todo asset existe com o tamanho do catálogo; folhas de sprites dividem em quadros inteiros; todo terreno tem tile. |
| `test_tile_info.gd` | Terreno com valores do GDD, conteúdo real do caixote, motivo de cada colono para a tarefa do tile, consulta sem alterar a simulação. |
| `test_construction.gd` | **Aceite do M3** (3 colonos erguem um cômodo 5×5 com porta e cama sozinhos, madeira gasta = custo exato, dá para entrar pela porta, colono com sono usa a cama), regras de colocação com motivo, parede com material exato, equipe mais rápida na cama, falta de material com motivo, cancelar devolve tudo, desmontar devolve metade e larga o conteúdo, pátio só aceita materiais, piso acelera, árvore no local é cortada antes, colono sai do lugar da parede, cama recupera 15/h. |
| `test_production.gd` | Fogueira cozinha até a meta e para (2 porções cruas por refeição, exato), "fazer N" e pausa, receita com dois ingredientes de lugares diferentes, falta de ingrediente explicada, apagar o pedido devolve os ingredientes, desmontar a bancada devolve os ingredientes, cozinha abate (6 carne e 1 pele), fogueira não abate, Cozinhar desligado, refeição preferida a frutas mais perto. |
| `test_food_sources.gd` | **Aceite do M4** (sem comida guardada nem frutas silvestres, 3 colonos vivem 4 dias de caça automática, abate, cozinha e plantação, sem ordem nova), espécies do MVP no mapa, caça deixa carcaça, presa ferida e colono perto fazem fugir, predador não é marcado, predador caça presa, migração, caça automática marca quem chega, plantação semeia, cresce, colhe e semeia de novo, água não vira plantação, cancelar apaga zona e caça. |
| `test_context_actions.gd` | Opções do clique: árvore cortar e cancelar, cama desmontar (qualquer tile dela), obra cancelada devolve o material, caçar animais mas não o predador, plantação criar, trocar o cultivo (tarefa refeita) e remover, colono dormir, cancelar ordem e comer; cada cultivo com uma coluna de arte por fase. |
| `test_colonists.gd` | **Aceite do M5** (Esforçada e Otimista × Preguiçoso, Pessimista e Glutão, com os mesmos níveis: trabalho, pausas, comida e humor diferentes), regras do gerador, curva de velocidade e tabela de XP, trabalho ensina e afinidade muda o humor, limite diário e esquecimento, nível muda a velocidade, humor anda até o alvo, dormir no chão é lembrado, agenda (para no Livre, dorme no Dormir), Esforçado termina a tarefa, Glutão, Covarde, pegar ferramenta melhor e largar, carga pesada. |
| `test_daylight.gd` | Horas de luz por estação (12, 15 e 9 h), noite, dia e meia-luz no pôr do sol. |
| `test_storage.gd` | Toda categoria com nome, categorias de alguns itens, pátio só com recursos básicos, filtro tira a comida e ela vai para o outro caixote, Guardar prioriza a pilha, sem lugar diz o motivo e avisa sozinho, recursos básicos juntam até 99 por espaço, grade de espaços do contêiner com o filtro escondido no Configurar. |
| `test_multi_select.gd` | Colonos no retângulo, convocar e dispensar o grupo, mover espalha cada um num tile, cancelar ordens, árvores e rochas do retângulo só com Cortar, Minerar e Colher (Cortar em todas e depois cancelar), construção de 4 tiles conta uma vez, tiles espalhados andáveis, painel com a lista do grupo e o resumo da área, plurais. |
| `test_research.gd` | **Aceite do M6** (um colono investiga as 3 salas depois de uma ordem; o artefato revela Redescoberta e o Vestígio libera a Mesa de análise), ruína alcançável com 3 salas e 1 artefato, árvore do MVP e ramos escondidos, Prática por trabalho e primeira vez, Curioso +25%, travas de construção e receita, liberar na Mesa de estudos, primeira caça revela Defesa e armas, Curioso prefere tarefas com artefatos, analisar o artefato rende 10 V. |
| `test_combat.gd` | **Aceite do M7** (3 colonos com lanças e convocados enfrentam 2 saqueadores: ninguém morre, os saqueadores morrem ou fogem e alguém sai ferido; sem preparo, levam itens), pontos de ameaça do exemplo do GDD, compra do grupo, calma, aviso com fumaça 1,5 dia antes e chegada, quem não está convocado foge e o convocado luta (e treina Corpo a corpo), caído sem socorro morre de perda de sangue (morte permanente, itens no chão, humor, adaptação), socorro até a cama e tratamento com recuperação, ferido de pé estanca o próprio sangramento, Covarde foge de mais longe. |
| `test_save_game.gd` | Partida carregada continua idêntica à original por 20 mil ticks (e a comparação percebe uma diferença mínima), salvar no meio de um ataque, objetos compartilhados continuam um só, definições voltam como o mesmo recurso, navegação refeita, gravar, listar, carregar e apagar o arquivo. |
| `test_alerts.gd` | Caído antes de faminto, vários colonos numa linha, aviso de ataque com os armados e a fumaça, ataque em andamento no topo, sem cama, pouca comida, item sem lugar, painel com 5 e "+N alertas", barra de colonos com o porquê. |
| `test_full_game.gd` | 2 dias com o jogador automático e 3 colonos: ninguém morre, camas, fogueira, bancada e mesa de estudos prontas, ainda há madeira e refeições, nenhum tick passa de 50 ms, salvar no meio continua igual. |
| `test_colonist_looks.gd` | Cabelo e cor pela idade em todas as idades, variedade (todas as peles, cabelos, cores e peças aparecem), mesma pose em todas as camadas nas 4 direções, troca de cor sem mover pixels, mesma seed dá a mesma aparência e ela vai para o arquivo salvo, a camada do mapa vira com o passo, continua virada parada e esconde a roupa tirada. |
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

## Partida completa

```bash
godot --headless --path . -s res://tests/full_game.gd -- --days=30 --colonists=5 --seed=12345 [--player]
```

Roda a partida headless e imprime um resumo por dia (colonos, fome, humor, comida guardada, madeira, refeições, camas, alertas) e, no fim, o tempo por tick (média, p99, pior), o que isso custa a 3× num quadro de 60 fps e as mensagens marcantes. `--player` liga o `FullGamePlayer` (`tests/full_game_player.gd`), que faz o que um jogador faria pela API da simulação: fogueira, bancadas, mesa de estudos e camas perto da chegada, corte, mineração, plantação, caça automática, pesquisas, pedidos e convocar no ataque.

## Ordem de implementação (próximos marcos)

**Resultado da partida de 30 dias (seed 12345, 5 colonos, M8):** sem jogador, os 5 sobrevivem com as refeições iniciais e frutas do mato, e os saqueadores levam itens sem resistência. Com o jogador automático, os 5 sobrevivem aos 4 ataques (no terceiro, 3 colonos caem e são socorridos), a comida guardada sobe para 50 dias e 5 pesquisas são liberadas. Tempo por tick: média 0,09 ms, p99 0,3 ms, pior 4,2 ms (11 ticks acima de 2 ms, todos na virada da hora); a 3×, 1,6% de um quadro de 60 fps.

**Ajustes de balanceamento do M8:** sangramento de 0,5% para 0,25% de sangue por hora por ponto de dano (um caído morria em 1,5 h, antes do socorro); o convocado sem alcance vai para cima de quem atira nele de longe (um arqueiro sozinho matava 4 colonos convocados que só seguravam a posição); a mensagem "se levantou" não sai mais quando o colono morre.

O MVP (M0 a M8) está completo. O próximo passo é testar com jogadores e trocar a arte provisória.

## Limitações conhecidas

- Fome em 0% derruba o humor, mas ainda não fere (a saúde do M7 vem só de combate).
- Caídos não comem; a recuperação leva horas, então no MVP isso não chega a ser um problema.
- Saqueadores não destroem construções nem sequestram; não há cobertura nem defesas construídas.
- Estruturas não giram: a cama é sempre vertical (1×2) e a mesa horizontal (2×1).
- Os quatro níveis de compreensão dos artefatos (Desconhecido a Reproduzível) ainda não existem: analisar só rende Vestígio. Sem provas nas pesquisas (nenhuma das 6 pede).
- Não há detecção de cômodos nem teto: qualidade de sala e beleza ficam para depois do MVP.
- O colono só percebe que o caminho foi bloqueado quando chega no trecho bloqueado.
- A busca de comida e de tarefas calcula caminho só para as mais próximas em linha reta (6 por tipo); uma opção mais longe em linha reta mas com caminho mais curto pode ser ignorada.
- O painel do tile ainda não mostra temperatura nem beleza: esses sistemas não existem no MVP atual.
- Comida não estraga e o abate não suja a cozinha: deterioração, limpeza e intoxicação ficam para depois do MVP.
- Qualidade dos itens (ruim a obra-prima) ainda não existe: a habilidade só muda a velocidade.
- Sem crises nem inspirações de humor (Fase 1 do GDD); sem lazer, convívio, Estudo e Ritual na agenda.
- Sem escolha de colonos no início da partida (2 a 5 com sorteio): entra com a criação de partida.
- A caça não testa linha de visão; o caçador atira através de árvores.
- Bancadas não têm níveis, anexos, ligação com contêineres nem ambiente (luz, limpeza, temperatura): fora do MVP pelo GDD.
- Uma só cultura (hortaliças) e sem estações no crescimento, conforme o escopo do MVP.
- O arquivo salvo depende dos nomes dos campos e dos caminhos dos scripts: renomear um campo ou mover um script quebra saves antigos (a versão do arquivo recusa os incompatíveis, sem migração).
- Árvores, arbustos e plantas de fibra já usam a arte final; o resto ainda é provisório. Os números das pilhas no chão ainda usam a fonte padrão (a Determination em 12 px não cabe num tile).
- Estações não afetam a simulação (só a arte), conforme o escopo do MVP.
- Árvores e arbustos não se espalham sozinhos: o mapa só perde árvores com o corte.
- A validação visual é manual; os testes automatizados cobrem a lógica.
