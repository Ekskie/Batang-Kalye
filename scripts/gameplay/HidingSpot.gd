class_name HidingSpot
extends Node3D

enum SpotType {
	BLUE_DRUM = 0,
	CARDBOARD_BOX = 1
}

@export var spot_type: SpotType = SpotType.BLUE_DRUM
@export var max_hide_duration: float = 8.0

var occupant: PlayerController = null
var hide_timer: float = 0.0
var is_occupied: bool = false
var wobble_intensity: float = 0.0

@onready var visual_root: Node3D = get_node_or_null("VisualRoot")
@onready var interact_area: Area3D = get_node_or_null("InteractArea")
@onready var slap_area: Area3D = get_node_or_null("SlapArea")
@onready var prompt_label: Label3D = get_node_or_null("PromptLabel")

var nearby_players: Array[PlayerController] = []

func _ready() -> void:
	add_to_group("hiding_spots")
	_build_visuals()
	if interact_area:
		interact_area.body_entered.connect(_on_body_entered)
		interact_area.body_exited.connect(_on_body_exited)

func _process(delta: float) -> void:
	if is_occupied and is_instance_valid(occupant):
		hide_timer += delta

		# Lock occupant position inside
		occupant.global_position = global_position + Vector3(0, 0.1, 0)
		occupant.velocity = Vector3.ZERO

		# Faster burst stamina recovery while hiding
		occupant.burst_stamina = min(occupant.burst_stamina_max, occupant.burst_stamina + 25.0 * delta)

		# Wobble starts after 5 seconds (heartbeat tension)
		if hide_timer >= 4.5:
			var t := (hide_timer - 4.5) * 18.0
			wobble_intensity = min(1.0, wobble_intensity + delta * 0.8)
			if visual_root:
				visual_root.rotation.z = sin(t) * 0.08 * wobble_intensity
				visual_root.rotation.x = cos(t * 0.7) * 0.06 * wobble_intensity
		else:
			wobble_intensity = 0.0
			if visual_root:
				visual_root.rotation = Vector3.ZERO

		# Max time reached -> Eject! (Authoritative on server or solo)
		if hide_timer >= max_hide_duration:
			if not multiplayer.has_multiplayer_peer() or multiplayer.is_server():
				eject_occupant(true)

	else:
		if visual_root:
			visual_root.rotation = Vector3.ZERO
		wobble_intensity = 0.0

	_update_prompt()

func _update_prompt() -> void:
	if not prompt_label:
		return

	if is_occupied:
		if is_instance_valid(occupant) and occupant.is_local_human():
			var time_left: float = max(0.0, max_hide_duration - hide_timer)
			prompt_label.visible = true
			prompt_label.text = "NAGTATAGO! (%.1fs) [SPACE: LABAS]" % time_left
			prompt_label.modulate = Color(1.0, 0.35, 0.35) if time_left < 3.0 else Color(0.4, 1.0, 0.6)
		else:
			prompt_label.visible = false
		return

	# Empty: Show prompt for local runner
	var show_for_local := false
	for p in nearby_players:
		if is_instance_valid(p) and p.is_local_human():
			if p.current_role == PlayerController.Role.RUNNER and not p.is_eliminated:
				show_for_local = true
				break

	if show_for_local:
		prompt_label.visible = true
		prompt_label.text = "MAGTAGO SA DRUM [E]" if spot_type == SpotType.BLUE_DRUM else "MAGTAGO SA KARTON [E]"
		prompt_label.modulate = Color(0.3, 0.85, 1.0)
	else:
		prompt_label.visible = false

func _is_multiplayer_active() -> bool:
	return is_inside_tree() and multiplayer != null and multiplayer.has_multiplayer_peer()

func _is_multiplayer_server() -> bool:
	return is_inside_tree() and multiplayer != null and multiplayer.has_multiplayer_peer() and multiplayer.is_server()

func interact(player: PlayerController) -> void:
	if not is_instance_valid(player):
		return

	# If this player is already the occupant, they are leaving
	if is_occupied and occupant == player:
		request_eject(player.player_id)
		return

	# If occupied by someone else, cannot enter
	if is_occupied:
		return

	if player.current_role != PlayerController.Role.RUNNER or player.is_eliminated:
		return

	# In multiplayer, clients request the server authoritatively
	if _is_multiplayer_active() and not multiplayer.is_server():
		rpc_id(1, "request_interact_rpc", player.player_id)
		return

	# Authoritative execution on server or local/solo
	_server_execute_enter_hiding(player)

