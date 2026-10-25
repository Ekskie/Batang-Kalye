class_name LobbyUI
extends Control

signal main_menu_requested
signal prev_char_requested
signal next_char_requested
signal color_selected(color_idx: int)
signal player_name_changed(new_name: String)
signal tab_changed(tab_idx: int)
signal host_hotspot_requested
signal join_hotspot_requested
signal solo_practice_requested
signal refresh_ip_requested
signal copy_ip_requested
signal start_game_requested
signal create_room_submitted(room_name: String, game_mode: int, duration: float, max_players: int)
signal refresh_lobbies_requested
signal join_lobby_requested(lobby_data: Dictionary)
signal join_code_requested(code: String)
signal settings_requested
signal leave_room_requested
signal store_requested
signal guide_requested
signal customization_requested

enum LobbyTab {
	BROWSE = 0,
	CREATE = 1,
	HOTSPOT_SOLO = 2
}

var current_tab: LobbyTab = LobbyTab.HOTSPOT_SOLO

# Top Navigation
@onready var btn_back: TextureButton = get_node_or_null("Margin/VBox/TopBar/LeftControls/BtnBack")
@onready var btn_main_menu: Button = get_node_or_null("Margin/VBox/TopBar/LeftControls/BtnMainMenu")
@onready var nickname_badge: Button = get_node_or_null("Margin/VBox/TopBar/CenterTitle/NicknameBadge")
@onready var btn_settings: BaseButton = get_node_or_null("Margin/VBox/TopBar/RightControls/BtnLobbySettings")
@onready var btn_store: BaseButton = get_node_or_null("Margin/VBox/TopBar/RightControls/BtnLobbyStore")
@onready var btn_guide: BaseButton = get_node_or_null("Margin/VBox/TopBar/RightControls/BtnLobbyGuide")
@onready var btn_close_lobby: BaseButton = get_node_or_null("Margin/VBox/TopBar/RightControls/BtnCloseLobby")

# Tara Hub Main Selection (3 Taped-Paper Options)
@onready var tara_hub: Control = get_node_or_null("Margin/VBox/BodyArea/TaraHub")
@onready var btn_hub_host: Button = get_node_or_null("Margin/VBox/BodyArea/TaraHub/RowHost/BtnHubHost") if get_node_or_null("Margin/VBox/BodyArea/TaraHub/RowHost/BtnHubHost") else get_node_or_null("Margin/VBox/BodyArea/TaraHub/CardHost/BtnHubHost")
@onready var btn_hub_public: Button = get_node_or_null("Margin/VBox/BodyArea/TaraHub/RowPublic/BtnHubPublic") if get_node_or_null("Margin/VBox/BodyArea/TaraHub/RowPublic/BtnHubPublic") else get_node_or_null("Margin/VBox/BodyArea/TaraHub/CardPublic/BtnHubPublic")
@onready var btn_hub_private: Button = get_node_or_null("Margin/VBox/BodyArea/TaraHub/RowPrivate/BtnHubPrivate") if get_node_or_null("Margin/VBox/BodyArea/TaraHub/RowPrivate/BtnHubPrivate") else get_node_or_null("Margin/VBox/BodyArea/TaraHub/CardPrivate/BtnHubPrivate")

# Character Preview Panel (Legacy compatibility)
@onready var viewport_frame: Control = get_node_or_null("Margin/VBox/MainHBox/LeftColumn/PreviewCard/Margin/VBox/ViewportFrame")
@onready var preview_viewport_container: SubViewportContainer = get_node_or_null("Margin/VBox/MainHBox/LeftColumn/PreviewCard/Margin/VBox/ViewportFrame/PreviewViewportContainer")
@onready var preview_sub_viewport: SubViewport = get_node_or_null("Margin/VBox/MainHBox/LeftColumn/PreviewCard/Margin/VBox/ViewportFrame/PreviewViewportContainer/PreviewSubViewport")
@onready var preview_char: CharacterAnimator = get_node_or_null("Margin/VBox/MainHBox/LeftColumn/PreviewCard/Margin/VBox/ViewportFrame/PreviewViewportContainer/PreviewSubViewport/PreviewChar")
var _btn_prev_char_node: Button = null
var btn_prev_char: Button:
	get:
		if not is_instance_valid(_btn_prev_char_node):
			_btn_prev_char_node = get_node_or_null("Margin/VBox/MainHBox/LeftColumn/PreviewCard/Margin/VBox/ViewportFrame/BtnPrevChar")
			if _btn_prev_char_node and not _signals_connected:
				_connect_internal_signals()
		return _btn_prev_char_node
	set(v):
		_btn_prev_char_node = v

var _btn_next_char_node: Button = null
var btn_next_char: Button:
	get:
		if not is_instance_valid(_btn_next_char_node):
			_btn_next_char_node = get_node_or_null("Margin/VBox/MainHBox/LeftColumn/PreviewCard/Margin/VBox/ViewportFrame/BtnNextChar")
			if _btn_next_char_node and not _signals_connected:
				_connect_internal_signals()
		return _btn_next_char_node
	set(v):
		_btn_next_char_node = v
@onready var char_name_label: Label = get_node_or_null("Margin/VBox/MainHBox/LeftColumn/PreviewCard/Margin/VBox/DetailsPill/HBox/CharName")
@onready var char_count_label: Label = get_node_or_null("Margin/VBox/MainHBox/LeftColumn/PreviewCard/Margin/VBox/DetailsPill/HBox/CharCount")
@onready var char_desc_label: Label = get_node_or_null("Margin/VBox/MainHBox/LeftColumn/PreviewCard/Margin/VBox/CharDesc")
@onready var palette_container: HBoxContainer = get_node_or_null("Margin/VBox/MainHBox/LeftColumn/PreviewCard/Margin/VBox/PaletteRow")
@onready var palette_dots_container: HBoxContainer = get_node_or_null("Margin/VBox/MainHBox/LeftColumn/PreviewCard/Margin/VBox/DotsRow")

var swipe_start_pos: Vector2 = Vector2.ZERO
var is_swiping: bool = false
var swipe_touch_id: int = -1
var has_swiped_current_gesture: bool = false
const SWIPE_THRESHOLD: float = 45.0

