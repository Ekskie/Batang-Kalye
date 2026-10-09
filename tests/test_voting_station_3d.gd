extends SceneTree

const VoteManagerScript = preload("res://scripts/gameplay/VoteManager.gd")
const VotingStationScript = preload("res://scripts/gameplay/VotingStation3D.gd")
const ScoreboardScript = preload("res://scripts/gameplay/VotingCourtScoreboard3D.gd")

func _init() -> void:
	call_deferred("run_tests")

func run_tests() -> void:
	print("\n==================================================")
	print("[3D PHYSICAL VOTING STATIONS & SCOREBOARD VERIFICATION]")
	print("==================================================")

	# 1. Initialize VoteManager
	var vote_manager = VoteManagerScript.new()
	vote_manager.name = "VoteManager"
	root.add_child(vote_manager)
	print("[PASS] VoteManager instantiated.")

	# 2. Instantiate Stations and Scoreboard
	var station_scene = load("res://scenes/gameplay/VotingStation3D.tscn")
	assert(station_scene != null, "VotingStation3D.tscn must load")

	var station0: Node3D = station_scene.instantiate()
	station0.name = "VotingStationPasaTaya"
	station0.set("mode_id", 0)
	station0.set("mode_name", "PASA-TAYA")
	station0.set("tagline", "Matira Matibay")
	station0.set("mode_icon", "💥")
	station0.set("theme_color", Color(1.0, 0.35, 0.1, 1.0))
	station0.position = Vector3(28.0, 0.02, -14.0)
	root.add_child(station0)

	var station1: Node3D = station_scene.instantiate()
	station1.name = "VotingStationHawaan"
	station1.set("mode_id", 1)
	station1.set("mode_name", "HAWAAN")
	station1.set("tagline", "Zombie Outbreak")
	station1.set("mode_icon", "🧟‍♂️")
	station1.set("theme_color", Color(0.2, 0.95, 0.3, 1.0))
	station1.position = Vector3(28.0, 0.02, -6.0)
	root.add_child(station1)

	var station2: Node3D = station_scene.instantiate()
	station2.name = "VotingStationTayaan"
	station2.set("mode_id", 2)
	station2.set("mode_name", "TAYAAN")
	station2.set("tagline", "Walang Bawian")
	station2.set("mode_icon", "🏃‍♂️")
	station2.set("theme_color", Color(0.2, 0.65, 1.0, 1.0))
	station2.position = Vector3(28.0, 0.02, 2.0)
	root.add_child(station2)

	var scoreboard_scene = load("res://scenes/gameplay/VotingCourtScoreboard3D.tscn")
	var scoreboard: Node3D = scoreboard_scene.instantiate()
	scoreboard.position = Vector3(28.0, 5.2, -23.2)
	root.add_child(scoreboard)

	# 3. Instantiate Player
	var player_scene = load("res://scenes/player/Player.tscn")
	var player: PlayerController = player_scene.instantiate()
	player.name = "1"
	player.player_id = 1
	root.add_child(player)

	await process_frame
	await physics_frame
	await physics_frame

	print("[PASS] 3 Stations, Scoreboard, and Player added to SceneTree.")

	# 4. Start Voting Session
	vote_manager.start_voting(10.0)
	assert(vote_manager.is_voting == true, "Voting must be active")
	print("[PASS] Voting session started: 10.0s duration.")

	# 5. Test Player Walking into Station 0 (Pasa-Taya)
	player.global_position = station0.global_position
	await physics_frame
	await physics_frame

	# Simulate body entered directly if physics query delayed in headless
	station0._on_body_entered(player)

	assert(vote_manager.player_votes.get(1, -1) == 0, "Player 1 vote must be registered for mode 0")
	assert(vote_manager.current_counts.get(0, 0) == 1, "Pasa-Taya count must be 1")
	assert(station0.label_prompt.text.contains("NAPILI"), "Station prompt must show selected state")
	print("[PASS] Stepping into Station 0 successfully cast vote for PASA-TAYA (tally=1).")

	# 6. Test Scoreboard Update
	scoreboard._on_vote_updated(vote_manager.current_counts, vote_manager.vote_timer)
	assert(scoreboard.label_standings.text.contains("PASA: 1"), "Scoreboard must reflect PASA: 1")
	print("[PASS] Overhead Scoreboard updated with live tally: %s" % scoreboard.label_standings.text)

	# 7. Test Switching Vote to Station 1 (Hawaan)
	station0._on_body_exited(player)
	player.global_position = station1.global_position
	station1._on_body_entered(player)

	assert(vote_manager.player_votes.get(1, -1) == 1, "Player 1 vote must now be registered for mode 1")
	assert(vote_manager.current_counts.get(1, 0) == 1, "Hawaan count must be 1")
	assert(vote_manager.current_counts.get(0, 0) == 0, "Pasa-Taya count must drop back to 0")
	print("[PASS] Running to Station 1 successfully transferred vote to HAWAAN (tally=1, old tally=0).")

	# 8. Test Timer Countdown Sync
	var initial_timer: float = float(vote_manager.vote_timer)
	vote_manager._process(1.0)
	assert(vote_manager.vote_timer < initial_timer, "VoteManager timer must count down smoothly")
	print("[PASS] Vote timer smoothly decremented (now %.1fs)." % vote_manager.vote_timer)

	# 9. Test Resolution & Victory Light Beam
	vote_manager._resolve_voting()
	assert(vote_manager.is_voting == false, "Voting session ended")
	assert(vote_manager.winning_mode == 1, "Winning mode must be HAWAAN (mode 1)")
	print("[PASS] Voting concluded. Winning mode: HAWAAN (id=1).")

	station1._on_vote_ended(1)
	assert(station1.victory_beam.visible == true, "Winning station must activate VictoryBeam")
	assert(station0.victory_beam.visible == false, "Losing station must NOT activate VictoryBeam")
	print("[PASS] Station 1 victory beam activated into the sky.")

	scoreboard._on_vote_ended(1)
	assert(scoreboard.label_timer.text.contains("HAWAAN"), "Scoreboard must proclaim HAWAAN victory")
	print("[PASS] Overhead scoreboard declared victory: %s" % scoreboard.label_timer.text)

	print("\n[ALL 3D PHYSICAL VOTING STATION & SCOREBOARD TESTS PASSED!]")
	quit(0)
