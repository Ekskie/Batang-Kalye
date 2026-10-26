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
@onready var street_flood_water: Node3D = get_node_or_null("StreetFloodWater")

# ==============================================================================
# FLOOD & BARADONG KANAL MECHANICS
# ==============================================================================
var flood_level: float = 0.0 # 0.0 to 100.0%
var is_flooded: bool = false
const CLOG_RATE_PER_SEC: float = 1.8 # fills in ~55s if trash is neglected
const DRAIN_RELIEF_PER_TRASH: float = 25.0 # -25% per trash deposit
const FLOOD_HEIGHT_DRY: float = -8.5
const FLOOD_HEIGHT_WET: float = -4.80
var _flood_water_tween: Tween = null

func _ready() -> void:
	add_to_group("maps")
	add_to_group("kalye_maps")
	if not street_flood_water:
		street_flood_water = get_node_or_null("StreetFloodWater")
	if street_flood_water:
		street_flood_water.position.y = FLOOD_HEIGHT_DRY
		street_flood_water.visible = false
		var wz: Area3D = street_flood_water.get_node_or_null("WaterZone") as Area3D
		if wz:
			wz.monitoring = false
	_hide_helper_nodes(self)
	_setup_map_materials_and_lod(self)
	_build_prop_collisions(self)
	call_deferred("_snap_all_items_and_bins_to_ground")

func update_flood(delta: float, is_playing: bool) -> void:
	if not is_playing:
		return
	if flood_level < 100.0:
		flood_level = minf(100.0, flood_level + CLOG_RATE_PER_SEC * delta)

	if flood_level >= 100.0 and not is_flooded:
		trigger_flood()
	elif flood_level < 80.0 and is_flooded:
		drain_flood()

	if is_inside_tree():
		var hud = get_node_or_null("/root/Main/HUD")
		if hud and hud.has_method("update_flood_meter"):
			hud.update_flood_meter(flood_level, is_flooded)

func reduce_flood(amount: float = DRAIN_RELIEF_PER_TRASH) -> void:
	flood_level = maxf(0.0, flood_level - amount)
	if is_flooded and flood_level < 80.0:
		drain_flood()
	if is_inside_tree():
		var hud = get_node_or_null("/root/Main/HUD")
		if hud and hud.has_method("update_flood_meter"):
			hud.update_flood_meter(flood_level, is_flooded)

func set_flood_state(level: float, flooded: bool) -> void:
	flood_level = level
	if flooded and not is_flooded:
		trigger_flood()
	elif not flooded and is_flooded:
		drain_flood()
	if is_inside_tree():
		var hud = get_node_or_null("/root/Main/HUD")
		if hud and hud.has_method("update_flood_meter"):
			hud.update_flood_meter(flood_level, is_flooded)

