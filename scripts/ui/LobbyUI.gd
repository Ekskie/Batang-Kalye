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

enum LobbyTab {
	BROWSE = 0,
	CREATE = 1,
	HOTSPOT_SOLO = 2
}

var current_tab: LobbyTab = LobbyTab.HOTSPOT_SOLO

# Top Navigation
@onready var btn_main_menu: Button = get_node_or_null("Margin/VBox/TopBar/LeftControls/BtnMainMenu")
@onready var btn_settings: Button = get_node_or_null("Margin/VBox/TopBar/RightControls/BtnLobbySettings")

# Character Preview Panel (Left)
@onready var preview_viewport_container: SubViewportContainer = get_node_or_null("Margin/VBox/MainHBox/LeftColumn/PreviewCard/Margin/VBox/ViewportFrame/PreviewViewportContainer")
@onready var preview_sub_viewport: SubViewport = get_node_or_null("Margin/VBox/MainHBox/LeftColumn/PreviewCard/Margin/VBox/ViewportFrame/PreviewViewportContainer/PreviewSubViewport")
@onready var preview_char: CharacterAnimator = get_node_or_null("Margin/VBox/MainHBox/LeftColumn/PreviewCard/Margin/VBox/ViewportFrame/PreviewViewportContainer/PreviewSubViewport/PreviewChar")
@onready var btn_prev_char: Button = get_node_or_null("Margin/VBox/MainHBox/LeftColumn/PreviewCard/Margin/VBox/ViewportFrame/BtnPrevChar")
@onready var btn_next_char: Button = get_node_or_null("Margin/VBox/MainHBox/LeftColumn/PreviewCard/Margin/VBox/ViewportFrame/BtnNextChar")
@onready var char_name_label: Label = get_node_or_null("Margin/VBox/MainHBox/LeftColumn/PreviewCard/Margin/VBox/DetailsPill/HBox/CharName")
@onready var char_count_label: Label = get_node_or_null("Margin/VBox/MainHBox/LeftColumn/PreviewCard/Margin/VBox/DetailsPill/HBox/CharCount")
@onready var char_desc_label: Label = get_node_or_null("Margin/VBox/MainHBox/LeftColumn/PreviewCard/Margin/VBox/CharDesc")
@onready var palette_container: HBoxContainer = get_node_or_null("Margin/VBox/MainHBox/LeftColumn/PreviewCard/Margin/VBox/PaletteRow")
@onready var palette_dots_container: HBoxContainer = get_node_or_null("Margin/VBox/MainHBox/LeftColumn/PreviewCard/Margin/VBox/DotsRow")

# Matchmaking / Lobby Card (Right)
@onready var player_name_input: LineEdit = get_node_or_null("Margin/VBox/MainHBox/RightColumn/LobbyCard/Margin/VBox/NameRow/NameInput")
@onready var btn_tab_lobbies: Button = get_node_or_null("Margin/VBox/MainHBox/RightColumn/LobbyCard/Margin/VBox/TabsRow/BtnTabLobbies")
@onready var btn_tab_create: Button = get_node_or_null("Margin/VBox/MainHBox/RightColumn/LobbyCard/Margin/VBox/TabsRow/BtnTabCreate")
@onready var btn_tab_hotspot: Button = get_node_or_null("Margin/VBox/MainHBox/RightColumn/LobbyCard/Margin/VBox/TabsRow/BtnTabHotspot")

# Tab Sub-Panels
@onready var panel_hotspot: VBoxContainer = get_node_or_null("Margin/VBox/MainHBox/RightColumn/LobbyCard/Margin/VBox/ContentPanels/PanelHotspot")
@onready var panel_lobbies: VBoxContainer = get_node_or_null("Margin/VBox/MainHBox/RightColumn/LobbyCard/Margin/VBox/ContentPanels/PanelLobbies")
@onready var panel_create: VBoxContainer = get_node_or_null("Margin/VBox/MainHBox/RightColumn/LobbyCard/Margin/VBox/ContentPanels/PanelCreate")

