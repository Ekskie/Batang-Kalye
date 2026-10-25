class_name GameOverUI
extends Control

## GameOverUI (Uwian Na! Minimalist Match Results)
## Displays a clean, spacious post-match leaderboard, 3D MVP Champion showcase,
## match earnings, and modern action buttons in our cohesive street celebration aesthetic.

signal rematch_requested
signal store_requested
signal lobby_requested

const CharacterModelScene = preload("res://scenes/player/CharacterModel.tscn")
const LilitaFont = preload("res://assets/fonts/LilitaOne-Regular.ttf")

@onready var bg_texture: TextureRect = get_node_or_null("BgTexture")
@onready var mode_label: Label = get_node_or_null("Margin/MainVBox/HeaderBar/RightHeaderChips/ModeChip/ModeLabel")
@onready var meta_summary_label: Label = get_node_or_null("Margin/MainVBox/HeaderBar/RightHeaderChips/MetaChip/MetaSummaryLabel")
@onready var rows_container: VBoxContainer = get_node_or_null("Margin/MainVBox/MainHBox/LeftColumn/TablePanel/Margin/VBox/ScrollContainer/RowsContainer")

# Top Player (MVP) 3D Viewport & Details
@onready var mvp_preview_root: Node3D = get_node_or_null("%MvpPreviewRoot")
@onready var mvp_role_badge: Label = get_node_or_null("Margin/MainVBox/MainHBox/RightColumn/TopPlayerCard/VBox/RoleBadge")
@onready var mvp_name_label: Label = get_node_or_null("Margin/MainVBox/MainHBox/RightColumn/TopPlayerCard/VBox/NameLabel")
@onready var earnings_val_label: Label = get_node_or_null("Margin/MainVBox/MainHBox/RightColumn/TopPlayerCard/VBox/EarningsPill/EarningsValue")

# Action Buttons
@onready var btn_rematch: Button = get_node_or_null("Margin/MainVBox/MainHBox/RightColumn/ButtonsHBox/BtnRematch")
@onready var btn_lobby: Button = get_node_or_null("Margin/MainVBox/MainHBox/RightColumn/ButtonsHBox/BtnLobby")
@onready var btn_store: Button = get_node_or_null("Margin/MainVBox/MainHBox/RightColumn/BtnStore")

var mvp_model: Node3D = null

const PORTRAITS: Dictionary = {
	0: preload("res://assets/portraits/portrait_tsuna.jpg"),
	1: preload("res://assets/portraits/portrait_kalbo.jpg"),
	2: preload("res://assets/portraits/portrait_totoy.jpg"),
	3: preload("res://assets/portraits/portrait_nene.jpg"),
	4: preload("res://assets/portraits/portrait_tisoy.jpg"),
	5: preload("res://assets/portraits/portrait_baldo.jpg"),
	6: preload("res://assets/portraits/portrait_nonoy.jpg"),
	7: preload("res://assets/portraits/portrait_kikay.jpg")
}
const DEFAULT_PORTRAIT: Texture2D = preload("res://assets/portraits/portrait_mvp.jpg")

func _init_node_references() -> void:
	if not bg_texture: bg_texture = get_node_or_null("BgTexture")
	if not mode_label: mode_label = get_node_or_null("Margin/MainVBox/HeaderBar/RightHeaderChips/ModeChip/ModeLabel")
	if not meta_summary_label: meta_summary_label = get_node_or_null("Margin/MainVBox/HeaderBar/RightHeaderChips/MetaChip/MetaSummaryLabel")
	if not rows_container: rows_container = get_node_or_null("Margin/MainVBox/MainHBox/LeftColumn/TablePanel/Margin/VBox/ScrollContainer/RowsContainer")
	if not mvp_preview_root: mvp_preview_root = get_node_or_null("%MvpPreviewRoot")
	if not mvp_role_badge: mvp_role_badge = get_node_or_null("Margin/MainVBox/MainHBox/RightColumn/TopPlayerCard/VBox/RoleBadge")
	if not mvp_name_label: mvp_name_label = get_node_or_null("Margin/MainVBox/MainHBox/RightColumn/TopPlayerCard/VBox/NameLabel")
	if not earnings_val_label: earnings_val_label = get_node_or_null("Margin/MainVBox/MainHBox/RightColumn/TopPlayerCard/VBox/EarningsPill/EarningsValue")
	if not btn_rematch: btn_rematch = get_node_or_null("Margin/MainVBox/MainHBox/RightColumn/ButtonsHBox/BtnRematch")
	if not btn_lobby: btn_lobby = get_node_or_null("Margin/MainVBox/MainHBox/RightColumn/ButtonsHBox/BtnLobby")
	if not btn_store: btn_store = get_node_or_null("Margin/MainVBox/MainHBox/RightColumn/BtnStore")

