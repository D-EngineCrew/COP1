extends Node
## Guardado y carga de partidas (3 ranuras) y ajustes.

const SETTINGS_PATH := "user://settings.json"


func _ready() -> void:
	load_settings()


func slot_path(i: int) -> String:
	return "user://slot_%d.json" % i


func has_slot(i: int) -> bool:
	return FileAccess.file_exists(slot_path(i))


func save_slot(i: int) -> bool:
	var data: Dictionary = Game.state.duplicate(true)
	data["saved_at"] = Time.get_datetime_string_from_system()
	var f := FileAccess.open(slot_path(i), FileAccess.WRITE)
	if f == null:
		return false
	f.store_string(JSON.stringify(data))
	f.close()
	Game.current_slot = i
	return true


func load_slot(i: int) -> bool:
	var data := read_slot(i)
	if data.is_empty():
		return false
	var base := Game.default_state()
	for k in data.keys():
		base[k] = data[k]
	Game.state = base
	Game.current_slot = i
	Game.in_game = true
	return true


func read_slot(i: int) -> Dictionary:
	if not has_slot(i):
		return {}
	var f := FileAccess.open(slot_path(i), FileAccess.READ)
	if f == null:
		return {}
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	f.close()
	return parsed if parsed is Dictionary else {}


func slot_summary(i: int) -> String:
	var d := read_slot(i)
	if d.is_empty():
		return "Ranura %d — vacía" % (i + 1)
	var mins := int(float(d.get("playtime", 0.0)) / 60.0)
	return "Ranura %d — %s · S/ %d · %d min · %s" % [i + 1, d.get("name", "JeanSyo"), int(d.get("money", 0)), mins, str(d.get("saved_at", "")).replace("T", " ")]


func delete_slot(i: int) -> void:
	if has_slot(i):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(slot_path(i)))


func save_settings() -> void:
	var f := FileAccess.open(SETTINGS_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(Game.settings))
		f.close()


func load_settings() -> void:
	if not FileAccess.file_exists(SETTINGS_PATH):
		return
	var f := FileAccess.open(SETTINGS_PATH, FileAccess.READ)
	if f == null:
		return
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	f.close()
	if parsed is Dictionary:
		for k in parsed.keys():
			Game.settings[k] = parsed[k]
	AudioServer.set_bus_volume_db(0, linear_to_db(float(Game.settings["volume"])))
