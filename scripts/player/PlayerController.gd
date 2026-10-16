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
signal street_item_changed(item_type: int, item_name: String, count: int)
signal hiding_state_changed(is_hiding: bool, time_left: float)
signal vault_available_changed(is_available: bool)
signal emote_triggered(emote_text: String)

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

var is_solo_practice: bool:
	get:
		var main_node = _get_main_node()
		if main_node and "network_manager" in main_node and main_node.network_manager:
			return main_node.network_manager.is_solo_practice
		return false

func _get_main_node() -> Node:
	var cur := get_parent()
	while cur:
		if ("players_container" in cur and "hud" in cur) or cur is GameManager:
			return cur
		cur = cur.get_parent()
	var m = get_node_or_null("/root/Main")
	if m and is_instance_valid(m) and not m.is_queued_for_deletion():
		return m
	return get_tree().current_scene if (is_inside_tree() and get_tree()) else null

func trigger_device_vibration(duration_ms: int) -> void:
	var gm = _get_main_node()
	if gm and gm.has_method("is_vibration_enabled") and not gm.is_vibration_enabled():
		return
	if Input.has_method("vibrate_handheld"):
		Input.vibrate_handheld(duration_ms)

func is_local_human() -> bool:
	if is_bot:
		return false
	if is_inside_tree() and multiplayer and multiplayer.has_multiplayer_peer():
		var my_id := multiplayer.get_unique_id()
		return player_id == my_id or get_multiplayer_authority() == my_id
	return player_id == 1

func is_local_controlled() -> bool:
	if is_bot:
		return is_multiplayer_authority()
	return is_local_human()

@export var player_name: String = "Player"
var player_title: String = ""

func set_player_title(title: String) -> void:
	player_title = title
	if name_label:
		if not player_title.is_empty():
			name_label.text = "%s\n«%s»" % [player_name, player_title]
		else:
			name_label.text = player_name

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

# Kalye Action Match Stats (for Leaderboard & Awards)
var stats_tags: int = 0
var stats_slips: int = 0
var stats_recycled: int = 0
var stats_hits: int = 0
var stats_hiding_time: float = 0.0
var stats_sprint_time: float = 0.0

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

# Parkour & Vaulting State
var is_vaulting: bool = false
var vault_progress: float = 0.0
var vault_duration: float = 0.40
var vault_start_pos: Vector3 = Vector3.ZERO
var vault_apex_pos: Vector3 = Vector3.ZERO
var vault_end_pos: Vector3 = Vector3.ZERO
var vault_forward_dir: Vector3 = Vector3.FORWARD
var can_vault: bool = false
var stats_vaults: int = 0

# Base Shelter State (Infected Base Mode)
var is_in_base: bool = false
var base_shelter_timer: float = 8.0
var base_shelter_max: float = 8.0
var base_cooldown_timer: float = 0.0

var coyote_timer: float = 0.0
var jump_buffer_timer: float = 0.0
var air_jumps_left: int = 0
var tag_cooldown: float = 0.0
var tag_cooldown_max: float = 0.6
var current_immunity_timer: float = 0.0
var power_reveal_timer: float = 0.0

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

# Street Items, Traps & Hiding State
var held_street_item: int = -1
var held_street_item_name: String = ""
var held_street_item_count: int = 0
var is_hiding: bool = false
var current_hiding_spot: Node3D = null
var is_slipping: bool = false
var slip_timer: float = 0.0
var slip_velocity: Vector3 = Vector3.ZERO
var chalk_blind_timer: float = 0.0
var is_aiming_throw: bool = false
const TrajectoryPreviewScript = preload("res://scripts/player/TrajectoryPreview.gd")
var trajectory_preview: Node3D = null

# Tournament & Crab Game Elimination State
var is_eliminated: bool = false
var spectating_target: PlayerController = null
var _spec_hud_timer: float = 0.0

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

# Network sync targets and throttling configuration (25Hz Throttling, Ring Buffer, Hermite Spline)
const NETWORK_TICK_RATE: float = 25.0
const NETWORK_TICK_INTERVAL: float = 1.0 / NETWORK_TICK_RATE # 0.04s (25 ticks/sec)
const SNAPSHOT_BUFFER_CAPACITY: int = 8
const INTERPOLATION_DELAY_MS: float = 80.0 # 80ms buffer (2 ticks at 25Hz)
const DELTA_SUPPRESSION_DIST_SQ: float = 0.04 * 0.04 # 0.04m threshold (0.0016 m^2)
const DELTA_SUPPRESSION_ROT: float = 0.02 # 0.02 rad rotation threshold
const HEARTBEAT_INTERVAL: float = 0.5 # 0.5s heartbeat timer for stationary players

# Network broadcasting state (Local Authority)
var _net_tick_timer: float = 0.0
var _net_tick_counter: int = 0
var _last_sent_position: Vector3 = Vector3.ZERO
var _last_sent_rotation_y: float = 0.0
var _last_sent_sliding: bool = false
var _last_sent_dashing: bool = false
var _last_sent_on_floor: bool = true
var _heartbeat_timer: float = 0.0

# Network remote targets & Snapshot Ring Buffer (Remote Peers)
var target_position: Vector3 = Vector3.ZERO
var target_velocity: Vector3 = Vector3.ZERO
var target_rotation_y: float = 0.0
var remote_horizontal_speed: float = 0.0
var remote_is_on_floor: bool = true
var snapshot_ring_buffer: Array[Dictionary] = []
var _interpolation_render_time_ms: float = 0.0
var _interpolation_initialized: bool = false

func _ready() -> void:
	add_to_group("players")
	set_multiplayer_authority(player_id)
	if name_label:
		name_label.text = player_name
		name_label.visible = false
	target_position = global_position
	target_rotation_y = model.rotation.y if model else 0.0
	_last_sent_position = global_position
	_last_sent_rotation_y = target_rotation_y
	snapshot_ring_buffer.clear()
	_interpolation_initialized = false
	_interpolation_render_time_ms = 0.0
	floor_max_angle = deg_to_rad(60.0)
	floor_snap_length = 0.35
	floor_constant_speed = true
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

		trajectory_preview = TrajectoryPreviewScript.new()
		trajectory_preview.name = "TrajectoryPreview"
		add_child(trajectory_preview)
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
			if hud_node.has_method("on_street_item_changed"):
				street_item_changed.connect(hud_node.on_street_item_changed)
				street_item_changed.emit(held_street_item, held_street_item_name, held_street_item_count)
			if hud_node.has_method("on_hiding_state_changed"):
				hiding_state_changed.connect(hud_node.on_hiding_state_changed)

func _setup_mobile_ui() -> void:
	if not mobile_ui:
		return
	mobile_ui.camera_dragged.connect(_on_mobile_camera_dragged)
	mobile_ui.jump_pressed.connect(func(): _queue_jump())
	mobile_ui.sprint_toggled.connect(func(sprint_on: bool):
		if not _is_game_paused():
			is_sprinting = sprint_on
	)
	mobile_ui.slide_pressed.connect(func(): _try_slide())
	mobile_ui.dash_pressed.connect(func(): _try_dash())
	mobile_ui.tag_pressed.connect(func(): _try_tag())
	if mobile_ui.has_signal("item_pressed"):
		mobile_ui.item_pressed.connect(func(): _on_item_input_pressed())
	if mobile_ui.has_signal("item_released"):
		mobile_ui.item_released.connect(func(): _on_item_input_released())
	if mobile_ui.has_signal("interact_pressed"):
		mobile_ui.interact_pressed.connect(func(): _try_interact())
	if mobile_ui.has_signal("drop_pressed"):
		mobile_ui.drop_pressed.connect(func(): drop_trash())
	if mobile_ui.has_method("on_powerup_changed"):
		powerup_changed.connect(mobile_ui.on_powerup_changed)
	if mobile_ui.has_method("update_powerup_buttons"):
		mobile_ui.update_powerup_buttons(active_powerup, dash_charges_left)
	if mobile_ui.has_method("set_tag_button_highlight"):
		mobile_ui.set_tag_button_highlight(current_role == Role.TAYA)
	if mobile_ui.has_signal("prev_spectate_pressed"):
		mobile_ui.prev_spectate_pressed.connect(func(): _cycle_spectate_target(-1))
	if mobile_ui.has_signal("next_spectate_pressed"):
		mobile_ui.next_spectate_pressed.connect(func(): _cycle_spectate_target(1))
	if mobile_ui.has_method("set_spectator_mode"):
		mobile_ui.set_spectator_mode(is_eliminated)
	if mobile_ui.has_signal("vault_pressed"):
		mobile_ui.vault_pressed.connect(func(): _try_vault())
	if mobile_ui.has_method("set_vault_available"):
		vault_available_changed.connect(mobile_ui.set_vault_available)

func _is_game_paused() -> bool:
	var main_node = get_node_or_null("/root/Main")
	return bool(main_node and ("is_game_paused" in main_node) and main_node.is_game_paused)

