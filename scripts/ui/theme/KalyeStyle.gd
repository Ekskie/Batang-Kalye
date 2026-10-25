@tool
class_name KalyeStyle
extends RefCounted
## Batang Kalye design system: palette tokens, stylebox factories, and the theme builder.
##
## The look follows the chunky mobile-arcade standard (Brawl Stars / Stumble Guys class):
## saturated toy-like surfaces, a single ink outline everywhere, a pressable darker lip,
## white display type with a heavy ink outline. All Filipino flavour lives in the copy.
##
## Usage from UI code:
##   KalyeStyle.apply_button(btn, KalyeStyle.Kind.PRIMARY)
##   KalyeStyle.apply_panel(panel, KalyeStyle.Surface.CARD)
##   KalyeStyle.apply_label(lbl, KalyeStyle.Text.HEADER)
## Scenes should prefer `theme_type_variation` (see VARIATION_* names below).

const KalyeBoxScript = preload("res://scripts/ui/theme/KalyeBox.gd")
const FONT_PATH := "res://assets/fonts/LilitaOne-Regular.ttf"

# ── Palette ────────────────────────────────────────────────────────────────────
const INK := Color("#151229")
const NAVY := Color("#10164a")
const PANEL := Color("#2b3a8c")
const PANEL_LIP := Color("#1b2567")
const CARD := Color("#3b4fb5")
const CARD_LIP := Color("#26358a")
const CARD_HOVER := Color("#4a5fca")
const INSET := Color("#1a2266")
const INSET_EDGE := Color("#0f1546")
const RULE := Color("#5468d4")

const BLUE := Color("#3d8bff")
const BLUE_LIP := Color("#2357c9")
const BLUE_HI := Color("#5c9eff")
const YELLOW := Color("#ffcb2e")
const YELLOW_LIP := Color("#d98a0b")
const YELLOW_HI := Color("#ffd95c")
const GREEN := Color("#5bd13a")
const GREEN_LIP := Color("#2e9425")
const GREEN_HI := Color("#74e052")
const RED := Color("#ff4d5e")
const RED_LIP := Color("#b82234")
const RED_HI := Color("#ff6b79")
const PURPLE := Color("#8d5bff")
const PURPLE_LIP := Color("#5631c4")
const PURPLE_HI := Color("#a47aff")
const ORANGE := Color("#ff8a2b")
const ORANGE_LIP := Color("#c9541a")
const ORANGE_HI := Color("#ffa152")
const LIME := Color("#a4f03a")
const LIME_LIP := Color("#5fa81c")
const GREY := Color("#7e86a6")
const GREY_LIP := Color("#535a78")

const TEXT := Color("#ffffff")
const TEXT_SOFT := Color("#cbd6ff")
const TEXT_MUTED := Color("#8e9cd9")
const TEXT_ACCENT := Color("#ffd84a")
const TEXT_DANGER := Color("#ff7a86")
const TEXT_SAFE := Color("#8bf06a")
const TEXT_INFECT := Color("#b8ff4f")
const TEXT_INFO := Color("#7cc8ff")

const OVERLAY := Color(0.04, 0.05, 0.16, 0.72)

enum Kind { BLUE, PRIMARY, SUCCESS, DANGER, PURPLE, ORANGE, GHOST, TAB, ROUND }
enum Surface { PANEL, CARD, INSET, PILL, HUD, OVERLAY, BADGE_YELLOW, BADGE_RED, BADGE_GREEN, BADGE_BLUE, BADGE_PURPLE, BADGE_LIME, NONE }
enum Text { BODY, TITLE, HEADER, SMALL, MUTED, ACCENT, INK_ON_LIGHT, DANGER, SAFE }

