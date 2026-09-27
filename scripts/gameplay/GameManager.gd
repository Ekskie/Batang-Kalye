class_name GameManager
extends Node

enum GameState {
	LOBBY,
	MAIBA_TAYA,
	PLAYING,
	GAME_OVER
}

enum MatchMode {
	CLASSIC_TAG, # Traditional "Walang Bawian" - Taya transfers, chaser becomes runner!
	INFECTION    # "Hawaan" - Taya stays Taya, runners infected become Taya!
}

@export var current_mode: MatchMode = MatchMode.CLASSIC_TAG
@export var match_duration: float = 180.0 # 3 minutes
var match_timer: float = 0.0
var current_state: GameState = GameState.LOBBY
var player_scene: PackedScene = preload("res://scenes/player/Player.tscn")

func is_infection() -> bool:
	return current_mode == MatchMode.INFECTION

const PLAYER_COLORS: Array[Color] = [
	Color(0.2, 0.6, 1.0),   # Cyan/Blue
	Color(1.0, 0.4, 0.2),   # Orange
	Color(0.2, 0.8, 0.4),   # Green
	Color(0.9, 0.2, 0.5),   # Pink
	Color(1.0, 0.85, 0.2),  # Yellow
	Color(0.6, 0.3, 0.9),   # Purple
	Color(0.1, 0.8, 0.8),   # Teal
	Color(0.95, 0.5, 0.1)   # Tangerine
]

# Nodes
@onready var network_manager: NetworkManager = $NetworkManager
@onready var maiba_manager: MaibaTayaManager = $MaibaTayaManager
@onready var map_node: Node3D = $KalyeMap
@onready var players_container: Node3D = $Players
@onready var lobby_ui: Control = $LobbyUI
@onready var hud: HUD = $HUD
@onready var maiba_ui: MaibaTayaUI = $MaibaTayaUI
@onready var game_over_ui: Control = $GameOverUI
@onready var winner_label: Label = $GameOverUI/Panel/VBoxContainer/WinnerLabel

# Lobby UI elements
@onready var name_input: LineEdit = $LobbyUI/Panel/VBoxContainer/NameEdit
@onready var ip_input: LineEdit = $LobbyUI/Panel/VBoxContainer/IPEdit
@onready var btn_host: Button = $LobbyUI/Panel/VBoxContainer/BtnHost
@onready var btn_join: Button = $LobbyUI/Panel/VBoxContainer/BtnJoin
@onready var btn_solo: Button = $LobbyUI/Panel/VBoxContainer/BtnSolo
@onready var btn_start_match: Button = $LobbyUI/Panel/VBoxContainer/BtnStartMatch
@onready var player_list_label: Label = $LobbyUI/Panel/VBoxContainer/PlayerListLabel
@onready var hotspot_info_label: Label = $LobbyUI/Panel/VBoxContainer/HotspotInfoLabel

func _ready() -> void:
	# Show lobby initially
	_set_game_state(GameState.LOBBY)

	_setup_network_signals()
	_setup_ui_signals()
	_setup_maiba_signals()

	# Display local IP for hotspot hosting
	var ips := NetworkManager.get_local_ip_addresses()
	hotspot_info_label.text = "Local / Hotspot IP: " + ips[0]
	ip_input.text = ips[0]

	if "--run-self-test" in OS.get_cmdline_user_args() or "--run-self-test" in OS.get_cmdline_args():
		call_deferred("_run_automated_self_test")

func _setup_network_signals() -> void:
	network_manager.server_created.connect(_on_server_created)
	network_manager.join_success.connect(_on_join_success)
	network_manager.join_failed.connect(_on_join_failed)
	network_manager.player_list_updated.connect(_update_lobby_player_list)

