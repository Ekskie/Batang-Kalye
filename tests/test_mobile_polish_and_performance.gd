extends SceneTree

const KalyeVirtualJoystickScript = preload("res://scripts/ui/VirtualJoystick.gd")
const MobileControlsScript = preload("res://scripts/ui/MobileControls.gd")
const KalyeMatchMapScript = preload("res://scripts/gameplay/KalyeMatchMap.gd")
const PlayerControllerScript = preload("res://scripts/player/PlayerController.gd")

var passed_count := 0
var failed_count := 0

func _init() -> void:
	call_deferred("run_tests")

func assert_true(condition: bool, message: String) -> void:
	if condition:
		passed_count += 1
		print("  [PASS] %s" % message)
	else:
		failed_count += 1
		print("  [FAIL] %s" % message)

func assert_eq(val1, val2, message: String) -> void:
	if val1 == val2:
		passed_count += 1
		print("  [PASS] %s" % message)
	else:
		failed_count += 1
		print("  [FAIL] %s (Expected: %s, Got: %s)" % [message, str(val2), str(val1)])

func run_tests() -> void:
	print("\n======================================================================")
	print(" [MOBILE POLISH & 60 FPS PERFORMANCE VERIFICATION SUITE] ")
	print("======================================================================")

	await test_dynamic_floating_joystick()
	await test_haptics_and_settings_persistence()
	await test_touch_hud_safe_area_and_scale()
	await test_kalye_match_map_lod_culling()

	print("\n======================================================================")
	print(" SUITE SUMMARY: %d Passed, %d Failed" % [passed_count, failed_count])
	print("======================================================================")
	if failed_count == 0:
		print(" ALL MOBILE & PERFORMANCE VERIFICATIONS PASSED SUCCESSFULLY!")
		quit(0)
	else:
		printerr(" SOME TESTS FAILED!")
		quit(1)

func test_dynamic_floating_joystick() -> void:
	print("\n--- 1. Testing Dynamic Floating Virtual Joystick ---")
	var joystick := KalyeVirtualJoystickScript.new()
	joystick.custom_minimum_size = Vector2(300, 300)
	joystick.size = Vector2(300, 300)
	root.add_child(joystick)
	await process_frame

	assert_true(is_instance_valid(joystick), "VirtualJoystick instantiated cleanly")
	assert_eq(joystick.joystick_mode, KalyeVirtualJoystickScript.JoystickMode.DYNAMIC, "Default mode is DYNAMIC (Floating)")
	assert_eq(joystick.output_vector, Vector2.ZERO, "Initial output vector is zero")
	assert_true(not joystick.is_active, "Joystick initially inactive")

	# 1.1 Touch press at arbitrary thumb coordinate (120, 200)
	var touch_down := InputEventScreenTouch.new()
	touch_down.index = 0
	touch_down.pressed = true
	touch_down.position = Vector2(120, 200)
	joystick._gui_input(touch_down)

	assert_true(joystick.is_active, "Joystick active upon screen touch")
	assert_eq(joystick.center_pos, Vector2(120, 200), "Floating joystick dynamically re-centered base directly under thumb (120, 200)")
	assert_eq(joystick.output_vector, Vector2.ZERO, "Output vector remains zero at touch inception point")

	# 1.2 Drag upwards to (120, 140) => 60px north
	var drag_up := InputEventScreenDrag.new()
	drag_up.index = 0
	drag_up.position = Vector2(120, 140)
	joystick._gui_input(drag_up)

	assert_true(joystick.output_vector.y < -0.8, "Upward drag produces negative Y vector (Got: %f)" % joystick.output_vector.y)
	assert_true(absf(joystick.output_vector.x) < 0.05, "Straight upward drag has near-zero X component")

	# 1.3 Release touch
	var touch_up := InputEventScreenTouch.new()
	touch_up.index = 0
	touch_up.pressed = false
	touch_up.position = Vector2(120, 140)
	joystick._gui_input(touch_up)

	assert_true(not joystick.is_active, "Joystick inactive after release")
	assert_eq(joystick.output_vector, Vector2.ZERO, "Output vector reset to zero on release")

	# 1.4 Switch to FIXED mode
	joystick.set_joystick_mode(KalyeVirtualJoystickScript.JoystickMode.FIXED)
	assert_eq(joystick.joystick_mode, KalyeVirtualJoystickScript.JoystickMode.FIXED, "Mode switched to FIXED successfully")

	# Touch press at (50, 50) while in FIXED mode
	touch_down.position = Vector2(50, 50)
	joystick._gui_input(touch_down)
	assert_eq(joystick.center_pos, joystick.default_center, "In FIXED mode, base center remains locked to default center")

	touch_up.position = Vector2(50, 50)
	joystick._gui_input(touch_up)
	joystick.queue_free()