# Matchmaking / Sub-Screens
@onready var player_name_input: LineEdit = get_node_or_null("Margin/VBox/MainHBox/RightColumn/LobbyCard/Margin/VBox/NameRow/NameInput")
@onready var btn_tab_lobbies: Button = get_node_or_null("Margin/VBox/MainHBox/RightColumn/LobbyCard/Margin/VBox/TabsRow/BtnTabLobbies")
@onready var btn_tab_create: Button = get_node_or_null("Margin/VBox/MainHBox/RightColumn/LobbyCard/Margin/VBox/TabsRow/BtnTabCreate")
@onready var btn_tab_hotspot: Button = get_node_or_null("Margin/VBox/MainHBox/RightColumn/LobbyCard/Margin/VBox/TabsRow/BtnTabHotspot")

# Tab Sub-Panels
@onready var panel_hotspot: VBoxContainer = get_node_or_null("Margin/VBox/BodyArea/SubScreens/PanelHotspot")
@onready var panel_lobbies: VBoxContainer = get_node_or_null("Margin/VBox/BodyArea/SubScreens/PanelLobbies")
@onready var panel_create: VBoxContainer = get_node_or_null("Margin/VBox/BodyArea/SubScreens/PanelCreate")

# Hotspot / Solo Sub-Panel Controls
@onready var hotspot_ip_input: LineEdit = get_node_or_null("Margin/VBox/BodyArea/SubScreens/PanelHotspot/CardPanel/Content/IpRow/IpInput")
@onready var btn_refresh_ip: Button = get_node_or_null("Margin/VBox/BodyArea/SubScreens/PanelHotspot/CardPanel/Content/IpRow/BtnRefreshIp")
@onready var btn_hotspot_host: Button = get_node_or_null("Margin/VBox/BodyArea/SubScreens/PanelHotspot/CardPanel/Content/Actions/BtnHotspotHost")
@onready var btn_hotspot_join: Button = get_node_or_null("Margin/VBox/BodyArea/SubScreens/PanelHotspot/CardPanel/Content/IpRow/BtnHotspotJoin")
@onready var btn_solo_practice: Button = get_node_or_null("Margin/VBox/BodyArea/SubScreens/PanelHotspot/CardPanel/Content/Actions/BtnSoloPractice")
@onready var local_ip_label: Label = get_node_or_null("Margin/VBox/BodyArea/SubScreens/PanelHotspot/CardPanel/Content/Footer/LocalIpLabel")
@onready var btn_copy_ip: Button = get_node_or_null("Margin/VBox/BodyArea/SubScreens/PanelHotspot/CardPanel/Content/IpRow/BtnCopyIp") if get_node_or_null("Margin/VBox/BodyArea/SubScreens/PanelHotspot/CardPanel/Content/IpRow/BtnCopyIp") else get_node_or_null("Margin/VBox/BodyArea/SubScreens/PanelHotspot/CardPanel/Content/Footer/BtnCopyIp")

# Online Lobbies Sub-Panel Controls
@onready var code_input: LineEdit = get_node_or_null("Margin/VBox/BodyArea/SubScreens/PanelLobbies/CardPanel/Content/CodeRow/CodeInput")
@onready var btn_join_code: Button = get_node_or_null("Margin/VBox/BodyArea/SubScreens/PanelLobbies/CardPanel/Content/CodeRow/BtnJoinCode")
@onready var lobby_list_container: VBoxContainer = get_node_or_null("Margin/VBox/BodyArea/SubScreens/PanelLobbies/CardPanel/Content/Scroll/LobbyListContainer")
@onready var btn_refresh_lobbies: Button = get_node_or_null("Margin/VBox/BodyArea/SubScreens/PanelLobbies/CardPanel/Content/CodeRow/BtnRefreshLobbies")

# Create Room Sub-Panel Controls
@onready var create_name_input: LineEdit = get_node_or_null("Margin/VBox/BodyArea/SubScreens/PanelCreate/CardPanel/Content/NameRow/CreateNameInput")
@onready var duration_option: OptionButton = get_node_or_null("Margin/VBox/BodyArea/SubScreens/PanelCreate/CardPanel/Content/DurationRow/DurationOption")
@onready var players_slider: HSlider = get_node_or_null("Margin/VBox/BodyArea/SubScreens/PanelCreate/CardPanel/Content/PlayersRow/PlayersSlider")
@onready var players_slider_val: Label = get_node_or_null("Margin/VBox/BodyArea/SubScreens/PanelCreate/CardPanel/Content/PlayersRow/HBox/Val")
@onready var btn_create_submit: Button = get_node_or_null("Margin/VBox/BodyArea/SubScreens/PanelCreate/CardPanel/Content/BtnCreateSubmit")

# Room Waiting View (When in a room waiting for players)
@onready var panel_room_waiting: VBoxContainer = get_node_or_null("Margin/VBox/BodyArea/SubScreens/PanelRoomWaiting")
@onready var room_name_title: Label = get_node_or_null("Margin/VBox/BodyArea/SubScreens/PanelRoomWaiting/CardPanel/Content/RoomTitle")
@onready var room_slots_container: VBoxContainer = get_node_or_null("Margin/VBox/BodyArea/SubScreens/PanelRoomWaiting/CardPanel/Content/SlotsScroll/SlotsContainer")
@onready var btn_leave_room: Button = get_node_or_null("Margin/VBox/BodyArea/SubScreens/PanelRoomWaiting/CardPanel/Content/ActionRow/BtnLeaveRoom")
@onready var btn_start_game: Button = get_node_or_null("Margin/VBox/BodyArea/SubScreens/PanelRoomWaiting/CardPanel/Content/ActionRow/BtnStartGame")

# Bottom Bar (Legacy compatibility)
@onready var info_tip_label: Label = get_node_or_null("Margin/VBox/BottomBar/TipHBox/TipLabel")

# Active selection data
var current_archetype_idx: int = 2 # Default: Totoy!
var current_color_idx: int = 0
var is_in_room: bool = false
var is_room_host: bool = false
var _saved_nickname: String = "Totoy"

func _enter_tree() -> void:
	_init_references()

func _ready() -> void:
	_init_references()
	_connect_internal_signals()
	_setup_options()
	open_hub()

func open_hub() -> void:
	if tara_hub:
		tara_hub.visible = true
	if panel_create:
		panel_create.visible = false
	if panel_lobbies:
		panel_lobbies.visible = false
	if panel_hotspot:
		panel_hotspot.visible = false
	if panel_room_waiting:
		panel_room_waiting.visible = false
	if btn_back:
		btn_back.visible = false
	if nickname_badge:
		nickname_badge.visible = false
	if btn_settings:
		btn_settings.visible = false
	var title_node = get_node_or_null("Margin/VBox/TopBar/CenterTitle/Title")
	if title_node:
		title_node.visible = false
	if btn_guide:
		btn_guide.visible = true
	if btn_close_lobby:
		btn_close_lobby.visible = true
	_update_header_player_names()

