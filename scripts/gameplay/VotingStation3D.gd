class_name VotingStation3D
extends Node3D

signal player_voted_at_station(mode_id: int)

@export var mode_id: int = 0 # 0: PASA-TAYA, 1: HAWAAN, 2: TAYAAN
@export var mode_name: String = "PASA-TAYA"
@export var tagline: String = "Matira Matibay"
@export var mode_icon: String = "💥"
@export var theme_color: Color = Color(1.0, 0.38, 0.12, 1.0) # Flame Orange for Pasa-Taya

@onready var trigger_area: Area3D = get_node_or_null("TriggerArea")
@onready var label_title: Label3D = get_node_or_null("LabelTitle")
@onready var label_tagline: Label3D = get_node_or_null("LabelTagline")
@onready var label_votes: Label3D = get_node_or_null("LabelVotes")
@onready var label_prompt: Label3D = get_node_or_null("LabelPrompt")
@onready var station_light: OmniLight3D = get_node_or_null("StationLight")
@onready var victory_beam: CSGCylinder3D = get_node_or_null("VictoryBeam")
@onready var border_ring: CSGTorus3D = get_node_or_null("BorderRing")

var vote_manager: Node = null
var is_local_player_inside: bool = false
var pulse_time: float = 0.0
var base_light_energy: float = 1.5

func _ready() -> void:
	_setup_visuals()
	_connect_trigger()
	_find_and_connect_vote_manager()

func _setup_visuals() -> void:
	if label_title:
		label_title.text = "%s %s" % [mode_icon, mode_name]
		label_title.modulate = theme_color
	if label_tagline:
		label_tagline.text = tagline
	if label_votes:
		label_votes.text = "0 BOTO"
	if label_prompt:
		label_prompt.text = "TUMAKBO DITO PARA BUMOTO"
	if station_light:
		station_light.light_color = theme_color
		station_light.light_energy = base_light_energy
	if victory_beam:
		victory_beam.visible = false
	if border_ring and border_ring.material is StandardMaterial3D:
		var mat: StandardMaterial3D = border_ring.material.duplicate()
		mat.albedo_color = theme_color
		mat.emission_enabled = true
		mat.emission = theme_color
		mat.emission_energy_multiplier = 1.8
		border_ring.material = mat

func _connect_trigger() -> void:
	if trigger_area:
		trigger_area.collision_layer = 0
		trigger_area.collision_mask = 2 # Monitor CharacterBody3D Player on layer 2
		if not trigger_area.body_entered.is_connected(_on_body_entered):
			trigger_area.body_entered.connect(_on_body_entered)
		if not trigger_area.body_exited.is_connected(_on_body_exited):
			trigger_area.body_exited.connect(_on_body_exited)

func _find_and_connect_vote_manager() -> void:
	# Try locating VoteManager in tree
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

	pulse_time += delta * 3.0
	if station_light:
		var pulse: float = sin(pulse_time) * 0.25
		station_light.light_energy = base_light_energy + pulse

	if victory_beam and victory_beam.visible:
		victory_beam.rotation.y += delta * 1.5

func _on_body_entered(body: Node3D) -> void:
	if not (body is PlayerController):
		return

	var player: PlayerController = body as PlayerController
	if not player.is_local_human():
		return

	is_local_player_inside = true

	# Cast vote if voting is currently underway
	if vote_manager and vote_manager.get("is_voting"):
		vote_manager.cast_vote(mode_id)
		player_voted_at_station.emit(mode_id)

		# Visual & Audio feedback
		if label_prompt:
			label_prompt.text = "✓ NAPILI MO NA ITO!"
			label_prompt.modulate = Color(1.0, 0.95, 0.2)

		var am = get_node_or_null("/root/AudioManager")
		if am and am.has_method("play_vote"):
			am.play_vote()
		elif am and am.has_method("play_score_ding"):
			am.play_score_ding()

		# Trigger pop animation on light
		base_light_energy = 3.2
		get_tree().create_timer(0.4).timeout.connect(func():
			base_light_energy = 1.8
		)
	else:
		if label_prompt:
			label_prompt.text = "%s (%s)" % [mode_name, tagline]

func _on_body_exited(body: Node3D) -> void:
	if not (body is PlayerController):
		return

	var player: PlayerController = body as PlayerController
	if not player.is_local_human():
		return

	is_local_player_inside = false

func _on_vote_started(duration: float) -> void:
	if victory_beam:
		victory_beam.visible = false
	base_light_energy = 1.8
	if label_votes:
		label_votes.text = "0 BOTO"
	if label_prompt:
		label_prompt.text = "TUMAKBO DITO PARA BUMOTO"
		label_prompt.modulate = Color(1.0, 1.0, 1.0)

	# If local player is already standing in the zone when vote starts, cast vote immediately
	if is_local_player_inside and vote_manager:
		vote_manager.cast_vote(mode_id)
		if label_prompt:
			label_prompt.text = "✓ NAPILI MO NA ITO!"
			label_prompt.modulate = Color(1.0, 0.95, 0.2)

func _on_vote_updated(vote_counts: Dictionary, time_left: float) -> void:
	var c: int = vote_counts.get(mode_id, 0)
	if label_votes:
		label_votes.text = "%d BOTO" % c

	var my_id: int = multiplayer.get_unique_id() if multiplayer.has_multiplayer_peer() else 1
	var voted_mode: int = -1
	if vote_manager and vote_manager.get("player_votes") is Dictionary:
		var p_votes: Dictionary = vote_manager.get("player_votes")
		if p_votes.has(my_id):
			voted_mode = p_votes[my_id]

	if voted_mode == mode_id:
		if label_prompt:
			label_prompt.text = "✓ NAPILI MO NA ITO!"
			label_prompt.modulate = Color(1.0, 0.95, 0.2)
		base_light_energy = 2.4
	else:
		if label_prompt and not is_local_player_inside:
			label_prompt.text = "TUMAKBO DITO PARA BUMOTO"
			label_prompt.modulate = Color(0.85, 0.85, 0.85)
		base_light_energy = 1.2

func _on_vote_ended(winning_mode: int) -> void:
	if winning_mode == mode_id:
		if victory_beam:
			victory_beam.visible = true
		if label_prompt:
			label_prompt.text = "★ PANALO ANG MODE NA ITO! ★"
			label_prompt.modulate = Color(1.0, 0.9, 0.1)
		base_light_energy = 4.0
		var am = get_node_or_null("/root/AudioManager")
		if am and am.has_method("play_vote_win"):
			am.play_vote_win()
		elif am and am.has_method("play_score_ding"):
			am.play_score_ding()
	else:
		if victory_beam:
			victory_beam.visible = false
		if label_prompt:
			label_prompt.text = "Tapos na ang botohan"
			label_prompt.modulate = Color(0.5, 0.5, 0.5)
		base_light_energy = 0.5
