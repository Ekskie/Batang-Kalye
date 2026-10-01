class_name HUD
extends Control

# Top Bar (Tournament Pill Header)
@onready var timer_label: Label = get_node_or_null("TopBar/TimerContainer/TimerLabel")
@onready var btn_hud_pause: Button = get_node_or_null("TopBar/BtnHudPause")
@onready var round_label: Label = get_node_or_null("TopBar/RoundContainer/Margin/RoundLabel")
@onready var alive_label: Label = get_node_or_null("TopBar/AliveContainer/Margin/AliveLabel")

# Player Status Deck (Bottom-Left Dashboard)
@onready var player_deck: PanelContainer = get_node_or_null("PlayerDeck")
@onready var role_badge: Label = (get_node_or_null("PlayerDeck/Margin/VBox/RoleRow/RoleBadge") as Label) if get_node_or_null("PlayerDeck/Margin/VBox/RoleRow/RoleBadge") else (get_node_or_null("SideBar/RolePanel/Margin/HBox/RoleBadge") as Label)
@onready var score_label: Label = (get_node_or_null("PlayerDeck/Margin/VBox/RoleRow/ScoreLabel") as Label) if get_node_or_null("PlayerDeck/Margin/VBox/RoleRow/ScoreLabel") else (get_node_or_null("SideBar/RolePanel/Margin/HBox/ScoreLabel") as Label)
@onready var role_panel: PanelContainer = (get_node_or_null("PlayerDeck") as PanelContainer) if get_node_or_null("PlayerDeck") else (get_node_or_null("SideBar/RolePanel") as PanelContainer)

# Stamina Display
@onready var stamina_panel: PanelContainer = (get_node_or_null("PlayerDeck") as PanelContainer) if get_node_or_null("PlayerDeck") else (get_node_or_null("StaminaPanel") as PanelContainer)
@onready var burst_bar: ProgressBar = (get_node_or_null("PlayerDeck/Margin/VBox/BurstBar") as ProgressBar) if get_node_or_null("PlayerDeck/Margin/VBox/BurstBar") else (get_node_or_null("StaminaPanel/Margin/VBox/BurstBar") as ProgressBar)
@onready var burst_val_label: Label = (get_node_or_null("PlayerDeck/Margin/VBox/BurstHeader/BurstValue") as Label) if get_node_or_null("PlayerDeck/Margin/VBox/BurstHeader/BurstValue") else (get_node_or_null("StaminaPanel/Margin/VBox/BurstHeader/BurstValue") as Label)
@onready var endurance_bar: ProgressBar = (get_node_or_null("PlayerDeck/Margin/VBox/EnduranceBar") as ProgressBar) if get_node_or_null("PlayerDeck/Margin/VBox/EnduranceBar") else (get_node_or_null("StaminaPanel/Margin/VBox/EnduranceBar") as ProgressBar)
@onready var endurance_val_label: Label = (get_node_or_null("PlayerDeck/Margin/VBox/EnduranceHeader/EnduranceValue") as Label) if get_node_or_null("PlayerDeck/Margin/VBox/EnduranceHeader/EnduranceValue") else (get_node_or_null("StaminaPanel/Margin/VBox/EnduranceHeader/EnduranceValue") as Label)
@onready var exhausted_warning: Label = (get_node_or_null("PlayerDeck/Margin/VBox/ExhaustedWarning") as Label) if get_node_or_null("PlayerDeck/Margin/VBox/ExhaustedWarning") else (get_node_or_null("StaminaPanel/Margin/VBox/ExhaustedWarning") as Label)

# Center Reticle Crosshair (Crab Game / Karlson style)
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
@onready var player_list_box: VBoxContainer = get_node_or_null("ScoreboardPanel/MarginContainer/VBoxContainer/PlayerList")

# Contextual Interaction Prompt
@onready var contextual_prompt: PanelContainer = get_node_or_null("ContextualPrompt")
@onready var prompt_icon_label: Label = get_node_or_null("ContextualPrompt/Margin/HBox/PromptIcon")
@onready var prompt_action_label: Label = get_node_or_null("ContextualPrompt/Margin/HBox/PromptAction")

# Bottom Inventory & Powerup Cards
@onready var inventory_slot: PanelContainer = get_node_or_null("BottomBar/InventorySlot")
@onready var trash_icon_label: Label = get_node_or_null("BottomBar/InventorySlot/Margin/VBox/TrashIcon")
@onready var trash_type_label: Label = get_node_or_null("BottomBar/InventorySlot/Margin/VBox/TrashType")
@onready var drop_hint_label: Label = get_node_or_null("BottomBar/InventorySlot/Margin/VBox/DropHint")

@onready var powerup_panel: PanelContainer = get_node_or_null("BottomBar/PowerupSlot")
@onready var powerup_icon_label: Label = get_node_or_null("BottomBar/PowerupSlot/Margin/VBox/PowerupIcon")
@onready var powerup_label: Label = get_node_or_null("BottomBar/PowerupSlot/Margin/VBox/PowerupLabel")

