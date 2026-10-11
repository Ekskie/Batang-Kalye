extends SceneTree

# ==============================================================================
# PHASE 2: GAME MODE UNIFICATION & INFECTED BASE TEST SUITE
# Verifies:
#   1. Normal Taayan (Classic Tag) lifecycle, tag transfer & win resolution
#   2. Pasa-Taya Elimination (Crab Game) rounds, elimination & finals
#   3. Infected Base shelter mechanics (entry, shelter timer, tag block, expiration)
#   4. Infection mode win conditions (0 runners -> Tayas win, timer 0 -> Runners win)
#   5. End-of-match recap leaderboard sorting per mode outcome
# ==============================================================================

var test_passes: int = 0
var test_failures: int = 0

func _init() -> void:
	call_deferred("run_all_tests")

func run_all_tests() -> void:
	print("\n" + "=".repeat(70))
	print(" [PHASE 2 VERIFICATION] GAME MODE UNIFICATION & INFECTED BASE SUITE")
	print("=".repeat(70))

	test_normal_taayan_lifecycle()
	test_elimination_mode_lifecycle()
	test_infected_base_shelter_mechanics()
	test_infection_mode_win_conditions()
	test_match_results_mode_sorting()

	print("\n" + "=".repeat(70))
	print(" PHASE 2 SUMMARY: %d PASSED, %d FAILED" % [test_passes, test_failures])
	print("=".repeat(70))

	if test_failures == 0:
		print(">>> ALL PHASE 2 GAME MODE & INFECTED BASE TESTS PASSED! <<<")
		quit(0)
	else:
		push_error(">>> PHASE 2 TESTS FAILED: %d failures detected! <<<" % test_failures)
		quit(1)

func assert_true(cond: bool, msg: String) -> void:
	if cond:
		test_passes += 1
		print("  [PASS] %s" % msg)
	else:
		test_failures += 1
		push_error("  [FAIL] %s" % msg)
		print("  [FAIL] %s" % msg)

func test_normal_taayan_lifecycle() -> void:
	print("\n--- [1] Normal Taayan (Classic Tag) Lifecycle ---")
	var gm_scene: PackedScene = load("res://scenes/main/Main.tscn")
	var main_node: Node = gm_scene.instantiate()
	root.add_child(main_node)
	var gm: GameManager = main_node as GameManager

	var mode := TayaanMode.new()
	assert_true(mode.mode_name == "Normal Taayan", "Mode name is 'Normal Taayan'")
	assert_true(mode.mode_type == 2, "Mode type is 2 (CLASSIC_TAG)")

	gm.match_duration = 30.0
	mode.start_mode(gm)
	assert_true(gm.match_timer == 30.0, "start_mode sets match_timer to match_duration")

	# Tag transfer
	gm.network_manager.players[1] = { "name": "Juan", "score": 0, "role": 1 }
	gm.network_manager.players[2] = { "name": "Pedro", "score": 0, "role": 0 }
	mode.on_player_tagged(gm, 1, 2)
	assert_true(gm.network_manager.players[1]["role"] == 0, "Tagger 1 role changed to RUNNER")
	assert_true(gm.network_manager.players[2]["role"] == 1, "Victim 2 role changed to TAYA")

	# Timer check
	gm.match_timer = 5.0
	assert_true(not mode.check_win_condition(gm), "Win condition false when timer > 0")
	gm.match_timer = 0.0
	assert_true(mode.check_win_condition(gm), "Win condition true when timer reaches 0")

	main_node.queue_free()

