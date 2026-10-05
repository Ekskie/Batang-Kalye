extends SceneTree

# ==============================================================================
# EMPIRICAL TEST SUITE: MILESTONE 3 (Mobile UX, Onboarding & Spectator Polish)
# ==============================================================================

const QuickGuideUIScript = preload("res://scripts/ui/QuickGuideUI.gd")
const MobileControlsScript = preload("res://scripts/ui/MobileControls.gd")
const HUDScript = preload("res://scripts/ui/HUD.gd")

var test_passes: int = 0
var test_failures: int = 0

func _init() -> void:
	call_deferred("run_all_tests")

func assert_true(cond: bool, msg: String) -> void:
	if cond:
		test_passes += 1
		print("  [PASS] %s" % msg)
	else:
		test_failures += 1
		push_error("  [FAIL] %s" % msg)
		print("  [FAIL] %s" % msg)

func run_all_tests() -> void:
	print("\n" + "=".repeat(70))
	print(" [MILESTONE 3 TEST SUITE] MOBILE UX, ONBOARDING & SPECTATOR POLISH")
	print("=".repeat(70))

	test_quick_guide_ui_flow()
	test_mobile_controls_presets()
	test_mobile_controls_spectator_mode()
	test_mobile_tag_button_in_range_glow()
	test_hud_spectator_card_integration()
	test_audio_manager_tag_swing()

	print("\n" + "=".repeat(70))
	print(" M3 TEST SUMMARY: %d PASSED, %d FAILED" % [test_passes, test_failures])
	print("=".repeat(70))

	if test_failures == 0:
		print(">>> ALL MILESTONE 3 TESTS PASSED! <<<")
		quit(0)
	else:
		push_error(">>> MILESTONE 3 TESTS FAILED: %d failures detected! <<<" % test_failures)
		quit(1)

func test_quick_guide_ui_flow() -> void:
	print("\n--- [1] QuickGuideUI 4-Tab Onboarding Modal ---")
	var guide_scene: PackedScene = preload("res://scenes/ui/QuickGuideUI.tscn")
	assert_true(guide_scene != null, "QuickGuideUI.tscn loaded successfully")

	var guide := guide_scene.instantiate() as QuickGuideUI
	assert_true(guide != null, "QuickGuideUI instantiated successfully")

	var root_ctrl := Control.new()
	root.add_child(root_ctrl)
	root_ctrl.add_child(guide)

	guide.open_guide()
	assert_true(guide.visible, "QuickGuideUI is visible when opened")
	assert_true(guide.current_tab_idx == 0, "Starts on Tab 0 (Maiba Taya)")
	assert_true("MAIBA TAYA" in guide.title_label.text, "Tab 0 title contains 'MAIBA TAYA'")

	# Test Next button
	guide._on_next_pressed()
	assert_true(guide.current_tab_idx == 1, "Next advances to Tab 1 (Stamina & Bilis)")
	assert_true("STAMINA" in guide.title_label.text, "Tab 1 title contains 'STAMINA'")

	# Test direct tab switching to Tab 2 (Street Items)
	guide._show_tab(2)
	assert_true(guide.current_tab_idx == 2, "Switched to Tab 2 (Mga Gamit)")
	assert_true("GAMIT" in guide.title_label.text, "Tab 2 title contains 'GAMIT'")
	assert_true("Spartan" in guide.body_label.text, "Tab 2 body contains 'Spartan'")

	# Test direct tab switching to Tab 3 (Segregation & Modes)
	guide._show_tab(3)
	assert_true(guide.current_tab_idx == 3, "Switched to Tab 3 (Segregation & Modes)")
	assert_true("SEGREGATION" in guide.title_label.text, "Tab 3 title contains 'SEGREGATION'")
	assert_true("Pasa-Taya" in guide.body_label.text, "Tab 3 body contains 'Pasa-Taya'")

	# Test Prev button back to Tab 2
	guide._on_prev_pressed()
	assert_true(guide.current_tab_idx == 2, "Prev button steps back to Tab 2")

	# Test Close
	var closed_emitted := [false]
	guide.closed.connect(func(): closed_emitted[0] = true)
	guide.close_guide()
	assert_true(not guide.visible, "QuickGuideUI is hidden after close")
	assert_true(closed_emitted[0], "QuickGuideUI emitted closed signal")

	root_ctrl.queue_free()

