class_name KagamitanUI
extends Control

## KagamitanUI (Wardrobe & Character Selection Screen)
## Dedicated screen matching user mockup with 3D turntable preview,
## 8-archetype cycling (< >), 3x3 color swatches, and Nickname editing.

signal closed
signal outfit_changed(outfit_data: Dictionary)
signal name_changed(new_name: String)

const CharacterModelScene = preload("res://scenes/player/CharacterModel.tscn")
const SAVE_PATH: String = "user://player_customization.cfg"

@onready var preview_sub_viewport: SubViewport = get_node_or_null("%PreviewSubViewport")
@onready var preview_model_root: Node3D = get_node_or_null("%PreviewModelRoot")
@onready var drag_area: Control = get_node_or_null("%DragArea")
@onready var nickname_input: LineEdit = get_node_or_null("%NicknameInput")
@onready var char_name_label: Label = get_node_or_null("%CharNameLabel")
@onready var char_title_label: Label = get_node_or_null("%CharTitleLabel")
@onready var btn_prev_char: TextureButton = get_node_or_null("%BtnPrevChar")
@onready var btn_next_char: TextureButton = get_node_or_null("%BtnNextChar")
@onready var color_grid: GridContainer = get_node_or_null("%ColorGrid")
@onready var btn_color_reset: Button = get_node_or_null("%BtnColorReset")
@onready var btn_close: TextureButton = get_node_or_null("%BtnClose")

var preview_model: Node3D = null
var current_archetype_idx: int = 0
var current_color_idx: int = 0
var player_nickname: String = "Totoy"

var is_dragging: bool = false
var last_drag_x: float = 0.0
var color_buttons: Array[Button] = []

func _init_node_references() -> void:
	if not preview_sub_viewport: preview_sub_viewport = get_node_or_null("%PreviewSubViewport") if has_node("%PreviewSubViewport") else get_node_or_null("LayoutHBox/PreviewContainer/SubViewportContainer/PreviewSubViewport")
	if not preview_model_root: preview_model_root = get_node_or_null("%PreviewModelRoot") if has_node("%PreviewModelRoot") else get_node_or_null("LayoutHBox/PreviewContainer/SubViewportContainer/PreviewSubViewport/World3D/PreviewModelRoot")
	if not drag_area: drag_area = get_node_or_null("%DragArea") if has_node("%DragArea") else get_node_or_null("LayoutHBox/PreviewContainer/DragArea")
	if not nickname_input: nickname_input = get_node_or_null("%NicknameInput") if has_node("%NicknameInput") else get_node_or_null("LayoutHBox/CardMargin/CustomCard/VBox/NicknameRow/NicknameInput")
	if not char_name_label: char_name_label = get_node_or_null("%CharNameLabel") if has_node("%CharNameLabel") else get_node_or_null("LayoutHBox/CardMargin/CustomCard/VBox/ArchetypeRow/CharTextVBox/CharNameLabel")
	if not char_title_label: char_title_label = get_node_or_null("%CharTitleLabel") if has_node("%CharTitleLabel") else get_node_or_null("LayoutHBox/CardMargin/CustomCard/VBox/ArchetypeRow/CharTextVBox/CharTitleLabel")
	if not btn_prev_char: btn_prev_char = get_node_or_null("%BtnPrevChar") if has_node("%BtnPrevChar") else get_node_or_null("LayoutHBox/CardMargin/CustomCard/VBox/ArchetypeRow/BtnPrevChar")
	if not btn_next_char: btn_next_char = get_node_or_null("%BtnNextChar") if has_node("%BtnNextChar") else get_node_or_null("LayoutHBox/CardMargin/CustomCard/VBox/ArchetypeRow/BtnNextChar")
	if not color_grid: color_grid = get_node_or_null("%ColorGrid") if has_node("%ColorGrid") else get_node_or_null("LayoutHBox/CardMargin/CustomCard/VBox/ColorGridCenter/ColorGrid")
	if not btn_color_reset: btn_color_reset = get_node_or_null("%BtnColorReset") if has_node("%BtnColorReset") else get_node_or_null("LayoutHBox/CardMargin/CustomCard/VBox/ColorGridCenter/ColorGrid/BtnColorReset")
	if not btn_close: btn_close = get_node_or_null("%BtnClose") if has_node("%BtnClose") else get_node_or_null("BtnClose")

func _ready() -> void:
	_init_node_references()
	_setup_signals()
	_setup_preview_model()
	_build_color_swatches()
	_load_saved_customization()
	_update_character_display()

