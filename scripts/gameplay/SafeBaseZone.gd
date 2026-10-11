class_name SafeBaseZone
extends Area3D

## SafeBaseZone
## Designated sanctuary zone for Infected Base mode (e.g. Tindahan ni Mama).
## Grants runners sheltered refuge against infected tags with limited shelter stamina.

@export var zone_radius: float = 5.5
@export var base_name: String = "Tindahan ni Mama (Ligtas Base)"

@onready var collision_shape: CollisionShape3D = get_node_or_null("CollisionShape3D")
@onready var visual_ring: CSGTorus3D = get_node_or_null("VisualRing")

var pulse_time: float = 0.0

func _ready() -> void:
	add_to_group("safe_bases")
	collision_layer = 0
	collision_mask = 2 # Player layer
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _process(delta: float) -> void:
	if visual_ring:
		pulse_time += delta * 2.5
		var alpha_pulse := 0.65 + 0.35 * sin(pulse_time)
		if visual_ring.material is StandardMaterial3D:
			visual_ring.material.albedo_color.a = alpha_pulse

func is_base_active() -> bool:
	var main = get_node_or_null("/root/Main")
	if main and main.has_method("is_infection"):
		return main.is_infection()
	return true

func _on_body_entered(body: Node3D) -> void:
	if not is_base_active():
		return
	if body is PlayerController and body.has_method("enter_safe_base"):
		body.enter_safe_base()

func _on_body_exited(body: Node3D) -> void:
	if body is PlayerController and body.has_method("exit_safe_base"):
		body.exit_safe_base()
