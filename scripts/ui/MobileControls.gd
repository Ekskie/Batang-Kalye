class_name MobileControls
extends Control

signal camera_dragged(relative_vec: Vector2)
signal jump_pressed()
signal sprint_toggled(is_sprinting: bool)
signal slide_pressed()
signal dash_pressed()
signal tag_pressed()
signal powerup_pressed()

@onready var joystick: KalyeVirtualJoystick = $LeftTouchZone/VirtualJoystick
@onready var camera_touch_zone: Control = $RightTouchZone
@onready var btn_jump: Button = $ActionButtons/BtnJump
@onready var btn_sprint: Button = $ActionButtons/BtnSprint
@onready var btn_slide: Button = $ActionButtons/BtnSlide
@onready var btn_dash: Button = $ActionButtons/BtnDash
@onready var btn_tag: Button = $ActionButtons/BtnTag
@onready var btn_powerup: Button = $ActionButtons/BtnPowerup

var camera_touch_id: int = -1
var is_sprinting: bool = false

func _ready() -> void:
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
	if btn_powerup:
		btn_powerup.pressed.connect(func(): powerup_pressed.emit())

	if camera_touch_zone:
		camera_touch_zone.gui_input.connect(_on_camera_zone_input)

	update_powerup_buttons(0, 0)

func _on_sprint_toggled(button_pressed: bool) -> void:
	is_sprinting = button_pressed
	sprint_toggled.emit(is_sprinting)
	if is_sprinting:
		btn_sprint.text = "⚡ SPRINTING"
	else:
		btn_sprint.text = "🏃 SPRINT"

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
			btn_tag.text = "🔥 HAMPAS (TAG!)"
			btn_tag.modulate = Color(1.0, 0.3, 0.2)
		else:
			btn_tag.text = "✋ IWAS / DEFLECT"
			btn_tag.modulate = Color(0.3, 0.8, 1.0)

func on_powerup_changed(powerup_type: int, _duration_left: float, charges: int) -> void:
	update_powerup_buttons(powerup_type, charges)

func update_powerup_buttons(powerup_type: int, dash_charges: int) -> void:
	if btn_dash:
		if powerup_type == 1 and dash_charges > 0: # DASH
			btn_dash.text = "⚡ DASH (%d)" % dash_charges
			btn_dash.modulate = Color(0.2, 0.95, 1.0, 1.0)
		else:
			btn_dash.text = "🔒 DASH"
			btn_dash.modulate = Color(0.7, 0.7, 0.7, 0.5)

	if btn_jump:
		if powerup_type == 3: # DOUBLE_JUMP
			btn_jump.text = "🦘 2x JUMP"
			btn_jump.modulate = Color(0.3, 1.0, 0.5, 1.0)
		else:
			btn_jump.text = "⬆ JUMP"
			btn_jump.modulate = Color(1.0, 1.0, 1.0, 1.0)
