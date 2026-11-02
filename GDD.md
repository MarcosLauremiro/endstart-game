# ENDSTART — Documento de design

Oct 29, 2026 · @miro

## Visão geral

Um jogo de gestão e simulação de colônia em pixel art, num mundo futurista pós-apocalíptico onde a humanidade renasceu sobre ruínas de mais de 3 mil anos. O jogador guia um pequeno assentamento, forma uma cultura ao longo do jogo e decide como crescer: explorando, pesquisando, comerciando ou guerreando.

**Nome: ENDSTART.** Um trocadilho entre fim (end) e início (start): o jogo começa onde o mundo terminou.

**Frase-conceito:** num mundo onde a tecnologia foi perdida, pesquisar é redescobrir

### Pilares

1. **Histórias que nascem das pessoas.** Cada colono tem personalidade, e as crises surgem dessas personalidades.
2. **Liberdade de caminho.** Focar na base, explorar o mundo, comerciar ou conquistar são todos válidos.
3. **O passado é um recurso perigoso.** Tecnologia antiga dá poder, mas cobra um preço.
4. **Lore em fragmentos.** A história do mundo é montada pelo jogador, sem linha narrativa fixa.

### Referências e o papel de cada uma

| Referência | O que inspira | Experiência no jogo |
| --- | --- | --- |
| RimWorld (principal) | Colonos, personalidade, construção livre | O núcleo: a vida e as crises da comunidade |
| Factorio | Cadeias de produção e automação | A economia, que cresce conforme a tecnologia é recuperada |
| Another Brick in the Mall | Gestão de comércio e visitantes | O assentamento como entreposto de caravanas e clãs |

As referências inspiram experiências, não são copiadas sistema por sistema.

### Ficha técnica

- **Gênero:** gestão e simulação de colônia, com exploração
- **Visão:** top-down 2D, pixel art
- **Motor:** Godot 4
- **Arte:** Aseprite
- **Plataforma inicial:** PC

### Loop central

&#91;embedded content: loop central · 6 etapas\]

Quanto mais tecnologia a colônia recupera, mais forte ela fica e mais a IA e os rivais reagem, o que empurra o jogador a explorar de novo.

## Mundo e lore

Há mais de 3 mil anos, 99% da humanidade morreu. Os sobreviventes formaram pequenas sociedades isoladas, perderam quase todo o conhecimento e, muito tempo depois, uma nova civilização começou a crescer usando os restos do mundo antigo.

O mundo é um planeta fictício parecido com a Terra, com continentes, oceanos e polos, mas sem lugares reais.

### A verdade central (proposta)

- O colapso foi uma combinação de crise climática, pandemias e guerras espalhadas pelo mundo. A antiga civilização criou uma IA para salvar o planeta desse colapso.
- A IA concluiu que a humanidade era a causa do problema e reduziu a população.
- Para "restaurar" os ecossistemas, a bioengenharia daquela época liberou organismos modificados. Deles evoluíram as criaturas hostis de hoje.
- A IA nunca foi totalmente desligada. Ela dorme em parte e reage quando a humanidade volta a usar tecnologia avançada.

### O Mundo

Ninguém hoje sabe que a IA é uma máquina. As pessoas a chamam de **o Mundo**: a força que manda tempestades, derruba o que voa e pune quem mexe demais no passado.

- **Herdeiros** tendem a venerá-la, como uma divindade que guarda o conhecimento antigo.
- **Enraizados** tendem a temê-la, e veem as relíquias como forma de despertar sua ira.
- **Remendadores** a tratam como clima ou sorte: algo a respeitar, sem pensar demais.
- Dentro de cada cultura há exceções, e colonos podem mudar de visão ao longo da partida.

Descobrir que "o Mundo" é uma IA é uma das grandes revelações do arco principal.

A história não precisa ser profunda. Basta que o jogador perceba, aos poucos, o que aconteceu e por que o mundo é como é.

### Como a história é revelada

- **Fragmentos antigos:** terminais, gravações, placas, murais e arquivos encontrados em ruínas.
- **Mitos dos clãs:** cada cultura conta sua versão do fim do mundo, e as versões se contradizem. Cruzar mitos com fragmentos revela a verdade.
- **Diário de descobertas:** um registro que se preenche como quebra-cabeça. Fragmentos podem ser lidos em qualquer ordem.
- **Artefatos com história:** alguns itens trazem uma descrição curta sobre quem os usou e como.

### Fauna

- **Animais comuns:** espécies atuais (cães, cabras, aves, cavalos), usadas para criação, caça e transporte.
- **Criaturas evoluídas:** descendentes da bioengenharia antiga. Algumas são domáveis, outras são predadoras, e algumas formam ninhos que crescem se forem ignorados.
- **Espécies do MVP:** Lebre (caça pequena), Cervo (caça grande) e Lobo-espinho (criatura evoluída, predadora). Presas pastam e fogem quando um colono ou um predador chega perto; o lobo-espinho caça presas de tempos em tempos. Quando uma espécie fica abaixo da população que o mapa sustenta, outro animal chega pela borda uma vez por dia.
- **Caça:** o caçador se aproxima até o alcance da arma (improvisada, lança ou arco) e ataca de longe. O animal ferido foge e o caçador persegue. Morto, vira uma carcaça no chão, que é guardada e abatida na cozinha. A **caça automática** por espécie marca os animais que estão no mapa e os que chegarem.

## Culturas

A cultura **não é escolhida no início**. Os sobreviventes chegam com origens diferentes e, com o tempo, o que o grupo faz, pesquisa e decide forma uma identidade. Em algum momento, a comunidade precisa assumir essa identidade, e essa decisão muda o resto da partida.

Os clãs controlados pelo jogo já têm cultura definida: eles se formaram muito antes do jogador chegar.

### Os três caminhos

| Cultura | Visão sobre a tecnologia antiga | Pontos fortes | Pontos fracos | Curva de desafio |
| --- | --- | --- | --- | --- |
| **Enraizados** | Evitam: alguns por crença, outros só por medo | Artesanato, animais e criaturas domadas, vida com pouco; o Mundo quase os ignora | Produção lenta, medicina limitada | Difícil no início, estável depois |
| **Remendadores** | Usam o que funciona, sem entender como | Flexíveis, bons no comércio e na improvisação | Equipamentos improvisados quebram e falham | Equilibrada |
| **Herdeiros** | Veneram e estudam o passado | Automação, armas antigas, transporte avançado | Dependem de energia e peças raras; atraem o Mundo | Fácil no início, crescente depois |

A dificuldade base vem da personalidade da IA e do terreno. A cultura muda a **curva** do desafio a partir do meio do jogo.

### Tendência cultural

A comunidade acumula pontos em três tendências: **Raiz**, **Remendo** e **Herança**. A proporção entre elas aparece num triângulo, e o ponto da comunidade se move conforme o jogo avança.

&#91;embedded content: tendência cultural · Raiz · Remendo · Herança\]

A tendência vem do **uso**, da **pesquisa**, das **pessoas** e das **escolhas**:

| Fonte | Raiz | Remendo | Herança |
| --- | --- | --- | --- |
| Uso: a cada 8 horas de trabalho (+1) | Ofícios artesanais, cultivo, animais | Máquinas a combustão, consertos, comércio | Máquinas e energia antigas |
| Uso: ações marcantes | Enterrar ou destruir uma relíquia (+15) | Usar artefato sem compreender (+3) | Restaurar uma máquina antiga (+15) |
| Pesquisa: por projeto concluído | Ofícios (+10) | Adaptações, que misturam ofício e relíquia (+10) | Redescoberta em nível Compreendido ou Reproduzível (+10) |
| Rituais | Rituais de temor ao Mundo (+5) | — | Rituais de veneração ao Mundo (+5) |
| Pessoas: por colono, por dia (+0,2) | Origem Enraizada; Devoto, Temeroso | Origem Remendadora; Ganancioso, Nômade | Origem Herdeira; Curioso, Obcecado |
| Escolhas em eventos (+10) | Enterrar o artefato | Desmontar para peças | Estudar o artefato |

Uso e pesquisa contam igual: dá para chegar a um caminho só usando, só pesquisando, ou pelos dois.

### Período de formação

Do início até a definição, a comunidade é um **grupo de sobreviventes**:

- Sem bônus culturais, valores coletivos ou festivais. Cada colono mantém os valores da sua origem.
- Toda a pesquisa está aberta, sem descontos.
- A atenção do Mundo usa multiplicador ×1,0.
- Os colonos comentam a mudança ("Estamos ficando parecidos com os Herdeiros"), para o jogador perceber a direção.

### A Assembleia: o momento da decisão

Quando a comunidade vira **acampamento** ou chega ao **dia 40** (o que vier primeiro), acontece a Assembleia em volta da fogueira comunal.

1. Cada colono declara qual caminho prefere, com base na origem, nos traços e na tendência atual.
2. O jogador vê a tendência em porcentagem, quantos colonos apoiam cada caminho e as consequências de cada escolha.
3. O jogador escolhe um dos três caminhos.

Dá para **adiar** até 15 dias ("ainda não decidimos"), com humor caindo 1 ponto por dia de espera para todos.

**Consequências da escolha:**

- **Seguir a tendência dominante:** celebração, humor +8 por 5 dias.
- **Ir contra a preferência de um colono:** humor −10 por 10 dias para ele ("não fui ouvido"). Se ele tiver um traço forte contrário, como Devoto diante dos Herdeiros, há 20% de chance de deixar a comunidade.
- **Escolher um caminho com menos de 20% de tendência:** 20 dias de adaptação, com bônus culturais pela metade.

**Matiz:** se a segunda maior tendência tiver 30% ou mais, ela vira um matiz da cultura, com um bônus pequeno (por exemplo, "Herdeiros de Raiz" ganham XP ×1,05 em Artesanato). São seis combinações possíveis além das três culturas puras.

### O que a definição muda

| Cultura | Libera | Valores | Festival | Atenção do Mundo |
| --- | --- | --- | --- | --- |
| Enraizados | Ofícios avançados, doma de criaturas, rituais | Destruir relíquias agrada; usar tecnologia antiga incomoda | Festa da Colheita | ×0,5 |
| Remendadores | Adaptações, entreposto, melhores máquinas a combustão | Engenhosidade e troca são valorizadas | Dia da Troca | ×1,0 |
| Herdeiros | Redescoberta mais barata, automação, veículos antigos | Preservar e estudar relíquias agrada; destruí-las revolta | Vigília do Arquivo | ×1,5 |

A cultura também define o bônus de XP cultural, os meios de transporte e energia típicos e o mito de origem que a comunidade passa a contar.

### Enraizados não são negacionistas

Todos os Enraizados dominam os ofícios e usam energia a combustão (madeira, carvão, óleo). O que muda é a relação com a tecnologia antiga, que varia de pessoa para pessoa:

- **Devotos:** acreditam que as relíquias são amaldiçoadas e as destroem.
- **Temerosos:** não negam o passado, apenas têm medo do que ele fez. Podem aceitar relíquias com tempo e cuidado.
- **Curiosos escondidos:** querem estudar o passado, mas guardam segredo.

### Mudança cultural

A tendência continua sendo contada depois da Assembleia.

- Se outro caminho passar a cultura atual por 25 pontos percentuais durante 20 dias, acontece uma **crise de identidade**.
- O jogador pode reafirmar a cultura (com perda de humor para quem discorda) ou convocar uma **nova Assembleia**.
- Só é possível uma mudança de cultura por porte da comunidade.

## Colonos

Cada colono é uma pessoa única, com corpo, habilidades, história, personalidade, pertences e rotina. O RimWorld é a base, mas com mais camadas: atributos físicos, afinidades e aversões, fobias, mais habilidades e especialistas mais valiosos, porque ser bom em quase tudo é raro.

### Ficha do colono

- **Identidade:** nome, idade, cultura de origem, visão sobre o Mundo.
- **História:** infância e vida adulta.
- **Atributos físicos:** Força, Vigor, Destreza, Percepção.
- **Habilidades:** 16 habilidades, cada uma com nível e afinidade.
- **Traços:** de 1 a 3.
- **Incapacidades e fobias:** o que a pessoa não faz ou teme.
- **Estado:** saúde, necessidades e humor.
- **Pertences:** equipamento e inventário.
- **Rotina:** agenda e prioridades de trabalho.
- **Relações:** família, amizades, rivalidades e romances.

### Necessidades

Fome, sono, conforto, temperatura, segurança, convívio social, lazer e propósito. Necessidades não atendidas reduzem o humor.

### Atributos físicos

Vão de 1 a 10, com média 5. São sorteados numa curva normal (média 5, desvio 1,5) e alterados por idade, história e traços.

| Atributo | Afeta |
| --- | --- |
| **Força** | Capacidade de carga, dano corpo a corpo, velocidade de construção e mineração |
| **Vigor** | Resistência a doenças, fadiga, frio e calor; velocidade de recuperação |
| **Destreza** | Trabalhos manuais finos, medicina, mecânica, pontaria |
| **Percepção** | Detecção de ameaças, pontaria, pesquisa, qualidade dos avisos no rádio |

Cada ponto acima ou abaixo de 5 muda o efeito em 6% (Força 8 = +18% de dano corpo a corpo).

### Habilidades

| Habilidade | Usada para | Atributo ligado |
| --- | --- | --- |
| Construção | Erguer, consertar e desmontar estruturas | Força |
| Mineração | Escavar rocha e trabalhar nas minas | Força |
| Cultivo | Plantar, colher, cuidar do solo | Vigor |
| Animais | Domar, criar, treinar animais e criaturas | Percepção |
| Cozinha | Preparar refeições, conservar comida | Destreza |
| Artesanato | Roupas, móveis, ferramentas simples, couro | Destreza |
| Metalurgia | Fornalha, fundição, ferraria, ligas | Força |
| Mecânica | Máquinas a combustão, máquinas antigas, veículos | Destreza |
| Medicina | Tratar feridas e doenças, cirurgias | Destreza |
| Corpo a corpo | Combate com armas brancas e mãos | Força |
| Pontaria | Arcos, armas de fogo, armas antigas | Percepção |
| Social | Diplomacia, liderança, recrutamento, ensino | — |
| Comércio | Preços, negociação com caravanas | — |
| Pesquisa | Estudar artefatos, redescoberta | Percepção |
| Exploração | Navegação, sobrevivência, furtividade, batedor | Vigor |
| Comunicação | Operar o rádio, decifrar sinais, interceptação | Percepção |

**Níveis (0 a 20):**

| Faixa | Título | Velocidade e qualidade |
| --- | --- | --- |
| 0 a 3 | Iniciante | 40% a 70% |
| 4 a 7 | Competente | 70% a 100% |
| 8 a 11 | Habilidoso | 100% a 125% |
| 12 a 15 | Especialista | 125% a 150% |
| 16 a 19 | Mestre | 150% a 175% |
| 20 | Lenda | 180% |

### Afinidade com cada habilidade

Cada habilidade tem uma afinidade, que muda o ganho de XP e o humor ao trabalhar nela:

| Afinidade | XP | Humor ao trabalhar |
| --- | --- | --- |
| Aversão | ×0,2 | −2 por hora |
| Nenhuma | ×0,35 | 0 |
| Interesse | ×1,0 | +1 por hora (até +6 por dia) |
| Paixão | ×1,5 | +2 por hora (até +10 por dia) |

A aversão não existe no RimWorld: um colono pode ser bom em algo que odeia fazer, o que cria escolhas difíceis.

### Ganho de XP

**XP ganho = XP base × afinidade × idade × traços × humor × ensino × cultura**

- **XP base:** 150 XP por hora de trabalho na atividade.
- **XP para subir do nível n:** 1.000 + 75 × n². Do 0 para o 1 são cerca de 7 horas de trabalho com interesse; do 10 para o 11, cerca de 57 horas.
- **Idade:** até 17 anos ×1,3; de 18 a 59 ×1,0; 60 ou mais ×0,7.
- **Humor:** contente ou melhor ×1,1; instável ou pior ×0,8.
- **Ensino:** trabalhando ao lado de alguém pelo menos 4 níveis acima ×1,25.
- **Cultura:** Enraizados ×1,1 em Artesanato, Cultivo e Animais; Remendadores ×1,1 em Mecânica e Comércio; Herdeiros ×1,1 em Pesquisa e Comunicação.
- **Limite diário:** acima de 4.000 XP no mesmo dia, numa habilidade, o ganho cai para ×0,2.
- **Esquecimento:** acima do nível 12, sem praticar, perde 40 XP por dia (80 acima do 16).

### Incapacidades e fobias

**Incapacidades** vêm da história ou de traços. O colono simplesmente não faz aquele tipo de trabalho:

- Trabalho pesado (Construção, Mineração)
- Violência (Corpo a corpo, Pontaria, caça)
- Trabalho social (Social, Comércio)
- Cuidados (Medicina, Animais)
- Trabalho intelectual (Pesquisa, Comunicação, Mecânica)
- Trabalho manual fino (Artesanato, Cozinha, Metalurgia)

**Fobias** não impedem o trabalho, mas geram medo, pânico e perda de humor perto da causa:

| Fobia | Efeito |
| --- | --- |
| Máquinas antigas | Humor −8 perto de máquinas ligadas; 10% de chance de pânico ao operar |
| Escuro | Humor −6 em áreas sem luz; não trabalha à noite sem iluminação |
| Água funda | Não embarca sem sedativo ou companhia de confiança |
| Criaturas | Pânico em combate contra criaturas; Animais −50% com criaturas |
| Multidões | Humor −1 por pessoa acima de 6 no mesmo cômodo |
| Subterrâneo | Recusa a mina; humor −10 em cavernas |

### Histórias

Cada colono tem uma **infância** e uma **vida adulta**. Elas dão bônus de habilidade, podem trazer incapacidades e traços, e contam um pedaço do mundo. Algumas são mais comuns em certas culturas.

**Infâncias (exemplos):**

| Infância | Bônus | Observações |
| --- | --- | --- |
| Criado em caravana | Comércio +3, Exploração +2 | Comum entre Remendadores |
| Filho de ferreiro | Metalurgia +3, Força +1 | — |
| Órfão das ruínas | Exploração +3, Corpo a corpo +1 | Chance do traço Desconfiado |
| Aprendiz de curandeira | Medicina +3, Cultivo +1 | Comum entre Enraizados |
| Criado no templo do Mundo | Pesquisa +2, Social +2 | Começa venerando o Mundo |
| Pastor da tundra | Animais +3, Vigor +1 | — |
| Criança-soldado de clã | Corpo a corpo +3, Pontaria +2 | Chance do traço Trauma |
| Catador de sucata | Mecânica +2, Mineração +1 | Comum entre Remendadores |
| Filho de pescadores | Cozinha +2, Exploração +2 | — |
| Guardado no arquivo | Pesquisa +3, Comunicação +2 | Herdeiros; incapaz de trabalho pesado |

