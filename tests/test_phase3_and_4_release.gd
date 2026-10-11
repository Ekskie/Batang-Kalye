extends SceneTree

# test_phase3_and_4_release.gd
# Verification suite for Phase 3 (UI & Lobby Streamlining) & Phase 4 (Match Recap, Map Optimization & Awards)

const LobbyUIScript = preload("res://scripts/ui/LobbyUI.gd")
const SocialLobbyUIScript = preload("res://scripts/ui/SocialLobbyUI.gd")
const VoteManagerScript = preload("res://scripts/gameplay/VoteManager.gd")
const GameOverUIScript = preload("res://scripts/ui/GameOverUI.gd")
const GameManagerScript = preload("res://scripts/gameplay/GameManager.gd")
const KalyeMatchMapScript = preload("res://scripts/gameplay/KalyeMatchMap.gd")

var passed_count: int = 0
var failed_count: int = 0

func _init() -> void:
	call_deferred("_run_all_tests")

func assert_true(cond: bool, msg: String) -> void:
	if cond:
		print("  [PASS] %s" % msg)
		passed_count += 1
	else:
		push_error("  [FAIL] %s" % msg)
		failed_count += 1

func assert_false(cond: bool, msg: String) -> void:
	assert_true(not cond, msg)

func assert_eq(a, b, msg: String) -> void:
	if a == b:
		print("  [PASS] %s" % msg)
		passed_count += 1
	else:
		push_error("  [FAIL] %s (Expected: %s, Got: %s)" % [msg, str(b), str(a)])
		failed_count += 1

func _run_all_tests() -> void:
	print("\n======================================================================")
	print(" [PHASE 3 & 4 VERIFICATION] UI, LOBBY, MAP OPTIMIZATION & RECAP SUITE")
	print("======================================================================")

	_test_lobby_ui_streamlining()
	_test_vote_manager_and_late_join_sync()
	_test_social_lobby_ui_voting_controls()
	_test_kalye_match_map_no_trimesh()
	_test_authentic_awards_and_recap()

	print("\n======================================================================")
	print(" PHASE 3 & 4 SUMMARY: %d PASSED, %d FAILED" % [passed_count, failed_count])
	print("======================================================================")

	if failed_count == 0:
		print(">>> ALL PHASE 3 & 4 TESTS PASSED! RELEASE QUALITY VERIFIED! <<<\n")
		quit(0)
	else:
		push_error(">>> SOME TESTS FAILED! <<<\n")
		quit(1)

func _test_lobby_ui_streamlining() -> void:
	print("\n--- [1] LobbyUI Streamlining (No Duplicate 2D Panels or Mode Dropdown) ---")
	var scene: PackedScene = load("res://scenes/ui/LobbyUI.tscn")
	assert_true(scene != null, "LobbyUI.tscn loads successfully")
	var lobby_inst: Control = scene.instantiate() as Control
	root.add_child(lobby_inst)

	# 1. Check PanelRoomWaiting is removed from scene
	var waiting_panel = lobby_inst.get_node_or_null("Margin/VBox/MainHBox/RightColumn/LobbyCard/Margin/VBox/ContentPanels/PanelRoomWaiting")
	assert_true(waiting_panel == null, "Redundant 2D PanelRoomWaiting is absent from scene tree")

	# 2. Check ModeRow is removed from PanelCreate
	var mode_row = lobby_inst.get_node_or_null("Margin/VBox/MainHBox/RightColumn/LobbyCard/Margin/VBox/ContentPanels/PanelCreate/ModeRow")
	assert_true(mode_row == null, "Duplicate ModeRow dropdown absent from PanelCreate (handled exclusively in 3D lobby)")

	# 3. Check Create Room submission
	var emitted_args: Array = []
	lobby_inst.create_room_submitted.connect(func(r_name, m_id, dur, max_p):
		emitted_args.append(r_name)
		emitted_args.append(m_id)
		emitted_args.append(dur)
		emitted_args.append(max_p)
	)
	lobby_inst._on_create_submit_pressed()
	assert_true(emitted_args.size() == 4, "create_room_submitted emitted with expected 4 arguments")
	assert_eq(emitted_args[0], "Tambayan Room", "Default room name is 'Tambayan Room'")
	assert_eq(emitted_args[1], 0, "Default mode passed cleanly (voting court decides actual mode)")

	lobby_inst.queue_free()

