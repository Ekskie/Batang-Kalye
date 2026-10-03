class_name CharacterAnimator
extends Node3D

enum CharacterType {
	TSUNA = 0,
	KALBO = 1,
	TOTOY = 2,
	ORIGINAL = 3,
	BATA = 4
}

const ARCHETYPES: Array[Dictionary] = [
	{
		"id": 0,
		"name": "Tsuna",
		"title": "Anime Kid",
		"base": 0,
		"hair": 0,
		"headwear": 0,
		"body": 0,
		"footwear": 0,
		"color": 0
	},
	{
		"id": 1,
		"name": "Kalbo",
		"title": "Street Brawler",
		"base": 1,
		"hair": 1,
		"headwear": 0,
		"body": 3,
		"footwear": 2,
		"color": 1
	},
	{
		"id": 2,
		"name": "Totoy",
		"title": "Sando Runner",
		"base": 2,
		"hair": 0,
		"headwear": 0,
		"body": 0,
		"footwear": 0,
		"color": 2
	},
	{
		"id": 3,
		"name": "Nene",
		"title": "Liksi Kid",
		"base": 0,
		"hair": 2,
		"headwear": 0,
		"body": 2,
		"footwear": 1,
		"color": 3
	},
	{
		"id": 4,
		"name": "Tisoy",
		"title": "Pormang Kanto",
		"base": 0,
		"hair": 0,
		"headwear": 1,
		"body": 0,
		"footwear": 1,
		"color": 4
	},
	{
		"id": 5,
		"name": "Baldo",
		"title": "Basketbolista",
		"base": 1,
		"hair": 1,
		"headwear": 4,
		"body": 1,
		"footwear": 1,
		"color": 5
	},
	{
		"id": 6,
		"name": "Nonoy",
		"title": "Pawisin",
		"base": 1,
		"hair": 3,
		"headwear": 2,
		"body": 0,
		"footwear": 0,
		"color": 6
	},
	{
		"id": 7,
		"name": "Kikay",
		"title": "Bibbo",
		"base": 0,
		"hair": 4,
		"headwear": 3,
		"body": 2,
		"footwear": 1,
		"color": 7
	}
]

const HAIR_OPTIONS: Array[Dictionary] = [
	{ "name": "Spiky Anime" },
	{ "name": "Kalbo (Kintab)" },
	{ "name": "Twin Pigtails" },
	{ "name": "Buzz Cut" },
	{ "name": "Bob Cut" }
]

const HEADWEAR_OPTIONS: Array[Dictionary] = [
	{ "name": "Wala (None)" },
	{ "name": "Baligtad na Snapback" },
	{ "name": "Good Morning Towel" },
	{ "name": "Bandana sa Noo" },
	{ "name": "Athletic Sweatband" }
]

const BODY_OPTIONS: Array[Dictionary] = [
	{ "name": "Street T-Shirt" },
	{ "name": "Sando #23 (Liga)" },
	{ "name": "Striped Pambahay" },
	{ "name": "Sleeveless Sando" }
]

const FOOTWEAR_OPTIONS: Array[Dictionary] = [
	{ "name": "Spartan (Asul/Puti)" },
	{ "name": "Islander (Pula)" },
	{ "name": "Black Rubber Slide" },
	{ "name": "Paang Hubad (Barefoot)" }
]

const COLOR_OPTIONS: Array[Dictionary] = [
	{ "name": "Puting Sando (Clean White)", "color": Color(0.95, 0.95, 0.95, 1.0) },
	{ "name": "Asul Kanto (Classic Navy)", "color": Color(0.18, 0.28, 0.48, 1.0) },
	{ "name": "Pulang Liga (Barangay Red)", "color": Color(0.72, 0.16, 0.16, 1.0) },
	{ "name": "Kulay Abo (Heather Grey)", "color": Color(0.52, 0.54, 0.56, 1.0) },
	{ "name": "Itim Kanto (Charcoal Black)", "color": Color(0.16, 0.17, 0.19, 1.0) },
	{ "name": "Kulay Kaki (Khaki Cargo)", "color": Color(0.60, 0.50, 0.38, 1.0) },
	{ "name": "Berdeng Army (Muted Olive)", "color": Color(0.28, 0.38, 0.26, 1.0) },
	{ "name": "Dilaw Pambahay (Sun Gold)", "color": Color(0.90, 0.74, 0.20, 1.0) }
]

const SKIN_TONES: Array[Dictionary] = [
	{ "name": "Kayumanggi (Natural Tan)", "color": Color(0.85, 0.62, 0.44, 1.0) },
	{ "name": "Moreno (Sun-Baked Bronze)", "color": Color(0.74, 0.50, 0.34, 1.0) },
	{ "name": "Mestizo (Warm Fair)", "color": Color(0.92, 0.72, 0.56, 1.0) },
	{ "name": "Matapang na Moreno (Deep Warm)", "color": Color(0.64, 0.42, 0.27, 1.0) }
]

const CHARACTER_NAMES: Array[String] = [
	"Tsuna (Anime Kid)",
	"Kalbo (Street Brawler)",
	"Totoy (Sando Runner)",
	"Nene (Liksi Kid)",
	"Tisoy (Pormang Kanto)",
	"Baldo (Basketbolista)",
	"Nonoy (Pawisin)",
	"Kikay (Bibbo)"
]

@export var is_taya: bool = false:
	set(value):
		if is_taya == value and is_inside_tree():
			return
		is_taya = value
		_update_taya_visuals()

# Active Customization State
var current_archetype: int = 0
var current_base_char: int = 0 # 0: Tsuna, 1: Kalbo, 2: Original
var current_skin_idx: int = 0
var current_skin_color: Color = Color(0.85, 0.62, 0.44, 1.0)
var current_hair: int = 0
var current_headwear: int = 0
var current_body: int = 0
var current_footwear: int = 0
var current_color_idx: int = 0

var current_character_type: int = CharacterType.TSUNA

