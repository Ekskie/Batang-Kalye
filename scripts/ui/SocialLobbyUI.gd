class_name SocialLobbyUI
extends Control

signal vote_requested()
signal leave_requested()
signal settings_requested()
signal emote_selected(emote_text: String)

@onready var room_title_label: Label = find_child("Title", true, false) as Label
@onready var room_ip_label: Label = find_child("Ip", true, false) as Label
@onready var player_count_label: Label = (find_child("PlayerCountLabel", true, false) if find_child("PlayerCountLabel", true, false) else find_child("Count", true, false)) as Label
@onready var btn_start_vote: BaseButton = find_child("BtnStartVote", true, false) as BaseButton
@onready var btn_emotes: BaseButton = find_child("BtnEmotes", true, false) as BaseButton
@onready var btn_settings: BaseButton = find_child("BtnSettings", true, false) as BaseButton
@onready var btn_leave: BaseButton = find_child("BtnLeave", true, false) as BaseButton
@onready var emotes_bar: PanelContainer = find_child("EmotesBar", true, false) as PanelContainer

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
		var formatted_name: String = room_name.to_upper()
		if not formatted_name.begins_with("BRGY") and not formatted_name.begins_with("BARANGAY"):
			formatted_name = "BRGY. " + formatted_name
		room_title_label.text = formatted_name
	if room_ip_label:
		room_ip_label.text = ip_str
	if player_count_label:
		player_count_label.text = "%d/%d" % [count, max_players]
	if btn_start_vote:
		btn_start_vote.visible = false # 3D buzzer podium in court handles voting

func set_voting_active(active: bool) -> void:
	if btn_start_vote and btn_start_vote is Button:
		(btn_start_vote as Button).disabled = active
		if active:
			(btn_start_vote as Button).text = "BUMOBOTO NA..."
		else:
			(btn_start_vote as Button).text = "★ BUMOTO NG LARO ★"
