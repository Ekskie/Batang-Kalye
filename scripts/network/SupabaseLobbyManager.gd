class_name SupabaseLobbyManager
extends Node

## SupabaseLobbyManager
## Manages master server matchmaking directory using Supabase REST API (PostgREST).
## Allows hosts to register/heartbeat/remove rooms and clients to discover/join lobbies.

signal lobbies_fetched(lobbies: Array)
signal fetch_failed(error_message: String)
signal lobby_created(lobby_info: Dictionary)
signal create_failed(error_message: String)
signal lobby_updated()
signal lobby_deleted()
signal config_changed()

const CONFIG_PATH: String = "user://supabase_config.json"
const HEARTBEAT_INTERVAL: float = 15.0 # seconds

# Dedicated Project Supabase Credentials (Preconfigured)
const DEFAULT_SUPABASE_URL: String = "https://edzrwxnsjpljgnzhzwwz.supabase.co"
const DEFAULT_SUPABASE_ANON_KEY: String = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImVkenJ3eG5zanBsamduemh6d3d6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTA4NDgxMDEsImV4cCI6MjEwNjQyNDEwMX0.8YEmkZPmwo4RIT7y4ZpFfzYazq125SspsOIkhemFyek"

var supabase_url: String = DEFAULT_SUPABASE_URL
var supabase_anon_key: String = DEFAULT_SUPABASE_ANON_KEY

# Current Active Hosted Lobby
var current_lobby_id: String = ""
var current_lobby_name: String = ""
var is_hosting_lobby: bool = false
var detected_public_ip: String = ""

# Internal HTTP Request nodes
var _http_fetch: HTTPRequest
var _http_create: HTTPRequest
var _http_heartbeat: HTTPRequest
var _http_delete: HTTPRequest
var _http_ip: HTTPRequest
var _heartbeat_timer: Timer

func _ready() -> void:
	_init_http_nodes()
	load_config()
	_detect_public_ip()

func _init_http_nodes() -> void:
	_http_fetch = HTTPRequest.new()
	_http_fetch.timeout = 8.0
	_http_fetch.request_completed.connect(_on_fetch_completed)
	add_child(_http_fetch)

	_http_create = HTTPRequest.new()
	_http_create.timeout = 8.0
	_http_create.request_completed.connect(_on_create_completed)
	add_child(_http_create)

	_http_heartbeat = HTTPRequest.new()
	_http_heartbeat.timeout = 8.0
	_http_heartbeat.request_completed.connect(_on_heartbeat_completed)
	add_child(_http_heartbeat)

	_http_delete = HTTPRequest.new()
	_http_delete.timeout = 8.0
	_http_delete.request_completed.connect(_on_delete_completed)
	add_child(_http_delete)

	_http_ip = HTTPRequest.new()
	_http_ip.timeout = 5.0
	_http_ip.request_completed.connect(_on_ip_detected)
	add_child(_http_ip)

	_heartbeat_timer = Timer.new()
	_heartbeat_timer.wait_time = HEARTBEAT_INTERVAL
	_heartbeat_timer.one_shot = false
	_heartbeat_timer.timeout.connect(_on_heartbeat_tick)
	add_child(_heartbeat_timer)

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_PREDELETE:
		if is_hosting_lobby and not current_lobby_id.is_empty():
			# Synchronous best-effort remove or delete
			delete_lobby()

# ==============================================================================
# CONFIGURATION PERSISTENCE
# ==============================================================================

func is_configured() -> bool:
	return not supabase_url.strip_edges().is_empty() and not supabase_anon_key.strip_edges().is_empty()

