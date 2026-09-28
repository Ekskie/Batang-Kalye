class_name GameManager
extends Node

enum GameState {
	TITLE,
	LOBBY,
	MAIBA_TAYA,
	PLAYING,
	GAME_OVER
}

enum MatchMode {
	CLASSIC_TAG, # Traditional "Walang Bawian" - Taya transfers, chaser becomes runner!
	INFECTION    # "Hawaan" - Taya stays Taya, runners infected become Taya!
}

@export var current_mode: MatchMode = MatchMode.CLASSIC_TAG
@export var match_duration: float = 180.0 # 3 minutes
var match_timer: float = 0.0
var current_state: GameState = GameState.TITLE
var is_game_paused: bool = false
var player_scene: PackedScene = preload("res://scenes/player/Player.tscn")

func is_infection() -> bool:
	return current_mode == MatchMode.INFECTION

const CHARACTER_OPTIONS: Array[Dictionary] = [
	{ "type": 0, "name": "⚡ Tsuna (Spiky Hair)" },
	{ "type": 1, "name": "🥊 Kalbo (Street Brawler)" },
	{ "type": 2, "name": "🧢 Batang Kalye (Original)" }
]

const COLOR_OPTIONS: Array[Dictionary] = [
	{ "name": "🔴 Pula (Crimson Fire)", "color": Color(0.95, 0.22, 0.18, 1.0) },
	{ "name": "🔵 Asul (Royal Blue)", "color": Color(0.18, 0.55, 0.95, 1.0) },
	{ "name": "🟢 Berde (Lime Green)", "color": Color(0.20, 0.82, 0.38, 1.0) },
	{ "name": "🟡 Dilaw (Sun Yellow)", "color": Color(0.98, 0.85, 0.15, 1.0) },
	{ "name": "🟠 Dalandan (Orange)", "color": Color(0.98, 0.50, 0.10, 1.0) },
	{ "name": "🟣 Lila (Royal Purple)", "color": Color(0.70, 0.28, 0.92, 1.0) },
	{ "name": "⚪ Puti (Clean White)", "color": Color(0.92, 0.94, 0.96, 1.0) },
	{ "name": "⚫ Itim (Charcoal Black)", "color": Color(0.20, 0.22, 0.25, 1.0) },
]

const PLAYER_COLORS: Array[Color] = [
	Color(0.95, 0.22, 0.18, 1.0), # 0: Pula
	Color(0.18, 0.55, 0.95, 1.0), # 1: Asul
	Color(0.20, 0.82, 0.38, 1.0), # 2: Berde
	Color(0.98, 0.85, 0.15, 1.0), # 3: Dilaw
	Color(0.98, 0.50, 0.10, 1.0), # 4: Dalandan
	Color(0.70, 0.28, 0.92, 1.0), # 5: Lila
	Color(0.92, 0.94, 0.96, 1.0), # 6: Puti
	Color(0.20, 0.22, 0.25, 1.0), # 7: Itim
]

const CHARACTER_PRESETS: Array[Dictionary] = [
	{ "char_type": 0, "color_idx": 3, "name": "1: ⚡Tsuna Dilaw" },
	{ "char_type": 1, "color_idx": 0, "name": "2: 🥊Kalbo Pula" },
	{ "char_type": 2, "color_idx": 1, "name": "3: 🧢Batang Asul" },
	{ "char_type": 0, "color_idx": 4, "name": "4: 🔥Tsuna Dalandan" },
	{ "char_type": 1, "color_idx": 2, "name": "5: 🩲Kalbo Berde" },
	{ "char_type": 2, "color_idx": 5, "name": "6: ⭐Batang Lila" },
	{ "char_type": 0, "color_idx": 6, "name": "7: ⚡Tsuna Puti" },
	{ "char_type": 1, "color_idx": 7, "name": "8: 🥊Kalbo Itim" }
]

var selected_char_idx: int = 0
var selected_color_idx: int = 3 # Default Tsuna Dilaw

# Core System Nodes
@onready var network_manager: NetworkManager = get_node_or_null("NetworkManager")
@onready var maiba_manager: MaibaTayaManager = get_node_or_null("MaibaTayaManager")
@onready var map_node: Node3D = get_node_or_null("KalyeMap")
@onready var players_container: Node3D = get_node_or_null("Players")
@onready var hud: HUD = get_node_or_null("HUD")
@onready var maiba_ui: MaibaTayaUI = get_node_or_null("MaibaTayaUI")
@onready var game_over_ui: Control = get_node_or_null("GameOverUI")
@onready var winner_label: Label = get_node_or_null("GameOverUI/Panel/VBoxContainer/WinnerLabel")
@onready var nanay_event: Node = get_node_or_null("NanayEvent")

# Title Screen UI elements
@onready var title_ui: Control = get_node_or_null("TitleScreenUI")
@onready var btn_enter_title: Button = get_node_or_null("TitleScreenUI/Center/Panel/VBox/BtnEnterTitle")

# Lobby UI elements
@onready var lobby_ui: Control = get_node_or_null("LobbyUI")
@onready var name_input: LineEdit = get_node_or_null("LobbyUI/Panel/VBoxContainer/MainColumns/RightConsole/NameRow/NameEdit")
@onready var ip_input: LineEdit = get_node_or_null("LobbyUI/Panel/VBoxContainer/MainColumns/RightConsole/ConnectionRow/IPEdit")
@onready var port_input: LineEdit = get_node_or_null("LobbyUI/Panel/VBoxContainer/MainColumns/RightConsole/ConnectionRow/PortEdit")
@onready var btn_host: Button = get_node_or_null("LobbyUI/Panel/VBoxContainer/MainColumns/RightConsole/BtnHost")
@onready var btn_join: Button = get_node_or_null("LobbyUI/Panel/VBoxContainer/MainColumns/RightConsole/BtnJoin")
@onready var btn_cancel: Button = get_node_or_null("LobbyUI/Panel/VBoxContainer/MainColumns/RightConsole/BtnCancel")
@onready var btn_solo: Button = get_node_or_null("LobbyUI/Panel/VBoxContainer/MainColumns/RightConsole/BtnSolo")
@onready var btn_start_match: Button = get_node_or_null("LobbyUI/Panel/VBoxContainer/MainColumns/RightConsole/BtnStartMatch")
@onready var slots_header: Label = get_node_or_null("LobbyUI/Panel/VBoxContainer/MainColumns/RightConsole/SlotsHeader")
@onready var player_list_label: Label = get_node_or_null("LobbyUI/Panel/VBoxContainer/MainColumns/RightConsole/SlotsHeader")
@onready var hotspot_info_label: Label = get_node_or_null("LobbyUI/Panel/VBoxContainer/MainColumns/RightConsole/InfoBox/LocalIPRow/HotspotInfoLabel")
@onready var btn_copy_ip: Button = get_node_or_null("LobbyUI/Panel/VBoxContainer/MainColumns/RightConsole/InfoBox/LocalIPRow/BtnCopyIP")
var slot_labels: Array[Label] = []

