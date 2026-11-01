class_name ResourceBar
extends PanelContainer
## Topo esquerdo (GDD > Interface): recursos rápidos. Os números são somados dos itens reais
## (contêineres, chão e mãos dos colonos), nunca de um contador separado.

const _ITEMS := [&"wood", &"stone_raw", &"raw_meat", &"carrot", &"wheat", &"mushroom", &"berries"]

var _food_label: Label
var _points_label: Label
## item → Label
var _labels := {}


func _ready() -> void:
	var row := HBoxContainer.new()
	add_child(row)
	_food_label = _add_entry(row, "items/simple_meal", "Comida guardada, em dias para a colônia toda")
	for item in _ITEMS:
		_labels[item] = _add_entry(row, Defs.item(item).icon, Defs.item(item).display_name)
	_points_label = _add_entry(row, "ui/icons/tabs/research", "Pontos de pesquisa: Prática e Vestígio")


func refresh(state: WorldState) -> void:
	var daily := Balance.DAILY_FOOD_NEED * maxi(state.colonists.size(), 1)
	_food_label.text = "%.1f d" % (state.stored_nutrition() / daily)
	for item in _labels:
		_labels[item].text = str(state.total_count(item))
	_points_label.text = "%d P · %d V" % [floori(state.research.points[Research.Points.PRACTICE]),
		floori(state.research.points[Research.Points.RELIC])]


func _add_entry(parent: Control, icon_id: String, tooltip: String) -> Label:
	var icon := TextureRect.new()
	icon.texture = AssetCatalog.texture(icon_id)
	icon.tooltip_text = tooltip
	parent.add_child(icon)
	var label := Label.new()
	label.tooltip_text = tooltip
	label.mouse_filter = Control.MOUSE_FILTER_PASS
	parent.add_child(label)
	return label