func _ready() -> void:
	_init_node_references()
	_setup_3d_preview()
	_setup_buttons()

func _process(delta: float) -> void:
	if not visible:
		return
	if mvp_model and is_instance_valid(mvp_model):
		mvp_model.rotate_y(delta * 0.70)
		if mvp_model.has_method("animate"):
			mvp_model.animate(delta, 0.0, true, 7.0)

func _setup_3d_preview() -> void:
	_init_node_references()
	if not mvp_preview_root:
		return
	if CharacterModelScene and not mvp_model:
		mvp_model = CharacterModelScene.instantiate() as Node3D
		mvp_model.rotation.y = PI
		mvp_preview_root.add_child(mvp_model)

func _setup_buttons() -> void:
	_init_node_references()
	if btn_rematch and not btn_rematch.pressed.is_connected(_on_btn_rematch_pressed):
		btn_rematch.pressed.connect(_on_btn_rematch_pressed)
	if btn_lobby and not btn_lobby.pressed.is_connected(_on_btn_lobby_pressed):
		btn_lobby.pressed.connect(_on_btn_lobby_pressed)
	if btn_store and not btn_store.pressed.is_connected(_on_btn_store_pressed):
		btn_store.pressed.connect(_on_btn_store_pressed)

func _on_btn_rematch_pressed() -> void:
	_play_ui_pop()
	rematch_requested.emit()

func _on_btn_lobby_pressed() -> void:
	_play_ui_pop()
	lobby_requested.emit()
	rematch_requested.emit()

func _on_btn_store_pressed() -> void:
	_play_ui_click()
	store_requested.emit()
	if is_inside_tree():
		var main_node = get_node_or_null("/root/Main")
		if main_node and ("store_ui" in main_node) and main_node.store_ui:
			main_node.store_ui.open_store()

