class_name TrashItem
extends Node3D

enum TrashType {
	PLASTIC_BOTTLE = 0,
	TIN_CAN = 1,
	BANANA_PEEL = 2,
	CANDY_WRAPPER = 3
}

enum BinCategory {
	RECYCLABLE = 0,     # Blue
	BIODEGRADABLE = 1,  # Green
	NON_BIO = 2         # Yellow
}

@export var trash_type: TrashType = TrashType.PLASTIC_BOTTLE:
	set(value):
		trash_type = value
		if is_inside_tree():
			_update_visuals()

@export var respawn_time: float = 12.0
var is_collected: bool = false
var respawn_timer: float = 0.0

@onready var visual_root: Node3D = $VisualRoot
@onready var bottle_mesh: Node3D = $VisualRoot/BottleMesh
@onready var can_mesh: Node3D = $VisualRoot/CanMesh
@onready var peel_mesh: Node3D = $VisualRoot/PeelMesh
@onready var wrapper_mesh: Node3D = $VisualRoot/WrapperMesh
@onready var highlight_ring: MeshInstance3D = get_node_or_null("HighlightRing")
@onready var label: Label3D = $Label3D
@onready var area: Area3D = $Area3D
@onready var pickup_particles: CPUParticles3D = get_node_or_null("PickupParticles")

var anim_time: float = 0.0
var base_y: float = 0.35
var nearby_players: Array[PlayerController] = []
var is_player_looking: bool = false
var is_animating_pickup: bool = false
var _highlight_mat: StandardMaterial3D = null

func _ready() -> void:
	if visual_root:
		base_y = visual_root.position.y
	_update_visuals()
	if area:
		area.body_entered.connect(_on_body_entered)
		area.body_exited.connect(_on_body_exited)
	# Duplicate the highlight ring material so we can tint it per-instance
	if highlight_ring:
		var src_mat = highlight_ring.get_active_material(0)
		if src_mat is StandardMaterial3D:
			_highlight_mat = src_mat.duplicate() as StandardMaterial3D
			highlight_ring.material_override = _highlight_mat
		else:
			_highlight_mat = StandardMaterial3D.new()
			_highlight_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			_highlight_mat.albedo_color = Color(1.0, 0.85, 0.25, 0.7)
			highlight_ring.material_override = _highlight_mat

func _process(delta: float) -> void:
	if is_collected:
		respawn_timer -= delta
		if respawn_timer <= 0.0:
			respawn()
		return

	if is_animating_pickup:
		return

	# Idle floating and spinning
	anim_time += delta * 2.8
	if visual_root:
		visual_root.position.y = base_y + sin(anim_time) * 0.08
		visual_root.rotate_y(delta * 2.0)

	# Dynamic highlight scaling based on player proximity and looking direction
	if highlight_ring and highlight_ring.visible:
		var pulse: float = 1.0 + sin(anim_time * 3.5) * 0.12
		if is_player_looking:
			pulse *= 1.25
			highlight_ring.scale = Vector3(pulse, 1.0, pulse)
			if _highlight_mat:
				_highlight_mat.albedo_color = Color(1.0, 0.95, 0.4, 0.95)
		else:
			highlight_ring.scale = Vector3(pulse, 1.0, pulse)
			if _highlight_mat:
				_highlight_mat.albedo_color = Color(1.0, 0.85, 0.25, 0.55)

	# Check if nearest local player is aiming toward this item
	_check_player_aim()

func _check_player_aim() -> void:
	is_player_looking = false
	for p in nearby_players:
		if is_instance_valid(p) and p.is_multiplayer_authority():
			var cam = p.get_viewport().get_camera_3d()
			if cam:
				var to_item: Vector3 = (global_position - cam.global_position).normalized()
				var cam_dir: Vector3 = -cam.global_transform.basis.z.normalized()
				if cam_dir.dot(to_item) > 0.65:
					is_player_looking = true
					break

func _update_visuals() -> void:
	if not is_inside_tree():
		return
	if bottle_mesh: bottle_mesh.visible = (trash_type == TrashType.PLASTIC_BOTTLE)
	if can_mesh: can_mesh.visible = (trash_type == TrashType.TIN_CAN)
	if peel_mesh: peel_mesh.visible = (trash_type == TrashType.BANANA_PEEL)
	if wrapper_mesh: wrapper_mesh.visible = (trash_type == TrashType.CANDY_WRAPPER)

	if label:
		label.text = get_item_icon()

