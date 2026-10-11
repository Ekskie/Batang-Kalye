extends SceneTree

# test_slip_animation_and_slopes.gd
# Verification suite for Slip Animation (saging/banana & tsinelas/slipper) and Slope Collisions

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
	print(" [SLIP ANIMATION & SLOPE COLLISION VERIFICATION SUITE] ")
	print("======================================================================")

	await _test_player_slip_banana()
	await _test_player_slip_tsinelas_stun()
	await _test_slip_animation_sharing_on_characters()
	await _test_map_slope_collisions()

	print("\n======================================================================")
	print(" SUITE SUMMARY: %d Passed, %d Failed" % [passed, failed])
	print("======================================================================")
	if failed == 0:
		print(" ALL VERIFICATIONS PASSED SUCCESSFULLY!")
		quit(0)
	else:
		print(" VERIFICATION RUN COMPLETED WITH FAILURES.")
		quit(1)

func _test_player_slip_banana() -> void:
	print("\n--- 1. Testing Banana Peel Slip: In-Place Stun & Camera Tracking ---")
	var player_scene = load("res://scenes/player/Player.tscn")
	assert_true(player_scene != null, "Player.tscn loaded")
	if not player_scene:
		return

	var player = player_scene.instantiate()
	root.add_child(player)
	await process_frame
	await process_frame

	var model = player.model
	assert_true(model != null, "Player model found and ready")
	if not model:
		player.queue_free()
		return

	var floor_body := StaticBody3D.new()
	var col_shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(20, 2, 20)
	col_shape.shape = box
	floor_body.add_child(col_shape)
	floor_body.position = Vector3(0, -1, 0)
	root.add_child(floor_body)

	var initial_pos: Vector3 = player.global_position
	# Apply initial velocity before slipping (as if running)
	player.velocity = Vector3(10.0, 0.0, -10.0)

	# Test banana slip
	player.apply_banana_slip("Lolong")
	assert_true(player.is_slipping, "player.is_slipping is true after apply_banana_slip")
	assert_true(model.is_slipping, "model.is_slipping is true after apply_banana_slip")
	assert_true(player.velocity.x == 0.0 and player.velocity.z == 0.0, "Horizontal velocity halted immediately to prevent sliding")

	# Process multiple physics frames
	for i in range(10):
		player._physics_process(0.016)

	var dist_moved: float = Vector2(player.global_position.x - initial_pos.x, player.global_position.z - initial_pos.z).length()
	assert_true(dist_moved < 0.05, "Player stays in exact place without sliding (moved %.4fm)" % dist_moved)

	# Verify camera tracks player rather than staying behind
	if player.camera_mount:
		var target_cam: Vector3 = player.global_position + Vector3(0, 1.4, 0)
		var cam_dist: float = player.camera_mount.global_position.distance_to(target_cam)
		assert_true(cam_dist < 0.2, "Camera mount smoothly tracks player during slip (offset: %.3fm)" % cam_dist)

	# Verify actions are blocked during slip (like a stun)
	player._try_slide()
	assert_true(not player.is_sliding, "Slide action blocked while slipping")
	player._try_dash()
	assert_true(not player.is_dashing, "Dash action blocked while slipping")
	player._queue_jump()
	assert_true(player.jump_buffer_timer == 0.0, "Jump action blocked while slipping")

	var cur_anim: String = model.active_anim.current_animation if (model.active_anim) else ""
	assert_true(cur_anim == "slip" or cur_anim == "Slip", "active_anim plays slip in place (current: %s)" % cur_anim)
	assert_true(model.active_anim.speed_scale > 1.0, "active_anim speed_scale scaled for responsive slip (%.2f)" % model.active_anim.speed_scale)

	floor_body.queue_free()
	player.queue_free()
	await process_frame

func _test_player_slip_tsinelas_stun() -> void:
	print("\n--- 2. Testing Slipper / Tsinelas Stun Slip Animation ---")
	var player_scene = load("res://scenes/player/Player.tscn")
	var player = player_scene.instantiate()
	root.add_child(player)
	await process_frame
	await process_frame

	var model = player.model
	assert_true(model != null, "Player model instantiated")
	if not model:
		player.queue_free()
		return

	player.apply_slipper_stun(1.5, "Kulas")
	assert_true(player.is_stunned, "player.is_stunned is true after apply_slipper_stun")
	assert_true(model.is_slipping, "model.is_slipping is true during slipper stun")

	player._physics_process(0.016)
	await process_frame

	var cur_anim: String = model.active_anim.current_animation if (model.active_anim) else ""
	assert_true(cur_anim == "slip" or cur_anim == "Slip", "active_anim plays slip on slipper stun (current: %s)" % cur_anim)

	# Test Dog NPC / generic stun also triggers slip anim
	player.is_stunned = false
	player.stun_timer = 0.0
	model.is_slipping = false
	model.slip_anim_timer = 0.0

	player.apply_stun(1.2)
	assert_true(player.is_stunned, "player.is_stunned is true after apply_stun")
	assert_true(model.is_slipping, "model.is_slipping is true after apply_stun")

	player._physics_process(0.016)
	await process_frame

	cur_anim = model.active_anim.current_animation if (model.active_anim) else ""
	assert_true(cur_anim == "slip" or cur_anim == "Slip", "active_anim plays slip on generic stun (current: %s)" % cur_anim)

	player.queue_free()
	await process_frame