func _test_vote_manager_and_late_join_sync() -> void:
	print("\n--- [2] VoteManager Multiple-Trigger Guard & Late-Joining Synchronization ---")
	var vm := VoteManagerScript.new()
	root.add_child(vm)

	# 1. Start voting
	vm.start_voting(10.0)
	assert_true(vm.is_voting, "Vote is now active")
	assert_eq(vm.vote_timer, 10.0, "Vote timer initialized to 10.0s")

	# 2. Prevent accidental multiple vote starts
	vm.vote_timer = 5.5
	vm.start_voting(10.0) # Attempt to re-trigger
	assert_eq(vm.vote_timer, 5.5, "Accidental duplicate vote start was prevented; timer preserved at 5.5s")

	# 3. Test late-joining sync logic
	var client_vm := VoteManagerScript.new()
	root.add_child(client_vm)
	assert_false(client_vm.is_voting, "Client VM initialized as not voting")

	var client_box: Array = [false, 0.0]
	client_vm.vote_started.connect(func(t): client_box[0] = true)
	client_vm.vote_updated.connect(func(counts, t): client_box[1] = t)

	# Simulate late join payload received from authority
	client_vm.sync_late_join_voting_state({ 0: 2, 1: 1, 2: 0 }, 5.5, 10.0)

	assert_true(client_vm.is_voting, "Late-joining client transitioned to is_voting = true")
	assert_true(client_box[0], "Late-joining client emitted vote_started signal")
	assert_eq(client_vm.vote_timer, 5.5, "Late-joining client synchronized vote_timer to 5.5s")
	assert_eq(client_vm.current_counts[0], 2, "Late-joining client synchronized vote counts for mode 0")

	# Also test periodic sync_vote_state activating un-initialized client
	var client2_vm := VoteManagerScript.new()
	root.add_child(client2_vm)
	client2_vm.sync_vote_state({ 1: 3 }, 4.0)
	assert_true(client2_vm.is_voting, "Client 2 activated voting from periodic sync_vote_state")
	assert_eq(client2_vm.vote_timer, 4.0, "Client 2 timer updated to 4.0s")

	vm.queue_free()
	client_vm.queue_free()
	client2_vm.queue_free()

func _test_social_lobby_ui_voting_controls() -> void:
	print("\n--- [3] SocialLobbyUI Dynamic Voting Button Controls ---")
	var scene: PackedScene = load("res://scenes/ui/SocialLobbyUI.tscn")
	assert_true(scene != null, "SocialLobbyUI.tscn loads successfully")
	var social_inst: Control = scene.instantiate() as Control
	root.add_child(social_inst)

	var btn_vote: Button = social_inst.btn_start_vote
	assert_true(btn_vote != null, "BtnStartVote exists in SocialLobbyUI")

	# 1. Update voting active state
	social_inst.set_voting_active(true)
	assert_true(btn_vote.disabled, "BtnStartVote disabled while voting is active")
	assert_eq(btn_vote.text, "BUMOBOTO NA...", "BtnStartVote displays 'BUMOBOTO NA...' status")

	# 2. Reset voting active state
	social_inst.set_voting_active(false)
	assert_false(btn_vote.disabled, "BtnStartVote re-enabled after vote ends")
	assert_eq(btn_vote.text, "★ BUMOTO NG LARO ★", "BtnStartVote restored to '★ BUMOTO NG LARO ★'")

	social_inst.queue_free()

func _test_kalye_match_map_no_trimesh() -> void:
	print("\n--- [4] KalyeMatchMap Performance (Zero Concave Trimesh Snags) ---")
	var scene: PackedScene = load("res://scenes/maps/KalyeMatchMap.tscn")
	assert_true(scene != null, "KalyeMatchMap.tscn loads successfully")
	var map: Node3D = scene.instantiate() as Node3D
	root.add_child(map)

	# Verify that no ConcavePolygonShape3D shapes exist on props (only convex or boxes)
	var concave_count := 0
	var convex_count := 0
	for child in map.find_children("*", "CollisionShape3D", true, false):
		var cs := child as CollisionShape3D
		if cs.shape is ConcavePolygonShape3D:
			concave_count += 1
		elif cs.shape is ConvexPolygonShape3D:
			convex_count += 1

	print("  [INFO] Found %d Concave and %d Convex prop colliders" % [concave_count, convex_count])
	assert_eq(concave_count, 0, "Zero concave trimesh collisions dynamically created on props (avoids hitches and vault snags)")
	assert_true(convex_count > 0, "Convex collision hulls generated cleanly for solid structures")

	map.queue_free()

