class_name CharacterAnimator
extends Node3D

enum CharacterType {
	TSUNA = 0,
	KALBO = 1,
	ORIGINAL = 2,
	BATA = 3
}

const CHARACTER_NAMES = [
	"⚡ Tsuna (Anime Kid)",
	"🥊 Kalbo (Street Brawler)",
	"🧢 Batang Kalye (Original)",
	"🏃 Bata (Street Runner)"
]

@export var is_taya: bool = false:
	set(value):
		if is_taya == value and is_inside_tree():
			return
		is_taya = value
		_update_taya_visuals()

var current_character_type: int = CharacterType.TSUNA

@export var character_type: CharacterType = CharacterType.TSUNA:
	set(value):
		character_type = value
		if is_inside_tree() and current_character_type != value:
			set_character(value)

# Model container references
@onready var model_tsuna: Node3D = get_node_or_null("ModelTsuna")
@onready var model_kalbo: Node3D = get_node_or_null("ModelKalbo")
@onready var model_bata: Node3D = get_node_or_null("ModelBata")
@onready var model_original: Node3D = get_node_or_null("ModelOriginal")

# Legacy / Original blocky model parts (under ModelOriginal)
@onready var body_mesh: MeshInstance3D = get_node_or_null("ModelOriginal/Torso") if has_node("ModelOriginal/Torso") else get_node_or_null("Torso")
@onready var head_mesh: MeshInstance3D = get_node_or_null("ModelOriginal/Torso/Head") if has_node("ModelOriginal/Torso/Head") else get_node_or_null("Torso/Head")
@onready var left_arm: Node3D = get_node_or_null("ModelOriginal/Torso/LeftArmPivot") if has_node("ModelOriginal/Torso/LeftArmPivot") else get_node_or_null("Torso/LeftArmPivot")
@onready var right_arm: Node3D = get_node_or_null("ModelOriginal/Torso/RightArmPivot") if has_node("ModelOriginal/Torso/RightArmPivot") else get_node_or_null("Torso/RightArmPivot")
@onready var left_leg: Node3D = get_node_or_null("ModelOriginal/LeftLegPivot") if has_node("ModelOriginal/LeftLegPivot") else get_node_or_null("LeftLegPivot")
@onready var right_leg: Node3D = get_node_or_null("ModelOriginal/RightLegPivot") if has_node("ModelOriginal/RightLegPivot") else get_node_or_null("RightLegPivot")

# Taya Visuals
@onready var taya_aura: Node3D = get_node_or_null("TayaAura")
@onready var taya_badge: Label3D = get_node_or_null("TayaBadge")
@onready var taya_flame_particles: CPUParticles3D = get_node_or_null("TayaAura/FlameParticles")

# Held Trash Item Attachments
@onready var held_item_anchor: Node3D = get_node_or_null("HeldItemAnchor")
@onready var held_bottle: Node3D = get_node_or_null("HeldItemAnchor/HeldBottle")
@onready var held_can: Node3D = get_node_or_null("HeldItemAnchor/HeldCan")
@onready var held_peel: Node3D = get_node_or_null("HeldItemAnchor/HeldPeel")
@onready var held_wrapper: Node3D = get_node_or_null("HeldItemAnchor/HeldWrapper")

# Active dynamic references
var active_model: Node3D = null
var active_anim: AnimationPlayer = null
var active_mesh: MeshInstance3D = null
var is_skeletal: bool = true
var model_base_pos: Vector3 = Vector3.ZERO
var model_base_rot_y: float = PI

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
var held_anchor_base_y: float = 0.70

func _ready() -> void:
	if held_item_anchor:
		held_anchor_base_y = held_item_anchor.position.y

	set_character(current_character_type)
	_update_taya_visuals()
	set_held_trash(-1)