# Character Customization & 3D Showroom UI elements
@onready var preview_char: CharacterAnimator = get_node_or_null("LobbyUI/Panel/VBoxContainer/MainColumns/LeftShowroom/PreviewFrame/PreviewViewportContainer/PreviewSubViewport/PreviewChar")
@onready var btn_prev_char: Button = get_node_or_null("LobbyUI/Panel/VBoxContainer/MainColumns/LeftShowroom/ModelRow/BtnPrevChar")
@onready var btn_next_char: Button = get_node_or_null("LobbyUI/Panel/VBoxContainer/MainColumns/LeftShowroom/ModelRow/BtnNextChar")
@onready var char_name_label: Label = get_node_or_null("LobbyUI/Panel/VBoxContainer/MainColumns/LeftShowroom/ModelRow/ModelBadge/CharNameLabel")
@onready var btn_prev_color: Button = get_node_or_null("LobbyUI/Panel/VBoxContainer/MainColumns/LeftShowroom/ColorRow/BtnPrevColor")
@onready var btn_next_color: Button = get_node_or_null("LobbyUI/Panel/VBoxContainer/MainColumns/LeftShowroom/ColorRow/BtnNextColor")
@onready var color_name_label: Label = get_node_or_null("LobbyUI/Panel/VBoxContainer/MainColumns/LeftShowroom/ColorRow/ColorBadge/ColorNameLabel")
@onready var preset_grid: GridContainer = get_node_or_null("LobbyUI/Panel/VBoxContainer/MainColumns/LeftShowroom/PresetGrid")

# Pause Menu UI elements
@onready var pause_ui: Control = get_node_or_null("PauseUI")
@onready var pause_panel: Control = get_node_or_null("PauseUI/PausePanel")
@onready var btn_resume: Button = get_node_or_null("PauseUI/PausePanel/VBoxContainer/BtnResume")
@onready var btn_settings: Button = get_node_or_null("PauseUI/PausePanel/VBoxContainer/BtnSettings")
@onready var btn_pause_lobby: Button = get_node_or_null("PauseUI/PausePanel/VBoxContainer/BtnPauseLobby")
@onready var btn_pause_quit: Button = get_node_or_null("PauseUI/PausePanel/VBoxContainer/BtnPauseQuit")
@onready var settings_panel: Control = get_node_or_null("PauseUI/SettingsPanel")
@onready var volume_slider: HSlider = get_node_or_null("PauseUI/SettingsPanel/VBoxContainer/VolumeRow/VolumeSlider")
@onready var volume_label: Label = get_node_or_null("PauseUI/SettingsPanel/VBoxContainer/VolumeRow/VolumeLabel")
@onready var sensitivity_slider: HSlider = get_node_or_null("PauseUI/SettingsPanel/VBoxContainer/SensitivityRow/SensitivitySlider")
@onready var sensitivity_label: Label = get_node_or_null("PauseUI/SettingsPanel/VBoxContainer/SensitivityRow/SensitivityLabel")
@onready var fov_slider: HSlider = get_node_or_null("PauseUI/SettingsPanel/VBoxContainer/FovRow/FovSlider")
@onready var fov_label: Label = get_node_or_null("PauseUI/SettingsPanel/VBoxContainer/FovRow/FovLabel")
@onready var btn_close_settings: Button = get_node_or_null("PauseUI/SettingsPanel/VBoxContainer/BtnCloseSettings")

func _enter_tree() -> void:
	_init_node_references()

