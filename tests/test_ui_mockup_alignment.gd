class_name TestUiMockupAlignment
extends SceneTree

var total_passed: int = 0
var total_failed: int = 0

func _init() -> void:
	print("==================================================")
	print("  TEST: UI Mockup Alignment Verification")
	print("==================================================")
	call_deferred("_run_tests")

func _check(cond: bool, test_name: String) -> void:
	if cond:
		print("[PASS] %s" % test_name)
		total_passed += 1
	else:
		printerr("[FAIL] %s" % test_name)
		total_failed += 1

func _run_tests() -> void:
	# ------------------------------------------------------------------
	# TEST 1: HUD.tscn & HUD.gd
	# ------------------------------------------------------------------
	print("\n--- Testing In-Game HUD (Mockup 1 & 3) ---")
	var hud_scene: PackedScene = load("res://scenes/ui/HUD.tscn")
	_check(hud_scene != null, "HUD.tscn scene file loads")

	if hud_scene:
		var hud: HUD = hud_scene.instantiate() as HUD
		_check(hud != null, "HUD instantiates successfully")
		root.add_child(hud)

		# Top Left Cluster
		var round_lbl = hud.round_label
		_check(round_lbl != null and round_lbl.text.begins_with("ROUND"), "HUD RoundLabel exists and displays Round info")

		var player_deck = hud.player_deck
		_check(player_deck != null, "HUD PlayerDeck card exists")

		var burst_bar = hud.burst_bar
		_check(burst_bar != null, "HUD HatawBar (Burst Stamina) exists")
		var endur_bar = hud.endurance_bar
		_check(endur_bar != null, "HUD HanginBar (Endurance Stamina) exists")

		var item_card = hud.get_node_or_null("TopLeftCluster/DeckAndItemRow/ItemSlotCard")
		_check(item_card != null, "HUD ItemSlotCard exists")

		var item_icon = hud.top_item_icon
		_check(item_icon != null and item_icon.texture != null and item_icon.texture.resource_path.ends_with("Props_lata.png"), "HUD ItemSlotCard displays Props_lata.png texture")

		# Top Right Controls
		var barya_cnt = hud.get_node_or_null("TopRightControls/BaryaContainer")
		_check(barya_cnt != null, "HUD BaryaContainer pill exists")
		var barya_icon = hud.get_node_or_null("TopRightControls/BaryaContainer/Margin/HBox/BaryaIcon") as TextureRect
		_check(barya_icon != null and barya_icon.texture != null and barya_icon.texture.resource_path.ends_with("Barya.png"), "HUD BaryaContainer uses Barya.png icon")

		var timer_cnt = hud.get_node_or_null("TopRightControls/TimerContainer")
		_check(timer_cnt != null, "HUD TimerContainer pill exists")
		var timer_icon = hud.get_node_or_null("TopRightControls/TimerContainer/Margin/HBox/ClockIcon") as TextureRect
		_check(timer_icon != null and timer_icon.texture != null and timer_icon.texture.resource_path.ends_with("Clock.png"), "HUD TimerContainer uses Clock.png icon")

		var btn_pause = hud.btn_hud_pause as TextureButton
		_check(btn_pause != null and btn_pause.texture_normal != null and btn_pause.texture_normal.resource_path.ends_with("Pause.png"), "HUD Pause button uses Pause.png texture")

		# Notification Banner (Mockup 3)
		var paper_banner: Control = hud.paper_notification_banner
		var paper_bg: TextureRect = hud.paper_notification_bg
		_check(paper_banner != null, "HUD PaperNotificationBanner exists")
		_check(paper_bg != null and paper_bg.texture != null and paper_bg.texture.resource_path.ends_with("Game_Notification_Banner.png"), "HUD PaperNotificationBanner uses Game_Notification_Banner.png")

		hud.show_paper_notification("TOTOY NAKATAYA!", 2.0)
		_check(paper_banner.visible == true, "show_paper_notification() makes banner visible")
		var banner_label = hud.paper_notification_label
		_check(banner_label != null and banner_label.text == "TOTOY NAKATAYA!", "show_paper_notification() sets banner text correctly")

		# Decluttering & Overlap Checks
		var scoreboard = hud.scoreboard_panel
		_check(scoreboard != null and scoreboard.visible == false, "ScoreboardPanel is hidden by default")
		_check(scoreboard != null and scoreboard.anchors_preset == Control.PRESET_CENTER, "ScoreboardPanel is centered (preset 8), eliminating top-right overlap")
		hud.toggle_scoreboard(true)
		_check(scoreboard.visible == true, "toggle_scoreboard(true) reveals scoreboard")
		hud.toggle_scoreboard(false)
		_check(scoreboard.visible == false, "toggle_scoreboard(false) conceals scoreboard")

		var flood_cnt = hud.flood_container
		_check(flood_cnt != null and flood_cnt.visible == false, "FloodMeterContainer is hidden by default at 0% water")
		hud.update_flood_meter(60.0, false)
		_check(flood_cnt.visible == true, "update_flood_meter(60) reveals flood warning")
		hud.update_flood_meter(0.0, false)
		_check(flood_cnt.visible == false, "update_flood_meter(0) conceals flood indicator for clean top bar")

		var cross = hud.crosshair
		_check(cross != null and cross.visible == false, "Crosshair is hidden by default during normal running")
		hud.on_street_item_changed(0, "TSINELAS", 1)
		_check(cross.visible == true, "Holding throwable item (Tsinelas) enables aiming crosshair")
		hud.on_street_item_changed(-1, "", 0)
		_check(cross.visible == false, "Dropping throwable item hides aiming crosshair")

		var bottom_bar = hud.get_node_or_null("BottomBar")
		_check(bottom_bar != null and bottom_bar.visible == false, "BottomBar duplicate item slots are hidden")

		var burst_val = hud.burst_val_label
		var endur_val = hud.endurance_val_label
		_check(burst_val != null and not burst_val.text.contains("BTC"), "BurstValue does not contain BTC placeholder")
		_check(endur_val != null and not endur_val.text.contains("BTC"), "EnduranceValue does not contain BTC placeholder")

		hud.queue_free()

	# ------------------------------------------------------------------
	# TEST 2: MobileControlsUI.tscn & MobileControls.gd
	# ------------------------------------------------------------------
	print("\n--- Testing Mobile Controls Dynamic Arc & Corner Action (Mockup 1) ---")
	var mobile_scene: PackedScene = load("res://scenes/ui/MobileControlsUI.tscn")
	_check(mobile_scene != null, "MobileControlsUI.tscn scene file loads")

	if mobile_scene:
		var mobile = mobile_scene.instantiate() as MobileControls
		_check(mobile != null, "MobileControlsUI instantiates successfully")
		root.add_child(mobile)

		var btn_tag: TextureButton = mobile.btn_tag as TextureButton
		_check(btn_tag != null, "BtnTag primary action button exists")
		if btn_tag:
			_check(btn_tag.size.x >= 104 and btn_tag.size.y >= 104, "BtnTag is sized >= 104x104 (120x120) for prominent corner action")
			_check(btn_tag.anchor_left == 1.0 and btn_tag.anchor_top == 1.0, "BtnTag is anchored to bottom-right corner")

		var btn_jump: TextureButton = mobile.btn_jump as TextureButton
		var btn_sprint: TextureButton = mobile.btn_sprint as TextureButton
		var btn_dash: TextureButton = mobile.btn_dash as TextureButton
		var btn_slide: TextureButton = mobile.btn_slide as TextureButton

		_check(btn_jump != null and btn_sprint != null and btn_dash != null and btn_slide != null, "Arc movement buttons (Jump, Sprint, Dash, Slide) all exist")

		# Dynamic context mode testing
		mobile.set_tag_button_highlight(true)
		_check(btn_tag.texture_normal == mobile.tex_tag, "set_tag_button_highlight(true) sets primary button to Hampas/Tag texture")

		mobile.set_tag_button_highlight(false)
		mobile.set_item_button_visible(true, "LATA")
		_check(btn_tag.texture_normal == mobile.tex_tapon, "set_item_button_visible(true) sets primary button to Tapon/Throw texture")

		mobile.set_item_button_visible(false)
		mobile.set_interact_prompt(true, "E", "Pulot")
		_check(btn_tag.texture_normal == mobile.tex_pulot, "set_interact_prompt(true) sets primary button to Pulot/Pickup texture")

		# Virtual Joystick Textures & Behavior (Joystick UI Upgrade)
		var v_joy: KalyeVirtualJoystick = mobile.joystick as KalyeVirtualJoystick
		_check(v_joy != null, "KalyeVirtualJoystick exists on MobileControlsUI")
		if v_joy:
			_check(v_joy.texture_boundary != null and v_joy.texture_boundary.resource_path.ends_with("JoystickBoundery.png"), "VirtualJoystick uses JoystickBoundery.png texture")
			_check(v_joy.texture_knob != null and v_joy.texture_knob.resource_path.ends_with("joystickCenter.png"), "VirtualJoystick uses joystickCenter.png texture")
			_check(v_joy.boundary_size == Vector2(200, 200), "VirtualJoystick boundary size is 200x200 px")
			_check(v_joy.knob_size == Vector2(110, 110), "VirtualJoystick knob size is 110x110 px")
			_check(v_joy.max_range == 75.0, "VirtualJoystick travel max range is 75.0 px")
			_check(v_joy.idle_opacity == 0.50, "VirtualJoystick idle opacity is 50%")
			_check(v_joy.active_opacity == 1.0, "VirtualJoystick active opacity is 100%")
			_check(v_joy.is_active == false, "VirtualJoystick is initially idle (is_active == false)")

			# Test touch engagement and deflection
			v_joy._start_touch(Vector2(120, 200))
			_check(v_joy.is_active == true, "Touching joystick sets is_active to true")
			_check(v_joy.center_pos == Vector2(120, 200), "Dynamic joystick recenters base to touch position")

			v_joy._update_knob_position(Vector2(120, 275))
			var vec = v_joy.get_vector()
			_check(is_equal_approx(vec.x, 0.0) and is_equal_approx(vec.y, 1.0), "Deflecting down produces normalized (0, 1) vector")

			v_joy._reset_joystick()
			_check(v_joy.is_active == false, "Releasing joystick resets is_active to false")
			_check(v_joy.get_vector() == Vector2.ZERO, "Releasing joystick returns output vector to ZERO")

		mobile.queue_free()

	# ------------------------------------------------------------------
	# TEST 3: SocialLobbyUI.tscn & SocialLobbyUI.gd (3D Social Lobby Header)
	# ------------------------------------------------------------------
	print("\n--- Testing 3D Social Lobby Top Bar Alignment ---")
	var social_scene: PackedScene = load("res://scenes/ui/SocialLobbyUI.tscn")
	_check(social_scene != null, "SocialLobbyUI.tscn scene file loads")

	if social_scene:
		var social: SocialLobbyUI = social_scene.instantiate() as SocialLobbyUI
		_check(social != null, "SocialLobbyUI instantiates successfully")
		root.add_child(social)

		var top_bar = social.get_node_or_null("TopBar") as PanelContainer
		_check(top_bar != null, "SocialLobbyUI TopBar panel container exists")

		var top_bar_style = top_bar.get_theme_stylebox("panel") if top_bar else null
		_check(top_bar_style != null and top_bar_style is StyleBoxFlat, "SocialLobbyUI TopBar uses dark blue StyleBoxFlat")

		_check(social.btn_leave != null, "SocialLobbyUI Leave/Back button exists")
		_check(social.player_count_label != null, "SocialLobbyUI PlayerCountLabel exists")
		_check(social.room_title_label != null, "SocialLobbyUI Room Title label exists")
		_check(social.room_ip_label != null, "SocialLobbyUI Room IP label exists")
		_check(social.btn_emotes != null, "SocialLobbyUI BtnEmotes exists")
		_check(social.btn_settings != null, "SocialLobbyUI BtnSettings exists")

		# Test update_lobby_info
		social.update_lobby_info("STA. CRUZ", "0.00.0", 2, 5, false)
		_check(social.player_count_label.text == "2/5", "update_lobby_info updates player count to 2/5")
		_check(social.room_title_label.text == "BRGY. STA. CRUZ", "update_lobby_info formats room title to BRGY. STA. CRUZ")
		_check(social.room_ip_label.text == "0.00.0", "update_lobby_info updates room ip/code to 0.00.0")

		# Emotes toggling check
		var emotes_bar = social.emotes_bar
		_check(emotes_bar != null and emotes_bar.visible == false, "EmotesBar starts hidden")
		social._toggle_emotes()
		_check(emotes_bar != null and emotes_bar.visible == true, "_toggle_emotes() reveals EmotesBar")
		social._toggle_emotes()
		_check(emotes_bar != null and emotes_bar.visible == false, "_toggle_emotes() toggles EmotesBar off")

		social.queue_free()

	# ------------------------------------------------------------------
	# TEST 4: LobbyUI.tscn & LobbyUI.gd (2D Tara Hub Clean Top Bar)
	# ------------------------------------------------------------------
	print("\n--- Testing 2D Tara Hub Clean Top Bar ---")
	var lobby_scene: PackedScene = load("res://scenes/ui/LobbyUI.tscn")
	_check(lobby_scene != null, "LobbyUI.tscn scene file loads")

	if lobby_scene:
		var lobby: LobbyUI = lobby_scene.instantiate() as LobbyUI
		_check(lobby != null, "LobbyUI instantiates successfully")
		root.add_child(lobby)

		_check(lobby.btn_back != null, "LobbyUI Back button exists")
		_check(lobby.btn_guide != null, "LobbyUI Guide button exists")

		var top_panel = lobby.top_bar_panel
		var top_style = top_panel.get_theme_stylebox("panel") if top_panel else null
		_check(top_style is StyleBoxEmpty or top_style == null, "LobbyUI TopBar has NO dark blue backdrop panel (transparent/empty)")

		# Ensure in-game player count and emotes buttons are not cluttering 2D Tara Hub
		_check(lobby.player_count_label == null, "LobbyUI has no PlayerCountLabel in 2D Tara Hub")
		_check(lobby.btn_emotes == null, "LobbyUI has no BtnEmotes in 2D Tara Hub")

		lobby.queue_free()

	print("\n==================================================")
	print("UI MOCKUP ALIGNMENT RESULTS: %d Passed, %d Failed" % [total_passed, total_failed])
	print("==================================================")

	if total_failed == 0:
		quit(0)
	else:
		quit(1)
