class_name MaibaTayaManager
extends Node

signal taya_decided(taya_peer_id: int, taya_name: String)
signal tayas_decided(taya_peer_ids: Array, taya_names: Array)
signal countdown_step(step_text: String)
signal hand_choice_requested(time_limit: float)

## Dynamic Multi-Taya formula: 1 Taya per 4-5 players
## <=8: 1 Taya; 9-10: 2 Tayas; 11-15: 3 Tayas; 16-20: 4 Tayas; 21-24: 5 Tayas
static func get_taya_count(player_count: int) -> int:
	if player_count <= 1:
		return 1
	var target_count: int = 1
	if player_count > 8:
		target_count = int(ceil(float(player_count) / 5.0))
	return clamp(target_count, 1, max(1, player_count - 1))

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
		if player_choices[pid] == HandGesture.PALM_UP:
			up_group.append(pid)
		else:
			down_group.append(pid)

	var needed_tayas: int = get_taya_count(player_ids.size())
	var selected_taya_ids: Array = []

	if needed_tayas == 1:
		var single_id: int = -1
		if up_group.size() == 1:
			single_id = up_group[0]
		elif down_group.size() == 1:
			single_id = down_group[0]
		else:
			if up_group.size() > 0 and (up_group.size() < down_group.size() or down_group.is_empty()):
				single_id = up_group.pick_random()
			elif down_group.size() > 0:
				single_id = down_group.pick_random()
			else:
				single_id = player_ids.pick_random() if not player_ids.is_empty() else 1
		if single_id != -1:
			selected_taya_ids.append(single_id)
	else:
		# Multi-Taya selection: prioritize minority gesture group ("maiba")
		var minority_group: Array = []
		var majority_group: Array = []

		if up_group.size() < down_group.size():
			minority_group = up_group.duplicate()
			majority_group = down_group.duplicate()
		elif down_group.size() < up_group.size():
			minority_group = down_group.duplicate()
			majority_group = up_group.duplicate()
		else:
			var all_shuffled: Array = player_ids.duplicate()
			all_shuffled.shuffle()
			minority_group = all_shuffled

		minority_group.shuffle()
		majority_group.shuffle()

		for pid in minority_group:
			if selected_taya_ids.size() < needed_tayas:
				selected_taya_ids.append(pid)

		for pid in majority_group:
			if selected_taya_ids.size() < needed_tayas and not selected_taya_ids.has(pid):
				selected_taya_ids.append(pid)

	# Safety fallback: ensure exactly needed_tayas are selected
	if selected_taya_ids.size() < needed_tayas:
		var remaining: Array = player_ids.duplicate()
		remaining.shuffle()
		for pid in remaining:
			if selected_taya_ids.size() < needed_tayas and not selected_taya_ids.has(pid):
				selected_taya_ids.append(pid)

	if selected_taya_ids.is_empty():
		selected_taya_ids.append(player_ids.pick_random() if not player_ids.is_empty() else 1)

	var taya_names: Array = []
	var net_manager = get_node_or_null("/root/Main/NetworkManager")
	for tid in selected_taya_ids:
		var t_name: String = "Player %d" % tid
		if net_manager and net_manager.players.has(tid):
			t_name = net_manager.players[tid].get("name", t_name)
		taya_names.append(t_name)

	is_resolving = false
	if multiplayer.has_multiplayer_peer():
		rpc("client_announce_multi_taya", selected_taya_ids, taya_names)
	else:
		client_announce_multi_taya(selected_taya_ids, taya_names)

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
func client_announce_multi_taya(taya_ids: Array, taya_names: Array) -> void:
	tayas_decided.emit(taya_ids, taya_names)
	if not taya_ids.is_empty():
		var first_name: String = taya_names[0] if not taya_names.is_empty() else ("Player %d" % taya_ids[0])
		taya_decided.emit(taya_ids[0], first_name)

@rpc("call_local", "reliable")
func client_announce_taya(taya_id: int, taya_name: String) -> void:
	client_announce_multi_taya([taya_id], [taya_name])
