class_name Interiors
extends RefCounted
## Interiores a los que se puede entrar de verdad: casa, bodega, pollería, tienda, comisaría, banco, hospital...

const ORIGIN := Vector3(0.0, 800.0, 0.0)

const DATA := {
	"casa": {"title": "Casa de JeanSyo — El Agustino", "size": Vector3(12, 3.2, 9), "floor": Color(0.55, 0.4, 0.28), "wall": Color(0.92, 0.85, 0.7), "keeper": false, "items": [
		{"name": "Cama", "pos": Vector3(-4.2, 0.3, -2.8), "size": Vector3(2.2, 0.6, 3.4), "color": Color(0.3, 0.45, 0.8), "prompt": "Dormir y guardar partida", "action": "sleep"},
		{"name": "Ventana", "pos": Vector3(0.0, 1.6, -4.3), "size": Vector3(3.0, 1.2, 0.1), "color": Color(0.6, 0.8, 1.0), "prompt": "Mirar el cielo (cambiar clima)", "action": "weather"},
		{"name": "Mesa", "pos": Vector3(3.5, 0.45, -1.5), "size": Vector3(2.4, 0.9, 1.2), "color": Color(0.5, 0.35, 0.2), "prompt": "Guardar partida", "action": "save"},
		{"name": "Sofá", "pos": Vector3(3.8, 0.4, 2.0), "size": Vector3(2.8, 0.8, 1.1), "color": Color(0.7, 0.25, 0.25), "prompt": "Descansar (+salud)", "action": "buy:health:30:0"},
	]},
	"bodega": {"title": "Bodega 'Don Lucho'", "size": Vector3(9, 3.0, 8), "floor": Color(0.6, 0.6, 0.55), "wall": Color(0.95, 0.9, 0.6), "keeper": true, "items": [
		{"name": "Gaseosa Kola", "pos": Vector3(-3.0, 0.9, -1.0), "size": Vector3(0.6, 0.6, 0.6), "color": Color(0.9, 0.7, 0.1), "prompt": "Comprar gaseosa (+10 vida) — S/ 3", "action": "buy:health:10:3"},
		{"name": "Pan con chicharrón", "pos": Vector3(-1.5, 0.9, -1.0), "size": Vector3(0.6, 0.4, 0.6), "color": Color(0.8, 0.55, 0.3), "prompt": "Comprar pan con chicharrón (+25 vida) — S/ 10", "action": "buy:health:25:10"},
		{"name": "Balas 9mm", "pos": Vector3(1.5, 0.9, -1.0), "size": Vector3(0.5, 0.3, 0.5), "color": Color(0.5, 0.5, 0.5), "prompt": "Comprar 12 balas 9mm — S/ 30", "action": "buy:ammo:pistola:12:30"},
		{"name": "Bate de Chacra", "pos": Vector3(3.0, 0.9, -1.0), "size": Vector3(0.2, 0.9, 0.2), "color": Color(0.55, 0.38, 0.2), "prompt": "Comprar Bate de Chacra — S/ 80", "action": "buy:weapon:bate:0:80"},
	]},
	"polleria": {"title": "Pollería 'El Buen Sabor'", "size": Vector3(10, 3.0, 8), "floor": Color(0.75, 0.3, 0.2), "wall": Color(0.95, 0.8, 0.3), "keeper": true, "items": [
		{"name": "1/4 de pollo", "pos": Vector3(-2.0, 0.9, -1.0), "size": Vector3(0.7, 0.3, 0.7), "color": Color(0.85, 0.55, 0.2), "prompt": "Comprar 1/4 de pollo con papas (+40 vida) — S/ 18", "action": "buy:health:40:18"},
		{"name": "Pollo entero", "pos": Vector3(0.5, 0.9, -1.0), "size": Vector3(0.9, 0.4, 0.9), "color": Color(0.8, 0.45, 0.15), "prompt": "Comprar pollo entero (salud completa) — S/ 60", "action": "buy:health:999:60"},
		{"name": "Chicha morada", "pos": Vector3(3.0, 0.9, -1.0), "size": Vector3(0.5, 0.7, 0.5), "color": Color(0.4, 0.1, 0.4), "prompt": "Comprar chicha morada (+15 vida) — S/ 6", "action": "buy:health:15:6"},
	]},
	"pizzeria": {"title": "Pizzería Kennedy", "size": Vector3(10, 3.0, 8), "floor": Color(0.3, 0.3, 0.32), "wall": Color(0.85, 0.3, 0.25), "keeper": true, "items": [
		{"name": "Pizza personal", "pos": Vector3(-1.5, 0.9, -1.0), "size": Vector3(0.8, 0.12, 0.8), "color": Color(0.9, 0.6, 0.25), "prompt": "Comprar pizza personal (+35 vida) — S/ 20", "action": "buy:health:35:20"},
		{"name": "Chicha morada", "pos": Vector3(1.5, 0.9, -1.0), "size": Vector3(0.5, 0.7, 0.5), "color": Color(0.4, 0.1, 0.4), "prompt": "Comprar chicha morada (+15 vida) — S/ 6", "action": "buy:health:15:6"},
	]},
	"tienda": {"title": "Tienda 'El Barrio' (armas y chalecos)", "size": Vector3(12, 3.2, 9), "floor": Color(0.35, 0.35, 0.38), "wall": Color(0.7, 0.75, 0.8), "keeper": true, "items": [
		{"name": "Chaleco", "pos": Vector3(-4.5, 0.9, -1.5), "size": Vector3(0.7, 0.9, 0.3), "color": Color(0.2, 0.3, 0.2), "prompt": "Comprar chaleco (+50 armadura) — S/ 150", "action": "buy:armor:50:150"},
		{"name": "Machete del Barrio", "pos": Vector3(-2.7, 0.9, -1.5), "size": Vector3(0.1, 0.8, 0.1), "color": Color(0.7, 0.72, 0.75), "prompt": "Comprar Machete del Barrio — S/ 140", "action": "buy:weapon:machete:0:140"},
		{"name": "Fierro 9mm", "pos": Vector3(-0.9, 0.9, -1.5), "size": Vector3(0.3, 0.2, 0.1), "color": Color(0.15, 0.15, 0.17), "prompt": "Comprar Fierro 9mm (+24 balas) — S/ 600", "action": "buy:weapon:pistola:24:600"},
		{"name": "Revólver Rímac", "pos": Vector3(0.9, 0.9, -1.5), "size": Vector3(0.3, 0.2, 0.1), "color": Color(0.35, 0.35, 0.38), "prompt": "Comprar Revólver Rímac (+12 balas) — S/ 900", "action": "buy:weapon:revolver:12:900"},
		{"name": "Escopeta Chalaca", "pos": Vector3(2.7, 0.9, -1.5), "size": Vector3(0.1, 0.1, 0.9), "color": Color(0.3, 0.2, 0.12), "prompt": "Comprar Escopeta Chalaca (+10 cartuchos) — S/ 1500", "action": "buy:weapon:escopeta:10:1500"},
		{"name": "Subfusil Huaylas", "pos": Vector3(4.5, 0.9, -1.5), "size": Vector3(0.1, 0.2, 0.6), "color": Color(0.1, 0.1, 0.12), "prompt": "Comprar Subfusil Huaylas (+60 balas) — S/ 2200", "action": "buy:weapon:subfusil:60:2200"},
	]},
	"comisaria": {"title": "Comisaría", "size": Vector3(11, 3.0, 8), "floor": Color(0.5, 0.52, 0.5), "wall": Color(0.55, 0.7, 0.55), "keeper": true, "items": [
		{"name": "Mostrador", "pos": Vector3(0.0, 0.5, -1.5), "size": Vector3(3.0, 1.0, 0.8), "color": Color(0.4, 0.3, 0.2), "prompt": "Pagar multa y limpiar antecedentes — S/ 300 por sirena", "action": "fine"},
	]},
	"banco": {"title": "Banco Central de la Gente", "size": Vector3(14, 3.5, 10), "floor": Color(0.7, 0.7, 0.72), "wall": Color(0.45, 0.55, 0.7), "keeper": true, "items": [
		{"name": "Bóveda", "pos": Vector3(0.0, 1.2, -4.3), "size": Vector3(3.0, 2.4, 0.4), "color": Color(0.3, 0.3, 0.32), "prompt": "Asaltar la bóveda (¡sube la búsqueda!)", "action": "rob"},
	]},
	"hospital": {"title": "Hospital Dos de Mayo", "size": Vector3(12, 3.2, 9), "floor": Color(0.85, 0.88, 0.9), "wall": Color(0.95, 0.95, 0.97), "keeper": true, "items": [
		{"name": "Camilla", "pos": Vector3(0.0, 0.4, -2.0), "size": Vector3(1.0, 0.8, 2.2), "color": Color(0.9, 0.3, 0.3), "prompt": "Curación completa — S/ 50", "action": "buy:health:999:50"},
	]},
	"gimnasio": {"title": "Gimnasio 'Fuerza Peruana'", "size": Vector3(11, 3.2, 8), "floor": Color(0.2, 0.2, 0.22), "wall": Color(0.7, 0.2, 0.2), "keeper": true, "items": [
		{"name": "Pesas", "pos": Vector3(0.0, 0.3, -2.5), "size": Vector3(1.6, 0.6, 0.6), "color": Color(0.5, 0.5, 0.55), "prompt": "Entrenar (+10 vida máxima) — S/ 100", "action": "train"},
	]},
	"museo": {"title": "Museo de Arte de Lima", "size": Vector3(14, 4.0, 10), "floor": Color(0.8, 0.78, 0.72), "wall": Color(0.95, 0.95, 0.95), "keeper": false, "items": [
		{"name": "Placa", "pos": Vector3(-3.0, 1.3, -4.3), "size": Vector3(1.4, 0.9, 0.1), "color": Color(0.9, 0.8, 0.3), "prompt": "Leer la placa del museo", "action": "info:Lima fue fundada en 1535 por Francisco Pizarro. Hoy es una de las ciudades más grandes de Sudamérica."},
		{"name": "Placa", "pos": Vector3(3.0, 1.3, -4.3), "size": Vector3(1.4, 0.9, 0.1), "color": Color(0.9, 0.8, 0.3), "prompt": "Leer la placa del museo", "action": "info:En Lima casi nunca llueve fuerte, pero la garúa cubre la ciudad buena parte del año."},
	]},
}


