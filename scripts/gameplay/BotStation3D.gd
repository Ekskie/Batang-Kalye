class_name BotStation3D
extends Node3D

# ==============================================================================
# BotStation3D.gd
# 3D Physical Bot Station & Roblox-Style Touch/Interact Pad for Enclosed Court Lobby.
# Allows players to step onto or interact with the pad to adjust/toggle bots
# for upcoming match sessions with live 3D floating visual feedback.
# ==============================================================================

signal bot_count_changed(new_count: int)
signal bot_station_triggered()

const FloatingTextScript = preload("res://scripts/player/FloatingText.gd")

@export var max_bots: int = 15
@export var step_debounce_time: float = 0.8
@export var theme_color: Color = Color(0.2, 0.8, 1.0, 1.0) # Cyber/Bot Neon Cyan
@export var active_color: Color = Color(1.0, 0.85, 0.2, 1.0) # Golden Yellow on max / active

@onready var trigger_area: Area3D = get_node_or_null("TriggerArea")
@onready var pressure_pad: CSGCylinder3D = get_node_or_null("StationPedestal/PressurePad")
@onready var border_ring: CSGTorus3D = get_node_or_null("BorderRing")
@onready var station_light: OmniLight3D = get_node_or_null("StationLight")
@onready var label_title: Label3D = get_node_or_null("LabelTitle")
@onready var label_tagline: Label3D = get_node_or_null("LabelTagline")
@onready var label_bot_count: Label3D = get_node_or_null("LabelBotCount")
@onready var label_status: Label3D = get_node_or_null("LabelStatus")
@onready var label_prompt: Label3D = get_node_or_null("LabelPrompt")

var current_bot_count: int = 0
var debounce_timer: float = 0.0
var is_local_player_inside: bool = false
var local_player: PlayerController = null
var original_pad_y: float = 0.42
var is_pressed_animating: bool = false
var pulse_time: float = 0.0
var base_light_energy: float = 1.6

var network_manager: Node = null
var game_manager: Node = null

func _ready() -> void:
	if pressure_pad:
		original_pad_y = pressure_pad.position.y
	_setup_visuals()
	_connect_trigger()
	_find_managers()
	_update_display()

func _find_managers() -> void:
	if not network_manager:
		network_manager = get_node_or_null("/root/NetworkManager")
		if not network_manager:
			var root = get_tree().root
			network_manager = root.find_child("NetworkManager", true, false)

	if not game_manager:
		game_manager = get_node_or_null("/root/GameManager")
		if not game_manager:
			var root = get_tree().root
			game_manager = root.find_child("GameManager", true, false)

	if network_manager and network_manager.has_signal("player_list_updated"):
		if not network_manager.player_list_updated.is_connected(_on_network_player_list_updated):
			network_manager.player_list_updated.connect(_on_network_player_list_updated)

func _setup_visuals() -> void:
	if label_title:
		label_title.text = "🤖 BOT STATION"
		label_title.modulate = theme_color
	if label_tagline:
		label_tagline.text = "Roblox Touch Pad - Tumapak o Pindutin"
	if label_bot_count:
		label_bot_count.text = "0 BOTS"
		label_bot_count.modulate = theme_color
	if label_status:
		label_status.text = "Lobby: 0 / %d Bots" % max_bots
	if label_prompt:
		label_prompt.text = "[E] / TUMAPAK: +1 BOT"
		label_prompt.modulate = Color(1.0, 1.0, 0.4)

	if station_light:
		station_light.light_color = theme_color
		station_light.light_energy = base_light_energy

	if border_ring and border_ring.material is StandardMaterial3D:
		var mat: StandardMaterial3D = border_ring.material.duplicate()
		mat.albedo_color = theme_color
		mat.emission_enabled = true
		mat.emission = theme_color
		mat.emission_energy_multiplier = 1.8
		border_ring.material = mat

	if pressure_pad and pressure_pad.material is StandardMaterial3D:
		var p_mat: StandardMaterial3D = pressure_pad.material.duplicate()
		p_mat.albedo_color = theme_color
		p_mat.emission_enabled = true
		p_mat.emission = theme_color
		p_mat.emission_energy_multiplier = 2.2
		pressure_pad.material = p_mat

