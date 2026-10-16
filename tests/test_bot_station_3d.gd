extends SceneTree

# ==============================================================================
# test_bot_station_3d.gd
# Verification suite for 3D Physical Bot Station & Roblox-Style Touch/Interact Pad
# in Enclosed 3D Court Lobby
# ==============================================================================

const BotStationScript = preload("res://scripts/gameplay/BotStation3D.gd")
const NetworkManagerScript = preload("res://scripts/network/NetworkManager.gd")
const PlayerControllerScript = preload("res://scripts/player/PlayerController.gd")

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
	print(" [3D PHYSICAL BOT STATION & ROBLOX-STYLE TOUCH PAD VERIFICATION SUITE] ")
	print("======================================================================")

	await _test_scene_structure_and_components()
	await _test_touch_and_interact_mechanics()
	await _test_visual_feedback_and_cycling()
	await _test_network_manager_integration()
	await _test_kalyemap_court_integration()
	await _test_rpc_sync_and_server_debounce()

	print("\n======================================================================")
	print(" BOT STATION 3D SUMMARY: %d PASSED, %d FAILED" % [passed, failed])
	print("======================================================================")

	if failed == 0:
		print(">>> ALL 3D BOT STATION & TOUCH PAD TESTS PASSED! <<<\n")
		quit(0)
	else:
		printerr(">>> SOME 3D BOT STATION TESTS FAILED! <<<\n")
		quit(1)

func _test_scene_structure_and_components() -> void:
	print("\n--- 1. Testing BotStation3D Scene Structure & Visual Nodes ---")
	var scene: PackedScene = load("res://scenes/gameplay/BotStation3D.tscn")
	assert_true(scene != null, "BotStation3D.tscn loads successfully")
	if not scene:
		return

	var station = scene.instantiate()
	root.add_child(station)
	await process_frame

	assert_true(station.get_node_or_null("Podium") != null, "Podium base exists")
	assert_true(station.get_node_or_null("BorderRing") != null, "BorderRing glowing frame exists")
	assert_true(station.get_node_or_null("StationPedestal") != null, "StationPedestal exists")
	assert_true(station.get_node_or_null("StationPedestal/PressurePad") != null, "Roblox touch PressurePad exists")
	assert_true(station.get_node_or_null("StationLight") != null, "StationLight exists")
	assert_true(station.get_node_or_null("TriggerArea") != null, "TriggerArea Area3D exists")

	# 3D floating billboard labels
	var l_title: Label3D = station.get_node_or_null("LabelTitle")
	var l_count: Label3D = station.get_node_or_null("LabelBotCount")
	var l_status: Label3D = station.get_node_or_null("LabelStatus")
	var l_prompt: Label3D = station.get_node_or_null("LabelPrompt")
	assert_true(l_title != null and l_title.billboard == BaseMaterial3D.BILLBOARD_ENABLED, "LabelTitle is 3D billboarded")
	assert_true(l_count != null and l_count.billboard == BaseMaterial3D.BILLBOARD_ENABLED, "LabelBotCount is 3D billboarded")
	assert_true(l_status != null and l_status.billboard == BaseMaterial3D.BILLBOARD_ENABLED, "LabelStatus is 3D billboarded")
	assert_true(l_prompt != null and l_prompt.billboard == BaseMaterial3D.BILLBOARD_ENABLED, "LabelPrompt is 3D billboarded")

	station.queue_free()
	await process_frame

func _test_touch_and_interact_mechanics() -> void:
	print("\n--- 2. Testing Roblox-Style Touch Pad & PlayerController Interact ---")
	var station = BotStationScript.new()
	root.add_child(station)
	station.max_bots = 5
	await process_frame

	# Setup mock labels
	var l_count := Label3D.new()
	station.label_bot_count = l_count
	station.add_child(l_count)

	var l_status := Label3D.new()
	station.label_status = l_status
	station.add_child(l_status)

	var l_prompt := Label3D.new()
	station.label_prompt = l_prompt
	station.add_child(l_prompt)

	# Initial state
	assert_eq(station.get_bot_count(), 0, "Initial bot count is 0")
	assert_eq(station.get_interaction_icon(), "🤖", "Interaction icon is 🤖")
	assert_eq(station.get_interaction_action(), "MAGDAGDAG NG BOT (+1)", "Interaction action is +1")

	# Interact press
	station.interact()
	assert_eq(station.get_bot_count(), 1, "interact() incremented bot count to 1")

	# Second press
	station.interact()
	assert_eq(station.get_bot_count(), 2, "Second interact() incremented bot count to 2")

	# Touch step simulation with mock player
	var player = PlayerControllerScript.new()
	player.name = "1"
	root.add_child(player)
	await process_frame

	station.debounce_timer = 0.0
	station._on_body_entered(player)
	assert_true(station.is_local_player_inside, "Local player marked as inside pad trigger")
	assert_eq(station.get_bot_count(), 3, "Stepping onto pad incremented bot count to 3")

	# Debounce protection: immediate subsequent body event while inside is blocked
	station._on_body_entered(player)
	assert_eq(station.get_bot_count(), 3, "Debounce timer blocks duplicate immediate triggers")

	# Exit pad
	station._on_body_exited(player)
	assert_true(not station.is_local_player_inside, "Player marked as exited pad")

	player.queue_free()
	station.queue_free()
	await process_frame

