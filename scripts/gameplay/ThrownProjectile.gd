class_name ThrownProjectile
extends Node3D

enum ProjectileType {
	TSINELAS = 0,
	CHALK_BAG = 1
}

@export var projectile_type: ProjectileType = ProjectileType.TSINELAS
@export var speed: float = 24.0
@export var gravity: float = -9.0
@export var lifetime: float = 2.5

var velocity: Vector3 = Vector3.ZERO
var thrower_id: int = -1
var thrower_name: String = "Player"
var is_active: bool = true

@onready var visual_mesh: Node3D = get_node_or_null("VisualMesh")
@onready var area: Area3D = get_node_or_null("Area3D")
@onready var particles: CPUParticles3D = get_node_or_null("ImpactParticles")

func setup(p_type: ProjectileType, start_pos: Vector3, launch_dir: Vector3, p_thrower_id: int, p_thrower_name: String) -> void:
	projectile_type = p_type
	global_position = start_pos
	thrower_id = p_thrower_id
	thrower_name = p_thrower_name
	velocity = launch_dir.normalized() * speed + Vector3(0, 1.5, 0)
	_build_visuals()

func _ready() -> void:
	if area:
		area.body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	if not is_active:
		return

	lifetime -= delta
	if lifetime <= 0.0:
		_impact(null, global_position)
		return

	# Apply gravity & movement
	velocity.y += gravity * delta
	global_position += velocity * delta

	# Tumble animation in air
	if visual_mesh:
		if projectile_type == ProjectileType.TSINELAS:
			visual_mesh.rotate_x(delta * 22.0)
			visual_mesh.rotate_y(delta * 8.0)
		else:
			visual_mesh.rotate_z(delta * 14.0)

	# Floor collision check
	if global_position.y <= 0.2:
		_impact(null, global_position)

func _on_body_entered(body: Node3D) -> void:
	if not is_active:
		return

	if body is PlayerController:
		var pc: PlayerController = body as PlayerController
		if pc.player_id == thrower_id:
			return # Don't hit self
		_impact(pc, global_position)

func _impact(hit_target: PlayerController, impact_pos: Vector3) -> void:
	if not is_active:
		return
	is_active = false

	if projectile_type == ProjectileType.TSINELAS:
		if hit_target:
			if Engine.has_singleton("AudioManager"):
				AudioManager.play_tsinelas_slap()
			elif has_node("/root/AudioManager"):
				get_node("/root/AudioManager").play_tsinelas_slap()

			hit_target.call("apply_slipper_stun", 1.4, thrower_name)
			var players := get_tree().get_nodes_in_group("players")
			for p in players:
				if p is PlayerController and p.player_id == thrower_id:
					p.stats_hits += 1
					break
			var ft = preload("res://scripts/player/FloatingText.gd")
			ft.spawn(get_parent(), hit_target.global_position + Vector3(0, 2.2, 0), "SAPUL!", Color(0.2, 0.8, 1.0))
		else:
			if Engine.has_singleton("AudioManager"):
				AudioManager.play_drop()
			elif has_node("/root/AudioManager"):
				get_node("/root/AudioManager").play_drop()

	elif projectile_type == ProjectileType.CHALK_BAG:
		if Engine.has_singleton("AudioManager"):
			AudioManager.play_chalk_puff()
		elif has_node("/root/AudioManager"):
			get_node("/root/AudioManager").play_chalk_puff()

		_spawn_chalk_cloud(impact_pos)

	if visual_mesh:
		visual_mesh.visible = false

	if particles:
		particles.restart()
		get_tree().create_timer(particles.lifetime + 0.1).timeout.connect(queue_free)
	else:
		queue_free()

func _spawn_chalk_cloud(center_pos: Vector3) -> void:
	var ft = preload("res://scripts/player/FloatingText.gd")
	ft.spawn(get_parent(), center_pos + Vector3(0, 1.8, 0), "CHALK DUST!", Color(0.95, 0.95, 1.0))

	# Find all runners within 5.0m of chalk impact
	var all_players = get_tree().get_nodes_in_group("players")
	for p in all_players:
		if p is PlayerController and not p.is_eliminated:
			if p.current_role == PlayerController.Role.RUNNER:
				if p.global_position.distance_to(center_pos) <= 5.2:
					p.call("apply_chalk_blind", 4.0)

func _build_visuals() -> void:
	if not visual_mesh:
		return
	for c in visual_mesh.get_children():
		c.queue_free()

	if projectile_type == ProjectileType.TSINELAS:
		var sole := MeshInstance3D.new()
		var b := BoxMesh.new()
		b.size = Vector3(0.25, 0.06, 0.55)
		sole.mesh = b
		var sole_mat := StandardMaterial3D.new()
		sole_mat.albedo_color = Color(0.12, 0.45, 0.9) # Spartan Blue
		sole.material_override = sole_mat
		visual_mesh.add_child(sole)

		var strap := MeshInstance3D.new()
		var t_mesh := TorusMesh.new()
		t_mesh.inner_radius = 0.08
		t_mesh.outer_radius = 0.14
		strap.mesh = t_mesh
		strap.position = Vector3(0, 0.07, -0.05)
		strap.rotation_degrees = Vector3(90, 0, 0)
		strap.scale = Vector3(1.0, 0.3, 0.8)
		var strap_mat := StandardMaterial3D.new()
		strap_mat.albedo_color = Color(0.95, 0.95, 0.95)
		strap.material_override = strap_mat
		visual_mesh.add_child(strap)
	else:
		var sack := MeshInstance3D.new()
		var s := SphereMesh.new()
		s.radius = 0.22
		s.height = 0.38
		sack.mesh = s
		var chalk_mat := StandardMaterial3D.new()
		chalk_mat.albedo_color = Color(0.95, 0.95, 0.98)
		sack.material_override = chalk_mat
		visual_mesh.add_child(sack)
