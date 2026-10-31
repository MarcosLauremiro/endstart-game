class_name DecisionRecord
extends RefCounted
## Registro de uma decisão: o que foi escolhido, o motivo real e as alternativas descartadas.
## Alimenta o painel "por quê". O resultado é preenchido quando a ação termina.

var tick: int
var chosen: String = ""
var reason: String = ""
var rejected: PackedStringArray = []
## Vazio enquanto a ação está em andamento; depois "concluída", "falhou: …" ou "interrompida: …".
var outcome: String = ""


func _init(at_tick: int) -> void:
	tick = at_tick
