class_name PlayerController
extends CharacterBody3D

signal tagged_other_player(target_id: int)
signal role_changed(new_role: int)
signal powerup_changed(powerup_type: int, duration_left: float, charges: int)
signal trash_changed(trash_type: int, trash_name: String, bin_category: int)
signal notification_displayed(message: String, is_success: bool)
signal interactable_changed(has_target: bool, prompt_icon: String, prompt_action: String)
signal danger_detected(is_danger: bool, distance: float)
signal stamina_changed(burst_val: float, burst_max: float, endurance_val: float, endurance_max: float, is_exhausted: bool)

enum Role {
	RUNNER = 0,
	TAYA = 1
}

enum PowerupType {
	NONE = 0,
	DASH = 1,
	SUPER_SPEED = 2,
	DOUBLE_JUMP = 3,
	WATER_RUN = 4,
	WALL_RUN = 5
}

const FloatingTextScript = preload("res://scripts/player/FloatingText.gd")

@export var player_id: int = 1:
	set(value):
		player_id = value
		if is_inside_tree():
			set_multiplayer_authority(value)

var is_bot: bool = false

func is_local_human() -> bool:
	if is_bot:
		return false
	if multiplayer.has_multiplayer_peer():
		var my_id := multiplayer.get_unique_id()
		return player_id == my_id or get_multiplayer_authority() == my_id
	return player_id == 1

@export var player_name: String = "Player"
@export var current_role: Role = Role.RUNNER:
	set(value):
		current_role = value
		if is_inside_tree():
			_update_role_state()

# Movement parameters (inspired by high-performance movement state machines)
@export_group("Movement Stats")
@export var walk_speed: float = 7.0
@export var sprint_speed: float = 11.5
@export var slide_speed: float = 15.0
@export var dash_speed: float = 24.0
@export var acceleration: float = 30.0
@export var friction: float = 22.0
@export var air_control: float = 8.5
@export var rotation_speed: float = 14.0

# Jump physics with asymmetric peak/fall gravity
@export_group("Jump Physics")
@export var jump_height: float = 2.4
@export var jump_time_to_peak: float = 0.32
@export var jump_time_to_fall: float = 0.26
@export var max_air_jumps: int = 0 # Air jumps locked until Imagination Powerup!
@export var coyote_time_duration: float = 0.15
@export var jump_buffer_duration: float = 0.15

@onready var jump_velocity: float = (2.0 * jump_height) / jump_time_to_peak
@onready var jump_gravity: float = (-2.0 * jump_height) / (jump_time_to_peak * jump_time_to_peak)
@onready var fall_gravity: float = (-2.0 * jump_height) / (jump_time_to_fall * jump_time_to_fall)

# Slide & Dash parameters
@export_group("Slide & Dash")
@export var slide_duration: float = 0.85
@export var slide_cooldown_max: float = 1.2
@export var dash_duration: float = 0.14
@export var dash_cooldown_max: float = 1.4

# Dual Stamina System (Burst Sprint + Long-Term Running Endurance)
@export_group("Stamina Stats")
@export var burst_stamina_max: float = 100.0
@export var endurance_stamina_max: float = 100.0
@export var burst_drain_rate: float = 24.0      # ~4.1s continuous sprint
@export var burst_recovery_idle: float = 38.0   # Fast refill when resting
@export var burst_recovery_walk: float = 20.0   # Moderate refill while walking
@export var endurance_drain_sprint: float = 7.5 # Drains while sprinting
@export var endurance_drain_run: float = 1.8    # Drains slowly while jogging/moving
@export var endurance_recovery_idle: float = 12.0 # Restores when standing still
@export var endurance_recovery_walk: float = 4.0  # Restores slowly while walking gently
@export var exhausted_speed: float = 3.2        # Slow limp when exhausted
@export var exhaustion_recovery_threshold: float = 30.0 # Must reach 30% to exit exhaustion

var burst_stamina: float = 100.0
var endurance_stamina: float = 100.0
var is_exhausted: bool = false
var stamina_regen_delay_timer: float = 0.0
var exhaust_pant_timer: float = 0.0

# Camera settings
@export_group("Camera")
@export var mouse_sensitivity: float = 0.003
@export var touch_sensitivity: float = 0.005
@export var base_fov: float = 72.0
@export var sprint_fov: float = 80.0
@export var slide_fov: float = 84.0
@export var dash_fov: float = 88.0

# Game mechanics
@export_group("Match Stats")
@export var survival_time: float = 0.0
@export var tag_count: int = 0
@export var is_immune: bool = false
@export var immunity_time: float = 2.5
const TAG_REACH: float = 4.2

# State timers
var camera_pitch: float = 0.0
var camera_yaw: float = 0.0
var is_sprinting: bool = false
var is_sliding: bool = false
var is_dashing: bool = false
var slide_timer: float = 0.0
var slide_cooldown: float = 0.0
var slide_direction: Vector3 = Vector3.ZERO
var dash_timer: float = 0.0
var dash_cooldown: float = 0.0
var dash_direction: Vector3 = Vector3.ZERO

var coyote_timer: float = 0.0
var jump_buffer_timer: float = 0.0
var air_jumps_left: int = 0
var tag_cooldown: float = 0.0
var tag_cooldown_max: float = 0.6
var current_immunity_timer: float = 0.0

# Waste Segregation & Inventory
var held_trash: int = -1
var held_trash_name: String = ""
var held_trash_category: int = 0

# Imagination Powerups
var active_powerup: PowerupType = PowerupType.NONE
var powerup_time_left: float = 0.0
var dash_charges_left: int = 0

# Movement modifiers & Water/Wall Run
var is_in_water: bool = false
var is_wall_running: bool = false
var wall_run_dir: Vector3 = Vector3.ZERO
var wall_run_normal: Vector3 = Vector3.ZERO

# Stun system (triggered by dog NPC or events)
var is_stunned: bool = false
var stun_timer: float = 0.0

# Contextual Interaction & Proximity
var nearby_interactables: Array[Node3D] = []
var current_interactable: Node3D = null
var danger_check_timer: float = 0.0
var is_cursor_free: bool = false  # True when user pressed Escape to free cursor

# Tournament & Crab Game Elimination State
var is_eliminated: bool = false
var spectating_target: PlayerController = null

# Screen Shake Juice
var camera_trauma: float = 0.0
const MAX_SHAKE_YAW: float = deg_to_rad(3.5)
const MAX_SHAKE_PITCH: float = deg_to_rad(3.0)
const MAX_SHAKE_ROLL: float = deg_to_rad(2.5)
var camera_tilt_current: float = 0.0

# Squash & Stretch Animation Feel
var model_base_scale: Vector3 = Vector3(0.75, 0.75, 0.75)
var squash_target: Vector3 = Vector3.ONE
var squash_current: Vector3 = Vector3.ONE

# Landing & Footstep Tracking
var was_on_floor_prev: bool = true
var prev_vert_vel: float = 0.0
var footstep_timer: float = 0.0

# Node references (using safe lookups for compatibility with AI bots & remote peers)
@onready var collision_shape: CollisionShape3D = get_node_or_null("CollisionShape3D")
@onready var camera_mount: Node3D = get_node_or_null("CameraMount")
@onready var spring_arm: SpringArm3D = get_node_or_null("CameraMount/SpringArm3D")
@onready var camera: Camera3D = get_node_or_null("CameraMount/SpringArm3D/Camera3D")
@onready var model: CharacterAnimator = get_node_or_null("CharacterModel")
@onready var tag_area: Area3D = get_node_or_null("TagArea")
@onready var name_label: Label3D = get_node_or_null("NameLabel")
@onready var mobile_ui: MobileControls = get_node_or_null("MobileControlsUI")
@onready var tag_pointer: TagPointerUI = get_node_or_null("TagPointerUI")
@onready var slide_dust: CPUParticles3D = get_node_or_null("SlideDust")
@onready var powerup_aura: CPUParticles3D = get_node_or_null("PowerupAura")
@onready var water_splash: CPUParticles3D = get_node_or_null("WaterSplash")
@onready var held_item_display: Label3D = get_node_or_null("HeldItemDisplay")

