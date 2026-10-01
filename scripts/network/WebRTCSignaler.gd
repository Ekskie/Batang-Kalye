class_name WebRTCSignaler
extends Node

## WebRTCSignaler
## Facilitates WebRTC signaling (Offer/Answer and ICE Candidates) between players
## over Supabase Realtime WebSockets using the Phoenix Channels protocol.

signal connected_to_server()
signal topic_joined()
signal peer_announced(peer_id: int)
signal signal_received(from_peer: int, to_peer: int, signal_type: String, data: Dictionary)
signal connection_failed(reason: String)
signal disconnected()

const PHOENIX_HEARTBEAT_INTERVAL: float = 25.0 # seconds
const STUN_SERVERS: Array = [
	{"urls": ["stun:stun.l.google.com:19302", "stun:stun1.l.google.com:19302"]}
]

var ws: WebSocketPeer = WebSocketPeer.new()
var supabase_url: String = ""
var supabase_anon_key: String = ""
var current_lobby_id: String = ""
var current_topic: String = ""
var my_peer_id: int = 1

var is_connected_ws: bool = false
var is_joined_topic: bool = false

var _ref_counter: int = 0
var _heartbeat_timer: float = 0.0
var _join_ref: String = ""

func _ready() -> void:
	set_process(true)

func _process(delta: float) -> void:
	if not ws:
		return

	ws.poll()
	var state := ws.get_ready_state()

	if state == WebSocketPeer.STATE_OPEN:
		if not is_connected_ws:
			is_connected_ws = true
			connected_to_server.emit()
			_join_lobby_topic()

		_heartbeat_timer += delta
		if _heartbeat_timer >= PHOENIX_HEARTBEAT_INTERVAL:
			_heartbeat_timer = 0.0
			_send_heartbeat()

		while ws.get_available_packet_count() > 0:
			var pkt := ws.get_packet()
			var text := pkt.get_string_from_utf8()
			_handle_message(text)

	elif state == WebSocketPeer.STATE_CLOSED:
		if is_connected_ws or is_joined_topic:
			is_connected_ws = false
			is_joined_topic = false
			var code := ws.get_close_code()
			var reason := ws.get_close_reason()
			print("[WebRTCSignaler] Disconnected. Code: %d, Reason: %s" % [code, reason])
			disconnected.emit()

func connect_to_lobby(p_supabase_url: String, p_anon_key: String, p_lobby_id: String, p_peer_id: int) -> Error:
	close()

	supabase_url = p_supabase_url.strip_edges().trim_suffix("/")
	supabase_anon_key = p_anon_key.strip_edges()
	current_lobby_id = p_lobby_id.strip_edges()
	my_peer_id = p_peer_id
	current_topic = "realtime:lobby_" + current_lobby_id

	# Construct WebSocket URL
	var ws_domain := supabase_url.replace("https://", "wss://").replace("http://", "ws://")
	var ws_url := "%s/realtime/v1/websocket?apikey=%s&vsn=1.0.0" % [ws_domain, supabase_anon_key]

	is_connected_ws = false
	is_joined_topic = false
	_heartbeat_timer = 0.0

	var err := ws.connect_to_url(ws_url)
	if err != OK:
		push_error("[WebRTCSignaler] Failed to connect to URL: %s" % error_string(err))
		connection_failed.emit("Failed to initiate WebSocket connection: %d" % err)
		return err

	print("[WebRTCSignaler] Connecting to Supabase Realtime for lobby: %s (peer %d)..." % [current_lobby_id, my_peer_id])
	return OK

func _join_lobby_topic() -> void:
	if not is_connected_ws or current_topic.is_empty():
		return

	_ref_counter += 1
	_join_ref = str(_ref_counter)

	var msg := {
		"topic": current_topic,
		"event": "phx_join",
		"payload": {
			"config": {
				"broadcast": {
					"self": false # Do not receive own echoes
				}
			}
		},
		"ref": _join_ref
	}
	ws.send_text(JSON.stringify(msg))
	print("[WebRTCSignaler] Sent phx_join for topic: ", current_topic)

func _send_heartbeat() -> void:
	if not is_connected_ws:
		return
	_ref_counter += 1
	var msg := {
		"topic": "phoenix",
		"event": "heartbeat",
		"payload": {},
		"ref": str(_ref_counter)
	}
	ws.send_text(JSON.stringify(msg))

func send_signal(to_peer: int, signal_type: String, data: Dictionary) -> void:
	if not is_joined_topic or ws.get_ready_state() != WebSocketPeer.STATE_OPEN:
		return

	_ref_counter += 1
	var payload := {
		"from_peer": my_peer_id,
		"to_peer": to_peer,
		"signal_type": signal_type,
		"data": data
	}

	var msg := {
		"topic": current_topic,
		"event": "broadcast",
		"payload": {
			"type": "broadcast",
			"event": "webrtc_signal",
			"payload": payload
		},
		"ref": str(_ref_counter)
	}
	ws.send_text(JSON.stringify(msg))

func announce_presence() -> void:
	send_signal(0, "peer_announce", {"peer_id": my_peer_id})

func _handle_message(text: String) -> void:
	var parsed = JSON.parse_string(text)
	if not parsed is Dictionary:
		return

	var event := str(parsed.get("event", ""))
	var topic := str(parsed.get("topic", ""))

	# Confirm topic join
	if event == "phx_reply" and str(parsed.get("ref", "")) == _join_ref:
		var reply_payload: Dictionary = parsed.get("payload", {})
		if reply_payload.get("status") == "ok":
			is_joined_topic = true
			print("[WebRTCSignaler] Successfully joined topic: ", topic)
			topic_joined.emit()
			announce_presence()
		else:
			connection_failed.emit("Failed to join Supabase lobby channel.")
		return

	# Handle broadcast WebRTC signals
	if event == "broadcast" and topic == current_topic:
		var wrapper: Dictionary = parsed.get("payload", {})
		if wrapper.get("event") == "webrtc_signal":
			var signal_data: Dictionary = wrapper.get("payload", {})
			var from_peer: int = int(signal_data.get("from_peer", 0))
			var to_peer: int = int(signal_data.get("to_peer", 0))
			var sig_type: String = str(signal_data.get("signal_type", ""))
			var data: Dictionary = signal_data.get("data", {})

			# If signal is for everyone (0) or specifically addressed to us
			if to_peer == 0 or to_peer == my_peer_id:
				if sig_type == "peer_announce":
					peer_announced.emit(from_peer)
				else:
					signal_received.emit(from_peer, to_peer, sig_type, data)

func close() -> void:
	is_connected_ws = false
	is_joined_topic = false
	current_topic = ""
	current_lobby_id = ""
	if ws and ws.get_ready_state() != WebSocketPeer.STATE_CLOSED:
		ws.close(1000, "Normal Closure")