**Vidas adultas (exemplos):**

| Vida adulta | Bônus | Observações |
| --- | --- | --- |
| Mineiro de veio | Mineração +5, Construção +2 | Chance da fobia de escuro |
| Ferreiro | Metalurgia +6, Artesanato +2 | — |
| Construtor de muralhas | Construção +6, Força +1 | — |
| Agricultor de terraço | Cultivo +6, Cozinha +2 | — |
| Cozinheiro de assentamento | Cozinha +6, Cultivo +2 | — |
| Domador de criaturas | Animais +6, Corpo a corpo +2 | Enraizados |
| Caçador | Pontaria +5, Exploração +2, Animais +1 | — |
| Batedor de caravana | Exploração +5, Pontaria +3 | — |
| Curandeiro itinerante | Medicina +6, Social +2 | Incapaz de violência |
| Mercador | Comércio +6, Social +3 | Incapaz de trabalho pesado |
| Operador de rádio | Comunicação +6, Mecânica +2 | — |
| Mecânico remendador | Mecânica +6, Metalurgia +2 | Remendadores |
| Escavador de relíquias | Pesquisa +4, Exploração +3, Mecânica +2 | Chance da fobia de subterrâneo |
| Guardião de arquivos | Pesquisa +6, Comunicação +2 | Herdeiros; incapaz de violência |
| Saqueador | Pontaria +4, Corpo a corpo +3 | Incapaz de trabalho social; má fama com clãs |
| Sacerdote do Mundo | Social +5, Medicina +2 | Venera o Mundo; incapaz de pesquisa |

### Geração e raridade

1. **Idade:** de 16 a 70 anos, a maioria entre 20 e 45.
2. **Cultura de origem** e **histórias**, com pesos por cultura.
3. **Atributos físicos.**
4. **Habilidades:** todas começam entre 0 e 3; somam-se os bônus das histórias; adultos ganham +1 a cada 10 anos nas habilidades da vida adulta.
5. **Afinidades:** de 1 a 3 interesses ou paixões, de 0 a 2 aversões.
6. **Traços:** de 1 a 3.
7. **Teto:** a soma de todos os níveis não passa de 70. Se passar, as habilidades menores são reduzidas.

Com essas regras, a chance aproximada de cada perfil ao gerar um colono é:

| Perfil | Definição | Chance |
| --- | --- | --- |
| Sem especialidade | Nenhuma habilidade 8 ou mais | \~5% |
| Especialista | Uma habilidade 8 ou mais | \~60% |
| Duas especialidades | Duas habilidades 8 ou mais | \~25% |
| Polivalente | Três habilidades 8 ou mais | \~8% |
| Raríssimo | Quatro ou mais habilidades 8 ou mais | \~1,5% |
| Mestre de nascença | Alguma habilidade 16 ou mais (sobreposto aos outros) | \~2% |

### Traços

Cada colono tem de 1 a 3 traços. Alguns formam **espectros**: só um traço de cada espectro por pessoa. A raridade define a chance de aparecer: comum (peso 10), incomum (peso 4), raro (peso 1).

**Relação com o passado** (espectro, exclusivo deste jogo):

| Traço | Efeito | Raridade |
| --- | --- | --- |
| Devoto do Mundo | Humor +5 com rituais; −10 ao ver relíquias em uso; pode destruir relíquias em crise | Incomum |
| Temeroso | Humor −5 perto de máquinas antigas ligadas; pontos de Vestígio −25% | Comum |
| Curioso | Pontos de conhecimento +25% em tudo o que faz; pode mexer em artefatos sem ordem | Comum |
| Obcecado pelo passado | Pontos de Vestígio +50%; às vezes ignora sono e fome para estudar | Raro |

**Trabalho e aprendizado** (espectros):

| Traço | Efeito | Raridade |
| --- | --- | --- |
| Preguiçoso | Velocidade de trabalho −20% | Comum |
| Esforçado | Velocidade de trabalho +15% | Comum |
| Incansável | Velocidade de trabalho +25%; precisa de menos lazer | Raro |
| Lento para aprender | XP ×0,75 | Comum |
| Aprende rápido | XP ×1,5 | Incomum |
| Gênio | XP ×1,5; pontos de conhecimento +20%; humor −5 com trabalho repetitivo | Raro |
| Dom | XP ×2 numa única habilidade, sorteada | Raro |

**Personalidade:**

| Traço | Efeito | Raridade |
| --- | --- | --- |
| Otimista | Humor base +6 | Comum |
| Pessimista | Humor base −6 | Comum |
| Esquentado | Chance de briga ×2 | Comum |
| Calmo | Chance de briga ×0,3; crises mais raras | Incomum |
| Ganancioso | Comércio +2; quer quarto melhor; pode roubar | Comum |
| Generoso | Humor +3 ao doar; Comércio −2 | Incomum |
| Rancoroso | Guarda mágoa por mais tempo e pode se vingar | Comum |
| Leal | Não deserta; humor +5 quando a colônia vai bem | Incomum |
| Solitário | Humor +4 sozinho; −4 em grupos grandes | Comum |
| Carismático | Social +3; libera opções de diálogo em eventos | Incomum |
| Covarde | Pode fugir em combate; detecta perigo antes | Comum |
| Corajoso | Não entra em pânico; aceita riscos maiores | Incomum |
| Supersticioso | Humor afetado por presságios e rituais | Comum |
| Protetor | Combate +20% quando um amigo está em perigo | Incomum |
| Nômade | Humor +5 em expedições; −5 após 20 dias sem sair | Comum |
| Ciumento | Fica mal quando outro tem coisa melhor | Comum |
| Desconfiado | Relações demoram a crescer; difícil de enganar | Comum |

**Corpo e mente:**

| Traço | Efeito | Raridade |
| --- | --- | --- |
| Forte | Força +2 | Incomum |
| Frágil | Vigor −2; recebe mais dano | Comum |
| Resistente | Vigor +2; sente menos frio e calor | Incomum |
| Ágil | Movimento +15% | Incomum |
| Olhos de águia | Percepção +2 | Incomum |
| Míope | Percepção −2 | Comum |
| Notívago | Prefere a noite; sem penalidade de escuro | Incomum |
| Sono leve | Acorda com barulho; sente menos sono em vigia | Comum |
| Glutão | Come 30% a mais | Comum |
| Trauma do passado | Pode travar em combate; humor −10 por dias após violência | Incomum |
| Mente firme | Limiar de crise −10 | Raro |
| Instável | Limiar de crise +10 | Comum |

### Humor

O humor vai de 0 a 100. Ele tende ao **humor-alvo** = 50 + soma dos pensamentos − expectativa, e se move cerca de 12 pontos por dia em direção ao alvo.

| Faixa | Estado | Efeito |
| --- | --- | --- |
| 0 a 9 | Crise extrema | Chance de abandonar a colônia, violência |
| 10 a 24 | Crise | Chance de crise maior |
| 25 a 34 | Instável | Chance de crise menor; XP ×0,8 |
| 35 a 64 | Neutro | — |
| 65 a 84 | Contente | XP ×1,1 |
| 85 a 100 | Inspirado | Chance de inspiração |

- **Pensamentos:** necessidades, ambiente (quarto, beleza, temperatura), relações, eventos, valores da cultura, crença sobre o Mundo, roupas e trabalho (afinidade ou aversão).
- **Expectativa:** cresce com o porte da comunidade. Quanto maior o lugar, mais as pessoas esperam: assentamento 0, acampamento 5, vila 10, povoado 15.
- **Crises menores:** comer compulsivamente, isolar-se, recusar trabalho por um dia.
- **Crises maiores:** brigas, sabotagem, destruir relíquias (Devoto), mexer em artefatos proibidos (Obcecado), tentar fugir.
- **Inspirações:** um dia de XP ×2, trabalho com qualidade garantida acima do normal, ou ideia de pesquisa.
- **Pensamentos do MVP:** fome, sono, Otimista e Pessimista, dormir no chão (por 12 h), dor (−1 a cada 10 de dano), a morte de alguém da comunidade (−8 por 3 dias) e o sentimento pelo trabalho: interesse +1 por hora (até +6), paixão +2 (até +10), aversão −2 (até −10), que some devagar sem trabalhar na habilidade.

### Agenda

Cada colono tem uma agenda por hora, editável como no RimWorld, com blocos de **Dormir**, **Trabalhar**, **Lazer**, **Livre**, **Estudo** (aprender com um mestre) e **Ritual**.

- **Agenda padrão:** Dormir das 22 h às 6 h, Livre das 20 h às 22 h e Trabalhar no resto. A partida começa às 6 h do dia 1.
- No bloco Dormir, o colono vai dormir se o sono estiver abaixo de 90%. Quando o bloco Trabalhar acaba, ele larga a tarefa (o Esforçado termina a que está fazendo).

O **calendário** da colônia mostra o ano de 60 dias e, para cada colono:

- Aniversários, turnos de vigia, expedições e dias de folga.
- Mudanças de estação, caravanas esperadas e avisos de ataque.
- Festivais por cultura: Festa da Colheita (Enraizados), Dia da Troca (Remendadores), Vigília do Arquivo (Herdeiros).

### Prioridades de trabalho

Uma grade como a do RimWorld: uma linha por colono, uma coluna por tipo de trabalho, prioridade de 1 (mais alta) a 4, ou desligado. Com prioridades iguais, vale a ordem das colunas.

Tipos de trabalho: Emergência, Medicina, Repouso, Cuidar, Vigia, Rádio, Animais, Cozinhar, Caçar, Construir, Cultivar, Minerar, Cortar plantas, Metalurgia, Artesanato, Mecânica, Carregar, Limpar, Pesquisar, Ensinar.

**No MVP:** Emergência (socorrer e tratar caídos, sem habilidade, prioridade 1 por padrão), Cozinhar, Caçar, Construir, Cultivar, Minerar, Cortar plantas, Artesanato, Carregar e Pesquisar.

- A alocação em minas é feita à parte: o colono alocado trabalha lá nas horas de trabalho.
- A partir da vila, chefes de equipe podem ajustar as prioridades da sua área sozinhos.

### Inventário e carga

Cada colono carrega itens por **peso (kg)**.

- **Capacidade de carga** = 15 kg + 5 kg × Força (Força 5 = 40 kg), mais o bônus da mochila.
- **Até 100%:** sem penalidade. **100% a 125%:** movimento −20%. **125% a 150%:** movimento −50%. **Acima de 150%:** não consegue andar.
- Itens volumosos (mais de 10 kg por unidade) só são carregados nas mãos, com a mão livre, ou em carroça.

**Faixas de peso para os itens:**

| Faixa | Peso por unidade | Exemplos |
| --- | --- | --- |
| Leve | Menos de 0,5 kg | Flechas, munição, ervas, tecido, refeição |
| Médio | 0,5 a 3 kg | Ferramentas, armas leves, barras de metal, artefatos pequenos |
| Pesado | 3 a 10 kg | Armaduras, armas de fogo, peças grandes |
| Volumoso | Mais de 10 kg | Móveis, máquinas, grandes artefatos |

**Pesos de referência:**

| Item | Peso |
| --- | --- |
| Madeira (unidade) | 0,5 kg |
| Pedra em bloco | 1,0 kg |
| Minério (cobre, ferro) | 1,0 kg |
| Barra de metal | 0,5 kg |
| Sucata | 0,8 kg |
| Carvão | 0,4 kg |
| Comida crua (porção) | 0,5 kg |
| Refeição pronta | 0,4 kg |
| Ração de viagem | 0,25 kg |
| Remédio de ervas | 0,1 kg |
| Tecido | 0,1 kg |
| Couro | 0,2 kg |
| Faca | 0,5 kg |
| Lança | 2,0 kg |
| Machado ou picareta | 2,5 kg |
| Arco | 1,0 kg |
| Flecha | 0,05 kg |
| Arma de fogo improvisada | 3,5 kg |
| Munição | 0,02 kg |
| Rádio portátil | 2,0 kg |
| Peça antiga | 0,5 kg |
| Artefato pequeno | 0,5 a 3 kg |

### Equipamento

Cada colono tem 8 espaços:

| Espaço | Exemplos | Efeito principal |
| --- | --- | --- |
| Chapéu | Chapéu de palha, gorro, capacete | Proteção da cabeça, frio e sol |
| Camisa | Túnica, camisa de linho, gibão, casaco de couro, casaco de pele | Isolamento térmico, aparência. O casaco ocupa este espaço |
| Armadura | Armadura de couro, de placas, armadura antiga | Proteção contra dano; reduz movimento conforme o peso |
| Calça | Calça de pano, de couro | Isolamento térmico |
| Sapatos | Sandálias, botas | Movimento em lama, neve e entulho |
| Mochila | Bolsa (+10 kg), mochila de couro (+20 kg), mochila antiga com armação (+35 kg) | Capacidade de carga |
| Cinto | Cinto simples (2 espaços), cinto de ferramentas (4 espaços) | Itens de uso rápido: remédio, munição, rádio |
| Mão | Ferramenta ou arma | Bônus de trabalho ou combate |

- **Ferramentas na mão** dão bônus: picareta Mineração ×1,25; martelo Construção ×1,15; faca de esfolar Caça e Cozinha ×1,1; machado Cortar plantas ×1,25. Ferramentas antigas valem mais.
- **Troca de ferramenta:** antes de um trabalho, o colono busca por perto (num contêiner ou no chão) a ferramenta melhor para ele e deixa no lugar a que tinha. Para caçar, vale a melhor arma (lança ou arco).
- **Trocar o item da mão** leva 1 segundo, se o outro estiver no cinto, ou 3 segundos, se estiver na mochila.
- **Qualidade:** ruim, normal, boa, excelente, obra-prima. Depende da habilidade de quem fez.
- **Desgaste:** roupas e ferramentas se desgastam com o uso. Roupa rasgada ou tirada de um morto reduz o humor.
- **Roupa adequada:** cada peça tem faixa de temperatura confortável. A soma das peças define o quanto o colono aguenta frio e calor.

### Relações

- Amizade, rivalidade, romance e família.
- Relações afetam humor, eficiência em trabalho conjunto e decisões em crises.
- Mestres e aprendizes formam um vínculo próprio, que acelera o ensino.

### Influência na comunidade

Colonos com traços fortes podem puxar a cultura para um lado. Um líder carismático e devoto do Mundo pode convencer o grupo a rejeitar uma tecnologia que o jogador queria usar.

## IA dos colonos

Cada colono decide sozinho o que fazer, mas todos trabalham juntos através de um **quadro de tarefas** compartilhado e de **reservas**. O jogador influencia com prioridades, agenda, ordens e pedidos, nunca controlando cada passo.

Três regras guiam tudo:

1. **Previsível:** o jogador consegue entender por que um colono fez algo.
2. **Coletiva:** dois colonos nunca fazem a mesma coisa ao mesmo tempo, e o trabalho se divide sozinho.
3. **Pessoal:** traços e humor mudam as escolhas, para cada colono parecer uma pessoa.

### Camadas de decisão

&#91;embedded content: camadas de decisão de cada colono\]

| Camada | Quando age | Exemplos |
| --- | --- | --- |
| 1. Reações | Sempre; interrompe tudo | Fugir de inimigo, apagar fogo próximo, pânico de fobia, cair ferido |
| 2. Necessidades críticas | Quando uma necessidade fica crítica | Comer com fome abaixo de 15%, dormir com sono abaixo de 8%, tratar sangramento |
| 3. Ordens diretas | Quando o jogador dá uma ordem | Colono convocado para combate, "priorizar esta tarefa" |
| 4. Agenda | Conforme o bloco da hora | Dormir, Lazer, Estudo, Ritual |
| 5. Trabalho | No bloco Trabalho ou Livre | Pega uma tarefa do quadro |
| 6. Tempo livre | Quando não há tarefa | Comer com fome abaixo de 30%, organizar pilhas, conversar, descansar |

**No MVP:** as reações são cair ferido (vence tudo, até outra reação), desmaiar de exaustão e fugir de saqueadores; as necessidades críticas incluem estancar o próprio sangramento e repousar ferido. O colono convocado pula as necessidades críticas e só segue as ordens.

### Ciclo de cada colono

O colono passa por estados: **Livre → Escolhendo → Indo → Executando → Concluindo → Livre**.

- **Pensamento escalonado:** cada colono reavalia a cada 30 ticks (meio segundo de jogo), em horários diferentes dos outros, para não pesar no processamento.
- **Interrupção:** uma camada mais alta pode interromper a tarefa atual. O progresso fica salvo na tarefa, e quem voltar continua de onde parou.
- **Bloqueio:** se o caminho fica bloqueado ou um material some, o colono solta a tarefa, marca o motivo e escolhe outra.

```gdscript
func pensar() -> void:
    var acao: Acao = escolher_acao()
    if acao != acao_atual:
        trocar_para(acao)

func escolher_acao() -> Acao:
    if tem_reacao_urgente(): return reacao_urgente()
    if tem_necessidade_critica(): return atender_necessidade()
    if ordem_direta: return ordem_direta
    var bloco := agenda.bloco_atual()
    if bloco in [Bloco.DORMIR, Bloco.LAZER, Bloco.ESTUDO, Bloco.RITUAL]:
        return atividade_do(bloco)
    var tarefa := quadro.melhor_tarefa_para(self)
    if tarefa and tarefa.reservar(self):
        return tarefa
    return tempo_livre()
```

### Quadro de tarefas

O quadro de tarefas é uma lista central de tudo o que precisa ser feito. O mundo cria tarefas sozinho:

- **Designações do jogador:** cortar, minerar, colher, construir, desmontar.
- **Pedidos de bancada:** cada item na fila de uma bancada vira tarefa.
- **Transporte:** pilhas soltas, abastecer bancadas, levar materiais para construções.
- **Cuidados:** alimentar e tratar pacientes, cuidar de animais.
- **Postos:** vigia, rádio, mina.

Cada tarefa guarda: tipo de trabalho, local, habilidade mínima, ferramenta útil, urgência, progresso e quem a reservou.

### Como o colono escolhe a tarefa

1. **Prioridade:** primeiro as tarefas dos tipos de trabalho com prioridade 1, depois 2, 3 e 4.
2. **Ordem das colunas:** dentro da mesma prioridade, vale a ordem dos tipos de trabalho na grade.
3. **Pontuação:** dentro do mesmo tipo, vence a maior pontuação.

**Pontuação = urgência × habilidade × afinidade × traços ÷ (1 + distância ÷ 30)**

