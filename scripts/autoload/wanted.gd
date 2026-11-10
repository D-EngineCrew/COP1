extends Node
## Nivel de búsqueda. En vez de estrellas se muestran sirenas de patrullero (1 a 5).

signal level_changed(level: int)

const THRESHOLDS := [0.0, 10.0, 30.0, 60.0, 100.0, 160.0]
const DECAY_DELAY := 8.0
const DECAY_RATE := 4.0

var heat := 0.0
var level := 0
var _unseen_time := 0.0
var _seen_this_frame := false
var last_crime_pos := Vector3.ZERO


func _ready() -> void:
	heat = float(Game.state.get("wanted_heat", 0.0))
	_update_level()


func reset_from_state() -> void:
	heat = float(Game.state.get("wanted_heat", 0.0))
	_unseen_time = 0.0
	_update_level()


func add_crime(points: float, at: Vector3) -> void:
	heat = minf(heat + points, 200.0)
	last_crime_pos = at
	_unseen_time = 0.0
	_update_level()


func report_seen() -> void:
	_seen_this_frame = true


func clear() -> void:
	heat = 0.0
	_update_level()


func _process(delta: float) -> void:
	if level == 0:
		return
	if _seen_this_frame:
		_unseen_time = 0.0
	else:
		_unseen_time += delta
		if _unseen_time > DECAY_DELAY:
			heat = maxf(heat - DECAY_RATE * delta, 0.0)
			_update_level()
	_seen_this_frame = false
	Game.state["wanted_heat"] = heat


func _update_level() -> void:
	var new_level := 0
	for i in range(THRESHOLDS.size()):
		if heat >= THRESHOLDS[i] and i > 0:
			new_level = i
	if new_level != level:
		level = new_level
		level_changed.emit(level)