func _unhandled_input(event: InputEvent) -> void:
	if not is_local_human() or _is_game_paused():
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
			if is_cursor_free or Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
				is_cursor_free = false
				Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			if event.button_index in [MOUSE_BUTTON_LEFT, MOUSE_BUTTON_WHEEL_DOWN]:
				_cycle_spectate_target(1)
				get_viewport().set_input_as_handled()
			elif event.button_index in [MOUSE_BUTTON_RIGHT, MOUSE_BUTTON_WHEEL_UP]:
				_cycle_spectate_target(-1)
				get_viewport().set_input_as_handled()
		elif event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			_rotate_camera(-event.relative.x * mouse_sensitivity, -event.relative.y * mouse_sensitivity)
		return

	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_T and is_solo_practice:
			var next_role: Role = Role.RUNNER if current_role == Role.TAYA else Role.TAYA
			current_role = next_role
			_update_role_state()

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

	# Right-Click: Use/Throw street item (Hold to Aim, Release to Throw)
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT:
		if not is_cursor_free and not _is_game_paused() and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			if event.pressed:
				_on_item_input_pressed()
			else:
				_on_item_input_released()
			get_viewport().set_input_as_handled()
			return

	# Key inputs for Items & Hiding
	if event is InputEventKey and not event.is_echo():
		if event.keycode == KEY_G:
			if not is_cursor_free and not _is_game_paused():
				if event.pressed:
					_on_item_input_pressed()
				else:
					_on_item_input_released()
				get_viewport().set_input_as_handled()
				return
		elif event.keycode == KEY_E and event.pressed:
			_try_interact()
			get_viewport().set_input_as_handled()
			return
		elif event.keycode == KEY_SPACE and is_hiding:
			exit_hiding_spot()
			get_viewport().set_input_as_handled()
			return

	# Mouse look when captured (only when cursor is NOT free and game is not paused)
	if not is_cursor_free and not _is_game_paused() and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED and event is InputEventMouseMotion:
		_rotate_camera(-event.relative.x * mouse_sensitivity, -event.relative.y * mouse_sensitivity)

func _on_mobile_camera_dragged(relative_vec: Vector2) -> void:
	if _is_game_paused() or not is_local_human():
		return
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
	if elim and is_aiming_throw:
		_cancel_throw_aim()
	if elim and is_hiding:
		exit_hiding_spot()
	if collision_shape:
		collision_shape.disabled = elim
	if model:
		model.visible = not elim
	if name_label:
		name_label.visible = not elim
	if tag_pointer:
		tag_pointer.visible = not elim
	if elim:
		velocity = Vector3.ZERO
		global_position = Vector3(0, -50, 0)
	if is_local_human():
		if mobile_ui and mobile_ui.has_method("set_spectator_mode"):
			mobile_ui.set_spectator_mode(elim)
		if elim:
			add_shake(0.85)
			trigger_device_vibration(250)
			_cycle_spectate_target(1)
		else:
			spectating_target = null
			var main_node = _get_main_node()
			if main_node and main_node.hud:
				main_node.hud.hide_spectator_bar()

func _cycle_spectate_target(step: int = 1) -> void:
	if not is_local_human():
		return
	var main_node = _get_main_node()
	if not main_node or not ("players_container" in main_node) or not main_node.players_container:
		return
	var alive_candidates: Array[PlayerController] = []
	if "alive_player_ids" in main_node and not main_node.alive_player_ids.is_empty():
		for pid in main_node.alive_player_ids:
			if pid != player_id:
				var p: PlayerController = main_node.players_container.get_node_or_null(str(pid)) as PlayerController
				if p and is_instance_valid(p) and not p.is_eliminated:
					alive_candidates.append(p)
	else:
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
		if spring_arm:
			spring_arm.add_excluded_object(spectating_target.get_rid())
		if camera_mount:
			camera_mount.global_position = spectating_target.global_position + Vector3(0, 1.4, 0)
		_update_spectator_hud()

func _update_spectator_hud() -> void:
	if not is_local_human() or not is_instance_valid(spectating_target):
		return
	var main_node = _get_main_node()
	if not main_node or not ("hud" in main_node) or not main_node.hud:
		return
	var alive_count: int = main_node.alive_player_ids.size() if ("alive_player_ids" in main_node) else 1
	if main_node.hud.has_method("update_spectator_info"):
		var target_name: String = str(spectating_target.player_name) if ("player_name" in spectating_target) else "Player"
		var target_role: int = int(spectating_target.current_role) if ("current_role" in spectating_target) else 0
		var target_score: int = int(spectating_target.score) if ("score" in spectating_target) else 0
		var target_tags: int = int(spectating_target.stats_tags) if ("stats_tags" in spectating_target) else 0
		var spec_info: Dictionary = {
			"name": target_name,
			"role": target_role,
			"score": target_score,
			"tags": target_tags,
			"alive_count": alive_count
		}
		main_node.hud.update_spectator_info(spec_info)
	elif main_node.hud.has_method("show_spectator_bar"):
		main_node.hud.show_spectator_bar(spectating_target.player_name)

func _physics_process(delta: float) -> void:
	var main_node = _get_main_node()
	if is_eliminated:
		if is_local_human():
			if is_instance_valid(spectating_target) and not spectating_target.is_eliminated:
				var target_cam_pos: Vector3 = spectating_target.global_position + Vector3(0, 1.4, 0)
				if camera_mount:
					if camera_mount.global_position.distance_squared_to(target_cam_pos) > 225.0:
						camera_mount.global_position = target_cam_pos
					else:
						camera_mount.global_position = camera_mount.global_position.lerp(target_cam_pos, delta * 25.0)
				_spec_hud_timer -= delta
				if _spec_hud_timer <= 0.0:
					_spec_hud_timer = 0.2
					_update_spectator_hud()
			else:
				_cycle_spectate_target(1)
			_process_shake(delta)
		else:
			velocity = Vector3.ZERO
		return

	_update_timers(delta)

	if is_hiding:
		stats_hiding_time += delta
		velocity = Vector3.ZERO
		if model: model.visible = false
		if name_label: name_label.visible = false
		_process_shake(delta)
		return

	if is_local_human():
		_process_authority_movement(delta)
		_process_scoring(delta)
		_update_tag_targeting()
		_update_mobile_tag_proximity()
		_update_name_tags_proximity()
		_update_camera_fov(delta)
		_update_interactable_target()
		_process_shake(delta)
		danger_check_timer -= delta
		if danger_check_timer <= 0.0:
			danger_check_timer = 0.25
			_check_danger_proximity()
		# Throttled 25Hz network sync with 3-tier distance culling & delta suppression
		if multiplayer.has_multiplayer_peer() and not is_solo_practice:
			_process_network_sync_broadcasting(delta)
	else:
		_process_remote_interpolation(delta)

	# Update procedural animations & squash deformation
	if model:
		squash_current = squash_current.lerp(squash_target, delta * 15.0)
		squash_target = squash_target.lerp(Vector3.ONE, delta * 8.0)
		model.scale = model_base_scale * squash_current
		var horizontal_speed: float
		var current_floor: bool
		if is_local_human():
			horizontal_speed = Vector2(velocity.x, velocity.z).length()
			current_floor = is_on_floor()
		else:
			horizontal_speed = remote_horizontal_speed
			current_floor = remote_is_on_floor

		var current_max: float = sprint_speed if (is_sprinting or horizontal_speed > 8.0) else walk_speed
		model.is_sliding = is_sliding
		model.is_dashing = is_dashing
		model.is_vaulting = is_vaulting
		model.is_slipping = is_slipping or (is_stunned and stun_timer > 0.0)
		model.is_stunned = is_stunned and stun_timer > 0.0
		model.has_superspeed = (active_powerup == PowerupType.SUPER_SPEED)
		model.animate(delta, horizontal_speed, current_floor, current_max)

	if slide_dust:
		var floor_check: bool = is_on_floor() if is_local_human() else remote_is_on_floor
		slide_dust.emitting = (is_sliding or (is_dashing and floor_check))

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
	if power_reveal_timer > 0.0: power_reveal_timer -= delta

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
				notification_displayed.emit("Okay na! Tumakbo na ulit!", true)

	if is_slipping:
		slip_timer -= delta
		if slip_timer <= 0.0:
			is_slipping = false

	if chalk_blind_timer > 0.0:
		chalk_blind_timer -= delta

	# Base shelter stamina update (Infected Base)
	if is_in_base:
		if current_role == Role.RUNNER:
			if base_shelter_timer > 0.0:
				base_shelter_timer = maxf(0.0, base_shelter_timer - delta)
				if base_shelter_timer <= 0.0 and is_local_human():
					notification_displayed.emit("UBOS NA ANG LIGTAS TIME SA BASE! Tumakbo!", false)
					var am = get_node_or_null("/root/AudioManager")
					if am and am.has_method("play_whiff"):
						am.play_whiff()
	else:
		if base_cooldown_timer > 0.0:
			base_cooldown_timer = maxf(0.0, base_cooldown_timer - delta)
		elif base_shelter_timer < base_shelter_max:
			base_shelter_timer = minf(base_shelter_max, base_shelter_timer + delta * 1.6)

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
	if is_aiming_throw:
		_cancel_throw_aim()
	is_stunned = true
	stun_timer = duration
	velocity = Vector3.ZERO
	squash_current = Vector3(1.2, 0.7, 1.2)
	if model and model.has_method("trigger_slip_animation"):
		model.trigger_slip_animation(duration)
	if is_inside_tree() and multiplayer and multiplayer.has_multiplayer_peer():
		rpc("play_slip_anim_rpc", duration)
	if name_label:
		name_label.text = "NA-STUN!"
	FloatingTextScript.spawn(get_parent(), global_position + Vector3(0, 2.0, 0), "ARF! NA-STUN!", Color(1.0, 0.7, 0.2))
	if is_local_human():
		add_shake(0.7)
		trigger_device_vibration(200)
		notification_displayed.emit("Kinagat ng aso!", false)

