class_name HUD
extends Control

# Top Bar (Tournament Pill Header & Controls)
@onready var timer_label: Label = (get_node_or_null("TopRightControls/TimerContainer/Margin/HBox/TimerLabel") as Label) if get_node_or_null("TopRightControls/TimerContainer/Margin/HBox/TimerLabel") else (get_node_or_null("TopBar/TimerContainer/TimerLabel") as Label)
@onready var btn_hud_pause: BaseButton = (get_node_or_null("TopRightControls/BtnHudPause") as BaseButton) if get_node_or_null("TopRightControls/BtnHudPause") else (get_node_or_null("TopBar/BtnHudPause") as BaseButton)
@onready var round_label: Label = (get_node_or_null("TopLeftCluster/RoundLabel") as Label) if get_node_or_null("TopLeftCluster/RoundLabel") else (get_node_or_null("TopBar/RoundContainer/Margin/RoundLabel") as Label)
@onready var alive_label: Label = (get_node_or_null("TopBar/AliveContainer/Margin/AliveLabel") as Label)
@onready var barya_label: Label = (get_node_or_null("TopRightControls/BaryaContainer/Margin/HBox/BaryaLabel") as Label) if get_node_or_null("TopRightControls/BaryaContainer/Margin/HBox/BaryaLabel") else (get_node_or_null("TopBar/BaryaContainer/Margin/HBox/BaryaLabel") as Label)

# Player Status Deck (Top-Left Dashboard Card)
@onready var player_deck: PanelContainer = (get_node_or_null("TopLeftCluster/DeckAndItemRow/PlayerDeck") as PanelContainer) if get_node_or_null("TopLeftCluster/DeckAndItemRow/PlayerDeck") else (get_node_or_null("PlayerDeck") as PanelContainer)
@onready var role_badge: Label = (get_node_or_null("TopLeftCluster/DeckAndItemRow/PlayerDeck/Margin/VBox/RoleRow/RoleBadge") as Label) if get_node_or_null("TopLeftCluster/DeckAndItemRow/PlayerDeck/Margin/VBox/RoleRow/RoleBadge") else ((get_node_or_null("PlayerDeck/Margin/VBox/RoleRow/RoleBadge") as Label) if get_node_or_null("PlayerDeck/Margin/VBox/RoleRow/RoleBadge") else (get_node_or_null("SideBar/RolePanel/Margin/HBox/RoleBadge") as Label))
@onready var score_label: Label = (get_node_or_null("TopLeftCluster/DeckAndItemRow/PlayerDeck/Margin/VBox/RoleRow/ScoreLabel") as Label) if get_node_or_null("TopLeftCluster/DeckAndItemRow/PlayerDeck/Margin/VBox/RoleRow/ScoreLabel") else ((get_node_or_null("PlayerDeck/Margin/VBox/RoleRow/ScoreLabel") as Label) if get_node_or_null("PlayerDeck/Margin/VBox/RoleRow/ScoreLabel") else (get_node_or_null("SideBar/RolePanel/Margin/HBox/ScoreLabel") as Label))
@onready var role_panel: PanelContainer = player_deck

# Stamina Display
@onready var stamina_panel: PanelContainer = player_deck
@onready var burst_bar: ProgressBar = (get_node_or_null("TopLeftCluster/DeckAndItemRow/PlayerDeck/Margin/VBox/BurstRow/BurstBar") as ProgressBar) if get_node_or_null("TopLeftCluster/DeckAndItemRow/PlayerDeck/Margin/VBox/BurstRow/BurstBar") else ((get_node_or_null("PlayerDeck/Margin/VBox/BurstBar") as ProgressBar) if get_node_or_null("PlayerDeck/Margin/VBox/BurstBar") else (get_node_or_null("StaminaPanel/Margin/VBox/BurstBar") as ProgressBar))
@onready var burst_val_label: Label = (get_node_or_null("TopLeftCluster/DeckAndItemRow/PlayerDeck/Margin/VBox/BurstRow/BurstValue") as Label) if get_node_or_null("TopLeftCluster/DeckAndItemRow/PlayerDeck/Margin/VBox/BurstRow/BurstValue") else ((get_node_or_null("PlayerDeck/Margin/VBox/BurstHeader/BurstValue") as Label) if get_node_or_null("PlayerDeck/Margin/VBox/BurstHeader/BurstValue") else (get_node_or_null("StaminaPanel/Margin/VBox/BurstHeader/BurstValue") as Label))
@onready var endurance_bar: ProgressBar = (get_node_or_null("TopLeftCluster/DeckAndItemRow/PlayerDeck/Margin/VBox/EnduranceRow/EnduranceBar") as ProgressBar) if get_node_or_null("TopLeftCluster/DeckAndItemRow/PlayerDeck/Margin/VBox/EnduranceRow/EnduranceBar") else ((get_node_or_null("PlayerDeck/Margin/VBox/EnduranceBar") as ProgressBar) if get_node_or_null("PlayerDeck/Margin/VBox/EnduranceBar") else (get_node_or_null("StaminaPanel/Margin/VBox/EnduranceBar") as ProgressBar))
@onready var endurance_val_label: Label = (get_node_or_null("TopLeftCluster/DeckAndItemRow/PlayerDeck/Margin/VBox/EnduranceRow/EnduranceValue") as Label) if get_node_or_null("TopLeftCluster/DeckAndItemRow/PlayerDeck/Margin/VBox/EnduranceRow/EnduranceValue") else ((get_node_or_null("PlayerDeck/Margin/VBox/EnduranceHeader/EnduranceValue") as Label) if get_node_or_null("PlayerDeck/Margin/VBox/EnduranceHeader/EnduranceValue") else (get_node_or_null("StaminaPanel/Margin/VBox/EnduranceHeader/EnduranceValue") as Label))
@onready var exhausted_warning: Label = (get_node_or_null("TopLeftCluster/DeckAndItemRow/PlayerDeck/Margin/VBox/ExhaustedWarning") as Label) if get_node_or_null("TopLeftCluster/DeckAndItemRow/PlayerDeck/Margin/VBox/ExhaustedWarning") else ((get_node_or_null("PlayerDeck/Margin/VBox/ExhaustedWarning") as Label) if get_node_or_null("PlayerDeck/Margin/VBox/ExhaustedWarning") else (get_node_or_null("StaminaPanel/Margin/VBox/ExhaustedWarning") as Label))

