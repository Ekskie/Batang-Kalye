class_name UwianNaUI
extends Control

signal cancelled
signal confirmed

@onready var modal_container: Control = $CenterContainer/VBoxContainer
@onready var btn_no: TextureButton = $CenterContainer/VBoxContainer/ButtonsRow/BtnNo
@onready var btn_yes: TextureButton = $CenterContainer/VBoxContainer/ButtonsRow/BtnYes

func _ensure_references() -> void:
	if not modal_container: modal_container = get_node_or_null("CenterContainer/VBoxContainer")
	if not btn_no: btn_no = get_node_or_null("CenterContainer/VBoxContainer/ButtonsRow/BtnNo")
	if not btn_yes: btn_yes = get_node_or_null("CenterContainer/VBoxContainer/ButtonsRow/BtnYes")

func _ready() -> void:
	_ensure_references()
	visible = false
	if btn_no and not btn_no.pressed.is_connected(_on_btn_no_pressed):
		btn_no.pressed.connect(_on_btn_no_pressed)
	if btn_yes and not btn_yes.pressed.is_connected(_on_btn_yes_pressed):
		btn_yes.pressed.connect(_on_btn_yes_pressed)

func open() -> void:
	_ensure_references()
	visible = true
	var am = get_node_or_null("/root/AudioManager") if is_inside_tree() else null
	if am and am.has_method("play_ui_pop"):
		am.play_ui_pop()
	if modal_container:
		modal_container.pivot_offset = modal_container.size * 0.5
		modal_container.scale = Vector2(0.85, 0.85)
		var t = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		t.tween_property(modal_container, "scale", Vector2.ONE, 0.22)

func close() -> void:
	print("UwianNaUI.close() called!")
	cancelled.emit()
	var am = get_node_or_null("/root/AudioManager") if is_inside_tree() else null
	if am and am.has_method("play_ui_cancel"):
		am.play_ui_cancel()
	if modal_container and is_inside_tree():
		var t = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		t.tween_property(modal_container, "scale", Vector2(0.85, 0.85), 0.15)
		t.tween_callback(func():
			visible = false
		)
	else:
		visible = false

func _on_btn_no_pressed() -> void:
	close()

func _on_btn_yes_pressed() -> void:
	var am = get_node_or_null("/root/AudioManager")
	if am and am.has_method("play_ui_click"):
		am.play_ui_click()
	confirmed.emit()
	var sm = get_node_or_null("/root/SupabaseLobbyManager")
	if not sm:
		var root = get_tree().root if get_tree() else null
		if root:
			sm = root.find_child("SupabaseLobbyManager", true, false)
	if sm and sm.has_method("delete_lobby") and sm.get("is_hosting_lobby"):
		sm.delete_lobby()
	get_tree().quit()
