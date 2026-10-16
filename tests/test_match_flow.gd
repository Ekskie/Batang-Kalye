extends SceneTree

# ==============================================================================
# test_match_flow.gd
# Verification suite for Bot Lobby Management (+/- Bot), Lobby Slot Sync,
# and Match Start Bot Spawning Architecture
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
	print(" [MATCH FLOW & MULTIPLAYER BOT BACKFILL VERIFICATION SUITE] ")
	print("======================================================================")

	await _test_network_manager_bot_operations()
	await _test_lobby_ui_bot_controls_and_invariants()
	await _test_lobby_ui_slot_sync_and_bot_badging()
	await _test_game_manager_bot_match_spawning()
	await _test_bot_boundaries_and_erasure()
	await _test_google_play_export_presets()

	print("\n======================================================================")
	print(" SUITE SUMMARY: %d Passed, %d Failed" % [passed, failed])
	print("======================================================================")
	if failed == 0:
		print(" ALL MATCH FLOW & BOT BACKFILL VERIFICATIONS PASSED!")
		quit(0)
	else:
		push_error(" MATCH FLOW VERIFICATION SUITE COMPLETED WITH FAILURES.")
		quit(1)

func _test_network_manager_bot_operations() -> void:
	print("\n--- 1. Testing NetworkManager Bot State Management ---")
	var nm := NetworkManager.new()
	root.add_child(nm)

	nm.is_host = true
	nm.players[1] = {
		"name": "HostPlayer",
		"score": 0,
		"role": 0,
		"is_bot": false
	}

	assert_eq(nm.get_bot_count(), 0, "Initial bot count is 0")

	# Add first bot
	var bot1_id := nm.add_bot()
	assert_eq(bot1_id, 90, "First bot assigned ID 90 (BOT_ID_BASE)")
	assert_eq(nm.get_bot_count(), 1, "Bot count is 1 after add_bot")
	assert_true(nm.players.has(90), "nm.players contains bot 90")
	assert_true(nm.players[90].get("is_bot", false), "Bot player marked with is_bot = true")
	assert_true(nm.players[90].get("name", "") != "", "Bot assigned a valid name (%s)" % nm.players[90].get("name", ""))

	# Add second bot
	var bot2_id := nm.add_bot()
	assert_eq(bot2_id, 91, "Second bot assigned ID 91")
	assert_eq(nm.get_bot_count(), 2, "Bot count is 2 after second add_bot")

	# Add third bot
	var bot3_id := nm.add_bot()
	assert_eq(bot3_id, 92, "Third bot assigned ID 92")
	assert_eq(nm.get_bot_count(), 3, "Bot count is 3 after third add_bot")

	# Remove most recent bot
	var removed := nm.remove_bot()
	assert_true(removed, "remove_bot succeeded")
	assert_eq(nm.get_bot_count(), 2, "Bot count is 2 after remove_bot")
	assert_true(not nm.players.has(92), "Bot 92 removed from nm.players")
	assert_true(nm.players.has(90) and nm.players.has(91), "Bots 90 and 91 retained")

	# Non-host protection
	nm.is_host = false
	var blocked_bot_id := nm.add_bot()
	assert_eq(blocked_bot_id, -1, "Non-host peer cannot add bots")
	var blocked_remove := nm.remove_bot()
	assert_true(not blocked_remove, "Non-host peer cannot remove bots")

	# Cleanup
	nm.queue_free()
	await process_frame

