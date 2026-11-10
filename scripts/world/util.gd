class_name Util
extends RefCounted
## Utilidades para construir geometría simple y barata (apta para móviles).

static var _mats := {}


static func mat(c: Color, emissive := false, alpha := 1.0) -> StandardMaterial3D:
	var key := "%s_%s_%s" % [c.to_html(true), emissive, alpha]
	if _mats.has(key):
		return _mats[key]
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = 1.0
	if emissive:
		m.emission_enabled = true
		m.emission = c
		m.emission_energy_multiplier = 1.6
	if alpha < 1.0:
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_mats[key] = m
	return m


static func box(parent: Node, size: Vector3, pos: Vector3, c: Color, collide := false, rot_y := 0.0, emissive := false) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.material_override = mat(c, emissive)
	mi.position = pos
	mi.rotation.y = rot_y
	parent.add_child(mi)
	if collide:
		var sb := StaticBody3D.new()
		var cs := CollisionShape3D.new()
		var bs := BoxShape3D.new()
		bs.size = size
		cs.shape = bs
		sb.add_child(cs)
		mi.add_child(sb)
	return mi


static func cyl(parent: Node, r_top: float, r_bottom: float, h: float, pos: Vector3, c: Color, collide := false) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = r_top
	cm.bottom_radius = r_bottom
	cm.height = h
	cm.radial_segments = 14
	cm.rings = 1
	mi.mesh = cm
	mi.material_override = mat(c)
	mi.position = pos
	parent.add_child(mi)
	if collide:
		var sb := StaticBody3D.new()
		var cs := CollisionShape3D.new()
		cs.shape = cm.create_trimesh_shape()
		sb.add_child(cs)
		mi.add_child(sb)
	return mi


static func sphere(parent: Node, r: float, pos: Vector3, c: Color) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = r
	sm.height = r * 2.0
	sm.radial_segments = 8
	sm.rings = 4
	mi.mesh = sm
	mi.material_override = mat(c)
	mi.position = pos
	parent.add_child(mi)
	return mi


static func tree(parent: Node, pos: Vector3, scale := 1.0) -> void:
	cyl(parent, 0.25 * scale, 0.35 * scale, 3.0 * scale, pos + Vector3(0, 1.5 * scale, 0), Color(0.4, 0.28, 0.18), true)
	sphere(parent, 1.9 * scale, pos + Vector3(0, 4.2 * scale, 0), Color(0.22, 0.5, 0.25))


static func label(parent: Node, text: String, pos: Vector3, color := Color.WHITE, far := 260.0) -> Label3D:
	var l := Label3D.new()
	l.text = text
	l.position = pos
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.font_size = 48
	l.pixel_size = 0.03
	l.outline_size = 14
	l.modulate = color
	l.visibility_range_end = far
	parent.add_child(l)
	return l


static func dist_point_segment(p: Vector2, a: Vector2, b: Vector2) -> float:
	var ab := b - a
	var len2 := ab.length_squared()
	if len2 < 0.0001:
		return p.distance_to(a)
	var t := clampf((p - a).dot(ab) / len2, 0.0, 1.0)
	return p.distance_to(a + ab * t)