func _process_authority_movement(delta: float) -> void:
	# Decoupled camera tracking player smoothly
	if camera_mount:
		var cam_speed: float = 35.0 if (is_slipping or is_stunned) else 25.0
		camera_mount.global_position = camera_mount.global_position.lerp(global_position + Vector3(0, 1.4, 0), delta * cam_speed)

	# Fall safeguard
	if global_position.y < -10.0:
		global_position = Vector3(0, 1.0, 0)
		velocity = Vector3.ZERO

	# Asymmetric Gravity
	if not is_on_floor() and not is_wall_running and not is_slipping:
		if velocity.y > 0.0:
			velocity.y += jump_gravity * delta
		else:
			velocity.y += fall_gravity * delta

	# Stun & Slip gate — freeze all input while stunned or slipping in exact place
	if is_stunned or is_slipping:
		if is_aiming_throw:
			_cancel_throw_aim()
		if is_slipping:
			velocity.y = 0.0
		velocity.x = move_toward(velocity.x, 0.0, friction * 2.0 * delta)
		velocity.z = move_toward(velocity.z, 0.0, friction * 2.0 * delta)
		move_and_slide()
		return

	# Handle active Vault
	if is_vaulting:
		if is_aiming_throw:
			_cancel_throw_aim()
		_process_vault(delta)
		if not is_vaulting:
			move_and_slide()
			_process_landing_and_footsteps(delta)
		return

	# In-game pause menu or cursor-free gate: freeze gameplay movement/actions while maintaining physics & gravity
	if _is_game_paused() or is_cursor_free:
		if is_aiming_throw:
			_cancel_throw_aim()
		if is_sliding:
			_end_slide()
		is_sprinting = false
		is_dashing = false
		is_wall_running = false
		_process_stamina(delta, false)
		velocity.x = move_toward(velocity.x, 0.0, friction * delta)
		velocity.z = move_toward(velocity.z, 0.0, friction * delta)
		move_and_slide()
		_process_landing_and_footsteps(delta)
		return

	# Update vaultable obstacle status
	var prev_can_vault := can_vault
	can_vault = _check_vaultable_obstacle()
	if can_vault != prev_can_vault:
		vault_available_changed.emit(can_vault)

	# Input checks
	var sprint_requested: bool = false
	if Input.is_action_pressed("sprint"):
		sprint_requested = true
	elif mobile_ui and mobile_ui.is_sprinting:
		sprint_requested = true

	if Input.is_action_just_pressed("jump"):
		if can_vault and _try_vault():
			jump_buffer_timer = 0.0
		else:
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

	# Tactical aiming speed constraint
	if is_aiming_throw:
		target_speed = min(target_speed, current_walk_spd * 0.72)

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
	else:
		velocity.x = move_toward(velocity.x, 0.0, friction * delta)
		velocity.z = move_toward(velocity.z, 0.0, friction * delta)

	# Character facing: face camera/aim while aiming throw, otherwise face movement direction
	if is_aiming_throw and cam_forward.length() > 0.1:
		var aim_facing := wrapf(atan2(-cam_forward.x, -cam_forward.z) - global_rotation.y, -PI, PI)
		model.rotation.y = lerp_angle(model.rotation.y, aim_facing, rotation_speed * delta * 1.5)
		tag_area.rotation.y = model.rotation.y
	elif move_dir.length() > 0.1:
		var target_facing := wrapf(atan2(-move_dir.x, -move_dir.z) - global_rotation.y, -PI, PI)
		model.rotation.y = lerp_angle(model.rotation.y, target_facing, rotation_speed * delta)
		tag_area.rotation.y = model.rotation.y

	# Update throw aiming arc if actively aiming
	if is_aiming_throw:
		_update_throw_aim_trajectory()

	move_and_slide()
	_process_landing_and_footsteps(delta)

func _play_sfx(method_name: String, arg = null) -> void:
	var am = get_node_or_null("/root/AudioManager")
	if not am or not is_instance_valid(am) or not am.has_method(method_name):
		return
	if arg != null:
		am.call(method_name, arg)
	else:
		am.call(method_name)

func _process_landing_and_footsteps(delta: float) -> void:
	# Dynamic Landing Juice
	if is_on_floor() and not was_on_floor_prev:
		if prev_vert_vel < -2.8:
			var impact_spd: float = abs(prev_vert_vel)
			squash_current = Vector3(1.22, 0.74, 1.22)
			_play_sfx("play_land", impact_spd)
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
				_play_sfx("play_footstep", is_in_water)
		else:
			footstep_timer = 0.1
	else:
		footstep_timer = 0.1

func _queue_jump() -> void:
	if _is_game_paused() or is_stunned or is_slipping:
		return
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

	_play_sfx("play_jump")

	if slide_dust:
		slide_dust.restart()
		slide_dust.emitting = true

	# Break slide on jump for slide-jump momentum boost
	if is_sliding:
		velocity.x *= 1.15
		velocity.z *= 1.15
		_end_slide()

func _try_slide() -> void:
	if _is_game_paused() or is_sliding or is_stunned or is_slipping or slide_cooldown > 0.0 or not is_on_floor():
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

	_play_sfx("play_slide")

	# Lower hitbox during slide
	if collision_shape and collision_shape.shape is CapsuleShape3D:
		collision_shape.shape.height = 0.95
		collision_shape.position.y = 0.48

func _end_slide() -> void:
	is_sliding = false
	if collision_shape and collision_shape.shape is CapsuleShape3D:
		collision_shape.shape.height = 1.45
		collision_shape.position.y = 0.725

# --- Parkour & Vaulting Mechanics ---
func _check_vaultable_obstacle() -> bool:
	if not is_inside_tree():
		return false
	var space_state := get_world_3d().direct_space_state
	if not space_state:
		return false

	var fwd := Vector3.ZERO
	var h_vel := Vector2(velocity.x, velocity.z)
	if h_vel.length() > 0.8:
		fwd = Vector3(velocity.x, 0.0, velocity.z).normalized()
	elif model and model.global_transform.basis.z.length_squared() > 0.01:
		fwd = -model.global_transform.basis.z.normalized()
		fwd.y = 0.0
		fwd = fwd.normalized()
	else:
		fwd = -global_transform.basis.z.normalized()
		fwd.y = 0.0
		fwd = fwd.normalized()

	if fwd.length_squared() < 0.1:
		fwd = Vector3.FORWARD

	var exclude_rids: Array[RID] = [get_rid()]

	# 1. Forward obstacle detection ray (supports obstacles from 0.45m to 1.1m)
	var chest_hit := {}
	for test_h in [0.70, 0.45]:
		var cast_start := global_position + Vector3(0.0, test_h, 0.0)
		var cast_end := cast_start + fwd * 1.35
		var cast_query := PhysicsRayQueryParameters3D.create(cast_start, cast_end, 1, exclude_rids)
		var h := space_state.intersect_ray(cast_query)
		if not h.is_empty():
			chest_hit = h
			break

	if chest_hit.is_empty():
		return false

	var hit_pt: Vector3 = chest_hit.position
	var hit_norm: Vector3 = chest_hit.normal

	# Must be facing toward the obstacle
	if hit_norm.dot(fwd) > -0.2:
		return false

	# 2. Forward head/clearance ray (height ~1.65m, reach 1.45m)
	var head_start := global_position + Vector3(0.0, 1.65, 0.0)
	var head_end := head_start + fwd * 1.45
	var head_query := PhysicsRayQueryParameters3D.create(head_start, head_end, 1, exclude_rids)
	var head_hit := space_state.intersect_ray(head_query)

	if not head_hit.is_empty():
		return false

	# 3. Top surface downward ray (from over obstacle, trying multiple forward offsets)
	var top_hit := {}
	for fwd_offset in [0.15, 0.35, 0.05]:
		var top_cast_start: Vector3 = hit_pt + fwd * float(fwd_offset) + Vector3(0.0, 1.2, 0.0)
		var top_cast_end: Vector3 = top_cast_start - Vector3(0.0, 1.8, 0.0)
		var top_query := PhysicsRayQueryParameters3D.create(top_cast_start, top_cast_end, 1, exclude_rids)
		var t_hit := space_state.intersect_ray(top_query)
		if not t_hit.is_empty():
			var h_diff: float = t_hit.position.y - global_position.y
			if h_diff >= 0.3 and h_diff <= 1.4:
				top_hit = t_hit
				break

	if top_hit.is_empty():
		return false

	var obs_top_y: float = top_hit.position.y
	var height_diff: float = obs_top_y - global_position.y
	if height_diff < 0.3 or height_diff > 1.4:
		return false

	# 4. Landing spot downward ray (behind obstacle)
	var land_cast_start := hit_pt + fwd * 1.35 + Vector3(0.0, 1.0, 0.0)
	var land_cast_end := land_cast_start - Vector3(0.0, 2.6, 0.0)
	var land_query := PhysicsRayQueryParameters3D.create(land_cast_start, land_cast_end, 1, exclude_rids)
	var land_hit := space_state.intersect_ray(land_query)

	if land_hit.is_empty():
		return false

	var land_pos: Vector3 = land_hit.position
	if abs(land_pos.y - global_position.y) > 1.8:
		return false

	vault_start_pos = global_position
	vault_apex_pos = Vector3(top_hit.position.x, obs_top_y + 0.35, top_hit.position.z)
	vault_end_pos = land_pos + Vector3(0.0, 0.05, 0.0)
	vault_forward_dir = fwd
	return true