func set_character(char_type: int) -> void:
	current_character_type = char_type as CharacterType

	# Hide all models first
	if model_tsuna: model_tsuna.visible = false
	if model_kalbo: model_kalbo.visible = false
	if model_bata: model_bata.visible = false
	if model_original: model_original.visible = false
	if body_mesh and body_mesh.get_parent() == self: body_mesh.visible = false
	if left_leg and left_leg.get_parent() == self: left_leg.visible = false
	if right_leg and right_leg.get_parent() == self: right_leg.visible = false

	match current_character_type:
		CharacterType.TSUNA:
			if model_tsuna:
				model_tsuna.visible = true
				active_model = model_tsuna
				active_anim = model_tsuna.get_node_or_null("AnimationPlayer")
				active_mesh = model_tsuna.get_node_or_null("Armature/Skeleton3D/base_body_001")
			is_skeletal = true
			model_base_rot_y = PI

		CharacterType.KALBO:
			if model_kalbo:
				model_kalbo.visible = true
				active_model = model_kalbo
				active_anim = model_kalbo.get_node_or_null("AnimationPlayer")
				active_mesh = model_kalbo.get_node_or_null("Armature/Skeleton3D/base_body_001")
			is_skeletal = true
			model_base_rot_y = PI

		CharacterType.BATA:
			if model_tsuna:
				model_tsuna.visible = true
				active_model = model_tsuna
				active_anim = model_tsuna.get_node_or_null("AnimationPlayer")
				active_mesh = model_tsuna.get_node_or_null("Armature/Skeleton3D/base_body_001")
			is_skeletal = true
			model_base_rot_y = PI

		CharacterType.ORIGINAL:
			if model_original:
				model_original.visible = true
				active_model = model_original
				active_anim = null
				active_mesh = body_mesh
			is_skeletal = false
			model_base_rot_y = 0.0

	if active_model:
		model_base_pos = active_model.position

	# Configure skeletal animation loops
	if active_anim:
		for a_name in ["idle", "jogging", "running", "narutoRun"]:
			if active_anim.has_animation(a_name):
				var a := active_anim.get_animation(a_name)
				a.loop_mode = Animation.LOOP_LINEAR
		for a_name in ["jump", "punching"]:
			if active_anim.has_animation(a_name):
				var a := active_anim.get_animation(a_name)
				a.loop_mode = Animation.LOOP_NONE
		if active_anim.has_animation("idle"):
			active_anim.play("idle")

	# Refresh materials on newly active model
	set_player_color(current_player_color)
	_update_taya_visuals()

func _update_taya_visuals() -> void:
	if not is_inside_tree():
		return
	if taya_aura:
		taya_aura.visible = is_taya
	if taya_flame_particles:
		taya_flame_particles.emitting = is_taya
	if taya_badge:
		taya_badge.visible = is_taya

	if is_taya:
		if active_mesh:
			active_mesh.material_override = taya_mat
		if body_mesh:
			body_mesh.material_override = taya_mat
	else:
		_apply_active_mesh_color(current_player_color)

func set_player_color(col: Color) -> void:
	current_player_color = col
	if not is_taya and is_inside_tree():
		_apply_active_mesh_color(col)

func _apply_active_mesh_color(col: Color) -> void:
	var custom_mat := StandardMaterial3D.new()
	custom_mat.albedo_color = col
	custom_mat.roughness = 0.5
	if active_mesh:
		active_mesh.material_override = custom_mat
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
	if active_anim and active_anim.has_animation("punching"):
		active_anim.play("punching", 0.08)
		active_anim.speed_scale = 2.2 # Snappy 0.4s tag punch strike

