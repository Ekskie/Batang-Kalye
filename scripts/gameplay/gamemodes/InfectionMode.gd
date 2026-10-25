class_name InfectionMode
extends BaseGameMode

## InfectionMode ("Infected Base")
## Outbreak survival mode where runners must survive against multiplying infected Tayas,
## utilizing the Tindahan Safe Base for limited refuge stamina.

var final_survivor_triggered: bool = false

func _init() -> void:
	mode_type = 1 # GameManager.MatchMode.INFECTION
	mode_name = "Infected Base"
	mode_tagline = "Outbreak Base Survival"
	mode_description = "Zombie outbreak sa kalye! Bawat mahampas ay magiging Taya rin. Gamitin ang Base sa Tindahan para sa limitadong proteksyon bago maubos ang oras!"
	icon_name = "🧟‍♂️"

func start_mode(game_manager: Node) -> void:
	final_survivor_triggered = false
	if "match_duration" in game_manager and "match_timer" in game_manager:
		game_manager.match_timer = game_manager.match_duration
	if "players_container" in game_manager and game_manager.players_container:
		for p in game_manager.players_container.get_children():
			if p is PlayerController:
				p.is_final_survivor = false
				if p.has_method("_update_role_state"):
					p._update_role_state()

func process_mode(game_manager: Node, _delta: float) -> void:
	if not game_manager.has_method("is_server_or_solo") or not game_manager.is_server_or_solo():
		return

	if "current_state" in game_manager and game_manager.current_state != 3: # 3 = PLAYING
		return

	if not ("players_container" in game_manager) or not game_manager.players_container:
		return

	var runners_left: int = 0
	var total_active: int = 0
	var last_runner_id: int = -1
	for p in game_manager.players_container.get_children():
		if p is PlayerController and not p.is_eliminated:
			total_active += 1
			if p.current_role == PlayerController.Role.RUNNER:
				runners_left += 1
				last_runner_id = p.player_id

	if runners_left == 1 and total_active >= 2 and not final_survivor_triggered and last_runner_id != -1:
		final_survivor_triggered = true
		if game_manager.has_method("sync_infection_final_survivor"):
			if game_manager.multiplayer.has_multiplayer_peer() and game_manager.multiplayer.is_server():
				game_manager.rpc("sync_infection_final_survivor", last_runner_id)
			else:
				game_manager.sync_infection_final_survivor(last_runner_id)

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
		victim.is_final_survivor = false
		if victim.has_method("_update_role_state"):
			victim._update_role_state()
		if "network_manager" in game_manager and game_manager.network_manager:
			if game_manager.network_manager.players.has(victim_id):
				game_manager.network_manager.players[victim_id]["role"] = 1
		if game_manager.has_method("rpc") and game_manager.multiplayer.has_multiplayer_peer():
			game_manager.rpc("sync_assign_taya", victim_id)
		var runners_remaining: int = 0
		var infected_count: int = 0
		for p in game_manager.players_container.get_children():
			if p is PlayerController and not p.is_eliminated:
				if p.current_role == PlayerController.Role.RUNNER:
					runners_remaining += 1
				else:
					infected_count += 1
		if "hud" in game_manager and game_manager.hud and game_manager.hud.has_method("show_toast_notification"):
			game_manager.hud.show_toast_notification("NAHAWAAN: %s! (%d Ligtas | %d Hawa)" % [victim.player_name, runners_remaining, infected_count], false)

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
