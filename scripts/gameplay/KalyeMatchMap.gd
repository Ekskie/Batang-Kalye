class_name KalyeMatchMap
extends Node3D

## KalyeMatchMap
## Vast suburban & retro-urban gameplay arena for Batang Kalye (120m x 120m).
## Features distinct residential subdivision, urban alleys, industrial construction yard,
## and barangay market/canal zones, packed with 19 hiding spots, parkour vaultable barriers,
## sightline breaks, street items, recycling station, dog chaser, and 24 spaced spawn markers.

@export var map_name: String = "Suburban Kalye"
@export var arena_size: Vector2 = Vector2(120.0, 120.0)

@onready var spawn_points_container: Node3D = get_node_or_null("SpawnPoints")

func _ready() -> void:
	add_to_group("maps")
	_build_prop_collisions(self)

func _build_prop_collisions(node: Node) -> void:
	for child in node.get_children():
		if child is MeshInstance3D and child.mesh != null:
			if not _has_static_collision(child):
				child.create_trimesh_collision()
		_build_prop_collisions(child)

func _has_static_collision(node: Node) -> bool:
	for c in node.get_children():
		if c is StaticBody3D:
			return true
	if node.get_parent() is StaticBody3D:
		return true
	return false

func get_spawn_markers() -> Array[Marker3D]:
	var markers: Array[Marker3D] = []
	var sp_node: Node = spawn_points_container if spawn_points_container else get_node_or_null("SpawnPoints")
	if sp_node:
		for c in sp_node.get_children():
			if c is Marker3D:
				markers.append(c)
	return markers
