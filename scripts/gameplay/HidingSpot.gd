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

		# Max time reached -> Eject!
		if hide_timer >= max_hide_duration:
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

func interact(player: PlayerController) -> void:
	if is_occupied:
		if player == occupant:
			eject_occupant(false)
		return

	if player.current_role != PlayerController.Role.RUNNER or player.is_eliminated:
		return

	# Enter hiding spot
	is_occupied = true
	occupant = player
	hide_timer = 0.0
	wobble_intensity = 0.0

	if player.has_method("enter_hiding_spot"):
		player.call("enter_hiding_spot", self)

	if Engine.has_singleton("AudioManager"):
		AudioManager.play_drum_hide()
	elif has_node("/root/AudioManager"):
		get_node("/root/AudioManager").play_drum_hide()

	var ft = preload("res://scripts/player/FloatingText.gd")
	ft.spawn(get_parent(), global_position + Vector3(0, 1.8, 0), "NAGTATAGO...", Color(0.3, 0.8, 1.0))

	if multiplayer.has_multiplayer_peer() and multiplayer.is_server():
		rpc("sync_hide_state", player.player_id, true)

func eject_occupant(forced: bool = false) -> void:
	if not is_occupied or not is_instance_valid(occupant):
		is_occupied = false
		occupant = null
		return

	var p := occupant
	is_occupied = false
	occupant = null
	hide_timer = 0.0

	if p.has_method("exit_hiding_spot"):
		p.call("exit_hiding_spot")

	# Hop out
	p.velocity = Vector3(randf_range(-2, 2), 6.5, randf_range(-2, 2))
	if forced:
		var ft = preload("res://scripts/player/FloatingText.gd")
		ft.spawn(get_parent(), global_position + Vector3(0, 2.0, 0), "NAHULOG!", Color(1.0, 0.7, 0.2))

	if multiplayer.has_multiplayer_peer() and multiplayer.is_server():
		rpc("sync_hide_state", p.player_id, false)

func on_taya_slap(taya: PlayerController) -> void:
	# Taya slapped this drum!
	if is_occupied and is_instance_valid(occupant):
		# SUCCESSFUL TAG!
		var caught_player := occupant
		eject_occupant(false)

		var ft = preload("res://scripts/player/FloatingText.gd")
		ft.spawn(get_parent(), global_position + Vector3(0, 2.2, 0), "HULI SA DRUM!", Color(1.0, 0.2, 0.2))

		if taya.has_method("perform_tag_on"):
			taya.call("perform_tag_on", caught_player)
	else:
		# EMPTY SLAP! Stun Taya with hollow clang!
		if Engine.has_singleton("AudioManager"):
			AudioManager.play_drum_clang()
		elif has_node("/root/AudioManager"):
			get_node("/root/AudioManager").play_drum_clang()

		if visual_root:
			var tw := create_tween()
			tw.tween_property(visual_root, "scale", Vector3(1.15, 0.85, 1.15), 0.08)
			tw.tween_property(visual_root, "scale", Vector3.ONE, 0.12)

		taya.call("apply_slipper_stun", 1.0, "Walang Laman!")
		var ft = preload("res://scripts/player/FloatingText.gd")
		ft.spawn(get_parent(), global_position + Vector3(0, 2.0, 0), "KLANG! WALANG TAO!", Color(1.0, 0.85, 0.2))

@rpc("call_local", "reliable")
func sync_hide_state(_pid: int, occupied: bool) -> void:
	is_occupied = occupied
	if not occupied:
		occupant = null

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
