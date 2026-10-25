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

var _swaying_nodes: Array[Node3D] = []
var _sway_time: float = 0.0

func _ready() -> void:
	add_to_group("maps")
	_hide_helper_nodes(self)
	_build_filipino_neighborhood_layers()
	_setup_map_materials_and_lod(self)
	_build_prop_collisions(self)

func _process(delta: float) -> void:
	if _swaying_nodes.is_empty():
		return
	_sway_time += delta
	for i in range(_swaying_nodes.size()):
		var n: Node3D = _swaying_nodes[i]
		if is_instance_valid(n):
			n.rotation.z = sin(_sway_time * 2.2 + float(i) * 0.7) * 0.06

func _is_clear_of_spawns(pos: Vector3, min_dist: float = 3.6) -> bool:
	var sp_node := get_node_or_null("SpawnPoints")
	if sp_node:
		for c in sp_node.get_children():
			if c is Node3D and Vector2(c.position.x - pos.x, c.position.z - pos.z).length() < min_dist:
				return false
	for group_name in ["HidingSpots", "StreetItems", "TrashItems"]:
		var g_node := get_node_or_null(group_name)
		if g_node:
			for c in g_node.get_children():
				if c is Node3D and Vector2(c.position.x - pos.x, c.position.z - pos.z).length() < 2.4:
					return false
	return true

func _create_solid_box_prop(parent: Node3D, prop_name: String, pos: Vector3, box_size: Vector3, col: Color, rot_y_deg: float = 0.0, roughness_val: float = 0.8) -> StaticBody3D:
	var sb := StaticBody3D.new()
	sb.name = prop_name
	sb.position = pos
	sb.rotation_degrees.y = rot_y_deg
	sb.collision_layer = 1
	sb.collision_mask = 1

	var cs := CollisionShape3D.new()
	var bshape := BoxShape3D.new()
	bshape.size = box_size
	cs.shape = bshape
	sb.add_child(cs)

	var mi := MeshInstance3D.new()
	mi.name = prop_name + "_mesh"
	var bmesh := BoxMesh.new()
	bmesh.size = box_size
	var mat := StandardMaterial3D.new()
	mat.albedo_color = col
	mat.roughness = roughness_val
	bmesh.material = mat
	mi.mesh = bmesh
	sb.add_child(mi)

	parent.add_child(sb)
	return sb

