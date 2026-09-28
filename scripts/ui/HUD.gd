class_name HUD
extends Control

# Top Bar
@onready var timer_label: Label = get_node_or_null("TopBar/TimerContainer/TimerLabel")
@onready var btn_hud_pause: Button = get_node_or_null("TopBar/BtnHudPause")

# Side Role & Score
@onready var role_badge: Label = get_node_or_null("SideBar/RolePanel/Margin/HBox/RoleBadge")
@onready var score_label: Label = get_node_or_null("SideBar/RolePanel/Margin/HBox/ScoreLabel")
@onready var role_panel: PanelContainer = get_node_or_null("SideBar/RolePanel")

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

var banner_tween: Tween
var toast_tween: Tween
var prompt_tween: Tween
var inv_tween: Tween

var is_taya_local: bool = false

func _ready() -> void:
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
	_update_inventory_display(-1)

func update_role_display(is_taya: bool) -> void:
	is_taya_local = is_taya
	if role_badge:
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
		else:
			score_label.text = "⏱️ %.1fs" % survival_seconds

func update_match_timer(time_left: float) -> void:
	if timer_label:
		var mins: int = int(time_left) / 60
		var secs: int = int(time_left) % 60
		timer_label.text = "%02d:%02d" % [mins, secs]
		if time_left < 30.0:
			timer_label.modulate = Color(1.0, 0.3, 0.2)
		else:
			timer_label.modulate = Color(1.0, 1.0, 1.0)

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
		var status_icon := " 🔥" if is_p_taya else ""
		if is_sent_home:
			status_icon = " 🏠"
		item.text = "%s%s: %d" % [pinfo.get("name", "Player"), status_icon, pinfo.get("score", 0)]
		if is_p_taya:
			item.modulate = Color(1.0, 0.35, 0.2)
		elif is_sent_home:
			item.modulate = Color(1.0, 0.75, 0.2)
		else:
			item.modulate = Color(0.85, 0.95, 1.0)
		player_list_box.add_child(item)

# --- Contextual Interaction Prompt ---
func on_interactable_changed(has_target: bool, prompt_icon: String, prompt_action: String) -> void:
	if not contextual_prompt:
		return

	if not has_target:
		if contextual_prompt.visible:
			if prompt_tween:
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

	if prompt_tween:
		prompt_tween.kill()
	prompt_tween = create_tween().set_parallel(true)
	prompt_tween.tween_property(contextual_prompt, "modulate:a", 1.0, 0.15)
	prompt_tween.tween_property(contextual_prompt, "scale", Vector2.ONE, 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

# --- Inventory Slot ---
func on_trash_changed(trash_type: int, trash_name: String, _bin_category: int) -> void:
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
		if inv_tween:
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

	if banner_tween:
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

	if toast_tween:
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

	if toast_tween:
		toast_tween.kill()

	toast_tween = create_tween()
	toast_tween.tween_property(toast_panel, "scale", Vector2(1.2, 1.2), 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	toast_tween.tween_property(toast_panel, "scale", Vector2.ONE, 0.1)
	toast_tween.tween_interval(3.5)
	toast_tween.tween_property(toast_panel, "modulate:a", 0.0, 0.4)
	toast_tween.tween_callback(func(): toast_panel.visible = false)
