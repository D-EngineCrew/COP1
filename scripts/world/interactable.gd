class_name Interactable
extends Area3D
## Zona con la que el jugador puede interactuar (puertas, tiendas, camas...).

var prompt := "Interactuar"
var callback := Callable()


static func make(parent: Node, text: String, pos: Vector3, cb: Callable, radius := 1.6) -> Interactable:
	var a := Interactable.new()
	a.prompt = text
	a.callback = cb
	a.collision_layer = 1 << 4
	a.collision_mask = 0
	a.monitoring = false
	var cs := CollisionShape3D.new()
	var sp := SphereShape3D.new()
	sp.radius = radius
	cs.shape = sp
	a.add_child(cs)
	a.position = pos
	parent.add_child(a)
	return a


func interact(player: Node) -> void:
	if callback.is_valid():
		callback.call(player)