# Top-Left Item Slot
@onready var top_item_icon: TextureRect = get_node_or_null("TopLeftCluster/DeckAndItemRow/ItemSlotCard/Margin/VBox/ItemIcon")
@onready var top_item_name: Label = get_node_or_null("TopLeftCluster/DeckAndItemRow/ItemSlotCard/Margin/VBox/ItemName")

# Center Reticle Crosshair (Crab Game / Karlson style)
@onready var flood_container: Control = get_node_or_null("TopRightControls/FloodMeterContainer") if get_node_or_null("TopRightControls/FloodMeterContainer") else get_node_or_null("TopBar/FloodMeterContainer")
@onready var flood_label: Label = get_node_or_null("%FloodLabel") if has_node("%FloodLabel") else (get_node_or_null("TopRightControls/FloodMeterContainer/Margin/FloodLabel") as Label if get_node_or_null("TopRightControls/FloodMeterContainer/Margin/FloodLabel") else get_node_or_null("TopBar/FloodMeterContainer/Margin/FloodLabel") as Label)
@onready var crosshair: Control = get_node_or_null("Crosshair")
@onready var crosshair_dot: ColorRect = get_node_or_null("Crosshair/Dot")
@onready var crosshair_ticks: Array[ColorRect] = [
	get_node_or_null("Crosshair/TickTop") as ColorRect,
	get_node_or_null("Crosshair/TickBottom") as ColorRect,
	get_node_or_null("Crosshair/TickLeft") as ColorRect,
	get_node_or_null("Crosshair/TickRight") as ColorRect
]

# Scoreboard
@onready var scoreboard_panel: PanelContainer = get_node_or_null("ScoreboardPanel")
@onready var player_list_box: VBoxContainer = (get_node_or_null("ScoreboardPanel/MarginContainer/VBoxContainer/ScoreboardScroll/PlayerList") as VBoxContainer) if get_node_or_null("ScoreboardPanel/MarginContainer/VBoxContainer/ScoreboardScroll/PlayerList") else (get_node_or_null("ScoreboardPanel/MarginContainer/VBoxContainer/PlayerList") as VBoxContainer)

# Contextual Interaction Prompt
@onready var contextual_prompt: PanelContainer = get_node_or_null("ContextualPrompt")
@onready var prompt_icon_label: Label = get_node_or_null("ContextualPrompt/Margin/HBox/PromptIcon")
@onready var prompt_action_label: Label = get_node_or_null("ContextualPrompt/Margin/HBox/PromptAction")

# Bottom Inventory & Powerup Cards
@onready var inventory_slot: PanelContainer = get_node_or_null("BottomBar/InventorySlot")
@onready var trash_icon_label: Label = get_node_or_null("BottomBar/InventorySlot/Margin/VBox/TrashIcon")
@onready var trash_type_label: Label = get_node_or_null("BottomBar/InventorySlot/Margin/VBox/TrashType")
@onready var drop_hint_label: Label = get_node_or_null("BottomBar/InventorySlot/Margin/VBox/DropHint")

# Street Items Slot & Hiding Panel
@onready var street_item_slot: PanelContainer = get_node_or_null("BottomBar/StreetItemSlot")
@onready var street_item_icon: Label = get_node_or_null("BottomBar/StreetItemSlot/Margin/VBox/ItemIcon")
@onready var street_item_name: Label = get_node_or_null("BottomBar/StreetItemSlot/Margin/VBox/ItemName")
@onready var street_item_hint: Label = get_node_or_null("BottomBar/StreetItemSlot/Margin/VBox/ItemHint")

@onready var hiding_panel: PanelContainer = get_node_or_null("HidingPanel")
@onready var hiding_timer_bar: ProgressBar = get_node_or_null("HidingPanel/Margin/VBox/HidingTimerBar")
@onready var hiding_label: Label = get_node_or_null("HidingPanel/Margin/VBox/HidingLabel")

@onready var powerup_panel: PanelContainer = get_node_or_null("BottomBar/PowerupSlot")
@onready var powerup_icon_label: Label = get_node_or_null("BottomBar/PowerupSlot/Margin/VBox/PowerupIcon")
@onready var powerup_label: Label = get_node_or_null("BottomBar/PowerupSlot/Margin/VBox/PowerupLabel")

# Danger Sensor
@onready var danger_overlay: Control = get_node_or_null("DangerOverlay")
@onready var danger_label: Label = get_node_or_null("DangerOverlay/DangerPill/Label")