func _test_slip_animation_sharing_on_characters() -> void:
	print("\n--- 3. Testing Slip Animation Shared Across Character Models (Tsuna, Kalbo, Totoy) ---")
	var player_scene = load("res://scenes/player/Player.tscn")
	var player = player_scene.instantiate()
	root.add_child(player)
	await process_frame
	await process_frame

	var model = player.model

	# Kalbo
	model.set_character(CharacterAnimator.CharacterType.KALBO)
	await process_frame
	player.apply_banana_slip("Totoy")
	player._physics_process(0.016)
	await process_frame
	var cur_anim: String = model.active_anim.current_animation if (model.active_anim) else ""
	assert_true(cur_anim == "slip" or cur_anim == "Slip", "Kalbo model plays slip animation (current: %s)" % cur_anim)

	# Totoy
	model.set_character(CharacterAnimator.CharacterType.TOTOY)
	await process_frame
	player.apply_slipper_stun(1.4, "Baldo")
	player._physics_process(0.016)
	await process_frame
	cur_anim = model.active_anim.current_animation if (model.active_anim) else ""
	assert_true(cur_anim == "slip" or cur_anim == "Slip", "Totoy model plays slip animation (current: %s)" % cur_anim)

	player.queue_free()
	await process_frame

func _test_map_slope_collisions() -> void:
	print("\n--- 4. Testing Slope / Slant / Slide Collisions on KalyeMatchMap ---")
	var map_scene = load("res://scenes/maps/KalyeMatchMap.tscn")
	assert_true(map_scene != null, "KalyeMatchMap.tscn loaded")
	if not map_scene:
		return

	var map = map_scene.instantiate()
	root.add_child(map)
	await process_frame
	await process_frame

	var concave_count: int = 0
	var convex_count: int = 0
	var box_count: int = 0
	var nodes_to_check: Array[Node] = [map]
	while not nodes_to_check.is_empty():
		var n: Node = nodes_to_check.pop_back()
		if n is CollisionShape3D and n.shape:
			if n.shape is ConcavePolygonShape3D:
				concave_count += 1
			elif n.shape is ConvexPolygonShape3D:
				convex_count += 1
			elif n.shape is BoxShape3D:
				box_count += 1
		for c in n.get_children():
			nodes_to_check.push_back(c)

	print("  Collider Counts: Concave=%d, Convex=%d, Box=%d" % [concave_count, convex_count, box_count])
	assert_eq(concave_count, 0, "KalyeMatchMap has 0 ConcavePolygonShape3D colliders (strict project requirement)")
	assert_true(convex_count > 100, "KalyeMatchMap has > 100 convex polygon prism colliders for slopes/slides (%d)" % convex_count)

	# Raycast slope tests
	var space_state = map.get_world_3d().direct_space_state

	# 1. Slope of Cube_041 (X=1.65, Z=-25.48)
	var ray_query = PhysicsRayQueryParameters3D.create(Vector3(1.65, 5.0, -25.48), Vector3(1.65, 0.0, -25.48))
	var hit = space_state.intersect_ray(ray_query)
	assert_true(not hit.is_empty(), "Raycast hit Cube_041 slope at Y=%.3f" % (hit.position.y if not hit.is_empty() else 0.0))

	# 2. Cylinder_009 yellow slanted roof
	var roof_query = PhysicsRayQueryParameters3D.create(Vector3(12.9, 17.0, 0.9), Vector3(12.9, 8.0, 0.9))
	var roof_hit = space_state.intersect_ray(roof_query)
	assert_true(not roof_hit.is_empty(), "Raycast hit Cylinder_009 slanted roof at Y=%.3f" % (roof_hit.position.y if not roof_hit.is_empty() else 0.0))

	# 3. Cylinder_006 playground slide
	var slide_query = PhysicsRayQueryParameters3D.create(Vector3(35.12, 9.0, -8.2), Vector3(35.12, 2.0, -8.2))
	var slide_hit = space_state.intersect_ray(slide_query)
	assert_true(not slide_hit.is_empty(), "Raycast hit playground slide (Cylinder_006) at Y=%.3f" % (slide_hit.position.y if not slide_hit.is_empty() else 0.0))

	# 4. Plane_013 slanted roof
	var plane_roof_query = PhysicsRayQueryParameters3D.create(Vector3(12.35, 12.0, 3.97), Vector3(12.35, 2.0, 3.97))
	var plane_roof_hit = space_state.intersect_ray(plane_roof_query)
	assert_true(not plane_roof_hit.is_empty(), "Raycast hit Plane_013 slanted roof at Y=%.3f" % (plane_roof_hit.position.y if not plane_roof_hit.is_empty() else 0.0))

	map.queue_free()
	await process_frame