func _update_header_player_names() -> void:
	var name_to_show: String = _saved_nickname if not _saved_nickname.is_empty() else "Totoy"
	var host_lbl = get_node_or_null("Margin/VBox/BodyArea/SubScreens/PanelCreate/HeaderRow/TextCol/HostPlayerName")
	if host_lbl: host_lbl.text = name_to_show
	var pub_lbl = get_node_or_null("Margin/VBox/BodyArea/SubScreens/PanelLobbies/HeaderRow/TextCol/PublicPlayerName")
	if pub_lbl: pub_lbl.text = name_to_show
	var priv_lbl = get_node_or_null("Margin/VBox/BodyArea/SubScreens/PanelHotspot/HeaderRow/TextCol/PrivatePlayerName")
	if priv_lbl: priv_lbl.text = name_to_show

func open_subscreen(tab: LobbyTab) -> void:
	switch_tab(tab)

func _init_references() -> void:
	if not btn_back: btn_back = get_node_or_null("Margin/VBox/TopBar/LeftControls/BtnBack")
	if not btn_main_menu: btn_main_menu = get_node_or_null("Margin/VBox/TopBar/LeftControls/BtnMainMenu")
	if not nickname_badge: nickname_badge = get_node_or_null("Margin/VBox/TopBar/CenterTitle/NicknameBadge")
	if not btn_settings: btn_settings = get_node_or_null("Margin/VBox/TopBar/RightControls/BtnLobbySettings")
	if not btn_store: btn_store = get_node_or_null("Margin/VBox/TopBar/RightControls/BtnLobbyStore")
	if not btn_guide: btn_guide = get_node_or_null("Margin/VBox/TopBar/RightControls/BtnLobbyGuide")
	if not btn_close_lobby: btn_close_lobby = get_node_or_null("Margin/VBox/TopBar/RightControls/BtnCloseLobby")

	if not tara_hub: tara_hub = get_node_or_null("Margin/VBox/BodyArea/TaraHub")
	if not btn_hub_host:
		btn_hub_host = get_node_or_null("Margin/VBox/BodyArea/TaraHub/RowHost/BtnHubHost") if get_node_or_null("Margin/VBox/BodyArea/TaraHub/RowHost/BtnHubHost") else get_node_or_null("Margin/VBox/BodyArea/TaraHub/CardHost/BtnHubHost")
	if not btn_hub_public:
		btn_hub_public = get_node_or_null("Margin/VBox/BodyArea/TaraHub/RowPublic/BtnHubPublic") if get_node_or_null("Margin/VBox/BodyArea/TaraHub/RowPublic/BtnHubPublic") else get_node_or_null("Margin/VBox/BodyArea/TaraHub/CardPublic/BtnHubPublic")
	if not btn_hub_private:
		btn_hub_private = get_node_or_null("Margin/VBox/BodyArea/TaraHub/RowPrivate/BtnHubPrivate") if get_node_or_null("Margin/VBox/BodyArea/TaraHub/RowPrivate/BtnHubPrivate") else get_node_or_null("Margin/VBox/BodyArea/TaraHub/CardPrivate/BtnHubPrivate")

	if not viewport_frame: viewport_frame = get_node_or_null("Margin/VBox/MainHBox/LeftColumn/PreviewCard/Margin/VBox/ViewportFrame")
	if not preview_viewport_container: preview_viewport_container = get_node_or_null("Margin/VBox/MainHBox/LeftColumn/PreviewCard/Margin/VBox/ViewportFrame/PreviewViewportContainer")
	if not preview_sub_viewport: preview_sub_viewport = get_node_or_null("Margin/VBox/MainHBox/LeftColumn/PreviewCard/Margin/VBox/ViewportFrame/PreviewViewportContainer/PreviewSubViewport")
	if not preview_char: preview_char = get_node_or_null("Margin/VBox/MainHBox/LeftColumn/PreviewCard/Margin/VBox/ViewportFrame/PreviewViewportContainer/PreviewSubViewport/PreviewChar")
	if not _btn_prev_char_node: _btn_prev_char_node = get_node_or_null("Margin/VBox/MainHBox/LeftColumn/PreviewCard/Margin/VBox/ViewportFrame/BtnPrevChar")
	if not _btn_next_char_node: _btn_next_char_node = get_node_or_null("Margin/VBox/MainHBox/LeftColumn/PreviewCard/Margin/VBox/ViewportFrame/BtnNextChar")
	if not char_name_label: char_name_label = get_node_or_null("Margin/VBox/MainHBox/LeftColumn/PreviewCard/Margin/VBox/DetailsPill/HBox/CharName")
	if not char_count_label: char_count_label = get_node_or_null("Margin/VBox/MainHBox/LeftColumn/PreviewCard/Margin/VBox/DetailsPill/HBox/CharCount")
	if not char_desc_label: char_desc_label = get_node_or_null("Margin/VBox/MainHBox/LeftColumn/PreviewCard/Margin/VBox/CharDesc")
	if not palette_container: palette_container = get_node_or_null("Margin/VBox/MainHBox/LeftColumn/PreviewCard/Margin/VBox/PaletteRow")
	if not palette_dots_container: palette_dots_container = get_node_or_null("Margin/VBox/MainHBox/LeftColumn/PreviewCard/Margin/VBox/DotsRow")

	if not player_name_input: player_name_input = get_node_or_null("Margin/VBox/MainHBox/RightColumn/LobbyCard/Margin/VBox/NameRow/NameInput")
	if not btn_tab_lobbies: btn_tab_lobbies = get_node_or_null("Margin/VBox/MainHBox/RightColumn/LobbyCard/Margin/VBox/TabsRow/BtnTabLobbies")
	if not btn_tab_create: btn_tab_create = get_node_or_null("Margin/VBox/MainHBox/RightColumn/LobbyCard/Margin/VBox/TabsRow/BtnTabCreate")
	if not btn_tab_hotspot: btn_tab_hotspot = get_node_or_null("Margin/VBox/MainHBox/RightColumn/LobbyCard/Margin/VBox/TabsRow/BtnTabHotspot")

	if not panel_hotspot:
		panel_hotspot = get_node_or_null("Margin/VBox/BodyArea/SubScreens/PanelHotspot") if get_node_or_null("Margin/VBox/BodyArea/SubScreens/PanelHotspot") else get_node_or_null("Margin/VBox/MainHBox/RightColumn/LobbyCard/Margin/VBox/ContentPanels/PanelHotspot")
	if not panel_lobbies:
		panel_lobbies = get_node_or_null("Margin/VBox/BodyArea/SubScreens/PanelLobbies") if get_node_or_null("Margin/VBox/BodyArea/SubScreens/PanelLobbies") else get_node_or_null("Margin/VBox/MainHBox/RightColumn/LobbyCard/Margin/VBox/ContentPanels/PanelLobbies")
	if not panel_create:
		panel_create = get_node_or_null("Margin/VBox/BodyArea/SubScreens/PanelCreate") if get_node_or_null("Margin/VBox/BodyArea/SubScreens/PanelCreate") else get_node_or_null("Margin/VBox/MainHBox/RightColumn/LobbyCard/Margin/VBox/ContentPanels/PanelCreate")

	if not hotspot_ip_input:
		hotspot_ip_input = get_node_or_null("Margin/VBox/BodyArea/SubScreens/PanelHotspot/CardPanel/Content/IpRow/IpInput") if get_node_or_null("Margin/VBox/BodyArea/SubScreens/PanelHotspot/CardPanel/Content/IpRow/IpInput") else get_node_or_null("Margin/VBox/MainHBox/RightColumn/LobbyCard/Margin/VBox/ContentPanels/PanelHotspot/IpRow/IpInput")
	if not btn_refresh_ip:
		btn_refresh_ip = get_node_or_null("Margin/VBox/BodyArea/SubScreens/PanelHotspot/CardPanel/Content/IpRow/BtnRefreshIp") if get_node_or_null("Margin/VBox/BodyArea/SubScreens/PanelHotspot/CardPanel/Content/IpRow/BtnRefreshIp") else get_node_or_null("Margin/VBox/MainHBox/RightColumn/LobbyCard/Margin/VBox/ContentPanels/PanelHotspot/IpRow/BtnRefreshIp")
	if not btn_hotspot_host:
		btn_hotspot_host = get_node_or_null("Margin/VBox/BodyArea/SubScreens/PanelHotspot/CardPanel/Content/Actions/BtnHotspotHost") if get_node_or_null("Margin/VBox/BodyArea/SubScreens/PanelHotspot/CardPanel/Content/Actions/BtnHotspotHost") else get_node_or_null("Margin/VBox/MainHBox/RightColumn/LobbyCard/Margin/VBox/ContentPanels/PanelHotspot/Actions/BtnHotspotHost")
	if not btn_hotspot_join:
		btn_hotspot_join = get_node_or_null("Margin/VBox/BodyArea/SubScreens/PanelHotspot/CardPanel/Content/IpRow/BtnHotspotJoin") if get_node_or_null("Margin/VBox/BodyArea/SubScreens/PanelHotspot/CardPanel/Content/IpRow/BtnHotspotJoin") else get_node_or_null("Margin/VBox/MainHBox/RightColumn/LobbyCard/Margin/VBox/ContentPanels/PanelHotspot/Actions/BtnHotspotJoin")
	if not btn_solo_practice:
		btn_solo_practice = get_node_or_null("Margin/VBox/BodyArea/SubScreens/PanelHotspot/CardPanel/Content/Actions/BtnSoloPractice") if get_node_or_null("Margin/VBox/BodyArea/SubScreens/PanelHotspot/CardPanel/Content/Actions/BtnSoloPractice") else get_node_or_null("Margin/VBox/MainHBox/RightColumn/LobbyCard/Margin/VBox/ContentPanels/PanelHotspot/Actions/BtnSoloPractice")
	if not local_ip_label:
		local_ip_label = get_node_or_null("Margin/VBox/BodyArea/SubScreens/PanelHotspot/CardPanel/Content/Footer/LocalIpLabel") if get_node_or_null("Margin/VBox/BodyArea/SubScreens/PanelHotspot/CardPanel/Content/Footer/LocalIpLabel") else get_node_or_null("Margin/VBox/MainHBox/RightColumn/LobbyCard/Margin/VBox/ContentPanels/PanelHotspot/Footer/LocalIpLabel")
	if not btn_copy_ip:
		btn_copy_ip = get_node_or_null("Margin/VBox/BodyArea/SubScreens/PanelHotspot/CardPanel/Content/IpRow/BtnCopyIp") if get_node_or_null("Margin/VBox/BodyArea/SubScreens/PanelHotspot/CardPanel/Content/IpRow/BtnCopyIp") else get_node_or_null("Margin/VBox/BodyArea/SubScreens/PanelHotspot/CardPanel/Content/Footer/BtnCopyIp")

	if not code_input:
		code_input = get_node_or_null("Margin/VBox/BodyArea/SubScreens/PanelLobbies/CardPanel/Content/CodeRow/CodeInput") if get_node_or_null("Margin/VBox/BodyArea/SubScreens/PanelLobbies/CardPanel/Content/CodeRow/CodeInput") else get_node_or_null("Margin/VBox/MainHBox/RightColumn/LobbyCard/Margin/VBox/ContentPanels/PanelLobbies/CodeRow/CodeInput")
	if not btn_join_code:
		btn_join_code = get_node_or_null("Margin/VBox/BodyArea/SubScreens/PanelLobbies/CardPanel/Content/CodeRow/BtnJoinCode") if get_node_or_null("Margin/VBox/BodyArea/SubScreens/PanelLobbies/CardPanel/Content/CodeRow/BtnJoinCode") else get_node_or_null("Margin/VBox/MainHBox/RightColumn/LobbyCard/Margin/VBox/ContentPanels/PanelLobbies/CodeRow/BtnJoinCode")
	if not lobby_list_container:
		lobby_list_container = get_node_or_null("Margin/VBox/BodyArea/SubScreens/PanelLobbies/CardPanel/Content/Scroll/LobbyListContainer") if get_node_or_null("Margin/VBox/BodyArea/SubScreens/PanelLobbies/CardPanel/Content/Scroll/LobbyListContainer") else get_node_or_null("Margin/VBox/MainHBox/RightColumn/LobbyCard/Margin/VBox/ContentPanels/PanelLobbies/Scroll/LobbyListContainer")
	if not btn_refresh_lobbies:
		btn_refresh_lobbies = get_node_or_null("Margin/VBox/BodyArea/SubScreens/PanelLobbies/CardPanel/Content/CodeRow/BtnRefreshLobbies") if get_node_or_null("Margin/VBox/BodyArea/SubScreens/PanelLobbies/CardPanel/Content/CodeRow/BtnRefreshLobbies") else get_node_or_null("Margin/VBox/MainHBox/RightColumn/LobbyCard/Margin/VBox/ContentPanels/PanelLobbies/BtnRefreshLobbies")

	if not create_name_input:
		create_name_input = get_node_or_null("Margin/VBox/BodyArea/SubScreens/PanelCreate/CardPanel/Content/NameRow/CreateNameInput") if get_node_or_null("Margin/VBox/BodyArea/SubScreens/PanelCreate/CardPanel/Content/NameRow/CreateNameInput") else get_node_or_null("Margin/VBox/MainHBox/RightColumn/LobbyCard/Margin/VBox/ContentPanels/PanelCreate/NameRow/CreateNameInput")
	if not duration_option:
		duration_option = get_node_or_null("Margin/VBox/BodyArea/SubScreens/PanelCreate/CardPanel/Content/DurationRow/DurationOption") if get_node_or_null("Margin/VBox/BodyArea/SubScreens/PanelCreate/CardPanel/Content/DurationRow/DurationOption") else get_node_or_null("Margin/VBox/MainHBox/RightColumn/LobbyCard/Margin/VBox/ContentPanels/PanelCreate/DurationRow/DurationOption")
	if not players_slider:
		players_slider = get_node_or_null("Margin/VBox/BodyArea/SubScreens/PanelCreate/CardPanel/Content/PlayersRow/PlayersSlider") if get_node_or_null("Margin/VBox/BodyArea/SubScreens/PanelCreate/CardPanel/Content/PlayersRow/PlayersSlider") else get_node_or_null("Margin/VBox/MainHBox/RightColumn/LobbyCard/Margin/VBox/ContentPanels/PanelCreate/PlayersRow/PlayersSlider")
	if not players_slider_val:
		players_slider_val = get_node_or_null("Margin/VBox/BodyArea/SubScreens/PanelCreate/CardPanel/Content/PlayersRow/HBox/Val") if get_node_or_null("Margin/VBox/BodyArea/SubScreens/PanelCreate/CardPanel/Content/PlayersRow/HBox/Val") else get_node_or_null("Margin/VBox/MainHBox/RightColumn/LobbyCard/Margin/VBox/ContentPanels/PanelCreate/PlayersRow/Val")
	if not btn_create_submit:
		btn_create_submit = get_node_or_null("Margin/VBox/BodyArea/SubScreens/PanelCreate/CardPanel/Content/BtnCreateSubmit") if get_node_or_null("Margin/VBox/BodyArea/SubScreens/PanelCreate/CardPanel/Content/BtnCreateSubmit") else get_node_or_null("Margin/VBox/MainHBox/RightColumn/LobbyCard/Margin/VBox/ContentPanels/PanelCreate/BtnCreateSubmit")

	if not panel_room_waiting:
		panel_room_waiting = get_node_or_null("Margin/VBox/BodyArea/SubScreens/PanelRoomWaiting") if get_node_or_null("Margin/VBox/BodyArea/SubScreens/PanelRoomWaiting") else get_node_or_null("Margin/VBox/MainHBox/RightColumn/LobbyCard/Margin/VBox/ContentPanels/PanelRoomWaiting")
	if not room_name_title:
		room_name_title = get_node_or_null("Margin/VBox/BodyArea/SubScreens/PanelRoomWaiting/CardPanel/Content/RoomTitle") if get_node_or_null("Margin/VBox/BodyArea/SubScreens/PanelRoomWaiting/CardPanel/Content/RoomTitle") else get_node_or_null("Margin/VBox/MainHBox/RightColumn/LobbyCard/Margin/VBox/ContentPanels/PanelRoomWaiting/RoomTitle")
	if not room_slots_container:
		room_slots_container = get_node_or_null("Margin/VBox/BodyArea/SubScreens/PanelRoomWaiting/CardPanel/Content/SlotsScroll/SlotsContainer") if get_node_or_null("Margin/VBox/BodyArea/SubScreens/PanelRoomWaiting/CardPanel/Content/SlotsScroll/SlotsContainer") else get_node_or_null("Margin/VBox/MainHBox/RightColumn/LobbyCard/Margin/VBox/ContentPanels/PanelRoomWaiting/SlotsScroll/SlotsContainer")
	if not btn_leave_room:
		btn_leave_room = get_node_or_null("Margin/VBox/BodyArea/SubScreens/PanelRoomWaiting/CardPanel/Content/ActionRow/BtnLeaveRoom") if get_node_or_null("Margin/VBox/BodyArea/SubScreens/PanelRoomWaiting/CardPanel/Content/ActionRow/BtnLeaveRoom") else get_node_or_null("Margin/VBox/MainHBox/RightColumn/LobbyCard/Margin/VBox/ContentPanels/PanelRoomWaiting/BtnLeaveRoom")
	if not btn_start_game:
		btn_start_game = get_node_or_null("Margin/VBox/BodyArea/SubScreens/PanelRoomWaiting/CardPanel/Content/ActionRow/BtnStartGame") if get_node_or_null("Margin/VBox/BodyArea/SubScreens/PanelRoomWaiting/CardPanel/Content/ActionRow/BtnStartGame") else get_node_or_null("Margin/VBox/BottomBar/BtnStartGame")