# Hotspot / Solo Sub-Panel Controls
@onready var hotspot_ip_input: LineEdit = get_node_or_null("Margin/VBox/MainHBox/RightColumn/LobbyCard/Margin/VBox/ContentPanels/PanelHotspot/IpRow/IpInput")
@onready var btn_refresh_ip: Button = get_node_or_null("Margin/VBox/MainHBox/RightColumn/LobbyCard/Margin/VBox/ContentPanels/PanelHotspot/IpRow/BtnRefreshIp")
@onready var btn_hotspot_host: Button = get_node_or_null("Margin/VBox/MainHBox/RightColumn/LobbyCard/Margin/VBox/ContentPanels/PanelHotspot/Actions/BtnHotspotHost")
@onready var btn_hotspot_join: Button = get_node_or_null("Margin/VBox/MainHBox/RightColumn/LobbyCard/Margin/VBox/ContentPanels/PanelHotspot/Actions/BtnHotspotJoin")
@onready var btn_solo_practice: Button = get_node_or_null("Margin/VBox/MainHBox/RightColumn/LobbyCard/Margin/VBox/ContentPanels/PanelHotspot/Actions/BtnSoloPractice")
@onready var local_ip_label: Label = get_node_or_null("Margin/VBox/MainHBox/RightColumn/LobbyCard/Margin/VBox/ContentPanels/PanelHotspot/Footer/LocalIpLabel")
@onready var btn_copy_ip: Button = get_node_or_null("Margin/VBox/MainHBox/RightColumn/LobbyCard/Margin/VBox/ContentPanels/PanelHotspot/Footer/BtnCopyIp")

# Online Lobbies Sub-Panel Controls
@onready var code_input: LineEdit = get_node_or_null("Margin/VBox/MainHBox/RightColumn/LobbyCard/Margin/VBox/ContentPanels/PanelLobbies/CodeRow/CodeInput")
@onready var btn_join_code: Button = get_node_or_null("Margin/VBox/MainHBox/RightColumn/LobbyCard/Margin/VBox/ContentPanels/PanelLobbies/CodeRow/BtnJoinCode")
@onready var lobby_list_container: VBoxContainer = get_node_or_null("Margin/VBox/MainHBox/RightColumn/LobbyCard/Margin/VBox/ContentPanels/PanelLobbies/Scroll/LobbyListContainer")
@onready var btn_refresh_lobbies: Button = get_node_or_null("Margin/VBox/MainHBox/RightColumn/LobbyCard/Margin/VBox/ContentPanels/PanelLobbies/BtnRefreshLobbies")

# Create Room Sub-Panel Controls
@onready var create_name_input: LineEdit = get_node_or_null("Margin/VBox/MainHBox/RightColumn/LobbyCard/Margin/VBox/ContentPanels/PanelCreate/NameRow/CreateNameInput")
@onready var mode_option: OptionButton = get_node_or_null("Margin/VBox/MainHBox/RightColumn/LobbyCard/Margin/VBox/ContentPanels/PanelCreate/ModeRow/ModeOption")
@onready var duration_option: OptionButton = get_node_or_null("Margin/VBox/MainHBox/RightColumn/LobbyCard/Margin/VBox/ContentPanels/PanelCreate/DurationRow/DurationOption")
@onready var players_slider: HSlider = get_node_or_null("Margin/VBox/MainHBox/RightColumn/LobbyCard/Margin/VBox/ContentPanels/PanelCreate/PlayersRow/PlayersSlider")
@onready var players_slider_val: Label = get_node_or_null("Margin/VBox/MainHBox/RightColumn/LobbyCard/Margin/VBox/ContentPanels/PanelCreate/PlayersRow/Val")
@onready var btn_create_submit: Button = get_node_or_null("Margin/VBox/MainHBox/RightColumn/LobbyCard/Margin/VBox/ContentPanels/PanelCreate/BtnCreateSubmit")