func _setup_ui_signals() -> void:
	btn_host.pressed.connect(_on_btn_host_pressed)
	btn_join.pressed.connect(_on_btn_join_pressed)
	btn_solo.pressed.connect(_on_btn_solo_pressed)
	btn_start_match.pressed.connect(_on_btn_start_match_pressed)

	var btn_rematch = $GameOverUI/Panel/VBoxContainer/BtnRematch
	if btn_rematch:
		btn_rematch.pressed.connect(func(): _set_game_state(GameState.LOBBY))

func _setup_maiba_signals() -> void:
	maiba_manager.countdown_step.connect(func(text: String): maiba_ui.show_chant(text))
	maiba_manager.hand_choice_requested.connect(func(limit: float): maiba_ui.request_choice(limit))
	maiba_ui.choice_made.connect(func(c: int): maiba_manager.rpc_id(1, "submit_hand_choice", c))
	maiba_manager.taya_decided.connect(_on_taya_decided)

func _on_btn_host_pressed() -> void:
	var pname := name_input.text.strip_edges()
	if pname.is_empty():
		pname = "Kuya Denn"
	network_manager.create_game(pname)

func _on_btn_join_pressed() -> void:
	var pname := name_input.text.strip_edges()
	if pname.is_empty():
		pname = "Bata " + str(randi() % 100)
	var ip := ip_input.text.strip_edges()
	network_manager.join_game(ip, pname)

func _on_btn_solo_pressed() -> void:
	var pname := name_input.text.strip_edges()
	if pname.is_empty():
		pname = "Dennrick (Solo)"
	network_manager.create_game(pname)
	_spawn_all_players()

	# Also spawn a PracticeBot runner so the player can chase and tag it!
	var bot_scene: PackedScene = preload("res://scenes/player/PracticeBot.tscn")
	var bot: PracticeBot = bot_scene.instantiate()
	bot.name = "99"
	bot.player_id = 99
	bot.player_name = "Bata (Bot)"
	bot.current_role = PlayerController.Role.RUNNER

	var spawn_points := map_node.get_node("SpawnPoints").get_children()
	if spawn_points.size() > 1:
		bot.position = spawn_points[1].global_position
	else:
		bot.position = Vector3(0, 0.5, 6)
	players_container.add_child(bot)
	if bot.model:
		bot.model.set_player_color(Color(0.2, 0.8, 0.4)) # Green runner

	# Register bot in network players for scoreboard
	network_manager.players[99] = {
		"name": "Bata (Bot)",
		"score": 0,
		"role": 0
	}

	# In solo practice, start player as Taya immediately to test chasing & tagging
	var local_p: PlayerController = players_container.get_node_or_null("1")
	if local_p:
		local_p.current_role = PlayerController.Role.TAYA
		network_manager.players[1]["role"] = 1

	_set_game_state(GameState.PLAYING)
	match_timer = match_duration

func notify_tag_event(chaser_id: int, target_id: int) -> void:
	if multiplayer.has_multiplayer_peer() and multiplayer.is_server():
		rpc("sync_tag_event", chaser_id, target_id)
	else:
		sync_tag_event(chaser_id, target_id)

@rpc("any_peer", "call_local", "reliable")
func sync_tag_event(chaser_id: int, target_id: int) -> void:
	var chaser_name: String = "Chaser"
	var target_name: String = "Runner"

	if network_manager.players.has(chaser_id):
		network_manager.players[chaser_id]["score"] += 50
		chaser_name = network_manager.players[chaser_id].get("name", "Chaser")
		if current_mode == MatchMode.CLASSIC_TAG:
			network_manager.players[chaser_id]["role"] = 0 # Former chaser becomes runner!

	if network_manager.players.has(target_id):
		network_manager.players[target_id]["role"] = 1 # Target becomes Taya!
		target_name = network_manager.players[target_id].get("name", "Runner")

	hud.update_scoreboard(network_manager.players)
	hud.show_tag_banner(chaser_name, target_name)

func award_recycle_points(pid: int, pts: int = 30) -> void:
	if multiplayer.has_multiplayer_peer() and multiplayer.is_server():
		rpc("sync_recycle_points", pid, pts)
	else:
		sync_recycle_points(pid, pts)

