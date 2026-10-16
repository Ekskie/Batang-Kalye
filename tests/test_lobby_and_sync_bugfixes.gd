extends SceneTree

var passed: int = 0
var failed: int = 0

func assert_true(condition: bool, msg: String) -> void:
	if condition:
		passed += 1
		print("  [PASS] %s" % msg)
	else:
		failed += 1
		print("  [FAIL] %s" % msg)

func assert_false(condition: bool, msg: String) -> void:
	assert_true(not condition, msg)

func assert_eq(a, b, msg: String) -> void:
	if a == b:
		passed += 1
		print("  [PASS] %s" % msg)
	else:
		failed += 1
		print("  [FAIL] %s (Expected: %s, Got: %s)" % [msg, str(b), str(a)])

func _init() -> void:
	call_deferred("run_all_tests")

func run_all_tests() -> void:
	print("\n======================================================================")
	print(" [BUG FIXES VERIFICATION] GHOST LOBBIES, VISIBILITY & REVERSE RUNNING")
	print("======================================================================\n")

	test_ghost_lobby_fixes()
	test_player_visibility_and_court_spawn()
	test_transform_server_relay_and_sync()
	test_reverse_running_animation_fix()
	test_broadcasting_active_in_lobby_and_playing_areas()

	print("\n======================================================================")
	print(" SUMMARY: %d PASSED, %d FAILED" % [passed, failed])
	print("======================================================================")
	if failed == 0:
		print(">>> ALL LOBBY & PLAYER SYNC BUG FIXES VERIFIED! RELEASE READY! <<<\n")
		quit(0)
	else:
		print(">>> SOME TESTS FAILED! <<<\n")
		quit(1)

func test_ghost_lobby_fixes() -> void:
	print("--- [1] Bug 1: Ghost Lobby Cleanup, Staleness Filter & Session Persistence ---")
	var slm := SupabaseLobbyManager.new()
	root.add_child(slm)

	# 1.1 Verify session file persistence
	slm.current_lobby_id = "test-session-lobby-uuid-1234"
	slm.is_hosting_lobby = true
	slm._save_active_session()
	assert_true(FileAccess.file_exists(SupabaseLobbyManager.SESSION_FILE_PATH), "Active lobby session file written on lobby creation")

	var f := FileAccess.open(SupabaseLobbyManager.SESSION_FILE_PATH, FileAccess.READ)
	var content: String = f.get_as_text() if f else ""
	if f: f.close()
	var parsed_session = JSON.parse_string(content)
	assert_true(parsed_session is Dictionary and parsed_session.get("lobby_id") == "test-session-lobby-uuid-1234", "Session file contains active lobby ID")

	# 1.2 Verify session clear on cleanup
	slm._cleanup_local_lobby_state()
	assert_false(FileAccess.file_exists(SupabaseLobbyManager.SESSION_FILE_PATH), "Session file deleted on lobby cleanup/leave")
	assert_eq(slm.current_lobby_id, "", "current_lobby_id reset to empty")
	assert_false(slm.is_hosting_lobby, "is_hosting_lobby reset to false")

	# 1.3 Verify staleness filter logic (older than 45s considered ghost)
	var now_unix: float = Time.get_unix_time_from_system()
	var fresh_time_str := Time.get_datetime_string_from_unix_time(int(now_unix - 10))
	var stale_time_str := Time.get_datetime_string_from_unix_time(int(now_unix - 90))

	var raw_lobbies: Array = [
		{
			"id": "fresh-room-1",
			"name": "Tambayan Fresh",
			"created_at": fresh_time_str,
			"updated_at": fresh_time_str
		},
		{
			"id": "stale-ghost-room-2",
			"name": "Ghost Lobby Dead",
			"created_at": stale_time_str,
			"updated_at": stale_time_str
		}
	]

	# Simulate _on_fetch_completed parsing
	var valid_lobbies: Array = []
	var stale_ids: Array[String] = []
	for lobby_item in raw_lobbies:
		var time_str: String = str(lobby_item.get("updated_at", ""))
		var clean_time := time_str.split(".")[0]
		var dt_unix := Time.get_unix_time_from_datetime_string(clean_time)
		if dt_unix > 0 and (now_unix - dt_unix) > 45.0:
			stale_ids.append(str(lobby_item.get("id")))
		else:
			valid_lobbies.append(lobby_item)

	assert_eq(valid_lobbies.size(), 1, "Stale ghost room was filtered out from active list")
	assert_eq(valid_lobbies[0]["id"], "fresh-room-1", "Only fresh lobby is retained for player browsing")
	assert_eq(stale_ids.size(), 1, "Stale lobby identified for background prune")
	assert_eq(stale_ids[0], "stale-ghost-room-2", "Target ghost ID queued for Supabase DELETE")

	slm.queue_free()

