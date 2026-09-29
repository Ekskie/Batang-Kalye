class_name CharacterAnimator
extends Node3D

enum CharacterType {
	TSUNA = 0,
	KALBO = 1,
	ORIGINAL = 2,
	BATA = 3
}

const ARCHETYPES: Array[Dictionary] = [
	{
		"id": 0,
		"name": "⚡ Tsuna",
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
		"name": "🥊 Kalbo",
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
		"name": "🏃 Totoy",
		"title": "Sando Runner",
		"base": 1,
		"hair": 3,
		"headwear": 0,
		"body": 1,
		"footwear": 0,
		"color": 2
	},
	{
		"id": 3,
		"name": "👧 Nene",
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
		"name": "🧢 Tisoy",
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
		"name": "🏀 Baldo",
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
		"name": "🧣 Nonoy",
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
		"name": "🎀 Kikay",
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
	{ "name": "⚡ Spiky Anime" },
	{ "name": "🥊 Kalbo (Kintab)" },
	{ "name": "👧 Twin Pigtails" },
	{ "name": "✂️ Buzz Cut" },
	{ "name": "🎀 Bob Cut" }
]

const HEADWEAR_OPTIONS: Array[Dictionary] = [
	{ "name": "🚫 Wala (None)" },
	{ "name": "🧢 Baligtad na Snapback" },
	{ "name": "🧣 Good Morning Towel" },
	{ "name": "🥷 Bandana sa Noo" },
	{ "name": "🏀 Athletic Sweatband" }
]

const BODY_OPTIONS: Array[Dictionary] = [
	{ "name": "👕 Street T-Shirt" },
	{ "name": "🏀 Sando #23 (Liga)" },
	{ "name": "🏠 Striped Pambahay" },
	{ "name": "🎽 Sleeveless Sando" }
]

const FOOTWEAR_OPTIONS: Array[Dictionary] = [
	{ "name": "🩴 Spartan (Asul/Puti)" },
	{ "name": "🔴 Islander (Pula)" },
	{ "name": "👟 Black Rubber Slide" },
	{ "name": "👣 Paang Hubad (Barefoot)" }
]

const COLOR_OPTIONS: Array[Dictionary] = [
	{ "name": "Asul (Electric Blue)", "color": Color(0.18, 0.58, 0.95, 1.0) },
	{ "name": "Pula (Tapang Red)", "color": Color(0.92, 0.22, 0.18, 1.0) },
	{ "name": "Berde (Luntiang Green)", "color": Color(0.18, 0.78, 0.38, 1.0) },
	{ "name": "Dilaw (Sun Yellow)", "color": Color(0.98, 0.85, 0.12, 1.0) },
	{ "name": "Kahel (Cyber Orange)", "color": Color(1.0, 0.52, 0.08, 1.0) },
	{ "name": "Lila (Fiesta Purple)", "color": Color(0.72, 0.28, 0.95, 1.0) },
	{ "name": "Teal (Kanto Cyan)", "color": Color(0.15, 0.82, 0.82, 1.0) },
	{ "name": "Rosas (Bata Pink)", "color": Color(0.95, 0.28, 0.65, 1.0) }
]

const CHARACTER_NAMES: Array[String] = [
	"⚡ Tsuna (Anime Kid)",
	"🥊 Kalbo (Street Brawler)",
	"🏃 Totoy (Sando Runner)",
	"👧 Nene (Liksi Kid)",
	"🧢 Tisoy (Pormang Kanto)",
	"🏀 Baldo (Basketbolista)",
	"🧣 Nonoy (Pawisin)",
	"🎀 Kikay (Bibbo)"
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

func _ready() -> void:
	if held_item_anchor:
		held_anchor_base_y = held_item_anchor.position.y

	_setup_modular_accessories()
	apply_preset(current_archetype)
	set_held_trash(-1)

func _setup_modular_accessories() -> void:
	for m in [model_tsuna, model_kalbo]:
		if not m:
			continue
		var skel: Skeleton3D = m.get_node_or_null("Armature/Skeleton3D")
		if not skel:
			continue

		var attach_dict := {}

		# 1. Head Attachment
		var head_attach := BoneAttachment3D.new()
		head_attach.name = "Attach_Head"
		head_attach.bone_name = "mixamorig_Head"
		skel.add_child(head_attach)
		attach_dict["head"] = head_attach
		_build_head_accessories(head_attach)

		# 2. Chest Attachment (mixamorig_Spine2)
		var chest_attach := BoneAttachment3D.new()
		chest_attach.name = "Attach_Chest"
		chest_attach.bone_name = "mixamorig_Spine2"
		skel.add_child(chest_attach)
		attach_dict["chest"] = chest_attach
		_build_chest_accessories(chest_attach)

		# 3. Feet Attachments (mixamorig_LeftFoot & RightFoot)
		var l_foot := BoneAttachment3D.new()
		l_foot.name = "Attach_LFoot"
		l_foot.bone_name = "mixamorig_LeftFoot"
		skel.add_child(l_foot)
		attach_dict["l_foot"] = l_foot
		_build_foot_accessories(l_foot, true)

		var r_foot := BoneAttachment3D.new()
		r_foot.name = "Attach_RFoot"
		r_foot.bone_name = "mixamorig_RightFoot"
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
		bun.mesh = sm
		bun.material_override = toon_black
		bun.position = Vector3(side * 0.024, 0.012, -0.005)
		pigtails.add_child(bun)

		var tail := MeshInstance3D.new()
		var cm := CapsuleMesh.new()
		cm.radius = 0.009
		cm.height = 0.035
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
		tie.mesh = tm
		var tie_mat := StandardMaterial3D.new()
		tie_mat.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
		tie_mat.albedo_color = Color(0.95, 0.2, 0.4, 1.0)
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
	top_hair.mesh = th_mesh
	top_hair.material_override = toon_black
	top_hair.position = Vector3(0, 0.013, -0.003)
	bob.add_child(top_hair)

	for side in [-1.0, 1.0]:
		var fringe := MeshInstance3D.new()
		var fm := CapsuleMesh.new()
		fm.radius = 0.008
		fm.height = 0.038
		fringe.mesh = fm
		fringe.material_override = toon_black
		fringe.position = Vector3(side * 0.022, -0.004, 0.008)
		bob.add_child(fringe)

	parent.add_child(bob)

	# D. Baligtad na Snapback Cap (Tisoy)
	var snapback := Node3D.new()
	snapback.name = "Acc_Snapback"
	snapback.visible = false

	var crown := MeshInstance3D.new()
	var c_mesh := SphereMesh.new()
	c_mesh.radius = 0.025
	c_mesh.height = 0.028
	crown.mesh = c_mesh
	crown.position = Vector3(0, 0.015, -0.004)
	snapback.add_child(crown)

	var visor := MeshInstance3D.new()
	var v_box := BoxMesh.new()
	v_box.size = Vector3(0.028, 0.003, 0.022)
	visor.mesh = v_box
	visor.position = Vector3(0, 0.018, -0.024) # Points backwards
	visor.rotation.x = deg_to_rad(-16.0)
	snapback.add_child(visor)
	parent.add_child(snapback)

	# E. Bandana sa Noo
	var bandana := Node3D.new()
	bandana.name = "Acc_Bandana"
	bandana.visible = false
	var band := MeshInstance3D.new()
	var tm_band := TorusMesh.new()
	tm_band.inner_radius = 0.021
	tm_band.outer_radius = 0.025
	band.mesh = tm_band
	band.position = Vector3(0, 0.008, 0.002)
	bandana.add_child(band)

	var knot := MeshInstance3D.new()
	var k_box := BoxMesh.new()
	k_box.size = Vector3(0.015, 0.015, 0.008)
	knot.mesh = k_box
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
	sweatband.mesh = sb_mesh
	var sb_mat := StandardMaterial3D.new()
	sb_mat.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
	sb_mat.albedo_color = Color(0.96, 0.96, 0.96, 1.0)
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
	l_flap.mesh = lf_mesh
	l_flap.material_override = towel_mat
	l_flap.position = Vector3(-0.016, -0.015, 0.016)
	towel.add_child(l_flap)

	# Right hanging flap
	var r_flap := MeshInstance3D.new()
	var rf_mesh := BoxMesh.new()
	rf_mesh.size = Vector3(0.015, 0.055, 0.004)
	r_flap.mesh = rf_mesh
	r_flap.material_override = towel_mat
	r_flap.position = Vector3(0.016, -0.015, 0.016)
	towel.add_child(r_flap)

	# Good Morning blue stripes
	var l_str := MeshInstance3D.new()
	var ls_mesh := BoxMesh.new()
	ls_mesh.size = Vector3(0.015, 0.006, 0.005)
	l_str.mesh = ls_mesh
	l_str.material_override = stripe_mat
	l_str.position = Vector3(-0.016, -0.036, 0.0165)
	towel.add_child(l_str)

	var r_str := MeshInstance3D.new()
	var rs_mesh := BoxMesh.new()
	rs_mesh.size = Vector3(0.015, 0.006, 0.005)
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

func _build_foot_accessories(parent: Node3D, is_left: bool) -> void:
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
	sole.mesh = sm
	sole.material_override = sole_mat
	sole.position = Vector3(0, -0.006, 0.006)
	spartan.add_child(sole)

	var strap := MeshInstance3D.new()
	var stm := BoxMesh.new()
	stm.size = Vector3(0.016, 0.005, 0.012)
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
	i_sole.mesh = ism
	i_sole.material_override = i_sole_mat
	i_sole.position = Vector3(0, -0.006, 0.006)
	islander.add_child(i_sole)

	var i_strap := MeshInstance3D.new()
	var istm := BoxMesh.new()
	istm.size = Vector3(0.017, 0.006, 0.014)
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
		p.get("color", idx % COLOR_OPTIONS.size())
	)

func set_modular_outfit(base_char: int, hair: int, headwear: int, body: int, footwear: int, col_idx: int) -> void:
	current_base_char = base_char
	current_hair = hair
	current_headwear = headwear
	current_body = body
	current_footwear = footwear
	current_color_idx = col_idx % COLOR_OPTIONS.size()
	current_player_color = COLOR_OPTIONS[current_color_idx]["color"]

	# Set base model
	set_character(current_base_char)
	set_player_color(current_player_color)

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
	var tsuna_hair := active_model.get_node_or_null("Armature/Skeleton3D/hair_001") as MeshInstance3D
	if tsuna_hair:
		tsuna_hair.visible = (current_hair == 0 and current_base_char == 0)

	# 1. Hair Slot
	if head:
		var pigtails = head.get_node_or_null("Acc_Pigtails")
		var buzz = head.get_node_or_null("Acc_BuzzCut")
		var bob = head.get_node_or_null("Acc_BobCut")
		if pigtails: pigtails.visible = (current_hair == 2)
		if buzz: buzz.visible = (current_hair == 3)
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
				c_mat.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
				c_mat.albedo_color = current_player_color
				for child in snapback.get_children():
					if child is MeshInstance3D:
						child.material_override = c_mat
		if bandana:
			bandana.visible = (current_headwear == 3)
			if bandana.visible:
				var b_mat := StandardMaterial3D.new()
				b_mat.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
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
		if j23: j23.visible = (current_body == 1)

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
		d.get("color", 0)
	)

