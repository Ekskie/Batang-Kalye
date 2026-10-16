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
	_hide_helper_nodes(self)
	_setup_map_materials_and_lod(self)
	_build_prop_collisions(self)

func _setup_map_materials(node: Node) -> void:
	_setup_map_materials_and_lod(node)

func _setup_map_materials_and_lod(node: Node) -> void:
	for child in node.get_children():
		if child is MeshInstance3D and child.mesh != null:
			for s in range(child.mesh.get_surface_count()):
				var surf_mat = child.get_surface_override_material(s)
				if surf_mat == null:
					surf_mat = child.mesh.surface_get_material(s)
				if surf_mat is BaseMaterial3D:
					surf_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
			_apply_lod_culling(child)
		_setup_map_materials_and_lod(child)

func _apply_lod_culling(mi: MeshInstance3D) -> void:
	var n_lower := mi.name.to_lower().replace(".", "_")
	# Major landmarks, ground floor, and arena perimeter remain unculled (0.0)
	if n_lower in ["cube_002", "cube_015", "arena_road"] or "wall" in n_lower or "floor" in n_lower or "ground" in n_lower or "asphalt" in n_lower or "perimeter" in n_lower:
		mi.visibility_range_end = 0.0
		return

	# Small clutter, fences, laundry, foliage, props: fade out past 55m
	if "fence" in n_lower or "plane" in n_lower or "tree" in n_lower or "bench" in n_lower or "light" in n_lower or "trash" in n_lower or "drum" in n_lower or "nurbs" in n_lower:
		mi.visibility_range_end = 55.0
		mi.visibility_range_end_margin = 8.0
		mi.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF
	else:
		# Medium residential houses, structures, and roofs: fade out past 95m
		mi.visibility_range_end = 95.0
		mi.visibility_range_end_margin = 12.0
		mi.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF

func _hide_helper_nodes(node: Node) -> void:
	for child in node.get_children():
		var n_lower := child.name.to_lower()
		if n_lower == "child" or n_lower == "jump":
			if child is VisualInstance3D:
				child.visible = false
		_hide_helper_nodes(child)

func _should_skip_collision(node: Node) -> bool:
	var n_lower := node.name.to_lower()
	var n_clean := n_lower.replace(".", "_")
	# Skip purely decorative props, tree foliage, street lamps, and dedicated triggers
	if "tree" in n_lower or "light" in n_lower or "bench" in n_lower or "decal" in n_lower:
		return true
	if "streetitems" in n_lower or "trashitems" in n_lower or "hidingspot" in n_lower:
		return true
	if "canal" in n_lower or "recycle" in n_lower or "dog" in n_lower or "base" in n_lower:
		return true
	# Skip hanging clothes on clotheslines (Plane to Plane_008)
	if n_clean in ["plane", "plane_001", "plane_002", "plane_003", "plane_004", "plane_005", "plane_006", "plane_007", "plane_008"]:
		return true
	if node is MeshInstance3D and node.mesh != null:
		for s in range(node.mesh.get_surface_count()):
			var mat = node.mesh.surface_get_material(s)
			if mat != null and "laundry" in mat.resource_name.to_lower():
				return true
	# Skip clotheslines wires, 3D text signs, and Blender scale helpers
	if "nurbs" in n_lower or "text" in n_lower or "child" in n_lower or "jump" in n_lower:
		return true
	return false

func _build_prop_collisions(node: Node) -> void:
	if _should_skip_collision(node):
		return
	if node is StaticBody3D or node is CollisionShape3D:
		return
	for child in node.get_children():
		if child is StaticBody3D or child is CollisionShape3D:
			continue
		if _should_skip_collision(child):
			continue
		if child is MeshInstance3D and child.mesh != null:
			if not _has_static_collision(child):
				var c_clean := child.name.to_lower().replace(".", "_")
				if c_clean in ["plane_010", "plane_014", "plane_015", "plane_016"]:
					_create_fence_box_collision(child)
				elif c_clean in [
					"cube_041", "plane_013", "cylinder_009", "cylinder_002", "cylinder_006",
					"cube_008", "cube_056", "plane_009", "plane_011", "plane_012",
					"cube_002", "cube_015"
				]:
					# Slants, roofs, slides, and interactive buildings (Tindahan, Brgy Hall):
					# Decompose into solid convex prisms so slopes, porches, and counters are traversable
					_create_mesh_convex_prisms(child)
				else:
					# Use clean convex collision hulls for solid compact structures and houses
					child.create_convex_collision(true, false)
					for gc in child.get_children():
						if gc is StaticBody3D:
							gc.collision_layer = 1
							gc.collision_mask = 1
		_build_prop_collisions(child)

func _create_mesh_convex_prisms(mi: MeshInstance3D) -> void:
	if not mi or not mi.mesh:
		return
	var sb := StaticBody3D.new()
	sb.name = mi.name + "_col"
	sb.collision_layer = 1
	sb.collision_mask = 1
	var m: Mesh = mi.mesh
	var shape_count := 0

	for s in range(m.get_surface_count()):
		var arr = m.surface_get_arrays(s)
		if arr.size() <= Mesh.ARRAY_VERTEX or arr[Mesh.ARRAY_VERTEX] == null:
			continue
		var verts: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
		var indices: PackedInt32Array = arr[Mesh.ARRAY_INDEX] if arr.size() > Mesh.ARRAY_INDEX and arr[Mesh.ARRAY_INDEX] != null else []
		var count = indices.size() if indices.size() > 0 else verts.size()

		for i in range(0, count, 3):
			var v0: Vector3 = verts[indices[i]] if indices.size() > 0 else verts[i]
			var v1: Vector3 = verts[indices[i+1]] if indices.size() > 0 else verts[i+1]
			var v2: Vector3 = verts[indices[i+2]] if indices.size() > 0 else verts[i+2]

			var edge1: Vector3 = v1 - v0
			var edge2: Vector3 = v2 - v0
			var normal: Vector3 = edge1.cross(edge2)
			if normal.length_squared() < 0.00001:
				continue
			normal = normal.normalized()

			# For roofs, slopes, and floors (near horizontal), extrude downward.
			# For vertical or steep walls, extrude inward along the negative normal.
			var extrude: Vector3
			if absf(normal.y) > 0.35:
				extrude = Vector3(0.0, -0.35, 0.0)
			else:
				extrude = -normal * 0.25

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
	sb.collision_layer = 1
	sb.collision_mask = 1
	var cs := CollisionShape3D.new()
	cs.name = "CollisionShape3D"
	var box := BoxShape3D.new()
	box.size = Vector3(max(aabb.size.x, 0.35), max(aabb.size.y, 0.35), max(aabb.size.z, 0.35))
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
		if p.has_node("VaultCollider"):
			return true
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
