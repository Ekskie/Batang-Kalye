class_name InfectionMode
extends BaseGameMode

## InfectionMode ("Infected Base")
## Outbreak survival mode where runners must survive against multiplying infected Tayas,
## utilizing the Tindahan Safe Base for limited refuge stamina.

func _init() -> void:
	mode_type = 1 # GameManager.MatchMode.INFECTION
	mode_name = "Infected Base"
	mode_tagline = "Outbreak Base Survival"
	mode_description = "Zombie outbreak sa kalye! Bawat mahampas ay magiging Taya rin. Gamitin ang Base sa Tindahan para sa limitadong proteksyon bago maubos ang oras!"
	icon_name = "🧟‍♂️"

func start_mode(game_manager: Node) -> void:
	if "match_duration" in game_manager and "match_timer" in game_manager:
		game_manager.match_timer = game_manager.match_duration

func process_mode(game_manager: Node, _delta: float) -> void:
	if not game_manager.has_method("is_server_or_solo") or not game_manager.is_server_or_solo():
		return

	if "current_state" in game_manager and game_manager.current_state != 3: # 3 = PLAYING
		return

	if not ("players_container" in game_manager) or not game_manager.players_container:
		return

	var runners_left: int = 0
	for p in game_manager.players_container.get_children():
		if p is PlayerController and not p.is_eliminated:
			if p.current_role == PlayerController.Role.RUNNER:
				runners_left += 1

	if runners_left == 0:
		if game_manager.has_method("sync_infection_game_over"):
			if game_manager.multiplayer.has_multiplayer_peer() and game_manager.multiplayer.is_server():
				game_manager.rpc("sync_infection_game_over", true)
			else:
				game_manager.sync_infection_game_over(true)
	elif "match_timer" in game_manager and game_manager.match_timer <= 0.0:
		if game_manager.has_method("sync_infection_game_over"):
			if game_manager.multiplayer.has_multiplayer_peer() and game_manager.multiplayer.is_server():
				game_manager.rpc("sync_infection_game_over", false)
			else:
				game_manager.sync_infection_game_over(false)

func on_player_tagged(game_manager: Node, _tagger_id: int, victim_id: int) -> void:
	if not ("players_container" in game_manager) or not game_manager.players_container:
		return
	var victim: PlayerController = game_manager.players_container.get_node_or_null(str(victim_id)) as PlayerController
	if victim:
		victim.current_role = PlayerController.Role.TAYA
		if "network_manager" in game_manager and game_manager.network_manager:
			if game_manager.network_manager.players.has(victim_id):
				game_manager.network_manager.players[victim_id]["role"] = 1
		if game_manager.has_method("rpc"):
			game_manager.rpc("sync_assign_taya", victim_id)
		if "hud" in game_manager and game_manager.hud and game_manager.hud.has_method("show_toast_notification"):
			game_manager.hud.show_toast_notification("NAHAWAAN: %s!" % victim.player_name, false)

func on_player_disconnected(game_manager: Node, _peer_id: int) -> void:
	if not game_manager.has_method("is_server_or_solo") or not game_manager.is_server_or_solo():
		return
	if not ("players_container" in game_manager) or not game_manager.players_container:
		return

	var runners_left: int = 0
	for p in game_manager.players_container.get_children():
		if p is PlayerController and not p.is_eliminated and p.current_role == PlayerController.Role.RUNNER:
			runners_left += 1

	if runners_left == 0 and ("current_state" in game_manager and game_manager.current_state == 3):
		if game_manager.has_method("sync_infection_game_over"):
			if game_manager.multiplayer.has_multiplayer_peer() and game_manager.multiplayer.is_server():
				game_manager.rpc("sync_infection_game_over", true)
			else:
				game_manager.sync_infection_game_over(true)

func check_win_condition(game_manager: Node) -> bool:
	if "match_timer" in game_manager:
		return game_manager.match_timer <= 0.0
	return false
