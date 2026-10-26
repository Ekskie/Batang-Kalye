class_name BananaTrap
extends Node3D

@export var lifetime: float = 35.0
var planter_id: int = -1
var planter_name: String = "Player"
var planter_node: Node = null
var arm_timer: float = 0.8 # Immunity for planter right after dropping
var is_triggered: bool = false
var base_ground_y: float = 0.0
var anim_time: float = 0.0

@onready var visual_root: Node3D = get_node_or_null("VisualRoot")
@onready var area: Area3D = get_node_or_null("Area3D")
@onready var particles: CPUParticles3D = get_node_or_null("SlipParticles")

func setup(p_planter_id: int, p_planter_name: String, drop_pos: Vector3, p_planter_node: Node = null) -> void:
	planter_id = p_planter_id
	planter_name = p_planter_name
	planter_node = p_planter_node
	base_ground_y = drop_pos.y + 0.02
	if is_inside_tree():
		global_position = Vector3(drop_pos.x, base_ground_y, drop_pos.z)
	else:
		position = Vector3(drop_pos.x, base_ground_y, drop_pos.z)

func _ready() -> void:
	add_to_group("banana_traps")
	_build_visuals()
	if area:
		area.body_entered.connect(_on_body_entered)
	call_deferred("_snap_to_ground")

func _snap_to_ground() -> void:
	if not is_inside_tree():
		return
	var space := get_world_3d().direct_space_state
	if space:
		var query := PhysicsRayQueryParameters3D.create(
			Vector3(global_position.x, global_position.y + 1.0, global_position.z),
			Vector3(global_position.x, global_position.y - 4.0, global_position.z)
		)
		query.collision_mask = 1 # Environment/Road only
		var hit := space.intersect_ray(query)
		if hit:
			base_ground_y = hit.position.y + 0.02
			global_position.y = base_ground_y

func _process(delta: float) -> void:
	if arm_timer > 0.0:
		arm_timer -= delta

	lifetime -= delta
	if lifetime <= 0.0 and not is_triggered:
		queue_free()
		return

	anim_time += delta * 2.8
	var map = get_tree().get_first_node_in_group("kalye_maps") if get_tree() else null
	var is_flooded: bool = map.is_flooded if (map and "is_flooded" in map) else false
	var water_y: float = map.FLOOD_HEIGHT_WET if (map and "FLOOD_HEIGHT_WET" in map) else -4.80

	if is_flooded and water_y > base_ground_y:
		# Buoyant floating on flood water surface
		global_position.y = (water_y + 0.02) + sin(anim_time) * 0.02
		if visual_root:
			visual_root.rotation.z = sin(anim_time * 1.5) * 0.05
	else:
		# Resting flat and level on road asphalt
		global_position.y = base_ground_y
		if visual_root:
			visual_root.rotation.z = 0.0

func _on_body_entered(body: Node3D) -> void:
	if is_triggered:
		return

	if body is PlayerController:
		var pc: PlayerController = body as PlayerController
		if (pc.player_id == planter_id or pc == planter_node) and arm_timer > 0.0:
			return # Safe period for planter

		_trigger_slip(pc)

func _trigger_slip(victim: PlayerController) -> void:
	if is_triggered:
		return
	is_triggered = true

	var am = get_node_or_null("/root/AudioManager")
	if am and am.has_method("play_banana_slip"):
		am.play_banana_slip()

	if victim and victim.has_method("apply_banana_slip"):
		victim.call("apply_banana_slip", planter_name)

	var ft = preload("res://scripts/player/FloatingText.gd")
	ft.spawn(get_parent(), global_position + Vector3(0, 1.8, 0), "DULAS!", Color(1.0, 0.9, 0.2))

	if visual_root:
		visual_root.visible = false

	if particles:
		particles.restart()
		get_tree().create_timer(particles.lifetime + 0.1).timeout.connect(queue_free)
	else:
		queue_free()

func _build_visuals() -> void:
	if not visual_root:
		return
	var peel_mat := StandardMaterial3D.new()
	peel_mat.albedo_color = Color(0.96, 0.84, 0.12) # Banana Yellow
	peel_mat.roughness = 0.35

	for i in range(3):
		var petal := MeshInstance3D.new()
		var c := CylinderMesh.new()
		c.top_radius = 0.01
		c.bottom_radius = 0.07
		c.height = 0.38
		petal.mesh = c
		petal.material_override = peel_mat
		petal.rotation_degrees = Vector3(82, i * 120.0, 0)
		petal.position = Vector3(0, 0.02, 0)
		visual_root.add_child(petal)