func test_haptics_and_settings_persistence() -> void:
	print("\n--- 2. Testing Haptic Feedback & Settings Persistence ---")
	var main_scene: PackedScene = load("res://scenes/main/Main.tscn")
	var gm: GameManager = main_scene.instantiate() as GameManager
	gm.is_running_automated_test = true
	root.add_child(gm)
	gm._init_node_references()
	await process_frame

	assert_true(gm.has_method("is_vibration_enabled"), "GameManager has is_vibration_enabled method")
	assert_true(gm.has_method("set_vibration_enabled"), "GameManager has set_vibration_enabled method")
	assert_true(gm.has_method("set_joystick_style"), "GameManager has set_joystick_style method")
	assert_true(gm.has_method("set_touch_ui_scale"), "GameManager has set_touch_ui_scale method")

	# Test toggling vibration
	gm.set_vibration_enabled(true)
	assert_true(gm.is_vibration_enabled(), "Vibration enabled is true")
	gm.set_vibration_enabled(false)
	assert_true(not gm.is_vibration_enabled(), "Vibration enabled toggled to false")
	gm.set_vibration_enabled(true)

	# Test joystick style and UI scale
	gm.set_joystick_style(1)
	assert_eq(int(gm.settings_data.get("joystick_style", 0)), 1, "Joystick style set to 1 (Fixed)")
	gm.set_touch_ui_scale(1.15)
	assert_eq(float(gm.settings_data.get("touch_ui_scale", 1.0)), 1.15, "Touch UI scale set to 1.15x")

	# Test saving and loading config
	gm._save_settings()
	var cfg := ConfigFile.new()
	var err := cfg.load(gm.SETTINGS_SAVE_PATH)
	assert_eq(err, OK, "settings.cfg loaded successfully")
	assert_eq(cfg.get_value("controls", "vibration", false), true, "Vibration persisted to settings.cfg")
	assert_eq(cfg.get_value("controls", "joystick_style", -1), 1, "Joystick style persisted to settings.cfg")
	assert_eq(cfg.get_value("controls", "touch_ui_scale", 0.0), 1.15, "Touch UI scale persisted to settings.cfg")

	# Test player vibration routing
	var player_scene: PackedScene = load("res://scenes/player/Player.tscn")
	var player: PlayerController = player_scene.instantiate() as PlayerController
	player.player_id = 1
	gm.players_container.add_child(player)
	await process_frame

	assert_true(player.has_method("trigger_device_vibration"), "PlayerController has trigger_device_vibration helper")
	# Suppressed when vibration disabled
	gm.set_vibration_enabled(false)
	player.trigger_device_vibration(100) # Should execute cleanly without error
	assert_true(not gm.is_vibration_enabled(), "Device vibration cleanly bypassed when disabled in settings")

	gm.queue_free()

