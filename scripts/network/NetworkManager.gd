class_name NetworkManager
extends Node

signal server_created()
signal join_success()
signal join_failed()
signal player_list_updated()
signal player_registered(peer_id: int)
signal server_disconnected()

const WebRTCSignalerScript = preload("res://scripts/network/WebRTCSignaler.gd")

const DEFAULT_PORT: int = 7777
const MAX_PLAYERS: int = 8

var peer: MultiplayerPeer = null
var connection_mode: String = "enet" # "enet" or "webrtc"
var webrtc_peers: Dictionary = {} # peer_id: WebRTCPeerConnection
var webrtc_has_remote_description: Dictionary = {} # peer_id: bool
var pending_ice_candidates: Dictionary = {} # peer_id: Array[Dictionary]
var signaler: Node = null # WebRTCSignaler instance
var current_webrtc_lobby_id: String = ""

var players: Dictionary = {} # peer_id: { "name": String, "score": int, "role": int, "character": int, "color_idx": int, "outfit": Dictionary }
var local_player_name: String = "Batang Kalye"
var local_character_type: int = 0
var local_color_index: int = 0
var local_outfit: Dictionary = {
	"archetype": 0,
	"base": 0,
	"skin": 0,
	"hair": 0,
	"headwear": 0,
	"body": 0,
	"footwear": 0,
	"color": 0
}
var is_host: bool = false
var is_solo_practice: bool = false
var last_join_ip: String = ""
var last_join_port: int = DEFAULT_PORT

func _ready() -> void:
	set_process(true)
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)

func _process(_delta: float) -> void:
	if connection_mode == "webrtc":
		for peer_id in webrtc_peers.keys():
			var conn: WebRTCPeerConnection = webrtc_peers.get(peer_id)
			if conn:
				conn.poll()

func create_game(player_name: String, port: int = DEFAULT_PORT) -> Error:
	local_player_name = player_name
	is_host = true
	is_solo_practice = false
	connection_mode = "enet"

	_cleanup_peers()

	var enet_peer := ENetMultiplayerPeer.new()
	var err := enet_peer.create_server(port, MAX_PLAYERS)
	if err != OK:
		push_error("Failed to create server on port %d: %s" % [port, error_string(err)])
		return err

	peer = enet_peer
	multiplayer.multiplayer_peer = peer
	players.clear()
	players[1] = {
		"name": local_player_name,
		"score": 0,
		"role": 0,
		"character": local_outfit.get("base", local_character_type),
		"color_idx": local_outfit.get("color", local_color_index),
		"outfit": local_outfit
	}
	server_created.emit()
	player_list_updated.emit()
	return OK

func join_game(address: String, player_name: String, port: int = DEFAULT_PORT) -> Error:
	local_player_name = player_name
	is_host = false
	is_solo_practice = false
	connection_mode = "enet"

	_cleanup_peers()

	var target_ip := address.strip_edges()
	if target_ip.is_empty():
		target_ip = "127.0.0.1"

	# If address has embedded port, e.g. "something.gl.at.ply.gg:12345"
	if ":" in target_ip:
		var parts := target_ip.split(":")
		target_ip = parts[0].strip_edges()
		if parts.size() > 1 and parts[1].strip_edges().is_valid_int():
			port = parts[1].strip_edges().to_int()

	# Validate port range
	if port <= 0 or port > 65535:
		port = DEFAULT_PORT

	last_join_ip = target_ip
	last_join_port = port

	# Resolve hostname if domain is provided
	var resolved_address := target_ip
	if not target_ip.is_valid_ip_address():
		var dns_result := IP.resolve_hostname(target_ip, IP.TYPE_IPV4)
		if not dns_result.is_empty():
			print("[NetworkManager] Resolved %s -> %s" % [target_ip, dns_result])
			resolved_address = dns_result
		else:
			print("[NetworkManager] DNS resolution empty, passing %s directly to ENet" % target_ip)

	var enet_peer := ENetMultiplayerPeer.new()
	var err := enet_peer.create_client(resolved_address, port)
	if err != OK:
		push_error("Failed to connect to %s:%d: %s" % [resolved_address, port, error_string(err)])
		join_failed.emit()
		return err

	peer = enet_peer
	multiplayer.multiplayer_peer = peer
	print("[NetworkManager] Connecting to %s:%d (peer status: %d)" % [resolved_address, port, peer.get_connection_status()])

	# Safety connection timeout timer (12s)
	get_tree().create_timer(12.0).timeout.connect(func():
		if peer and peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTING:
			print("[NetworkManager] Connection timed out after 12 seconds")
			leave_game()
			join_failed.emit()
	)

	return OK