func _test_visual_feedback_and_cycling() -> void:
	print("\n--- 3. Testing 3D Visual Feedback, Max Bounds & Cycling ---")
	var station = BotStationScript.new()
	root.add_child(station)
	station.max_bots = 3
	await process_frame

	var l_count := Label3D.new()
	station.label_bot_count = l_count
	station.add_child(l_count)

	var l_status := Label3D.new()
	station.label_status = l_status
	station.add_child(l_status)

	var l_prompt := Label3D.new()
	station.label_prompt = l_prompt
	station.add_child(l_prompt)

	station._update_display()
	assert_eq(l_count.text, "0 BOTS", "Display shows '0 BOTS'")

	# Step 1 -> 1
	station.trigger_bot_adjustment()
	assert_eq(station.get_bot_count(), 1, "Count is 1")
	assert_eq(l_count.text, "1 BOTS", "Display shows '1 BOTS'")
	assert_eq(l_status.text, "Lobby: 1 / 3 Bots", "Status shows 'Lobby: 1 / 3 Bots'")

	# Step 2 -> 2
	station.trigger_bot_adjustment()
	assert_eq(station.get_bot_count(), 2, "Count is 2")
	assert_eq(l_count.text, "2 BOTS", "Display shows '2 BOTS'")

	# Step 3 -> 3 (Max)
	station.trigger_bot_adjustment()
	assert_eq(station.get_bot_count(), 3, "Count is 3 (Max)")
	assert_eq(l_count.text, "3 BOTS", "Display shows '3 BOTS'")
	assert_eq(l_count.modulate, station.active_color, "LabelBotCount modulated with active_color at max")
	assert_eq(station.get_interaction_action(), "I-RESET ANG MGA BOT (0)", "Prompt changed to reset at max")

	# Step 4 -> Cycle back to 0
	station.trigger_bot_adjustment()
	assert_eq(station.get_bot_count(), 0, "Count cycled back to 0 after max")
	assert_eq(l_count.text, "0 BOTS", "Display reset to '0 BOTS'")
	assert_eq(station.get_interaction_action(), "MAGDAGDAG NG BOT (+1)", "Prompt restored to +1")

	station.queue_free()
	await process_frame

func _test_network_manager_integration() -> void:
	print("\n--- 4. Testing NetworkManager Real-Time Sync Integration ---")
	var nm = NetworkManagerScript.new()
	nm.name = "NetworkManager"
	nm.is_host = true
	root.add_child(nm)

	var station = BotStationScript.new()
	station.name = "BotStation"
	station.max_bots = 10
	root.add_child(station)
	await process_frame

	var l_count := Label3D.new()
	station.label_bot_count = l_count
	station.add_child(l_count)

	var l_status := Label3D.new()
	station.label_status = l_status
	station.add_child(l_status)

	var l_prompt := Label3D.new()
	station.label_prompt = l_prompt
	station.add_child(l_prompt)

	station._find_managers()
	station._update_display()

	assert_eq(station.network_manager, nm, "Station located NetworkManager")
	assert_eq(station.get_bot_count(), 0, "Bot count starts at 0")

	# Adding bot via station adds to NetworkManager
	station.trigger_bot_adjustment()
	assert_eq(nm.get_bot_count(), 1, "nm.get_bot_count() is 1")
	assert_eq(station.get_bot_count(), 1, "station.get_bot_count() matches nm")
	assert_true(nm.players.has(NetworkManager.BOT_ID_BASE), "NetworkManager has bot 90")

	# External bot addition emits player_list_updated and updates station
	nm.add_bot()
	await process_frame
	assert_eq(station.get_bot_count(), 2, "Station updated via player_list_updated signal")
	assert_eq(l_count.text, "2 BOTS", "Label shows 2 BOTS")

	# Reset bots via station
	station.reset_bots()
	assert_eq(nm.get_bot_count(), 0, "All bots cleanly cleared from nm")
	assert_eq(station.get_bot_count(), 0, "Station reflects 0 bots")

	station.queue_free()
	nm.queue_free()
	await process_frame