# Network sync targets for remote peers
var target_position: Vector3 = Vector3.ZERO
var target_rotation_y: float = 0.0

func _ready() -> void:
	add_to_group("players")
	set_multiplayer_authority(player_id)
	if name_label:
		name_label.text = player_name
	target_position = global_position
	target_rotation_y = model.rotation.y if model else 0.0
	if model:
		model_base_scale = model.scale

	# Authority setup
	if is_local_human():
		if camera:
			camera.current = true
			camera.fov = base_fov
		if camera_mount:
			camera_mount.top_level = true
			camera_mount.global_position = global_position + Vector3(0, 1.4, 0)
		if spring_arm:
			spring_arm.add_excluded_object(get_rid())
			spring_arm.collision_mask = 1 # Environment only

		camera_yaw = 0.0
		camera_pitch = deg_to_rad(-12.0)
		_apply_camera_rotation()

		var is_mobile := OS.has_feature("mobile") or OS.get_name() in ["Android", "iOS"] or DisplayServer.is_touchscreen_available()
		if mobile_ui:
			mobile_ui.visible = is_mobile
			_setup_mobile_ui()

		if tag_pointer:
			tag_pointer.visible = true

		if not is_mobile and not DisplayServer.is_touchscreen_available() and camera:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	else:
		if camera:
			camera.current = false
		if mobile_ui:
			mobile_ui.visible = false
		if tag_pointer:
			tag_pointer.visible = false

	_update_role_state()
	_update_powerup_visuals()
	_update_held_item_visuals()

	if is_local_human():
		var hud_node = get_node_or_null("/root/Main/HUD")
		if hud_node:
			if hud_node.has_method("on_powerup_changed"):
				powerup_changed.connect(hud_node.on_powerup_changed)
			if hud_node.has_method("on_trash_changed"):
				trash_changed.connect(hud_node.on_trash_changed)
			if hud_node.has_method("show_toast_notification"):
				notification_displayed.connect(hud_node.show_toast_notification)
			if hud_node.has_method("on_interactable_changed"):
				interactable_changed.connect(hud_node.on_interactable_changed)
			if hud_node.has_method("on_danger_detected"):
				danger_detected.connect(hud_node.on_danger_detected)
			if hud_node.has_method("on_stamina_changed"):
				stamina_changed.connect(hud_node.on_stamina_changed)
				stamina_changed.emit(burst_stamina, burst_stamina_max, endurance_stamina, endurance_stamina_max, is_exhausted)

func _setup_mobile_ui() -> void:
	if not mobile_ui:
		return
	mobile_ui.camera_dragged.connect(_on_mobile_camera_dragged)
	mobile_ui.jump_pressed.connect(func(): _queue_jump())
	mobile_ui.sprint_toggled.connect(func(sprint_on: bool): is_sprinting = sprint_on)
	mobile_ui.slide_pressed.connect(func(): _try_slide())
	mobile_ui.dash_pressed.connect(func(): _try_dash())
	mobile_ui.tag_pressed.connect(func(): _try_tag())
	if mobile_ui.has_signal("interact_pressed"):
		mobile_ui.interact_pressed.connect(func(): _try_interact())
	if mobile_ui.has_signal("drop_pressed"):
		mobile_ui.drop_pressed.connect(func(): drop_trash())
	if mobile_ui.has_method("on_powerup_changed"):
		powerup_changed.connect(mobile_ui.on_powerup_changed)
	if mobile_ui.has_method("update_powerup_buttons"):
		mobile_ui.update_powerup_buttons(active_powerup, dash_charges_left)

func _unhandled_input(event: InputEvent) -> void:
	if not is_local_human():
		return

	var main_node = get_node_or_null("/root/Main")
	var is_paused: bool = main_node and ("is_game_paused" in main_node) and main_node.is_game_paused
	if is_paused:
		return

	# Spectator mode input (when eliminated)
	if is_eliminated:
		if event is InputEventKey and event.pressed and not event.echo:
			if event.keycode in [KEY_SPACE, KEY_RIGHT, KEY_D, KEY_ENTER]:
				_cycle_spectate_target(1)
				get_viewport().set_input_as_handled()
			elif event.keycode in [KEY_LEFT, KEY_A]:
				_cycle_spectate_target(-1)
				get_viewport().set_input_as_handled()
		elif event is InputEventMouseButton and event.pressed:
			if event.button_index == MOUSE_BUTTON_LEFT:
				_cycle_spectate_target(1)
				get_viewport().set_input_as_handled()
			elif event.button_index == MOUSE_BUTTON_RIGHT:
				_cycle_spectate_target(-1)
				get_viewport().set_input_as_handled()
		elif event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			_rotate_camera(-event.relative.x * mouse_sensitivity, -event.relative.y * mouse_sensitivity)
		return

	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_T:
			# Debug practice role toggle
			var next_role: Role = Role.RUNNER if current_role == Role.TAYA else Role.TAYA
			current_role = next_role

	# Left click: if cursor is free, recapture it; otherwise execute tag
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if is_cursor_free:
			# User clicked back into game — recapture
			is_cursor_free = false
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		elif Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		else:
			_try_tag()

	# Mouse look when captured (only when cursor is NOT free and game is not paused)
	if not is_cursor_free and not is_paused and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED and event is InputEventMouseMotion:
		_rotate_camera(-event.relative.x * mouse_sensitivity, -event.relative.y * mouse_sensitivity)

func _on_mobile_camera_dragged(relative_vec: Vector2) -> void:
	if is_local_human():
		_rotate_camera(-relative_vec.x * touch_sensitivity, -relative_vec.y * touch_sensitivity)

func _apply_camera_rotation() -> void:
	if camera_mount:
		camera_mount.rotation = Vector3(0, camera_yaw, 0)
	if spring_arm:
		spring_arm.rotation = Vector3(camera_pitch, 0, 0)

func _rotate_camera(delta_yaw: float, delta_pitch: float) -> void:
	camera_yaw += delta_yaw
	camera_pitch = clamp(camera_pitch + delta_pitch, deg_to_rad(-60.0), deg_to_rad(30.0))
	_apply_camera_rotation()

func add_shake(amount: float) -> void:
	if not is_local_human():
		return
	camera_trauma = clamp(camera_trauma + amount, 0.0, 1.0)

func _process_shake(delta: float) -> void:
	if not camera:
		return
	var target_tilt: float = 0.0
	if is_sliding:
		target_tilt = deg_to_rad(-2.5)
	camera_tilt_current = lerp(camera_tilt_current, target_tilt, delta * 8.0)

	if camera_trauma > 0.0:
		camera_trauma = max(0.0, camera_trauma - delta * 1.6)
		var shake := camera_trauma * camera_trauma
		var sy := randf_range(-1.0, 1.0) * MAX_SHAKE_YAW * shake
		var sp := randf_range(-1.0, 1.0) * MAX_SHAKE_PITCH * shake
		var sr := randf_range(-1.0, 1.0) * MAX_SHAKE_ROLL * shake
		camera.rotation = Vector3(sp, sy, sr + camera_tilt_current)
	elif abs(camera_tilt_current) > 0.001:
		camera.rotation = Vector3(0, 0, camera_tilt_current)
	elif camera.rotation != Vector3.ZERO:
		camera.rotation = Vector3.ZERO

