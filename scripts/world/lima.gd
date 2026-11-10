class_name Lima
extends RefCounted
## Datos geográficos de Lima (coordenadas aproximadas) y conversión a metros de juego.
## El mapa se comprime con SCALE para que quepa en un móvil manteniendo posiciones relativas.

const ORIGIN_LAT := -12.0600   # El Agustino (casa de JeanSyo)
const ORIGIN_LON := -77.0100
const SCALE := 0.12
const M_PER_DEG_LAT := 110574.0
const M_PER_DEG_LON := 108900.0
const BOUNDS_LAT := Vector2(-12.20, -11.92)  # sur, norte
const BOUNDS_LON := Vector2(-77.15, -76.90)  # oeste, este

# Estilos de urbanismo por tipo de distrito
const STYLES := {
	"casco": {"floors": [2, 5], "lot": [12.0, 22.0], "block": 46.0, "road": 9.0, "density": 0.95,
		"colors": [Color(0.85, 0.78, 0.55), Color(0.9, 0.85, 0.7), Color(0.8, 0.6, 0.4), Color(0.75, 0.7, 0.6)]},
	"popular": {"floors": [1, 3], "lot": [7.0, 12.0], "block": 36.0, "road": 7.0, "density": 0.95,
		"colors": [Color(0.8, 0.45, 0.35), Color(0.6, 0.6, 0.55), Color(0.85, 0.75, 0.5), Color(0.5, 0.65, 0.75), Color(0.75, 0.55, 0.6)]},
	"cerro": {"floors": [1, 2], "lot": [6.0, 10.0], "block": 32.0, "road": 6.0, "density": 0.9,
		"colors": [Color(0.9, 0.5, 0.3), Color(0.3, 0.6, 0.8), Color(0.85, 0.8, 0.3), Color(0.55, 0.75, 0.45), Color(0.8, 0.4, 0.55), Color(0.7, 0.7, 0.7)]},
	"comercial": {"floors": [3, 7], "lot": [12.0, 20.0], "block": 44.0, "road": 9.0, "density": 1.0,
		"colors": [Color(0.7, 0.7, 0.75), Color(0.85, 0.5, 0.3), Color(0.4, 0.55, 0.75), Color(0.9, 0.85, 0.6)]},
	"residencial": {"floors": [2, 4], "lot": [12.0, 18.0], "block": 54.0, "road": 10.0, "density": 0.8,
		"colors": [Color(0.92, 0.9, 0.85), Color(0.85, 0.8, 0.7), Color(0.75, 0.82, 0.75), Color(0.9, 0.75, 0.65)]},
	"torres": {"floors": [6, 16], "lot": [18.0, 28.0], "block": 64.0, "road": 12.0, "density": 0.75,
		"colors": [Color(0.55, 0.65, 0.75), Color(0.85, 0.85, 0.88), Color(0.7, 0.75, 0.8), Color(0.45, 0.5, 0.58)]},
	"industrial": {"floors": [1, 2], "lot": [24.0, 40.0], "block": 80.0, "road": 12.0, "density": 0.6,
		"colors": [Color(0.6, 0.6, 0.62), Color(0.5, 0.55, 0.6), Color(0.7, 0.55, 0.4)]},
	"bohemio": {"floors": [1, 3], "lot": [10.0, 16.0], "block": 44.0, "road": 8.0, "density": 0.85,
		"colors": [Color(0.3, 0.7, 0.75), Color(0.95, 0.75, 0.3), Color(0.85, 0.4, 0.45), Color(0.6, 0.45, 0.8), Color(0.95, 0.95, 0.9)]},
}

