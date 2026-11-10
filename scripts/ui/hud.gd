class_name Hud
extends CanvasLayer
## Interfaz en partida: vida, armadura, dinero, hora, clima, sirenas, minimapa, mensajes y menú de pausa.

var player: Player
var world: World
var touch: TouchControls
var minimap: MiniMap
var sirens: SirenIcons
var root: Control
var info_label: Label
var weapon_label: Label
var prompt_label: Label
var msg_label: Label
var banner_label: Label
var interior_label: Label
var death_label: Label
var death_rect: ColorRect
var bars: Control
var pause_panel: PanelContainer
var slots_box: VBoxContainer
var _msgs: Array = []
var _banner_t := 0.0


func _ready() -> void:
	layer = 10
	process_mode = Node.PROCESS_MODE_ALWAYS


func setup(p: Player, w: World) -> void:
	player = p
	world = w
	root = Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	touch = TouchControls.new()
	touch.process_mode = Node.PROCESS_MODE_PAUSABLE
	root.add_child(touch)
	touch.pause_pressed.connect(open_pause)
	minimap = MiniMap.new()
	minimap.builder = w.builder
	minimap.player = p
	minimap.position = Vector2(14, 14)
	root.add_child(minimap)
	sirens = SirenIcons.new()
	root.add_child(sirens)
	bars = Control.new()
	bars.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bars.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bars.draw.connect(_draw_bars)
	root.add_child(bars)
	info_label = _make_label(22, HORIZONTAL_ALIGNMENT_RIGHT)
	weapon_label = _make_label(20, HORIZONTAL_ALIGNMENT_CENTER)
	prompt_label = _make_label(24, HORIZONTAL_ALIGNMENT_CENTER)
	prompt_label.add_theme_color_override("font_color", Color(1, 0.95, 0.5))
	msg_label = _make_label(20, HORIZONTAL_ALIGNMENT_CENTER)
	banner_label = _make_label(34, HORIZONTAL_ALIGNMENT_CENTER)
	interior_label = _make_label(22, HORIZONTAL_ALIGNMENT_CENTER)
	death_rect = ColorRect.new()
	death_rect.color = Color(0.5, 0, 0, 0.45)
	death_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	death_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	death_rect.visible = false
	root.add_child(death_rect)
	death_label = _make_label(64, HORIZONTAL_ALIGNMENT_CENTER)
	death_label.visible = false
	_build_pause_menu()
	Game.message.connect(_on_message)
	Game.state_changed.connect(func(): bars.queue_redraw())


func _make_label(size: int, align: HorizontalAlignment) -> Label:
	var l := Label.new()
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	l.add_theme_constant_override("outline_size", 6)
	l.horizontal_alignment = align
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(l)
	return l


func _on_message(text: String) -> void:
	_msgs.append({"text": text, "t": 3.5})
	if _msgs.size() > 4:
		_msgs.pop_front()


func show_location(text: String, color := Color.WHITE) -> void:
	banner_label.text = text
	banner_label.add_theme_color_override("font_color", color)
	_banner_t = 3.0


func set_interior(title: String) -> void:
	interior_label.text = title
	interior_label.visible = title != ""
	minimap.visible = title == ""
	sirens.visible = title == ""


func show_death(text: String, duration := 0.0) -> void:
	death_label.text = text
	death_label.visible = true
	death_rect.visible = true
	if duration > 0.0:
		get_tree().create_timer(duration).timeout.connect(hide_death)


func hide_death() -> void:
	death_label.visible = false
	death_rect.visible = false


