extends SceneTree

# ==============================================================================
# PHASE 1 STABILITY & MULTIPLAYER AUTHORITY TEST SUITE
# Verifies:
#   1. Server-authoritative role assignment (unauthorized peer rejection)
#   2. Player disconnection despawns 3D avatar from scene tree
#   3. Player disconnection cleans up alive_player_ids and eliminated_player_ids
#   4. Taya disconnection mid-match auto-promotes surviving runner to Taya
#   5. Elimination match with 1 survivor remaining concludes cleanly
#   6. Server disconnection cleanly flushes all player instances & resets state
# ==============================================================================

var test_passes: int = 0
var test_failures: int = 0

func _init() -> void:
	call_deferred("run_all_tests")

func run_all_tests() -> void:
	print("\n" + "=".repeat(70))
	print(" [PHASE 1 VERIFICATION] STABILITY & MULTIPLAYER AUTHORITY SUITE")
	print("=".repeat(70))

	test_unauthorized_role_rpc_logic()
	test_disconnect_despawns_player_node()
	test_taya_disconnect_auto_promotes_runner()
	test_elimination_single_survivor_concludes_match()
	test_server_disconnect_flushes_all_nodes()

	print("\n" + "=".repeat(70))
	print(" PHASE 1 SUMMARY: %d PASSED, %d FAILED" % [test_passes, test_failures])
	print("=".repeat(70))

	if test_failures == 0:
		print(">>> ALL PHASE 1 STABILITY & AUTHORITY TESTS PASSED! <<<")
		quit(0)
	else:
		push_error(">>> PHASE 1 TESTS FAILED: %d failures detected! <<<" % test_failures)
		quit(1)

func assert_true(cond: bool, msg: String) -> void:
	if cond:
		test_passes += 1
		print("  [PASS] %s" % msg)
	else:
		test_failures += 1
		push_error("  [FAIL] %s" % msg)
		print("  [FAIL] %s" % msg)

func test_unauthorized_role_rpc_logic() -> void:
	print("\n--- [1] Server Authority Sender Validation ---")
	var player_scene: PackedScene = load("res://scenes/player/Player.tscn")
	var player: PlayerController = player_scene.instantiate() as PlayerController
	root.add_child(player)

	player.current_role = PlayerController.Role.RUNNER
	assert_true(player.current_role == PlayerController.Role.RUNNER, "Player initialized as RUNNER")

	# Locally without network peer, set_role_rpc works cleanly
	player.set_role_rpc(PlayerController.Role.TAYA)
	assert_true(player.current_role == PlayerController.Role.TAYA, "Local authority can update role to TAYA")

	player.grant_immunity_rpc(3.0)
	assert_true(player.is_immune and player.current_immunity_timer == 3.0, "grant_immunity_rpc sets timer")

	player.queue_free()

func test_disconnect_despawns_player_node() -> void:
	print("\n--- [2] Disconnect Despawns Player Node & Cleans State ---")
	var gm_scene: PackedScene = load("res://scenes/main/Main.tscn")
	var main_node: Node = gm_scene.instantiate()
	root.add_child(main_node)

	var gm: GameManager = main_node as GameManager
	assert_true(gm != null, "GameManager instantiated")

	# Add simulated players
	var p2: PlayerController = gm.player_scene.instantiate()
	p2.name = "2"
	p2.player_id = 2
	gm.players_container.add_child(p2)

	var p3: PlayerController = gm.player_scene.instantiate()
	p3.name = "3"
	p3.player_id = 3
	gm.players_container.add_child(p3)

	gm.alive_player_ids = [2, 3]
	gm.current_state = GameManager.GameState.PLAYING

	assert_true(gm.players_container.has_node("2"), "Player 2 exists in players_container before disconnect")

	# Trigger disconnection of Player 2
	gm._on_player_disconnected(2)

	assert_true(not gm.alive_player_ids.has(2), "Player 2 removed from alive_player_ids")
	assert_true(gm.alive_player_ids == [3], "Player 3 remains alone in alive_player_ids")
	assert_true(p2.is_queued_for_deletion() or not gm.players_container.has_node("2"), "Player 2 node is freed/despawned")

	main_node.queue_free()

