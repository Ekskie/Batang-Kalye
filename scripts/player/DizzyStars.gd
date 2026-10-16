class_name DizzyStars
extends Node3D

# DizzyStars.gd
# Comic-style animated orbiting golden stars that appear above stunned / slipping players.

var is_active: bool = false
var orbit_angle: float = 0.0
var star_nodes: Array[Node3D] = []
var star_material: StandardMaterial3D

const STAR_COUNT: int = 3
const ORBIT_RADIUS: float = 0.32
const ORBIT_SPEED: float = 4.8

func _ready() -> void:
	_setup_stars()
	visible = false

func _setup_stars() -> void:
	star_material = StandardMaterial3D.new()
	star_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	star_material.albedo_color = Color(1.0, 0.9, 0.15, 1.0) # Bright golden yellow

	# Create a composite 4-point comic star mesh using two crossed diamond prisms
	var prism_mesh := PrismMesh.new()
	prism_mesh.size = Vector3(0.09, 0.09, 0.02)
	prism_mesh.material = star_material

	for i in range(STAR_COUNT):
		var star_root := Node3D.new()
		star_root.name = "Star_%d" % i

		# Visual 1: vertical diamond
		var p1 := MeshInstance3D.new()
		p1.mesh = prism_mesh
		star_root.add_child(p1)

		# Visual 2: horizontal diamond (rotated 90 deg for 4-pointed star)
		var p2 := MeshInstance3D.new()
		p2.mesh = prism_mesh
		p2.rotation.z = deg_to_rad(90.0)
		star_root.add_child(p2)

		add_child(star_root)
		star_nodes.append(star_root)

func _process(delta: float) -> void:
	if not is_active:
		if visible:
			visible = false
		return

	if not visible:
		visible = true

	orbit_angle += delta * ORBIT_SPEED
	var angle_step: float = (TAU) / float(STAR_COUNT)

	for i in range(star_nodes.size()):
		var star := star_nodes[i]
		if not star:
			continue
		var a: float = orbit_angle + float(i) * angle_step
		var x: float = cos(a) * ORBIT_RADIUS
		var z: float = sin(a) * ORBIT_RADIUS
		var y: float = sin(a * 2.0) * 0.05 # Playful bobbing

		star.position = Vector3(x, y, z)
		# Tilted cartoon rotation
		star.rotation.y = a + PI * 0.5
		star.rotation.z = sin(orbit_angle * 3.0 + float(i)) * 0.35
		star.rotation.x = deg_to_rad(-25.0)

func set_active(active: bool) -> void:
	is_active = active
	visible = active
	if active and orbit_angle == 0.0:
		orbit_angle = randf() * TAU
