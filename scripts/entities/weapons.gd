class_name Weapons
extends RefCounted
## Armas de COP 1 (nombres inventados). "melee" no usa munición.

const DATA := {
	"punos": {"name": "Puños", "melee": true, "damage": 8.0, "rate": 2.5, "range": 2.2, "pellets": 1, "spread": 0.0, "auto": false, "price": 0, "pack": 0, "color": Color(0.8, 0.6, 0.45), "loud": 6.0},
	"bate": {"name": "Bate de Chacra", "melee": true, "damage": 22.0, "rate": 1.4, "range": 2.8, "pellets": 1, "spread": 0.0, "auto": false, "price": 80, "pack": 0, "color": Color(0.55, 0.38, 0.2), "loud": 8.0},
	"machete": {"name": "Machete del Barrio", "melee": true, "damage": 34.0, "rate": 1.8, "range": 2.4, "pellets": 1, "spread": 0.0, "auto": false, "price": 140, "pack": 0, "color": Color(0.7, 0.72, 0.75), "loud": 6.0},
	"pistola": {"name": "Fierro 9mm", "melee": false, "damage": 22.0, "rate": 3.0, "range": 60.0, "pellets": 1, "spread": 1.5, "auto": false, "price": 600, "pack": 24, "color": Color(0.15, 0.15, 0.17), "loud": 70.0},
	"revolver": {"name": "Revólver Rímac", "melee": false, "damage": 42.0, "rate": 1.5, "range": 70.0, "pellets": 1, "spread": 1.0, "auto": false, "price": 900, "pack": 12, "color": Color(0.35, 0.35, 0.38), "loud": 85.0},
	"escopeta": {"name": "Escopeta Chalaca", "melee": false, "damage": 10.0, "rate": 1.0, "range": 25.0, "pellets": 8, "spread": 7.0, "auto": false, "price": 1500, "pack": 10, "color": Color(0.3, 0.2, 0.12), "loud": 95.0},
	"subfusil": {"name": "Subfusil Huaylas", "melee": false, "damage": 12.0, "rate": 9.0, "range": 45.0, "pellets": 1, "spread": 3.5, "auto": true, "price": 2200, "pack": 60, "color": Color(0.1, 0.1, 0.12), "loud": 90.0},
}

const ORDER := ["punos", "bate", "machete", "pistola", "revolver", "escopeta", "subfusil"]


static func info(id: String) -> Dictionary:
	return DATA.get(id, DATA["punos"])


static func owned_list() -> Array:
	var out: Array = []
	var w: Dictionary = Game.state["weapons"]
	for id in ORDER:
		if w.has(id):
			out.append(id)
	return out


static func next_owned(current: String) -> String:
	var list := owned_list()
	if list.is_empty():
		return "punos"
	var i := list.find(current)
	return list[(i + 1) % list.size()]


static func give(id: String, ammo := 0) -> void:
	var w: Dictionary = Game.state["weapons"]
	w[id] = int(w.get(id, 0)) + ammo
