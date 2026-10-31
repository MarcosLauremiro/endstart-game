class_name CameraController
extends Camera2D
## Câmera top-down com panorâmica e níveis de zoom fixos (nunca zoom livre, conforme o GDD).

var _zoom_index: int = Balance.DEFAULT_ZOOM_INDEX


func _ready() -> void:
	_apply_zoom()


## Limita a câmera aos limites do mapa e a centraliza nele.
func set_map_bounds(map_pixels: Vector2i) -> void:
	limit_left = 0
	limit_top = 0
	limit_right = map_pixels.x
	limit_bottom = map_pixels.y
	position = Vector2(map_pixels) * 0.5


## Centraliza a câmera num tile (ex.: clique num contêiner do painel de armazém).
func focus(cell: Vector2i) -> void:
	position = (Vector2(cell) + Vector2.ONE * 0.5) * Balance.TILE_SIZE


func _process(delta: float) -> void:
	var direction := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	position += direction * Balance.CAMERA_PAN_SPEED * delta / zoom.x


func _unhandled_input(event: InputEvent) -> void:
	if not event is InputEventMouseButton or not event.pressed:
		return
	match event.button_index:
		MOUSE_BUTTON_WHEEL_UP:
			_change_zoom(1)
		MOUSE_BUTTON_WHEEL_DOWN:
			_change_zoom(-1)


func _change_zoom(step: int) -> void:
	_zoom_index = clampi(_zoom_index + step, 0, Balance.ZOOM_LEVELS.size() - 1)
	_apply_zoom()


func _apply_zoom() -> void:
	var level: float = Balance.ZOOM_LEVELS[_zoom_index]
	zoom = Vector2.ONE * level
