class_name MobileControls
extends Control

signal camera_dragged(relative_vec: Vector2)
signal jump_pressed()
signal vault_pressed()
signal sprint_toggled(is_sprinting: bool)
signal slide_pressed()
signal dash_pressed()
signal tag_pressed()
signal interact_pressed()
signal drop_pressed()
signal item_pressed()
signal item_released()
signal prev_spectate_pressed()
signal next_spectate_pressed()

enum LayoutPreset {
	DEFAULT = 0,
	LEFT_HANDED = 1,
	COMPACT = 2
}

var current_preset: int = LayoutPreset.DEFAULT

@onready var joystick: KalyeVirtualJoystick = $LeftTouchZone/VirtualJoystick
@onready var left_touch_zone: Control = $LeftTouchZone
@onready var camera_touch_zone: Control = $RightTouchZone
@onready var action_buttons: Control = $ActionButtons
@onready var btn_jump: Button = $ActionButtons/BtnJump
var jump_label: Button:
	get: return btn_jump
@onready var btn_sprint: Button = $ActionButtons/BtnSprint
@onready var btn_slide: Button = $ActionButtons/BtnSlide
@onready var btn_dash: Button = $ActionButtons/BtnDash
@onready var btn_tag: Button = $ActionButtons/BtnTag
@onready var btn_interact: Button = get_node_or_null("ActionButtons/BtnInteract")
@onready var btn_drop: Button = get_node_or_null("ActionButtons/BtnDrop")
@onready var btn_item: Button = get_node_or_null("ActionButtons/BtnItem")

# Spectator Controls
@onready var spectator_controls: Control = get_node_or_null("SpectatorControls")
@onready var btn_prev_spectate: Button = get_node_or_null("SpectatorControls/BtnPrevSpectate")
@onready var btn_next_spectate: Button = get_node_or_null("SpectatorControls/BtnNextSpectate")

var camera_touch_id: int = -1
var is_sprinting: bool = false
var is_spectator: bool = false
var is_vault_available: bool = false

func _ready() -> void:
	add_to_group("mobile_controls")
	var buttons: Array[Button] = [btn_jump, btn_sprint, btn_slide, btn_dash, btn_tag, btn_interact, btn_drop, btn_item]
	if btn_prev_spectate: buttons.append(btn_prev_spectate)
	if btn_next_spectate: buttons.append(btn_next_spectate)
	
	for b in buttons:
		if b:
			_setup_button_juice(b)

	if btn_jump:
		btn_jump.pressed.connect(func():
			if is_vault_available:
				vault_pressed.emit()
			jump_pressed.emit()
		)
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
		btn_item.button_down.connect(func(): item_pressed.emit())
		btn_item.button_up.connect(func(): item_released.emit())
	if btn_prev_spectate:
		btn_prev_spectate.pressed.connect(func(): prev_spectate_pressed.emit())
	if btn_next_spectate:
		btn_next_spectate.pressed.connect(func(): next_spectate_pressed.emit())

	if camera_touch_zone:
		camera_touch_zone.gui_input.connect(_on_camera_zone_input)

	update_powerup_buttons(0, 0)
	set_interact_prompt(false, "", "")
	set_drop_button_visible(false)
	set_tag_button_highlight(false)
	set_item_button_visible(false)
	set_spectator_mode(false)

	_adapt_display_safe_area()
	if get_tree() and get_tree().root:
		get_tree().root.size_changed.connect(_adapt_display_safe_area)

	var gm = get_node_or_null("/root/Main")
	if gm and "settings_data" in gm:
		set_joystick_mode(int(gm.settings_data.get("joystick_style", 0)))
		set_ui_scale(float(gm.settings_data.get("touch_ui_scale", 1.0)))

func trigger_haptic(duration_ms: int = 18) -> void:
	var gm = get_node_or_null("/root/Main")
	if gm and gm.has_method("is_vibration_enabled") and not gm.is_vibration_enabled():
		return
	if Input.has_method("vibrate_handheld"):
		Input.vibrate_handheld(duration_ms)