func _test_authentic_awards_and_recap() -> void:
	print("\n--- [5] Authentic Post-Match Recap & Awards Calculation ---")
	var gm := GameManagerScript.new()

	# Test 1: All 0 stats should result in 'Walang Award', NOT player 0 fallback
	var zero_players: Array[Dictionary] = [
		{ "name": "Totoy", "huli": 0, "patama": 0, "dulas": 0, "basura": 0, "tago": 0, "vaults": 0, "surv": 0.0, "sprint_time": 0.0 },
		{ "name": "Nene",  "huli": 0, "patama": 0, "dulas": 0, "basura": 0, "tago": 0, "vaults": 0, "surv": 0.0, "sprint_time": 0.0 }
	]

	var zero_awards: Dictionary = gm._calculate_kalye_awards(zero_players)
	assert_eq(zero_awards["taya_master"], "Walang Award", "Zero tags -> taya_master is 'Walang Award' (no fake fallback)")
	assert_eq(zero_awards["vault_king"], "Walang Award", "Zero vaults -> vault_king is 'Walang Award'")
	assert_eq(zero_awards["sprint_king"], "Walang Award", "Zero sprint -> sprint_king is 'Walang Award' (not aliased to dulas)")
	assert_eq(zero_awards["basura"], "Walang Award", "Zero recycled -> basura is 'Walang Award'")

	# Test 2: Authentic stats assign awards properly to deserving players
	var real_players: Array[Dictionary] = [
		{ "name": "Totoy", "huli": 3, "patama": 2, "dulas": 1, "basura": 0, "tago": 0, "vaults": 5, "surv": 15.0, "sprint_time": 6.5 },
		{ "name": "Nene",  "huli": 0, "patama": 0, "dulas": 0, "basura": 4, "tago": 1, "vaults": 1, "surv": 45.0, "sprint_time": 1.2 },
		{ "name": "Tisoy", "huli": 1, "patama": 5, "dulas": 0, "basura": 1, "tago": 4, "vaults": 0, "surv": 20.0, "sprint_time": 4.0 }
	]

	var real_awards: Dictionary = gm._calculate_kalye_awards(real_players)
	assert_eq(real_awards["taya_master"], "Totoy", "Totoy (3 tags) awarded Taya Master")
	assert_eq(real_awards["vault_king"], "Totoy", "Totoy (5 vaults) awarded Vault King")
	assert_eq(real_awards["sprint_king"], "Totoy", "Totoy (6.5s sprint) awarded Sprint King based on authentic sprint time")
	assert_eq(real_awards["basura"], "Nene", "Nene (4 recycled) awarded Basura Champion")
	assert_eq(real_awards["sniper"], "Tisoy", "Tisoy (5 hits) awarded Sniper")
	assert_eq(real_awards["escape_artist"], "Nene", "Nene (45s survival) awarded Escape Artist")

	# Test 3: GameOverUI display rendering
	var game_over_scene: PackedScene = load("res://scenes/ui/GameOverUI.tscn")
	assert_true(game_over_scene != null, "GameOverUI.tscn loads successfully")
	var go_ui: Control = game_over_scene.instantiate() as Control
	root.add_child(go_ui)

	# Verify awards card displays '-' for Walang Award
	go_ui._populate_awards_card(zero_awards)
	var labels: Array[Node] = go_ui.awards_container.find_children("*", "Label", true, false)
	var dash_count := 0
	for lbl in labels:
		if (lbl as Label).text == "-":
			dash_count += 1
	assert_eq(dash_count, 5, "All 5 award slots display clean '-' when unearned")

	go_ui.queue_free()
	gm.free()
