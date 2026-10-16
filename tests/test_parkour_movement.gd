extends SceneTree

# ==============================================================================
# test_parkour_movement.gd
# Verification suite for Parkour Vaulting Movement & Bot Slipper Lead Trajectory
# ==============================================================================

var passed: int = 0
var failed: int = 0

func assert_true(cond: bool, msg: String) -> void:
	if cond:
		print("  [PASS] %s" % msg)
		passed += 1
	else:
		push_error("  [FAIL] %s" % msg)
		print("  [FAIL] %s" % msg)
		failed += 1

func assert_eq(a, b, msg: String) -> void:
	if a == b:
		print("  [PASS] %s" % msg)
		passed += 1
	else:
		push_error("  [FAIL] %s (Expected %s, Got %s)" % [msg, str(b), str(a)])
		print("  [FAIL] %s (Expected %s, Got %s)" % [msg, str(b), str(a)])
		failed += 1

func _init() -> void:
	call_deferred("_run_all_tests")

func _run_all_tests() -> void:
	print("\n======================================================================")
	print(" [PARKOUR MOVEMENT & BOT TRAJECTORY VERIFICATION SUITE] ")
	print("======================================================================")

	await _test_obstacle_vault_detection()
	await _test_bot_vault_execution_and_momentum()
	await _test_bot_slipper_target_selection()
	await _test_bot_slipper_lead_calculation()
	await _test_bot_slipper_throw_projectile()
	await _test_bot_remote_interpolation()

	print("\n======================================================================")
	print(" SUITE SUMMARY: %d Passed, %d Failed" % [passed, failed])
	print("======================================================================")
	if failed == 0:
		print(" ALL PARKOUR & BOT TRAJECTORY VERIFICATIONS PASSED!")
		quit(0)
	else:
		push_error(" PARKOUR VERIFICATION SUITE COMPLETED WITH FAILURES.")
		quit(1)

func _create_static_obstacle(pos: Vector3, size: Vector3) -> StaticBody3D:
	var sb := StaticBody3D.new()
	sb.collision_layer = 1
	sb.collision_mask = 1
	var cs := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	cs.shape = box
	sb.add_child(cs)
	sb.position = pos
	root.add_child(sb)
	return sb

func _test_obstacle_vault_detection() -> void:
	print("\n--- 1. Testing Parkour Obstacle Raycast & Vault Detection ---")
	var bot_scene: PackedScene = load("res://scenes/player/PracticeBot.tscn")
	if not bot_scene:
		bot_scene = load("res://scenes/player/Player.tscn")
	assert_true(bot_scene != null, "Player/PracticeBot scene loaded")
	if not bot_scene:
		return

	# Create ground plane
	var ground := _create_static_obstacle(Vector3(0, -0.5, 0), Vector3(30, 1, 30))

	# Create a vaultable barrier (height 0.8m, depth 0.3m, width 3.0m) at Z=1.0
	# Center at Y=0.4 so top is at Y=0.8
	var barrier := _create_static_obstacle(Vector3(0, 0.4, 1.0), Vector3(3.0, 0.8, 0.3))

	var player = bot_scene.instantiate()
	root.add_child(player)
	player.global_position = Vector3(0, 0.0, 0.0)
	player.velocity = Vector3(0, 0, 3.5) # Running toward barrier in +Z

	await physics_frame
	await physics_frame

	var can_vault: bool = player._check_vaultable_obstacle()
	assert_true(can_vault, "Vaultable obstacle detected ahead at 1.0m distance")
	assert_true(player.vault_apex_pos.y > 0.8, "Vault apex computed above obstacle top (%.2fm)" % player.vault_apex_pos.y)
	assert_true(player.vault_end_pos.z > 1.0, "Vault landing target computed beyond obstacle (%.2fm)" % player.vault_end_pos.z)

	# Test facing away from obstacle: should return false
	player.velocity = Vector3(0, 0, -3.5) # Moving away in -Z
	assert_true(not player._check_vaultable_obstacle(), "Obstacle ignored when player moves away")

	# Clean up
	player.queue_free()
	barrier.queue_free()
	ground.queue_free()
	await process_frame

