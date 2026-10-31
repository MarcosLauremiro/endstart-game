class_name BuildMenu
extends PanelContainer
## Menu de construção (GDD > Interface: aba Construir). Lista as estruturas com o custo;
## escolher uma liga o modo de colocação na cena principal.

signal structure_selected(def: StructureDef)


func _ready() -> void:
	var column := VBoxContainer.new()
	add_child(column)
	var title := Label.new()
	title.text = "Construir (B) — escolha e clique ou arraste no mapa"
	title.add_theme_color_override("font_color", UiTheme.COMMUNITY)
	column.add_child(title)
	for def in Defs.structures():
		var button := Button.new()
		button.text = "%s — %s, %s h" % [def.display_name, def.cost_text(), _hours(def.work_hours)]
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.focus_mode = Control.FOCUS_NONE
		button.tooltip_text = _placement_hint(def)
		button.pressed.connect(func() -> void: structure_selected.emit(def))
		column.add_child(button)


static func _hours(value: float) -> String:
	return ("%.1f" % value).replace(".", ",")


static func _placement_hint(def: StructureDef) -> String:
	match def.placement:
		StructureDef.Placement.AREA:
			return "Arraste para cobrir uma área"
		StructureDef.Placement.OUTLINE:
			return "Arraste para fazer o contorno de um cômodo (ou uma linha)"
	return "Clique para colocar (ocupa %d×%d)" % [def.footprint.x, def.footprint.y]
