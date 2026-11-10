class_name SirenIcons
extends Control
## Nivel de búsqueda: cinco sirenas de patrullero (en vez de estrellas).


func _ready() -> void:
	custom_minimum_size = Vector2(5 * 38.0, 36.0)
	size = custom_minimum_size
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _process(_d: float) -> void:
	queue_redraw()


func _draw() -> void:
	var level := Wanted.level
	var t := Time.get_ticks_msec() / 1000.0
	var flash := int(t / 0.22) % 2 == 0
	for i in range(5):
		var x := i * 38.0
		var active := i < level
		var dome := Color(0.25, 0.25, 0.28, 0.5)
		if active:
			dome = Color(1.0, 0.15, 0.15) if (flash == (i % 2 == 0)) else Color(0.2, 0.35, 1.0)
		draw_rect(Rect2(x + 4, 22, 26, 8), Color(0.12, 0.12, 0.14, 0.9))
		draw_rect(Rect2(x + 8, 10, 18, 12), dome)
		draw_circle(Vector2(x + 17, 10), 9.0, dome)
		if active:
			draw_arc(Vector2(x + 17, 12), 15.0, PI * 1.1, PI * 1.9, 10, Color(dome.r, dome.g, dome.b, 0.6), 2.0)
