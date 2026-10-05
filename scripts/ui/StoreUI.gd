class_name StoreUI
extends Control

## StoreUI ("Tindahan ni Aling Nena")
## Manages in-game shop browsing, purchasing, and equipping of Pinoy cosmetics and titles.

signal closed()
signal item_equipped(category: String, item_id: Variant)

const EconomyManagerScript = preload("res://scripts/gameplay/EconomyManager.gd")

@export var economy_manager: Node = null

@onready var wallet_label: Label = get_node_or_null("%WalletLabel")
@onready var rep_label: Label = get_node_or_null("%RepLabel")
@onready var items_container: Container = get_node_or_null("%ItemsContainer")
@onready var tab_archetypes: Button = get_node_or_null("%TabArchetypes")
@onready var tab_headwear: Button = get_node_or_null("%TabHeadwear")
@onready var tab_body: Button = get_node_or_null("%TabBody")
@onready var tab_footwear: Button = get_node_or_null("%TabFootwear")
@onready var tab_titles: Button = get_node_or_null("%TabTitles")
@onready var close_btn: Button = get_node_or_null("%CloseButton")
@onready var aling_nena_dialogue: Label = get_node_or_null("%AlingNenaDialogue")

var current_category: String = "archetypes"
var game_manager_ref: Node = null

const NENA_QUOTES: Array[String] = [
	"\"Bawal ang utang dito sa Tindahan ni Aling Nena!\"",
	"\"Mag-ipon ka ng Barya mula sa pagtakbo at pag-segregate ng basura!\"",
	"\"Bagong tsinelas ba hanap mo? Matibay ang Spartan dito!\"",
	"\"Lakas ng Street Rep mo ah! Pwede ka na magsuot ng pang-Idol.\"",
	"\"Suotin mo 'yang towel cape para mukha kang superhero sa kalye!\""
]

func _ready() -> void:
	if not economy_manager:
		economy_manager = get_node_or_null("/root/Main/EconomyManager")
		if not economy_manager:
			# Fallback create instance if standalone
			economy_manager = EconomyManagerScript.new()
			add_child(economy_manager)
	
	if economy_manager:
		economy_manager.wallet_updated.connect(_on_wallet_updated)
		economy_manager.item_purchased.connect(_on_item_purchased)
	
	if close_btn:
		close_btn.pressed.connect(_on_close_pressed)
	
	if tab_archetypes: tab_archetypes.pressed.connect(func(): _switch_tab("archetypes"))
	if tab_headwear: tab_headwear.pressed.connect(func(): _switch_tab("headwear"))
	if tab_body: tab_body.pressed.connect(func(): _switch_tab("body"))
	if tab_footwear: tab_footwear.pressed.connect(func(): _switch_tab("footwear"))
	if tab_titles: tab_titles.pressed.connect(func(): _switch_tab("titles"))
	
	_update_wallet_ui()
	_switch_tab("archetypes")

func open_store() -> void:
	visible = true
	_update_wallet_ui()
	if aling_nena_dialogue:
		aling_nena_dialogue.text = NENA_QUOTES[randi() % NENA_QUOTES.size()]
	_refresh_items()

func close_store() -> void:
	visible = false
	closed.emit()

func _on_close_pressed() -> void:
	close_store()

func _on_wallet_updated(_barya: int, _rep: int) -> void:
	_update_wallet_ui()
	_refresh_items()

func _on_item_purchased(_cat: String, _id: Variant) -> void:
	if aling_nena_dialogue:
		aling_nena_dialogue.text = "\"Salamat sa pagbili! Bagay na bagay sa'yo 'yan, iho/iha!\""
	_update_wallet_ui()
	_refresh_items()

func _update_wallet_ui() -> void:
	if not economy_manager:
		return
	if wallet_label:
		wallet_label.text = "🪙 BARYA: %d" % economy_manager.barya
	if rep_label:
		rep_label.text = "⭐ STREET REP: %d" % economy_manager.street_rep

func _switch_tab(category: String) -> void:
	current_category = category
	
	# Update active button visuals
	if tab_archetypes: tab_archetypes.button_pressed = (category == "archetypes")
	if tab_headwear: tab_headwear.button_pressed = (category == "headwear")
	if tab_body: tab_body.button_pressed = (category == "body")
	if tab_footwear: tab_footwear.button_pressed = (category == "footwear")
	if tab_titles: tab_titles.button_pressed = (category == "titles")
	
	_refresh_items()

