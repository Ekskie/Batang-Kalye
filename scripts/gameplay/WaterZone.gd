class_name WaterZone
extends Area3D

@export var water_depth: float = 0.45

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node3D) -> void:
	if body is PlayerController and body.has_method("set_in_water"):
		body.set_in_water(true)

func _on_body_exited(body: Node3D) -> void:
	if body is PlayerController and body.has_method("set_in_water"):
		body.set_in_water(false)