var _signals_connected: bool = false

func _connect_internal_signals() -> void:
	if _signals_connected:
		return
	_signals_connected = true

	# Navigation Buttons
	if btn_back:
		btn_back.pressed.connect(_on_back_pressed)
	if btn_main_menu:
		btn_main_menu.pressed.connect(_on_back_pressed)
	if nickname_badge:
		nickname_badge.pressed.connect(func():
			var am = get_node_or_null("/root/AudioManager")
			if am and am.has_method("play_ui_click"): am.play_ui_click()
			customization_requested.emit()
		)
	if btn_settings:
		btn_settings.pressed.connect(func():
			var am = get_node_or_null("/root/AudioManager")
			if am and am.has_method("play_ui_click"): am.play_ui_click()
			settings_requested.emit()
		)
	if btn_store:
		btn_store.pressed.connect(func():
			var am = get_node_or_null("/root/AudioManager")
			if am and am.has_method("play_ui_click"): am.play_ui_click()
			store_requested.emit()
		)
	if btn_guide:
		btn_guide.pressed.connect(func():
			var am = get_node_or_null("/root/AudioManager")
			if am and am.has_method("play_ui_click"): am.play_ui_click()
			guide_requested.emit()
		)
	if btn_close_lobby:
		btn_close_lobby.pressed.connect(func():
			var am = get_node_or_null("/root/AudioManager")
			if am and am.has_method("play_ui_cancel"): am.play_ui_cancel()
			if tara_hub and not tara_hub.visible:
				open_hub()
			else:
				main_menu_requested.emit()
		)

	# Tara Hub Row selections & Hover
	if btn_hub_host:
		btn_hub_host.pressed.connect(func(): switch_tab(LobbyTab.CREATE))
	if btn_hub_public:
		btn_hub_public.pressed.connect(func(): switch_tab(LobbyTab.BROWSE))
	if btn_hub_private:
		btn_hub_private.pressed.connect(func(): switch_tab(LobbyTab.HOTSPOT_SOLO))

	var setup_row_hover = func(btn: Button, row_node: Control):
		if not btn or not row_node:
			return
		btn.mouse_entered.connect(func():
			var tw = row_node.create_tween().set_parallel(true)
			tw.tween_property(row_node, "modulate", Color(1.08, 1.05, 0.88, 1.0), 0.12)
		)
		btn.mouse_exited.connect(func():
			var tw = row_node.create_tween().set_parallel(true)
			tw.tween_property(row_node, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.12)
		)

	setup_row_hover.call(btn_hub_host, get_node_or_null("Margin/VBox/BodyArea/TaraHub/RowHost"))
	setup_row_hover.call(btn_hub_public, get_node_or_null("Margin/VBox/BodyArea/TaraHub/RowPublic"))
	setup_row_hover.call(btn_hub_private, get_node_or_null("Margin/VBox/BodyArea/TaraHub/RowPrivate"))

	# Legacy Character Carousel
	if btn_prev_char:
		btn_prev_char.pressed.connect(func():
			var am = get_node_or_null("/root/AudioManager")
			if am and am.has_method("play_ui_click"): am.play_ui_click()
			prev_char_requested.emit()
		)
	if btn_next_char:
		btn_next_char.pressed.connect(func():
			var am = get_node_or_null("/root/AudioManager")
			if am and am.has_method("play_ui_click"): am.play_ui_click()
			next_char_requested.emit()
		)
	if viewport_frame:
		viewport_frame.gui_input.connect(_on_viewport_frame_input)

	# Player Name
	if player_name_input:
		player_name_input.text_changed.connect(func(new_text: String):
			player_name_changed.emit(new_text.strip_edges())
		)

	# Legacy Tabs
	if btn_tab_lobbies:
		btn_tab_lobbies.pressed.connect(func(): switch_tab(LobbyTab.BROWSE))
	if btn_tab_create:
		btn_tab_create.pressed.connect(func(): switch_tab(LobbyTab.CREATE))
	if btn_tab_hotspot:
		btn_tab_hotspot.pressed.connect(func(): switch_tab(LobbyTab.HOTSPOT_SOLO))

	# Hotspot / Solo Actions
	if btn_hotspot_host:
		btn_hotspot_host.pressed.connect(func(): host_hotspot_requested.emit())
	if btn_hotspot_join:
		btn_hotspot_join.pressed.connect(func(): join_hotspot_requested.emit())
	if btn_solo_practice:
		btn_solo_practice.pressed.connect(func(): solo_practice_requested.emit())
	if btn_refresh_ip:
		btn_refresh_ip.pressed.connect(func(): refresh_ip_requested.emit())
	if btn_copy_ip:
		btn_copy_ip.pressed.connect(func(): copy_ip_requested.emit())
	if hotspot_ip_input:
		hotspot_ip_input.text_submitted.connect(func(_new_text):
			join_hotspot_requested.emit()
		)

	# Online Browse & Join
	if btn_refresh_lobbies:
		btn_refresh_lobbies.pressed.connect(func(): refresh_lobbies_requested.emit())
	if btn_join_code and code_input:
		btn_join_code.pressed.connect(func():
			var code := code_input.text.strip_edges()
			if not code.is_empty():
				join_code_requested.emit(code)
		)

	# Create Room
	if btn_create_submit:
		btn_create_submit.pressed.connect(_on_create_submit_pressed)
	if players_slider and players_slider_val:
		players_slider.value_changed.connect(func(v: float):
			players_slider_val.text = "%d / %d" % [int(v), int(players_slider.max_value)]
		)

	# Leave room
	if btn_leave_room:
		btn_leave_room.pressed.connect(func():
			set_room_waiting_state(false, false, "", {})
			leave_room_requested.emit()
			open_hub()
		)

	# Start Match CTA
	if btn_start_game:
		btn_start_game.pressed.connect(func(): start_game_requested.emit())

