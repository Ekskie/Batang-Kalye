class_name KalyeVirtualJoystick
extends Control

signal joystick_moved(vector: Vector2)
signal joystick_released()

@export var max_range: float = 65.0
@export var base_color: Color = Color(1.0, 1.0, 1.0, 0.25)
@export var knob_color: Color = Color(1.0, 0.8, 0.2, 0.75)
@export var deadzone: float = 0.15

var touch_id: int = -1
var center_pos: Vector2 = Vector2.ZERO
var current_pos: Vector2 = Vector2.ZERO
var output_vector: Vector2 = Vector2.ZERO
var is_active: bool = false

func _ready() -> void:
	center_pos = size * 0.5
	current_pos = center_pos

func _draw() -> void:
	var c := size * 0.5
	# Outer base circle
	draw_circle(c, max_range, base_color)
	draw_arc(c, max_range, 0, TAU, 32, Color(1, 1, 1, 0.4), 2.0)
	# Inner knob circle
	var knob_center := center_pos if not is_active else current_pos
	draw_circle(knob_center, max_range * 0.45, knob_color)
	draw_arc(knob_center, max_range * 0.45, 0, TAU, 24, Color(1, 1, 1, 0.8), 2.0)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed and touch_id == -1:
			touch_id = event.index
			is_active = true
			_update_knob_position(event.position)
		elif not event.pressed and event.index == touch_id:
			_reset_joystick()
	elif event is InputEventScreenDrag and event.index == touch_id:
		_update_knob_position(event.position)
	elif event is InputEventMouseButton and Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed and touch_id == -1:
				touch_id = 999
				is_active = true
				_update_knob_position(event.position)
			elif not event.pressed and touch_id == 999:
				_reset_joystick()
	elif event is InputEventMouseMotion and touch_id == 999 and Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		_update_knob_position(event.position)

func _update_knob_position(touch_pos: Vector2) -> void:
	var diff := touch_pos - (size * 0.5)
	if diff.length() > max_range:
		diff = diff.normalized() * max_range
	current_pos = (size * 0.5) + diff

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
	current_pos = size * 0.5
	output_vector = Vector2.ZERO
	joystick_released.emit()
	queue_redraw()

func get_vector() -> Vector2:
	return output_vector
