class_name World
extends Node3D
## Escena principal del juego: arma el mundo, el jugador, la población, la policía y los interiores.

const NPC_TARGET := [12, 22, 34]
const TRAFFIC_TARGET := [3, 7, 11]

var builder: CityBuilder
var player: Player
var hud: Hud
var actors: Node3D
var env: Environment
var sun: DirectionalLight3D
var rain: CPUParticles3D
var player_car: Vehicle
var interior_root: Node3D
var in_interior := false
var _district := ""
var _gang := ""
var _npc_t := 0.0
var _traffic_t := 0.0
var _police_t := 0.0
var _cull_t := 0.0
var _arrest_cd := 0.0
var _last_level := 0
var _death_pending := false


func _ready() -> void:
	Game.in_game = true
	Game.paused = false
	get_tree().paused = false
	Game.dbg("Cargando Lima...")
	await get_tree().process_frame
	_setup_environment()
	Game.dbg("1/6 cielo y clima listos")
	builder = CityBuilder.new()
	add_child(builder)
	builder.setup(self)
	actors = Node3D.new()
	add_child(actors)
	Game.dbg("2/6 avenidas listas")
	await get_tree().process_frame
	var start := Game.get_vec3("pos")
	Game.state["inside"] = ""
	await builder.preload_async(start)
	Game.dbg("3/6 ciudad lista")
	player = Player.new()
	add_child(player)
	player.global_position = start
	player.yaw = float(Game.state.get("yaw", 0.0))
	player.died.connect(_on_player_died)
	Game.dbg("4/6 JeanSyo listo")
	_spawn_player_car()
	hud = Hud.new()
	add_child(hud)
	hud.setup(player, self)
	Game.dbg("5/6 interfaz lista")
	Weather.current = String(Game.state.get("weather", "nublado"))
	Weather.bind(env, sun, rain)
	Wanted.reset_from_state()
	_last_level = Wanted.level
	Wanted.level_changed.connect(_on_wanted_changed)
	Game.arrested.connect(_on_arrested)
	Game.notify("Bienvenido a COP 1, %s" % Game.state["name"])
	Game.dbg("6/6 listo")
	Game.dbg_hide(4.0)
	get_tree().create_timer(2.0).timeout.connect(func():
		if is_instance_valid(player):
			Game.dbg("pos=%s chunks=%d fps=%d" % [str(player.global_position.snapped(Vector3.ONE)), builder.chunks.size(), Engine.get_frames_per_second()])
			Game.dbg_hide(8.0))


func _exit_tree() -> void:
	Weather.unbind()
	if Wanted.level_changed.is_connected(_on_wanted_changed):
		Wanted.level_changed.disconnect(_on_wanted_changed)
	if Game.arrested.is_connected(_on_arrested):
		Game.arrested.disconnect(_on_arrested)


func _setup_environment() -> void:
	env = Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.6, 0.65, 0.72)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.7, 0.72, 0.78)
	env.ambient_light_energy = 0.8
	env.fog_enabled = true
	env.fog_density = 0.004
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	sun = DirectionalLight3D.new()
	sun.shadow_enabled = bool(Game.settings["shadows"]) and int(Game.settings["quality"]) > 0
	sun.directional_shadow_max_distance = 70.0
	add_child(sun)
	rain = CPUParticles3D.new()
	rain.amount = 400
	rain.lifetime = 1.1
	rain.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	rain.emission_box_extents = Vector3(22, 0.5, 22)
	rain.direction = Vector3(0.1, -1, 0)
	rain.spread = 3.0
	rain.initial_velocity_min = 22.0
	rain.initial_velocity_max = 26.0
	rain.gravity = Vector3.ZERO
	var qm := BoxMesh.new()
	qm.size = Vector3(0.025, 0.7, 0.025)
	rain.mesh = qm
	rain.material_override = Util.mat(Color(0.8, 0.88, 1.0, 0.6), false, 0.6)
	rain.emitting = false
	add_child(rain)


func _spawn_player_car() -> void:
	player_car = Vehicle.new().setup("auto_jean")
	player_car.persist = true
	add_child(player_car)
	player_car.global_position = Game.get_vec3("car_pos")
	player_car.rotation.y = float(Game.state.get("car_yaw", 0.0))
	player_car.destroyed.connect(_on_car_destroyed)
	Util.label(player_car, "Tu auto", Vector3(0, 3.0, 0), Color(0.5, 0.8, 1.0), 40.0)