@export var character_type: CharacterType = CharacterType.TSUNA:
	set(value):
		character_type = value
		if is_inside_tree() and current_character_type != value:
			set_character(value)

# Model container references
@onready var model_tsuna: Node3D = get_node_or_null("ModelTsuna")
@onready var model_kalbo: Node3D = get_node_or_null("ModelKalbo")
@onready var model_totoy: Node3D = get_node_or_null("ModelTotoy")
@onready var model_bata: Node3D = get_node_or_null("ModelBata")
@onready var model_original: Node3D = get_node_or_null("ModelOriginal")

# Legacy / Original blocky model parts (under ModelOriginal)
@onready var body_mesh: MeshInstance3D = get_node_or_null("ModelOriginal/Torso") if has_node("ModelOriginal/Torso") else get_node_or_null("Torso")
@onready var head_mesh: MeshInstance3D = get_node_or_null("ModelOriginal/Torso/Head") if has_node("ModelOriginal/Torso/Head") else get_node_or_null("Torso/Head")
@onready var left_arm: Node3D = get_node_or_null("ModelOriginal/Torso/LeftArmPivot") if has_node("ModelOriginal/Torso/LeftArmPivot") else get_node_or_null("Torso/LeftArmPivot")
@onready var right_arm: Node3D = get_node_or_null("ModelOriginal/Torso/RightArmPivot") if has_node("ModelOriginal/Torso/RightArmPivot") else get_node_or_null("Torso/RightArmPivot")
@onready var left_leg: Node3D = get_node_or_null("ModelOriginal/LeftLegPivot") if has_node("ModelOriginal/LeftLegPivot") else get_node_or_null("LeftLegPivot")
@onready var right_leg: Node3D = get_node_or_null("ModelOriginal/RightLegPivot") if has_node("ModelOriginal/RightLegPivot") else get_node_or_null("RightLegPivot")

# Taya Visuals
@onready var taya_aura: Node3D = get_node_or_null("TayaAura")
@onready var taya_badge: Label3D = get_node_or_null("TayaBadge")
@onready var taya_flame_particles: CPUParticles3D = get_node_or_null("TayaAura/FlameParticles")

# Held Trash Item Attachments
@onready var held_item_anchor: Node3D = get_node_or_null("HeldItemAnchor")
@onready var held_bottle: Node3D = get_node_or_null("HeldItemAnchor/HeldBottle")
@onready var held_can: Node3D = get_node_or_null("HeldItemAnchor/HeldCan")
@onready var held_peel: Node3D = get_node_or_null("HeldItemAnchor/HeldPeel")
@onready var held_wrapper: Node3D = get_node_or_null("HeldItemAnchor/HeldWrapper")

# Active dynamic references
var active_model: Node3D = null
var active_anim: AnimationPlayer = null
var active_mesh: MeshInstance3D = null
var is_skeletal: bool = true
var model_base_pos: Vector3 = Vector3.ZERO
var model_base_rot_y: float = PI

var walk_cycle_time: float = 0.0
var is_tag_swinging: bool = false
var tag_swing_timer: float = 0.0
var tag_swing_duration: float = 0.40

var is_carrying: bool = false
var held_trash_type: int = -1

var runner_mat: Material = preload("res://assets/materials/mat_runner.tres")
var taya_mat: Material = preload("res://assets/materials/mat_taya_glow.tres")
var current_player_color: Color = Color(0.18, 0.58, 0.95, 1.0)

var is_sliding: bool = false
var is_dashing: bool = false
var has_superspeed: bool = false
var held_anchor_base_y: float = 0.70

# Modular Accessory Nodes Map: model -> { "head": BoneAttachment3D, ... }
var modular_attachments: Dictionary = {}

# Node3D property compatibility for tweening / tinting
var modulate: Color = Color.WHITE

func _init_model_references() -> void:
	if not model_tsuna: model_tsuna = get_node_or_null("ModelTsuna")
	if not model_kalbo: model_kalbo = get_node_or_null("ModelKalbo")
	if not model_totoy: model_totoy = get_node_or_null("ModelTotoy")
	if not model_bata: model_bata = get_node_or_null("ModelBata")
	if not model_original: model_original = get_node_or_null("ModelOriginal")

	if not model_totoy and ResourceLoader.exists("res://assets/models/Totoy.glb"):
		var totoy_scene = load("res://assets/models/Totoy.glb") as PackedScene
		if totoy_scene:
			model_totoy = totoy_scene.instantiate() as Node3D
			model_totoy.name = "ModelTotoy"
			model_totoy.scale = Vector3(-25.0, 25.0, -25.0)
			model_totoy.position = Vector3.ZERO
			model_totoy.visible = false
			add_child(model_totoy)

func _ready() -> void:
	_init_model_references()
	if held_item_anchor:
		held_anchor_base_y = held_item_anchor.position.y

	_setup_modular_accessories()
	apply_preset(current_archetype)
	set_held_trash(-1)

func _exit_tree() -> void:
	if is_taya:
		is_taya = false
	if taya_flame_particles:
		taya_flame_particles.emitting = false
	if taya_aura:
		taya_aura.visible = false
	if active_mesh:
		active_mesh.material_override = null
	if body_mesh:
		body_mesh.material_override = null