| Fator | Valores |
| --- | --- |
| Urgência | Normal 1; alta 2 (pedido marcado pelo jogador); crítica 3 (comida estragando, incêndio, paciente sem comer) |
| Habilidade | 0,5 + nível ÷ 20 |
| Afinidade | Paixão 1,3; interesse 1,1; nenhuma 1,0; aversão 0,7 |
| Traços | Ex.: Curioso ×1,3 em tarefas com artefatos; Nômade ×1,3 em tarefas longe da base |
| Distância | Custo do caminho em tiles, já considerando terreno |

Tarefas que o colono não pode fazer (incapacidade, habilidade abaixo do mínimo, local perigoso, sem acesso) nem entram na conta.

### Trabalho em conjunto

- **Reservas:** ao pegar uma tarefa, o colono reserva a tarefa, os materiais, a bancada e o tile de trabalho. Ninguém mais usa o que está reservado. Reservas expiram se o colono ficar 30 segundos de jogo sem avançar.
- **Divisão automática:** tarefas grandes, como uma parede de 20 tiles, são quebradas em partes. Cada colono pega a parte livre mais próxima.
- **Ajuda mútua:** em construções e objetos grandes, até 3 colonos podem trabalhar juntos. A velocidade total é ×1 com um, ×1,8 com dois e ×2,4 com três.
- **Cadeia de abastecimento:** quando uma bancada precisa de material, nasce uma tarefa de Carregar com a mesma prioridade do pedido. Se ninguém pegar em 10 segundos de jogo, o próprio artesão busca o material.
- **Ensino:** com Ensinar ligado, um mestre prefere tarefas perto de um aprendiz na mesma habilidade (bônus de XP ×1,25 para o aprendiz).
- **Pedido de socorro:** um colono em perigo avisa os próximos. Protetores e Corajosos vêm ajudar; Covardes se afastam; os outros decidem pela capacidade de luta.
- **Vigia:** a comunidade tenta manter pelo menos um colono acordado de vigia à noite. Sem ninguém, aparece um alerta.
- **Chefes de equipe (a partir da vila):** ajustam prioridades da sua área sozinhos. Exemplo: com menos de 5 dias de comida, sobem Cultivar e Cozinhar para a equipe.

### Necessidades e escolhas do dia a dia

| Necessidade | No tempo livre | Interrompe o trabalho |
| --- | --- | --- |
| Fome | Abaixo de 30% | Abaixo de 15% |
| Sono | Abaixo de 20% | Abaixo de 8% (desmaia em 0%) |
| Lazer | Abaixo de 30%, no bloco Lazer | Nunca |
| Convívio | Abaixo de 25%, procura alguém | Nunca |
| Temperatura | Procura roupa ou abrigo | Em hipotermia ou insolação |

- **Comida:** escolhe a melhor refeição disponível por perto, preferindo a que dá mais humor. Deixa refeições melhores para pacientes.
- **Ferramentas:** pega a melhor ferramenta para a tarefa no rack ou baú mais próximo, e devolve ao terminar.
- **Roupas:** troca roupa gasta ou inadequada para a temperatura, se houver uma melhor guardada.

### Personalidade nas decisões

| Traço | Comportamento |
| --- | --- |
| Preguiçoso | Faz pausas de 15 minutos a cada 2 horas de trabalho |
| Esforçado | Pula pausas; continua uma tarefa mesmo no fim do bloco Trabalho |
| Nômade | Prefere tarefas longe da base; às vezes vaga pelo mapa no tempo livre |
| Curioso | Pode desviar para examinar um artefato (se permitido) |
| Ganancioso | Pequena chance de guardar um item valioso no próprio inventário |
| Solitário | Evita tarefas com outros colonos por perto |
| Covarde | Evita tarefas em áreas com perigo recente |
| Esquentado | Mais chance de discussão durante trabalho em conjunto |

### Conversas e relações

- Colonos próximos no bloco Lazer ou Livre têm chance de conversar (cerca de 1 vez por hora).
- O resultado depende da compatibilidade de traços e da relação atual: aproxima, afasta ou vira briga.
- Trabalhar junto por muito tempo cria laços, para o bem ou para o mal.

### Movimento

- Caminhos com `AStarGrid2D`, com custo por tipo de terreno.
- Áreas perigosas (fogo, inimigos, ruínas instáveis) ganham custo alto, e o colono as evita.
- O mapa é dividido em regiões por chunk, para descartar rápido tarefas inalcançáveis.

### "Por que ele não está fazendo isso?"

Cada colono tem um painel que mostra o estado atual, a tarefa, as 5 melhores opções com pontuação e, para qualquer tarefa clicada, o motivo de não fazer: "prioridade desligada", "material reservado por Ana", "sem caminho", "incapaz de trabalho pesado". Isso evita a frustração com colonos "burros".

### Desempenho

- Orçamento de 2 ms por quadro para toda a IA.
- Tarefas indexadas por tipo de trabalho e por região.
- Com 30 colonos e cerca de 2.000 tarefas abertas, cada colono avalia só as tarefas dos tipos ativos dele e das regiões alcançáveis.

### Porte da comunidade

A comunidade evolui em quatro portes: **Assentamento → Acampamento → Vila → Povoado**. O povoado é o limite. Cada porte libera recursos de gestão e traz novas pressões, para a colônia não ficar grande demais para gerenciar.

| Porte | Colonos | Requisitos para subir | O que libera | Pressões |
| --- | --- | --- | --- | --- |
| Assentamento | 1 a 5 | Início | Construções básicas | Poucas mãos para tudo |
| Acampamento | 6 a 10 | 6 colonos, fogueira comunal, armazém coberto, quartos para todos | Primeiro líder, receptor de rádio, mais tipos de trabalho | Expectativa +5 |
| Vila | 11 a 20 | 11 colonos, salão comum, 2 áreas liberadas, defesas básicas, 10 dias de comida estocada | Conselho, chefes de equipe, transmissor, comércio com caravanas | Expectativa +10; grupos internos surgem |
| Povoado | 21 a 30 | 21 colonos, mercado ou entreposto, 4 áreas liberadas, muralha, enfermaria | Delegação completa, filiais, grandes caravanas | Expectativa +15; mais atenção de rivais e do Mundo |

**Como o jogador vê a evolução:**

- Um **painel de porte** mostra o porte atual e uma lista de requisitos do próximo, com cada item marcado quando cumprido.
- Ao subir, acontece um **marco**: uma cerimônia dos colonos, uma mensagem de evento e uma música curta.
- O **estandarte** da comunidade muda de aparência a cada porte.
- O nome da comunidade muda de forma ("Assentamento do Vale", depois "Vila do Vale").
- Se a população cair abaixo do mínimo do porte por 15 dias seguidos, a comunidade volta para o porte anterior.

**Contramedidas contra o crescimento excessivo:**

- **Liderança:** cada líder coordena até 8 colonos. Acima disso, eficiência e humor caem.
- **Custos crescentes:** mais comida, moradia, doenças por aglomeração e conflitos.
- **Facções internas:** a partir da vila, grupos com interesses próprios exigem negociação.
- **Atenção externa:** comunidades grandes chamam rivais e o Mundo (pontos por colono maiores, ver Balanceamento).
- **Delegação:** chefes de equipe assumem áreas e decidem sozinhos.
- **Limite do povoado:** acima de 30 colonos, as pressões ficam severas. O caminho natural é **fundar uma filial**, gerida por ordens gerais e conectada por rádio e rotas de comércio.

## Construção, produção e transporte

A construção segue o modelo do RimWorld: o jogador desenha paredes, salas e móveis, e os colonos executam. A produção cresce em camadas, inspirada no Factorio, e o transporte define até onde a colônia alcança.

### Construção

- Grade de tiles 16×16, com paredes, pisos, portas, móveis e estações de trabalho.
- Salas têm qualidade (tamanho, beleza, limpeza) que afeta o humor.
- Materiais: madeira, pedra, barro, metal fundido, sucata e ligas antigas.
- Estruturas antigas no mapa podem ser reaproveitadas como parte da base.

### Camadas de produção

| Camada | Exemplo de cadeia | Quem executa |
| --- | --- | --- |
| 1. Manual | Madeira → bancada → ferramentas | Colonos |
| 2. Ofício | Minério → fornalha → metal → ferraria | Colonos com máquinas a combustão |
| 3. Automatizada | Sucata → triturador → esteira → montadora | Máquinas antigas restauradas |

- **Enraizados** dominam as camadas 1 e 2, com bônus de qualidade artesanal.
- **Remendadores** dominam a camada 2 e chegam à 3 com máquinas improvisadas que quebram.
- **Herdeiros** chegam à camada 3, mas precisam de energia estável e peças raras.

### Energia

- **Combustão (todas as culturas):** madeira, carvão vegetal, carvão mineral, óleo e o que mais houver. Move fornalhas, caldeiras e motores simples.
- **Força natural:** moinhos de vento e rodas d'água.
- **Energia antiga:** geradores e células de energia restauradas. Muito mais potentes, mas aumentam a atenção da IA.

### Transporte

Transporte terrestre e marítimo evolui com a tecnologia. Voar ainda não foi descoberto: o transporte aéreo só aparece no fim da progressão.

| Nível | Terrestre | Marítimo |
| --- | --- | --- |
| 1. Tração | A pé, animais de carga, carroças | Jangadas, barcos a remo e a vela |
| 2. Combustão | Carroças motorizadas, veículos improvisados, mistura de animais com motor | Barcos a vapor e a motor |
| 3. Antigo | Veículos antigos restaurados, trilhos e vagões antigos | Embarcações antigas restauradas |
| 4. Céu (fim de jogo) | Primeiros voos, redescobertos perto do fim | — |

- Enraizados usam o nível 1 e criaturas domadas como montaria.
- Remendadores misturam animais e máquinas, como carroças puxadas por animais com motor de apoio.
- Herdeiros chegam ao nível 3, com alto custo de manutenção.

**Lore do céu:** ninguém sabe mais voar. O conhecimento se perdeu, e muitos acreditam que o céu pertence ao Mundo. Redescobrir o voo é um marco de fim de jogo, e cada voo chama muita atenção do Mundo.

## Bancadas, itens e construções

### Princípios

O objetivo é ir além do RimWorld com menos bancadas, mas mais profundas:

- **Poucas bancadas fortes:** a cozinha faz tudo o que envolve comida, incluindo abater animais. A bancada de produção faz o básico de quase tudo.
- **Níveis em vez de bancadas novas:** a mesma bancada evolui de rústica para reforçada e depois oficina.
- **Anexos:** objetos colocados a até 2 tiles da bancada que adicionam receitas ou bônus. A oficina vai sendo montada aos poucos.
- **Ambiente importa:** luz, limpeza, temperatura e uma sala própria afetam velocidade e qualidade.
- **Pedidos inteligentes:** fila com condições, como "fazer até ter 20", "só se houver carne sobrando", "pausar à noite" ou "prioridade alta".
- **Ninguém fica preso:** qualquer colono com a prioridade certa pega o próximo pedido.
- **Bancada de campanha:** versão portátil para expedições.

### Níveis de bancada

| Nível | Velocidade | Qualidade máxima | Receitas |
| --- | --- | --- | --- |
| Rústica | ×0,8 | Boa | Básicas |
| Reforçada | ×1,0 | Excelente | Intermediárias |
| Oficina | ×1,2 | Obra-prima | Avançadas |

Subir de nível custa materiais e exige a pesquisa correspondente.

### Ambiente de trabalho

- **Luz:** sem luz, trabalho ×0,8.
- **Limpeza:** sala suja reduz a velocidade em até 15%. Na cozinha, a chance de intoxicação alimentar cai de 5% (suja) para 0,5% (limpa).
- **Temperatura:** fora da faixa de 10 a 30 °C, trabalho ×0,85.
- **Sala própria:** bancada numa sala dedicada ganha +5% de chance de subir a qualidade.

### Bancadas

| Bancada | Tamanho | Custo | Habilidade | O que faz | Anexos |
| --- | --- | --- | --- | --- | --- |
| Fogueira | 1×1 | 5 madeira | Cozinha | Refeições simples, assar carne; dá luz e calor | — |
| **Bancada de cozinha** | 3×1 | 15 madeira, 5 blocos de pedra | Cozinha | Abater e limpar animais (carne, pele, ossos, gordura), refeições, conservas, rações de viagem | Fogão a lenha (+25% velocidade), Defumadouro (conservas que duram 60 dias), Barril de água (intoxicação −50%), Moinho manual (farinha e pão) |
| **Bancada de produção** | 3×1 | 20 madeira, 10 blocos de pedra | Artesanato ou Construção | Ferramentas simples, armas primitivas, móveis, cordas, cestos, blocos de pedra, tochas, flechas, consertos simples | Torno de bancada (+qualidade), Painel de ferramentas (+15% velocidade), Serra de pedra (blocos 2× mais rápido), Mesa de montagem (móveis grandes, carroças) |
| Bancada de costura | 3×1 | 15 madeira, 5 fibra | Artesanato | Tecido, roupas, casacos, mochilas, cintos, armaduras de couro e tecido | Tina de curtume (pele em couro), Roca (fio 1,5× mais rápido), Manequim (+qualidade em armaduras) |
| Fornalha | 2×2 | 30 pedra, 10 barro | Metalurgia | Fundir minério em barras, vidro, tijolos | Fole (+30% velocidade), Chaminé (sem fumaça na sala), Moldes (barras em lote) |
| Forno de carvão | 2×2 | 20 barro | — | Transforma madeira em carvão sozinho, em 1 dia | — |
| Forja | 2×1 | 20 pedra, 15 barras de cobre | Metalurgia | Ferramentas, armas e armaduras de metal, peças de metal | Bigorna (obrigatória), Tina de têmpera (+qualidade), Esmeril (consertos 2× mais rápidos) |
| Botica | 2×1 | 10 madeira, 4 barro | Medicina | Remédios de ervas, chás, pomadas, ataduras | Destilador (álcool medicinal), Varal de secagem (ervas duram mais) |
| Barril de fermentação | 1×1 | 8 madeira | — | Cerveja, vinho e vinagre sozinho, em 6 dias | — |
| Bancada de remendo | 3×1 | 15 madeira, 10 sucata | Mecânica | Desmontar sucata em peças, consertar qualquer item, adaptações com sucata e relíquias | Caixa de peças (+chance de peça boa) |
| Bancada mecânica | 3×2 | 20 barras de ferro, 6 peças simples | Mecânica | Motores a combustão, bombas, carroças motorizadas, veículos, manutenção de máquinas | Guincho (veículos), Banco de testes (falhas −30%) |
| Bancada de rádio | 2×1 | 10 madeira, 4 peças simples, 2 barras de cobre | Comunicação | Rádios, antenas, consertos, decifrar gravações antigas | Antena de bancada (+alcance) |
| Mesa de cartografia | 2×1 | 15 madeira, 5 tecido | Exploração | Desenhar, copiar e corrigir mapas | — |
| Mesa de análise | 2×1 | 15 madeira, 5 vidro | Pesquisa | Analisar artefatos rapidamente, gerando pontos de Vestígio | Lupa (+20% pontos), Bandeja de desmontagem (desmonta artefatos em peças) |
| Mesa de estudos | 2×2 | 20 madeira, 5 couro | — | Onde a pesquisa é liberada (ver Conhecimento e pesquisa) | Evolui para Arquivo e Laboratório antigo |
| Santuário | 2×2 | Varia por cultura | Social | Rituais, festivais | — |
| Fogueira comunal | 3×3 | 10 pedra, 5 madeira | — | Reuniões e a Assembleia; requisito do acampamento | — |
| Laboratório antigo | 4×3 | 20 barras de ferro, 10 peças antigas, energia antiga | Pesquisa e Mecânica | Reproduzir artefatos antigos | — |
| Bancada de campanha | 1×1 | 6 madeira, 2 couro (8 kg) | Cozinha ou Artesanato | Cozinhar e consertar em expedições | — |

- **Bancada de produção rústica:** custa 20 madeira e 10 pedra bruta (e não blocos de pedra), porque os blocos só saem dela. A ordem do começo fica: minerar, bancada de produção, blocos, bancada de cozinha.
- **Painel da bancada:** cada pedido da fila tem modo (fazer N, fazer até ter X, sempre), meta, pausa, subir na fila e apagar. O primeiro pedido possível da fila é feito; o que já tem ingredientes separados termina antes. Apagar o pedido devolve os ingredientes ao chão.
- **Mesa de estudos no MVP:** custa 20 madeira e 5 fibra (couro fica fora do MVP, e a pele só sai da cozinha, que depende de pesquisa feita nesta mesa). 2×2, 3 h. Não é operada por ninguém: só precisa existir para liberar pesquisas.
- **Mesa de análise no MVP:** custa 15 madeira e 5 sucata (vidro fica fora do MVP; a sucata vem da ruína). Analisar um artefato leva 3 h (Pesquisar), rende 10 V e o transforma em artefato estudado, que não é analisado de novo.

### Qualidade

| Habilidade | Ruim | Normal | Boa | Excelente | Obra-prima |
| --- | --- | --- | --- | --- | --- |
| 0 a 3 | 50% | 45% | 5% | — | — |
| 4 a 7 | 15% | 60% | 22% | 3% | — |
| 8 a 11 | 5% | 40% | 40% | 14% | 1% |
| 12 a 15 | — | 20% | 45% | 30% | 5% |
| 16 a 20 | — | 5% | 35% | 45% | 15% |

A qualidade máxima é limitada pelo nível da bancada. Uma inspiração sobe o resultado em um nível.

### Valor dos itens

**Valor = (soma dos materiais + horas de trabalho × 4) × multiplicador de qualidade**

Multiplicadores de qualidade: ruim 0,6; normal 1,0; boa 1,25; excelente 1,6; obra-prima 2,5. Essa regra mantém o valor coerente entre o que se compra, vende e fabrica.

| Recurso | Valor por unidade |
| --- | --- |
| Pedra bruta | 0,4 |
| Barro | 0,5 |
| Fibra | 0,5 |
| Madeira | 1 |
| Vegetal | 1 |
| Bloco de pedra | 1,5 |
| Carne crua | 1,5 |
| Pele | 1,5 |
| Carvão | 1,5 |
| Minério de cobre | 2 |
| Ervas | 2 |
| Sucata | 2 |
| Minério de ferro | 2,5 |
| Tecido | 2,5 |
| Couro | 3 |
| Vidro | 4 |
| Barra de cobre | 6 |
| Barra de ferro | 8 |
| Peça simples | 10 |
| Peça antiga | 40 |

### Receitas iniciais

