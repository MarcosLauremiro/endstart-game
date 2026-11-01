class_name DaylightView
extends CanvasModulate
## Escurece o mapa à noite pela luz do Daylight. Só afeta o mundo (camada 0): a interface fica
## numa CanvasLayer própria e não escurece.

## Cor do mapa na noite mais escura (azulada, para ainda dar para ver o que acontece).
const NIGHT_TINT := Color(0.32, 0.36, 0.55)


func show_light(light: float) -> void:
	color = NIGHT_TINT.lerp(Color.WHITE, light)