func _setup_modular_accessories() -> void:
	_init_model_references()
	for m in [model_tsuna, model_kalbo, model_totoy]:
		if not m:
			continue
		var skel: Skeleton3D = m.get_node_or_null("Armature/Skeleton3D")
		if not skel:
			continue

		var attach_dict := {}

		# 1. Head Attachment
		var head_attach := BoneAttachment3D.new()
		head_attach.name = "Attach_Head"
		var b_head_name = "mixamorig_Head"
		var b_head_idx = skel.find_bone("mixamorig_Head")
		if b_head_idx == -1:
			b_head_name = "mixamorig:Head"
			b_head_idx = skel.find_bone("mixamorig:Head")
		head_attach.bone_name = b_head_name
		head_attach.bone_idx = b_head_idx
		skel.add_child(head_attach)
		attach_dict["head"] = head_attach
		_build_head_accessories(head_attach)

		# 2. Chest Attachment (mixamorig_Spine2)
		var chest_attach := BoneAttachment3D.new()
		chest_attach.name = "Attach_Chest"
		var b_chest_name = "mixamorig_Spine2"
		var b_chest_idx = skel.find_bone("mixamorig_Spine2")
		if b_chest_idx == -1:
			b_chest_name = "mixamorig:Spine2"
			b_chest_idx = skel.find_bone("mixamorig:Spine2")
		chest_attach.bone_name = b_chest_name
		chest_attach.bone_idx = b_chest_idx
		skel.add_child(chest_attach)
		attach_dict["chest"] = chest_attach
		_build_chest_accessories(chest_attach)

		# 3. Feet Attachments (mixamorig_LeftFoot & RightFoot)
		var l_foot := BoneAttachment3D.new()
		l_foot.name = "Attach_LFoot"
		var b_lfoot_name = "mixamorig_LeftFoot"
		var b_lfoot_idx = skel.find_bone("mixamorig_LeftFoot")
		if b_lfoot_idx == -1:
			b_lfoot_name = "mixamorig:LeftFoot"
			b_lfoot_idx = skel.find_bone("mixamorig:LeftFoot")
		l_foot.bone_name = b_lfoot_name
		l_foot.bone_idx = b_lfoot_idx
		skel.add_child(l_foot)
		attach_dict["l_foot"] = l_foot
		_build_foot_accessories(l_foot, true)

		var r_foot := BoneAttachment3D.new()
		r_foot.name = "Attach_RFoot"
		var b_rfoot_name = "mixamorig_RightFoot"
		var b_rfoot_idx = skel.find_bone("mixamorig_RightFoot")
		if b_rfoot_idx == -1:
			b_rfoot_name = "mixamorig:RightFoot"
			b_rfoot_idx = skel.find_bone("mixamorig:RightFoot")
		r_foot.bone_name = b_rfoot_name
		r_foot.bone_idx = b_rfoot_idx
		skel.add_child(r_foot)
		attach_dict["r_foot"] = r_foot
		_build_foot_accessories(r_foot, false)

		modular_attachments[m] = attach_dict

func _build_head_accessories(parent: Node3D) -> void:
	var toon_black := StandardMaterial3D.new()
	toon_black.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
	toon_black.specular_mode = BaseMaterial3D.SPECULAR_TOON
	toon_black.albedo_color = Color(0.1, 0.1, 0.12, 1.0)
	toon_black.roughness = 0.8

	# A. Twin Pigtails (Nene)
	var pigtails := Node3D.new()
	pigtails.name = "Acc_Pigtails"
	pigtails.visible = false

	for side in [-1.0, 1.0]:
		var bun := MeshInstance3D.new()
		var sm := SphereMesh.new()
		sm.radius = 0.012
		sm.height = 0.024
		sm.material = toon_black
		bun.mesh = sm
		bun.material_override = toon_black
		bun.position = Vector3(side * 0.024, 0.012, -0.005)
		pigtails.add_child(bun)

		var tail := MeshInstance3D.new()
		var cm := CapsuleMesh.new()
		cm.radius = 0.009
		cm.height = 0.035
		cm.material = toon_black
		tail.mesh = cm
		tail.material_override = toon_black
		tail.position = Vector3(side * 0.028, -0.008, -0.008)
		tail.rotation.z = deg_to_rad(side * -18.0)
		pigtails.add_child(tail)

		# Hair ties
		var tie := MeshInstance3D.new()
		var tm := TorusMesh.new()
		tm.inner_radius = 0.006
		tm.outer_radius = 0.011
		var tie_mat := StandardMaterial3D.new()
		tie_mat.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
		tie_mat.albedo_color = Color(0.95, 0.2, 0.4, 1.0)
		tm.material = tie_mat
		tie.mesh = tm
		tie.material_override = tie_mat
		tie.position = Vector3(side * 0.025, 0.006, -0.006)
		pigtails.add_child(tie)

	parent.add_child(pigtails)

	# B. Buzz Cut (Totoy)
	var buzz := MeshInstance3D.new()
	buzz.name = "Acc_BuzzCut"
	buzz.visible = false
	var b_mesh := SphereMesh.new()
	b_mesh.radius = 0.023
	b_mesh.height = 0.028
	b_mesh.material = toon_black
	buzz.mesh = b_mesh
	buzz.material_override = toon_black
	buzz.position = Vector3(0, 0.012, -0.002)
	parent.add_child(buzz)

	# C. Bob Cut (Kikay)
	var bob := Node3D.new()
	bob.name = "Acc_BobCut"
	bob.visible = false
	var top_hair := MeshInstance3D.new()
	var th_mesh := SphereMesh.new()
	th_mesh.radius = 0.024
	th_mesh.height = 0.030
	th_mesh.material = toon_black
	top_hair.mesh = th_mesh
	top_hair.material_override = toon_black
	top_hair.position = Vector3(0, 0.013, -0.003)
	bob.add_child(top_hair)

	for side in [-1.0, 1.0]:
		var fringe := MeshInstance3D.new()
		var fm := CapsuleMesh.new()
		fm.radius = 0.008
		fm.height = 0.038
		fm.material = toon_black
		fringe.mesh = fm
		fringe.material_override = toon_black
		fringe.position = Vector3(side * 0.022, -0.004, 0.008)
		bob.add_child(fringe)

	parent.add_child(bob)

	# D. Baligtad na Snapback Cap (Tisoy)
	var snapback := Node3D.new()
	snapback.name = "Acc_Snapback"
	snapback.visible = false

	var cap_mat := StandardMaterial3D.new()
	cap_mat.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
	cap_mat.albedo_color = Color(0.85, 0.2, 0.2, 1.0)

	var crown := MeshInstance3D.new()
	var c_mesh := SphereMesh.new()
	c_mesh.radius = 0.025
	c_mesh.height = 0.028
	c_mesh.material = cap_mat
	crown.mesh = c_mesh
	crown.material_override = cap_mat
	crown.position = Vector3(0, 0.015, -0.004)
	snapback.add_child(crown)

	var visor := MeshInstance3D.new()
	var v_box := BoxMesh.new()
	v_box.size = Vector3(0.028, 0.003, 0.022)
	v_box.material = cap_mat
	visor.mesh = v_box
	visor.material_override = cap_mat
	visor.position = Vector3(0, 0.018, -0.024) # Points backwards
	visor.rotation.x = deg_to_rad(-16.0)
	snapback.add_child(visor)
	parent.add_child(snapback)

	# E. Bandana sa Noo
	var bandana := Node3D.new()
	bandana.name = "Acc_Bandana"
	bandana.visible = false

	var band_mat := StandardMaterial3D.new()
	band_mat.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
	band_mat.albedo_color = Color(0.9, 0.15, 0.15, 1.0)

	var band := MeshInstance3D.new()
	var tm_band := TorusMesh.new()
	tm_band.inner_radius = 0.021
	tm_band.outer_radius = 0.025
	tm_band.material = band_mat
	band.mesh = tm_band
	band.material_override = band_mat
	band.position = Vector3(0, 0.008, 0.002)
	bandana.add_child(band)

	var knot := MeshInstance3D.new()
	var k_box := BoxMesh.new()
	k_box.size = Vector3(0.015, 0.015, 0.008)
	k_box.material = band_mat
	knot.mesh = k_box
	knot.material_override = band_mat
	knot.position = Vector3(0, 0.008, -0.024)
	bandana.add_child(knot)
	parent.add_child(bandana)

	# F. Athletic Sweatband (Baldo)
	var sweatband := MeshInstance3D.new()
	sweatband.name = "Acc_Sweatband"
	sweatband.visible = false
	var sb_mesh := TorusMesh.new()
	sb_mesh.inner_radius = 0.021
	sb_mesh.outer_radius = 0.025
	var sb_mat := StandardMaterial3D.new()
	sb_mat.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
	sb_mat.albedo_color = Color(0.96, 0.96, 0.96, 1.0)
	sb_mesh.material = sb_mat
	sweatband.mesh = sb_mesh
	sweatband.material_override = sb_mat
	sweatband.position = Vector3(0, 0.009, 0.002)
	parent.add_child(sweatband)

