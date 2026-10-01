class_name MaibaTayaUI
extends Control

signal choice_made(choice: int)

@onready var chant_label: Label = (get_node_or_null("CenterContainer/Panel/Margin/VBoxContainer/ChantLabel") as Label) if get_node_or_null("CenterContainer/Panel/Margin/VBoxContainer/ChantLabel") else (get_node_or_null("CenterContainer/VBoxContainer/ChantLabel") as Label)
@onready var choice_container: HBoxContainer = (get_node_or_null("CenterContainer/Panel/Margin/VBoxContainer/ChoiceContainer") as HBoxContainer) if get_node_or_null("CenterContainer/Panel/Margin/VBoxContainer/ChoiceContainer") else (get_node_or_null("CenterContainer/VBoxContainer/ChoiceContainer") as HBoxContainer)
@onready var btn_palm_up: Button = (get_node_or_null("CenterContainer/Panel/Margin/VBoxContainer/ChoiceContainer/BtnPalmUp") as Button) if get_node_or_null("CenterContainer/Panel/Margin/VBoxContainer/ChoiceContainer/BtnPalmUp") else (get_node_or_null("CenterContainer/VBoxContainer/ChoiceContainer/BtnPalmUp") as Button)
@onready var btn_palm_down: Button = (get_node_or_null("CenterContainer/Panel/Margin/VBoxContainer/ChoiceContainer/BtnPalmDown") as Button) if get_node_or_null("CenterContainer/Panel/Margin/VBoxContainer/ChoiceContainer/BtnPalmDown") else (get_node_or_null("CenterContainer/VBoxContainer/ChoiceContainer/BtnPalmDown") as Button)
@onready var result_label: Label = (get_node_or_null("CenterContainer/Panel/Margin/VBoxContainer/ResultLabel") as Label) if get_node_or_null("CenterContainer/Panel/Margin/VBoxContainer/ResultLabel") else (get_node_or_null("CenterContainer/VBoxContainer/ResultLabel") as Label)
@onready var panel: PanelContainer = get_node_or_null("CenterContainer/Panel")

var selected_choice: int = -1

func _ready() -> void:
	visible = false
	if choice_container:
		choice_container.visible = false
	if result_label:
		result_label.visible = false

	if btn_palm_up:
		btn_palm_up.pressed.connect(func(): _choose(0))
	if btn_palm_down:
		btn_palm_down.pressed.connect(func(): _choose(1))

func show_chant(text: String) -> void:
	visible = true
	if result_label:
		result_label.visible = false
	if chant_label:
		chant_label.visible = true
		chant_label.text = text
		chant_label.pivot_offset = chant_label.size * 0.5
		var t := create_tween()
		t.tween_property(chant_label, "scale", Vector2(1.2, 1.2), 0.1).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		t.tween_property(chant_label, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)

func request_choice(_time_limit: float) -> void:
	selected_choice = -1
	if choice_container:
		choice_container.visible = true
		choice_container.scale = Vector2(0.85, 0.85)
		choice_container.pivot_offset = choice_container.size * 0.5
		var t := create_tween()
		t.tween_property(choice_container, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	if btn_palm_up:
		btn_palm_up.disabled = false
	if btn_palm_down:
		btn_palm_down.disabled = false

func _choose(choice: int) -> void:
	selected_choice = choice
	if btn_palm_up:
		btn_palm_up.disabled = true
	if btn_palm_down:
		btn_palm_down.disabled = true
	choice_made.emit(choice)
	if chant_label:
		chant_label.text = "NAKAPILI KA NA! ⏳"

func show_result(taya_name: String, is_local_player_taya: bool) -> void:
	if choice_container:
		choice_container.visible = false
	if chant_label:
		chant_label.visible = false
	if result_label:
		result_label.visible = true
		result_label.pivot_offset = result_label.size * 0.5
		var t := create_tween()
		t.tween_property(result_label, "scale", Vector2(1.25, 1.25), 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		t.tween_property(result_label, "scale", Vector2.ONE, 0.18)

		if is_local_player_taya:
			result_label.text = "🔥 IKAW ANG TAYA! HUMANDA SILA! 🔥"
			result_label.modulate = Color(1.0, 0.3, 0.2)
		else:
			result_label.text = "🏃 SI " + taya_name.to_upper() + " ANG TAYA! TAKBO NA! 💨"
			result_label.modulate = Color(0.2, 0.95, 0.45)

	# Hide after 3 seconds
	get_tree().create_timer(3.0).timeout.connect(func(): visible = false)
