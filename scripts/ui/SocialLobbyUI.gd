class_name SocialLobbyUI
extends Control

signal vote_requested()
signal leave_requested()
signal settings_requested()
signal emote_selected(emote_text: String)

@onready var room_title_label: Label = get_node_or_null("TopBar/Margin/HBox/RoomInfo/Title")
@onready var room_ip_label: Label = get_node_or_null("TopBar/Margin/HBox/RoomInfo/Ip")
@onready var player_count_label: Label = get_node_or_null("TopBar/Margin/HBox/PlayerCount/Count")
@onready var btn_start_vote: Button = get_node_or_null("TopBar/Margin/HBox/BtnStartVote")
@onready var btn_emotes: Button = get_node_or_null("TopBar/Margin/HBox/BtnEmotes")
@onready var btn_settings: Button = get_node_or_null("TopBar/Margin/HBox/BtnSettings")
@onready var btn_leave: Button = get_node_or_null("TopBar/Margin/HBox/BtnLeave")
@onready var emotes_bar: PanelContainer = get_node_or_null("EmotesBar")

func _ready() -> void:
	if btn_start_vote:
		btn_start_vote.pressed.connect(func(): vote_requested.emit())
	if btn_leave:
		btn_leave.pressed.connect(func(): leave_requested.emit())
	if btn_settings:
		btn_settings.pressed.connect(func(): settings_requested.emit())
	if btn_emotes:
		btn_emotes.pressed.connect(_toggle_emotes)

	var emotes: Array[String] = [
		"Kumusta! 👋",
		"Habulin mo 'ko! 🏃",
		"Astig! 🔥",
		"Haha! 😂",
		"Talon! 🤸"
	]

	for i in range(1, 6):
		var btn: Button = get_node_or_null("EmotesBar/HBox/Emote%d" % i) as Button
		if btn:
			var txt: String = emotes[i - 1]
			btn.text = txt
			btn.pressed.connect(func():
				emote_selected.emit(txt)
				if emotes_bar: emotes_bar.visible = false
			)

	if emotes_bar:
		emotes_bar.visible = false

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventKey and event.pressed and not event.is_echo():
		match event.keycode:
			KEY_1:
				emote_selected.emit("Kumusta! 👋")
			KEY_2:
				emote_selected.emit("Habulin mo 'ko! 🏃")
			KEY_3:
				emote_selected.emit("Astig! 🔥")
			KEY_4:
				emote_selected.emit("Haha! 😂")
			KEY_5:
				emote_selected.emit("Talon! 🤸")

func _toggle_emotes() -> void:
	if emotes_bar:
		emotes_bar.visible = not emotes_bar.visible

func update_lobby_info(room_name: String, ip_str: String, count: int, max_players: int, _is_host: bool) -> void:
	if room_title_label:
		room_title_label.text = "BARANGAY LOBBY: %s" % room_name.to_upper()
	if room_ip_label:
		room_ip_label.text = ip_str
	if player_count_label:
		player_count_label.text = "MGA BATA: %d / %d" % [count, max_players]
	if btn_start_vote:
		btn_start_vote.visible = false # 3D buzzer podium in court handles voting

func set_voting_active(active: bool) -> void:
	if btn_start_vote:
		btn_start_vote.disabled = active
		if active:
			btn_start_vote.text = "BUMOBOTO NA..."
		else:
			btn_start_vote.text = "★ BUMOTO NG LARO ★"