# Theme type-variation names used by scenes.
const VARIATION_BUTTON := {
	Kind.BLUE: "", Kind.PRIMARY: "BtnPrimary", Kind.SUCCESS: "BtnSuccess", Kind.DANGER: "BtnDanger",
	Kind.PURPLE: "BtnPurple", Kind.ORANGE: "BtnOrange", Kind.GHOST: "BtnGhost", Kind.TAB: "BtnTab", Kind.ROUND: "BtnRound",
}
const VARIATION_PANEL := {
	Surface.PANEL: "", Surface.CARD: "PanelCard", Surface.INSET: "PanelInset", Surface.PILL: "PanelPill",
	Surface.HUD: "PanelHUD", Surface.OVERLAY: "PanelOverlay", Surface.BADGE_YELLOW: "BadgeYellow",
	Surface.BADGE_RED: "BadgeRed", Surface.BADGE_GREEN: "BadgeGreen", Surface.BADGE_BLUE: "BadgeBlue",
	Surface.BADGE_PURPLE: "BadgePurple", Surface.BADGE_LIME: "BadgeLime", Surface.NONE: "PanelNone",
}
const VARIATION_LABEL := {
	Text.BODY: "", Text.TITLE: "LabelTitle", Text.HEADER: "LabelHeader", Text.SMALL: "LabelSmall",
	Text.MUTED: "LabelMuted", Text.ACCENT: "LabelAccent", Text.INK_ON_LIGHT: "LabelInk",
	Text.DANGER: "LabelDanger", Text.SAFE: "LabelSafe",
}

# ── Box factories ─────────────────────────────────────────────────────────────

static func box(fill: Color, lip: Color, radius: int = 12, lip_h: int = 5, outline: int = 3, gloss: float = 0.0, drop: int = 0) -> StyleBox:
	var b: StyleBox = KalyeBoxScript.new()
	b.fill = fill
	b.lip = lip
	b.ink = INK
	b.radius = radius
	b.lip_height = lip_h
	b.outline = outline
	b.gloss = gloss
	b.drop = drop
	return b

static func _margins(sb: StyleBox, l: float, t: float, r: float, btm: float) -> StyleBox:
	sb.content_margin_left = l
	sb.content_margin_top = t
	sb.content_margin_right = r
	sb.content_margin_bottom = btm
	return sb

static func _button_colors(kind: int) -> Array:
	match kind:
		Kind.PRIMARY: return [YELLOW, YELLOW_LIP, YELLOW_HI]
		Kind.SUCCESS: return [GREEN, GREEN_LIP, GREEN_HI]
		Kind.DANGER: return [RED, RED_LIP, RED_HI]
		Kind.PURPLE: return [PURPLE, PURPLE_LIP, PURPLE_HI]
		Kind.ORANGE: return [ORANGE, ORANGE_LIP, ORANGE_HI]
		Kind.GHOST: return [INSET, INSET_EDGE, CARD_LIP]
		Kind.TAB: return [INSET, INSET_EDGE, CARD_LIP]
	return [BLUE, BLUE_LIP, BLUE_HI]

## Returns { normal, hover, pressed, disabled, focus } styleboxes for a button kind.
static func button_styles(kind: int = Kind.BLUE, radius: int = -1) -> Dictionary:
	var c: Array = _button_colors(kind)
	var r := radius if radius >= 0 else (28 if kind == Kind.ROUND else 14)
	var gloss := 0.0 if kind in [Kind.GHOST, Kind.TAB] else 0.16
	var lip_h := 6
	var pad_x := 18.0 if kind != Kind.ROUND else 8.0
	var normal := _margins(box(c[0], c[1], r, lip_h, 3, gloss, 3), pad_x, 9, pad_x, 9 + lip_h)
	var hover := _margins(box(c[2], c[1], r, lip_h, 3, gloss, 3), pad_x, 9, pad_x, 9 + lip_h)
	var pressed: StyleBox
	if kind == Kind.TAB:
		# Toggled tab = selected: becomes the yellow primary surface.
		pressed = _margins(box(YELLOW, YELLOW_LIP, r, lip_h, 3, 0.16, 3), pad_x, 9, pad_x, 9 + lip_h)
	else:
		pressed = _margins(box(c[0].darkened(0.06), c[1], r, 2, 3, gloss * 0.5, 1), pad_x, 13, pad_x, 9)
	var disabled := _margins(box(GREY, GREY_LIP, r, lip_h, 3, 0.0, 0), pad_x, 9, pad_x, 9 + lip_h)
	var focus := StyleBoxFlat.new()
	focus.draw_center = false
	focus.set_border_width_all(3)
	focus.border_color = Color(1, 1, 1, 0.9)
	focus.set_corner_radius_all(r + 3)
	focus.set_expand_margin_all(3)
	return { "normal": normal, "hover": hover, "pressed": pressed, "disabled": disabled, "focus": focus, "hover_pressed": pressed }