# Danger Sensor
@onready var danger_overlay: Control = get_node_or_null("DangerOverlay")
@onready var danger_label: Label = get_node_or_null("DangerOverlay/DangerPill/Label")

# Announcements
@onready var toast_panel: PanelContainer = get_node_or_null("ToastPanel")
@onready var toast_label: Label = get_node_or_null("ToastPanel/MarginContainer/ToastLabel")

@onready var tag_banner: PanelContainer = get_node_or_null("TagBanner")
@onready var tag_banner_label: Label = get_node_or_null("TagBanner/MarginContainer/Label")

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

var deck_style_runner: StyleBoxFlat
var deck_style_taya: StyleBoxFlat

var is_taya_local: bool = false
var prev_tags: int = -1
var prev_countdown_sec: int = -1
var prev_alive_count: int = -1

func _ready() -> void:
	_init_deck_styles()

	if btn_hud_pause:
		btn_hud_pause.pressed.connect(func():
			var main_node = get_node_or_null("/root/Main")
			if main_node and main_node.has_method("toggle_pause"):
				main_node.toggle_pause()
		)
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

	update_speed_lines(0.0)
	_update_inventory_display(-1)

func _init_deck_styles() -> void:
	deck_style_runner = StyleBoxFlat.new()
	deck_style_runner.bg_color = Color(0.04, 0.07, 0.12, 0.92)
	deck_style_runner.border_width_left = 2
	deck_style_runner.border_width_top = 2
	deck_style_runner.border_width_right = 2
	deck_style_runner.border_width_bottom = 2
	deck_style_runner.border_color = Color(0.18, 0.85, 0.65, 0.9)
	deck_style_runner.set_corner_radius_all(16)
	deck_style_runner.shadow_color = Color(0.05, 0.4, 0.25, 0.3)
	deck_style_runner.shadow_size = 10

	deck_style_taya = StyleBoxFlat.new()
	deck_style_taya.bg_color = Color(0.08, 0.04, 0.06, 0.94)
	deck_style_taya.border_width_left = 2
	deck_style_taya.border_width_top = 2
	deck_style_taya.border_width_right = 2
	deck_style_taya.border_width_bottom = 2
	deck_style_taya.border_color = Color(1.0, 0.25, 0.15, 0.95)
	deck_style_taya.set_corner_radius_all(16)
	deck_style_taya.shadow_color = Color(0.8, 0.1, 0.1, 0.4)
	deck_style_taya.shadow_size = 14

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

func update_role_display(is_taya: bool) -> void:
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
			role_badge.text = "🔥 TAYA"
			role_badge.modulate = Color(1.0, 0.3, 0.15)
		else:
			role_badge.text = "👟 RUNNER"
			role_badge.modulate = Color(0.25, 0.95, 0.45)

func update_score(survival_seconds: float, tags: int, is_taya: bool) -> void:
	if score_label:
		if is_taya:
			score_label.text = "🏆 %d HAMPAS" % tags
			score_label.modulate = Color(1.0, 0.85, 0.2)
			if prev_tags != -1 and tags > prev_tags:
				_pulse_score_label()
			prev_tags = tags
		else:
			score_label.text = "⏱️ %.1fs" % survival_seconds
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

func _pulse_timer_label() -> void:
	if not timer_label:
		return
	timer_label.pivot_offset = timer_label.size * 0.5
	if timer_pulse_tween and timer_pulse_tween.is_valid():
		timer_pulse_tween.kill()
	timer_pulse_tween = create_tween()
	timer_pulse_tween.tween_property(timer_label, "scale", Vector2(1.25, 1.25), 0.08).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	timer_pulse_tween.tween_property(timer_label, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)

func update_round_badge(round_num: int, _mode_name: String, alive_count: int, total_count: int) -> void:
	if round_label:
		if alive_count <= 2 and total_count > 2:
			round_label.text = "🏆 FINALS (1v1)"
			round_label.modulate = Color(1.0, 0.35, 0.2)
		else:
			round_label.text = "🥊 ROUND %d" % round_num
			round_label.modulate = Color(1.0, 0.85, 0.2)

	if alive_label:
		alive_label.text = "👥 %d BUHAY" % alive_count
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
		spectator_label.text = "👁️ NANONOOD KAY: %s   |   [SPACE / CLICK / A-D] Palitan" % target_name.to_upper()

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
		intermission_title.text = "💥 NA-TAYA SI %s! ELIMINADO NA!" % eliminated_name.to_upper()
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
		child.queue_free()

	for pid in players_data.keys():
		var pinfo = players_data[pid]
		var item := Label.new()
		var is_p_taya: bool = (pinfo.get("role", 0) == 1)
		var is_sent_home: bool = pinfo.get("sent_home", false)
		var p_name: String = str(pinfo.get("name", "Player"))
		var p_score: int = int(pinfo.get("score", 0))

		var status_icon := "👟 "
		if is_p_taya:
			status_icon = "🔥 "
		elif is_sent_home:
			status_icon = "🏠 "

		item.text = "%s%-10s %d" % [status_icon, p_name, p_score]
		item.add_theme_font_size_override("font_size", 12)

		if is_p_taya:
			item.modulate = Color(1.0, 0.35, 0.2)
		elif is_sent_home:
			item.modulate = Color(0.7, 0.7, 0.7, 0.7)
		else:
			item.modulate = Color(0.85, 0.95, 1.0)
		player_list_box.add_child(item)

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
			trash_icon_label.text = "📭"
			trash_icon_label.modulate = Color(0.6, 0.6, 0.6, 0.4)
		if trash_type_label:
			trash_type_label.text = "WALANG LAMAN"
			trash_type_label.modulate = Color(0.6, 0.6, 0.6, 0.5)
		if drop_hint_label:
			drop_hint_label.visible = false
		inventory_slot.modulate = Color(0.8, 0.8, 0.8, 0.6)
	else:
		# Item carried!
		var icon: String = "📦"
		var tname: String = "BASURA"
		match trash_type:
			0:
				icon = "🍾"
				tname = "BOTE"
			1:
				icon = "🥫"
				tname = "LATA"
			2:
				icon = "🍌"
				tname = "SAGING"
			3:
				icon = "🍬"
				tname = "KENDI"

		if trash_icon_label:
			trash_icon_label.text = icon
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

