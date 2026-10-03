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

	print("\n[ALL LOBBY UI TESTS PASSED SUCCESSFULLY!]")
	quit(0)