func _server_execute_enter_hiding(player: PlayerController) -> void:
	if is_occupied or not is_instance_valid(player):
		return
	if player.current_role != PlayerController.Role.RUNNER or player.is_eliminated:
		return

	if _is_multiplayer_active():
		rpc("sync_hide_state", player.player_id, true)
	else:
		sync_hide_state(player.player_id, true)

@rpc("any_peer", "reliable")
func request_interact_rpc(pid: int) -> void:
	if not _is_multiplayer_server():
		return
	var player := _find_player(pid)
	if not is_instance_valid(player):
		return
	# Validate distance to spot
	if global_position.distance_to(player.global_position) > 4.5:
		return
	interact(player)

func request_eject(pid: int) -> void:
	if _is_multiplayer_active() and not multiplayer.is_server():
		rpc_id(1, "request_eject_rpc", pid)
	else:
		eject_occupant(false)

@rpc("any_peer", "reliable")
func request_eject_rpc(pid: int) -> void:
	if not _is_multiplayer_server():
		return
	if is_occupied and is_instance_valid(occupant) and occupant.player_id == pid:
		eject_occupant(false)
	elif is_occupied:
		var p := _find_player(pid)
		if is_instance_valid(p) and p.is_hiding:
			eject_occupant(false)

func eject_occupant(forced: bool = false) -> void:
	if not is_occupied:
		return

	var pid := occupant.player_id if is_instance_valid(occupant) else 0

	if _is_multiplayer_server():
		rpc("sync_hide_state", pid, false, forced)
	else:
		sync_hide_state(pid, false, forced)

func on_taya_slap(taya: PlayerController) -> void:
	if not is_instance_valid(taya):
		return

	if _is_multiplayer_active() and not multiplayer.is_server():
		rpc_id(1, "request_slap_rpc", taya.player_id)
		return

	_server_execute_slap(taya)

@rpc("any_peer", "reliable")
func request_slap_rpc(taya_id: int) -> void:
	if not _is_multiplayer_server():
		return
	var taya := _find_player(taya_id)
	if not is_instance_valid(taya):
		return
	if global_position.distance_to(taya.global_position) > PlayerController.TAG_REACH + 1.5:
		return
	_server_execute_slap(taya)

func _server_execute_slap(taya: PlayerController) -> void:
	if is_occupied and is_instance_valid(occupant):
		# SUCCESSFUL TAG!
		var caught_player := occupant
		eject_occupant(false)

		if is_inside_tree():
			var ft = preload("res://scripts/player/FloatingText.gd")
			var spot_name: String = "KARTON" if spot_type == SpotType.CARDBOARD_BOX else "DRUM"
			var p_parent = get_parent()
			if p_parent:
				ft.spawn(p_parent, global_position + Vector3(0, 2.2, 0), "HULI SA %s!" % spot_name, Color(1.0, 0.2, 0.2))

		if taya.has_method("perform_tag_on"):
			taya.call("perform_tag_on", caught_player)
	else:
		# EMPTY SLAP! Stun Taya with hollow clang!
		if _is_multiplayer_server():
			rpc("sync_empty_slap", taya.player_id)
		else:
			sync_empty_slap(taya.player_id)

@rpc("call_local", "reliable")
func sync_empty_slap(taya_id: int) -> void:
	var tree := get_tree()
	var am = tree.root.get_node_or_null("AudioManager") if (tree and tree.root) else null
	if am and am.has_method("play_drum_clang"):
		am.play_drum_clang()

	if visual_root:
		var tw := create_tween()
		tw.tween_property(visual_root, "scale", Vector3(1.15, 0.85, 1.15), 0.08)
		tw.tween_property(visual_root, "scale", Vector3.ONE, 0.12)

	var taya := _find_player(taya_id)
	if is_instance_valid(taya):
		taya.apply_slipper_stun(1.0, "Walang Laman!")

	if is_inside_tree():
		var p_parent = get_parent()
		if p_parent:
			var ft = preload("res://scripts/player/FloatingText.gd")
			ft.spawn(p_parent, global_position + Vector3(0, 2.0, 0), "KLANG! WALANG TAO!", Color(1.0, 0.85, 0.2))

