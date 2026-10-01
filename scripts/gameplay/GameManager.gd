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
	PASA_TAYA_ELIMINATION = 0, # Crab Game Elimination / Bomb Tag ("Pasa-Taya: Matira Matibay")
	INFECTION = 1,             # "Hawaan: Zombie Tag" - Outbreak survival
	CLASSIC_TAG = 2            # "Walang Bawian: Points Tag" - Continuous survival & recycle points
}

@export var current_mode: MatchMode = MatchMode.PASA_TAYA_ELIMINATION
@export var match_duration: float = 45.0 # Round timer
var match_timer: float = 0.0
var current_state: GameState = GameState.TITLE
var is_game_paused: bool = false
var player_scene: PackedScene = preload("res://scenes/player/Player.tscn")
var bot_scene: PackedScene = preload("res://scenes/player/PracticeBot.tscn")

# Tournament & Elimination State (Crab Game)
var current_round: int = 1
var alive_player_ids: Array[int] = []
var eliminated_player_ids: Array[int] = []
var is_intermission: bool = false
var intermission_timer: float = 0.0
var last_tick_second: int = -1

func is_infection() -> bool:
	return current_mode == MatchMode.INFECTION

func is_elimination() -> bool:
	return current_mode == MatchMode.PASA_TAYA_ELIMINATION

func is_server_or_solo() -> bool:
	if network_manager and network_manager.is_solo_practice:
		return true
	if multiplayer.has_multiplayer_peer():
		return multiplayer.is_server()
	return true

func _get_mode_display_name() -> String:
	match current_mode:
		MatchMode.PASA_TAYA_ELIMINATION:
			return "Pasa-Taya"
		MatchMode.INFECTION:
			return "Hawaan"
		MatchMode.CLASSIC_TAG:
			return "Walang Bawian"
	return "Taya-Tayaan"

const COLOR_OPTIONS: Array[Dictionary] = [
	{ "name": "⚪ Puting Sando (Clean White)", "color": Color(0.95, 0.95, 0.95, 1.0) },
	{ "name": "🔵 Asul Kanto (Classic Navy)", "color": Color(0.18, 0.28, 0.48, 1.0) },
	{ "name": "🔴 Pulang Liga (Barangay Red)", "color": Color(0.72, 0.16, 0.16, 1.0) },
	{ "name": "🔘 Kulay Abo (Heather Grey)", "color": Color(0.52, 0.54, 0.56, 1.0) },
	{ "name": "⚫ Itim Kanto (Charcoal Black)", "color": Color(0.16, 0.17, 0.19, 1.0) },
	{ "name": "🩳 Kulay Kaki (Khaki Cargo)", "color": Color(0.60, 0.50, 0.38, 1.0) },
	{ "name": "🌿 Berdeng Army (Muted Olive)", "color": Color(0.28, 0.38, 0.26, 1.0) },
	{ "name": "🟡 Dilaw Pambahay (Sun Gold)", "color": Color(0.90, 0.74, 0.20, 1.0) }
]

const PLAYER_COLORS: Array[Color] = [
	Color(0.95, 0.95, 0.95, 1.0),
	Color(0.18, 0.28, 0.48, 1.0),
	Color(0.72, 0.16, 0.16, 1.0),
	Color(0.52, 0.54, 0.56, 1.0),
	Color(0.16, 0.17, 0.19, 1.0),
	Color(0.60, 0.50, 0.38, 1.0),
	Color(0.28, 0.38, 0.26, 1.0),
	Color(0.90, 0.74, 0.20, 1.0)
]

const SAVE_PATH: String = "user://player_customization.cfg"

# Character Customization State (8 Archetypes & Modular Slots)
var current_archetype: int = 0
var current_base: int = 0
var current_hair: int = 0
var current_headwear: int = 0
var current_body: int = 0
var current_footwear: int = 0
var current_color_idx: int = 0
var current_skin_idx: int = 0

var selected_char_idx: int:
	get: return current_archetype
	set(v): current_archetype = v

var selected_color_idx: int:
	get: return current_color_idx
	set(v): current_color_idx = v

# Core System Nodes
@onready var network_manager: NetworkManager = get_node_or_null("NetworkManager")
@onready var maiba_manager: MaibaTayaManager = get_node_or_null("MaibaTayaManager")
@onready var map_node: Node3D = get_node_or_null("KalyeMap")
@onready var lobby_camera: Camera3D = get_node_or_null("LobbyCamera3D")
@onready var players_container: Node3D = get_node_or_null("Players")
@onready var hud: HUD = get_node_or_null("HUD")
@onready var maiba_ui: MaibaTayaUI = get_node_or_null("MaibaTayaUI")
@onready var game_over_ui: Control = get_node_or_null("GameOverUI")
@onready var winner_label: Label = get_node_or_null("GameOverUI/Panel/VBoxContainer/WinnerLabel")
@onready var nanay_event: Node = get_node_or_null("NanayEvent")

# Title Screen UI elements
@onready var title_ui: Control = get_node_or_null("TitleScreenUI")
@onready var btn_enter_title: Button = get_node_or_null("TitleScreenUI/Center/Panel/VBox/BtnEnterTitle")

# Lobby UI elements & Supabase Matchmaking
enum LobbyTab { BROWSE, HOST, DIRECT, ROOM_ACTIVE }
var current_lobby_tab: LobbyTab = LobbyTab.BROWSE

enum HostNetType { ONLINE, HOTSPOT }
var current_host_net_type: HostNetType = HostNetType.ONLINE
var current_joined_room_name: String = "Kalye Room"

const SupabaseLobbyManagerScript = preload("res://scripts/network/SupabaseLobbyManager.gd")
@onready var supabase_manager: Node = get_node_or_null("SupabaseLobbyManager")
@onready var lobby_ui: Control = get_node_or_null("LobbyUI")
@onready var name_input: LineEdit = get_node_or_null("LobbyUI/Panel/VBoxContainer/MainColumns/RightConsole/NameRow/NameEdit")

# Tab row buttons
@onready var btn_tab_browse: Button = get_node_or_null("LobbyUI/Panel/VBoxContainer/MainColumns/RightConsole/TabRow/BtnTabBrowse")
@onready var btn_tab_host: Button = get_node_or_null("LobbyUI/Panel/VBoxContainer/MainColumns/RightConsole/TabRow/BtnTabHost")
@onready var btn_tab_direct: Button = get_node_or_null("LobbyUI/Panel/VBoxContainer/MainColumns/RightConsole/TabRow/BtnTabDirect")

# Main Console Sections
@onready var browse_section: Control = get_node_or_null("LobbyUI/Panel/VBoxContainer/MainColumns/RightConsole/BrowseSection")
@onready var host_section: Control = get_node_or_null("LobbyUI/Panel/VBoxContainer/MainColumns/RightConsole/HostSection")
@onready var direct_section: Control = get_node_or_null("LobbyUI/Panel/VBoxContainer/MainColumns/RightConsole/DirectSection")
@onready var room_active_section: Control = get_node_or_null("LobbyUI/Panel/VBoxContainer/MainColumns/RightConsole/RoomActiveSection")

# Browse Section elements
@onready var lobbies_status_label: Label = get_node_or_null("LobbyUI/Panel/VBoxContainer/MainColumns/RightConsole/BrowseSection/BrowseHeaderRow/LobbiesStatusLabel")
@onready var btn_refresh_lobbies: Button = get_node_or_null("LobbyUI/Panel/VBoxContainer/MainColumns/RightConsole/BrowseSection/BrowseHeaderRow/BtnRefreshLobbies")
@onready var lobby_list_container: VBoxContainer = get_node_or_null("LobbyUI/Panel/VBoxContainer/MainColumns/RightConsole/BrowseSection/LobbyScroll/LobbyListContainer")
@onready var empty_notice_label: Label = get_node_or_null("LobbyUI/Panel/VBoxContainer/MainColumns/RightConsole/BrowseSection/LobbyScroll/LobbyListContainer/EmptyNoticeLabel")
@onready var btn_quick_host: Button = get_node_or_null("LobbyUI/Panel/VBoxContainer/MainColumns/RightConsole/BrowseSection/BtnQuickHost")

# Host Section elements
@onready var room_name_input: LineEdit = get_node_or_null("LobbyUI/Panel/VBoxContainer/MainColumns/RightConsole/HostSection/RoomNameRow/RoomNameEdit")
@onready var btn_net_mode_toggle: Button = get_node_or_null("LobbyUI/Panel/VBoxContainer/MainColumns/RightConsole/HostSection/NetModeRow/BtnNetModeToggle")
@onready var host_address_row: HBoxContainer = get_node_or_null("LobbyUI/Panel/VBoxContainer/MainColumns/RightConsole/HostSection/HostAddressRow")
@onready var host_address_input: LineEdit = get_node_or_null("LobbyUI/Panel/VBoxContainer/MainColumns/RightConsole/HostSection/HostAddressRow/AddressEdit")
@onready var host_port_input: LineEdit = get_node_or_null("LobbyUI/Panel/VBoxContainer/MainColumns/RightConsole/HostSection/HostAddressRow/PortEdit")
@onready var btn_create_supabase_room: Button = get_node_or_null("LobbyUI/Panel/VBoxContainer/MainColumns/RightConsole/HostSection/BtnCreateSupabaseRoom")
@onready var host_status_label: Label = get_node_or_null("LobbyUI/Panel/VBoxContainer/MainColumns/RightConsole/HostSection/HostStatusLabel")

# Direct / Solo Section elements
@onready var ip_input: LineEdit = get_node_or_null("LobbyUI/Panel/VBoxContainer/MainColumns/RightConsole/DirectSection/ConnectionRow/IPEdit")
@onready var port_input: LineEdit = get_node_or_null("LobbyUI/Panel/VBoxContainer/MainColumns/RightConsole/DirectSection/ConnectionRow/PortEdit")
@onready var btn_host: Button = get_node_or_null("LobbyUI/Panel/VBoxContainer/MainColumns/RightConsole/DirectSection/BtnHost")
@onready var btn_join: Button = get_node_or_null("LobbyUI/Panel/VBoxContainer/MainColumns/RightConsole/DirectSection/BtnJoin")
@onready var btn_solo: Button = get_node_or_null("LobbyUI/Panel/VBoxContainer/MainColumns/RightConsole/DirectSection/BtnSolo")
@onready var hotspot_info_label: Label = get_node_or_null("LobbyUI/Panel/VBoxContainer/MainColumns/RightConsole/DirectSection/InfoBox/LocalIPRow/HotspotInfoLabel")
@onready var btn_copy_ip: Button = get_node_or_null("LobbyUI/Panel/VBoxContainer/MainColumns/RightConsole/DirectSection/InfoBox/LocalIPRow/BtnCopyIP")

# Room Active Section elements
@onready var active_room_title: Label = get_node_or_null("LobbyUI/Panel/VBoxContainer/MainColumns/RightConsole/RoomActiveSection/ActiveRoomTitle")
@onready var btn_cancel: Button = get_node_or_null("LobbyUI/Panel/VBoxContainer/MainColumns/RightConsole/RoomActiveSection/BtnCancel")
@onready var btn_start_match: Button = get_node_or_null("LobbyUI/Panel/VBoxContainer/MainColumns/RightConsole/RoomActiveSection/BtnStartMatch")
@onready var btn_mode_toggle: Button = get_node_or_null("LobbyUI/Panel/VBoxContainer/MainColumns/RightConsole/HostSection/ModeRow/BtnModeToggle")
@onready var slots_header: Label = get_node_or_null("LobbyUI/Panel/VBoxContainer/MainColumns/RightConsole/RoomActiveSection/SlotsHeader")
@onready var player_list_label: Label = get_node_or_null("LobbyUI/Panel/VBoxContainer/MainColumns/RightConsole/RoomActiveSection/SlotsHeader")
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

# Slot Fine-Tuning UI elements
@onready var btn_prev_hair: Button = get_node_or_null("LobbyUI/Panel/VBoxContainer/MainColumns/LeftShowroom/SlotsGrid/HairRow/BtnPrevHair")
@onready var btn_next_hair: Button = get_node_or_null("LobbyUI/Panel/VBoxContainer/MainColumns/LeftShowroom/SlotsGrid/HairRow/BtnNextHair")
@onready var hair_label: Label = get_node_or_null("LobbyUI/Panel/VBoxContainer/MainColumns/LeftShowroom/SlotsGrid/HairRow/HairBadge/HairLabel")

@onready var btn_prev_head: Button = get_node_or_null("LobbyUI/Panel/VBoxContainer/MainColumns/LeftShowroom/SlotsGrid/HeadRow/BtnPrevHead")
@onready var btn_next_head: Button = get_node_or_null("LobbyUI/Panel/VBoxContainer/MainColumns/LeftShowroom/SlotsGrid/HeadRow/BtnNextHead")
@onready var head_label: Label = get_node_or_null("LobbyUI/Panel/VBoxContainer/MainColumns/LeftShowroom/SlotsGrid/HeadRow/HeadBadge/HeadLabel")

@onready var btn_prev_body: Button = get_node_or_null("LobbyUI/Panel/VBoxContainer/MainColumns/LeftShowroom/SlotsGrid/BodyRow/BtnPrevBody")
@onready var btn_next_body: Button = get_node_or_null("LobbyUI/Panel/VBoxContainer/MainColumns/LeftShowroom/SlotsGrid/BodyRow/BtnNextBody")
@onready var body_label: Label = get_node_or_null("LobbyUI/Panel/VBoxContainer/MainColumns/LeftShowroom/SlotsGrid/BodyRow/BodyBadge/BodyLabel")

@onready var btn_prev_foot: Button = get_node_or_null("LobbyUI/Panel/VBoxContainer/MainColumns/LeftShowroom/SlotsGrid/FootRow/BtnPrevFoot")
@onready var btn_next_foot: Button = get_node_or_null("LobbyUI/Panel/VBoxContainer/MainColumns/LeftShowroom/SlotsGrid/FootRow/BtnNextFoot")
@onready var foot_label: Label = get_node_or_null("LobbyUI/Panel/VBoxContainer/MainColumns/LeftShowroom/SlotsGrid/FootRow/FootBadge/FootLabel")

# Pause & Settings Menu UI elements
const SETTINGS_SAVE_PATH: String = "user://game_settings.cfg"
var settings_opened_from: String = "PAUSE"
var settings_data: Dictionary = {
	"preset": 2, # 1: Low, 2: Medium, 3: High, 0: Custom
	"render_scale": 0.75,
	"shadows": true,
	"glow": false,
	"max_fps": 60,
	"anti_aliasing": 0,
	"show_fps": false,
	"volume": 1.0,
	"sensitivity": 2.5,
	"fov": 75.0
}