## Construye el interior bajo `root` y devuelve la posición global de aparición.
static func build(id: String, root: Node3D, world: Node) -> Vector3:
	var d: Dictionary = DATA.get(id, DATA["bodega"])
	var s: Vector3 = d["size"]
	var wall: Color = d["wall"]
	Util.box(root, Vector3(s.x, 0.3, s.z), Vector3(0, -0.15, 0), d["floor"], true)
	Util.box(root, Vector3(s.x, 0.3, s.z), Vector3(0, s.y + 0.15, 0), wall.darkened(0.2), true)
	Util.box(root, Vector3(s.x, s.y, 0.3), Vector3(0, s.y * 0.5, -s.z * 0.5 - 0.15), wall, true)
	Util.box(root, Vector3(s.x, s.y, 0.3), Vector3(0, s.y * 0.5, s.z * 0.5 + 0.15), wall, true)
	Util.box(root, Vector3(0.3, s.y, s.z), Vector3(-s.x * 0.5 - 0.15, s.y * 0.5, 0), wall, true)
	Util.box(root, Vector3(0.3, s.y, s.z), Vector3(s.x * 0.5 + 0.15, s.y * 0.5, 0), wall, true)
	var light := OmniLight3D.new()
	light.position = Vector3(0, s.y - 0.4, 0)
	light.omni_range = maxf(s.x, s.z) * 1.3
	light.light_energy = 1.6
	root.add_child(light)
	Util.label(root, d["title"], Vector3(0, s.y - 0.5, -s.z * 0.5 + 0.4), Color(1, 1, 0.8), 40.0)
	if d["keeper"]:
		var h := Humanoid.create(Color(0.9, 0.9, 0.9), Color(0.25, 0.25, 0.3))
		h.position = Vector3(0, 0, -s.z * 0.5 + 1.2)
		root.add_child(h)
	for it in d["items"]:
		var b := Util.box(root, it["size"], it["pos"], it["color"], true)
		Util.label(b, it["name"], Vector3(0, it["size"].y * 0.5 + 0.5, 0), Color.WHITE, 12.0)
		var action: String = it["action"]
		Interactable.make(root, it["prompt"], it["pos"] + Vector3(0, 0, 0.9), func(p): apply(action, p, world), 1.8)
	var door_pos := Vector3(0, 1.0, s.z * 0.5 - 0.8)
	Interactable.make(root, "Salir", door_pos, func(_p): world.exit_interior(), 1.6)
	Util.box(root, Vector3(1.4, 2.2, 0.1), Vector3(0, 1.1, s.z * 0.5 - 0.05), Color(0.35, 0.22, 0.12))
	return root.global_position + Vector3(0, 0.3, s.z * 0.5 - 2.4)