@rpc("call_local", "reliable")
func sync_hide_state(pid: int, occupied: bool, forced: bool = false) -> void:
	is_occupied = occupied
	var p := _find_player(pid)

	if occupied:
		hide_timer = 0.0
		wobble_intensity = 0.0
		if is_instance_valid(p):
			occupant = p
			p.enter_hiding_spot(self)

		var tree := get_tree()
		var am = tree.root.get_node_or_null("AudioManager") if (tree and tree.root) else null
		if am and am.has_method("play_drum_hide"):
			am.play_drum_hide()

		if is_inside_tree():
			var p_parent = get_parent()
			if p_parent:
				var ft = preload("res://scripts/player/FloatingText.gd")
				ft.spawn(p_parent, global_position + Vector3(0, 1.8, 0), "NAGTATAGO...", Color(0.3, 0.8, 1.0))
	else:
		var exiting_player := occupant if is_instance_valid(occupant) else p
		is_occupied = false
		occupant = null
		hide_timer = 0.0
		wobble_intensity = 0.0
		if visual_root:
			visual_root.rotation = Vector3.ZERO

		if is_instance_valid(exiting_player):
			exiting_player.exit_hiding_spot()
			exiting_player.velocity = Vector3(randf_range(-2, 2), 6.5, randf_range(-2, 2))

		if forced and is_inside_tree():
			var p_parent = get_parent()
			if p_parent:
				var ft = preload("res://scripts/player/FloatingText.gd")
				ft.spawn(p_parent, global_position + Vector3(0, 2.0, 0), "NAHULOG!", Color(1.0, 0.7, 0.2))

func _find_player(pid: int) -> PlayerController:
	if is_instance_valid(occupant) and occupant.player_id == pid:
		return occupant
	for np in nearby_players:
		if is_instance_valid(np) and np.player_id == pid:
			return np
	if not is_inside_tree():
		return null
	var tree := get_tree()
	if tree and tree.root:
		var players_container = tree.root.get_node_or_null("Main/Players")
		if players_container:
			var p = players_container.get_node_or_null(str(pid))
			if p is PlayerController:
				return p
		for p in tree.get_nodes_in_group("players"):
			if p is PlayerController and p.player_id == pid:
				return p
	return null

func _on_body_entered(body: Node3D) -> void:
	if body is PlayerController and not nearby_players.has(body):
		nearby_players.append(body)

func _on_body_exited(body: Node3D) -> void:
	if body is PlayerController:
		nearby_players.erase(body)

func _build_visuals() -> void:
	if not visual_root:
		return

	if spot_type == SpotType.BLUE_DRUM:
		var drum := MeshInstance3D.new()
		var cyl := CylinderMesh.new()
		cyl.top_radius = 0.55
		cyl.bottom_radius = 0.52
		cyl.height = 1.3
		drum.mesh = cyl
		drum.position = Vector3(0, 0.65, 0)
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.1, 0.35, 0.85) # Iconic Blue Plastic Kalye Drum
		mat.roughness = 0.4
		drum.material_override = mat
		visual_root.add_child(drum)

		# Drum lid rim ring
		var rim := MeshInstance3D.new()
		var t := TorusMesh.new()
		t.inner_radius = 0.52
		t.outer_radius = 0.58
		rim.mesh = t
		rim.position = Vector3(0, 1.3, 0)
		var black_mat := StandardMaterial3D.new()
		black_mat.albedo_color = Color(0.12, 0.12, 0.14)
		rim.material_override = black_mat
		visual_root.add_child(rim)
	else:
		var box := MeshInstance3D.new()
		var b := BoxMesh.new()
		b.size = Vector3(1.1, 1.1, 1.1)
		box.mesh = b
		box.position = Vector3(0, 0.55, 0)
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.68, 0.52, 0.35) # Cardboard Brown
		mat.roughness = 0.8
		box.material_override = mat
		visual_root.add_child(box)
