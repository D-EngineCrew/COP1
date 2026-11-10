class_name TouchControls
extends Control
## Controles táctiles multitáctil: joystick flotante, cámara por arrastre y botones de acción.

signal pause_pressed

const JOY_R := 85.0

var move := Vector2.ZERO
var enabled := true
var in_vehicle := false
var action_label := "Acción"
var buttons := {}
var _look := Vector2.ZERO
var _held := {}
var _just := {}
var _joy_idx := -1
var _joy_origin := Vector2.ZERO
var _joy_pos := Vector2.ZERO
var _look_idx := -1
var _btn_idx := {}


func _ready() -> void:
	add_to_group("touch")
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	resized.connect(_layout)
	_layout()


func _layout() -> void:
	var s := size
	buttons = {
		"fire": {"pos": Vector2(s.x - 135, s.y - 135), "r": 66.0, "label": "Disparar"},
		"jump": {"pos": Vector2(s.x - 285, s.y - 80), "r": 44.0, "label": "Saltar"},
		"action": {"pos": Vector2(s.x - 105, s.y - 295), "r": 48.0, "label": action_label},
		"weapon": {"pos": Vector2(s.x - 265, s.y - 205), "r": 40.0, "label": "Arma"},
		"brake": {"pos": Vector2(s.x - 135, s.y - 135), "r": 66.0, "label": "Freno"},
		"pause": {"pos": Vector2(s.x - 46, 46), "r": 28.0, "label": "II"},
	}
	queue_redraw()


func _btn_visible(bname: String) -> bool:
	match bname:
		"fire", "weapon", "jump":
			return not in_vehicle
		"brake":
			return in_vehicle
	return true


func held(bname: String) -> bool:
	return _held.get(bname, false)


func just_pressed(bname: String) -> bool:
	var v: bool = _just.get(bname, false)
	_just[bname] = false
	return v


func consume_look() -> Vector2:
	var l := _look
	_look = Vector2.ZERO
	return l


func reset() -> void:
	move = Vector2.ZERO
	_held.clear()
	_just.clear()
	_btn_idx.clear()
	_joy_idx = -1
	_look_idx = -1
	queue_redraw()


func set_vehicle_mode(v: bool, label: String) -> void:
	if v != in_vehicle or label != action_label:
		in_vehicle = v
		action_label = label
		_layout()


func _input(event: InputEvent) -> void:
	if not enabled or not is_visible_in_tree():
		return
	if event is InputEventScreenTouch:
		var ev := make_input_local(event) as InputEventScreenTouch
		var pos := ev.position
		if ev.pressed:
			for n in buttons.keys():
				var b: Dictionary = buttons[n]
				if _btn_visible(n) and pos.distance_to(b["pos"]) <= float(b["r"]) * 1.2 and not _btn_idx.values().has(n):
					_btn_idx[ev.index] = n
					_held[n] = true
					_just[n] = true
					if n == "pause":
						pause_pressed.emit()
					queue_redraw()
					return
			if pos.x < size.x * 0.45 and pos.y > size.y * 0.2 and _joy_idx == -1:
				_joy_idx = ev.index
				_joy_origin = pos
				_joy_pos = pos
				queue_redraw()
			elif pos.x >= size.x * 0.3 and _look_idx == -1:
				_look_idx = ev.index
		else:
			if _btn_idx.has(ev.index):
				_held[_btn_idx[ev.index]] = false
				_btn_idx.erase(ev.index)
			if ev.index == _joy_idx:
				_joy_idx = -1
				move = Vector2.ZERO
			if ev.index == _look_idx:
				_look_idx = -1
			queue_redraw()
	elif event is InputEventScreenDrag:
		var ev := make_input_local(event) as InputEventScreenDrag
		if ev.index == _joy_idx:
			_joy_pos = ev.position
			var v := (_joy_pos - _joy_origin) / JOY_R
			if v.length() > 1.0:
				v = v.normalized()
				_joy_pos = _joy_origin + v * JOY_R
			move = Vector2(v.x, -v.y)
			if move.length() < 0.12:
				move = Vector2.ZERO
			queue_redraw()
		elif ev.index == _look_idx:
			_look += ev.relative


func _draw() -> void:
	var font := ThemeDB.fallback_font
	if _joy_idx != -1:
		draw_circle(_joy_origin, JOY_R, Color(1, 1, 1, 0.12))
		draw_arc(_joy_origin, JOY_R, 0, TAU, 32, Color(1, 1, 1, 0.45), 3.0)
		draw_circle(_joy_pos, 34.0, Color(1, 1, 1, 0.45))
	else:
		var hint := Vector2(size.x * 0.13, size.y - 150)
		draw_arc(hint, JOY_R, 0, TAU, 32, Color(1, 1, 1, 0.18), 3.0)
		draw_string(font, hint + Vector2(-JOY_R, 6), "Mover", HORIZONTAL_ALIGNMENT_CENTER, JOY_R * 2.0, 18, Color(1, 1, 1, 0.35))
	for n in buttons.keys():
		if not _btn_visible(n):
			continue
		var b: Dictionary = buttons[n]
		var p: Vector2 = b["pos"]
		var r: float = b["r"]
		var down: bool = _held.get(n, false)
		var col := Color(0.9, 0.2, 0.2, 0.55) if n == "fire" else Color(1, 1, 1, 0.28)
		if n == "brake":
			col = Color(0.95, 0.6, 0.15, 0.5)
		if down:
			col.a = 0.8
		draw_circle(p, r, col)
		draw_arc(p, r, 0, TAU, 28, Color(1, 1, 1, 0.55), 2.5)
		var text: String = action_label if n == "action" else String(b["label"])
		draw_string(font, p + Vector2(-r, 6), text, HORIZONTAL_ALIGNMENT_CENTER, r * 2.0, 17, Color(1, 1, 1, 0.95))