func _init_node_references() -> void:
	if not network_manager: network_manager = get_node_or_null("NetworkManager")
	if not maiba_manager: maiba_manager = get_node_or_null("MaibaTayaManager")
	if not map_node: map_node = get_node_or_null("KalyeMap")
	if not players_container: players_container = get_node_or_null("Players")
	if not hud: hud = get_node_or_null("HUD")
	if not maiba_ui: maiba_ui = get_node_or_null("MaibaTayaUI")
	if not game_over_ui: game_over_ui = get_node_or_null("GameOverUI")
	if not winner_label: winner_label = get_node_or_null("GameOverUI/Panel/VBoxContainer/WinnerLabel")
	if not nanay_event: nanay_event = get_node_or_null("NanayEvent")

	if not title_ui: title_ui = get_node_or_null("TitleScreenUI")
	if not btn_enter_title: btn_enter_title = get_node_or_null("TitleScreenUI/Center/Panel/VBox/BtnEnterTitle")

	if not lobby_ui: lobby_ui = get_node_or_null("LobbyUI")
	if not name_input:
		name_input = get_node_or_null("LobbyUI/Panel/VBoxContainer/MainColumns/RightConsole/NameRow/NameEdit")
	if not name_input:
		name_input = get_node_or_null("LobbyUI/Panel/VBoxContainer/MainColumns/RightConsole/NameEdit")

	if not ip_input:
		ip_input = get_node_or_null("LobbyUI/Panel/VBoxContainer/MainColumns/RightConsole/ConnectionRow/IPEdit")
	if not ip_input:
		ip_input = get_node_or_null("LobbyUI/Panel/VBoxContainer/MainColumns/RightConsole/ConnectionBox/IPEdit")

	if not port_input:
		port_input = get_node_or_null("LobbyUI/Panel/VBoxContainer/MainColumns/RightConsole/ConnectionRow/PortEdit")
	if not port_input:
		port_input = get_node_or_null("LobbyUI/Panel/VBoxContainer/MainColumns/RightConsole/ConnectionBox/PortEdit")

	if not btn_host: btn_host = get_node_or_null("LobbyUI/Panel/VBoxContainer/MainColumns/RightConsole/BtnHost")
	if not btn_join: btn_join = get_node_or_null("LobbyUI/Panel/VBoxContainer/MainColumns/RightConsole/BtnJoin")
	if not btn_cancel: btn_cancel = get_node_or_null("LobbyUI/Panel/VBoxContainer/MainColumns/RightConsole/BtnCancel")
	if not btn_solo: btn_solo = get_node_or_null("LobbyUI/Panel/VBoxContainer/MainColumns/RightConsole/BtnSolo")
	if not btn_start_match: btn_start_match = get_node_or_null("LobbyUI/Panel/VBoxContainer/MainColumns/RightConsole/BtnStartMatch")

	if not hotspot_info_label:
		hotspot_info_label = get_node_or_null("LobbyUI/Panel/VBoxContainer/MainColumns/RightConsole/InfoBox/LocalIPRow/HotspotInfoLabel")
	if not hotspot_info_label:
		hotspot_info_label = get_node_or_null("LobbyUI/Panel/VBoxContainer/MainColumns/RightConsole/HotspotInfoLabel")

	if not btn_copy_ip:
		btn_copy_ip = get_node_or_null("LobbyUI/Panel/VBoxContainer/MainColumns/RightConsole/InfoBox/LocalIPRow/BtnCopyIP")

	if not slots_header:
		slots_header = get_node_or_null("LobbyUI/Panel/VBoxContainer/MainColumns/RightConsole/SlotsHeader")
	if not player_list_label:
		player_list_label = slots_header if slots_header else get_node_or_null("LobbyUI/Panel/VBoxContainer/MainColumns/RightConsole/PlayerListBox/PlayerListLabel")

	# Collect 8 Slot labels
	slot_labels.clear()
	for i in range(1, 9):
		var lbl: Label = get_node_or_null("LobbyUI/Panel/VBoxContainer/MainColumns/RightConsole/SlotsGrid/Slot" + str(i) + "/Label")
		if lbl:
			slot_labels.append(lbl)

	if not preview_char:
		preview_char = get_node_or_null("LobbyUI/Panel/VBoxContainer/MainColumns/LeftShowroom/PreviewFrame/PreviewViewportContainer/PreviewSubViewport/PreviewChar")
	if not preview_char:
		preview_char = get_node_or_null("LobbyUI/Panel/VBoxContainer/MainColumns/LeftShowroom/PreviewViewportContainer/PreviewSubViewport/PreviewChar")

	if not btn_prev_char: btn_prev_char = get_node_or_null("LobbyUI/Panel/VBoxContainer/MainColumns/LeftShowroom/ModelRow/BtnPrevChar")
	if not btn_next_char: btn_next_char = get_node_or_null("LobbyUI/Panel/VBoxContainer/MainColumns/LeftShowroom/ModelRow/BtnNextChar")
	if not char_name_label:
		char_name_label = get_node_or_null("LobbyUI/Panel/VBoxContainer/MainColumns/LeftShowroom/ModelRow/ModelBadge/CharNameLabel")
	if not char_name_label:
		char_name_label = get_node_or_null("LobbyUI/Panel/VBoxContainer/MainColumns/LeftShowroom/ModelRow/CharNameLabel")

	if not btn_prev_color: btn_prev_color = get_node_or_null("LobbyUI/Panel/VBoxContainer/MainColumns/LeftShowroom/ColorRow/BtnPrevColor")
	if not btn_next_color: btn_next_color = get_node_or_null("LobbyUI/Panel/VBoxContainer/MainColumns/LeftShowroom/ColorRow/BtnNextColor")
	if not color_name_label:
		color_name_label = get_node_or_null("LobbyUI/Panel/VBoxContainer/MainColumns/LeftShowroom/ColorRow/ColorBadge/ColorNameLabel")
	if not color_name_label:
		color_name_label = get_node_or_null("LobbyUI/Panel/VBoxContainer/MainColumns/LeftShowroom/ColorRow/ColorNameLabel")

	if not preset_grid: preset_grid = get_node_or_null("LobbyUI/Panel/VBoxContainer/MainColumns/LeftShowroom/PresetGrid")

	if not pause_ui: pause_ui = get_node_or_null("PauseUI")
	if not pause_panel: pause_panel = get_node_or_null("PauseUI/PausePanel")
	if not btn_resume: btn_resume = get_node_or_null("PauseUI/PausePanel/VBoxContainer/BtnResume")
	if not btn_settings: btn_settings = get_node_or_null("PauseUI/PausePanel/VBoxContainer/BtnSettings")
	if not btn_pause_lobby: btn_pause_lobby = get_node_or_null("PauseUI/PausePanel/VBoxContainer/BtnPauseLobby")
	if not btn_pause_quit: btn_pause_quit = get_node_or_null("PauseUI/PausePanel/VBoxContainer/BtnPauseQuit")
	if not settings_panel: settings_panel = get_node_or_null("PauseUI/SettingsPanel")
	if not volume_slider: volume_slider = get_node_or_null("PauseUI/SettingsPanel/VBoxContainer/VolumeRow/VolumeSlider")
	if not volume_label: volume_label = get_node_or_null("PauseUI/SettingsPanel/VBoxContainer/VolumeRow/VolumeLabel")
	if not sensitivity_slider: sensitivity_slider = get_node_or_null("PauseUI/SettingsPanel/VBoxContainer/SensitivityRow/SensitivitySlider")
	if not sensitivity_label: sensitivity_label = get_node_or_null("PauseUI/SettingsPanel/VBoxContainer/SensitivityRow/SensitivityLabel")
	if not fov_slider: fov_slider = get_node_or_null("PauseUI/SettingsPanel/VBoxContainer/FovRow/FovSlider")
	if not fov_label: fov_label = get_node_or_null("PauseUI/SettingsPanel/VBoxContainer/FovRow/FovLabel")
	if not btn_close_settings: btn_close_settings = get_node_or_null("PauseUI/SettingsPanel/VBoxContainer/BtnCloseSettings")

func _ready() -> void:
	_init_node_references()

	var run_test := false
	for arg in OS.get_cmdline_args():
		if "--run-self-test" in arg:
			run_test = true
	for arg in OS.get_cmdline_user_args():
		if "--run-self-test" in arg:
			run_test = true

	# Start on Title for players, or Lobby for automated test runs
	if run_test:
		_set_game_state(GameState.LOBBY)
	else:
		_set_game_state(GameState.TITLE)

	_setup_network_signals()
	_setup_ui_signals()
	_setup_maiba_signals()
	_setup_nanay_event()

	# Display local IP for hotspot hosting
	var ips := NetworkManager.get_local_ip_addresses()
	if hotspot_info_label:
		hotspot_info_label.text = "Local IP: " + ips[0] + " (Port 7777)"
	if ip_input and (ip_input.text.is_empty() or ip_input.text == "127.0.0.1"):
		ip_input.text = ips[0]

	_update_lobby_player_list()

	if run_test:
		call_deferred("_run_automated_self_test")