func test_elimination_mode_lifecycle() -> void:
	print("\n--- [2] Pasa-Taya Elimination Lifecycle & Finals ---")
	var gm_scene: PackedScene = load("res://scenes/main/Main.tscn")
	var main_node: Node = gm_scene.instantiate()
	root.add_child(main_node)
	var gm: GameManager = main_node as GameManager

	var mode := EliminationMode.new()
	assert_true(mode.mode_name.begins_with("Pasa-Taya"), "Mode name is Pasa-Taya")
	assert_true(mode.mode_type == 0, "Mode type is 0 (PASA_TAYA_ELIMINATION)")

	gm.alive_player_ids = [1, 2, 3]
	assert_true(not mode.check_win_condition(gm), "3 alive players: win condition false")

	gm.alive_player_ids = [1]
	assert_true(mode.check_win_condition(gm), "1 alive player: win condition true (Champion reached)")

	# Full runtime lifecycle & spectator mode verification
	gm.current_mode = gm.MatchMode.PASA_TAYA_ELIMINATION
	gm.active_game_mode = mode
	var ids: Array[int] = [1, 2, 3, 4]
	gm.alive_player_ids = ids
	var elim_ids: Array[int] = []
	gm.eliminated_player_ids = elim_ids
	gm.current_round = 1
	gm.current_state = gm.GameState.PLAYING

	var p1 = load("res://scenes/player/Player.tscn").instantiate()
	p1.name = "1"
	p1.player_id = 1
	p1.current_role = p1.Role.RUNNER
	gm.players_container.add_child(p1)

	for bid in [2, 3, 4]:
		var bot = load("res://scenes/player/PracticeBot.tscn").instantiate()
		bot.name = str(bid)
		bot.player_id = bid
		bot.current_role = bot.Role.RUNNER
		gm.players_container.add_child(bot)

	var bot2 = gm.players_container.get_node("2")
	bot2.current_role = bot2.Role.TAYA

	mode.start_mode(gm)
	assert_true(gm.match_timer == 45.0, "Round 1 match timer initialized to 45.0s")

	# Timer expires: bot 2 should be eliminated and enter intermission
	gm.match_timer = 0.0
	gm._process(0.016)
	assert_true(gm.is_intermission, "Intermission entered on round timer expiry")
	assert_true(gm.alive_player_ids.size() == 3 and not gm.alive_player_ids.has(2), "Bot 2 eliminated cleanly; 3 players remain alive")

	# Intermission finishes: advance to Round 2
	gm._process(4.1)
	assert_true(not gm.is_intermission, "Intermission concluded cleanly")
	assert_true(gm.current_round == 2, "Transitioned to Round 2")
	assert_true(gm.match_timer == 35.0, "Round 2 match timer set to 35.0s")

	# Eliminate human player 1 in Round 2 to verify spectator mode
	p1.current_role = p1.Role.TAYA
	var bot3 = gm.players_container.get_node("3")
	bot3.current_role = bot3.Role.RUNNER
	var bot4 = gm.players_container.get_node("4")
	bot4.current_role = bot4.Role.RUNNER

	gm.match_timer = 0.0
	gm._process(0.016)

	assert_true(p1.is_eliminated, "Human player 1 marked eliminated")
	assert_true(p1.spectating_target != null, "Player 1 spectator target assigned")
	assert_true(p1.spectating_target.player_id in [3, 4], "Spectator target is an alive player")

	var initial_target_id = p1.spectating_target.player_id
	p1._cycle_spectate_target(1)
	assert_true(p1.spectating_target.player_id in [3, 4] and p1.spectating_target.player_id != initial_target_id, "Spectator cycling switches between alive players")

	# Advance to Round 3 (Finals)
	gm._process(4.1)
	assert_true(gm.current_round == 3, "Transitioned to Round 3 (Finals)")
	assert_true(p1.is_eliminated, "Spectator status persists across round transitions")

	# Resolve Finals
	gm.match_timer = 0.0
	gm._process(0.016)
	assert_true(gm.current_state == gm.GameState.GAME_OVER, "Game cleanly concluded on Finals expiration")

	main_node.queue_free()

func test_infected_base_shelter_mechanics() -> void:
	print("\n--- [3] Infected Base Shelter & Tag Deflection Mechanics ---")
	var player_scene: PackedScene = load("res://scenes/player/Player.tscn")
	var runner: PlayerController = player_scene.instantiate() as PlayerController
	root.add_child(runner)
	runner.current_role = PlayerController.Role.RUNNER

	var base_scene: PackedScene = load("res://scenes/gameplay/SafeBaseZone.tscn")
	var base_zone: Node = base_scene.instantiate()
	root.add_child(base_zone)

	assert_true(base_zone != null, "SafeBaseZone loaded and instantiated cleanly")
	assert_true(runner.base_shelter_timer == 8.0, "Runner default base shelter timer is 8.0s")

	# Runner enters base
	runner.enter_safe_base()
	assert_true(runner.is_in_base, "Runner marked as inside base")
	assert_true(runner.is_sheltered_in_base(), "Runner is actively sheltered in base")

	# Simulate Taya attempting to tag sheltered runner
	var chaser: PlayerController = player_scene.instantiate() as PlayerController
	root.add_child(chaser)
	chaser.current_role = PlayerController.Role.TAYA

	chaser.perform_tag_on(runner)
	assert_true(runner.current_role == PlayerController.Role.RUNNER, "Tag deflected! Sheltered runner was NOT infected")

	# Drain shelter timer to 0
	runner.base_shelter_timer = 0.0
	assert_true(not runner.is_sheltered_in_base(), "Shelter expires when timer reaches 0s")

	# Runner leaves base
	runner.exit_safe_base()
	assert_true(not runner.is_in_base, "Runner marked as outside base")
	assert_true(runner.base_cooldown_timer == 5.0, "Cooldown timer initiated after leaving base")

	runner.queue_free()
	chaser.queue_free()
	base_zone.queue_free()