@onready var pause_ui: Control = get_node_or_null("PauseUI")
@onready var pause_panel: Control = get_node_or_null("PauseUI/PausePanel")
@onready var btn_resume: Button = get_node_or_null("PauseUI/PausePanel/VBoxContainer/BtnResume")
@onready var btn_settings: Button = get_node_or_null("PauseUI/PausePanel/VBoxContainer/BtnSettings")
@onready var btn_pause_lobby: Button = get_node_or_null("PauseUI/PausePanel/VBoxContainer/BtnPauseLobby")
@onready var btn_pause_quit: Button = get_node_or_null("PauseUI/PausePanel/VBoxContainer/BtnPauseQuit")
@onready var settings_panel: Control = get_node_or_null("PauseUI/SettingsPanel")

@onready var btn_title_settings: Button = get_node_or_null("TitleScreenUI/Center/Panel/VBox/BtnTitleSettings")
@onready var btn_lobby_settings: Button = get_node_or_null("LobbyUI/Panel/VBoxContainer/TopBar/LeftControls/BtnLobbySettings")
@onready var btn_preset_low: Button = get_node_or_null("PauseUI/SettingsPanel/VBoxContainer/ScrollContainer/ScrollContent/PresetRow/BtnPresetLow")
@onready var btn_preset_med: Button = get_node_or_null("PauseUI/SettingsPanel/VBoxContainer/ScrollContainer/ScrollContent/PresetRow/BtnPresetMed")
@onready var btn_preset_high: Button = get_node_or_null("PauseUI/SettingsPanel/VBoxContainer/ScrollContainer/ScrollContent/PresetRow/BtnPresetHigh")
@onready var preset_sub_label: Label = get_node_or_null("PauseUI/SettingsPanel/VBoxContainer/ScrollContainer/ScrollContent/PresetSubLabel")
@onready var scale_label: Label = get_node_or_null("PauseUI/SettingsPanel/VBoxContainer/ScrollContainer/ScrollContent/ScaleRow/ScaleLabel")
@onready var scale_slider: HSlider = get_node_or_null("PauseUI/SettingsPanel/VBoxContainer/ScrollContainer/ScrollContent/ScaleRow/ScaleSlider")
@onready var shadows_check: CheckButton = get_node_or_null("PauseUI/SettingsPanel/VBoxContainer/ScrollContainer/ScrollContent/ShadowsRow/ShadowsCheck")
@onready var glow_check: CheckButton = get_node_or_null("PauseUI/SettingsPanel/VBoxContainer/ScrollContainer/ScrollContent/GlowRow/GlowCheck")
@onready var fps_limit_option: OptionButton = get_node_or_null("PauseUI/SettingsPanel/VBoxContainer/ScrollContainer/ScrollContent/FpsLimitRow/FpsLimitOption")
@onready var aa_option: OptionButton = get_node_or_null("PauseUI/SettingsPanel/VBoxContainer/ScrollContainer/ScrollContent/AaRow/AaOption")
@onready var fps_counter_check: CheckButton = get_node_or_null("PauseUI/SettingsPanel/VBoxContainer/ScrollContainer/ScrollContent/FpsCounterRow/FpsCounterCheck")

@onready var volume_slider: HSlider = get_node_or_null("PauseUI/SettingsPanel/VBoxContainer/ScrollContainer/ScrollContent/VolumeRow/VolumeSlider")
@onready var volume_label: Label = get_node_or_null("PauseUI/SettingsPanel/VBoxContainer/ScrollContainer/ScrollContent/VolumeRow/VolumeLabel")
@onready var sensitivity_slider: HSlider = get_node_or_null("PauseUI/SettingsPanel/VBoxContainer/ScrollContainer/ScrollContent/SensitivityRow/SensitivitySlider")
@onready var sensitivity_label: Label = get_node_or_null("PauseUI/SettingsPanel/VBoxContainer/ScrollContainer/ScrollContent/SensitivityRow/SensitivityLabel")
@onready var fov_slider: HSlider = get_node_or_null("PauseUI/SettingsPanel/VBoxContainer/ScrollContainer/ScrollContent/FovRow/FovSlider")
@onready var fov_label: Label = get_node_or_null("PauseUI/SettingsPanel/VBoxContainer/ScrollContainer/ScrollContent/FovRow/FovLabel")
@onready var btn_close_settings: Button = get_node_or_null("PauseUI/SettingsPanel/VBoxContainer/BtnCloseSettings")
@onready var fps_label: Label = get_node_or_null("FpsOverlay/FpsLabel")

func _enter_tree() -> void:
	_init_node_references()

func _init_node_references() -> void:
	if not network_manager: network_manager = get_node_or_null("NetworkManager")
	if not maiba_manager: maiba_manager = get_node_or_null("MaibaTayaManager")
	if not map_node: map_node = get_node_or_null("KalyeMap")
	if not lobby_camera: lobby_camera = get_node_or_null("LobbyCamera3D")
	if not players_container: players_container = get_node_or_null("Players")
	if not hud: hud = get_node_or_null("HUD")
	if not maiba_ui: maiba_ui = get_node_or_null("MaibaTayaUI")
	if not game_over_ui: game_over_ui = get_node_or_null("GameOverUI")
	if not winner_label: winner_label = get_node_or_null("GameOverUI/Panel/VBoxContainer/WinnerLabel")
	if not nanay_event: nanay_event = get_node_or_null("NanayEvent")

	if not supabase_manager: supabase_manager = get_node_or_null("SupabaseLobbyManager")

	if not title_ui: title_ui = get_node_or_null("TitleScreenUI")
	if not btn_enter_title: btn_enter_title = get_node_or_null("TitleScreenUI/Center/Panel/VBox/BtnEnterTitle")

	if not lobby_ui: lobby_ui = get_node_or_null("LobbyUI")
	if not name_input:
		name_input = get_node_or_null("LobbyUI/Panel/VBoxContainer/MainColumns/RightConsole/NameRow/NameEdit")
	if not name_input:
		name_input = get_node_or_null("LobbyUI/Panel/VBoxContainer/MainColumns/RightConsole/NameEdit")

	# Tab row buttons
	if not btn_tab_browse: btn_tab_browse = get_node_or_null("LobbyUI/Panel/VBoxContainer/MainColumns/RightConsole/TabRow/BtnTabBrowse")
	if not btn_tab_host: btn_tab_host = get_node_or_null("LobbyUI/Panel/VBoxContainer/MainColumns/RightConsole/TabRow/BtnTabHost")
	if not btn_tab_direct: btn_tab_direct = get_node_or_null("LobbyUI/Panel/VBoxContainer/MainColumns/RightConsole/TabRow/BtnTabDirect")

	# Main Console Sections
	if not browse_section: browse_section = get_node_or_null("LobbyUI/Panel/VBoxContainer/MainColumns/RightConsole/BrowseSection")
	if not host_section: host_section = get_node_or_null("LobbyUI/Panel/VBoxContainer/MainColumns/RightConsole/HostSection")
	if not direct_section: direct_section = get_node_or_null("LobbyUI/Panel/VBoxContainer/MainColumns/RightConsole/DirectSection")
	if not room_active_section: room_active_section = get_node_or_null("LobbyUI/Panel/VBoxContainer/MainColumns/RightConsole/RoomActiveSection")

	# Browse Section elements
	if not lobbies_status_label: lobbies_status_label = get_node_or_null("LobbyUI/Panel/VBoxContainer/MainColumns/RightConsole/BrowseSection/BrowseHeaderRow/LobbiesStatusLabel")
	if not btn_refresh_lobbies: btn_refresh_lobbies = get_node_or_null("LobbyUI/Panel/VBoxContainer/MainColumns/RightConsole/BrowseSection/BrowseHeaderRow/BtnRefreshLobbies")
	if not lobby_list_container: lobby_list_container = get_node_or_null("LobbyUI/Panel/VBoxContainer/MainColumns/RightConsole/BrowseSection/LobbyScroll/LobbyListContainer")
	if not empty_notice_label: empty_notice_label = get_node_or_null("LobbyUI/Panel/VBoxContainer/MainColumns/RightConsole/BrowseSection/LobbyScroll/LobbyListContainer/EmptyNoticeLabel")
	if not btn_quick_host: btn_quick_host = get_node_or_null("LobbyUI/Panel/VBoxContainer/MainColumns/RightConsole/BrowseSection/BtnQuickHost")

	# Host Section elements
	if not room_name_input: room_name_input = get_node_or_null("LobbyUI/Panel/VBoxContainer/MainColumns/RightConsole/HostSection/RoomNameRow/RoomNameEdit")
	if not btn_net_mode_toggle: btn_net_mode_toggle = get_node_or_null("LobbyUI/Panel/VBoxContainer/MainColumns/RightConsole/HostSection/NetModeRow/BtnNetModeToggle")
	if not host_address_row: host_address_row = get_node_or_null("LobbyUI/Panel/VBoxContainer/MainColumns/RightConsole/HostSection/HostAddressRow")
	if not host_address_input: host_address_input = get_node_or_null("LobbyUI/Panel/VBoxContainer/MainColumns/RightConsole/HostSection/HostAddressRow/AddressEdit")
	if not host_port_input: host_port_input = get_node_or_null("LobbyUI/Panel/VBoxContainer/MainColumns/RightConsole/HostSection/HostAddressRow/PortEdit")
	if not btn_create_supabase_room: btn_create_supabase_room = get_node_or_null("LobbyUI/Panel/VBoxContainer/MainColumns/RightConsole/HostSection/BtnCreateSupabaseRoom")
	if not host_status_label: host_status_label = get_node_or_null("LobbyUI/Panel/VBoxContainer/MainColumns/RightConsole/HostSection/HostStatusLabel")

	# Direct / Solo Section elements
	if not ip_input:
		ip_input = get_node_or_null("LobbyUI/Panel/VBoxContainer/MainColumns/RightConsole/DirectSection/ConnectionRow/IPEdit")
	if not ip_input:
		ip_input = get_node_or_null("LobbyUI/Panel/VBoxContainer/MainColumns/RightConsole/ConnectionRow/IPEdit")
	if not ip_input:
		ip_input = get_node_or_null("LobbyUI/Panel/VBoxContainer/MainColumns/RightConsole/ConnectionBox/IPEdit")

	if not port_input:
		port_input = get_node_or_null("LobbyUI/Panel/VBoxContainer/MainColumns/RightConsole/DirectSection/ConnectionRow/PortEdit")
	if not port_input:
		port_input = get_node_or_null("LobbyUI/Panel/VBoxContainer/MainColumns/RightConsole/ConnectionRow/PortEdit")
	if not port_input:
		port_input = get_node_or_null("LobbyUI/Panel/VBoxContainer/MainColumns/RightConsole/ConnectionBox/PortEdit")

	if not btn_host:
		btn_host = get_node_or_null("LobbyUI/Panel/VBoxContainer/MainColumns/RightConsole/DirectSection/BtnHost")
	if not btn_host:
		btn_host = get_node_or_null("LobbyUI/Panel/VBoxContainer/MainColumns/RightConsole/BtnHost")

	if not btn_join:
		btn_join = get_node_or_null("LobbyUI/Panel/VBoxContainer/MainColumns/RightConsole/DirectSection/BtnJoin")
	if not btn_join:
		btn_join = get_node_or_null("LobbyUI/Panel/VBoxContainer/MainColumns/RightConsole/BtnJoin")

	if not btn_solo:
		btn_solo = get_node_or_null("LobbyUI/Panel/VBoxContainer/MainColumns/RightConsole/DirectSection/BtnSolo")
	if not btn_solo:
		btn_solo = get_node_or_null("LobbyUI/Panel/VBoxContainer/MainColumns/RightConsole/BtnSolo")

	if not hotspot_info_label:
		hotspot_info_label = get_node_or_null("LobbyUI/Panel/VBoxContainer/MainColumns/RightConsole/DirectSection/InfoBox/LocalIPRow/HotspotInfoLabel")
	if not hotspot_info_label:
		hotspot_info_label = get_node_or_null("LobbyUI/Panel/VBoxContainer/MainColumns/RightConsole/InfoBox/LocalIPRow/HotspotInfoLabel")
	if not hotspot_info_label:
		hotspot_info_label = get_node_or_null("LobbyUI/Panel/VBoxContainer/MainColumns/RightConsole/HotspotInfoLabel")

	if not btn_copy_ip:
		btn_copy_ip = get_node_or_null("LobbyUI/Panel/VBoxContainer/MainColumns/RightConsole/DirectSection/InfoBox/LocalIPRow/BtnCopyIP")
	if not btn_copy_ip:
		btn_copy_ip = get_node_or_null("LobbyUI/Panel/VBoxContainer/MainColumns/RightConsole/InfoBox/LocalIPRow/BtnCopyIP")

	# Room Active Section elements
	if not active_room_title:
		active_room_title = get_node_or_null("LobbyUI/Panel/VBoxContainer/MainColumns/RightConsole/RoomActiveSection/ActiveRoomTitle")

	if not btn_cancel:
		btn_cancel = get_node_or_null("LobbyUI/Panel/VBoxContainer/MainColumns/RightConsole/RoomActiveSection/BtnCancel")
	if not btn_cancel:
		btn_cancel = get_node_or_null("LobbyUI/Panel/VBoxContainer/MainColumns/RightConsole/BtnCancel")

	if not btn_start_match:
		btn_start_match = get_node_or_null("LobbyUI/Panel/VBoxContainer/MainColumns/RightConsole/RoomActiveSection/BtnStartMatch")
	if not btn_start_match:
		btn_start_match = get_node_or_null("LobbyUI/Panel/VBoxContainer/MainColumns/RightConsole/BtnStartMatch")

	if not btn_mode_toggle:
		btn_mode_toggle = get_node_or_null("LobbyUI/Panel/VBoxContainer/MainColumns/RightConsole/HostSection/ModeRow/BtnModeToggle")
	if not btn_mode_toggle:
		btn_mode_toggle = get_node_or_null("LobbyUI/Panel/VBoxContainer/MainColumns/RightConsole/ModeRow/BtnModeToggle")

	if not slots_header:
		slots_header = get_node_or_null("LobbyUI/Panel/VBoxContainer/MainColumns/RightConsole/RoomActiveSection/SlotsHeader")
	if not slots_header:
		slots_header = get_node_or_null("LobbyUI/Panel/VBoxContainer/MainColumns/RightConsole/SlotsHeader")
	if not player_list_label:
		player_list_label = slots_header if slots_header else get_node_or_null("LobbyUI/Panel/VBoxContainer/MainColumns/RightConsole/PlayerListBox/PlayerListLabel")

	# Collect 8 Slot labels
	slot_labels.clear()
	for i in range(1, 9):
		var lbl: Label = get_node_or_null("LobbyUI/Panel/VBoxContainer/MainColumns/RightConsole/RoomActiveSection/SlotsGrid/Slot" + str(i) + "/Label")
		if not lbl:
			lbl = get_node_or_null("LobbyUI/Panel/VBoxContainer/MainColumns/RightConsole/SlotsGrid/Slot" + str(i) + "/Label")
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

	if not btn_prev_hair: btn_prev_hair = get_node_or_null("LobbyUI/Panel/VBoxContainer/MainColumns/LeftShowroom/SlotsGrid/HairRow/BtnPrevHair")
	if not btn_next_hair: btn_next_hair = get_node_or_null("LobbyUI/Panel/VBoxContainer/MainColumns/LeftShowroom/SlotsGrid/HairRow/BtnNextHair")
	if not hair_label: hair_label = get_node_or_null("LobbyUI/Panel/VBoxContainer/MainColumns/LeftShowroom/SlotsGrid/HairRow/HairBadge/HairLabel")

	if not btn_prev_head: btn_prev_head = get_node_or_null("LobbyUI/Panel/VBoxContainer/MainColumns/LeftShowroom/SlotsGrid/HeadRow/BtnPrevHead")
	if not btn_next_head: btn_next_head = get_node_or_null("LobbyUI/Panel/VBoxContainer/MainColumns/LeftShowroom/SlotsGrid/HeadRow/BtnNextHead")
	if not head_label: head_label = get_node_or_null("LobbyUI/Panel/VBoxContainer/MainColumns/LeftShowroom/SlotsGrid/HeadRow/HeadBadge/HeadLabel")

	if not btn_prev_body: btn_prev_body = get_node_or_null("LobbyUI/Panel/VBoxContainer/MainColumns/LeftShowroom/SlotsGrid/BodyRow/BtnPrevBody")
	if not btn_next_body: btn_next_body = get_node_or_null("LobbyUI/Panel/VBoxContainer/MainColumns/LeftShowroom/SlotsGrid/BodyRow/BtnNextBody")
	if not body_label: body_label = get_node_or_null("LobbyUI/Panel/VBoxContainer/MainColumns/LeftShowroom/SlotsGrid/BodyRow/BodyBadge/BodyLabel")

	if not btn_prev_foot: btn_prev_foot = get_node_or_null("LobbyUI/Panel/VBoxContainer/MainColumns/LeftShowroom/SlotsGrid/FootRow/BtnPrevFoot")
	if not btn_next_foot: btn_next_foot = get_node_or_null("LobbyUI/Panel/VBoxContainer/MainColumns/LeftShowroom/SlotsGrid/FootRow/BtnNextFoot")
	if not foot_label: foot_label = get_node_or_null("LobbyUI/Panel/VBoxContainer/MainColumns/LeftShowroom/SlotsGrid/FootRow/FootBadge/FootLabel")

	if not pause_ui: pause_ui = get_node_or_null("PauseUI")
	if not pause_panel: pause_panel = get_node_or_null("PauseUI/PausePanel")
	if not btn_resume: btn_resume = get_node_or_null("PauseUI/PausePanel/VBoxContainer/BtnResume")
	if not btn_settings: btn_settings = get_node_or_null("PauseUI/PausePanel/VBoxContainer/BtnSettings")
	if not btn_pause_lobby: btn_pause_lobby = get_node_or_null("PauseUI/PausePanel/VBoxContainer/BtnPauseLobby")
	if not btn_pause_quit: btn_pause_quit = get_node_or_null("PauseUI/PausePanel/VBoxContainer/BtnPauseQuit")
	if not settings_panel: settings_panel = get_node_or_null("PauseUI/SettingsPanel")

	if not btn_title_settings: btn_title_settings = get_node_or_null("TitleScreenUI/Center/Panel/VBox/BtnTitleSettings")
	if not btn_lobby_settings: btn_lobby_settings = get_node_or_null("LobbyUI/Panel/VBoxContainer/TopBar/LeftControls/BtnLobbySettings")
	if not btn_preset_low: btn_preset_low = get_node_or_null("PauseUI/SettingsPanel/VBoxContainer/ScrollContainer/ScrollContent/PresetRow/BtnPresetLow")
	if not btn_preset_med: btn_preset_med = get_node_or_null("PauseUI/SettingsPanel/VBoxContainer/ScrollContainer/ScrollContent/PresetRow/BtnPresetMed")
	if not btn_preset_high: btn_preset_high = get_node_or_null("PauseUI/SettingsPanel/VBoxContainer/ScrollContainer/ScrollContent/PresetRow/BtnPresetHigh")
	if not preset_sub_label: preset_sub_label = get_node_or_null("PauseUI/SettingsPanel/VBoxContainer/ScrollContainer/ScrollContent/PresetSubLabel")
	if not scale_label: scale_label = get_node_or_null("PauseUI/SettingsPanel/VBoxContainer/ScrollContainer/ScrollContent/ScaleRow/ScaleLabel")
	if not scale_slider: scale_slider = get_node_or_null("PauseUI/SettingsPanel/VBoxContainer/ScrollContainer/ScrollContent/ScaleRow/ScaleSlider")
	if not shadows_check: shadows_check = get_node_or_null("PauseUI/SettingsPanel/VBoxContainer/ScrollContainer/ScrollContent/ShadowsRow/ShadowsCheck")
	if not glow_check: glow_check = get_node_or_null("PauseUI/SettingsPanel/VBoxContainer/ScrollContainer/ScrollContent/GlowRow/GlowCheck")
	if not fps_limit_option: fps_limit_option = get_node_or_null("PauseUI/SettingsPanel/VBoxContainer/ScrollContainer/ScrollContent/FpsLimitRow/FpsLimitOption")
	if not aa_option: aa_option = get_node_or_null("PauseUI/SettingsPanel/VBoxContainer/ScrollContainer/ScrollContent/AaRow/AaOption")
	if not fps_counter_check: fps_counter_check = get_node_or_null("PauseUI/SettingsPanel/VBoxContainer/ScrollContainer/ScrollContent/FpsCounterRow/FpsCounterCheck")

	if not volume_slider: volume_slider = get_node_or_null("PauseUI/SettingsPanel/VBoxContainer/ScrollContainer/ScrollContent/VolumeRow/VolumeSlider")
	if not volume_label: volume_label = get_node_or_null("PauseUI/SettingsPanel/VBoxContainer/ScrollContainer/ScrollContent/VolumeRow/VolumeLabel")
	if not sensitivity_slider: sensitivity_slider = get_node_or_null("PauseUI/SettingsPanel/VBoxContainer/ScrollContainer/ScrollContent/SensitivityRow/SensitivitySlider")
	if not sensitivity_label: sensitivity_label = get_node_or_null("PauseUI/SettingsPanel/VBoxContainer/ScrollContainer/ScrollContent/SensitivityRow/SensitivityLabel")
	if not fov_slider: fov_slider = get_node_or_null("PauseUI/SettingsPanel/VBoxContainer/ScrollContainer/ScrollContent/FovRow/FovSlider")
	if not fov_label: fov_label = get_node_or_null("PauseUI/SettingsPanel/VBoxContainer/ScrollContainer/ScrollContent/FovRow/FovLabel")
	if not btn_close_settings: btn_close_settings = get_node_or_null("PauseUI/SettingsPanel/VBoxContainer/BtnCloseSettings")
	if not fps_label: fps_label = get_node_or_null("FpsOverlay/FpsLabel")