func display_game_over(players_data: Array[Dictionary], match_meta: Dictionary, _awards_data: Dictionary = {}) -> void:
	_init_node_references()
	_setup_3d_preview()
	_setup_buttons()
	visible = true

	if is_inside_tree():
		modulate = Color(1, 1, 1, 0)
		var tw := create_tween()
		if tw:
			tw.tween_property(self, "modulate", Color(1, 1, 1, 1), 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

		var audio_mgr = get_node_or_null("/root/AudioManager")
		if audio_mgr and audio_mgr.has_method("play_ui_game_over"):
			audio_mgr.play_ui_game_over()
		elif audio_mgr and audio_mgr.has_method("play_whistle"):
			audio_mgr.play_whistle()

	# 1. Update Match Header Chips
	if mode_label:
		var mode_str: String = match_meta.get("mode_name", "TAYAAN SA KANTO").to_upper()
		mode_label.text = "🎮 " + mode_str
	if meta_summary_label:
		var sec: int = int(match_meta.get("duration", 0.0))
		var time_str: String = "%02d:%02d" % [int(float(sec) / 60.0), sec % 60]
		meta_summary_label.text = "⏱️ %s  •  👥 %d BATA" % [time_str, players_data.size()]

	# 2. Populate Minimalist 4-Column Leaderboard Rows
	if rows_container:
		for c in rows_container.get_children():
			c.queue_free()

		for i in range(players_data.size()):
			var p: Dictionary = players_data[i]
			var row := _build_player_row(i + 1, p)
			rows_container.add_child(row)

	# 3. Populate Top Player (MVP) 3D Card
	if not players_data.is_empty():
		var mvp: Dictionary = players_data[0]
		_populate_top_player_card(mvp)

	# 4. Award and Display Economy Earnings
	_award_and_display_earnings(players_data)

func _populate_top_player_card(mvp: Dictionary) -> void:
	var char_idx: int = mvp.get("character", 0)

	# Apply archetype & visuals to 3D model
	if mvp_model:
		if mvp.has("outfit") and mvp["outfit"] is Dictionary and not mvp["outfit"].is_empty():
			if mvp_model.has_method("apply_outfit_dict"):
				mvp_model.apply_outfit_dict(mvp["outfit"])
		elif mvp_model.has_method("apply_preset"):
			mvp_model.apply_preset(char_idx)

		if mvp.has("color") and mvp_model.has_method("set_player_color"):
			var c_idx = int(mvp.get("color", 0))
			if c_idx >= 0 and c_idx < CharacterAnimator.COLOR_OPTIONS.size():
				mvp_model.set_player_color(CharacterAnimator.COLOR_OPTIONS[c_idx]["color"])

	if mvp_name_label:
		mvp_name_label.text = str(mvp.get("name", "KAMPEON")).to_upper()

	if mvp_role_badge:
		if mvp.get("is_taya", false):
			mvp_role_badge.text = "● TAYA"
			mvp_role_badge.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2, 1.0))
		else:
			mvp_role_badge.text = "● KAMPEON"
			mvp_role_badge.add_theme_color_override("font_color", Color(0.28, 0.95, 0.50, 1.0))

func _award_and_display_earnings(players_data: Array[Dictionary]) -> void:
	if not is_inside_tree():
		return
	var eco: EconomyManager = get_node_or_null("/root/Main/EconomyManager")
	if not eco:
		var gm = get_node_or_null("/root/Main")
		if gm and "economy_manager" in gm:
			eco = gm.economy_manager

	if not eco or players_data.is_empty():
		return

	var local_pid: int = 1
	var nm = get_node_or_null("/root/Main/NetworkManager")
	if nm and multiplayer.has_multiplayer_peer():
		local_pid = multiplayer.get_unique_id()

	var my_data: Dictionary = {}
	for p in players_data:
		if p.get("id", 0) == local_pid or (nm and p.get("name") == nm.local_player_name):
			my_data = p
			break
	if my_data.is_empty():
		my_data = players_data[0]

	var my_score: int = int(my_data.get("score", 0))
	var my_tags: int = int(my_data.get("huli", 0))
	var my_recycled: int = int(my_data.get("basura", 0))
	var is_win: bool = (players_data[0].get("id", 0) == local_pid) or (my_data.get("status") == "LIGTAS")

	var earnings := eco.award_match_earnings(my_score, my_tags, my_recycled, is_win)
	if earnings_val_label:
		earnings_val_label.text = "🪙 +%d Barya   ⭐ +%d Rep" % [
			earnings.get("barya_earned", 0),
			earnings.get("rep_earned", 0)
		]