func _test_lobby_ui_bot_controls_and_invariants() -> void:
	print("\n--- 2. Testing 2D LobbyUI Bot Controls Removal & 3D BotStation Integration ---")
	var lobby_scene: PackedScene = load("res://scenes/ui/LobbyUI.tscn")
	assert_true(lobby_scene != null, "LobbyUI.tscn loaded")
	if not lobby_scene:
		return

	var lobby_ui: LobbyUI = lobby_scene.instantiate() as LobbyUI
	root.add_child(lobby_ui)
	await process_frame
	await process_frame

	# Verification that obsolete 2D bot buttons have been cleanly removed from LobbyUI
	assert_true(lobby_ui.get("btn_add_bot") == null, "btn_add_bot removed from 2D LobbyUI (obsolete)")
	assert_true(lobby_ui.get("btn_remove_bot") == null, "btn_remove_bot removed from 2D LobbyUI (obsolete)")
	assert_true(lobby_ui.get("bot_controls_row") == null, "bot_controls_row removed from 2D LobbyUI (obsolete)")
	assert_true(not ("btn_add_bot" in lobby_ui), "btn_add_bot member absent from LobbyUI")
	assert_true(not ("btn_remove_bot" in lobby_ui), "btn_remove_bot member absent from LobbyUI")
	assert_true(not ("bot_controls_row" in lobby_ui), "bot_controls_row member absent from LobbyUI")

	# Ensure room_slots_container exists for slot generation verification
	if not lobby_ui.room_slots_container:
		var mock_container := VBoxContainer.new()
		mock_container.name = "SlotsContainer"
		lobby_ui.add_child(mock_container)
		lobby_ui.room_slots_container = mock_container

	# Populate room slots via set_room_waiting_state
	lobby_ui.set_room_waiting_state(true, true, "Tambayan Room", {}, 24)

	# STRICT INVARIANT: room_slots_container must have exactly 24 children
	assert_eq(lobby_ui.room_slots_container.get_child_count(), 24, "room_slots_container contains exactly 24 slot nodes (invariant)")

	lobby_ui.queue_free()
	await process_frame

	# Verify 3D Physical Bot Station (Roblox-style touch/interact pad) in 3D enclosed court
	var bot_station_scene: PackedScene = load("res://scenes/gameplay/BotStation3D.tscn")
	assert_true(bot_station_scene != null, "BotStation3D.tscn loaded successfully")
	if bot_station_scene:
		var bot_station = bot_station_scene.instantiate()
		root.add_child(bot_station)
		await process_frame

		assert_true(bot_station.get_node_or_null("StationPedestal") != null, "StationPedestal exists in BotStation3D")
		assert_true(bot_station.get_node_or_null("StationPedestal/PressurePad") != null, "PressurePad exists in BotStation3D")
		assert_true(bot_station.get_node_or_null("BorderRing") != null, "BorderRing exists in BotStation3D")
		assert_true(bot_station.get_node_or_null("StationLight") != null, "StationLight exists in BotStation3D")
		assert_true(bot_station.get_node_or_null("LabelTitle") != null, "LabelTitle 3D billboard exists")
		assert_true(bot_station.get_node_or_null("LabelBotCount") != null, "LabelBotCount 3D billboard exists")
		assert_true(bot_station.get_node_or_null("LabelStatus") != null, "LabelStatus 3D billboard exists")
		assert_true(bot_station.get_node_or_null("LabelPrompt") != null, "LabelPrompt 3D billboard exists")
		assert_true(bot_station.has_method("interact"), "BotStation3D supports interact() [E / Tap]")
		assert_true(bot_station.has_method("get_interaction_action"), "BotStation3D implements get_interaction_action()")
		assert_true(bot_station.has_method("trigger_bot_adjustment"), "BotStation3D implements trigger_bot_adjustment()")

		# Test mock adjustment / cycling
		assert_eq(bot_station.get_bot_count(), 0, "BotStation3D starts with 0 bots")
		bot_station.interact()
		assert_eq(bot_station.get_bot_count(), 1, "Interacting with BotStation3D increments bot count to 1")
		var lbl_count = bot_station.get_node_or_null("LabelBotCount")
		assert_true(lbl_count != null and lbl_count.text == "1 BOTS", "3D LabelBotCount updated to 1 BOTS")

		bot_station.queue_free()
		await process_frame