func _trigger_vault(start_pos: Vector3, apex_pos: Vector3, end_pos: Vector3) -> void:
	is_vaulting = true
	vault_progress = 0.0
	vault_start_pos = start_pos
	vault_apex_pos = apex_pos
	vault_end_pos = end_pos
	var diff := end_pos - start_pos
	diff.y = 0.0
	vault_forward_dir = diff.normalized() if diff.length_squared() > 0.01 else Vector3.FORWARD
	stats_vaults += 1
	squash_target = Vector3(0.85, 1.25, 0.85)
	add_shake(0.2)
	_play_sfx("play_vault")
	if is_local_controlled() and multiplayer.has_multiplayer_peer() and not is_solo_practice:
		rpc("sync_vault_trigger", vault_start_pos, vault_apex_pos, vault_end_pos)

func _process_vault(delta: float) -> void:
	if not is_vaulting:
		return
	vault_progress += delta / vault_duration
	if vault_progress >= 1.0:
		is_vaulting = false
		global_position = vault_end_pos
		velocity = vault_forward_dir * sprint_speed
		squash_target = Vector3(1.15, 0.85, 1.15)
		_play_sfx("play_land", sprint_speed)
		return

	var t: float = clampf(vault_progress, 0.0, 1.0)
	var omt: float = 1.0 - t
	global_position = omt * omt * vault_start_pos + 2.0 * omt * t * vault_apex_pos + t * t * vault_end_pos
	if model:
		var target_rot_y := atan2(-vault_forward_dir.x, -vault_forward_dir.z)
		model.rotation.y = lerp_angle(model.rotation.y, target_rot_y, delta * 20.0)

func _try_vault() -> bool:
	if _is_game_paused() or is_vaulting or is_stunned or is_hiding or is_slipping or is_eliminated:
		return false

	if _check_vaultable_obstacle():
		_trigger_vault(vault_start_pos, vault_apex_pos, vault_end_pos)
		return true
	return false

@rpc("call_local", "reliable")
func sync_vault_trigger(start_p: Vector3, apex_p: Vector3, end_p: Vector3) -> void:
	if not is_local_controlled():
		_trigger_vault(start_p, apex_p, end_p)

# --- Social Emotes ---
func trigger_emote(emote_text: String) -> void:
	if _is_game_paused() or is_eliminated or is_hiding:
		return
	if is_local_human():
		if multiplayer.has_multiplayer_peer() and not is_solo_practice:
			rpc("sync_emote", player_id, emote_text)
		else:
			_display_emote(emote_text)

@rpc("call_local", "reliable")
func sync_emote(sender_id: int, emote_text: String) -> void:
	if player_id == sender_id:
		_display_emote(emote_text)

func _display_emote(emote_text: String) -> void:
	FloatingTextScript.spawn(get_parent(), global_position + Vector3(0.0, 2.2, 0.0), emote_text, Color(1.0, 0.9, 0.2))
	squash_current = Vector3(1.25, 0.75, 1.25)
	_play_sfx("play_score_ding")
	emote_triggered.emit(emote_text)

func _try_dash() -> void:
	if _is_game_paused() or is_dashing or is_stunned or is_slipping or dash_cooldown > 0.0:
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
			notification_displayed.emit("Naka-lock ang Dash! Mag-recycle ng basura para ma-unlock!", false)
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

	_play_sfx("play_dash")

	if is_local_human():
		add_shake(0.25)
		var main_node = get_node_or_null("/root/Main")
		if main_node and main_node.hud and main_node.hud.has_method("trigger_hit_flash"):
			main_node.hud.trigger_hit_flash(Color(0.2, 0.85, 1.0, 0.35), 0.2)

	FloatingTextScript.spawn(get_parent(), global_position + Vector3(0, 1.9, 0), "KIDLAT DASH!", Color(0.25, 0.9, 1.0))

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
			_play_sfx("play_pant")

		# Exit exhaustion check
		if endurance_stamina >= exhaustion_recovery_threshold:
			is_exhausted = false
			exhaust_pant_timer = 0.0
			_play_sfx("play_recover_breath")
			FloatingTextScript.spawn(get_parent(), global_position + Vector3(0, 2.0, 0), "NAKAHINGA NA!", Color(0.3, 1.0, 0.6))
			if is_local_human():
				notification_displayed.emit("Nakahinga na ulit! Pwede nang tumakbo!", true)
	else:
		if is_sprinting and is_moving:
			stats_sprint_time += delta
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
				_play_sfx("play_pant")
				FloatingTextScript.spawn(get_parent(), global_position + Vector3(0, 2.0, 0), "HINGAL! PAGOD NA...", Color(1.0, 0.35, 0.2))
				add_shake(0.35)
				if is_local_human():
					var main_node = get_node_or_null("/root/Main")
					if main_node and main_node.hud and main_node.hud.has_method("trigger_hit_flash"):
						main_node.hud.trigger_hit_flash(Color(0.8, 0.2, 0.2, 0.3), 0.35)
					notification_displayed.emit("HINGAL NA! Sobrang takbo, kailangan magpahinga!", false)
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
						_play_sfx("play_pant")
						FloatingTextScript.spawn(get_parent(), global_position + Vector3(0, 2.0, 0), "HINGAL! PAGOD NA...", Color(1.0, 0.35, 0.2))
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
	if is_aiming_throw:
		target_fov = base_fov - 10.0
	elif is_exhausted:
		target_fov = base_fov - 4.0
	elif is_dashing:
		target_fov = dash_fov
	elif is_sliding:
		target_fov = slide_fov
	elif is_sprinting and Vector2(velocity.x, velocity.z).length() > 8.0:
		target_fov = sprint_fov

	camera.fov = lerp(camera.fov, target_fov, delta * 8.0)

# Tag Targeting and Pointer system (active only when power reveal is triggered)
func _update_tag_targeting() -> void:
	if not tag_pointer or not camera:
		return

	if not tag_pointer.is_power_revealed:
		tag_pointer.update_pointer(camera, null, false, false)
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

func _update_mobile_tag_proximity() -> void:
	if not mobile_ui or not mobile_ui.has_method("set_tag_in_range"):
		return
	if current_role != Role.TAYA or is_eliminated:
		mobile_ui.set_tag_in_range(false)
		return
	var in_range := false
	var all_players = get_tree().get_nodes_in_group("players")
	for p in all_players:
		if p is PlayerController and p != self:
			if p.current_role == Role.RUNNER and not p.is_immune and not p.is_eliminated:
				if global_position.distance_to(p.global_position) <= TAG_REACH + 0.4:
					in_range = true
					break
	mobile_ui.set_tag_in_range(in_range)

# Point-blank line-of-sight nametag check (under 2.2m when looking directly at player)
func _update_name_tags_proximity() -> void:
	var all_players = get_tree().get_nodes_in_group("players")
	var cam_node: Node3D = (camera as Node3D) if camera else (self as Node3D)
	var cam_fwd: Vector3 = -cam_node.global_transform.basis.z

	var main_node = get_node_or_null("/root/Main")
	var is_lobby_state: bool = false
	if main_node and ("current_state" in main_node):
		var st: int = int(main_node.current_state)
		# TITLE=0, LOBBY=1, SOCIAL_LOBBY=5
		is_lobby_state = (st in [0, 1, 5])

	for p in all_players:
		if p is PlayerController and p != self:
			if not p.name_label:
				continue
			if p.is_hiding or p.is_eliminated:
				p.name_label.visible = false
				continue
			if p.power_reveal_timer > 0.0:
				p.name_label.visible = true
				continue

			var dist := global_position.distance_to(p.global_position)
			if is_lobby_state:
				p.name_label.visible = (dist <= 20.0)
			else:
				if dist <= 3.0:
					var to_p: Vector3 = (p.global_position - cam_node.global_position).normalized()
					var dot: float = cam_fwd.dot(to_p)
					p.name_label.visible = (dot > 0.2)
				else:
					p.name_label.visible = false

func _try_tag() -> void:
	if _is_game_paused() or is_stunned or is_slipping or tag_cooldown > 0.0:
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

	if target_to_tag:
		perform_tag_on(target_to_tag)
	else:
		var am = get_node_or_null("/root/AudioManager")
		if am and am.has_method("play_tag_swing"):
			am.play_tag_swing()
		# Check if Taya slapped a nearby hiding spot (Blue drum or Cardboard box)
		var hiding_spots = get_tree().get_nodes_in_group("hiding_spots")
		for spot in hiding_spots:
			if spot.has_method("on_taya_slap") and global_position.distance_to(spot.global_position) <= TAG_REACH:
				spot.call("on_taya_slap", self)
				return

