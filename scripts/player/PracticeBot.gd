class_name PracticeBot
extends PlayerController

var ai_wander_target: Vector3 = Vector3.ZERO
var ai_repath_timer: float = 0.0
var ai_jump_timer: float = 0.0

func _init() -> void:
	is_bot = true

func _ready() -> void:
	super._ready()
	# Bots are locally controlled by the server / single player practice
	set_multiplayer_authority(1)
	player_name = "Bata (Bot)"
	if name_label:
		name_label.text = player_name
	_pick_new_wander_target()

func _physics_process(delta: float) -> void:
	if is_eliminated:
		velocity = Vector3.ZERO
		return

	# Run base timers and immunity
	_update_timers(delta)
	ai_repath_timer -= delta
	ai_jump_timer -= delta

	if current_role == Role.RUNNER:
		_process_runner_ai(delta)
		_process_scoring(delta)
	else:
		_process_chaser_ai(delta)

	var is_moving := (velocity.length() > 0.2)
	_process_stamina(delta, is_moving)

	# Update visual animations & squash deformation
	var horizontal_speed: float = Vector2(velocity.x, velocity.z).length()
	var current_max: float = sprint_speed if is_sprinting else walk_speed
	if model:
		squash_current = squash_current.lerp(squash_target, delta * 15.0)
		squash_target = squash_target.lerp(Vector3.ONE, delta * 8.0)
		model.scale = model_base_scale * squash_current
		model.is_sliding = is_sliding
		model.is_dashing = is_dashing
		model.has_superspeed = false
		model.animate(delta, horizontal_speed, is_on_floor(), current_max)

func _process_runner_ai(delta: float) -> void:
	# Find nearest Taya to flee from
	var nearest_taya: PlayerController = null
	var min_dist: float = 999.0

	for p in get_tree().get_nodes_in_group("players"):
		if p is PlayerController and p != self and p.current_role == Role.TAYA and not p.is_eliminated:
			var d := global_position.distance_to(p.global_position)
			if d < min_dist:
				min_dist = d
				nearest_taya = p

	var move_dir := Vector3.ZERO

	if nearest_taya and min_dist < 16.0:
		# Flee away from Taya!
		move_dir = (global_position - nearest_taya.global_position).normalized()
		move_dir.y = 0.0
		is_sprinting = (min_dist < 8.0)
		# Dodge jump or slide if close
		if min_dist < 5.0 and ai_jump_timer <= 0.0 and is_on_floor():
			_execute_jump()
			ai_jump_timer = randf_range(1.5, 3.0)
	else:
		# Wander around map
		if ai_repath_timer <= 0.0 or global_position.distance_to(ai_wander_target) < 2.0:
			_pick_new_wander_target()
		move_dir = (ai_wander_target - global_position).normalized()
		move_dir.y = 0.0
		is_sprinting = false

	_apply_bot_movement(move_dir, delta)

func _process_chaser_ai(delta: float) -> void:
	# Find nearest Runner to hunt down
	var nearest_runner: PlayerController = null
	var min_dist: float = 999.0

	for p in get_tree().get_nodes_in_group("players"):
		if p is PlayerController and p != self and p.current_role == Role.RUNNER and not p.is_immune and not p.is_eliminated:
			var d := global_position.distance_to(p.global_position)
			if d < min_dist:
				min_dist = d
				nearest_runner = p

	var move_dir := Vector3.ZERO

	if nearest_runner:
		move_dir = (nearest_runner.global_position - global_position).normalized()
		move_dir.y = 0.0
		is_sprinting = true

		# Attempt tag if within reach
		if min_dist <= TAG_REACH and tag_cooldown <= 0.0:
			_try_tag()
		elif min_dist <= (TAG_REACH + 3.0) and not is_dashing and dash_cooldown <= 0.0:
			_try_dash()
	else:
		if ai_repath_timer <= 0.0:
			_pick_new_wander_target()
		move_dir = (ai_wander_target - global_position).normalized()
		move_dir.y = 0.0
		is_sprinting = false

	_apply_bot_movement(move_dir, delta)

func _apply_bot_movement(move_dir: Vector3, delta: float) -> void:
	# Gravity
	if not is_on_floor():
		velocity.y += fall_gravity * delta

	var target_spd: float = walk_speed
	if is_exhausted:
		target_spd = exhausted_speed
	elif is_sprinting and burst_stamina > 0.0:
		target_spd = sprint_speed
	else:
		is_sprinting = false

	if current_role == Role.TAYA:
		target_spd *= 1.05

	if move_dir.length() > 0.1:
		velocity.x = move_toward(velocity.x, move_dir.x * target_spd, acceleration * delta)
		velocity.z = move_toward(velocity.z, move_dir.z * target_spd, acceleration * delta)
		if model:
			var target_facing := atan2(-move_dir.x, -move_dir.z)
			model.rotation.y = lerp_angle(model.rotation.y, target_facing, rotation_speed * delta)
			if tag_area:
				tag_area.rotation.y = model.rotation.y
	else:
		velocity.x = move_toward(velocity.x, 0.0, friction * delta)
		velocity.z = move_toward(velocity.z, 0.0, friction * delta)

	move_and_slide()

func _pick_new_wander_target() -> void:
	ai_repath_timer = randf_range(3.0, 6.0)
	var map := get_node_or_null("/root/Main/KalyeMap")
	if map and map.has_node("SpawnPoints"):
		var sps := map.get_node("SpawnPoints").get_children()
		if sps.size() > 0:
			ai_wander_target = sps.pick_random().global_position
			return
	ai_wander_target = Vector3(randf_range(-42, 42), 0.5, randf_range(-42, 42))