func set_character(char_type: int) -> void:
	current_character_type = char_type as CharacterType
	current_base_char = char_type

	# Hide all models first
	if model_tsuna: model_tsuna.visible = false
	if model_kalbo: model_kalbo.visible = false
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
				active_mesh = model_tsuna.get_node_or_null("Armature/Skeleton3D/base_body_001")
			is_skeletal = true
			model_base_rot_y = PI

		CharacterType.KALBO:
			if model_kalbo:
				model_kalbo.visible = true
				active_model = model_kalbo
				active_anim = model_kalbo.get_node_or_null("AnimationPlayer")
				active_mesh = model_kalbo.get_node_or_null("Armature/Skeleton3D/base_body_001")
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
				active_mesh = model_tsuna.get_node_or_null("Armature/Skeleton3D/base_body_001")
			is_skeletal = true
			model_base_rot_y = PI

	if active_model:
		model_base_pos = active_model.position

	# Configure skeletal animation loops
	if active_anim:
		for a_name in ["idle", "jogging", "running", "narutoRun"]:
			if active_anim.has_animation(a_name):
				var a := active_anim.get_animation(a_name)
				a.loop_mode = Animation.LOOP_LINEAR
		for a_name in ["jump", "punching"]:
			if active_anim.has_animation(a_name):
				var a := active_anim.get_animation(a_name)
				a.loop_mode = Animation.LOOP_NONE
		if active_anim.has_animation("idle"):
			active_anim.play("idle")

	# Refresh materials on newly active model
	set_player_color(current_player_color)
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
	else:
		_apply_active_mesh_color(current_player_color)

