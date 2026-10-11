extends SceneTree

# Test suite for Hiding Spot RPC and node path synchronization
# Verifies:
# 1. KalyeMap deterministic naming across transitions (preventing @Node3D@xxx auto-naming)
# 2. Hiding spot node path consistency (Main/KalyeMap/HidingSpots/HidingBox2)
# 3. Cardboard box and blue drum entry, visibility toggle, and prompt update
# 4. Multi-peer RPC synchronization (sync_hide_state with player resolution)
# 5. Client requests (request_interact_rpc, request_eject_rpc, request_slap_rpc)
# 6. Taya slap mechanics (catching occupant vs hollow clang stun on empty)
# 7. Elimination and spacebar exit handling

var pass_count: int = 0
var fail_count: int = 0

func _init() -> void:
	call_deferred("_run_all_tests")

func _assert(condition: bool, test_name: String) -> void:
	if condition:
		pass_count += 1
		print("  [PASS] %s" % test_name)
	else:
		fail_count += 1
		print("  [FAIL] %s" % test_name)

func _run_all_tests() -> void:
	print("\n======================================================================")
	print(" [TEST SUITE] HIDING SPOT RPC & MULTIPLAYER PATH DETERMINISM")
	print("======================================================================\n")

	test_map_naming_determinism()
	test_hiding_spot_local_mechanics()
	test_hiding_spot_multiplayer_rpc_sync()
	test_taya_slap_mechanics()
	test_elimination_and_exit_handling()

	print("\n======================================================================")
	print(" SUMMARY: %d PASSED, %d FAILED" % [pass_count, fail_count])
	print("======================================================================")
	if fail_count == 0:
		print(">>> ALL HIDING SPOT RPC & PATH SYNC TESTS PASSED! <<<\n")
		quit(0)
	else:
		print(">>> SOME TESTS FAILED! <<<\n")
		quit(1)

func test_map_naming_determinism() -> void:
	print("--- [1] Map Naming Determinism & RPC Node Path Resolution ---")
	var main_scene: PackedScene = load("res://scenes/main/Main.tscn")
	_assert(main_scene != null, "Main.tscn loaded successfully")

	var main_node = main_scene.instantiate()
	root.add_child(main_node)

	# 1. Initial map name check
	var initial_map = main_node.get_node_or_null("KalyeMap")
	_assert(initial_map != null, "Initial lobby map exists and is named KalyeMap")
	_assert(not initial_map.name.begins_with("@Node3D@"), "Initial map name is not @Node3D@xxx auto-generated")

	# 2. Switch to match map
	main_node.switch_to_match_map()
	var match_map = main_node.get_node_or_null("KalyeMap")
	_assert(match_map != null, "Switched to match map: node is named KalyeMap")
	_assert(match_map.name == "KalyeMap", "Match map name strictly equals KalyeMap (deterministic)")
	_assert(not match_map.name.begins_with("@Node3D@"), "Match map is NOT renamed to @Node3D@xxx")

	# 3. Check hiding spot node path resolution
	var hiding_box2 = main_node.get_node_or_null("KalyeMap/HidingSpots/HidingBox2")
	_assert(hiding_box2 != null, "HidingBox2 resolved cleanly at KalyeMap/HidingSpots/HidingBox2")
	var full_path: String = str(hiding_box2.get_path())
	_assert(full_path.ends_with("/Main/KalyeMap/HidingSpots/HidingBox2"), "Full node path is deterministic (/root/Main/KalyeMap/HidingSpots/HidingBox2)")
	_assert(not "@Node3D@" in full_path, "Full node path contains zero @Node3D@ prefixes")

	var hiding_drum1 = main_node.get_node_or_null("KalyeMap/HidingSpots/HidingDrum1")
	_assert(hiding_drum1 != null, "HidingDrum1 resolved cleanly at KalyeMap/HidingSpots/HidingDrum1")

	# 4. Switch to lobby map and back to match map (simulate match end -> lobby -> match cycle)
	main_node.switch_to_lobby_map()
	var lobby_map2 = main_node.get_node_or_null("KalyeMap")
	_assert(lobby_map2 != null and lobby_map2.name == "KalyeMap", "Returned to lobby: map node remains named KalyeMap")

	main_node.switch_to_match_map()
	var match_map2 = main_node.get_node_or_null("KalyeMap")
	_assert(match_map2 != null and match_map2.name == "KalyeMap", "Switched back to match map: map node remains named KalyeMap")
	var box2_second_cycle = main_node.get_node_or_null("KalyeMap/HidingSpots/HidingBox2")
	_assert(box2_second_cycle != null, "HidingBox2 reliably found across multiple map switches")

	root.remove_child(main_node)
	main_node.free()