func perform_tag_on(target_to_tag: PlayerController) -> void:
	if not target_to_tag or target_to_tag.is_immune or target_to_tag.is_eliminated:
		return

	if target_to_tag.has_method("is_sheltered_in_base") and target_to_tag.is_sheltered_in_base():
		if is_local_human():
			notification_displayed.emit("LIGTAS SA BASE! Bawal manghuli dito!", false)
			FloatingTextScript.spawn(get_parent(), target_to_tag.global_position + Vector3(0, 2.0, 0), "LIGTAS SA BASE!", Color(0.2, 0.95, 0.5))
			var am = get_node_or_null("/root/AudioManager")
			if am and am.has_method("play_whiff"):
				am.play_whiff()
		return

	# Forward lunge towards target on tag
	var lunge_dir := (target_to_tag.global_position - global_position).normalized()
	lunge_dir.y = 0.0
	velocity += lunge_dir * 5.5
	squash_current = Vector3(0.85, 0.85, 1.3)

	if is_local_human():
		var am = get_node_or_null("/root/AudioManager")
		if am:
			if am.has_method("play_tag_hit"):
				am.play_tag_hit()
			if am.has_method("play_score_ding"):
				am.play_score_ding()
		add_shake(0.4)
		trigger_hit_stop(55.0)
		var main_node = get_node_or_null("/root/Main")
		if main_node and ("hud" in main_node) and main_node.hud and main_node.hud.has_method("trigger_hit_flash"):
			main_node.hud.trigger_hit_flash(Color(1.0, 0.85, 0.2, 0.45), 0.22)
		trigger_device_vibration(80)

	# Spawn visual hit effect locally & popup score combat text
	spawn_hit_vfx(target_to_tag.global_position + Vector3(0, 1.2, 0))
	FloatingTextScript.spawn(get_parent(), target_to_tag.global_position + Vector3(0, 2.0, 0), "HULI! +1", Color(1.0, 0.88, 0.2))

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
	if is_vaulting:
		_process_vault(delta)
		return

	if snapshot_ring_buffer.size() < 2:
		# Fallback to standard exponential lerp if insufficient snapshot history
		global_position = global_position.lerp(target_position, delta * 18.0)
		if global_position.distance_to(target_position) < 0.05:
			remote_horizontal_speed = move_toward(remote_horizontal_speed, 0.0, delta * 20.0)
		if model:
			model.rotation.y = lerp_angle(model.rotation.y, target_rotation_y, delta * 18.0)
			if tag_area:
				tag_area.rotation.y = model.rotation.y
		return

	# Advance interpolation render timeline
	_interpolation_render_time_ms += delta * 1000.0

	var newest_time: float = float(snapshot_ring_buffer.back()["time_ms"])
	var oldest_time: float = float(snapshot_ring_buffer.front()["time_ms"])

	# Target render time sits INTERPOLATION_DELAY_MS behind the newest packet
	var target_render_time: float = newest_time - INTERPOLATION_DELAY_MS
	var lag: float = target_render_time - _interpolation_render_time_ms

	# Drift & lag compensation
	if abs(lag) > 150.0:
		_interpolation_render_time_ms = target_render_time
	elif abs(lag) > 20.0:
		_interpolation_render_time_ms += lag * (delta * 3.0)

	# Boundary checks
	if _interpolation_render_time_ms <= oldest_time:
		var s0: Dictionary = snapshot_ring_buffer[0]
		var s1: Dictionary = snapshot_ring_buffer[1]
		_apply_spline_sample(s0, s1, 0.0, delta)
		return
	elif _interpolation_render_time_ms >= newest_time:
		# Packet starvation: dead-reckoning extrapolation along velocity
		var last_snap: Dictionary = snapshot_ring_buffer.back()
		var extrap_sec: float = clamp((_interpolation_render_time_ms - newest_time) / 1000.0, 0.0, 0.15)
		var extrap_pos: Vector3 = last_snap["pos"] + (last_snap["vel"] * extrap_sec)
		global_position = global_position.lerp(extrap_pos, delta * 18.0)
		if model:
			model.rotation.y = lerp_angle(model.rotation.y, float(last_snap["rot_y"]), delta * 18.0)
			if tag_area:
				tag_area.rotation.y = model.rotation.y
		remote_horizontal_speed = move_toward(remote_horizontal_speed, 0.0, delta * 12.0)
		return

	# Search snapshot buffer for bracketing pair [S0, S1]
	for i in range(snapshot_ring_buffer.size() - 1):
		var t0: float = float(snapshot_ring_buffer[i]["time_ms"])
		var t1: float = float(snapshot_ring_buffer[i + 1]["time_ms"])
		if _interpolation_render_time_ms >= t0 and _interpolation_render_time_ms <= t1:
			var s0: Dictionary = snapshot_ring_buffer[i]
			var s1: Dictionary = snapshot_ring_buffer[i + 1]
			var span: float = t1 - t0
			var factor: float = clamp((_interpolation_render_time_ms - t0) / span, 0.0, 1.0) if span > 0.001 else 0.0
			_apply_spline_sample(s0, s1, factor, delta)
			return

	# Fallback if bracket search edge case occurs
	var fallback_snap: Dictionary = snapshot_ring_buffer.back()
	global_position = global_position.lerp(fallback_snap["pos"], delta * 18.0)
	if model:
		model.rotation.y = lerp_angle(model.rotation.y, float(fallback_snap["rot_y"]), delta * 18.0)
		if tag_area:
			tag_area.rotation.y = model.rotation.y

func _apply_spline_sample(s0: Dictionary, s1: Dictionary, s: float, _delta: float) -> void:
	var p0: Vector3 = s0["pos"]
	var p1: Vector3 = s1["pos"]
	var v0: Vector3 = s0["vel"]
	var v1: Vector3 = s1["vel"]
	var dt_sec: float = max(0.001, (float(s1["time_ms"]) - float(s0["time_ms"])) / 1000.0)

	# Velocity tangents scaled by interval duration
	var m0: Vector3 = v0 * dt_sec
	var m1: Vector3 = v1 * dt_sec

	# Cubic Hermite basis functions
	var s2: float = s * s
	var s3: float = s2 * s
	var h00: float = 2.0 * s3 - 3.0 * s2 + 1.0
	var h10: float = s3 - 2.0 * s2 + s
	var h01: float = -2.0 * s3 + 3.0 * s2
	var h11: float = s3 - s2

	var hermite_pos: Vector3 = (h00 * p0) + (h10 * m0) + (h01 * p1) + (h11 * m1)
	global_position = hermite_pos

	# Rotation and animation states
	var interp_rot: float = lerp_angle(float(s0["rot_y"]), float(s1["rot_y"]), s)
	if model:
		model.rotation.y = interp_rot
		if tag_area:
			tag_area.rotation.y = interp_rot

	remote_horizontal_speed = lerp(float(s0["speed"]), float(s1["speed"]), s)
	var active_snap: Dictionary = s1 if s >= 0.5 else s0
	remote_is_on_floor = active_snap["floor"]
	is_sliding = active_snap["slide"]
	is_dashing = active_snap["dash"]

func _push_snapshot(snapshot: Dictionary) -> void:
	# Teleport/Respawn detection: if position jumped > 10m, clear buffer and snap
	if snapshot_ring_buffer.size() > 0:
		var last_snap: Dictionary = snapshot_ring_buffer.back()
		if snapshot["pos"].distance_squared_to(last_snap["pos"]) > 100.0:
			snapshot_ring_buffer.clear()
			global_position = snapshot["pos"]
			_interpolation_initialized = false

	if snapshot_ring_buffer.is_empty():
		snapshot_ring_buffer.append(snapshot)
		_interpolation_render_time_ms = float(snapshot["time_ms"]) - INTERPOLATION_DELAY_MS
		_interpolation_initialized = true
		return

	var last_time: int = snapshot_ring_buffer.back()["time_ms"]
	if snapshot["time_ms"] > last_time:
		snapshot_ring_buffer.append(snapshot)
	else:
		# Chronological insertion for out-of-order packets
		var inserted: bool = false
		for i in range(snapshot_ring_buffer.size() - 1, -1, -1):
			if snapshot["time_ms"] > snapshot_ring_buffer[i]["time_ms"]:
				snapshot_ring_buffer.insert(i + 1, snapshot)
				inserted = true
				break
		if not inserted and (snapshot_ring_buffer[0]["time_ms"] - snapshot["time_ms"]) < 250:
			snapshot_ring_buffer.insert(0, snapshot)

	# Keep buffer within capacity
	while snapshot_ring_buffer.size() > SNAPSHOT_BUFFER_CAPACITY:
		snapshot_ring_buffer.pop_front()

