class_name Bill
extends RefCounted
## Um pedido na fila da bancada (GDD: Pedidos inteligentes). Modos do MVP:
## fazer N vezes, fazer até ter X do produto (contando contêineres, chão e mãos) ou sempre.

enum Mode { COUNT, UNTIL, FOREVER }

const MODE_NAMES := {
	Mode.COUNT: "fazer %d",
	Mode.UNTIL: "até ter %d",
	Mode.FOREVER: "sempre",
}

var id: int
var recipe: RecipeDef
var mode: Mode = Mode.UNTIL
var target: int = 10
## Quantas vezes já foi feito (usado no modo "fazer N").
var done: int = 0
var paused: bool = false


## Argumentos opcionais: o carregamento (SaveGame) cria a instância vazia e preenche os campos.
func _init(new_id: int = 0, new_recipe: RecipeDef = null) -> void:
	id = new_id
	recipe = new_recipe
	if recipe:
		target = recipe.default_target


## Por que o pedido não deve rodar agora, ou "" se deve.
func condition_problem(state: WorldState) -> String:
	if paused:
		return "pausado"
	match mode:
		Mode.COUNT:
			if done >= target:
				return "concluído (%d de %d)" % [done, target]
		Mode.UNTIL:
			var have := state.total_count(recipe.main_product())
			if have >= target:
				return "já há %d de %d %s" % [have, target, Defs.item(recipe.main_product()).display_name.to_lower()]
	return ""


func mode_text() -> String:
	if mode == Mode.FOREVER:
		return MODE_NAMES[mode]
	return MODE_NAMES[mode] % target


## Linha do painel: receita, modo e andamento.
func describe(state: WorldState) -> String:
	var progress := ""
	match mode:
		Mode.COUNT:
			progress = " (feitos %d)" % done
		Mode.UNTIL:
			progress = " (tem %d)" % state.total_count(recipe.main_product())
	return "%s — %s%s%s" % [recipe.display_name, mode_text(), progress, " · pausado" if paused else ""]