func set_player_color(col: Color) -> void:
	current_player_color = col
	if not is_taya and is_inside_tree():
		_apply_active_mesh_color(col)

func _apply_active_mesh_color(col: Color) -> void:
	var custom_mat := StandardMaterial3D.new()
	custom_mat.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
	custom_mat.specular_mode = BaseMaterial3D.SPECULAR_TOON
	custom_mat.albedo_color = col
	custom_mat.roughness = 0.45
	if active_mesh:
		active_mesh.material_override = custom_mat
	if body_mesh:
		body_mesh.material_override = custom_mat

func set_held_trash(trash_type: int) -> void:
	held_trash_type = trash_type
	is_carrying = (trash_type != -1)
	if held_item_anchor:
		held_item_anchor.visible = is_carrying
	if held_bottle: held_bottle.visible = (trash_type == 0)
	if held_can: held_can.visible = (trash_type == 1)
	if held_peel: held_peel.visible = (trash_type == 2)
	if held_wrapper: held_wrapper.visible = (trash_type == 3)

func trigger_tag_animation() -> void:
	is_tag_swinging = true
	tag_swing_timer = tag_swing_duration
	if active_anim and active_anim.has_animation("punching"):
		active_anim.play("punching", 0.08)
		active_anim.speed_scale = 2.2 # Snappy 0.4s tag punch strike