const DISTRICTS := [
	{"id": "cercado", "name": "Cercado de Lima", "lat": -12.0464, "lon": -77.0300, "r": 2.0, "style": "casco"},
	{"id": "rimac", "name": "Rímac", "lat": -12.0300, "lon": -77.0330, "r": 2.2, "style": "popular"},
	{"id": "agustino", "name": "El Agustino", "lat": -12.0600, "lon": -77.0100, "r": 1.8, "style": "cerro"},
	{"id": "victoria", "name": "La Victoria", "lat": -12.0680, "lon": -77.0200, "r": 1.8, "style": "comercial"},
	{"id": "sanluis", "name": "San Luis", "lat": -12.0770, "lon": -77.0100, "r": 1.0, "style": "residencial"},
	{"id": "santaanita", "name": "Santa Anita", "lat": -12.0450, "lon": -76.9700, "r": 2.0, "style": "popular"},
	{"id": "ate", "name": "Ate", "lat": -12.0500, "lon": -76.9400, "r": 3.5, "style": "industrial"},
	{"id": "sjl", "name": "San Juan de Lurigancho", "lat": -12.0050, "lon": -77.0000, "r": 4.5, "style": "cerro"},
	{"id": "brena", "name": "Breña", "lat": -12.0560, "lon": -77.0500, "r": 1.0, "style": "popular"},
	{"id": "pueblolibre", "name": "Pueblo Libre", "lat": -12.0720, "lon": -77.0630, "r": 1.3, "style": "residencial"},
	{"id": "jesusmaria", "name": "Jesús María", "lat": -12.0700, "lon": -77.0510, "r": 1.1, "style": "residencial"},
	{"id": "lince", "name": "Lince", "lat": -12.0840, "lon": -77.0360, "r": 0.9, "style": "residencial"},
	{"id": "sanisidro", "name": "San Isidro", "lat": -12.0980, "lon": -77.0360, "r": 1.6, "style": "torres"},
	{"id": "magdalena", "name": "Magdalena del Mar", "lat": -12.0900, "lon": -77.0700, "r": 1.4, "style": "residencial"},
	{"id": "sanmiguel", "name": "San Miguel", "lat": -12.0780, "lon": -77.0850, "r": 2.0, "style": "residencial"},
	{"id": "miraflores", "name": "Miraflores", "lat": -12.1200, "lon": -77.0290, "r": 1.8, "style": "torres"},
	{"id": "surquillo", "name": "Surquillo", "lat": -12.1100, "lon": -77.0100, "r": 1.3, "style": "popular"},
	{"id": "barranco", "name": "Barranco", "lat": -12.1500, "lon": -77.0200, "r": 1.4, "style": "bohemio"},
	{"id": "chorrillos", "name": "Chorrillos", "lat": -12.1700, "lon": -77.0150, "r": 2.5, "style": "popular"},
	{"id": "surco", "name": "Santiago de Surco", "lat": -12.1400, "lon": -76.9950, "r": 3.5, "style": "residencial"},
	{"id": "sanborja", "name": "San Borja", "lat": -12.1050, "lon": -76.9980, "r": 1.8, "style": "residencial"},
	{"id": "lamolina", "name": "La Molina", "lat": -12.0850, "lon": -76.9300, "r": 4.0, "style": "residencial"},
	{"id": "independencia", "name": "Independencia", "lat": -11.9900, "lon": -77.0550, "r": 2.5, "style": "cerro"},
	{"id": "losolivos", "name": "Los Olivos", "lat": -11.9700, "lon": -77.0750, "r": 3.0, "style": "residencial"},
	{"id": "comas", "name": "Comas", "lat": -11.9400, "lon": -77.0500, "r": 3.5, "style": "cerro"},
	{"id": "smp", "name": "San Martín de Porres", "lat": -12.0000, "lon": -77.0900, "r": 3.5, "style": "popular"},
]

# Avenidas principales (ancho en metros de juego)
const AVENUES := [
	{"name": "Av. Javier Prado", "w": 18.0, "pts": [[-12.0895, -77.0640], [-12.0915, -77.0390], [-12.0870, -77.0100], [-12.0860, -76.9750], [-12.0820, -76.9450]]},
	{"name": "Av. Arequipa", "w": 16.0, "pts": [[-12.0536, -77.0376], [-12.0780, -77.0360], [-12.1000, -77.0340], [-12.1190, -77.0310]]},
	{"name": "Vía Expresa", "w": 20.0, "pts": [[-12.0560, -77.0345], [-12.0800, -77.0310], [-12.1100, -77.0260], [-12.1380, -77.0240]]},
	{"name": "Av. Nicolás Ayllón", "w": 18.0, "pts": [[-12.0480, -77.0290], [-12.0450, -77.0150], [-12.0440, -77.0050], [-12.0430, -76.9700], [-12.0420, -76.9350]]},
	{"name": "Av. Túpac Amaru", "w": 16.0, "pts": [[-12.0380, -77.0400], [-12.0100, -77.0550], [-11.9700, -77.0600], [-11.9300, -77.0500]]},
	{"name": "Av. Universitaria", "w": 16.0, "pts": [[-12.0650, -77.0850], [-12.0300, -77.0830], [-11.9900, -77.0780], [-11.9500, -77.0640]]},
	{"name": "Av. Colonial", "w": 16.0, "pts": [[-12.0470, -77.0450], [-12.0480, -77.0800], [-12.0420, -77.1200]]},
	{"name": "Vía de Evitamiento", "w": 20.0, "pts": [[-12.0220, -77.0070], [-12.0550, -76.9980], [-12.0750, -76.9900], [-12.1000, -76.9950]]},
	{"name": "Circuito de Playas", "w": 14.0, "pts": [[-12.0910, -77.0760], [-12.1140, -77.0560], [-12.1300, -77.0450], [-12.1500, -77.0380]]},
	{"name": "Av. Grau - Abancay", "w": 14.0, "pts": [[-12.0560, -77.0330], [-12.0500, -77.0290], [-12.0510, -77.0200], [-12.0600, -77.0150]]},
]

