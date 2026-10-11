class_name TayaanMode
extends BaseGameMode

## TayaanMode ("Normal Taayan / Walang Bawian")
## Classic Filipino street tag where one Taya chases runners.
## Points are accumulated through survival, tags, and recycling.

func _init() -> void:
	mode_type = 2 # GameManager.MatchMode.CLASSIC_TAG
	mode_name = "Normal Taayan"
	mode_tagline = "Classic Tag"
	mode_description = "Klasikong habulan sa kalye! Isang Taya laban sa lahat ng Runner. Mabuhay hanggang maubos ang oras at mag-ipon ng puntos."
	icon_name = "🏃‍♂️"

func start_mode(game_manager: Node) -> void:
	if "match_duration" in game_manager and "match_timer" in game_manager:
		game_manager.match_timer = game_manager.match_duration

func process_mode(game_manager: Node, _delta: float) -> void:
	if not game_manager.has_method("is_server_or_solo") or not game_manager.is_server_or_solo():
		return
	if "current_state" in game_manager and game_manager.current_state != 3: # 3 = PLAYING
		return
	if "match_timer" in game_manager and game_manager.match_timer <= 0.0:
		if game_manager.has_method("sync_game_over"):
			if game_manager.multiplayer.has_multiplayer_peer() and game_manager.multiplayer.is_server():
				game_manager.rpc("sync_game_over")
			else:
				game_manager.sync_game_over()

func on_player_tagged(game_manager: Node, tagger_id: int, victim_id: int) -> void:
	if game_manager.has_method("_server_process_tag_transfer"):
		game_manager._server_process_tag_transfer(tagger_id, victim_id)

func on_player_disconnected(game_manager: Node, _peer_id: int) -> void:
	if not game_manager.has_method("is_server_or_solo") or not game_manager.is_server_or_solo():
		return
	if game_manager.multiplayer.has_multiplayer_peer() and not game_manager.network_manager.is_solo_practice:
		if game_manager.network_manager.players.size() <= 1 and ("current_state" in game_manager and game_manager.current_state == 3):
			if game_manager.has_method("sync_game_over"):
				if game_manager.multiplayer.is_server():
					game_manager.rpc("sync_game_over")
				else:
					game_manager.sync_game_over()

func check_win_condition(game_manager: Node) -> bool:
	if "match_timer" in game_manager:
		return game_manager.match_timer <= 0.0
	return false