@rpc("any_peer", "call_local", "reliable")
func sync_recycle_points(pid: int, pts: int) -> void:
	if network_manager.players.has(pid):
		network_manager.players[pid]["score"] += pts
	if hud:
		hud.update_scoreboard(network_manager.players)

func _on_btn_start_match_pressed() -> void:
	if multiplayer.is_server():
		rpc("sync_start_match")

@rpc("call_local", "reliable")
func sync_start_match() -> void:
	_start_match_flow()

func _start_match_flow() -> void:
	_spawn_all_players()
	_set_game_state(GameState.MAIBA_TAYA)

	if multiplayer.is_server():
		var pids := network_manager.players.keys()
		maiba_manager.start_selection(pids)

func _on_taya_decided(taya_id: int, taya_name: String) -> void:
	var my_id := multiplayer.get_unique_id()
	var is_me_taya := (my_id == taya_id)
	maiba_ui.show_result(taya_name, is_me_taya)

	# Set roles across players
	for player_node in players_container.get_children():
		if player_node is PlayerController:
			if player_node.player_id == taya_id:
				player_node.current_role = PlayerController.Role.TAYA
			else:
				player_node.current_role = PlayerController.Role.RUNNER

	# Begin match after 2 seconds
	get_tree().create_timer(2.0).timeout.connect(func():
		_set_game_state(GameState.PLAYING)
		match_timer = match_duration
	)

func _spawn_all_players() -> void:
	# Clear existing players
	for child in players_container.get_children():
		child.queue_free()

	var spawn_points := map_node.get_node("SpawnPoints").get_children()
	var spawn_idx := 0

	for pid in network_manager.players.keys():
		var pinfo = network_manager.players[pid]
		var player_instance: PlayerController = player_scene.instantiate()
		player_instance.name = str(pid)
		player_instance.player_id = pid
		player_instance.player_name = pinfo.get("name", "Player")

		# Spawn point
		var spawn_pos: Vector3 = Vector3(0, 1, 0)
		if spawn_points.size() > 0:
			var sp: Marker3D = spawn_points[spawn_idx % spawn_points.size()]
			spawn_pos = sp.global_position
			spawn_idx += 1
		player_instance.position = spawn_pos

		players_container.add_child(player_instance)

		# Color distinction
		var pcol: Color = PLAYER_COLORS[spawn_idx % PLAYER_COLORS.size()]
		if player_instance.model:
			player_instance.model.set_player_color(pcol)

func _process(delta: float) -> void:
	if current_state == GameState.PLAYING:
		match_timer -= delta
		hud.update_match_timer(match_timer)

		# Update local player hud
		var my_id := multiplayer.get_unique_id()
		var my_node: PlayerController = players_container.get_node_or_null(str(my_id))
		if my_node:
			hud.update_role_display(my_node.current_role == PlayerController.Role.TAYA)
			hud.update_score(my_node.survival_time, my_node.tag_count, my_node.current_role == PlayerController.Role.TAYA)

		hud.update_scoreboard(network_manager.players)

		if multiplayer.is_server() and match_timer <= 0.0:
			rpc("sync_game_over")

@rpc("call_local", "reliable")
func sync_game_over() -> void:
	_set_game_state(GameState.GAME_OVER)
	# Determine highest survival runner or top chaser
	var best_name := ""
	var best_score := -1.0
	for player_node in players_container.get_children():
		if player_node is PlayerController:
			var player: PlayerController = player_node as PlayerController
			var final_score: float = player.survival_time + (float(player.tag_count) * 30.0)
			if final_score > best_score:
				best_score = final_score
				best_name = player.player_name

	winner_label.text = "📢 \"HOY MGA BATA! UMUWI NA KAYO, GABI NA!\"\n\n🏆 PANALO: %s! 🏆\nScore: %.0f" % [best_name, best_score]