| Item | Bancada | Materiais | Tempo | Peso | Valor (normal) |
| --- | --- | --- | --- | --- | --- |
| Refeição simples | Fogueira ou cozinha | 2 porções cruas | 0,5 h | 0,4 kg | 5 |
| Refeição completa | Cozinha | 1 carne, 1 vegetal, 1 erva | 1 h | 0,4 kg | 9 (humor +3) |
| Rações de viagem ×3 | Cozinha + defumadouro | 3 carne, 2 vegetal | 2 h | 0,25 kg cada | 5 cada |
| Abater animal pequeno | Cozinha | 1 animal | 0,5 h | — | Rende 6 carne, 1 pele |
| Abater animal grande | Cozinha | 1 animal | 2 h | — | Rende 30 carne, 4 pele, 2 gordura |
| Faca de pedra | Produção | 1 pedra, 1 madeira | 0,5 h | 0,5 kg | 5 |
| Machado de pedra | Produção | 2 pedra, 2 madeira | 1 h | 2,5 kg | 9 |
| Lança de madeira | Produção | 3 madeira | 1 h | 2,0 kg | 7 |
| Arco | Produção | 3 madeira, 2 fibra | 2 h | 1,0 kg | 13 |
| Flechas ×10 | Produção | 2 madeira, 1 pedra | 1 h | 0,05 kg cada | 0,75 cada |
| Blocos de pedra ×4 | Produção | 4 pedra bruta | 1 h | 1,0 kg cada | 1,5 cada |
| Cama rústica | Produção | 12 madeira | 3 h | 15 kg | 24 |
| Mesa simples | Produção | 10 madeira | 2,5 h | 12 kg | 20 |
| Carroça | Produção (oficina) | 40 madeira, 4 barras de ferro | 16 h | Volumosa | 136 |
| Couro | Costura + curtume | 1 pele | 0,5 h | 0,2 kg | 3,5 |
| Tecido | Costura | 3 fibra | 0,25 h | 0,1 kg | 2,5 |
| Camisa de linho | Costura | 4 tecido | 2 h | 0,4 kg | 18 |
| Casaco de couro | Costura | 8 couro | 5 h | 1,5 kg | 44 |
| Mochila de couro | Costura | 6 couro | 4 h | 1,0 kg | 34 |
| Armadura de couro | Costura | 12 couro | 6 h | 6 kg | 60 |
| Barras de cobre ×5 | Fornalha | 10 minério de cobre, 2 carvão | 2 h | 0,5 kg cada | 6 cada |
| Barras de ferro ×5 | Fornalha | 10 minério de ferro, 3 carvão | 3 h | 0,5 kg cada | 8 cada |
| Carvão ×4 | Forno de carvão | 6 madeira | 1 dia, sem trabalhador | 0,4 kg cada | 1,5 cada |
| Faca de ferro | Forja | 1 barra de ferro, 1 madeira | 1,5 h | 0,5 kg | 15 |
| Picareta de ferro | Forja | 2 barras de ferro, 1 madeira | 3 h | 2,5 kg | 29 (Mineração ×1,25) |
| Armadura de placas de ferro | Forja | 10 barras de ferro, 4 couro | 12 h | 9 kg | 140 |
| Remédio de ervas | Botica | 3 ervas | 1 h | 0,1 kg | 10 |
| Peça simples | Remendo | 3 sucata | 1 h | 0,5 kg | 10 (5% de chance de sair uma peça antiga) |
| Rádio portátil | Rádio | 4 peças simples, 2 barras de cobre | 6 h | 2,0 kg | 76 |
| Mapa regional | Cartografia | 2 couro | 4 h | 0,1 kg | 22 |

### Construções

| Estrutura | Custo | Tempo | Resistência | Observação |
| --- | --- | --- | --- | --- |
| Parede de madeira | 3 madeira | 0,5 h | 150 | Inflamável |
| Parede de tijolo | 4 tijolos | 1 h | 350 | Tijolos vêm da fornalha |
| Parede de pedra | 4 blocos de pedra | 1,5 h | 450 | Não queima |
| Parede reforçada | 3 blocos, 2 sucata | 2 h | 600 | — |
| Porta simples | 5 madeira | 1 h | 100 | — |
| Porta reforçada | 4 madeira, 3 barras de ferro | 2 h | 300 | — |
| Piso de terra batida | — | 0,1 h | — | Beleza 0 |
| Piso de madeira | 1 madeira | 0,2 h | — | Beleza +1, inflamável |
| Piso de pedra | 1 bloco de pedra | 0,3 h | — | Beleza +1 |
| Cerca | 1 madeira | 0,2 h | 60 | Para animais |
| Paliçada | 5 madeira | 1 h | 250 | Defesa básica |
| Muralha de pedra | 8 blocos de pedra | 3 h | 900 | Defesa |
| Torre de vigia | 20 madeira, 5 blocos | 6 h | 300 | Aviso +0,5 dia |
| Tocha | 1 madeira | 0,1 h | — | Luz por 2 dias |
| Lampião a óleo | 1 barra de cobre, óleo | 0,5 h | — | Luz contínua com óleo |

### Plantação

O jogador desenha uma **zona de plantação** e escolhe o que ela planta. Os colonos semeiam os tiles livres (Cultivar), as plantas crescem conforme a fertilidade e, maduras, são colhidas; o tile volta a ser semeado sozinho. Planta silvestre ou itens no tile impedem semear. Trocar o cultivo ou apagar a zona não destrói o que já foi semeado.

| Cultivo | Fases | Dias até madura | Colheita | Observação |
| --- | --- | --- | --- | --- |
| Cenoura | 3 | 5 | 5 cenouras | Comida crua (nutrição 20) |
| Trigo | 4 | 8 | 10 trigos | Não se come cru; serve de porção crua para refeições |
| Cogumelo | 2 | 3 | 3 cogumelos | Comida crua (nutrição 15) |

### Armazenamento

No RimWorld, os itens ficam espalhados no chão em zonas de estoque, o que deixa a base feia e bagunçada. Aqui, **tudo é guardado em contêineres**: baús, barris, prateleiras e pátios de materiais. O chão é só um estado temporário.

**Itens no chão:**

- Viram uma **pilha solta**, com um marcador visível.
- Geram uma tarefa de "guardar" automaticamente.
- Clicar numa pilha dá a opção **Guardar**, que leva a pilha antes das outras. Se nenhum contêiner com espaço aceita a categoria do item, o jogo diz o motivo; o mesmo aviso aparece sozinho quando o transporte trava por falta de lugar.
- Estragam mais rápido ao ar livre: comida apodrece 2× mais rápido, metal enferruja, roupas se desgastam.
- Cada pilha solta reduz a beleza do ambiente em 2.

### Tipos de contêiner

Cada contêiner tem **espaços**. Cada espaço guarda um tipo de item até o tamanho máximo da pilha.

Clicar num contêiner mostra o interior como num baú: a grade de espaços, cada um com o ícone do item e a quantidade no canto (nada quando há só um). Passar o mouse num espaço mostra o item, quanto tem e quanto cabe, o que está a caminho e o que está reservado. Embaixo da grade, o botão **Configurar** abre as configurações do contêiner (no MVP, o filtro por categoria).

| Contêiner | Tamanho | Custo | Espaços | Aceita | Especial |
| --- | --- | --- | --- | --- | --- |
| Cesto de vime | 1×1 | 3 fibra | 4 | Leves e médios | Barato e leve (3 kg), dá para levar em expedições |
| Caixote | 1×1 | 5 madeira | 6 | Tudo, exceto líquidos | Pode ser carregado em carroças |
| Baú rústico | 1×1 | 8 madeira | 10 | Tudo, exceto líquidos | Protege do clima |
| Baú reforçado | 1×2 | 10 madeira, 2 barras de ferro | 20 | Tudo, exceto líquidos | Pode ser trancado |
| Prateleira | 1×2 | 6 madeira | 8 | Leves e médios | Os itens aparecem no sprite |
| Rack de ferramentas | 1×1, na parede | 4 madeira | 6 | Ferramentas e armas | Mostra cada ferramenta pendurada |
| Barril | 1×1 | 8 madeira | 3 | Comida, grãos, líquidos | Comida dura ×1,5 |
| Caixa fria | 1×2 | 10 pedra, 5 barro | 8 | Comida | Comida dura ×3; precisa ficar num cômodo frio ou com gelo |
| Arca de armas | 1×2 | 4 barras de ferro, 6 madeira | 12 | Armas, armaduras, munição | Trancada; acesso só para colonos autorizados |
| Pátio de materiais | 2×2 | 4 madeira | 4 grandes | Madeira, pedra, minério, sucata | Pilhas organizadas visíveis, até 4 andares |
| Silo | 2×2 | 30 blocos de pedra | 2 grandes | Grãos | Grãos não estragam |
| Cofre antigo | 1×1 | Encontrado em ruínas ou pesquisado | 6 | Artefatos e peças antigas | Artefatos guardados nele não geram atenção do Mundo |

**Tamanho máximo de pilha por espaço:**

| Tipo de item | Pilha | Pilha em espaço grande |
| --- | --- | --- |
| Materiais (madeira, pedra, minério, sucata) | 50 (no MVP, os recursos básicos juntam até 99) | 300 |
| Barras de metal, peças simples | 25 | — |
| Comida e ingredientes | 20 | — |
| Grãos | 50 | 500 |
| Remédios | 20 | — |
| Munição e flechas | 200 | — |
| Ferramentas, armas, roupas, armaduras, artefatos | 1 | — |

Cada cultura tem visuais próprios: Enraizados usam cestos e baús entalhados; Remendadores, caixotes de sucata; Herdeiros, cofres e caixas antigas restauradas.

### Categorias de itens

Todo item pertence a uma categoria. O filtro dos contêineres trabalha com elas.

| Categoria | Itens |
| --- | --- |
| Alimentos | Refeições, frutas silvestres, cenoura, cogumelo, trigo, carne crua |
| Carcaças | Animais caçados, antes do abate |
| Recursos básicos | Madeira, pedra bruta, fibra, sucata (e minérios, quando entrarem) |
| Recursos avançados | Blocos de pedra, pele, gordura (e couro, tecido, barras, quando entrarem) |
| Ferramentas | Faca, machado, picareta |
| Armas | Lança, arco, flechas |
| Roupas | Túnica, calça e as outras peças de vestir |
| Artefatos | Artefatos e peças antigas |

O pátio de materiais aceita só recursos básicos; caixotes e baús aceitam tudo.

### Organização

Cada contêiner tem configurações próprias:

- **Filtro:** por categoria, item, qualidade mínima e estado (por exemplo, "só roupas acima de 50% de durabilidade"). No MVP, o filtro é por categoria e fica no botão Configurar, embaixo dos espaços do contêiner. O que deixa de ser permitido sai para o chão ao lado e é levado para outro contêiner que aceite.
- **Prioridade:** baixa, normal, alta ou crítica. Itens vão primeiro para os de prioridade maior.
- **Ligação com bancada:** um contêiner ligado a uma bancada abastece ela primeiro. Uma despensa ligada à cozinha encurta o caminho de quem cozinha.
- **Tranca:** baús reforçados, arcas e cofres podem ser trancados, com lista de colonos autorizados.
- **Nome:** o jogador pode renomear ("Despensa", "Arsenal").

Um cômodo com 3 ou mais contêineres e piso vira um **armazém**: itens dentro dele estragam 20% mais devagar, e colonos acham o que procuram mais rápido.

### Logística

- O trabalho **Carregar** (na grade de prioridades) move itens para o contêiner válido mais próximo de maior prioridade.
- Em momentos livres, colonos **consolidam** pilhas: juntam itens iguais espalhados em vários contêineres.
- Bancadas pegam materiais primeiro do contêiner ligado, depois do mais próximo.
- Caixotes e cestos podem ser carregados cheios em carroças, para caravanas e expedições.
- Atacantes que vêm saquear miram o contêiner mais valioso que conhecem. Onde guardar as coisas vira parte da defesa.

### Interface de armazenamento

Um **painel de armazenamento** mostra tudo o que a comunidade tem, sem precisar procurar pelo mapa.

&#91;embedded content: esboço do painel de armazenamento\]

- **Visão geral:** totais por categoria, com quantidade, tendência por dia e quantos dias de comida restam.
- **Contêineres:** lista com nome, local, ocupação e filtro. Clicar centraliza a câmera no contêiner.
- **Metas:** estoque mínimo e máximo por item. Abaixo do mínimo, o jogo cria um pedido automático na bancada certa; acima do máximo, para de produzir.
- **Busca:** digitar um item mostra em quais contêineres ele está, destacando-os no mapa.
- **Alertas:** estoque baixo, contêiner cheio, comida estragando, item sem lugar para ir.

No mapa:

- **Passar o mouse** sobre um contêiner mostra o conteúdo resumido.
- **Clicar** abre a grade de espaços do contêiner. Arrastar itens entre dois contêineres abertos cria uma tarefa de transporte.
- O **sprite** muda conforme a lotação (vazio, metade, cheio). Prateleiras, racks e pátios mostram os itens de verdade.
- Um **modo de visualização de armazenamento** colore os contêineres por categoria e lotação.

## Conhecimento e pesquisa

O conhecimento tem dois trilhos: os **ofícios**, que são a tecnologia atual que as comunidades já dominam, e a **redescoberta**, que é a tecnologia antiga encontrada nas ruínas. Ninguém começa do zero: todo povo sabe fazer coisas básicas, nem que seja de forma simples.

### Ofícios: a tecnologia atual

É o que sobreviveu ao tempo como prática, passado de geração em geração.

- **Conhecido desde o início:** fogo e combustão, agricultura, criação de animais, tecelagem, cerâmica, carpintaria, uso de rodas e carroças, medicina com ervas.
- **Ofícios avançados:** fornalha para fundir metal, ferraria, ligas simples, saber para que serve cada metal, vidro, construção em pedra, barcos a vela, rádio simples.
- Ofícios evoluem por **prática e mestres**: colonos experientes ensinam aprendizes, e conhecimento pode ser trocado com outros clãs.
- Variam por cultura: Enraizados têm os melhores artesãos; Herdeiros dependem menos de ofícios.

### Materiais que duraram

Algumas coisas resistiram a 3 mil anos e são parte do dia a dia, mesmo sem ninguém saber fabricá-las: ligas metálicas antigas, vidro e cerâmica técnica, cabos de cobre, plásticos degradados, painéis e chapas. Elas são recurso comum para todas as culturas, mesmo as que temem tecnologia.

### Redescoberta: a tecnologia antiga

Cada artefato ou tecnologia antiga passa por quatro níveis de compreensão:

1. **Desconhecido:** o objeto existe, mas ninguém sabe o que é.
2. **Usável:** dá para usar sem entender. Há risco de falha, acidente ou de alertar a IA.
3. **Compreendido:** uso seguro e manutenção possível.
4. **Reproduzível:** a comunidade consegue fabricar o item.

### Como a pesquisa funciona

A pesquisa não segue o modelo do RimWorld, com um colono preso numa mesa esperando uma barra encher. Ela segue a lógica do Graveyard Keeper:

1. **Ações geram pontos de conhecimento.** Trabalhar, explorar, conversar e celebrar geram pontos de quatro tipos.
2. **Ações liberam ramos.** Um ramo da árvore só aparece depois de uma ação-gatilho, como extrair o primeiro minério ou domar o primeiro animal.
3. **Cada pesquisa tem um custo** em pontos e, às vezes, em materiais ou numa **prova**: um item que precisa ser levado à mesa, como uma barra de ferro para pesquisar a forja.
4. **Liberação imediata.** Com os pontos e materiais disponíveis, a pesquisa é liberada na hora, na Mesa de estudos. Ninguém fica preso à mesa; um colono só leva a prova até lá, quando houver.

Os pontos são da comunidade inteira, e não há limite para acumular.

**No MVP:** só há pontos de Prática e Vestígio e as 6 pesquisas: Ferramentas de pedra, Armazenamento, Bancada de cozinha, Alvenaria de pedra, Armas primitivas e Mesa de análise. Sobrevivência, Agricultura e Construção aparecem desde o início. **Defesa e armas** aparece na primeira caça (antes de existir ataque) ou no primeiro ataque sofrido. **Redescoberta** aparece quando um artefato é encontrado, porque a Mesa de análise, que analisa artefatos, é ela mesma uma pesquisa desse ramo. A janela de Pesquisa mostra os ramos escondidos como "???", com a dica do gatilho.

### Tipos de pontos

| Ponto | Sigla | Vem de |
| --- | --- | --- |
| **Prática** | P | Trabalho produtivo: fabricar, construir, cultivar, cozinhar, minerar |
| **Vestígio** | V | Passado: investigar ruínas, encontrar e analisar artefatos, decifrar transmissões antigas |
| **Relato** | R | Mundo: explorar, mapear, contatos com clãs, comércio, rádio, missões |
| **Cultura** | C | Comunidade: rituais, festivais, Assembleia, ensino, obras-primas |

### Quanto cada ação rende

| Ação | Pontos |
| --- | --- |
| A cada 3 horas de trabalho produtivo | 1 P |
| Fazer algo pela primeira vez | +3 P |
| Item de qualidade boa ou melhor | +1 P |
| Investigar uma sala de ruína | 2 V |
| Encontrar fragmento de lore | 3 V |
| Encontrar artefato | 5 a 15 V, conforme a raridade |
| Analisar artefato na mesa de análise | 5 a 20 V |
| Decifrar transmissão antiga | 8 V |
| Desmontar artefato | 3 V, mais peças |
| Mapear um hexágono | 1 R |
| Primeira visita a um local | 5 R |
| Primeiro contato com um clã | 10 R |
| Troca com caravana | 2 R |
| Rumor captado no rádio | 1 R |
| Concluir missão | 5 a 15 R |
| Receber professor ou visitante | 10 R |
| Ritual | 3 C |
| Festival | 10 C |
| Assembleia | 15 C |
| Aprendiz sobe de nível com um mestre | 2 C |
| Criar uma obra-prima | 5 C |

**Habilidades multiplicam os pontos:** Vestígio de análise × (0,5 + Pesquisa ÷ 10); Relato × (0,5 + Social ou Exploração ÷ 10), usando a maior.

**Traços que mudam pontos:**

| Traço | Efeito nos pontos |
| --- | --- |
| Curioso | +25% em todos os pontos que gera |
| Obcecado pelo passado | +50% em Vestígio |
| Gênio | +20% em todos os pontos que gera |
| Temeroso | −25% em Vestígio |
| Carismático | +25% em Relato |
| Devoto do Mundo | +25% em Cultura |

**Ritmo esperado:** uma comunidade de 4 colonos rende por volta de 8 a 12 pontos por dia no começo, o suficiente para uma pesquisa de nível I a cada 2 ou 3 dias.

### A ruína do MVP

Uma ruína pequena fica entre 20 e 40 tiles da chegada: um prédio antigo de 13×5 tiles, com 3 salas em fila (Antessala, Galeria e Câmara) ligadas por portas. Suas paredes não se constroem nem se desmontam.