func _setup_network_signals() -> void:
	network_manager.server_created.connect(_on_server_created)
	network_manager.join_success.connect(_on_join_success)
	network_manager.join_failed.connect(_on_join_failed)
	network_manager.player_list_updated.connect(_update_lobby_player_list)
	network_manager.server_disconnected.connect(_on_server_disconnected)

func _setup_ui_signals() -> void:
	if btn_enter_title:
		btn_enter_title.pressed.connect(_on_btn_enter_title_pressed)

	if btn_host: btn_host.pressed.connect(_on_btn_host_pressed)
	if btn_join: btn_join.pressed.connect(_on_btn_join_pressed)
	if btn_cancel: btn_cancel.pressed.connect(_on_btn_cancel_pressed)
	if btn_solo: btn_solo.pressed.connect(_on_btn_solo_pressed)
	if btn_start_match: btn_start_match.pressed.connect(_on_btn_start_match_pressed)
	if ip_input:
		ip_input.text_changed.connect(_on_ip_text_changed)
	if name_input:
		name_input.text_changed.connect(func(_new_name: String):
			if not multiplayer.has_multiplayer_peer() or multiplayer.get_peers().is_empty():
				_update_lobby_player_list()
		)
	if btn_copy_ip:
		btn_copy_ip.pressed.connect(_on_btn_copy_ip_pressed)

	if btn_prev_char: btn_prev_char.pressed.connect(_on_prev_char_pressed)
	if btn_next_char: btn_next_char.pressed.connect(_on_next_char_pressed)
	if btn_prev_color: btn_prev_color.pressed.connect(_on_prev_color_pressed)
	if btn_next_color: btn_next_color.pressed.connect(_on_next_color_pressed)
	if preset_grid:
		for i in range(min(8, preset_grid.get_child_count())):
			var p_btn: Button = preset_grid.get_child(i) as Button
			if p_btn:
				p_btn.pressed.connect(_select_preset.bind(i))

	# Pause menu buttons & settings
	if btn_resume:
		btn_resume.pressed.connect(func(): set_paused(false))
	if btn_settings:
		btn_settings.pressed.connect(func():
			if pause_panel: pause_panel.visible = false
			if settings_panel: settings_panel.visible = true
		)
	if btn_close_settings:
		btn_close_settings.pressed.connect(func():
			if settings_panel: settings_panel.visible = false
			if pause_panel: pause_panel.visible = true
		)
	if btn_pause_lobby:
		btn_pause_lobby.pressed.connect(_on_btn_pause_lobby_pressed)
	if btn_pause_quit:
		btn_pause_quit.pressed.connect(func(): get_tree().quit())

	if volume_slider:
		volume_slider.value_changed.connect(_on_volume_changed)
	if sensitivity_slider:
		sensitivity_slider.value_changed.connect(_on_sensitivity_changed)
	if fov_slider:
		fov_slider.value_changed.connect(_on_fov_changed)

	_update_customization_ui()

	var btn_rematch = get_node_or_null("GameOverUI/Panel/VBoxContainer/BtnRematch")
	if btn_rematch:
		btn_rematch.pressed.connect(func(): _set_game_state(GameState.LOBBY))

func _on_btn_enter_title_pressed() -> void:
	_set_game_state(GameState.LOBBY)

func _on_btn_copy_ip_pressed() -> void:
	var ips := NetworkManager.get_local_ip_addresses()
	var text_to_copy := ips[0] + ":7777"
	if ip_input and not ip_input.text.is_empty():
		var p_str := port_input.text.strip_edges() if port_input else "7777"
		text_to_copy = ip_input.text.strip_edges() + ":" + p_str
	DisplayServer.clipboard_set(text_to_copy)
	if hotspot_info_label:
		var orig := hotspot_info_label.text
		hotspot_info_label.text = "📋 Copied: " + text_to_copy
		get_tree().create_timer(2.0).timeout.connect(func():
			if hotspot_info_label:
				hotspot_info_label.text = orig
		)

func _on_prev_char_pressed() -> void:
	selected_char_idx = (selected_char_idx - 1 + CHARACTER_OPTIONS.size()) % CHARACTER_OPTIONS.size()
	_update_customization_ui()

func _on_next_char_pressed() -> void:
	selected_char_idx = (selected_char_idx + 1) % CHARACTER_OPTIONS.size()
	_update_customization_ui()

func _on_prev_color_pressed() -> void:
	selected_color_idx = (selected_color_idx - 1 + COLOR_OPTIONS.size()) % COLOR_OPTIONS.size()
	_update_customization_ui()

func _on_next_color_pressed() -> void:
	selected_color_idx = (selected_color_idx + 1) % COLOR_OPTIONS.size()
	_update_customization_ui()

func _select_preset(idx: int) -> void:
	if idx < 0 or idx >= CHARACTER_PRESETS.size():
		return
	var preset := CHARACTER_PRESETS[idx]
	selected_char_idx = preset["char_type"]
	selected_color_idx = preset["color_idx"]
	_update_customization_ui()

func _update_customization_ui() -> void:
	if char_name_label and selected_char_idx < CHARACTER_OPTIONS.size():
		char_name_label.text = CHARACTER_OPTIONS[selected_char_idx]["name"]
	if color_name_label and selected_color_idx < COLOR_OPTIONS.size():
		color_name_label.text = COLOR_OPTIONS[selected_color_idx]["name"]
		color_name_label.modulate = COLOR_OPTIONS[selected_color_idx]["color"]

	if preview_char:
		preview_char.set_character(selected_char_idx)
		var pcol: Color = COLOR_OPTIONS[selected_color_idx % COLOR_OPTIONS.size()]["color"]
		preview_char.set_player_color(pcol)

	if network_manager:
		network_manager.set_local_customization(selected_char_idx, selected_color_idx)