func trigger_hit_stop(duration_ms: float = 55.0) -> void:
	if not is_local_human():
		return
	Engine.time_scale = 0.06
	get_tree().create_timer(duration_ms / 1000.0, true, false, true).timeout.connect(func():
		Engine.time_scale = 1.0
	)

func set_eliminated(elim: bool) -> void:
	is_eliminated = elim
	if collision_shape:
		collision_shape.disabled = elim
	if model:
		model.visible = not elim
	if name_label:
		name_label.visible = not elim
	if tag_pointer:
		tag_pointer.visible = not elim
	if is_local_human():
		if elim:
			add_shake(0.85)
			if Input.has_method("vibrate_handheld"):
				Input.vibrate_handheld(250)
			_cycle_spectate_target(1)
		else:
			spectating_target = null
			var main_node = get_node_or_null("/root/Main")
			if main_node and main_node.hud:
				main_node.hud.hide_spectator_bar()

func _cycle_spectate_target(step: int = 1) -> void:
	if not is_local_human():
		return
	var main_node = get_node_or_null("/root/Main")
	if not main_node or not ("players_container" in main_node) or not main_node.players_container:
		return
	var alive_candidates: Array[PlayerController] = []
	for p in main_node.players_container.get_children():
		if p is PlayerController and p != self and not p.is_eliminated:
			alive_candidates.append(p)
	if alive_candidates.is_empty():
		spectating_target = null
		if main_node.hud:
			main_node.hud.hide_spectator_bar()
		return
	var idx := 0
	if spectating_target and alive_candidates.has(spectating_target):
		idx = (alive_candidates.find(spectating_target) + step) % alive_candidates.size()
		if idx < 0:
			idx = alive_candidates.size() - 1
	spectating_target = alive_candidates[idx]
	if is_instance_valid(spectating_target):
		global_position = spectating_target.global_position
		if camera_mount:
			camera_mount.global_position = spectating_target.global_position + Vector3(0, 1.4, 0)
		if main_node.hud:
			main_node.hud.show_spectator_bar(spectating_target.player_name)

func _physics_process(delta: float) -> void:
	var main_node = get_node_or_null("/root/Main")
	if main_node and ("is_game_paused" in main_node) and main_node.is_game_paused:
		velocity.x = move_toward(velocity.x, 0.0, friction * delta)
		velocity.z = move_toward(velocity.z, 0.0, friction * delta)
		move_and_slide()
		return

	if is_eliminated:
		if is_local_human():
			if is_instance_valid(spectating_target) and not spectating_target.is_eliminated:
				global_position = spectating_target.global_position
				if camera_mount:
					camera_mount.global_position = camera_mount.global_position.lerp(spectating_target.global_position + Vector3(0, 1.4, 0), delta * 25.0)
			else:
				_cycle_spectate_target(1)
			_process_shake(delta)
		else:
			velocity = Vector3.ZERO
		return

	_update_timers(delta)

	if is_local_human():
		_process_authority_movement(delta)
		_process_scoring(delta)
		_update_tag_targeting()
		_update_camera_fov(delta)
		_update_interactable_target()
		_process_shake(delta)
		danger_check_timer -= delta
		if danger_check_timer <= 0.0:
			danger_check_timer = 0.25
			_check_danger_proximity()
		# Send sync data to peers
		if multiplayer.has_multiplayer_peer():
			var rot_y: float = model.rotation.y if model else 0.0
			rpc("sync_transform", global_position, rot_y, velocity.length(), is_on_floor(), is_sliding, is_dashing)
	else:
		_process_remote_interpolation(delta)

	# Update procedural animations & squash deformation
	if model:
		squash_current = squash_current.lerp(squash_target, delta * 15.0)
		squash_target = squash_target.lerp(Vector3.ONE, delta * 8.0)
		model.scale = model_base_scale * squash_current
		var horizontal_speed: float = Vector2(velocity.x, velocity.z).length()
		var current_max: float = sprint_speed if is_sprinting else walk_speed
		model.is_sliding = is_sliding
		model.is_dashing = is_dashing
		model.has_superspeed = (active_powerup == PowerupType.SUPER_SPEED)
		model.animate(delta, horizontal_speed, is_on_floor(), current_max)

	if slide_dust:
		slide_dust.emitting = (is_sliding or (is_dashing and is_on_floor()))

	# Anime speed lines juice for local player
	if is_local_human():
		var h_spd: float = Vector2(velocity.x, velocity.z).length()
		var speed_intensity: float = 0.0
		if is_exhausted:
			speed_intensity = 0.0
		elif is_dashing:
			speed_intensity = 1.0
		elif is_sliding:
			speed_intensity = clamp(remap(h_spd, walk_speed, slide_speed, 0.25, 0.85), 0.0, 0.85)
		elif h_spd > sprint_speed * 0.9:
			speed_intensity = clamp(remap(h_spd, sprint_speed * 0.9, 18.5, 0.15, 0.9), 0.0, 1.0)
		if main_node and main_node.hud and main_node.hud.has_method("update_speed_lines"):
			main_node.hud.update_speed_lines(speed_intensity)

func _update_timers(delta: float) -> void:
	if tag_cooldown > 0.0: tag_cooldown -= delta
	if slide_cooldown > 0.0: slide_cooldown -= delta
	if dash_cooldown > 0.0: dash_cooldown -= delta
	if jump_buffer_timer > 0.0: jump_buffer_timer -= delta

	if current_immunity_timer > 0.0:
		current_immunity_timer -= delta
		if current_immunity_timer <= 0.0:
			is_immune = false

	# Stun timer countdown (dog NPC / event stun)
	if is_stunned:
		stun_timer -= delta
		if stun_timer <= 0.0:
			is_stunned = false
			_update_role_state()
			if is_local_human():
				notification_displayed.emit("Okay na! Tumakbo na ulit! 🏃", true)

	# Imagination powerup countdown
	if active_powerup != PowerupType.NONE:
		powerup_time_left -= delta
		if powerup_time_left <= 0.0:
			clear_powerup()
		elif is_local_human():
			powerup_changed.emit(active_powerup, powerup_time_left, dash_charges_left)

	if is_on_floor():
		coyote_timer = coyote_time_duration
		air_jumps_left = 1 if (active_powerup == PowerupType.DOUBLE_JUMP) else 0
		is_wall_running = false
	else:
		if coyote_timer > 0.0:
			coyote_timer -= delta

func apply_stun(duration: float) -> void:
	is_stunned = true
	stun_timer = duration
	velocity = Vector3.ZERO
	squash_current = Vector3(1.2, 0.7, 1.2)
	if name_label:
		name_label.text = "💫 NA-STUN! 💫"
	FloatingTextScript.spawn(get_parent(), global_position + Vector3(0, 2.0, 0), "🐶 ARF! NA-STUN! 💫", Color(1.0, 0.7, 0.2))
	if is_local_human():
		add_shake(0.7)
		if Input.has_method("vibrate_handheld"):
			Input.vibrate_handheld(200)
		notification_displayed.emit("🐶 Kinagat ng aso!", false)