func _build_filipino_neighborhood_layers() -> void:
	if has_node("BarangayNeighborhoodLayer"):
		return
	var root_layer := Node3D.new()
	root_layer.name = "BarangayNeighborhoodLayer"
	add_child(root_layer)

	# 1. Parkour & Vaulting Layer (Low hollow-block walls, wooden benches, softdrink crates)
	var parkour_node := Node3D.new()
	parkour_node.name = "ParkourObstacles"
	root_layer.add_child(parkour_node)

	var vault_defs := [
		{"name": "VaultHollowWallNorth", "pos": Vector3(-15.0, 0.40, -18.0), "size": Vector3(3.4, 0.80, 0.36), "col": Color(0.62, 0.60, 0.57), "rot": 0.0},
		{"name": "VaultHollowWallEast", "pos": Vector3(18.0, 0.40, -6.0), "size": Vector3(0.36, 0.80, 3.4), "col": Color(0.62, 0.60, 0.57), "rot": 0.0},
		{"name": "VaultBenchPlazaWest", "pos": Vector3(-8.0, 0.38, 3.0), "size": Vector3(2.8, 0.76, 0.42), "col": Color(0.55, 0.36, 0.20), "rot": 0.0},
		{"name": "VaultBenchPlazaEast", "pos": Vector3(6.0, 0.38, -4.0), "size": Vector3(2.8, 0.76, 0.42), "col": Color(0.55, 0.36, 0.20), "rot": 90.0},
		{"name": "VaultCrateRowSouth", "pos": Vector3(-10.0, 0.42, 26.0), "size": Vector3(2.4, 0.84, 0.42), "col": Color(0.78, 0.18, 0.15), "rot": 0.0},
		{"name": "VaultFenceAlley", "pos": Vector3(24.0, 0.42, -19.0), "size": Vector3(3.2, 0.84, 0.34), "col": Color(0.32, 0.45, 0.38), "rot": 0.0}
	]
	for vd in vault_defs:
		if _is_clear_of_spawns(vd["pos"]):
			_create_solid_box_prop(parkour_node, vd["name"], vd["pos"], vd["size"], vd["col"], vd["rot"])

	# 2. Mid-Level Traversal Platforms (Stepped crates & porch ledges with multiple exits)
	var mid_layer := Node3D.new()
	mid_layer.name = "MidLevelPlatforms"
	root_layer.add_child(mid_layer)

	if _is_clear_of_spawns(Vector3(-2.0, 0.0, -14.0), 3.0):
		_create_solid_box_prop(mid_layer, "WoodenCrateStepLow", Vector3(-3.6, 0.35, -14.0), Vector3(1.2, 0.70, 1.2), Color(0.62, 0.42, 0.22))
		_create_solid_box_prop(mid_layer, "WoodenCrateStepMid", Vector3(-2.2, 0.70, -14.0), Vector3(1.4, 1.40, 1.4), Color(0.54, 0.36, 0.18))
		_create_solid_box_prop(mid_layer, "ConcretePorchLedge", Vector3(0.4, 1.05, -14.0), Vector3(3.6, 2.10, 2.2), Color(0.72, 0.68, 0.62))
		_create_solid_box_prop(mid_layer, "WoodenCrateStepEast", Vector3(2.8, 0.50, -14.0), Vector3(1.2, 1.00, 1.2), Color(0.60, 0.40, 0.22))

	# 3. Parked Tricycle TODA & Jeepney Waiting Shed
	var vehicles_node := Node3D.new()
	vehicles_node.name = "FilipinoVehiclesAndShed"
	root_layer.add_child(vehicles_node)

	if _is_clear_of_spawns(Vector3(-24.0, 0.0, 2.0), 3.5):
		var trike := _create_solid_box_prop(vehicles_node, "TricycleTodaBody", Vector3(-24.0, 0.65, 2.0), Vector3(1.6, 1.3, 2.3), Color(0.82, 0.16, 0.14), 15.0, 0.45)
		var trike_roof := MeshInstance3D.new()
		trike_roof.name = "TricycleRoofYero_mesh"
		var rmesh := BoxMesh.new()
		rmesh.size = Vector3(1.75, 0.12, 2.4)
		var rmat := StandardMaterial3D.new()
		rmat.albedo_color = Color(0.95, 0.80, 0.15)
		rmat.roughness = 0.5
		rmesh.material = rmat
		trike_roof.mesh = rmesh
		trike_roof.position = Vector3(0.0, 0.72, 0.0)
		trike.add_child(trike_roof)

		var TodaLbl := Label3D.new()
		TodaLbl.name = "TodaTextLabel"
		TodaLbl.text = "KALYE TODA #08\nBYAHENG KANTO"
		TodaLbl.font_size = 18
		TodaLbl.outline_size = 5
		TodaLbl.modulate = Color(1.0, 0.92, 0.25)
		TodaLbl.position = Vector3(0.0, 1.15, 0.0)
		trike.add_child(TodaLbl)

	if _is_clear_of_spawns(Vector3(8.0, 0.0, -34.0), 3.8):
		var jeep := _create_solid_box_prop(vehicles_node, "ParkedJeepneyBody", Vector3(8.0, 0.95, -34.0), Vector3(2.2, 1.9, 5.2), Color(0.92, 0.72, 0.12), -10.0, 0.4)
		var jeep_roof := MeshInstance3D.new()
		jeep_roof.name = "JeepneyRoofMetal_mesh"
		var jmesh := BoxMesh.new()
		jmesh.size = Vector3(2.3, 0.15, 5.0)
		var jmat := StandardMaterial3D.new()
		jmat.albedo_color = Color(0.85, 0.20, 0.18)
		jmat.metallic = 0.35
		jmesh.material = jmat
		jeep_roof.mesh = jmesh
		jeep_roof.position = Vector3(0.0, 1.02, 0.0)
		jeep.add_child(jeep_roof)

		var jeep_sign := Label3D.new()
		jeep_sign.name = "JeepneySignText"
		jeep_sign.text = "BAYAN • PALENGKE • KANTO\nPATOK EXPRESS"
		jeep_sign.font_size = 20
		jeep_sign.outline_size = 6
		jeep_sign.modulate = Color(1.0, 0.96, 0.80)
		jeep_sign.position = Vector3(0.0, 1.45, 0.0)
		jeep.add_child(jeep_sign)

	# 4. Authentic Barangay Signs, Sari-Sari Store Tarpaulin, Water Jugs & Warm Streetlights
	var signs_node := Node3D.new()
	signs_node.name = "BarangaySignageAndClutter"
	root_layer.add_child(signs_node)

	var sign_configs := [
		{"pos": Vector3(0.0, 3.4, 18.5), "text": "TINDAHAN NI ALING NENA\nPALOAD • YELO • RC • ICE CANDY\n[SAFE BASE REFUGE]", "col": Color(1.0, 0.92, 0.35), "size": 22},
		{"pos": Vector3(-18.0, 3.1, -9.0), "text": "BARANGAY STA. CRUZ — PUROK 3\n\"Bayanihan sa Kalye, Ligtas na Tayaan\"", "col": Color(0.45, 0.95, 1.0), "size": 19},
		{"pos": Vector3(24.0, 2.6, 10.5), "text": "BARANGAY ECO-STATION\nI-Segregate ang Basura para sa Powerup!", "col": Color(0.4, 1.0, 0.55), "size": 18},
		{"pos": Vector3(0.0, 2.4, 28.5), "text": "TAWIRAN NG ESTERO\nMag-ingat sa Basang Tulay!", "col": Color(0.55, 0.85, 1.0), "size": 18}
	]
	for sc in sign_configs:
		var lbl := Label3D.new()
		lbl.name = "BrgySignText"
		lbl.position = sc["pos"]
		lbl.text = sc["text"]
		lbl.font_size = sc["size"]
		lbl.outline_size = 6
		lbl.modulate = sc["col"]
		lbl.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
		signs_node.add_child(lbl)

	# Warm golden-hour streetlamps near key landmarks (Tindahan Safe Base, Plaza, Canal Bridge)
	for lamp_pos in [Vector3(0.0, 4.2, 18.0), Vector3(-12.0, 4.5, -8.0), Vector3(16.0, 4.5, -10.0), Vector3(0.0, 4.0, 30.0)]:
		var lamp := OmniLight3D.new()
		lamp.name = "KalyeWarmStreetLight"
		lamp.position = lamp_pos
		lamp.light_color = Color(1.0, 0.82, 0.52)
		lamp.light_energy = 1.15
		lamp.omni_range = 16.0
		signs_node.add_child(lamp)

	# 5. Overhead Fiesta Banderitas (swaying gently in the afternoon breeze)
	var banderitas_root := Node3D.new()
	banderitas_root.name = "FiestaBanderitas"
	root_layer.add_child(banderitas_root)
	var flag_colors := [
		Color(0.95, 0.22, 0.20),
		Color(0.98, 0.82, 0.15),
		Color(0.20, 0.65, 0.95),
		Color(0.25, 0.85, 0.40)
	]
	for span_idx in range(3):
		var z_coord: float = -12.0 + float(span_idx) * 12.0
		var strand := Node3D.new()
		strand.name = "BanderitasStrand_%d" % span_idx
		strand.position = Vector3(0.0, 4.4, z_coord)
		banderitas_root.add_child(strand)
		_swaying_nodes.append(strand)
		for f_idx in range(9):
			var flag_mi := MeshInstance3D.new()
			flag_mi.name = "FlagPlane_%d" % f_idx
			var pmesh := BoxMesh.new()
			pmesh.size = Vector3(0.32, 0.42, 0.04)
			var fmat := StandardMaterial3D.new()
			fmat.albedo_color = flag_colors[(span_idx + f_idx) % flag_colors.size()]
			fmat.roughness = 0.6
			pmesh.material = fmat
			flag_mi.mesh = pmesh
			var x_off: float = -8.0 + float(f_idx) * 2.0
			var sag_y: float = -0.35 * sin((float(f_idx) / 8.0) * PI)
			flag_mi.position = Vector3(x_off, sag_y, 0.0)
			strand.add_child(flag_mi)

	# 6. Authentic Barangay Ground Markings & Sidewalk Infrastructure
	_build_ground_markings(root_layer)