func _process_network_sync_broadcasting(delta: float) -> void:
	var main_node = get_node_or_null("/root/Main")
	if not main_node or not is_instance_valid(main_node) or main_node.is_queued_for_deletion():
		main_node = null
		var p = get_parent()
		if p and p.get_parent() is GameManager and not p.get_parent().is_queued_for_deletion():
			main_node = p.get_parent()
		elif is_inside_tree() and get_tree().root:
			for c in get_tree().root.get_children():
				if c is GameManager and not c.is_queued_for_deletion():
					main_node = c
					break
	if main_node and "current_state" in main_node:
		var st: int = int(main_node.current_state)
		# TITLE=0 and 2D LOBBY=1 suppress 3D movement syncing.
		# SOCIAL_LOBBY=5, PLAYING=3, MAIBA_TAYA=2, GAME_OVER=4 actively broadcast.
		if st in [0, 1]:
			return

	_net_tick_timer += delta
	_heartbeat_timer += delta

	if _net_tick_timer < NETWORK_TICK_INTERVAL:
		return

	_net_tick_timer = fmod(_net_tick_timer, NETWORK_TICK_INTERVAL)
	_net_tick_counter = (_net_tick_counter + 1) % 1000000

	var rot_y: float = model.rotation.y if model else rotation.y
	var h_spd_sync: float = Vector2(velocity.x, velocity.z).length()
	var now_ms: int = Time.get_ticks_msec()

	# Delta suppression evaluation
	var pos_moved: bool = global_position.distance_squared_to(_last_sent_position) >= DELTA_SUPPRESSION_DIST_SQ
	var rot_diff: float = abs(wrapf(rot_y - _last_sent_rotation_y, -PI, PI))
	var rot_turned: bool = rot_diff >= DELTA_SUPPRESSION_ROT
	var vel_active: bool = velocity.length_squared() > 0.0025
	var state_changed: bool = (is_sliding != _last_sent_sliding or is_dashing != _last_sent_dashing or is_on_floor() != _last_sent_on_floor)
	var is_heartbeat: bool = _heartbeat_timer >= HEARTBEAT_INTERVAL

	# Suppress packet if stationary and heartbeat interval has not elapsed
	if not pos_moved and not rot_turned and not vel_active and not state_changed and not is_heartbeat:
		return

	# Update sent history
	_last_sent_position = global_position
	_last_sent_rotation_y = rot_y
	_last_sent_sliding = is_sliding
	_last_sent_dashing = is_dashing
	_last_sent_on_floor = is_on_floor()
	if is_heartbeat:
		_heartbeat_timer = 0.0

	if not multiplayer.has_multiplayer_peer():
		return

	# In client-server topology (ENet / WebRTC), clients send transforms directly to Host (peer 1)
	if not multiplayer.is_server():
		if multiplayer.get_peers().has(1):
			rpc_id(1, "sync_transform", global_position, velocity, rot_y, h_spd_sync, is_on_floor(), is_sliding, is_dashing, now_ms)
		return

	var connected_peers := multiplayer.get_peers()
	if connected_peers.is_empty():
		return

	# Host broadcasts with 3-tier distance and threat prioritization
	var all_players: Array[Node] = get_tree().get_nodes_in_group("players")
	var peer_nodes: Array[PlayerController] = []
	for p in all_players:
		if p is PlayerController and p != self and not p.is_bot:
			peer_nodes.append(p)

	if peer_nodes.is_empty():
		# Fallback broadcast when specific peer nodes are not resolved
		rpc("sync_transform", global_position, velocity, rot_y, h_spd_sync, is_on_floor(), is_sliding, is_dashing, now_ms)
		return

	for peer_p in peer_nodes:
		var target_id: int = peer_p.player_id
		if target_id <= 0 or not connected_peers.has(target_id):
			continue

		var dist: float = global_position.distance_to(peer_p.global_position)
		var is_threat: bool = (current_role == Role.TAYA or peer_p.current_role == Role.TAYA)

		var should_send: bool = false
		if is_threat or dist <= 20.0:
			# Tier 1 (Threat / Distance <= 20m): full 25Hz
			should_send = true
		elif dist <= 45.0:
			# Tier 2 (Mid-range 20m - 45m): 12.5Hz (every 2nd tick)
			should_send = (_net_tick_counter % 2 == 0)
		else:
			# Tier 3 (Far > 45m): 6.25Hz (every 4th tick)
			should_send = (_net_tick_counter % 4 == 0)

		if should_send or is_heartbeat:
			rpc_id(target_id, "sync_transform", global_position, velocity, rot_y, h_spd_sync, is_on_floor(), is_sliding, is_dashing, now_ms)

func reset_network_interpolation(new_pos: Vector3) -> void:
	global_position = new_pos
	target_position = new_pos
	target_velocity = Vector3.ZERO
	_last_sent_position = new_pos
	snapshot_ring_buffer.clear()
	_interpolation_initialized = false
	_interpolation_render_time_ms = 0.0
	if camera_mount and is_local_human() and not is_eliminated:
		camera_mount.global_position = new_pos + Vector3(0, 1.4, 0)

func _process_scoring(delta: float) -> void:
	var main_node = get_node_or_null("/root/Main")
	if main_node and "current_state" in main_node and main_node.current_state != 3:
		return
	if current_role == Role.RUNNER:
		survival_time += delta

@rpc("call_local", "reliable")
func play_tag_anim_rpc() -> void:
	if model:
		model.trigger_tag_animation()

@rpc("call_local", "reliable")
func play_slip_anim_rpc(duration: float = 1.4) -> void:
	if model and model.has_method("trigger_slip_animation"):
		model.trigger_slip_animation(duration)

@rpc("any_peer", "unreliable")
func sync_transform(
	pos: Vector3,
	vel: Vector3,
	rot_y: float,
	speed_val: float,
	floor_val: bool,
	remote_slide: bool,
	remote_dash: bool,
	timestamp_ms: int
) -> void:
	target_position = pos
	target_velocity = vel
	target_rotation_y = rot_y
	remote_horizontal_speed = speed_val
	remote_is_on_floor = floor_val
	is_sliding = remote_slide
	is_dashing = remote_dash

	var recv_time: int = Time.get_ticks_msec()
	if timestamp_ms <= 0:
		timestamp_ms = recv_time

	var snapshot: Dictionary = {
		"pos": pos,
		"vel": vel,
		"rot_y": rot_y,
		"speed": speed_val,
		"floor": floor_val,
		"slide": remote_slide,
		"dash": remote_dash,
		"time_ms": timestamp_ms,
		"recv_time_ms": recv_time
	}
	_push_snapshot(snapshot)

	# Authoritative server relay: forward remote client's transform to all other peers
	if multiplayer.has_multiplayer_peer() and multiplayer.is_server():
		var sender_id := multiplayer.get_remote_sender_id()
		if sender_id > 1:
			for other_peer in multiplayer.get_peers():
				if other_peer != sender_id:
					rpc_id(other_peer, "sync_transform", pos, vel, rot_y, speed_val, floor_val, remote_slide, remote_dash, timestamp_ms)

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
		if target_node.has_method("is_sheltered_in_base") and target_node.is_sheltered_in_base():
			return
		var dist: float = chaser_node.global_position.distance_to(target_node.global_position)
		if dist <= (TAG_REACH + 1.8) and not target_node.is_immune and target_node.current_role == Role.RUNNER:
			chaser_node.tag_count += 1
			chaser_node.stats_tags += 1
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
	_play_sfx("play_tag_boom")

	squash_current = Vector3(1.3, 0.7, 1.3)

	if is_local_human():
		add_shake(0.7)
		trigger_hit_stop(65.0)
		var main_node = get_node_or_null("/root/Main")
		if main_node and main_node.hud and main_node.hud.has_method("trigger_hit_flash"):
			main_node.hud.trigger_hit_flash(Color(1.0, 0.15, 0.15, 0.55), 0.28)
		trigger_device_vibration(150)

	FloatingTextScript.spawn(get_parent(), global_position + Vector3(0, 2.0, 0), "NA-TAYA!", Color(1.0, 0.25, 0.25))

	set_role_rpc(Role.TAYA)
	grant_immunity_rpc(immunity_time)
	if multiplayer.has_multiplayer_peer():
		rpc("set_role_rpc", Role.TAYA)
		rpc("grant_immunity_rpc", immunity_time)

@rpc("any_peer", "call_local", "reliable")
func set_role_rpc(new_role: int) -> void:
	if multiplayer.has_multiplayer_peer() and not multiplayer.is_server():
		var sender := multiplayer.get_remote_sender_id()
		if sender != 1:
			push_warning("Unauthorized role change attempt rejected from peer %d" % sender)
			return
	current_role = new_role as Role
	_update_role_state()
	role_changed.emit(current_role)

@rpc("any_peer", "call_local", "reliable")
func grant_immunity_rpc(duration: float) -> void:
	if multiplayer.has_multiplayer_peer() and not multiplayer.is_server():
		var sender := multiplayer.get_remote_sender_id()
		if sender != 1:
			push_warning("Unauthorized grant_immunity attempt rejected from peer %d" % sender)
			return
	is_immune = true
	current_immunity_timer = duration

func _update_role_state() -> void:
	if model:
		model.is_taya = (current_role == Role.TAYA)
	if mobile_ui:
		mobile_ui.set_tag_button_highlight(current_role == Role.TAYA)
	if name_label:
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
	stats_recycled += 1
	held_trash = -1
	held_trash_name = ""
	held_trash_category = 0

	_update_held_item_visuals()

	# Award score via GameManager
	var gm = get_node_or_null("/root/Main")
	if gm and gm.has_method("award_recycle_points"):
		gm.award_recycle_points(player_id, 30)

	_play_sfx("play_score_ding")

	FloatingTextScript.spawn(get_parent(), global_position + Vector3(0, 2.0, 0), "+30 SCORE!", Color(0.2, 1.0, 0.45))

	# Grant random powerup!
	grant_random_powerup()

	# Bonus Kalye Street Item reward upon segregating trash!
	if held_street_item == -1:
		var bonus_item: int = 0 if (randf() < 0.6) else 1
		pickup_street_item(bonus_item, "Spartan Tsinelas" if bonus_item == 0 else "Balat ng Saging")

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

	_play_sfx("play_powerup")

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
			notification_displayed.emit("Naglaho na ang kapangyarihan!", false)

	if multiplayer.has_multiplayer_peer():
		rpc("sync_powerup_state", 0)