# Room Waiting View (When in a room waiting for players)
@onready var panel_room_waiting: VBoxContainer = get_node_or_null("Margin/VBox/MainHBox/RightColumn/LobbyCard/Margin/VBox/ContentPanels/PanelRoomWaiting")
@onready var room_name_title: Label = get_node_or_null("Margin/VBox/MainHBox/RightColumn/LobbyCard/Margin/VBox/ContentPanels/PanelRoomWaiting/RoomTitle")
@onready var room_slots_container: VBoxContainer = get_node_or_null("Margin/VBox/MainHBox/RightColumn/LobbyCard/Margin/VBox/ContentPanels/PanelRoomWaiting/SlotsContainer")
@onready var btn_leave_room: Button = get_node_or_null("Margin/VBox/MainHBox/RightColumn/LobbyCard/Margin/VBox/ContentPanels/PanelRoomWaiting/BtnLeaveRoom")

# Bottom Bar
@onready var info_tip_label: Label = get_node_or_null("Margin/VBox/BottomBar/TipHBox/TipLabel")
@onready var btn_start_game: Button = get_node_or_null("Margin/VBox/BottomBar/BtnStartGame")

# Active selection data
var current_archetype_idx: int = 2 # Default: Totoy!
var current_color_idx: int = 0
var is_in_room: bool = false
var is_room_host: bool = false

func _ready() -> void:
	_init_references()
	_connect_internal_signals()
	switch_tab(LobbyTab.HOTSPOT_SOLO)
	_setup_options()