func _on_back_pressed() -> void:
	var am = get_node_or_null("/root/AudioManager")
	if am and am.has_method("play_ui_cancel"): am.play_ui_cancel()
	if tara_hub and not tara_hub.visible:
		open_hub()
	else:
		main_menu_requested.emit()

func _on_viewport_frame_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var touch_ev := event as InputEventScreenTouch
		if touch_ev.pressed and swipe_touch_id == -1:
			swipe_touch_id = touch_ev.index
			swipe_start_pos = touch_ev.position
			is_swiping = true
			has_swiped_current_gesture = false
		elif not touch_ev.pressed and touch_ev.index == swipe_touch_id:
			swipe_touch_id = -1
			is_swiping = false
			has_swiped_current_gesture = false
	elif event is InputEventScreenDrag:
		var drag_ev := event as InputEventScreenDrag
		if drag_ev.index == swipe_touch_id and not has_swiped_current_gesture:
			var delta_x: float = drag_ev.position.x - swipe_start_pos.x
			if abs(delta_x) >= SWIPE_THRESHOLD:
				has_swiped_current_gesture = true
				if delta_x > 0:
					prev_char_requested.emit()
				else:
					next_char_requested.emit()
				swipe_start_pos = drag_ev.position
	elif event is InputEventMouseButton and swipe_touch_id == -1:
		var mouse_btn := event as InputEventMouseButton
		if mouse_btn.button_index == MOUSE_BUTTON_LEFT:
			if mouse_btn.pressed:
				is_swiping = true
				has_swiped_current_gesture = false
				swipe_start_pos = mouse_btn.position
			else:
				is_swiping = false
				has_swiped_current_gesture = false
	elif event is InputEventMouseMotion and is_swiping and swipe_touch_id == -1 and not has_swiped_current_gesture:
		var mouse_motion := event as InputEventMouseMotion
		var delta_x: float = mouse_motion.position.x - swipe_start_pos.x
		if abs(delta_x) >= SWIPE_THRESHOLD:
			has_swiped_current_gesture = true
			if delta_x > 0:
				prev_char_requested.emit()
			else:
				next_char_requested.emit()
			swipe_start_pos = mouse_motion.position