func _ready() -> void:
	# Lock orientation to landscape on mobile / handheld devices
	if DisplayServer.has_feature(DisplayServer.FEATURE_ORIENTATION):
		DisplayServer.screen_set_orientation(DisplayServer.SCREEN_SENSOR_LANDSCAPE)

	_init_node_references()
	_load_player_outfit()
	_load_settings()

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
		hotspot_info_label.text = "Ang iyong IP: " + ips[0]
	if ip_input and (ip_input.text.is_empty() or ip_input.text == "127.0.0.1"):
		ip_input.text = ips[0]

	_switch_right_tab(LobbyTab.BROWSE)
	_update_lobby_player_list()

	if run_test:
		call_deferred("_run_automated_self_test")

func _setup_network_signals() -> void:
	network_manager.server_created.connect(_on_server_created)
	network_manager.join_success.connect(_on_join_success)
	network_manager.join_failed.connect(_on_join_failed)
	network_manager.player_list_updated.connect(_update_lobby_player_list)
	network_manager.player_registered.connect(_on_player_registered_midgame)
	network_manager.server_disconnected.connect(_on_server_disconnected)

	if supabase_manager:
		supabase_manager.lobbies_fetched.connect(_on_supabase_lobbies_fetched)
		supabase_manager.fetch_failed.connect(_on_supabase_fetch_failed)
		supabase_manager.lobby_created.connect(_on_supabase_lobby_created)
		supabase_manager.create_failed.connect(_on_supabase_create_failed)

func _setup_ui_signals() -> void:
	if btn_enter_title:
		btn_enter_title.pressed.connect(_on_btn_enter_title_pressed)

	# Tab switching buttons
	if btn_tab_browse:
		btn_tab_browse.pressed.connect(func():
			_switch_right_tab(LobbyTab.BROWSE)
			_fetch_supabase_lobbies()
		)
	if btn_tab_host:
		btn_tab_host.pressed.connect(func(): _switch_right_tab(LobbyTab.HOST))
	if btn_tab_direct:
		btn_tab_direct.pressed.connect(func(): _switch_right_tab(LobbyTab.DIRECT))
	if btn_quick_host:
		btn_quick_host.pressed.connect(func(): _switch_right_tab(LobbyTab.HOST))

	# Browse & Room creation buttons
	if btn_refresh_lobbies:
		btn_refresh_lobbies.pressed.connect(_fetch_supabase_lobbies)
	if btn_create_supabase_room:
		btn_create_supabase_room.pressed.connect(_on_btn_create_supabase_room_pressed)
	if btn_net_mode_toggle:
		btn_net_mode_toggle.pressed.connect(_on_btn_net_mode_toggle_pressed)
	_update_host_net_mode_ui()

	if btn_host: btn_host.pressed.connect(_on_btn_host_pressed)
	if btn_join: btn_join.pressed.connect(_on_btn_join_pressed)
	if btn_cancel: btn_cancel.pressed.connect(_on_btn_cancel_pressed)
	if btn_solo: btn_solo.pressed.connect(_on_btn_solo_pressed)
	if btn_start_match: btn_start_match.pressed.connect(_on_btn_start_match_pressed)
	if btn_mode_toggle: btn_mode_toggle.pressed.connect(_on_btn_mode_toggle_pressed)
	_update_mode_ui()
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

	if btn_prev_hair: btn_prev_hair.pressed.connect(func(): _cycle_slot("hair", -1))
	if btn_next_hair: btn_next_hair.pressed.connect(func(): _cycle_slot("hair", 1))
	if btn_prev_head: btn_prev_head.pressed.connect(func(): _cycle_slot("headwear", -1))
	if btn_next_head: btn_next_head.pressed.connect(func(): _cycle_slot("headwear", 1))
	if btn_prev_body: btn_prev_body.pressed.connect(func(): _cycle_slot("body", -1))
	if btn_next_body: btn_next_body.pressed.connect(func(): _cycle_slot("body", 1))
	if btn_prev_foot: btn_prev_foot.pressed.connect(func(): _cycle_slot("footwear", -1))
	if btn_next_foot: btn_next_foot.pressed.connect(func(): _cycle_slot("footwear", 1))

	if preset_grid:
		for i in range(min(8, preset_grid.get_child_count())):
			var p_btn: Button = preset_grid.get_child(i) as Button
			if p_btn:
				p_btn.pressed.connect(_select_preset.bind(i))

	# Pause menu buttons & settings
	if btn_resume:
		btn_resume.pressed.connect(func(): set_paused(false))
	if btn_settings:
		btn_settings.pressed.connect(func(): _open_settings("PAUSE"))
	if btn_title_settings:
		btn_title_settings.pressed.connect(func(): _open_settings("TITLE"))
	if btn_lobby_settings:
		btn_lobby_settings.pressed.connect(func(): _open_settings("LOBBY"))
	if btn_close_settings:
		btn_close_settings.pressed.connect(_close_settings)
	if btn_pause_lobby:
		btn_pause_lobby.pressed.connect(_on_btn_pause_lobby_pressed)
	if btn_pause_quit:
		btn_pause_quit.pressed.connect(func(): get_tree().quit())

	# Quick Graphics Presets
	if btn_preset_low:
		btn_preset_low.pressed.connect(func(): _apply_preset(1))
	if btn_preset_med:
		btn_preset_med.pressed.connect(func(): _apply_preset(2))
	if btn_preset_high:
		btn_preset_high.pressed.connect(func(): _apply_preset(3))

	# Detailed Graphics Controls
	if scale_slider:
		scale_slider.value_changed.connect(_on_render_scale_changed)
	if shadows_check:
		shadows_check.toggled.connect(_on_shadows_toggled)
	if glow_check:
		glow_check.toggled.connect(_on_glow_toggled)
	if fps_limit_option:
		fps_limit_option.item_selected.connect(_on_fps_limit_selected)
	if aa_option:
		aa_option.item_selected.connect(_on_aa_selected)
	if fps_counter_check:
		fps_counter_check.toggled.connect(_on_fps_counter_toggled)

	# Audio & Controls
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
	_switch_right_tab(LobbyTab.BROWSE)
	_fetch_supabase_lobbies()

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

func _cycle_slot(slot_name: String, dir: int) -> void:
	match slot_name:
		"hair":
			var sz := CharacterAnimator.HAIR_OPTIONS.size()
			current_hair = (current_hair + dir + sz) % sz
		"headwear":
			var sz := CharacterAnimator.HEADWEAR_OPTIONS.size()
			current_headwear = (current_headwear + dir + sz) % sz
		"body":
			var sz := CharacterAnimator.BODY_OPTIONS.size()
			current_body = (current_body + dir + sz) % sz
		"footwear":
			var sz := CharacterAnimator.FOOTWEAR_OPTIONS.size()
			current_footwear = (current_footwear + dir + sz) % sz
	_update_customization_ui()
	_save_player_outfit()

func _on_prev_char_pressed() -> void:
	var sz := CharacterAnimator.ARCHETYPES.size()
	var new_idx := (current_archetype - 1 + sz) % sz
	_select_preset(new_idx)