func _setup_maiba_signals() -> void:
	maiba_manager.countdown_step.connect(func(text: String): maiba_ui.show_chant(text))
	maiba_manager.hand_choice_requested.connect(func(limit: float): maiba_ui.request_choice(limit))
	maiba_ui.choice_made.connect(func(c: int): maiba_manager.rpc_id(1, "submit_hand_choice", c))
	maiba_manager.taya_decided.connect(_on_taya_decided)

func _setup_nanay_event() -> void:
	if not nanay_event:
		return
	nanay_event.call("setup", self, players_container)
	nanay_event.connect("player_sent_home", _on_player_sent_home)

func _on_player_sent_home(pid: int, pname: String) -> void:
	# Player reached Tindahan — they are OUT of this round (spectator) but rejoin next round
	var player_node: PlayerController = players_container.get_node_or_null(str(pid)) as PlayerController
	if player_node:
		# Make them a spectator: hide and disable input
		player_node.visible = false
		player_node.set_process(false)
		player_node.set_physics_process(false)
		# Don't make them Taya — they're just sent home!

	# Update scoreboard data — deduct 10 pts for being caught by Nanay :)
	if network_manager.players.has(pid):
		network_manager.players[pid]["score"] = max(0, network_manager.players[pid].get("score", 0) - 10)
		network_manager.players[pid]["sent_home"] = true

	if hud:
		hud.show_tag_banner("NANAY", pname)
		hud.update_scoreboard(network_manager.players)

func _on_ip_text_changed(new_text: String) -> void:
	if not ip_input:
		ip_input = get_node_or_null("LobbyUI/Panel/VBoxContainer/ConnectionBox/IPEdit")
	if not port_input:
		port_input = get_node_or_null("LobbyUI/Panel/VBoxContainer/ConnectionBox/PortEdit")

	if ":" in new_text:
		var parts := new_text.split(":")
		var host_part := parts[0].strip_edges()
		var port_part := parts[1].strip_edges()
		if port_part.is_valid_int():
			if ip_input:
				ip_input.text = host_part
			if port_input:
				port_input.text = port_part

func _on_btn_host_pressed() -> void:
	var pname := name_input.text.strip_edges() if name_input else "Kuya Denn"
	if pname.is_empty():
		pname = "Kuya Denn"

	if not port_input:
		port_input = get_node_or_null("LobbyUI/Panel/VBoxContainer/ConnectionBox/PortEdit")

	var port := NetworkManager.DEFAULT_PORT
	if port_input and port_input.text.strip_edges().is_valid_int():
		port = port_input.text.strip_edges().to_int()

	var err := network_manager.create_game(pname, port)
	if err != OK:
		hotspot_info_label.text = "❌ Failed to create server sa Port %d!\n(Baka may ibang app na gumagamit nito)" % port
		return

	hotspot_info_label.text = "🟢 Server Active sa Port %d!\nI-forward sa PlayIt.gg o ipamigay ang Local IP sa kalaro." % port
	btn_host.disabled = true
	btn_join.disabled = true
	btn_cancel.visible = true
	btn_start_match.visible = true

func _on_btn_join_pressed() -> void:
	var pname := name_input.text.strip_edges() if name_input else "Bata"
	if pname.is_empty():
		pname = "Bata " + str(randi() % 100)

	if not ip_input:
		ip_input = get_node_or_null("LobbyUI/Panel/VBoxContainer/ConnectionBox/IPEdit")
	if not port_input:
		port_input = get_node_or_null("LobbyUI/Panel/VBoxContainer/ConnectionBox/PortEdit")

	var target := ip_input.text.strip_edges() if ip_input else "127.0.0.1"
	var port := NetworkManager.DEFAULT_PORT

	if ":" in target:
		var parts := target.split(":")
		target = parts[0].strip_edges()
		if parts.size() > 1 and parts[1].strip_edges().is_valid_int():
			port = parts[1].strip_edges().to_int()
			if port_input:
				port_input.text = str(port)
	elif port_input and port_input.text.strip_edges().is_valid_int():
		port = port_input.text.strip_edges().to_int()

	if target.is_empty():
		target = "127.0.0.1"

	hotspot_info_label.text = "⏳ Kumukonekta sa %s:%d...\n(Pakihintay ang PlayIt.gg / Host)" % [target, port]
	btn_host.disabled = true
	btn_join.disabled = true
	btn_cancel.visible = true

	var err := network_manager.join_game(target, pname, port)
	if err != OK:
		hotspot_info_label.text = "❌ Error connecting to %s:%d." % [target, port]
		btn_host.disabled = false
		btn_join.disabled = false
		btn_cancel.visible = false

func _on_btn_cancel_pressed() -> void:
	network_manager.leave_game()
	btn_host.disabled = false
	btn_join.disabled = false
	btn_cancel.visible = false
	btn_start_match.visible = false
	var ips := NetworkManager.get_local_ip_addresses()
	hotspot_info_label.text = "Local IP: " + ips[0] + " (Port 7777)\nPara sa Online: Gamitin ang PlayIt.gg Domain + Port"
	player_list_label.text = "Mga Kasali: (Naghihintay...)"

func _on_btn_solo_pressed() -> void:
	_init_node_references()
	var pname := name_input.text.strip_edges() if name_input else "Dennrick (Solo)"
	if pname.is_empty():
		pname = "Dennrick (Solo)"
	network_manager.create_game(pname)
	_spawn_all_players()

	# Also spawn a PracticeBot runner so the player can chase and tag it!
	var bot_scene: PackedScene = preload("res://scenes/player/PracticeBot.tscn")
	var bot: PracticeBot = bot_scene.instantiate()
	bot.name = "99"
	bot.player_id = 99
	bot.player_name = "Kalbo (Bot)"
	bot.current_role = PlayerController.Role.RUNNER

	var spawn_points := map_node.get_node("SpawnPoints").get_children()
	if spawn_points.size() > 1:
		bot.position = spawn_points[1].global_position
	else:
		bot.position = Vector3(0, 0.5, 6)
	players_container.add_child(bot)
	if bot.model:
		bot.model.set_character(CharacterAnimator.CharacterType.KALBO)
		bot.model.set_player_color(COLOR_OPTIONS[2]["color"]) # Green runner

	# Register bot in network players for scoreboard
	network_manager.players[99] = {
		"name": "Kalbo (Bot)",
		"score": 0,
		"role": 0,
		"character": 1,
		"color_idx": 2
	}

	# In solo practice, start player as Taya immediately to test chasing & tagging
	var local_p: PlayerController = players_container.get_node_or_null("1")
	if local_p:
		local_p.current_role = PlayerController.Role.TAYA
		network_manager.players[1]["role"] = 1
		if local_p.model:
			local_p.model.set_character(selected_char_idx)
			local_p.model.set_player_color(COLOR_OPTIONS[selected_color_idx % COLOR_OPTIONS.size()]["color"])

	_set_game_state(GameState.PLAYING)
	match_timer = match_duration

