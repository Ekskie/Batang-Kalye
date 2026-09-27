class_name CharacterAnimator
extends Node3D

@export var is_taya: bool = false:
	set(value):
		is_taya = value
		_update_taya_visuals()

@onready var body_mesh: MeshInstance3D = $Torso
@onready var head_mesh: MeshInstance3D = $Torso/Head
@onready var left_arm: Node3D = $Torso/LeftArmPivot
@onready var right_arm: Node3D = $Torso/RightArmPivot
@onready var left_leg: Node3D = $LeftLegPivot
@onready var right_leg: Node3D = $RightLegPivot
@onready var taya_aura: Node3D = $TayaAura
@onready var taya_badge: Label3D = $TayaBadge

var walk_cycle_time: float = 0.0
var is_tag_swinging: bool = false
var tag_swing_timer: float = 0.0
var tag_swing_duration: float = 0.35

var runner_mat: Material = preload("res://assets/materials/mat_runner.tres")
var taya_mat: Material = preload("res://assets/materials/mat_taya_glow.tres")
var current_player_color: Color = Color(0.18, 0.58, 0.95, 1.0)

func _ready() -> void:
	_update_taya_visuals()

func _update_taya_visuals() -> void:
	if not is_inside_tree():
		return
	if taya_aura:
		taya_aura.visible = is_taya
	if taya_badge:
		taya_badge.visible = is_taya
	if body_mesh:
		if is_taya:
			body_mesh.material_override = taya_mat
		else:
			var custom_mat := StandardMaterial3D.new()
			custom_mat.albedo_color = current_player_color
			custom_mat.roughness = 0.5
			body_mesh.material_override = custom_mat

func set_player_color(col: Color) -> void:
	current_player_color = col
	if not is_taya and is_inside_tree() and body_mesh:
		var custom_mat := StandardMaterial3D.new()
		custom_mat.albedo_color = col
		custom_mat.roughness = 0.5
		body_mesh.material_override = custom_mat

func trigger_tag_animation() -> void:
	is_tag_swinging = true
	tag_swing_timer = tag_swing_duration

var is_sliding: bool = false
var is_dashing: bool = false

func animate(delta: float, horizontal_speed: float, is_on_floor: bool, max_speed: float) -> void:
	# Tag action animation override for right arm
	if is_tag_swinging:
		tag_swing_timer -= delta
		var progress: float = 1.0 - (tag_swing_timer / tag_swing_duration)
		# Rapid slap forward and back
		var swing_angle: float = sin(progress * PI) * 1.8
		if right_arm:
			right_arm.rotation.x = -swing_angle
			right_arm.rotation.y = sin(progress * PI) * 0.8
		if tag_swing_timer <= 0.0:
			is_tag_swinging = false
			if right_arm:
				right_arm.rotation = Vector3.ZERO

	# Dash pose (Naruto forward lean & arms trailing)
	if is_dashing:
		if body_mesh:
			body_mesh.position.y = lerp(body_mesh.position.y, 0.45, delta * 15.0)
			body_mesh.rotation.x = lerp_angle(body_mesh.rotation.x, deg_to_rad(35.0), delta * 15.0)
		if left_arm and not is_tag_swinging:
			left_arm.rotation.x = lerp_angle(left_arm.rotation.x, deg_to_rad(70.0), delta * 15.0)
		if right_arm and not is_tag_swinging:
			right_arm.rotation.x = lerp_angle(right_arm.rotation.x, deg_to_rad(70.0), delta * 15.0)
		if left_leg and right_leg:
			left_leg.rotation.x = lerp_angle(left_leg.rotation.x, deg_to_rad(-20.0), delta * 15.0)
			right_leg.rotation.x = lerp_angle(right_leg.rotation.x, deg_to_rad(-20.0), delta * 15.0)
		return

	# Slide pose (Lean back, feet forward, ground skid)
	if is_sliding:
		if body_mesh:
			body_mesh.position.y = lerp(body_mesh.position.y, 0.35, delta * 15.0)
			body_mesh.rotation.x = lerp_angle(body_mesh.rotation.x, deg_to_rad(-30.0), delta * 15.0)
		if left_leg and right_leg:
			left_leg.rotation.x = lerp_angle(left_leg.rotation.x, deg_to_rad(65.0), delta * 15.0)
			right_leg.rotation.x = lerp_angle(right_leg.rotation.x, deg_to_rad(55.0), delta * 15.0)
		if left_arm and not is_tag_swinging:
			left_arm.rotation.x = lerp_angle(left_arm.rotation.x, deg_to_rad(-40.0), delta * 15.0)
		if right_arm and not is_tag_swinging:
			right_arm.rotation.x = lerp_angle(right_arm.rotation.x, deg_to_rad(-40.0), delta * 15.0)
		return

	if not is_on_floor:
		# Jump pose
		if body_mesh:
			body_mesh.position.y = lerp(body_mesh.position.y, 0.7, delta * 10.0)
			body_mesh.rotation.x = lerp_angle(body_mesh.rotation.x, 0.0, delta * 10.0)
		if left_leg and right_leg:
			left_leg.rotation.x = lerp_angle(left_leg.rotation.x, deg_to_rad(35.0), delta * 10.0)
			right_leg.rotation.x = lerp_angle(right_leg.rotation.x, deg_to_rad(-25.0), delta * 10.0)
		if left_arm and not is_tag_swinging:
			left_arm.rotation.x = lerp_angle(left_arm.rotation.x, deg_to_rad(-60.0), delta * 10.0)
		return

	if horizontal_speed > 0.3:
		# Running / walking animation
		var run_ratio: float = clamp(horizontal_speed / max_speed, 0.2, 1.6)
		walk_cycle_time += delta * 14.0 * run_ratio

		var leg_swing: float = sin(walk_cycle_time) * 0.75 * run_ratio
		var arm_swing: float = cos(walk_cycle_time) * 0.75 * run_ratio
		var vertical_bob: float = abs(sin(walk_cycle_time * 2.0)) * 0.08 * run_ratio

		if left_leg:
			left_leg.rotation.x = leg_swing
		if right_leg:
			right_leg.rotation.x = -leg_swing

		if left_arm:
			left_arm.rotation.x = -arm_swing
		if right_arm and not is_tag_swinging:
			right_arm.rotation.x = arm_swing

		# Subtle body tilt forward when running fast
		if body_mesh:
			body_mesh.position.y = 0.7 + vertical_bob
			body_mesh.rotation.x = deg_to_rad(10.0 * run_ratio)
	else:
		# Idle breathing
		walk_cycle_time += delta * 2.5
		var idle_breath: float = sin(walk_cycle_time) * 0.02
		
		if body_mesh:
			body_mesh.position.y = 0.7 + idle_breath
			body_mesh.rotation.x = lerp_angle(body_mesh.rotation.x, 0.0, delta * 8.0)
		if left_leg:
			left_leg.rotation.x = lerp_angle(left_leg.rotation.x, 0.0, delta * 8.0)
		if right_leg:
			right_leg.rotation.x = lerp_angle(right_leg.rotation.x, 0.0, delta * 8.0)
		if left_arm:
			left_arm.rotation.x = lerp_angle(left_arm.rotation.x, 0.0, delta * 8.0)
		if right_arm and not is_tag_swinging:
			right_arm.rotation.x = lerp_angle(right_arm.rotation.x, 0.0, delta * 8.0)

	# Rotate aura if Taya
	if is_taya and taya_aura:
		taya_aura.rotate_y(delta * 2.5)
		var inner := taya_aura.get_node_or_null("InnerRing")
		if inner:
			inner.rotate_y(delta * -4.5)