func animate(delta: float, horizontal_speed: float, is_on_floor: bool, max_speed: float) -> void:
	var using_naruto: bool = (has_superspeed or is_dashing or horizontal_speed > 13.0)

	# 1. Skeletal Character Animation
	if is_skeletal and active_anim:
		if is_tag_swinging and active_anim.has_animation("punching"):
			# Let punch strike play
			pass
		elif not is_on_floor:
			if active_anim.has_animation("jump"):
				if active_anim.current_animation != "jump":
					active_anim.play("jump", 0.12)
				active_anim.speed_scale = 1.2
			elif horizontal_speed > 3.0:
				if active_anim.current_animation != "jogging":
					active_anim.play("jogging", 0.2)
				active_anim.speed_scale = 0.8
			else:
				if active_anim.current_animation != "idle":
					active_anim.play("idle", 0.2)
				active_anim.speed_scale = 0.8
		else:
			if horizontal_speed > 0.3:
				if using_naruto and active_anim.has_animation("narutoRun"):
					if active_anim.current_animation != "narutoRun":
						active_anim.play("narutoRun", 0.15)
					active_anim.speed_scale = clamp(horizontal_speed / 11.5, 1.0, 2.4)
				elif horizontal_speed > 8.0 and active_anim.has_animation("running"):
					if active_anim.current_animation != "running":
						active_anim.play("running", 0.15)
					active_anim.speed_scale = clamp(horizontal_speed / 11.5, 0.85, 1.8)
				elif active_anim.has_animation("jogging"):
					if active_anim.current_animation != "jogging":
						active_anim.play("jogging", 0.15)
					active_anim.speed_scale = clamp(horizontal_speed / 7.0, 0.75, 1.4)
			else:
				if active_anim.has_animation("idle"):
					if active_anim.current_animation != "idle":
						active_anim.play("idle", 0.25)
					active_anim.speed_scale = 1.0

	# 2. Original Procedural Animation (Batang Kalye Retro Model)
	elif not is_skeletal:
		if is_on_floor and horizontal_speed > 0.3:
			walk_cycle_time += delta * (horizontal_speed / max(max_speed, 1.0)) * 14.0
			var leg_swing: float = sin(walk_cycle_time) * 0.65
			if left_leg: left_leg.rotation.x = leg_swing
			if right_leg: right_leg.rotation.x = -leg_swing
			if not is_tag_swinging:
				if left_arm: left_arm.rotation.x = -leg_swing * 0.75
				if right_arm: right_arm.rotation.x = leg_swing * 0.75
			if body_mesh:
				body_mesh.position.y = 0.7 + abs(sin(walk_cycle_time * 2.0)) * 0.04
		else:
			if left_leg: left_leg.rotation.x = lerp_angle(left_leg.rotation.x, 0.0, delta * 12.0)
			if right_leg: right_leg.rotation.x = lerp_angle(right_leg.rotation.x, 0.0, delta * 12.0)
			if not is_tag_swinging:
				if left_arm: left_arm.rotation.x = lerp_angle(left_arm.rotation.x, 0.0, delta * 12.0)
				if right_arm: right_arm.rotation.x = lerp_angle(right_arm.rotation.x, 0.0, delta * 12.0)
			if body_mesh:
				body_mesh.position.y = lerp(body_mesh.position.y, 0.7, delta * 8.0)

	# 3. Tag Action Reach / Slap Lunge
	if is_tag_swinging:
		tag_swing_timer -= delta
		var progress: float = 1.0 - (tag_swing_timer / tag_swing_duration)
		var swing_angle: float = sin(progress * PI) * 1.8

		if active_model:
			var lunge: float = sin(progress * PI) * 0.24
			active_model.position.z = model_base_pos.z - lunge
			active_model.rotation.y = model_base_rot_y + sin(progress * PI) * 0.25

		if right_arm:
			right_arm.rotation.x = swing_angle
			right_arm.rotation.y = -sin(progress * PI) * 0.6

		if tag_swing_timer <= 0.0:
			is_tag_swinging = false
			if active_model:
				active_model.position.z = model_base_pos.z
				active_model.rotation.y = model_base_rot_y
			if right_arm:
				right_arm.rotation = Vector3.ZERO
	else:
		if active_model:
			active_model.position.z = lerp(active_model.position.z, model_base_pos.z, delta * 12.0)
			active_model.rotation.y = lerp_angle(active_model.rotation.y, model_base_rot_y, delta * 12.0)

	# 4. Dynamic Tilt Overlays (Dash, Slide, Jump)
	if is_dashing:
		if active_model:
			active_model.rotation.x = lerp_angle(active_model.rotation.x, deg_to_rad(28.0), delta * 15.0)
		return

	if is_sliding:
		if active_model:
			active_model.rotation.x = lerp_angle(active_model.rotation.x, deg_to_rad(-24.0), delta * 15.0)
			active_model.position.y = lerp(active_model.position.y, model_base_pos.y - 0.18, delta * 15.0)
		return

	if not is_on_floor:
		if active_model:
			active_model.rotation.x = lerp_angle(active_model.rotation.x, deg_to_rad(5.0), delta * 8.0)
			active_model.position.y = lerp(active_model.position.y, model_base_pos.y + 0.05, delta * 8.0)
		_apply_carry_bob(delta)
		return

	# Reset orientation smoothly when normal walking/idling
	if active_model:
		active_model.rotation.x = lerp_angle(active_model.rotation.x, 0.0, delta * 8.0)
		active_model.rotation.y = lerp_angle(active_model.rotation.y, model_base_rot_y, delta * 8.0)
		active_model.position.y = lerp(active_model.position.y, model_base_pos.y, delta * 8.0)

	_apply_carry_bob(delta)

	# 5. Rotate fiery aura rings if Taya
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
