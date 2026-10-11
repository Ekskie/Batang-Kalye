class_name VoteManager
extends Node

signal vote_started(duration: float)
signal vote_updated(vote_counts: Dictionary, time_left: float)
signal vote_ended(winning_mode: int)

const MODE_OPTIONS: Array[Dictionary] = [
	{
		"id": 0,
		"name": "PASA-TAYA",
		"tagline": "Matira Matibay",
		"desc": "Ipasa ang pagiging Taya bago maubos ang oras! Elimination battle.",
		"icon": "💥"
	},
	{
		"id": 1,
		"name": "HAWAAN",
		"tagline": "Zombie Outbreak",
		"desc": "Lahat ng mahahampas ay magiging Taya rin! Magtago at tumakbo.",
		"icon": "🧟‍♂️"
	},
	{
		"id": 2,
		"name": "TAYAAN",
		"tagline": "Walang Bawian",
		"desc": "Klasikong habulan sa kalye! Isang Taya laban sa lahat.",
		"icon": "🏃‍♂️"
	}
]

var is_voting: bool = false
var vote_timer: float = 0.0
var vote_duration: float = 10.0
var player_votes: Dictionary = {} # peer_id: mode_id
var current_counts: Dictionary = { 0: 0, 1: 0, 2: 0 }
var winning_mode: int = 0
var sync_timer: float = 0.0

func _process(delta: float) -> void:
	if not is_voting:
		return

	vote_timer = max(0.0, vote_timer - delta)

	if is_server_or_solo():
		sync_timer += delta
		if sync_timer >= 0.5:
			sync_timer = 0.0
			if multiplayer.has_multiplayer_peer():
				rpc("sync_vote_state", current_counts, vote_timer)
			else:
				vote_updated.emit(current_counts, vote_timer)

		if vote_timer <= 0.0:
			_resolve_voting()
	else:
		vote_updated.emit(current_counts, vote_timer)

func is_server_or_solo() -> bool:
	if not multiplayer.has_multiplayer_peer():
		return true
	return multiplayer.is_server()

func start_voting(duration: float = 10.0) -> void:
	if not is_server_or_solo():
		return
	if is_voting:
		return # Prevent accidental duplicate voting triggers
	is_voting = true
	vote_duration = duration
	vote_timer = duration
	sync_timer = 0.0
	player_votes.clear()
	_recalc_counts()
	
	if multiplayer.has_multiplayer_peer():
		rpc("sync_start_voting", duration)
	else:
		_on_client_start_voting(duration)

func request_start_voting(duration: float = 10.0) -> void:
	if is_server_or_solo():
		start_voting(duration)
	elif multiplayer.has_multiplayer_peer():
		rpc_id(1, "request_start_voting_rpc", duration)

@rpc("any_peer", "reliable")
func request_start_voting_rpc(duration: float = 10.0) -> void:
	if is_server_or_solo():
		start_voting(duration)

func sync_late_join_to_peer(peer_id: int) -> void:
	if not is_server_or_solo() or not is_voting:
		return
	if multiplayer.has_multiplayer_peer():
		rpc_id(peer_id, "sync_late_join_voting_state", current_counts, vote_timer, vote_duration)

@rpc("authority", "reliable")
func sync_late_join_voting_state(counts: Dictionary, time_left: float, duration: float) -> void:
	is_voting = true
	vote_timer = time_left
	vote_duration = duration
	current_counts = counts
	vote_started.emit(time_left)
	vote_updated.emit(counts, time_left)

@rpc("call_local", "reliable")
func sync_start_voting(duration: float) -> void:
	_on_client_start_voting(duration)

func _on_client_start_voting(duration: float) -> void:
	is_voting = true
	vote_timer = duration
	vote_duration = duration
	player_votes.clear()
	_recalc_counts()
	vote_started.emit(duration)

func cast_vote(mode_id: int) -> void:
	var my_id: int = multiplayer.get_unique_id() if multiplayer.has_multiplayer_peer() else 1
	player_votes[my_id] = mode_id
	if is_server_or_solo():
		_recalc_counts()
		if multiplayer.has_multiplayer_peer():
			rpc("sync_vote_state", current_counts, vote_timer)
		else:
			vote_updated.emit(current_counts, vote_timer)
	else:
		rpc_id(1, "submit_vote_rpc", my_id, mode_id)

@rpc("any_peer", "reliable")
func submit_vote_rpc(peer_id: int, mode_id: int) -> void:
	if not is_server_or_solo():
		return
	player_votes[peer_id] = mode_id
	_recalc_counts()
	if multiplayer.has_multiplayer_peer():
		rpc("sync_vote_state", current_counts, vote_timer)
	else:
		vote_updated.emit(current_counts, vote_timer)

@rpc("call_local", "reliable")
func sync_vote_state(counts: Dictionary, time_left: float) -> void:
	current_counts = counts
	vote_timer = time_left
	if not is_voting and time_left > 0.0:
		is_voting = true
		vote_started.emit(time_left)
	vote_updated.emit(counts, time_left)

func _recalc_counts() -> void:
	current_counts = { 0: 0, 1: 0, 2: 0 }
	for pid in player_votes.keys():
		var m: int = player_votes[pid]
		if current_counts.has(m):
			current_counts[m] += 1
		else:
			current_counts[m] = 1

func _resolve_voting() -> void:
	if not is_voting:
		return
	is_voting = false
	_recalc_counts()

	var max_v := -1
	var best_modes: Array[int] = []
	for m in [0, 1, 2]:
		var c: int = current_counts.get(m, 0)
		if c > max_v:
			max_v = c
			best_modes = [m]
		elif c == max_v:
			best_modes.append(m)

	if best_modes.is_empty():
		winning_mode = 2 # Default Classic Tag
	else:
		best_modes.shuffle()
		winning_mode = best_modes[0]

	if multiplayer.has_multiplayer_peer():
		rpc("sync_vote_winner", winning_mode)
	else:
		_on_client_vote_winner(winning_mode)

@rpc("call_local", "reliable")
func sync_vote_winner(win_mode: int) -> void:
	_on_client_vote_winner(win_mode)

func _on_client_vote_winner(win_mode: int) -> void:
	is_voting = false
	winning_mode = win_mode
	vote_ended.emit(win_mode)