func animate(delta: float, horizontal_speed: float, is_on_floor: bool, max_speed: float) -> void:
	var using_naruto: bool = (has_superspeed or is_dashing or horizontal_speed > 13.0)

	# 1. Skeletal Character Animation
	if is_skeletal and active_anim:
		if is_tag_swinging and active_anim.has_animation("punching"):
			pass
		elif not is_on_floor:
			if active_anim.has_animation("jump"):
				if active_anim.current_animation != "jump":
					active_anim.play("jump", 0.12)
				active_anim.speed_scale = 1.2
			elif horizontal_speed > 3.0:
				if active_anim.current_animation != "jogging":
					active_anim.play("jogging", 0.2)
				active_anim.speed_scale = 0.8
			else:
				if active_anim.current_animation != "idle":
					active_anim.play("idle", 0.2)
				active_anim.speed_scale = 0.8
		else:
			if horizontal_speed > 0.3:
				if using_naruto and active_anim.has_animation("narutoRun"):
					if active_anim.current_animation != "narutoRun":
						active_anim.play("narutoRun", 0.15)
					active_anim.speed_scale = clamp(horizontal_speed / 11.5, 1.0, 2.4)
				elif horizontal_speed > 8.0 and active_anim.has_animation("running"):
					if active_anim.current_animation != "running":
						active_anim.play("running", 0.15)
					active_anim.speed_scale = clamp(horizontal_speed / 11.5, 0.85, 1.8)
				elif active_anim.has_animation("jogging"):
					if active_anim.current_animation != "jogging":
						active_anim.play("jogging", 0.15)
					active_anim.speed_scale = clamp(horizontal_speed / 7.0, 0.75, 1.4)
			else:
				if active_anim.has_animation("idle"):
					if active_anim.current_animation != "idle":
						active_anim.play("idle", 0.25)
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