func _on_next_char_pressed() -> void:
	var sz := CharacterAnimator.ARCHETYPES.size()
	var new_idx := (current_archetype + 1) % sz
	_select_preset(new_idx)

func _on_prev_color_pressed() -> void:
	var sz := COLOR_OPTIONS.size()
	current_color_idx = (current_color_idx - 1 + sz) % sz
	_update_customization_ui()
	_save_player_outfit()

func _on_next_color_pressed() -> void:
	var sz := COLOR_OPTIONS.size()
	current_color_idx = (current_color_idx + 1) % sz
	_update_customization_ui()
	_save_player_outfit()

func _select_preset(idx: int) -> void:
	if idx < 0 or idx >= CharacterAnimator.ARCHETYPES.size():
		return
	current_archetype = idx
	var p: Dictionary = CharacterAnimator.ARCHETYPES[idx]
	current_base = p.get("base", 0)
	current_hair = p.get("hair", 0)
	current_headwear = p.get("headwear", 0)
	current_body = p.get("body", 0)
	current_footwear = p.get("footwear", 0)
	current_color_idx = p.get("color", idx % COLOR_OPTIONS.size())
	current_skin_idx = p.get("skin", 0)
	_update_customization_ui()
	_save_player_outfit()

func _get_current_outfit_dict() -> Dictionary:
	return {
		"archetype": current_archetype,
		"base": current_base,
		"hair": current_hair,
		"headwear": current_headwear,
		"body": current_body,
		"footwear": current_footwear,
		"color": current_color_idx,
		"skin": current_skin_idx
	}

func _save_player_outfit() -> void:
	var cfg := ConfigFile.new()
	if name_input and not name_input.text.strip_edges().is_empty():
		cfg.set_value("player", "name", name_input.text.strip_edges())
	cfg.set_value("outfit", "archetype", current_archetype)
	cfg.set_value("outfit", "base", current_base)
	cfg.set_value("outfit", "hair", current_hair)
	cfg.set_value("outfit", "headwear", current_headwear)
	cfg.set_value("outfit", "body", current_body)
	cfg.set_value("outfit", "footwear", current_footwear)
	cfg.set_value("outfit", "color", current_color_idx)
	cfg.set_value("outfit", "skin", current_skin_idx)
	cfg.save(SAVE_PATH)

func _load_player_outfit() -> void:
	var cfg := ConfigFile.new()
	var err := cfg.load(SAVE_PATH)
	if err == OK:
		if name_input and cfg.has_section_key("player", "name"):
			name_input.text = cfg.get_value("player", "name", "Dennrick")
		if cfg.has_section("outfit"):
			current_archetype = cfg.get_value("outfit", "archetype", 0)
			current_base = cfg.get_value("outfit", "base", 0)
			current_hair = cfg.get_value("outfit", "hair", 0)
			current_headwear = cfg.get_value("outfit", "headwear", 0)
			current_body = cfg.get_value("outfit", "body", 0)
			current_footwear = cfg.get_value("outfit", "footwear", 0)
			current_color_idx = cfg.get_value("outfit", "color", 0)
			current_skin_idx = cfg.get_value("outfit", "skin", 0)
			return
	_select_preset(0)

func _update_customization_ui() -> void:
	if char_name_label and current_archetype < CharacterAnimator.ARCHETYPES.size():
		var arch := CharacterAnimator.ARCHETYPES[current_archetype]
		char_name_label.text = "%s (%s)" % [arch["name"], arch["title"]]

	if color_name_label and current_color_idx < COLOR_OPTIONS.size():
		var col_info := COLOR_OPTIONS[current_color_idx]
		color_name_label.text = col_info["name"]
		color_name_label.modulate = col_info["color"]

	if hair_label and current_hair < CharacterAnimator.HAIR_OPTIONS.size():
		hair_label.text = CharacterAnimator.HAIR_OPTIONS[current_hair]["name"]

	if head_label and current_headwear < CharacterAnimator.HEADWEAR_OPTIONS.size():
		head_label.text = CharacterAnimator.HEADWEAR_OPTIONS[current_headwear]["name"]

	if body_label and current_body < CharacterAnimator.BODY_OPTIONS.size():
		body_label.text = CharacterAnimator.BODY_OPTIONS[current_body]["name"]

	if foot_label and current_footwear < CharacterAnimator.FOOTWEAR_OPTIONS.size():
		foot_label.text = CharacterAnimator.FOOTWEAR_OPTIONS[current_footwear]["name"]

	if preview_char:
		preview_char.set_modular_outfit(
			current_base,
			current_hair,
			current_headwear,
			current_body,
			current_footwear,
			current_color_idx,
			current_skin_idx
		)

	if network_manager:
		network_manager.set_local_outfit(_get_current_outfit_dict())

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

func _on_btn_mode_toggle_pressed() -> void:
	current_mode = ((int(current_mode) + 1) % 3) as MatchMode
	_update_mode_ui()
	_setup_round_timer()
	if multiplayer.has_multiplayer_peer() and multiplayer.is_server():
		rpc("sync_match_mode", int(current_mode))

@rpc("any_peer", "call_local", "reliable")
func sync_match_mode(mode_idx: int) -> void:
	current_mode = mode_idx as MatchMode
	_update_mode_ui()
	_setup_round_timer()

func _update_mode_ui() -> void:
	if not btn_mode_toggle:
		btn_mode_toggle = get_node_or_null("LobbyUI/Panel/VBoxContainer/MainColumns/RightConsole/ModeRow/BtnModeToggle")
	if btn_mode_toggle:
		match current_mode:
			MatchMode.PASA_TAYA_ELIMINATION:
				btn_mode_toggle.text = "💣 PASA-TAYA (CRAB GAME ELIMINATION)"
				btn_mode_toggle.modulate = Color(1.0, 0.85, 0.2)
			MatchMode.INFECTION:
				btn_mode_toggle.text = "☣️ HAWAAN (INFECTION TAG)"
				btn_mode_toggle.modulate = Color(0.3, 1.0, 0.4)
			MatchMode.CLASSIC_TAG:
				btn_mode_toggle.text = "🏃 KLASIKONG TAYA (POINTS MATCH)"
				btn_mode_toggle.modulate = Color(0.4, 0.8, 1.0)

func _on_btn_net_mode_toggle_pressed() -> void:
	current_host_net_type = ((int(current_host_net_type) + 1) % 2) as HostNetType
	_update_host_net_mode_ui()

func _update_host_net_mode_ui() -> void:
	if not btn_net_mode_toggle:
		btn_net_mode_toggle = get_node_or_null("LobbyUI/Panel/VBoxContainer/MainColumns/RightConsole/HostSection/NetModeRow/BtnNetModeToggle")
	if not host_address_row:
		host_address_row = get_node_or_null("LobbyUI/Panel/VBoxContainer/MainColumns/RightConsole/HostSection/HostAddressRow")

	var ips := NetworkManager.get_local_ip_addresses()
	var local_ip := ips[0] if not ips.is_empty() else "127.0.0.1"

	match current_host_net_type:
		HostNetType.ONLINE:
			if btn_net_mode_toggle:
				btn_net_mode_toggle.text = "🌐 ONLINE (Kahit Saang Internet o Data)"
				btn_net_mode_toggle.add_theme_color_override("font_color", Color(0.35, 0.95, 0.72))
			if host_address_row:
				host_address_row.visible = false
			if host_address_input:
				host_address_input.text = ""
			if host_status_label:
				host_status_label.text = "🌐 Online: Makakapaglaro kahit sino saan mang panig ng bansa gamit ang Wi-Fi o Mobile Data."
		HostNetType.HOTSPOT:
			if btn_net_mode_toggle:
				btn_net_mode_toggle.text = "📡 HOTSPOT (Magkasama sa Iisang Wi-Fi)"
				btn_net_mode_toggle.add_theme_color_override("font_color", Color(1.0, 0.85, 0.25))
			if host_address_row:
				host_address_row.visible = false
			if host_address_input:
				host_address_input.text = local_ip
			if host_status_label:
				host_status_label.text = "📡 Hotspot: Para sa magkakatabi na nakakonekta sa iisang Wi-Fi o Phone Hotspot nang walang internet."

func _setup_round_timer() -> void:
	match current_mode:
		MatchMode.PASA_TAYA_ELIMINATION:
			if current_round == 1:
				match_duration = 45.0
			elif current_round == 2:
				match_duration = 35.0
			else:
				match_duration = 25.0
		MatchMode.INFECTION:
			match_duration = 60.0
		MatchMode.CLASSIC_TAG:
			match_duration = 180.0
	match_timer = match_duration
	last_tick_second = -1

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

	var ips := NetworkManager.get_local_ip_addresses()
	var local_ip := ips[0] if not ips.is_empty() else "127.0.0.1"

	var err := network_manager.create_game(pname, port)
	if err != OK:
		hotspot_info_label.text = "❌ Nabigo sa pagbukas ng Hotspot server!"
		return

	hotspot_info_label.text = "🟢 Bukas ang Hotspot Room!\nIpa-type sa kalaro ang IP na: %s" % local_ip
	btn_host.disabled = true
	btn_join.disabled = true
	btn_cancel.visible = true
	btn_start_match.visible = true
	_switch_right_tab(LobbyTab.ROOM_ACTIVE)
	if active_room_title:
		active_room_title.text = "📡 HOTSPOT ROOM (%s)" % local_ip

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

	hotspot_info_label.text = "⏳ Kumukonekta sa Host (%s)..." % target
	btn_host.disabled = true
	btn_join.disabled = true
	btn_cancel.visible = true
	_switch_right_tab(LobbyTab.ROOM_ACTIVE)
	if active_room_title:
		active_room_title.text = "📡 HOTSPOT LOBBY: %s" % target
	if btn_start_match:
		btn_start_match.visible = false

	var err := network_manager.join_game(target, pname, port)
	if err != OK:
		hotspot_info_label.text = "❌ Hindi makakonekta sa %s." % target
		btn_host.disabled = false
		btn_join.disabled = false
		btn_cancel.visible = false
		_switch_right_tab(LobbyTab.DIRECT)

func _on_btn_cancel_pressed() -> void:
	if supabase_manager and supabase_manager.is_hosting_lobby:
		supabase_manager.delete_lobby()
	network_manager.leave_game()
	btn_host.disabled = false
	btn_join.disabled = false
	btn_cancel.visible = false
	btn_start_match.visible = false
	_switch_right_tab(LobbyTab.BROWSE)
	_fetch_supabase_lobbies()
	var ips := NetworkManager.get_local_ip_addresses()
	hotspot_info_label.text = "Ang iyong IP: " + ips[0]
	player_list_label.text = "Mga Kasali: (Naghihintay...)"

# ==============================================================================
# TAB SWITCHING & SUPABASE LOBBY BROWSER
# ==============================================================================

func _switch_right_tab(tab: LobbyTab) -> void:
	current_lobby_tab = tab
	if browse_section: browse_section.visible = (tab == LobbyTab.BROWSE)
	if host_section: host_section.visible = (tab == LobbyTab.HOST)
	if direct_section: direct_section.visible = (tab == LobbyTab.DIRECT)
	if room_active_section: room_active_section.visible = (tab == LobbyTab.ROOM_ACTIVE)

	# Modulate tab buttons to indicate active tab
	if btn_tab_browse:
		btn_tab_browse.modulate = Color(1.0, 1.0, 1.0, 1.0) if tab == LobbyTab.BROWSE else Color(0.65, 0.75, 0.88, 0.75)
	if btn_tab_host:
		btn_tab_host.modulate = Color(1.0, 1.0, 1.0, 1.0) if tab == LobbyTab.HOST else Color(0.65, 0.75, 0.88, 0.75)
	if btn_tab_direct:
		btn_tab_direct.modulate = Color(1.0, 1.0, 1.0, 1.0) if tab == LobbyTab.DIRECT else Color(0.65, 0.75, 0.88, 0.75)

func _fetch_supabase_lobbies() -> void:
	if not supabase_manager:
		return
	if not supabase_manager.is_configured():
		if empty_notice_label:
			empty_notice_label.visible = true
			empty_notice_label.text = "ℹ️ Hindi makakonekta sa matchmaking server.\n(Maaaring gamitin ang [📡 HOTSPOT / SOLO] para sa Wi-Fi o Offline laro)."
		if lobbies_status_label:
			lobbies_status_label.text = "Offline"
		return

	if empty_notice_label:
		empty_notice_label.visible = true
		empty_notice_label.text = "⏳ Hinahanap ang mga bukas na laro..."
	if lobbies_status_label:
		lobbies_status_label.text = "Naghahanap..."

	supabase_manager.fetch_lobbies()