func trigger_flood() -> void:
	is_flooded = true
	if not street_flood_water:
		street_flood_water = get_node_or_null("StreetFloodWater")
	if street_flood_water:
		street_flood_water.visible = true
		var wz: Area3D = street_flood_water.get_node_or_null("WaterZone") as Area3D
		if wz:
			wz.monitoring = true
		if is_inside_tree():
			if _flood_water_tween and _flood_water_tween.is_valid():
				_flood_water_tween.kill()
			_flood_water_tween = create_tween()
			_flood_water_tween.tween_property(street_flood_water, "position:y", FLOOD_HEIGHT_WET, 1.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		else:
			street_flood_water.position.y = FLOOD_HEIGHT_WET

	var s_items = find_child("StreetItems", true, false)
	if s_items:
		for item in s_items.get_children():
			if item.has_method("set_flooded"):
				item.set_flooded(true, FLOOD_HEIGHT_WET)
	if is_inside_tree() and get_tree():
		get_tree().call_group("street_items", "set_flooded", true, FLOOD_HEIGHT_WET)

	var t_items = find_child("TrashItems", true, false)
	if t_items:
		for trash in t_items.get_children():
			if trash.has_method("set_flooded"):
				trash.set_flooded(true, FLOOD_HEIGHT_WET)
	if is_inside_tree() and get_tree():
		get_tree().call_group("trash_items", "set_flooded", true, FLOOD_HEIGHT_WET)

	if is_inside_tree():
		var hud = get_node_or_null("/root/Main/HUD")
		if hud and hud.has_method("show_toast_notification"):
			hud.show_toast_notification("⚠️ BUMABAHA NA! BARADO ANG KANAL!\n(Itapon ang basura sa tamang basurahan para humupa ang baha!)", false)

		var am = get_node_or_null("/root/AudioManager")
		if am and am.has_method("play_whistle"):
			am.play_whistle()

func drain_flood() -> void:
	is_flooded = false
	if not street_flood_water:
		street_flood_water = get_node_or_null("StreetFloodWater")
	if street_flood_water:
		var wz: Area3D = street_flood_water.get_node_or_null("WaterZone") as Area3D
		if wz:
			wz.monitoring = false
		if is_inside_tree():
			if _flood_water_tween and _flood_water_tween.is_valid():
				_flood_water_tween.kill()
			_flood_water_tween = create_tween()
			_flood_water_tween.tween_property(street_flood_water, "position:y", FLOOD_HEIGHT_DRY, 1.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
			_flood_water_tween.tween_callback(func():
				if not is_flooded and is_instance_valid(street_flood_water):
					street_flood_water.visible = false
			)
		else:
			street_flood_water.position.y = FLOOD_HEIGHT_DRY
			street_flood_water.visible = false

	var s_items = find_child("StreetItems", true, false)
	if s_items:
		for item in s_items.get_children():
			if item.has_method("set_flooded"):
				item.set_flooded(false, FLOOD_HEIGHT_DRY)
	if is_inside_tree() and get_tree():
		get_tree().call_group("street_items", "set_flooded", false, FLOOD_HEIGHT_DRY)

	var t_items = find_child("TrashItems", true, false)
	if t_items:
		for trash in t_items.get_children():
			if trash.has_method("set_flooded"):
				trash.set_flooded(false, FLOOD_HEIGHT_DRY)
	if is_inside_tree() and get_tree():
		get_tree().call_group("trash_items", "set_flooded", false, FLOOD_HEIGHT_DRY)
		get_tree().call_group("players", "set_in_water", false)

	if is_inside_tree():
		var hud = get_node_or_null("/root/Main/HUD")
		if hud and hud.has_method("show_toast_notification"):
			hud.show_toast_notification("✅ HUMUPA NA ANG BAHA! Malinis na ang kanal!", true)

func _snap_all_items_and_bins_to_ground() -> void:
	if not is_inside_tree():
		return
	var space := get_world_3d().direct_space_state
	if space == null:
		return

	var containers := ["StreetItems", "TrashItems", "SegregationBins"]
	for c_name in containers:
		var container := find_child(c_name, true, false)
		if container:
			for item in container.get_children():
				if not (item is Node3D):
					continue
				var origin_x: float = item.position.x
				var origin_z: float = item.position.z
				var query := PhysicsRayQueryParameters3D.create(
					Vector3(origin_x, 25.0, origin_z),
					Vector3(origin_x, -25.0, origin_z)
				)
				query.collide_with_areas = false
				query.collide_with_bodies = true
				var hit := space.intersect_ray(query)
				if hit:
					var ground_y: float = hit.position.y
					var offset: float = 0.02 if (c_name != "SegregationBins") else 0.0
					item.position.y = ground_y + offset

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
	if mi.mesh == null:
		return
	for s in range(mi.mesh.get_surface_count()):
		var mat = mi.mesh.surface_get_material(s)
		if mat:
			var m_lower: String = String(mat.resource_name).to_lower()
			if "concrete" in m_lower or "court" in m_lower or "ground" in m_lower or "road" in m_lower or "asphalt" in m_lower:
				mi.visibility_range_end = 0.0
				return
	mi.visibility_range_end = 120.0
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
	# Skip purely decorative props, tree foliage, street lamps, and dedicated triggers
	if "tree" in n_lower or "light" in n_lower or "bench" in n_lower or "decal" in n_lower:
		return true
	if "streetitems" in n_lower or "trashitems" in n_lower or "hidingspot" in n_lower or "spawn" in n_lower:
		return true
	if "canal" in n_lower or "recycle" in n_lower or "dog" in n_lower or "base" in n_lower or "flood" in n_lower or "water" in n_lower:
		return true
	if "nurbs" in n_lower or "text" in n_lower or "child" in n_lower or "jump" in n_lower:
		return true

	# Check surface materials: only skip purely decorative foliage / laundry if not structural
	if node is MeshInstance3D and node.mesh != null:
		var has_structural := false
		var has_decorative := false
		var structural_keywords := ["concrete", "wall", "roof", "court", "tindahan", "door", "fence", "bakeshop", "burger", "hall", "metal", "wood", "post", "pole", "yero", "exhaust", "shutter"]
		var decorative_keywords := ["laundry", "plant", "bush", "tree"]
		for s in range(node.mesh.get_surface_count()):
			var mat = node.mesh.surface_get_material(s)
			if mat != null:
				var m_name: String = String(mat.resource_name).to_lower()
				for sk in structural_keywords:
					if sk in m_name:
						has_structural = true
						break
				for dk in decorative_keywords:
					if dk in m_name:
						has_decorative = true
						break
		if has_decorative and not has_structural:
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
				child.create_trimesh_collision()
				for gc in child.get_children():
					if gc is StaticBody3D:
						gc.collision_layer = 1
						gc.collision_mask = 1
						for gch in gc.get_children():
							if gch is CollisionShape3D and gch.shape is ConcavePolygonShape3D:
								gch.shape.backface_collision = true
		_build_prop_collisions(child)

func _has_static_collision(node: Node) -> bool:
	for c in node.get_children():
		if c is StaticBody3D or (c is CSGBox3D and c.use_collision):
			return true
	var p = node.get_parent()
	if p is StaticBody3D or p is CharacterBody3D or p is Area3D:
		return true
	if p is CSGBox3D and p.use_collision:
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

func respawn_all_items() -> void:
	var s_items := find_child("StreetItems", true, false)
	if s_items:
		for item in s_items.get_children():
			if item is StreetItem and item.has_method("respawn"):
				item.respawn()

	var t_items := find_child("TrashItems", true, false)
	if t_items:
		for trash in t_items.get_children():
			if trash is TrashItem and trash.has_method("respawn"):
				trash.respawn()