func _process_authority_movement(delta: float) -> void:
	# Decoupled camera tracking player smoothly
	if camera_mount:
		camera_mount.global_position = camera_mount.global_position.lerp(global_position + Vector3(0, 1.4, 0), delta * 25.0)

	# Fall safeguard
	if global_position.y < -10.0:
		global_position = Vector3(0, 1.0, 0)
		velocity = Vector3.ZERO

	# Asymmetric Gravity
	if not is_on_floor() and not is_wall_running:
		if velocity.y > 0.0:
			velocity.y += jump_gravity * delta
		else:
			velocity.y += fall_gravity * delta

	# Stun gate — freeze all input while stunned by dog/event
	if is_stunned:
		velocity.x = move_toward(velocity.x, 0.0, friction * delta)
		velocity.z = move_toward(velocity.z, 0.0, friction * delta)
		move_and_slide()
		return

	# Cursor-free gate — freeze all input while cursor is visible (Escape pressed)
	if is_cursor_free:
		velocity.x = move_toward(velocity.x, 0.0, friction * delta)
		velocity.z = move_toward(velocity.z, 0.0, friction * delta)
		if not is_on_floor():
			velocity.y += fall_gravity * delta
		move_and_slide()
		return

	# Input checks
	var sprint_requested: bool = false
	if Input.is_action_pressed("sprint"):
		sprint_requested = true
	elif mobile_ui and mobile_ui.is_sprinting:
		sprint_requested = true

	if Input.is_action_just_pressed("jump"):
		_queue_jump()

	if Input.is_action_just_pressed("slide"):
		_try_slide()

	if Input.is_action_just_pressed("dash"):
		_try_dash()

	if Input.is_action_just_pressed("action_tag"):
		_try_tag()

	if Input.is_action_just_pressed("interact"):
		_try_interact()

	if Input.is_action_just_pressed("drop_trash"):
		drop_trash()

	# Process queued jump
	if jump_buffer_timer > 0.0:
		if is_on_floor() or coyote_timer > 0.0:
			_execute_jump()
		elif active_powerup == PowerupType.DOUBLE_JUMP and air_jumps_left > 0 and not is_on_floor():
			# Double jump (Luksong-Tinik)
			air_jumps_left -= 1
			_execute_jump()
			if slide_dust:
				slide_dust.restart()
				slide_dust.emitting = true

	# Handle active Dash
	if is_dashing:
		dash_timer -= delta
		velocity.x = dash_direction.x * dash_speed
		velocity.z = dash_direction.z * dash_speed
		velocity.y = 0.0 # Maintain level flight during dash
		if dash_timer <= 0.0:
			is_dashing = false
		move_and_slide()
		_process_landing_and_footsteps(delta)
		return

	# Handle active Slide
	if is_sliding:
		slide_timer -= delta
		var slide_progress: float = 1.0 - (slide_timer / slide_duration)
		var current_slide_spd: float = lerp(slide_speed, walk_speed, slide_progress)
		velocity.x = slide_direction.x * current_slide_spd
		velocity.z = slide_direction.z * current_slide_spd

		# Slide ends on timer expiry or leaving floor
		if slide_timer <= 0.0 or not is_on_floor():
			_end_slide()
		move_and_slide()
		_process_landing_and_footsteps(delta)
		return

	# Standard movement calculation relative to camera yaw
	var keyboard_input := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var mobile_input := mobile_ui.get_movement_vector() if mobile_ui else Vector2.ZERO
	var final_input := keyboard_input
	if mobile_input.length() > 0.1:
		final_input = mobile_input

	var cam_forward := Vector3.FORWARD
	var cam_right := Vector3.RIGHT
	if camera_mount:
		cam_forward = -camera_mount.global_transform.basis.z
		cam_right = camera_mount.global_transform.basis.x
		cam_forward.y = 0.0
		cam_right.y = 0.0
		cam_forward = cam_forward.normalized()
		cam_right = cam_right.normalized()

	var move_dir := (cam_right * final_input.x + cam_forward * -final_input.y).normalized()
	var is_moving := (move_dir.length() > 0.1)

	# Determine if sprint is permitted
	if sprint_requested and is_moving and not is_exhausted and burst_stamina > 0.0:
		is_sprinting = true
	else:
		is_sprinting = false

	# Process Dual Stamina
	_process_stamina(delta, is_moving)

	# Wall Run handling (Akyat-Pader)
	if active_powerup == PowerupType.WALL_RUN and not is_on_floor() and is_on_wall():
		var wall_norm := get_wall_normal()
		var forward_cam := cam_forward
		var wall_tangent := forward_cam.slide(wall_norm).normalized()

		if final_input.y < -0.1 or move_dir.length() > 0.2:
			is_wall_running = true
			wall_run_normal = wall_norm
			wall_run_dir = wall_tangent

			# Slow vertical fall during wall run
			velocity.y = max(velocity.y + (jump_gravity * 0.12) * delta, -2.2)

			# Wall run forward along wall tangent
			var wr_speed: float = 13.5
			velocity.x = wall_run_dir.x * wr_speed
			velocity.z = wall_run_dir.z * wr_speed

			# Model facing along wall run direction
			if model:
				var target_facing := atan2(-wall_run_dir.x, -wall_run_dir.z)
				model.rotation.y = lerp_angle(model.rotation.y, target_facing, rotation_speed * delta)
				var cross_up := wall_norm.cross(wall_tangent).y
				model.rotation.z = lerp_angle(model.rotation.z, 0.25 if cross_up > 0 else -0.25, delta * 10.0)

			# Wall kick if jump is queued
			if jump_buffer_timer > 0.0:
				jump_buffer_timer = 0.0
				velocity.y = jump_velocity * 1.15
				velocity.x = (wall_norm.x * 9.0) + (wall_run_dir.x * 7.5)
				velocity.z = (wall_norm.z * 9.0) + (wall_run_dir.z * 7.5)
				is_wall_running = false
				if model:
					model.rotation.z = 0.0

			move_and_slide()
			_process_landing_and_footsteps(delta)
			return
		else:
			is_wall_running = false
			if model:
				model.rotation.z = lerp_angle(model.rotation.z, 0.0, delta * 12.0)
	else:
		is_wall_running = false
		if model:
			model.rotation.z = lerp_angle(model.rotation.z, 0.0, delta * 12.0)

	var current_sprint_spd: float = sprint_speed
	var current_walk_spd: float = walk_speed

	if active_powerup == PowerupType.SUPER_SPEED:
		current_sprint_spd = 18.5
		current_walk_spd = 11.0

	var target_speed: float = current_walk_spd
	if is_exhausted:
		target_speed = exhausted_speed
	elif is_sprinting:
		target_speed = current_sprint_spd
	if current_role == Role.TAYA:
		target_speed *= 1.1
	if has_trash():
		target_speed *= 0.85 # High risk: 15% carrying slowdown

	# Water zone physics
	if is_in_water:
		if active_powerup == PowerupType.WATER_RUN:
			target_speed *= 1.25 # Lundag-Baha: fast water sprint!
			if water_splash and (is_sprinting or velocity.length() > 3.0):
				water_splash.emitting = true
		else:
			target_speed *= 0.55 # Water drag slowdown
			if water_splash:
				water_splash.emitting = false
	else:
		if water_splash:
			water_splash.emitting = false

	var target_vel_x: float = move_dir.x * target_speed
	var target_vel_z: float = move_dir.z * target_speed

	var accel_factor: float = acceleration if is_on_floor() else air_control
	if active_powerup == PowerupType.SUPER_SPEED:
		accel_factor *= 1.5

	if move_dir.length() > 0.1:
		velocity.x = move_toward(velocity.x, target_vel_x, accel_factor * delta)
		velocity.z = move_toward(velocity.z, target_vel_z, accel_factor * delta)

		var target_facing := atan2(-move_dir.x, -move_dir.z)
		model.rotation.y = lerp_angle(model.rotation.y, target_facing, rotation_speed * delta)
		tag_area.rotation.y = model.rotation.y
	else:
		velocity.x = move_toward(velocity.x, 0.0, friction * delta)
		velocity.z = move_toward(velocity.z, 0.0, friction * delta)

	move_and_slide()
	_process_landing_and_footsteps(delta)