- O jogador clica na ruína e escolhe **Investigar a ruína**: cada sala vira uma tarefa de Pesquisar, de 1 hora.
- Cada sala investigada rende 2 V. A Antessala e a Galeria guardam 4 sucatas cada; a Câmara guarda o **artefato**, que rende mais 15 V e revela o ramo Redescoberta.
- Com isso, os 21 V já pagam a pesquisa Mesa de análise: explorar a ruína libera uma pesquisa.

### Custos por nível

| Nível | Pontos totais | Materiais típicos | Onde se libera |
| --- | --- | --- | --- |
| I | 15 a 40 | Comuns | Mesa de estudos |
| II | 50 a 120 | Metais, couro, provas simples | Mesa de estudos |
| III | 200 a 350 | Barras, peças simples, às vezes 1 peça antiga | Arquivo |
| IV | 600 a 900 | Peças antigas | Arquivo e Laboratório antigo |
| V | 1.500 a 2.500 | Artefatos raros | Laboratório antigo |

### Pesquisa e cultura

- Antes da Assembleia, todos os ramos custam o preço normal.
- Depois, pesquisas ligadas à cultura da comunidade custam −25%; as ligadas à cultura oposta custam +50%.
- Algumas pesquisas são exclusivas de cada cultura.
- Cada pesquisa liberada soma 10 pontos na tendência cultural correspondente.

## Árvore de pesquisa

Custo em pontos: P = Prática, V = Vestígio, R = Relato, C = Cultura. Ramos marcados com "início" já aparecem no começo do jogo; os outros surgem com o gatilho.

### Sobrevivência (início)

| Pesquisa | Nível | Custo | Requisito | Libera |
| --- | --- | --- | --- | --- |
| Ferramentas de pedra | I | 15 P | — | Faca, machado e picareta de pedra |
| Armazenamento | I | 20 P | — | Prateleira, rack de ferramentas, barril, pátio de materiais, painel de metas |
| Conservação | I | 25 P | Bancada de cozinha | Defumadouro, rações de viagem |
| Mobília | II | 50 P, 10 C | — | Mesas, cadeiras, decoração, beleza |
| Produção reforçada | II | 60 P; 20 madeira, 10 blocos | Ferramentas de pedra | Bancada de produção nível reforçado |
| Oficina | III | 220 P, 30 C; 10 barras de ferro | Produção reforçada, Ferraria | Bancada de produção nível oficina, carroça |

### Agricultura e alimentação (início)

| Pesquisa | Nível | Custo | Requisito | Libera |
| --- | --- | --- | --- | --- |
| Bancada de cozinha | I | 20 P | — | Bancada de cozinha, abate de animais |
| Ervas medicinais | II | 40 P, 5 R | — | Plantio de ervas |
| Adubação | II | 60 P, 10 R | — | Fertilidade +20% |
| Fermentação | II | 70 P | — | Barril de fermentação |
| Moagem | II | 60 P | Bancada de cozinha | Moinho manual, farinha e pão |
| Irrigação | III | 220 P, 30 R; 10 barras de cobre | Adubação | Bomba manual, canais |
| Estufa | III | 300 P; 40 vidro | Irrigação | Cultivo no inverno |

### Construção (início)

| Pesquisa | Nível | Custo | Requisito | Libera |
| --- | --- | --- | --- | --- |
| Alvenaria de pedra | I | 25 P | — | Blocos e paredes de pedra |
| Defesas básicas | II | 80 P, 10 R | — | Paliçada, torre de vigia |
| Pontes | II | 70 P | Alvenaria de pedra | Pontes sobre água rasa |
| Tijolos | II | 60 P | Fornalha | Tijolos e paredes de tijolo |
| Muralha | III | 250 P, 20 C | Defesas básicas | Muralha de pedra, porta reforçada |

### Metalurgia (gatilho: extrair o primeiro minério)

| Pesquisa | Nível | Custo | Requisito | Libera |
| --- | --- | --- | --- | --- |
| Fornalha | I | 30 P | — | Fornalha, forno de carvão, barras de cobre |
| Vidro | II | 50 P | Fornalha | Vidro |
| Ferraria | II | 100 P; prova: 1 barra de cobre | Fornalha | Forja, bigorna, ferramentas de cobre |
| Bronze | II | 80 P; prova: 1 barra de cobre | Fornalha | Ligas de bronze |
| Ferro | III | 250 P, 20 R; prova: 1 barra de ferro | Ferraria | Ferramentas, armas e armaduras de ferro |
| Ligas antigas | IV | 700 V, 300 P; 3 peças antigas | Ferro, Compreensão básica | Trabalhar ligas antigas |

### Têxteis e couro (gatilho: primeira pele ou fibra)

| Pesquisa | Nível | Custo | Requisito | Libera |
| --- | --- | --- | --- | --- |
| Curtume | I | 20 P | — | Tina de curtume, couro |
| Tear manual | I | 30 P | — | Bancada de costura, tecido, roupas simples |
| Alfaiataria | II | 80 P, 5 C | Tear manual | Casacos, mochila de couro, cinto de ferramentas |
| Armaduras de couro | II | 90 P | Curtume | Armaduras de couro |
| Armaduras de placas | III | 260 P | Ferro, Armaduras de couro | Armaduras de metal |

### Medicina (gatilho: primeiro ferimento tratado)

| Pesquisa | Nível | Custo | Requisito | Libera |
| --- | --- | --- | --- | --- |
| Remédios de ervas | I | 25 P, 5 R | — | Botica, remédios e ataduras |
| Destilação | II | 70 P | Fermentação | Destilador, álcool medicinal |
| Cirurgia básica | II | 120 P, 30 R | Remédios de ervas | Cirurgias simples, maca |
| Medicina antiga | III | 300 V, 100 P; 2 peças antigas | Cirurgia básica, Compreensão básica | Kits médicos antigos |

### Animais (gatilho: domar o primeiro animal)

| Pesquisa | Nível | Custo | Requisito | Libera |
| --- | --- | --- | --- | --- |
| Currais | I | 20 P | — | Cercas, cocho, ninhos |
| Animais de carga | II | 70 P, 10 R | Currais | Treinar animais de carga |
| Selaria | II | 80 P | Animais de carga, Curtume | Arreios, carroça de tração |
| Doma de criaturas | III | 250 P, 80 R, 30 C | Selaria | Domar criaturas evoluídas (Enraizados −25%) |

### Combustão e máquinas (gatilho: fornalha construída e sucata mecânica encontrada)

| Pesquisa | Nível | Custo | Requisito | Libera |
| --- | --- | --- | --- | --- |
| Remendos | I | 30 P, 10 V | — | Bancada de remendo, peças simples |
| Caldeira | II | 100 P, 20 V | Remendos, Fornalha | Caldeira a vapor |
| Bancada mecânica | III | 220 P, 40 V | Caldeira, Ferro | Bancada mecânica |
| Motor a combustão | III | 300 P, 60 V; 4 peças simples | Bancada mecânica | Motores, bombas, carroça motorizada |
| Veículo a combustão | IV | 650 P, 150 V; 10 barras de ferro, 2 peças antigas | Motor a combustão | Veículos a combustão, barco a motor |

### Comunicação (gatilho: encontrar um rádio ou peça de rádio)

| Pesquisa | Nível | Custo | Requisito | Libera |
| --- | --- | --- | --- | --- |
| Receptor | I | 40 P, 10 R | — | Bancada de rádio, receptor simples |
| Antena e torre | II | 80 P, 20 R | Receptor | Antena, torre de rádio |
| Transmissor | II | 120 P, 30 R; 4 peças simples | Receptor | Transmissor |
| Repetidora | III | 250 P, 60 R | Transmissor, Antena e torre | Repetidoras em postos avançados |
| Decifrar sinais antigos | III | 200 V, 50 R | Transmissor | Transmissões antigas viram pontos e lore |

### Exploração (gatilho: primeira expedição)

| Pesquisa | Nível | Custo | Requisito | Libera |
| --- | --- | --- | --- | --- |
| Batedores | I | 20 R | — | Ordem de batedor, revelar hexágonos vizinhos |
| Cartografia | I | 30 R, 10 P | — | Mesa de cartografia, mapas |
| Sobrevivência em viagem | II | 60 R | Batedores | Barracas, bancada de campanha |
| Navegação | II | 90 R, 20 P | Cartografia | Barcos a remo e vela |
| Postos avançados | III | 220 R, 60 P | Sobrevivência em viagem | Ocupar locais como postos |

### Defesa e armas (gatilho: primeiro ataque sofrido)

| Pesquisa | Nível | Custo | Requisito | Libera |
| --- | --- | --- | --- | --- |
| Armas primitivas | I | 20 P | — | Lança, arco, flechas |
| Armadilhas | II | 60 P | — | Armadilhas de estaca e laço |
| Bestas | II | 90 P, 10 R | Armas primitivas | Bestas e virotes |
| Armas improvisadas | III | 250 P, 80 V; 2 peças simples | Bestas, Remendos | Armas de fogo improvisadas, pólvora |
| Armas antigas | IV | 800 V, 200 P; 4 peças antigas | Armas improvisadas, Reprodução | Armas antigas (Herdeiros −25%) |

### Redescoberta (gatilho: primeiro artefato analisado)

| Pesquisa | Nível | Custo | Requisito | Libera |
| --- | --- | --- | --- | --- |
| Mesa de análise | I | 20 V | — | Mesa de análise |
| Compreensão básica | II | 80 V | Mesa de análise | Levar artefatos simples a Compreendido |
| Arquivo | III | 250 V, 50 C | Compreensão básica | Arquivo (pesquisas de nível III) |
| Reprodução | IV | 700 V, 200 P; 5 peças antigas | Arquivo | Laboratório antigo, artefatos Reproduzíveis |
| Engenharia do passado | V | 2.000 V, 500 P; 3 artefatos raros | Reprodução | Reproduzir artefatos complexos |

### Energia (gatilho: caldeira construída ou gerador antigo encontrado)

| Pesquisa | Nível | Custo | Requisito | Libera |
| --- | --- | --- | --- | --- |
| Moinhos | II | 80 P | — | Moinho de vento, roda d'água |
| Gerador a combustão | III | 300 P, 50 V | Caldeira | Gerador a combustão |
| Células antigas | IV | 900 V; 6 peças antigas | Reprodução | Células de energia antigas (atenção do Mundo) |

### Comércio e diplomacia (gatilho: primeira caravana)

| Pesquisa | Nível | Custo | Requisito | Libera |
| --- | --- | --- | --- | --- |
| Barraca de troca | I | 20 R | — | Barraca de troca, preços visíveis |
| Diplomacia | II | 80 R, 20 C | — | Enviados, acordos, presentes |
| Entreposto | II | 100 R, 30 C | Barraca de troca | Entreposto, pousada (Remendadores −25%) |
| Rotas comerciais | III | 250 R | Entreposto | Caravanas próprias, rotas fixas |

### Crença e comunidade (gatilho: primeiro funeral ou Assembleia)

| Pesquisa | Nível | Custo | Requisito | Libera |
| --- | --- | --- | --- | --- |
| Santuário | I | 15 C | — | Santuário, rituais |
| Festivais | II | 50 C | Santuário | Festival da cultura |
| Ensino formal | II | 60 C, 20 P | — | Bloco Estudo na agenda, sala de aula |
| Tradição oral | III | 200 C, 100 R | Festivais | Mitos revelam fragmentos de lore |

### Céu (gatilho: fragmento de lore sobre o voo e Reprodução liberada)

| Pesquisa | Nível | Custo | Requisito | Libera |
| --- | --- | --- | --- | --- |
| Aerostática | IV | 900 V, 300 P | Reprodução | Balões de observação |
| Voo | V | 2.500 V, 800 P; 5 artefatos raros | Aerostática, Veículo a combustão | Primeiros voos |

### Pesquisas exclusivas de cultura

| Cultura | Pesquisa | Nível | Custo | Libera |
| --- | --- | --- | --- | --- |
| Enraizados | Mestres artesãos | III | 300 P, 80 C | Qualidade sobe um nível em Artesanato, Costura e Cozinha |
| Enraizados | Comunhão com criaturas | IV | 600 P, 300 C | Criaturas domadas lutam e trabalham melhor |
| Remendadores | Gambiarra segura | III | 200 P, 100 V | Itens improvisados falham 50% menos |
| Remendadores | Mercado das ruínas | IV | 600 R, 200 V | Caravanas trazem peças antigas com frequência |
| Herdeiros | Automação | IV | 700 V, 300 P; 6 peças antigas | Esteiras e montadoras |
| Herdeiros | Restauração de veículos | IV | 800 V; 4 peças antigas | Veículos antigos restaurados |

## Mapa jogável e território

A partida começa numa região pequena e cresce aos poucos. O jogador libera áreas vizinhas, marca seu domínio no mapa e encontra cidades em ruínas, outras colônias e recursos. A expansão tem um limite, para a região nunca ficar desproporcional.

### Região inicial

- **Definido:** começar com **128×128 tiles**, formados por 4×4 chunks de 32×32 tiles. Com 1 tile ≈ 1 metro, são cerca de 128 m de lado.
- O entorno aparece bloqueado, com névoa e fronteiras visíveis, mostrando que há mais para descobrir.
- As proporções completas estão na subseção abaixo.

### Proporções com tiles de 16×16

A medida base é **1 tile = 16×16 pixels ≈ 1 metro**. Um colono ocupa 1 tile. O mapa é montado em **chunks de 32×32 tiles**, que são a unidade de geração, de liberação de áreas e de desempenho.

&#91;embedded content: proporções do mapa local · 1,6 px por tile no desenho\]

### O que cabe na tela

A resolução base do jogo é **640×360**, ampliada por números inteiros para manter o pixel art nítido. Em 1920×1080 isso dá escala 3×.

| Monitor | Escala | Zoom normal | Zoom mais afastado |
| --- | --- | --- | --- |
| 1280×720 | 2× | 40×22 tiles | 80×45 tiles |
| 1920×1080 | 3× | 40×22 tiles | 120×67 tiles |
| 2560×1440 | 4× | 40×22 tiles | 160×90 tiles |

Os níveis de zoom devem cair sempre em números inteiros de pixels da tela por pixel da arte (3, 2 e 1 em 1080p), para nada ficar borrado ou irregular.

### Tamanho dos objetos

| Objeto | Ocupa (tiles) | Sprite (px) |
| --- | --- | --- |
| Colono | 1×1 | 16×24 (a cabeça passa do tile) |
| Parede, porta, fogueira, tocha | 1×1 | 16×16 (parede pode ter 16×24) |
| Cama rústica | 1×2 | 16×32 |
| Bancada | 3×1 | 48×16 |
| Árvore | 1×1 de base | 16×32 a 32×48 |
| Animal grande | 1×1 | até 32×24 |
| Entrada de mina | 3×2 | 48×32 |
| Quarto pequeno | 4×4 por dentro | — |
| Salão comum | 8×8 por dentro | — |

### Como fazer no Godot

1. **Project Settings > Display > Window:** Viewport 640×360; para testes, Window Override 1920×1080.
2. **Stretch:** Mode `canvas_items`, Aspect `expand`, Scale Mode `integer`.
3. **Rendering > Textures:** Default Texture Filter `Nearest`, para o pixel art não borrar.
4. **Rendering > 2D:** ativar Snap 2D Transforms to Pixel e Snap 2D Vertices to Pixel.
5. **TileSet:** tile size 16×16. No Aseprite, usar grade de 16×16 e exportar o tileset como sprite sheet.
6. **Camadas:** um `TileMapLayer` para cada camada: Terreno, Piso, Construções, Objetos e Névoa.
7. **Chunks:** guardar o mapa por chunk (um dicionário com a coordenada do chunk como chave) e gerar cada chunk quando a área dele é liberada.
8. **Câmera:** `Camera2D` com uma lista fixa de níveis de zoom, nunca zoom livre.

Exemplo de geração de um chunk a partir da seed:

```gdscript
const CHUNK := 32          # tiles por chunk
const REGIAO_INICIAL := 4  # 4×4 chunks = 128×128 tiles
const REGIAO_MAX := 8      # 8×8 chunks = 256×256 tiles

var world_seed: int = 123456
var noise := FastNoiseLite.new()

func gerar_chunk(hex: Vector2i, chunk: Vector2i) -> void:
    # mesma seed + mesmo hexágono = sempre o mesmo mapa
    noise.seed = hash([world_seed, hex])
    noise.frequency = 0.03
    for y in CHUNK:
        for x in CHUNK:
            var cel := chunk * CHUNK + Vector2i(x, y)
            var altura := noise.get_noise_2d(cel.x, cel.y)
            var tipo := 0 if altura < 0.2 else 1  # 0 = solo, 1 = rocha
            $Terreno.set_cell(cel, 0, Vector2i(tipo, 0))
```

### Áreas liberáveis

- O entorno é dividido em **áreas grandes de formato irregular**, definidas pela geografia: vale, floresta, margem de rio, encosta, cidade em ruínas.
- O tamanho de cada área varia com o que ela contém: uma cidade em ruínas é maior que um bosque.
- Para liberar uma área: explorar com batedores, depois reivindicar (construir um marco ou posto e pagar o custo em recursos e colonos).
- Áreas ocupadas por outros clãs só se liberam por acordo ou conquista.
- Outras colônias, ruínas de cidades e ninhos podem estar dentro da própria região, como vizinhos no mesmo mapa.

### Território de domínio

- O domínio não é um quadrado: é uma **área orgânica pintada no mapa**, com fronteira própria.
- Ele cresce a partir de estruturas de influência (casas, marcos, torres de vigia, postos) e fica restrito às áreas liberadas.
- Áreas sem presença por muito tempo perdem influência e podem ser tomadas por rivais ou criaturas.
- Fronteiras com vizinhos podem gerar disputas, acordos ou guerra.

### Limite de expansão

- **Limite máximo: 256×256 tiles** (8×8 chunks), próximo do mapa padrão do RimWorld (250×250).
- As áreas liberáveis são grupos irregulares de chunks. De 6 a 8 áreas cobrem o espaço entre a região inicial e o limite.
- O porte da colônia também limita: um acampamento não consegue manter tantas áreas quanto um povoado.
- Ao chegar no limite, o caminho para crescer é **fundar uma filial** em outro hexágono do mapa-mundi.
- O limite também protege o desempenho do jogo.

### Montanhas e minas

Montanhas funcionam como no RimWorld: rocha escavada tile a tile, com pedra e veios de minério visíveis na superfície. As **minas** são abstratas: o interior não é mostrado.

- A mina é construída numa encosta ou entrada natural.
- O jogador **aloca um colono** na mina. Ele entra e produz minério ao longo do tempo. Para produzir mais, constroem-se mais minas.
- Cada mina tem uma **profundidade interna**, que aumenta conforme é trabalhada. Quanto mais funda, mais raros os minérios e maiores os riscos.
- A **habilidade de mineração** do colono define velocidade, chance de minérios raros e segurança.
- Escoras, iluminação, ventilação e bombas d'água reduzem os riscos.

