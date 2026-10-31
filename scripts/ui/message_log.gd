class_name MessageLog
extends VBoxContainer
## Canto inferior direito (GDD > Interface): mensagens recentes que somem sozinhas.

const _MAX_VISIBLE := 5
const _LIFETIME_SECONDS := 8.0
const _OUTLINE_SIZE := 3

## Label → segundos restantes
var _remaining := {}


func _ready() -> void:
	alignment = BoxContainer.ALIGNMENT_END
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func add_message(text: String) -> void:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	label.add_theme_constant_override("outline_size", _OUTLINE_SIZE)
	label.add_theme_color_override("font_outline_color", UiTheme.PANEL_BACKGROUND)
	add_child(label)
	_remaining[label] = _LIFETIME_SECONDS
	while get_child_count() > _MAX_VISIBLE:
		var oldest := get_child(0)
		_remaining.erase(oldest)
		remove_child(oldest)
		oldest.queue_free()


func _process(delta: float) -> void:
	for label in _remaining.keys():
		_remaining[label] -= delta
		if _remaining[label] <= 0.0:
			_remaining.erase(label)
			label.queue_free()