func _on_car_destroyed(_v: Vehicle) -> void:
	Game.notify("Tu auto explotó. Lo repondrán en tu casa.")
	get_tree().create_timer(25.0).timeout.connect(func():
		if is_instance_valid(self) and is_inside_tree():
			_spawn_player_car_at_home())


func _spawn_player_car_at_home() -> void:
	Game.set_vec3("car_pos", Game.HOME_CAR)
	Game.state["car_yaw"] = 0.0
	_spawn_player_car()
	Game.notify("Tu auto está de vuelta en El Agustino")


func _process(delta: float) -> void:
	if player == null or Game.paused:
		return
	_arrest_cd = maxf(_arrest_cd - delta, 0.0)
	rain.global_position = player.cam.global_position + Vector3(0, 12, 0)
	if in_interior:
		return
	var pp := _focus_pos()
	builder.update_around(pp)
	_check_fall(pp)
	_check_location(pp)
	_npc_t -= delta
	_traffic_t -= delta
	_police_t -= delta
	_cull_t -= delta
	if _npc_t <= 0.0:
		_npc_t = 0.5
		_spawn_pedestrian(pp)
	if _traffic_t <= 0.0:
		_traffic_t = 1.2
		_spawn_traffic(pp)
	if _police_t <= 0.0:
		_police_t = 1.5
		_police_manager(pp)
	if _cull_t <= 0.0:
		_cull_t = 1.0
		_cull(pp)
	if player.vehicle == null and is_instance_valid(player_car) and not player_car.wreck:
		Game.set_vec3("car_pos", player_car.global_position)
		Game.state["car_yaw"] = player_car.rotation.y
	elif player.vehicle == player_car:
		Game.set_vec3("car_pos", player_car.global_position)
		Game.state["car_yaw"] = player_car.rotation.y


func _focus_pos() -> Vector3:
	return player.vehicle.global_position if player.vehicle else player.global_position


# ---------- Estado ----------
func _check_fall(pp: Vector3) -> void:
	if pp.y < -6.0 or not Lima.in_bounds(pp):
		player.global_position = Game.HOME_SPAWN
		player.velocity = Vector3.ZERO
		if player.vehicle:
			player.vehicle.global_position = Game.HOME_CAR
		Game.notify("Volviste a tu casa en El Agustino")


func _check_location(pp: Vector3) -> void:
	var d := Lima.district_at(pp)
	if d["name"] != _district:
		_district = d["name"]
		hud.show_location(_district)
	var g := Lima.gang_at(pp)
	var gname: String = g.get("name", "")
	if gname != _gang:
		_gang = gname
		if gname != "":
			hud.show_location("Territorio: " + gname, Color(1.0, 0.5, 0.4))


func save_game() -> void:
	player.save_state()
	if is_instance_valid(player_car):
		Game.set_vec3("car_pos", player_car.global_position)
		Game.state["car_yaw"] = player_car.rotation.y
	if Save.save_slot(Game.current_slot):
		Game.notify("Partida guardada (ranura %d)" % (Game.current_slot + 1))
	else:
		Game.notify("No se pudo guardar")


func cycle_weather() -> void:
	var i := Weather.STATES.find(Weather.current)
	var nxt: String = Weather.STATES[(i + 1) % Weather.STATES.size()]
	Weather.set_weather(nxt)
	Game.notify("Clima: " + Weather.LABELS[nxt])


# ---------- Interiores ----------
func enter_interior(id: String, _door_pos: Vector3) -> void:
	if in_interior or player.dead:
		return
	in_interior = true
	Game.state["inside"] = id
	Game.set_vec3("return_pos", player.global_position)
	builder.visible = false
	actors.visible = false
	actors.process_mode = Node.PROCESS_MODE_DISABLED
	builder.process_mode = Node.PROCESS_MODE_DISABLED
	if is_instance_valid(player_car):
		player_car.visible = false
	rain.emitting = false
	interior_root = Node3D.new()
	interior_root.position = Interiors.ORIGIN
	add_child(interior_root)
	var spawn := Interiors.build(id, interior_root, self)
	player.global_position = spawn
	player.velocity = Vector3.ZERO
	player.yaw = 0.0
	hud.set_interior(Interiors.DATA[id]["title"])


func exit_interior() -> void:
	if not in_interior:
		return
	in_interior = false
	Game.state["inside"] = ""
	if interior_root:
		interior_root.queue_free()
		interior_root = null
	builder.visible = true
	actors.visible = true
	actors.process_mode = Node.PROCESS_MODE_INHERIT
	builder.process_mode = Node.PROCESS_MODE_INHERIT
	if is_instance_valid(player_car):
		player_car.visible = true
	player.global_position = Game.get_vec3("return_pos") + Vector3(0, 0.3, 0)
	player.velocity = Vector3.ZERO
	Weather.set_weather(Weather.current, true)
	hud.set_interior("")