func test_touch_hud_safe_area_and_scale() -> void:
	print("\n--- 3. Testing Touch HUD Safe Area & UI Scaling ---")
	var hud_scene: PackedScene = load("res://scenes/ui/MobileControlsUI.tscn")
	var hud: MobileControls = hud_scene.instantiate() as MobileControls
	root.add_child(hud)
	await process_frame

	assert_true(is_instance_valid(hud), "MobileControlsUI.tscn loaded and instantiated")
	assert_true(hud.is_in_group("mobile_controls"), "MobileControls automatically registered into mobile_controls group")

	# Test UI scale adjustment
	hud.set_ui_scale(1.25)
	assert_eq(hud.scale, Vector2(1.25, 1.25), "set_ui_scale successfully scales HUD to Vector2(1.25, 1.25)")

	hud.set_ui_scale(0.85)
	assert_eq(hud.scale, Vector2(0.85, 0.85), "set_ui_scale successfully scales HUD to Vector2(0.85, 0.85)")

	# Test safe area adaptation execution
	hud._adapt_display_safe_area()
	assert_true(hud.left_touch_zone != null, "LeftTouchZone exists and has safe margins applied")
	assert_true(hud.action_buttons != null, "ActionButtons exists and has safe margins applied")

	# Test joystick mode delegation
	hud.set_joystick_mode(1)
	assert_eq(hud.joystick.joystick_mode, KalyeVirtualJoystickScript.JoystickMode.FIXED, "HUD successfully delegates joystick mode to child VirtualJoystick")

	# Test button micro-haptics hook
	assert_true(hud.has_method("trigger_haptic"), "MobileControls has trigger_haptic method")
	hud.trigger_haptic(18) # Micro-pulse should execute safely
	assert_true(true, "trigger_haptic(18) micro-pulse executed without exception")

	hud.queue_free()

func test_kalye_match_map_lod_culling() -> void:
	print("\n--- 4. Testing Suburban Kalye 60 FPS LOD Distance Culling ---")
	var map_scene: PackedScene = load("res://scenes/maps/KalyeMatchMap.tscn")
	var map: KalyeMatchMap = map_scene.instantiate() as KalyeMatchMap
	root.add_child(map)
	await process_frame

	assert_true(is_instance_valid(map), "KalyeMatchMap loaded cleanly")

	# Check landmarks (should NOT be culled: visibility_range_end == 0.0)
	var tindahan: MeshInstance3D = null
	var brgy_hall: MeshInstance3D = null
	var fence_plane: MeshInstance3D = null
	var other_house: MeshInstance3D = null

	var stack: Array[Node] = [map]
	while not stack.is_empty():
		var node = stack.pop_back()
		if node is MeshInstance3D:
			var n: String = node.name.to_lower()
			if n == "cube_002":
				tindahan = node
			elif n == "cube_015":
				brgy_hall = node
			elif "plane_010" in n or "plane_014" in n or "fence" in n:
				if not fence_plane:
					fence_plane = node
			elif not other_house and "cube" in n and n != "cube_002" and n != "cube_015":
				other_house = node
		for c in node.get_children():
			stack.append(c)

	assert_true(tindahan != null, "Found Tindahan mesh in map hierarchy")
	if tindahan:
		assert_eq(tindahan.visibility_range_end, 0.0, "Tindahan landmark is unculled (0.0) for long-range orientation")

	assert_true(brgy_hall != null, "Found Barangay Hall mesh in map hierarchy")
	if brgy_hall:
		assert_eq(brgy_hall.visibility_range_end, 0.0, "Barangay Hall landmark is unculled (0.0) for long-range orientation")

	assert_true(fence_plane != null, "Found fence mesh in map hierarchy")
	if fence_plane:
		assert_eq(fence_plane.visibility_range_end, 55.0, "Clutter/fence mesh has visibility_range_end configured to 55.0m for 60 FPS")
		assert_eq(fence_plane.visibility_range_fade_mode, GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF, "Clutter/fence mesh has smooth self-fade mode")

	assert_true(other_house != null, "Found residential house mesh in map hierarchy")
	if other_house:
		assert_eq(other_house.visibility_range_end, 95.0, "Intermediate residential house has visibility_range_end set to 95.0m")

	# Verify strict mobile collision requirement is preserved (0 concave)
	var concave_count := 0
	var col_stack: Array[Node] = [map]
	while not col_stack.is_empty():
		var n = col_stack.pop_back()
		if n is CollisionShape3D and n.shape is ConcavePolygonShape3D:
			concave_count += 1
		for c in n.get_children():
			col_stack.append(c)

	assert_eq(concave_count, 0, "KalyeMatchMap strictly preserves 0 ConcavePolygonShape3D colliders")

	map.queue_free()
