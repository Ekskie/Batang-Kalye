class_name BaseGameMode
extends RefCounted

var mode_type: int = 0
var mode_name: String = "Larong Kalye"
var mode_tagline: String = "Street Game"
var mode_description: String = "Filipino multiplayer street game."
var icon_name: String = "🏃"

func start_mode(_game_manager: Node) -> void:
	pass

func process_mode(_game_manager: Node, _delta: float) -> void:
	pass

func on_player_tagged(_game_manager: Node, _tagger_id: int, _victim_id: int) -> void:
	pass

func check_win_condition(_game_manager: Node) -> bool:
	return false

func end_mode(_game_manager: Node) -> void:
	pass

func get_mode_meta(_game_manager: Node) -> Dictionary:
	return {
		"mode_name": mode_name,
		"tagline": mode_tagline,
		"description": mode_description,
		"icon": icon_name
	}