func _init_references() -> void:
	if not btn_main_menu: btn_main_menu = get_node_or_null("Margin/VBox/TopBar/LeftControls/BtnMainMenu")
	if not preview_viewport_container: preview_viewport_container = get_node_or_null("Margin/VBox/MainHBox/LeftColumn/PreviewCard/Margin/VBox/ViewportFrame/PreviewViewportContainer")
	if not preview_sub_viewport: preview_sub_viewport = get_node_or_null("Margin/VBox/MainHBox/LeftColumn/PreviewCard/Margin/VBox/ViewportFrame/PreviewViewportContainer/PreviewSubViewport")
	if not preview_char: preview_char = get_node_or_null("Margin/VBox/MainHBox/LeftColumn/PreviewCard/Margin/VBox/ViewportFrame/PreviewViewportContainer/PreviewSubViewport/PreviewChar")
	if not btn_prev_char: btn_prev_char = get_node_or_null("Margin/VBox/MainHBox/LeftColumn/PreviewCard/Margin/VBox/ViewportFrame/BtnPrevChar")
	if not btn_next_char: btn_next_char = get_node_or_null("Margin/VBox/MainHBox/LeftColumn/PreviewCard/Margin/VBox/ViewportFrame/BtnNextChar")
	if not char_name_label: char_name_label = get_node_or_null("Margin/VBox/MainHBox/LeftColumn/PreviewCard/Margin/VBox/DetailsPill/HBox/CharName")
	if not char_count_label: char_count_label = get_node_or_null("Margin/VBox/MainHBox/LeftColumn/PreviewCard/Margin/VBox/DetailsPill/HBox/CharCount")
	if not char_desc_label: char_desc_label = get_node_or_null("Margin/VBox/MainHBox/LeftColumn/PreviewCard/Margin/VBox/CharDesc")
	if not palette_container: palette_container = get_node_or_null("Margin/VBox/MainHBox/LeftColumn/PreviewCard/Margin/VBox/PaletteRow")
	if not palette_dots_container: palette_dots_container = get_node_or_null("Margin/VBox/MainHBox/LeftColumn/PreviewCard/Margin/VBox/DotsRow")

	if not player_name_input: player_name_input = get_node_or_null("Margin/VBox/MainHBox/RightColumn/LobbyCard/Margin/VBox/NameRow/NameInput")
	if not btn_tab_lobbies: btn_tab_lobbies = get_node_or_null("Margin/VBox/MainHBox/RightColumn/LobbyCard/Margin/VBox/TabsRow/BtnTabLobbies")
	if not btn_tab_create: btn_tab_create = get_node_or_null("Margin/VBox/MainHBox/RightColumn/LobbyCard/Margin/VBox/TabsRow/BtnTabCreate")
	if not btn_tab_hotspot: btn_tab_hotspot = get_node_or_null("Margin/VBox/MainHBox/RightColumn/LobbyCard/Margin/VBox/TabsRow/BtnTabHotspot")

	if not panel_hotspot: panel_hotspot = get_node_or_null("Margin/VBox/MainHBox/RightColumn/LobbyCard/Margin/VBox/ContentPanels/PanelHotspot")
	if not panel_lobbies: panel_lobbies = get_node_or_null("Margin/VBox/MainHBox/RightColumn/LobbyCard/Margin/VBox/ContentPanels/PanelLobbies")
	if not panel_create: panel_create = get_node_or_null("Margin/VBox/MainHBox/RightColumn/LobbyCard/Margin/VBox/ContentPanels/PanelCreate")

	if not hotspot_ip_input: hotspot_ip_input = get_node_or_null("Margin/VBox/MainHBox/RightColumn/LobbyCard/Margin/VBox/ContentPanels/PanelHotspot/IpRow/IpInput")
	if not btn_refresh_ip: btn_refresh_ip = get_node_or_null("Margin/VBox/MainHBox/RightColumn/LobbyCard/Margin/VBox/ContentPanels/PanelHotspot/IpRow/BtnRefreshIp")
	if not btn_hotspot_host: btn_hotspot_host = get_node_or_null("Margin/VBox/MainHBox/RightColumn/LobbyCard/Margin/VBox/ContentPanels/PanelHotspot/Actions/BtnHotspotHost")
	if not btn_hotspot_join: btn_hotspot_join = get_node_or_null("Margin/VBox/MainHBox/RightColumn/LobbyCard/Margin/VBox/ContentPanels/PanelHotspot/Actions/BtnHotspotJoin")
	if not btn_solo_practice: btn_solo_practice = get_node_or_null("Margin/VBox/MainHBox/RightColumn/LobbyCard/Margin/VBox/ContentPanels/PanelHotspot/Actions/BtnSoloPractice")
	if not local_ip_label: local_ip_label = get_node_or_null("Margin/VBox/MainHBox/RightColumn/LobbyCard/Margin/VBox/ContentPanels/PanelHotspot/Footer/LocalIpLabel")
	if not btn_copy_ip: btn_copy_ip = get_node_or_null("Margin/VBox/MainHBox/RightColumn/LobbyCard/Margin/VBox/ContentPanels/PanelHotspot/Footer/BtnCopyIp")

	if not code_input: code_input = get_node_or_null("Margin/VBox/MainHBox/RightColumn/LobbyCard/Margin/VBox/ContentPanels/PanelLobbies/CodeRow/CodeInput")
	if not btn_join_code: btn_join_code = get_node_or_null("Margin/VBox/MainHBox/RightColumn/LobbyCard/Margin/VBox/ContentPanels/PanelLobbies/CodeRow/BtnJoinCode")
	if not lobby_list_container: lobby_list_container = get_node_or_null("Margin/VBox/MainHBox/RightColumn/LobbyCard/Margin/VBox/ContentPanels/PanelLobbies/Scroll/LobbyListContainer")
	if not btn_refresh_lobbies: btn_refresh_lobbies = get_node_or_null("Margin/VBox/MainHBox/RightColumn/LobbyCard/Margin/VBox/ContentPanels/PanelLobbies/BtnRefreshLobbies")

	if not create_name_input: create_name_input = get_node_or_null("Margin/VBox/MainHBox/RightColumn/LobbyCard/Margin/VBox/ContentPanels/PanelCreate/NameRow/CreateNameInput")
	if not mode_option: mode_option = get_node_or_null("Margin/VBox/MainHBox/RightColumn/LobbyCard/Margin/VBox/ContentPanels/PanelCreate/ModeRow/ModeOption")
	if not duration_option: duration_option = get_node_or_null("Margin/VBox/MainHBox/RightColumn/LobbyCard/Margin/VBox/ContentPanels/PanelCreate/DurationRow/DurationOption")
	if not players_slider: players_slider = get_node_or_null("Margin/VBox/MainHBox/RightColumn/LobbyCard/Margin/VBox/ContentPanels/PanelCreate/PlayersRow/PlayersSlider")
	if not players_slider_val: players_slider_val = get_node_or_null("Margin/VBox/MainHBox/RightColumn/LobbyCard/Margin/VBox/ContentPanels/PanelCreate/PlayersRow/Val")
	if not btn_create_submit: btn_create_submit = get_node_or_null("Margin/VBox/MainHBox/RightColumn/LobbyCard/Margin/VBox/ContentPanels/PanelCreate/BtnCreateSubmit")

	if not panel_room_waiting: panel_room_waiting = get_node_or_null("Margin/VBox/MainHBox/RightColumn/LobbyCard/Margin/VBox/ContentPanels/PanelRoomWaiting")
	if not room_name_title: room_name_title = get_node_or_null("Margin/VBox/MainHBox/RightColumn/LobbyCard/Margin/VBox/ContentPanels/PanelRoomWaiting/RoomTitle")
	if not room_slots_container: room_slots_container = get_node_or_null("Margin/VBox/MainHBox/RightColumn/LobbyCard/Margin/VBox/ContentPanels/PanelRoomWaiting/SlotsContainer")
	if not btn_leave_room: btn_leave_room = get_node_or_null("Margin/VBox/MainHBox/RightColumn/LobbyCard/Margin/VBox/ContentPanels/PanelRoomWaiting/BtnLeaveRoom")

	if not info_tip_label: info_tip_label = get_node_or_null("Margin/VBox/BottomBar/TipHBox/TipLabel")
	if not btn_start_game: btn_start_game = get_node_or_null("Margin/VBox/BottomBar/BtnStartGame")