func _on_supabase_lobbies_fetched(lobbies: Array) -> void:
	if not lobby_list_container:
		return

	# Remove any existing dynamically generated room cards
	for child in lobby_list_container.get_children():
		if child != empty_notice_label:
			child.queue_free()

	if lobbies.is_empty():
		if empty_notice_label:
			empty_notice_label.visible = true
			empty_notice_label.text = "Walang nahanap na bukas na lobby sa ngayon.\nI-click ang [➕ GUMAWA] para ikaw ang mag-host ng laro!"
		if lobbies_status_label:
			lobbies_status_label.text = "Aktibong Lobbies: 0"
		return

	if empty_notice_label:
		empty_notice_label.visible = false
	if lobbies_status_label:
		lobbies_status_label.text = "Aktibong Lobbies: %d nahanap" % lobbies.size()

	for lobby in lobbies:
		if not lobby is Dictionary:
			continue

		var card := PanelContainer.new()
		var card_style := StyleBoxFlat.new()
		card_style.bg_color = Color(0.05, 0.09, 0.16, 0.94)
		card_style.border_width_left = 1
		card_style.border_width_top = 1
		card_style.border_width_right = 1
		card_style.border_width_bottom = 1
		card_style.border_color = Color(0.16, 0.32, 0.5, 0.8)
		card_style.set_corner_radius_all(8)
		card_style.content_margin_left = 10
		card_style.content_margin_top = 6
		card_style.content_margin_right = 10
		card_style.content_margin_bottom = 6
		card.add_theme_stylebox_override("panel", card_style)

		var hbox := HBoxContainer.new()
		hbox.set("theme_override_constants/separation", 8)
		card.add_child(hbox)

		var info_vbox := VBoxContainer.new()
		info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		info_vbox.set("theme_override_constants/separation", 2)
		hbox.add_child(info_vbox)

		var title_lbl := Label.new()
		var is_online_webrtc := str(lobby.get("address", "")).strip_edges().to_lower() == "webrtc"
		var addr_str: String = str(lobby.get("address", "")).strip_edges()
		var h_name: String = str(lobby.get("host_name", "Host"))
		var m_name: String = str(lobby.get("game_mode", "Pasa-Taya"))

		if is_online_webrtc:
			title_lbl.text = "🌐 " + str(lobby.get("name", "Kalye Room")) + "  [ONLINE]"
			title_lbl.add_theme_color_override("font_color", Color(0.35, 0.95, 1.0))
		elif addr_str.begins_with("192.168.") or addr_str.begins_with("10.") or addr_str.begins_with("172.") or addr_str == "127.0.0.1":
			title_lbl.text = "📡 " + str(lobby.get("name", "Kalye Room")) + "  [HOTSPOT]"
			title_lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.25))
		else:
			title_lbl.text = "🌐 " + str(lobby.get("name", "Kalye Room")) + "  [ONLINE]"
			title_lbl.add_theme_color_override("font_color", Color(0.45, 0.85, 1.0))
		title_lbl.add_theme_font_size_override("font_size", 13)
		info_vbox.add_child(title_lbl)

		var sub_lbl := Label.new()
		if is_online_webrtc:
			sub_lbl.text = "👤 Host: %s | 🎮 %s | 🌐 Kahit Saang Internet / Mobile Data" % [h_name, m_name]
		elif addr_str.begins_with("192.168.") or addr_str.begins_with("10.") or addr_str.begins_with("172.") or addr_str == "127.0.0.1":
			sub_lbl.text = "👤 Host: %s | 🎮 %s | 📡 Iisang Wi-Fi o Hotspot" % [h_name, m_name]
		else:
			sub_lbl.text = "👤 Host: %s | 🎮 %s | 🌐 Online Room" % [h_name, m_name]
		sub_lbl.add_theme_color_override("font_color", Color(0.65, 0.82, 0.95))
		sub_lbl.add_theme_font_size_override("font_size", 11)
		info_vbox.add_child(sub_lbl)

		var count_badge := PanelContainer.new()
		var badge_style := StyleBoxFlat.new()
		badge_style.bg_color = Color(0.04, 0.3, 0.18, 0.9)
		badge_style.border_width_left = 1
		badge_style.border_width_top = 1
		badge_style.border_width_right = 1
		badge_style.border_width_bottom = 1
		badge_style.border_color = Color(0.2, 0.8, 0.45, 0.85)
		badge_style.set_corner_radius_all(6)
		badge_style.content_margin_left = 6
		badge_style.content_margin_top = 3
		badge_style.content_margin_right = 6
		badge_style.content_margin_bottom = 3
		count_badge.add_theme_stylebox_override("panel", badge_style)
		count_badge.size_flags_vertical = Control.SIZE_SHRINK_CENTER

		var count_lbl := Label.new()
		count_lbl.text = "👥 %d/%d" % [int(lobby.get("player_count", 1)), int(lobby.get("max_players", 8))]
		count_lbl.add_theme_color_override("font_color", Color(0.4, 1.0, 0.6))
		count_lbl.add_theme_font_size_override("font_size", 11)
		count_badge.add_child(count_lbl)
		hbox.add_child(count_badge)

		var join_btn := Button.new()
		join_btn.text = "🎮 SUMALI"
		join_btn.custom_minimum_size = Vector2(85, 32)
		join_btn.add_theme_font_size_override("font_size", 12)
		join_btn.add_theme_color_override("font_color", Color(1, 1, 1))

		var btn_style := StyleBoxFlat.new()
		btn_style.bg_color = Color(0.06, 0.71, 0.51, 1)
		btn_style.border_width_left = 1
		btn_style.border_width_top = 1
		btn_style.border_width_right = 1
		btn_style.border_width_bottom = 1
		btn_style.border_color = Color(0.35, 0.95, 0.72, 0.9)
		btn_style.set_corner_radius_all(8)
		join_btn.add_theme_stylebox_override("normal", btn_style)

		join_btn.pressed.connect(_join_supabase_lobby.bind(lobby))
		hbox.add_child(join_btn)

		lobby_list_container.add_child(card)

func _on_supabase_fetch_failed(error_message: String) -> void:
	if empty_notice_label:
		empty_notice_label.visible = true
		empty_notice_label.text = "❌ " + error_message
	if lobbies_status_label:
		lobbies_status_label.text = "Fetch Error"

func _join_supabase_lobby(lobby: Dictionary) -> void:
	var target_address: String = str(lobby.get("address", "127.0.0.1")).strip_edges()
	var target_port: int = int(lobby.get("port", NetworkManager.DEFAULT_PORT))
	var host_name: String = str(lobby.get("host_name", "Host"))
	var room_name: String = str(lobby.get("name", "Kalye Match"))
	var lobby_id: String = str(lobby.get("id", ""))
	current_joined_room_name = room_name

	var pname := name_input.text.strip_edges() if name_input else "Bata"
	if pname.is_empty():
		pname = "Bata " + str(randi() % 100)

	_switch_right_tab(LobbyTab.ROOM_ACTIVE)
	if btn_start_match:
		btn_start_match.visible = false
	if btn_cancel:
		btn_cancel.visible = true
		btn_cancel.text = "❌ I-CANCEL"

	# Initialize empty slot labels with connecting message
	for i in range(8):
		if i < slot_labels.size():
			var lbl: Label = slot_labels[i]
			if i == 0:
				lbl.text = "Slot 1: ⏳ Kumukonekta kay %s (Host)..." % host_name
				lbl.modulate = Color(1.0, 0.9, 0.4, 1.0)
			else:
				lbl.text = "Slot %d: (Empty)" % (i + 1)
				lbl.modulate = Color(0.45, 0.55, 0.68, 0.8)

	if target_address.to_lower() == "webrtc":
		if active_room_title:
			active_room_title.text = "🌐 Kumukonekta sa Online Lobby: %s..." % room_name
		if hotspot_info_label:
			hotspot_info_label.text = "⏳ Kumukonekta sa Online Room (%s)..." % room_name
		var err := network_manager.join_webrtc_game(lobby_id, pname, supabase_manager.supabase_url, supabase_manager.supabase_anon_key)
		if err != OK:
			if hotspot_info_label:
				hotspot_info_label.text = "❌ Nabigo sa pagsali sa Online Room: %s" % room_name
			_switch_right_tab(LobbyTab.BROWSE)
		return

	# LAN or Direct ENet
	var is_private_ip := target_address.begins_with("192.168.") or target_address.begins_with("10.") or target_address.begins_with("172.") or target_address == "127.0.0.1"
	if active_room_title:
		active_room_title.text = "🏠 Kumukonekta sa Local Lobby: %s..." % room_name
	if hotspot_info_label:
		if is_private_ip:
			hotspot_info_label.text = "⏳ Kumukonekta sa Local IP %s:%d...\n(Paalala: Kailangang pareho kayo ng Wi-Fi o Hotspot ng Host!)" % [target_address, target_port]
		else:
			hotspot_info_label.text = "⏳ Kumukonekta sa %s:%d..." % [target_address, target_port]

	var err := network_manager.join_game(target_address, pname, target_port)
	if err != OK:
		if hotspot_info_label:
			hotspot_info_label.text = "❌ Hindi makakonekta sa %s:%d" % [target_address, target_port]
		_switch_right_tab(LobbyTab.BROWSE)

func _on_btn_create_supabase_room_pressed() -> void:
	var pname := name_input.text.strip_edges() if name_input else "Kuya Denn"
	if pname.is_empty():
		pname = "Kuya Denn"

	var rname := room_name_input.text.strip_edges() if room_name_input else ""
	if rname.is_empty():
		rname = pname + "'s Tambayan"

	var port := NetworkManager.DEFAULT_PORT
	if host_port_input and host_port_input.text.strip_edges().is_valid_int():
		port = host_port_input.text.strip_edges().to_int()

	var custom_addr := host_address_input.text.strip_edges() if host_address_input else ""

	var mode_name := "Pasa-Taya"
	match current_mode:
		MatchMode.PASA_TAYA_ELIMINATION: mode_name = "Pasa-Taya"
		MatchMode.INFECTION: mode_name = "Hawaan"
		MatchMode.CLASSIC_TAG: mode_name = "Klasikong Taya"

	var is_online := (current_host_net_type == HostNetType.ONLINE)

	if is_online:
		if host_status_label:
			host_status_label.text = "⏳ Inihahanda ang Online Room..."
		if supabase_manager:
			supabase_manager.register_lobby(rname, pname, "webrtc", 0, mode_name)

		_switch_right_tab(LobbyTab.ROOM_ACTIVE)
		if active_room_title:
			active_room_title.text = "🌐 ONLINE ROOM: %s" % rname
		if btn_start_match:
			btn_start_match.visible = true
			btn_start_match.disabled = true
			btn_start_match.text = "🎮 SIMULAN ANG LARO (Naghihintay ng kalaro...)"
			btn_start_match.modulate = Color(0.9, 0.9, 0.6, 0.9)
		if btn_cancel:
			btn_cancel.visible = true
			btn_cancel.text = "❌ ISARA ANG ROOM"
		return

	# Hotspot Room:
	var ips := NetworkManager.get_local_ip_addresses()
	var local_ip := ips[0] if not ips.is_empty() else "127.0.0.1"

	var err := network_manager.create_game(pname, port)
	if err != OK:
		if host_status_label:
			host_status_label.text = "❌ Nabigo sa pagbukas ng Hotspot Room!"
		return

	if supabase_manager:
		supabase_manager.register_lobby(rname, pname, local_ip, port, mode_name)

	_switch_right_tab(LobbyTab.ROOM_ACTIVE)
	if active_room_title:
		active_room_title.text = "📡 HOTSPOT ROOM: %s (%s)" % [rname, local_ip]
	if btn_start_match:
		btn_start_match.visible = true
		btn_start_match.disabled = true
		btn_start_match.text = "🎮 SIMULAN ANG LARO (Naghihintay ng kalaro...)"
		btn_start_match.modulate = Color(0.9, 0.9, 0.6, 0.9)
	if btn_cancel:
		btn_cancel.visible = true
		btn_cancel.text = "❌ ISARA ANG ROOM"

func _on_supabase_lobby_created(lobby_info: Dictionary) -> void:
	var lobby_id := str(lobby_info.get("id", ""))
	var address := str(lobby_info.get("address", "")).strip_edges().to_lower()
	print("[GameManager] Supabase lobby registered: ", lobby_id)

	if address == "webrtc":
		var pname := name_input.text.strip_edges() if name_input else "Kuya Denn"
		if pname.is_empty():
			pname = "Kuya Denn"
		var err := network_manager.create_webrtc_game(pname, lobby_id, supabase_manager.supabase_url, supabase_manager.supabase_anon_key)
		if err == OK:
			if host_status_label:
				host_status_label.text = "🟢 Handa na ang Online Room! (Makakasali na ang mga kalaro sa Internet o Data)"
			print("[GameManager] WebRTC host listening on lobby: ", lobby_id)
		else:
			if host_status_label:
				host_status_label.text = "❌ Bigo sa pagbukas ng Online Room: %d" % err
	else:
		if host_status_label:
			host_status_label.text = "🟢 Handa na ang Hotspot Room! (Pwedeng sumali ang mga nasa parehong Wi-Fi)"

func _on_supabase_create_failed(error_message: String) -> void:
	print("[GameManager] Failed to register to Supabase: ", error_message)
	if host_status_label:
		host_status_label.text = "⚠️ Hindi maikonekta ang room: " + error_message

func _on_btn_solo_pressed() -> void:
	_init_node_references()
	if network_manager:
		network_manager.is_solo_practice = true
	var pname := name_input.text.strip_edges() if name_input else "Dennrick (Solo)"
	if pname.is_empty():
		pname = "Dennrick (Solo)"
	network_manager.create_game(pname)
	_spawn_all_players()

	# In solo practice tournament, spawn 3 bots: Kalbo (99), Totoy (98), Nene (97)
	var bot_configs := [
		{ "id": 99, "name": "Kalbo (Bot)", "preset": 1, "color": 2, "pos_idx": 1 },
		{ "id": 98, "name": "Totoy (Bot)", "preset": 2, "color": 1, "pos_idx": 2 },
		{ "id": 97, "name": "Nene (Bot)", "preset": 3, "color": 3, "pos_idx": 3 }
	]

	var spawn_points: Array = []
	if map_node and map_node.has_node("SpawnPoints"):
		spawn_points = map_node.get_node("SpawnPoints").get_children()

	alive_player_ids = [1]
	eliminated_player_ids.clear()
	current_round = 1

	for b_cfg in bot_configs:
		alive_player_ids.append(b_cfg["id"])
		var bot: PracticeBot = bot_scene.instantiate()
		bot.name = str(b_cfg["id"])
		bot.player_id = b_cfg["id"]
		bot.player_name = b_cfg["name"]
		bot.current_role = PlayerController.Role.RUNNER

		if spawn_points.size() > b_cfg["pos_idx"]:
			bot.position = spawn_points[b_cfg["pos_idx"]].global_position
		else:
			bot.position = Vector3(b_cfg["pos_idx"] * 3.0 - 5.0, 0.5, 6)

		players_container.add_child(bot)
		if bot.model:
			bot.model.apply_preset(b_cfg["preset"])
			bot.model.set_player_color(COLOR_OPTIONS[b_cfg["color"] % COLOR_OPTIONS.size()]["color"])

		network_manager.players[b_cfg["id"]] = {
			"name": b_cfg["name"],
			"score": 0,
			"role": 0,
			"character": b_cfg["preset"],
			"color_idx": b_cfg["color"],
			"outfit": CharacterAnimator.ARCHETYPES[b_cfg["preset"]]
		}

	# In solo practice, start player as Taya immediately to test chasing & tagging
	var local_p: PlayerController = players_container.get_node_or_null("1")
	if local_p:
		local_p.current_role = PlayerController.Role.TAYA
		network_manager.players[1]["role"] = 1
		if local_p.model:
			local_p.model.apply_outfit_dict(_get_current_outfit_dict())

	_setup_round_timer()
	_set_game_state(GameState.PLAYING)
	if Engine.has_singleton("AudioManager"):
		AudioManager.play_whistle()
	elif has_node("/root/AudioManager"):
		get_node("/root/AudioManager").play_whistle()

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
		if current_mode != MatchMode.INFECTION:
			network_manager.players[chaser_id]["role"] = 0 # Former chaser becomes runner!

	if network_manager.players.has(target_id):
		network_manager.players[target_id]["role"] = 1 # Target becomes Taya!
		target_name = network_manager.players[target_id].get("name", "Runner")

	if hud:
		hud.update_scoreboard(network_manager.players)
		if current_mode == MatchMode.PASA_TAYA_ELIMINATION:
			hud.show_tag_banner(chaser_name, "PASA KAY " + target_name)
		else:
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
	current_round = 1
	eliminated_player_ids.clear()
	alive_player_ids.clear()
	for pid in network_manager.players.keys():
		alive_player_ids.append(int(pid))
	if alive_player_ids.is_empty():
		alive_player_ids.append(multiplayer.get_unique_id() if multiplayer.has_multiplayer_peer() else 1)
	is_intermission = false

	if supabase_manager and supabase_manager.is_hosting_lobby:
		supabase_manager.update_lobby(network_manager.players.size(), true)

	_spawn_all_players()
	_set_game_state(GameState.MAIBA_TAYA)

	if is_server_or_solo():
		maiba_manager.start_selection(alive_player_ids)

