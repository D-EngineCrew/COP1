class_name Npc
extends CharacterBody3D
## Peatones, miembros de bandas y policías con IA por estados.
## Estados: idle, walk, flee, investigate, attack, dead.

enum Role { CIVIL, GANG, POLICE }

const WALK := 1.7
const RUN := 6.0
const GRAVITY := 22.0
const SHIRTS := [Color(0.85, 0.3, 0.25), Color(0.25, 0.5, 0.8), Color(0.9, 0.85, 0.4), Color(0.4, 0.7, 0.4), Color(0.8, 0.8, 0.8), Color(0.55, 0.3, 0.6), Color(0.95, 0.55, 0.2)]
const SKINS := [Color(0.82, 0.62, 0.46), Color(0.7, 0.5, 0.36), Color(0.6, 0.42, 0.3), Color(0.88, 0.7, 0.56)]

var role := Role.CIVIL
var swat := false
var gang: Dictionary = {}
var hp := 40.0
var state := "walk"
var weapon_id := "punos"
var brave := false
var humanoid: Humanoid
var target: Node3D = null
var _dir := Vector3.FORWARD
var _timer := 0.0
var _think := 0.0
var _cooldown := 0.0
var _flee_from := Vector3.ZERO
var _investigate_pos := Vector3.ZERO
var _witness_cd := 0.0
var _dead := false


func setup(r: Role, opts := {}) -> Npc:
	role = r
	swat = opts.get("swat", false)
	gang = opts.get("gang", {})
	var shirt: Color = SHIRTS.pick_random()
	var pants := Color(0.2, 0.22, 0.3).lerp(Color(randf(), randf(), randf()), 0.25)
	var cap := Color(0, 0, 0, 0)
	match role:
		Role.CIVIL:
			hp = 40.0
			brave = randf() < 0.15
			if brave:
				weapon_id = "bate"
			if randf() < 0.25:
				cap = Color(randf(), randf(), randf())
		Role.GANG:
			hp = 70.0
			shirt = gang.get("color", Color(0.2, 0.2, 0.2))
			cap = (gang.get("color", Color.BLACK) as Color).lightened(0.25)
			weapon_id = ["bate", "machete", "pistola", "pistola", "revolver"].pick_random()
			state = "walk"
		Role.POLICE:
			hp = 160.0 if swat else 95.0
			shirt = Color(0.1, 0.1, 0.12) if swat else Color(0.25, 0.4, 0.25)
			pants = shirt.darkened(0.15)
			cap = shirt.darkened(0.3)
			weapon_id = "subfusil" if swat else "pistola"
			add_to_group("police")
	humanoid = Humanoid.create(shirt, pants, SKINS.pick_random(), cap)
	add_child(humanoid)
	if weapon_id != "punos":
		var w := Weapons.info(weapon_id)
		var length := 0.3 if not w["melee"] else 0.6
		Util.box(humanoid.r_arm, Vector3(0.06, length, 0.06), Vector3(0, -0.45 - length * 0.4, 0), w["color"])
	var cs := CollisionShape3D.new()
	var cap_s := CapsuleShape3D.new()
	cap_s.radius = 0.32
	cap_s.height = 1.8
	cs.shape = cap_s
	cs.position.y = 0.9
	add_child(cs)
	add_to_group("npc")
	_dir = Vector3.FORWARD.rotated(Vector3.UP, randf() * TAU)
	_think = randf() * 0.3
	return self


func is_dead() -> bool:
	return _dead


func is_hostile() -> bool:
	return state == "attack"


func _player() -> Node3D:
	return Game.player if (Game.player and is_instance_valid(Game.player) and not Game.player.dead) else null


func _can_see(t: Node3D, max_dist: float) -> bool:
	var d := global_position.distance_to(t.global_position)
	if d > max_dist:
		return false
	var from := global_position + Vector3.UP * 1.5
	var to := t.global_position + Vector3.UP * 1.2
	var q := PhysicsRayQueryParameters3D.create(from, to)
	q.exclude = [get_rid()]
	q.collision_mask = 1
	var hit := get_world_3d().direct_space_state.intersect_ray(q)
	if hit.is_empty():
		return true
	var col: Object = hit["collider"]
	return col == t or (col is Vehicle and col == (t as Player).vehicle)


