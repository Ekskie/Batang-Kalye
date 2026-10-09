class_name TayaanMode
extends BaseGameMode

func _init() -> void:
	mode_type = 2 # GameManager.MatchMode.CLASSIC_TAG
	mode_name = "Tayaan (Walang Bawian)"
	mode_tagline = "Classic Tag"
	mode_description = "Isang Taya ang hahabol sa lahat ng Runner! Mabuhay hanggang maubos ang oras at mag-ipon ng puntos."
	icon_name = "🏃‍♂️"

func start_mode(game_manager: Node) -> void:
	if "match_duration" in game_manager and "match_timer" in game_manager:
		game_manager.match_timer = game_manager.match_duration

func process_mode(game_manager: Node, _delta: float) -> void:
	if "match_timer" in game_manager and game_manager.match_timer <= 0.0:
		if game_manager.has_method("is_server_or_solo") and game_manager.is_server_or_solo():
			if game_manager.has_method("sync_game_over"):
				game_manager.sync_game_over()

func on_player_tagged(game_manager: Node, tagger_id: int, victim_id: int) -> void:
	if game_manager.has_method("_server_process_tag_transfer"):
		game_manager._server_process_tag_transfer(tagger_id, victim_id)

func check_win_condition(game_manager: Node) -> bool:
	if "match_timer" in game_manager:
		return game_manager.match_timer <= 0.0
	return false
