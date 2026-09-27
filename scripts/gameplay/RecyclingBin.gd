class_name RecyclingBin
extends Area3D

@export var bin_category: TrashItem.BinCategory = TrashItem.BinCategory.RECYCLABLE

@onready var spark_particles: CPUParticles3D = get_node_or_null("SparkParticles")
@onready var bin_label: Label3D = get_node_or_null("Label3D")

var deposit_cooldown: Dictionary = {}

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node3D) -> void:
	if not (body is PlayerController):
		return

	var player: PlayerController = body as PlayerController
	if not player.has_trash():
		return

	# Prevent multiple triggers within short window
	var p_id = player.player_id
	var current_msec = Time.get_ticks_msec()
	if deposit_cooldown.has(p_id) and (current_msec - deposit_cooldown[p_id]) < 1000:
		return
	deposit_cooldown[p_id] = current_msec

	var item_cat = get_category_for_trash(player.held_trash as TrashItem.TrashType)
	var is_correct = (item_cat == bin_category)

	if is_correct:
		_play_success_effects()
		player.deposit_trash(true, bin_category)
	else:
		player.deposit_trash(false, bin_category)

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
	if spark_particles:
		spark_particles.restart()
		spark_particles.emitting = true
