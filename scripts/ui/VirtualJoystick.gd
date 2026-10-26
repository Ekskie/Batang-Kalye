class_name KalyeVirtualJoystick
extends Control

signal joystick_moved(vector: Vector2)
signal joystick_released()

enum JoystickMode {
	DYNAMIC = 0, # Floating: recenters under thumb anywhere in touch zone
	FIXED = 1    # Static: stays at default center position
}

@export_group("Textures")
@export var texture_boundary: Texture2D = preload("res://assets/Game Icons-Buttons/Joystick/JoystickBoundery.png")
@export var texture_knob: Texture2D = preload("res://assets/Game Icons-Buttons/Joystick/joystickCenter.png")

@export_group("Dimensions & Physics")
@export var joystick_mode: JoystickMode = JoystickMode.DYNAMIC
@export var boundary_size: Vector2 = Vector2(200.0, 200.0)
@export var knob_size: Vector2 = Vector2(110.0, 110.0)
@export var max_range: float = 75.0
@export var deadzone: float = 0.15
@export var idle_opacity: float = 0.50
@export var active_opacity: float = 1.0
@export var default_offset_from_bottom_left: Vector2 = Vector2(145.0, 145.0)

@export_group("Fallback Colors")
@export var base_color: Color = Color(0.08, 0.10, 0.15, 0.45)
@export var knob_color: Color = Color(0.85, 0.88, 0.92, 0.65)

var touch_id: int = -1
var default_center: Vector2 = Vector2.ZERO
var center_pos: Vector2 = Vector2.ZERO
var current_pos: Vector2 = Vector2.ZERO
var output_vector: Vector2 = Vector2.ZERO
var is_active: bool = false
var _reset_tween: Tween = null

func _ready() -> void:
	_update_default_center()
	resized.connect(_on_resized)

func _on_resized() -> void:
	_update_default_center()
	if not is_active:
		center_pos = default_center
		current_pos = default_center
		queue_redraw()

func _update_default_center() -> void:
	if size.x > default_offset_from_bottom_left.x * 1.5 and size.y > default_offset_from_bottom_left.y * 1.5:
		default_center = Vector2(default_offset_from_bottom_left.x, size.y - default_offset_from_bottom_left.y)
	else:
		default_center = size * 0.5
	if not is_active:
		center_pos = default_center
		current_pos = default_center

func set_joystick_mode(mode: int) -> void:
	joystick_mode = mode as JoystickMode
	_reset_joystick()

func _draw() -> void:
	var alpha_factor: float = active_opacity if is_active else idle_opacity

	if texture_boundary and texture_knob:
		# Draw boundary texture (frame + directional arrows)
		var b_col := Color(1.0, 1.0, 1.0, alpha_factor)
		var b_rect := Rect2(center_pos - boundary_size * 0.5, boundary_size)
		draw_texture_rect(texture_boundary, b_rect, false, b_col)

		# Draw knob texture (3D shaded center sphere)
		var k_col := Color(1.0, 1.0, 1.0, alpha_factor)
		var k_rect := Rect2(current_pos - knob_size * 0.5, knob_size)
		draw_texture_rect(texture_knob, k_rect, false, k_col)
	else:
		# Fallback vector circles if textures are unavailable
		var c := center_pos
		var b_col := base_color
		b_col.a *= alpha_factor
		draw_circle(c, max_range, b_col)
		draw_arc(c, max_range, 0, TAU, 36, Color(1.0, 1.0, 1.0, 0.25 * alpha_factor), 2.0)
		draw_arc(c, max_range * deadzone, 0, TAU, 24, Color(1.0, 1.0, 1.0, 0.10 * alpha_factor), 1.0)

		var knob_c := current_pos
		var k_col := knob_color
		k_col.a *= (1.0 if is_active else 0.5)
		draw_circle(knob_c, max_range * 0.42, k_col)
		draw_arc(knob_c, max_range * 0.42, 0, TAU, 28, Color(1.0, 1.0, 1.0, 0.85 * alpha_factor), 2.0)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed and touch_id == -1:
			touch_id = event.index
			_start_touch(event.position)
		elif not event.pressed and event.index == touch_id:
			_reset_joystick()
	elif event is InputEventScreenDrag and event.index == touch_id:
		_update_knob_position(event.position)
	elif event is InputEventMouseButton and Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed and touch_id == -1:
				touch_id = 999
				_start_touch(event.position)
			elif not event.pressed and touch_id == 999:
				_reset_joystick()
	elif event is InputEventMouseMotion and touch_id == 999 and Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		_update_knob_position(event.position)

func _start_touch(touch_pos: Vector2) -> void:
	if _reset_tween and _reset_tween.is_valid():
		_reset_tween.kill()

	is_active = true
	if joystick_mode == JoystickMode.DYNAMIC:
		# Floating mode: recenter base directly under user thumb
		center_pos = touch_pos
		current_pos = touch_pos
		output_vector = Vector2.ZERO
	else:
		# Fixed mode: base stays at default center
		center_pos = default_center
		_update_knob_position(touch_pos)
	queue_redraw()

func _update_knob_position(touch_pos: Vector2) -> void:
	var diff := touch_pos - center_pos
	if diff.length() > max_range:
		diff = diff.normalized() * max_range
	current_pos = center_pos + diff

	var raw_vec := diff / max_range
	if raw_vec.length() < deadzone:
		output_vector = Vector2.ZERO
	else:
		output_vector = raw_vec

	joystick_moved.emit(output_vector)
	queue_redraw()

func _reset_joystick() -> void:
	touch_id = -1
	is_active = false
	output_vector = Vector2.ZERO
	joystick_released.emit()

	if _reset_tween and _reset_tween.is_valid():
		_reset_tween.kill()

	if joystick_mode == JoystickMode.DYNAMIC and center_pos != default_center:
		_reset_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		_reset_tween.tween_property(self, "center_pos", default_center, 0.2)
		_reset_tween.tween_property(self, "current_pos", default_center, 0.2)
		_reset_tween.tween_method(func(_v: float): queue_redraw(), 0.0, 1.0, 0.2)
	else:
		current_pos = center_pos
		queue_redraw()

func get_vector() -> Vector2:
	return output_vector