@rpc("any_peer", "call_local", "reliable")
func sync_powerup_state(p_type: int) -> void:
	if multiplayer.has_multiplayer_peer() and not multiplayer.is_server():
		var sender := multiplayer.get_remote_sender_id()
		if sender != 1 and sender != get_multiplayer_authority():
			push_warning("Unauthorized powerup sync rejected from peer %d" % sender)
			return
	active_powerup = p_type as PowerupType
	_update_powerup_visuals()

func get_powerup_name() -> String:
	match active_powerup:
		PowerupType.DASH:
			return "KIDLAT DASH (3x)"
		PowerupType.SUPER_SPEED:
			return "SUPER SPEED (Bilis-Alon)"
		PowerupType.DOUBLE_JUMP:
			return "DOUBLE JUMP (Luksong-Tinik)"
		PowerupType.WATER_RUN:
			return "WATER RUN (Lundag-Baha)"
		PowerupType.WALL_RUN:
			return "WALL RUN (Akyat-Pader)"
	return "WALA"

func set_in_water(in_water: bool) -> void:
	is_in_water = in_water
	if is_in_water and active_powerup == PowerupType.WATER_RUN:
		if is_local_human():
			notification_displayed.emit("WATER RUN! Tumatakbo sa ibabaw ng baha!", true)

func enter_safe_base() -> void:
	is_in_base = true
	if is_local_human() and current_role == Role.RUNNER:
		if base_shelter_timer > 0.0:
			notification_displayed.emit("LIGTAS SA BASE! (Protektado sa Taya)", true)
		else:
			notification_displayed.emit("UBOS NA ANG LIGTAS TIME! Kailangan lumabas muna!", false)

func exit_safe_base() -> void:
	is_in_base = false
	base_cooldown_timer = 5.0
	if is_local_human() and current_role == Role.RUNNER:
		notification_displayed.emit("Lumabas sa Base! Mag-ingat sa mga Taya!", false)

func is_sheltered_in_base() -> bool:
	return is_in_base and base_shelter_timer > 0.0 and current_role == Role.RUNNER

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
	if _is_game_paused():
		return
	if is_hiding:
		exit_hiding_spot()
		return

	# Check hiding spots in proximity
	var hiding_spots = get_tree().get_nodes_in_group("hiding_spots")
	for spot in hiding_spots:
		if spot.has_method("interact") and global_position.distance_to(spot.global_position) <= 2.2:
			spot.call("interact", self)
			return

	_update_interactable_target()
	if not is_instance_valid(current_interactable):
		return
	if current_interactable is TrashItem:
		current_interactable.interact(self)
	elif current_interactable is RecyclingBin:
		current_interactable.interact(self)
	elif current_interactable.has_method("interact"):
		current_interactable.interact(self)

func drop_trash() -> void:
	if _is_game_paused() or not has_trash():
		return
	var _dropped_type := held_trash
	held_trash = -1
	held_trash_name = ""
	held_trash_category = 0
	_update_held_item_visuals()

	_play_sfx("play_drop")

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
		var icon: String = ""
		var action: String = "INTERACT"
		if current_interactable is TrashItem:
			icon = current_interactable.get_item_icon()
			action = "PULUTIN"
		elif current_interactable is RecyclingBin:
			icon = "[BIN]"
			action = "IPASOK" if has_trash() else "BASURAHAN"
		elif current_interactable.has_method("get_interaction_action"):
			action = current_interactable.get_interaction_action()
			icon = current_interactable.get_interaction_icon() if current_interactable.has_method("get_interaction_icon") else "★"
		interactable_changed.emit(true, icon, action)
		if mobile_ui and mobile_ui.has_method("set_interact_prompt"):
			mobile_ui.set_interact_prompt(true, icon, action)
	else:
		interactable_changed.emit(false, "", "")
		if mobile_ui and mobile_ui.has_method("set_interact_prompt"):
			mobile_ui.set_interact_prompt(false, "", "")

func _check_danger_proximity() -> void:
	if current_role != Role.RUNNER or power_reveal_timer <= 0.0:
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
			_play_sfx("play_danger")
	else:
		danger_detected.emit(false, 0.0)

# ==============================================================================
# STREET ITEMS, COUNTERPLAY & HIDING MECHANICS
# ==============================================================================

func can_pickup_street_item(i_type: int) -> bool:
	if is_eliminated or is_hiding:
		return false
	if held_street_item != -1 and held_street_item != i_type:
		return false
	if held_street_item == i_type and held_street_item_count >= 2:
		return false
	return true

func pickup_street_item(i_type: int, i_name: String) -> void:
	if held_street_item == i_type:
		held_street_item_count = min(2, held_street_item_count + 1)
	else:
		held_street_item = i_type
		held_street_item_name = i_name
		held_street_item_count = 1

	if is_local_human():
		street_item_changed.emit(held_street_item, held_street_item_name, held_street_item_count)
		if mobile_ui and mobile_ui.has_method("set_item_button_visible"):
			mobile_ui.set_item_button_visible(true, i_name.substr(0, 7))
		notification_displayed.emit("Nakuha: %s! [Right-Click / G para gamitin]" % i_name, true)

func _on_item_input_pressed() -> void:
	if _is_game_paused() or is_eliminated or is_stunned or is_slipping or is_hiding:
		return
	if held_street_item == -1 or held_street_item_count <= 0:
		return

	# If throwable item (Tsinelas or Chalk Bag), enter Aiming Mode
	if held_street_item == 0 or held_street_item == 3:
		is_aiming_throw = true
		_update_throw_aim_trajectory()
	else:
		# Immediate use for non-throwables (Banana, Whistle, Ice Candy)
		use_current_item()

func _on_item_input_released() -> void:
	if is_aiming_throw:
		_cancel_throw_aim()
		use_current_item()

func _cancel_throw_aim() -> void:
	is_aiming_throw = false
	if trajectory_preview:
		trajectory_preview.hide_preview()
	var main_node = _get_main_node()
	if main_node and main_node.hud and main_node.hud.has_method("set_aiming_mode"):
		main_node.hud.set_aiming_mode(false, false)

func _update_throw_aim_trajectory() -> void:
	if not trajectory_preview:
		return
	if (held_street_item != 0 and held_street_item != 3) or is_stunned or is_slipping or is_eliminated or is_hiding:
		_cancel_throw_aim()
		return

	var shoulder_offset := global_transform.basis * Vector3(0.35, 1.25, -0.2)
	var start_pos := global_position + shoulder_offset

	var aim_target: Vector3
	var is_locked: bool = false
	if camera:
		var space_state := get_world_3d().direct_space_state
		var cam_pos := camera.global_position
		var cam_forward := -camera.global_transform.basis.z
		var ray_end := cam_pos + cam_forward * 50.0
		var query := PhysicsRayQueryParameters3D.create(cam_pos, ray_end)
		query.exclude = [get_rid()]
		query.collision_mask = 1 | 2 # Environment & Players
		var hit := space_state.intersect_ray(query)
		if hit:
			aim_target = hit.position
			var hit_col = hit.get("collider")
			if hit_col and hit_col != self and (hit_col is PlayerController or (hit_col is Node and hit_col.is_in_group("players"))):
				is_locked = true
		else:
			aim_target = ray_end
	else:
		aim_target = global_position - global_transform.basis.z * 20.0 + Vector3(0, 1.2, 0)

	var dir := (aim_target - start_pos).normalized()
	var throw_speed: float = 24.0
	var throw_gravity: float = -9.0
	var initial_vel: Vector3 = dir * throw_speed + Vector3(0, 1.5, 0)

	var exclude_rids: Array[RID] = [get_rid()]
	var traj_info: Dictionary = trajectory_preview.update_trajectory(
		start_pos,
		initial_vel,
		throw_gravity,
		get_world_3d().direct_space_state,
		exclude_rids
	)

	var locked_status: bool = is_locked or traj_info.get("is_locked", false)
	var main_node = _get_main_node()
	if main_node and main_node.hud and main_node.hud.has_method("set_aiming_mode"):
		main_node.hud.set_aiming_mode(true, locked_status)