func _setup_options() -> void:
	if duration_option:
		duration_option.clear()
		duration_option.add_item("30 Segundo (Mabilis)", 30)
		duration_option.add_item("45 Segundo (Standard)", 45)
		duration_option.add_item("60 Segundo (Mahaba)", 60)
		duration_option.add_item("90 Segundo (Matagalan)", 90)
		duration_option.add_item("120 Segundo (Todo)", 120)
		duration_option.select(1)

func switch_tab(tab: LobbyTab) -> void:
	current_tab = tab
	var am = get_node_or_null("/root/AudioManager")
	if am and am.has_method("play_ui_click"): am.play_ui_click()

	if tara_hub:
		tara_hub.visible = false
	if panel_room_waiting and panel_room_waiting.visible:
		panel_room_waiting.visible = false

	if panel_lobbies: panel_lobbies.visible = (tab == LobbyTab.BROWSE)
	if panel_create: panel_create.visible = (tab == LobbyTab.CREATE)
	if panel_hotspot: panel_hotspot.visible = (tab == LobbyTab.HOTSPOT_SOLO)

	if btn_back: btn_back.visible = true
	if btn_guide: btn_guide.visible = true
	if btn_close_lobby: btn_close_lobby.visible = false

	_update_header_player_names()

	_style_tab_button(btn_tab_lobbies, tab == LobbyTab.BROWSE)
	_style_tab_button(btn_tab_create, tab == LobbyTab.CREATE)
	_style_tab_button(btn_tab_hotspot, tab == LobbyTab.HOTSPOT_SOLO)

	_update_bottom_cta()
	tab_changed.emit(int(tab))

