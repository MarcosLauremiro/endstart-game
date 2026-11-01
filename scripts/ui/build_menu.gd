class_name BuildMenu
extends PanelContainer
## Menu de construção (GDD > Interface: aba Construir). Lista as estruturas com o custo;
## escolher uma liga o modo de colocação na cena principal.

signal structure_selected(def: StructureDef)

## Três colunas, nome e custo em duas linhas, para o menu caber acima da barra de baixo.
const _COLUMNS := 3

var _simulation: Simulation
## StructureDef → Button
var _buttons := {}


func _ready() -> void:
	var column := VBoxContainer.new()
	add_child(column)
	var title := Label.new()
	title.text = "Construir (B) — escolha e clique ou arraste no mapa"
	title.add_theme_color_override("font_color", UiTheme.COMMUNITY)
	column.add_child(title)
	var grid := GridContainer.new()
	grid.columns = _COLUMNS
	column.add_child(grid)
	for def in Defs.structures():
		if not def.buildable:
			continue
		var button := Button.new()
		button.text = "%s\n%s · %s h" % [def.display_name, def.cost_text(), _hours(def.work_hours)]
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.focus_mode = Control.FOCUS_NONE
		button.tooltip_text = _placement_hint(def)
		button.pressed.connect(func() -> void: structure_selected.emit(def))
		grid.add_child(button)
		_buttons[def] = button


func bind(simulation: Simulation) -> void:
	_simulation = simulation
	refresh()


## Estruturas que dependem de pesquisa ficam desligadas, com o nome da pesquisa na dica.
func refresh() -> void:
	if _simulation == null:
		return
	for def in _buttons:
		var missing := _simulation.state.research.missing_for_structure(def.id)
		var button: Button = _buttons[def]
		button.disabled = missing != null
		button.tooltip_text = "Precisa da pesquisa %s" % missing.display_name if missing else _placement_hint(def)


static func _hours(value: float) -> String:
	return ("%.1f" % value).replace(".", ",")


static func _placement_hint(def: StructureDef) -> String:
	match def.placement:
		StructureDef.Placement.AREA:
			return "Arraste para cobrir uma área"
		StructureDef.Placement.OUTLINE:
			return "Arraste para fazer o contorno de um cômodo (ou uma linha)"
	return "Clique para colocar (ocupa %d×%d)" % [def.footprint.x, def.footprint.y]
