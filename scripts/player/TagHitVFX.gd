class_name TagHitVFX
extends Node3D

@onready var label: Label3D = $Label3D
@onready var spark_mesh: MeshInstance3D = $SparkMesh

var lifetime: float = 0.55
var timer: float = 0.0

func _ready() -> void:
	scale = Vector3(0.3, 0.3, 0.3)
	if spark_mesh and spark_mesh.material_override:
		spark_mesh.material_override = spark_mesh.material_override.duplicate()

func _process(delta: float) -> void:
	timer += delta
	var progress: float = timer / lifetime

	# Scale up rapidly then fade
	var s: float = lerp(0.5, 2.2, ease(progress, 0.4))
	scale = Vector3(s, s, s)
	position.y += delta * 1.5

	if label:
		label.modulate.a = 1.0 - progress
	if spark_mesh and spark_mesh.material_override:
		spark_mesh.material_override.albedo_color.a = 1.0 - progress

	if timer >= lifetime:
		queue_free()