func _style_tab_button(btn: Button, is_active: bool) -> void:
	if not btn:
		return
	KalyeStyle.apply_button(btn, KalyeStyle.Kind.PRIMARY if is_active else KalyeStyle.Kind.TAB, 14)

func _update_bottom_cta() -> void:
	if not btn_start_game:
		return
	if is_in_room:
		if is_room_host:
			btn_start_game.text = "SIMULAN ANG LARO (Host) →"
			btn_start_game.disabled = false
		else:
			btn_start_game.text = "NAGHIHINTAY SA HOST..."
			btn_start_game.disabled = true
	else:
		btn_start_game.disabled = false
		match current_tab:
			LobbyTab.HOTSPOT_SOLO:
				btn_start_game.text = "SIMULA NG LARO →"
			LobbyTab.CREATE:
				btn_start_game.text = "BUKUIN AT SIMULAN →"
			LobbyTab.BROWSE:
				btn_start_game.text = "SUMALI SA LARO →"

func _on_create_submit_pressed() -> void:
	var r_name: String = create_name_input.text.strip_edges() if create_name_input else "Tambayan Room"
	if r_name.is_empty():
		r_name = "Tambayan Room"
	var mode_id: int = 0
	var dur_id: float = float(duration_option.get_selected_id()) if duration_option else 45.0
	var max_p: int = int(players_slider.value) if players_slider else 8
	create_room_submitted.emit(r_name, mode_id, dur_id, max_p)

# --- Public API methods called by GameManager ---

func set_player_name(pname: String) -> void:
	_saved_nickname = pname
	if player_name_input:
		player_name_input.text = pname
	if nickname_badge:
		nickname_badge.text = "👤  " + pname + " ✎"
	_update_header_player_names()

func get_player_name() -> String:
	if player_name_input and not player_name_input.text.strip_edges().is_empty():
		return player_name_input.text.strip_edges()
	return _saved_nickname

func update_character_info(idx: int, char_name: String, char_desc: String, is_unlocked: bool = true) -> void:
	current_archetype_idx = idx
	if char_name_label:
		if is_unlocked:
			char_name_label.text = char_name + " ✎"
		else:
			char_name_label.text = "🔒 " + char_name
	if char_count_label:
		char_count_label.text = "%d / 8" % (idx + 1)
	if char_desc_label:
		if is_unlocked:
			char_desc_label.text = "👕 " + char_desc
		else:
			char_desc_label.text = "🔒 NAKALOCK — Bilihin sa Tindahan ni Aling Nena (🪙)"

func set_color_swatches(colors: Array[Dictionary], selected_color_idx: int) -> void:
	current_color_idx = selected_color_idx
	if not palette_container:
		return
	for c in palette_container.get_children():
		c.queue_free()

	for i in range(colors.size()):
		var c_info: Dictionary = colors[i]
		var col: Color = c_info.get("color", Color.WHITE)
		var is_sel: bool = (i == selected_color_idx)

		var swatch := Button.new()
		swatch.custom_minimum_size = Vector2(46, 46)
		var sb := KalyeStyle.box(col, col.darkened(0.32), 12, 4, 4 if is_sel else 3, 0.22, 3)
		var sb_hover := KalyeStyle.box(col.lightened(0.1), col.darkened(0.25), 12, 4, 4 if is_sel else 3, 0.28, 3)
		var sb_pressed := KalyeStyle.box(col.darkened(0.08), col.darkened(0.38), 12, 2, 4 if is_sel else 3, 0.12, 1)
		if is_sel:
			sb.ink = KalyeStyle.YELLOW
			sb_hover.ink = KalyeStyle.YELLOW
			sb_pressed.ink = KalyeStyle.YELLOW
		swatch.add_theme_stylebox_override("normal", sb)
		swatch.add_theme_stylebox_override("hover", sb_hover)
		swatch.add_theme_stylebox_override("pressed", sb_pressed)

		var idx := i
		swatch.pressed.connect(func():
			current_color_idx = idx
			color_selected.emit(idx)
			set_color_swatches(colors, idx)
		)
		palette_container.add_child(swatch)

	_update_palette_dots(colors.size(), selected_color_idx)

func _update_palette_dots(total: int, active_idx: int) -> void:
	if not palette_dots_container:
		return
	for c in palette_dots_container.get_children():
		c.queue_free()

	for i in range(total):
		var dot := Label.new()
		dot.text = "●" if i == active_idx else "○"
		dot.add_theme_font_size_override("font_size", 12)
		dot.add_theme_color_override("font_color", KalyeStyle.TEXT_ACCENT if i == active_idx else KalyeStyle.TEXT_MUTED)
		palette_dots_container.add_child(dot)

func set_hotspot_ip(ip_str: String) -> void:
	if hotspot_ip_input:
		hotspot_ip_input.text = ip_str
	if local_ip_label:
		local_ip_label.text = "Lokal na IP: %s (Port 7777)" % ip_str

func get_hotspot_target_ip() -> String:
	if hotspot_ip_input:
		return hotspot_ip_input.text.strip_edges()
	return ""