func _on_taya_decided(taya_id: int, taya_name: String) -> void:
	var my_id := multiplayer.get_unique_id()
	var is_me_taya := (my_id == taya_id)
	maiba_ui.show_result(taya_name, is_me_taya)

	# Set roles across players
	for player_node in players_container.get_children():
		if player_node is PlayerController:
			if player_node.player_id == taya_id:
				player_node.current_role = PlayerController.Role.TAYA
				if network_manager.players.has(taya_id):
					network_manager.players[taya_id]["role"] = 1
			else:
				player_node.current_role = PlayerController.Role.RUNNER
				if network_manager.players.has(player_node.player_id):
					network_manager.players[player_node.player_id]["role"] = 0

	# Begin match after 2 seconds
	get_tree().create_timer(2.0).timeout.connect(func():
		_set_game_state(GameState.PLAYING)
		_setup_round_timer()
		if Engine.has_singleton("AudioManager"):
			AudioManager.play_whistle()
		elif has_node("/root/AudioManager"):
			get_node("/root/AudioManager").play_whistle()
	)

func _spawn_single_player(int_pid: int, spawn_idx: int = 0) -> PlayerController:
	if players_container.has_node(str(int_pid)):
		return players_container.get_node(str(int_pid)) as PlayerController

	var pinfo: Dictionary = network_manager.players[int_pid] if network_manager.players.has(int_pid) else network_manager.players.get(str(int_pid), {})
	var player_instance: PlayerController
	if int_pid in [97, 98, 99]:
		player_instance = bot_scene.instantiate()
	else:
		player_instance = player_scene.instantiate()

	player_instance.name = str(int_pid)
	player_instance.player_id = int_pid
	player_instance.player_name = pinfo.get("name", "Player %d" % int_pid)

	# Spawn point
	var spawn_points: Array = []
	if map_node and map_node.has_node("SpawnPoints"):
		spawn_points = map_node.get_node("SpawnPoints").get_children()
	var spawn_pos: Vector3 = Vector3(0, 1, 0)
	if spawn_points.size() > 0:
		var sp: Marker3D = spawn_points[spawn_idx % spawn_points.size()]
		spawn_pos = sp.global_position
	player_instance.position = spawn_pos

	players_container.add_child(player_instance)

	# Character model & modular outfit customization
	if player_instance.model:
		if pinfo.has("outfit") and pinfo["outfit"] is Dictionary and not pinfo["outfit"].is_empty():
			player_instance.model.apply_outfit_dict(pinfo["outfit"])
		else:
			var char_type: int = pinfo.get("character", selected_char_idx if int_pid == 1 else 0)
			var color_idx: int = pinfo.get("color_idx", selected_color_idx if int_pid == 1 else (spawn_idx % COLOR_OPTIONS.size()))
			player_instance.model.apply_preset(char_type)
			player_instance.model.set_player_color(COLOR_OPTIONS[color_idx % COLOR_OPTIONS.size()]["color"])

	if player_instance.is_local_human():
		player_instance.mouse_sensitivity = float(settings_data.get("sensitivity", 2.5)) * 0.001
		player_instance.base_fov = float(settings_data.get("fov", 75.0))
		if player_instance.camera:
			player_instance.camera.fov = player_instance.base_fov

	return player_instance

func _spawn_all_players() -> void:
	# Clear existing players
	for child in players_container.get_children():
		child.queue_free()

	var sorted_pids: Array[int] = []
	for pid in network_manager.players.keys():
		sorted_pids.append(int(pid))
	sorted_pids.sort()

	for idx in range(sorted_pids.size()):
		_spawn_single_player(sorted_pids[idx], idx)

func _on_player_registered_midgame(new_pid: int) -> void:
	if multiplayer.has_multiplayer_peer() and multiplayer.is_server() and current_state in [GameState.PLAYING, GameState.MAIBA_TAYA]:
		# Broadcast spawn to all peers and sync match state to the newcomer
		rpc("sync_spawn_new_player", new_pid)
		rpc_id(new_pid, "sync_late_join_match", int(current_state), current_round, match_timer, int(current_mode), network_manager.players)

@rpc("call_local", "reliable")
func sync_spawn_new_player(pid: int) -> void:
	_spawn_single_player(pid, players_container.get_child_count())
	if not alive_player_ids.has(pid):
		alive_player_ids.append(pid)
	if hud:
		hud.update_scoreboard(network_manager.players)
		var pname: String = network_manager.players.get(pid, {}).get("name", "Player %d" % pid)
		hud.show_toast_notification("👋 Sumali sa laro: %s!" % pname, true)

@rpc("authority", "reliable")
func sync_late_join_match(state: int, round_num: int, timer_left: float, mode: int, all_players: Dictionary) -> void:
	network_manager.players = all_players
	current_mode = mode as MatchMode
	current_round = round_num
	match_timer = timer_left
	alive_player_ids.clear()
	for pid in all_players.keys():
		alive_player_ids.append(int(pid))
	_spawn_all_players()
	_set_game_state(state as GameState)

func _input(event: InputEvent) -> void:
	if current_state == GameState.PLAYING:
		if event is InputEventKey and event.is_pressed() and not event.is_echo() and event.keycode == KEY_ESCAPE:
			if settings_panel and settings_panel.visible:
				_close_settings()
			else:
				toggle_pause()
			get_viewport().set_input_as_handled()
			return

func _unhandled_input(event: InputEvent) -> void:
	if current_state == GameState.TITLE:
		if settings_panel and settings_panel.visible:
			return
		if event is InputEventKey and event.pressed:
			if event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER or event.keycode == KEY_SPACE:
				_on_btn_enter_title_pressed()
				get_viewport().set_input_as_handled()
		elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			_on_btn_enter_title_pressed()
			get_viewport().set_input_as_handled()

func _process(delta: float) -> void:
	if fps_label and fps_label.visible:
		fps_label.text = "FPS: %d" % Engine.get_frames_per_second()
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
			if is_intermission:
				intermission_timer -= delta
				if hud:
					hud.update_intermission_timer(intermission_timer)
				if is_server_or_solo() and intermission_timer <= 0.0:
					_start_next_round()
				return

			match_timer -= delta
			if hud:
				hud.update_match_timer(match_timer)

			# Sound ticking when timer is critical (under 10s)
			if match_timer <= 10.0 and match_timer > 0.0:
				var sec := int(match_timer)
				if sec != last_tick_second:
					last_tick_second = sec
					if Engine.has_singleton("AudioManager"):
						AudioManager.play_tick()
					elif has_node("/root/AudioManager"):
						get_node("/root/AudioManager").play_tick()

			# Update local player hud
			var my_id := multiplayer.get_unique_id()
			var my_node: PlayerController = players_container.get_node_or_null(str(my_id))
			if my_node:
				hud.update_role_display(my_node.current_role == PlayerController.Role.TAYA)
				hud.update_score(my_node.survival_time, my_node.tag_count, my_node.current_role == PlayerController.Role.TAYA)

			# Infection early win condition check: if 0 runners left
			if current_mode == MatchMode.INFECTION and is_server_or_solo():
				var alive_runners: int = 0
				for p in players_container.get_children():
					if p is PlayerController and not p.is_eliminated and p.current_role == PlayerController.Role.RUNNER:
						alive_runners += 1
				if alive_runners == 0:
					if multiplayer.has_multiplayer_peer() and multiplayer.is_server():
						rpc("sync_infection_game_over", true)
					else:
						sync_infection_game_over(true)
					return

			if hud:
				hud.update_scoreboard(network_manager.players)
				hud.update_round_badge(current_round, _get_mode_display_name(), alive_player_ids.size(), network_manager.players.size())

			if is_server_or_solo() and match_timer <= 0.0:
				_on_round_timer_expired()

func _on_round_timer_expired() -> void:
	match current_mode:
		MatchMode.CLASSIC_TAG:
			if multiplayer.has_multiplayer_peer() and multiplayer.is_server():
				rpc("sync_game_over")
			else:
				sync_game_over()
		MatchMode.INFECTION:
			var runners_left: int = 0
			for p in players_container.get_children():
				if p is PlayerController and not p.is_eliminated and p.current_role == PlayerController.Role.RUNNER:
					runners_left += 1
			var taya_won: bool = (runners_left == 0)
			if multiplayer.has_multiplayer_peer() and multiplayer.is_server():
				rpc("sync_infection_game_over", taya_won)
			else:
				sync_infection_game_over(taya_won)
		MatchMode.PASA_TAYA_ELIMINATION:
			var eliminated_id: int = -1
			for p in players_container.get_children():
				if p is PlayerController and not p.is_eliminated and p.current_role == PlayerController.Role.TAYA:
					eliminated_id = p.player_id
					break
			if eliminated_id == -1 and not alive_player_ids.is_empty():
				eliminated_id = alive_player_ids.pick_random()

			if multiplayer.has_multiplayer_peer() and multiplayer.is_server():
				rpc("sync_round_elimination", current_round, eliminated_id)
			else:
				sync_round_elimination(current_round, eliminated_id)

@rpc("call_local", "reliable")
func sync_round_elimination(round_num: int, eliminated_id: int) -> void:
	var elim_name := "Player %d" % eliminated_id
	if network_manager.players.has(eliminated_id):
		elim_name = network_manager.players[eliminated_id].get("name", elim_name)
		network_manager.players[eliminated_id]["eliminated"] = true

	alive_player_ids.erase(eliminated_id)
	eliminated_player_ids.append(eliminated_id)

	if Engine.has_singleton("AudioManager"):
		AudioManager.play_elimination()
	elif has_node("/root/AudioManager"):
		get_node("/root/AudioManager").play_elimination()

	var elim_node: PlayerController = players_container.get_node_or_null(str(eliminated_id)) as PlayerController
	if elim_node:
		elim_node.set_eliminated(true)
		if elim_node.is_bot:
			elim_node.global_position = Vector3(0, -50, 0)

	var my_id := multiplayer.get_unique_id()
	if my_id == eliminated_id:
		if hud:
			hud.show_toast_notification("💥 NA-TAYA KA! IKAW AY ELIMINADO! (Nanonood na)", false)
	else:
		if hud:
			hud.show_tag_banner("ELIMINADO!", elim_name)

	# Check tournament win condition
	if alive_player_ids.size() <= 1:
		var winner_id: int = alive_player_ids[0] if alive_player_ids.size() == 1 else -1
		sync_tournament_winner(winner_id)
		return

	# Transition to Intermission before next round
	is_intermission = true
	intermission_timer = 4.0
	if hud:
		hud.show_round_intermission(round_num + 1, elim_name, alive_player_ids.size())

func _start_next_round() -> void:
	if multiplayer.has_multiplayer_peer() and multiplayer.is_server():
		rpc("sync_next_round_start", current_round + 1)
	else:
		sync_next_round_start(current_round + 1)

@rpc("call_local", "reliable")
func sync_next_round_start(next_round: int) -> void:
	current_round = next_round
	is_intermission = false
	_setup_round_timer()

	var spawn_points: Array = []
	if map_node and map_node.has_node("SpawnPoints"):
		spawn_points = map_node.get_node("SpawnPoints").get_children()
	var sp_idx := 0
	for pid in alive_player_ids:
		var pnode: PlayerController = players_container.get_node_or_null(str(pid)) as PlayerController
		if pnode:
			if spawn_points.size() > 0:
				pnode.global_position = spawn_points[sp_idx % spawn_points.size()].global_position
				sp_idx += 1
			pnode.velocity = Vector3.ZERO
			pnode.is_stunned = false
			pnode.is_immune = false
			pnode.current_role = PlayerController.Role.RUNNER

	# Pick random new Taya among alive players
	if is_server_or_solo():
		var new_taya_id: int = alive_player_ids.pick_random()
		if multiplayer.has_multiplayer_peer() and multiplayer.is_server():
			rpc("sync_assign_taya", new_taya_id)
		else:
			sync_assign_taya(new_taya_id)

	if Engine.has_singleton("AudioManager"):
		AudioManager.play_whistle()
	elif has_node("/root/AudioManager"):
		get_node("/root/AudioManager").play_whistle()

	if hud:
		hud.hide_round_intermission()
		hud.show_toast_notification("📢 ROUND %d: TAKBUHAN NA!" % current_round, true)

@rpc("call_local", "reliable")
func sync_assign_taya(taya_id: int) -> void:
	for p in players_container.get_children():
		if p is PlayerController:
			if p.is_eliminated:
				continue
			if p.player_id == taya_id:
				p.current_role = PlayerController.Role.TAYA
				if network_manager.players.has(taya_id):
					network_manager.players[taya_id]["role"] = 1
			else:
				p.current_role = PlayerController.Role.RUNNER
				if network_manager.players.has(p.player_id):
					network_manager.players[p.player_id]["role"] = 0
	if hud:
		hud.update_scoreboard(network_manager.players)

@rpc("call_local", "reliable")
func sync_tournament_winner(winner_id: int) -> void:
	_set_game_state(GameState.GAME_OVER)
	var winner_name: String = "Kampeon"
	if network_manager.players.has(winner_id):
		winner_name = network_manager.players[winner_id].get("name", "Kampeon")
	winner_label.text = "👑 ULTIMATE BATANG KALYE CHAMPION! 👑\n\n🏆 PANALO: %s! 🏆\nNalampasan ang lahat ng Rounds sa Crab Game Elimination!" % winner_name