func _process(delta: float) -> void:
	if preview_char and is_instance_valid(preview_char):
		preview_char.rotate_y(delta * 0.65)
		preview_char.animate(delta, 0.0, true, 7.0)

var _signals_connected: bool = false

func _connect_internal_signals() -> void:
	if _signals_connected:
		return
	_signals_connected = true

	if btn_main_menu:
		btn_main_menu.pressed.connect(func(): main_menu_requested.emit())
	if btn_settings:
		btn_settings.pressed.connect(func(): settings_requested.emit())

	# Character Carousel
	if btn_prev_char:
		btn_prev_char.pressed.connect(func(): prev_char_requested.emit())
	if btn_next_char:
		btn_next_char.pressed.connect(func(): next_char_requested.emit())

	# Player Name
	if player_name_input:
		player_name_input.text_changed.connect(func(new_text: String):
			player_name_changed.emit(new_text.strip_edges())
		)

	# Tabs
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
			players_slider_val.text = "%d / 8" % int(v)
		)

	# Leave room
	if btn_leave_room:
		btn_leave_room.pressed.connect(func():
			set_room_waiting_state(false, false, "", {})
			leave_room_requested.emit()
			switch_tab(LobbyTab.HOTSPOT_SOLO)
		)

	# Primary Bottom CTA
	if btn_start_game:
		btn_start_game.pressed.connect(func(): start_game_requested.emit())

func _setup_options() -> void:
	if mode_option:
		mode_option.clear()
		mode_option.add_item("Pasa-Taya: Matira Matibay", 0)
		mode_option.add_item("Hawaan: Zombie Outbreak", 1)
		mode_option.add_item("Walang Bawian: Points Tag", 2)

	if duration_option:
		duration_option.clear()
		duration_option.add_item("30 Segundo (Mabilis)", 30)
		duration_option.add_item("45 Segundo (Standard)", 45)
		duration_option.add_item("60 Segundo (Mahaba)", 60)
		duration_option.select(1)

func switch_tab(tab: LobbyTab) -> void:
	current_tab = tab
	if panel_room_waiting and panel_room_waiting.visible:
		panel_room_waiting.visible = false

	if panel_lobbies: panel_lobbies.visible = (tab == LobbyTab.BROWSE)
	if panel_create: panel_create.visible = (tab == LobbyTab.CREATE)
	if panel_hotspot: panel_hotspot.visible = (tab == LobbyTab.HOTSPOT_SOLO)

	_style_tab_button(btn_tab_lobbies, tab == LobbyTab.BROWSE)
	_style_tab_button(btn_tab_create, tab == LobbyTab.CREATE)
	_style_tab_button(btn_tab_hotspot, tab == LobbyTab.HOTSPOT_SOLO)

	_update_bottom_cta()
	tab_changed.emit(int(tab))

