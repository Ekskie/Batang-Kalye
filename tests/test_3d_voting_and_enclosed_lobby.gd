extends SceneTree

const VoteManagerScript = preload("res://scripts/gameplay/VoteManager.gd")
const VotingStartButtonScript = preload("res://scripts/gameplay/VotingStartButton3D.gd")
const VotingStationScript = preload("res://scripts/gameplay/VotingStation3D.gd")
const GameManagerScript = preload("res://scripts/gameplay/GameManager.gd")

func _init() -> void:
	call_deferred("run_tests")

func run_tests() -> void:
	print("\n======================================================================")
	print(" [VERIFICATION] 3D VOTING SYSTEM BUTTON & ENCLOSED LOBBY SUITE")
	print("======================================================================")

	var passed := 0
	var failed := 0

	# --- 1. Test VotingStartButton3D Scene & Script ---
	print("\n--- [1] 3D Voting Start Button (Podium Buzzer) ---")
	var btn_scene = load("res://scenes/gameplay/VotingStartButton3D.tscn")
	if btn_scene != null:
		print("  [PASS] VotingStartButton3D.tscn loaded successfully")
		passed += 1
	else:
		printerr("  [FAIL] Failed to load VotingStartButton3D.tscn")
		failed += 1

	var buzzer: Node3D = btn_scene.instantiate()
	root.add_child(buzzer)

	if buzzer.get_node_or_null("Pedestal") != null and buzzer.get_node_or_null("Pedestal/ButtonDome") != null:
		print("  [PASS] Pedestal and ButtonDome exist in VotingStartButton3D")
		passed += 1
	else:
		printerr("  [FAIL] Missing Pedestal or ButtonDome in VotingStartButton3D")
		failed += 1

	if buzzer.has_method("interact") and buzzer.has_method("get_interaction_action"):
		print("  [PASS] interact() and get_interaction_action() implemented for PlayerController")
		passed += 1
	else:
		printerr("  [FAIL] Missing interact() or get_interaction_action()")
		failed += 1

	# Test starting vote via 3D buzzer
	var vm = VoteManagerScript.new()
	vm.name = "VoteManager"
	root.add_child(vm)
	buzzer.set("vote_manager", vm)

	buzzer.interact(null)
	if vm.is_voting:
		print("  [PASS] Interacting with 3D buzzer successfully triggered vote_manager.is_voting = true")
		passed += 1
	else:
		printerr("  [FAIL] Interacting with buzzer did not trigger voting")
		failed += 1

	buzzer.queue_free()
	vm.queue_free()

	# --- 2. Test VotingStation3D Physical Button Dome ---
	print("\n--- [2] 3D Voting Station Physical Button Pedestals ---")
	var station_scene = load("res://scenes/gameplay/VotingStation3D.tscn")
	var station: Node3D = station_scene.instantiate()
	root.add_child(station)

	if station.get_node_or_null("StationButton") != null and station.get_node_or_null("StationButton/ButtonCap") != null:
		print("  [PASS] StationButton pedestal and ButtonCap dome exist in VotingStation3D")
		passed += 1
	else:
		printerr("  [FAIL] Missing StationButton or ButtonCap dome in VotingStation3D")
		failed += 1

	if station.has_method("interact"):
		print("  [PASS] VotingStation3D supports direct physical interact() [E / Tap]")
		passed += 1
	else:
		printerr("  [FAIL] VotingStation3D lacks interact() method")
		failed += 1

	station.queue_free()

	# --- 3. Test KalyeMap Enclosed Covered Court & 3D Buzzer ---
	print("\n--- [3] KalyeMap Covered Court Enclosure & 3D Buzzer Integration ---")
	var map_scene = load("res://scenes/maps/KalyeMap.tscn")
	if map_scene != null:
		print("  [PASS] KalyeMap.tscn loaded successfully")
		passed += 1
	else:
		printerr("  [FAIL] Failed to load KalyeMap.tscn")
		failed += 1

	var map: Node3D = map_scene.instantiate()
	root.add_child(map)

	var court: Node3D = map.get_node_or_null("Ground/BarangayBasketballCourt")
	if court != null:
		print("  [PASS] BarangayBasketballCourt found in KalyeMap")
		passed += 1
	else:
		printerr("  [FAIL] Missing BarangayBasketballCourt in KalyeMap")
		failed += 1

	var buzzer_in_court = court.get_node_or_null("VotingStartButton")
	if buzzer_in_court != null:
		print("  [PASS] VotingStartButton instantiated in BarangayBasketballCourt")
		passed += 1
	else:
		printerr("  [FAIL] VotingStartButton missing in BarangayBasketballCourt")
		failed += 1

	# Check Enclosure Walls and Roof
	var wall_nodes := [
		"EnclosureWestLower", "EnclosureWestUpper",
		"EnclosureEastLower", "EnclosureEastUpper",
		"EnclosureNorthLower", "EnclosureNorthUpper",
		"EnclosureSouthLower", "EnclosureSouthUpper",
		"EnclosureRoof"
	]
	var all_enclosures_ok := true
	for w_name in wall_nodes:
		var node = court.get_node_or_null(w_name)
		if node == null:
			all_enclosures_ok = false
			printerr("  [FAIL] Missing enclosure node: %s" % w_name)
			failed += 1
		elif not node.use_collision:
			all_enclosures_ok = false
			printerr("  [FAIL] Enclosure node %s missing collision" % w_name)
			failed += 1

	if all_enclosures_ok:
		print("  [PASS] All 8 perimeter enclosure walls and covered roof canopy verified with solid collision")
		passed += 1

	# Check Support Pillars and Floodlights
	var floodlight = court.get_node_or_null("EnclosureFloodlightNorth")
	var banner = court.get_node_or_null("EnclosureBanner")
	if floodlight != null and banner != null:
		print("  [PASS] Overhead gymnasium floodlights and entrance banner verified")
		passed += 1
	else:
		printerr("  [FAIL] Missing floodlights or banner in covered court")
		failed += 1

	# --- 4. Test All 24 Lobby Spawns Confined Inside Enclosed Court ---
	print("\n--- [4] 24 Player Lobby Spawn Positions Confinement ---")
	var court_world_pos: Vector3 = court.global_position # (28, 0, -6)
	var west_bound: float = court_world_pos.x - 13.5     # 14.5
	var east_bound: float = court_world_pos.x + 19.5     # 47.5
	var north_bound: float = court_world_pos.z - 18.5    # -24.5
	var south_bound: float = court_world_pos.z + 18.5    # 12.5

	var gm = GameManagerScript.new()
	var all_spawns_confined := true
	var station_hawaan_center := court_world_pos + Vector3(0.0, 0.02, 0.0)

	for i in range(24):
		var p_pos: Vector3 = gm._get_lobby_spawn_position(i)
		var in_x: bool = p_pos.x > west_bound and p_pos.x < east_bound
		var in_z: bool = p_pos.z > north_bound and p_pos.z < south_bound
		if not (in_x and in_z):
			all_spawns_confined = false
			printerr("  [FAIL] Spawn %d at %s outside court bounds [%.1f, %.1f] x [%.1f, %.1f]" % [i, p_pos, west_bound, east_bound, north_bound, south_bound])
			failed += 1

		# Verify no spawn overlaps station triggers (radius 2.2m)
		var dist_to_hawaan: float = p_pos.distance_to(station_hawaan_center)
		if dist_to_hawaan < 2.2:
			all_spawns_confined = false
			printerr("  [FAIL] Spawn %d at %s overlaps Hawaan station trigger (dist=%.2f < 2.2)" % [i, p_pos, dist_to_hawaan])
			failed += 1

	if all_spawns_confined:
		print("  [PASS] All 24 lobby spawn positions strictly confined within enclosed covered court [14.5..47.5, -24.5..12.5]")
		print("  [PASS] Zero spawn collisions with voting station triggers")
		passed += 2

	gm.queue_free()
	map.queue_free()

	# --- 5. Test 2D UI Button Hidden ---
	print("\n--- [5] 2D UI Elimination (100% 3D In-World Voting) ---")
	var social_scene = load("res://scenes/ui/SocialLobbyUI.tscn")
	var social_ui = social_scene.instantiate()
	root.add_child(social_ui)

	if social_ui.btn_start_vote != null and not social_ui.btn_start_vote.visible:
		print("  [PASS] BtnStartVote in SocialLobbyUI is hidden (3D in-world button active)")
		passed += 1
	else:
		printerr("  [FAIL] BtnStartVote in SocialLobbyUI is visible or null")
		failed += 1

	social_ui.update_lobby_info("TestRoom", "127.0.0.1", 1, 8, true)
	if not social_ui.btn_start_vote.visible:
		print("  [PASS] BtnStartVote remains hidden after update_lobby_info(host=true)")
		passed += 1
	else:
		printerr("  [FAIL] BtnStartVote became visible after update_lobby_info")
		failed += 1

	var vote_ui_scene = load("res://scenes/ui/VoteUI.tscn")
	var vote_ui = vote_ui_scene.instantiate()
	root.add_child(vote_ui)
	vote_ui._on_vote_started(10.0)
	if not vote_ui.visible:
		print("  [PASS] VoteUI modal cards remain hidden during vote (scoreboard & stations handle display)")
		passed += 1
	else:
		printerr("  [FAIL] VoteUI became visible during vote")
		failed += 1

	social_ui.queue_free()
	vote_ui.queue_free()

	# --- Summary ---
	print("\n======================================================================")
	print(" SUMMARY: %d PASSED, %d FAILED" % [passed, failed])
	print("======================================================================")

	if failed == 0:
		print(">>> ALL 3D VOTING & ENCLOSED LOBBY TESTS PASSED! <<<\n")
		quit(0)
	else:
		printerr(">>> SOME TESTS FAILED! <<<\n")
		quit(1)