# Hitos. "kind" decide el modelo 3D; "int" es el interior al que se puede entrar.
const LANDMARKS := [
	{"id": "plaza_mayor", "name": "Plaza Mayor y Catedral", "lat": -12.0464, "lon": -77.0300, "kind": "catedral", "int": ""},
	{"id": "plaza_sanmartin", "name": "Plaza San Martín", "lat": -12.0516, "lon": -77.0344, "kind": "plaza", "int": ""},
	{"id": "dosdemayo", "name": "Plaza Dos de Mayo", "lat": -12.0535, "lon": -77.0426, "kind": "plaza", "int": ""},
	{"id": "mali", "name": "Museo de Arte de Lima", "lat": -12.0584, "lon": -77.0356, "kind": "museo", "int": "museo"},
	{"id": "cerro_sc", "name": "Cerro San Cristóbal", "lat": -12.0390, "lon": -77.0310, "kind": "cruz", "int": ""},
	{"id": "acho", "name": "Plaza de Acho", "lat": -12.0397, "lon": -77.0267, "kind": "plaza_toros", "int": ""},
	{"id": "mercado_central", "name": "Mercado Central", "lat": -12.0513, "lon": -77.0237, "kind": "mercado", "int": "bodega"},
	{"id": "gamarra", "name": "Emporio Comercial Gamarra", "lat": -12.0675, "lon": -77.0130, "kind": "emporio", "int": "tienda"},
	{"id": "matute", "name": "Estadio Alejandro Villanueva", "lat": -12.0690, "lon": -77.0215, "kind": "estadio", "int": ""},
	{"id": "estadio_nacional", "name": "Estadio Nacional", "lat": -12.0672, "lon": -77.0333, "kind": "estadio", "int": ""},
	{"id": "parque_reserva", "name": "Parque de la Reserva", "lat": -12.0702, "lon": -77.0345, "kind": "fuente", "int": ""},
	{"id": "campo_marte", "name": "Campo de Marte", "lat": -12.0700, "lon": -77.0436, "kind": "parque", "int": ""},
	{"id": "hospital_dosdemayo", "name": "Hospital Dos de Mayo", "lat": -12.0610, "lon": -77.0160, "kind": "hospital", "int": "hospital"},
	{"id": "comisaria_agustino", "name": "Comisaría de El Agustino", "lat": -12.0580, "lon": -77.0120, "kind": "comisaria", "int": "comisaria"},
	{"id": "polleria_agustino", "name": "Pollería El Buen Sabor", "lat": -12.0625, "lon": -77.0085, "kind": "tienda_chica", "int": "polleria"},
	{"id": "banco_victoria", "name": "Banco Central de la Gente", "lat": -12.0640, "lon": -77.0200, "kind": "banco", "int": "banco"},
	{"id": "parque_leyendas", "name": "Parque de las Leyendas", "lat": -12.0715, "lon": -77.0940, "kind": "parque", "int": ""},
	{"id": "aeropuerto", "name": "Aeropuerto Jorge Chávez", "lat": -12.0219, "lon": -77.1143, "kind": "aeropuerto", "int": ""},
	{"id": "real_plaza_salaverry", "name": "Real Plaza Salaverry", "lat": -12.0894, "lon": -77.0529, "kind": "mall", "int": "tienda"},
	{"id": "olivar", "name": "Parque El Olivar", "lat": -12.1005, "lon": -77.0345, "kind": "parque", "int": ""},
	{"id": "huaca_pucllana", "name": "Huaca Pucllana", "lat": -12.1114, "lon": -77.0334, "kind": "huaca", "int": ""},
	{"id": "parque_kennedy", "name": "Parque Kennedy", "lat": -12.1211, "lon": -77.0297, "kind": "parque", "int": "pizzeria"},
	{"id": "larcomar", "name": "Larcomar", "lat": -12.1319, "lon": -77.0300, "kind": "mall", "int": "tienda"},
	{"id": "puente_suspiros", "name": "Puente de los Suspiros", "lat": -12.1497, "lon": -77.0206, "kind": "puente", "int": ""},
	{"id": "gimnasio_surquillo", "name": "Gimnasio Fuerza Peruana", "lat": -12.1090, "lon": -77.0120, "kind": "tienda_chica", "int": "gimnasio"},
	{"id": "jockey_plaza", "name": "Jockey Plaza", "lat": -12.0850, "lon": -76.9747, "kind": "mall", "int": "tienda"},
	{"id": "monumental", "name": "Estadio Monumental", "lat": -12.0561, "lon": -76.9427, "kind": "estadio", "int": ""},
	{"id": "plaza_norte", "name": "Mall Plaza Norte", "lat": -11.9945, "lon": -77.0603, "kind": "mall", "int": "tienda"},
	{"id": "cerro_agustino", "name": "Cerro El Agustino", "lat": -12.0540, "lon": -76.9990, "kind": "cruz", "int": ""},
]

