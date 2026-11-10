class_name Vehicle
extends CharacterBody3D
## Vehículo arcade (ligero para móviles): sedán, taxi, combi, mototaxi y patrullero.

signal destroyed(v: Vehicle)

const TYPES := {
	"auto_jean": {"name": "Sedán de JeanSyo", "size": Vector3(1.9, 0.8, 4.2), "cabin": Vector3(1.7, 0.65, 2.1), "cabin_z": 0.15, "color": Color(0.15, 0.35, 0.8),
		"vmax": 34.0, "accel": 14.0, "steer": 1.8, "hp": 320.0, "wheels": [[-0.95, 1.35], [0.95, 1.35], [-0.95, -1.35], [0.95, -1.35]]},
	"sedan": {"name": "Sedán", "size": Vector3(1.9, 0.8, 4.2), "cabin": Vector3(1.7, 0.65, 2.1), "cabin_z": 0.15, "color": Color(0.6, 0.6, 0.62),
		"vmax": 30.0, "accel": 12.0, "steer": 1.8, "hp": 280.0, "wheels": [[-0.95, 1.35], [0.95, 1.35], [-0.95, -1.35], [0.95, -1.35]]},
	"taxi": {"name": "Taxi", "size": Vector3(1.8, 0.75, 3.9), "cabin": Vector3(1.6, 0.6, 1.9), "cabin_z": 0.1, "color": Color(0.95, 0.8, 0.1),
		"vmax": 28.0, "accel": 12.0, "steer": 1.9, "hp": 260.0, "wheels": [[-0.9, 1.25], [0.9, 1.25], [-0.9, -1.25], [0.9, -1.25]]},
	"combi": {"name": "Combi", "size": Vector3(2.0, 1.5, 5.0), "cabin": Vector3(1.9, 0.6, 3.6), "cabin_z": 0.2, "color": Color(0.9, 0.9, 0.9),
		"vmax": 24.0, "accel": 8.0, "steer": 1.4, "hp": 380.0, "wheels": [[-1.0, 1.6], [1.0, 1.6], [-1.0, -1.6], [1.0, -1.6]]},
	"mototaxi": {"name": "Mototaxi", "size": Vector3(1.2, 0.9, 2.3), "cabin": Vector3(1.1, 0.5, 1.2), "cabin_z": -0.2, "color": Color(0.85, 0.2, 0.15),
		"vmax": 20.0, "accel": 9.0, "steer": 2.4, "hp": 140.0, "wheels": [[0.0, 0.9], [-0.55, -0.8], [0.55, -0.8]]},
	"patrullero": {"name": "Patrullero", "size": Vector3(1.9, 0.8, 4.3), "cabin": Vector3(1.7, 0.6, 2.0), "cabin_z": 0.1, "color": Color(0.95, 0.95, 0.97),
		"vmax": 38.0, "accel": 16.0, "steer": 2.0, "hp": 380.0, "wheels": [[-0.95, 1.4], [0.95, 1.4], [-0.95, -1.4], [0.95, -1.4]]},
}
const WHEEL_R := 0.38

var type_id := "sedan"
var spec: Dictionary
var hp := 300.0
var speed := 0.0
var throttle := 0.0
var steer := 0.0
var handbrake := false
var driver: Node3D = null
var ai_mode := "idle"          # idle | player | traffic | chase
var ai_target: Node3D = null
var path: Array = []
var path_i := 0
var path_dir := 1
var persist := false           # el auto del jugador no se borra al alejarse
var wreck := false
var siren := false
var _wheels: Array = []
var _front: Array = []
var _siren_boxes: Array = []
var _siren_t := 0.0
var _stuck_t := 0.0
var _reverse_t := 0.0
var _body: MeshInstance3D