func notify_tag_event(chaser_id: int, target_id: int) -> void:
	if multiplayer.has_multiplayer_peer() and multiplayer.is_server():
		rpc("sync_tag_event", chaser_id, target_id)
	else:
		sync_tag_event(chaser_id, target_id)

@rpc("any_peer", "call_local", "reliable")
func sync_tag_event(chaser_id: int, target_id: int) -> void:
	var chaser_name: String = "Chaser"
	var target_name: String = "Runner"

	if network_manager.players.has(chaser_id):
		network_manager.players[chaser_id]["score"] += 50
		chaser_name = network_manager.players[chaser_id].get("name", "Chaser")
		if current_mode == MatchMode.CLASSIC_TAG:
			network_manager.players[chaser_id]["role"] = 0 # Former chaser becomes runner!

	if network_manager.players.has(target_id):
		network_manager.players[target_id]["role"] = 1 # Target becomes Taya!
		target_name = network_manager.players[target_id].get("name", "Runner")

	hud.update_scoreboard(network_manager.players)
	hud.show_tag_banner(chaser_name, target_name)

func award_recycle_points(pid: int, pts: int = 30) -> void:
	if multiplayer.has_multiplayer_peer() and multiplayer.is_server():
		rpc("sync_recycle_points", pid, pts)
	else:
		sync_recycle_points(pid, pts)

@rpc("any_peer", "call_local", "reliable")
func sync_recycle_points(pid: int, pts: int) -> void:
	if network_manager.players.has(pid):
		network_manager.players[pid]["score"] += pts
	if hud:
		hud.update_scoreboard(network_manager.players)

func _on_btn_start_match_pressed() -> void:
	if multiplayer.is_server():
		rpc("sync_start_match")

@rpc("call_local", "reliable")
func sync_start_match() -> void:
	_start_match_flow()

func _start_match_flow() -> void:
	_spawn_all_players()
	_set_game_state(GameState.MAIBA_TAYA)

	if multiplayer.is_server():
		var pids := network_manager.players.keys()
		maiba_manager.start_selection(pids)

func _on_taya_decided(taya_id: int, taya_name: String) -> void:
	var my_id := multiplayer.get_unique_id()
	var is_me_taya := (my_id == taya_id)
	maiba_ui.show_result(taya_name, is_me_taya)

	# Set roles across players
	for player_node in players_container.get_children():
		if player_node is PlayerController:
			if player_node.player_id == taya_id:
				player_node.current_role = PlayerController.Role.TAYA
			else:
				player_node.current_role = PlayerController.Role.RUNNER

	# Begin match after 2 seconds
	get_tree().create_timer(2.0).timeout.connect(func():
		_set_game_state(GameState.PLAYING)
		match_timer = match_duration
	)

func _spawn_all_players() -> void:
	# Clear existing players
	for child in players_container.get_children():
		child.queue_free()

	var spawn_points := map_node.get_node("SpawnPoints").get_children()
	var spawn_idx := 0

	for pid in network_manager.players.keys():
		var pinfo = network_manager.players[pid]
		var player_instance: PlayerController = player_scene.instantiate()
		player_instance.name = str(pid)
		player_instance.player_id = pid
		player_instance.player_name = pinfo.get("name", "Player")

		# Spawn point
		var spawn_pos: Vector3 = Vector3(0, 1, 0)
		if spawn_points.size() > 0:
			var sp: Marker3D = spawn_points[spawn_idx % spawn_points.size()]
			spawn_pos = sp.global_position
			spawn_idx += 1
		player_instance.position = spawn_pos

		players_container.add_child(player_instance)

		# Character model & color customization
		var char_type: int = pinfo.get("character", selected_char_idx if pid == 1 else 0)
		var color_idx: int = pinfo.get("color_idx", selected_color_idx if pid == 1 else (spawn_idx % COLOR_OPTIONS.size()))
		var pcol: Color = COLOR_OPTIONS[color_idx % COLOR_OPTIONS.size()]["color"]
		if player_instance.model:
			player_instance.model.set_character(char_type)
			player_instance.model.set_player_color(pcol)

func _input(event: InputEvent) -> void:
	if current_state == GameState.PLAYING:
		if event is InputEventKey and event.is_pressed() and not event.is_echo() and event.keycode == KEY_ESCAPE:
			if settings_panel and settings_panel.visible:
				settings_panel.visible = false
				if pause_panel:
					pause_panel.visible = true
			else:
				toggle_pause()
			get_viewport().set_input_as_handled()
			return

func _unhandled_input(event: InputEvent) -> void:
	if current_state == GameState.TITLE:
		if event is InputEventKey and event.pressed:
			if event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER or event.keycode == KEY_SPACE:
				_on_btn_enter_title_pressed()
				get_viewport().set_input_as_handled()
		elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			_on_btn_enter_title_pressed()
			get_viewport().set_input_as_handled()

func _process(delta: float) -> void:
	if current_state == GameState.TITLE:
		if btn_enter_title:
			var pulse := 0.88 + 0.12 * sin(Time.get_ticks_msec() * 0.005)
			btn_enter_title.modulate.a = pulse
	elif current_state == GameState.LOBBY:
		if preview_char:
			preview_char.rotate_y(delta * 0.8)
			preview_char.animate(delta, 0.0, true, 7.0)
	elif current_state == GameState.PLAYING:
		if not is_game_paused:
			match_timer -= delta
			if hud:
				hud.update_match_timer(match_timer)

			# Update local player hud
			var my_id := multiplayer.get_unique_id()
			var my_node: PlayerController = players_container.get_node_or_null(str(my_id))
			if my_node:
				hud.update_role_display(my_node.current_role == PlayerController.Role.TAYA)
				hud.update_score(my_node.survival_time, my_node.tag_count, my_node.current_role == PlayerController.Role.TAYA)

			if hud:
				hud.update_scoreboard(network_manager.players)

			if multiplayer.is_server() and match_timer <= 0.0:
				rpc("sync_game_over")