# Announcements
@onready var toast_panel: Control = get_node_or_null("ToastPanel")
@onready var toast_label: Label = get_node_or_null("ToastPanel/MarginContainer/ToastLabel")

@onready var tag_banner: Control = get_node_or_null("TagBanner")
@onready var tag_banner_bg: TextureRect = get_node_or_null("TagBanner/BannerBg")
@onready var tag_banner_label: Label = get_node_or_null("TagBanner/MarginContainer/Label")
@onready var paper_notification_banner: Control = tag_banner
@onready var paper_notification_bg: TextureRect = tag_banner_bg
@onready var paper_notification_label: Label = tag_banner_label

# Tournament & Spectator Nodes
@onready var critical_vignette: ColorRect = get_node_or_null("CriticalVignette")
@onready var speed_lines: ColorRect = get_node_or_null("SpeedLines")
@onready var hit_flash: ColorRect = get_node_or_null("HitFlash")
@onready var spectator_bar: PanelContainer = get_node_or_null("SpectatorBar")
@onready var spectator_label: Label = get_node_or_null("SpectatorBar/Margin/SpectatorLabel")
@onready var intermission_banner: PanelContainer = get_node_or_null("IntermissionBanner")
@onready var intermission_title: Label = get_node_or_null("IntermissionBanner/Margin/VBox/Title")
@onready var intermission_sub: Label = get_node_or_null("IntermissionBanner/Margin/VBox/Sub")

var banner_tween: Tween
var toast_tween: Tween
var prompt_tween: Tween
var inv_tween: Tween
var hit_flash_tween: Tween
var score_pulse_tween: Tween
var timer_pulse_tween: Tween
var stamina_warning_tween: Tween
var crosshair_tween: Tween
var deck_pulse_tween: Tween

var deck_style_runner: StyleBox
var deck_style_taya: StyleBox

var is_taya_local: bool = false
var prev_tags: int = -1
var prev_countdown_sec: int = -1
var prev_alive_count: int = -1

func _ready() -> void:
	_init_deck_styles()

	if btn_hud_pause:
		_apply_button_squash(btn_hud_pause)
		btn_hud_pause.pressed.connect(func():
			var main_node = get_node_or_null("/root/Main")
			if main_node and main_node.has_method("toggle_pause"):
				main_node.toggle_pause()
		)

	var gm = get_node_or_null("/root/Main")
	if gm and "economy_manager" in gm and gm.economy_manager:
		update_barya(gm.economy_manager.barya_balance)
		if gm.economy_manager.has_signal("balance_changed"):
			gm.economy_manager.balance_changed.connect(func(nb, _nr): update_barya(nb))
	if contextual_prompt:
		contextual_prompt.visible = false
	if danger_overlay:
		danger_overlay.visible = false
	if powerup_panel:
		powerup_panel.visible = false
	if critical_vignette:
		critical_vignette.visible = false
	if hit_flash:
		hit_flash.visible = false
	if spectator_bar:
		spectator_bar.visible = false
	if intermission_banner:
		intermission_banner.visible = false
	if scoreboard_panel:
		scoreboard_panel.visible = false
	if flood_container:
		flood_container.visible = false
	if crosshair:
		crosshair.visible = false
	var bottom_bar = get_node_or_null("BottomBar")
	if bottom_bar:
		bottom_bar.visible = false

func _apply_button_squash(btn: BaseButton) -> void:
	if not btn:
		return
	btn.pivot_offset = btn.size * 0.5
	btn.button_down.connect(func():
		var t := create_tween()
		t.tween_property(btn, "scale", Vector2(0.92, 0.92), 0.06).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	)
	btn.button_up.connect(func():
		var t := create_tween()
		t.tween_property(btn, "scale", Vector2.ONE, 0.16).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	)

	update_speed_lines(0.0)
	_update_inventory_display(-1)
	_set_crosshair_throwable_mode(false)

func _init_deck_styles() -> void:
	deck_style_runner = KalyeStyle.surface_style(KalyeStyle.Surface.HUD)
	deck_style_taya = KalyeStyle.box(Color(0.28, 0.06, 0.10, 0.90), Color(0.14, 0.02, 0.05, 0.94), 14, 2, 3, 0.12, 2)
	deck_style_taya.ink = KalyeStyle.RED
	deck_style_taya.content_margin_left = 12.0
	deck_style_taya.content_margin_right = 12.0
	deck_style_taya.content_margin_top = 6.0
	deck_style_taya.content_margin_bottom = 7.0

func update_speed_lines(intensity: float) -> void:
	if speed_lines and speed_lines.material:
		speed_lines.material.set_shader_parameter("speed_intensity", clampf(intensity, 0.0, 1.0))