func _build_player_row(rank: int, p: Dictionary) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(0, 46)

	var sb := StyleBoxFlat.new()
	sb.set_corner_radius_all(10)
	sb.content_margin_left = 12.0
	sb.content_margin_right = 12.0
	sb.content_margin_top = 6.0
	sb.content_margin_bottom = 6.0

	if rank == 1:
		sb.bg_color = Color(0.12, 0.17, 0.32, 0.95)
		sb.set_border_width_all(2)
		sb.border_color = Color(1.0, 0.85, 0.28, 1.0) # Golden champion border
		sb.shadow_color = Color(1.0, 0.85, 0.28, 0.2)
		sb.shadow_size = 4
	else:
		sb.bg_color = Color(0.08, 0.11, 0.20, 0.90)
		sb.set_border_width_all(1)
		sb.border_color = Color(1.0, 1.0, 1.0, 0.70)
		sb.shadow_color = Color(0, 0, 0, 0.25)
		sb.shadow_size = 2

	panel.add_theme_stylebox_override("panel", sb)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 4)
	margin.add_theme_constant_override("margin_right", 4)
	panel.add_child(margin)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 8)
	margin.add_child(hbox)

	# 1. Rank (#)
	var rank_label := Label.new()
	rank_label.custom_minimum_size = Vector2(44, 0)
	rank_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rank_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	if LilitaFont: rank_label.add_theme_font_override("font", LilitaFont)
	rank_label.add_theme_font_size_override("font_size", 15)
	if rank == 1:
		rank_label.text = "👑 1"
		rank_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.28, 1.0))
	elif rank == 2:
		rank_label.text = "🥈 2"
		rank_label.add_theme_color_override("font_color", Color(0.88, 0.90, 0.95, 1.0))
	elif rank == 3:
		rank_label.text = "🥉 3"
		rank_label.add_theme_color_override("font_color", Color(0.92, 0.70, 0.50, 1.0))
	else:
		rank_label.text = str(rank)
		rank_label.add_theme_color_override("font_color", Color(1, 1, 1, 0.75))
	hbox.add_child(rank_label)

	# 2. Player (Bata: Avatar + Clean Single Name)
	var player_box := HBoxContainer.new()
	player_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	player_box.add_theme_constant_override("separation", 10)
	player_box.alignment = BoxContainer.ALIGNMENT_CENTER

	var avatar := TextureRect.new()
	avatar.custom_minimum_size = Vector2(34, 34)
	avatar.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	avatar.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	var char_idx: int = p.get("character", 0)
	avatar.texture = PORTRAITS.get(char_idx, DEFAULT_PORTRAIT)
	player_box.add_child(avatar)

	var name_label := Label.new()
	name_label.text = str(p.get("name", "Player"))
	name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if LilitaFont: name_label.add_theme_font_override("font", LilitaFont)
	name_label.add_theme_font_size_override("font_size", 15)
	if rank == 1:
		name_label.add_theme_color_override("font_color", Color(1.0, 0.88, 0.35, 1.0))
	else:
		name_label.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	player_box.add_child(name_label)
	hbox.add_child(player_box)

	# 3. Status Badge (Katayuan)
	var status_text: String = p.get("status", "LIGTAS")
	var status_label := Label.new()
	status_label.custom_minimum_size = Vector2(100, 0)
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	if LilitaFont: status_label.add_theme_font_override("font", LilitaFont)
	status_label.add_theme_font_size_override("font_size", 13)

	match status_text:
		"TAYA":
			status_label.text = "● TAYA"
			status_label.add_theme_color_override("font_color", Color(1.0, 0.84, 0.28, 1.0))
		"LIGTAS":
			status_label.text = "● LIGTAS"
			status_label.add_theme_color_override("font_color", Color(0.28, 0.95, 0.50, 1.0))
		"HULI":
			status_label.text = "● HULI"
			status_label.add_theme_color_override("font_color", Color(0.95, 0.30, 0.30, 1.0))
		_:
			status_label.text = "● " + status_text
			status_label.add_theme_color_override("font_color", Color(0.75, 0.65, 0.95, 1.0))
	hbox.add_child(status_label)

	# 4. Score (Puntos)
	var score_label := Label.new()
	score_label.custom_minimum_size = Vector2(80, 0)
	score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	score_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	score_label.text = str(int(p.get("score", 0)))
	if LilitaFont: score_label.add_theme_font_override("font", LilitaFont)
	score_label.add_theme_font_size_override("font_size", 16)
	if rank == 1:
		score_label.add_theme_color_override("font_color", Color(1.0, 0.88, 0.32, 1.0))
	else:
		score_label.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	hbox.add_child(score_label)

	return panel

func _play_ui_pop() -> void:
	if is_inside_tree():
		var am = get_node_or_null("/root/AudioManager")
		if am and am.has_method("play_ui_pop"):
			am.play_ui_pop()

func _play_ui_click() -> void:
	if is_inside_tree():
		var am = get_node_or_null("/root/AudioManager")
		if am and am.has_method("play_ui_click"):
			am.play_ui_click()