func _test_lobby_ui_slot_sync_and_bot_badging() -> void:
	print("\n--- 3. Testing LobbyUI Slot Synchronization & [BOT] Badging ---")
	var lobby_scene: PackedScene = load("res://scenes/ui/LobbyUI.tscn")
	var lobby_ui: LobbyUI = lobby_scene.instantiate() as LobbyUI
	root.add_child(lobby_ui)
	await process_frame

	if not lobby_ui.room_slots_container:
		var mock_container := VBoxContainer.new()
		mock_container.name = "SlotsContainer"
		lobby_ui.add_child(mock_container)
		lobby_ui.room_slots_container = mock_container

	var players_data: Dictionary = {
		1: { "name": "Kapitan", "is_bot": false },
		90: { "name": "Baldo", "is_bot": true },
		91: { "name": "Totoy", "is_bot": true }
	}

	lobby_ui.set_room_waiting_state(true, true, "Tambayan Room", players_data, 24)

	var slot1 = lobby_ui.room_slots_container.get_child(0) as Label
	var slot2 = lobby_ui.room_slots_container.get_child(1) as Label
	var slot3 = lobby_ui.room_slots_container.get_child(2) as Label
	var slot4 = lobby_ui.room_slots_container.get_child(3) as Label

	assert_true("[HOST]" in slot1.text, "Slot 1 shows [HOST] tag for host player")
	assert_true("[BOT]" in slot2.text, "Slot 2 shows [BOT] badge for bot 90 (Baldo)")
	assert_true("Baldo" in slot2.text, "Slot 2 shows bot name Baldo")
	assert_true("[BOT]" in slot3.text, "Slot 3 shows [BOT] badge for bot 91 (Totoy)")
	assert_true("Bakante" in slot4.text, "Slot 4 shows empty/bakante")

	lobby_ui.queue_free()
	await process_frame

func _test_game_manager_bot_match_spawning() -> void:
	print("\n--- 4. Testing GameManager Match Start Bot Spawning & Authority ---")
	var main_scene: PackedScene = load("res://scenes/main/Main.tscn")
	var gm_node: Node = main_scene.instantiate()
	root.add_child(gm_node)
	await process_frame
	await process_frame

	var gm: GameManager = gm_node as GameManager
	assert_true(gm != null, "GameManager instantiated")
	if not gm:
		return

	# Setup network manager state with host human and bot
	var nm = gm.network_manager
	nm.is_host = true
	nm.players.clear()
	nm.players[1] = {
		"name": "HostPlayer",
		"score": 0,
		"role": 0,
		"is_bot": false,
		"character": 0,
		"color_idx": 0
	}
	nm.players[90] = {
		"name": "Totoy",
		"score": 0,
		"role": 0,
		"is_bot": true,
		"character": 1,
		"color_idx": 2
	}

	# Spawn human player (ID 1)
	var human_player: PlayerController = gm._spawn_single_player(1, 0)
	assert_true(human_player != null, "Human player spawned")
	assert_true(not human_player.is_bot, "Human player has is_bot = false")
	assert_true(not (human_player is PracticeBot), "Human player is NOT PracticeBot instance")

	# Spawn bot player (ID 90)
	var bot_player: PlayerController = gm._spawn_single_player(90, 1)
	assert_true(bot_player != null, "Bot player spawned")
	assert_true(bot_player.is_bot, "Bot player has is_bot = true")
	assert_true(bot_player is PracticeBot, "Bot player instantiated as PracticeBot")
	assert_eq(bot_player.get_multiplayer_authority(), 1, "Bot player has multiplayer authority set to host (1)")

	# Test lobby bot add/remove callbacks
	var initial_count := nm.get_bot_count()
	gm._on_lobby_add_bot_requested()
	assert_eq(nm.get_bot_count(), initial_count + 1, "GameManager _on_lobby_add_bot_requested increments bot count")

	gm._on_lobby_remove_bot_requested()
	assert_eq(nm.get_bot_count(), initial_count, "GameManager _on_lobby_remove_bot_requested decrements bot count")

	gm_node.queue_free()
	await process_frame

