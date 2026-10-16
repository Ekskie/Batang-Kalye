class_name VotingStartButton3D
extends Node3D

signal vote_button_activated()

@onready var button_dome: CSGCylinder3D = get_node_or_null("Pedestal/ButtonDome")
@onready var button_light: OmniLight3D = get_node_or_null("ButtonLight")
@onready var label_title: Label3D = get_node_or_null("LabelTitle")
@onready var label_status: Label3D = get_node_or_null("LabelStatus")
@onready var label_prompt: Label3D = get_node_or_null("LabelPrompt")
@onready var trigger_area: Area3D = get_node_or_null("TriggerArea")

var vote_manager: Node = null
var is_player_nearby: bool = false
var original_button_y: float = 0.95
var is_pressed_animating: bool = false
var pulse_time: float = 0.0

func _ready() -> void:
	if button_dome:
		original_button_y = button_dome.position.y
	_setup_visuals()
	_connect_trigger()
	_find_and_connect_vote_manager()

func _setup_visuals() -> void:
	if label_title:
		label_title.text = "★ BUMOTO NG LARO ★"
		label_title.modulate = Color(1.0, 0.85, 0.2)
	if label_status:
		label_status.text = "PINDUTIN ANG BUZZER PARA SIMULAN ANG BOTOHAN"
		label_status.modulate = Color(0.9, 0.95, 1.0)
	if label_prompt:
		label_prompt.text = "[E] / [TAP] PINDUTIN ANG BUZZER"
		label_prompt.visible = false

func _connect_trigger() -> void:
	if trigger_area:
		trigger_area.collision_layer = 0
		trigger_area.collision_mask = 2 # Monitor CharacterBody3D Player layer
		if not trigger_area.body_entered.is_connected(_on_body_entered):
			trigger_area.body_entered.connect(_on_body_entered)
		if not trigger_area.body_exited.is_connected(_on_body_exited):
			trigger_area.body_exited.connect(_on_body_exited)

func _find_and_connect_vote_manager() -> void:
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

func _process(delta: float) -> void:
	if not vote_manager:
		_find_and_connect_vote_manager()

	pulse_time += delta * 4.0
	if button_light:
		var is_active := bool(vote_manager and vote_manager.get("is_voting"))
		var base_e := 2.2 if is_active else 1.2
		button_light.light_energy = base_e + sin(pulse_time) * 0.4

func _on_body_entered(body: Node3D) -> void:
	if not (body is PlayerController):
		return
	var player: PlayerController = body as PlayerController
	if not player.is_local_human():
		return

	is_player_nearby = true
	if label_prompt:
		label_prompt.visible = true
	if player.has_method("register_nearby_interactable"):
		player.register_nearby_interactable(self)

func _on_body_exited(body: Node3D) -> void:
	if not (body is PlayerController):
		return
	var player: PlayerController = body as PlayerController
	if not player.is_local_human():
		return

	is_player_nearby = false
	if label_prompt:
		label_prompt.visible = false
	if player.has_method("unregister_nearby_interactable"):
		player.unregister_nearby_interactable(self)

func get_interaction_action() -> String:
	if vote_manager and vote_manager.get("is_voting"):
		return "BUMOBOTO NA"
	return "PINDUTIN ANG BUZZER"

func get_interaction_icon() -> String:
	return "🗳️"

func interact(_player: PlayerController = null) -> void:
	if not vote_manager:
		_find_and_connect_vote_manager()

	_animate_button_press()

	if vote_manager:
		if vote_manager.get("is_voting"):
			if label_prompt:
				label_prompt.text = "Bumoboto na! Tumakbo sa mga station!"
		else:
			if vote_manager.has_method("request_start_voting"):
				vote_manager.request_start_voting(10.0)
			elif vote_manager.has_method("start_voting"):
				vote_manager.start_voting(10.0)
			vote_button_activated.emit()

func _animate_button_press() -> void:
	if is_pressed_animating:
		return
	is_pressed_animating = true

	var am = get_node_or_null("/root/AudioManager")
	if am:
		if am.has_method("play_vote"):
			am.play_vote()
		elif am.has_method("play_whistle"):
			am.play_whistle()

	if button_dome:
		var tw := create_tween()
		tw.tween_property(button_dome, "position:y", original_button_y - 0.08, 0.08).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.tween_property(button_dome, "position:y", original_button_y, 0.16).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
		tw.tween_callback(func(): is_pressed_animating = false)

	if button_light:
		button_light.light_energy = 4.0

func _on_vote_started(_duration: float) -> void:
	if label_status:
		label_status.text = "★ BUMOBOTO NA! TUMAKBO SA MGA STATION! ★"
		label_status.modulate = Color(1.0, 0.35, 0.1)
	if label_prompt:
		label_prompt.text = "Bumoboto na! Pumili ng laro sa court!"

func _on_vote_updated(_vote_counts: Dictionary, time_left: float) -> void:
	if label_status:
		label_status.text = "ORAS NG BOTOHAN: %.0fs" % max(0.0, time_left)
		if time_left <= 3.0:
			label_status.modulate = Color(1.0, 0.2, 0.2)
		else:
			label_status.modulate = Color(1.0, 0.85, 0.2)

func _on_vote_ended(winning_mode: int) -> void:
	var mode_name := "TAYAAN"
	match winning_mode:
		0: mode_name = "💥 PASA-TAYA"
		1: mode_name = "🧟‍♂️ HAWAAN"
		2: mode_name = "🏃‍♂️ TAYAAN"

	if label_status:
		label_status.text = "★ NA-PILI: %s! ★" % mode_name
		label_status.modulate = Color(0.2, 1.0, 0.4)
	if label_prompt:
		label_prompt.text = "Humanda na sa laro!"

	get_tree().create_timer(3.5).timeout.connect(func():
		if is_instance_valid(self):
			_setup_visuals()
	)
