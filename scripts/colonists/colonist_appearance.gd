class_name ColonistAppearance
extends RefCounted
## Aparência de um colono: só índices nas tabelas de ColonistLooks (tom de pele, estilo e cor do
## cabelo, peça e cor da roupa de cima e de baixo). É dado da simulação, então vai para o arquivo
## salvo junto com o colono; o desenho é montado pelo ColonistsView.

var skin_tone: int = 0
## Linha do estilo na folha de cabelos (hair.png).
var hair_style: int = 0
var hair_color: int = 0
## Linha da peça na folha de roupas (clothing.png): de cima (camisa, regata, casaco, top) e de baixo
## (calça, short, saia).
var top: int = 0
var top_color: int = 0
var bottom: int = ColonistLooks.FIRST_BOTTOM_ROW
var bottom_color: int = 0
