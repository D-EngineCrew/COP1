class_name CityBuilder
extends Node3D
## Genera Lima por chunks alrededor del jugador (manzanas, edificios, avenidas, hitos y autos estacionados).
## Usa MultiMesh y colisiones fusionadas para que el móvil aguante.

const CS := 128.0
const SIDEWALK := Color(0.55, 0.55, 0.52)
const ASPHALT := Color(0.2, 0.2, 0.22)
const AVENUE := Color(0.14, 0.14, 0.16)

var world: Node
var chunks := {}
var queue: Array = []
var avenue_segs: Array = []      # {a: Vector2, b: Vector2, w: float, idx: int}
var avenue_pts: Array = []       # por avenida: Array[Vector3]
var spots: Array = []            # {pos: Vector2, r: float}
var lm_nodes := {}
var lm_list: Array = []
var _mesh_box := BoxMesh.new()
var _mat_vcol := StandardMaterial3D.new()
var _rng := RandomNumberGenerator.new()
var _lm_timer := 0.0


func setup(w: Node) -> void:
	world = w
	_mesh_box.size = Vector3.ONE
	_mat_vcol.vertex_color_use_as_albedo = true
	_mat_vcol.roughness = 1.0
	_build_avenues()
	lm_list = Lima.LANDMARKS.duplicate()
	lm_list.append(Landmarks.HOME)
	for lm in lm_list:
		var p := Lima.to_local(lm["lat"], lm["lon"])
		spots.append({"pos": Vector2(p.x, p.z), "r": Landmarks.radius(lm["kind"])})
	var r := Lima.world_rect()
	var water := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(r.size.x + 4000.0, r.size.y + 4000.0)
	water.mesh = pm
	water.material_override = Util.mat(Color(0.22, 0.42, 0.55))
	water.position = Vector3(r.position.x + r.size.x * 0.5 - 1500.0, -0.5, r.position.y + r.size.y * 0.5)
	add_child(water)


func _build_avenues() -> void:
	var idx := 0
	for av in Lima.AVENUES:
		var pts: Array = []
		for p in av["pts"]:
			pts.append(Lima.to_local(p[0], p[1]))
		avenue_pts.append(pts)
		var w: float = av["w"]
		for i in range(pts.size() - 1):
			var a: Vector3 = pts[i]
			var b: Vector3 = pts[i + 1]
			var a2 := Vector2(a.x, a.z)
			var b2 := Vector2(b.x, b.z)
			avenue_segs.append({"a": a2, "b": b2, "w": w, "idx": idx, "seg": i})
			var d := b2 - a2
			var mid := (a2 + b2) * 0.5
			var rot := atan2(-d.y, d.x)
			Util.box(self, Vector3(d.length() + w * 0.5, 0.1, w), Vector3(mid.x, 0.11, mid.y), AVENUE, false, rot)
			Util.box(self, Vector3(d.length() + w * 0.3, 0.02, 0.35), Vector3(mid.x, 0.17, mid.y), Color(0.95, 0.8, 0.2), false, rot)
		idx += 1


func lane_path(avenue_idx: int, dir: int) -> Array:
	var pts: Array = (avenue_pts[avenue_idx] as Array).duplicate()
	if dir < 0:
		pts.reverse()
	var w: float = Lima.AVENUES[avenue_idx]["w"]
	var out: Array = []
	for i in range(pts.size()):
		var a: Vector3 = pts[maxi(i - 1, 0)]
		var b: Vector3 = pts[mini(i + 1, pts.size() - 1)]
		var d := Vector2(b.x - a.x, b.z - a.z).normalized()
		var right := Vector2(-d.y, d.x)
		var p: Vector3 = pts[i]
		out.append(Vector3(p.x + right.x * w * 0.25, 0.0, p.z + right.y * w * 0.25))
	return out


func dist_to_avenue(p: Vector2) -> float:
	var best := INF
	for s in avenue_segs:
		var d := Util.dist_point_segment(p, s["a"], s["b"]) - float(s["w"]) * 0.5
		if d < best:
			best = d
	return best


func _near_landmark(p: Vector2, margin := 0.0) -> bool:
	for s in spots:
		if p.distance_to(s["pos"]) < float(s["r"]) + margin:
			return true
	return false


func has_chunk_at(p: Vector3) -> bool:
	return chunks.has(Vector2i(floori(p.x / CS), floori(p.z / CS)))


