class_name TrashItem
extends Node3D

enum TrashType {
	PLASTIC_BOTTLE = 0,
	TIN_CAN = 1,
	BANANA_PEEL = 2,
	CANDY_WRAPPER = 3
}

enum BinCategory {
	RECYCLABLE = 0,     # Blue
	BIODEGRADABLE = 1,  # Green
	NON_BIO = 2         # Yellow
}

@export var trash_type: TrashType = TrashType.PLASTIC_BOTTLE:
	set(value):
		trash_type = value
		if is_inside_tree():
			_update_visuals()

@export var respawn_time: float = 12.0
var is_collected: bool = false
var respawn_timer: float = 0.0

@onready var visual_root: Node3D = $VisualRoot
@onready var bottle_mesh: Node3D = $VisualRoot/BottleMesh
@onready var can_mesh: Node3D = $VisualRoot/CanMesh
@onready var peel_mesh: Node3D = $VisualRoot/PeelMesh
@onready var wrapper_mesh: Node3D = $VisualRoot/WrapperMesh
@onready var label: Label3D = $Label3D
@onready var area: Area3D = $Area3D

var anim_time: float = 0.0
var base_y: float = 0.35

func _ready() -> void:
	base_y = visual_root.position.y
	_update_visuals()
	area.body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	if is_collected:
		respawn_timer -= delta
		if respawn_timer <= 0.0:
			respawn()
		return

	# Gentle floating and spinning
	anim_time += delta * 2.8
	visual_root.position.y = base_y + sin(anim_time) * 0.08
	visual_root.rotate_y(delta * 2.0)

func _update_visuals() -> void:
	if not is_inside_tree():
		return
	if bottle_mesh: bottle_mesh.visible = (trash_type == TrashType.PLASTIC_BOTTLE)
	if can_mesh: can_mesh.visible = (trash_type == TrashType.TIN_CAN)
	if peel_mesh: peel_mesh.visible = (trash_type == TrashType.BANANA_PEEL)
	if wrapper_mesh: wrapper_mesh.visible = (trash_type == TrashType.CANDY_WRAPPER)

	if label:
		label.text = get_item_name() + "\n" + get_bin_hint()

func get_item_name() -> String:
	match trash_type:
		TrashType.PLASTIC_BOTTLE:
			return "🍾 Bote ng Tubig"
		TrashType.TIN_CAN:
			return "🥫 Lata ng Sardinas"
		TrashType.BANANA_PEEL:
			return "🍌 Balat ng Saging"
		TrashType.CANDY_WRAPPER:
			return "🍬 Balat ng Kendi"
	return "Basura"

func get_bin_category() -> BinCategory:
	match trash_type:
		TrashType.PLASTIC_BOTTLE, TrashType.TIN_CAN:
			return BinCategory.RECYCLABLE
		TrashType.BANANA_PEEL:
			return BinCategory.BIODEGRADABLE
		TrashType.CANDY_WRAPPER:
			return BinCategory.NON_BIO
	return BinCategory.RECYCLABLE

func get_bin_hint() -> String:
	match get_bin_category():
		BinCategory.RECYCLABLE:
			return "[Asul: Recyclable]"
		BinCategory.BIODEGRADABLE:
			return "[Berde: Nabubulok]"
		BinCategory.NON_BIO:
			return "[Dilaw: Di-Nabubulok]"
	return ""

func _on_body_entered(body: Node3D) -> void:
	if is_collected:
		return
	if body is PlayerController and body.has_method("pickup_trash"):
		var accepted: bool = body.pickup_trash(self)
		if accepted:
			collect()

func collect() -> void:
	is_collected = true
	respawn_timer = respawn_time
	visible = false
	if area:
		area.monitoring = false

func respawn() -> void:
	is_collected = false
	visible = true
	if area:
		area.monitoring = true
	# Randomize trash type on respawn for variety
	trash_type = (randi() % 4) as TrashType
	_update_visuals()