func _setup_button_juice(btn: Button) -> void:
	btn.pivot_offset = btn.custom_minimum_size * 0.5
	btn.button_down.connect(func():
		trigger_haptic(18)
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
		if is_vault_available:
			btn_jump.text = "VAULT"
			btn_jump.modulate = Color(1.0, 0.88, 0.25)
		elif powerup_type == 3: # DOUBLE_JUMP
			btn_jump.text = "2x TALON"
			btn_jump.modulate = Color(0.7, 1.0, 0.8, 1.0)
		else:
			btn_jump.text = "TALON"
			btn_jump.modulate = Color(1.0, 1.0, 1.0, 1.0)

func set_vault_available(available: bool) -> void:
	is_vault_available = available
	if btn_jump:
		if is_vault_available:
			btn_jump.text = "VAULT"
			btn_jump.modulate = Color(1.0, 0.88, 0.25)
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

func set_spectator_mode(active: bool) -> void:
	is_spectator = active
	if action_buttons:
		action_buttons.visible = not active
	if left_touch_zone:
		left_touch_zone.visible = not active
	if spectator_controls:
		spectator_controls.visible = active

func set_tag_in_range(in_range: bool) -> void:
	if not btn_tag or not btn_tag.visible or is_spectator:
		return
	if in_range:
		btn_tag.text = "🔥 HAMPASIN!"
		btn_tag.modulate = Color(1.0, 0.9, 0.2, 1.0)
	else:
		btn_tag.text = "HAMPAS"
		btn_tag.modulate = Color(1.0, 1.0, 1.0, 1.0)

func set_layout_preset(preset: int) -> void:
	current_preset = preset as LayoutPreset
	if not left_touch_zone or not action_buttons:
		return
	match current_preset:
		LayoutPreset.DEFAULT:
			left_touch_zone.anchor_left = 0.0
			left_touch_zone.anchor_right = 0.4
			action_buttons.anchor_left = 0.55
			action_buttons.anchor_right = 0.98
			scale = Vector2.ONE
		LayoutPreset.LEFT_HANDED:
			# Invert sides: joystick right, buttons left
			left_touch_zone.anchor_left = 0.6
			left_touch_zone.anchor_right = 1.0
			action_buttons.anchor_left = 0.02
			action_buttons.anchor_right = 0.45
			scale = Vector2.ONE
		LayoutPreset.COMPACT:
			left_touch_zone.anchor_left = 0.0
			left_touch_zone.anchor_right = 0.35
			action_buttons.anchor_left = 0.65
			action_buttons.anchor_right = 0.98
			scale = Vector2(0.85, 0.85)

func set_ui_scale(new_scale: float) -> void:
	var clamped := clampf(new_scale, 0.6, 1.4)
	scale = Vector2(clamped, clamped)

func set_ui_opacity(new_opacity: float) -> void:
	modulate.a = clampf(new_opacity, 0.2, 1.0)

func set_joystick_mode(mode: int) -> void:
	if joystick and joystick.has_method("set_joystick_mode"):
		joystick.set_joystick_mode(mode)

func _adapt_display_safe_area() -> void:
	if not is_inside_tree():
		return
	var vp_size: Vector2 = get_viewport_rect().size
	if vp_size.x <= 0.0 or vp_size.y <= 0.0:
		return

	var safe_rect: Rect2i = DisplayServer.get_display_safe_area()
	if safe_rect.size.x <= 0 or safe_rect.size.y <= 0:
		return

	var window_size: Vector2i = DisplayServer.window_get_size()
	if window_size.x <= 0 or window_size.y <= 0:
		return

	var scale_x: float = vp_size.x / float(window_size.x)
	var scale_y: float = vp_size.y / float(window_size.y)

	var margin_left: float = float(safe_rect.position.x) * scale_x
	var margin_right: float = float(window_size.x - (safe_rect.position.x + safe_rect.size.x)) * scale_x
	var margin_bottom: float = float(window_size.y - (safe_rect.position.y + safe_rect.size.y)) * scale_y

	# Apply safe margins to touch zones so phone cutouts / curved corners don't clip controls
	if left_touch_zone:
		left_touch_zone.offset_left = maxf(margin_left, 0.0)
		left_touch_zone.offset_bottom = -maxf(margin_bottom, 0.0)
	if action_buttons:
		action_buttons.offset_right = -maxf(margin_right, 0.0)
		action_buttons.offset_bottom = -maxf(margin_bottom, 0.0)