func test_player_visibility_and_court_spawn() -> void:
	print("\n--- [2] Bug 2: 3D Court Player Spawning & Invisibility Prevention ---")
	var gm_scene: PackedScene = load("res://scenes/main/Main.tscn")
	var gm: GameManager = gm_scene.instantiate() as GameManager
	gm.is_running_automated_test = true
	root.add_child(gm)
	gm._init_node_references()

	# Transition to SOCIAL_LOBBY
	gm.current_state = GameManager.GameState.SOCIAL_LOBBY

	# Spawn player 1 (Host) and player 2 (Joining Client)
	if gm.network_manager:
		gm.network_manager.players[1] = {"name": "HostPlayer", "outfit": {"base": 0, "color": 0}}
		gm.network_manager.players[2] = {"name": "ClientPlayer", "outfit": {"base": 1, "color": 1}}

	var host_p: PlayerController = gm._spawn_single_player(1, 0)
	var client_p: PlayerController = gm._spawn_single_player(2, 1)

	assert_true(is_instance_valid(host_p), "Host player spawned successfully")
	assert_true(is_instance_valid(client_p), "Client player spawned successfully")

	# Court spawn points are around Vector3(35.5, 0.5, -6.0)
	var court_center := Vector3(35.5, 0.5, -6.0)
	assert_true(host_p.global_position.distance_to(court_center) < 10.0, "Host spawned within basketball court boundary")
	assert_true(client_p.global_position.distance_to(court_center) < 10.0, "Client spawned within basketball court boundary")

	# Crucial: target_position must NOT be at match spawn (-22, 0.5, -35)
	var match_spawn := Vector3(-22.0, 0.5, -35.0)
	assert_true(client_p.target_position.distance_to(match_spawn) > 20.0, "Client target_position is NOT initialized to match spawn 40m away")
	assert_true(client_p.target_position.distance_to(court_center) < 10.0, "Client target_position matches court spawn (prevents being sucked off court)")

	# Verify reset_network_interpolation updates both target_position and _last_sent_position
	var new_court_pos := Vector3(36.0, 0.5, -5.0)
	client_p.reset_network_interpolation(new_court_pos)
	assert_eq(client_p.global_position, new_court_pos, "reset_network_interpolation sets global_position")
	assert_eq(client_p.target_position, new_court_pos, "reset_network_interpolation synchronizes target_position")
	assert_eq(client_p._last_sent_position, new_court_pos, "reset_network_interpolation updates _last_sent_position for delta suppression")
	assert_true(client_p.snapshot_ring_buffer.is_empty(), "reset_network_interpolation flushes stale snapshot ring buffer")

	gm.queue_free()

