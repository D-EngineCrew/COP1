class_name Landmarks
extends RefCounted
## Construye los hitos de Lima con cajas y cilindros (modelos low-poly).

const RADIUS := {
	"catedral": 52.0, "plaza": 26.0, "museo": 26.0, "cruz": 42.0, "plaza_toros": 26.0, "mercado": 24.0,
	"emporio": 34.0, "estadio": 42.0, "fuente": 40.0, "parque": 30.0, "hospital": 24.0, "comisaria": 18.0,
	"tienda_chica": 12.0, "banco": 20.0, "aeropuerto": 130.0, "mall": 56.0, "huaca": 28.0, "puente": 22.0, "casa": 28.0,
}

const HOME := {"id": "home", "name": "Casa de JeanSyo", "lat": Lima.ORIGIN_LAT, "lon": Lima.ORIGIN_LON, "kind": "casa", "int": "casa"}


static func radius(kind: String) -> float:
	return RADIUS.get(kind, 20.0)


static func build(lm: Dictionary, world: Node) -> Node3D:
	var root := Node3D.new()
	root.name = "LM_" + String(lm["id"])
	root.position = Lima.to_local(lm["lat"], lm["lon"])
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(lm["id"])
	var front := 6.0
	var tall := 12.0
	match lm["kind"]:
		"casa":
			Util.box(root, Vector3(10, 3.2, 8), Vector3(0, 1.6, 0), Color(0.95, 0.8, 0.5), true)
			Util.box(root, Vector3(9, 3.0, 7), Vector3(0, 4.7, 0), Color(0.4, 0.7, 0.8), true)
			Util.box(root, Vector3(10.6, 0.4, 8.6), Vector3(0, 6.4, 0), Color(0.5, 0.25, 0.2), true)
			Util.box(root, Vector3(3.0, 2.4, 0.1), Vector3(-2.5, 1.2, 4.05), Color(0.3, 0.3, 0.35))
			Util.box(root, Vector3(1.2, 2.2, 0.1), Vector3(2.0, 1.1, 4.05), Color(0.35, 0.22, 0.12))
			front = 5.2
			tall = 8.0
		"catedral":
			Util.box(root, Vector3(60, 0.25, 60), Vector3(0, 0.12, 0), Color(0.8, 0.78, 0.7))
			Util.cyl(root, 2.5, 3.0, 1.0, Vector3(0, 0.5, 0), Color(0.6, 0.6, 0.62), true)
			Util.cyl(root, 0.4, 0.4, 3.5, Vector3(0, 2.0, 0), Color(0.7, 0.7, 0.7))
			Util.box(root, Vector3(18, 14, 30), Vector3(36, 7, 0), Color(0.9, 0.82, 0.6), true)
			Util.box(root, Vector3(5, 26, 5), Vector3(31, 13, -9), Color(0.88, 0.8, 0.58), true)
			Util.box(root, Vector3(5, 26, 5), Vector3(31, 13, 9), Color(0.88, 0.8, 0.58), true)
			Util.box(root, Vector3(60, 12, 14), Vector3(0, 6, -37), Color(0.88, 0.8, 0.62), true)
			Util.box(root, Vector3(14, 10, 50), Vector3(-37, 5, 0), Color(0.78, 0.66, 0.45), true)
			Util.box(root, Vector3(0.6, 1.0, 50), Vector3(-29.5, 7.0, 0), Color(0.45, 0.28, 0.15))
			tall = 30.0
		"plaza":
			Util.box(root, Vector3(36, 0.25, 36), Vector3(0, 0.12, 0), Color(0.78, 0.76, 0.7))
			Util.cyl(root, 0.6, 0.9, 7.0, Vector3(0, 3.5, 0), Color(0.7, 0.7, 0.72), true)
			for p in [Vector2(-13, -13), Vector2(13, -13), Vector2(-13, 13), Vector2(13, 13)]:
				Util.tree(root, Vector3(p.x, 0.2, p.y))
			tall = 10.0
		"museo":
			Util.box(root, Vector3(36, 12, 22), Vector3(0, 6, 0), Color(0.93, 0.93, 0.9), true)
			for i in range(-2, 3):
				Util.cyl(root, 0.7, 0.7, 10.0, Vector3(i * 6.0, 5, 11.8), Color(0.98, 0.98, 0.95))
			front = 13.5
		"cruz":
			Util.cyl(root, 7.0, 38.0, 24.0, Vector3(0, 12, 0), Color(0.55, 0.48, 0.34), true)
			Util.box(root, Vector3(1.2, 12, 1.2), Vector3(0, 30, 0), Color(0.95, 0.95, 0.95), false, 0.0, true)
			Util.box(root, Vector3(7, 1.2, 1.2), Vector3(0, 33, 0), Color(0.95, 0.95, 0.95), false, 0.0, true)
			tall = 40.0
		"plaza_toros":
			Util.cyl(root, 20.0, 20.0, 10.0, Vector3(0, 5, 0), Color(0.92, 0.88, 0.7), true)
			Util.cyl(root, 17.0, 17.0, 0.3, Vector3(0, 10.1, 0), Color(0.75, 0.6, 0.4))
			tall = 14.0
		"mercado":
			Util.box(root, Vector3(34, 8, 22), Vector3(0, 4, 0), Color(0.8, 0.75, 0.55), true)
			var cols := [Color(0.9, 0.3, 0.2), Color(0.2, 0.6, 0.9), Color(0.95, 0.8, 0.2), Color(0.3, 0.7, 0.4), Color(0.8, 0.4, 0.8), Color(0.95, 0.5, 0.2)]
			for i in range(6):
				Util.box(root, Vector3(5.0, 0.3, 2.5), Vector3(-14.0 + i * 5.6, 3.6, 12.3), cols[i])
			front = 13.5
		"emporio":
			Util.box(root, Vector3(46, 5, 28), Vector3(0, 2.5, 0), Color(0.82, 0.82, 0.85), true)
			var tcols := [Color(0.9, 0.35, 0.3), Color(0.3, 0.6, 0.9), Color(0.95, 0.8, 0.25), Color(0.4, 0.75, 0.5), Color(0.85, 0.5, 0.85), Color(0.95, 0.6, 0.2)]
			var i := 0
			for ix in range(-1, 2):
				for iz in range(-1, 1):
					var h := 18.0 + rng.randf() * 14.0
					Util.box(root, Vector3(12, h, 12), Vector3(ix * 15.0, 5 + h * 0.5, iz * 13.0 + 1.0), tcols[i % 6], true)
					i += 1
			front = 15.5
			tall = 32.0
		"estadio":
			Util.box(root, Vector3(50, 0.15, 30), Vector3(0, 0.08, 0), Color(0.25, 0.6, 0.25))
			Util.box(root, Vector3(60, 14, 10), Vector3(0, 7, -20), Color(0.85, 0.85, 0.88), true)
			Util.box(root, Vector3(60, 14, 10), Vector3(0, 7, 20), Color(0.85, 0.85, 0.88), true)
			Util.box(root, Vector3(10, 14, 30), Vector3(-30, 7, 0), Color(0.8, 0.8, 0.84), true)
			Util.box(root, Vector3(10, 14, 30), Vector3(30, 7, 0), Color(0.8, 0.8, 0.84), true)
			tall = 18.0
		"fuente":
			Util.box(root, Vector3(70, 0.2, 70), Vector3(0, 0.1, 0), Color(0.3, 0.6, 0.3))
			Util.box(root, Vector3(24, 0.3, 24), Vector3(0, 0.2, 0), Color(0.3, 0.6, 0.9))
			var fc := [Color(0.2, 0.9, 1.0), Color(1.0, 0.3, 0.8), Color(1.0, 0.9, 0.2), Color(0.4, 1.0, 0.4), Color(1.0, 0.5, 0.2), Color(0.6, 0.5, 1.0)]
			for i in range(6):
				var a := TAU * i / 6.0
				Util.box(root, Vector3(1.4, 4.0, 1.4), Vector3(cos(a) * 8.0, 2.2, sin(a) * 8.0), fc[i], false, 0.0, true)
			for p in [Vector2(-28, -28), Vector2(28, -28), Vector2(-28, 28), Vector2(28, 28)]:
				Util.tree(root, Vector3(p.x, 0.2, p.y))
			tall = 9.0
		"parque":
			Util.box(root, Vector3(50, 0.2, 50), Vector3(0, 0.1, 0), Color(0.32, 0.62, 0.3))
			for i in range(9):
				Util.tree(root, Vector3(rng.randf_range(-22, 22), 0.2, rng.randf_range(-22, 22)), rng.randf_range(0.8, 1.3))
			if lm["int"] != "":
				Util.box(root, Vector3(9, 5, 6), Vector3(14, 2.5, 14), Color(0.9, 0.4, 0.3), true)
				front = 0.0
			tall = 10.0
		"hospital":
			Util.box(root, Vector3(30, 16, 18), Vector3(0, 8, 0), Color(0.94, 0.94, 0.96), true)
			Util.box(root, Vector3(1.8, 6, 0.2), Vector3(0, 11, 9.1), Color(0.9, 0.1, 0.1), false, 0.0, true)
			Util.box(root, Vector3(6, 1.8, 0.2), Vector3(0, 11, 9.1), Color(0.9, 0.1, 0.1), false, 0.0, true)
			front = 10.5
			tall = 20.0
		"comisaria":
			Util.box(root, Vector3(20, 8, 14), Vector3(0, 4, 0), Color(0.45, 0.6, 0.45), true)
			Util.box(root, Vector3(20.2, 1.4, 0.3), Vector3(0, 7, 7.1), Color(0.15, 0.25, 0.6))
			Util.label(root, "POLICÍA", Vector3(0, 8.5, 7.5), Color(0.5, 0.7, 1.0), 120.0)
			front = 8.0
		"tienda_chica":
			var c := Color.from_hsv(rng.randf(), 0.5, 0.9)
			Util.box(root, Vector3(12, 6, 9), Vector3(0, 3, 0), c, true)
			Util.box(root, Vector3(12.4, 0.3, 2.5), Vector3(0, 4.4, 5.2), c.darkened(0.3))
			front = 5.5
		"banco":
			Util.box(root, Vector3(22, 11, 16), Vector3(0, 5.5, 0), Color(0.55, 0.62, 0.78), true)
			for i in range(4):
				Util.cyl(root, 0.7, 0.7, 10.0, Vector3(-8.0 + i * 5.3, 5, 8.8), Color(0.9, 0.9, 0.92))
			front = 9.8
		"aeropuerto":
			Util.box(root, Vector3(110, 12, 30), Vector3(0, 6, 0), Color(0.9, 0.9, 0.93), true)
			Util.box(root, Vector3(110, 5, 0.3), Vector3(0, 5, 15.1), Color(0.4, 0.6, 0.85))
			Util.cyl(root, 3.0, 4.0, 34.0, Vector3(65, 17, 10), Color(0.85, 0.85, 0.88), true)
			Util.box(root, Vector3(130, 0.1, 60), Vector3(0, 0.05, -45), Color(0.35, 0.35, 0.37))
			Util.box(root, Vector3(420, 0.12, 40), Vector3(0, 0.06, -110), Color(0.2, 0.2, 0.22))
			Util.box(root, Vector3(400, 0.14, 0.6), Vector3(0, 0.07, -110), Color(0.95, 0.95, 0.95))
			tall = 40.0
		"mall":
			Util.box(root, Vector3(70, 14, 44), Vector3(0, 7, 0), Color(0.78, 0.78, 0.82), true)
			Util.box(root, Vector3(70.2, 3, 0.4), Vector3(0, 11, 22.2), Color.from_hsv(rng.randf(), 0.7, 0.9))
			Util.box(root, Vector3(80, 0.1, 50), Vector3(0, 0.05, 49), Color(0.27, 0.27, 0.3))
			front = 23.5
			tall = 17.0
		"huaca":
			for i in range(4):
				Util.box(root, Vector3(40 - 8 * i, 3.5, 30 - 6 * i), Vector3(0, 1.75 + 3.5 * i, 0), Color(0.7, 0.5, 0.32).darkened(i * 0.05), true)
			tall = 16.0
		"puente":
			Util.box(root, Vector3(30, 0.5, 4.5), Vector3(0, 0.25, 0), Color(0.55, 0.3, 0.2))
			Util.box(root, Vector3(1.0, 8, 1.0), Vector3(-14, 4, 0), Color(0.55, 0.3, 0.2), true)
			Util.box(root, Vector3(1.0, 8, 1.0), Vector3(14, 4, 0), Color(0.55, 0.3, 0.2), true)
			Util.box(root, Vector3(30, 0.8, 0.8), Vector3(0, 8, 0), Color(0.55, 0.3, 0.2))
			tall = 10.0
	Util.label(root, lm["name"], Vector3(0, tall + 4.0, 0), Color(1, 0.95, 0.6))
	var iid: String = lm["int"]
	if iid != "":
		var title: String = Interiors.DATA[iid]["title"]
		var off := Vector3(14, 1.0, 17.0) if (lm["kind"] == "parque") else Vector3(0, 1.0, front)
		var door := Interactable.make(root, "Entrar: " + title, off, func(p): world.enter_interior(iid, root.global_position + off), 1.7)
		var marker := Util.box(door, Vector3(1.0, 0.12, 1.0), Vector3(0, -0.9, 0), Color(1.0, 0.85, 0.2), false, 0.0, true)
		marker.name = "Marker"
	return root
