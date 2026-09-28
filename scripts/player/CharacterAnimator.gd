class_name CharacterAnimator
extends Node3D

@export var is_taya: bool = false:
	set(value):
		is_taya = value
		_update_taya_visuals()

# Bataanimation GLB Model references
@onready var bata_model: Node3D = get_node_or_null("Bataanimation")
@onready var bata_anim: AnimationPlayer = get_node_or_null("Bataanimation/AnimationPlayer")
@onready var bata_mesh: MeshInstance3D = get_node_or_null("Bataanimation/Armature_003/Skeleton3D/pCube7")

# Legacy / Fallback primitive nodes
@onready var body_mesh: MeshInstance3D = get_node_or_null("Torso")
@onready var head_mesh: MeshInstance3D = get_node_or_null("Torso/Head")
@onready var left_arm: Node3D = get_node_or_null("Torso/LeftArmPivot")
@onready var right_arm: Node3D = get_node_or_null("Torso/RightArmPivot")
@onready var left_leg: Node3D = get_node_or_null("LeftLegPivot")
@onready var right_leg: Node3D = get_node_or_null("RightLegPivot")

# Taya Visuals
@onready var taya_aura: Node3D = get_node_or_null("TayaAura")
@onready var taya_badge: Label3D = get_node_or_null("TayaBadge")
@onready var taya_flame_particles: CPUParticles3D = get_node_or_null("TayaAura/FlameParticles")

# Held Trash Item Attachments
@onready var held_item_anchor: Node3D = get_node_or_null("HeldItemAnchor") if has_node("HeldItemAnchor") else get_node_or_null("Torso/HeldItemAnchor")
@onready var held_bottle: Node3D = get_node_or_null("HeldItemAnchor/HeldBottle") if has_node("HeldItemAnchor/HeldBottle") else get_node_or_null("Torso/HeldItemAnchor/HeldBottle")
@onready var held_can: Node3D = get_node_or_null("HeldItemAnchor/HeldCan") if has_node("HeldItemAnchor/HeldCan") else get_node_or_null("Torso/HeldItemAnchor/HeldCan")
@onready var held_peel: Node3D = get_node_or_null("HeldItemAnchor/HeldPeel") if has_node("HeldItemAnchor/HeldPeel") else get_node_or_null("Torso/HeldItemAnchor/HeldPeel")
@onready var held_wrapper: Node3D = get_node_or_null("HeldItemAnchor/HeldWrapper") if has_node("HeldItemAnchor/HeldWrapper") else get_node_or_null("Torso/HeldItemAnchor/HeldWrapper")

var walk_cycle_time: float = 0.0
var is_tag_swinging: bool = false
var tag_swing_timer: float = 0.0
var tag_swing_duration: float = 0.40

var is_carrying: bool = false
var held_trash_type: int = -1

var runner_mat: Material = preload("res://assets/materials/mat_runner.tres")
var taya_mat: Material = preload("res://assets/materials/mat_taya_glow.tres")
var current_player_color: Color = Color(0.18, 0.58, 0.95, 1.0)

var is_sliding: bool = false
var is_dashing: bool = false
var has_superspeed: bool = false

var bata_base_pos: Vector3 = Vector3.ZERO
var bata_base_rot_y: float = PI
var held_anchor_base_y: float = 0.70

func _ready() -> void:
	if bata_model:
		bata_base_pos = bata_model.position
		bata_base_rot_y = bata_model.rotation.y
		# Ensure old primitive limbs are hidden
		if body_mesh: body_mesh.visible = false
		if left_leg: left_leg.visible = false
		if right_leg: right_leg.visible = false

	# Setup loop modes for Bataanimation animations
	if bata_anim:
		# Looping locomotion animations
		for a_name in ["idle", "jogging", "running", "narutoRun"]:
			if bata_anim.has_animation(a_name):
				var a := bata_anim.get_animation(a_name)
				a.loop_mode = Animation.LOOP_LINEAR
		# One-shot action animations
		for a_name in ["jump", "punching"]:
			if bata_anim.has_animation(a_name):
				var a := bata_anim.get_animation(a_name)
				a.loop_mode = Animation.LOOP_NONE
		if bata_anim.has_animation("idle"):
			bata_anim.play("idle")

	if held_item_anchor:
		held_anchor_base_y = held_item_anchor.position.y

	_update_taya_visuals()
	set_held_trash(-1)

