class_name NanayEvent
extends Node

signal player_sent_home(player_id: int, player_name: String)

@export var min_event_interval: float = 45.0
@export var max_event_interval: float = 90.0
@export var home_reach_radius: float = 3.0
@export var event_duration: float = 15.0

var game_manager: GameManager = null
var players_container: Node3D = null
var nanay_timer: float = 0.0
var active_event: bool = false
var event_target_id: int = -1
var event_timer: float = 0.0
var home_marker: Node3D = null
var event_label: Label3D = null
var sent_home_ids: Array = []

const TINDAHAN_POS := Vector3(-8.5, 0.5, 0.0)

func _ready() -> void:
	_reset_nanay_timer()

func setup(gm: GameManager, pc: Node3D) -> void:
	game_manager = gm
	players_container = pc

	home_marker = Node3D.new()
	home_marker.name = "HomeMarker"
	add_child(home_marker)

	var mesh_inst := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 2.0
	cyl.bottom_radius = 2.0
	cyl.height = 0.15
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 0.85, 0.1, 0.75)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.7, 0.0)
	mat.emission_energy_multiplier = 1.5
	cyl.material = mat
	mesh_inst.mesh = cyl
	home_marker.add_child(mesh_inst)

	event_label = Label3D.new()
	event_label.text = ""
	event_label.font_size = 20
	event_label.outline_size = 5
	event_label.modulate = Color(1, 0.9, 0.2, 1)
	event_label.position = Vector3(0, 2.5, 0)
	home_marker.add_child(event_label)

	home_marker.global_position = TINDAHAN_POS
	home_marker.visible = false

func _physics_process(delta: float) -> void:
	if not game_manager or not players_container:
		return
	if game_manager.current_state != GameManager.GameState.PLAYING:
		if active_event:
			_cancel_event()
		return

	if active_event:
		_tick_event(delta)
	else:
		nanay_timer -= delta
		if nanay_timer <= 0.0:
			_try_start_event()
			_reset_nanay_timer()

func _reset_nanay_timer() -> void:
	nanay_timer = randf_range(min_event_interval, max_event_interval)

func _try_start_event() -> void:
	if not multiplayer.is_server() and multiplayer.has_multiplayer_peer():
		return
	if not players_container:
		return

	var eligible: Array = []
	for child in players_container.get_children():
		if child is PlayerController:
			var pc: PlayerController = child as PlayerController
			if pc.current_role == PlayerController.Role.RUNNER:
				if not sent_home_ids.has(pc.player_id):
					if not pc.is_stunned:
						eligible.append(pc)

	if eligible.is_empty():
		return

	var chosen: PlayerController = eligible[randi() % eligible.size()]
	_start_event(chosen.player_id, chosen.player_name)

func _start_event(pid: int, pname: String) -> void:
	if multiplayer.has_multiplayer_peer() and multiplayer.is_server():
		rpc("sync_nanay_event", pid, pname)
	else:
		sync_nanay_event(pid, pname)

@rpc("call_local", "reliable")
func sync_nanay_event(pid: int, pname: String) -> void:
	active_event = true
	event_target_id = pid
	event_timer = event_duration
	if home_marker:
		home_marker.visible = true
	if event_label:
		event_label.text = "🏠 UWI NA, %s!\nPINAPAUWI KA NI NANAY!" % pname.to_upper()

	var local_id := multiplayer.get_unique_id()
	if local_id == pid or not multiplayer.has_multiplayer_peer():
		if game_manager and game_manager.hud:
			game_manager.hud.show_nanay_alert(pname)

func _tick_event(delta: float) -> void:
	event_timer -= delta

	var target: PlayerController = null
	if players_container:
		var node = players_container.get_node_or_null(str(event_target_id))
		if node is PlayerController:
			target = node as PlayerController

	if is_instance_valid(target):
		var dist: float = target.global_position.distance_to(TINDAHAN_POS)
		if dist < home_reach_radius:
			_send_player_home(event_target_id, target.player_name)
			return

	if event_timer <= 0.0:
		_cancel_event()

func _send_player_home(pid: int, pname: String) -> void:
	if not sent_home_ids.has(pid):
		sent_home_ids.append(pid)
	if multiplayer.has_multiplayer_peer() and multiplayer.is_server():
		rpc("sync_sent_home", pid, pname)
	else:
		sync_sent_home(pid, pname)

func _cancel_event() -> void:
	active_event = false
	event_target_id = -1
	if home_marker:
		home_marker.visible = false
	if event_label:
		event_label.text = ""

@rpc("call_local", "reliable")
func sync_sent_home(pid: int, pname: String) -> void:
	active_event = false
	event_target_id = -1
	if home_marker:
		home_marker.visible = false
	if event_label:
		event_label.text = ""

	player_sent_home.emit(pid, pname)

	var local_id := multiplayer.get_unique_id()
	if local_id == pid or not multiplayer.has_multiplayer_peer():
		if game_manager and game_manager.hud:
			game_manager.hud.show_toast_notification("🏠 Pinauwi ka ni Nanay! Hihintayin ka sa susunod na laro.", false)

func clear_sent_home() -> void:
	sent_home_ids.clear()