func _process_landing_and_footsteps(delta: float) -> void:
	# Dynamic Landing Juice
	if is_on_floor() and not was_on_floor_prev:
		if prev_vert_vel < -2.8:
			var impact_spd: float = abs(prev_vert_vel)
			squash_current = Vector3(1.22, 0.74, 1.22)
			if Engine.has_singleton("AudioManager"):
				AudioManager.play_land(impact_spd)
			elif has_node("/root/AudioManager"):
				get_node("/root/AudioManager").play_land(impact_spd)
			if impact_spd > 5.5:
				add_shake(clamp(impact_spd / 26.0, 0.06, 0.28))
				if slide_dust:
					slide_dust.restart()
					slide_dust.emitting = true
	was_on_floor_prev = is_on_floor()
	prev_vert_vel = velocity.y

	# Dynamic Footstep Juice
	if is_on_floor() and not is_sliding and not is_dashing and not is_stunned and not is_wall_running:
		var move_speed: float = Vector2(velocity.x, velocity.z).length()
		if move_speed > 1.2:
			var step_interval: float = 0.52 if is_exhausted else clampf(remap(move_speed, walk_speed, sprint_speed, 0.38, 0.22), 0.18, 0.42)
			footstep_timer -= delta
			if footstep_timer <= 0.0:
				footstep_timer = step_interval
				if Engine.has_singleton("AudioManager"):
					AudioManager.play_footstep(is_in_water)
				elif has_node("/root/AudioManager"):
					get_node("/root/AudioManager").play_footstep(is_in_water)
		else:
			footstep_timer = 0.1
	else:
		footstep_timer = 0.1

func _queue_jump() -> void:
	jump_buffer_timer = jump_buffer_duration

func _execute_jump() -> void:
	jump_buffer_timer = 0.0
	coyote_timer = 0.0
	velocity.y = jump_velocity * (0.8 if is_exhausted else 1.0)
	squash_current = Vector3(0.82, 1.28, 0.82)

	if not is_exhausted:
		burst_stamina = max(0.0, burst_stamina - 6.0)
		endurance_stamina = max(0.0, endurance_stamina - 2.5)
		stamina_regen_delay_timer = 0.45

	if Engine.has_singleton("AudioManager"):
		AudioManager.play_jump()
	elif has_node("/root/AudioManager"):
		get_node("/root/AudioManager").play_jump()

	if slide_dust:
		slide_dust.restart()
		slide_dust.emitting = true

	# Break slide on jump for slide-jump momentum boost
	if is_sliding:
		velocity.x *= 1.15
		velocity.z *= 1.15
		_end_slide()

func _try_slide() -> void:
	if is_sliding or slide_cooldown > 0.0 or not is_on_floor():
		return

	if is_exhausted:
		if is_local_human():
			notification_displayed.emit("Hindi makadulas habang hingal! Magpahinga muna.", false)
		return

	if has_trash():
		if is_local_human():
			notification_displayed.emit("Mabigat ang dala! Pindutin ang [Q] para bitawan.", false)
		return

	var h_vel := Vector2(velocity.x, velocity.z)
	if h_vel.length() < 3.0:
		return

	burst_stamina = max(0.0, burst_stamina - 12.0)
	endurance_stamina = max(0.0, endurance_stamina - 4.0)
	stamina_regen_delay_timer = 0.5

	is_sliding = true
	slide_timer = slide_duration
	slide_cooldown = slide_cooldown_max
	slide_direction = Vector3(velocity.x, 0, velocity.z).normalized()
	squash_current = Vector3(1.18, 0.65, 1.18)

	if Engine.has_singleton("AudioManager"):
		AudioManager.play_slide()
	elif has_node("/root/AudioManager"):
		get_node("/root/AudioManager").play_slide()

	# Lower hitbox during slide
	if collision_shape and collision_shape.shape is CapsuleShape3D:
		collision_shape.shape.height = 0.95
		collision_shape.position.y = 0.48

func _end_slide() -> void:
	is_sliding = false
	if collision_shape and collision_shape.shape is CapsuleShape3D:
		collision_shape.shape.height = 1.45
		collision_shape.position.y = 0.725

func _try_dash() -> void:
	if is_dashing or dash_cooldown > 0.0:
		return

	if is_exhausted:
		if is_local_human():
			notification_displayed.emit("Hindi makapag-dash habang hingal! Magpahinga muna.", false)
		return

	if has_trash():
		if is_local_human():
			notification_displayed.emit("Mabigat ang dala! Pindutin ang [Q] para bitawan.", false)
		return

	# Dash requires imagination powerup!
	if active_powerup != PowerupType.DASH or dash_charges_left <= 0:
		if is_local_human():
			notification_displayed.emit("🔒 Naka-lock ang Dash! Mag-recycle ng basura para ma-unlock!", false)
		return

	dash_charges_left -= 1
	is_dashing = true
	dash_timer = dash_duration
	dash_cooldown = dash_cooldown_max
	squash_current = Vector3(0.82, 0.82, 1.35)

	var h_vel := Vector3(velocity.x, 0, velocity.z)
	if h_vel.length() > 0.2:
		dash_direction = h_vel.normalized()
	else:
		# Dash forward relative to model facing
		dash_direction = -model.global_transform.basis.z if model else Vector3.FORWARD
		dash_direction.y = 0.0
		dash_direction = dash_direction.normalized()

	if Engine.has_singleton("AudioManager"):
		AudioManager.play_dash()
	elif has_node("/root/AudioManager"):
		get_node("/root/AudioManager").play_dash()

	if is_local_human():
		add_shake(0.25)
		var main_node = get_node_or_null("/root/Main")
		if main_node and main_node.hud and main_node.hud.has_method("trigger_hit_flash"):
			main_node.hud.trigger_hit_flash(Color(0.2, 0.85, 1.0, 0.35), 0.2)

	FloatingTextScript.spawn(get_parent(), global_position + Vector3(0, 1.9, 0), "⚡ KIDLAT DASH!", Color(0.25, 0.9, 1.0))

	if is_local_human():
		powerup_changed.emit(active_powerup, powerup_time_left, dash_charges_left)
	if dash_charges_left <= 0:
		clear_powerup()

