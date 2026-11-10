extends Control
## Menú principal de COP 1: nueva partida, continuar, cargar, opciones y acerca de.

const RED := Color(0.85, 0.1, 0.2)

var pages := {}
var content: VBoxContainer
var slots_new: VBoxContainer
var slots_load: VBoxContainer


func _ready() -> void:
	get_tree().paused = false
	Game.in_game = false
	Game.paused = false
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.color = Color(0.07, 0.08, 0.11)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	_skyline()
	var bar := ColorRect.new()
	bar.color = RED
	bar.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	bar.custom_minimum_size = Vector2(0, 10)
	bar.size = Vector2(0, 10)
	add_child(bar)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	content = VBoxContainer.new()
	content.add_theme_constant_override("separation", 12)
	content.custom_minimum_size = Vector2(520, 0)
	center.add_child(content)
	var title := Label.new()
	title.text = "COP 1"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 84)
	title.add_theme_color_override("font_color", Color(1, 1, 1))
	title.add_theme_color_override("font_outline_color", RED)
	title.add_theme_constant_override("outline_size", 14)
	content.add_child(title)
	var sub := Label.new()
	sub.text = "City of Peru · Ciudad del Perú"
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_font_size_override("font_size", 22)
	content.add_child(sub)
	_build_main()
	_build_new()
	_build_load()
	_build_options()
	_build_about()
	_show("main")


func _skyline() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 51
	for i in range(30):
		var r := ColorRect.new()
		var h := rng.randf_range(60, 260)
		r.color = Color(0.1, 0.11, 0.15).lerp(Color(0.2, 0.2, 0.26), rng.randf())
		r.anchor_top = 1.0
		r.anchor_bottom = 1.0
		r.anchor_left = i / 30.0
		r.anchor_right = (i + 1) / 30.0
		r.offset_top = -h
		r.offset_bottom = 0
		r.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(r)


func _button(text: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(0, 56)
	b.add_theme_font_size_override("font_size", 24)
	b.pressed.connect(cb)
	return b


func _page(id: String) -> VBoxContainer:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	content.add_child(v)
	pages[id] = v
	return v


func _show(id: String) -> void:
	for k in pages.keys():
		pages[k].visible = (k == id)
	if id == "new":
		_refresh_slots(slots_new, true)
	elif id == "load":
		_refresh_slots(slots_load, false)
	if id == "main":
		_continue_button.disabled = _latest_slot() < 0


var _continue_button: Button


func _build_main() -> void:
	var p := _page("main")
	_continue_button = _button("Continuar", _continue)
	p.add_child(_continue_button)
	p.add_child(_button("Nueva partida", func(): _show("new")))
	p.add_child(_button("Cargar partida", func(): _show("load")))
	p.add_child(_button("Opciones", func(): _show("options")))
	p.add_child(_button("Acerca de", func(): _show("about")))
	if OS.get_name() != "Android" and OS.get_name() != "iOS":
		p.add_child(_button("Salir", func(): get_tree().quit()))


func _build_new() -> void:
	var p := _page("new")
	var l := Label.new()
	l.text = "Elige una ranura para la nueva partida"
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	p.add_child(l)
	slots_new = VBoxContainer.new()
	slots_new.add_theme_constant_override("separation", 8)
	p.add_child(slots_new)
	p.add_child(_button("Volver", func(): _show("main")))


func _build_load() -> void:
	var p := _page("load")
	var l := Label.new()
	l.text = "Cargar partida guardada"
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	p.add_child(l)
	slots_load = VBoxContainer.new()
	slots_load.add_theme_constant_override("separation", 8)
	p.add_child(slots_load)
	p.add_child(_button("Volver", func(): _show("main")))


func _refresh_slots(box: VBoxContainer, is_new: bool) -> void:
	for c in box.get_children():
		c.queue_free()
	for i in range(Game.SLOTS):
		var idx := i
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		box.add_child(row)
		var txt := Save.slot_summary(i)
		if is_new:
			var b := _button(txt + ("  (se sobrescribe)" if Save.has_slot(i) else ""), func(): _start_new(idx))
			b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			b.add_theme_font_size_override("font_size", 17)
			row.add_child(b)
		else:
			var b2 := _button(txt, func(): _load(idx))
			b2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			b2.add_theme_font_size_override("font_size", 17)
			b2.disabled = not Save.has_slot(i)
			row.add_child(b2)
			var del := _button("Borrar", func():
				Save.delete_slot(idx)
				_refresh_slots(box, false))
			del.add_theme_font_size_override("font_size", 17)
			del.disabled = not Save.has_slot(i)
			row.add_child(del)


func _latest_slot() -> int:
	var best := -1
	var best_t := ""
	for i in range(Game.SLOTS):
		if Save.has_slot(i):
			var t := String(Save.read_slot(i).get("saved_at", ""))
			if best == -1 or t > best_t:
				best = i
				best_t = t
	return best


func _continue() -> void:
	var i := _latest_slot()
	if i >= 0:
		_load(i)


func _load(i: int) -> void:
	if Save.load_slot(i):
		_start_world()


func _start_new(i: int) -> void:
	Game.new_game(i)
	Save.save_slot(i)
	_start_world()


func _start_world() -> void:
	Game.in_game = true
	get_tree().change_scene_to_file("res://scenes/world.tscn")


func _build_options() -> void:
	var p := _page("options")
	var q := OptionButton.new()
	q.add_item("Gráficos: Bajo", 0)
	q.add_item("Gráficos: Medio", 1)
	q.add_item("Gráficos: Alto", 2)
	q.selected = clampi(int(Game.settings["quality"]), 0, 2)
	q.custom_minimum_size = Vector2(0, 52)
	q.item_selected.connect(func(i):
		Game.settings["quality"] = i
		Save.save_settings())
	p.add_child(q)
	var sh := CheckBox.new()
	sh.text = "Sombras (consume más batería)"
	sh.button_pressed = bool(Game.settings["shadows"])
	sh.toggled.connect(func(on):
		Game.settings["shadows"] = on
		Save.save_settings())
	p.add_child(sh)
	p.add_child(_slider("Volumen", float(Game.settings["volume"]), 0.0, 1.0, func(v):
		Game.settings["volume"] = v
		AudioServer.set_bus_volume_db(0, linear_to_db(maxf(v, 0.001)))
		Save.save_settings()))
	p.add_child(_slider("Sensibilidad de cámara", float(Game.settings["sens"]), 0.4, 2.5, func(v):
		Game.settings["sens"] = v
		Save.save_settings()))
	p.add_child(_button("Volver", func(): _show("main")))


func _slider(text: String, value: float, lo: float, hi: float, cb: Callable) -> Control:
	var box := VBoxContainer.new()
	var l := Label.new()
	l.text = text
	box.add_child(l)
	var s := HSlider.new()
	s.min_value = lo
	s.max_value = hi
	s.step = 0.05
	s.value = value
	s.custom_minimum_size = Vector2(0, 32)
	s.value_changed.connect(cb)
	box.add_child(s)
	return box


func _build_about() -> void:
	var p := _page("about")
	var l := Label.new()
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size = Vector2(520, 0)
	l.text = "COP 1 es un juego de mundo abierto ambientado en Lima, Perú. Los distritos y lugares están inspirados en la ciudad real con ubicaciones aproximadas y escala comprimida.\n\nLas bandas, personajes, armas y vehículos son totalmente ficticios y no representan casos ni personas reales.\n\nProtagonista: JeanSyo. Su casa y su auto están en El Agustino."
	p.add_child(l)
	p.add_child(_button("Volver", func(): _show("main")))