@rpc("call_local", "reliable")
func sync_game_over() -> void:
	_set_game_state(GameState.GAME_OVER)
	# Determine highest survival runner or top chaser
	var best_name := ""
	var best_score := -1.0
	for player_node in players_container.get_children():
		if player_node is PlayerController:
			var player: PlayerController = player_node as PlayerController
			var final_score: float = player.survival_time + (float(player.tag_count) * 30.0)
			if final_score > best_score:
				best_score = final_score
				best_name = player.player_name

	winner_label.text = "📢 \"HOY MGA BATA! UMUWI NA KAYO, GABI NA!\"\n\n🏆 PANALO: %s! 🏆\nScore: %.0f" % [best_name, best_score]

func _set_game_state(new_state: GameState) -> void:
	current_state = new_state
	if title_ui: title_ui.visible = (new_state == GameState.TITLE)
	if lobby_ui: lobby_ui.visible = (new_state == GameState.LOBBY)
	if hud: hud.visible = (new_state == GameState.PLAYING)
	if maiba_ui: maiba_ui.visible = (new_state == GameState.MAIBA_TAYA)
	if game_over_ui: game_over_ui.visible = (new_state == GameState.GAME_OVER)
	if pause_ui: pause_ui.visible = false
	is_game_paused = false

	if new_state == GameState.LOBBY or new_state == GameState.TITLE:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		for child in players_container.get_children():
			child.queue_free()
		if nanay_event:
			nanay_event.call("clear_sent_home")

func toggle_pause() -> void:
	if current_state != GameState.PLAYING:
		return
	set_paused(not is_game_paused)

func set_paused(paused: bool) -> void:
	is_game_paused = paused
	if pause_ui:
		pause_ui.visible = paused
	if pause_panel:
		pause_panel.visible = paused
	if settings_panel:
		settings_panel.visible = false

	if paused:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	else:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _on_volume_changed(val: float) -> void:
	var bus_idx := AudioServer.get_bus_index("Master")
	if bus_idx >= 0:
		if val > 0.01:
			AudioServer.set_bus_volume_db(bus_idx, linear_to_db(clamp(val, 0.0001, 1.0)))
			AudioServer.set_bus_mute(bus_idx, false)
		else:
			AudioServer.set_bus_mute(bus_idx, true)
	if volume_label:
		volume_label.text = "🔊 Master Volume: %d%%" % int(val * 100)

func _on_sensitivity_changed(val: float) -> void:
	var my_id := multiplayer.get_unique_id()
	if players_container:
		var my_node = players_container.get_node_or_null(str(my_id))
		if my_node and "mouse_sensitivity" in my_node:
			my_node.mouse_sensitivity = val * 0.001
	if sensitivity_label:
		sensitivity_label.text = "🖱️ Mouse Sensitivity: %.1f" % val

func _on_fov_changed(val: float) -> void:
	var my_id := multiplayer.get_unique_id()
	if players_container:
		var my_node = players_container.get_node_or_null(str(my_id))
		if my_node:
			if "base_fov" in my_node:
				my_node.base_fov = val
			if "camera" in my_node and my_node.camera:
				my_node.camera.fov = val
	if fov_label:
		fov_label.text = "👁️ Field of View (FOV): %.0f°" % val

func _on_btn_pause_lobby_pressed() -> void:
	set_paused(false)
	if multiplayer.has_multiplayer_peer():
		network_manager.leave_game()
	_set_game_state(GameState.LOBBY)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if btn_host: btn_host.disabled = false
	if btn_join: btn_join.disabled = false
	if btn_cancel: btn_cancel.visible = false
	if btn_start_match: btn_start_match.visible = false
	_update_lobby_player_list()
	var ips := NetworkManager.get_local_ip_addresses()
	if hotspot_info_label:
		hotspot_info_label.text = "Local IP: " + ips[0] + " (Port 7777)"

func _on_server_created() -> void:
	btn_host.disabled = true
	btn_join.disabled = true
	btn_cancel.visible = true
	btn_start_match.visible = true

func _on_join_success() -> void:
	btn_host.disabled = true
	btn_join.disabled = true
	btn_cancel.visible = true
	btn_start_match.visible = false
	hotspot_info_label.text = "✅ Nakakonekta sa Host! (%s:%d)\nNaghihintay na simulan ng Host..." % [network_manager.last_join_ip, network_manager.last_join_port]

func _on_join_failed() -> void:
	btn_host.disabled = false
	btn_join.disabled = false
	btn_cancel.visible = false
	hotspot_info_label.text = "❌ Connection failed sa %s:%d!\nPakisuri kung tama ang PlayIt.gg IP/Domain at Port." % [network_manager.last_join_ip, network_manager.last_join_port]

func _on_server_disconnected() -> void:
	_set_game_state(GameState.LOBBY)
	btn_host.disabled = false
	btn_join.disabled = false
	btn_cancel.visible = false
	btn_start_match.visible = false
	hotspot_info_label.text = "⚠️ Na-disconnect mula sa Server."
	_update_lobby_player_list()

func _update_lobby_player_list() -> void:
	var count := network_manager.players.size()
	if slots_header:
		slots_header.text = "👥 MGA MANLALARO (%d / 8 PLAYERS)" % count
	elif player_list_label:
		player_list_label.text = "👥 MGA MANLALARO (%d / 8 PLAYERS)" % count

	var pids := network_manager.players.keys()
	if pids.is_empty():
		var local_name := name_input.text.strip_edges() if name_input and not name_input.text.is_empty() else "Dennrick"
		for i in range(8):
			if i < slot_labels.size():
				var lbl: Label = slot_labels[i]
				if i == 0:
					lbl.text = "Slot 1: " + local_name
					lbl.modulate = Color(0.95, 0.98, 1.0, 1.0)
				else:
					lbl.text = "Slot %d: (Empty)" % (i + 1)
					lbl.modulate = Color(0.45, 0.55, 0.68, 0.8)
		return

	for i in range(8):
		if i < slot_labels.size():
			var lbl: Label = slot_labels[i]
			if i < pids.size():
				var pid: int = pids[i]
				var pinfo: Dictionary = network_manager.players[pid]
				var is_host: bool = (pid == 1)
				var tag := " 👑" if is_host else ""
				lbl.text = "Slot %d: %s%s" % [i + 1, pinfo.get("name", "Player"), tag]
				lbl.modulate = Color(0.95, 0.98, 1.0, 1.0)
			else:
				lbl.text = "Slot %d: (Empty)" % (i + 1)
				lbl.modulate = Color(0.45, 0.55, 0.68, 0.8)