func use_current_item() -> void:
	if is_aiming_throw:
		_cancel_throw_aim()
	if _is_game_paused() or is_eliminated or is_stunned or is_slipping or is_hiding:
		return
	if held_street_item == -1 or held_street_item_count <= 0:
		return

	var used_type := held_street_item
	held_street_item_count -= 1
	if held_street_item_count <= 0:
		held_street_item = -1
		held_street_item_name = ""

	if is_local_human():
		street_item_changed.emit(held_street_item, held_street_item_name, held_street_item_count)
		if mobile_ui and mobile_ui.has_method("set_item_button_visible"):
			mobile_ui.set_item_button_visible(held_street_item != -1, held_street_item_name.substr(0, 7) if held_street_item != -1 else "BATO")

	match used_type:
		0: # TSINELAS (Spartan Flying Slipper)
			_throw_tsinelas()
		1: # SAGING (Banana Peel Trap)
			_drop_banana()
		2: # WHISTLE (Barangay Whistle Radar)
			_blow_whistle()
		3: # CHALK_BAG (Chalk Dust Bag)
			_throw_chalk_bag()
		4: # ICE_CANDY (Pampalakas)
			_consume_ice_candy()

	if multiplayer.has_multiplayer_peer() and is_local_controlled():
		rpc("sync_use_item_rpc", used_type)

@rpc("any_peer", "call_local", "reliable")
func sync_use_item_rpc(used_type: int) -> void:
	if not is_local_controlled():
		match used_type:
			0: _throw_tsinelas()
			1: _drop_banana()
			2: _blow_whistle()
			3: _throw_chalk_bag()
			4: _consume_ice_candy()

func _throw_tsinelas() -> void:
	var proj_scene: PackedScene = load("res://scenes/gameplay/ThrownProjectile.tscn")
	if not proj_scene:
		return

	var aim_target: Vector3
	if camera:
		var space_state := get_world_3d().direct_space_state
		var cam_pos := camera.global_position
		var cam_forward := -camera.global_transform.basis.z
		var ray_end := cam_pos + cam_forward * 50.0
		var query := PhysicsRayQueryParameters3D.create(cam_pos, ray_end)
		query.exclude = [get_rid()]
		query.collision_mask = 1 | 2 # Environment & Players
		var hit := space_state.intersect_ray(query)
		if hit:
			aim_target = hit.position
		else:
			aim_target = ray_end
	else:
		aim_target = global_position - global_transform.basis.z * 20.0 + Vector3(0, 1.2, 0)

	var shoulder_offset := global_transform.basis * Vector3(0.35, 1.25, -0.2)
	var start_pos := global_position + shoulder_offset
	var dir := (aim_target - start_pos).normalized()

	var proj: ThrownProjectile = proj_scene.instantiate() as ThrownProjectile
	get_parent().add_child(proj)
	proj.setup(ThrownProjectile.ProjectileType.TSINELAS, start_pos, dir, player_id, player_name)

	_play_sfx("play_tsinelas_throw")

	FloatingTextScript.spawn(get_parent(), global_position + Vector3(0, 2.0, 0), "BATO TSINELAS!", Color(0.3, 0.85, 1.0))

func _drop_banana() -> void:
	var trap_scene: PackedScene = load("res://scenes/gameplay/BananaTrap.tscn")
	if not trap_scene:
		return

	var drop_pos := global_position - global_transform.basis.z * 1.2
	var trap: BananaTrap = trap_scene.instantiate() as BananaTrap
	get_parent().add_child(trap)
	trap.setup(player_id, player_name, drop_pos)

	FloatingTextScript.spawn(get_parent(), global_position + Vector3(0, 2.0, 0), "BALAT NG SAGING!", Color(1.0, 0.9, 0.2))

func _blow_whistle() -> void:
	_play_sfx("play_whistle")

	FloatingTextScript.spawn(get_parent(), global_position + Vector3(0, 2.2, 0), "SIPOL! TAGO NA!", Color(1.0, 0.35, 0.35))
	add_shake(0.35)

	if tag_pointer:
		tag_pointer.trigger_power_reveal(3.5)

	# Reveal all other active players for 3.5s
	for p in get_tree().get_nodes_in_group("players"):
		if p is PlayerController and p != self and not p.is_eliminated:
			if p.is_hiding:
				p.exit_hiding_spot()
			p.power_reveal_timer = 3.5
			if p.name_label:
				p.name_label.visible = true
			FloatingTextScript.spawn(get_parent(), p.global_position + Vector3(0, 2.0, 0), "AY TAYA!", Color(1.0, 0.8, 0.2))
			p.squash_current = Vector3(0.85, 1.25, 0.85)

func _throw_chalk_bag() -> void:
	var proj_scene: PackedScene = load("res://scenes/gameplay/ThrownProjectile.tscn")
	if not proj_scene:
		return

	var aim_target: Vector3
	if camera:
		var space_state := get_world_3d().direct_space_state
		var cam_pos := camera.global_position
		var cam_forward := -camera.global_transform.basis.z
		var ray_end := cam_pos + cam_forward * 50.0
		var query := PhysicsRayQueryParameters3D.create(cam_pos, ray_end)
		query.exclude = [get_rid()]
		query.collision_mask = 1 | 2 # Environment & Players
		var hit := space_state.intersect_ray(query)
		if hit:
			aim_target = hit.position
		else:
			aim_target = ray_end
	else:
		aim_target = global_position - global_transform.basis.z * 20.0 + Vector3(0, 1.2, 0)

	var shoulder_offset := global_transform.basis * Vector3(0.35, 1.25, -0.2)
	var start_pos := global_position + shoulder_offset
	var dir := (aim_target - start_pos).normalized()

	var proj: ThrownProjectile = proj_scene.instantiate() as ThrownProjectile
	get_parent().add_child(proj)
	proj.setup(ThrownProjectile.ProjectileType.CHALK_BAG, start_pos, dir, player_id, player_name)

	FloatingTextScript.spawn(get_parent(), global_position + Vector3(0, 2.0, 0), "CHALK DUST!", Color(0.95, 0.95, 1.0))

func _consume_ice_candy() -> void:
	burst_stamina = burst_stamina_max
	endurance_stamina = endurance_stamina_max
	is_exhausted = false

	# Temporary adrenaline surge
	set_powerup(PowerupType.SUPER_SPEED, 3.5)

	_play_sfx("play_ice_candy")

	FloatingTextScript.spawn(get_parent(), global_position + Vector3(0, 2.0, 0), "ICE CANDY RUSH!", Color(1.0, 0.45, 0.8))

func apply_slipper_stun(duration: float, attacker_name: String) -> void:
	if is_immune or is_eliminated:
		return
	if is_aiming_throw:
		_cancel_throw_aim()
	is_stunned = true
	stun_timer = max(stun_timer, duration)
	velocity = velocity * 0.15
	squash_current = Vector3(1.3, 0.4, 1.3)
	_play_sfx("play_stun")
	add_shake(0.4)
	if model and model.has_method("trigger_slip_animation"):
		model.trigger_slip_animation(duration)
	if is_inside_tree() and multiplayer and multiplayer.has_multiplayer_peer():
		rpc("play_slip_anim_rpc", duration)
	if is_local_human():
		notification_displayed.emit("SAPUL NG TSINELAS ni %s!" % attacker_name, false)

func apply_banana_slip(planter_name: String) -> void:
	if is_eliminated:
		return
	if is_aiming_throw:
		_cancel_throw_aim()
	stats_slips += 1
	is_slipping = true
	slip_timer = 1.4
	velocity.x = 0.0
	velocity.y = 0.0
	velocity.z = 0.0
	slip_velocity = Vector3.ZERO
	squash_current = Vector3(1.2, 0.65, 1.2)
	add_shake(0.25)
	if model and model.has_method("trigger_slip_animation"):
		model.trigger_slip_animation(1.4)
	if is_inside_tree() and multiplayer and multiplayer.has_multiplayer_peer():
		rpc("play_slip_anim_rpc", 1.4)
	if is_local_human():
		trigger_device_vibration(180)
		notification_displayed.emit("NANDULAS SA SAGING ni %s!" % planter_name, false)

func apply_chalk_blind(duration: float) -> void:
	chalk_blind_timer = duration
	if is_local_human():
		notification_displayed.emit("NAPULING SA CHALK DUST!", false)
		var main_node = get_node_or_null("/root/Main")
		if main_node and main_node.hud and main_node.hud.has_method("trigger_hit_flash"):
			main_node.hud.trigger_hit_flash(Color(0.9, 0.9, 0.95, 0.6), duration * 0.4)

func enter_hiding_spot(spot: Node3D) -> void:
	is_hiding = true
	current_hiding_spot = spot
	if model:
		model.visible = false
	if name_label:
		name_label.visible = false
	if is_local_human():
		hiding_state_changed.emit(true, 8.0)
		var is_box: bool = is_instance_valid(spot) and ("spot_type" in spot) and spot.spot_type == 1
		var msg: String = "Nagtatago sa karton... Tahimik lang!" if is_box else "Nagtatago sa drum... Tahimik lang!"
		notification_displayed.emit(msg, true)

func exit_hiding_spot() -> void:
	if not is_hiding:
		return

	if multiplayer.has_multiplayer_peer() and not multiplayer.is_server():
		if is_instance_valid(current_hiding_spot) and current_hiding_spot.has_method("request_eject"):
			current_hiding_spot.call("request_eject", player_id)
			return

	is_hiding = false
	if is_instance_valid(current_hiding_spot) and current_hiding_spot.has_method("eject_occupant"):
		if current_hiding_spot.get("occupant") == self:
			current_hiding_spot.call("eject_occupant", false)
	current_hiding_spot = null
	if model:
		model.visible = not is_eliminated
	if name_label:
		name_label.visible = not is_eliminated
	if is_local_human():
		hiding_state_changed.emit(false, 0.0)
