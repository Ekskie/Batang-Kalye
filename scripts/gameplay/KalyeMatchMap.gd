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

var _mat_cache: Dictionary = {}

func _ready() -> void:
	add_to_group("maps")
	_hide_helper_nodes(self)
	_setup_map_materials(self)
	_build_prop_collisions(self)

func _get_texture_material(tex_path: String) -> StandardMaterial3D:
	if _mat_cache.has(tex_path):
		return _mat_cache[tex_path]
	var mat := StandardMaterial3D.new()
	var tex = load(tex_path)
	if tex:
		mat.albedo_texture = tex
	mat.roughness = 0.85
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	_mat_cache[tex_path] = mat
	return mat

func _setup_map_materials(node: Node) -> void:
	var tex_map: Dictionary = {
		"cube_044": "res://assets/models/For maps/Batang Kalye_Wall_Blue.png",
		"cube_045": "res://assets/models/For maps/Batang Kalye_Wall_Green.png",
		"cube_046": "res://assets/models/For maps/Batang Kalye_Wall_Yellow.png",
		"cube_047": "res://assets/models/For maps/Batang Kalye_Wall_Orange.png",
		"cube_048": "res://assets/models/For maps/Batang Kalye_Wall_Red.png",
		"cube_049": "res://assets/models/For maps/Batang Kalye_Concrete_Breezeblocks.png",
		"cube_050": "res://assets/models/For maps/Batang Kalye_Wall_Blue.png",
		"cube_051": "res://assets/models/For maps/Batang Kalye_Wall_Yellow.png",
		"cube_052": "res://assets/models/For maps/Batang Kalye_Wall_Green.png",
		"cube_053": "res://assets/models/For maps/Batang Kalye_Wall_Red.png",
		"cube_054": "res://assets/models/For maps/Batang Kalye_Wall_Orange.png",
		"cube_055": "res://assets/models/For maps/Batang Kalye_Wall_Blue.png",
		"plane_013": "res://assets/models/For maps/Batang Kalye_Roof_Blue.png",
		"cylinder_009": "res://assets/models/For maps/Batang Kalye_Roof_Yellow.png",
		"cube_012": "res://assets/models/For maps/Batang Kalye_Door_Blue.png",
		"cube_039": "res://assets/models/For maps/Batang Kalye_Door_Green.png",
		"cube_013": "res://assets/models/For maps/Batang Kalye_Window_Shutter.png",
		"cube_014": "res://assets/models/For maps/Batang Kalye_Window.png",
	}

	for child in node.get_children():
		var n_lower := child.name.to_lower()
		if child is MeshInstance3D and child.mesh != null:
			if tex_map.has(n_lower):
				var mat = _get_texture_material(tex_map[n_lower])
				child.material_override = mat
				for s in range(child.mesh.get_surface_count()):
					child.set_surface_override_material(s, mat)
			for s in range(child.mesh.get_surface_count()):
				var surf_mat = child.get_surface_override_material(s)
				if surf_mat == null:
					surf_mat = child.mesh.surface_get_material(s)
				if surf_mat is BaseMaterial3D:
					surf_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
		_setup_map_materials(child)

func _hide_helper_nodes(node: Node) -> void:
	for child in node.get_children():
		var n_lower := child.name.to_lower()
		if n_lower == "child" or n_lower == "jump":
			if child is VisualInstance3D:
				child.visible = false
		_hide_helper_nodes(child)

func _should_skip_collision(node: Node) -> bool:
	var n_lower := node.name.to_lower()
	# Skip purely decorative props, tree foliage, street lamps, and dedicated triggers
	if "tree" in n_lower or "light" in n_lower or "bench" in n_lower or "decal" in n_lower:
		return true
	if "streetitems" in n_lower or "trashitems" in n_lower or "hidingspot" in n_lower:
		return true
	if "canal" in n_lower or "recycle" in n_lower or "dog" in n_lower or "base" in n_lower:
		return true
	# Skip hanging clothes on clotheslines (Plane to Plane_008)
	if n_lower in ["plane", "plane_001", "plane_002", "plane_003", "plane_004", "plane_005", "plane_006", "plane_007", "plane_008"]:
		return true
	# Skip clotheslines wires, 3D text signs, and Blender scale helpers
	if "nurbs" in n_lower or "text" in n_lower or "child" in n_lower or "jump" in n_lower:
		return true
	return false

