class_name Humanoid
extends Node3D
## Personaje humanoide hecho con cajas, con animación procedural de caminar.

var l_leg: Node3D
var r_leg: Node3D
var l_arm: Node3D
var r_arm: Node3D
var phase := 0.0
var aiming := false
var fallen := false


static func create(shirt: Color, pants: Color, skin := Color(0.82, 0.62, 0.46), cap: Color = Color(0, 0, 0, 0)) -> Humanoid:
	var h := Humanoid.new()
	h.l_leg = h._limb(Vector3(-0.12, 0.9, 0), Vector3(0.18, 0.9, 0.2), pants, 0.45)
	h.r_leg = h._limb(Vector3(0.12, 0.9, 0), Vector3(0.18, 0.9, 0.2), pants, 0.45)
	h.l_arm = h._limb(Vector3(-0.31, 1.48, 0), Vector3(0.14, 0.62, 0.16), shirt, 0.28)
	h.r_arm = h._limb(Vector3(0.31, 1.48, 0), Vector3(0.14, 0.62, 0.16), shirt, 0.28)
	Util.box(h, Vector3(0.46, 0.6, 0.26), Vector3(0, 1.2, 0), shirt)
	Util.box(h, Vector3(0.24, 0.26, 0.24), Vector3(0, 1.66, 0), skin)
	if cap.a > 0.0:
		Util.box(h, Vector3(0.27, 0.09, 0.27), Vector3(0, 1.82, 0), cap)
		Util.box(h, Vector3(0.27, 0.04, 0.14), Vector3(0, 1.78, -0.17), cap)
	return h


func _limb(joint: Vector3, size: Vector3, c: Color, drop: float) -> Node3D:
	var pivot := Node3D.new()
	pivot.position = joint
	add_child(pivot)
	Util.box(pivot, size, Vector3(0, -drop, 0), c)
	return pivot


func animate(delta: float, speed: float) -> void:
	if fallen:
		return
	var amt := clampf(speed / 4.0, 0.0, 1.4)
	phase += delta * (4.0 + speed * 1.6)
	var swing := sin(phase) * 0.85 * amt
	l_leg.rotation.x = swing
	r_leg.rotation.x = -swing
	l_arm.rotation.x = -swing * 0.8
	if aiming:
		r_arm.rotation.x = 1.45
	else:
		r_arm.rotation.x = swing * 0.8


func swing_arm() -> void:
	var tw := create_tween()
	tw.tween_property(r_arm, "rotation:x", 1.9, 0.08)
	tw.tween_property(r_arm, "rotation:x", 0.3, 0.14)


func fall() -> void:
	fallen = true
	var tw := create_tween()
	tw.tween_property(self, "rotation:x", -PI / 2.0, 0.35)
	tw.parallel().tween_property(self, "position:y", 0.25, 0.35)


func sit() -> void:
	l_leg.rotation.x = -1.5
	r_leg.rotation.x = -1.5
	l_arm.rotation.x = -0.8
	r_arm.rotation.x = -0.8
