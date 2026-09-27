class_name MaibaTayaUI
extends Control

signal choice_made(choice: int)

@onready var chant_label: Label = $CenterContainer/VBoxContainer/ChantLabel
@onready var choice_container: HBoxContainer = $CenterContainer/VBoxContainer/ChoiceContainer
@onready var btn_palm_up: Button = $CenterContainer/VBoxContainer/ChoiceContainer/BtnPalmUp
@onready var btn_palm_down: Button = $CenterContainer/VBoxContainer/ChoiceContainer/BtnPalmDown
@onready var result_label: Label = $CenterContainer/VBoxContainer/ResultLabel

var selected_choice: int = -1

func _ready() -> void:
	visible = false
	choice_container.visible = false
	result_label.visible = false

	btn_palm_up.pressed.connect(func(): _choose(0))
	btn_palm_down.pressed.connect(func(): _choose(1))

func show_chant(text: String) -> void:
	visible = true
	result_label.visible = false
	chant_label.visible = true
	chant_label.text = text

func request_choice(_time_limit: float) -> void:
	selected_choice = -1
	choice_container.visible = true
	btn_palm_up.disabled = false
	btn_palm_down.disabled = false

func _choose(choice: int) -> void:
	selected_choice = choice
	btn_palm_up.disabled = true
	btn_palm_down.disabled = true
	choice_made.emit(choice)
	chant_label.text = "NAKAPILI KA NA! ⏳"

func show_result(taya_name: String, is_local_player_taya: bool) -> void:
	choice_container.visible = false
	chant_label.visible = false
	result_label.visible = true
	if is_local_player_taya:
		result_label.text = "🔥 IKAW ANG TAYA! HUMANDA SILA! 🔥"
		result_label.modulate = Color(1.0, 0.25, 0.2)
	else:
		result_label.text = "🏃 SI " + taya_name.to_upper() + " ANG TAYA! TAKBO NA! 💨"
		result_label.modulate = Color(0.2, 0.9, 0.3)

	# Hide after 3 seconds
	get_tree().create_timer(3.0).timeout.connect(func(): visible = false)
