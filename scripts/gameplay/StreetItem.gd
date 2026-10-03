class_name StreetItem
extends Node3D

enum ItemType {
	TSINELAS = 0,    # Spartan Flying Slipper (Runner)
	SAGING = 1,      # Balat ng Saging Slip Trap (Runner)
	WHISTLE = 2,     # Barangay Whistle Radar (Taya)
	CHALK_BAG = 3,   # Chalk Dust Blind Cloud (Taya)
	ICE_CANDY = 4    # Ice Candy Stamina + Speed (Taya)
}

@export var item_type: ItemType = ItemType.TSINELAS:
	set(val):
		item_type = val
		if is_inside_tree():
			_update_visuals()

@export var respawn_time: float = 16.0
var is_collected: bool = false
var respawn_timer: float = 0.0
var anim_time: float = 0.0

@onready var visual_root: Node3D = get_node_or_null("VisualRoot")
@onready var label: Label3D = get_node_or_null("Label3D")
@onready var area: Area3D = get_node_or_null("Area3D")
@onready var ring: MeshInstance3D = get_node_or_null("HighlightRing")
@onready var particles: CPUParticles3D = get_node_or_null("PickupParticles")

var nearby_players: Array[PlayerController] = []

func _ready() -> void:
	add_to_group("street_items")
	_build_or_update_meshes()
	_update_visuals()
	if area:
		area.body_entered.connect(_on_body_entered)
		area.body_exited.connect(_on_body_exited)

func _process(delta: float) -> void:
	if is_collected:
		respawn_timer -= delta
		if respawn_timer <= 0.0:
			respawn()
		return

	anim_time += delta * 2.8
	if visual_root:
		visual_root.position.y = 0.35 + sin(anim_time) * 0.08
		visual_root.rotate_y(delta * 1.8)

	if ring and ring.visible:
		var pulse: float = 1.0 + sin(anim_time * 3.5) * 0.12
		ring.scale = Vector3(pulse, 1.0, pulse)

	# Check pickup proximity
	_check_auto_pickup()

func _check_auto_pickup() -> void:
	if is_collected or nearby_players.is_empty():
		return

	for p in nearby_players:
		if not is_instance_valid(p) or p.is_eliminated:
			continue

		# Check role compatibility
		var is_taya := (p.current_role == PlayerController.Role.TAYA)
		var is_for_taya := (item_type in [ItemType.WHISTLE, ItemType.CHALK_BAG, ItemType.ICE_CANDY])
		var is_for_runner := (item_type in [ItemType.TSINELAS, ItemType.SAGING])

		if (is_taya and is_for_taya) or (not is_taya and is_for_runner):
			# If player can carry item
			if p.has_method("pickup_street_item") and p.call("can_pickup_street_item", int(item_type)):
				collect(p)
				break

func collect(collector: PlayerController) -> void:
	if is_collected:
		return
	is_collected = true
	respawn_timer = respawn_time

	if collector and collector.has_method("pickup_street_item"):
		collector.call("pickup_street_item", int(item_type), get_item_name())

	if Engine.has_singleton("AudioManager"):
		AudioManager.play_pickup()
	elif has_node("/root/AudioManager"):
		get_node("/root/AudioManager").play_pickup()

	if particles:
		particles.restart()

	if visual_root:
		visual_root.visible = false
	if label:
		label.visible = false
	if ring:
		ring.visible = false

	if multiplayer.has_multiplayer_peer() and multiplayer.is_server():
		rpc("sync_item_collected")

@rpc("call_local", "reliable")
func sync_item_collected() -> void:
	is_collected = true
	respawn_timer = respawn_time
	if visual_root: visual_root.visible = false
	if label: label.visible = false
	if ring: ring.visible = false

func respawn() -> void:
	is_collected = false
	if visual_root: visual_root.visible = true
	if label: label.visible = true
	if ring: ring.visible = true

	if multiplayer.has_multiplayer_peer() and multiplayer.is_server():
		rpc("sync_item_respawn")

@rpc("call_local", "reliable")
func sync_item_respawn() -> void:
	is_collected = false
	if visual_root: visual_root.visible = true
	if label: label.visible = true
	if ring: ring.visible = true

func _on_body_entered(body: Node3D) -> void:
	if body is PlayerController and not nearby_players.has(body):
		nearby_players.append(body)

func _on_body_exited(body: Node3D) -> void:
	if body is PlayerController:
		nearby_players.erase(body)

func get_item_name() -> String:
	match item_type:
		ItemType.TSINELAS: return "Spartan Tsinelas"
		ItemType.SAGING: return "Balat ng Saging"
		ItemType.WHISTLE: return "Barangay Whistle"
		ItemType.CHALK_BAG: return "Chalk Dust Bag"
		ItemType.ICE_CANDY: return "Ice Candy"
	return "Street Item"

func get_item_action_hint() -> String:
	match item_type:
		ItemType.TSINELAS: return "[Right-Click / BATO] Pambalibag Stun!"
		ItemType.SAGING: return "[Right-Click / BATO] Bitawan sa Kalye!"
		ItemType.WHISTLE: return "[Right-Click / BATO] Sipol Reveal!"
		ItemType.CHALK_BAG: return "[Right-Click / BATO] Ibato ang Chalk!"
		ItemType.ICE_CANDY: return "[Right-Click / BATO] Sipsipin Pabilis!"
	return "Gamitin"

func _update_visuals() -> void:
	if label:
		label.text = get_item_name()
		match item_type:
			ItemType.TSINELAS:
				label.modulate = Color(0.3, 0.7, 1.0)
			ItemType.SAGING:
				label.modulate = Color(1.0, 0.9, 0.2)
			ItemType.WHISTLE:
				label.modulate = Color(1.0, 0.35, 0.35)
			ItemType.CHALK_BAG:
				label.modulate = Color(0.9, 0.9, 0.95)
			ItemType.ICE_CANDY:
				label.modulate = Color(1.0, 0.45, 0.8)

	_show_matching_mesh()

