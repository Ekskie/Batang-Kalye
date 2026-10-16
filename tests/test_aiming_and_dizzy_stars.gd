extends SceneTree

# test_aiming_and_dizzy_stars.gd
# Verification suite for:
# 1. Hold-to-Aim & Release-to-Throw for Tsinelas with 3D Trajectory Preview, FOV zoom, and lock-on
# 2. Animated Cartoon Dizzy Stars orbiting victim head during stun & slip

const DizzyStarsScript = preload("res://scripts/player/DizzyStars.gd")
const TrajectoryPreviewScript = preload("res://scripts/player/TrajectoryPreview.gd")

var passed: int = 0
var failed: int = 0

func _init() -> void:
	call_deferred("_run_all_tests")

func assert_true(cond: bool, msg: String) -> void:
	if cond:
		print("  [PASS] %s" % msg)
		passed += 1
	else:
		push_error("  [FAIL] %s" % msg)
		failed += 1

func assert_eq(a, b, msg: String) -> void:
	if a == b:
		print("  [PASS] %s" % msg)
		passed += 1
	else:
		push_error("  [FAIL] %s (Expected %s, Got %s)" % [msg, str(b), str(a)])
		failed += 1

func _run_all_tests() -> void:
	print("\n======================================================================")
	print(" [HOLD-TO-AIM TRAJECTORY & CARTOON DIZZY STARS TEST SUITE] ")
	print("======================================================================")

	await _test_dizzy_stars_component()
	await _test_trajectory_preview_component()
	await _test_hold_to_aim_throw_flow()
	await _test_dizzy_stars_on_slip_and_stun()
	await _test_non_throwable_items_immediate_use()

	print("\n======================================================================")
	print(" SUITE SUMMARY: %d Passed, %d Failed" % [passed, failed])
	print("======================================================================")
	if failed == 0:
		print(" ALL VERIFICATIONS PASSED SUCCESSFULLY!")
		quit(0)
	else:
		print(" VERIFICATION RUN COMPLETED WITH FAILURES.")
		quit(1)

func _test_dizzy_stars_component() -> void:
	print("\n--- 1. Testing DizzyStars Component Visuals & Orbit Physics ---")
	var stars = DizzyStarsScript.new()
	root.add_child(stars)
	await process_frame

	assert_true(stars != null, "DizzyStars instantiated")
	assert_eq(stars.star_nodes.size(), 3, "Created exactly 3 comic diamond stars")
	assert_true(not stars.visible, "Initial visibility is false")

	stars.set_active(true)
	assert_true(stars.visible, "set_active(true) makes component visible")
	assert_true(stars.is_active, "is_active flag set to true")

	# Process frames to verify smooth orbital animation without math crashes
	for _i in range(10):
		stars._process(0.016)

	assert_true(stars.orbit_angle > 0.0, "Orbit angle advancing smoothly (%f rad)" % stars.orbit_angle)

	stars.set_active(false)
	assert_true(not stars.visible, "set_active(false) hides stars")
	assert_true(not stars.is_active, "is_active reset to false")

	stars.queue_free()
	await process_frame

func _test_trajectory_preview_component() -> void:
	print("\n--- 2. Testing TrajectoryPreview Component Arc & Raycasting ---")
	var traj = TrajectoryPreviewScript.new()
	root.add_child(traj)
	await process_frame

	assert_true(traj != null, "TrajectoryPreview instantiated")
	assert_true(traj.immediate_mesh != null, "ImmediateMesh created for 3D trajectory line strip")
	assert_true(traj.landing_marker != null, "Landing marker torus created")

	# Test raycast arc calculation
	var space := (root.get_child(0) as Node3D).get_world_3d().direct_space_state if root.get_child_count() > 0 and root.get_child(0) is Node3D else null
	var origin := Vector3(0, 1.5, 0)
	var initial_vel := Vector3(0, 2.0, -10.0)
	var gravity_accel := -9.0

	var result: Dictionary = traj.update_trajectory(origin, initial_vel, gravity_accel, space, [])
	assert_true(traj.visible, "Trajectory is visible after update")
	assert_true(result.has("has_hit"), "Returns trajectory hit status")
	assert_true(result.has("hit_point"), "Returns trajectory hit point")
	assert_true(result.has("is_locked"), "Returns lock-on state")

	traj.hide_preview()
	assert_true(not traj.visible, "hide_preview() sets visible = false")

	traj.queue_free()
	await process_frame

