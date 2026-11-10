class_name MiniMap
extends Control
## Minimapa circular centrado en el jugador (la cámara apunta hacia arriba).

const RANGE := 230.0

var builder: CityBuilder
var player: Player
var _t := 0.0


func _ready() -> void:
	custom_minimum_size = Vector2(170, 170)
	size = custom_minimum_size
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _process(delta: float) -> void:
	_t += delta
	if _t > 0.06:
		_t = 0.0
		queue_redraw()


func _to_map(world_pos: Vector3, center: Vector3, rot: float) -> Vector2:
	var d := Vector2(world_pos.x - center.x, world_pos.z - center.z)
	d = d.rotated(rot) * (size.x * 0.5 / RANGE)
	return size * 0.5 + d


func _inside(p: Vector2) -> bool:
	return p.distance_to(size * 0.5) < size.x * 0.5 - 3.0


func _draw() -> void:
	if player == null or builder == null or not is_instance_valid(player):
		return
	var c := size * 0.5
	draw_circle(c, size.x * 0.5, Color(0.08, 0.1, 0.12, 0.7))
	var center := player.vehicle.global_position if player.vehicle else player.global_position
	var fwd := Vector2(-sin(player.yaw), -cos(player.yaw))
	var rot := fwd.angle_to(Vector2(0, -1))
	for s in builder.avenue_segs:
		var a := _to_map(Vector3(s["a"].x, 0, s["a"].y), center, rot)
		var b := _to_map(Vector3(s["b"].x, 0, s["b"].y), center, rot)
		if _inside(a) or _inside(b):
			draw_line(a, b, Color(0.75, 0.75, 0.8, 0.8), 3.0)
	for sp in builder.spots:
		var p := _to_map(Vector3(sp["pos"].x, 0, sp["pos"].y), center, rot)
		if _inside(p):
			draw_circle(p, 3.5, Color(1.0, 0.85, 0.3))
	for n in get_tree().get_nodes_in_group("npc"):
		if not (n is Npc) or n.is_dead():
			continue
		var p2 := _to_map(n.global_position, center, rot)
		if not _inside(p2):
			continue
		if n.role == Npc.Role.POLICE:
			draw_circle(p2, 3.0, Color(0.3, 0.5, 1.0))
		elif n.is_hostile():
			draw_circle(p2, 3.0, Color(1.0, 0.3, 0.3))
	if is_instance_valid(builder.world) and builder.world.player_car and not builder.world.player_car.wreck:
		var pc := _to_map(builder.world.player_car.global_position, center, rot)
		if _inside(pc):
			draw_rect(Rect2(pc - Vector2(3, 3), Vector2(6, 6)), Color(0.4, 0.8, 1.0))
	# jugador
	var tri := PackedVector2Array([c + Vector2(0, -8), c + Vector2(6, 6), c + Vector2(-6, 6)])
	draw_colored_polygon(tri, Color.WHITE)
	draw_arc(c, size.x * 0.5 - 1.5, 0, TAU, 48, Color(1, 1, 1, 0.6), 2.0)