func trigger_hit_flash(color: Color = Color(1, 1, 1, 0.65), duration: float = 0.2) -> void:
	if not hit_flash:
		return
	hit_flash.visible = true
	hit_flash.color = color
	if hit_flash_tween and hit_flash_tween.is_valid():
		hit_flash_tween.kill()
	hit_flash_tween = create_tween()
	hit_flash_tween.tween_property(hit_flash, "color:a", 0.0, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	hit_flash_tween.tween_callback(func(): hit_flash.visible = false)

	# Snappy reticle bloom on tag impact
	if crosshair:
		crosshair.scale = Vector2(1.5, 1.5)
		if crosshair_tween and crosshair_tween.is_valid():
			crosshair_tween.kill()
		crosshair_tween = create_tween()
		crosshair_tween.tween_property(crosshair, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)

var held_street_item_local: int = -1

func _set_crosshair_throwable_mode(active: bool) -> void:
	if crosshair:
		crosshair.visible = active
	for tick in crosshair_ticks:
		if is_instance_valid(tick):
			tick.visible = active
	if crosshair_dot:
		crosshair_dot.color = Color(1.0, 0.9, 0.3, 0.95) if active else Color(1.0, 1.0, 1.0, 0.85)
	if crosshair and active:
		var target_scale := Vector2(1.2, 1.2)
		var t := create_tween()
		t.tween_property(crosshair, "scale", target_scale, 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func set_aiming_mode(active: bool, is_locked: bool = false) -> void:
	if not crosshair:
		return
	if active:
		crosshair.visible = true
		for tick in crosshair_ticks:
			if is_instance_valid(tick):
				tick.visible = true
				tick.color = Color(1.0, 0.35, 0.25, 0.95) if is_locked else Color(1.0, 0.92, 0.35, 0.95)
		if crosshair_dot:
			crosshair_dot.color = Color(1.0, 0.35, 0.25, 1.0) if is_locked else Color(1.0, 0.95, 0.4, 1.0)
		var target_scale := Vector2(1.38, 1.38) if is_locked else Vector2(1.25, 1.25)
		var t := create_tween()
		t.tween_property(crosshair, "scale", target_scale, 0.08).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	else:
		_set_crosshair_throwable_mode(held_street_item_local == 0 or held_street_item_local == 3)

func update_role_display(is_taya: bool, is_eliminated: bool = false) -> void:
	if is_eliminated:
		is_taya_local = false
		if player_deck:
			player_deck.add_theme_stylebox_override("panel", deck_style_runner)
		if role_badge:
			role_badge.text = "NANONOOD"
			role_badge.modulate = Color(0.7, 0.75, 0.85)
		return

	var role_changed := (is_taya != is_taya_local)
	is_taya_local = is_taya

	if player_deck:
		player_deck.add_theme_stylebox_override("panel", deck_style_taya if is_taya else deck_style_runner)
		if role_changed:
			if deck_pulse_tween and deck_pulse_tween.is_valid():
				deck_pulse_tween.kill()
			deck_pulse_tween = create_tween()
			deck_pulse_tween.tween_property(player_deck, "scale", Vector2(1.08, 1.08), 0.1).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			deck_pulse_tween.tween_property(player_deck, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)

	if role_badge:
		role_badge.pivot_offset = role_badge.size * 0.5
		if role_changed:
			var t := create_tween()
			t.tween_property(role_badge, "scale", Vector2(1.3, 1.3), 0.08).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			t.tween_property(role_badge, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)

		if is_taya:
			var is_infected_mode := false
			var main_node = get_node_or_null("/root/Main")
			if main_node and main_node.has_method("is_infection"):
				is_infected_mode = main_node.is_infection()
			if is_infected_mode:
				role_badge.text = "☣ HAWA"
				role_badge.modulate = Color(0.45, 1.0, 0.25)
			else:
				role_badge.text = "TAYA"
				role_badge.modulate = Color(1.0, 0.2, 0.35)
		else:
			role_badge.text = "LIGTAS"
			role_badge.modulate = Color(0.2, 0.95, 0.5)

func on_tag_cooldown_started(duration: float, is_hit: bool) -> void:
	if not crosshair:
		return
	if crosshair_tween and crosshair_tween.is_valid():
		crosshair_tween.kill()
	crosshair_tween = create_tween().set_parallel(true)
	if is_hit:
		crosshair.scale = Vector2(1.45, 1.45)
		crosshair_tween.tween_property(crosshair, "scale", Vector2.ONE, maxf(0.18, duration)).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
		if crosshair_dot:
			crosshair_dot.color = Color(0.25, 1.0, 0.5, 1.0)
			crosshair_tween.tween_property(crosshair_dot, "color", Color(1.0, 1.0, 1.0, 0.85), maxf(0.2, duration))
	else:
		# Missed tag (whiff): contract reticle briefly and recover over cooldown duration
		crosshair.scale = Vector2(0.68, 0.68)
		crosshair_tween.tween_property(crosshair, "scale", Vector2.ONE, maxf(0.15, duration)).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		if crosshair_dot:
			crosshair_dot.color = Color(0.95, 0.55, 0.25, 0.75)
			crosshair_tween.tween_property(crosshair_dot, "color", Color(1.0, 1.0, 1.0, 0.85), maxf(0.15, duration))
		for tick in crosshair_ticks:
			if is_instance_valid(tick):
				tick.visible = true
				tick.color = Color(0.95, 0.55, 0.25, 0.7)
				crosshair_tween.tween_property(tick, "color", Color(1.0, 1.0, 1.0, 0.7), maxf(0.15, duration))

func update_score(survival_seconds: float, tags: int, is_taya: bool) -> void:
	if score_label:
		if is_taya:
			score_label.text = "%d HAMPAS" % tags
			score_label.modulate = Color(1.0, 0.85, 0.2)
			if prev_tags != -1 and tags > prev_tags:
				_pulse_score_label()
			prev_tags = tags
		else:
			score_label.text = "%.1fs" % survival_seconds
			score_label.modulate = Color(0.85, 0.95, 1.0)

func _pulse_score_label() -> void:
	if not score_label:
		return
	score_label.pivot_offset = score_label.size * 0.5
	if score_pulse_tween and score_pulse_tween.is_valid():
		score_pulse_tween.kill()
	score_pulse_tween = create_tween()
	score_pulse_tween.tween_property(score_label, "scale", Vector2(1.35, 1.35), 0.1).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	score_pulse_tween.tween_property(score_label, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)

func update_barya(count: int) -> void:
	if barya_label:
		barya_label.text = str(count)

func update_match_timer(time_left: float) -> void:
	if timer_label:
		var mins: int = int(time_left / 60.0)
		var secs: int = int(time_left) % 60
		timer_label.text = "%02d:%02d" % [mins, secs]

		if time_left < 10.0 and secs != prev_countdown_sec:
			prev_countdown_sec = secs
			_pulse_timer_label()

		if time_left < 10.0:
			timer_label.modulate = Color(1.0, 0.25, 0.2)
			if critical_vignette:
				critical_vignette.visible = is_taya_local
				var pulse := 0.16 + 0.14 * sin(Time.get_ticks_msec() * 0.014)
				critical_vignette.color = Color(0.95, 0.05, 0.05, pulse)
		elif time_left < 30.0:
			timer_label.modulate = Color(1.0, 0.65, 0.2)
			if critical_vignette:
				critical_vignette.visible = false
		else:
			timer_label.modulate = Color(1.0, 1.0, 1.0)
			if critical_vignette:
				critical_vignette.visible = false

func update_flood_meter(level: float, is_flooded: bool) -> void:
	if not flood_container:
		flood_container = get_node_or_null("TopRightControls/FloodMeterContainer") if get_node_or_null("TopRightControls/FloodMeterContainer") else get_node_or_null("TopBar/FloodMeterContainer")
	if flood_container:
		flood_container.visible = (is_flooded or level > 0.0)

	if not flood_label:
		flood_label = get_node_or_null("%FloodLabel") if has_node("%FloodLabel") else get_node_or_null("TopBar/FloodMeterContainer/Margin/FloodLabel")
	if not flood_label:
		return

	if is_flooded or level >= 100.0:
		flood_label.text = "🚨 BUMABAHA NA!"
		flood_label.add_theme_color_override("font_color", Color(1.0, 0.25, 0.25, 1.0))
	elif level >= 80.0:
		flood_label.text = "🚨 KANAL: %d%% MAG-APAW!" % int(level)
		flood_label.add_theme_color_override("font_color", Color(1.0, 0.45, 0.2, 1.0))
	elif level >= 50.0:
		flood_label.text = "⚠️ KANAL: %d%% BARADO" % int(level)
		flood_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.25, 1.0))
	else:
		flood_label.text = "🌊 KANAL: MALINIS"
		flood_label.add_theme_color_override("font_color", Color(0.35, 0.85, 0.95, 1.0))