func _process_stamina(delta: float, is_moving: bool) -> void:
	if is_exhausted:
		is_sprinting = false
		# While exhausted, player must rest or walk slowly to catch their breath
		if is_moving:
			endurance_stamina = min(endurance_stamina_max, endurance_stamina + endurance_recovery_walk * delta)
		else:
			endurance_stamina = min(endurance_stamina_max, endurance_stamina + endurance_recovery_idle * delta)

		# Burst stamina recovers slowly while catching breath
		burst_stamina = min(burst_stamina_max, burst_stamina + (burst_recovery_walk * 0.4) * delta)

		# Exhaustion panting loop
		exhaust_pant_timer -= delta
		if exhaust_pant_timer <= 0.0:
			exhaust_pant_timer = 1.35
			if Engine.has_singleton("AudioManager"):
				AudioManager.play_pant()
			elif has_node("/root/AudioManager"):
				get_node("/root/AudioManager").play_pant()

		# Exit exhaustion check
		if endurance_stamina >= exhaustion_recovery_threshold:
			is_exhausted = false
			exhaust_pant_timer = 0.0
			if Engine.has_singleton("AudioManager"):
				AudioManager.play_recover_breath()
			elif has_node("/root/AudioManager"):
				get_node("/root/AudioManager").play_recover_breath()
			FloatingTextScript.spawn(get_parent(), global_position + Vector3(0, 2.0, 0), "💨 NAKAHINGA NA! 🏃", Color(0.3, 1.0, 0.6))
			if is_local_human():
				notification_displayed.emit("Nakahinga na ulit! Pwede nang tumakbo! 🏃", true)
	else:
		if is_sprinting and is_moving:
			var burst_drain: float = burst_drain_rate * delta
			var end_drain: float = endurance_drain_sprint * delta
			if active_powerup == PowerupType.SUPER_SPEED:
				burst_drain *= 0.5
				end_drain *= 0.5

			burst_stamina = max(0.0, burst_stamina - burst_drain)
			endurance_stamina = max(0.0, endurance_stamina - end_drain)
			stamina_regen_delay_timer = 0.45

			if burst_stamina <= 0.0:
				is_sprinting = false

			if endurance_stamina <= 0.0:
				# Trigger exhaustion!
				is_exhausted = true
				is_sprinting = false
				exhaust_pant_timer = 0.0
				if Engine.has_singleton("AudioManager"):
					AudioManager.play_pant()
				elif has_node("/root/AudioManager"):
					get_node("/root/AudioManager").play_pant()
				FloatingTextScript.spawn(get_parent(), global_position + Vector3(0, 2.0, 0), "💨 HINGAL! PAGOD NA...", Color(1.0, 0.35, 0.2))
				add_shake(0.35)
				if is_local_human():
					var main_node = get_node_or_null("/root/Main")
					if main_node and main_node.hud and main_node.hud.has_method("trigger_hit_flash"):
						main_node.hud.trigger_hit_flash(Color(0.8, 0.2, 0.2, 0.3), 0.35)
					notification_displayed.emit("⚠️ HINGAL NA! Sobrang takbo, kailangan magpahinga!", false)
		else:
			# Not sprinting
			if stamina_regen_delay_timer > 0.0:
				stamina_regen_delay_timer -= delta
			else:
				# Burst recovery
				if is_moving:
					burst_stamina = min(burst_stamina_max, burst_stamina + burst_recovery_walk * delta)
					# Running stamina drains slowly during continuous running/jogging
					endurance_stamina = max(0.0, endurance_stamina - endurance_drain_run * delta)
					if endurance_stamina <= 0.0:
						is_exhausted = true
						is_sprinting = false
						exhaust_pant_timer = 0.0
						if Engine.has_singleton("AudioManager"):
							AudioManager.play_pant()
						elif has_node("/root/AudioManager"):
							get_node("/root/AudioManager").play_pant()
						FloatingTextScript.spawn(get_parent(), global_position + Vector3(0, 2.0, 0), "💨 HINGAL! PAGOD NA...", Color(1.0, 0.35, 0.2))
				else:
					# Resting still — full recovery for both bars
					burst_stamina = min(burst_stamina_max, burst_stamina + burst_recovery_idle * delta)
					endurance_stamina = min(endurance_stamina_max, endurance_stamina + endurance_recovery_idle * delta)

	burst_stamina = clampf(burst_stamina, 0.0, burst_stamina_max)
	endurance_stamina = clampf(endurance_stamina, 0.0, endurance_stamina_max)

	if is_local_human():
		stamina_changed.emit(burst_stamina, burst_stamina_max, endurance_stamina, endurance_stamina_max, is_exhausted)
		if mobile_ui and mobile_ui.has_method("set_sprint_disabled"):
			mobile_ui.set_sprint_disabled(is_exhausted or burst_stamina <= 0.0)

func _update_camera_fov(delta: float) -> void:
	if not camera:
		return
	var target_fov := base_fov
	if is_exhausted:
		target_fov = base_fov - 4.0
	elif is_dashing:
		target_fov = dash_fov
	elif is_sliding:
		target_fov = slide_fov
	elif is_sprinting and Vector2(velocity.x, velocity.z).length() > 8.0:
		target_fov = sprint_fov

	camera.fov = lerp(camera.fov, target_fov, delta * 8.0)

# Tag Targeting and Pointer system
func _update_tag_targeting() -> void:
	if not tag_pointer or not camera:
		return

	var best_target: PlayerController = null
	var min_dist: float = 9999.0
	var is_hunting_runners := (current_role == Role.TAYA)

	var all_players = get_tree().get_nodes_in_group("players")
	for p in all_players:
		if p is PlayerController and p != self:
			var candidate: PlayerController = p
			var d := global_position.distance_to(candidate.global_position)

			if is_hunting_runners:
				# Taya looks for closest Runner
				if candidate.current_role == Role.RUNNER and not candidate.is_immune and not candidate.is_eliminated:
					if d < min_dist:
						min_dist = d
						best_target = candidate
			else:
				# Runner looks for closest Taya
				if candidate.current_role == Role.TAYA and not candidate.is_eliminated:
					if d < min_dist:
						min_dist = d
						best_target = candidate

	var target_is_taya := false
	if best_target:
		target_is_taya = (best_target.current_role == Role.TAYA)

	tag_pointer.update_pointer(camera, best_target, target_is_taya, is_hunting_runners)

func _try_tag() -> void:
	if tag_cooldown > 0.0:
		return

	tag_cooldown = tag_cooldown_max
	if model:
		model.trigger_tag_animation()
	if multiplayer.has_multiplayer_peer():
		rpc("play_tag_anim_rpc")

	if current_role != Role.TAYA:
		return

	# Search for closest valid runner within TAG_REACH
	var target_to_tag: PlayerController = null
	var min_dist: float = TAG_REACH

	var all_players = get_tree().get_nodes_in_group("players")
	for p in all_players:
		if p is PlayerController and p != self:
			var candidate: PlayerController = p
			if candidate.current_role == Role.RUNNER and not candidate.is_immune and not candidate.is_eliminated:
				var dist := global_position.distance_to(candidate.global_position)
				if dist <= TAG_REACH and dist < min_dist:
					min_dist = dist
					target_to_tag = candidate

	# Also check lock-on target from pointer if within tag reach
	if not target_to_tag and tag_pointer and tag_pointer.current_target is PlayerController:
		var tracked_p: PlayerController = tag_pointer.current_target as PlayerController
		if tracked_p.current_role == Role.RUNNER and not tracked_p.is_immune and not tracked_p.is_eliminated:
			if global_position.distance_to(tracked_p.global_position) <= TAG_REACH:
				target_to_tag = tracked_p

	if target_to_tag:
		# Forward lunge towards target on tag
		var lunge_dir := (target_to_tag.global_position - global_position).normalized()
		lunge_dir.y = 0.0
		velocity += lunge_dir * 5.5
		squash_current = Vector3(0.85, 0.85, 1.3)

		if is_local_human():
			add_shake(0.4)
			trigger_hit_stop(55.0)
			var main_node = get_node_or_null("/root/Main")
			if main_node and main_node.hud and main_node.hud.has_method("trigger_hit_flash"):
				main_node.hud.trigger_hit_flash(Color(1.0, 0.85, 0.2, 0.45), 0.22)
			if Input.has_method("vibrate_handheld"):
				Input.vibrate_handheld(80)

		# Spawn visual hit effect locally & popup score combat text
		spawn_hit_vfx(target_to_tag.global_position + Vector3(0, 1.2, 0))
		FloatingTextScript.spawn(get_parent(), target_to_tag.global_position + Vector3(0, 2.0, 0), "💥 HULI! +1", Color(1.0, 0.88, 0.2))

		# Execute tag on server or locally
		tagged_other_player.emit(target_to_tag.player_id)
		if multiplayer.has_multiplayer_peer() and not multiplayer.is_server():
			rpc_id(1, "request_tag_player", target_to_tag.player_id)
		else:
			_server_process_tag(player_id, target_to_tag.player_id)