static func apply(action: String, player: Node, world: Node) -> void:
	var parts := action.split(":")
	var p := player as Player
	match parts[0]:
		"buy":
			var price := int(parts[parts.size() - 1])
			if int(Game.state["money"]) < price:
				Game.notify("No te alcanza el dinero")
				return
			match parts[1]:
				"health":
					if price > 0 and p.health >= p.max_health:
						Game.notify("Ya tienes la salud completa")
						return
					p.heal(float(parts[2]))
				"armor":
					p.armor = minf(p.armor + float(parts[2]), 100.0)
				"ammo":
					if not Game.state["weapons"].has(parts[2]):
						Game.notify("Primero necesitas esa arma")
						return
					Weapons.give(parts[2], int(parts[3]))
				"weapon":
					Weapons.give(parts[2], int(parts[3]))
					Game.notify("Compraste: " + String(Weapons.info(parts[2])["name"]))
			Game.add_money(-price)
			if price > 0:
				Game.notify("-S/ %d" % price)
		"sleep":
			Game.state["time"] = fmod(float(Game.state["time"]) + 8.0, 24.0)
			p.heal(999.0)
			world.save_game()
			Game.notify("Dormiste y guardaste la partida")
		"save":
			world.save_game()
			Game.notify("Partida guardada")
		"weather":
			world.cycle_weather()
		"fine":
			if Wanted.level == 0:
				Game.notify("No tienes antecedentes")
				return
			var cost := 300 * Wanted.level
			if int(Game.state["money"]) < cost:
				Game.notify("La multa cuesta S/ %d" % cost)
				return
			Game.add_money(-cost)
			Wanted.clear()
			Game.notify("Multa pagada: -S/ %d" % cost)
		"rob":
			if bool(Game.state.get("bank_robbed", false)):
				Game.notify("La bóveda está vacía")
				return
			Game.state["bank_robbed"] = true
			var loot := randi_range(1800, 3200)
			Game.add_money(loot)
			Wanted.add_crime(75.0, p.global_position)
			Game.notify("¡Botín! +S/ %d — la policía viene" % loot)
		"train":
			if int(Game.state["money"]) < 100:
				Game.notify("Cuesta S/ 100")
				return
			if p.max_health >= 150.0:
				Game.notify("Ya estás al máximo")
				return
			Game.add_money(-100)
			p.max_health += 10.0
			p.heal(10.0)
			Game.notify("Vida máxima: %d" % int(p.max_health))
		"info":
			Game.notify(action.substr(5))