func create_webrtc_game(player_name: String, lobby_id: String, supabase_url: String, supabase_key: String) -> Error:
	local_player_name = player_name
	is_host = true
	is_solo_practice = false
	connection_mode = "webrtc"
	current_webrtc_lobby_id = lobby_id

	_cleanup_peers()

	var rtc_peer := WebRTCMultiplayerPeer.new()
	var err := rtc_peer.create_server()
	if err != OK:
		push_error("Failed to create WebRTC server: %d" % err)
		return err

	peer = rtc_peer
	multiplayer.multiplayer_peer = peer
	players.clear()
	players[1] = {
		"name": local_player_name,
		"score": 0,
		"role": 0,
		"character": local_outfit.get("base", local_character_type),
		"color_idx": local_outfit.get("color", local_color_index),
		"outfit": local_outfit
	}

	_setup_signaler(supabase_url, supabase_key, lobby_id, 1)

	server_created.emit()
	player_list_updated.emit()
	return OK

func join_webrtc_game(lobby_id: String, player_name: String, supabase_url: String, supabase_key: String) -> Error:
	local_player_name = player_name
	is_host = false
	is_solo_practice = false
	connection_mode = "webrtc"
	current_webrtc_lobby_id = lobby_id

	_cleanup_peers()

	var client_id := randi_range(2, 999999)

	var rtc_peer := WebRTCMultiplayerPeer.new()
	var err := rtc_peer.create_client(client_id)
	if err != OK:
		push_error("Failed to create WebRTC client: %d" % err)
		join_failed.emit()
		return err

	peer = rtc_peer
	multiplayer.multiplayer_peer = peer

	_setup_signaler(supabase_url, supabase_key, lobby_id, client_id)

	# Safety connection timeout timer (30s to allow TURN relay allocation on mobile data)
	get_tree().create_timer(30.0).timeout.connect(func():
		if connection_mode == "webrtc" and not is_host:
			if multiplayer.multiplayer_peer == peer and not multiplayer.get_peers().has(1):
				print("[NetworkManager] WebRTC join timed out after 30 seconds")
				leave_game()
				join_failed.emit()
	)

	return OK

func _setup_signaler(supabase_url: String, supabase_key: String, lobby_id: String, my_id: int) -> void:
	if signaler:
		signaler.close()
		signaler.queue_free()
		signaler = null

	signaler = WebRTCSignalerScript.new()
	add_child(signaler)
	signaler.topic_joined.connect(_on_signaler_topic_joined)
	signaler.peer_announced.connect(_on_signaler_peer_announced)
	signaler.signal_received.connect(_on_signaler_signal_received)
	signaler.connection_failed.connect(func(reason):
		print("[NetworkManager] WebRTCSignaler failed: ", reason)
		if not is_host:
			leave_game()
			join_failed.emit()
	)
	signaler.connect_to_lobby(supabase_url, supabase_key, lobby_id, my_id)

func _on_signaler_topic_joined() -> void:
	print("[NetworkManager] Connected to signaling topic. My peer ID: ", multiplayer.get_unique_id())
	if not is_host:
		_create_client_peer_connection(1)

