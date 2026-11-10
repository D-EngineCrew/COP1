extends Node
## Hora del día y clima limeño: despejado, nublado (lo más común), llovizna (garúa) y lluvia.

signal weather_changed(weather_name: String)

const STATES := ["despejado", "nublado", "llovizna", "lluvia"]
const LABELS := {"despejado": "Despejado", "nublado": "Nublado", "llovizna": "Llovizna", "lluvia": "Lluvia"}
# probabilidad de pasar a cada estado (Lima: mucha nubosidad y garúa)
const WEIGHTS := {"despejado": 0.15, "nublado": 0.5, "llovizna": 0.25, "lluvia": 0.1}
const DAY_REAL_SECONDS := 1200.0

const SKY_KEYS := [
	[0.0, Color(0.02, 0.03, 0.08)], [5.0, Color(0.04, 0.05, 0.11)], [6.5, Color(0.9, 0.55, 0.4)],
	[8.0, Color(0.6, 0.74, 0.88)], [17.0, Color(0.6, 0.74, 0.88)], [18.5, Color(0.95, 0.5, 0.3)],
	[20.0, Color(0.05, 0.06, 0.14)], [24.0, Color(0.02, 0.03, 0.08)],
]

var current := "nublado"
var cloud := 0.6
var rain_amount := 0.0
var env: Environment
var sun: DirectionalLight3D
var rain: CPUParticles3D
var _timer := 60.0
var _target_cloud := 0.6
var _target_rain := 0.0


func _ready() -> void:
	set_weather(String(Game.state.get("weather", "nublado")), true)


func bind(e: Environment, s: DirectionalLight3D, r: CPUParticles3D) -> void:
	env = e
	sun = s
	rain = r
	set_weather(current, true)


func unbind() -> void:
	env = null
	sun = null
	rain = null


func set_weather(w: String, instant := false) -> void:
	if not STATES.has(w):
		w = "nublado"
	current = w
	Game.state["weather"] = w
	match w:
		"despejado":
			_target_cloud = 0.1
			_target_rain = 0.0
		"nublado":
			_target_cloud = 0.7
			_target_rain = 0.0
		"llovizna":
			_target_cloud = 0.85
			_target_rain = 0.35
		"lluvia":
			_target_cloud = 1.0
			_target_rain = 1.0
	if instant:
		cloud = _target_cloud
		rain_amount = _target_rain
	if rain:
		rain.amount = 250 if w == "llovizna" else 600
		rain.emitting = _target_rain > 0.0
	weather_changed.emit(w)


func _pick_random() -> String:
	var r := randf()
	var acc := 0.0
	for k in WEIGHTS.keys():
		acc += WEIGHTS[k]
		if r <= acc:
			return k
	return "nublado"


func _process(delta: float) -> void:
	if not Game.in_game or Game.paused:
		return
	Game.state["time"] = fmod(float(Game.state["time"]) + delta * 24.0 / DAY_REAL_SECONDS, 24.0)
	Game.state["playtime"] = float(Game.state["playtime"]) + delta
	_timer -= delta
	if _timer <= 0.0:
		_timer = randf_range(70.0, 150.0)
		set_weather(_pick_random())
	cloud = move_toward(cloud, _target_cloud, delta * 0.05)
	rain_amount = move_toward(rain_amount, _target_rain, delta * 0.08)
	if rain and rain.emitting and rain_amount <= 0.0 and _target_rain <= 0.0:
		rain.emitting = false
	_apply_environment()


func sky_color(h: float) -> Color:
	for i in range(SKY_KEYS.size() - 1):
		var a: Array = SKY_KEYS[i]
		var b: Array = SKY_KEYS[i + 1]
		if h >= a[0] and h <= b[0]:
			return (a[1] as Color).lerp(b[1], (h - a[0]) / (b[0] - a[0]))
	return SKY_KEYS[0][1]


func is_night() -> bool:
	var h: float = float(Game.state["time"])
	return h < 5.5 or h > 19.5


func _apply_environment() -> void:
	if env == null or sun == null:
		return
	var h: float = float(Game.state["time"])
	var base := sky_color(h)
	var lum := base.get_luminance()
	var gray := Color(0.66, 0.67, 0.7) * clampf(lum * 1.4 + 0.05, 0.05, 1.0)
	var col := base.lerp(gray, cloud * 0.8)
	col = col.darkened(rain_amount * 0.25)
	env.background_color = col
	env.ambient_light_color = col.lerp(Color.WHITE, 0.35)
	env.ambient_light_energy = lerpf(0.35, 0.9, clampf(lum * 1.5, 0.0, 1.0))
	env.fog_light_color = col
	env.fog_density = lerpf(0.0015, 0.008, maxf(cloud * 0.5, rain_amount))
	var elev := sin((h - 6.0) / 12.0 * PI) * 70.0
	sun.rotation_degrees = Vector3(-maxf(elev, 8.0), (h - 12.0) * 15.0, 0.0)
	var day := clampf(elev / 25.0, 0.0, 1.0)
	sun.light_energy = lerpf(0.08, 1.15, day) * (1.0 - cloud * 0.55)
	sun.light_color = Color(1.0, 0.92, 0.8).lerp(Color(0.6, 0.7, 1.0), 1.0 - day)