func _build_chest_accessories(parent: Node3D) -> void:
	# Good Morning Towel (Nonoy)
	var towel := Node3D.new()
	towel.name = "Acc_Towel"
	towel.visible = false

	var towel_mat := StandardMaterial3D.new()
	towel_mat.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
	towel_mat.specular_mode = BaseMaterial3D.SPECULAR_TOON
	towel_mat.albedo_color = Color(0.96, 0.96, 0.92, 1.0)
	towel_mat.roughness = 0.9

	var stripe_mat := StandardMaterial3D.new()
	stripe_mat.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
	stripe_mat.albedo_color = Color(0.15, 0.42, 0.82, 1.0)

	# Left hanging flap
	var l_flap := MeshInstance3D.new()
	var lf_mesh := BoxMesh.new()
	lf_mesh.size = Vector3(0.015, 0.055, 0.004)
	lf_mesh.material = towel_mat
	l_flap.mesh = lf_mesh
	l_flap.material_override = towel_mat
	l_flap.position = Vector3(-0.016, -0.015, 0.016)
	towel.add_child(l_flap)

	# Right hanging flap
	var r_flap := MeshInstance3D.new()
	var rf_mesh := BoxMesh.new()
	rf_mesh.size = Vector3(0.015, 0.055, 0.004)
	rf_mesh.material = towel_mat
	r_flap.mesh = rf_mesh
	r_flap.material_override = towel_mat
	r_flap.position = Vector3(0.016, -0.015, 0.016)
	towel.add_child(r_flap)

	# Good Morning blue stripes
	var l_str := MeshInstance3D.new()
	var ls_mesh := BoxMesh.new()
	ls_mesh.size = Vector3(0.015, 0.006, 0.005)
	ls_mesh.material = stripe_mat
	l_str.mesh = ls_mesh
	l_str.material_override = stripe_mat
	l_str.position = Vector3(-0.016, -0.036, 0.0165)
	towel.add_child(l_str)

	var r_str := MeshInstance3D.new()
	var rs_mesh := BoxMesh.new()
	rs_mesh.size = Vector3(0.015, 0.006, 0.005)
	rs_mesh.material = stripe_mat
	r_str.mesh = rs_mesh
	r_str.material_override = stripe_mat
	r_str.position = Vector3(0.016, -0.036, 0.0165)
	towel.add_child(r_str)

	parent.add_child(towel)

	# Sando #23 Badge (Liga)
	var badge := Label3D.new()
	badge.name = "Acc_Jersey23"
	badge.visible = false
	badge.text = "23"
	badge.font_size = 32
	badge.modulate = Color(1.0, 0.9, 0.2, 1.0)
	badge.outline_modulate = Color(0.1, 0.1, 0.12, 1.0)
	badge.outline_size = 6
	badge.position = Vector3(0, 0.01, 0.02)
	badge.scale = Vector3(0.03, 0.03, 0.03)
	parent.add_child(badge)