func _on_signaler_peer_announced(from_peer: int) -> void:
	print("[NetworkManager] Peer %d announced presence on signaling topic." % from_peer)
	if not is_host and from_peer == 1:
		# Host is active on the channel; ensure offer is created and dispatched
		if not webrtc_has_remote_description.get(1, false):
			print("[NetworkManager Client] Host announced presence, sending offer...")
			_create_client_peer_connection(1)

func _create_client_peer_connection(target_peer_id: int) -> void:
	if webrtc_peers.has(target_peer_id):
		var old_conn: WebRTCPeerConnection = webrtc_peers[target_peer_id]
		if old_conn:
			old_conn.close()
		webrtc_peers.erase(target_peer_id)
		webrtc_has_remote_description.erase(target_peer_id)

	var conn := WebRTCPeerConnection.new()
	var init_err := conn.initialize({
		"iceServers": WebRTCSignalerScript.ICE_SERVERS
	})
	if init_err != OK:
		push_error("[NetworkManager] Failed to init client WebRTCPeerConnection: %d" % init_err)
		return

	conn.session_description_created.connect(func(type, sdp):
		conn.set_local_description(type, sdp)
		if signaler:
			signaler.send_signal(target_peer_id, "offer", {"type": type, "sdp": sdp})
	)

	conn.ice_candidate_created.connect(func(cand_media, cand_index, cand_name):
		print("[NetworkManager Client] ICE candidate gathered: ", cand_name)
		if signaler:
			signaler.send_signal(target_peer_id, "candidate", {"media": cand_media, "index": cand_index, "name": cand_name})
	)

	webrtc_peers[target_peer_id] = conn
	if peer is WebRTCMultiplayerPeer:
		peer.add_peer(conn, target_peer_id)

	conn.create_offer()

func _is_unreachable_private_candidate(cand_str: String) -> bool:
	if not "typ host" in cand_str:
		return false

	var parts := cand_str.split(" ")
	if parts.size() <= 4:
		return false
	var ip := parts[4]

	var is_private := false
	if ip.begins_with("10.") or ip.begins_with("192.168.") or ip.begins_with("127.") or ip.begins_with("100."):
		is_private = true
	elif ip.begins_with("172."):
		var octets := ip.split(".")
		if octets.size() > 1:
			var second := int(octets[1])
			if second >= 16 and second <= 31:
				is_private = true

	if not is_private:
		return false

	# If remote host is on the exact same local subnet (e.g. both on same 192.168.1.x Wi-Fi), allow it
	var my_ips := IP.get_local_addresses()
	for local_ip in my_ips:
		if local_ip.count(".") == 3 and ip.count(".") == 3:
			var local_prefix := local_ip.substr(0, local_ip.rfind("."))
			var remote_prefix := ip.substr(0, ip.rfind("."))
			if local_prefix == remote_prefix:
				return false

	return true

func _handle_incoming_candidate(from_peer: int, data: Dictionary) -> void:
	var cand_name: String = str(data.get("name", ""))
	var cand_media: String = str(data.get("media", ""))
	var cand_index: int = int(data.get("index", 0))

	if _is_unreachable_private_candidate(cand_name):
		print("[NetworkManager] Skipping unreachable private candidate from peer %d: %s" % [from_peer, cand_name])
		return

	print("[NetworkManager] Received valid ICE candidate from peer %d: %s" % [from_peer, cand_name])
	if webrtc_peers.has(from_peer) and webrtc_has_remote_description.get(from_peer, false):
		var conn: WebRTCPeerConnection = webrtc_peers[from_peer]
		var add_err := conn.add_ice_candidate(cand_media, cand_index, cand_name)
		print("[NetworkManager] Added ICE candidate for peer %d (res=%d)" % [from_peer, add_err])
	else:
		if not pending_ice_candidates.has(from_peer):
			pending_ice_candidates[from_peer] = []
		pending_ice_candidates[from_peer].append(data)
		print("[NetworkManager] Queued pending candidate for peer %d (total: %d)" % [from_peer, pending_ice_candidates[from_peer].size()])