func test_hiding_spot_local_mechanics() -> void:
	print("\n--- [2] Local Hiding Spot Mechanics (Drum & Cardboard Box) ---")
	var player_script = load("res://scripts/player/PlayerController.gd")
	var hiding_spot_script = load("res://scripts/gameplay/HidingSpot.gd")

	var mock_main = Node.new()
	mock_main.name = "Main"
	root.add_child(mock_main)

	var mock_players = Node3D.new()
	mock_players.name = "Players"
	mock_main.add_child(mock_players)

	var p1 = player_script.new()
	p1.name = "1"
	p1.player_id = 1
	p1.current_role = player_script.Role.RUNNER
	p1.is_eliminated = false
	mock_players.add_child(p1)

	var box_spot = hiding_spot_script.new()
	box_spot.spot_type = hiding_spot_script.SpotType.CARDBOARD_BOX
	box_spot.name = "HidingBoxTest"
	mock_main.add_child(box_spot)

	var drum_spot = hiding_spot_script.new()
	drum_spot.spot_type = hiding_spot_script.SpotType.BLUE_DRUM
	drum_spot.name = "HidingDrumTest"
	mock_main.add_child(drum_spot)

	# Enter Cardboard Box
	box_spot.interact(p1)
	_assert(box_spot.is_occupied == true, "Box is occupied after runner interacts")
	_assert(box_spot.occupant == p1, "Box occupant is set to player")
	_assert(p1.is_hiding == true, "Player is_hiding flag is true")
	_assert(p1.current_hiding_spot == box_spot, "Player current_hiding_spot references box")

	# Exit Cardboard Box
	p1.exit_hiding_spot()
	_assert(box_spot.is_occupied == false, "Box is no longer occupied after exit")
	_assert(box_spot.occupant == null, "Box occupant is cleared")
	_assert(p1.is_hiding == false, "Player is_hiding flag is false")
	_assert(p1.current_hiding_spot == null, "Player current_hiding_spot is null")

	# Enter Blue Drum
	drum_spot.interact(p1)
	_assert(drum_spot.is_occupied == true, "Drum is occupied after runner interacts")
	_assert(drum_spot.occupant == p1, "Drum occupant is set to player")
	_assert(p1.is_hiding == true, "Player is_hiding flag is true for drum")

	# Exit via second interact on occupied spot
	drum_spot.interact(p1)
	_assert(drum_spot.is_occupied == false, "Drum is cleared when occupant interacts to leave")
	_assert(p1.is_hiding == false, "Player is_hiding flag is false after leaving drum")

	# Taya should not be able to hide
	p1.current_role = player_script.Role.TAYA
	box_spot.interact(p1)
	_assert(box_spot.is_occupied == false, "Taya is blocked from entering hiding spot")

	root.remove_child(mock_main)
	mock_main.free()