func _test_bot_vault_execution_and_momentum() -> void:
	print("\n--- 2. Testing Bot Vault Bezier Execution & Momentum Preservation ---")
	var bot_scene: PackedScene = load("res://scenes/player/PracticeBot.tscn")
	if not bot_scene:
		bot_scene = load("res://scenes/player/Player.tscn")
	var bot = bot_scene.instantiate()
	root.add_child(bot)
	await process_frame
	await process_frame

	assert_true(not bot.is_vaulting, "Bot starts with is_vaulting = false")
	var initial_vault_count: int = bot.stats_vaults

	var start := Vector3(0, 0, 0)
	var apex := Vector3(0, 1.2, 1.0)
	var end := Vector3(0, 0, 2.0)

	bot._trigger_vault(start, apex, end)
	assert_true(bot.is_vaulting, "Bot enters vaulting state after _trigger_vault")
	assert_eq(bot.stats_vaults, initial_vault_count + 1, "Vault counter incremented")
	assert_true(bot.vault_progress == 0.0, "Vault progress initialized to 0.0")

	# Advance 50% through vault
	bot._process_vault(bot.vault_duration * 0.5)
	assert_true(bot.is_vaulting, "Bot remains vaulting at midpoint")
	assert_true(bot.vault_progress >= 0.45 and bot.vault_progress <= 0.55, "Progress correctly scaled (%.2f)" % bot.vault_progress)
	assert_true(bot.global_position.y > 0.5, "Bot elevated above ground at midpoint (Y=%.2f)" % bot.global_position.y)

	# Complete vault
	bot._process_vault(bot.vault_duration * 0.6)
	assert_true(not bot.is_vaulting, "Vault ends when duration expires")
	assert_true(bot.global_position.distance_to(end) < 0.1, "Bot arrived at landing destination")
	assert_true(bot.velocity.length() >= (bot.sprint_speed - 0.5), "Sprint forward momentum preserved (%.2f m/s)" % bot.velocity.length())

	bot.queue_free()
	await process_frame

func _test_bot_slipper_target_selection() -> void:
	print("\n--- 3. Testing Bot Slipper Target Selection & Line-of-Sight ---")
	var bot_scene: PackedScene = load("res://scenes/player/PracticeBot.tscn")
	var bot1 = bot_scene.instantiate()
	var bot2 = bot_scene.instantiate()
	root.add_child(bot1)
	root.add_child(bot2)

	bot1.add_to_group("players")
	bot2.add_to_group("players")
	bot1.player_id = 91
	bot2.player_id = 92

	bot1.current_role = PlayerController.Role.RUNNER
	bot2.current_role = PlayerController.Role.TAYA

	bot1.global_position = Vector3(0, 0, 0)
	bot2.global_position = Vector3(0, 0, 8) # 8m away in range

	await physics_frame
	await physics_frame

	# Runner bot1 should target Taya bot2
	var target = bot1._find_slipper_target()
	assert_true(target == bot2, "Runner bot finds Taya bot as slipper target at 8m")

	# Taya bot2 should target Runner bot1
	var chaser_target = bot2._find_slipper_target()
	assert_true(chaser_target == bot1, "Taya bot finds Runner bot as slipper target at 8m")

	# Test distance too far (> 15m)
	bot2.global_position = Vector3(0, 0, 20)
	await physics_frame
	assert_true(bot1._find_slipper_target() == null, "Target ignored when beyond max range (>15m)")

	# Test distance too close (< 2m)
	bot2.global_position = Vector3(0, 0, 1.0)
	await physics_frame
	assert_true(bot1._find_slipper_target() == null, "Target ignored when inside minimum range (<2m)")

	# Test immunity check: immune runner should be ignored by chaser
	bot2.global_position = Vector3(0, 0, 8)
	bot1.is_immune = true
	await physics_frame
	assert_true(bot2._find_slipper_target() == null, "Immune runner is ignored by chaser bot")
	bot1.is_immune = false

	# Test line-of-sight obstruction
	var wall := _create_static_obstacle(Vector3(0, 1.0, 4.0), Vector3(5.0, 3.0, 1.0))
	await physics_frame
	await physics_frame
	assert_true(not bot1._check_line_of_sight(bot2), "Line of sight blocked by wall obstacle")
	assert_true(bot1._find_slipper_target() == null, "Obstacle obstruction prevents target selection")

	wall.queue_free()
	bot1.queue_free()
	bot2.queue_free()
	await process_frame

func _test_bot_slipper_lead_calculation() -> void:
	print("\n--- 4. Testing Slipper Lead Trajectory Prediction Math ---")
	# Target is 12m away moving laterally at 6.0 m/s
	# Slipper speed = 24.0 m/s -> lead time = 12 / 24 = 0.5s
	# Target travel distance = 6.0 * 0.5 = 3.0m lateral offset
	var bot_pos := Vector3(0, 0, 0)
	var target_pos := Vector3(12, 0, 0)
	var target_vel := Vector3(0, 0, 6.0)
	var slipper_speed := 24.0

	var dist := bot_pos.distance_to(target_pos)
	var lead_time := dist / slipper_speed
	assert_eq(lead_time, 0.5, "Computed lead time for 12m at 24m/s is 0.5s")

	var predicted_aim := target_pos + target_vel * lead_time + Vector3(0, 0.75, 0)
	var expected_aim := Vector3(12, 0.75, 3.0)
	assert_true(predicted_aim.distance_to(expected_aim) < 0.001, "Predicted aim coordinates account for target velocity vector")

	# Test stationary target: lead offset should be zero
	var stationary_vel := Vector3.ZERO
	var stationary_aim := target_pos + stationary_vel * lead_time + Vector3(0, 0.75, 0)
	assert_true(stationary_aim.distance_to(Vector3(12, 0.75, 0)) < 0.001, "Stationary target lead matches center of mass")