func _flush_pending_ice_candidates(peer_id: int) -> void:
	if webrtc_peers.has(peer_id) and pending_ice_candidates.has(peer_id):
		var conn: WebRTCPeerConnection = webrtc_peers[peer_id]
		var candidates: Array = pending_ice_candidates[peer_id]
		print("[NetworkManager] Flushing %d pending ICE candidates for peer %d" % [candidates.size(), peer_id])
		for c in candidates:
			var c_name: String = str(c.get("name", ""))
			if _is_unreachable_private_candidate(c_name):
				print("[NetworkManager] Skipping unreachable pending candidate: ", c_name)
				continue
			var add_err := conn.add_ice_candidate(str(c.get("media", "")), int(c.get("index", 0)), c_name)
			print("[NetworkManager] Flushed candidate (res=%d): %s" % [add_err, c_name])
		pending_ice_candidates.erase(peer_id)

func _on_signaler_signal_received(from_peer: int, _to_peer: int, sig_type: String, data: Dictionary) -> void:
	if is_host:
		if sig_type == "offer":
			print("[NetworkManager Host] Received offer from peer %d" % from_peer)
			var conn: WebRTCPeerConnection
			if webrtc_peers.has(from_peer):
				conn = webrtc_peers[from_peer]
			else:
				conn = WebRTCPeerConnection.new()
				conn.initialize({
					"iceServers": WebRTCSignalerScript.ICE_SERVERS
				})
				conn.session_description_created.connect(func(type, sdp):
					conn.set_local_description(type, sdp)
					if signaler:
						signaler.send_signal(from_peer, "answer", {"type": type, "sdp": sdp})
				)
				conn.ice_candidate_created.connect(func(cand_media, cand_index, cand_name):
					print("[NetworkManager Host] ICE candidate gathered: ", cand_name)
					if signaler:
						signaler.send_signal(from_peer, "candidate", {"media": cand_media, "index": cand_index, "name": cand_name})
				)
				webrtc_peers[from_peer] = conn
				if peer is WebRTCMultiplayerPeer:
					peer.add_peer(conn, from_peer)

			conn.set_remote_description(data.get("type", "offer"), data.get("sdp", ""))
			webrtc_has_remote_description[from_peer] = true
			_flush_pending_ice_candidates(from_peer)

		elif sig_type == "candidate":
			print("[NetworkManager Host] Received candidate signal from peer %d" % from_peer)
			_handle_incoming_candidate(from_peer, data)

	else:
		if sig_type == "answer" and from_peer == 1:
			print("[NetworkManager Client] Received answer from host")
			if webrtc_peers.has(1):
				var conn: WebRTCPeerConnection = webrtc_peers[1]
				conn.set_remote_description(data.get("type", "answer"), data.get("sdp", ""))
				webrtc_has_remote_description[1] = true
				_flush_pending_ice_candidates(1)

		elif sig_type == "candidate" and from_peer == 1:
			print("[NetworkManager Client] Received candidate signal from host")
			_handle_incoming_candidate(from_peer, data)

func set_local_outfit(outfit: Dictionary) -> void:
	local_outfit = outfit.duplicate()
	local_character_type = outfit.get("base", 0)
	local_color_index = outfit.get("color", 0)
	var my_id := multiplayer.get_unique_id() if multiplayer.has_multiplayer_peer() else 1
	if players.has(my_id):
		players[my_id]["character"] = local_character_type
		players[my_id]["color_idx"] = local_color_index
		players[my_id]["outfit"] = local_outfit
		if multiplayer.has_multiplayer_peer():
			if multiplayer.is_server():
				rpc("sync_player_list", players)
			else:
				rpc_id(1, "update_outfit", local_outfit)
		player_list_updated.emit()