func _build_prop_collisions(node: Node) -> void:
	if _should_skip_collision(node):
		return
	for child in node.get_children():
		if _should_skip_collision(child):
			continue
		if child is MeshInstance3D and child.mesh != null:
			if not _has_static_collision(child):
				var c_lower := child.name.to_lower()
				if c_lower in ["plane_010", "plane_014", "plane_015", "plane_016"]:
					_create_fence_box_collision(child)
				elif c_lower in ["cube_041", "plane_013", "cylinder_009", "cylinder_002", "cylinder_006", "cube_008", "cube_056", "plane_009", "plane_011", "plane_012"]:
					# Slant, slope, slide, and roof sections: decomposed into exact 3D convex prisms
					_create_mesh_convex_prisms(child)
				else:
					# Use clean convex collision hulls for solid compact structures
					child.create_convex_collision(true, false)
		_build_prop_collisions(child)

func _create_mesh_convex_prisms(mi: MeshInstance3D) -> void:
	if not mi or not mi.mesh:
		return
	var sb := StaticBody3D.new()
	sb.name = mi.name + "_col"
	var m: Mesh = mi.mesh
	var extrude := Vector3(0.0, -0.35, 0.0)
	var shape_count := 0

	for s in range(m.get_surface_count()):
		var arr = m.surface_get_arrays(s)
		if arr.size() <= Mesh.ARRAY_VERTEX or arr[Mesh.ARRAY_VERTEX] == null:
			continue
		var verts: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
		var indices: PackedInt32Array = arr[Mesh.ARRAY_INDEX] if arr.size() > Mesh.ARRAY_INDEX and arr[Mesh.ARRAY_INDEX] != null else []
		var count = indices.size() if indices.size() > 0 else verts.size()

		for i in range(0, count, 3):
			var v0 = verts[indices[i]] if indices.size() > 0 else verts[i]
			var v1 = verts[indices[i+1]] if indices.size() > 0 else verts[i+1]
			var v2 = verts[indices[i+2]] if indices.size() > 0 else verts[i+2]

			var shape := ConvexPolygonShape3D.new()
			shape.points = PackedVector3Array([
				v0, v1, v2,
				v0 + extrude, v1 + extrude, v2 + extrude
			])
			var cs := CollisionShape3D.new()
			cs.shape = shape
			sb.add_child(cs)
			shape_count += 1

	if shape_count > 0:
		mi.add_child(sb)
	else:
		sb.free()

func _create_fence_box_collision(mi: MeshInstance3D) -> void:
	var aabb: AABB = mi.mesh.get_aabb()
	var sb := StaticBody3D.new()
	sb.name = mi.name + "_col"
	var cs := CollisionShape3D.new()
	cs.name = "CollisionShape3D"
	var box := BoxShape3D.new()
	box.size = Vector3(max(aabb.size.x, 0.3), max(aabb.size.y, 0.3), max(aabb.size.z, 0.3))
	cs.shape = box
	cs.position = aabb.position + aabb.size * 0.5
	sb.add_child(cs)
	mi.add_child(sb)

func _has_static_collision(node: Node) -> bool:
	for c in node.get_children():
		if c is StaticBody3D or (c is CSGBox3D and c.use_collision):
			return true
	var p = node.get_parent()
	if p is StaticBody3D or p is CharacterBody3D or p is Area3D:
		return true
	if p is CSGBox3D and p.use_collision:
		return true
	# Skip generating extra collisions if sibling is a dedicated vault CSG collider
	if p != null:
		for sibling in p.get_children():
			if sibling is CSGBox3D and sibling.use_collision and sibling.name.begins_with("VaultCollider"):
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