func _process(delta: float) -> void:
	if player == null or not is_instance_valid(player):
		return
	var s := root.size
	minimap.position = Vector2(14, 14)
	sirens.position = Vector2(s.x - sirens.size.x - 90, 62)
	var weather_name: String = Weather.LABELS.get(Weather.current, "")
	info_label.text = "S/ %d\n%s · %s" % [int(Game.state["money"]), Game.format_time(), weather_name]
	info_label.position = Vector2(s.x - 360 - 90, 8)
	info_label.size = Vector2(360, 60)
	var wid := String(Game.state["weapon"])
	var w := Weapons.info(wid)
	var ammo_txt := "" if w["melee"] else "  ·  %d" % int(Game.state["weapons"].get(wid, 0))
	weapon_label.text = String(w["name"]) + ammo_txt
	weapon_label.position = Vector2(s.x * 0.5 - 200, s.y - 40)
	weapon_label.size = Vector2(400, 30)
	var prompt := player.prompt_text
	prompt_label.text = prompt
	prompt_label.visible = prompt != "" and not player.dead
	prompt_label.position = Vector2(s.x * 0.5 - 360, s.y - 130)
	prompt_label.size = Vector2(720, 36)
	touch.set_vehicle_mode(player.vehicle != null, _action_label(prompt))
	touch.enabled = not pause_panel.visible and not player.dead
	var lines := ""
	for m in _msgs:
		m["t"] -= delta
		lines += String(m["text"]) + "\n"
	_msgs = _msgs.filter(func(m): return m["t"] > 0.0)
	msg_label.text = lines.strip_edges()
	msg_label.position = Vector2(s.x * 0.5 - 360, 14)
	msg_label.size = Vector2(720, 100)
	_banner_t = maxf(_banner_t - delta, 0.0)
	banner_label.modulate.a = clampf(_banner_t, 0.0, 1.0)
	banner_label.position = Vector2(s.x * 0.5 - 360, s.y * 0.22)
	banner_label.size = Vector2(720, 50)
	interior_label.position = Vector2(s.x * 0.5 - 360, 8)
	interior_label.size = Vector2(720, 36)
	death_label.position = Vector2(0, s.y * 0.35)
	death_label.size = Vector2(s.x, 90)
	bars.queue_redraw()


func _action_label(prompt: String) -> String:
	if prompt.begins_with("Bajar"):
		return "Bajar"
	if prompt.begins_with("Subir"):
		return "Subir"
	if prompt.begins_with("Entrar"):
		return "Entrar"
	if prompt == "Salir":
		return "Salir"
	if prompt != "":
		return "Usar"
	return "Acción"


func _draw_bars() -> void:
	if player == null or not is_instance_valid(player):
		return
	var s := root.size
	var w := 300.0
	var x := s.x * 0.5 - w * 0.5
	var y := s.y - 62.0
	bars.draw_rect(Rect2(x - 2, y - 2, w + 4, 14), Color(0, 0, 0, 0.6))
	bars.draw_rect(Rect2(x, y, w * clampf(player.health / player.max_health, 0.0, 1.0), 10), Color(0.85, 0.2, 0.2))
	if player.armor > 0.0:
		bars.draw_rect(Rect2(x - 2, y - 16, w + 4, 10), Color(0, 0, 0, 0.6))
		bars.draw_rect(Rect2(x, y - 14, w * clampf(player.armor / 100.0, 0.0, 1.0), 6), Color(0.3, 0.55, 0.95))


# ---------- Menú de pausa ----------
func _build_pause_menu() -> void:
	pause_panel = PanelContainer.new()
	pause_panel.visible = false
	pause_panel.process_mode = Node.PROCESS_MODE_ALWAYS
	pause_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	pause_panel.custom_minimum_size = Vector2(460, 0)
	root.add_child(pause_panel)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 10)
	pause_panel.add_child(vb)
	var title := Label.new()
	title.text = "COP 1 — Pausa"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 30)
	vb.add_child(title)
	vb.add_child(_button("Continuar", close_pause))
	slots_box = VBoxContainer.new()
	slots_box.add_theme_constant_override("separation", 6)
	vb.add_child(slots_box)
	vb.add_child(_button("Clima siguiente", func(): world.cycle_weather()))
	vb.add_child(_button("Menú principal", _to_main_menu))


func _button(text: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(0, 54)
	b.add_theme_font_size_override("font_size", 22)
	b.pressed.connect(cb)
	return b


func _refresh_slots() -> void:
	for c in slots_box.get_children():
		c.queue_free()
	for i in range(Game.SLOTS):
		var idx := i
		slots_box.add_child(_button("Guardar en: " + Save.slot_summary(i), func():
			Game.current_slot = idx
			world.save_game()
			_refresh_slots()))


func open_pause() -> void:
	if pause_panel.visible or player.dead:
		return
	_refresh_slots()
	pause_panel.visible = true
	get_tree().paused = true
	Game.paused = true
	touch.reset()


func close_pause() -> void:
	pause_panel.visible = false
	get_tree().paused = false
	Game.paused = false


func _to_main_menu() -> void:
	player.save_state()
	get_tree().paused = false
	Game.paused = false
	Game.in_game = false
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
