@tool
class_name KalyeBox
extends StyleBox
## Chunky "pressable toy" stylebox used across the Batang Kalye UI.
##
## Layers (back to front), all vector so they stay crisp at any phone DPI:
##   1. optional drop shadow (ink, offset down)
##   2. ink outline (full rect, rounded)
##   3. lip — the darker underside that makes the surface feel pressable
##   4. body fill
##   5. optional gloss band across the top of the body
##
## Pressed buttons use a shorter lip and a larger top content margin so the label
## visibly sinks into the button.

@export var fill: Color = Color("#3d8bff")
@export var lip: Color = Color("#2357c9")
@export var ink: Color = Color("#151229")
@export_range(0, 12) var outline: int = 3
@export_range(0, 16) var lip_height: int = 5
@export_range(0, 64) var radius: int = 12
@export_range(0.0, 1.0) var gloss: float = 0.0
@export_range(0, 16) var drop: int = 0
@export_range(0.0, 1.0) var drop_alpha: float = 0.35

var _shadow_box: StyleBoxFlat
var _ink_box: StyleBoxFlat
var _lip_box: StyleBoxFlat
var _body_box: StyleBoxFlat
var _gloss_box: StyleBoxFlat
var _cached_params: Array = []

func _flat(color: Color, r: int) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = color
	s.set_corner_radius_all(maxi(r, 0))
	s.corner_detail = 8
	s.anti_aliasing = true
	s.anti_aliasing_size = 0.75
	return s

func _build() -> void:
	_shadow_box = _flat(Color(ink.r, ink.g, ink.b, ink.a * drop_alpha), radius)
	_ink_box = _flat(ink, radius)
	_lip_box = _flat(lip, radius - outline)
	_body_box = _flat(fill, radius - outline)
	_gloss_box = _flat(Color(1, 1, 1, gloss), maxi(radius - outline - 2, 0))
	_gloss_box.corner_radius_bottom_left = 4
	_gloss_box.corner_radius_bottom_right = 4

func _draw(to_canvas_item: RID, rect: Rect2) -> void:
	var current_params := [fill, lip, ink, outline, lip_height, radius, gloss, drop, drop_alpha]
	if _ink_box == null or _cached_params != current_params:
		_cached_params = current_params
		_build()
	if drop > 0 and drop_alpha > 0.0:
		_shadow_box.draw(to_canvas_item, Rect2(rect.position + Vector2(0, drop), rect.size))
	if outline > 0 and ink.a > 0.0:
		_ink_box.draw(to_canvas_item, rect)
	var inner := rect.grow(-outline)
	if inner.size.x <= 0.0 or inner.size.y <= 0.0:
		return
	if lip_height > 0:
		_lip_box.draw(to_canvas_item, inner)
	var body := Rect2(inner.position, Vector2(inner.size.x, maxf(inner.size.y - lip_height, 0.0)))
	_body_box.draw(to_canvas_item, body)
	if gloss > 0.0 and body.size.y > 10.0:
		var g := Rect2(body.position + Vector2(4, 3), Vector2(body.size.x - 8, body.size.y * 0.42))
		_gloss_box.draw(to_canvas_item, g)

func _get_draw_rect(rect: Rect2) -> Rect2:
	if drop > 0:
		return Rect2(rect.position, rect.size + Vector2(0, drop))
	return rect