func spawn_hit_vfx(pos: Vector3) -> void:
	var vfx_scene: PackedScene = preload("res://scenes/player/TagHitVFX.tscn")
	if vfx_scene:
		var vfx = vfx_scene.instantiate()
		var parent_node = get_parent()
		if parent_node:
			parent_node.add_child(vfx)
			vfx.global_position = pos
		else:
			vfx.queue_free()

@rpc("any_peer", "call_local", "reliable")
func spawn_hit_vfx_rpc(pos: Vector3) -> void:
	spawn_hit_vfx(pos)

func _process_remote_interpolation(delta: float) -> void:
	global_position = global_position.lerp(target_position, delta * 18.0)
	if model:
		model.rotation.y = lerp_angle(model.rotation.y, target_rotation_y, delta * 18.0)
		if tag_area:
			tag_area.rotation.y = model.rotation.y

func _process_scoring(delta: float) -> void:
	if current_role == Role.RUNNER:
		survival_time += delta

@rpc("call_local", "reliable")
func play_tag_anim_rpc() -> void:
	if model:
		model.trigger_tag_animation()

@rpc("unreliable")
func sync_transform(pos: Vector3, rot_y: float, _speed: float, _floor: bool, remote_slide: bool, remote_dash: bool) -> void:
	target_position = pos
	target_rotation_y = rot_y
	is_sliding = remote_slide
	is_dashing = remote_dash

@rpc("any_peer", "call_local", "reliable")
func request_tag_player(target_id: int) -> void:
	if not multiplayer.is_server():
		return

	var chaser_id := multiplayer.get_remote_sender_id()
	if chaser_id == 0:
		chaser_id = player_id

	_server_process_tag(chaser_id, target_id)

func _server_process_tag(chaser_id: int, target_id: int) -> void:
	var players_node := get_parent()
	if not players_node:
		return
	var target_node: PlayerController = players_node.get_node_or_null(str(target_id)) as PlayerController
	var chaser_node: PlayerController = players_node.get_node_or_null(str(chaser_id)) as PlayerController

	if target_node and chaser_node:
		if target_node.is_eliminated or chaser_node.is_eliminated:
			return
		var dist: float = chaser_node.global_position.distance_to(target_node.global_position)
		if dist <= (TAG_REACH + 1.8) and not target_node.is_immune and target_node.current_role == Role.RUNNER:
			chaser_node.tag_count += 1
			# Broadcast hit visual effect to all clients
			if multiplayer.has_multiplayer_peer():
				rpc("spawn_hit_vfx_rpc", target_node.global_position + Vector3(0, 1.2, 0))

			# Apply tag to target
			target_node.apply_tagged(chaser_id)

			# In Classic Tag mode, former chaser becomes a Runner with immunity to escape!
			var game_mgr = get_node_or_null("/root/Main")
			var is_infection_mode: bool = false
			if game_mgr and game_mgr.has_method("is_infection"):
				is_infection_mode = game_mgr.is_infection()

			if not is_infection_mode:
				chaser_node.set_role_rpc(Role.RUNNER)
				chaser_node.grant_immunity_rpc(immunity_time)
				if multiplayer.has_multiplayer_peer():
					chaser_node.rpc("set_role_rpc", Role.RUNNER)
					chaser_node.rpc("grant_immunity_rpc", immunity_time)

			# Notify GameManager to update scoreboard and show match broadcast banner
			if game_mgr and game_mgr.has_method("notify_tag_event"):
				game_mgr.notify_tag_event(chaser_id, target_id)

func apply_tagged(_chaser_id: int) -> void:
	if has_trash():
		drop_trash()
	if Engine.has_singleton("AudioManager"):
		AudioManager.play_tag_boom()
	elif has_node("/root/AudioManager"):
		get_node("/root/AudioManager").play_tag_boom()

	squash_current = Vector3(1.3, 0.7, 1.3)

	if is_local_human():
		add_shake(0.7)
		trigger_hit_stop(65.0)
		var main_node = get_node_or_null("/root/Main")
		if main_node and main_node.hud and main_node.hud.has_method("trigger_hit_flash"):
			main_node.hud.trigger_hit_flash(Color(1.0, 0.15, 0.15, 0.55), 0.28)
		if Input.has_method("vibrate_handheld"):
			Input.vibrate_handheld(150)

	FloatingTextScript.spawn(get_parent(), global_position + Vector3(0, 2.0, 0), "💥 NA-TAYA!", Color(1.0, 0.25, 0.25))

	set_role_rpc(Role.TAYA)
	grant_immunity_rpc(immunity_time)
	if multiplayer.has_multiplayer_peer():
		rpc("set_role_rpc", Role.TAYA)
		rpc("grant_immunity_rpc", immunity_time)

@rpc("any_peer", "call_local", "reliable")
func set_role_rpc(new_role: int) -> void:
	current_role = new_role as Role
	_update_role_state()
	role_changed.emit(current_role)

@rpc("any_peer", "call_local", "reliable")
func grant_immunity_rpc(duration: float) -> void:
	is_immune = true
	current_immunity_timer = duration

func _update_role_state() -> void:
	if model:
		model.is_taya = (current_role == Role.TAYA)
	if mobile_ui:
		mobile_ui.set_tag_button_highlight(current_role == Role.TAYA)
	if name_label:
		if current_role == Role.TAYA:
			name_label.text = "[TAYA] " + player_name
			name_label.modulate = Color(1.0, 0.25, 0.2)
		else:
			name_label.text = player_name
			name_label.modulate = Color(0.9, 0.9, 0.9)

# --- Waste Segregation & Inventory System ---
func has_trash() -> bool:
	return held_trash != -1

func pickup_trash(item: TrashItem) -> bool:
	if is_eliminated or has_trash():
		return false

	held_trash = item.trash_type
	held_trash_name = item.get_item_name()
	held_trash_category = item.get_bin_category()

	_update_held_item_visuals()

	if is_local_human():
		trash_changed.emit(held_trash, held_trash_name, held_trash_category)
		_update_interactable_target()

	return true

func deposit_trash(is_correct: bool, _bin_cat: int) -> void:
	if not is_correct:
		# Subtle negative feedback is handled visually and via sound by the RecyclingBin
		return

	# Correct deposit!
	held_trash = -1
	held_trash_name = ""
	held_trash_category = 0

	_update_held_item_visuals()

	# Award score via GameManager
	var gm = get_node_or_null("/root/Main")
	if gm and gm.has_method("award_recycle_points"):
		gm.award_recycle_points(player_id, 30)

	if Engine.has_singleton("AudioManager"):
		AudioManager.play_score_ding()
	elif has_node("/root/AudioManager"):
		get_node("/root/AudioManager").play_score_ding()

	FloatingTextScript.spawn(get_parent(), global_position + Vector3(0, 2.0, 0), "✨ +30 SCORE! ♻️", Color(0.2, 1.0, 0.45))

	# Grant random powerup!
	grant_random_powerup()

	if is_local_human():
		trash_changed.emit(-1, "", 0)
		_update_interactable_target()

# --- Imagination Powerup System ---
func grant_random_powerup() -> PowerupType:
	var options = [
		PowerupType.DASH,
		PowerupType.SUPER_SPEED,
		PowerupType.DOUBLE_JUMP,
		PowerupType.WATER_RUN,
		PowerupType.WALL_RUN
	]
	var chosen: PowerupType = options.pick_random() as PowerupType
	set_powerup(chosen)

	if Engine.has_singleton("AudioManager"):
		AudioManager.play_powerup()
	elif has_node("/root/AudioManager"):
		get_node("/root/AudioManager").play_powerup()

	return chosen