# --- Imagination Powerup Slot ---
func on_powerup_changed(powerup_type: int, duration_left: float, charges: int) -> void:
	if not powerup_panel:
		return

	if powerup_type == 0:
		powerup_panel.visible = false
		return

	powerup_panel.visible = true
	var p_icon := "✨"
	var p_desc := "IMAGINATION"
	match powerup_type:
		1:
			p_icon = "⚡"
			p_desc = "KIDLAT DASH (%dx)" % charges
		2:
			p_icon = "🏃"
			p_desc = "SUPER SPEED (%.0fs)" % duration_left
		3:
			p_icon = "🦘"
			p_desc = "2x JUMP (%.0fs)" % duration_left
		4:
			p_icon = "🌊"
			p_desc = "WATER RUN (%.0fs)" % duration_left
		5:
			p_icon = "🧗"
			p_desc = "WALL RUN (%.0fs)" % duration_left

	if powerup_icon_label:
		powerup_icon_label.text = p_icon
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
		danger_label.text = "⚠️ TAYA MALAPIT! (%.0fm)" % distance

# --- Tag & Nanay Announcements ---
func show_tag_banner(chaser_name: String, target_name: String) -> void:
	if not tag_banner or not tag_banner_label:
		return

	tag_banner_label.text = "💥 %s NA-TAYA SI %s!\nWALANG BAWIAN!" % [chaser_name.to_upper(), target_name.to_upper()]
	tag_banner.visible = true
	tag_banner.scale = Vector2(0.5, 0.5)
	tag_banner.modulate.a = 1.0

	if banner_tween and banner_tween.is_valid():
		banner_tween.kill()

	banner_tween = create_tween()
	banner_tween.tween_property(tag_banner, "scale", Vector2(1.15, 1.15), 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	banner_tween.tween_property(tag_banner, "scale", Vector2(1.0, 1.0), 0.1)
	banner_tween.tween_interval(2.0)
	banner_tween.tween_property(tag_banner, "modulate:a", 0.0, 0.35)
	banner_tween.tween_callback(func(): tag_banner.visible = false)

func show_toast_notification(message: String, is_success: bool) -> void:
	if not toast_panel or not toast_label:
		return

	toast_label.text = message
	toast_panel.visible = true
	toast_panel.scale = Vector2(0.8, 0.8)
	toast_panel.modulate.a = 1.0

	if is_success:
		toast_panel.modulate = Color(0.9, 1.0, 0.9, 1.0)
	else:
		toast_panel.modulate = Color(1.0, 0.75, 0.75, 1.0)

	if toast_tween and toast_tween.is_valid():
		toast_tween.kill()

	toast_tween = create_tween()
	toast_tween.tween_property(toast_panel, "scale", Vector2(1.06, 1.06), 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	toast_tween.tween_property(toast_panel, "scale", Vector2.ONE, 0.08)
	toast_tween.tween_interval(2.0)
	toast_tween.tween_property(toast_panel, "modulate:a", 0.0, 0.3)
	toast_tween.tween_callback(func(): toast_panel.visible = false)

func show_nanay_alert(pname: String) -> void:
	if not toast_panel or not toast_label:
		return

	toast_label.text = "🏠 HOY %s! UMUWI KA NA!\nPINAPAUWI KA NI NANAY!" % pname.to_upper()
	toast_panel.visible = true
	toast_panel.scale = Vector2(0.5, 0.5)
	toast_panel.modulate = Color(1.0, 0.7, 0.1, 1.0)

	if toast_tween and toast_tween.is_valid():
		toast_tween.kill()

	toast_tween = create_tween()
	toast_tween.tween_property(toast_panel, "scale", Vector2(1.2, 1.2), 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	toast_tween.tween_property(toast_panel, "scale", Vector2.ONE, 0.1)
	toast_tween.tween_interval(3.5)
	toast_tween.tween_property(toast_panel, "modulate:a", 0.0, 0.4)
	toast_tween.tween_callback(func(): toast_panel.visible = false)

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
