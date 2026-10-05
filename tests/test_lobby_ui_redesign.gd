extends SceneTree

func _init() -> void:
	print("[LobbyUI Test] Instantiating LobbyUI scene...")
	var lobby_scene: PackedScene = load("res://scenes/ui/LobbyUI.tscn")
	if not lobby_scene:
		push_error("[FAIL] Failed to load res://scenes/ui/LobbyUI.tscn")
		quit(1)
		return

	var lobby_instance = lobby_scene.instantiate()
	root.add_child(lobby_instance)

	var lobby_ui: LobbyUI = lobby_instance as LobbyUI
	if not lobby_ui:
		push_error("[FAIL] Instantiated node is not of type LobbyUI")
		quit(1)
		return
	print("[PASS] LobbyUI instantiated successfully as type LobbyUI.")

	# Ensure onready variables are initialized
	if lobby_ui.player_name_input == null:
		lobby_ui._ready()

	# 1. Verify Player Name Input (Must be empty by default, zero Dennrick)
	if lobby_ui.player_name_input == null:
		push_error("[FAIL] player_name_input is null!")
		quit(1)
		return

	var initial_name: String = lobby_ui.get_player_name()
	if not initial_name.is_empty():
		push_error("[FAIL] player_name_input should be empty by default, but got: " + initial_name)
		quit(1)
		return
	print("[PASS] player_name_input is empty by default: '" + initial_name + "'")
	print("[PASS] Placeholder text: '" + lobby_ui.player_name_input.placeholder_text + "'")

	# 2. Verify Tab Switching
	lobby_ui.switch_tab(LobbyUI.LobbyTab.BROWSE)
	if not lobby_ui.panel_lobbies.visible or lobby_ui.panel_create.visible or lobby_ui.panel_hotspot.visible:
		push_error("[FAIL] BROWSE tab visibility incorrect!")
		quit(1)
		return
	print("[PASS] Switched to BROWSE tab successfully.")

	lobby_ui.switch_tab(LobbyUI.LobbyTab.CREATE)
	if not lobby_ui.panel_create.visible or lobby_ui.panel_lobbies.visible or lobby_ui.panel_hotspot.visible:
		push_error("[FAIL] CREATE tab visibility incorrect!")
		quit(1)
		return
	print("[PASS] Switched to CREATE tab successfully.")

	lobby_ui.switch_tab(LobbyUI.LobbyTab.HOTSPOT_SOLO)
	if not lobby_ui.panel_hotspot.visible or lobby_ui.panel_lobbies.visible or lobby_ui.panel_create.visible:
		push_error("[FAIL] HOTSPOT_SOLO tab visibility incorrect!")
		quit(1)
		return
	print("[PASS] Switched to HOTSPOT_SOLO tab successfully.")

	# 3. Verify Character Preview Info update
	lobby_ui.update_character_info(2, "Totoy", "Sando Runner")
	if lobby_ui.char_name_label.text != "Totoy ✎":
		push_error("[FAIL] Character name label mismatch: " + lobby_ui.char_name_label.text)
		quit(1)
		return
	if lobby_ui.char_count_label.text != "3 / 8":
		push_error("[FAIL] Character count label mismatch: " + lobby_ui.char_count_label.text)
		quit(1)
		return
	if lobby_ui.char_desc_label.text != "👕 Sando Runner":
		push_error("[FAIL] Character desc label mismatch: " + lobby_ui.char_desc_label.text)
		quit(1)
		return
	print("[PASS] Character info updated successfully for Totoy (3/8).")

	# 4. Verify Color Swatches & Dots
	var test_colors: Array[Dictionary] = [
		{ "name": "Dilaw", "color": Color(1.0, 0.85, 0.2) },
		{ "name": "Asul", "color": Color(0.2, 0.55, 0.95) },
		{ "name": "Pula", "color": Color(0.95, 0.25, 0.25) }
	]
	lobby_ui.set_color_swatches(test_colors, 0)
	if lobby_ui.palette_container.get_child_count() != 3:
		push_error("[FAIL] Palette container children count mismatch: " + str(lobby_ui.palette_container.get_child_count()))
		quit(1)
		return
	if lobby_ui.palette_dots_container.get_child_count() != 3:
		push_error("[FAIL] Palette dots container children count mismatch: " + str(lobby_ui.palette_dots_container.get_child_count()))
		quit(1)
		return
	print("[PASS] Color swatches and indicator dots generated successfully.")

	# 5. Verify Room Waiting State
	lobby_ui.set_room_waiting_state(true, true, "Laro sa Kanto", { 1: { "name": "HostPlayer" }, 2: { "name": "Client1" } })
	if not lobby_ui.panel_room_waiting.visible:
		push_error("[FAIL] Room waiting panel not visible!")
		quit(1)
		return
	if lobby_ui.room_slots_container.get_child_count() != 8:
		push_error("[FAIL] Room slots count mismatch: " + str(lobby_ui.room_slots_container.get_child_count()))
		quit(1)
		return
	print("[PASS] Room waiting slots populated (8 slots) successfully.")

	# 6. Verify Online Lobbies Population
	var mock_lobbies: Array[Dictionary] = [
		{ "name": "Tumbang Preso Room", "host_name": "Baldo", "game_mode": "Pasa-Taya", "player_count": 3, "max_players": 8 }
	]
	lobby_ui.populate_online_lobbies(mock_lobbies)
	if lobby_ui.lobby_list_container.get_child_count() != 1:
		push_error("[FAIL] Lobby list count mismatch: " + str(lobby_ui.lobby_list_container.get_child_count()))
		quit(1)
		return
	print("[PASS] Online lobbies dynamic list rendered successfully.")

	# 7. Verify Solo Practice Signal Emission
	var signal_box: Array[bool] = [false]
	lobby_ui.solo_practice_requested.connect(func(): signal_box[0] = true)
	lobby_ui.btn_solo_practice.pressed.emit()
	if not signal_box[0]:
		push_error("[FAIL] solo_practice_requested signal not emitted from button!")
		quit(1)
		return
	print("[PASS] btn_solo_practice emitted solo_practice_requested successfully.")

	# 8. Verify Mobile Touch Target Dimensions
	var first_swatch: Button = lobby_ui.palette_container.get_child(0) as Button
	if first_swatch == null or first_swatch.custom_minimum_size.x < 44.0 or first_swatch.custom_minimum_size.y < 44.0:
		push_error("[FAIL] Palette swatch touch target size too small: " + str(first_swatch.custom_minimum_size if first_swatch else "null"))
		quit(1)
		return
	print("[PASS] Color swatch touch size is finger-friendly: " + str(first_swatch.custom_minimum_size))

	if lobby_ui.btn_prev_char.custom_minimum_size.x < 50.0 or lobby_ui.btn_prev_char.custom_minimum_size.y < 50.0:
		push_error("[FAIL] btn_prev_char size too small: " + str(lobby_ui.btn_prev_char.custom_minimum_size))
		quit(1)
		return
	if lobby_ui.btn_next_char.custom_minimum_size.x < 50.0 or lobby_ui.btn_next_char.custom_minimum_size.y < 50.0:
		push_error("[FAIL] btn_next_char size too small: " + str(lobby_ui.btn_next_char.custom_minimum_size))
		quit(1)
		return
	print("[PASS] 3D character preview navigation buttons are enlarged for touch (>=50x50): " + str(lobby_ui.btn_prev_char.custom_minimum_size))

	if lobby_ui.btn_start_game.custom_minimum_size.y < 54.0:
		push_error("[FAIL] btn_start_game height too small: " + str(lobby_ui.btn_start_game.custom_minimum_size))
		quit(1)
		return
	print("[PASS] Hero CTA start button height is mobile-ready (>=54px): " + str(lobby_ui.btn_start_game.custom_minimum_size))

	if lobby_ui.btn_tab_hotspot.custom_minimum_size.y < 44.0:
		push_error("[FAIL] Tab button height too small: " + str(lobby_ui.btn_tab_hotspot.custom_minimum_size))
		quit(1)
		return
	print("[PASS] Tab button height is mobile-ready (>=44px): " + str(lobby_ui.btn_tab_hotspot.custom_minimum_size))

	# 9. Verify Touch Swipe on Character Preview Viewport
	var swipe_prev_fired: Array[bool] = [false]
	var swipe_next_fired: Array[bool] = [false]
	lobby_ui.prev_char_requested.connect(func(): swipe_prev_fired[0] = true)
	lobby_ui.next_char_requested.connect(func(): swipe_next_fired[0] = true)

	# Simulate Swipe Right -> Prev
	var touch_down := InputEventScreenTouch.new()
	touch_down.index = 0
	touch_down.pressed = true
	touch_down.position = Vector2(100, 100)
	lobby_ui._on_viewport_frame_input(touch_down)

	var touch_drag_right := InputEventScreenDrag.new()
	touch_drag_right.index = 0
	touch_drag_right.position = Vector2(160, 100) # +60px right
	lobby_ui._on_viewport_frame_input(touch_drag_right)

	var touch_up := InputEventScreenTouch.new()
	touch_up.index = 0
	touch_up.pressed = false
	touch_up.position = Vector2(160, 100)
	lobby_ui._on_viewport_frame_input(touch_up)

	if not swipe_prev_fired[0]:
		push_error("[FAIL] Swipe right did not fire prev_char_requested signal!")
		quit(1)
		return
	print("[PASS] Swipe right gesture correctly triggered prev_char_requested.")

	# Simulate Swipe Left -> Next
	touch_down.position = Vector2(200, 100)
	lobby_ui._on_viewport_frame_input(touch_down)

	var touch_drag_left := InputEventScreenDrag.new()
	touch_drag_left.index = 0
	touch_drag_left.position = Vector2(130, 100) # -70px left
	lobby_ui._on_viewport_frame_input(touch_drag_left)

	lobby_ui._on_viewport_frame_input(touch_up)

	if not swipe_next_fired[0]:
		push_error("[FAIL] Swipe left did not fire next_char_requested signal!")
		quit(1)
		return
	print("[PASS] Swipe left gesture correctly triggered next_char_requested.")

	# Test that continuous drag in a single touch gesture does not double-fire
	swipe_next_fired[0] = false
	var touch_down2 := InputEventScreenTouch.new()
	touch_down2.index = 0
	touch_down2.pressed = true
	touch_down2.position = Vector2(300, 100)
	lobby_ui._on_viewport_frame_input(touch_down2)

	var drag1 := InputEventScreenDrag.new()
	drag1.index = 0
	drag1.position = Vector2(240, 100) # -60px left -> triggers swipe
	lobby_ui._on_viewport_frame_input(drag1)

	if not swipe_next_fired[0]:
		push_error("[FAIL] Swipe did not fire on initial drag beyond threshold!")
		quit(1)
		return

	swipe_next_fired[0] = false
	# Drag further in same gesture without releasing finger (-120px)
	var drag2 := InputEventScreenDrag.new()
	drag2.index = 0
	drag2.position = Vector2(180, 100)
	lobby_ui._on_viewport_frame_input(drag2)

	if swipe_next_fired[0]:
		push_error("[FAIL] Swipe fired multiple times in a single continuous touch gesture!")
		quit(1)
		return
	print("[PASS] Continuous drag in single swipe gesture does not double-fire.")

	var touch_up2 := InputEventScreenTouch.new()
	touch_up2.index = 0
	touch_up2.pressed = false
	touch_up2.position = Vector2(180, 100)
	lobby_ui._on_viewport_frame_input(touch_up2)

	# 10. Verify Character Navigation Button Press in Main scene (1-step increment, no skipping)
	var main_scene = load("res://scenes/main/Main.tscn")
	if not main_scene:
		push_error("[FAIL] Could not load Main.tscn!")
		quit(1)
		return
	var main_node = main_scene.instantiate()
	root.add_child(main_node)

	var main_lobby_ui = main_node.get_node_or_null("LobbyUI") as LobbyUI
	if not main_lobby_ui:
		push_error("[FAIL] LobbyUI not found in Main.tscn!")
		quit(1)
		return

	# Force archetype to known index 0
	main_node._select_preset(0)
	if main_node.current_archetype != 0:
		push_error("[FAIL] Could not set current_archetype to 0!")
		quit(1)
		return

	# Press next button 7 times, checking that every single archetype (1..7) is visited one by one!
	for expected_idx in range(1, 8):
		main_lobby_ui.btn_next_char.pressed.emit()
		if main_node.current_archetype != expected_idx:
			push_error("[FAIL] Pressing Next skipped! Expected %d but got %d" % [expected_idx, main_node.current_archetype])
			quit(1)
			return

	print("[PASS] Pressing Next button cycles through archetypes 1-by-1 without skipping (0 -> 1 -> 2 -> 3 -> 4 -> 5 -> 6 -> 7).")

	# Press prev button 7 times, checking that it decrements one by one!
	for expected_idx in range(6, -1, -1):
		main_lobby_ui.btn_prev_char.pressed.emit()
		if main_node.current_archetype != expected_idx:
			push_error("[FAIL] Pressing Prev skipped! Expected %d but got %d" % [expected_idx, main_node.current_archetype])
			quit(1)
			return

	print("[PASS] Pressing Prev button cycles backwards 1-by-1 without skipping (7 -> 6 -> 5 -> 4 -> 3 -> 2 -> 1 -> 0).")

	print("\n[ALL LOBBY UI TESTS PASSED SUCCESSFULLY!]")
	quit(0)