func setup(id: String) -> Vehicle:
	type_id = id
	spec = TYPES[id]
	hp = spec["hp"]
	var s: Vector3 = spec["size"]
	var cb: Vector3 = spec["cabin"]
	var col: Color = spec["color"]
	_body = Util.box(self, s, Vector3(0, 0.3 + s.y * 0.5, 0), col)
	var cabin := Util.box(self, cb, Vector3(0, 0.3 + s.y + cb.y * 0.5, spec["cabin_z"]), col.lightened(0.1))
	Util.box(cabin, Vector3(cb.x + 0.02, cb.y * 0.5, cb.z - 0.3), Vector3(0, 0.05, 0), Color(0.12, 0.16, 0.2))
	Util.box(self, Vector3(s.x * 0.8, 0.12, 0.08), Vector3(0, 0.3 + s.y * 0.6, -s.z * 0.5), Color(1, 1, 0.8), false, 0.0, true)
	Util.box(self, Vector3(s.x * 0.8, 0.12, 0.08), Vector3(0, 0.3 + s.y * 0.6, s.z * 0.5), Color(0.9, 0.1, 0.1), false, 0.0, true)
	if id == "taxi":
		Util.box(self, Vector3(0.5, 0.18, 0.25), Vector3(0, 0.3 + s.y + cb.y + 0.1, spec["cabin_z"]), Color(1, 1, 0.5), false, 0.0, true)
	if id == "combi":
		Util.box(self, Vector3(s.x + 0.02, 0.18, s.z * 0.8), Vector3(0, 0.3 + s.y * 0.55, 0), Color(0.15, 0.55, 0.25))
	if id == "patrullero":
		Util.box(self, Vector3(s.x + 0.02, 0.22, s.z * 0.45), Vector3(0, 0.3 + s.y * 0.35, 0.2), Color(0.1, 0.25, 0.6))
		var top := 0.3 + s.y + cb.y + 0.1
		_siren_boxes.append(Util.box(self, Vector3(0.45, 0.16, 0.25), Vector3(-0.4, top, spec["cabin_z"]), Color(0.1, 0.1, 0.1)))
		_siren_boxes.append(Util.box(self, Vector3(0.45, 0.16, 0.25), Vector3(0.4, top, spec["cabin_z"]), Color(0.1, 0.1, 0.1)))
	for i in range(spec["wheels"].size()):
		var w: Array = spec["wheels"][i]
		var pivot := Node3D.new()
		pivot.position = Vector3(w[0], WHEEL_R, w[1])
		add_child(pivot)
		var spin := Node3D.new()
		pivot.add_child(spin)
		var mi := MeshInstance3D.new()
		var cm := CylinderMesh.new()
		cm.top_radius = WHEEL_R
		cm.bottom_radius = WHEEL_R
		cm.height = 0.25
		cm.radial_segments = 10
		mi.mesh = cm
		mi.material_override = Util.mat(Color(0.08, 0.08, 0.08))
		mi.rotation.z = PI / 2.0
		spin.add_child(mi)
		_wheels.append(spin)
		if w[1] > 0.0:
			_front.append(pivot)
	var cs := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = Vector3(s.x, s.y + cb.y * 0.6, s.z)
	cs.shape = bs
	cs.position = Vector3(0, 0.3 + bs.size.y * 0.5, 0)
	add_child(cs)
	floor_snap_length = 0.6
	add_to_group("vehicle")
	set_physics_process(false)
	return self


func enter(d: Node3D, as_player: bool) -> void:
	driver = d
	ai_mode = "player" if as_player else ai_mode
	set_physics_process(true)


func leave() -> Vector3:
	driver = null
	ai_mode = "idle"
	throttle = 0.0
	steer = 0.0
	return global_position + global_transform.basis.x * -2.3 + Vector3.UP * 0.4


func forward() -> Vector3:
	return -global_transform.basis.z


func take_damage(amount: float, attacker: Node = null) -> void:
	if wreck:
		return
	hp -= amount
	set_physics_process(true)
	if hp <= 0.0:
		_explode(attacker)


func _explode(attacker: Node) -> void:
	wreck = true
	siren = false
	throttle = 0.0
	if _body:
		_body.material_override = Util.mat(Color(0.07, 0.07, 0.07))
	var fx := CPUParticles3D.new()
	fx.amount = 40
	fx.lifetime = 1.2
	fx.one_shot = true
	fx.explosiveness = 0.9
	fx.direction = Vector3.UP
	fx.spread = 70.0
	fx.initial_velocity_min = 4.0
	fx.initial_velocity_max = 9.0
	fx.gravity = Vector3(0, -6, 0)
	var qm := SphereMesh.new()
	qm.radius = 0.25
	qm.height = 0.5
	qm.radial_segments = 6
	qm.rings = 3
	fx.mesh = qm
	fx.material_override = Util.mat(Color(1.0, 0.5, 0.1), true)
	fx.emitting = true
	add_child(fx)
	if driver:
		if driver.has_method("eject_from_vehicle"):
			driver.eject_from_vehicle()
		if driver.has_method("take_damage"):
			driver.take_damage(35.0, self)
		driver = null
	for grp in ["npc", "player"]:
		for n in get_tree().get_nodes_in_group(grp):
			if n is Node3D and n.global_position.distance_to(global_position) < 8.0 and n.has_method("take_damage"):
				n.take_damage(55.0, attacker)
	Game.broadcast_noise(global_position, 120.0, attacker)
	if attacker and attacker.is_in_group("player"):
		Wanted.add_crime(12.0, global_position)
	ai_mode = "idle"
	destroyed.emit(self)
	if not persist:
		get_tree().create_timer(25.0).timeout.connect(queue_free)


func drive(thr: float, st: float, hb: bool) -> void:
	throttle = thr
	steer = st
	handbrake = hb