# ---------- Eventos ----------
func hear(pos: Vector3, source: Node) -> void:
	if _dead:
		return
	var from_player := source != null and source.is_in_group("player")
	match role:
		Role.CIVIL:
			if brave and from_player and global_position.distance_to(pos) < 10.0 and randf() < 0.5:
				_start_attack(source)
			elif state != "flee":
				_flee(pos, randf_range(4.0, 8.0))
		Role.GANG:
			if from_player and global_position.distance_to(pos) < 45.0:
				_start_attack(source)
		Role.POLICE:
			if Wanted.level == 0 and from_player and global_position.distance_to(pos) < 60.0:
				_investigate_pos = pos
				state = "investigate"
				_timer = 8.0


func take_damage(amount: float, attacker: Node = null) -> void:
	if _dead:
		return
	hp -= amount
	var by_player := attacker != null and attacker.is_in_group("player")
	if by_player:
		var pts := 0.0
		match role:
			Role.CIVIL:
				pts = 3.0 if hp > 0.0 else 8.0
			Role.POLICE:
				pts = 12.0 if hp > 0.0 else 35.0
			Role.GANG:
				pts = 0.0
		if pts > 0.0:
			_report_crime(pts)
	if hp <= 0.0:
		_die(attacker)
		return
	match role:
		Role.CIVIL:
			if brave and by_player:
				_start_attack(attacker)
			else:
				_flee(attacker.global_position if attacker else global_position, 7.0)
		_:
			if by_player:
				_start_attack(attacker)


func _report_crime(points: float) -> void:
	# la policía lo ve de cerca, o 2+ civiles testigos llaman a la policía
	var seen := false
	for p in get_tree().get_nodes_in_group("police"):
		if p is Node3D and p.global_position.distance_to(global_position) < 55.0 and not p.is_dead():
			seen = true
			break
	if not seen:
		var witnesses := 0
		for n in get_tree().get_nodes_in_group("npc"):
			if n != self and n is Npc and n.role == Role.CIVIL and not n._dead and n.global_position.distance_to(global_position) < 16.0:
				witnesses += 1
		seen = witnesses >= 2
	if seen:
		Wanted.add_crime(points, global_position)


func _die(attacker: Node) -> void:
	_dead = true
	state = "dead"
	remove_from_group("npc")
	remove_from_group("police")
	humanoid.fall()
	velocity = Vector3.ZERO
	if attacker != null and attacker.is_in_group("player"):
		var loot := 0
		match role:
			Role.CIVIL: loot = randi_range(5, 40)
			Role.GANG: loot = randi_range(40, 140)
			Role.POLICE: loot = randi_range(60, 120)
		Game.add_money(loot)
		Game.state["kills"] = int(Game.state["kills"]) + 1
		Game.notify("+S/ %d" % loot)
		if role == Role.GANG and randf() < 0.3:
			var ammo_id := "pistola"
			Weapons.give(ammo_id, 6)
	get_tree().create_timer(9.0).timeout.connect(queue_free)


func _start_attack(t: Node) -> void:
	if t is Node3D:
		target = t
		state = "attack"
		_timer = 12.0


func _flee(from: Vector3, t: float) -> void:
	state = "flee"
	_flee_from = from
	_timer = t


# ---------- Bucle ----------
func _physics_process(delta: float) -> void:
	if _dead:
		return
	_cooldown = maxf(_cooldown - delta, 0.0)
	_timer -= delta
	_think -= delta
	if _think <= 0.0:
		_think = 0.25
		_decide()
	var speed := 0.0
	match state:
		"idle":
			pass
		"walk":
			speed = WALK
		"flee":
			speed = RUN
			var away := global_position - _flee_from
			away.y = 0.0
			_dir = away.normalized() if away.length() > 0.1 else _dir
		"investigate":
			speed = WALK * 2.0
			_face_move_to(_investigate_pos)
		"attack":
			speed = _attack_move()
	if role == Role.POLICE and Wanted.level > 0 and state != "dead":
		var p := _player()
		if p:
			_police_pursue(p)
			speed = _police_speed
	_move(delta, speed)


var _police_speed := 0.0


func _decide() -> void:
	if _dead:
		return
	if state == "flee" and _timer <= 0.0:
		state = "walk"
	if (state == "walk" or state == "idle") and (_timer <= 0.0):
		_timer = randf_range(2.0, 6.0)
		if randf() < 0.25:
			state = "idle"
		else:
			state = "walk"
			_dir = Vector3.FORWARD.rotated(Vector3.UP, randf() * TAU)
	if state == "investigate" and (_timer <= 0.0 or global_position.distance_to(_investigate_pos) < 3.0):
		state = "walk"
	if state == "attack" and (_timer <= 0.0 or target == null or not is_instance_valid(target)):
		state = "walk"
		target = null
	# bandas: atacan al jugador si lo ven cerca (y es hostil por territorio)
	if role == Role.GANG and state != "attack":
		var p := _player()
		if p and _can_see(p, 22.0) and (Game.state["kills"] as int) >= 0 and randf() < 0.35:
			_start_attack(p)


