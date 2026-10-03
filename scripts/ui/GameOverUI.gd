class_name GameOverUI
extends Control

signal rematch_requested

@onready var bg_texture: TextureRect = get_node_or_null("BgTexture")
@onready var rows_container: VBoxContainer = get_node_or_null("Margin/MainVBox/MainHBox/LeftColumn/TablePanel/Margin/VBox/ScrollContainer/RowsContainer")
@onready var meta_players_label: Label = get_node_or_null("Margin/MainVBox/MainHBox/LeftColumn/MetaBar/HBox/PlayersBox/Val")
@onready var meta_duration_label: Label = get_node_or_null("Margin/MainVBox/MainHBox/LeftColumn/MetaBar/HBox/DurationBox/Val")
@onready var meta_taya_label: Label = get_node_or_null("Margin/MainVBox/MainHBox/LeftColumn/MetaBar/HBox/TayaBox/Val")
@onready var meta_mode_label: Label = get_node_or_null("Margin/MainVBox/MainHBox/LeftColumn/MetaBar/HBox/ModeBox/Val")

# Top Player Card
@onready var mvp_portrait: TextureRect = get_node_or_null("Margin/MainVBox/MainHBox/RightColumn/TopPlayerCard/VBox/PortraitContainer/Portrait")
@onready var mvp_role_badge: Label = get_node_or_null("Margin/MainVBox/MainHBox/RightColumn/TopPlayerCard/VBox/RoleBadge")
@onready var mvp_name_label: Label = get_node_or_null("Margin/MainVBox/MainHBox/RightColumn/TopPlayerCard/VBox/NameLabel")
@onready var mvp_stat_huli: Label = get_node_or_null("Margin/MainVBox/MainHBox/RightColumn/TopPlayerCard/VBox/StatsGrid/BoxHuli/V/Num")
@onready var mvp_stat_dulas: Label = get_node_or_null("Margin/MainVBox/MainHBox/RightColumn/TopPlayerCard/VBox/StatsGrid/BoxDulas/V/Num")
@onready var mvp_stat_basura: Label = get_node_or_null("Margin/MainVBox/MainHBox/RightColumn/TopPlayerCard/VBox/StatsGrid/BoxBasura/V/Num")
@onready var mvp_stat_tago: Label = get_node_or_null("Margin/MainVBox/MainHBox/RightColumn/TopPlayerCard/VBox/StatsGrid/BoxTago/V/Num")
@onready var mvp_quote_label: Label = get_node_or_null("Margin/MainVBox/MainHBox/RightColumn/TopPlayerCard/VBox/QuoteLabel")

# Awards Card
@onready var awards_container: VBoxContainer = get_node_or_null("Margin/MainVBox/MainHBox/RightColumn/AwardsCard/VBox/AwardsList")

# Buttons
@onready var btn_lobby: Button = get_node_or_null("Margin/MainVBox/MainHBox/RightColumn/BtnLobby")

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

const MVP_QUOTES: Array[String] = [
	"\"PINAKA-MATALINO SA KALYE!\"",
	"\"HARI NG KANTO!\"",
	"\"LAKAS NG RESBAK!\"",
	"\"DI NAHULI, WALANG SUKO!\"",
	"\"IDOL SA LARONG PINOY!\""
]

func _ready() -> void:
	if btn_lobby:
		btn_lobby.pressed.connect(func(): rematch_requested.emit())

