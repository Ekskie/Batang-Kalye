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

var is_power_revealed: bool = false
var power_reveal_timer: float = 0.0

func _ready() -> void:
	visible = true
	reticle.visible = false
	offscreen_indicator.visible = false
	if warning_banner:
		warning_banner.visible = false

func trigger_power_reveal(duration: float = 3.5) -> void:
	is_power_revealed = true
	power_reveal_timer = duration

func _process(delta: float) -> void:
	if is_power_revealed:
		power_reveal_timer -= delta
		if power_reveal_timer <= 0.0:
			is_power_revealed = false
			reticle.visible = false
			offscreen_indicator.visible = false
			if warning_banner:
				warning_banner.visible = false

func update_pointer(camera: Camera3D, target: Node3D, target_is_taya: bool, local_is_taya: bool) -> void:
	# Keep all reticles, distance markers, and banners hidden unless a power (e.g. Whistle) revealed players
	if not is_power_revealed or not camera or not is_instance_valid(target):
		reticle.visible = false
		offscreen_indicator.visible = false
		if warning_banner:
			warning_banner.visible = false
		current_target = null
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
				reticle_icon.text = "[TAG READY!]"
				reticle_icon.modulate = Color(1.0, 0.2, 0.1)
				reticle_label.text = "HAMPASIN MO! (%.1fm)" % dist
				reticle_label.modulate = Color(1.0, 0.9, 0.2)
				reticle.pivot_offset = reticle.size * 0.5
				var pulse := 1.0 + 0.14 * sin(Time.get_ticks_msec() * 0.016)
				reticle.scale = Vector2.ONE * pulse
			else:
				reticle_icon.text = "[NAKITA!]"
				reticle_icon.modulate = Color(0.2, 0.8, 1.0)
				reticle_label.text = "%s (%.1fm)" % [target_name, dist]
				reticle_label.modulate = Color(1.0, 1.0, 1.0)
				reticle.scale = Vector2.ONE
		else:
			# Player is Runner - revealed opponent
			reticle_icon.text = "[NAKITA!]"
			reticle_icon.modulate = Color(1.0, 0.4, 0.2)
			reticle_label.text = "%s (%.1fm)" % [target_name, dist]
			reticle_label.modulate = Color(1.0, 0.8, 0.4)
			reticle.scale = Vector2.ONE
	else:
		# Off-screen arrow pointing to target
		reticle.visible = false
		reticle.scale = Vector2.ONE
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

		offscreen_label.text = "%.0fm" % dist
		if local_is_taya:
			offscreen_indicator.modulate = Color(0.3, 0.85, 1.0) if not in_tag_range else Color(1.0, 0.3, 0.2)
		else:
			offscreen_indicator.modulate = Color(1.0, 0.4, 0.2)

	# Danger warning if runner and opponent is close during reveal
	if warning_banner:
		if not local_is_taya and dist <= 9.0:
			warning_banner.visible = true
			warning_label.text = "BABALA! MALAPIT: %.1fm" % dist
			warning_banner.pivot_offset = warning_banner.size * 0.5
			var warn_pulse := 1.0 + 0.06 * sin(Time.get_ticks_msec() * 0.02)
			warning_banner.scale = Vector2.ONE * warn_pulse
		else:
			warning_banner.visible = false
