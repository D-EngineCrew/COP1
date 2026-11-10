class_name Player
extends CharacterBody3D
## JeanSyo: movimiento, cámara, armas con apuntado asistido, vehículos e interacciones.

signal died
signal interior_request(door: Node)

const WALK := 3.6
const RUN := 6.8
const JUMP := 6.2
const GRAVITY := 22.0

var humanoid: Humanoid
var cam: Camera3D
var yaw := 0.0
var pitch := 0.45
var vehicle: Vehicle = null
var health := 100.0
var max_health := 100.0
var armor := 0.0
var dead := false
var prompt_text := ""
var frozen := false
var _touch: Node = null
var _cooldown := 0.0
var _aim_t := 0.0
var _weapon_node: MeshInstance3D
var _interact_area: Area3D
var _nearby: Array = []
var _sync_t := 0.0
var _regen_t := 0.0
var _kb_prev := {}
var _col: CollisionShape3D


func _ready() -> void:
	add_to_group("player")
	humanoid = Humanoid.create(Color(0.78, 0.12, 0.15), Color(0.2, 0.28, 0.5), Color(0.8, 0.6, 0.45), Color(0.1, 0.1, 0.1))
	add_child(humanoid)
	var cs := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.35
	cap.height = 1.8
	cs.shape = cap
	cs.position.y = 0.9
	add_child(cs)
	_col = cs
	cam = Camera3D.new()
	cam.top_level = true
	cam.fov = 72.0
	cam.far = 260.0 + 140.0 * float(Game.settings["quality"])
	add_child(cam)
	cam.make_current()
	_interact_area = Area3D.new()
	_interact_area.collision_layer = 0
	_interact_area.collision_mask = 1 << 4
	var ac := CollisionShape3D.new()
	var sp := SphereShape3D.new()
	sp.radius = 2.6
	ac.shape = sp
	ac.position.y = 1.0
	_interact_area.add_child(ac)
	add_child(_interact_area)
	_interact_area.area_entered.connect(func(a): _nearby.append(a))
	_interact_area.area_exited.connect(func(a): _nearby.erase(a))
	max_health = float(Game.state.get("max_health", 100.0))
	health = float(Game.state["health"])
	armor = float(Game.state["armor"])
	_equip(String(Game.state["weapon"]))
	Game.player = self


func _exit_tree() -> void:
	if Game.player == self:
		Game.player = null


func _equip(id: String) -> void:
	if not Game.state["weapons"].has(id):
		id = "punos"
	Game.state["weapon"] = id
	if _weapon_node:
		_weapon_node.queue_free()
		_weapon_node = null
	var w := Weapons.info(id)
	if id == "punos":
		return
	var length := 0.3
	match id:
		"bate": length = 0.85
		"machete": length = 0.6
		"escopeta": length = 0.7
		"subfusil": length = 0.4
	_weapon_node = Util.box(humanoid.r_arm, Vector3(0.06, length, 0.06), Vector3(0, -0.45 - length * 0.4, 0), w["color"])


func _get_touch() -> Node:
	if _touch == null or not is_instance_valid(_touch):
		_touch = get_tree().get_first_node_in_group("touch")
	return _touch


func _kb_pressed(key: int) -> bool:
	var now := Input.is_physical_key_pressed(key)
	var was: bool = _kb_prev.get(key, false)
	_kb_prev[key] = now
	return now and not was


func _physics_process(delta: float) -> void:
	if dead or frozen:
		return
	var t := _get_touch()
	var move := Vector2.ZERO
	var fire_held := false
	var jump_p := false
	var action_p := false
	var weapon_p := false
	var brake := false
	var look := Vector2.ZERO
	if t:
		move = t.move
		look = t.consume_look()
		fire_held = t.held("fire")
		jump_p = t.just_pressed("jump")
		action_p = t.just_pressed("action")
		weapon_p = t.just_pressed("weapon")
		brake = t.held("brake")
	# teclado (pruebas en PC)
	var kb := Input.get_vector("move_left", "move_right", "move_back", "move_forward")
	if kb != Vector2.ZERO:
		move = kb
	if Input.is_physical_key_pressed(KEY_SPACE):
		fire_held = true
	jump_p = jump_p or _kb_pressed(KEY_J)
	action_p = action_p or _kb_pressed(KEY_E)
	weapon_p = weapon_p or _kb_pressed(KEY_Q)
	var s := float(Game.settings["sens"])
	yaw -= look.x * 0.006 * s
	pitch = clampf(pitch + look.y * 0.004 * s, 0.05, 1.1)
	_cooldown = maxf(_cooldown - delta, 0.0)
	_aim_t = maxf(_aim_t - delta, 0.0)
	_update_prompt()
	if action_p:
		_interact()
	if vehicle:
		_drive(delta, move, brake, look)
	else:
		_on_foot(delta, move, fire_held, jump_p, weapon_p)
	_update_camera(delta)
	_sync_t += delta
	if _sync_t > 1.0:
		_sync_t = 0.0
		save_state()
	if health < max_health and health > 0.0:
		_regen_t += delta
		if _regen_t > 12.0:
			health = minf(health + delta * 0.6, max_health)