static func surface_style(surface: int) -> StyleBox:
	match surface:
		Surface.CARD:
			return _margins(box(CARD, CARD_LIP, 14, 4, 3), 14, 10, 14, 14)
		Surface.INSET:
			var s := StyleBoxFlat.new()
			s.bg_color = INSET
			s.border_width_top = 3
			s.border_color = INSET_EDGE
			s.set_corner_radius_all(12)
			s.anti_aliasing = true
			return _margins(s, 12, 10, 12, 10)
		Surface.PILL:
			return _margins(box(Color(NAVY, 0.92), INSET_EDGE, 99, 0, 3), 14, 5, 14, 6)
		Surface.HUD:
			return _margins(box(Color(NAVY, 0.84), INSET_EDGE, 14, 0, 3), 12, 6, 12, 7)
		Surface.OVERLAY:
			var o := StyleBoxFlat.new()
			o.bg_color = OVERLAY
			return o
		Surface.BADGE_YELLOW:
			return _margins(box(YELLOW, YELLOW_LIP, 10, 3, 3), 10, 3, 10, 6)
		Surface.BADGE_RED:
			return _margins(box(RED, RED_LIP, 10, 3, 3), 10, 3, 10, 6)
		Surface.BADGE_GREEN:
			return _margins(box(GREEN, GREEN_LIP, 10, 3, 3), 10, 3, 10, 6)
		Surface.BADGE_BLUE:
			return _margins(box(BLUE, BLUE_LIP, 10, 3, 3), 10, 3, 10, 6)
		Surface.BADGE_PURPLE:
			return _margins(box(PURPLE, PURPLE_LIP, 10, 3, 3), 10, 3, 10, 6)
		Surface.BADGE_LIME:
			return _margins(box(LIME, LIME_LIP, 10, 3, 3), 10, 3, 10, 6)
		Surface.NONE:
			return StyleBoxEmpty.new()
	return _margins(box(PANEL, PANEL_LIP, 20, 6, 3, 0.0, 5), 20, 16, 20, 20)

# ── Runtime helpers for script-built UI ───────────────────────────────────────

static func apply_button(btn: Button, kind: int = Kind.BLUE, font_size: int = -1) -> void:
	if btn == null:
		return
	var st := button_styles(kind)
	for k in st.keys():
		btn.add_theme_stylebox_override(k, st[k])
	btn.add_theme_color_override("font_color", TEXT)
	btn.add_theme_color_override("font_hover_color", TEXT)
	btn.add_theme_color_override("font_pressed_color", TEXT)
	btn.add_theme_color_override("font_hover_pressed_color", TEXT)
	btn.add_theme_color_override("font_focus_color", TEXT)
	btn.add_theme_color_override("font_disabled_color", Color(1, 1, 1, 0.75))
	btn.add_theme_color_override("font_outline_color", INK)
	btn.add_theme_constant_override("outline_size", 6)
	if font_size > 0:
		btn.add_theme_font_size_override("font_size", font_size)

static func apply_panel(ctrl: Control, surface: int = Surface.PANEL) -> void:
	if ctrl == null:
		return
	var key := "panel"
	ctrl.add_theme_stylebox_override(key, surface_style(surface))