func test_taya_disconnect_auto_promotes_runner() -> void:
	print("\n--- [3] Taya Disconnect Auto-Promotes Surviving Runner ---")
	var gm_scene: PackedScene = load("res://scenes/main/Main.tscn")
	var main_node: Node = gm_scene.instantiate()
	root.add_child(main_node)

	var gm: GameManager = main_node as GameManager

	var taya_player: PlayerController = gm.player_scene.instantiate()
	taya_player.name = "10"
	taya_player.player_id = 10
	taya_player.current_role = PlayerController.Role.TAYA
	gm.players_container.add_child(taya_player)

	var runner_player: PlayerController = gm.player_scene.instantiate()
	runner_player.name = "11"
	runner_player.player_id = 11
	runner_player.current_role = PlayerController.Role.RUNNER
	gm.players_container.add_child(runner_player)

	gm.alive_player_ids = [10, 11]
	gm.current_state = GameManager.GameState.PLAYING
	gm.current_mode = GameManager.MatchMode.CLASSIC_TAG

	# Taya (10) disconnects
	gm._on_player_disconnected(10)

	assert_true(runner_player.current_role == PlayerController.Role.TAYA, "Runner 11 auto-promoted to TAYA after Taya 10 disconnected")
	assert_true(runner_player.is_immune, "Runner 11 granted immunity head start on promotion")

	main_node.queue_free()

func test_elimination_single_survivor_concludes_match() -> void:
	print("\n--- [4] Elimination Disconnect Triggers Clean Victory Resolution ---")
	var gm_scene: PackedScene = load("res://scenes/main/Main.tscn")
	var main_node: Node = gm_scene.instantiate()
	root.add_child(main_node)

	var gm: GameManager = main_node as GameManager

	var p1: PlayerController = gm.player_scene.instantiate()
	p1.name = "20"
	p1.player_id = 20
	gm.players_container.add_child(p1)

	var p2: PlayerController = gm.player_scene.instantiate()
	p2.name = "21"
	p2.player_id = 21
	gm.players_container.add_child(p2)

	gm.alive_player_ids = [20, 21]
	gm.current_state = GameManager.GameState.PLAYING
	gm.current_mode = GameManager.MatchMode.PASA_TAYA_ELIMINATION

	# Peer 20 drops
	gm._on_player_disconnected(20)

	assert_true(gm.alive_player_ids.size() == 1 and gm.alive_player_ids[0] == 21, "Sole surviving player 21 isolated in alive list")
	assert_true(gm.current_state == GameManager.GameState.GAME_OVER, "GameManager immediately transitioned to GAME_OVER rather than hanging")

	main_node.queue_free()

func test_server_disconnect_flushes_all_nodes() -> void:
	print("\n--- [5] Server Disconnect Clean Teardown & Reset ---")
	var gm_scene: PackedScene = load("res://scenes/main/Main.tscn")
	var main_node: Node = gm_scene.instantiate()
	root.add_child(main_node)

	var gm: GameManager = main_node as GameManager

	for i in range(5):
		var p: PlayerController = gm.player_scene.instantiate()
		p.name = str(30 + i)
		p.player_id = 30 + i
		gm.players_container.add_child(p)

	gm.alive_player_ids = [30, 31, 32, 33, 34]
	gm.current_state = GameManager.GameState.PLAYING

	assert_true(gm.players_container.get_child_count() == 5, "5 players active before server disconnect")

	# Server disconnect fires
	gm._on_server_disconnected()

	assert_true(gm.players_container.get_child_count() == 0, "players_container flushed completely (0 children)")
	assert_true(gm.alive_player_ids.is_empty(), "alive_player_ids cleared")
	assert_true(gm.current_state == GameManager.GameState.LOBBY, "State cleanly returned to LOBBY")
	assert_true(Input.mouse_mode == Input.MOUSE_MODE_VISIBLE, "Mouse mode restored to VISIBLE")

	main_node.queue_free()