func _on_foot(delta: float, move: Vector2, fire_held: bool, jump_p: bool, weapon_p: bool) -> void:
	var cam_fwd := Vector3(-sin(yaw), 0, -cos(yaw))
	var cam_right := Vector3(cos(yaw), 0, -sin(yaw))
	var dir := cam_right * move.x + cam_fwd * move.y
	var mag := clampf(move.length(), 0.0, 1.0)
	var spd := (RUN if mag > 0.85 else WALK) * mag
	velocity.x = dir.x * (spd / maxf(mag, 0.01)) if mag > 0.01 else move_toward(velocity.x, 0.0, 30.0 * delta)
	velocity.z = dir.z * (spd / maxf(mag, 0.01)) if mag > 0.01 else move_toward(velocity.z, 0.0, 30.0 * delta)
	if is_on_floor():
		velocity.y = -1.0
		if jump_p:
			velocity.y = JUMP
	else:
		velocity.y -= GRAVITY * delta
	move_and_slide()
	if mag > 0.05:
		var target := atan2(-dir.x, -dir.z)
		humanoid.rotation.y = lerp_angle(humanoid.rotation.y, target, clampf(delta * 14.0, 0.0, 1.0))
	humanoid.aiming = _aim_t > 0.0 and not Weapons.info(String(Game.state["weapon"]))["melee"]
	humanoid.animate(delta, Vector2(velocity.x, velocity.z).length())
	if weapon_p:
		_equip(Weapons.next_owned(String(Game.state["weapon"])))
		Game.notify(Weapons.info(String(Game.state["weapon"]))["name"])
	if fire_held:
		_fire()


func _drive(delta: float, move: Vector2, brake: bool, look: Vector2) -> void:
	if vehicle == null or not is_instance_valid(vehicle):
		vehicle = null
		return
	vehicle.drive(move.y, move.x, brake)
	global_position = vehicle.global_position
	if absf(vehicle.speed) > 3.0 and look.length() < 0.5:
		var f := vehicle.forward()
		var ty := atan2(-f.x, -f.z)
		if vehicle.speed < 0.0:
			ty += PI
		yaw = lerp_angle(yaw, ty, clampf(delta * 1.8, 0.0, 1.0))
	if vehicle.wreck:
		_leave_vehicle()


func _update_camera(delta: float) -> void:
	var base := vehicle.global_position if vehicle else global_position
	var target := base + Vector3.UP * (1.9 if vehicle else 1.6)
	var dist := 8.5 if vehicle else 5.0
	var dir := Vector3(sin(yaw) * cos(pitch), sin(pitch), cos(yaw) * cos(pitch))
	var want := target + dir * dist
	var q := PhysicsRayQueryParameters3D.create(target, want)
	q.exclude = [get_rid()] + ([vehicle.get_rid()] if vehicle else [])
	q.collision_mask = 1
	var hit := get_world_3d().direct_space_state.intersect_ray(q)
	if not hit.is_empty():
		want = hit["position"] + (target - want).normalized() * 0.4
	cam.global_position = cam.global_position.lerp(want, clampf(delta * 14.0, 0.0, 1.0))
	if cam.global_position.distance_to(target) > 0.2:
		cam.look_at(target, Vector3.UP)


# ---------- Armas ----------
func _find_target(max_range: float, cone_deg: float) -> Node3D:
	var cam_fwd := Vector3(-sin(yaw), 0, -cos(yaw))
	var best: Node3D = null
	var best_score := INF
	for n in get_tree().get_nodes_in_group("npc"):
		if not (n is Node3D) or (n.has_method("is_dead") and n.is_dead()):
			continue
		var to: Vector3 = n.global_position - global_position
		var d := to.length()
		if d > max_range or d < 0.5:
			continue
		var ang := rad_to_deg(cam_fwd.angle_to(Vector3(to.x, 0, to.z)))
		if ang > cone_deg:
			continue
		var score := d + ang * 0.35
		if n.has_method("is_hostile") and n.is_hostile():
			score -= 10.0
		if score < best_score:
			best_score = score
			best = n
	return best