func _refresh_items() -> void:
	if not items_container or not economy_manager:
		return
	
	# Clear previous item cards
	for child in items_container.get_children():
		child.queue_free()
	
	var catalog_items: Array = EconomyManagerScript.CATALOG.get(current_category, [])
	var current_outfit: Dictionary = _get_current_outfit()
	
	for item_data in catalog_items:
		var card := _create_item_card(item_data, current_outfit)
		items_container.add_child(card)

func _get_current_outfit() -> Dictionary:
	var gm = get_node_or_null("/root/Main")
	if gm and "local_outfit" in gm:
		return gm.local_outfit
	var nm = get_node_or_null("/root/Main/NetworkManager")
	if nm and "local_outfit" in nm:
		return nm.local_outfit
	return {}

func _create_item_card(data: Dictionary, current_outfit: Dictionary) -> Control:
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(260, 140)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	card.add_child(vbox)
	
	# Item Name & Description
	var name_lbl := Label.new()
	name_lbl.text = str(data.get("name", "Item"))
	name_lbl.add_theme_font_size_override("font_size", 16)
	vbox.add_child(name_lbl)
	
	var desc_lbl := Label.new()
	desc_lbl.text = str(data.get("desc", ""))
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_lbl.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8, 0.85))
	desc_lbl.add_theme_font_size_override("font_size", 12)
	vbox.add_child(desc_lbl)
	
	# Price / Rep requirements
	var item_id = data.get("id")
	var cost: int = int(data.get("cost", 0))
	var req_rep: int = int(data.get("rep", 0))
	var is_owned: bool = economy_manager.is_unlocked(current_category, item_id)
	
	var cost_lbl := Label.new()
	if is_owned:
		cost_lbl.text = "✓ NABILI NA / LIBRE"
		cost_lbl.add_theme_color_override("font_color", Color(0.3, 0.9, 0.3))
	else:
		var cost_str := "🪙 %d Barya" % cost
		if req_rep > 0:
			cost_str += " | ⭐ Rep: %d" % req_rep
		cost_lbl.text = cost_str
		if economy_manager.can_afford(cost, req_rep):
			cost_lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
		else:
			cost_lbl.add_theme_color_override("font_color", Color(0.9, 0.4, 0.4))
	cost_lbl.add_theme_font_size_override("font_size", 12)
	vbox.add_child(cost_lbl)
	
	# Action button: Equip or Buy
	var action_btn := Button.new()
	action_btn.custom_minimum_size = Vector2(0, 36)
	
	var is_equipped: bool = _is_item_equipped(current_category, item_id, current_outfit)
	
	if is_owned:
		if is_equipped:
			action_btn.text = "✓ NAKASUOT"
			action_btn.disabled = true
		else:
			action_btn.text = "ISUOT"
			action_btn.pressed.connect(func(): _equip_item(current_category, item_id))
	else:
		if economy_manager.can_afford(cost, req_rep):
			action_btn.text = "BILIHIN"
			action_btn.pressed.connect(func(): _buy_item(current_category, item_id, cost, req_rep))
		else:
			action_btn.text = "KULANG BARYA/REP"
			action_btn.disabled = true
	
	vbox.add_child(action_btn)
	return card

func _is_item_equipped(category: String, item_id: Variant, outfit: Dictionary) -> bool:
	match category:
		"archetypes":
			return int(outfit.get("base", 0)) == int(item_id)
		"headwear":
			return int(outfit.get("headwear", 0)) == int(item_id)
		"body":
			return int(outfit.get("body", 0)) == int(item_id)
		"footwear":
			return int(outfit.get("footwear", 0)) == int(item_id)
		"titles":
			return economy_manager.equipped_title == str(item_id)
	return false

func _buy_item(category: String, item_id: Variant, cost: int, req_rep: int) -> void:
	if economy_manager.purchase_item(category, item_id, cost, req_rep):
		var am = get_node_or_null("/root/AudioManager")
		if am and am.has_method("play_score_ding"):
			am.play_score_ding()
		_refresh_items()

func _equip_item(category: String, item_id: Variant) -> void:
	if category == "titles":
		economy_manager.equip_title(str(item_id))
	
	item_equipped.emit(category, item_id)
	
	# Update GameManager if available
	var gm = get_node_or_null("/root/Main")
	if gm and gm.has_method("apply_store_equip"):
		gm.apply_store_equip(category, item_id)
	
	_refresh_items()