# ---------- Muerte y arresto ----------
func _on_player_died() -> void:
	if _death_pending:
		return
	_death_pending = true
	hud.show_death("¡CAÍSTE!")
	get_tree().create_timer(3.5).timeout.connect(_respawn_hospital)


func _respawn_hospital() -> void:
	_death_pending = false
	if not is_instance_valid(player):
		return
	if in_interior:
		exit_interior()
	var lm: Dictionary = Lima.LANDMARKS[12]
	for l in Lima.LANDMARKS:
		if l["id"] == "hospital_dosdemayo":
			lm = l
	var pos := Lima.to_local(lm["lat"], lm["lon"]) + Vector3(0, 1.0, 14.0)
	builder.preload_around(pos)
	var fee := int(int(Game.state["money"]) * 0.1)
	Game.add_money(-fee)
	Wanted.clear()
	player.revive_at(pos)
	hud.hide_death()
	Game.notify("Te atendieron en el Hospital Dos de Mayo (-S/ %d)" % fee)


func _on_arrested() -> void:
	if _arrest_cd > 0.0 or player.dead or in_interior:
		return
	_arrest_cd = 6.0
	var fee := int(int(Game.state["money"]) * 0.1)
	Game.add_money(-fee)
	Wanted.clear()
	var lm: Dictionary = Lima.LANDMARKS[0]
	for l in Lima.LANDMARKS:
		if l["id"] == "comisaria_agustino":
			lm = l
	var pos := Lima.to_local(lm["lat"], lm["lon"]) + Vector3(0, 1.0, 11.0)
	if player.vehicle:
		player.eject_from_vehicle()
	builder.preload_around(pos)
	player.global_position = pos
	player.velocity = Vector3.ZERO
	for n in get_tree().get_nodes_in_group("police"):
		n.queue_free()
	hud.show_death("ARRESTADO", 2.0)
	Game.notify("Te arrestaron. Multa: S/ %d" % fee)


func _on_wanted_changed(level: int) -> void:
	if level > 0 and _last_level == 0:
		Game.notify("¡La policía te busca!")
	if level == 0 and _last_level > 0:
		Game.notify("Te perdieron de vista")
		for v in get_tree().get_nodes_in_group("vehicle"):
			if v is Vehicle and v.has_meta("police_unit"):
				v.siren = false
				v.ai_mode = "idle" if v.driver == null else v.ai_mode
				if v.driver == null:
					get_tree().create_timer(10.0).timeout.connect(v.queue_free)
	_last_level = level


# ---------- Población ----------
func _free_spot(pos: Vector3, radius: float) -> bool:
	if not builder.has_chunk_at(pos) or not Lima.is_land(pos):
		return false
	var q := PhysicsShapeQueryParameters3D.new()
	var sp := SphereShape3D.new()
	sp.radius = radius
	q.shape = sp
	q.transform = Transform3D(Basis.IDENTITY, pos + Vector3(0, radius + 0.2, 0))
	q.collision_mask = 1
	return get_world_3d().direct_space_state.intersect_shape(q, 1).is_empty()


func _ring_point(center: Vector3, rmin: float, rmax: float) -> Vector3:
	var a := randf() * TAU
	var r := randf_range(rmin, rmax)
	return Vector3(center.x + cos(a) * r, 0.1, center.z + sin(a) * r)


func _spawn_pedestrian(pp: Vector3) -> void:
	var count := 0
	for n in get_tree().get_nodes_in_group("npc"):
		if not n.is_in_group("police"):
			count += 1
	if count >= NPC_TARGET[clampi(int(Game.settings["quality"]), 0, 2)]:
		return
	var pos := _ring_point(pp, 30.0, 85.0)
	if not _free_spot(pos, 0.5):
		return
	var g := Lima.gang_at(pos)
	var npc := Npc.new()
	if not g.is_empty() and randf() < 0.55:
		npc.setup(Npc.Role.GANG, {"gang": g})
	else:
		npc.setup(Npc.Role.CIVIL)
	actors.add_child(npc)
	npc.global_position = pos


