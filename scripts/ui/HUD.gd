class_name HUD
extends Control

@onready var role_badge: Label = $TopBar/RoleBadge
@onready var score_label: Label = $TopBar/ScoreLabel
@onready var timer_label: Label = $TopBar/TimerLabel
@onready var player_list_box: VBoxContainer = $ScoreboardPanel/MarginContainer/VBoxContainer/PlayerList

@onready var tag_banner: PanelContainer = $TagBanner
@onready var tag_banner_label: Label = $TagBanner/MarginContainer/Label

@onready var powerup_panel: PanelContainer = $PowerupPanel
@onready var powerup_label: Label = $PowerupPanel/MarginContainer/PowerupLabel

@onready var held_trash_panel: PanelContainer = $HeldTrashPanel
@onready var held_trash_name_label: Label = $HeldTrashPanel/MarginContainer/VBoxContainer/HeldTrashName
@onready var held_trash_hint_label: Label = $HeldTrashPanel/MarginContainer/VBoxContainer/HeldTrashHint

@onready var toast_panel: PanelContainer = $ToastPanel
@onready var toast_label: Label = $ToastPanel/MarginContainer/ToastLabel

var banner_tween: Tween
var toast_tween: Tween

func update_role_display(is_taya: bool) -> void:
	if is_taya:
		role_badge.text = "🔥 IKAW ANG TAYA! (CHASER)"
		role_badge.modulate = Color(1.0, 0.3, 0.2)
	else:
		role_badge.text = "👟 RUNNER (IWAS TAYA)"
		role_badge.modulate = Color(0.2, 0.9, 0.4)

func update_score(survival_seconds: float, tags: int, is_taya: bool) -> void:
	if is_taya:
		score_label.text = "🏆 Tags: %d" % tags
	else:
		score_label.text = "⏱️ Survived: %.1fs" % survival_seconds

func update_match_timer(time_left: float) -> void:
	var mins: int = int(time_left) / 60
	var secs: int = int(time_left) % 60
	timer_label.text = "%02d:%02d" % [mins, secs]

func update_scoreboard(players_data: Dictionary) -> void:
	for child in player_list_box.get_children():
		child.queue_free()

	for pid in players_data.keys():
		var pinfo = players_data[pid]
		var item := Label.new()
		var is_p_taya: bool = (pinfo.get("role", 0) == 1)
		var role_tag := " [TAYA]" if is_p_taya else ""
		item.text = "%s%s: %d pts" % [pinfo.get("name", "Player"), role_tag, pinfo.get("score", 0)]
		if is_p_taya:
			item.modulate = Color(1.0, 0.4, 0.3)
		player_list_box.add_child(item)

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
	banner_tween.tween_interval(2.2)
	banner_tween.tween_property(tag_banner, "modulate:a", 0.0, 0.4)
	banner_tween.tween_callback(func(): tag_banner.visible = false)

func on_powerup_changed(powerup_type: int, duration_left: float, charges: int) -> void:
	if not powerup_panel or not powerup_label:
		return

	if powerup_type == 0: # NONE
		powerup_panel.visible = false
		return

	powerup_panel.visible = true
	match powerup_type:
		1: # DASH
			powerup_label.text = "✨ IMAGINATION: ⚡ KIDLAT DASH (%d charges)" % charges
		2: # SUPER_SPEED
			powerup_label.text = "✨ IMAGINATION: 🏃 SUPER SPEED (%.1fs)" % duration_left
		3: # DOUBLE_JUMP
			powerup_label.text = "✨ IMAGINATION: 🦘 DOUBLE JUMP (%.1fs)" % duration_left
		4: # WATER_RUN
			powerup_label.text = "✨ IMAGINATION: 🌊 WATER RUN (%.1fs)" % duration_left
		5: # WALL_RUN
			powerup_label.text = "✨ IMAGINATION: 🧗 WALL RUN (%.1fs)" % duration_left

func on_trash_changed(trash_type: int, trash_name: String, bin_category: int) -> void:
	if not held_trash_panel or not held_trash_name_label or not held_trash_hint_label:
		return

	if trash_type == -1:
		held_trash_panel.visible = false
		return

	held_trash_panel.visible = true
	held_trash_name_label.text = "🗑️ Dala: " + trash_name

	match bin_category:
		0: # Recyclable
			held_trash_hint_label.text = "👉 Dalhin sa: 🔵 Asul (Recyclable)"
			held_trash_hint_label.modulate = Color(0.3, 0.8, 1.0)
		1: # Biodegradable
			held_trash_hint_label.text = "👉 Dalhin sa: 🟢 Berde (Nabubulok)"
			held_trash_hint_label.modulate = Color(0.4, 1.0, 0.4)
		2: # Non-Biodegradable
			held_trash_hint_label.text = "👉 Dalhin sa: 🟡 Dilaw (Di-Nabubulok)"
			held_trash_hint_label.modulate = Color(1.0, 0.9, 0.3)

func show_toast_notification(message: String, is_success: bool) -> void:
	if not toast_panel or not toast_label:
		return

	toast_label.text = message
	toast_panel.visible = true
	toast_panel.scale = Vector2(0.7, 0.7)
	toast_panel.modulate.a = 1.0

	# Tint toast background based on success or warning
	if is_success:
		toast_panel.modulate = Color(0.9, 1.0, 0.9, 1.0)
	else:
		toast_panel.modulate = Color(1.0, 0.75, 0.75, 1.0)

	if toast_tween:
		toast_tween.kill()

	toast_tween = create_tween()
	toast_tween.tween_property(toast_panel, "scale", Vector2(1.08, 1.08), 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	toast_tween.tween_property(toast_panel, "scale", Vector2(1.0, 1.0), 0.08)
	toast_tween.tween_interval(2.2)
	toast_tween.tween_property(toast_panel, "modulate:a", 0.0, 0.35)
	toast_tween.tween_callback(func(): toast_panel.visible = false)