# Bandas inventadas, inspiradas en la realidad pero sin copiar casos reales
const GANGS := [
	{"id": "cuervos", "name": "Los Cuervos de Gamarra", "lat": -12.0675, "lon": -77.0130, "r": 1.0, "color": Color(0.1, 0.1, 0.1), "desc": "Cobran cupos a los comerciantes del emporio."},
	{"id": "jauria", "name": "La Jauría del Cerro", "lat": -12.0330, "lon": -77.0310, "r": 1.2, "color": Color(0.6, 0.1, 0.1), "desc": "Controlan las faldas del cerro y los mototaxis."},
	{"id": "halcones", "name": "Los Halcones de Lurigancho", "lat": -12.0050, "lon": -77.0000, "r": 2.0, "color": Color(0.8, 0.6, 0.1), "desc": "Roban carga en la Evitamiento."},
	{"id": "lobos", "name": "Los Lobos de la Costa Verde", "lat": -12.1650, "lon": -77.0200, "r": 1.5, "color": Color(0.1, 0.4, 0.7), "desc": "Asaltan en las playas al atardecer."},
	{"id": "zorros", "name": "Los Zorros de Comas", "lat": -11.9450, "lon": -77.0500, "r": 2.0, "color": Color(0.3, 0.6, 0.2), "desc": "Se disputan el control de las combis."},
]

const COAST := [
	[-11.90, -77.140], [-12.04, -77.150], [-12.075, -77.125], [-12.095, -77.080],
	[-12.125, -77.045], [-12.150, -77.032], [-12.20, -77.020],
]

static var _district_pos: Array = []
static var _gang_pos: Array = []


static func to_local(lat: float, lon: float) -> Vector3:
	return Vector3((lon - ORIGIN_LON) * M_PER_DEG_LON * SCALE, 0.0, -(lat - ORIGIN_LAT) * M_PER_DEG_LAT * SCALE)


static func to_latlon(p: Vector3) -> Vector2:
	var lat := ORIGIN_LAT - p.z / (M_PER_DEG_LAT * SCALE)
	var lon := ORIGIN_LON + p.x / (M_PER_DEG_LON * SCALE)
	return Vector2(lat, lon)


static func km_to_game(km: float) -> float:
	return km * 1000.0 * SCALE


static func coast_lon(lat: float) -> float:
	for i in range(COAST.size() - 1):
		var a: Array = COAST[i]
		var b: Array = COAST[i + 1]
		if lat <= a[0] and lat >= b[0]:
			var t: float = (a[0] - lat) / (a[0] - b[0])
			return lerpf(a[1], b[1], t)
	return COAST[0][1] if lat > COAST[0][0] else COAST[COAST.size() - 1][1]


static func is_land(p: Vector3) -> bool:
	var ll := to_latlon(p)
	return ll.y > coast_lon(ll.x)


static func in_bounds(p: Vector3) -> bool:
	var ll := to_latlon(p)
	return ll.x >= BOUNDS_LAT.x and ll.x <= BOUNDS_LAT.y and ll.y >= BOUNDS_LON.x and ll.y <= BOUNDS_LON.y


static func world_rect() -> Rect2:
	var a := to_local(BOUNDS_LAT.y, BOUNDS_LON.x)  # noroeste
	var b := to_local(BOUNDS_LAT.x, BOUNDS_LON.y)  # sureste
	return Rect2(Vector2(a.x, a.z), Vector2(b.x - a.x, b.z - a.z))


static func district_at(p: Vector3) -> Dictionary:
	if _district_pos.is_empty():
		for d in DISTRICTS:
			_district_pos.append(to_local(d["lat"], d["lon"]))
	var best := 0
	var best_v := INF
	for i in range(DISTRICTS.size()):
		var c: Vector3 = _district_pos[i]
		var v := Vector2(p.x - c.x, p.z - c.z).length() / km_to_game(DISTRICTS[i]["r"])
		if v < best_v:
			best_v = v
			best = i
	return DISTRICTS[best]


static func gang_at(p: Vector3) -> Dictionary:
	if _gang_pos.is_empty():
		for g in GANGS:
			_gang_pos.append(to_local(g["lat"], g["lon"]))
	for i in range(GANGS.size()):
		var c: Vector3 = _gang_pos[i]
		if Vector2(p.x - c.x, p.z - c.z).length() < km_to_game(GANGS[i]["r"]):
			return GANGS[i]
	return {}


static func home_position() -> Vector3:
	return Vector3(0.0, 0.0, 0.0)