func _update_taya_visuals() -> void:
	if not is_inside_tree():
		return
	if taya_aura:
		taya_aura.visible = is_taya
	if taya_flame_particles:
		taya_flame_particles.emitting = is_taya
	if taya_badge:
		taya_badge.visible = is_taya

	# Update materials on Bata character model
	if is_taya:
		if bata_mesh:
			bata_mesh.material_override = taya_mat
		if body_mesh:
			body_mesh.material_override = taya_mat
	else:
		var custom_mat := StandardMaterial3D.new()
		custom_mat.albedo_color = current_player_color
		custom_mat.roughness = 0.5
		if bata_mesh:
			bata_mesh.material_override = custom_mat
		if body_mesh:
			body_mesh.material_override = custom_mat

func set_player_color(col: Color) -> void:
	current_player_color = col
	if not is_taya and is_inside_tree():
		var custom_mat := StandardMaterial3D.new()
		custom_mat.albedo_color = col
		custom_mat.roughness = 0.5
		if bata_mesh:
			bata_mesh.material_override = custom_mat
		if body_mesh:
			body_mesh.material_override = custom_mat

func set_held_trash(trash_type: int) -> void:
	held_trash_type = trash_type
	is_carrying = (trash_type != -1)
	if held_item_anchor:
		held_item_anchor.visible = is_carrying
	if held_bottle: held_bottle.visible = (trash_type == 0)
	if held_can: held_can.visible = (trash_type == 1)
	if held_peel: held_peel.visible = (trash_type == 2)
	if held_wrapper: held_wrapper.visible = (trash_type == 3)

func trigger_tag_animation() -> void:
	is_tag_swinging = true
	tag_swing_timer = tag_swing_duration
	if bata_anim and bata_anim.has_animation("punching"):
		bata_anim.play("punching", 0.08)
		bata_anim.speed_scale = 2.2 # Snappy 0.4s tag punch strike