func display_game_over(players_data: Array[Dictionary], match_meta: Dictionary, awards_data: Dictionary) -> void:
	visible = true
	if is_inside_tree():
		modulate = Color(1, 1, 1, 0)
		var tw := create_tween()
		if tw:
			tw.tween_property(self, "modulate", Color(1, 1, 1, 1), 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	# Sound fanfare
	var audio_mgr = get_node_or_null("/root/AudioManager")
	if audio_mgr and audio_mgr.has_method("play_whistle"):
		audio_mgr.play_whistle()

	if get_tree():
		get_tree().create_timer(0.25).timeout.connect(func():
			var am = get_node_or_null("/root/AudioManager")
			if am and am.has_method("play_powerup"):
				am.play_powerup()
		)

	# 1. Update Match Meta
	if meta_players_label:
		meta_players_label.text = "%d / %d" % [players_data.size(), match_meta.get("max_players", 8)]
	if meta_duration_label:
		var sec: int = int(match_meta.get("duration", 0.0))
		meta_duration_label.text = "%02d:%02d" % [sec / 60, sec % 60]
	if meta_taya_label:
		meta_taya_label.text = match_meta.get("taya_name", "Walang Taya")
	if meta_mode_label:
		meta_mode_label.text = match_meta.get("mode_name", "TAYAAN SA KANTO").to_upper()

	# 2. Populate Leaderboard Rows
	if rows_container:
		for c in rows_container.get_children():
			c.queue_free()

		for i in range(players_data.size()):
			var p: Dictionary = players_data[i]
			var row := _build_player_row(i + 1, p)
			rows_container.add_child(row)

	# 3. Populate Top Player (MVP) Card
	if not players_data.is_empty():
		var mvp: Dictionary = players_data[0]
		_populate_top_player_card(mvp)

	# 4. Populate Mga Parangal (Awards) Card
	_populate_awards_card(awards_data)

func _populate_top_player_card(mvp: Dictionary) -> void:
	var char_idx: int = mvp.get("character", 0)
	var tex: Texture2D = PORTRAITS.get(char_idx, DEFAULT_PORTRAIT)
	if mvp_portrait:
		mvp_portrait.texture = tex

	if mvp_role_badge:
		if mvp.get("is_taya", false):
			mvp_role_badge.text = "TAYA"
			mvp_role_badge.modulate = Color(1.0, 0.85, 0.2, 1.0)
		else:
			mvp_role_badge.text = "KAMPEON"
			mvp_role_badge.modulate = Color(0.25, 0.9, 0.45, 1.0)

	if mvp_name_label:
		mvp_name_label.text = str(mvp.get("name", "KAMPEON")).to_upper()

	if mvp_stat_huli: mvp_stat_huli.text = str(mvp.get("huli", 0))
	if mvp_stat_dulas: mvp_stat_dulas.text = str(mvp.get("dulas", 0))
	if mvp_stat_basura: mvp_stat_basura.text = str(mvp.get("basura", 0))
	if mvp_stat_tago: mvp_stat_tago.text = str(mvp.get("tago", 0))

	if mvp_quote_label:
		mvp_quote_label.text = MVP_QUOTES[randi() % MVP_QUOTES.size()]

func _populate_awards_card(awards_data: Dictionary) -> void:
	if not awards_container:
		return
	for c in awards_container.get_children():
		c.queue_free()

	var awards_def: Array[Dictionary] = [
		{ "icon": "🏃", "title": "Best Chaser", "key": "chaser" },
		{ "icon": "🩴", "title": "Spartan Sniper", "key": "sniper" },
		{ "icon": "🍌", "title": "Hari ng Dulas", "key": "dulas" },
		{ "icon": "🗑️", "title": "Basura King", "key": "basura" },
		{ "icon": "🛢️", "title": "Ninja ng Drum", "key": "ninja" }
	]

	for a in awards_def:
		var winner: String = awards_data.get(a["key"], "Walang Award")
		var row := HBoxContainer.new()
		row.custom_minimum_size = Vector2(0, 24)

		var icon_label := Label.new()
		icon_label.text = a["icon"]
		icon_label.custom_minimum_size = Vector2(24, 0)
		row.add_child(icon_label)

		var title_label := Label.new()
		title_label.text = a["title"]
		title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		title_label.add_theme_color_override("font_color", Color(0.75, 0.78, 0.82, 1.0))
		title_label.add_theme_font_size_override("font_size", 12)
		row.add_child(title_label)

		var name_label := Label.new()
		name_label.text = winner
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		name_label.add_theme_color_override("font_color", Color(0.95, 0.85, 0.35, 1.0))
		name_label.add_theme_font_size_override("font_size", 12)
		row.add_child(name_label)

		awards_container.add_child(row)

func _build_player_row(rank: int, p: Dictionary) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(0, 42)

	var sb := StyleBoxFlat.new()
	sb.set_corner_radius_all(6)
	if rank == 1:
		sb.bg_color = Color(0.20, 0.16, 0.05, 0.70)
		sb.border_color = Color(0.92, 0.75, 0.18, 0.90)
		sb.set_border_width_all(1)
	else:
		sb.bg_color = Color(0.08, 0.09, 0.12, 0.65)
		sb.border_color = Color(0.18, 0.20, 0.24, 0.35)
		sb.set_border_width_all(1)
	panel.add_theme_stylebox_override("panel", sb)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_right", 8)
	margin.add_theme_constant_override("margin_top", 4)
	margin.add_theme_constant_override("margin_bottom", 4)
	panel.add_child(margin)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 6)
	margin.add_child(hbox)

	# 1. Rank
	var rank_label := Label.new()
	rank_label.custom_minimum_size = Vector2(32, 0)
	rank_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if rank == 1:
		rank_label.text = "👑 1"
		rank_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
	else:
		rank_label.text = str(rank)
		rank_label.add_theme_color_override("font_color", Color(0.7, 0.72, 0.75))
	rank_label.add_theme_font_size_override("font_size", 13)
	hbox.add_child(rank_label)

	# 2. Player (Avatar + Name)
	var player_box := HBoxContainer.new()
	player_box.custom_minimum_size = Vector2(170, 0)
	player_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	player_box.add_theme_constant_override("separation", 8)

	var avatar := TextureRect.new()
	avatar.custom_minimum_size = Vector2(30, 30)
	avatar.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	avatar.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	var char_idx: int = p.get("character", 0)
	avatar.texture = PORTRAITS.get(char_idx, DEFAULT_PORTRAIT)
	player_box.add_child(avatar)

	var name_label := Label.new()
	name_label.text = p.get("name", "Player")
	name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if rank == 1:
		name_label.add_theme_color_override("font_color", Color(1.0, 0.95, 0.75))
	else:
		name_label.add_theme_color_override("font_color", Color(0.92, 0.92, 0.95))
	name_label.add_theme_font_size_override("font_size", 13)
	player_box.add_child(name_label)
	hbox.add_child(player_box)

	# 3. Status Badge
	var status_text: String = p.get("status", "LIGTAS")
	var status_label := Label.new()
	status_label.custom_minimum_size = Vector2(85, 0)
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	status_label.text = status_text
	status_label.add_theme_font_size_override("font_size", 11)

	match status_text:
		"TAYA":
			status_label.text = "● TAYA"
			status_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
		"LIGTAS":
			status_label.text = "● LIGTAS"
			status_label.add_theme_color_override("font_color", Color(0.25, 0.9, 0.45))
		"HULI":
			status_label.text = "● HULI"
			status_label.add_theme_color_override("font_color", Color(0.95, 0.3, 0.3))
		_:
			status_label.text = "● OUT"
			status_label.add_theme_color_override("font_color", Color(0.65, 0.65, 0.7))
	hbox.add_child(status_label)

	# 4. Huli, Dulas, Basura, Patama, Tago
	for col_key in ["huli", "dulas", "basura", "patama", "tago"]:
		var val_label := Label.new()
		val_label.custom_minimum_size = Vector2(55, 0)
		val_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		val_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		val_label.text = str(p.get(col_key, 0))
		val_label.add_theme_color_override("font_color", Color(0.85, 0.88, 0.92))
		val_label.add_theme_font_size_override("font_size", 12)
		hbox.add_child(val_label)

	# 5. Score
	var score_label := Label.new()
	score_label.custom_minimum_size = Vector2(65, 0)
	score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	score_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	score_label.text = str(int(p.get("score", 0)))
	if rank == 1:
		score_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
	else:
		score_label.add_theme_color_override("font_color", Color(0.95, 0.95, 0.98))
	score_label.add_theme_font_size_override("font_size", 13)
	hbox.add_child(score_label)

	return panel