func set_local_customization(char_type: int, color_idx: int) -> void:
	local_character_type = char_type
	local_color_index = color_idx
	local_outfit = {
		"archetype": char_type,
		"base": char_type,
		"skin": 0,
		"hair": 0,
		"headwear": 0,
		"body": 0,
		"footwear": 0,
		"color": color_idx
	}
	set_local_outfit(local_outfit)

func leave_game() -> void:
	_cleanup_peers()
	connection_mode = "enet"
	current_webrtc_lobby_id = ""
	players.clear()
	is_host = false
	is_solo_practice = false
	player_list_updated.emit()

func _cleanup_peers() -> void:
	if signaler:
		signaler.close()
		signaler.queue_free()
		signaler = null
	for conn in webrtc_peers.values():
		if conn:
			conn.close()
	webrtc_peers.clear()
	webrtc_has_remote_description.clear()
	pending_ice_candidates.clear()
	if peer:
		peer.close()
		multiplayer.multiplayer_peer = null
		peer = null

func _on_peer_connected(id: int) -> void:
	if multiplayer.is_server():
		# Send current players to the newcomer
		rpc_id(id, "sync_player_list", players)

func _on_peer_disconnected(id: int) -> void:
	if connection_mode == "webrtc" and webrtc_peers.has(id):
		var conn: WebRTCPeerConnection = webrtc_peers.get(id)
		if conn:
			conn.close()
		webrtc_peers.erase(id)
	if players.has(id):
		players.erase(id)
		player_list_updated.emit()
		if multiplayer.is_server():
			rpc("sync_player_list", players)

func _on_connected_to_server() -> void:
	rpc_id(1, "register_player_outfit", local_player_name, local_outfit)
	join_success.emit()

func _on_connection_failed() -> void:
	_cleanup_peers()
	join_failed.emit()

func _on_server_disconnected() -> void:
	_cleanup_peers()
	connection_mode = "enet"
	current_webrtc_lobby_id = ""
	players.clear()
	player_list_updated.emit()
	server_disconnected.emit()

@rpc("any_peer", "reliable")
func register_player_outfit(new_name: String, outfit: Dictionary) -> void:
	if not multiplayer.is_server():
		return
	var sender_id := multiplayer.get_remote_sender_id()
	players[sender_id] = {
		"name": new_name,
		"score": 0,
		"role": 0,
		"character": outfit.get("base", 0),
		"color_idx": outfit.get("color", 0),
		"outfit": outfit
	}
	rpc("sync_player_list", players)
	player_list_updated.emit()
	player_registered.emit(sender_id)

@rpc("any_peer", "reliable")
func register_player(new_name: String, char_type: int = 0, color_idx: int = 0) -> void:
	var dummy_outfit := {
		"archetype": char_type,
		"base": char_type,
		"skin": 0,
		"hair": 0,
		"headwear": 0,
		"body": 0,
		"footwear": 0,
		"color": color_idx
	}
	register_player_outfit(new_name, dummy_outfit)

@rpc("any_peer", "reliable")
func update_outfit(outfit: Dictionary) -> void:
	var sender_id := multiplayer.get_remote_sender_id()
	if sender_id == 0:
		sender_id = multiplayer.get_unique_id()
	if players.has(sender_id):
		players[sender_id]["outfit"] = outfit
		players[sender_id]["character"] = outfit.get("base", 0)
		players[sender_id]["color_idx"] = outfit.get("color", 0)
		if multiplayer.is_server():
			rpc("sync_player_list", players)
		player_list_updated.emit()

@rpc("any_peer", "reliable")
func update_customization(char_type: int, color_idx: int) -> void:
	var dummy_outfit := {
		"archetype": char_type,
		"base": char_type,
		"skin": 0,
		"hair": 0,
		"headwear": 0,
		"body": 0,
		"footwear": 0,
		"color": color_idx
	}
	update_outfit(dummy_outfit)

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