func _fire() -> void:
	if _cooldown > 0.0:
		return
	var id := String(Game.state["weapon"])
	var w := Weapons.info(id)
	_cooldown = 1.0 / float(w["rate"])
	var melee: bool = w["melee"]
	if not melee:
		var ammo := int(Game.state["weapons"].get(id, 0))
		if ammo <= 0:
			Game.notify("Sin munición")
			_cooldown = 0.5
			return
		Game.state["weapons"][id] = ammo - 1
	var target := _find_target(float(w["range"]), 55.0 if not melee else 80.0)
	var origin := global_position + Vector3.UP * 1.4
	var dir: Vector3
	if target:
		dir = ((target.global_position + Vector3.UP * 1.2) - origin).normalized()
	else:
		dir = Vector3(-sin(yaw), -0.02, -cos(yaw)).normalized()
	humanoid.rotation.y = atan2(-dir.x, -dir.z)
	_aim_t = 1.6
	humanoid.swing_arm()
	Game.broadcast_noise(global_position, float(w["loud"]), self)
	if melee:
		if target and global_position.distance_to(target.global_position) <= float(w["range"]) + 0.6:
			_hit(target, float(w["damage"]))
		return
	for i in range(int(w["pellets"])):
		var d := dir
		var sp := deg_to_rad(float(w["spread"]))
		d = d.rotated(Vector3.UP, randf_range(-sp, sp)).rotated(cam.global_transform.basis.x, randf_range(-sp, sp) * 0.5)
		var to := origin + d * float(w["range"])
		var q := PhysicsRayQueryParameters3D.create(origin + d * 0.7, to)
		q.exclude = [get_rid()] + ([vehicle.get_rid()] if vehicle else [])
		var res := get_world_3d().direct_space_state.intersect_ray(q)
		var end := to
		if not res.is_empty():
			end = res["position"]
			var col: Object = res["collider"]
			if col is Node and col.has_method("take_damage"):
				_hit(col, float(w["damage"]))
		_tracer(origin + d * 0.7, end)


func _hit(target: Object, dmg: float) -> void:
	target.take_damage(dmg, self)


func _tracer(a: Vector3, b: Vector3) -> void:
	var dist := a.distance_to(b)
	if dist < 0.5:
		return
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(0.04, 0.04, dist)
	mi.mesh = bm
	mi.material_override = Util.mat(Color(1.0, 0.9, 0.5), true)
	get_parent().add_child(mi)
	mi.global_position = (a + b) * 0.5
	mi.look_at(b, Vector3.UP)
	get_tree().create_timer(0.05).timeout.connect(mi.queue_free)


# ---------- Interacción ----------
func _nearest_vehicle() -> Vehicle:
	var best: Vehicle = null
	var bd := 4.2
	for v in get_tree().get_nodes_in_group("vehicle"):
		if v is Vehicle and not v.wreck and v.driver == null:
			var d := v.global_position.distance_to(global_position)
			if d < bd:
				bd = d
				best = v
	return best


func _nearest_interactable() -> Node:
	var best: Node = null
	var bd := INF
	for a in _nearby:
		if is_instance_valid(a) and a.has_method("interact"):
			var d: float = a.global_position.distance_to(global_position)
			if d < bd:
				bd = d
				best = a
	return best


func _update_prompt() -> void:
	if vehicle:
		prompt_text = "Bajar del vehículo"
		return
	var it := _nearest_interactable()
	if it:
		prompt_text = String(it.prompt)
		return
	var v := _nearest_vehicle()
	prompt_text = ("Subir: " + String(v.spec["name"])) if v else ""


func _interact() -> void:
	if vehicle:
		_leave_vehicle()
		return
	var it := _nearest_interactable()
	if it:
		it.interact(self)
		return
	var v := _nearest_vehicle()
	if v:
		_enter_vehicle(v)


func _enter_vehicle(v: Vehicle) -> void:
	vehicle = v
	v.enter(self, true)
	if v.get_parent() != get_parent():
		v.reparent(get_parent())
	humanoid.visible = false
	_col.disabled = true
	if v.type_id == "patrullero":
		Wanted.add_crime(25.0, v.global_position)
	elif not v.persist:
		Wanted.add_crime(4.0, v.global_position)
	Game.notify(String(v.spec["name"]))


func _leave_vehicle() -> void:
	if vehicle == null:
		return
	var pos := vehicle.leave()
	vehicle = null
	global_position = pos
	humanoid.visible = true
	_col.disabled = false
	velocity = Vector3.ZERO


func eject_from_vehicle() -> void:
	if vehicle:
		_leave_vehicle()


# ---------- Vida ----------
func take_damage(amount: float, attacker: Node = null) -> void:
	if dead:
		return
	_regen_t = 0.0
	var a := minf(armor, amount * 0.6)
	armor -= a
	health -= amount - a
	if health <= 0.0:
		health = 0.0
		_die()


func heal(v: float) -> void:
	health = minf(health + v, max_health)


func _die() -> void:
	dead = true
	if vehicle:
		_leave_vehicle()
	humanoid.visible = true
	humanoid.fall()
	died.emit()


func revive_at(pos: Vector3) -> void:
	dead = false
	health = max_health
	armor = 0.0
	humanoid.fallen = false
	humanoid.rotation = Vector3.ZERO
	humanoid.position = Vector3.ZERO
	global_position = pos
	velocity = Vector3.ZERO


func save_state() -> void:
	Game.state["health"] = health
	Game.state["armor"] = armor
	Game.state["max_health"] = max_health
	var p := vehicle.global_position if vehicle else global_position
	Game.set_vec3("pos", p)
	Game.state["yaw"] = yaw