func _process(delta: float) -> void:
	if not visible:
		return
	if preview_model and is_instance_valid(preview_model):
		if not is_dragging:
			preview_model.rotate_y(delta * 0.75)
		if preview_model.has_method("animate"):
			preview_model.animate(delta, 0.0, true, 7.0)

var _signals_connected: bool = false

func _setup_signals() -> void:
	if _signals_connected:
		return
	_signals_connected = true

	if btn_close and not btn_close.pressed.is_connected(close_kagamitan):
		btn_close.pressed.connect(func():
			_play_ui_sound()
			close_kagamitan()
		)
	if btn_prev_char:
		btn_prev_char.pressed.connect(func():
			_play_ui_sound()
			_change_archetype(-1)
		)
	if btn_next_char:
		btn_next_char.pressed.connect(func():
			_play_ui_sound()
			_change_archetype(1)
		)
	if btn_color_reset:
		btn_color_reset.pressed.connect(func():
			_play_ui_sound()
			_reset_to_default_color()
		)
	if nickname_input:
		nickname_input.text_changed.connect(_on_nickname_text_changed)
		nickname_input.text_submitted.connect(_on_nickname_text_submitted)
	if drag_area:
		drag_area.gui_input.connect(_on_drag_area_input)

func _setup_preview_model() -> void:
	if not preview_model_root:
		return
	if CharacterModelScene:
		preview_model = CharacterModelScene.instantiate() as Node3D
		preview_model.rotation.y = PI
		preview_model_root.add_child(preview_model)

func _build_color_swatches() -> void:
	if not color_grid:
		return
	color_buttons.clear()

	# Remove any existing swatch buttons except reset button
	for child in color_grid.get_children():
		if child != btn_color_reset:
			child.queue_free()

	for i in range(CharacterAnimator.COLOR_OPTIONS.size()):
		var col_info: Dictionary = CharacterAnimator.COLOR_OPTIONS[i]
		var col: Color = col_info.get("color", Color.WHITE)
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(64, 64)
		btn.focus_mode = Control.FOCUS_NONE
		btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		btn.tooltip_text = col_info.get("name", "Kulay")

		_style_swatch_button(btn, col, (i == current_color_idx))

		var idx := i
		btn.pressed.connect(func():
			_play_ui_sound()
			_select_color(idx)
		)

		color_buttons.append(btn)
		color_grid.add_child(btn)

	# Ensure reset button is placed as the 9th child (at bottom-right of 3x3)
	if btn_color_reset:
		btn_color_reset.get_parent().move_child(btn_color_reset, color_grid.get_child_count() - 1)
		_style_reset_button(btn_color_reset)

func _style_swatch_button(btn: Button, col: Color, is_selected: bool) -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = col
	sb.set_corner_radius_all(8)
	if is_selected:
		sb.set_border_width_all(3)
		sb.border_color = Color(1.0, 0.88, 0.20, 1.0) # Golden active border
		sb.shadow_color = Color(1.0, 0.88, 0.20, 0.4)
		sb.shadow_size = 3
	else:
		sb.set_border_width_all(2)
		sb.border_color = Color(1.0, 1.0, 1.0, 0.85) # Crisp white border
		sb.shadow_color = Color(0, 0, 0, 0.3)
		sb.shadow_size = 2

	var hover_sb := sb.duplicate() as StyleBoxFlat
	hover_sb.border_color = Color(1.0, 0.95, 0.5, 1.0)
	hover_sb.shadow_size = 4

	btn.add_theme_stylebox_override("normal", sb)
	btn.add_theme_stylebox_override("hover", hover_sb)
	btn.add_theme_stylebox_override("pressed", hover_sb)

func _style_reset_button(btn: Button) -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.08, 0.09, 0.12, 1.0)
	sb.set_corner_radius_all(8)
	sb.set_border_width_all(2)
	sb.border_color = Color(1.0, 1.0, 1.0, 0.85)
	sb.shadow_color = Color(0, 0, 0, 0.4)
	sb.shadow_size = 2

	var hover_sb := sb.duplicate() as StyleBoxFlat
	hover_sb.border_color = Color(1.0, 0.88, 0.20, 1.0)
	hover_sb.shadow_size = 4

	btn.add_theme_stylebox_override("normal", sb)
	btn.add_theme_stylebox_override("hover", hover_sb)
	btn.add_theme_stylebox_override("pressed", hover_sb)

func _change_archetype(delta: int) -> void:
	var total := CharacterAnimator.ARCHETYPES.size()
	current_archetype_idx = (current_archetype_idx + delta + total) % total
	var default_col: int = int(CharacterAnimator.ARCHETYPES[current_archetype_idx].get("color", 0))
	current_color_idx = default_col
	_update_character_display()
	_save_customization()