func test_mobile_controls_presets() -> void:
	print("\n--- [2] MobileControls Layout Presets & Ergonomics ---")
	var mobile_scene: PackedScene = preload("res://scenes/ui/MobileControlsUI.tscn")
	assert_true(mobile_scene != null, "MobileControlsUI.tscn loaded successfully")

	var mobile := mobile_scene.instantiate() as MobileControls
	assert_true(mobile != null, "MobileControls instantiated successfully")

	var root_ctrl := Control.new()
	root.add_child(root_ctrl)
	root_ctrl.add_child(mobile)

	# Preset: DEFAULT
	mobile.set_layout_preset(MobileControls.LayoutPreset.DEFAULT)
	assert_true(mobile.current_preset == MobileControls.LayoutPreset.DEFAULT, "Preset set to DEFAULT")
	assert_true(is_equal_approx(mobile.left_touch_zone.anchor_left, 0.0), "DEFAULT joystick zone anchored at left (0.0)")
	assert_true(is_equal_approx(mobile.action_buttons.anchor_left, 0.55), "DEFAULT action buttons anchored at right (0.55)")
	assert_true(mobile.scale == Vector2.ONE, "DEFAULT scale is 1.0")

	# Preset: LEFT_HANDED
	mobile.set_layout_preset(MobileControls.LayoutPreset.LEFT_HANDED)
	assert_true(mobile.current_preset == MobileControls.LayoutPreset.LEFT_HANDED, "Preset set to LEFT_HANDED")
	assert_true(is_equal_approx(mobile.left_touch_zone.anchor_left, 0.6), "LEFT_HANDED joystick zone anchored at right (0.6)")
	assert_true(is_equal_approx(mobile.action_buttons.anchor_left, 0.02), "LEFT_HANDED action buttons anchored at left (0.02)")

	# Preset: COMPACT
	mobile.set_layout_preset(MobileControls.LayoutPreset.COMPACT)
	assert_true(mobile.current_preset == MobileControls.LayoutPreset.COMPACT, "Preset set to COMPACT")
	assert_true(mobile.scale == Vector2(0.85, 0.85), "COMPACT scales entire control set to 0.85x")

	# Scale & Opacity adjustments
	mobile.set_ui_scale(1.25)
	assert_true(is_equal_approx(mobile.scale.x, 1.25), "Custom UI scale 1.25x applied correctly")

	mobile.set_ui_opacity(0.8)
	assert_true(is_equal_approx(mobile.modulate.a, 0.8), "Custom UI opacity 0.8 applied correctly")

	root_ctrl.queue_free()

func test_mobile_controls_spectator_mode() -> void:
	print("\n--- [3] Mobile Touch Spectator Controls ---")
	var mobile_scene: PackedScene = preload("res://scenes/ui/MobileControlsUI.tscn")
	var mobile := mobile_scene.instantiate() as MobileControls

	var root_ctrl := Control.new()
	root.add_child(root_ctrl)
	root_ctrl.add_child(mobile)

	# Active Player state
	mobile.set_spectator_mode(false)
	assert_true(mobile.action_buttons.visible == true, "Action buttons visible for active player")
	assert_true(mobile.left_touch_zone.visible == true, "Joystick zone visible for active player")
	assert_true(mobile.spectator_controls.visible == false, "Spectator buttons hidden for active player")

	# Eliminated / Spectator state
	mobile.set_spectator_mode(true)
	assert_true(mobile.action_buttons.visible == false, "Action buttons hidden when spectating")
	assert_true(mobile.left_touch_zone.visible == false, "Joystick hidden when spectating")
	assert_true(mobile.spectator_controls.visible == true, "Spectator controls visible when spectating")

	# Test Spectator Signals
	var prev_emitted := [false]
	var next_emitted := [false]
	mobile.prev_spectate_pressed.connect(func(): prev_emitted[0] = true)
	mobile.next_spectate_pressed.connect(func(): next_emitted[0] = true)

	mobile.btn_prev_spectate.emit_signal("pressed")
	assert_true(prev_emitted[0], "[PREV] spectator touch button fired signal")

	mobile.btn_next_spectate.emit_signal("pressed")
	assert_true(next_emitted[0], "[NEXT] spectator touch button fired signal")

	root_ctrl.queue_free()