static func apply_label(lbl: Control, text_kind: int = Text.BODY, font_size: int = -1) -> void:
	if lbl == null:
		return
	var spec := _label_spec(text_kind)
	lbl.add_theme_color_override("font_color", spec.color)
	lbl.add_theme_color_override("font_outline_color", INK)
	lbl.add_theme_constant_override("outline_size", spec.outline)
	lbl.add_theme_color_override("font_shadow_color", Color(INK, 0.9 if spec.outline > 0 else 0.0))
	lbl.add_theme_constant_override("shadow_offset_x", 0)
	lbl.add_theme_constant_override("shadow_offset_y", spec.shadow)
	lbl.add_theme_constant_override("shadow_outline_size", spec.outline)
	var fs: int = font_size if font_size > 0 else spec.size
	if fs > 0:
		lbl.add_theme_font_size_override("font_size", fs)

static func _label_spec(text_kind: int) -> Dictionary:
	match text_kind:
		Text.TITLE: return { "color": TEXT, "outline": 10, "shadow": 4, "size": 40 }
		Text.HEADER: return { "color": TEXT, "outline": 7, "shadow": 3, "size": 24 }
		Text.SMALL: return { "color": TEXT_SOFT, "outline": 4, "shadow": 2, "size": 14 }
		Text.MUTED: return { "color": TEXT_MUTED, "outline": 0, "shadow": 0, "size": 14 }
		Text.ACCENT: return { "color": TEXT_ACCENT, "outline": 6, "shadow": 2, "size": -1 }
		Text.INK_ON_LIGHT: return { "color": INK, "outline": 0, "shadow": 0, "size": -1 }
		Text.DANGER: return { "color": TEXT_DANGER, "outline": 6, "shadow": 2, "size": -1 }
		Text.SAFE: return { "color": TEXT_SAFE, "outline": 6, "shadow": 2, "size": -1 }
	return { "color": TEXT, "outline": 5, "shadow": 2, "size": -1 }

## Maps any legacy accent colour onto the nearest palette text colour.
static func remap_text_color(c: Color) -> Color:
	if c.a < 0.05:
		return c
	var lum := c.get_luminance()
	if c.s < 0.22:
		if lum < 0.35:
			return INK
		if lum > 0.8:
			return TEXT
		return TEXT_SOFT
	var h := c.h * 360.0
	if h < 18.0 or h >= 335.0:
		return TEXT_DANGER
	if h < 40.0:
		return ORANGE_HI
	if h < 68.0:
		return TEXT_ACCENT
	if h < 160.0:
		return TEXT_SAFE
	if h < 250.0:
		return TEXT_INFO
	return PURPLE_HI

# ── Procedural icons (embedded in the theme resource) ────────────────────────

static func _cover(d: float) -> float:
	return clampf(0.5 - d, 0.0, 1.0)

static func _rr_sdf(p: Vector2, center: Vector2, half: Vector2, r: float) -> float:
	var q := (p - center).abs() - half + Vector2(r, r)
	return Vector2(maxf(q.x, 0.0), maxf(q.y, 0.0)).length() + minf(maxf(q.x, q.y), 0.0) - r

static func _blend(dst: Color, src: Color, a: float) -> Color:
	var sa := src.a * a
	var oa := sa + dst.a * (1.0 - sa)
	if oa <= 0.0001:
		return Color(0, 0, 0, 0)
	var rgb := (Color(src.r, src.g, src.b) * sa + Color(dst.r, dst.g, dst.b) * dst.a * (1.0 - sa)) / oa
	return Color(rgb.r, rgb.g, rgb.b, oa)