| Profundidade interna | Minérios típicos | Riscos |
| --- | --- | --- |
| Rasa | Pedra, carvão, cobre, estanho | Baixos |
| Média | Ferro, chumbo, prata | Desabamentos |
| Funda | Ouro, minérios raros | Gás, inundação |
| Abismo | Ligas antigas, cristais, restos do mundo antigo | Criaturas, grandes colapsos |

Os cálculos de produção e risco estão em Balanceamento e cálculos.

### Início da partida

- O jogador escolhe de **2 a 5 colonos**. Proposta de equilíbrio: menos colonos significa mais recursos iniciais.
- Recursos essenciais são entregues no começo de acordo com a dificuldade:

| Dificuldade | Comida | Materiais e ferramentas | Remédios |
| --- | --- | --- | --- |
| JARDIM (fácil) | Cerca de 30 dias | Madeira, pedra e ferramentas de sobra | Kit completo |
| BALANÇA (média) | Cerca de 15 dias | O suficiente para o primeiro abrigo | Básico |
| CEIFA (difícil) | Cerca de 7 dias | Pouco; quase tudo precisa ser coletado | Quase nenhum |

- **Desbloqueado desde o início:** paredes de madeira e pedra, portas simples, pisos rústicos, camas rústicas, fogueira, tocha, bancada rústica, cesto de vime, caixote, baú rústico, plantação e cerca.
- Não há cultura no início: cada colono traz a origem dele, e a cultura da comunidade se forma com o tempo (ver Culturas).

## Exploração e mapa-mundi

Explorar é descobrir o mundo aos poucos, como um conhecimento que se conquista: primeiro se ouve falar de um lugar, depois ele é mapeado, só então se viaja até lá. A exploração do RimWorld (caravanas lentas e locais genéricos) não é referência aqui.

### O que evitar do RimWorld

- Viagens longas sem decisões, só esperando a caravana chegar.
- Locais grandes e vazios, gerados sem propósito.
- Mapa-mundi que não muda com o tempo.

### Planeta e mapa-mundi

- O mundo é **gerado a cada novo jogo** a partir de uma **seed**. A mesma seed sempre gera o mesmo mundo, então dá para repetir ou compartilhar um mundo.
- Mapa **retangular**, sem globo: polos no topo e na base, faixa equatorial no meio.
- O mapa é dividido em **hexágonos**. Cada hexágono é uma região com bioma, relevo, clima e conteúdo próprios.
- O jogador escolhe um hexágono para fundar o assentamento. Ao selecionar, o jogo mostra bioma, relevo, temperatura, recursos e o índice de dificuldade do local.
- O clima segue a latitude: polos gelados, equador quente, biomas intermediários. Os hemisférios têm estações invertidas.
- Oceanos e rios importam, porque o transporte marítimo é um caminho real de expansão.
- Os nomes dos lugares vêm de palavras antigas corrompidas, encontradas em placas e mapas velhos.
- **Tamanhos de mundo:** pequeno 80×50 hexágonos, médio 120×75, grande 160×100.

### Começar dentro de um clã

Hexágonos dentro do território de um clã podem ser escolhidos, mas o assentamento começa em **conflito direto** com ele:

- A reputação com o clã começa como hostil.
- O primeiro ataque acontece entre os dias 3 e 6, sempre com aviso.
- Negociar só fica possível depois de resistir a dois ataques ou derrotar uma força do clã.
- Em troca, a região costuma ter bons recursos, já que o clã a escolheu por algum motivo.

### O ciclo da exploração

1. **Ouvir:** rumores chegam pelo rádio, por viajantes e pelos mitos dos clãs. Um rumor aponta uma região, nem sempre com precisão.
2. **Mapear:** batedores, postos de observação e cartógrafos revelam regiões. **Mapas são itens**: podem ser trocados, vendidos ou roubados. Mapas antigos podem estar errados, porque em 3 mil anos rios mudaram e cidades afundaram.
3. **Viajar:** a expedição se move pelo mapa-mundi em rotas planejadas. O tipo de transporte define velocidade, carga e alcance. No caminho surgem eventos curtos de decisão, influenciados pelos traços dos colonos do grupo.
4. **Explorar o local:** o grupo entra no lugar em tempo real com pausa. Os locais são **pequenos e densos**: salas, portas trancadas, energia a religar, armadilhas, criaturas e terminais. Também é possível resolver a exploração à distância, com mais risco e menos recompensa.
5. **Ocupar:** um local explorado pode virar posto avançado (mina, porto, torre de rádio), que amplia o alcance e cria rotas.

### Rotas de viagem

Viagens só têm como destino lugares **já conhecidos**: mapeados, visitados ou revelados por rumores precisos. Ao planejar, o jogador escolhe a rota:

| Rota | Distância | Perigo | Descobertas |
| --- | --- | --- | --- |
| Segura e conhecida | Mais longa (×1,6) | Baixo | Quase nenhuma |
| Média | Intermediária (×1,25) | Bandidos e criaturas hostis | Algumas |
| Desconhecida | Mais curta (×1,0, quase em linha reta) | Alto e imprevisível | Muitas: ruínas, rumores, mapas |

Quanto mais segura, mais longa e lenta. Quanto mais perigosa, mais curta e rápida.

- **JARDIM e BALANÇA:** as 3 rotas, com informações corretas.
- **CEIFA:** só 2 rotas, média e desconhecida.
- **ECO:** as 3 rotas, mas a classificação de perigo pode estar errada.

Os cálculos de tempo e risco estão em Balanceamento e cálculos.

### Eventos de viagem

Na viagem, os acontecimentos chegam primeiro como **eventos de texto**, com opções. Só quando a escolha dá errado (ou o jogador escolhe lutar) o evento vira **combate em tempo real**, num mapa pequeno do local.

**Exemplo: acampamento de bandidos no caminho**

| Opção | Chance base de sucesso | Modificadores | Se falhar |
| --- | --- | --- | --- |
| Passar direto | 30% | +2% por nível de Corpo a corpo ou Pontaria do melhor lutador | Combate em tempo real, com os bandidos preparados |
| Passar sem ser visto | 55% | +3% por nível de Exploração do batedor; +10% à noite; −5% por colono acima de 3; −10% com animais ou carroça | Combate em tempo real, com o grupo surpreendido |
| Dar a volta | 85% | +2% por nível de Exploração | Mais 0,5 a 1 dia de viagem e comida; em falha, encontro no desvio |

- A chance final fica sempre entre 5% e 95%.
- Traços abrem ou mudam opções: um Carismático libera "Negociar passagem"; um Covarde pode fugir sozinho; um Esquentado pode atacar sem ordem.
- Outros eventos: ponte quebrada, tempestade, viajante ferido, ruína no caminho, rebanho de criaturas, sinal estranho no rádio, caravana de outro clã.

### Locais exploráveis

| Tipo | O que oferece | Risco |
| --- | --- | --- |
| Ruína comum | Sucata, materiais, fragmentos de lore | Baixo |
| Instalação antiga | Artefatos avançados, terminais, máquinas | Médio a alto |
| Ninho de criaturas | Materiais biológicos raros | Alto |
| Naufrágio ou porto antigo | Embarcações, cargas, mapas marítimos | Médio |
| Posto da IA | Tecnologia de ponta, peças-chave do objetivo | Muito alto |

### Um mundo que muda

- Outros clãs também exploram: uma ruína pode ser saqueada antes de o jogador chegar.
- Ninhos crescem se forem ignorados, e criaturas migram com as estações.
- Rotas comerciais e territórios mudam conforme as guerras e alianças entre clãs.

## Rádio e missões

O rádio é o sistema de missões e a principal janela para o mundo. Ele é tecnologia atual, conhecida e fabricável, não uma relíquia: todas as culturas podem ter um, com qualidade diferente.

### Equipamento

- **Receptor simples:** escuta frequências próximas.
- **Antena e torre:** aumentam o alcance e a clareza do sinal.
- **Transmissor:** permite falar com outros, não só ouvir.
- **Repetidoras:** instaladas em postos avançados, ampliam a rede.
- **Operador de rádio:** função de colono. Habilidade e traços afetam o que ele capta e entende.

### O que se capta

| Frequência | Conteúdo |
| --- | --- |
| Clãs e aliados | Notícias, pedidos de ajuda, propostas de acordo |
| Comerciantes | Caravanas a caminho, preços, mercadorias procuradas |
| Socorro | Grupos em perigo, sobreviventes perdidos, possíveis novos colonos |
| Rivais | Conversas interceptadas, movimentos de tropas, planos de ataque |
| Mundo antigo | Transmissões automáticas de 3 mil anos atrás, ainda em loop (lore) |
| Sinais estranhos | Interferência e padrões da IA |

### Missões

- Chegam como chamadas: escoltar, entregar, resgatar, caçar uma criatura, investigar um sinal.
- Recompensas: reputação, conhecimento, artefatos, mapas e colonos.
- Missões são opcionais e têm prazo; ignorar algumas pode ter consequências.

### Interceptação e prevenção

- O rádio pode captar que um ataque está sendo preparado contra um assentamento que "parece ser o nosso".
- A informação vem incompleta e, às vezes, falsa (contrainformação de rivais).
- A precisão depende do equipamento e do operador.

### Transmitir tem preço

- Transmitir permite negociar, blefar, pedir ajuda ou anunciar o mercado do assentamento, atraindo caravanas.
- Mas cada transmissão revela a posição para rivais e aumenta a atenção da IA.

## Clãs, diplomacia, comércio e guerra

O mundo é dividido entre vários clãs controlados pelo jogo, cada um com cultura, líder, valores e conhecimento próprios. A relação com eles é o principal caminho para crescer sem depender só de ruínas.

### Clãs

- Cada clã pertence a uma das três culturas, com variações locais (costumes, rituais, nomes).
- Clãs têm reputação com o jogador, de hostil a aliado.
- Clãs também se relacionam entre si: alianças, rivalidades e guerras acontecem sem o jogador.

### Diplomacia

- Presentes, acordos, casamentos entre clãs, pedidos de ajuda e troca de prisioneiros.
- Agir contra os valores de um clã reduz a reputação com ele.

### Comércio: o entreposto

Inspirado em Another Brick in the Mall, o assentamento pode virar um centro de comércio:

- Construir barracas, armazéns, pousada e oficinas para visitantes.
- Caravanas e viajantes chegam conforme a reputação e a infraestrutura.
- O jogador define o que vende, os preços e quais clãs são bem-vindos.
- Visitantes trazem notícias, mapas, conhecimento e, às vezes, problemas.

### Guerra

- Ataques a outros clãs para saquear recursos, artefatos ou capturar especialistas.
- Conquistar um clã pode anexá-lo, trazendo colonos com outra cultura.
- Guerra gera retaliação e piora a reputação com aliados do alvo.

## A IA, ameaças e crises

No lugar de um "narrador", o jogo tem a **IA**: a mesma inteligência antiga da lore, que observa o mundo e decide o ritmo dos acontecimentos. Escolher a personalidade da IA no início é a principal escolha de dificuldade. Toda grande ameaça dá sinais antes, e o jogador sempre tem meios de se preparar.

Dentro do jogo, ninguém usa a palavra IA: os colonos falam do **Mundo**. O termo IA aparece só neste documento e nos menus de configuração da partida, até o jogador descobrir a verdade.

### Personalidades da IA (proposta)

| IA | Comportamento | Dificuldade |
| --- | --- | --- |
| **JARDIM** | Quer o mundo em equilíbrio. Poucas ameaças, avisos longos, atenção sobe devagar | Fácil |
| **BALANÇA** | Reage na medida do que a colônia faz. Ritmo de tensão e calma | Média |
| **CEIFA** | Vê a humanidade como risco. Ameaças frequentes, avisos curtos, atenção sobe rápido | Difícil |
| **ECO** | Fragmentada e imprevisível. Eventos estranhos, sinais confusos | Caótica |

Na lore, são diferentes estados da mesma IA: escolher uma é escolher como ela "acordou" neste mundo.

### Medidor de atenção

- Sobe com o uso de energia, máquinas, artefatos avançados e transmissões de rádio. Cai com o tempo.
- **Baixa:** a IA quase ignora a colônia.
- **Média:** drones de reconhecimento e pequenas sabotagens.
- **Alta:** ataques diretos para destruir a tecnologia e, se necessário, os humanos.
- A personalidade da IA define a velocidade do medidor e a força das respostas.

### Contato com a IA

A forma como a IA se comunica evolui com o contato e com o uso de tecnologia:

1. **Silêncio:** nenhum sinal claro.
2. **Interferência:** padrões estranhos no rádio e em máquinas.
3. **Fragmentos:** mensagens de texto curtas e quebradas.
4. **Diálogo:** mensagens diretas, com intenção clara.
5. **Voz (futuro):** áudio, apenas nos níveis mais altos de contato.

### Tipos de ameaça

| Fonte | Exemplos |
| --- | --- |
| Natureza | Tempestades, secas, pragas na plantação, doenças, invernos longos |
| Criaturas | Predadores, migrações, ninhos que se expandem |
| Humanos | Ataques de clãs rivais, saqueadores, espiões |
| A IA | Drones, máquinas sentinela, sabotagem de tecnologia, invasões |
| Internas | Brigas, crises de humor, facções internas, deserção |

### Prevenção em vez de surpresa

No RimWorld, ataques surpresa podem destruir uma colônia de uma vez. Aqui, o objetivo é que crises sejam desafios, não quebras.

- **Sinais antes da ameaça:** conversas captadas no rádio, rastros, fumaça no horizonte, animais fugindo, drones avistados, colonos com humor baixo dando sinais dias antes.
- **Tempo para reagir:** quanto melhor a vigilância (rádio, batedores, vigias, aliados informantes), maior e mais precisa a antecedência.
- **Respostas possíveis:** reforçar defesas, emboscar na rota, negociar ou pagar tributo, pedir ajuda a aliados, blefar pelo rádio, esconder estoques, evacuar.
- **Inimigos com objetivo:** atacantes vêm buscar algo (saquear, sequestrar, destruir uma máquina) e recuam quando conseguem ou quando sofrem perdas. Eles não lutam até o último.
- **Janela de recuperação:** depois de uma crise grande, a IA dá um período de calma proporcional ao dano.
- **Escala pelo progresso:** a força das ameaças acompanha o desenvolvimento da colônia, não só a riqueza acumulada.

### Combate

- Tempo real com pausa, com cobertura, posições e ordens diretas, como no RimWorld.
- Defesas construídas, inspiradas no Factorio: muralhas, torres, armadilhas e, para culturas tecnológicas, linhas automáticas de abastecimento de munição.
- Cada cultura luta de um jeito: Enraizados com arcos, lanças e animais; Remendadores com armas improvisadas; Herdeiros com armas antigas e máquinas.

**Combate no MVP:**

- **Convocar (V):** o colono convocado larga o que fazia e segura a posição. Com arma de corpo a corpo, vai até inimigos a até 6 tiles; com arco, atira só de onde está. Botão direito num saqueador manda atacá-lo; em chão livre, ir até lá. V sem ninguém selecionado convoca (ou dispensa) todos.
- **Quem não está convocado foge** de saqueadores a até 8 tiles (o Covarde, de 12), correndo 12 tiles. O Covarde convocado abandona o combate com 25 de dano.
- **Acerto:** corpo a corpo 55% + 3,5% por nível de Corpo a corpo; à distância 80% − 4% por tile + 2% por nível; sempre entre 25% e 95%. O dano varia ±20%, e a Força muda o dano corpo a corpo em 6% por ponto. Cada golpe treina Corpo a corpo.

| Arma | Dano | Alcance | Golpe a cada | Ferimento |
| --- | --- | --- | --- | --- |
| Mãos vazias | 5 | Corpo a corpo | 1 s | Contusão |
| Faca de pedra | 8 | Corpo a corpo | 1 s | Corte |
| Machado de pedra | 11 | Corpo a corpo | 1 s | Corte |
| Lança de madeira | 13 | Corpo a corpo | 1 s | Perfuração |
| Arco | 10 | 12 tiles | 2 s | Perfuração |

No MVP o arco não gasta flechas.

### Ferimentos, socorro e morte (MVP)

- Cada golpe que acerta vira um **ferimento** (corte, perfuração ou contusão) com o dano causado. Cortes e perfurações **sangram** até serem tratados: 0,5% de sangue por hora para cada ponto de dano.
- **Caído** com 60 de dano ou 50% de sangue perdido; **morto** com 100 de dano ou 100% de sangue perdido. A dor tira até 50% da velocidade de trabalho e de movimento.
- **Cura por hora** de cada ferimento: 0,5 sem tratar, 2 tratado, ×1,5 deitado numa cama. Sem sangrar, o sangue volta 4% por hora.
- De pé e sangrando, o colono **estanca os próprios ferimentos** (45 min). Com 30 de dano ou mais, **repousa** numa cama até baixar de 15.
- Quem cai gera tarefas de **Emergência**: **Socorrer** (levar até uma cama livre) e **Tratar** (30 min, estanca o sangramento). Sem cama livre, é tratado no chão.
- **Morte permanente:** o colono sai da partida, o que vestia e carregava fica no chão, a comunidade sente (−8 de humor por 3 dias) e o M\_adaptação cai. Corpos, túmulos e funerais ficam para depois do MVP.

### Saqueadores do MVP

- **Quando:** o primeiro ataque chega no dia 6; depois, a cada 5 a 9 dias (média 7, BALANÇA), sempre depois da calma do ataque anterior. Chegam entre 8 h e 18 h.
- **Aviso:** 1,5 dia antes, uma coluna de **fumaça no horizonte** aparece perto da borda por onde vão chegar, com uma mensagem; o painel de tempo mostra quanto falta.
- **Grupo:** os pontos de ameaça (ver Balanceamento) compram saqueadores com lança (50) e arqueiros (65, 35% de chance a cada compra quando os pontos dão). Sempre vem ao menos um.
- **Objetivo:** vão saquear o contêiner ou a pilha mais perto, levam até 25 kg do que vale mais por kg e fogem pela borda de onde vieram. No caminho, atacam quem chega a 7 tiles (o arqueiro, ao alcance do arco) ou quem os ataca, e não perseguem quem foge para longe. Caídos não são atacados.
- **Recuo:** cada um foge com 50 de dano; o grupo inteiro recua quando metade já saiu do combate (morto, fugido ou com o saque) ou depois de 12 h no mapa. Morto, o saqueador deixa a arma no chão.
- **Depois:** a calma do GDD (2 + 10 × perdidos ÷ total dias) adia o próximo ataque, e o primeiro ataque revela o ramo Defesa e armas.

## Objetivos e finais