func _build_foot_accessories(parent: Node3D, _is_left: bool) -> void:
	# A. Spartan Slippers (Asul Sole / Puti Strap)
	var spartan := Node3D.new()
	spartan.name = "Acc_Spartan"
	spartan.visible = false

	var sole_mat := StandardMaterial3D.new()
	sole_mat.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
	sole_mat.albedo_color = Color(0.12, 0.45, 0.88, 1.0)

	var strap_mat := StandardMaterial3D.new()
	strap_mat.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
	strap_mat.albedo_color = Color(0.95, 0.95, 0.95, 1.0)

	var sole := MeshInstance3D.new()
	var sm := BoxMesh.new()
	sm.size = Vector3(0.015, 0.004, 0.032)
	sm.material = sole_mat
	sole.mesh = sm
	sole.material_override = sole_mat
	sole.position = Vector3(0, -0.006, 0.006)
	spartan.add_child(sole)

	var strap := MeshInstance3D.new()
	var stm := BoxMesh.new()
	stm.size = Vector3(0.016, 0.005, 0.012)
	stm.material = strap_mat
	strap.mesh = stm
	strap.material_override = strap_mat
	strap.position = Vector3(0, -0.002, 0.008)
	spartan.add_child(strap)
	parent.add_child(spartan)

	# B. Islander Slippers (Pula Sole / Itim Strap)
	var islander := Node3D.new()
	islander.name = "Acc_Islander"
	islander.visible = false

	var i_sole_mat := StandardMaterial3D.new()
	i_sole_mat.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
	i_sole_mat.albedo_color = Color(0.88, 0.18, 0.18, 1.0)

	var i_strap_mat := StandardMaterial3D.new()
	i_strap_mat.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
	i_strap_mat.albedo_color = Color(0.1, 0.1, 0.12, 1.0)

	var i_sole := MeshInstance3D.new()
	var ism := BoxMesh.new()
	ism.size = Vector3(0.016, 0.005, 0.034)
	ism.material = i_sole_mat
	i_sole.mesh = ism
	i_sole.material_override = i_sole_mat
	i_sole.position = Vector3(0, -0.006, 0.006)
	islander.add_child(i_sole)

	var i_strap := MeshInstance3D.new()
	var istm := BoxMesh.new()
	istm.size = Vector3(0.017, 0.006, 0.014)
	istm.material = i_strap_mat
	i_strap.mesh = istm
	i_strap.material_override = i_strap_mat
	i_strap.position = Vector3(0, -0.001, 0.008)
	islander.add_child(i_strap)
	parent.add_child(islander)

	# C. Black Rubber Slide
	var slide := Node3D.new()
	slide.name = "Acc_Slide"
	slide.visible = false

	var sl_mat := StandardMaterial3D.new()
	sl_mat.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
	sl_mat.albedo_color = Color(0.15, 0.15, 0.18, 1.0)

	var sl_mesh := BoxMesh.new()
	sl_mesh.size = Vector3(0.016, 0.007, 0.034)
	sl_mesh.material = sl_mat
	var sl_inst := MeshInstance3D.new()
	sl_inst.mesh = sl_mesh
	sl_inst.material_override = sl_mat
	sl_inst.position = Vector3(0, -0.004, 0.006)
	slide.add_child(sl_inst)
	parent.add_child(slide)

func apply_preset(idx: int) -> void:
	if idx < 0 or idx >= ARCHETYPES.size():
		idx = 0
	current_archetype = idx
	var p: Dictionary = ARCHETYPES[idx]
	set_modular_outfit(
		p.get("base", 0),
		p.get("hair", 0),
		p.get("headwear", 0),
		p.get("body", 0),
		p.get("footwear", 0),
		p.get("color", idx % COLOR_OPTIONS.size()),
		p.get("skin", 0)
	)

func set_modular_outfit(base_char: int, hair: int, headwear: int, body: int, footwear: int, col_idx: int, skin_idx: int = 0) -> void:
	current_base_char = base_char
	current_hair = hair
	current_headwear = headwear
	current_body = body
	current_footwear = footwear
	current_color_idx = col_idx % COLOR_OPTIONS.size()
	current_player_color = COLOR_OPTIONS[current_color_idx]["color"]
	current_skin_idx = skin_idx % SKIN_TONES.size()
	current_skin_color = SKIN_TONES[current_skin_idx]["color"]

	# Set base model
	set_character(current_base_char)
	_apply_active_mesh_color(current_player_color)

	# Update modular accessories on active model
	_update_modular_visuals()

func _update_modular_visuals() -> void:
	if not active_model or not modular_attachments.has(active_model):
		return

	var attaches: Dictionary = modular_attachments[active_model]
	var head: Node3D = attaches.get("head")
	var chest: Node3D = attaches.get("chest")
	var l_foot: Node3D = attaches.get("l_foot")
	var r_foot: Node3D = attaches.get("r_foot")

	# Native Tsuna hair toggle
	var tsuna_hair := active_model.get_node_or_null("Armature/Skeleton3D/hair") as MeshInstance3D
	if not tsuna_hair:
		tsuna_hair = active_model.get_node_or_null("Armature/Skeleton3D/hair_001") as MeshInstance3D
	if tsuna_hair and current_base_char == 0:
		tsuna_hair.visible = (current_hair == 0)

	# Native Totoy hair toggle
	var totoy_hair := active_model.get_node_or_null("Armature/Skeleton3D/hair_001") as MeshInstance3D
	if not totoy_hair:
		totoy_hair = active_model.get_node_or_null("Armature/Skeleton3D/hair.001") as MeshInstance3D
	if totoy_hair and current_base_char == CharacterType.TOTOY:
		totoy_hair.visible = (current_hair == 0 or current_hair == 3)

	# 1. Hair Slot
	if head:
		var pigtails = head.get_node_or_null("Acc_Pigtails")
		var buzz = head.get_node_or_null("Acc_BuzzCut")
		var bob = head.get_node_or_null("Acc_BobCut")
		if pigtails: pigtails.visible = (current_hair == 2)
		if buzz: buzz.visible = (current_hair == 3 and current_base_char != CharacterType.TOTOY)
		if bob: bob.visible = (current_hair == 4)

	# 2. Headwear Slot
	if head:
		var snapback = head.get_node_or_null("Acc_Snapback")
		var bandana = head.get_node_or_null("Acc_Bandana")
		var sweatband = head.get_node_or_null("Acc_Sweatband")
		if snapback:
			snapback.visible = (current_headwear == 1)
			if snapback.visible:
				var c_mat := StandardMaterial3D.new()
				c_mat.albedo_color = current_player_color
				for child in snapback.get_children():
					if child is MeshInstance3D:
						child.material_override = c_mat
		if bandana:
			bandana.visible = (current_headwear == 3)
			if bandana.visible:
				var b_mat := StandardMaterial3D.new()
				b_mat.albedo_color = Color(0.85, 0.15, 0.15, 1.0)
				for child in bandana.get_children():
					if child is MeshInstance3D:
						child.material_override = b_mat
		if sweatband:
			sweatband.visible = (current_headwear == 4)

	# 3. Body / Sando Slot
	if chest:
		var towel = chest.get_node_or_null("Acc_Towel")
		var j23 = chest.get_node_or_null("Acc_Jersey23")
		if towel: towel.visible = (current_headwear == 2)
		if j23: j23.visible = (current_body == 1 and current_base_char != CharacterType.TOTOY)

	# 4. Footwear Slot
	for f in [l_foot, r_foot]:
		if not f:
			continue
		var spartan = f.get_node_or_null("Acc_Spartan")
		var islander = f.get_node_or_null("Acc_Islander")
		var slide = f.get_node_or_null("Acc_Slide")
		if spartan: spartan.visible = (current_footwear == 0)
		if islander: islander.visible = (current_footwear == 1)
		if slide: slide.visible = (current_footwear == 2)