func load_config() -> void:
	# Default to project master server credentials
	supabase_url = DEFAULT_SUPABASE_URL
	supabase_anon_key = DEFAULT_SUPABASE_ANON_KEY

	# Check ProjectSettings or user config overrides if present
	if ProjectSettings.has_setting("batang_kalye/network/supabase_url"):
		var p_url := str(ProjectSettings.get_setting("batang_kalye/network/supabase_url", "")).strip_edges()
		if not p_url.is_empty():
			supabase_url = p_url
	if ProjectSettings.has_setting("batang_kalye/network/supabase_key"):
		var p_key := str(ProjectSettings.get_setting("batang_kalye/network/supabase_key", "")).strip_edges()
		if not p_key.is_empty():
			supabase_anon_key = p_key

	if FileAccess.file_exists(CONFIG_PATH):
		var file := FileAccess.open(CONFIG_PATH, FileAccess.READ)
		if file:
			var content := file.get_as_text()
			file.close()
			var json_res = JSON.parse_string(content)
			if json_res is Dictionary:
				var u := str(json_res.get("url", "")).strip_edges()
				var k := str(json_res.get("key", "")).strip_edges()
				if not u.is_empty() and not k.is_empty():
					supabase_url = u
					supabase_anon_key = k

	config_changed.emit()

func save_config(url: String, key: String) -> void:
	supabase_url = url.strip_edges().trim_suffix("/")
	supabase_anon_key = key.strip_edges()

	var data := {
		"url": supabase_url,
		"key": supabase_anon_key
	}
	var file := FileAccess.open(CONFIG_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data, "\t"))
		file.close()

	config_changed.emit()

func get_auth_headers() -> PackedStringArray:
	return PackedStringArray([
		"apikey: " + supabase_anon_key,
		"Authorization: Bearer " + supabase_anon_key,
		"Content-Type: application/json"
	])

# ==============================================================================
# PUBLIC IP DETECTION
# ==============================================================================

func _detect_public_ip() -> void:
	if _http_ip:
		var err := _http_ip.request("https://api.ipify.org?format=json")
		if err != OK:
			print("[SupabaseLobbyManager] Could not start public IP request: ", err)