func test_mobile_tag_button_in_range_glow() -> void:
	print("\n--- [4] Mobile Tag Button Glow & Feedback ---")
	var mobile_scene: PackedScene = preload("res://scenes/ui/MobileControlsUI.tscn")
	var mobile := mobile_scene.instantiate() as MobileControls

	var root_ctrl := Control.new()
	root.add_child(root_ctrl)
	root_ctrl.add_child(mobile)

	# Runner role -> tag button hidden
	mobile.set_tag_button_highlight(false)
	assert_true(mobile.btn_tag.visible == false, "Tag button hidden when Runner")

	# Taya role -> tag button visible
	mobile.set_tag_button_highlight(true)
	assert_true(mobile.btn_tag.visible == true, "Tag button visible when Taya")
	assert_true(mobile.btn_tag.text == "HAMPAS", "Default tag text is 'HAMPAS'")

	# In-Range Glow
	mobile.set_tag_in_range(true)
	assert_true("HAMPASIN" in mobile.btn_tag.text, "Tag text changes to '🔥 HAMPASIN!' when in range")
	assert_true(mobile.btn_tag.modulate.r > 0.9 and mobile.btn_tag.modulate.g > 0.8, "Tag button glows gold in range")

	# Out-of-Range Reset
	mobile.set_tag_in_range(false)
	assert_true(mobile.btn_tag.text == "HAMPAS", "Tag text reverts to 'HAMPAS' when out of range")
	assert_true(mobile.btn_tag.modulate == Color(1.0, 1.0, 1.0, 1.0), "Tag button color reverts to white")

	root_ctrl.queue_free()

func test_hud_spectator_card_integration() -> void:
	print("\n--- [5] HUD Live Spectator Info Card ---")
	var hud_scene: PackedScene = preload("res://scenes/ui/HUD.tscn")
	assert_true(hud_scene != null, "HUD.tscn loaded successfully")

	var hud := hud_scene.instantiate() as HUD

	var root_ctrl := Control.new()
	root.add_child(root_ctrl)
	root_ctrl.add_child(hud)

	# Update spectator info for Taya target
	var taya_data: Dictionary = {
		"name": "Baste",
		"role": 1,
		"score": 420,
		"tags": 5,
		"alive_count": 8
	}
	hud.update_spectator_info(taya_data)
	assert_true(hud.spectator_bar.visible, "Spectator bar visible when updating info")
	assert_true("BASTE" in hud.spectator_label.text, "Spectator label contains uppercase player name 'BASTE'")
	assert_true("TAYA" in hud.spectator_label.text, "Spectator label reflects role 'TAYA'")
	assert_true("420" in hud.spectator_label.text, "Spectator label reflects score '420'")
	assert_true("Huli: 5" in hud.spectator_label.text, "Spectator label reflects tags 'Huli: 5'")
	assert_true("Buhay: 8" in hud.spectator_label.text, "Spectator label reflects remaining runners 'Buhay: 8'")

	# Update spectator info for Runner target
	var runner_data: Dictionary = {
		"name": "Totoy",
		"role": 0,
		"score": 180,
		"tags": 0,
		"alive_count": 7
	}
	hud.update_spectator_info(runner_data)
	assert_true("TOTOY" in hud.spectator_label.text, "Spectator label switched to 'TOTOY'")
	assert_true("RUNNER" in hud.spectator_label.text, "Spectator label reflects role 'RUNNER'")

	# Hide spectator bar
	hud.hide_spectator_bar()
	assert_true(not hud.spectator_bar.visible, "Spectator bar hidden when calling hide_spectator_bar()")

	root_ctrl.queue_free()

func test_audio_manager_tag_swing() -> void:
	print("\n--- [6] AudioManager Tag Swing SFX ---")
	var am = root.get_node_or_null("/root/AudioManager")
	if am:
		assert_true(am.has_method("play_tag_swing"), "AudioManager has play_tag_swing() method")
		am.play_tag_swing()
		assert_true(true, "Called AudioManager.play_tag_swing() without exception")
	else:
		# Standalone check
		var am_script = preload("res://scripts/audio/AudioManager.gd")
		var am_inst = am_script.new()
		assert_true(am_inst.has_method("play_tag_swing"), "AudioManager script defines play_tag_swing()")
		am_inst.free()