func _select_color(col_idx: int) -> void:
	current_color_idx = col_idx % CharacterAnimator.COLOR_OPTIONS.size()
	if preview_model and preview_model.has_method("set_player_color"):
		var col: Color = CharacterAnimator.COLOR_OPTIONS[current_color_idx]["color"]
		preview_model.set_player_color(col)
	_refresh_swatches()
	_save_customization()

func _reset_to_default_color() -> void:
	if current_archetype_idx >= 0 and current_archetype_idx < CharacterAnimator.ARCHETYPES.size():
		var default_col: int = int(CharacterAnimator.ARCHETYPES[current_archetype_idx].get("color", 0))
		_select_color(default_col)

func _update_character_display() -> void:
	if current_archetype_idx < 0 or current_archetype_idx >= CharacterAnimator.ARCHETYPES.size():
		current_archetype_idx = 0
	var arch_data: Dictionary = CharacterAnimator.ARCHETYPES[current_archetype_idx]

	if char_name_label:
		char_name_label.text = str(arch_data.get("name", "Tsuna")).to_upper()
	if char_title_label:
		char_title_label.text = "(%s)" % str(arch_data.get("title", "Anime Kid")).to_upper()

	if preview_model:
		if preview_model.has_method("apply_preset"):
			preview_model.apply_preset(current_archetype_idx)
		if preview_model.has_method("set_player_color"):
			var col: Color = CharacterAnimator.COLOR_OPTIONS[current_color_idx]["color"]
			preview_model.set_player_color(col)

	_refresh_swatches()

func _refresh_swatches() -> void:
	for i in range(color_buttons.size()):
		var btn: Button = color_buttons[i]
		if is_instance_valid(btn):
			var col: Color = CharacterAnimator.COLOR_OPTIONS[i]["color"]
			_style_swatch_button(btn, col, (i == current_color_idx))

func _on_nickname_text_changed(new_text: String) -> void:
	player_nickname = new_text.strip_edges()
	_save_customization()
	name_changed.emit(player_nickname)

func _on_nickname_text_submitted(new_text: String) -> void:
	player_nickname = new_text.strip_edges()
	_save_customization()
	name_changed.emit(player_nickname)
	if nickname_input:
		nickname_input.release_focus()

func _on_drag_area_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT:
			is_dragging = mb.pressed
			last_drag_x = mb.position.x
	elif event is InputEventMouseMotion and is_dragging:
		var mm := event as InputEventMouseMotion
		var dx := mm.position.x - last_drag_x
		last_drag_x = mm.position.x
		if preview_model and is_instance_valid(preview_model):
			preview_model.rotate_y(dx * 0.015)
	elif event is InputEventScreenTouch:
		var st := event as InputEventScreenTouch
		is_dragging = st.pressed
		last_drag_x = st.position.x
	elif event is InputEventScreenDrag and is_dragging:
		var sd := event as InputEventScreenDrag
		if preview_model and is_instance_valid(preview_model):
			preview_model.rotate_y(sd.relative.x * 0.015)

func open_kagamitan() -> void:
	_init_node_references()
	_setup_signals()
	if not preview_model:
		_setup_preview_model()
	if color_buttons.is_empty():
		_build_color_swatches()
	_load_saved_customization()
	_update_character_display()
	visible = true

func close_kagamitan() -> void:
	_save_customization()
	visible = false
	closed.emit()

func _load_saved_customization() -> void:
	var cfg := ConfigFile.new()
	var err := cfg.load(SAVE_PATH)
	if err == OK:
		player_nickname = cfg.get_value("player", "name", "Totoy")
		if player_nickname.to_lower() == "dennrick" or player_nickname.to_lower() == "kuya denn" or player_nickname.is_empty():
			player_nickname = "Totoy"
		if cfg.has_section("outfit"):
			current_archetype_idx = cfg.get_value("outfit", "archetype", 0)
			current_color_idx = cfg.get_value("outfit", "color", 0)
	if nickname_input:
		nickname_input.text = player_nickname

func _save_customization() -> void:
	var cfg := ConfigFile.new()
	var _e := cfg.load(SAVE_PATH)
	cfg.set_value("player", "name", player_nickname)
	cfg.set_value("outfit", "archetype", current_archetype_idx)
	cfg.set_value("outfit", "color", current_color_idx)
	cfg.save(SAVE_PATH)

	outfit_changed.emit({
		"archetype": current_archetype_idx,
		"color": current_color_idx,
		"name": player_nickname
	})

func _play_ui_sound() -> void:
	var am = get_node_or_null("/root/AudioManager")
	if am and am.has_method("play_ui_click"):
		am.play_ui_click()