func _on_ip_detected(_result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	if response_code == 200:
		var parsed = JSON.parse_string(body.get_string_from_utf8())
		if parsed is Dictionary and parsed.has("ip"):
			detected_public_ip = str(parsed["ip"]).strip_edges()
			print("[SupabaseLobbyManager] Detected Public IP: ", detected_public_ip)

func get_best_host_address(fallback_ip: String = "") -> String:
	# If caller passed a custom IP or PlayIt domain, use it
	var clean := fallback_ip.strip_edges()
	if not clean.is_empty() and clean != "127.0.0.1" and clean != "localhost":
		return clean

	# If public IP is available, prefer it for internet play
	if not detected_public_ip.is_empty():
		return detected_public_ip

	# Fallback to local network IP
	var local_ips := NetworkManager.get_local_ip_addresses()
	if not local_ips.is_empty():
		return local_ips[0]

	return "127.0.0.1"

# ==============================================================================
# LOBBY BROWSER (FETCH)
# ==============================================================================

func fetch_lobbies() -> void:
	if not is_configured():
		fetch_failed.emit("Hindi ma-access ang Supabase matchmaking server.")
		return

	var endpoint := supabase_url + "/rest/v1/lobbies?select=*&is_started=eq.false&order=created_at.desc"
	var headers := PackedStringArray([
		"apikey: " + supabase_anon_key,
		"Authorization: Bearer " + supabase_anon_key
	])

	var err := _http_fetch.request(endpoint, headers, HTTPClient.METHOD_GET)
	if err != OK:
		fetch_failed.emit("Hindi makakonekta sa Supabase API: Error %d" % err)

func _on_fetch_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	if result != HTTPRequest.RESULT_SUCCESS:
		fetch_failed.emit("Walang koneksyon sa internet o hindi maabot ang Supabase.")
		return

	if response_code == 401 or response_code == 403:
		fetch_failed.emit("Supabase Auth Error (%d): Maling Anon Key o kulang sa RLS policy." % response_code)
		return

	if response_code == 404:
		fetch_failed.emit("Hindi nahanap ang table na 'lobbies' sa Supabase database.")
		return

	if response_code < 200 or response_code >= 300:
		fetch_failed.emit("Supabase returned error code: %d" % response_code)
		return

	var text := body.get_string_from_utf8()
	var parsed = JSON.parse_string(text)
	if parsed is Array:
		lobbies_fetched.emit(parsed)
	else:
		lobbies_fetched.emit([])

# ==============================================================================
# LOBBY REGISTRATION (CREATE)
# ==============================================================================

func register_lobby(lobby_name: String, host_name: String, address: String, port: int, mode_name: String, max_p: int = 8) -> void:
	if not is_configured():
		create_failed.emit("Hindi ma-access ang Supabase matchmaking server.")
		return

	var endpoint := supabase_url + "/rest/v1/lobbies"
	var headers := PackedStringArray([
		"apikey: " + supabase_anon_key,
		"Authorization: Bearer " + supabase_anon_key,
		"Content-Type: application/json",
		"Prefer: return=representation"
	])

	var lobby_data := {
		"name": lobby_name,
		"host_name": host_name,
		"address": address,
		"port": port,
		"player_count": 1,
		"max_players": max_p,
		"game_mode": mode_name,
		"is_started": false
	}

	current_lobby_name = lobby_name
	var body := JSON.stringify(lobby_data)
	var err := _http_create.request(endpoint, headers, HTTPClient.METHOD_POST, body)
	if err != OK:
		create_failed.emit("Bigo sa pag-request ng lobby registration: Error %d" % err)

func _on_create_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	if result != HTTPRequest.RESULT_SUCCESS:
		create_failed.emit("Walang koneksyon sa internet sa paggawa ng lobby.")
		return

	if response_code != 201 and response_code != 200:
		var err_body := body.get_string_from_utf8()
		create_failed.emit("Supabase Create Error (%d): %s" % [response_code, err_body])
		return

	var text := body.get_string_from_utf8()
	var parsed = JSON.parse_string(text)
	if parsed is Array and not parsed.is_empty():
		var row: Dictionary = parsed[0]
		current_lobby_id = str(row.get("id", ""))
		is_hosting_lobby = true
		_heartbeat_timer.start()
		lobby_created.emit(row)
		print("[SupabaseLobbyManager] Lobby registered with ID: ", current_lobby_id)
	elif parsed is Dictionary:
		current_lobby_id = str(parsed.get("id", ""))
		is_hosting_lobby = true
		_heartbeat_timer.start()
		lobby_created.emit(parsed)
		print("[SupabaseLobbyManager] Lobby registered with ID: ", current_lobby_id)
	else:
		create_failed.emit("Hindi ma-parse ang sagot ng Supabase.")

# ==============================================================================
# HEARTBEAT & UPDATE
# ==============================================================================

func update_lobby(player_count: int, is_started: bool = false) -> void:
	if current_lobby_id.is_empty() or not is_configured():
		return

	var endpoint := supabase_url + "/rest/v1/lobbies?id=eq." + current_lobby_id
	var headers := get_auth_headers()
	var payload := {
		"player_count": player_count,
		"is_started": is_started
	}

	var body := JSON.stringify(payload)
	_http_heartbeat.request(endpoint, headers, HTTPClient.METHOD_PATCH, body)

func _on_heartbeat_tick() -> void:
	if not is_hosting_lobby or current_lobby_id.is_empty():
		return

	# Count players currently connected
	var count := 1
	var gm := get_tree().current_scene
	if gm and "network_manager" in gm and gm.network_manager:
		count = max(1, gm.network_manager.players.size())

	update_lobby(count, false)

func _on_heartbeat_completed(_result: int, response_code: int, _headers: PackedStringArray, _body: PackedByteArray) -> void:
	if response_code >= 200 and response_code < 300:
		lobby_updated.emit()

# ==============================================================================
# LOBBY REMOVAL (DELETE)
# ==============================================================================

func delete_lobby() -> void:
	if current_lobby_id.is_empty() or not is_configured():
		_cleanup_local_lobby_state()
		return

	var endpoint := supabase_url + "/rest/v1/lobbies?id=eq." + current_lobby_id
	var headers := PackedStringArray([
		"apikey: " + supabase_anon_key,
		"Authorization: Bearer " + supabase_anon_key
	])

	_http_delete.request(endpoint, headers, HTTPClient.METHOD_DELETE)
	_cleanup_local_lobby_state()

func _on_delete_completed(_result: int, _response_code: int, _headers: PackedStringArray, _body: PackedByteArray) -> void:
	lobby_deleted.emit()
	print("[SupabaseLobbyManager] Lobby deleted from Supabase.")

func _cleanup_local_lobby_state() -> void:
	_heartbeat_timer.stop()
	current_lobby_id = ""
	current_lobby_name = ""
	is_hosting_lobby = false
