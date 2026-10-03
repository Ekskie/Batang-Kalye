class_name MaibaTayaManager
extends Node

signal taya_decided(taya_peer_id: int, taya_name: String)
signal countdown_step(step_text: String)
signal hand_choice_requested(time_limit: float)

enum HandGesture {
	PALM_UP = 0,   # Puti / Ibabaw
	PALM_DOWN = 1  # Itim / Ilalim
}

var player_choices: Dictionary = {} # peer_id: HandGesture
var is_resolving: bool = false

func start_selection(connected_player_ids: Array) -> void:
	if not multiplayer.is_server():
		return

	player_choices.clear()
	is_resolving = false
	_run_chant_sequence(connected_player_ids)

func _run_chant_sequence(player_ids: Array) -> void:
	rpc("client_show_chant", "MA...")
	await get_tree().create_timer(0.9).timeout
	rpc("client_show_chant", "I...")
	await get_tree().create_timer(0.9).timeout
	rpc("client_show_chant", "BA...")
	await get_tree().create_timer(0.9).timeout
	rpc("client_show_chant", "TAYA! (PILI NA!)")
	rpc("client_request_choice", 2.0)

	await get_tree().create_timer(2.2).timeout
	_resolve_choices(player_ids)

func _resolve_choices(player_ids: Array) -> void:
	if is_resolving:
		return
	is_resolving = true

	# Fill default choices for anyone who didn't pick
	for pid in player_ids:
		if not player_choices.has(pid):
			player_choices[pid] = randi() % 2

	var up_group: Array = []
	var down_group: Array = []

	for pid in player_ids:
		if not player_choices.has(pid):
			player_choices[pid] = randi() % 2
		if player_choices[pid] == HandGesture.PALM_UP:
			up_group.append(pid)
		else:
			down_group.append(pid)

	var selected_taya_id: int = -1

	if up_group.size() == 1:
		selected_taya_id = up_group[0]
	elif down_group.size() == 1:
		selected_taya_id = down_group[0]
	else:
		# If no single odd one out, randomly pick from the minority group or random pick
		if up_group.size() > 0 and (up_group.size() < down_group.size() or down_group.is_empty()):
			selected_taya_id = up_group.pick_random()
		elif down_group.size() > 0:
			selected_taya_id = down_group.pick_random()
		else:
			selected_taya_id = player_ids.pick_random() if not player_ids.is_empty() else 1

	if selected_taya_id == -1 and not player_ids.is_empty():
		selected_taya_id = player_ids.pick_random()

	var taya_name: String = "Player %d" % selected_taya_id
	var net_manager = get_node_or_null("/root/Main/NetworkManager")
	if net_manager and net_manager.players.has(selected_taya_id):
		taya_name = net_manager.players[selected_taya_id]["name"]

	rpc("client_announce_taya", selected_taya_id, taya_name)

@rpc("any_peer", "call_local", "reliable")
func submit_hand_choice(choice: int) -> void:
	var sender_id := multiplayer.get_remote_sender_id()
	if sender_id == 0:
		sender_id = multiplayer.get_unique_id() if multiplayer.has_multiplayer_peer() else 1
	player_choices[sender_id] = choice

@rpc("call_local", "reliable")
func client_show_chant(chant_text: String) -> void:
	countdown_step.emit(chant_text)

@rpc("call_local", "reliable")
func client_request_choice(time_limit: float) -> void:
	hand_choice_requested.emit(time_limit)

@rpc("call_local", "reliable")
func client_announce_taya(taya_id: int, taya_name: String) -> void:
	taya_decided.emit(taya_id, taya_name)
