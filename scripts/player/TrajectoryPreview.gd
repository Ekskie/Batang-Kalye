class_name TrajectoryPreview
extends Node3D

# TrajectoryPreview.gd
# Dynamic 3D arc trajectory line and landing reticle preview for thrown street items (Tsinelas, Chalk, etc.)

var line_mesh_instance: MeshInstance3D
var immediate_mesh: ImmediateMesh
var landing_marker: Node3D
var landing_mesh_instance: MeshInstance3D
var line_material: StandardMaterial3D
var marker_material: StandardMaterial3D

var is_locked_on_player: bool = false
var has_hit: bool = false
var hit_point: Vector3 = Vector3.ZERO
var hit_normal: Vector3 = Vector3.UP
var hit_collider: Object = null

const COLOR_DEFAULT := Color(0.25, 0.85, 1.0, 0.9) # Comic Cyan
const COLOR_LOCKED := Color(1.0, 0.35, 0.25, 0.95) # Red-Orange Lock-on
const COLOR_GROUND := Color(1.0, 0.9, 0.25, 0.9)  # Golden Landing

func _ready() -> void:
	top_level = true # Independent of player rotation to avoid jitter
	_setup_visuals()
	visible = false

func _setup_visuals() -> void:
	# 1. Line Material
	line_material = StandardMaterial3D.new()
	line_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	line_material.albedo_color = COLOR_DEFAULT
	line_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA

	immediate_mesh = ImmediateMesh.new()
	line_mesh_instance = MeshInstance3D.new()
	line_mesh_instance.mesh = immediate_mesh
	add_child(line_mesh_instance)

	# 2. Landing Reticle Marker
	landing_marker = Node3D.new()
	landing_marker.name = "LandingMarker"
	add_child(landing_marker)

	marker_material = StandardMaterial3D.new()
	marker_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	marker_material.albedo_color = COLOR_DEFAULT
	marker_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA

	var torus := TorusMesh.new()
	torus.inner_radius = 0.32
	torus.outer_radius = 0.42
	torus.material = marker_material

	landing_mesh_instance = MeshInstance3D.new()
	landing_mesh_instance.mesh = torus
	landing_marker.add_child(landing_mesh_instance)

func update_trajectory(origin: Vector3, initial_vel: Vector3, gravity_accel: float, space_state: PhysicsDirectSpaceState3D, exclude_rids: Array[RID]) -> Dictionary:
	visible = true
	immediate_mesh.clear_surfaces()

	var points: Array[Vector3] = []
	var cur_pos: Vector3 = origin
	var cur_vel: Vector3 = initial_vel
	var dt: float = 0.04
	var max_steps: int = 32

	has_hit = false
	hit_collider = null
	is_locked_on_player = false
	points.append(cur_pos)

	for _i in range(max_steps):
		var next_vel := cur_vel + Vector3(0.0, gravity_accel, 0.0) * dt
		var next_pos := cur_pos + (cur_vel + next_vel) * 0.5 * dt

		if space_state:
			var query := PhysicsRayQueryParameters3D.create(cur_pos, next_pos, 1 | 2, exclude_rids)
			var ray_hit := space_state.intersect_ray(query)
			if not ray_hit.is_empty():
				has_hit = true
				hit_point = ray_hit.position
				hit_normal = ray_hit.normal
				hit_collider = ray_hit.collider
				points.append(hit_point)
				if hit_collider and (hit_collider.is_in_group("players") or "player_id" in hit_collider):
					is_locked_on_player = true
				break

		points.append(next_pos)
		cur_pos = next_pos
		cur_vel = next_vel

	# Choose color based on target
	var active_color: Color = COLOR_LOCKED if is_locked_on_player else (COLOR_GROUND if has_hit else COLOR_DEFAULT)
	line_material.albedo_color = active_color
	marker_material.albedo_color = active_color

	# Draw parabolic line strip
	if points.size() >= 2:
		immediate_mesh.surface_begin(Mesh.PRIMITIVE_LINE_STRIP, line_material)
		for p in points:
			immediate_mesh.surface_add_vertex(p)
		immediate_mesh.surface_end()

	# Update landing marker position & orientation
	if has_hit:
		landing_marker.visible = true
		landing_marker.global_position = hit_point + hit_normal * 0.03
		# Align ring normal with hit normal
		if abs(hit_normal.y) < 0.99:
			var up_vec := Vector3.UP
			var right_vec := hit_normal.cross(up_vec).normalized()
			var forward_vec := right_vec.cross(hit_normal).normalized()
			landing_marker.global_basis = Basis(right_vec, hit_normal, forward_vec)
		else:
			landing_marker.global_basis = Basis.IDENTITY
	else:
		landing_marker.visible = false

	return {
		"has_hit": has_hit,
		"hit_point": hit_point,
		"hit_normal": hit_normal,
		"is_locked": is_locked_on_player,
		"collider": hit_collider
	}

func hide_preview() -> void:
	visible = false
	if immediate_mesh:
		immediate_mesh.clear_surfaces()
	if landing_marker:
		landing_marker.visible = false