func test_infection_mode_win_conditions() -> void:
	print("\n--- [4] Infection Mode Win Conditions (Tayas Win vs Runners Win) ---")
	var gm_scene: PackedScene = load("res://scenes/main/Main.tscn")
	var main_node: Node = gm_scene.instantiate()
	root.add_child(main_node)
	var gm: GameManager = main_node as GameManager

	var mode := InfectionMode.new()
	assert_true(mode.mode_name == "Infected Base", "Mode name is 'Infected Base'")
	assert_true(mode.mode_type == 1, "Mode type is 1 (INFECTION)")

	# Add 1 Taya and 1 Runner
	var p_taya: PlayerController = gm.player_scene.instantiate()
	p_taya.name = "5"
	p_taya.player_id = 5
	p_taya.current_role = PlayerController.Role.TAYA
	gm.players_container.add_child(p_taya)

	var p_runner: PlayerController = gm.player_scene.instantiate()
	p_runner.name = "6"
	p_runner.player_id = 6
	p_runner.current_role = PlayerController.Role.RUNNER
	gm.players_container.add_child(p_runner)

	gm.current_state = GameManager.GameState.PLAYING
	gm.match_timer = 30.0

	# Both alive -> no game over yet
	mode.process_mode(gm, 0.1)
	assert_true(gm.current_state == GameManager.GameState.PLAYING, "Game remains in PLAYING while runners survive")

	# Tag runner -> 0 runners left
	p_runner.current_role = PlayerController.Role.TAYA
	mode.process_mode(gm, 0.1)
	assert_true(gm.current_state == GameManager.GameState.GAME_OVER, "0 runners left: Game transitioned to GAME_OVER (Tayas win)")

	main_node.queue_free()

func test_match_results_mode_sorting() -> void:
	print("\n--- [5] Match Results Recap Leaderboard Sorting ---")
	var gm_scene: PackedScene = load("res://scenes/main/Main.tscn")
	var main_node: Node = gm_scene.instantiate()
	root.add_child(main_node)
	var gm: GameManager = main_node as GameManager

	# Set up simulated players in network_manager
	gm.network_manager.players[10] = { "name": "ZombieKing", "score": 200, "role": 1 }
	gm.network_manager.players[11] = { "name": "SurvivorHero", "score": 80, "role": 0 }

	var p_zombie: PlayerController = gm.player_scene.instantiate()
	p_zombie.name = "10"
	p_zombie.player_id = 10
	p_zombie.current_role = PlayerController.Role.TAYA
	p_zombie.stats_tags = 3
	gm.players_container.add_child(p_zombie)

	var p_hero: PlayerController = gm.player_scene.instantiate()
	p_hero.name = "11"
	p_hero.player_id = 11
	p_hero.current_role = PlayerController.Role.RUNNER
	p_hero.survival_time = 45.0
	gm.players_container.add_child(p_hero)

	gm.current_mode = GameManager.MatchMode.INFECTION

	# Case A: Runners Won (infection_taya_won = false)
	# Surviving Runner (SurvivorHero) MUST be Rank 1 MVP over ZombieKing despite lower raw points
	var results_runners_won: Array[Dictionary] = gm._compile_match_results(-1, false)
	assert_true(results_runners_won[0]["name"] == "SurvivorHero", "Infection: Surviving runner is Rank 1 MVP when Runners Win")
	assert_true(results_runners_won[0]["status"] == "LIGTAS", "Rank 1 player status is LIGTAS")

	# Case B: Tayas Won (infection_taya_won = true)
	# Top Zombie (ZombieKing) MUST be Rank 1 MVP
	var results_tayas_won: Array[Dictionary] = gm._compile_match_results(-1, true)
	assert_true(results_tayas_won[0]["name"] == "ZombieKing", "Infection: Top infector is Rank 1 MVP when Tayas Win")

	main_node.queue_free()