func _pulse_timer_label() -> void:
	if not timer_label:
		return
	timer_label.pivot_offset = timer_label.size * 0.5
	if timer_pulse_tween and timer_pulse_tween.is_valid():
		timer_pulse_tween.kill()
	timer_pulse_tween = create_tween()
	timer_pulse_tween.tween_property(timer_label, "scale", Vector2(1.25, 1.25), 0.08).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	timer_pulse_tween.tween_property(timer_label, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)

func update_round_badge(round_num: int, mode_name: String, alive_count: int, total_count: int) -> void:
	if round_label:
		var mode_str := (" - " + mode_name.to_upper()) if not mode_name.is_empty() else ""
		if alive_count <= 2 and total_count > 2:
			round_label.text = "FINALS (1v1)%s" % mode_str
			round_label.modulate = Color(1.0, 0.35, 0.2)
		else:
			round_label.text = "ROUND %d%s" % [round_num, mode_str]
			round_label.modulate = Color(1.0, 0.85, 0.2)

	if alive_label:
		alive_label.text = "%d BUHAY" % alive_count
		if alive_count <= 2:
			alive_label.modulate = Color(1.0, 0.35, 0.25)
		else:
			alive_label.modulate = Color(0.2, 0.95, 0.5)

		# Scale bounce when alive count decreases
		if prev_alive_count != -1 and alive_count < prev_alive_count:
			alive_label.pivot_offset = alive_label.size * 0.5
			var at := create_tween()
			at.tween_property(alive_label, "scale", Vector2(1.3, 1.3), 0.1).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			at.tween_property(alive_label, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
		prev_alive_count = alive_count

func show_spectator_bar(target_name: String) -> void:
	if spectator_bar:
		spectator_bar.visible = true
	if spectator_label:
		spectator_label.text = "NANONOOD KAY: %s   |   [SPACE / CLICK / A-D] Palitan" % target_name.to_upper()

func update_spectator_info(target_data: Dictionary) -> void:
	if spectator_bar:
		spectator_bar.visible = true
	var t_name: String = str(target_data.get("name", "Player")).to_upper()
	var t_role_str: String = "TAYA 🔥" if int(target_data.get("role", 0)) == 1 else "RUNNER 🏃"
	var t_score: int = int(target_data.get("score", 0))
	var t_tags: int = int(target_data.get("tags", 0))
	var alive_count: int = int(target_data.get("alive_count", 0))
	if spectator_label:
		spectator_label.text = "NANONOOD KAY: %s (%s)  |  Score: %d  |  Huli: %d  |  Buhay: %d\n[SPACE / TOUCH / A-D] Palitan ng Titingnan" % [t_name, t_role_str, t_score, t_tags, alive_count]

func hide_spectator_bar() -> void:
	if spectator_bar:
		spectator_bar.visible = false

func show_round_intermission(next_round: int, eliminated_name: String, remaining_count: int) -> void:
	if intermission_banner:
		intermission_banner.visible = true
		intermission_banner.scale = Vector2(0.8, 0.8)
		intermission_banner.pivot_offset = intermission_banner.size * 0.5
		var t := create_tween()
		t.tween_property(intermission_banner, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	if intermission_title:
		if "," in eliminated_name:
			intermission_title.text = "NA-TAYA SILA: %s! ELIMINADO NA!" % eliminated_name.to_upper()
		else:
			intermission_title.text = "NA-TAYA SI %s! ELIMINADO NA!" % eliminated_name.to_upper()
	if intermission_sub:
		intermission_sub.text = "%d bata na lang ang natitira sa kalye!\nSusunod na Round %d sa loob ng ilang sandali..." % [remaining_count, next_round]

func hide_round_intermission() -> void:
	if intermission_banner:
		intermission_banner.visible = false

func update_intermission_timer(time_left: float) -> void:
	if intermission_sub:
		intermission_sub.text = "Paghahanda para sa susunod na round: %.1fs" % maxf(0.0, time_left)
	if time_left <= 0.0:
		hide_round_intermission()

func update_scoreboard(players_data: Dictionary) -> void:
	if not player_list_box:
		return
	for child in player_list_box.get_children():
		player_list_box.remove_child(child)
		child.queue_free()

	for pid in players_data.keys():
		var pinfo = players_data[pid]
		var item := Label.new()
		var is_p_taya: bool = (pinfo.get("role", 0) == 1)
		var is_sent_home: bool = pinfo.get("sent_home", false)
		var p_name: String = str(pinfo.get("name", "Player"))
		var p_score: int = int(pinfo.get("score", 0))

		var status_icon := ""
		if is_p_taya:
			status_icon = "[TAYA] "
		elif is_sent_home:
			status_icon = "[UMUWI] "

		item.text = "%s%-10s %d" % [status_icon, p_name, p_score]
		item.add_theme_font_size_override("font_size", 12)

		if is_p_taya:
			item.modulate = Color(1.0, 0.35, 0.2)
		elif is_sent_home:
			item.modulate = Color(0.7, 0.7, 0.7, 0.7)
		else:
			item.modulate = Color(0.85, 0.95, 1.0)
		player_list_box.add_child(item)

func toggle_scoreboard(show_board: bool) -> void:
	if scoreboard_panel:
		scoreboard_panel.visible = show_board

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.keycode == KEY_TAB and not event.echo:
		toggle_scoreboard(event.pressed)

# --- Contextual Interaction Prompt ---
func on_interactable_changed(has_target: bool, prompt_icon: String, prompt_action: String) -> void:
	if crosshair:
		_set_crosshair_target_bloom(has_target)

	if not contextual_prompt:
		return

	if not has_target:
		if contextual_prompt.visible:
			if prompt_tween and prompt_tween.is_valid():
				prompt_tween.kill()
			prompt_tween = create_tween()
			prompt_tween.tween_property(contextual_prompt, "modulate:a", 0.0, 0.12)
			prompt_tween.tween_callback(func(): contextual_prompt.visible = false)
		return

	if prompt_icon_label:
		prompt_icon_label.text = prompt_icon
	if prompt_action_label:
		prompt_action_label.text = "[E] " + prompt_action

	if not contextual_prompt.visible:
		contextual_prompt.visible = true
		contextual_prompt.modulate.a = 0.0
		contextual_prompt.scale = Vector2(0.8, 0.8)

	if prompt_tween and prompt_tween.is_valid():
		prompt_tween.kill()
	prompt_tween = create_tween().set_parallel(true)
	prompt_tween.tween_property(contextual_prompt, "modulate:a", 1.0, 0.15)
	prompt_tween.tween_property(contextual_prompt, "scale", Vector2.ONE, 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _set_crosshair_target_bloom(active: bool) -> void:
	if not crosshair:
		return
	if crosshair_tween and crosshair_tween.is_valid():
		crosshair_tween.kill()
	crosshair_tween = create_tween().set_parallel(true)
	if active:
		crosshair_tween.tween_property(crosshair, "scale", Vector2(1.3, 1.3), 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		if crosshair_dot:
			crosshair_tween.tween_property(crosshair_dot, "color", Color(1.0, 0.85, 0.2, 1.0), 0.1)
		for tick in crosshair_ticks:
			if tick:
				crosshair_tween.tween_property(tick, "color", Color(1.0, 0.85, 0.2, 0.9), 0.1)
	else:
		crosshair_tween.tween_property(crosshair, "scale", Vector2.ONE, 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		if crosshair_dot:
			crosshair_tween.tween_property(crosshair_dot, "color", Color(1.0, 1.0, 1.0, 0.85), 0.12)
		for tick in crosshair_ticks:
			if tick:
				crosshair_tween.tween_property(tick, "color", Color(1.0, 1.0, 1.0, 0.7), 0.12)

# --- Inventory Slot ---
func on_trash_changed(trash_type: int, _trash_name: String, _bin_category: int) -> void:
	_update_inventory_display(trash_type)

func _update_inventory_display(trash_type: int) -> void:
	if not inventory_slot:
		return

	if trash_type == -1:
		# Empty state
		if trash_icon_label:
			trash_icon_label.text = ""
			trash_icon_label.modulate = Color(0.6, 0.6, 0.6, 0.4)
		if trash_type_label:
			trash_type_label.text = "WALANG LAMAN"
			trash_type_label.modulate = Color(0.6, 0.6, 0.6, 0.5)
		if drop_hint_label:
			drop_hint_label.visible = false
		inventory_slot.modulate = Color(0.8, 0.8, 0.8, 0.6)
	else:
		# Item carried!
		var tname: String = "BASURA"
		match trash_type:
			0:
				tname = "BOTE"
			1:
				tname = "LATA"
			2:
				tname = "SAGING"
			3:
				tname = "KENDI"

		if trash_icon_label:
			trash_icon_label.text = ""
			trash_icon_label.modulate = Color(1.0, 1.0, 1.0, 1.0)
		if trash_type_label:
			trash_type_label.text = tname
			trash_type_label.modulate = Color(1.0, 0.9, 0.3, 1.0)
		if drop_hint_label:
			drop_hint_label.text = "[Q] BITAW"
			drop_hint_label.visible = true

		inventory_slot.modulate = Color(1.0, 1.0, 1.0, 1.0)

		# Scale punch animation on pickup
		if inv_tween and inv_tween.is_valid():
			inv_tween.kill()
		inv_tween = create_tween()
		inv_tween.tween_property(inventory_slot, "scale", Vector2(1.2, 1.2), 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		inv_tween.tween_property(inventory_slot, "scale", Vector2.ONE, 0.12)

# --- Street Items Slot & Hiding Display ---
func on_street_item_changed(item_type: int, _item_name: String, count: int) -> void:
	if not street_item_slot:
		return

	held_street_item_local = item_type

	if item_type == -1 or count <= 0:
		_set_crosshair_throwable_mode(false)
		if street_item_icon: street_item_icon.text = ""
		if street_item_name:
			street_item_name.text = "WALANG GAMIT"
			street_item_name.modulate = Color(0.6, 0.6, 0.6, 0.5)
		if street_item_hint:
			street_item_hint.visible = false
		if street_item_slot:
			street_item_slot.modulate = Color(0.8, 0.8, 0.8, 0.6)
		if top_item_name:
			top_item_name.text = "WALA"
		if top_item_icon:
			top_item_icon.modulate = Color(1.0, 1.0, 1.0, 0.25)
	else:
		_set_crosshair_throwable_mode(item_type == 0 or item_type == 3)
		var iname := "GAMIT"
		var icon := "🎒"
		var hint := "[R-CLICK / G] GAMIT"
		var col := Color(1.0, 1.0, 1.0)

		match item_type:
			0: # TSINELAS
				iname = "TSINELAS (%dx)" % count if count > 1 else "TSINELAS"
				icon = "🩴"
				hint = "[HOLD R-CLICK / G] ASINTA / BATO"
				col = Color(0.3, 0.85, 1.0)
			1: # SAGING
				iname = "SAGING (%dx)" % count if count > 1 else "SAGING"
				icon = "🍌"
				hint = "[R-CLICK] BITAW"
				col = Color(1.0, 0.9, 0.2)
			2: # WHISTLE
				iname = "SIPOL"
				icon = "📢"
				hint = "[R-CLICK] REVEAL"
				col = Color(1.0, 0.35, 0.35)
			3: # CHALK_BAG
				iname = "CHALK DUST"
				icon = "🌫️"
				hint = "[R-CLICK] BATO"
				col = Color(0.95, 0.95, 1.0)
			4: # ICE_CANDY
				iname = "ICE CANDY"
				icon = "🍧"
				hint = "[R-CLICK] SIPSIP"
				col = Color(1.0, 0.45, 0.8)

		if street_item_icon:
			street_item_icon.text = icon
		if street_item_name:
			street_item_name.text = iname
			street_item_name.modulate = col
		if street_item_hint:
			street_item_hint.text = hint
			street_item_hint.visible = true

		if top_item_name:
			top_item_name.text = iname.split(" ")[0]
		if top_item_icon:
			top_item_icon.modulate = Color.WHITE
			match item_type:
				0:
					top_item_icon.texture = load("res://assets/models/Mapupdate/Props_lata.png")
				1:
					top_item_icon.texture = load("res://assets/models/Mapupdate/Props_rotten banana.png")
				3:
					top_item_icon.texture = load("res://assets/models/Mapupdate/Props_chalk dust.png")
				4:
					top_item_icon.texture = load("res://assets/models/Mapupdate/Props_candy wrapper.png")

		street_item_slot.modulate = Color.WHITE

		var tw := create_tween()
		tw.tween_property(street_item_slot, "scale", Vector2(1.2, 1.2), 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_property(street_item_slot, "scale", Vector2.ONE, 0.12)

func on_hiding_state_changed(is_hiding: bool, time_left: float) -> void:
	if not hiding_panel:
		return
	hiding_panel.visible = is_hiding
	if is_hiding:
		if hiding_timer_bar:
			hiding_timer_bar.value = time_left
		if hiding_label:
			hiding_label.text = "NAGTATAGO (%.1fs) [SPACE: LABAS]" % time_left
			hiding_label.modulate = Color(1.0, 0.35, 0.35) if time_left < 3.0 else Color(0.3, 0.9, 1.0)

# --- Imagination Powerup Slot ---
func on_powerup_changed(powerup_type: int, duration_left: float, charges: int) -> void:
	if not powerup_panel:
		return

	if powerup_type == 0:
		powerup_panel.visible = false
		return

	powerup_panel.visible = true
	var p_desc := "IMAGINATION"
	match powerup_type:
		1:
			p_desc = "KIDLAT DASH (%dx)" % charges
		2:
			p_desc = "SUPER SPEED (%.0fs)" % duration_left
		3:
			p_desc = "2x JUMP (%.0fs)" % duration_left
		4:
			p_desc = "WATER RUN (%.0fs)" % duration_left
		5:
			p_desc = "WALL RUN (%.0fs)" % duration_left

	if powerup_icon_label:
		powerup_icon_label.text = ""
	if powerup_label:
		powerup_label.text = p_desc

# --- Danger Sensor ---
func on_danger_detected(is_danger: bool, distance: float) -> void:
	if not danger_overlay:
		return

	if not is_danger or is_taya_local:
		danger_overlay.visible = false
		return

	danger_overlay.visible = true
	if danger_label:
		danger_label.text = "TAYA MALAPIT! (%.0fm)" % distance

# --- Tag & Nanay Announcements (Unified Paper Banner) ---
func show_paper_notification(message: String, duration: float = 2.8) -> void:
	if not tag_banner or not tag_banner_label:
		return

	tag_banner_label.text = message
	tag_banner.visible = true
	tag_banner.scale = Vector2(0.85, 0.85)
	tag_banner.modulate.a = 1.0
	tag_banner.position.y = -130.0

	if banner_tween and banner_tween.is_valid():
		banner_tween.kill()

	banner_tween = create_tween().set_parallel(true)
	banner_tween.tween_property(tag_banner, "scale", Vector2.ONE, 0.24).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	banner_tween.tween_property(tag_banner, "position:y", 18.0, 0.24).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	var hide_seq := create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	hide_seq.tween_interval(duration)
	hide_seq.tween_property(tag_banner, "position:y", -140.0, 0.22)
	hide_seq.tween_callback(func(): tag_banner.visible = false)

func show_tag_banner(chaser_name: String, target_name: String) -> void:
	show_paper_notification("%s NA-TAYA SI %s!\nWALANG BAWIAN!" % [chaser_name.to_upper(), target_name.to_upper()])

func show_toast_notification(message: String, is_success: bool = true) -> void:
	show_paper_notification(message)
	if toast_panel and toast_label:
		toast_label.text = message
		toast_panel.visible = true
		toast_panel.scale = Vector2(0.8, 0.8)
		toast_panel.modulate = Color(0.9, 1.0, 0.9, 1.0) if is_success else Color(1.0, 0.75, 0.75, 1.0)
		if toast_tween and toast_tween.is_valid():
			toast_tween.kill()
		toast_tween = create_tween()
		toast_tween.tween_property(toast_panel, "scale", Vector2.ONE, 0.15)
		toast_tween.tween_interval(2.0)
		toast_tween.tween_property(toast_panel, "modulate:a", 0.0, 0.3)
		toast_tween.tween_callback(func(): toast_panel.visible = false)

func show_nanay_alert(pname: String) -> void:
	show_paper_notification("HOY %s! UMUWI KA NA!\nPINAPAUWI KA NI NANAY!" % pname.to_upper())

func on_stamina_changed(burst_val: float, burst_max: float, endurance_val: float, endurance_max: float, exhausted: bool) -> void:
	if burst_bar and burst_max > 0.0:
		var burst_pct: float = clampf((burst_val / burst_max) * 100.0, 0.0, 100.0)
		burst_bar.value = burst_pct
		if burst_val_label:
			burst_val_label.text = "%d%%" % int(burst_pct)
			if burst_pct <= 20.0:
				burst_val_label.modulate = Color(1.0, 0.3, 0.3)
			else:
				burst_val_label.modulate = Color(1.0, 0.95, 0.6)

	if endurance_bar and endurance_max > 0.0:
		var end_pct: float = clampf((endurance_val / endurance_max) * 100.0, 0.0, 100.0)
		endurance_bar.value = end_pct
		if endurance_val_label:
			endurance_val_label.text = "%d%%" % int(end_pct)
			if exhausted or end_pct <= 25.0:
				endurance_val_label.modulate = Color(1.0, 0.25, 0.2)
			else:
				endurance_val_label.modulate = Color(0.7, 0.95, 1.0)

	if exhausted_warning:
		if exhausted:
			if not exhausted_warning.visible:
				exhausted_warning.visible = true
				if stamina_warning_tween and stamina_warning_tween.is_valid():
					stamina_warning_tween.kill()
				stamina_warning_tween = create_tween().set_loops()
				stamina_warning_tween.tween_property(exhausted_warning, "modulate:a", 0.25, 0.35)
				stamina_warning_tween.tween_property(exhausted_warning, "modulate:a", 1.0, 0.35)
		else:
			if exhausted_warning.visible:
				exhausted_warning.visible = false
				if stamina_warning_tween and stamina_warning_tween.is_valid():
					stamina_warning_tween.kill()
				exhausted_warning.modulate.a = 1.0