func _test_hold_to_aim_throw_flow() -> void:
	print("\n--- 3. Testing Hold-to-Aim & Release-to-Throw Gameplay Flow ---")
	var player_scene = load("res://scenes/player/Player.tscn")
	assert_true(player_scene != null, "Player.tscn loaded")
	if not player_scene:
		return

	var world_root := Node3D.new()
	root.add_child(world_root)

	var player = player_scene.instantiate()
	player.player_id = 1
	player.name = "1"
	world_root.add_child(player)
	await process_frame
	await process_frame

	assert_true(player.trajectory_preview != null, "Local human player has TrajectoryPreview")

	# Pick up Spartan Tsinelas (item 0)
	player.pickup_street_item(0, "TSINELAS")
	assert_eq(player.held_street_item, 0, "Held street item is 0 (TSINELAS)")
	assert_eq(player.held_street_item_count, 1, "Held count is 1")

	# 1. Simulate Button Press / Right-Click (Hold to Aim)
	player._on_item_input_pressed()
	assert_true(player.is_aiming_throw, "is_aiming_throw is active on press")

	# 2. Check FOV pull in _update_camera_fov
	if player.camera:
		var init_fov = player.camera.fov
		for _i in range(15):
			player._update_camera_fov(0.016)
		assert_true(player.camera.fov < init_fov, "Camera FOV pulled in for over-the-shoulder aim (from %f to %f)" % [init_fov, player.camera.fov])

	# 3. Simulate movement processing while aiming (tactical walk speed constraint)
	player._process_authority_movement(0.016)
	assert_true(player.trajectory_preview.visible, "Trajectory preview active while aiming")

	# 4. Simulate Release-to-Throw
	var children_before := world_root.get_child_count()
	player._on_item_input_released()

	assert_true(not player.is_aiming_throw, "is_aiming_throw reset to false on release")
	assert_true(not player.trajectory_preview.visible, "Trajectory preview hidden on release")
	assert_eq(player.held_street_item, -1, "Held item consumed")
	assert_eq(player.held_street_item_count, 0, "Held count decremented to 0")

	# Verify ThrownProjectile was instantiated in parent
	var projectile_spawned: bool = false
	for child in world_root.get_children():
		if child is ThrownProjectile:
			projectile_spawned = true
			break
	assert_true(projectile_spawned, "ThrownProjectile successfully launched into world on release")

	world_root.queue_free()
	await process_frame

func _test_dizzy_stars_on_slip_and_stun() -> void:
	print("\n--- 4. Testing Comic Dizzy Stars Feedback on Slip and Stun ---")
	var player_scene = load("res://scenes/player/Player.tscn")
	var world_root := Node3D.new()
	root.add_child(world_root)

	var player = player_scene.instantiate()
	player.player_id = 1
	player.name = "1"
	world_root.add_child(player)
	await process_frame
	await process_frame

	var model = player.model
	assert_true(model != null, "CharacterAnimator model found")
	assert_true(model.dizzy_stars != null, "DizzyStars component attached to CharacterAnimator")
	assert_true(not model.dizzy_stars.visible, "Dizzy stars initially inactive")

	# 1. Banana slip triggers dizzy stars
	player.apply_banana_slip("Totoy")
	assert_true(player.is_slipping, "Player is slipping")

	model.animate(0.016, 0.0, true, 6.0)
	assert_true(model.dizzy_stars.visible, "Dizzy stars active during banana slip")
	assert_true(model.dizzy_stars.is_active, "Dizzy stars orbiting during banana slip")

	# 2. Slipper stun triggers dizzy stars
	player.is_slipping = false
	player.slip_timer = 0.0
	model.slip_anim_timer = 0.0

	player.apply_slipper_stun(1.2, "Tsuna")
	assert_true(player.is_stunned, "Player is stunned by slipper")

	model.animate(0.016, 0.0, true, 6.0)
	assert_true(model.dizzy_stars.visible, "Dizzy stars active during slipper stun")

	# 3. Recovery hides dizzy stars
	player.is_stunned = false
	player.stun_timer = 0.0
	player.is_slipping = false
	model.is_stunned = false
	model.is_slipping = false
	model.animate(0.016, 0.0, true, 6.0)
	assert_true(not model.dizzy_stars.visible, "Dizzy stars disappear upon recovery")

	world_root.queue_free()
	await process_frame

func _test_non_throwable_items_immediate_use() -> void:
	print("\n--- 5. Testing Non-Throwable Street Items (Immediate Use) ---")
	var player_scene = load("res://scenes/player/Player.tscn")
	var world_root := Node3D.new()
	root.add_child(world_root)

	var player = player_scene.instantiate()
	player.player_id = 1
	player.name = "1"
	world_root.add_child(player)
	await process_frame
	await process_frame

	# Pick up Saging (Banana Peel, item 1)
	player.pickup_street_item(1, "SAGING")
	assert_eq(player.held_street_item, 1, "Held item is 1 (SAGING)")

	# Pressing item input should immediately drop banana and NOT enter aiming mode
	player._on_item_input_pressed()
	assert_true(not player.is_aiming_throw, "is_aiming_throw remains false for non-throwables")
	assert_eq(player.held_street_item, -1, "Banana peel used immediately on press")

	world_root.queue_free()
	await process_frame