func get_outfit_data() -> Dictionary:
	return {
		"archetype": current_archetype,
		"base": current_base_char,
		"skin": current_skin_idx,
		"hair": current_hair,
		"headwear": current_headwear,
		"body": current_body,
		"footwear": current_footwear,
		"color": current_color_idx
	}

func apply_outfit_dict(d: Dictionary) -> void:
	if d.is_empty():
		return
	if d.has("archetype") and not d.has("hair"):
		apply_preset(d.get("archetype", 0))
		return
	set_modular_outfit(
		d.get("base", 0),
		d.get("hair", 0),
		d.get("headwear", 0),
		d.get("body", 0),
		d.get("footwear", 0),
		d.get("color", 0),
		d.get("skin", 0)
	)

func set_character(char_type: int) -> void:
	_init_model_references()
	current_character_type = char_type as CharacterType
	current_base_char = char_type

	# Hide all models first
	if model_tsuna: model_tsuna.visible = false
	if model_kalbo: model_kalbo.visible = false
	if model_totoy: model_totoy.visible = false
	if model_bata: model_bata.visible = false
	if model_original: model_original.visible = false
	if body_mesh and body_mesh.get_parent() == self: body_mesh.visible = false
	if left_leg and left_leg.get_parent() == self: left_leg.visible = false
	if right_leg and right_leg.get_parent() == self: right_leg.visible = false

	match current_character_type:
		CharacterType.TSUNA:
			if model_tsuna:
				model_tsuna.visible = true
				active_model = model_tsuna
				active_anim = model_tsuna.get_node_or_null("AnimationPlayer")
				active_mesh = model_tsuna.get_node_or_null("Armature/Skeleton3D/base_body")
				if not active_mesh:
					active_mesh = model_tsuna.get_node_or_null("Armature/Skeleton3D/base_body_001")
				var th = model_tsuna.get_node_or_null("Armature/Skeleton3D/hair")
				if not th:
					th = model_tsuna.get_node_or_null("Armature/Skeleton3D/hair_001")
				if th: th.visible = true
			is_skeletal = true
			model_base_rot_y = PI

		CharacterType.KALBO:
			if model_kalbo:
				model_kalbo.visible = true
				active_model = model_kalbo
				active_anim = model_kalbo.get_node_or_null("AnimationPlayer")
				active_mesh = model_kalbo.get_node_or_null("Armature/Skeleton3D/base_body_001")
				if not active_mesh:
					active_mesh = model_kalbo.get_node_or_null("Armature/Skeleton3D/base_body")
			is_skeletal = true
			model_base_rot_y = PI

		CharacterType.TOTOY:
			if model_totoy:
				model_totoy.visible = true
				active_model = model_totoy
				active_anim = model_totoy.get_node_or_null("AnimationPlayer")
				active_mesh = model_totoy.get_node_or_null("Armature/Skeleton3D/base_body_001")
				if not active_mesh:
					active_mesh = model_totoy.get_node_or_null("Armature/Skeleton3D/base_body.001")
				if not active_mesh:
					active_mesh = model_totoy.get_node_or_null("Armature/Skeleton3D/base_body")
				if not active_mesh:
					var skel = model_totoy.get_node_or_null("Armature/Skeleton3D")
					if skel:
						for c in skel.get_children():
							if c is MeshInstance3D and ("base_body" in c.name or "Body" in c.name):
								active_mesh = c
								break
				var th = model_totoy.get_node_or_null("Armature/Skeleton3D/hair_001")
				if not th:
					th = model_totoy.get_node_or_null("Armature/Skeleton3D/hair.001")
				if th: th.visible = true
			is_skeletal = true
			model_base_rot_y = PI

		CharacterType.ORIGINAL:
			if model_original:
				model_original.visible = true
				active_model = model_original
				active_anim = null
				active_mesh = body_mesh
			is_skeletal = false
			model_base_rot_y = 0.0

		_:
			if model_tsuna:
				model_tsuna.visible = true
				active_model = model_tsuna
				active_anim = model_tsuna.get_node_or_null("AnimationPlayer")
				active_mesh = model_tsuna.get_node_or_null("Armature/Skeleton3D/base_body")
				if not active_mesh:
					active_mesh = model_tsuna.get_node_or_null("Armature/Skeleton3D/base_body_001")
			is_skeletal = true
			model_base_rot_y = PI

	if active_model:
		model_base_pos = active_model.position

	# Configure skeletal animation loops
	if active_anim:
		# Auto-alias animations if named with _Armature suffix or capitalized (e.g. from Blender export)
		var lib_list: Array[StringName] = active_anim.get_animation_library_list()
		for lib_name in lib_list:
			var lib: AnimationLibrary = active_anim.get_animation_library(lib_name)
			if lib:
				var candidate_names: Array[String] = ["idle", "jogging", "running", "narutoRun", "jump", "punching", "t-pose", "slip"]
				for a_name: String in candidate_names:
					var suffixed: String = a_name + "_Armature"
					if lib.has_animation(suffixed) and not lib.has_animation(a_name):
						lib.add_animation(a_name, lib.get_animation(suffixed))
					var cap_name: String = a_name.capitalize()
					if lib.has_animation(cap_name) and not lib.has_animation(a_name):
						lib.add_animation(a_name, lib.get_animation(cap_name))

		var loop_anims: Array[String] = ["idle", "jogging", "running", "narutoRun", "idle_Armature", "jogging_Armature", "running_Armature", "narutoRun_Armature"]
		for a_name: String in loop_anims:
			if active_anim.has_animation(a_name):
				var a: Animation = active_anim.get_animation(a_name)
				if a:
					a.loop_mode = Animation.LOOP_LINEAR

		var non_loop_anims: Array[String] = ["jump", "punching", "jump_Armature", "punching_Armature", "slip", "Slip"]
		for a_name: String in non_loop_anims:
			if active_anim.has_animation(a_name):
				var a: Animation = active_anim.get_animation(a_name)
				if a:
					a.loop_mode = Animation.LOOP_NONE

		if _has_anim("idle"):
			_play_anim("idle")

	# Refresh materials on newly active model
	_apply_active_mesh_color(current_player_color)
	_update_taya_visuals()