func _spawn_traffic(pp: Vector3) -> void:
	var cars := 0
	for v in get_tree().get_nodes_in_group("vehicle"):
		if v is Vehicle and v.ai_mode == "traffic":
			cars += 1
	if cars >= TRAFFIC_TARGET[clampi(int(Game.settings["quality"]), 0, 2)]:
		return
	var cands: Array = []
	for s in builder.avenue_segs:
		var mid: Vector2 = (s["a"] + s["b"]) * 0.5
		var d := Vector2(mid.x - pp.x, mid.y - pp.z).length()
		if d > 40.0 and d < 190.0:
			cands.append(s)
	if cands.is_empty():
		return
	var s: Dictionary = cands.pick_random()
	var dir := 1 if randf() < 0.5 else -1
	var path := builder.lane_path(s["idx"], dir)
	var n := path.size()
	var seg: int = s["seg"]
	var i0 := seg if dir > 0 else (n - 1 - (seg + 1))
	if i0 < 0 or i0 + 1 >= n:
		return
	var a: Vector3 = path[i0]
	var b: Vector3 = path[i0 + 1]
	var t := randf_range(0.1, 0.9)
	var pos := a.lerp(b, t)
	pos.y = 0.3
	if not _free_spot(pos, 1.8):
		return
	var roll := randf()
	var vt := "sedan" if roll < 0.35 else ("taxi" if roll < 0.6 else ("combi" if roll < 0.85 else "mototaxi"))
	var v := Vehicle.new().setup(vt)
	actors.add_child(v)
	v.global_position = pos
	var d3 := (b - a).normalized()
	v.rotation.y = atan2(-d3.x, -d3.z)
	v.path = path
	v.path_i = i0 + 1
	v.ai_mode = "traffic"
	v.set_physics_process(true)
	if vt == "sedan":
		v._body.material_override = Util.mat(Color.from_hsv(randf(), 0.5, 0.75))


func _police_manager(pp: Vector3) -> void:
	var cops := 0
	var cars := 0
	for n in get_tree().get_nodes_in_group("police"):
		if n is Npc and not n.is_dead():
			cops += 1
	for v in get_tree().get_nodes_in_group("vehicle"):
		if v is Vehicle and v.has_meta("police_unit") and not v.wreck:
			cars += 1
	var lvl := Wanted.level
	if lvl == 0:
		if cops < 2 and randf() < 0.3:
			_spawn_cop(pp, 40.0, 90.0, false)
		return
	var want_cops := lvl * 2 + (2 if lvl >= 4 else 0)
	if cops < want_cops:
		_spawn_cop(pp, 35.0, 65.0, lvl >= 4 and randf() < 0.5)
	if lvl >= 2 and cars < lvl - 1:
		_spawn_patrol_car(pp)
	# los patrulleros llegan y bajan a los oficiales
	for v in get_tree().get_nodes_in_group("vehicle"):
		if v is Vehicle and v.has_meta("police_unit") and v.ai_mode == "chase" and not v.wreck:
			var d: float = v.global_position.distance_to(pp)
			if d < 18.0 and absf(v.speed) < 5.0:
				v.ai_mode = "idle"
				for _k in range(2):
					_spawn_cop_at(v.global_position + v.global_transform.basis.x * randf_range(-3.0, 3.0) + Vector3(0, 0.2, 0), lvl >= 4)


func _spawn_cop(pp: Vector3, rmin: float, rmax: float, swat: bool) -> void:
	var pos := _ring_point(pp, rmin, rmax)
	if not _free_spot(pos, 0.5):
		return
	_spawn_cop_at(pos, swat)


func _spawn_cop_at(pos: Vector3, swat: bool) -> void:
	var npc := Npc.new()
	npc.setup(Npc.Role.POLICE, {"swat": swat})
	actors.add_child(npc)
	npc.global_position = pos


func _spawn_patrol_car(pp: Vector3) -> void:
	var pos := _ring_point(pp, 80.0, 125.0)
	if not _free_spot(pos, 2.0):
		return
	var v := Vehicle.new().setup("patrullero")
	v.set_meta("police_unit", true)
	actors.add_child(v)
	v.global_position = pos + Vector3(0, 0.2, 0)
	v.ai_mode = "chase"
	v.ai_target = player
	v.siren = true
	v.set_physics_process(true)


func _cull(pp: Vector3) -> void:
	for n in get_tree().get_nodes_in_group("npc"):
		if n is Node3D and n.global_position.distance_to(pp) > 125.0:
			n.queue_free()
	for v in get_tree().get_nodes_in_group("vehicle"):
		if not (v is Vehicle) or v.persist or v == player.vehicle:
			continue
		if v.get_parent() == actors and v.global_position.distance_to(pp) > 240.0 and v.driver == null:
			v.queue_free()
