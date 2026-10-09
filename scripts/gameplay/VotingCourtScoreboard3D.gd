class_name VotingCourtScoreboard3D
extends Node3D

@onready var label_timer: Label3D = get_node_or_null("LabelTimer")
@onready var label_subtitle: Label3D = get_node_or_null("LabelSubtitle")
@onready var label_standings: Label3D = get_node_or_null("LabelStandings")

var vote_manager: Node = null

func _ready() -> void:
	if label_timer:
		label_timer.text = "HUMANDA SA BOTOHAN"
	if label_subtitle:
		label_subtitle.text = "🏀 BASKETBALL COURT VOTING ARENA 🏀\nTumakbo sa voting station ng nais mong laro!"
	if label_standings:
		label_standings.text = "💥 PASA-TAYA: 0 | 🧟‍♂️ HAWAAN: 0 | 🏃‍♂️ TAYAAN: 0"
	_find_and_connect_manager()

func _find_and_connect_manager() -> void:
	if not vote_manager:
		var root = get_tree().root
		vote_manager = root.find_child("VoteManager", true, false)

	if vote_manager:
		if not vote_manager.vote_started.is_connected(_on_vote_started):
			vote_manager.vote_started.connect(_on_vote_started)
		if not vote_manager.vote_updated.is_connected(_on_vote_updated):
			vote_manager.vote_updated.connect(_on_vote_updated)
		if not vote_manager.vote_ended.is_connected(_on_vote_ended):
			vote_manager.vote_ended.connect(_on_vote_ended)

func _process(_delta: float) -> void:
	if not vote_manager:
		_find_and_connect_manager()

func _on_vote_started(duration: float) -> void:
	if label_timer:
		label_timer.text = "ORAS: %.0fs" % duration
		label_timer.modulate = Color(1.0, 0.9, 0.2)
	if label_subtitle:
		label_subtitle.text = "TUMAKBO SA 3D STATIONS PARA BUMOTO!"
	if label_standings:
		label_standings.text = "💥 PASA-TAYA: 0 | 🧟‍♂️ HAWAAN: 0 | 🏃‍♂️ TAYAAN: 0"

func _on_vote_updated(vote_counts: Dictionary, time_left: float) -> void:
	if label_timer:
		label_timer.text = "ORAS: %.0fs" % max(0.0, time_left)
		if time_left <= 3.0:
			label_timer.modulate = Color(1.0, 0.2, 0.2)
		else:
			label_timer.modulate = Color(1.0, 0.9, 0.2)
	if label_standings:
		label_standings.text = "💥 PASA: %d  |  🧟‍♂️ HAWA: %d  |  🏃‍♂️ TAYA: %d" % [
			vote_counts.get(0, 0),
			vote_counts.get(1, 0),
			vote_counts.get(2, 0)
		]

func _on_vote_ended(winning_mode: int) -> void:
	var mode_name := "TAYAAN"
	match winning_mode:
		0: mode_name = "💥 PASA-TAYA"
		1: mode_name = "🧟‍♂️ HAWAAN"
		2: mode_name = "🏃‍♂️ TAYAAN"

	if label_timer:
		label_timer.text = "★ NA-PILI: %s ★" % mode_name
		label_timer.modulate = Color(0.2, 1.0, 0.4)
	if label_subtitle:
		label_subtitle.text = "HUMANDA NA SA LARO!"