func _attack_move() -> float:
	if target == null or not is_instance_valid(target):
		return 0.0
	var w := Weapons.info(weapon_id)
	var to := target.global_position - global_position
	to.y = 0.0
	var d := to.length()
	_dir = to.normalized() if d > 0.1 else _dir
	var can_see := _can_see(target, float(w["range"]) + 5.0)
	var want_range := 1.7 if w["melee"] else minf(float(w["range"]) * 0.45, 14.0)
	if can_see and d <= float(w["range"]):
		_attack_with(w, d)
	if d > want_range:
		return RUN * 0.85
	return 0.0


func _attack_with(w: Dictionary, d: float) -> void:
	if _cooldown > 0.0 or target == null:
		return
	_cooldown = 1.0 / float(w["rate"]) + (0.5 if role == Role.POLICE else 0.8)
	humanoid.swing_arm()
	if w["melee"]:
		if d <= float(w["range"]) + 0.5 and target.has_method("take_damage"):
			target.take_damage(float(w["damage"]) * 0.7, self)
		return
	var acc := clampf(0.7 - d / 60.0, 0.15, 0.6)
	var origin := global_position + Vector3.UP * 1.4
	var end := target.global_position + Vector3.UP * 1.1
	if randf() < acc and target.has_method("take_damage"):
		target.take_damage(float(w["damage"]) * 0.6, self)
	else:
		end += Vector3(randf_range(-1.5, 1.5), randf_range(-0.5, 1.0), randf_range(-1.5, 1.5))
	_tracer(origin, end)
	Game.broadcast_noise(global_position, float(w["loud"]) * 0.5, self)


func _tracer(a: Vector3, b: Vector3) -> void:
	var dist := a.distance_to(b)
	if dist < 0.5:
		return
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(0.04, 0.04, dist)
	mi.mesh = bm
	mi.material_override = Util.mat(Color(1.0, 0.7, 0.3), true)
	get_parent().add_child(mi)
	mi.global_position = (a + b) * 0.5
	mi.look_at(b, Vector3.UP)
	get_tree().create_timer(0.05).timeout.connect(mi.queue_free)


func _police_pursue(p: Node3D) -> void:
	var seen := _can_see(p, 70.0)
	if seen:
		Wanted.report_seen()
		Wanted.last_crime_pos = p.global_position
	var goal := p.global_position if seen else Wanted.last_crime_pos
	var to := goal - global_position
	to.y = 0.0
	var d := to.length()
	if d > 0.1:
		_dir = to.normalized()
	state = "attack"
	target = p
	var w := Weapons.info(weapon_id)
	if Wanted.level == 1:
		# nivel 1: intentan arrestar
		_police_speed = RUN * 0.9 if d > 1.6 else 0.0
		if d < 1.8 and seen and not (p as Player).vehicle:
			Game.arrested.emit()
		return
	var stop := minf(float(w["range"]) * 0.4, 12.0)
	_police_speed = RUN * 0.9 if d > stop else 0.0
	if seen and d <= float(w["range"]):
		_attack_with(w, d)


func _face_move_to(pos: Vector3) -> void:
	var to := pos - global_position
	to.y = 0.0
	if to.length() > 0.1:
		_dir = to.normalized()


func _move(delta: float, speed: float) -> void:
	velocity.x = _dir.x * speed
	velocity.z = _dir.z * speed
	if is_on_floor():
		velocity.y = -1.0
	else:
		velocity.y -= GRAVITY * delta
	move_and_slide()
	if speed > 0.1:
		if is_on_wall() and state in ["walk", "flee"]:
			_dir = _dir.rotated(Vector3.UP, randf_range(1.2, 2.2) * (1.0 if randf() < 0.5 else -1.0))
		humanoid.rotation.y = lerp_angle(humanoid.rotation.y, atan2(-_dir.x, -_dir.z), clampf(delta * 10.0, 0.0, 1.0))
	humanoid.aiming = state == "attack" and not Weapons.info(weapon_id)["melee"]
	humanoid.animate(delta, Vector2(velocity.x, velocity.z).length())