func _style_tab_button(btn: Button, is_active: bool) -> void:
	if not btn:
		return
	if is_active:
		btn.add_theme_color_override("font_color", Color(0.08, 0.09, 0.12, 1.0))
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(0.92, 0.90, 0.86, 1.0)
		sb.set_corner_radius_all(14)
		sb.content_margin_left = 12
		sb.content_margin_right = 12
		sb.content_margin_top = 4
		sb.content_margin_bottom = 4
		btn.add_theme_stylebox_override("normal", sb)
		btn.add_theme_stylebox_override("hover", sb)
		btn.add_theme_stylebox_override("pressed", sb)
	else:
		btn.add_theme_color_override("font_color", Color(0.70, 0.72, 0.78, 1.0))
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(0, 0, 0, 0)
		sb.set_corner_radius_all(14)
		sb.content_margin_left = 12
		sb.content_margin_right = 12
		sb.content_margin_top = 4
		sb.content_margin_bottom = 4
		btn.add_theme_stylebox_override("normal", sb)
		btn.add_theme_stylebox_override("hover", sb)
		btn.add_theme_stylebox_override("pressed", sb)

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
	var mode_id: int = mode_option.get_selected_id() if mode_option else 0
	var dur_id: float = float(duration_option.get_selected_id()) if duration_option else 45.0
	var max_p: int = int(players_slider.value) if players_slider else 8
	create_room_submitted.emit(r_name, mode_id, dur_id, max_p)

# --- Public API methods called by GameManager ---

func set_player_name(pname: String) -> void:
	if player_name_input:
		player_name_input.text = pname

func get_player_name() -> String:
	if player_name_input:
		return player_name_input.text.strip_edges()
	return ""

func update_character_info(idx: int, char_name: String, char_desc: String) -> void:
	current_archetype_idx = idx
	if char_name_label:
		char_name_label.text = char_name + " ✎"
	if char_count_label:
		char_count_label.text = "%d / 8" % (idx + 1)
	if char_desc_label:
		char_desc_label.text = "👕 " + char_desc

func set_color_swatches(colors: Array[Dictionary], selected_color_idx: int) -> void:
	current_color_idx = selected_color_idx
	if not palette_container:
		return
	for c in palette_container.get_children():
		c.queue_free()

	for i in range(colors.size()):
		var c_info: Dictionary = colors[i]
		var col: Color = c_info.get("color", Color.WHITE)

		var swatch := Button.new()
		swatch.custom_minimum_size = Vector2(34, 34)
		var sb := StyleBoxFlat.new()
		sb.set_corner_radius_all(8)
		sb.bg_color = col
		if i == selected_color_idx:
			sb.border_color = Color(1.0, 0.9, 0.3, 1.0)
			sb.set_border_width_all(2)
		else:
			sb.border_color = Color(0.2, 0.22, 0.28, 0.6)
			sb.set_border_width_all(1)

		swatch.add_theme_stylebox_override("normal", sb)
		swatch.add_theme_stylebox_override("hover", sb)
		swatch.add_theme_stylebox_override("pressed", sb)

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
		dot.add_theme_font_size_override("font_size", 10)
		dot.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3, 1.0) if i == active_idx else Color(0.5, 0.52, 0.58, 0.8))
		palette_dots_container.add_child(dot)

func set_hotspot_ip(ip_str: String) -> void:
	if hotspot_ip_input:
		hotspot_ip_input.text = ip_str
	if local_ip_label:
		local_ip_label.text = "Local IP: %s (Port 7777)" % ip_str

func get_hotspot_target_ip() -> String:
	if hotspot_ip_input:
		return hotspot_ip_input.text.strip_edges()
	return ""

