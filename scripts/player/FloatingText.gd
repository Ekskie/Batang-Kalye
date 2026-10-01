class_name FloatingText
extends Node3D

@onready var label: Label3D = $Label3D

var lifetime: float = 0.85
var timer: float = 0.0
var rise_speed: float = 2.4

func _ready() -> void:
	scale = Vector3(0.2, 0.2, 0.2)

func setup(text_msg: String, text_color: Color = Color.WHITE) -> void:
	if not label:
		label = get_node_or_null("Label3D")
	if label:
		label.text = text_msg
		label.modulate = text_color

func _process(delta: float) -> void:
	timer += delta
	var progress := timer / lifetime

	# Float upward with deceleration
	position.y += rise_speed * delta * (1.0 - progress * 0.4)

	# Punchy pop scale
	if progress < 0.25:
		var t := progress / 0.25
		scale = Vector3.ONE * lerp(0.2, 1.35, ease(t, 0.2))
	elif progress < 0.45:
		var t := (progress - 0.25) / 0.2
		scale = Vector3.ONE * lerp(1.35, 1.0, ease(t, 0.5))

	# Fade out
	if progress > 0.5:
		var fade := 1.0 - ((progress - 0.5) / 0.5)
		if label:
			label.modulate.a = clamp(fade, 0.0, 1.0)

	if timer >= lifetime:
		queue_free()

static func spawn(parent: Node, spawn_pos: Vector3, msg: String, col: Color = Color.WHITE) -> FloatingText:
	var scene: PackedScene = preload("res://scenes/player/FloatingText.tscn")
	if not scene or not parent:
		return null
	var inst: FloatingText = scene.instantiate() as FloatingText
	parent.add_child(inst)
	inst.global_position = spawn_pos
	inst.setup(msg, col)
	return inst
