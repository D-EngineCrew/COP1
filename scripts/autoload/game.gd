extends Node
## Estado global de COP 1: partida actual, ajustes y utilidades.

signal message(text: String)
signal state_changed
signal arrested

const SLOTS := 3
const HOME_SPAWN := Vector3(0.0, 1.0, 9.0)
const HOME_CAR := Vector3(11.0, 1.0, 9.0)

var state: Dictionary = {}
var settings := {"quality": 1, "volume": 0.8, "shadows": true, "sens": 1.0}
var current_slot := 0
var in_game := false
var paused := false
var player: Node3D = null


func _ready() -> void:
	state = default_state()


func default_state() -> Dictionary:
	return {
		"name": "JeanSyo",
		"money": 500,
		"health": 100.0,
		"armor": 0.0,
		"pos": [HOME_SPAWN.x, HOME_SPAWN.y, HOME_SPAWN.z],
		"yaw": 0.0,
		"time": 9.0,
		"weather": "nublado",
		"wanted_heat": 0.0,
		"weapons": {"punos": 0, "pistola": 24},
		"weapon": "punos",
		"car_pos": [HOME_CAR.x, HOME_CAR.y, HOME_CAR.z],
		"car_yaw": 0.0,
		"playtime": 0.0,
		"kills": 0,
		"inside": "",
		"return_pos": [HOME_SPAWN.x, HOME_SPAWN.y, HOME_SPAWN.z],
	}


func new_game(slot: int) -> void:
	state = default_state()
	current_slot = slot
	in_game = true


func notify(text: String) -> void:
	message.emit(text)


func add_money(v: int) -> void:
	state["money"] = int(state["money"]) + v
	state_changed.emit()


func get_vec3(key: String) -> Vector3:
	var a: Array = state.get(key, [0, 0, 0])
	return Vector3(float(a[0]), float(a[1]), float(a[2]))


func set_vec3(key: String, v: Vector3) -> void:
	state[key] = [v.x, v.y, v.z]


func chunk_radius() -> int:
	return [1, 2, 3][clampi(int(settings["quality"]), 0, 2)]


func format_time() -> String:
	var t: float = float(state["time"])
	var h := int(t) % 24
	var m := int((t - floorf(t)) * 60.0)
	return "%02d:%02d" % [h, m]


func broadcast_noise(pos: Vector3, radius: float, source: Node = null) -> void:
	for n in get_tree().get_nodes_in_group("npc"):
		if n.has_method("hear") and n.global_position.distance_to(pos) < radius:
			n.hear(pos, source)