func set_room_waiting_state(in_room: bool, is_host: bool, room_name: String, players: Dictionary) -> void:
	is_in_room = in_room
	is_room_host = is_host

	if panel_room_waiting:
		panel_room_waiting.visible = in_room
	if panel_hotspot:
		panel_hotspot.visible = not in_room and (current_tab == LobbyTab.HOTSPOT_SOLO)
	if panel_lobbies:
		panel_lobbies.visible = not in_room and (current_tab == LobbyTab.BROWSE)
	if panel_create:
		panel_create.visible = not in_room and (current_tab == LobbyTab.CREATE)

	if in_room:
		if room_name_title:
			room_name_title.text = "KASALUKUYANG ROOM: " + room_name
		if room_slots_container:
			for c in room_slots_container.get_children():
				c.queue_free()

			var pids := players.keys()
			for i in range(8):
				var slot_lbl := Label.new()
				slot_lbl.add_theme_font_size_override("font_size", 12)
				if i < pids.size():
					var pid = pids[i]
					var pinfo: Dictionary = players[pid]
					var is_p_host := (i == 0)
					slot_lbl.text = "Slot %d: %s %s" % [i + 1, pinfo.get("name", "Player"), "[HOST]" if is_p_host else ""]
					slot_lbl.add_theme_color_override("font_color", Color(0.95, 0.98, 1.0))
				else:
					slot_lbl.text = "Slot %d: (Bakante)" % (i + 1)
					slot_lbl.add_theme_color_override("font_color", Color(0.45, 0.50, 0.58, 0.6))
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
		empty_lbl.add_theme_color_override("font_color", Color(0.65, 0.7, 0.75, 0.8))
		empty_lbl.add_theme_font_size_override("font_size", 12)
		lobby_list_container.add_child(empty_lbl)
		return

	for l_data in lobbies:
		var row := PanelContainer.new()
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(0.10, 0.12, 0.16, 0.85)
		sb.set_corner_radius_all(8)
		sb.set_border_width_all(1)
		sb.border_color = Color(0.2, 0.24, 0.3, 0.5)
		row.add_theme_stylebox_override("panel", sb)

		var margin := MarginContainer.new()
		margin.add_theme_constant_override("margin_left", 10)
		margin.add_theme_constant_override("margin_right", 10)
		margin.add_theme_constant_override("margin_top", 6)
		margin.add_theme_constant_override("margin_bottom", 6)
		row.add_child(margin)

		var hbox := HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 10)
		margin.add_child(hbox)

		var info_vbox := VBoxContainer.new()
		info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL

		var title := Label.new()
		title.text = str(l_data.get("name", "Tambayan"))
		title.add_theme_font_size_override("font_size", 13)
		title.add_theme_color_override("font_color", Color(0.95, 0.95, 0.98))
		info_vbox.add_child(title)

		var meta := Label.new()
		meta.text = "Host: %s • Mode: %s • %d/%d" % [
			l_data.get("host_name", "Host"),
			l_data.get("game_mode", "Pasa-Taya"),
			l_data.get("player_count", 1),
			l_data.get("max_players", 8)
		]
		meta.add_theme_font_size_override("font_size", 10)
		meta.add_theme_color_override("font_color", Color(0.65, 0.7, 0.78))
		info_vbox.add_child(meta)

		hbox.add_child(info_vbox)

		var btn_join := Button.new()
		btn_join.text = "SUMALI >"
		btn_join.add_theme_font_size_override("font_size", 11)
		var bsb := StyleBoxFlat.new()
		bsb.bg_color = Color(0.92, 0.9, 0.85)
		bsb.set_corner_radius_all(6)
		bsb.content_margin_left = 10
		bsb.content_margin_right = 10
		bsb.content_margin_top = 4
		bsb.content_margin_bottom = 4
		btn_join.add_theme_stylebox_override("normal", bsb)
		btn_join.add_theme_color_override("font_color", Color(0.08, 0.09, 0.12))

		var cur_data := l_data
		btn_join.pressed.connect(func(): join_lobby_requested.emit(cur_data))
		hbox.add_child(btn_join)

		lobby_list_container.add_child(row)