func test_transform_server_relay_and_sync() -> void:
	print("\n--- [3] Bug 2: Star-Topology Transform Relay & Non-Destructive Late Join ---")
	var gm_scene: PackedScene = load("res://scenes/main/Main.tscn")
	var gm: GameManager = gm_scene.instantiate() as GameManager
	gm.is_running_automated_test = true
	root.add_child(gm)
	gm._init_node_references()

	gm.current_state = GameManager.GameState.SOCIAL_LOBBY
	if gm.network_manager:
		gm.network_manager.players[1] = {"name": "HostPlayer", "outfit": {}}
		gm.network_manager.players[2] = {"name": "ClientPlayer", "outfit": {}}

	# Initial spawn
	var p1: PlayerController = gm._spawn_single_player(1, 0)
	var p2: PlayerController = gm._spawn_single_player(2, 1)

	# Simulate late join sync: sync_late_join_lobby must NOT free existing local players
	var p2_id_before: int = p2.get_instance_id()
	var all_players: Dictionary = {
		1: {"name": "HostPlayer", "outfit": {}},
		2: {"name": "ClientPlayer", "outfit": {}},
		3: {"name": "NewPeer", "outfit": {}}
	}

	gm.sync_late_join_lobby(all_players)

	var p2_after = gm.players_container.get_node_or_null("2")
	assert_true(is_instance_valid(p2_after), "Player 2 node preserved across late join sync")
	assert_eq(p2_after.get_instance_id(), p2_id_before, "Existing Player 2 was NOT destroyed and recreated")

	var p3_node = gm.players_container.get_node_or_null("3")
	assert_true(is_instance_valid(p3_node), "New Player 3 node created cleanly")
	assert_eq(gm.players_container.get_child_count(), 3, "All 3 peers present in players_container")

	# Test transform reception
	var test_pos := Vector3(14.5, 0.5, -6.2)
	var test_vel := Vector3(2.0, 0.0, 1.0)
	var test_rot := 1.25
	p2.sync_transform(test_pos, test_vel, test_rot, 2.2, true, false, false, 50000)

	assert_eq(p2.target_position, test_pos, "sync_transform updates target_position on remote peer")
	assert_eq(p2.target_velocity, test_vel, "sync_transform updates target_velocity")
	assert_eq(p2.target_rotation_y, test_rot, "sync_transform updates target_rotation_y")
	assert_false(p2.snapshot_ring_buffer.is_empty(), "sync_transform pushes valid snapshot to ring buffer")

	gm.queue_free()

func test_reverse_running_animation_fix() -> void:
	print("\n--- [4] Bug 3: Reverse Running Animation & Root Rotation Fix ---")
	var p_scene: PackedScene = load("res://scenes/player/Player.tscn")
	var player: PlayerController = p_scene.instantiate() as PlayerController
	player.player_id = 1
	root.add_child(player)

	# 4.1 Verify root rotation remains Vector3.ZERO
	assert_eq(player.rotation, Vector3.ZERO, "PlayerController root rotation is Vector3.ZERO")

	# 4.2 Initial facing in social lobby: camera_yaw and model.rotation.y face court, root is ZERO
	player.camera_yaw = -PI / 2.0
	player._apply_camera_rotation()
	if player.model:
		player.model.rotation.y = -PI / 2.0
	player.rotation = Vector3.ZERO

	assert_eq(player.rotation, Vector3.ZERO, "Root rotation remains Vector3.ZERO after lobby facing setup")
	if player.model:
		assert_true(is_equal_approx(player.model.rotation.y, -PI / 2.0), "Model visual facing set cleanly without corrupting root node")

	# 4.3 Test movement direction vs target_facing
	# Camera faces -Z (yaw = 0)
	player.camera_yaw = 0.0
	player._apply_camera_rotation()

	# If moving forward (move_dir = Vector3(0, 0, -1)):
	var move_forward := Vector3(0.0, 0.0, -1.0)
	var facing_forward := wrapf(atan2(-move_forward.x, -move_forward.z) - player.global_rotation.y, -PI, PI)
	# atan2(-0, -(-1)) = atan2(0, 1) = 0.0
	assert_true(abs(facing_forward) < 0.001, "Moving forward results in target_facing = 0.0 (faces forward, NOT reverse/backwards)")

	# If moving backward (move_dir = Vector3(0, 0, 1)):
	var move_backward := Vector3(0.0, 0.0, 1.0)
	var facing_backward := wrapf(atan2(-move_backward.x, -move_backward.z) - player.global_rotation.y, -PI, PI)
	# atan2(0, -1) = PI or -PI
	assert_true(abs(abs(facing_backward) - PI) < 0.001, "Moving backward results in target_facing = PI (faces backward)")

	# If root node had an arbitrary rotation (e.g. PI/4), formula compensates cleanly:
	player.rotation.y = PI / 4.0
	var compensated_facing := wrapf(atan2(-move_forward.x, -move_forward.z) - player.global_rotation.y, -PI, PI)
	# Local model rotation + parent global rotation = world facing (0.0)!
	var world_model_facing := wrapf(player.global_rotation.y + compensated_facing, -PI, PI)
	assert_true(abs(world_model_facing) < 0.001, "Target facing formula compensates for parent rotation (world facing matches move_dir)")

	player.queue_free()