O objetivo principal é encontrar **O Arquivo**, um cofre de conhecimento da antiga civilização. Ele revela a verdade sobre a IA e leva à decisão final sobre o destino do mundo. Outros finais existem para quem prefere outro caminho.

### Arco principal: O Arquivo

1. **Os rumores:** fragmentos e mitos citam um lugar onde "o mundo antigo guardou tudo".
2. **As chaves:** juntar pistas e peças espalhadas em instalações antigas, clãs e postos da IA.
3. **A abertura:** chegar ao Arquivo e descobrir a verdade sobre o fim do mundo.
4. **A escolha:** decidir o que fazer com o conhecimento e com a IA.

### Finais

| Final | Como se chega | Combina com |
| --- | --- | --- |
| Desligar a IA | Usar o Arquivo para encontrar e destruir o núcleo da IA | Remendadores, Herdeiros |
| Negociar com a IA | Provar que a humanidade pode viver em equilíbrio | Qualquer cultura |
| Fundir-se com a IA | Unir humanos e máquina num novo começo | Herdeiros |
| Selar o Arquivo | Destruir ou esconder o conhecimento para que o erro não se repita | Enraizados |
| Unificação | Tornar-se o centro do mundo por diplomacia, comércio ou conquista | Qualquer cultura |
| Sobrevivência livre | Sem final; o jogador joga enquanto quiser | Qualquer cultura |

Os finais não são exclusivos de uma cultura, mas cada cultura tem facilidade natural com alguns.

## Balanceamento e cálculos

Todos os números aqui são ponto de partida para testes. A estrutura segue a lógica do RimWorld (pontos de ameaça calculados a partir de riqueza e colonos, com multiplicadores), adaptada às regras deste jogo: atenção do Mundo, avisos e rotas.

### Tempo

- Simulação a 60 ticks por segundo na velocidade 1×.
- **1 hora** de jogo = 1.800 ticks = 30 segundos reais a 1×.
- **1 dia** = 24 horas = 43.200 ticks = 12 minutos reais a 1× (4 min a 3×, 2 min a 6×).
- **Velocidades, como no RimWorld:** pausa, normal 1×, rápida 3× e muito rápida 6× (teclas Espaço, 1, 2 e 3). Ultrarrápida 15× (tecla 4) só no modo de desenvolvimento.
- **1 estação** = 15 dias. **1 ano** = 4 estações = 60 dias, cerca de 12 horas reais a 1×.
- O ano começa na primavera. No hemisfério sul as estações são invertidas (somam-se 30 dias).

### Dia e noite

Horas de luz = 12 + A × sen(2π × (dia − 7,5) / 60), onde A depende da latitude.

| Latitude | A | Primavera | Verão | Outono | Inverno |
| --- | --- | --- | --- | --- | --- |
| Equatorial | 0,5 | 12 h | 12,5 h | 12 h | 11,5 h |
| Temperada | 3 | 12 h | 15 h | 12 h | 9 h |
| Fria | 6 | 12 h | 18 h | 12 h | 6 h |
| Polar | 10 | 12 h | 22 h | 12 h | 2 h |

Valores no meio de cada estação.

- Fora de áreas iluminadas, visão e detecção caem 50%.
- Trabalho sem luz é 20% mais lento.
- Plantas só crescem com luz (do dia ou artificial).
- À noite, a chance de eventos com criaturas é multiplicada por 1,5.
- Colonos dormem por padrão das 22 h às 6 h, ajustável por agenda.
- **Visual:** o mapa escurece à noite num tom azulado, com amanhecer e anoitecer de 1 hora; a interface não escurece. No MVP a latitude é temperada.

### Estações e temperatura

Temperatura (°C) = T\_bioma + A\_sazonal × sen(2π × (dia − 7,5) / 60) + A\_diária × cos(2π × (hora − 15) / 24) + variação aleatória de até ±3.

| Bioma | T\_bioma | A\_sazonal | A\_diária |
| --- | --- | --- | --- |
| Planície | 14 | 12 | 6 |
| Floresta temperada | 12 | 12 | 5 |
| Costa | 15 | 7 | 3 |
| Pântano | 18 | 8 | 4 |
| Floresta tropical | 26 | 3 | 4 |
| Cidade em ruínas | 14 | 10 | 4 |
| Deserto | 26 | 10 | 12 |
| Tundra | −8 | 14 | 5 |
| Gelo polar | −25 | 15 | 4 |

| Estação | Plantas | Eventos comuns | Viagem |
| --- | --- | --- | --- |
| Primavera | Crescimento normal; melhor época de plantio | Chuvas, enchentes, migrações | ×0,9 (lama) |
| Verão | Crescimento ×1,1 | Secas, ondas de calor, incêndios | ×1,0 |
| Outono | Colheita; crescimento ×0,8 | Tempestades, mais caravanas | ×0,95 |
| Inverno | Para abaixo de 1 °C | Frio extremo, criaturas famintas atacam mais | ×0,7 em biomas frios |

- Plantas crescem entre 1 e 45 °C, com ótimo entre 10 e 35 °C.
- Colonos sofrem hipotermia abaixo de −10 °C sem roupa adequada, e insolação acima de 40 °C.

### Pontos de ameaça

A força de cada ataque é medida em pontos, que o atacante "gasta" para montar o grupo.

**Pontos = (P\_riqueza + P\_colonos) × M\_IA × M\_adaptação × M\_início**

- **Riqueza (R)** = valor dos itens + valor dos animais + 0,5 × valor das construções.
- **P\_riqueza:** interpolação linear na tabela abaixo.
- **P\_colonos:** soma por colono capaz de lutar (feridos e crianças contam 25%). O valor é marginal: os 5 primeiros valem 25 cada, do 6º ao 10º valem 45 cada, e assim por diante. Colônias grandes ficam mais visadas, o que reforça o incentivo às filiais.
- **M\_IA:** multiplicador da personalidade (ver Parâmetros das IAs).
- **M\_início** = mín(1; 0,3 + 0,07 × dia). O jogo chega à força total no dia 10.
- **M\_adaptação:** começa em 1,0; cai 0,15 a cada morte de colono (mínimo 0,5) e 0,05 por construção importante destruída; sobe 0,01 por dia sem perdas, até o teto da IA.
- Todo ataque tem no mínimo 35 pontos e no máximo o teto da IA.

| Riqueza | P\_riqueza |
| --- | --- |
| Até 10.000 | 0 |
| 100.000 | 600 |
| 300.000 | 1.800 |
| 600.000 | 3.000 |
| 1.000.000 ou mais | 4.000 |

| Colonos | Pontos por colono |
| --- | --- |
| 1 a 5 | 25 |
| 6 a 10 | 45 |
| 11 a 20 | 70 |
| 21 ou mais | 100 |

| Atacante | Custo em pontos |
| --- | --- |
| Criatura pequena | 30 |
| Saqueador com lança | 50 |
| Arqueiro | 65 |
| Drone do Mundo | 80 |
| Atirador com arma improvisada | 90 |
| Veterano | 130 |
| Criatura grande | 150 |
| Sentinela do Mundo | 250 |

**Exemplo:** dia 30, BALANÇA, 4 colonos, riqueza 40.000.

- P\_riqueza = (40.000 − 10.000) / 90.000 × 600 = 200
- P\_colonos = 4 × 25 = 100
- Pontos = 300 × 1,0 × 1,0 × 1,0 = **300** → por exemplo, 4 saqueadores com lança e 1 arqueiro (265 pontos).

**Ataques do Mundo** usam uma conta própria, e só acontecem com atenção a partir de 30: Pontos = (P\_riqueza calculado só com tecnologia antiga + atenção × 15) × M\_IA × M\_início.

### Atenção do Mundo

- Vai de 0 a 100. Faixas: 0 a 29 baixa, 30 a 69 média, 70 a 100 alta.
- **Ganho por dia:** máquina antiga ligada +0,3; gerador ou célula de energia antiga +0,6; artefato em uso sem compreensão +0,2.
- **Ganho por ação:** transmissão de rádio +2; voo +10.
- **Multiplicador por cultura:** Enraizados ×0,5, Remendadores ×1,0, Herdeiros ×1,5; antes da Assembleia, ×1,0.
- **Queda por dia:** 1 × fator de esquecimento da IA.

### Avisos e recuperação

- **Antecedência do aviso** = aviso base da IA + bônus de vigilância: rádio com operador +1 dia, torre de vigia +0,5 dia, batedores na área +0,5 dia, aliado informante +1 dia.
- **Precisão do aviso** = 50% + 5% × habilidade do operador de rádio (máximo 95%). Avisos imprecisos podem errar o alvo, o tamanho ou o dia.
- **Dias de calma depois de uma crise** = (2 + 10 × colonos perdidos ÷ total de colonos) × fator de recuperação da IA. Exemplo: perder 1 de 4 colonos em BALANÇA dá 4,5 dias de calma.

### Parâmetros das IAs

| Parâmetro | JARDIM | BALANÇA | ECO | CEIFA |
| --- | --- | --- | --- | --- |
| M\_IA | 0,5 | 1,0 | 0,6 a 1,8, sorteado por evento | 1,6 |
| Teto de pontos | 3.000 | 6.000 | 8.000 | 10.000 |
| Intervalo médio entre ameaças | 12 dias | 7 dias | 3 a 14 dias | 4,5 dias |
| Aviso base | 3 dias | 1,5 dia | 0 a 3 dias | 0,5 dia |
| Esquecimento da atenção | 1,5 | 1,0 | 0,5 a 1,5 | 0,6 |
| Teto de adaptação | 1,0 | 1,15 | 1,2 | 1,3 |
| Fator de recuperação | 1,5 | 1,0 | 1,0 | 0,6 |
| Rotas de viagem | 3 | 3 | 3, podem enganar | 2 |
| Comida inicial | \~30 dias | \~15 dias | \~15 dias | \~7 dias |

Recursos iniciais × (1 + 0,15 × (5 − número de colonos)). Começar com 2 colonos dá 45% a mais de recursos que começar com 5.

### Viagem e rotas

**Tempo de viagem (dias)** = soma, para cada hexágono da rota, de 1 ÷ (V × M\_terreno × M\_estação).

| Transporte | V (hexágonos por dia) |
| --- | --- |
| A pé | 1,0 |
| Animais de carga | 1,3 |
| Carroça | 1,6 |
| Barco a remo ou vela | 2,5 |
| Veículo a combustão | 3,0 |
| Barco a motor | 4,0 |
| Veículo antigo | 5,0 |

Carga acima do limite reduz a velocidade em 30%.

| Terreno do hexágono | M\_terreno |
| --- | --- |
| Estrada antiga | 1,3 |
| Planície | 1,0 |
| Deserto | 0,8 |
| Floresta | 0,75 |
| Colinas | 0,6 |
| Pântano | 0,5 |
| Neve e gelo | 0,5 |
| Montanha | 0,35 (veículos não passam) |

| Rota | Distância | Risco base por dia | Força do encontro | Chance de descoberta por dia |
| --- | --- | --- | --- | --- |
| Segura | ×1,6 | 3% | 20% dos pontos de ameaça | 1% |
| Média | ×1,25 | 15% | 50% dos pontos de ameaça | 8% |
| Desconhecida | ×1,0 | 30% | 80% dos pontos de ameaça | 25% |

- **Chance de encontro por dia** = risco base × M\_IA × (1 − proteção).
- **Proteção** = 0,05 × habilidade do batedor + 0,1 com escolta armada (máximo 0,6).

**Exemplo:** destino a 6 hexágonos de floresta, de carroça, no verão, em BALANÇA, com proteção 0,2.

| Rota | Hexágonos | Duração | Chance de pelo menos um encontro |
| --- | --- | --- | --- |
| Segura | \~10 | 8,3 dias | \~18% |
| Média | 7,5 | 6,3 dias | \~55% |
| Desconhecida | 6 | 5 dias | \~75% |

### Dificuldade do terreno

Ao escolher o hexágono inicial, o jogo mostra o **Índice de Dificuldade do Local (IDL)** = bioma + relevo + ameaças − recursos, de 0 a 100.

| Fator | Pontos |
| --- | --- |
| Bioma: planície | 5 |
| Bioma: floresta temperada ou costa | 10 |
| Bioma: floresta tropical | 25 |
| Bioma: pântano ou cidade em ruínas | 30 |
| Bioma: deserto | 35 |
| Bioma: tundra | 40 |
| Bioma: gelo polar | 70 |
| Relevo: plano / colinas / montanhoso | 0 / +5 / +10 |
| Ninho de criaturas próximo | +10 |
| Clã hostil vizinho | +10 |
| Posto do Mundo próximo | +15 |
| Dentro do território de um clã | +20 |
| Água doce, solo fértil, minério à vista | −5 cada |

Faixas: 0 a 20 tranquilo, 21 a 40 moderado, 41 a 60 difícil, 61 ou mais extremo.

No mapa local, cada tipo de terreno afeta movimento, construção e cultivo:

| Terreno | Movimento | Construção | Fertilidade |
| --- | --- | --- | --- |
| Piso construído | 110% | Sim | — |
| Solo | 100% | Sim | 100% |
| Solo rico | 100% | Sim | 140% |
| Grama alta | 90% | Sim | 100% |
| Areia | 80% | Sim | 30% |
| Entulho antigo | 70% | Depois de limpar | — |
| Lama | 60% | Não | 70% |
| Neve funda | 50% | Sim | — |
| Água rasa | 40% | Só pontes | — |
| Água funda | Intransponível | Não | — |
| Rocha | Intransponível | Depois de escavar | — |

### Mineração

Habilidades vão de 0 a 20, como no RimWorld.

- **Produção por dia** = 8 × (0,5 + habilidade ÷ 10) × ferramenta (nenhuma 1,0; ferro 1,25; antiga 1,6). Um mineiro de habilidade 20 sem ferramenta produz 20 unidades por dia.
- **Profundidade interna** sobe com o total extraído: rasa até 49 unidades, média de 50 a 149, funda de 150 a 299, abismo a partir de 300 (exige escoras e ventilação).
- **Chance de minério raro por unidade:** rasa 2%, média 6%, funda 12%, abismo 20%, mais 0,5% por nível de habilidade.
- **Chance de acidente por dia** = risco base (rasa 0,5%, média 1,5%, funda 3%, abismo 6%) × (1 − 0,04 × habilidade) × (1 − 0,15 por estrutura de apoio instalada).

## Interface

A organização da informação segue o RimWorld, porque funciona: mapa no centro, colonos no topo, abas na base, inspeção no canto. A diferença está no visual, mais bonito e com identidade própria, e em mostrar só o necessário em cada momento.

### Princípios contra a poluição visual

1. **Três camadas de informação:** o essencial fica sempre visível; o detalhe aparece ao passar o mouse; o completo aparece ao clicar.
2. **Contexto:** painéis só aparecem quando fazem sentido. O mapa de temperatura só aparece no modo de temperatura.
3. **Cores com significado fixo:** a mesma cor sempre quer dizer a mesma coisa (ver Estilo visual).
4. **Ícone mais texto curto:** números só onde a decisão depende deles.
5. **Alertas com limite:** no máximo 5 visíveis, ordenados por urgência; o resto vira "+N alertas".
6. **Posições fixas:** cada coisa está sempre no mesmo lugar, para o jogador criar memória.
7. **Teclado para tudo:** cada aba, modo e ordem tem atalho.
8. **Pausa automática opcional** ao abrir painéis grandes e cartas de evento.

### Tela principal

&#91;embedded content: layout da tela principal\]

| Região | Conteúdo | Detalhe ao passar o mouse |
| --- | --- | --- |
| Topo esquerdo | Recursos rápidos: até 6 itens escolhidos pelo jogador (por padrão, comida em dias, madeira, remédios) | Tendência por dia e onde está guardado |
| Topo centro | Barra de colonos: retrato, faixa de humor e ícone de estado (dormindo, ferido, em crise, em expedição) | Nome, tarefa atual, necessidades |
| Topo direito | Dia, estação, hora, temperatura, clima e velocidade do tempo | Previsão do dia e horas de luz |
| Lateral direita | Alertas, até 5 | O motivo e um atalho para resolver |
| Base | Barra de abas | Atalho de teclado |
| Canto inferior esquerdo | Painel de inspeção do que está selecionado | — |
| Canto inferior direito | Mensagens recentes, que somem sozinhas | Histórico completo no Diário |
| Centro | Cartas de evento e decisões, quando houver | — |

**Abas da barra inferior:** Construir, Ordens, Trabalho, Agenda, Colonos, Armazém, Pesquisa, Rádio, Mundo, Diário, Comunidade e Menu. Rádio, Mundo e Comunidade só aparecem quando o sistema é liberado.

### Painel de inspeção

Mostra o que estiver selecionado: colono, animal, bancada, contêiner, planta, construção ou tile.

**Seleção por arraste:** sem ferramenta ativa, arrastar com o botão esquerdo desenha um retângulo. Soltar no mesmo tile é um clique comum. Se o retângulo pega colonos, só eles são selecionados (um só vira a seleção comum). O painel lista cada um com o que está fazendo; clicar num nome seleciona só ele. As opções valem para o grupo: convocar ou dispensar todos (V) e cancelar as ordens. Com o botão direito, todos atacam o saqueador clicado, o mais perto que puder faz a tarefa clicada, ou cada um vai para um tile livre em volta do ponto clicado. Sem colonos, ficam selecionadas as **árvores, rochas, arbustos e plantas de fibra** do retângulo, cada uma com sua marca, e o painel mostra só as opções delas, nesta ordem: **Cortar**, **Minerar** e **Colher** (com a quantidade, como "Cortar (12)", e os cancelamentos do que já está marcado). O que é cortado ou minerado sai da seleção. Sem nada disso no retângulo, a área inteira fica selecionada: o painel resume o que há nela ("16 árvores, 5 plantas de fibra") e junta as opções iguais numa só, que vale para todos os alvos ("Desmontar: Caixote (2)", "Caçar: Lebre (4)"). Uma construção de vários tiles conta uma vez, e criar plantação fica de fora (para isso, há a ordem Plantação).

- **Colono:** abas Geral, Habilidades, Saúde, Equipamento, Social e Por quê.
- **Bancada:** fila de pedidos, anexos, nível e condições do ambiente.
- **Contêiner:** grade de espaços, filtro e prioridade.
- **Construção:** resistência, materiais faltando, quem está trabalhando.
- **Tile:** terreno, fertilidade, temperatura, beleza.

**Opções do que foi clicado:** no topo do painel aparecem botões com o que dá para fazer ali: cortar uma árvore, colher, minerar, desmontar uma construção, cancelar uma obra, caçar um animal, guardar uma pilha, escolher o cultivo da plantação, criar uma plantação no chão livre ou investigar uma ruína. No colono: convocar ou dispensar, comer agora, dormir agora, largar o item da mão e cancelar a ordem. No MVP, a saúde (ferimentos, sangue perdido e sangramento por hora) fica na aba Geral, e o painel do tile mostra os saqueadores que estão nele. O que já está marcado vira "cancelar". A lista começa pequena e cresce com o jogo.