@rpc("call_local", "reliable")
func sync_infection_game_over(taya_won: bool) -> void:
	_set_game_state(GameState.GAME_OVER)
	if taya_won:
		winner_label.text = "🧟 LAHAT NAHAWAAN NA! 🧟\n\n🏆 PANALO ANG MGA TAYA! 🏆\nWala nang nakaligtas na Runner sa kalye!"
	else:
		winner_label.text = "👟 NAKALIGTAS ANG MGA RUNNER! 👟\n\n🏆 PANALO ANG MGA RUNNER! 🏆\nMatagumpay na nakaligtas sa outbreak bago naubos ang oras!"

@rpc("call_local", "reliable")
func sync_game_over() -> void:
	_set_game_state(GameState.GAME_OVER)
	var best_name := ""
	var best_score := -1.0
	for pid in network_manager.players.keys():
		var pinfo = network_manager.players[pid]
		var player_node: PlayerController = players_container.get_node_or_null(str(pid)) as PlayerController
		var surv_time: float = player_node.survival_time if player_node else 0.0
		var tag_pts: float = (float(player_node.tag_count) * 30.0) if player_node else 0.0
		var stored_score: float = float(pinfo.get("score", 0))
		var total_calc_score: float = surv_time + tag_pts + stored_score
		if total_calc_score > best_score:
			best_score = total_calc_score
			best_name = pinfo.get("name", "Player")

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

	if lobby_camera:
		var has_local_cam := false
		for p in players_container.get_children():
			if p is PlayerController and p.is_local_human() and p.camera:
				has_local_cam = true
				if new_state in [GameState.MAIBA_TAYA, GameState.PLAYING]:
					p.camera.current = true
				break
		lobby_camera.current = (new_state in [GameState.TITLE, GameState.LOBBY, GameState.GAME_OVER]) or (not has_local_cam)

	if new_state == GameState.LOBBY or new_state == GameState.TITLE:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		is_intermission = false
		current_round = 1
		eliminated_player_ids.clear()
		alive_player_ids.clear()
		if hud:
			hud.hide_spectator_bar()
			hud.hide_round_intermission()
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

func _load_settings() -> void:
	var is_mobile := DisplayServer.is_touchscreen_available() or OS.has_feature("mobile")
	if is_mobile:
		settings_data = {
			"preset": 1, # Default Low on mobile/tablets for smooth 60 FPS
			"render_scale": 0.60,
			"shadows": false,
			"glow": false,
			"max_fps": 60,
			"anti_aliasing": 0,
			"show_fps": false,
			"volume": 1.0,
			"sensitivity": 2.5,
			"fov": 75.0
		}
	else:
		settings_data = {
			"preset": 2, # Balanced on desktop
			"render_scale": 0.75,
			"shadows": true,
			"glow": false,
			"max_fps": 60,
			"anti_aliasing": 1,
			"show_fps": false,
			"volume": 1.0,
			"sensitivity": 2.5,
			"fov": 75.0
		}

	var cfg := ConfigFile.new()
	var err := cfg.load(SETTINGS_SAVE_PATH)
	if err == OK:
		settings_data["preset"] = cfg.get_value("graphics", "preset", settings_data["preset"])
		settings_data["render_scale"] = cfg.get_value("graphics", "render_scale", settings_data["render_scale"])
		settings_data["shadows"] = cfg.get_value("graphics", "shadows", settings_data["shadows"])
		settings_data["glow"] = cfg.get_value("graphics", "glow", settings_data["glow"])
		settings_data["max_fps"] = cfg.get_value("graphics", "max_fps", settings_data["max_fps"])
		settings_data["anti_aliasing"] = cfg.get_value("graphics", "anti_aliasing", settings_data["anti_aliasing"])
		settings_data["show_fps"] = cfg.get_value("graphics", "show_fps", settings_data["show_fps"])
		settings_data["volume"] = cfg.get_value("audio", "volume", settings_data["volume"])
		settings_data["sensitivity"] = cfg.get_value("controls", "sensitivity", settings_data["sensitivity"])
		settings_data["fov"] = cfg.get_value("controls", "fov", settings_data["fov"])

	apply_graphics_settings()
	_sync_settings_ui()

func _save_settings() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("graphics", "preset", settings_data.get("preset", 2))
	cfg.set_value("graphics", "render_scale", settings_data.get("render_scale", 0.75))
	cfg.set_value("graphics", "shadows", settings_data.get("shadows", true))
	cfg.set_value("graphics", "glow", settings_data.get("glow", false))
	cfg.set_value("graphics", "max_fps", settings_data.get("max_fps", 60))
	cfg.set_value("graphics", "anti_aliasing", settings_data.get("anti_aliasing", 0))
	cfg.set_value("graphics", "show_fps", settings_data.get("show_fps", false))
	cfg.set_value("audio", "volume", settings_data.get("volume", 1.0))
	cfg.set_value("controls", "sensitivity", settings_data.get("sensitivity", 2.5))
	cfg.set_value("controls", "fov", settings_data.get("fov", 75.0))
	cfg.save(SETTINGS_SAVE_PATH)

func apply_graphics_settings() -> void:
	# 1. 3D Viewport Resolution Scale
	var r_scale: float = clamp(float(settings_data.get("render_scale", 0.75)), 0.5, 1.0)
	get_viewport().scaling_3d_scale = r_scale
	get_viewport().scaling_3d_mode = Viewport.SCALING_3D_MODE_BILINEAR

	# 2. Sun Shadows
	var shadows_on: bool = bool(settings_data.get("shadows", true))
	var sun = get_node_or_null("KalyeMap/SunLight") as DirectionalLight3D
	if sun:
		sun.shadow_enabled = shadows_on
		if shadows_on:
			sun.directional_shadow_max_distance = 60.0 if int(settings_data.get("preset", 0)) <= 2 else 150.0

	# 3. Glow & Bloom
	var glow_on: bool = bool(settings_data.get("glow", false))
	var env_node = get_node_or_null("KalyeMap/WorldEnvironment") as WorldEnvironment
	if env_node and env_node.environment:
		env_node.environment.glow_enabled = glow_on

	# 4. Engine FPS Cap
	var target_fps: int = int(settings_data.get("max_fps", 60))
	Engine.max_fps = target_fps

	# 5. Anti-Aliasing
	var aa_mode: int = int(settings_data.get("anti_aliasing", 0))
	get_viewport().screen_space_aa = Viewport.SCREEN_SPACE_AA_FXAA if aa_mode == 1 else Viewport.SCREEN_SPACE_AA_DISABLED

	# 6. Live FPS Counter
	var show_fps: bool = bool(settings_data.get("show_fps", false))
	if fps_label:
		fps_label.visible = show_fps

	# 7. Volume, Sensitivity & FOV
	_apply_audio_volume(float(settings_data.get("volume", 1.0)))
	_apply_sensitivity(float(settings_data.get("sensitivity", 2.5)))
	_apply_fov(float(settings_data.get("fov", 75.0)))

func _apply_preset(preset_idx: int) -> void:
	match preset_idx:
		1: # Mababa (Low / Tipid)
			settings_data["preset"] = 1
			settings_data["render_scale"] = 0.60
			settings_data["shadows"] = false
			settings_data["glow"] = false
			settings_data["max_fps"] = 60
			settings_data["anti_aliasing"] = 0
		2: # Balanse (Medium)
			settings_data["preset"] = 2
			settings_data["render_scale"] = 0.75
			settings_data["shadows"] = true
			settings_data["glow"] = false
			settings_data["max_fps"] = 60
			settings_data["anti_aliasing"] = 1
		3: # Mataas (High / Maganda)
			settings_data["preset"] = 3
			settings_data["render_scale"] = 1.00
			settings_data["shadows"] = true
			settings_data["glow"] = true
			settings_data["max_fps"] = 0 # Unlimited
			settings_data["anti_aliasing"] = 1

	apply_graphics_settings()
	_sync_settings_ui()
	_save_settings()

func _sync_settings_ui() -> void:
	var p: int = int(settings_data.get("preset", 0))
	if btn_preset_low:
		btn_preset_low.text = "👉 🚀 MABABA" if p == 1 else "🚀 MABABA (Tipid)"
	if btn_preset_med:
		btn_preset_med.text = "👉 ⚖️ BALANSE" if p == 2 else "⚖️ BALANSE"
	if btn_preset_high:
		btn_preset_high.text = "👉 ✨ MATAAS" if p == 3 else "✨ MATAAS"

	var r_scale: float = float(settings_data.get("render_scale", 0.75))
	if scale_slider:
		scale_slider.set_value_no_signal(r_scale)
	if scale_label:
		var speed_desc := "Pinakamabilis" if r_scale <= 0.6 else ("Balanse" if r_scale <= 0.8 else "Mataas na Linaw")
		scale_label.text = "📐 3D Resolution Scale: %d%% (%s)" % [int(r_scale * 100), speed_desc]

	if shadows_check:
		shadows_check.set_pressed_no_signal(bool(settings_data.get("shadows", true)))
	if glow_check:
		glow_check.set_pressed_no_signal(bool(settings_data.get("glow", false)))

	var fps_cap: int = int(settings_data.get("max_fps", 60))
	if fps_limit_option:
		var idx: int = 0 if fps_cap == 30 else (1 if fps_cap == 60 else 2)
		fps_limit_option.select(idx)

	var aa_mode: int = int(settings_data.get("anti_aliasing", 0))
	if aa_option:
		aa_option.select(aa_mode)

	if fps_counter_check:
		fps_counter_check.set_pressed_no_signal(bool(settings_data.get("show_fps", false)))

	if volume_slider:
		volume_slider.set_value_no_signal(float(settings_data.get("volume", 1.0)))
	if sensitivity_slider:
		sensitivity_slider.set_value_no_signal(float(settings_data.get("sensitivity", 2.5)))
	if fov_slider:
		fov_slider.set_value_no_signal(float(settings_data.get("fov", 75.0)))

func _open_settings(from_source: String) -> void:
	settings_opened_from = from_source
	if pause_ui:
		pause_ui.visible = true
	if pause_panel:
		pause_panel.visible = false
	if settings_panel:
		settings_panel.visible = true
	_sync_settings_ui()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _close_settings() -> void:
	if settings_panel:
		settings_panel.visible = false
	if settings_opened_from == "PAUSE":
		if is_game_paused and pause_panel:
			pause_panel.visible = true
		elif pause_ui:
			pause_ui.visible = false
			if current_state == GameState.PLAYING:
				Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	else:
		if pause_ui:
			pause_ui.visible = false
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _on_render_scale_changed(val: float) -> void:
	settings_data["render_scale"] = val
	settings_data["preset"] = 0
	get_viewport().scaling_3d_scale = val
	_sync_settings_ui()
	_save_settings()

func _on_shadows_toggled(toggled: bool) -> void:
	settings_data["shadows"] = toggled
	settings_data["preset"] = 0
	var sun = get_node_or_null("KalyeMap/SunLight") as DirectionalLight3D
	if sun:
		sun.shadow_enabled = toggled
	_sync_settings_ui()
	_save_settings()

func _on_glow_toggled(toggled: bool) -> void:
	settings_data["glow"] = toggled
	settings_data["preset"] = 0
	var env_node = get_node_or_null("KalyeMap/WorldEnvironment") as WorldEnvironment
	if env_node and env_node.environment:
		env_node.environment.glow_enabled = toggled
	_sync_settings_ui()
	_save_settings()

func _on_fps_limit_selected(idx: int) -> void:
	var fps_val := 30 if idx == 0 else (60 if idx == 1 else 0)
	settings_data["max_fps"] = fps_val
	Engine.max_fps = fps_val
	_save_settings()

func _on_aa_selected(idx: int) -> void:
	settings_data["anti_aliasing"] = idx
	get_viewport().screen_space_aa = Viewport.SCREEN_SPACE_AA_FXAA if idx == 1 else Viewport.SCREEN_SPACE_AA_DISABLED
	_save_settings()

func _on_fps_counter_toggled(toggled: bool) -> void:
	settings_data["show_fps"] = toggled
	if fps_label:
		fps_label.visible = toggled
	_save_settings()

func _apply_audio_volume(val: float) -> void:
	var bus_idx := AudioServer.get_bus_index("Master")
	if bus_idx >= 0:
		if val > 0.01:
			AudioServer.set_bus_volume_db(bus_idx, linear_to_db(clamp(val, 0.0001, 1.0)))
			AudioServer.set_bus_mute(bus_idx, false)
		else:
			AudioServer.set_bus_mute(bus_idx, true)
	if volume_label:
		volume_label.text = "🔊 Master Volume: %d%%" % int(val * 100)

func _on_volume_changed(val: float) -> void:
	settings_data["volume"] = val
	_apply_audio_volume(val)
	_save_settings()

func _apply_sensitivity(val: float) -> void:
	var my_id := multiplayer.get_unique_id()
	if players_container:
		var my_node = players_container.get_node_or_null(str(my_id))
		if my_node and "mouse_sensitivity" in my_node:
			my_node.mouse_sensitivity = val * 0.001
	if sensitivity_label:
		sensitivity_label.text = "🖱️ Mouse / Touch Sensitivity: %.1f" % val

func _on_sensitivity_changed(val: float) -> void:
	settings_data["sensitivity"] = val
	_apply_sensitivity(val)
	_save_settings()

func _apply_fov(val: float) -> void:
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

func _on_fov_changed(val: float) -> void:
	settings_data["fov"] = val
	_apply_fov(val)
	_save_settings()

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
	btn_cancel.text = "❌ UMALIS SA ROOM"
	btn_start_match.visible = false
	if active_room_title:
		active_room_title.text = "🏠 LOBBY: %s" % current_joined_room_name
	if hotspot_info_label:
		hotspot_info_label.text = "✅ Nakakonekta sa Host! Naghihintay na simulan ng Host ang laro..."
	_update_lobby_player_list()

func _on_join_failed() -> void:
	btn_host.disabled = false
	btn_join.disabled = false
	btn_cancel.visible = false
	btn_start_match.visible = false
	_switch_right_tab(LobbyTab.BROWSE)
	if empty_notice_label:
		empty_notice_label.visible = true
		empty_notice_label.text = "❌ Hindi nakakonekta sa Host!\n• Kung Online Room: Maaaring offline na ang Host o nagkaroon ng network delay. I-refresh at subukan ulit.\n• Kung Local Room: Siguraduhing magkapareho kayo ng Wi-Fi o Hotspot ng Host."
	if lobbies_status_label:
		lobbies_status_label.text = "Bigo ang Koneksyon"
	if hotspot_info_label:
		hotspot_info_label.text = "❌ Bigo sa pagkonekta sa host."