func get_item_icon() -> String:
	match trash_type:
		TrashType.PLASTIC_BOTTLE:
			return "[BOTE]"
		TrashType.TIN_CAN:
			return "[LATA]"
		TrashType.BANANA_PEEL:
			return "[SAGING]"
		TrashType.CANDY_WRAPPER:
			return "[KENDI]"
	return "[BASURA]"

func get_item_name() -> String:
	match trash_type:
		TrashType.PLASTIC_BOTTLE:
			return "Bote ng Tubig"
		TrashType.TIN_CAN:
			return "Lata ng Sardinas"
		TrashType.BANANA_PEEL:
			return "Balat ng Saging"
		TrashType.CANDY_WRAPPER:
			return "Balat ng Kendi"
	return "Basura"

func get_bin_category() -> BinCategory:
	match trash_type:
		TrashType.PLASTIC_BOTTLE, TrashType.TIN_CAN:
			return BinCategory.RECYCLABLE
		TrashType.BANANA_PEEL:
			return BinCategory.BIODEGRADABLE
		TrashType.CANDY_WRAPPER:
			return BinCategory.NON_BIO
	return BinCategory.RECYCLABLE

func get_bin_hint() -> String:
	match get_bin_category():
		BinCategory.RECYCLABLE:
			return "[Asul: Recyclable]"
		BinCategory.BIODEGRADABLE:
			return "[Berde: Nabubulok]"
		BinCategory.NON_BIO:
			return "[Dilaw: Di-Nabubulok]"
	return ""

# --- Proximity & Interaction ---
func _on_body_entered(body: Node3D) -> void:
	if is_collected:
		return
	if body is PlayerController:
		var player: PlayerController = body as PlayerController
		if not nearby_players.has(player):
			nearby_players.append(player)

		if player.is_multiplayer_authority():
			if highlight_ring:
				highlight_ring.visible = true
			if label:
				label.text = "%s\n[E]" % get_item_icon()
			player.register_nearby_interactable(self)

func _on_body_exited(body: Node3D) -> void:
	if body is PlayerController:
		var player: PlayerController = body as PlayerController
		nearby_players.erase(player)

		if player.is_multiplayer_authority():
			player.unregister_nearby_interactable(self)

		if nearby_players.is_empty():
			if highlight_ring:
				highlight_ring.visible = false
			if label:
				label.text = get_item_icon()

# Deliberate Interaction (Called when player presses E or taps mobile interact button)
func interact(player: PlayerController) -> bool:
	if is_collected or is_animating_pickup:
		return false
	if not is_instance_valid(player) or player.has_trash():
		return false

	var accepted: bool = player.pickup_trash(self)
	if accepted:
		_play_pickup_animation_and_collect(player)
		return true
	return false

func _play_pickup_animation_and_collect(player: PlayerController) -> void:
	is_animating_pickup = true
	if highlight_ring:
		highlight_ring.visible = false
	if label:
		label.visible = false

	# Play particle burst
	if pickup_particles:
		pickup_particles.restart()
		pickup_particles.emitting = true

	# Play audio
	if Engine.has_singleton("AudioManager"):
		AudioManager.play_pickup()
	elif has_node("/root/AudioManager"):
		get_node("/root/AudioManager").play_pickup()

	# Quick smooth suction / fly toward player tween
	if visual_root:
		var tween := create_tween()
		tween.set_parallel(true)
		var target_pos := to_local(player.global_position + Vector3(0, 0.8, 0))
		tween.tween_property(visual_root, "position", target_pos, 0.16).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tween.tween_property(visual_root, "scale", Vector3(0.1, 0.1, 0.1), 0.16)
		tween.finished.connect(func():
			collect()
		)
	else:
		collect()

func collect() -> void:
	is_collected = true
	is_animating_pickup = false
	respawn_timer = respawn_time
	visible = false
	if visual_root:
		visual_root.position.y = base_y
		visual_root.scale = Vector3.ONE
	if area:
		area.monitoring = false
	for p in nearby_players:
		if is_instance_valid(p) and p.is_multiplayer_authority():
			p.unregister_nearby_interactable(self)
	nearby_players.clear()

func respawn() -> void:
	is_collected = false
	is_animating_pickup = false
	visible = true
	if label:
		label.visible = true
	if area:
		area.monitoring = true
	# Randomize trash type on respawn for variety
	trash_type = (randi() % 4) as TrashType
	_update_visuals()