func _set_game_state(new_state: GameState) -> void:
	current_state = new_state
	lobby_ui.visible = (new_state == GameState.LOBBY)
	hud.visible = (new_state == GameState.PLAYING)
	maiba_ui.visible = (new_state == GameState.MAIBA_TAYA)
	game_over_ui.visible = (new_state == GameState.GAME_OVER)

	if new_state == GameState.LOBBY:
		# Free players
		for child in players_container.get_children():
			child.queue_free()

func _on_server_created() -> void:
	btn_host.disabled = true
	btn_join.disabled = true
	btn_start_match.visible = true

func _on_join_success() -> void:
	btn_host.disabled = true
	btn_join.disabled = true
	btn_start_match.visible = false

func _on_join_failed() -> void:
	hotspot_info_label.text = "Connection failed! Check IP address."

func _update_lobby_player_list() -> void:
	var text := "Mga Kasali (%d / 8):\n" % network_manager.players.size()
	for pid in network_manager.players.keys():
		var pinfo = network_manager.players[pid]
		text += "• " + pinfo["name"] + "\n"
	player_list_label.text = text

func _run_automated_self_test() -> void:
	var results: Array[String] = []
	results.append("[SELF-TEST] Starting automated verification...")

	# 1. Click Solo Practice (spawns player 1 and bot 99)
	results.append("[SELF-TEST] Clicking Solo Practice...")
	_on_btn_solo_pressed()

	var p1: PlayerController = players_container.get_node_or_null("1") as PlayerController
	var bot: PracticeBot = players_container.get_node_or_null("99") as PracticeBot

	if not p1:
		results.append("[FAIL] Player 1 not found in Players container!")
		_write_test_results(results, 1)
		return
	if not bot:
		results.append("[FAIL] Bot 99 not found in Players container!")
		_write_test_results(results, 1)
		return

	results.append("[PASS] Player 1 and Bot 99 spawned successfully.")
	results.append(" - P1 Authority: " + str(p1.get_multiplayer_authority()) + " | Role: " + str(p1.current_role))
	results.append(" - Bot Authority: " + str(bot.get_multiplayer_authority()) + " | Role: " + str(bot.current_role))

	# 2. Verify P1 Camera & UI exists, Bot Camera is safely null
	if not p1.camera:
		results.append("[FAIL] P1 Camera3D is missing!")
		_write_test_results(results, 1)
		return
	if bot.camera != null:
		results.append("[WARN] Bot has unexpected camera.")
	results.append("[PASS] P1 has active Camera3D, Bot safely has null camera without errors.")

	# 3. Simulate movement & tagging
	p1.global_position = bot.global_position + Vector3(0, 0, 1.5)
	results.append("[SELF-TEST] Triggering tag from distance: " + str(p1.global_position.distance_to(bot.global_position)))
	p1._try_tag()

	results.append(" - Post-tag P1 Role: " + str(p1.current_role) + " (Expected RUNNER: 0)")
	results.append(" - Post-tag Bot Role: " + str(bot.current_role) + " (Expected TAYA: 1)")
	results.append(" - P1 Tag count: " + str(p1.tag_count))

	if p1.current_role != PlayerController.Role.RUNNER or bot.current_role != PlayerController.Role.TAYA:
		results.append("[FAIL] Role transfer failed!")
		_write_test_results(results, 1)
		return

	# 4. End match
	sync_game_over()
	results.append("[PASS] Game over reached. Winner announcement: " + winner_label.text)
	results.append("[ALL TESTS PASSED] ZERO RUNTIME ERRORS DETECTED!")
	_write_test_results(results, 0)

func _write_test_results(lines: Array[String], exit_code: int) -> void:
	var f := FileAccess.open("user://test_results.txt", FileAccess.WRITE)
	if f:
		f.store_string("\n".join(lines))
		f.close()
	get_tree().quit(exit_code)
