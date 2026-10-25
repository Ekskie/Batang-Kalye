class_name FloatingText
extends Node3D

@onready var label: Label3D = $Label3D

var lifetime: float = 0.85
var timer: float = 0.0
var rise_speed: float = 2.4
var tilt_angle: float = 0.0

func _ready() -> void:
	scale = Vector3(0.15, 0.15, 0.15)
	tilt_angle = randf_range(-7.0, 7.0)
	rotation_degrees.z = tilt_angle

func setup(text_msg: String, text_color: Color = Color.WHITE) -> void:
	if not label:
		label = get_node_or_null("Label3D")
	if label:
		label.text = text_msg
		label.modulate = text_color
		if label.font == null:
			var default_font = load("res://assets/fonts/LilitaOne-Regular.ttf")
			if default_font:
				label.font = default_font

func _process(delta: float) -> void:
	timer += delta
	var progress := timer / lifetime

	# Float upward with deceleration
	position.y += rise_speed * delta * (1.0 - progress * 0.4)

	# Comic punchy spring pop scale
	if progress < 0.22:
		var t := progress / 0.22
		scale = Vector3.ONE * lerp(0.15, 1.48, ease(t, 0.25))
	elif progress < 0.42:
		var t := (progress - 0.22) / 0.20
		scale = Vector3.ONE * lerp(1.48, 1.05, ease(t, 0.5))
	elif progress < 0.60:
		var t := (progress - 0.42) / 0.18
		scale = Vector3.ONE * lerp(1.05, 1.0, ease(t, 0.5))

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