func _test_kalyemap_court_integration() -> void:
	print("\n--- 5. Testing KalyeMap Court 3D Bot Station Node Integration ---")
	var map_scene: PackedScene = load("res://scenes/maps/KalyeMap.tscn")
	assert_true(map_scene != null, "KalyeMap.tscn loaded")
	if not map_scene:
		return

	var map = map_scene.instantiate()
	root.add_child(map)
	await process_frame

	var court = map.get_node_or_null("Ground/BarangayBasketballCourt")
	assert_true(court != null, "BarangayBasketballCourt found in KalyeMap")

	var bot_station = court.get_node_or_null("BotStation")
	assert_true(bot_station != null, "BotStation node instantiated in BarangayBasketballCourt")
	assert_true(bot_station is BotStationScript, "BotStation is instance of BotStationScript")

	# Verify position within court bounds and not overlapping voting stations
	var station_pos: Vector3 = bot_station.position
	assert_true(station_pos.x > -13.0 and station_pos.x < 13.0, "BotStation X is within court floor bounds")
	assert_true(station_pos.z > -17.0 and station_pos.z < 17.0, "BotStation Z is within court floor bounds")

	var buzzer = court.get_node_or_null("VotingStartButton")
	if buzzer:
		var d = station_pos.distance_to(buzzer.position)
		assert_true(d >= 3.0, "BotStation does not overlap VotingStartButton (dist=%.2fm)" % d)

	map.queue_free()
	await process_frame

func _test_rpc_sync_and_server_debounce() -> void:
	print("\n--- 6. Testing BotStation3D Multiplayer RPC Sync & Server Debounce ---")
	var station = BotStationScript.new()
	station.name = "BotStation"
	station.max_bots = 5
	root.add_child(station)
	await process_frame

	var l_count := Label3D.new()
	station.label_bot_count = l_count
	station.add_child(l_count)

	var l_status := Label3D.new()
	station.label_status = l_status
	station.add_child(l_status)

	var l_prompt := Label3D.new()
	station.label_prompt = l_prompt
	station.add_child(l_prompt)

	# 1. Test request_adjust_bots with debounce
	station.debounce_timer = 0.0
	station.request_adjust_bots()
	assert_eq(station.get_bot_count(), 1, "First request_adjust_bots increments bot count to 1")
	assert_true(station.debounce_timer > 0.0, "Server debounce timer active after request")

	# Immediate second call is blocked by debounce
	station.request_adjust_bots()
	assert_eq(station.get_bot_count(), 1, "Immediate second request_adjust_bots blocked by server debounce")

	# 2. Test sync_bot_feedback with various feedback types
	station.sync_bot_feedback(3, 0) # ADDED
	assert_eq(station.get_bot_count(), 3, "sync_bot_feedback sets bot count to 3")
	assert_eq(l_count.text, "3 BOTS", "sync_bot_feedback updates LabelBotCount")

	station.sync_bot_feedback(0, 1) # RESET
	assert_eq(station.get_bot_count(), 0, "sync_bot_feedback resets count to 0")

	station.sync_bot_feedback(0, 2) # FULL
	assert_eq(station.get_bot_count(), 0, "sync_bot_feedback handles FULL state cleanly")

	# 3. Test local_player real-time interactable refresh
	var player = PlayerControllerScript.new()
	player.name = "1"
	root.add_child(player)
	await process_frame

	station.debounce_timer = 0.0
	station._on_body_entered(player)
	assert_true(station.local_player == player, "local_player tracked on pad entry")

	# Changing count via feedback calls _update_interactable_target on player
	station.sync_bot_feedback(5, 0) # Reach max
	assert_eq(station.get_interaction_action(), "I-RESET ANG MGA BOT (0)", "Prompt dynamically changed to reset at max")

	station._on_body_exited(player)
	assert_true(station.local_player == null, "local_player cleared on pad exit")

	player.queue_free()
	station.queue_free()
	await process_frame
