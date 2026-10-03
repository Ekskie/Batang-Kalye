class_name MobileControls
extends Control

signal camera_dragged(relative_vec: Vector2)
signal jump_pressed()
signal sprint_toggled(is_sprinting: bool)
signal slide_pressed()
signal dash_pressed()
signal tag_pressed()
signal interact_pressed()
signal drop_pressed()
signal item_pressed()

@onready var joystick: KalyeVirtualJoystick = $LeftTouchZone/VirtualJoystick
@onready var camera_touch_zone: Control = $RightTouchZone
@onready var btn_jump: Button = $ActionButtons/BtnJump
@onready var btn_sprint: Button = $ActionButtons/BtnSprint
@onready var btn_slide: Button = $ActionButtons/BtnSlide
@onready var btn_dash: Button = $ActionButtons/BtnDash
@onready var btn_tag: Button = $ActionButtons/BtnTag
@onready var btn_interact: Button = get_node_or_null("ActionButtons/BtnInteract")
@onready var btn_drop: Button = get_node_or_null("ActionButtons/BtnDrop")
@onready var btn_item: Button = get_node_or_null("ActionButtons/BtnItem")

var camera_touch_id: int = -1
var is_sprinting: bool = false

func _ready() -> void:
	var buttons: Array[Button] = [btn_jump, btn_sprint, btn_slide, btn_dash, btn_tag, btn_interact, btn_drop, btn_item]
	for b in buttons:
		if b:
			_setup_button_juice(b)

	if btn_jump:
		btn_jump.pressed.connect(func(): jump_pressed.emit())
	if btn_sprint:
		btn_sprint.toggled.connect(_on_sprint_toggled)
	if btn_slide:
		btn_slide.pressed.connect(func(): slide_pressed.emit())
	if btn_dash:
		btn_dash.pressed.connect(func(): dash_pressed.emit())
	if btn_tag:
		btn_tag.pressed.connect(func(): tag_pressed.emit())
	if btn_interact:
		btn_interact.pressed.connect(func(): interact_pressed.emit())
	if btn_drop:
		btn_drop.pressed.connect(func(): drop_pressed.emit())
	if btn_item:
		btn_item.pressed.connect(func(): item_pressed.emit())

	if camera_touch_zone:
		camera_touch_zone.gui_input.connect(_on_camera_zone_input)

	update_powerup_buttons(0, 0)
	set_interact_prompt(false, "", "")
	set_drop_button_visible(false)
	set_tag_button_highlight(false)
	set_item_button_visible(false)

func _setup_button_juice(btn: Button) -> void:
	btn.pivot_offset = btn.custom_minimum_size * 0.5
	btn.button_down.connect(func():
		var tw := btn.create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.tween_property(btn, "scale", Vector2(0.92, 0.92), 0.05)
	)
	btn.button_up.connect(func():
		var tw := btn.create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_property(btn, "scale", Vector2(1.0, 1.0), 0.12)
	)

func _on_sprint_toggled(button_pressed: bool) -> void:
	is_sprinting = button_pressed
	sprint_toggled.emit(is_sprinting)
	if is_sprinting:
		btn_sprint.text = "SPRINTING"
		btn_sprint.modulate = Color(1.0, 0.92, 0.45, 1.0)
	else:
		btn_sprint.text = "SPRINT"
		btn_sprint.modulate = Color(1.0, 1.0, 1.0, 1.0)

func set_sprint_disabled(disabled: bool) -> void:
	if btn_sprint:
		if disabled:
			btn_sprint.button_pressed = false
			is_sprinting = false
			btn_sprint.text = "PAGOD"
			btn_sprint.modulate = Color(0.65, 0.65, 0.65, 0.5)
			btn_sprint.disabled = true
		else:
			if btn_sprint.disabled:
				btn_sprint.disabled = false
				btn_sprint.modulate = Color(1.0, 1.0, 1.0, 1.0)
				btn_sprint.text = "SPRINT"

func _on_camera_zone_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed and camera_touch_id == -1:
			camera_touch_id = event.index
		elif not event.pressed and event.index == camera_touch_id:
			camera_touch_id = -1
	elif event is InputEventScreenDrag and event.index == camera_touch_id:
		camera_dragged.emit(event.relative)

func get_movement_vector() -> Vector2:
	if joystick:
		return joystick.get_vector()
	return Vector2.ZERO

func set_tag_button_highlight(is_taya: bool) -> void:
	if btn_tag:
		if is_taya:
			btn_tag.visible = true
			btn_tag.text = "HAMPAS"
			btn_tag.modulate = Color(1.0, 1.0, 1.0, 1.0)
		else:
			btn_tag.visible = false

func on_powerup_changed(powerup_type: int, _duration_left: float, charges: int) -> void:
	update_powerup_buttons(powerup_type, charges)

func update_powerup_buttons(powerup_type: int, dash_charges: int) -> void:
	if btn_dash:
		if powerup_type == 1 and dash_charges > 0: # DASH
			btn_dash.text = "DASH (%d)" % dash_charges
			btn_dash.modulate = Color(0.6, 0.9, 1.0, 1.0)
		else:
			btn_dash.text = "DASH"
			btn_dash.modulate = Color(0.65, 0.65, 0.65, 0.4)

	if btn_jump:
		if powerup_type == 3: # DOUBLE_JUMP
			btn_jump.text = "2x TALON"
			btn_jump.modulate = Color(0.7, 1.0, 0.8, 1.0)
		else:
			btn_jump.text = "TALON"
			btn_jump.modulate = Color(1.0, 1.0, 1.0, 1.0)

# --- Contextual Interaction Prompt for Mobile ---
func set_interact_prompt(p_visible: bool, _icon: String, action_text: String) -> void:
	if btn_interact:
		btn_interact.visible = p_visible
		if p_visible:
			btn_interact.text = action_text.to_upper()

func set_drop_button_visible(p_visible: bool) -> void:
	if btn_drop:
		btn_drop.visible = p_visible

func set_item_button_visible(p_visible: bool, item_name: String = "BATO") -> void:
	if btn_item:
		btn_item.visible = p_visible
		if p_visible:
			btn_item.text = item_name.to_upper()