func set_room_waiting_state(in_room: bool, is_host: bool = false, room_name: String = "", players: Dictionary = {}, max_slots: int = 0) -> void:
	is_in_room = in_room
	is_room_host = is_host

	var show_waiting: bool = in_room and panel_room_waiting != null
	if tara_hub:
		tara_hub.visible = not in_room and (current_tab != LobbyTab.HOTSPOT_SOLO and current_tab != LobbyTab.BROWSE and current_tab != LobbyTab.CREATE)
	if panel_room_waiting:
		panel_room_waiting.visible = in_room
	if panel_hotspot:
		panel_hotspot.visible = not show_waiting and (current_tab == LobbyTab.HOTSPOT_SOLO)
	if panel_lobbies:
		panel_lobbies.visible = not show_waiting and (current_tab == LobbyTab.BROWSE)
	if panel_create:
		panel_create.visible = not show_waiting and (current_tab == LobbyTab.CREATE)

	if in_room:
		if room_name_title:
			room_name_title.text = "KASALUKUYANG ROOM: " + room_name
		if room_slots_container:
			for c in room_slots_container.get_children():
				room_slots_container.remove_child(c)
				c.queue_free()

			var pids := players.keys()
			var total_slots: int = max_slots if max_slots > 0 else (int(players_slider.value) if players_slider else 24)
			total_slots = max(total_slots, pids.size())
			for i in range(total_slots):
				var slot_lbl := Label.new()
				slot_lbl.add_theme_font_size_override("font_size", 14)
				if i < pids.size():
					var pid = pids[i]
					var pinfo: Dictionary = players[pid]
					var is_p_host := (int(pid) == 1)
					var is_bot: bool = bool(pinfo.get("is_bot", false)) or (int(pid) in [97, 98, 99]) or (int(pid) >= 80 and int(pid) < 120)
					if is_bot:
						var bname: String = str(pinfo.get("name", "Bot"))
						if not bname.begins_with("[BOT]"):
							slot_lbl.text = "Slot %d: [BOT] %s" % [i + 1, bname]
						else:
							slot_lbl.text = "Slot %d: %s" % [i + 1, bname]
						slot_lbl.add_theme_color_override("font_color", KalyeStyle.TEXT_INFO)
					elif is_p_host:
						slot_lbl.text = "Slot %d: %s [HOST]" % [i + 1, pinfo.get("name", "Player")]
						slot_lbl.add_theme_color_override("font_color", KalyeStyle.TEXT_ACCENT)
					else:
						slot_lbl.text = "Slot %d: %s" % [i + 1, pinfo.get("name", "Player")]
						slot_lbl.add_theme_color_override("font_color", KalyeStyle.TEXT)
				else:
					slot_lbl.text = "Slot %d: (Bakante)" % (i + 1)
					slot_lbl.add_theme_color_override("font_color", KalyeStyle.TEXT_MUTED)
				room_slots_container.add_child(slot_lbl)

	_update_bottom_cta()

func populate_online_lobbies(lobbies: Array[Dictionary]) -> void:
	if not lobby_list_container:
		return
	for c in lobby_list_container.get_children():
		c.queue_free()

	if lobbies.is_empty():
		var empty_lbl := Label.new()
		empty_lbl.text = "Walang nahanap na aktibong kwarto sa kalye."
		empty_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		var font_res = preload("res://assets/fonts/LilitaOne-Regular.ttf")
		if font_res:
			empty_lbl.add_theme_font_override("font", font_res)
		empty_lbl.add_theme_font_size_override("font_size", 14)
		empty_lbl.add_theme_color_override("font_color", Color(1, 1, 1, 0.6))
		lobby_list_container.add_child(empty_lbl)
		return

	var font_res = preload("res://assets/fonts/LilitaOne-Regular.ttf")
	var normal_box = StyleBoxFlat.new()
	normal_box.bg_color = Color(0.08, 0.12, 0.22, 0.8)
	normal_box.set_border_width_all(1)
	normal_box.border_color = Color(1, 1, 1, 0.85)
	normal_box.set_corner_radius_all(8)
	normal_box.content_margin_left = 16
	normal_box.content_margin_right = 16
	normal_box.content_margin_top = 8
	normal_box.content_margin_bottom = 8

	var hover_box = StyleBoxFlat.new()
	hover_box.bg_color = Color(0.14, 0.18, 0.28, 0.95)
	hover_box.set_border_width_all(2)
	hover_box.border_color = Color(1.0, 0.88, 0.45, 1.0)
	hover_box.set_corner_radius_all(8)
	hover_box.content_margin_left = 16
	hover_box.content_margin_right = 16
	hover_box.content_margin_top = 8
	hover_box.content_margin_bottom = 8

	for l_data in lobbies:
		var card_btn := Button.new()
		card_btn.custom_minimum_size = Vector2(0, 42)
		card_btn.focus_mode = Control.FOCUS_NONE
		card_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		card_btn.add_theme_stylebox_override("normal", normal_box)
		card_btn.add_theme_stylebox_override("hover", hover_box)
		card_btn.add_theme_stylebox_override("pressed", hover_box)

		var margin := MarginContainer.new()
		margin.set_anchors_preset(Control.PRESET_FULL_RECT)
		margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
		margin.add_theme_constant_override("margin_left", 14)
		margin.add_theme_constant_override("margin_right", 14)
		card_btn.add_child(margin)

		var hbox := HBoxContainer.new()
		hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
		margin.add_child(hbox)

		var title := Label.new()
		title.text = str(l_data.get("name", "Tambayan"))
		title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		if font_res: title.add_theme_font_override("font", font_res)
		title.add_theme_font_size_override("font_size", 16)
		title.add_theme_color_override("font_color", Color(1, 1, 1, 1))
		title.mouse_filter = Control.MOUSE_FILTER_IGNORE
		hbox.add_child(title)

		var count_lbl := Label.new()
		var p_count = l_data.get("player_count", 1)
		var p_max = l_data.get("max_players", 8)
		count_lbl.text = "%d/%d" % [p_count, p_max]
		if font_res: count_lbl.add_theme_font_override("font", font_res)
		count_lbl.add_theme_font_size_override("font_size", 16)
		count_lbl.add_theme_color_override("font_color", Color(1, 1, 1, 1))
		count_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		hbox.add_child(count_lbl)

		var cur_data := l_data
		card_btn.pressed.connect(func():
			var am = get_node_or_null("/root/AudioManager")
			if am and am.has_method("play_ui_click"): am.play_ui_click()
			join_lobby_requested.emit(cur_data)
		)

		lobby_list_container.add_child(card_btn)