func _update_taya_visuals() -> void:
	if not is_inside_tree():
		return
	if taya_aura:
		taya_aura.visible = is_taya
	if taya_flame_particles:
		taya_flame_particles.emitting = is_taya
	if taya_badge:
		taya_badge.visible = is_taya

	if is_taya:
		if active_mesh:
			active_mesh.material_override = taya_mat
		if body_mesh:
			body_mesh.material_override = taya_mat
		if active_model and active_model == model_totoy:
			var parts_taya: Array[String] = ["Shirt_001", "Shirt.001", "short_001", "short.001", "hair_001", "hair.001", "face_001", "face.001"]
			for part: String in parts_taya:
				var p_node: MeshInstance3D = active_model.get_node_or_null("Armature/Skeleton3D/" + part) as MeshInstance3D
				if p_node:
					p_node.material_override = taya_mat
	else:
		if active_model and active_model == model_totoy:
			var parts_clear: Array[String] = ["Shirt_001", "Shirt.001", "short_001", "short.001", "hair_001", "hair.001", "face_001", "face.001"]
			for part: String in parts_clear:
				var p_node: MeshInstance3D = active_model.get_node_or_null("Armature/Skeleton3D/" + part) as MeshInstance3D
				if p_node:
					p_node.material_override = null
		_apply_active_mesh_color(current_player_color)

func set_player_color(col: Color) -> void:
	current_player_color = col
	if not is_taya and is_inside_tree():
		_apply_active_mesh_color(col)

func _apply_active_mesh_color(col: Color) -> void:
	if active_mesh and active_mesh.mesh:
		active_mesh.material_override = null
		var surface_count: int = active_mesh.mesh.get_surface_count()
		if surface_count > 0:
			# Surface 0: Human Skin
			var skin_mat := StandardMaterial3D.new()
			skin_mat.albedo_color = current_skin_color
			skin_mat.roughness = 0.68
			active_mesh.set_surface_override_material(0, skin_mat)

		if surface_count > 1:
			# Surface 1: Shorts / Clothing
			var clothes_mat := StandardMaterial3D.new()
			clothes_mat.albedo_color = col
			clothes_mat.roughness = 0.5
			active_mesh.set_surface_override_material(1, clothes_mat)

	if active_model and active_model == model_totoy:
		var shirt = active_model.get_node_or_null("Armature/Skeleton3D/Shirt_001") as MeshInstance3D
		if not shirt:
			shirt = active_model.get_node_or_null("Armature/Skeleton3D/Shirt.001") as MeshInstance3D
		if shirt:
			var s_mat := StandardMaterial3D.new()
			s_mat.albedo_color = col
			s_mat.roughness = 0.5
			shirt.material_override = s_mat

	if body_mesh:
		body_mesh.material_override = null
		if body_mesh.mesh and body_mesh.mesh.get_surface_count() > 0:
			var b_mat := StandardMaterial3D.new()
			b_mat.albedo_color = col
			b_mat.roughness = 0.5
			body_mesh.set_surface_override_material(0, b_mat)

func set_held_trash(trash_type: int) -> void:
	held_trash_type = trash_type
	is_carrying = (trash_type != -1)
	if held_item_anchor:
		held_item_anchor.visible = is_carrying
	if held_bottle: held_bottle.visible = (trash_type == 0)
	if held_can: held_can.visible = (trash_type == 1)
	if held_peel: held_peel.visible = (trash_type == 2)
	if held_wrapper: held_wrapper.visible = (trash_type == 3)

func _has_anim(anim_name: String) -> bool:
	if not active_anim:
		return false
	return active_anim.has_animation(anim_name) or active_anim.has_animation(anim_name + "_Armature") or active_anim.has_animation(anim_name.capitalize())

func _get_anim_name(anim_name: String) -> String:
	if not active_anim:
		return anim_name
	if active_anim.has_animation(anim_name):
		return anim_name
	if active_anim.has_animation(anim_name + "_Armature"):
		return anim_name + "_Armature"
	if active_anim.has_animation(anim_name.capitalize()):
		return anim_name.capitalize()
	return anim_name

func _play_anim(anim_name: String, custom_blend: float = -1.0) -> void:
	if not active_anim:
		return
	var target: String = _get_anim_name(anim_name)
	if active_anim.has_animation(target):
		if active_anim.current_animation != target:
			active_anim.play(target, custom_blend)

func trigger_tag_animation() -> void:
	is_tag_swinging = true
	tag_swing_timer = tag_swing_duration
	if active_anim and _has_anim("punching"):
		_play_anim("punching", 0.08)
		active_anim.speed_scale = 2.2 # Snappy 0.4s tag punch strike