func _connect_trigger() -> void:
	if trigger_area:
		trigger_area.collision_layer = 0
		trigger_area.collision_mask = 2 # Monitor CharacterBody3D Player layer
		if not trigger_area.body_entered.is_connected(_on_body_entered):
			trigger_area.body_entered.connect(_on_body_entered)
		if not trigger_area.body_exited.is_connected(_on_body_exited):
			trigger_area.body_exited.connect(_on_body_exited)

func _process(delta: float) -> void:
	if debounce_timer > 0.0:
		debounce_timer -= delta

	if not network_manager:
		_find_managers()

	pulse_time += delta * 3.0
	if station_light:
		var pulse: float = sin(pulse_time) * 0.25
		station_light.light_energy = base_light_energy + pulse

func _on_body_entered(body: Node3D) -> void:
	if not (body is PlayerController):
		return
	var player: PlayerController = body as PlayerController
	if not player.is_local_human():
		return

	local_player = player
	is_local_player_inside = true
	if player.has_method("register_nearby_interactable"):
		player.register_nearby_interactable(self)

	if debounce_timer <= 0.0:
		debounce_timer = step_debounce_time
		trigger_bot_adjustment()

func _on_body_exited(body: Node3D) -> void:
	if not (body is PlayerController):
		return
	var player: PlayerController = body as PlayerController
	if not player.is_local_human():
		return

	if local_player == player:
		local_player = null
	is_local_player_inside = false
	if player.has_method("unregister_nearby_interactable"):
		player.unregister_nearby_interactable(self)

func get_interaction_action() -> String:
	if current_bot_count >= max_bots:
		return "I-RESET ANG MGA BOT (0)"
	return "MAGDAGDAG NG BOT (+1)"

func get_interaction_icon() -> String:
	return "🤖"

func interact(_player: PlayerController = null) -> void:
	if _player and is_instance_valid(_player):
		local_player = _player
	trigger_bot_adjustment()

func trigger_bot_adjustment() -> void:
	_animate_pad_press()
	perform_bot_adjustment()

func _animate_pad_press() -> void:
	if is_pressed_animating:
		return
	is_pressed_animating = true

	var am = get_node_or_null("/root/AudioManager")
	if am:
		if am.has_method("play_score_ding"):
			am.play_score_ding()
		elif am.has_method("play_vote"):
			am.play_vote()

	if pressure_pad and is_inside_tree():
		var tw := create_tween()
		tw.tween_property(pressure_pad, "position:y", original_pad_y - 0.05, 0.08).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.tween_property(pressure_pad, "position:y", original_pad_y, 0.16).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
		tw.tween_callback(func(): is_pressed_animating = false)
	else:
		is_pressed_animating = false

	if station_light and is_inside_tree():
		station_light.light_energy = 3.5
		get_tree().create_timer(0.3).timeout.connect(func():
			if station_light:
				station_light.light_energy = base_light_energy
		)

func perform_bot_adjustment() -> void:
	_find_managers()

	# If connected peer and not host/server, request host via RPC
	if multiplayer.has_multiplayer_peer() and not multiplayer.is_server():
		rpc_id(1, "request_adjust_bots")
		return

	var fb_type: int = 0 # 0: added, 1: reset, 2: full
	if network_manager and network_manager.has_method("get_bot_count"):
		var cur := int(network_manager.get_bot_count())
		var max_cap: int = min(max_bots, 23)
		if cur < max_cap and network_manager.players.size() < 24:
			var bot_id: int = network_manager.add_bot()
			if bot_id > 0:
				current_bot_count = network_manager.get_bot_count()
				fb_type = 0
			else:
				fb_type = 2
		else:
			if cur == 0 and network_manager.players.size() >= 24:
				fb_type = 2
			else:
				# At max or full: cycle / reset back to 0
				while network_manager.get_bot_count() > 0:
					network_manager.remove_bot()
				current_bot_count = 0
				fb_type = 1

		if game_manager and game_manager.has_method("_update_lobby_player_list"):
			game_manager._update_lobby_player_list()
	else:
		# Standalone / mock mode without active NetworkManager
		current_bot_count = (current_bot_count + 1) % (max_bots + 1)
		fb_type = 0 if current_bot_count > 0 else 1

	if multiplayer.has_multiplayer_peer() and multiplayer.is_server():
		rpc("sync_bot_feedback", current_bot_count, fb_type)
	else:
		sync_bot_feedback(current_bot_count, fb_type)