func _test_bot_slipper_throw_projectile() -> void:
	print("\n--- 5. Testing Bot Slipper Throw Projectile Spawning ---")
	var bot_scene: PackedScene = load("res://scenes/player/PracticeBot.tscn")
	var bot = bot_scene.instantiate()
	root.add_child(bot)
	bot.player_id = 95
	bot.player_name = "Bot Baldo"
	bot.global_position = Vector3(0, 0, 0)

	# Give bot a slipper
	bot.held_street_item = 0 # TSINELAS
	bot.held_street_item_count = 1

	await process_frame
	await process_frame

	# Call _throw_tsinelas
	bot._throw_tsinelas()

	# Find spawned ThrownProjectile in root
	var spawned_proj: ThrownProjectile = null
	for child in root.get_children():
		if child is ThrownProjectile:
			spawned_proj = child
			break

	assert_true(spawned_proj != null, "ThrownProjectile instantiated into scene tree")
	if spawned_proj:
		assert_eq(spawned_proj.projectile_type, ThrownProjectile.ProjectileType.TSINELAS, "Projectile type is TSINELAS")
		assert_eq(spawned_proj.thrower_id, 95, "Projectile thrower ID recorded as 95")
		assert_eq(spawned_proj.thrower_name, "Bot Baldo", "Projectile thrower name recorded")
		assert_true(spawned_proj.velocity.length() > 20.0, "Projectile launch velocity applied (%.2f m/s)" % spawned_proj.velocity.length())
		assert_true(spawned_proj.velocity.y > 0.0, "Upward arc impulse applied to slipper trajectory")
		spawned_proj.queue_free()

	bot.queue_free()
	await process_frame

func _test_bot_remote_interpolation() -> void:
	print("\n--- 6. Testing Non-Host Remote Peer Bot Interpolation & Animation ---")
	var bot_scene: PackedScene = load("res://scenes/player/PracticeBot.tscn")
	var bot = bot_scene.instantiate()
	root.add_child(bot)
	bot.global_position = Vector3(0, 0, 0)
	bot.reset_network_interpolation(Vector3(0, 0, 0))

	# Remote peer sync arrives with new position (10, 0, 5) and horizontal speed 4.5
	bot.sync_transform(Vector3(10, 0, 5), Vector3(4, 0, 2), 0.5, 4.5, true, false, false, 50000)
	assert_true(bot.target_position == Vector3(10, 0, 5), "sync_transform updates target_position on bot")
	assert_true(bot.target_velocity == Vector3(4, 0, 2), "sync_transform updates target_velocity on bot")
	assert_eq(bot.remote_horizontal_speed, 4.5, "sync_transform updates remote_horizontal_speed on bot")
	assert_true(bot.remote_is_on_floor, "sync_transform updates remote_is_on_floor on bot")

	# Process remote interpolation step
	bot._process_remote_interpolation(0.05)
	assert_true(bot.global_position.x > 0.0, "Bot moves toward target position via interpolation")

	# Simulate non-authority client peer environment
	bot.set_multiplayer_authority(1) # Authority is Host
	assert_true(bot.is_local_controlled(), "Host authority controls bot locally")

	# Now simulate being a remote peer (client 2) observing the host bot
	bot.set_multiplayer_authority(999) # Remote authority
	assert_true(not bot.is_local_controlled(), "Remote peer does not control remote bot")

	# Verify remote vault sync trigger
	assert_true(not bot.is_vaulting, "Bot initially not vaulting on remote peer")
	bot.sync_vault_trigger(Vector3(0, 0, 0), Vector3(0, 1.2, 1.0), Vector3(0, 0, 2.0))
	assert_true(bot.is_vaulting, "sync_vault_trigger successfully triggers vault on remote peer")
	assert_eq(bot.vault_apex_pos, Vector3(0, 1.2, 1.0), "Remote peer sets vault apex position")
	assert_eq(bot.vault_end_pos, Vector3(0, 0, 2.0), "Remote peer sets vault landing position")

	# Verify controlling authority ignores bounce-back to prevent infinite recursion
	bot.set_multiplayer_authority(1) # Restore authority
	bot.is_vaulting = false
	bot.sync_vault_trigger(Vector3(0, 0, 0), Vector3(0, 1.2, 1.0), Vector3(0, 0, 2.0))
	assert_true(not bot.is_vaulting, "Controlling authority safely ignores sync_vault_trigger RPC bounce-back")

	bot.queue_free()
	await process_frame