func _physics_process(delta: float) -> void:
	if wreck:
		throttle = 0.0
		steer = 0.0
	match ai_mode:
		"traffic":
			_ai_traffic(delta)
		"chase":
			_ai_chase(delta)
	var vmax: float = spec["vmax"]
	var target := throttle * (vmax if throttle >= 0.0 else vmax * 0.35)
	if absf(throttle) > 0.01:
		var a: float = spec["accel"]
		if signf(throttle) != signf(speed) and absf(speed) > 0.5:
			a *= 2.5
		speed = move_toward(speed, target, a * delta)
	else:
		speed = move_toward(speed, 0.0, 7.0 * delta)
	if handbrake:
		speed = move_toward(speed, 0.0, 28.0 * delta)
	var sf := clampf(speed / 5.0, -1.0, 1.0)
	rotation.y -= steer * float(spec["steer"]) * sf * delta * (1.0 - clampf(absf(speed) / (vmax * 1.8), 0.0, 0.45))
	var f := forward()
	velocity.x = f.x * speed
	velocity.z = f.z * speed
	if is_on_floor():
		velocity.y = -1.0
	else:
		velocity.y -= 30.0 * delta
	move_and_slide()
	_handle_collisions()
	_animate(delta)
	if driver == null and ai_mode == "idle" and absf(speed) < 0.05 and is_on_floor():
		set_physics_process(false)


func _handle_collisions() -> void:
	for i in range(get_slide_collision_count()):
		var c := get_slide_collision(i)
		if c.get_normal().y > 0.6:
			continue
		var other := c.get_collider()
		var impact := absf(speed)
		if other is Node and other.is_in_group("npc"):
			if impact > 2.0 and other.has_method("take_damage"):
				other.take_damage(impact * 3.0, driver)
			continue
		if other is Node and other.is_in_group("player"):
			continue
		if impact > 6.0:
			take_damage((impact - 5.0) * 4.0, driver)
			if other is Vehicle:
				other.take_damage((impact - 5.0) * 3.0, driver)
			Game.broadcast_noise(global_position, 30.0, driver)
		speed *= 0.4


func _animate(delta: float) -> void:
	for w in _wheels:
		w.rotation.x -= speed * delta / WHEEL_R
	for p in _front:
		p.rotation.y = lerpf(p.rotation.y, -steer * 0.5, 0.3)
	if siren and not _siren_boxes.is_empty():
		_siren_t += delta
		var on_red := int(_siren_t / 0.15) % 2 == 0
		_siren_boxes[0].material_override = Util.mat(Color(1, 0.1, 0.1), true) if on_red else Util.mat(Color(0.1, 0.1, 0.1))
		_siren_boxes[1].material_override = Util.mat(Color(0.2, 0.3, 1.0), true) if not on_red else Util.mat(Color(0.1, 0.1, 0.1))


func _steer_to(point: Vector3) -> float:
	var local := global_transform.basis.inverse() * (point - global_position)
	if local.z > 0.0 and absf(local.x) < 2.0:
		return 1.0
	return clampf(atan2(local.x, -local.z) * 1.6, -1.0, 1.0)


func _ray_ahead(dist: float) -> bool:
	var space := get_world_3d().direct_space_state
	var from := global_position + Vector3.UP * 0.9
	var q := PhysicsRayQueryParameters3D.create(from, from + forward() * dist)
	q.exclude = [get_rid()]
	return not space.intersect_ray(q).is_empty()


func _ai_traffic(delta: float) -> void:
	if path.size() < 2:
		throttle = 0.0
		return
	var tp: Vector3 = path[path_i]
	if Vector2(tp.x - global_position.x, tp.z - global_position.z).length() < 8.0:
		path_i += path_dir
		if path_i >= path.size() or path_i < 0:
			if driver == null and not persist:
				queue_free()
			return
		tp = path[path_i]
	steer = _steer_to(tp)
	throttle = 0.0 if _ray_ahead(9.0) else 0.55
	if absf(steer) > 0.6:
		throttle = minf(throttle, 0.3)


func _ai_chase(delta: float) -> void:
	if ai_target == null or not is_instance_valid(ai_target):
		throttle = 0.0
		return
	var tp := ai_target.global_position
	var dist := global_position.distance_to(tp)
	if _reverse_t > 0.0:
		_reverse_t -= delta
		throttle = -1.0
		steer = -_steer_to(tp)
		return
	steer = _steer_to(tp)
	throttle = 1.0 if dist > 14.0 else 0.0
	if dist <= 14.0:
		handbrake = true
	else:
		handbrake = false
	if throttle > 0.0 and absf(speed) < 1.0:
		_stuck_t += delta
		if _stuck_t > 1.2:
			_stuck_t = 0.0
			_reverse_t = 1.0
	else:
		_stuck_t = 0.0