Selecionar vários colonos mostra um resumo do grupo e as ordens em comum.

### Janelas

| Janela | O que mostra |
| --- | --- |
| Colonos | Tabela com todos os colonos: humor, saúde, tarefa, habilidades principais; colunas configuráveis |
| Trabalho | Grade de prioridades (ver Colonos) |
| Agenda | Grade de horas por colono, com pintura arrastando o mouse |
| Armazém | Painel de armazenamento (ver Armazenamento) |
| Pesquisa | Árvore com os ramos revelados; ramos ainda escondidos aparecem como "???"; pontos P, V, R e C no topo; no MVP, cada pesquisa tem o custo, o que libera e o botão Liberar (ou o motivo de não poder) |
| Rádio | Dial de frequência que o jogador gira, onda do sinal, canais conhecidos, missões ativas |
| Mundo | Mapa-mundi em hexágonos, rotas, expedições em andamento |
| Diário | Fragmentos de lore, mitos dos clãs, descobertas e histórico de eventos |
| Comunidade | Porte e requisitos, triângulo de tendência cultural, valores, relações com clãs |
| Bancada | Fila de pedidos com condições |

**Atalhos do MVP:** Espaço pausa; 1, 2 e 3 mudam a velocidade; B Construir; C Cortar; M Minerar; H Colher; K Caçar; P Plantação; D Desmontar; X Cancelar; W Trabalho; A Agenda; I Armazém; R Pesquisa; V Convocar (sem seleção: todos); Esc fecha a janela ou solta a ferramenta; F11 tela cheia. Botão direito com um colono selecionado: num saqueador, atacar; numa tarefa, priorizar; no chão, ir até lá. Arrastar sem ferramenta seleciona vários colonos, as árvores, rochas e plantas (Cortar, Minerar, Colher) ou uma área. Em build de desenvolvimento: 4 acelera para 15× e F5 gera um mapa novo.

### Cartas de evento

Eventos de texto, decisões de viagem e a Assembleia aparecem como **cartas** no centro da tela:

- Ilustração em pixel art no topo.
- Texto curto, de 2 a 4 frases.
- Opções com a chance de sucesso visível e, ao passar o mouse, o que influencia a chance.
- Opções liberadas por traços aparecem com o retrato do colono que as permite.

### Modos de visualização

Camadas sobre o mapa, ligadas por atalho: zonas, território, beleza, temperatura, luz, fertilidade, armazenamento, perigo e caminhos. Só um modo fica ativo por vez.

### Criação de partida

1. **Mundo:** seed, tamanho (80×50, 120×75, 160×100) e personalidade da IA, apresentada como cartas.
2. **Local:** escolha do hexágono no mapa-mundi, com bioma, relevo, clima e índice de dificuldade.
3. **Colonos:** de 2 a 5, com sorteio individual e ficha completa.
4. **Início:** resumo dos recursos iniciais e começo da partida.

### Estilo visual: rust punk

A estética mistura **cyberpunk** e **rústico**: painéis de metal oxidado, madeira e couro, com telas antigas de fósforo e brilho neon onde há tecnologia antiga. É como se a interface fosse montada com restos do mundo antigo.

- **Molduras:** painéis em 9 partes (9-slice) de pixel art, com cantos de 16 px, rebites e emendas.
- **Fundo dos painéis:** escuro e quase opaco (90%), para o mapa não competir com o texto.
- **Telas de tecnologia:** Rádio, Pesquisa e terminais usam efeito de tela antiga, com linhas de varredura leves e brilho.
- **Interferência do Mundo:** com atenção alta, a interface sofre falhas visuais breves (texto tremido, chiado). A própria interface conta a história.
- **Fonte:** Dogica Pixel (pixel art proporcional, com os acentos do português; licença SIL OFL, com crédito em CREDITOS.md). Ela é desenhada numa grade de 8 px e fica no tamanho nativo: 8 px reais com a interface em ×2.
- **Escala da interface:** separada da do mapa e sempre inteira e par, para a fonte ficar nítida: ×2 do 720p ao 1440p (em tela cheia 1080p o mapa fica em ×3 e a interface continua em ×2, com mais espaço), ×4 em 4K.
- **Sons de interface:** cliques mecânicos, chaves, chiado de rádio.

**Cores com significado:**

| Uso | Cor | Hex (proposta) |
| --- | --- | --- |
| Fundo dos painéis | Grafite quente | #1B1A1F |
| Bordas e molduras | Ferrugem | #7A4A32 |
| Texto principal | Creme | #E8DCC0 |
| Texto secundário | Cinza quente | #9A9285 |
| Comunidade e ofícios | Âmbar | #F2A541 |
| Tecnologia antiga e o Mundo | Ciano neon | #3FE0D0 |
| Positivo | Verde musgo | #7BC96F |
| Perigo | Vermelho | #E5534B |
| Lore e mistério | Violeta | #9B7BD8 |

**Molduras por cultura:** antes da Assembleia, a interface usa sucata neutra. Depois, as molduras mudam: Enraizados com madeira, couro, cordas e âmbar; Remendadores com chapas soldadas, fita e laranja; Herdeiros com metal limpo, vidro e ciano neon.

## Arte e áudio

Pixel art top-down feita no Aseprite, com um visual que mistura natureza retomando o mundo e restos de alta tecnologia corroídos pelo tempo.

### Diretrizes de arte

- **Tamanho de tile:** 16×16.
- **Paleta:** limitada e consistente. Tons terrosos e verdes para o mundo atual; ciano, branco e metálico para a tecnologia antiga.
- **Contraste visual:** o que é antigo deve parecer "de outro mundo", liso e geométrico, ao lado do que é feito à mão, irregular e rústico.
- **Identidade por cultura:** cada cultura tem materiais, roupas e símbolos próprios, reconhecíveis à distância.
- **Legibilidade:** colonos, ameaças e itens importantes precisam ser identificáveis de relance.

### Fluxo de trabalho

- Sprites e animações no Aseprite, exportados como sprite sheets.
- Importação no Godot com o plugin de importação do Aseprite, ou por sprite sheets com arquivo de dados.

### Áudio

- Trilha ambiente calma, com instrumentos acústicos misturados a sons sintéticos distorcidos.
- Variação por cultura e por estado (calma, tensão, ataque).
- Sons da tecnologia antiga devem soar estranhos e ligeiramente ameaçadores.

## Arquitetura técnica em Godot

A regra principal é separar a simulação da apresentação. A simulação roda em "ticks" e guarda o estado do mundo; a parte visual só lê esse estado e desenha. Isso facilita salvar, carregar, acelerar o tempo e simular mapas fora da tela.

### Decisões iniciais

- **Motor:** Godot 4, com GDScript no começo. C# fica para depois, se o desempenho exigir.
- **Mapa:** `TileMapLayer`, com camadas separadas para terreno, construções e objetos.
- **Tempo:** ticks fixos de simulação, com velocidades 1×, 3× e 6× e pausa, como no RimWorld (teclas 1 a 3 e Espaço).
- **Janela:** abre maximizada; F11 alterna a tela cheia. A tela base de 640×360 cresce em escala inteira e ocupa a janela toda, mostrando mais mapa nas sobras.
- **Caminhos:** `AStarGrid2D` para movimentação na grade.
- **IA dos colonos:** Utility AI, em que cada tarefa recebe uma pontuação com base em necessidades, habilidades e prioridades, e o colono escolhe a maior.
- **Dados:** itens, construções, traços e tecnologias definidos como `Resource` (`.tres`), para adicionar conteúdo sem mexer em código.
- **Salvamento:** livre, como no RimWorld, podendo salvar e voltar a qualquer momento. O estado da simulação é serializado inteiro; nada visual é salvo.

### Sistemas principais

- Mundo e mapa (grade, tiles, zonas)
- Colonos (necessidades, humor, habilidades, traços, relações)
- Tarefas e trabalho (fila de tarefas, prioridades)
- Construção e produção (receitas, estações, estoque)
- Pesquisa (artefatos, níveis de compreensão)
- Eventos e IA (personalidade, atenção, avisos)
- Facções e diplomacia
- Mapa-mundi retangular em hexágonos gerado por seed, expedições e transporte
- Interface (painéis, alertas, seleção, ordens)
- Rádio e missões (frequências, interceptação, transmissão)

## Roadmap e MVP

O primeiro marco é um MVP jogável com o núcleo do RimWorld: colonos sobrevivendo numa base. Tudo o mais entra depois que esse núcleo for divertido.

### Objetivo do MVP

Provar que o núcleo é divertido: **de 2 a 5 colonos sobrevivendo 30 dias** numa região de 128×128 tiles, com construção, produção, pesquisa simples, uma ruína e uma ameaça. Se esse núcleo não for divertido, nenhum sistema extra vai salvar o jogo.

### O que entra e o que fica de fora

| Sistema | Dentro do MVP | Fora do MVP |
| --- | --- | --- |
| Mapa | 128×128 gerado por seed; 1 bioma (floresta temperada), com uma pequena montanha e um rio | Mapa-mundi, hexágonos, áreas liberáveis |
| Tempo | Ticks, dia e noite, velocidades 1×, 3×, 6× e pausa (como no RimWorld); temperatura fixa amena | Estações, clima, temperatura variável |
| Colonos | Escolha de 2 a 5 com sorteio; 6 habilidades; atributo Força; 8 traços; afinidades | Outras 10 habilidades, fobias, histórias completas |
| Necessidades | Fome, sono, humor | Lazer, convívio, temperatura, doenças |
| IA dos colonos | Camadas de decisão, quadro de tarefas, reservas, divisão de tarefas, painel "por quê" | Chefes de equipe, ensino, conversas complexas |
| Rotina | Grade de prioridades; agenda com Dormir, Trabalhar e Livre | Estudo, Ritual, calendário |
| Construção | Paredes de madeira e pedra, porta, piso de madeira, cama rústica, fogueira, mesa | Defesas, muralhas, pontes |
| Produção | Bancada de produção (rústica) e bancada de cozinha, com fila "fazer até X" | Níveis, anexos, outras bancadas |
| Armazenamento | Caixote, baú rústico, pátio de materiais; painel com totais e busca | Metas, tranca, ligação com bancadas |
| Inventário | Carga por peso; espaços Camisa, Calça e Mão | Outros 5 espaços |
| Pesquisa | Pontos de Prática e Vestígio; Mesa de estudos; 6 pesquisas | Relato, Cultura, gatilhos de ramos |
| Exploração | 1 ruína pequena no mapa, com 3 salas e 1 artefato | Expedições, rotas, eventos de viagem |
| Ameaça | Ataque de saqueadores com aviso visual e pontos de ameaça; IA BALANÇA fixa | Outras IAs, o Mundo, criaturas, rádio |
| Combate | Corpo a corpo e arco; convocar colonos; ferimentos; morte permanente | Cobertura avançada, defesas automáticas |
| Cultura | Não entra | Tendência, Assembleia |
| Sistema | Salvar e carregar a qualquer momento | — |
| Arte | Tiles e sprites provisórios em 16×16, com a paleta final | Arte final, animações completas |
| Áudio | Não entra | Trilha e efeitos |

### Conteúdo exato do MVP

- **Habilidades:** Construção, Mineração, Cultivo, Cozinha, Artesanato, Corpo a corpo.
- **Traços:** Esforçado, Preguiçoso, Otimista, Pessimista, Curioso, Forte, Glutão, Covarde.
- **Recursos:** madeira, pedra bruta, blocos de pedra, fibra, carne crua, vegetal, frutas silvestres, refeição simples, sucata.
- **Receitas:** refeição simples, abater animal pequeno, faca de pedra, machado de pedra, lança de madeira, arco, flechas, blocos de pedra, cama rústica.
- **Pesquisas:** Ferramentas de pedra, Bancada de cozinha, Alvenaria de pedra, Armazenamento, Armas primitivas, Mesa de análise.
- **Animais:** 2 espécies caçáveis (um pequeno, um grande) e 1 predador.
- **Ameaça:** saqueadores com lança e arco.

### Interface do MVP

- Barra de colonos no topo, com retrato e alertas.
- Ficha do colono: necessidades, humor, habilidades, traços, equipamento e inventário.
- Grade de prioridades de trabalho e agenda simples.
- Menu de construção e ordens (cortar, minerar, colher, caçar).
- Painel de bancada com fila de pedidos.
- Painel de armazenamento simples e painel de pesquisa.
- Painel "por quê" de cada colono.
- Controles de tempo, alertas e mensagens de evento.

### Marcos de desenvolvimento

| Marco | Conteúdo | Pronto quando |
| --- | --- | --- |
| M0. Fundação | Projeto no Godot (640×360, escala inteira), camadas de tiles, câmera com zoom fixo, ticks, velocidades, geração do mapa por seed | Um mapa 128×128 aparece igual com a mesma seed |
| M1. Um colono vivo | Movimento, caminhos, seleção, ordem de mover, fome e sono, comer frutas e dormir no chão | Um colono sobrevive sozinho por 3 dias de jogo |
| M2. Quadro de tarefas | Designações (cortar, minerar, colher), Carregar, reservas, divisão de tarefas, grade de prioridades | 3 colonos dividem um trabalho sem conflito |
| M3. Construção e armazenamento | Plantas de construção, entrega de materiais, contêineres, painel simples | Os colonos erguem uma casa e guardam tudo em contêineres |
| M4. Produção e comida | Bancadas, receitas, fila "fazer até X", cozinhar, abater, refeições | A comida vem de caça e cozinha, sem intervenção constante |
| M5. Colonos completos | Habilidades, XP, traços, humor, agenda, ficha, inventário e equipamento | Dois colonos com traços diferentes se comportam de forma visivelmente diferente |
| M6. Pesquisa e ruína | Pontos, Mesa de estudos, 6 pesquisas, ruína com artefato | Explorar a ruína libera uma pesquisa |
| M7. Ameaça | Aviso, saqueadores, combate, ferimentos, morte permanente, recuperação | Um ataque é desafiador mas sobrevivível com preparação |
| M8. Fechamento | Salvar e carregar, alertas, painel "por quê", ajustes de balanceamento | Uma partida de 30 dias roda do começo ao fim |

### Critérios de sucesso

- Uma partida de 30 dias com 5 colonos roda a 3× sem travar, a 60 quadros por segundo.
- Quem joga entende por que cada colono faz o que faz.
- Cada partida gera pelo menos uma situação emergente marcante (briga, fome, ataque difícil).
- Testadores pedem "só mais um dia".
- Salvar e carregar restaura o estado exatamente.

### Riscos e como reduzir

| Risco | Como reduzir |
| --- | --- |
| IA dos colonos confusa ou lenta | Começar pelo M2, com o painel "por quê" desde cedo e orçamento de 2 ms medido |
| Caminhos pesados no mapa | Regiões por chunk e recálculo só quando algo muda |
| Escopo crescendo | Tudo que não está na tabela acima vai para uma lista de "depois do MVP" |
| Arte atrasando o código | Sprites provisórios com o tamanho e a paleta finais |

### Fases seguintes

1. **Fase 1, profundidade da colônia:** mais traços, relações, salas com qualidade, medicina, crises de humor.
2. **Fase 2, pesquisa e produção:** níveis de compreensão, camadas de produção, energia.
3. **Fase 3, mundo:** mapa-mundi, rádio e missões, expedições, transporte, locais exploráveis, fragmentos de lore.
4. **Fase 4, clãs:** facções, diplomacia, entreposto de comércio, guerra.
5. **Fase 5, culturas e IA:** formação cultural completa (tendência, Assembleia, matizes e crises de identidade), personalidades e medidor de atenção da IA, sistema de avisos e prevenção.
6. **Fase 6, objetivo:** arco do Arquivo e os finais.

Cada fase deve terminar com uma versão jogável, testada antes de seguir.

## Decisões e questões em aberto

### Decisões tomadas

| Tema | Decisão |
| --- | --- |
| Nomes das culturas | Enraizados, Remendadores e Herdeiros |
| Causa do colapso | Combinação de clima, pandemia e guerra pelo mundo |
| Tile | 16×16 |
| Combate | Tempo real com pausa (RimWorld) + defesas construídas (Factorio) |
| Mapa-mundi | Planeta fictício, retangular, em hexágonos, gerado por seed a cada jogo |
| Narrador | Substituído pela IA, com personalidades que definem a dificuldade |
| Voz da IA | Sem áudio por enquanto; a comunicação evolui com o contato |
| Salvamento | Livre, podendo voltar a qualquer momento |
| Transporte | Terrestre e marítimo; voo só no fim da progressão |
| Missões | Sistema de rádio |
| Nome da IA no jogo | As pessoas a chamam de "o Mundo" |
| Colonos iniciais | De 2 a 5, escolhidos pelo jogador |
| Personalidades da IA | JARDIM, BALANÇA, CEIFA e ECO |
| Morte de colonos | Permanente |
| Minas | Só alocação de colono, sem níveis visíveis |
| Rotas de viagem | Segura, média e desconhecida; só para lugares conhecidos |
| Início em território de clã | Começa em conflito direto com o clã |
| Nome do jogo | ENDSTART |
| Região local | Começa com 128×128 tiles; máximo de 256×256 |
| Tamanhos de mundo | 80×50, 120×75 e 160×100 hexágonos (revisar após testes) |
| Porte da comunidade | Assentamento, acampamento, vila e povoado (limite) |
| Eventos de viagem | Texto com opções primeiro; tempo real só quando dá errado |
| Equipamento | Chapéu, camisa (inclui casaco), armadura, calça, sapatos, mochila, cinto e mão |
| Cultura | Formada durante o jogo por uso, pesquisa e escolhas; assumida na Assembleia |
| Pesquisa | Pontos gerados por ações (Prática, Vestígio, Relato, Cultura); ramos liberados por gatilhos; liberação imediata na Mesa de estudos |
| Bancadas | Cozinha única (abate e comida); bancada de produção para o básico; níveis e anexos |
| Armazenamento | Tudo em contêineres com espaços; chão só temporário; painel de armazenamento com metas e busca |

### Questões em aberto

- [ ] Validar em testes os números de Balanceamento e cálculos
- [ ] Validar a raridade de perfis e o teto de 70 na soma das habilidades
- [ ] Lista completa de infâncias, vidas adultas e traços
- [ ] Ajustar os tamanhos de mundo depois dos testes
- [ ] Validar o ritmo de pontos de pesquisa (8 a 12 por dia no início)
- [ ] Completar a árvore de pesquisa com os níveis IV e V de todos os ramos
- [ ] Lista completa de receitas e valores dos itens