func animate(delta: float, horizontal_speed: float, is_on_floor: bool, max_speed: float) -> void:
	var using_naruto: bool = (has_superspeed or is_dashing or horizontal_speed > 13.0)

	# 1. Skeletal Character Animation
	if is_skeletal and active_anim:
		if is_tag_swinging and _has_anim("punching"):
			pass
		elif not is_on_floor:
			if _has_anim("jump"):
				_play_anim("jump", 0.12)
				active_anim.speed_scale = 1.2
			elif horizontal_speed > 3.0:
				_play_anim("jogging", 0.2)
				active_anim.speed_scale = 0.8
			else:
				_play_anim("idle", 0.2)
				active_anim.speed_scale = 0.8
		else:
			if horizontal_speed > 0.3:
				if using_naruto and _has_anim("narutoRun"):
					_play_anim("narutoRun", 0.15)
					active_anim.speed_scale = clamp(horizontal_speed / 11.5, 1.0, 2.4)
				elif horizontal_speed > 8.0 and _has_anim("running"):
					_play_anim("running", 0.15)
					active_anim.speed_scale = clamp(horizontal_speed / 11.5, 0.85, 1.8)
				elif _has_anim("jogging"):
					_play_anim("jogging", 0.15)
					active_anim.speed_scale = clamp(horizontal_speed / 7.0, 0.75, 1.4)
			else:
				if _has_anim("idle"):
					_play_anim("idle", 0.25)
					active_anim.speed_scale = 1.0

	# 2. Original Procedural Animation (Batang Kalye Retro Model)
	elif not is_skeletal:
		if is_on_floor and horizontal_speed > 0.3:
			walk_cycle_time += delta * (horizontal_speed / max(max_speed, 1.0)) * 14.0
			var leg_swing: float = sin(walk_cycle_time) * 0.65
			if left_leg: left_leg.rotation.x = leg_swing
			if right_leg: right_leg.rotation.x = -leg_swing
			if not is_tag_swinging:
				if left_arm: left_arm.rotation.x = -leg_swing * 0.75
				if right_arm: right_arm.rotation.x = leg_swing * 0.75
			if body_mesh:
				body_mesh.position.y = 0.7 + abs(sin(walk_cycle_time * 2.0)) * 0.04
		else:
			if left_leg: left_leg.rotation.x = lerp_angle(left_leg.rotation.x, 0.0, delta * 12.0)
			if right_leg: right_leg.rotation.x = lerp_angle(right_leg.rotation.x, 0.0, delta * 12.0)
			if not is_tag_swinging:
				if left_arm: left_arm.rotation.x = lerp_angle(left_arm.rotation.x, 0.0, delta * 12.0)
				if right_arm: right_arm.rotation.x = lerp_angle(right_arm.rotation.x, 0.0, delta * 12.0)
			if body_mesh:
				body_mesh.position.y = lerp(body_mesh.position.y, 0.7, delta * 8.0)

	# 3. Tag Action Reach / Slap Lunge
	if is_tag_swinging:
		tag_swing_timer -= delta
		var progress: float = 1.0 - (tag_swing_timer / tag_swing_duration)
		var swing_angle: float = sin(progress * PI) * 1.8

		if active_model:
			var lunge: float = sin(progress * PI) * 0.24
			active_model.position.z = model_base_pos.z - lunge
			active_model.rotation.y = model_base_rot_y + sin(progress * PI) * 0.25

		if right_arm:
			right_arm.rotation.x = swing_angle
			right_arm.rotation.y = -sin(progress * PI) * 0.6

		if tag_swing_timer <= 0.0:
			is_tag_swinging = false
			if active_model:
				active_model.position.z = model_base_pos.z
				active_model.rotation.y = model_base_rot_y
			if right_arm:
				right_arm.rotation = Vector3.ZERO
	else:
		if active_model:
			active_model.position.z = lerp(active_model.position.z, model_base_pos.z, delta * 12.0)
			active_model.rotation.y = lerp_angle(active_model.rotation.y, model_base_rot_y, delta * 12.0)

	# 4. Dynamic Tilt Overlays (Dash, Slide, Jump)
	if is_dashing:
		if active_model:
			active_model.rotation.x = lerp_angle(active_model.rotation.x, deg_to_rad(28.0), delta * 15.0)
		return

	if is_sliding:
		if active_model:
			active_model.rotation.x = lerp_angle(active_model.rotation.x, deg_to_rad(-24.0), delta * 15.0)
			active_model.position.y = lerp(active_model.position.y, model_base_pos.y - 0.18, delta * 15.0)
		return

	if not is_on_floor:
		if active_model:
			active_model.rotation.x = lerp_angle(active_model.rotation.x, deg_to_rad(5.0), delta * 8.0)
			active_model.position.y = lerp(active_model.position.y, model_base_pos.y + 0.05, delta * 8.0)
		_apply_carry_bob(delta)
		return

	# Reset orientation smoothly when normal walking/idling
	if active_model:
		active_model.rotation.x = lerp_angle(active_model.rotation.x, 0.0, delta * 8.0)
		active_model.rotation.y = lerp_angle(active_model.rotation.y, model_base_rot_y, delta * 8.0)
		active_model.position.y = lerp(active_model.position.y, model_base_pos.y, delta * 8.0)

	_apply_carry_bob(delta)

	# 5. Rotate fiery aura rings if Taya
	if is_taya and taya_aura:
		taya_aura.rotate_y(delta * 2.5)
		var inner := taya_aura.get_node_or_null("InnerRing")
		if inner:
			inner.rotate_y(delta * -4.5)

func _apply_carry_bob(_delta: float) -> void:
	if is_carrying and held_item_anchor:
		walk_cycle_time += _delta * 12.0
		var bob: float = sin(walk_cycle_time) * 0.03
		held_item_anchor.position.y = held_anchor_base_y + bob
		held_item_anchor.rotation.z = sin(walk_cycle_time * 0.5) * 0.04