func _build_ground_markings(root: Node3D) -> void:
	var markings_node := Node3D.new()
	markings_node.name = "BarangayGroundMarkings"
	root.add_child(markings_node)

	var yellow_mat := StandardMaterial3D.new()
	yellow_mat.albedo_color = Color(0.96, 0.78, 0.16)
	yellow_mat.roughness = 0.85

	var white_mat := StandardMaterial3D.new()
	white_mat.albedo_color = Color(0.92, 0.92, 0.92)
	white_mat.roughness = 0.85

	var curb_mat := preload("res://assets/materials/mat_sidewalk.tres")

	var drain_mat := StandardMaterial3D.new()
	drain_mat.albedo_color = Color(0.20, 0.22, 0.25)
	drain_mat.metallic = 0.85
	drain_mat.roughness = 0.35

	var drain_slot_mat := StandardMaterial3D.new()
	drain_slot_mat.albedo_color = Color(0.06, 0.06, 0.07)
	drain_slot_mat.roughness = 0.95

	# 1. Main East-West Street Yellow Centerline Dashes (Z = -25.0, from X = -42 to 42)
	var ew_mesh := BoxMesh.new()
	ew_mesh.size = Vector3(2.8, 0.012, 0.22)
	ew_mesh.material = yellow_mat
	for x_val in range(-42, 43, 5):
		var fx := float(x_val)
		if (fx >= -26.0 and fx <= -18.0) or (fx >= -3.0 and fx <= 3.0) or (fx >= 4.0 and fx <= 8.0) or (fx >= 18.0 and fx <= 22.0):
			continue
		var dash := MeshInstance3D.new()
		dash.name = "YellowDashEW_%d" % x_val
		dash.mesh = ew_mesh
		dash.position = Vector3(fx, 0.012, -25.0)
		markings_node.add_child(dash)

	# 2. Lower East-West Street Yellow Centerline Dashes (Z = 22.0, from X = -36 to 36)
	for x_val in range(-36, 37, 5):
		var fx := float(x_val)
		if (fx >= -25.0 and fx <= -19.0) or (fx >= -3.0 and fx <= 3.0) or (fx >= 12.0 and fx <= 16.0):
			continue
		var dash := MeshInstance3D.new()
		dash.name = "YellowDashLowerEW_%d" % x_val
		dash.mesh = ew_mesh
		dash.position = Vector3(fx, 0.012, 22.0)
		markings_node.add_child(dash)

	# 3. North-South West Avenue Yellow Centerline Dashes (X = -22.0, from Z = -42 to 28)
	var ns_mesh := BoxMesh.new()
	ns_mesh.size = Vector3(0.22, 0.012, 2.8)
	ns_mesh.material = yellow_mat
	for z_val in range(-42, 29, 5):
		var fz := float(z_val)
		if (fz >= -28.0 and fz <= -21.0) or (fz >= -3.0 and fz <= 3.0) or (fz >= 19.0 and fz <= 25.0):
			continue
		var dash := MeshInstance3D.new()
		dash.name = "YellowDashNS_%d" % z_val
		dash.mesh = ns_mesh
		dash.position = Vector3(-22.0, 0.012, fz)
		markings_node.add_child(dash)

	# 4. Pedestrian Zebra Crosswalks (White parallel stripes)
	var crosswalk_defs := [
		{"name": "CrosswalkWestAveMain", "base": Vector3(-22.0, 0.014, -20.5), "axis": "x", "stripe_size": Vector3(0.48, 0.012, 3.2), "count": 6, "spacing": 0.85},
		{"name": "CrosswalkTindahan", "base": Vector3(0.0, 0.014, 13.5), "axis": "x", "stripe_size": Vector3(0.48, 0.012, 3.2), "count": 6, "spacing": 0.85},
		{"name": "CrosswalkEsteroBridge", "base": Vector3(0.0, 0.014, 26.5), "axis": "x", "stripe_size": Vector3(0.48, 0.012, 3.2), "count": 6, "spacing": 0.85},
		{"name": "CrosswalkEastMain", "base": Vector3(6.0, 0.014, -25.0), "axis": "z", "stripe_size": Vector3(3.2, 0.012, 0.48), "count": 6, "spacing": 0.85}
	]
	for cw in crosswalk_defs:
		var c_node := Node3D.new()
		c_node.name = cw["name"]
		c_node.position = cw["base"]
		markings_node.add_child(c_node)
		var c_mesh := BoxMesh.new()
		c_mesh.size = cw["stripe_size"]
		c_mesh.material = white_mat
		var half_count: float = float(cw["count"] - 1) * 0.5
		for s_idx in range(cw["count"]):
			var offset: float = (float(s_idx) - half_count) * float(cw["spacing"])
			var stripe := MeshInstance3D.new()
			stripe.name = "Stripe_%d" % s_idx
			stripe.mesh = c_mesh
			if cw["axis"] == "x":
				stripe.position = Vector3(offset, 0.0, 0.0)
			else:
				stripe.position = Vector3(0.0, 0.0, offset)
			c_node.add_child(stripe)

	# 5. Sidewalk Concrete Curbs (Kanto Borders lining street margins)
	var curb_defs := [
		{"pos": Vector3(-35.0, 0.025, -28.2), "size": Vector3(14.0, 0.05, 0.22)},
		{"pos": Vector3(-7.0, 0.025, -28.2), "size": Vector3(20.0, 0.05, 0.22)},
		{"pos": Vector3(22.0, 0.025, -28.2), "size": Vector3(24.0, 0.05, 0.22)},
		{"pos": Vector3(-35.0, 0.025, -21.8), "size": Vector3(14.0, 0.05, 0.22)},
		{"pos": Vector3(-7.0, 0.025, -21.8), "size": Vector3(20.0, 0.05, 0.22)},
		{"pos": Vector3(22.0, 0.025, -21.8), "size": Vector3(24.0, 0.05, 0.22)},
		{"pos": Vector3(-25.2, 0.025, -36.0), "size": Vector3(0.22, 0.05, 14.0)},
		{"pos": Vector3(-25.2, 0.025, 0.0), "size": Vector3(0.22, 0.05, 26.0)},
		{"pos": Vector3(-18.8, 0.025, -36.0), "size": Vector3(0.22, 0.05, 14.0)},
		{"pos": Vector3(-18.8, 0.025, 0.0), "size": Vector3(0.22, 0.05, 26.0)}
	]
	for idx in range(curb_defs.size()):
		var cd = curb_defs[idx]
		var c_mi := MeshInstance3D.new()
		c_mi.name = "CurbBorder_%d" % idx
		var cmesh := BoxMesh.new()
		cmesh.size = cd["size"]
		cmesh.material = curb_mat
		c_mi.mesh = cmesh
		c_mi.position = cd["pos"]
		markings_node.add_child(c_mi)

	# 6. Metallic Storm Drain Grates (Street Gutters)
	var drain_positions := [
		Vector3(-19.2, 0.015, -24.6),
		Vector3(-24.8, 0.015, -24.6),
		Vector3(-19.2, 0.015, 21.6),
		Vector3(-24.8, 0.015, 21.6),
		Vector3(-3.4, 0.015, 25.2),
		Vector3(3.4, 0.015, 25.2)
	]
	var grate_base_mesh := BoxMesh.new()
	grate_base_mesh.size = Vector3(0.72, 0.016, 1.05)
	grate_base_mesh.material = drain_mat

	var grate_slot_mesh := BoxMesh.new()
	grate_slot_mesh.size = Vector3(0.56, 0.018, 0.09)
	grate_slot_mesh.material = drain_slot_mat

	for d_idx in range(drain_positions.size()):
		var d_pos: Vector3 = drain_positions[d_idx]
		var d_root := Node3D.new()
		d_root.name = "StormDrainGrate_%d" % d_idx
		d_root.position = d_pos
		markings_node.add_child(d_root)

		var base_mi := MeshInstance3D.new()
		base_mi.name = "GrateFrame"
		base_mi.mesh = grate_base_mesh
		d_root.add_child(base_mi)

		for slot_idx in range(4):
			var slot_z: float = -0.36 + float(slot_idx) * 0.24
			var slot_mi := MeshInstance3D.new()
			slot_mi.name = "GrateSlot_%d" % slot_idx
			slot_mi.mesh = grate_slot_mesh
			slot_mi.position = Vector3(0.0, 0.002, slot_z)
			d_root.add_child(slot_mi)

	# 7. Plaza Half-Court Basketball Key Markings (Street Liga Basketball Court on asphalt)
	var court_root := Node3D.new()
	court_root.name = "PlazaBasketballCourtMarkings"
	court_root.position = Vector3(-6.0, 0.013, -3.0)
	markings_node.add_child(court_root)

	var chalk_mat := StandardMaterial3D.new()
	chalk_mat.albedo_color = Color(0.92, 0.92, 0.90, 0.85)
	chalk_mat.roughness = 0.92

	var court_lines := [
		{"pos": Vector3(0.0, 0.0, 2.8), "size": Vector3(3.6, 0.01, 0.10)},
		{"pos": Vector3(-1.8, 0.0, 0.0), "size": Vector3(0.10, 0.01, 5.6)},
		{"pos": Vector3(1.8, 0.0, 0.0), "size": Vector3(0.10, 0.01, 5.6)},
		{"pos": Vector3(0.0, 0.0, -2.8), "size": Vector3(4.8, 0.01, 0.10)}
	]
	for cl_idx in range(court_lines.size()):
		var cl = court_lines[cl_idx]
		var l_mi := MeshInstance3D.new()
		l_mi.name = "CourtLine_%d" % cl_idx
		var l_mesh := BoxMesh.new()
		l_mesh.size = cl["size"]
		l_mesh.material = chalk_mat
		l_mi.mesh = l_mesh
		l_mi.position = cl["pos"]
		court_root.add_child(l_mi)

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
	if "fence" in n_lower or "plane" in n_lower or "tree" in n_lower or "bench" in n_lower or "light" in n_lower or "trash" in n_lower or "drum" in n_lower or "nurbs" in n_lower or "flag" in n_lower or "vault" in n_lower or "crate" in n_lower or "curb" in n_lower or "grate" in n_lower or "marking" in n_lower or "stripe" in n_lower or "court" in n_lower or "dash" in n_lower:
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
	if "groundmarkings" in n_lower or "marking" in n_lower or "crosswalk" in n_lower or "curb" in n_lower or "grate" in n_lower or "courtline" in n_lower or "dash" in n_lower:
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
				if c_clean in [
					"plane_010", "plane_014", "plane_015", "plane_016",
					"cube_041", "plane_013", "cylinder_009", "cylinder_002", "cylinder_006",
					"cube_008", "cube_056", "plane_009", "plane_011", "plane_012",
					"cube_002", "cube_015"
				]:
					# Slants, roofs, slides, fences, and interactive buildings:
					# Decompose into solid convex prisms so slopes, fences, and roofs are traversable
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
	_create_mesh_convex_prisms(mi)

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
