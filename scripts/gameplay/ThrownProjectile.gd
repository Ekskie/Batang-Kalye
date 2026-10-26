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
var thrower_node: Node = null
var is_active: bool = true
var target_start_pos: Vector3 = Vector3.ZERO

var visual_mesh: Node3D = null
var area: Area3D = null
var particles: CPUParticles3D = null
var flight_trail: CPUParticles3D = null

func setup(p_type: ProjectileType, start_pos: Vector3, launch_dir: Vector3, p_thrower_id: int, p_thrower_name: String, p_thrower_node: Node = null) -> void:
	projectile_type = p_type
	target_start_pos = start_pos
	thrower_id = p_thrower_id
	thrower_name = p_thrower_name
	thrower_node = p_thrower_node
	velocity = launch_dir.normalized() * speed + Vector3(0, 1.5, 0)

	if is_inside_tree():
		global_position = start_pos
	else:
		position = start_pos

	_ensure_references()
	_build_visuals()
	_setup_flight_trail()

func _ensure_references() -> void:
	if not visual_mesh:
		visual_mesh = get_node_or_null("VisualMesh")
	if not area:
		area = get_node_or_null("Area3D")
	if not particles:
		particles = get_node_or_null("ImpactParticles")

func _ready() -> void:
	_ensure_references()

	if target_start_pos != Vector3.ZERO:
		global_position = target_start_pos

	if not visual_mesh or visual_mesh.get_child_count() == 0:
		_build_visuals()

	if not flight_trail:
		_setup_flight_trail()

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

	# Out-of-bounds safety check (only if projectile falls into the map void)
	if global_position.y < -15.0:
		_impact(null, global_position)

func _on_body_entered(body: Node3D) -> void:
	if not is_active:
		return

	# Ignore thrower completely (reference and ID)
	if body == thrower_node:
		return
	if body is PlayerController:
		var pc: PlayerController = body as PlayerController
		if pc.player_id == thrower_id or (thrower_node and pc == thrower_node):
			return # Don't hit self
		_impact(pc, global_position)
	elif body is StaticBody3D or body is CSGBox3D or body is GridMap:
		# Hit environment terrain (asphalt road, sidewalk, wall, obstacle)
		_impact(null, global_position)

func _impact(hit_target: PlayerController, impact_pos: Vector3) -> void:
	if not is_active:
		return
	is_active = false

	# Stop trail emitter immediately
	if flight_trail:
		flight_trail.emitting = false

	if projectile_type == ProjectileType.TSINELAS:
		if hit_target:
			var am = get_node_or_null("/root/AudioManager")
			if am and am.has_method("play_tsinelas_slap"):
				am.play_tsinelas_slap()

			hit_target.call("apply_slipper_stun", 1.4, thrower_name)
			var players := get_tree().get_nodes_in_group("players")
			for p in players:
				if p is PlayerController and p.player_id == thrower_id:
					p.stats_hits += 1
					break
			var ft = preload("res://scripts/player/FloatingText.gd")
			ft.spawn(get_parent(), hit_target.global_position + Vector3(0, 2.2, 0), "SAPUL!", Color(0.2, 0.8, 1.0))
		else:
			var am_drop = get_node_or_null("/root/AudioManager")
			if am_drop and am_drop.has_method("play_drop"):
				am_drop.play_drop()

	elif projectile_type == ProjectileType.CHALK_BAG:
		var am_puff = get_node_or_null("/root/AudioManager")
		if am_puff and am_puff.has_method("play_chalk_puff"):
			am_puff.play_chalk_puff()

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

	# Find all runners within 5.2m of chalk impact (excluding thrower)
	var all_players = get_tree().get_nodes_in_group("players")
	for p in all_players:
		if p is PlayerController and not p.is_eliminated:
			if p.player_id == thrower_id or p == thrower_node:
				continue # Thrower never blinds themselves
			if p.current_role == PlayerController.Role.RUNNER:
				if p.global_position.distance_to(center_pos) <= 5.2:
					p.call("apply_chalk_blind", 4.0)

func _setup_flight_trail() -> void:
	if flight_trail:
		flight_trail.queue_free()
		flight_trail = null

	flight_trail = CPUParticles3D.new()
	flight_trail.name = "FlightTrail"

	var trail_mat := StandardMaterial3D.new()
	trail_mat.shading_mode = StandardMaterial3D.SHADING_MODE_UNSHADED
	trail_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA

	var sphere_mesh := SphereMesh.new()

	if projectile_type == ProjectileType.TSINELAS:
		# Wind streak / comic motion trail
		trail_mat.albedo_color = Color(0.6, 0.85, 1.0, 0.45)
		sphere_mesh.radius = 0.08
		sphere_mesh.height = 0.16
		flight_trail.amount = 14
		flight_trail.lifetime = 0.25
		flight_trail.scale_amount_min = 0.8
		flight_trail.scale_amount_max = 0.2
	else:
		# Chalk dust powder trail
		trail_mat.albedo_color = Color(0.96, 0.96, 0.98, 0.6)
		sphere_mesh.radius = 0.12
		sphere_mesh.height = 0.24
		flight_trail.amount = 22
		flight_trail.lifetime = 0.4
		flight_trail.scale_amount_min = 0.9
		flight_trail.scale_amount_max = 0.3

	sphere_mesh.material = trail_mat
	flight_trail.mesh = sphere_mesh
	flight_trail.gravity = Vector3(0, -0.6, 0)
	flight_trail.initial_velocity_min = 0.2
	flight_trail.initial_velocity_max = 0.6
	flight_trail.spread = 35.0
	flight_trail.emitting = true
	add_child(flight_trail)

func _build_visuals() -> void:
	_ensure_references()
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
		sole_mat.roughness = 0.5
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
		chalk_mat.roughness = 0.9
		sack.material_override = chalk_mat
		visual_mesh.add_child(sack)