func update_around(pos: Vector3, burst := 1) -> void:
	var pc := Vector2i(floori(pos.x / CS), floori(pos.z / CS))
	var r := Game.chunk_radius()
	for dx in range(-r, r + 1):
		for dz in range(-r, r + 1):
			var k := Vector2i(pc.x + dx, pc.y + dz)
			if not chunks.has(k) and not queue.has(k):
				queue.append(k)
	queue.sort_custom(func(a, b): return Vector2(a - pc).length_squared() < Vector2(b - pc).length_squared())
	for _i in range(burst):
		if queue.is_empty():
			break
		_build_chunk(queue.pop_front())
	for k in chunks.keys():
		if absi(k.x - pc.x) > r + 1 or absi(k.y - pc.y) > r + 1:
			chunks[k].queue_free()
			chunks.erase(k)
	queue = queue.filter(func(k): return absi(k.x - pc.x) <= r + 1 and absi(k.y - pc.y) <= r + 1)
	_update_landmarks(pos)


func preload_around(pos: Vector3) -> void:
	update_around(pos, 1)
	var guard := 0
	while not queue.is_empty() and guard < 200:
		_build_chunk(queue.pop_front())
		guard += 1
	_update_landmarks(pos, true)


func _update_landmarks(pos: Vector3, force := false) -> void:
	_lm_timer -= get_process_delta_time()
	if _lm_timer > 0.0 and not force:
		return
	_lm_timer = 1.0
	var built := 0
	for lm in lm_list:
		var id: String = lm["id"]
		var p := Lima.to_local(lm["lat"], lm["lon"])
		var d := Vector2(p.x - pos.x, p.z - pos.z).length()
		var reach := 520.0 + Landmarks.radius(lm["kind"]) * 2.0
		if d < reach and not lm_nodes.has(id) and (built < 2 or force):
			var node := Landmarks.build(lm, world)
			add_child(node)
			lm_nodes[id] = node
			built += 1
		elif d > reach + 160.0 and lm_nodes.has(id):
			lm_nodes[id].queue_free()
			lm_nodes.erase(id)


func _build_chunk(c: Vector2i) -> void:
	var origin := Vector2(c.x * CS, c.y * CS)
	var center := Vector3(origin.x + CS * 0.5, 0.0, origin.y + CS * 0.5)
	var root := Node3D.new()
	root.name = "Chunk_%d_%d" % [c.x, c.y]
	add_child(root)
	chunks[c] = root
	var land := false
	for p in [center, Vector3(origin.x, 0, origin.y), Vector3(origin.x + CS, 0, origin.y), Vector3(origin.x, 0, origin.y + CS), Vector3(origin.x + CS, 0, origin.y + CS)]:
		if Lima.is_land(p) and Lima.in_bounds(p):
			land = true
	if not land:
		return
	var ground := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(CS, CS)
	ground.mesh = pm
	ground.material_override = Util.mat(ASPHALT)
	ground.position = center
	root.add_child(ground)
	var gb := StaticBody3D.new()
	var gcs := CollisionShape3D.new()
	var gbox := BoxShape3D.new()
	gbox.size = Vector3(CS, 1.0, CS)
	gcs.shape = gbox
	gb.position = center + Vector3(0, -0.5, 0)
	gb.add_child(gcs)
	root.add_child(gb)

	var district := Lima.district_at(center)
	var st: Dictionary = Lima.STYLES[district["style"]]
	_rng.seed = hash(c)
	var road: float = st["road"]
	var n := maxi(1, roundi(CS / (float(st["block"]) + road)))
	var pitch := CS / n
	var block := pitch - road
	var floors: Array = st["floors"]
	var lot_rng: Array = st["lot"]
	var colors: Array = st["colors"]
	var density: float = st["density"]
	var b_xf: Array = []
	var b_col: Array = []
	var s_xf: Array = []
	var s_col: Array = []
	var body := StaticBody3D.new()
	root.add_child(body)
	for i in range(n):
		for j in range(n):
			var bx := origin.x + i * pitch + road * 0.5
			var bz := origin.y + j * pitch + road * 0.5
			var bc := Vector2(bx + block * 0.5, bz + block * 0.5)
			var bc3 := Vector3(bc.x, 0, bc.y)
			if not Lima.is_land(bc3) or not Lima.in_bounds(bc3):
				continue
			if not _near_landmark(bc, -8.0):
				s_xf.append(Transform3D(Basis.from_scale(Vector3(block, 0.12, block)), Vector3(bc.x, 0.06, bc.y)))
				s_col.append(SIDEWALK)
			var lw: float = _rng.randf_range(lot_rng[0], lot_rng[1])
			var nx := maxi(2, roundi(block / lw))
			var nz := maxi(2, roundi(block / lw))
			var lx := block / nx
			var lz := block / nz
			# alturas y validez de los lotes del perímetro
			var info := {}
			for ix in range(nx):
				for iz in range(nz):
					if not (ix == 0 or ix == nx - 1 or iz == 0 or iz == nz - 1):
						continue
					var lc := Vector2(bx + (ix + 0.5) * lx, bz + (iz + 0.5) * lz)
					var ok := _rng.randf() < density
					var h := float(_rng.randi_range(floors[0], floors[1])) * 3.2 + _rng.randf() * 1.2
					if ok:
						ok = Lima.is_land(Vector3(lc.x, 0, lc.y)) and not _near_landmark(lc, 4.0) and dist_to_avenue(lc) > maxf(lx, lz) * 0.6 + 1.0
					info[Vector2i(ix, iz)] = {"ok": ok, "h": h, "c": lc}
					if ok:
						var col: Color = (colors[_rng.randi() % colors.size()] as Color).lerp(Color(_rng.randf(), _rng.randf(), _rng.randf()), 0.08).darkened(_rng.randf() * 0.15)
						b_xf.append(Transform3D(Basis.from_scale(Vector3(lx - 0.8, h, lz - 0.8)), Vector3(lc.x, h * 0.5 + 0.12, lc.y)))
						b_col.append(col)
			_add_runs(body, info, nx, nz, lx, lz)
	_flush_multimesh(root, b_xf, b_col)
	_flush_multimesh(root, s_xf, s_col)
	# autos estacionados en las calles internas
	var cars := _rng.randi_range(0, 2)
	for _k in range(cars):
		if n < 2:
			break
		var line := _rng.randi_range(1, n - 1)
		var along := _rng.randf_range(origin.y + 10.0, origin.y + CS - 10.0)
		var side := 1.0 if _rng.randf() < 0.5 else -1.0
		var cx := origin.x + line * pitch + side * (road * 0.5 - 1.7)
		var p2 := Vector2(cx, along)
		if dist_to_avenue(p2) < 4.0 or _near_landmark(p2, 2.0) or not Lima.is_land(Vector3(cx, 0, along)):
			continue
		var roll := _rng.randf()
		var vt := "sedan" if roll < 0.4 else ("taxi" if roll < 0.62 else ("combi" if roll < 0.85 else "mototaxi"))
		var v := Vehicle.new().setup(vt)
		root.add_child(v)
		v.position = Vector3(cx, 0.05, along)
		v.rotation.y = 0.0 if side > 0.0 else PI
		if vt == "sedan":
			v._body.material_override = Util.mat(Color.from_hsv(_rng.randf(), 0.5, 0.75))