@rpc("authority", "call_local", "reliable")
func sync_bot_feedback(new_count: int, feedback_type: int) -> void:
	_animate_pad_press()
	current_bot_count = new_count
	_update_display()
	match feedback_type:
		0:
			var max_cap: int = min(max_bots, 23)
			_spawn_floating_text("+1 BOT! (%d/%d)" % [current_bot_count, max_cap], theme_color)
		1:
			_spawn_floating_text("BOTS RESET (0)", Color(1.0, 0.4, 0.4))
		2:
			_spawn_floating_text("PUNO NA ANG LOBBY! (24/24)", Color(1.0, 0.8, 0.2))
	bot_count_changed.emit(current_bot_count)
	bot_station_triggered.emit()

@rpc("any_peer", "call_local", "reliable")
func request_adjust_bots() -> void:
	if not (multiplayer.is_server() or not multiplayer.has_multiplayer_peer()):
		return
	if debounce_timer > 0.0:
		return
	debounce_timer = step_debounce_time
	perform_bot_adjustment()

func _spawn_floating_text(msg: String, col: Color) -> void:
	if not is_inside_tree():
		return
	if FloatingTextScript and get_parent():
		FloatingTextScript.spawn(get_parent(), global_position + Vector3(0, 2.5, 0), msg, col)

func _on_network_player_list_updated() -> void:
	if network_manager and network_manager.has_method("get_bot_count"):
		current_bot_count = network_manager.get_bot_count()
	_update_display()

func _update_display() -> void:
	if network_manager and network_manager.has_method("get_bot_count"):
		current_bot_count = network_manager.get_bot_count()

	if label_bot_count:
		label_bot_count.text = "%d BOTS" % current_bot_count
		if current_bot_count >= max_bots:
			label_bot_count.modulate = active_color
		else:
			label_bot_count.modulate = theme_color

	if label_status:
		label_status.text = "Lobby: %d / %d Bots" % [current_bot_count, max_bots]

	if label_prompt:
		if current_bot_count >= max_bots:
			label_prompt.text = "[E] / TUMAPAK: I-RESET ANG MGA BOT"
			label_prompt.modulate = active_color
		else:
			label_prompt.text = "[E] / TUMAPAK: +1 BOT"
			label_prompt.modulate = Color(1.0, 1.0, 0.4)

	var active_c := active_color if current_bot_count >= max_bots else theme_color
	if pressure_pad and pressure_pad.material is StandardMaterial3D:
		var p_mat := pressure_pad.material as StandardMaterial3D
		p_mat.albedo_color = active_c
		p_mat.emission = active_c

	if local_player and is_instance_valid(local_player) and local_player.has_method("_update_interactable_target"):
		local_player._update_interactable_target()

# Direct programmatic helpers
func add_bot() -> int:
	_find_managers()
	if network_manager and network_manager.has_method("add_bot"):
		var bid: int = network_manager.add_bot()
		current_bot_count = network_manager.get_bot_count()
		_update_display()
		bot_count_changed.emit(current_bot_count)
		return bid
	else:
		current_bot_count = min(max_bots, current_bot_count + 1)
		_update_display()
		bot_count_changed.emit(current_bot_count)
		return current_bot_count

func remove_bot() -> bool:
	_find_managers()
	if network_manager and network_manager.has_method("remove_bot"):
		var res: bool = network_manager.remove_bot()
		current_bot_count = network_manager.get_bot_count()
		_update_display()
		bot_count_changed.emit(current_bot_count)
		return res
	else:
		if current_bot_count > 0:
			current_bot_count -= 1
			_update_display()
			bot_count_changed.emit(current_bot_count)
			return true
		return false

func reset_bots() -> void:
	_find_managers()
	if network_manager and network_manager.has_method("remove_bot"):
		while network_manager.get_bot_count() > 0:
			network_manager.remove_bot()
		current_bot_count = 0
	else:
		current_bot_count = 0
	_update_display()
	bot_count_changed.emit(current_bot_count)

func toggle_bots() -> void:
	if current_bot_count > 0:
		reset_bots()
	else:
		add_bot()

func get_bot_count() -> int:
	return current_bot_count