func _show_matching_mesh() -> void:
	if not visual_root:
		return
	for child in visual_root.get_children():
		child.visible = false

	var node_name := ""
	match item_type:
		ItemType.TSINELAS: node_name = "TsinelasMesh"
		ItemType.SAGING: node_name = "SagingMesh"
		ItemType.WHISTLE: node_name = "WhistleMesh"
		ItemType.CHALK_BAG: node_name = "ChalkMesh"
		ItemType.ICE_CANDY: node_name = "IceCandyMesh"

	var m = visual_root.get_node_or_null(node_name)
	if m:
		m.visible = true

func _build_or_update_meshes() -> void:
	if not visual_root:
		visual_root = Node3D.new()
		visual_root.name = "VisualRoot"
		add_child(visual_root)

	# 1. Tsinelas Mesh (Classic Spartan blue sole + white strap)
	if not visual_root.has_node("TsinelasMesh"):
		var t_root := Node3D.new()
		t_root.name = "TsinelasMesh"
		var sole := MeshInstance3D.new()
		var b := BoxMesh.new()
		b.size = Vector3(0.24, 0.05, 0.55)
		sole.mesh = b
		var sole_mat := StandardMaterial3D.new()
		sole_mat.albedo_color = Color(0.12, 0.42, 0.85) # Blue rubber
		sole.material_override = sole_mat
		t_root.add_child(sole)

		var strap := MeshInstance3D.new()
		var t_mesh := TorusMesh.new()
		t_mesh.inner_radius = 0.08
		t_mesh.outer_radius = 0.14
		strap.mesh = t_mesh
		strap.position = Vector3(0, 0.06, -0.05)
		strap.rotation_degrees = Vector3(90, 0, 0)
		strap.scale = Vector3(1.0, 0.3, 0.8)
		var strap_mat := StandardMaterial3D.new()
		strap_mat.albedo_color = Color(0.95, 0.95, 0.95) # White strap
		strap.material_override = strap_mat
		t_root.add_child(strap)
		visual_root.add_child(t_root)

	# 2. Saging Mesh (Banana Peel)
	if not visual_root.has_node("SagingMesh"):
		var s_root := Node3D.new()
		s_root.name = "SagingMesh"
		var peel_mat := StandardMaterial3D.new()
		peel_mat.albedo_color = Color(0.96, 0.82, 0.12) # Banana yellow
		peel_mat.roughness = 0.4
		for i in range(3):
			var petal := MeshInstance3D.new()
			var c := CylinderMesh.new()
			c.top_radius = 0.02
			c.bottom_radius = 0.08
			c.height = 0.42
			petal.mesh = c
			petal.material_override = peel_mat
			petal.rotation_degrees = Vector3(55, i * 120.0, 0)
			petal.position = Vector3(0, 0.05, 0)
			s_root.add_child(petal)
		visual_root.add_child(s_root)

	# 3. Whistle Mesh (Barangay Referee Whistle)
	if not visual_root.has_node("WhistleMesh"):
		var w_root := Node3D.new()
		w_root.name = "WhistleMesh"
		var body := MeshInstance3D.new()
		var c := CylinderMesh.new()
		c.top_radius = 0.12
		c.bottom_radius = 0.12
		c.height = 0.16
		body.mesh = c
		body.rotation_degrees = Vector3(0, 0, 90)
		var met_mat := StandardMaterial3D.new()
		met_mat.albedo_color = Color(0.85, 0.2, 0.2) # Barangay Red Whistle
		met_mat.metallic = 0.6
		met_mat.roughness = 0.3
		body.material_override = met_mat
		w_root.add_child(body)

		var mouth := MeshInstance3D.new()
		var b := BoxMesh.new()
		b.size = Vector3(0.12, 0.08, 0.28)
		mouth.mesh = b
		mouth.position = Vector3(0, 0, 0.16)
		mouth.material_override = met_mat
		w_root.add_child(mouth)
		visual_root.add_child(w_root)

	# 4. Chalk Mesh (Bag of powdered chalk)
	if not visual_root.has_node("ChalkMesh"):
		var c_root := Node3D.new()
		c_root.name = "ChalkMesh"
		var sack := MeshInstance3D.new()
		var s := SphereMesh.new()
		s.radius = 0.2
		s.height = 0.35
		sack.mesh = s
		var chalk_mat := StandardMaterial3D.new()
		chalk_mat.albedo_color = Color(0.94, 0.94, 0.98)
		chalk_mat.roughness = 0.95
		sack.material_override = chalk_mat
		c_root.add_child(sack)
		visual_root.add_child(c_root)

	# 5. Ice Candy Mesh (Tied plastic tube)
	if not visual_root.has_node("IceCandyMesh"):
		var ic_root := Node3D.new()
		ic_root.name = "IceCandyMesh"
		var tube := MeshInstance3D.new()
		var cyl := CylinderMesh.new()
		cyl.top_radius = 0.06
		cyl.bottom_radius = 0.06
		cyl.height = 0.55
		tube.mesh = cyl
		var ic_mat := StandardMaterial3D.new()
		ic_mat.albedo_color = Color(1.0, 0.45, 0.15, 0.88) # Mango Ice Candy
		ic_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		ic_mat.roughness = 0.2
		tube.material_override = ic_mat
		tube.rotation_degrees = Vector3(45, 25, 0)
		ic_root.add_child(tube)
		visual_root.add_child(ic_root)

	_show_matching_mesh()