func set_powerup(p_type: PowerupType, duration: float = 16.0) -> void:
	active_powerup = p_type
	powerup_time_left = duration

	if active_powerup == PowerupType.DASH:
		dash_charges_left = 3
	elif active_powerup == PowerupType.DOUBLE_JUMP:
		max_air_jumps = 1
		air_jumps_left = 1
	else:
		max_air_jumps = 0
		air_jumps_left = 0

	_update_powerup_visuals()

	if is_local_human():
		powerup_changed.emit(active_powerup, powerup_time_left, dash_charges_left)

	if multiplayer.has_multiplayer_peer():
		rpc("sync_powerup_state", int(active_powerup))

func clear_powerup() -> void:
	var was_active = (active_powerup != PowerupType.NONE)
	active_powerup = PowerupType.NONE
	powerup_time_left = 0.0
	dash_charges_left = 0
	max_air_jumps = 0
	air_jumps_left = 0

	_update_powerup_visuals()

	if is_local_human():
		powerup_changed.emit(active_powerup, 0.0, 0)
		if was_active:
			notification_displayed.emit("💨 Naglaho na ang kapangyarihan!", false)

	if multiplayer.has_multiplayer_peer():
		rpc("sync_powerup_state", 0)

@rpc("any_peer", "call_local", "reliable")
func sync_powerup_state(p_type: int) -> void:
	active_powerup = p_type as PowerupType
	_update_powerup_visuals()

func get_powerup_name() -> String:
	match active_powerup:
		PowerupType.DASH:
			return "⚡ KIDLAT DASH (3x)"
		PowerupType.SUPER_SPEED:
			return "🏃 SUPER SPEED (Bilis-Alon)"
		PowerupType.DOUBLE_JUMP:
			return "🦘 DOUBLE JUMP (Luksong-Tinik)"
		PowerupType.WATER_RUN:
			return "🌊 WATER RUN (Lundag-Baha)"
		PowerupType.WALL_RUN:
			return "🧗 WALL RUN (Akyat-Pader)"
	return "WALA"

func set_in_water(in_water: bool) -> void:
	is_in_water = in_water
	if is_in_water and active_powerup == PowerupType.WATER_RUN:
		if is_local_human():
			notification_displayed.emit("🌊 WATER RUN! Tumatakbo sa ibabaw ng baha!", true)

func _update_powerup_visuals() -> void:
	if powerup_aura:
		if active_powerup != PowerupType.NONE:
			powerup_aura.emitting = true
			match active_powerup:
				PowerupType.DASH:
					powerup_aura.color = Color(0.2, 0.9, 1.0, 0.9)
				PowerupType.SUPER_SPEED:
					powerup_aura.color = Color(1.0, 0.85, 0.1, 0.9)
				PowerupType.DOUBLE_JUMP:
					powerup_aura.color = Color(0.3, 1.0, 0.5, 0.9)
				PowerupType.WATER_RUN:
					powerup_aura.color = Color(0.1, 0.6, 1.0, 0.9)
				PowerupType.WALL_RUN:
					powerup_aura.color = Color(0.9, 0.3, 1.0, 0.9)
		else:
			powerup_aura.emitting = false

	if mobile_ui and mobile_ui.has_method("update_powerup_buttons"):
		mobile_ui.update_powerup_buttons(active_powerup, dash_charges_left)

func _update_held_item_visuals() -> void:
	if model and model.has_method("set_held_trash"):
		model.set_held_trash(held_trash)
	if held_item_display:
		held_item_display.visible = false
	if mobile_ui and mobile_ui.has_method("set_drop_button_visible"):
		mobile_ui.set_drop_button_visible(has_trash())
	if is_local_human() and multiplayer.has_multiplayer_peer():
		rpc("sync_held_trash_rpc", held_trash)

@rpc("any_peer", "call_local", "reliable")
func sync_held_trash_rpc(t_type: int) -> void:
	held_trash = t_type
	if model and model.has_method("set_held_trash"):
		model.set_held_trash(t_type)

# --- Contextual Interaction & Loot System ---
func _try_interact() -> void:
	_update_interactable_target()
	if not is_instance_valid(current_interactable):
		return
	if current_interactable is TrashItem:
		current_interactable.interact(self)
	elif current_interactable is RecyclingBin:
		current_interactable.interact(self)

func drop_trash() -> void:
	if not has_trash():
		return
	var _dropped_type := held_trash
	held_trash = -1
	held_trash_name = ""
	held_trash_category = 0
	_update_held_item_visuals()

	if Engine.has_singleton("AudioManager"):
		AudioManager.play_drop()
	elif has_node("/root/AudioManager"):
		get_node("/root/AudioManager").play_drop()

	if is_local_human():
		trash_changed.emit(-1, "", 0)
		_update_interactable_target()

func register_nearby_interactable(node: Node3D) -> void:
	if not nearby_interactables.has(node):
		nearby_interactables.append(node)
	_update_interactable_target()

func unregister_nearby_interactable(node: Node3D) -> void:
	nearby_interactables.erase(node)
	if current_interactable == node:
		current_interactable = null
	_update_interactable_target()

func _update_interactable_target() -> void:
	var valid_list: Array[Node3D] = []
	for item in nearby_interactables:
		if is_instance_valid(item):
			valid_list.append(item)
	nearby_interactables = valid_list

	if nearby_interactables.is_empty():
		current_interactable = null
		interactable_changed.emit(false, "", "")
		if mobile_ui and mobile_ui.has_method("set_interact_prompt"):
			mobile_ui.set_interact_prompt(false, "", "")
		return

	# Prioritize by distance and suitability
	var best: Node3D = null
	var min_d: float = 999.0
	for item in nearby_interactables:
		if item is TrashItem and has_trash():
			continue # Already carrying an item
		var d: float = global_position.distance_to(item.global_position)
		if d < min_d:
			min_d = d
			best = item

	current_interactable = best
	if is_instance_valid(current_interactable):
		var icon: String = "✨"
		var action: String = "INTERACT"
		if current_interactable is TrashItem:
			icon = current_interactable.get_item_icon()
			action = "PULUTIN"
		elif current_interactable is RecyclingBin:
			icon = "🗑️"
			action = "IPASOK" if has_trash() else "BASURAHAN"
		interactable_changed.emit(true, icon, action)
		if mobile_ui and mobile_ui.has_method("set_interact_prompt"):
			mobile_ui.set_interact_prompt(true, icon, action)
	else:
		interactable_changed.emit(false, "", "")
		if mobile_ui and mobile_ui.has_method("set_interact_prompt"):
			mobile_ui.set_interact_prompt(false, "", "")

func _check_danger_proximity() -> void:
	if current_role != Role.RUNNER:
		danger_detected.emit(false, 0.0)
		return

	var min_dist: float = 999.0
	for p in get_tree().get_nodes_in_group("players"):
		if p is PlayerController and p != self and p.current_role == Role.TAYA:
			var d := global_position.distance_to(p.global_position)
			if d < min_dist:
				min_dist = d

	if min_dist < 14.0:
		danger_detected.emit(true, min_dist)
		if min_dist < 8.0:
			if Engine.has_singleton("AudioManager"):
				AudioManager.play_danger()
			elif has_node("/root/AudioManager"):
				get_node("/root/AudioManager").play_danger()
	else:
		danger_detected.emit(false, 0.0)