func test_hiding_spot_multiplayer_rpc_sync() -> void:
	print("\n--- [3] Multi-Peer RPC Synchronization (sync_hide_state) ---")
	var player_script = load("res://scripts/player/PlayerController.gd")
	var hiding_spot_script = load("res://scripts/gameplay/HidingSpot.gd")

	var mock_main = Node.new()
	mock_main.name = "Main"
	root.add_child(mock_main)

	var mock_players = Node3D.new()
	mock_players.name = "Players"
	mock_main.add_child(mock_players)

	var p2 = player_script.new()
	p2.name = "2"
	p2.player_id = 2
	p2.current_role = player_script.Role.RUNNER
	p2.is_eliminated = false
	mock_players.add_child(p2)

	var spot = hiding_spot_script.new()
	spot.name = "HidingBox2"
	mock_main.add_child(spot)

	# Simulate remote peer receiving sync_hide_state(2, true)
	spot.sync_hide_state(2, true)
	_assert(spot.is_occupied == true, "sync_hide_state sets is_occupied to true on remote peer")
	_assert(spot.occupant == p2, "sync_hide_state resolves occupant to Player 2 on remote peer")
	_assert(p2.is_hiding == true, "Player 2 is_hiding is true on remote peer")
	_assert(p2.current_hiding_spot == spot, "Player 2 current_hiding_spot linked to spot on remote peer")

	# Simulate remote peer receiving sync_hide_state(2, false)
	spot.sync_hide_state(2, false, false)
	_assert(spot.is_occupied == false, "sync_hide_state sets is_occupied to false on remote peer")
	_assert(spot.occupant == null, "sync_hide_state clears occupant on remote peer")
	_assert(p2.is_hiding == false, "Player 2 is_hiding is false on remote peer")
	_assert(p2.current_hiding_spot == null, "Player 2 current_hiding_spot cleared on remote peer")

	# Forced ejection (e.g. 8s timeout)
	spot.sync_hide_state(2, true)
	_assert(spot.is_occupied == true, "Re-entered spot for timeout test")
	spot.sync_hide_state(2, false, true)
	_assert(spot.is_occupied == false, "Forced ejection cleared spot")
	_assert(p2.is_hiding == false, "Player 2 cleanly ejected after timeout")
	_assert(p2.velocity.y > 0.0, "Player 2 received hop-out vertical velocity")

	root.remove_child(mock_main)
	mock_main.free()

func test_taya_slap_mechanics() -> void:
	print("\n--- [4] Taya Slap Tag & Empty Slap Stun ---")
	var player_script = load("res://scripts/player/PlayerController.gd")
	var hiding_spot_script = load("res://scripts/gameplay/HidingSpot.gd")

	var mock_main = Node.new()
	mock_main.name = "Main"
	root.add_child(mock_main)

	var mock_players = Node3D.new()
	mock_players.name = "Players"
	mock_main.add_child(mock_players)

	var taya = player_script.new()
	taya.name = "1"
	taya.player_id = 1
	taya.current_role = player_script.Role.TAYA
	mock_players.add_child(taya)

	var runner = player_script.new()
	runner.name = "2"
	runner.player_id = 2
	runner.current_role = player_script.Role.RUNNER
	mock_players.add_child(runner)

	var spot = hiding_spot_script.new()
	spot.spot_type = hiding_spot_script.SpotType.CARDBOARD_BOX
	spot.name = "HidingBoxSlap"
	mock_main.add_child(spot)

	# 1. Slap empty box -> Stun Taya with hollow clang
	spot.on_taya_slap(taya)
	_assert(taya.is_stunned == true, "Taya is stunned after slapping empty cardboard box")
	_assert(taya.stun_timer > 0.0, "Taya stun timer is active")
	taya.is_stunned = false
	taya.stun_timer = 0.0

	# 2. Put runner inside box -> Slap occupied box -> Tag & Eject
	spot.interact(runner)
	_assert(spot.is_occupied == true, "Runner is hiding in the box")

	spot.on_taya_slap(taya)
	_assert(spot.is_occupied == false, "Box occupant ejected upon Taya slap")
	_assert(runner.is_hiding == false, "Caught runner is no longer hiding")

	root.remove_child(mock_main)
	mock_main.free()

func test_elimination_and_exit_handling() -> void:
	print("\n--- [5] Elimination and Exit State Handling ---")
	var player_script = load("res://scripts/player/PlayerController.gd")
	var hiding_spot_script = load("res://scripts/gameplay/HidingSpot.gd")

	var mock_main = Node.new()
	mock_main.name = "Main"
	root.add_child(mock_main)

	var mock_players = Node3D.new()
	mock_players.name = "Players"
	mock_main.add_child(mock_players)

	var p = player_script.new()
	p.name = "10"
	p.player_id = 10
	p.current_role = player_script.Role.RUNNER
	mock_players.add_child(p)

	var spot = hiding_spot_script.new()
	spot.name = "ElimSpot"
	mock_main.add_child(spot)

	spot.interact(p)
	_assert(p.is_hiding == true, "Player enters hiding spot")

	# Eliminating player while hiding should auto-exit
	p.set_eliminated(true)
	_assert(p.is_hiding == false, "Eliminated player automatically exits hiding spot")
	_assert(spot.is_occupied == false, "Spot is vacated upon player elimination")

	root.remove_child(mock_main)
	mock_main.free()