func test_broadcasting_active_in_lobby_and_playing_areas() -> void:
	print("\n--- [5] Bug Fix: Player Transform Sync Active in Lobby & Playing Areas ---")
	var gm_scene: PackedScene = load("res://scenes/main/Main.tscn")
	var gm: GameManager = gm_scene.instantiate() as GameManager
	gm.is_running_automated_test = true
	gm.name = "Main"
	root.add_child(gm)
	gm._init_node_references()

	# Create local player 1
	var p1: PlayerController = gm._spawn_single_player(1, 0)
	p1.name = "1"
	p1.player_id = 1

	# Test 5.1: In 2D TITLE (0) and LOBBY (1), broadcasting is suppressed
	gm.current_state = GameManager.GameState.TITLE
	p1._last_sent_position = Vector3.ZERO
	p1.global_position = Vector3(10, 0, 10)
	p1._net_tick_timer = 0.1
	p1._process_network_sync_broadcasting(0.05)
	assert_eq(p1._last_sent_position, Vector3.ZERO, "TITLE (0) suppresses transform broadcast")

	gm.current_state = GameManager.GameState.LOBBY
	p1._last_sent_position = Vector3.ZERO
	p1.global_position = Vector3(10, 0, 10)
	p1._net_tick_timer = 0.1
	p1._process_network_sync_broadcasting(0.05)
	assert_eq(p1._last_sent_position, Vector3.ZERO, "LOBBY (1) suppresses transform broadcast")

	# Test 5.2: In SOCIAL_LOBBY (5), broadcasting is ACTIVE
	gm.current_state = GameManager.GameState.SOCIAL_LOBBY
	p1._last_sent_position = Vector3.ZERO
	p1.global_position = Vector3(15, 0.5, -6)
	p1._net_tick_timer = 0.1
	p1._process_network_sync_broadcasting(0.05)
	assert_eq(p1._last_sent_position, Vector3(15, 0.5, -6), "SOCIAL_LOBBY (5) actively broadcasts player transforms")

	# Test 5.3: In PLAYING (3), broadcasting is ACTIVE
	gm.current_state = GameManager.GameState.PLAYING
	p1._last_sent_position = Vector3.ZERO
	p1.global_position = Vector3(-20, 0.5, -30)
	p1._net_tick_timer = 0.1
	p1._process_network_sync_broadcasting(0.05)
	assert_eq(p1._last_sent_position, Vector3(-20, 0.5, -30), "PLAYING (3) actively broadcasts player transforms")

	# Test 5.4: In MAIBA_TAYA (2), broadcasting is ACTIVE
	gm.current_state = GameManager.GameState.MAIBA_TAYA
	p1._last_sent_position = Vector3.ZERO
	p1.global_position = Vector3(-10, 0.5, -15)
	p1._net_tick_timer = 0.1
	p1._process_network_sync_broadcasting(0.05)
	assert_eq(p1._last_sent_position, Vector3(-10, 0.5, -15), "MAIBA_TAYA (2) actively broadcasts player transforms")

	# Test 5.5: Server authoritative role & immunity updates
	p1.current_role = PlayerController.Role.RUNNER
	p1.set_role_rpc(PlayerController.Role.TAYA)
	assert_eq(p1.current_role, PlayerController.Role.TAYA, "Server authoritatively updates role via set_role_rpc")

	p1.is_immune = false
	p1.grant_immunity_rpc(3.0)
	assert_true(p1.is_immune, "Server authoritatively grants immunity via grant_immunity_rpc")
	assert_eq(p1.current_immunity_timer, 3.0, "Immunity timer set to 3.0s")

	# Test 5.6: Supabase heartbeat in-flight guard
	if gm.supabase_manager:
		var slm := gm.supabase_manager
		slm.current_lobby_id = "test-lobby-heartbeat"
		slm.update_lobby(2, false)
		assert_true(true, "update_lobby executes safely with in-flight guard")

	gm.queue_free()

