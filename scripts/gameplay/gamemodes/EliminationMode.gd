class_name EliminationMode
extends BaseGameMode

## EliminationMode ("Pasa-Taya: Matira Matibay")
## Round-based Crab Game elimination where players must tag others to pass off Taya
## before the timer expires. Remaining Tayas are eliminated each round.

func _init() -> void:
	mode_type = 0 # GameManager.MatchMode.PASA_TAYA_ELIMINATION
	mode_name = "Pasa-Taya (Matira Matibay)"
	mode_tagline = "Crab Game Elimination"
	mode_description = "I-pasa ang pagiging Taya bago maubos ang timer! Ang matitirang Taya sa huli ay tanggal, hanggang isa na lang ang matira."
	icon_name = "💥"

func start_mode(game_manager: Node) -> void:
	if "match_duration" in game_manager and "match_timer" in game_manager:
		game_manager.match_timer = game_manager.match_duration

func process_mode(game_manager: Node, _delta: float) -> void:
	if not game_manager.has_method("is_server_or_solo") or not game_manager.is_server_or_solo():
		return
	if "current_state" in game_manager and game_manager.current_state != 3: # 3 = PLAYING
		return
	if "is_intermission" in game_manager and game_manager.is_intermission:
		return
	if "match_timer" in game_manager and game_manager.match_timer <= 0.0:
		if game_manager.has_method("_on_round_timer_expired"):
			game_manager._on_round_timer_expired()

func on_player_tagged(game_manager: Node, tagger_id: int, victim_id: int) -> void:
	if game_manager.has_method("_server_process_tag_transfer"):
		game_manager._server_process_tag_transfer(tagger_id, victim_id)

func on_player_disconnected(game_manager: Node, _peer_id: int) -> void:
	if not game_manager.has_method("is_server_or_solo") or not game_manager.is_server_or_solo():
		return
	if "alive_player_ids" in game_manager and game_manager.alive_player_ids.size() <= 1:
		var winner_id: int = game_manager.alive_player_ids[0] if game_manager.alive_player_ids.size() == 1 else -1
		if game_manager.has_method("sync_tournament_winner"):
			if game_manager.multiplayer.has_multiplayer_peer() and game_manager.multiplayer.is_server():
				game_manager.rpc("sync_tournament_winner", winner_id)
			else:
				game_manager.sync_tournament_winner(winner_id)

func check_win_condition(game_manager: Node) -> bool:
	if "alive_player_ids" in game_manager:
		return game_manager.alive_player_ids.size() <= 1
	return false
