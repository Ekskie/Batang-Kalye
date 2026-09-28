class_name RecyclingBin
extends Area3D

@export var bin_category: TrashItem.BinCategory = TrashItem.BinCategory.RECYCLABLE

@onready var spark_particles: CPUParticles3D = get_node_or_null("SparkParticles")
@onready var visual_bin: Node3D = get_node_or_null("VisualBin")
@onready var bin_label: Label3D = get_node_or_null("VisualBin/Label")

var nearby_players: Array[PlayerController] = []
var is_animating: bool = false
var original_bin_pos: Vector3 = Vector3.ZERO

func _ready() -> void:
	if visual_bin:
		original_bin_pos = visual_bin.position
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node3D) -> void:
	if body is PlayerController:
		var player: PlayerController = body as PlayerController
		if not nearby_players.has(player):
			nearby_players.append(player)
		if player.is_multiplayer_authority():
			player.register_nearby_interactable(self)

func _on_body_exited(body: Node3D) -> void:
	if body is PlayerController:
		var player: PlayerController = body as PlayerController
		nearby_players.erase(player)
		if player.is_multiplayer_authority():
			player.unregister_nearby_interactable(self)

# Deliberate Interaction (E or Mobile Interact)
func interact(player: PlayerController) -> bool:
	if not is_instance_valid(player) or not player.has_trash() or is_animating:
		return false

	var item_cat = get_category_for_trash(player.held_trash as TrashItem.TrashType)
	var is_correct = (item_cat == bin_category)

	if is_correct:
		_play_success_effects()
		player.deposit_trash(true, bin_category)
		return true
	else:
		_play_fail_effects()
		player.deposit_trash(false, bin_category)
		return false

func get_category_for_trash(t: TrashItem.TrashType) -> TrashItem.BinCategory:
	match t:
		TrashItem.TrashType.PLASTIC_BOTTLE, TrashItem.TrashType.TIN_CAN:
			return TrashItem.BinCategory.RECYCLABLE
		TrashItem.TrashType.BANANA_PEEL:
			return TrashItem.BinCategory.BIODEGRADABLE
		TrashItem.TrashType.CANDY_WRAPPER:
			return TrashItem.BinCategory.NON_BIO
	return TrashItem.BinCategory.RECYCLABLE

func _play_success_effects() -> void:
	is_animating = true

	# Sound
	if Engine.has_singleton("AudioManager"):
		AudioManager.play_bin_correct()
	elif has_node("/root/AudioManager"):
		get_node("/root/AudioManager").play_bin_correct()

	# Particles
	if spark_particles:
		spark_particles.restart()
		spark_particles.emitting = true

	# Squash and stretch happy bounce
	if visual_bin:
		var tween := create_tween()
		tween.tween_property(visual_bin, "scale", Vector3(1.22, 0.76, 1.22), 0.1).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_property(visual_bin, "scale", Vector3(0.92, 1.18, 0.92), 0.14).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_property(visual_bin, "scale", Vector3(1.0, 1.0, 1.0), 0.12).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
		tween.finished.connect(func(): is_animating = false)
	else:
		is_animating = false

func _play_fail_effects() -> void:
	is_animating = true

	# Sound: Dull thud / buzz
	if Engine.has_singleton("AudioManager"):
		AudioManager.play_bin_wrong()
	elif has_node("/root/AudioManager"):
		get_node("/root/AudioManager").play_bin_wrong()

	# Subtle horizontal rattle/shake
	if visual_bin:
		var tween := create_tween()
		var p := original_bin_pos
		tween.tween_property(visual_bin, "position:x", p.x + 0.08, 0.05)
		tween.tween_property(visual_bin, "position:x", p.x - 0.08, 0.05)
		tween.tween_property(visual_bin, "position:x", p.x + 0.06, 0.04)
		tween.tween_property(visual_bin, "position:x", p.x - 0.06, 0.04)
		tween.tween_property(visual_bin, "position:x", p.x, 0.04)
		tween.finished.connect(func(): is_animating = false)
	else:
		is_animating = false