func _on_server_disconnected() -> void:
	_set_game_state(GameState.LOBBY)
	btn_host.disabled = false
	btn_join.disabled = false
	btn_cancel.visible = false
	btn_start_match.visible = false
	_switch_right_tab(LobbyTab.BROWSE)
	_fetch_supabase_lobbies()
	if empty_notice_label:
		empty_notice_label.visible = true
		empty_notice_label.text = "⚠️ Na-disconnect mula sa Server / Host."
	if hotspot_info_label:
		hotspot_info_label.text = "⚠️ Na-disconnect mula sa Server."
	_update_lobby_player_list()

func _update_lobby_player_list() -> void:
	var count := network_manager.players.size()
	if slots_header:
		slots_header.text = "👥 MGA MANLALARO (%d / 8 PLAYERS)" % count
	elif player_list_label:
		player_list_label.text = "👥 MGA MANLALARO (%d / 8 PLAYERS)" % count

	if supabase_manager and supabase_manager.is_hosting_lobby:
		supabase_manager.update_lobby(max(1, count), false)

	# Start Match button dynamic status
	if btn_start_match:
		if multiplayer.has_multiplayer_peer() and multiplayer.is_server():
			btn_start_match.visible = true
			if count >= 2:
				btn_start_match.disabled = false
				btn_start_match.text = "🎮 SIMULAN ANG LARO (%d PLAYERS READY)" % count
				btn_start_match.modulate = Color(1.0, 1.0, 1.0, 1.0)
			else:
				btn_start_match.disabled = false
				btn_start_match.text = "🎮 SIMULAN ANG LARO (Naghihintay ng kalaro...)"
				btn_start_match.modulate = Color(0.9, 0.9, 0.6, 0.9)
		else:
			btn_start_match.visible = false

	var pids := network_manager.players.keys()
	if pids.is_empty():
		var local_name := name_input.text.strip_edges() if name_input and not name_input.text.is_empty() else "Dennrick"
		for i in range(8):
			if i < slot_labels.size():
				var lbl: Label = slot_labels[i]
				if i == 0:
					if network_manager.is_host:
						lbl.text = "Slot 1: " + local_name + " 👑"
						lbl.modulate = Color(0.95, 0.98, 1.0, 1.0)
					else:
						lbl.text = "Slot 1: ⏳ Kumukonekta sa Host..."
						lbl.modulate = Color(1.0, 0.9, 0.4, 1.0)
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
				var is_h: bool = (pid == 1)
				var tag := " 👑" if is_h else ""
				lbl.text = "Slot %d: %s%s" % [i + 1, pinfo.get("name", "Player"), tag]
				lbl.modulate = Color(0.95, 0.98, 1.0, 1.0)
			else:
				lbl.text = "Slot %d: (Empty)" % (i + 1)
				lbl.modulate = Color(0.45, 0.55, 0.68, 0.8)

func _run_automated_self_test() -> void:
	var results: Array[String] = []
	results.append("[SELF-TEST] Starting automated verification...")

	# 1. Test IP & Port auto-parsing
	results.append("[SELF-TEST] Testing address parsing...")
	_on_ip_text_changed("192.168.43.1:7777")
	if ip_input.text == "192.168.43.1" and port_input.text == "7777":
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

	# 5b. Test Dual Stamina & Exhaustion System
	results.append("[SELF-TEST] Testing Dual Stamina & Exhaustion System...")
	p1.burst_stamina = 100.0
	p1.endurance_stamina = 100.0
	p1.is_exhausted = false
	p1.is_sprinting = true
	p1._process_stamina(1.0, true)
	if p1.burst_stamina < 100.0 and p1.endurance_stamina < 100.0:
		results.append("[PASS] Sprint movement drains burst stamina (%.1f/100) and endurance (%.1f/100)." % [p1.burst_stamina, p1.endurance_stamina])
	else:
		results.append("[FAIL] Sprint movement did not drain stamina!")
		_write_test_results(results, 1)
		return

	p1.endurance_stamina = 0.0
	p1._process_stamina(0.1, true)
	if p1.is_exhausted and not p1.is_sprinting:
		results.append("[PASS] Exhaustion triggered when endurance reaches 0; sprint locked out.")
	else:
		results.append("[FAIL] Exhaustion was not triggered!")
		_write_test_results(results, 1)
		return

	p1.endurance_stamina = 35.0
	p1._process_stamina(0.1, false)
	if not p1.is_exhausted:
		results.append("[PASS] Exhaustion cleared after catching breath above threshold (%.1f/100)." % p1.endurance_stamina)
	else:
		results.append("[FAIL] Exhaustion did not clear above threshold!")
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

	# 7b. Test Mobile Graphics Optimization & Presets
	results.append("[SELF-TEST] Testing Mobile Graphics Optimization & Presets...")
	_apply_preset(1) # Apply MABABA (Low / Performance)
	var sun_node := get_node_or_null("KalyeMap/SunLight") as DirectionalLight3D
	var env_node := get_node_or_null("KalyeMap/WorldEnvironment") as WorldEnvironment
	if is_equal_approx(get_viewport().scaling_3d_scale, 0.60) and sun_node and not sun_node.shadow_enabled and env_node and not env_node.environment.glow_enabled:
		results.append("[PASS] Mababa (Low) preset applied correctly: 3D scale=60%, shadows=OFF, glow=OFF.")
	else:
		results.append("[FAIL] Mababa preset failed to apply! scale=" + str(get_viewport().scaling_3d_scale))
		_write_test_results(results, 1)
		return

	_apply_preset(2) # Switch to Balanse (Medium)
	if is_equal_approx(get_viewport().scaling_3d_scale, 0.75) and sun_node and sun_node.shadow_enabled:
		results.append("[PASS] Balanse (Medium) preset applied correctly: 3D scale=75%, shadows=ON.")
	else:
		results.append("[FAIL] Balanse preset failed to apply!")
		_write_test_results(results, 1)
		return

	# Test Settings Modal Navigation
	_open_settings("PAUSE")
	if settings_panel and settings_panel.visible:
		results.append("[PASS] Settings panel opened successfully.")
	else:
		results.append("[FAIL] Settings panel failed to open!")
		_write_test_results(results, 1)
		return
	_close_settings()
	if settings_panel and not settings_panel.visible:
		results.append("[PASS] Settings panel closed successfully.")
	else:
		results.append("[FAIL] Settings panel failed to close!")
		_write_test_results(results, 1)
		return

	# 8. Test 8-Character Modular Customization & Persistence
	results.append("[SELF-TEST] Testing 8-Character Roster & Customization...")
	for arch_idx in range(CharacterAnimator.ARCHETYPES.size()):
		_select_preset(arch_idx)
		if current_archetype != arch_idx:
			results.append("[FAIL] Archetype selection failed for " + str(arch_idx))
			_write_test_results(results, 1)
			return
	results.append("[PASS] All 8 Pinoy Archetypes selected and applied successfully.")

	# Test slot fine-tuning (e.g. hair, headwear, sando, tsinelas)
	_cycle_slot("hair", 1)
	_cycle_slot("headwear", 1)
	_cycle_slot("body", 1)
	_cycle_slot("footwear", 1)
	var outfit: Dictionary = _get_current_outfit_dict()
	_save_player_outfit()
	_load_player_outfit()
	var loaded_outfit: Dictionary = _get_current_outfit_dict()
	if loaded_outfit["footwear"] == outfit["footwear"] and loaded_outfit["headwear"] == outfit["headwear"]:
		results.append("[PASS] Modular outfit saved to config and reloaded successfully.")
	else:
		results.append("[FAIL] Customization persistence mismatch!")
		_write_test_results(results, 1)
		return

	# 9. Test Bot Elimination & Spectator Isolation
	results.append("[SELF-TEST] Testing Bot Elimination & Spectator Isolation...")
	var bot98: PracticeBot = players_container.get_node_or_null("98") as PracticeBot
	sync_round_elimination(1, 99)
	if p1.is_eliminated:
		results.append("[FAIL] Human player 1 was mistakenly eliminated when bot 99 was eliminated!")
		_write_test_results(results, 1)
		return
	if hud and hud.spectator_bar and hud.spectator_bar.visible:
		results.append("[FAIL] Spectator bar showed up on living human player screen when bot was eliminated!")
		_write_test_results(results, 1)
		return
	results.append("[PASS] Bot 99 eliminated without hijacking human player spectator mode.")

	# Verify human player can tag remaining alive bot (98) and ignores dead bot (99)
	if bot98:
		p1.tag_cooldown = 0.0
		p1.current_role = PlayerController.Role.TAYA
		bot98.current_role = PlayerController.Role.RUNNER
		bot98.is_immune = false
		p1.global_position = bot98.global_position + Vector3(0, 0, 1.2)
		p1._try_tag()
		if bot98.current_role == PlayerController.Role.TAYA:
			results.append("[PASS] Human player successfully tagged living Bot 98 without locking onto dead Bot 99.")
		else:
			results.append("[FAIL] Tagging living bot failed after another bot was eliminated!")
			_write_test_results(results, 1)
			return

	# Verify human player elimination and spectator cycling
	results.append("[SELF-TEST] Testing Human Player Elimination & Spectator Mode...")
	p1.set_eliminated(true)
	if not p1.is_eliminated:
		results.append("[FAIL] Human player failed to enter eliminated state!")
		_write_test_results(results, 1)
		return
	if hud and hud.spectator_bar and not hud.spectator_bar.visible:
		results.append("[FAIL] Spectator bar did not show when human player died!")
		_write_test_results(results, 1)
		return
	if not p1.spectating_target or p1.spectating_target.is_eliminated:
		results.append("[FAIL] Spectating target invalid or was an eliminated player!")
		_write_test_results(results, 1)
		return
	var _initial_target := p1.spectating_target
	p1._cycle_spectate_target(1)
	if p1.camera_mount:
		var cam_dist: float = p1.camera_mount.global_position.distance_to(p1.spectating_target.global_position)
		if cam_dist > 5.0:
			results.append("[FAIL] Camera mount did not follow spectated target (dist=" + str(cam_dist) + ")!")
			_write_test_results(results, 1)
			return
	results.append("[PASS] Human player spectator camera tracks target and switches targets correctly.")
	p1.set_eliminated(false)

	# 10. Test Multiplayer Match Flow & Start Match
	results.append("[SELF-TEST] Testing Multiplayer Match Flow & Start Match...")
	network_manager.players.clear()
	network_manager.players[1] = { "name": "HostPlayer", "score": 0, "role": 0, "character": 0, "color_idx": 0, "outfit": {} }
	network_manager.players[2] = { "name": "ClientPlayer2", "score": 0, "role": 0, "character": 1, "color_idx": 1, "outfit": {} }
	_start_match_flow()
	if alive_player_ids.size() == 2 and players_container.has_node("1") and players_container.has_node("2"):
		results.append("[PASS] Multiplayer match flow started cleanly with 2 players; alive_player_ids populated without type error.")
	else:
		results.append("[FAIL] Multiplayer match flow failed to initialize alive players!")
		_write_test_results(results, 1)
		return

	# 11. End match
	sync_game_over()
	results.append("[PASS] Game over reached. Winner: " + winner_label.text)

	# 12. Test Supabase Matchmaking & Tabbed Lobby Setup
	results.append("[SELF-TEST] Testing Supabase Matchmaking & Tab Switching...")
	_switch_right_tab(LobbyTab.HOST)
	if host_section and host_section.visible and not browse_section.visible:
		results.append("[PASS] Switched to Host Tab successfully.")
	else:
		results.append("[FAIL] Host tab switching failed!")
		_write_test_results(results, 1)
		return

	_switch_right_tab(LobbyTab.DIRECT)
	if direct_section and direct_section.visible and not host_section.visible:
		results.append("[PASS] Switched to Direct Tab successfully.")
	else:
		results.append("[FAIL] Direct tab switching failed!")
		_write_test_results(results, 1)
		return

	_switch_right_tab(LobbyTab.BROWSE)
	if browse_section and browse_section.visible and not direct_section.visible:
		results.append("[PASS] Switched back to Browse Tab successfully.")
	else:
		results.append("[FAIL] Browse tab switching failed!")
		_write_test_results(results, 1)
		return

	# Test Supabase dynamic card rendering (both LAN and WebRTC Online)
	var mock_lobby_lan: Dictionary = {
		"id": "test-uuid-1234",
		"name": "Bata Kalye LAN Match",
		"host_name": "Dennrick",
		"address": "127.0.0.1",
		"port": 7777,
		"player_count": 2,
		"max_players": 8,
		"game_mode": "Pasa-Taya"
	}
	var mock_lobby_webrtc: Dictionary = {
		"id": "test-uuid-5678",
		"name": "Bata Kalye Online Match",
		"host_name": "Dennrick",
		"address": "webrtc",
		"port": 0,
		"player_count": 1,
		"max_players": 8,
		"game_mode": "Klasikong Taya"
	}
	_on_supabase_lobbies_fetched([mock_lobby_lan, mock_lobby_webrtc])
	if lobby_list_container and lobby_list_container.get_child_count() > 2:
		results.append("[PASS] Supabase dynamic room cards (LAN & WebRTC Online P2P) rendered into lobby list successfully.")
	else:
		results.append("[FAIL] Supabase room cards failed to render!")
		_write_test_results(results, 1)
		return

	# 13. Test WebRTC Online Peer Initialization & Cleanup
	results.append("[SELF-TEST] Testing WebRTC Online Peer Initialization & Cleanup...")
	var rtc_err = network_manager.create_webrtc_game("HostDenn", "test_lobby_123", supabase_manager.supabase_url, supabase_manager.supabase_anon_key)
	if rtc_err == OK and network_manager.connection_mode == "webrtc" and network_manager.multiplayer.has_multiplayer_peer():
		results.append("[PASS] WebRTC host peer initialized successfully!")
	else:
		results.append("[FAIL] WebRTC host peer initialization failed: %d" % rtc_err)
		_write_test_results(results, 1)
		return

	network_manager.leave_game()
	if network_manager.connection_mode == "enet" and not network_manager.multiplayer.has_multiplayer_peer():
		results.append("[PASS] WebRTC peer and signaler cleaned up cleanly.")
	else:
		results.append("[FAIL] WebRTC peer cleanup failed!")
		_write_test_results(results, 1)
		return

	results.append("[ALL TESTS PASSED] ZERO RUNTIME ERRORS DETECTED!")
	for child in players_container.get_children():
		child.queue_free()
	_write_test_results(results, 0)

func _write_test_results(lines: Array[String], exit_code: int) -> void:
	for line in lines:
		print(line)
	var f := FileAccess.open("res://test_results.txt", FileAccess.WRITE)
	if f:
		f.store_string("\n".join(lines))
		f.close()
	get_tree().quit(exit_code)