func animate(delta: float, horizontal_speed: float, is_on_floor: bool, max_speed: float) -> void:
	# Check if Naruto Run should be active:
	# Triggered by Super Speed powerup, Kidlat Dash, or ultra-high velocity
	var using_naruto: bool = (has_superspeed or is_dashing or horizontal_speed > 13.0)

	# 1. Skeletal Animation State Machine
	if bata_anim:
		if is_tag_swinging and bata_anim.has_animation("punching"):
			# Let the tag punch animation finish without interruption
			pass
		elif not is_on_floor:
			# In air (jump / fall / luksong-tinik double jump): play jump animation
			if bata_anim.has_animation("jump"):
				if bata_anim.current_animation != "jump":
					bata_anim.play("jump", 0.12)
				bata_anim.speed_scale = 1.2
			elif horizontal_speed > 3.0:
				if bata_anim.current_animation != "jogging":
					bata_anim.play("jogging", 0.2)
				bata_anim.speed_scale = 0.8
			else:
				if bata_anim.current_animation != "idle":
					bata_anim.play("idle", 0.2)
				bata_anim.speed_scale = 0.8
		else:
			# On floor: switch based on movement speed and powerups
			if horizontal_speed > 0.3:
				if using_naruto and bata_anim.has_animation("narutoRun"):
					# Super Speed / Kidlat Dash: Naruto Run!
					if bata_anim.current_animation != "narutoRun":
						bata_anim.play("narutoRun", 0.15)
					bata_anim.speed_scale = clamp(horizontal_speed / 11.5, 1.0, 2.4)
				elif horizontal_speed > 8.0 and bata_anim.has_animation("running"):
					# Fast sprint
					if bata_anim.current_animation != "running":
						bata_anim.play("running", 0.15)
					bata_anim.speed_scale = clamp(horizontal_speed / 11.5, 0.85, 1.8)
				elif bata_anim.has_animation("jogging"):
					# Normal walk / jog
					if bata_anim.current_animation != "jogging":
						bata_anim.play("jogging", 0.15)
					bata_anim.speed_scale = clamp(horizontal_speed / 7.0, 0.75, 1.4)
			else:
				# Standing idle
				if bata_anim.has_animation("idle"):
					if bata_anim.current_animation != "idle":
						bata_anim.play("idle", 0.25)
					bata_anim.speed_scale = 1.0

	# 2. Tag Action Reach / Slap Lunge
	if is_tag_swinging:
		tag_swing_timer -= delta
		var progress: float = 1.0 - (tag_swing_timer / tag_swing_duration)
		var swing_angle: float = sin(progress * PI) * 1.8

		if bata_model:
			# Forward lunge & torso twist for impactful tag reach
			var lunge: float = sin(progress * PI) * 0.24
			bata_model.position.z = bata_base_pos.z - lunge
			bata_model.rotation.y = bata_base_rot_y + sin(progress * PI) * 0.25

		if right_arm:
			right_arm.rotation.x = swing_angle
			right_arm.rotation.y = -sin(progress * PI) * 0.6

		if tag_swing_timer <= 0.0:
			is_tag_swinging = false
			if bata_model:
				bata_model.position.z = bata_base_pos.z
				bata_model.rotation.y = bata_base_rot_y
			if right_arm:
				right_arm.rotation = Vector3.ZERO
	else:
		if bata_model:
			bata_model.position.z = lerp(bata_model.position.z, bata_base_pos.z, delta * 12.0)
			bata_model.rotation.y = lerp_angle(bata_model.rotation.y, bata_base_rot_y, delta * 12.0)

	# 3. Dynamic Tilt Overlays (Dash, Slide, Jump)
	if is_dashing:
		if bata_model:
			bata_model.rotation.x = lerp_angle(bata_model.rotation.x, deg_to_rad(28.0), delta * 15.0)
		return

	if is_sliding:
		if bata_model:
			bata_model.rotation.x = lerp_angle(bata_model.rotation.x, deg_to_rad(-24.0), delta * 15.0)
			bata_model.position.y = lerp(bata_model.position.y, bata_base_pos.y - 0.18, delta * 15.0)
		return

	if not is_on_floor:
		if bata_model:
			bata_model.rotation.x = lerp_angle(bata_model.rotation.x, deg_to_rad(5.0), delta * 8.0)
			bata_model.position.y = lerp(bata_model.position.y, bata_base_pos.y + 0.05, delta * 8.0)
		_apply_carry_bob(delta)
		return

	# Reset orientation smoothly when normal walking/idling
	if bata_model:
		bata_model.rotation.x = lerp_angle(bata_model.rotation.x, 0.0, delta * 8.0)
		bata_model.rotation.y = lerp_angle(bata_model.rotation.y, bata_base_rot_y, delta * 8.0)
		bata_model.position.y = lerp(bata_model.position.y, bata_base_pos.y, delta * 8.0)

	_apply_carry_bob(delta)

	# 4. Rotate fiery aura rings if Taya
	if is_taya and taya_aura:
		taya_aura.rotate_y(delta * 2.5)
		var inner := taya_aura.get_node_or_null("InnerRing")
		if inner:
			inner.rotate_y(delta * -4.5)

func _apply_carry_bob(_delta: float) -> void:
	if is_carrying and held_item_anchor:
		walk_cycle_time += _delta * 12.0
		var bob: float = sin(walk_cycle_time) * 0.03
		held_item_anchor.position.y = held_anchor_base_y + bob
		held_item_anchor.rotation.z = sin(walk_cycle_time * 0.5) * 0.04