static func make_knob(size: int, fill: Color, ring: int = 3) -> ImageTexture:
	var img := Image.create(size, size + 3, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var c := Vector2(size, size) * 0.5
	var rad := size * 0.5 - 1.0
	for y in img.get_height():
		for x in size:
			var p := Vector2(x + 0.5, y + 0.5)
			var col := Color(0, 0, 0, 0)
			col = _blend(col, Color(INK, 0.45), _cover((p - (c + Vector2(0, 3))).length() - rad))
			col = _blend(col, INK, _cover((p - c).length() - rad))
			col = _blend(col, fill, _cover((p - c).length() - (rad - ring)))
			col = _blend(col, Color(1, 1, 1, 0.35), _cover((p - (c - Vector2(0, rad * 0.35))).length() - rad * 0.38))
			img.set_pixel(x, y, col)
	return ImageTexture.create_from_image(img)

static func make_switch(on: bool, w: int = 56, h: int = 32) -> ImageTexture:
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var track_fill := GREEN if on else INSET
	var c := Vector2(w, h) * 0.5
	var half := Vector2(w, h) * 0.5 - Vector2(1, 1)
	var knob_r := h * 0.5 - 5.0
	var knob_c := Vector2(w - h * 0.5 - 1.0, h * 0.5) if on else Vector2(h * 0.5 + 1.0, h * 0.5)
	for y in h:
		for x in w:
			var p := Vector2(x + 0.5, y + 0.5)
			var col := Color(0, 0, 0, 0)
			col = _blend(col, INK, _cover(_rr_sdf(p, c, half, half.y)))
			col = _blend(col, track_fill, _cover(_rr_sdf(p, c, half - Vector2(3, 3), half.y - 3)))
			col = _blend(col, INK, _cover((p - knob_c).length() - (knob_r + 2.0)))
			col = _blend(col, TEXT, _cover((p - knob_c).length() - knob_r))
			img.set_pixel(x, y, col)
	return ImageTexture.create_from_image(img)

static func make_checkbox(on: bool, s: int = 28) -> ImageTexture:
	var img := Image.create(s, s, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var c := Vector2(s, s) * 0.5
	var half := Vector2(s, s) * 0.5 - Vector2(1, 1)
	for y in s:
		for x in s:
			var p := Vector2(x + 0.5, y + 0.5)
			var col := Color(0, 0, 0, 0)
			col = _blend(col, INK, _cover(_rr_sdf(p, c, half, 7)))
			col = _blend(col, GREEN if on else INSET, _cover(_rr_sdf(p, c, half - Vector2(3, 3), 5)))
			if on:
				# Tick: two segments.
				var d1 := _seg_dist(p, Vector2(s * 0.28, s * 0.52), Vector2(s * 0.44, s * 0.68))
				var d2 := _seg_dist(p, Vector2(s * 0.44, s * 0.68), Vector2(s * 0.74, s * 0.34))
				col = _blend(col, TEXT, _cover(minf(d1, d2) - 2.4))
			img.set_pixel(x, y, col)
	return ImageTexture.create_from_image(img)

static func _seg_dist(p: Vector2, a: Vector2, b: Vector2) -> float:
	var pa := p - a
	var ba := b - a
	var t := clampf(pa.dot(ba) / ba.dot(ba), 0.0, 1.0)
	return (pa - ba * t).length()

static func make_chevron_down(s: int = 20) -> ImageTexture:
	var img := Image.create(s, s, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var a := Vector2(s * 0.22, s * 0.36)
	var m := Vector2(s * 0.5, s * 0.66)
	var b := Vector2(s * 0.78, s * 0.36)
	for y in s:
		for x in s:
			var p := Vector2(x + 0.5, y + 0.5)
			var d := minf(_seg_dist(p, a, m), _seg_dist(p, m, b))
			var col := Color(0, 0, 0, 0)
			col = _blend(col, INK, _cover(d - 4.2))
			col = _blend(col, TEXT, _cover(d - 2.0))
			img.set_pixel(x, y, col)
	return ImageTexture.create_from_image(img)

# ── Theme builder ─────────────────────────────────────────────────────────────

static func build_theme() -> Theme:
	var t := Theme.new()
	var font: Font = load(FONT_PATH)
	t.default_font = font
	t.default_font_size = 18

	# Button family --------------------------------------------------------
	for kind in VARIATION_BUTTON.keys():
		var tname: String = VARIATION_BUTTON[kind]
		var type_name := "Button" if tname == "" else tname
		if tname != "":
			t.set_type_variation(tname, "Button")
		var st := button_styles(kind)
		for k in st.keys():
			t.set_stylebox(k, type_name, st[k])
		t.set_color("font_color", type_name, TEXT)
		t.set_color("font_hover_color", type_name, TEXT)
		t.set_color("font_pressed_color", type_name, TEXT)
		t.set_color("font_hover_pressed_color", type_name, TEXT)
		t.set_color("font_focus_color", type_name, TEXT)
		t.set_color("font_disabled_color", type_name, Color(1, 1, 1, 0.75))
		t.set_color("font_outline_color", type_name, INK)
		t.set_constant("outline_size", type_name, 6)
		t.set_constant("h_separation", type_name, 8)
		t.set_font_size("font_size", type_name, 20)
	t.set_color("font_color", "BtnTab", TEXT_SOFT)
	t.set_color("font_hover_color", "BtnTab", TEXT)

	# OptionButton / MenuButton inherit the blue button.
	var ob := button_styles(Kind.BLUE)
	for k in ob.keys():
		t.set_stylebox(k, "OptionButton", ob[k])
		t.set_stylebox(k, "MenuButton", ob[k])
	for tn in ["OptionButton", "MenuButton"]:
		t.set_color("font_color", tn, TEXT)
		t.set_color("font_hover_color", tn, TEXT)
		t.set_color("font_pressed_color", tn, TEXT)
		t.set_color("font_focus_color", tn, TEXT)
		t.set_color("font_outline_color", tn, INK)
		t.set_constant("outline_size", tn, 6)
		t.set_font_size("font_size", tn, 18)
	t.set_icon("arrow", "OptionButton", make_chevron_down())
	t.set_constant("arrow_margin", "OptionButton", 12)

	# CheckButton / CheckBox --------------------------------------------------
	var flat_row := StyleBoxEmpty.new()
	flat_row.content_margin_left = 4
	flat_row.content_margin_right = 4
	flat_row.content_margin_top = 6
	flat_row.content_margin_bottom = 6
	for tn in ["CheckButton", "CheckBox"]:
		for k in ["normal", "hover", "pressed", "hover_pressed", "disabled", "focus"]:
			t.set_stylebox(k, tn, flat_row)
		t.set_color("font_color", tn, TEXT)
		t.set_color("font_hover_color", tn, TEXT)
		t.set_color("font_pressed_color", tn, TEXT)
		t.set_color("font_hover_pressed_color", tn, TEXT)
		t.set_color("font_focus_color", tn, TEXT)
		t.set_color("font_outline_color", tn, INK)
		t.set_constant("outline_size", tn, 5)
		t.set_font_size("font_size", tn, 17)
		t.set_constant("h_separation", tn, 12)
	var sw_on := make_switch(true)
	var sw_off := make_switch(false)
	for k in ["checked", "checked_disabled"]:
		t.set_icon(k, "CheckButton", sw_on)
	for k in ["unchecked", "unchecked_disabled"]:
		t.set_icon(k, "CheckButton", sw_off)
	var cb_on := make_checkbox(true)
	var cb_off := make_checkbox(false)
	for k in ["checked", "checked_disabled", "radio_checked", "radio_checked_disabled"]:
		t.set_icon(k, "CheckBox", cb_on)
	for k in ["unchecked", "unchecked_disabled", "radio_unchecked", "radio_unchecked_disabled"]:
		t.set_icon(k, "CheckBox", cb_off)

	# Labels -------------------------------------------------------------------
	for text_kind in VARIATION_LABEL.keys():
		var vname: String = VARIATION_LABEL[text_kind]
		var tn := "Label" if vname == "" else vname
		if vname != "":
			t.set_type_variation(vname, "Label")
		var spec := _label_spec(text_kind)
		t.set_color("font_color", tn, spec.color)
		t.set_color("font_outline_color", tn, INK)
		t.set_constant("outline_size", tn, spec.outline)
		t.set_color("font_shadow_color", tn, Color(INK, 0.9 if spec.outline > 0 else 0.0))
		t.set_constant("shadow_offset_x", tn, 0)
		t.set_constant("shadow_offset_y", tn, spec.shadow)
		t.set_constant("shadow_outline_size", tn, spec.outline)
		t.set_constant("line_spacing", tn, 0)
		if spec.size > 0:
			t.set_font_size("font_size", tn, spec.size)
	t.set_font_size("font_size", "Label", 17)
	t.set_type_variation("LabelBadge", "Label")
	t.set_stylebox("normal", "LabelBadge", surface_style(Surface.PILL))
	t.set_font_size("font_size", "LabelBadge", 13)
	t.set_color("font_color", "LabelBadge", TEXT_ACCENT)
	t.set_constant("outline_size", "LabelBadge", 4)
	t.set_constant("shadow_offset_y", "LabelBadge", 0)
	t.set_color("font_outline_color", "LabelBadge", INK)

	t.set_color("default_color", "RichTextLabel", TEXT)
	t.set_color("font_outline_color", "RichTextLabel", INK)
	t.set_constant("outline_size", "RichTextLabel", 4)
	t.set_font_size("normal_font_size", "RichTextLabel", 17)
	t.set_font_size("bold_font_size", "RichTextLabel", 18)

	# Panels -------------------------------------------------------------------
	for surface in VARIATION_PANEL.keys():
		var pv: String = VARIATION_PANEL[surface]
		var sb := surface_style(surface)
		if pv == "":
			t.set_stylebox("panel", "PanelContainer", sb)
			t.set_stylebox("panel", "Panel", sb)
		else:
			t.set_type_variation(pv, "PanelContainer")
			t.set_stylebox("panel", pv, sb)
			var pv_panel := pv + "Panel"
			t.set_type_variation(pv_panel, "Panel")
			t.set_stylebox("panel", pv_panel, sb)

	# Inputs ------------------------------------------------------------------
	var le := surface_style(Surface.INSET).duplicate()
	le.content_margin_left = 14
	le.content_margin_right = 14
	le.content_margin_top = 10
	le.content_margin_bottom = 10
	var le_focus: StyleBoxFlat = le.duplicate()
	le_focus.set_border_width_all(3)
	le_focus.border_color = YELLOW
	t.set_stylebox("normal", "LineEdit", le)
	t.set_stylebox("focus", "LineEdit", le_focus)
	t.set_stylebox("read_only", "LineEdit", le)
	t.set_color("font_color", "LineEdit", TEXT)
	t.set_color("font_placeholder_color", "LineEdit", TEXT_MUTED)
	t.set_color("caret_color", "LineEdit", YELLOW)
	t.set_color("selection_color", "LineEdit", Color(BLUE, 0.6))
	t.set_color("font_outline_color", "LineEdit", INK)
	t.set_constant("outline_size", "LineEdit", 0)
	t.set_constant("caret_width", "LineEdit", 3)
	t.set_font_size("font_size", "LineEdit", 18)

	# Sliders --------------------------------------------------------------------
	var track := StyleBoxFlat.new()
	track.bg_color = INSET
	track.border_color = INK
	track.set_border_width_all(3)
	track.set_corner_radius_all(9)
	track.content_margin_top = 6
	track.content_margin_bottom = 6
	track.anti_aliasing = true
	var track_fill: StyleBoxFlat = track.duplicate()
	track_fill.bg_color = YELLOW
	t.set_stylebox("slider", "HSlider", track)
	t.set_stylebox("grabber_area", "HSlider", track_fill)
	t.set_stylebox("grabber_area_highlight", "HSlider", track_fill)
	t.set_icon("grabber", "HSlider", make_knob(28, TEXT))
	t.set_icon("grabber_highlight", "HSlider", make_knob(28, YELLOW_HI))
	t.set_icon("grabber_disabled", "HSlider", make_knob(28, GREY))
	t.set_icon("tick", "HSlider", ImageTexture.new())

	# Progress bars ----------------------------------------------------------
	var pb_bg := StyleBoxFlat.new()
	pb_bg.bg_color = INSET
	pb_bg.border_color = INK
	pb_bg.set_border_width_all(3)
	pb_bg.set_corner_radius_all(10)
	pb_bg.anti_aliasing = true
	t.set_stylebox("background", "ProgressBar", pb_bg)
	t.set_stylebox("fill", "ProgressBar", box(YELLOW, YELLOW_LIP, 10, 3, 3, 0.18))
	t.set_color("font_color", "ProgressBar", TEXT)
	t.set_color("font_outline_color", "ProgressBar", INK)
	t.set_constant("outline_size", "ProgressBar", 5)

	# Scrollbars ---------------------------------------------------------------
	var sb_track := StyleBoxFlat.new()
	sb_track.bg_color = Color(INSET_EDGE, 0.7)
	sb_track.set_corner_radius_all(6)
	sb_track.content_margin_left = 5
	sb_track.content_margin_right = 5
	sb_track.content_margin_top = 5
	sb_track.content_margin_bottom = 5
	var sb_grab := StyleBoxFlat.new()
	sb_grab.bg_color = YELLOW
	sb_grab.border_color = INK
	sb_grab.set_border_width_all(2)
	sb_grab.set_corner_radius_all(6)
	sb_grab.anti_aliasing = true
	var sb_grab_hi: StyleBoxFlat = sb_grab.duplicate()
	sb_grab_hi.bg_color = YELLOW_HI
	for tn in ["VScrollBar", "HScrollBar"]:
		t.set_stylebox("scroll", tn, sb_track)
		t.set_stylebox("scroll_focus", tn, sb_track)
		t.set_stylebox("grabber", tn, sb_grab)
		t.set_stylebox("grabber_highlight", tn, sb_grab_hi)
		t.set_stylebox("grabber_pressed", tn, sb_grab_hi)
	t.set_stylebox("panel", "ScrollContainer", StyleBoxEmpty.new())

	# Separators ---------------------------------------------------------------
	var line := StyleBoxLine.new()
	line.color = Color(RULE, 0.8)
	line.thickness = 2
	t.set_stylebox("separator", "HSeparator", line)
	t.set_constant("separation", "HSeparator", 10)
	var vline := StyleBoxLine.new()
	vline.color = Color(RULE, 0.8)
	vline.thickness = 2
	vline.vertical = true
	t.set_stylebox("separator", "VSeparator", vline)

	# Popups / tooltips --------------------------------------------------------
	t.set_stylebox("panel", "PopupMenu", _margins(box(PANEL, PANEL_LIP, 14, 4, 3), 8, 8, 8, 12))
	var hover_row := StyleBoxFlat.new()
	hover_row.bg_color = BLUE
	hover_row.set_corner_radius_all(8)
	t.set_stylebox("hover", "PopupMenu", hover_row)
	t.set_color("font_color", "PopupMenu", TEXT)
	t.set_color("font_hover_color", "PopupMenu", TEXT)
	t.set_color("font_outline_color", "PopupMenu", INK)
	t.set_constant("outline_size", "PopupMenu", 4)
	t.set_font_size("font_size", "PopupMenu", 18)
	t.set_constant("v_separation", "PopupMenu", 10)
	t.set_stylebox("panel", "TooltipPanel", _margins(box(NAVY, INSET_EDGE, 10, 0, 3), 10, 6, 10, 8))
	t.set_color("font_color", "TooltipLabel", TEXT)

	# Containers ----------------------------------------------------------------
	t.set_constant("separation", "VBoxContainer", 10)
	t.set_constant("separation", "HBoxContainer", 10)
	return t