func _test_bot_boundaries_and_erasure() -> void:
	print("\n--- 5. Testing Bot Capacity Boundaries & Key Erasure Robustness ---")
	var nm := NetworkManager.new()
	root.add_child(nm)
	nm.is_host = true
	nm.players.clear()
	nm.players[1] = { "name": "Host", "is_bot": false }

	# Fill bots up to MAX_PLAYERS (23 bots + 1 host = 24 players)
	var added_ids: Array[int] = []
	for i in range(23):
		var bid := nm.add_bot()
		assert_true(bid > 0, "Bot %d added successfully (ID %d)" % [i + 1, bid])
		added_ids.append(bid)

	assert_eq(nm.players.size(), 24, "Lobby is full at MAX_PLAYERS (24)")
	assert_eq(nm.get_bot_count(), 23, "Bot count is exactly 23")

	# Attempting to add 24th bot beyond MAX_PLAYERS must fail gracefully
	var overflow_bid := nm.add_bot()
	assert_eq(overflow_bid, -1, "add_bot returns -1 when room is full at MAX_PLAYERS")
	assert_eq(nm.players.size(), 24, "Room size does not exceed MAX_PLAYERS")

	# Test mixed string and integer key erasure robustness in remove_bot
	nm.players.clear()
	nm.players[1] = { "name": "Host", "is_bot": false }
	nm.players["99"] = { "name": "StringKeyBot", "is_bot": true }
	var string_key_bot_count := nm.get_bot_count()
	var remove_res := nm.remove_bot()
	assert_true(remove_res, "remove_bot succeeds when bot key is stored as string")
	assert_true(not nm.players.has("99") and not nm.players.has(99), "String key bot cleanly erased from dictionary")
	assert_eq(nm.get_bot_count(), string_key_bot_count - 1, "Bot count decremented after string key bot removal")

	nm.queue_free()
	await process_frame

func _test_google_play_export_presets() -> void:
	print("\n--- 6. Testing Google Play Store Export Presets Specification ---")
	var cfg := ConfigFile.new()
	var err := cfg.load("res://export_presets.cfg")
	assert_eq(err, OK, "export_presets.cfg loads cleanly")
	if err != OK:
		return

	# Android Preset checks
	assert_eq(cfg.get_value("preset.0", "name", ""), "Android", "Preset 0 is named 'Android'")
	assert_eq(cfg.get_value("preset.0", "platform", ""), "Android", "Preset 0 platform is 'Android'")
	assert_eq(cfg.get_value("preset.0.options", "package/unique_name", ""), "com.fieryfox.batangkalye", "Android package unique name is 'com.fieryfox.batangkalye'")
	assert_eq(cfg.get_value("preset.0.options", "package/name", ""), "Batang Kalye", "Android application name is 'Batang Kalye'")
	assert_eq(cfg.get_value("preset.0.options", "gradle_build/target_sdk", ""), "34", "Android target SDK is 34 (Google Play compliance)")
	assert_eq(cfg.get_value("preset.0.options", "gradle_build/export_format", -1), 1, "Android export format is 1 (.aab App Bundle)")
	assert_true(bool(cfg.get_value("preset.0.options", "gradle_build/use_gradle_build", false)), "Android preset has use_gradle_build enabled for AAB generation")

	# Windows Desktop Preset checks
	assert_eq(cfg.get_value("preset.2", "name", ""), "Windows Desktop", "Preset 2 is named 'Windows Desktop'")
	assert_true(bool(cfg.get_value("preset.2", "runnable", false)), "Windows Desktop preset is runnable")

	# Linux Dedicated Server Preset checks
	assert_eq(cfg.get_value("preset.3", "name", ""), "Linux Dedicated Server", "Preset 3 is named 'Linux Dedicated Server'")
	assert_true(bool(cfg.get_value("preset.3", "dedicated_server", false)), "Linux preset is configured as dedicated server")
