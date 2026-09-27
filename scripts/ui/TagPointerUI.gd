class_name TagPointerUI
extends Control

@onready var reticle: Control = $Reticle
@onready var reticle_label: Label = $Reticle/InfoLabel
@onready var reticle_icon: Label = $Reticle/Icon
@onready var offscreen_indicator: Control = $OffscreenIndicator
@onready var offscreen_label: Label = $OffscreenIndicator/DistanceLabel
@onready var warning_banner: PanelContainer = $WarningBanner
@onready var warning_label: Label = $WarningBanner/Label

var current_target: Node3D = null
var is_target_taya: bool = false
var in_tag_range: bool = false
const TAG_RANGE: float = 4.2

func _ready() -> void:
	visible = true
	reticle.visible = false
	offscreen_indicator.visible = false
	if warning_banner:
		warning_banner.visible = false

func update_pointer(camera: Camera3D, target: Node3D, target_is_taya: bool, local_is_taya: bool) -> void:
	if not camera or not is_instance_valid(target):
		reticle.visible = false
		offscreen_indicator.visible = false
		if warning_banner:
			warning_banner.visible = false
		return

	current_target = target
	is_target_taya = target_is_taya

	var target_head_pos := target.global_position + Vector3(0, 1.85, 0)
	var local_cam_pos := camera.global_position
	var dist := local_cam_pos.distance_to(target.global_position)
	in_tag_range = (dist <= TAG_RANGE)

	var vp_rect := get_viewport_rect()
	var screen_center := vp_rect.size * 0.5
	var is_behind := camera.is_position_behind(target_head_pos)
	var screen_pos := camera.unproject_position(target_head_pos)

	# Check if on-screen
	var margin := 50.0
	var is_on_screen := not is_behind and \
		screen_pos.x >= margin and screen_pos.x <= vp_rect.size.x - margin and \
		screen_pos.y >= margin and screen_pos.y <= vp_rect.size.y - margin

	if is_on_screen:
		# On-screen reticle over target head
		reticle.visible = true
		offscreen_indicator.visible = false
		reticle.position = screen_pos - (reticle.size * 0.5)

		var target_name: String = target.get("player_name") if "player_name" in target else "Player"

		if local_is_taya:
			# Player is Taya hunting runner
			if in_tag_range:
				reticle_icon.text = "🎯 [TAG READY!]"
				reticle_icon.modulate = Color(1.0, 0.2, 0.1)
				reticle_label.text = "🔥 HAMPASIN MO! (%.1fm)" % dist
				reticle_label.modulate = Color(1.0, 0.9, 0.2)
			else:
				reticle_icon.text = "🎯"
				reticle_icon.modulate = Color(0.2, 0.8, 1.0)
				reticle_label.text = "%s (%.1fm)" % [target_name, dist]
				reticle_label.modulate = Color(1.0, 1.0, 1.0)
		else:
			# Player is Runner watching Taya
			reticle_icon.text = "⚠️ [TAYA]"
			reticle_icon.modulate = Color(1.0, 0.2, 0.1)
			reticle_label.text = "%s (%.1fm)" % [target_name, dist]
			reticle_label.modulate = Color(1.0, 0.4, 0.4)
	else:
		# Off-screen arrow pointing to target
		reticle.visible = false
		offscreen_indicator.visible = true

		var dir_to_target := screen_pos - screen_center
		if is_behind:
			dir_to_target = -dir_to_target

		var angle := dir_to_target.angle()
		offscreen_indicator.rotation = angle + (PI * 0.5)

		# Clamp indicator to screen perimeter
		var edge_dist: float = minf(screen_center.x - margin, screen_center.y - margin) * 0.85
		var clamped_pos: Vector2 = screen_center + Vector2(cos(angle), sin(angle)) * edge_dist
		offscreen_indicator.position = clamped_pos

		var role_hint := "RUNNER" if local_is_taya else "TAYA"
		offscreen_label.text = "%s: %.0fm" % [role_hint, dist]
		if local_is_taya:
			offscreen_indicator.modulate = Color(0.3, 0.85, 1.0) if not in_tag_range else Color(1.0, 0.3, 0.2)
		else:
			offscreen_indicator.modulate = Color(1.0, 0.25, 0.2)

	# Danger warning if runner and Taya is close
	if warning_banner:
		if not local_is_taya and dist <= 9.0:
			warning_banner.visible = true
			warning_label.text = "⚠️ DELIKADO! MALAPIT NA ANG TAYA: %.1fm 💨" % dist
		else:
			warning_banner.visible = false
