class_name NetworkManager
extends Node

signal server_created()
signal join_success()
signal join_failed()
signal player_list_updated()
signal match_started()

const DEFAULT_PORT: int = 7777
const MAX_PLAYERS: int = 8

var peer: ENetMultiplayerPeer
var players: Dictionary = {} # peer_id: { "name": String, "score": int, "role": int }
var local_player_name: String = "Batang Kalye"
var is_host: bool = false

func _ready() -> void:
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)

func create_game(player_name: String, port: int = DEFAULT_PORT) -> Error:
	local_player_name = player_name
	is_host = true
	peer = ENetMultiplayerPeer.new()
	var err := peer.create_server(port, MAX_PLAYERS)
	if err != OK:
		push_error("Failed to create server on port %d: %s" % [port, error_string(err)])
		return err

	multiplayer.multiplayer_peer = peer
	players[1] = {
		"name": local_player_name,
		"score": 0,
		"role": 0
	}
	server_created.emit()
	player_list_updated.emit()
	return OK

func join_game(address: String, player_name: String, port: int = DEFAULT_PORT) -> Error:
	local_player_name = player_name
	is_host = false
	peer = ENetMultiplayerPeer.new()
	var target_ip := address.strip_edges()
	if target_ip.is_empty():
		target_ip = "127.0.0.1"

	var err := peer.create_client(target_ip, port)
	if err != OK:
		push_error("Failed to connect to %s:%d: %s" % [target_ip, port, error_string(err)])
		join_failed.emit()
		return err

	multiplayer.multiplayer_peer = peer
	return OK

func leave_game() -> void:
	if peer:
		peer.close()
		multiplayer.multiplayer_peer = null
		peer = null
	players.clear()
	is_host = false
	player_list_updated.emit()

func _on_peer_connected(id: int) -> void:
	if multiplayer.is_server():
		# Send current players to the newcomer
		rpc_id(id, "sync_player_list", players)

func _on_peer_disconnected(id: int) -> void:
	if players.has(id):
		players.erase(id)
		player_list_updated.emit()
		if multiplayer.is_server():
			rpc("sync_player_list", players)

func _on_connected_to_server() -> void:
	var my_id := multiplayer.get_unique_id()
	rpc_id(1, "register_player", local_player_name)
	join_success.emit()

func _on_connection_failed() -> void:
	multiplayer.multiplayer_peer = null
	join_failed.emit()

func _on_server_disconnected() -> void:
	multiplayer.multiplayer_peer = null
	players.clear()
	player_list_updated.emit()

@rpc("any_peer", "reliable")
func register_player(new_name: String) -> void:
	if not multiplayer.is_server():
		return
	var sender_id := multiplayer.get_remote_sender_id()
	players[sender_id] = {
		"name": new_name,
		"score": 0,
		"role": 0
	}
	rpc("sync_player_list", players)
	player_list_updated.emit()

@rpc("authority", "reliable")
func sync_player_list(updated_players: Dictionary) -> void:
	players = updated_players
	player_list_updated.emit()

static func get_local_ip_addresses() -> Array[String]:
	var addresses: Array[String] = []
	for ip in IP.get_local_addresses():
		# Filter for IPv4 and non-loopback
		if ip.count(".") == 3 and not ip.begins_with("127."):
			addresses.append(ip)
	if addresses.is_empty():
		addresses.append("127.0.0.1")
	return addresses
