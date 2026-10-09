class_name VoteUI
extends Control

signal vote_selected(mode_id: int)

const VoteManagerScript = preload("res://scripts/gameplay/VoteManager.gd")

@onready var title_label: Label = get_node_or_null("Panel/VBox/TitleLabel")
@onready var timer_label: Label = get_node_or_null("Panel/VBox/TimerLabel")
@onready var cards_container: HBoxContainer = get_node_or_null("Panel/VBox/CardsContainer")
@onready var winner_banner: PanelContainer = get_node_or_null("Panel/WinnerBanner")
@onready var winner_label: Label = get_node_or_null("Panel/WinnerBanner/WinnerLabel")

var vote_manager: Node = null
var my_selected_mode: int = -1

func setup_manager(mgr: Node) -> void:
	vote_manager = mgr
	if not vote_manager.vote_started.is_connected(_on_vote_started):
		vote_manager.vote_started.connect(_on_vote_started)
	if not vote_manager.vote_updated.is_connected(_on_vote_updated):
		vote_manager.vote_updated.connect(_on_vote_updated)
	if not vote_manager.vote_ended.is_connected(_on_vote_ended):
		vote_manager.vote_ended.connect(_on_vote_ended)

func _ready() -> void:
	visible = false
	if winner_banner:
		winner_banner.visible = false

	# Connect buttons for each card
	for i in range(3):
		var btn: Button = get_node_or_null("Panel/VBox/CardsContainer/Card%d/Margin/VBox/BtnVote" % i) as Button
		if btn:
			var mode_idx := i
			btn.pressed.connect(func(): _on_card_clicked(mode_idx))

func _on_vote_started(duration: float) -> void:
	visible = true
	my_selected_mode = -1
	if winner_banner:
		winner_banner.visible = false
	if timer_label:
		timer_label.text = "Natitirang Oras: %.0fs" % duration
	_update_card_counts({ 0: 0, 1: 0, 2: 0 })
	_highlight_selected_card()

func _on_vote_updated(counts: Dictionary, time_left: float) -> void:
	if timer_label:
		timer_label.text = "Natitirang Oras: %.0fs" % max(0.0, time_left)
	_update_card_counts(counts)

	# Synchronize card highlight if vote was cast at a 3D physical station
	var my_id: int = multiplayer.get_unique_id() if multiplayer.has_multiplayer_peer() else 1
	if vote_manager and vote_manager.get("player_votes") is Dictionary:
		var p_votes: Dictionary = vote_manager.get("player_votes")
		if p_votes.has(my_id):
			my_selected_mode = p_votes[my_id]
			_highlight_selected_card()

func _on_vote_ended(winning_mode: int) -> void:
	var mode_name := "TAYAAN"
	for opt in VoteManagerScript.MODE_OPTIONS:
		if opt["id"] == winning_mode:
			mode_name = opt["name"]
			break

	if winner_banner:
		winner_banner.visible = true
		if winner_label:
			winner_label.text = "★ NA-PILI: %s! ★\nHumanda na sa Maiba Taya!" % mode_name

	var am = get_node_or_null("/root/AudioManager")
	if am and am.has_method("play_vote_win"):
		am.play_vote_win()

	get_tree().create_timer(2.2).timeout.connect(func():
		visible = false
		if winner_banner:
			winner_banner.visible = false
	)

func _on_card_clicked(mode_id: int) -> void:
	my_selected_mode = mode_id
	if vote_manager:
		vote_manager.cast_vote(mode_id)
	var am = get_node_or_null("/root/AudioManager")
	if am and am.has_method("play_vote"):
		am.play_vote()
	_highlight_selected_card()
	vote_selected.emit(mode_id)

func _update_card_counts(counts: Dictionary) -> void:
	for i in range(3):
		var count_lbl: Label = get_node_or_null("Panel/VBox/CardsContainer/Card%d/Margin/VBox/VoteCount" % i) as Label
		if count_lbl:
			var c: int = counts.get(i, 0)
			count_lbl.text = "%d BOTO" % c

func _highlight_selected_card() -> void:
	for i in range(3):
		var btn: Button = get_node_or_null("Panel/VBox/CardsContainer/Card%d/Margin/VBox/BtnVote" % i) as Button
		if btn:
			if i == my_selected_mode:
				btn.text = "✓ NAPILI MO"
				btn.modulate = Color(1.0, 0.9, 0.2)
			else:
				btn.text = "IBOTO ITO"
				btn.modulate = Color(1.0, 1.0, 1.0)