func _add_runs(body: StaticBody3D, info: Dictionary, nx: int, nz: int, lx: float, lz: float) -> void:
	# fusiona lotes contiguos de cada lado en un solo collider
	var sides := []
	var top: Array = []
	var bottom: Array = []
	for ix in range(nx):
		top.append(Vector2i(ix, 0))
		bottom.append(Vector2i(ix, nz - 1))
	var left: Array = []
	var right: Array = []
	for iz in range(1, nz - 1):
		left.append(Vector2i(0, iz))
		right.append(Vector2i(nx - 1, iz))
	sides = [top, bottom, left, right]
	for side in sides:
		var run: Array = []
		for k in range(side.size() + 1):
			var valid := k < side.size() and info.has(side[k]) and info[side[k]]["ok"]
			if valid:
				run.append(side[k])
			elif not run.is_empty():
				_collider_for_run(body, info, run, lx, lz)
				run = []


func _collider_for_run(body: StaticBody3D, info: Dictionary, run: Array, lx: float, lz: float) -> void:
	var minp := Vector2(INF, INF)
	var maxp := Vector2(-INF, -INF)
	var hmax := 0.0
	for k in run:
		var d: Dictionary = info[k]
		var c: Vector2 = d["c"]
		minp = Vector2(minf(minp.x, c.x - lx * 0.5), minf(minp.y, c.y - lz * 0.5))
		maxp = Vector2(maxf(maxp.x, c.x + lx * 0.5), maxf(maxp.y, c.y + lz * 0.5))
		hmax = maxf(hmax, d["h"])
	var cs := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = Vector3(maxp.x - minp.x - 0.8, hmax, maxp.y - minp.y - 0.8)
	cs.shape = bs
	cs.position = Vector3((minp.x + maxp.x) * 0.5, hmax * 0.5, (minp.y + maxp.y) * 0.5)
	body.add_child(cs)


func _flush_multimesh(root: Node3D, xfs: Array, cols: Array) -> void:
	if xfs.is_empty():
		return
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.mesh = _mesh_box
	mm.instance_count = xfs.size()
	for i in range(xfs.size()):
		mm.set_instance_transform(i, xfs[i])
		mm.set_instance_color(i, cols[i])
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm
	mmi.material_override = _mat_vcol
	root.add_child(mmi)
