class_name PracticeBot
extends PlayerController

var ai_wander_target: Vector3 = Vector3.ZERO
var ai_repath_timer: float = 0.0
var ai_jump_timer: float = 0.0
var ai_item_use_timer: float = 0.0
var ai_banter_timer: float = 0.0

const RUNNER_BANTER := ["WAG AKO!", "HABOL!", "BILIS MO!", "DI MO KO MAABUTAN!", "AY TAYA!"]
const TAYA_BANTER := ["DITO KAYO!", "WALA NANG MAKATATAKBO!", "SAPUL KA SAKIN!", "TAGO PA!"]

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
	ai_item_use_timer = randf_range(1.0, 3.0)
	ai_banter_timer = randf_range(5.0, 12.0)

func _physics_process(delta: float) -> void:
	if is_eliminated:
		velocity = Vector3.ZERO
		return

	# Run base timers and immunity
	_update_timers(delta)
	ai_repath_timer -= delta
	ai_jump_timer -= delta
	ai_item_use_timer -= delta
	ai_banter_timer -= delta

	# Check hiding state
	if is_hiding:
		stats_hiding_time += delta
		velocity = Vector3.ZERO
		if model: model.visible = false
		if name_label: name_label.visible = false
		if is_instance_valid(current_hiding_spot) and current_hiding_spot.get("hide_timer") > randf_range(3.5, 6.5):
			exit_hiding_spot()
		return

	# Check slip state
	if is_slipping:
		velocity.x = slip_velocity.x
		velocity.z = slip_velocity.z
		if not is_on_floor():
			velocity.y += fall_gravity * delta
		move_and_slide()
		if model:
			squash_current = squash_current.lerp(Vector3(1.35, 0.4, 1.35), delta * 12.0)
			model.scale = model_base_scale * squash_current
		return

	# Stun state
	if is_stunned:
		velocity.x = move_toward(velocity.x, 0.0, friction * delta)
		velocity.z = move_toward(velocity.z, 0.0, friction * delta)
		move_and_slide()
		return

	if current_role == Role.RUNNER:
		_process_runner_ai(delta)
		_process_scoring(delta)
	else:
		_process_chaser_ai(delta)

	# Banter
	if ai_banter_timer <= 0.0:
		ai_banter_timer = randf_range(8.0, 18.0)
		_trigger_bot_banter()

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

func _trigger_bot_banter() -> void:
	var pool := TAYA_BANTER if (current_role == Role.TAYA) else RUNNER_BANTER
	var phrase: String = pool.pick_random()
	var col := Color(1.0, 0.4, 0.4) if (current_role == Role.TAYA) else Color(0.4, 0.9, 1.0)
	FloatingTextScript.spawn(get_parent(), global_position + Vector3(0, 2.2, 0), phrase, col)

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

	if nearest_taya and min_dist < 18.0:
		# Flee away from Taya!
		move_dir = (global_position - nearest_taya.global_position).normalized()
		move_dir.y = 0.0
		is_sprinting = (min_dist < 9.0)

		# Tactical item usage when chased
		if ai_item_use_timer <= 0.0 and held_street_item != -1:
			if held_street_item == 0 and min_dist < 8.0: # Tsinelas fling
				use_current_item()
				ai_item_use_timer = randf_range(2.0, 4.0)
			elif held_street_item == 1 and min_dist < 6.0: # Banana peel drop
				use_current_item()
				ai_item_use_timer = randf_range(2.0, 4.0)

		# Check if can hide in nearby drum when cornered
		if min_dist < 7.0:
			var hiding_spots = get_tree().get_nodes_in_group("hiding_spots")
			for spot in hiding_spots:
				if spot is HidingSpot and not spot.is_occupied:
					if global_position.distance_to(spot.global_position) < 3.2:
						spot.interact(self)
						return

		# Dodge jump or slide if close
		if min_dist < 5.0 and ai_jump_timer <= 0.0 and is_on_floor():
			_execute_jump()
			ai_jump_timer = randf_range(1.5, 3.0)
	else:
		# Search for street items or trash if inventory has space
		var target_pos := ai_wander_target
		if held_street_item == -1:
			var nearest_item := _find_nearest_street_item()
			if nearest_item:
				target_pos = nearest_item.global_position

		if ai_repath_timer <= 0.0 or global_position.distance_to(target_pos) < 2.0:
			_pick_new_wander_target()
		move_dir = (target_pos - global_position).normalized()
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

	# Check suspicious / occupied hiding spots
	var checked_spot: HidingSpot = null
	var hiding_spots = get_tree().get_nodes_in_group("hiding_spots")
	for spot in hiding_spots:
		if spot is HidingSpot and global_position.distance_to(spot.global_position) <= (TAG_REACH + 0.5):
			if spot.is_occupied or spot.wobble_intensity > 0.0:
				checked_spot = spot
				break

	if checked_spot and tag_cooldown <= 0.0:
		_try_tag()
		return

	if nearest_runner:
		move_dir = (nearest_runner.global_position - global_position).normalized()
		move_dir.y = 0.0
		is_sprinting = true

		# Use chaser items
		if ai_item_use_timer <= 0.0 and held_street_item != -1:
			if held_street_item == 2 and min_dist > 10.0: # Whistle
				use_current_item()
				ai_item_use_timer = 5.0
			elif held_street_item == 3 and min_dist < 9.0: # Chalk bag
				use_current_item()
				ai_item_use_timer = 4.0
			elif held_street_item == 4 and is_exhausted: # Ice Candy
				use_current_item()
				ai_item_use_timer = 4.0

		# Attempt tag if within reach
		if min_dist <= TAG_REACH and tag_cooldown <= 0.0:
			_try_tag()
		elif min_dist <= (TAG_REACH + 3.0) and not is_dashing and dash_cooldown <= 0.0:
			_try_dash()
	else:
		# If no runners in sight, use whistle if holding one
		if held_street_item == 2 and ai_item_use_timer <= 0.0:
			use_current_item()
			ai_item_use_timer = 6.0

		# Seek street item if empty
		var target_pos := ai_wander_target
		if held_street_item == -1:
			var nearest_item := _find_nearest_street_item()
			if nearest_item:
				target_pos = nearest_item.global_position

		if ai_repath_timer <= 0.0 or global_position.distance_to(target_pos) < 2.0:
			_pick_new_wander_target()
		move_dir = (target_pos - global_position).normalized()
		move_dir.y = 0.0
		is_sprinting = false

	_apply_bot_movement(move_dir, delta)

func _find_nearest_street_item() -> StreetItem:
	var items = get_tree().get_nodes_in_group("street_items")
	var best: StreetItem = null
	var min_d: float = 18.0
	for item in items:
		if item is StreetItem and not item.is_collected:
			var is_taya: bool = (current_role == Role.TAYA)
			var is_for_taya: bool = (item.item_type in [StreetItem.ItemType.WHISTLE, StreetItem.ItemType.CHALK_BAG, StreetItem.ItemType.ICE_CANDY])
			var is_for_runner: bool = (item.item_type in [StreetItem.ItemType.TSINELAS, StreetItem.ItemType.SAGING])
			if (is_taya and is_for_taya) or (not is_taya and is_for_runner):
				var d := global_position.distance_to(item.global_position)
				if d < min_d:
					min_d = d
					best = item
	return best

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