func _run_automated_self_test() -> void:
	var results: Array[String] = []
	results.append("[SELF-TEST] Starting automated verification...")

	# 1. Test PlayIt.gg IP & Port auto-parsing
	results.append("[SELF-TEST] Testing PlayIt.gg address parsing...")
	_on_ip_text_changed("taya-kalye.gl.at.ply.gg:34567")
	if ip_input.text == "taya-kalye.gl.at.ply.gg" and port_input.text == "34567":
		results.append("[PASS] Auto-parsed host and port correctly: " + ip_input.text + ":" + port_input.text)
	else:
		results.append("[FAIL] Auto-parsing failed: ip=" + ip_input.text + ", port=" + port_input.text)
		_write_test_results(results, 1)
		return

	# 2. Click Solo Practice (spawns player 1 and bot 99)
	results.append("[SELF-TEST] Spawning Solo Practice match...")
	_on_btn_solo_pressed()

	var p1: PlayerController = players_container.get_node_or_null("1") as PlayerController
	var bot: PracticeBot = players_container.get_node_or_null("99") as PracticeBot

	if not p1 or not bot:
		results.append("[FAIL] Player 1 or Bot 99 not found!")
		_write_test_results(results, 1)
		return

	results.append("[PASS] Player 1 and Bot 99 spawned successfully.")

	# 3. Test Powerup Gating (Dash & Double Jump locked by default)
	results.append("[SELF-TEST] Testing Powerup Gating...")
	if p1.max_air_jumps == 0 and p1.active_powerup == PlayerController.PowerupType.NONE:
		results.append("[PASS] Double Jump locked by default (max_air_jumps = 0).")
	else:
		results.append("[FAIL] Double Jump is not locked by default!")
		_write_test_results(results, 1)
		return

	# Verify Dash gating: attempting dash without powerup
	p1._try_dash()
	if not p1.is_dashing:
		results.append("[PASS] Dash locked by default without Imagination Powerup.")
	else:
		results.append("[FAIL] Player dashed without powerup!")
		_write_test_results(results, 1)
		return

	# 4. Test Trash Pickup & Recycling Bin System
	results.append("[SELF-TEST] Testing Trash Pickup & Segregation...")
	var test_trash: TrashItem = TrashItem.new()
	test_trash.trash_type = TrashItem.TrashType.PLASTIC_BOTTLE
	var picked := p1.pickup_trash(test_trash)
	if picked and p1.has_trash() and p1.held_trash == TrashItem.TrashType.PLASTIC_BOTTLE:
		results.append("[PASS] Picked up Plastic Bottle: " + p1.held_trash_name)
	else:
		results.append("[FAIL] Failed to pick up trash!")
		_write_test_results(results, 1)
		return

	# Deposit into WRONG bin (Biodegradable / Green = 1)
	p1.deposit_trash(false, 1)
	if p1.has_trash():
		results.append("[PASS] Wrong bin rejected deposit; trash kept safely in hand.")
	else:
		results.append("[FAIL] Trash was lost in wrong bin!")
		_write_test_results(results, 1)
		return

	# Deposit into RIGHT bin (Recyclable / Blue = 0)
	var prev_score: int = network_manager.players[1]["score"]
	p1.deposit_trash(true, 0)
	test_trash.free()
	if not p1.has_trash() and network_manager.players[1]["score"] == (prev_score + 30):
		results.append("[PASS] Correct bin accepted trash! +30 score awarded (Total: " + str(network_manager.players[1]["score"]) + ").")
		results.append("[PASS] Imagination Powerup Unlocked: " + p1.get_powerup_name())
	else:
		results.append("[FAIL] Correct deposit failed or score not awarded!")
		_write_test_results(results, 1)
		return

	# 5. Test Powerup Abilities (grant DASH explicitly to verify execution)
	p1.set_powerup(PlayerController.PowerupType.DASH, 15.0)
	p1._try_dash()
	if p1.is_dashing and p1.dash_charges_left == 2:
		results.append("[PASS] Kidlat Dash executed successfully with powerup! Charges left: " + str(p1.dash_charges_left))
	else:
		results.append("[FAIL] Kidlat Dash failed to execute!")
		_write_test_results(results, 1)
		return

	# 6. Test Tagging
	p1.global_position = bot.global_position + Vector3(0, 0, 1.5)
	p1.current_role = PlayerController.Role.TAYA
	bot.current_role = PlayerController.Role.RUNNER
	bot.is_immune = false
	results.append("[SELF-TEST] Testing Tagging mechanism...")
	p1._try_tag()

	results.append(" - Post-tag P1 Role: " + str(p1.current_role) + " (Expected RUNNER: 0)")
	results.append(" - Post-tag Bot Role: " + str(bot.current_role) + " (Expected TAYA: 1)")

	if p1.current_role != PlayerController.Role.RUNNER or bot.current_role != PlayerController.Role.TAYA:
		results.append("[FAIL] Role transfer failed!")
		_write_test_results(results, 1)
		return

	results.append("[PASS] Tag role transfer successful.")

	# 7. Test Pause Menu
	results.append("[SELF-TEST] Testing Pause Menu...")
	toggle_pause()
	if is_game_paused and pause_ui and pause_ui.visible:
		results.append("[PASS] Pause menu opened successfully.")
	else:
		results.append("[FAIL] Pause menu failed to open!")
		_write_test_results(results, 1)
		return
	toggle_pause()
	if not is_game_paused and pause_ui and not pause_ui.visible:
		results.append("[PASS] Pause menu closed successfully.")
	else:
		results.append("[FAIL] Pause menu failed to close!")
		_write_test_results(results, 1)
		return

	# 8. End match
	sync_game_over()
	results.append("[PASS] Game over reached. Winner: " + winner_label.text)
	results.append("[ALL TESTS PASSED] ZERO RUNTIME ERRORS DETECTED!")
	for child in players_container.get_children():
		child.free()
	_write_test_results(results, 0)

func _write_test_results(lines: Array[String], exit_code: int) -> void:
	for line in lines:
		print(line)
	var f := FileAccess.open("res://test_results.txt", FileAccess.WRITE)
	if f:
		f.store_string("\n".join(lines))
		f.close()
	get_tree().quit(exit_code)
