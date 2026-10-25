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
@onready var close_btn: BaseButton = get_node_or_null("%CloseButton")
@onready var aling_nena_dialogue: Label = get_node_or_null("%AlingNenaDialogue")
@onready var preview_world: Node3D = get_node_or_null("%PreviewWorld")

const CharacterModelScene = preload("res://scenes/player/CharacterModel.tscn")

var current_category: String = "archetypes"
var game_manager_ref: Node = null
var preview_model: Node3D = null
var preview_outfit_state: Dictionary = {}

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
	
	_apply_sari_sari_theme()
	_setup_store_3d_preview()
	_update_wallet_ui()
	_switch_tab("archetypes")

func _process(delta: float) -> void:
	if visible and preview_model and is_instance_valid(preview_model):
		preview_model.rotate_y(delta * 0.9)
		if preview_model.has_method("animate"):
			preview_model.animate(delta, 0.0, true, 7.0)

func _apply_sari_sari_theme() -> void:
	var panel := get_node_or_null("CenterContainer/PanelContainer") as PanelContainer
	if panel:
		panel.custom_minimum_size = Vector2(980, 580)
		KalyeStyle.apply_panel(panel, KalyeStyle.Surface.PANEL)

func _setup_store_3d_preview() -> void:
	if preview_world:
		if CharacterModelScene:
			preview_model = CharacterModelScene.instantiate() as Node3D
			preview_model.rotation.y = PI
			preview_world.add_child(preview_model)
		return

	var main_vbox := get_node_or_null("CenterContainer/PanelContainer/MarginContainer/VBoxContainer") as VBoxContainer
	var scroll := get_node_or_null("CenterContainer/PanelContainer/MarginContainer/VBoxContainer/ScrollContainer") as ScrollContainer
	if not main_vbox or not scroll or main_vbox.has_node("StoreBodyHBox"):
		return

	var body_hbox := HBoxContainer.new()
	body_hbox.name = "StoreBodyHBox"
	body_hbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body_hbox.add_theme_constant_override("separation", 14)

	var scroll_idx := scroll.get_index()
	main_vbox.remove_child(scroll)
	main_vbox.add_child(body_hbox)
	main_vbox.move_child(body_hbox, scroll_idx)

	# Left 3D Turntable Preview Card
	var preview_card := PanelContainer.new()
	preview_card.name = "Preview3DCard"
	preview_card.custom_minimum_size = Vector2(235, 360)
	KalyeStyle.apply_panel(preview_card, KalyeStyle.Surface.CARD)

	var p_vbox := VBoxContainer.new()
	p_vbox.add_theme_constant_override("separation", 6)
	preview_card.add_child(p_vbox)

	var p_title := Label.new()
	p_title.text = "SALAMIN SA TINDAHAN"
	p_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	KalyeStyle.apply_label(p_title, KalyeStyle.Text.ACCENT, 13)
	p_vbox.add_child(p_title)

	var sub_vc := SubViewportContainer.new()
	sub_vc.stretch = true
	sub_vc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sub_vc.custom_minimum_size = Vector2(215, 295)
	p_vbox.add_child(sub_vc)

	var sub_vp := SubViewport.new()
	sub_vp.own_world_3d = true
	sub_vp.transparent_bg = true
	sub_vp.size = Vector2i(240, 320)
	sub_vp.render_target_update_mode = SubViewport.UPDATE_WHEN_VISIBLE
	sub_vc.add_child(sub_vp)

	var root_3d := Node3D.new()
	sub_vp.add_child(root_3d)

	var key_light := DirectionalLight3D.new()
	key_light.rotation_degrees = Vector3(-35, 35, 0)
	key_light.light_color = Color(1.0, 0.94, 0.84)
	key_light.light_energy = 1.4
	root_3d.add_child(key_light)

	var fill_light := OmniLight3D.new()
	fill_light.position = Vector3(-1.5, 1.6, 2.0)
	fill_light.light_color = Color(0.75, 0.85, 1.0)
	fill_light.light_energy = 0.8
	root_3d.add_child(fill_light)

	var cam := Camera3D.new()
	cam.position = Vector3(0.0, 1.02, 3.15)
	cam.rotation_degrees = Vector3(-2.0, 0.0, 0.0)
	cam.fov = 44.0
	root_3d.add_child(cam)

	if CharacterModelScene:
		preview_model = CharacterModelScene.instantiate() as Node3D
		preview_model.rotation.y = PI
		root_3d.add_child(preview_model)

	body_hbox.add_child(preview_card)

	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if items_container and items_container is GridContainer:
		(items_container as GridContainer).columns = 2
	body_hbox.add_child(scroll)

func _sync_preview_to_outfit(outfit_dict: Dictionary) -> void:
	preview_outfit_state = outfit_dict.duplicate()
	if preview_model and is_instance_valid(preview_model):
		if preview_model.has_method("apply_outfit_dict") and not preview_outfit_state.is_empty():
			preview_model.apply_outfit_dict(preview_outfit_state)
		elif preview_model.has_method("apply_preset"):
			preview_model.apply_preset(int(preview_outfit_state.get("archetype", 2)))

func _preview_catalog_item(category: String, item_id: Variant) -> void:
	if preview_outfit_state.is_empty():
		preview_outfit_state = _get_current_outfit().duplicate()
	match category:
		"archetypes":
			if preview_model and preview_model.has_method("apply_preset"):
				preview_model.apply_preset(int(item_id))
				if preview_model.has_method("get_outfit_data"):
					preview_outfit_state = preview_model.get_outfit_data()
			return
		"headwear":
			preview_outfit_state["headwear"] = int(item_id)
		"body":
			preview_outfit_state["body"] = int(item_id)
		"footwear":
			preview_outfit_state["footwear"] = int(item_id)
	_sync_preview_to_outfit(preview_outfit_state)

func open_store() -> void:
	visible = true
	_update_wallet_ui()
	_sync_preview_to_outfit(_get_current_outfit())
	if aling_nena_dialogue:
		aling_nena_dialogue.text = NENA_QUOTES[randi() % NENA_QUOTES.size()]
	_refresh_items()

func close_store() -> void:
	visible = false
	closed.emit()

func _on_close_pressed() -> void:
	var am = get_node_or_null("/root/AudioManager")
	if am and am.has_method("play_ui_cancel"):
		am.play_ui_cancel()
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
		wallet_label.text = "%d" % economy_manager.barya
	if rep_label:
		rep_label.text = "REP: %d" % economy_manager.street_rep

func _switch_tab(category: String) -> void:
	current_category = category
	var am = get_node_or_null("/root/AudioManager")
	if am and am.has_method("play_ui_click"):
		am.play_ui_click()
	
	# Update active button visuals & text color indicator based on awning tab backgrounds
	var tab_configs := {
		"archetypes": {"btn": tab_archetypes, "sel_col": Color(0.12, 0.1, 0.18, 1.0), "unsel_col": Color(0.42, 0.35, 0.15, 0.7)},
		"headwear": {"btn": tab_headwear, "sel_col": Color(1.0, 1.0, 1.0, 1.0), "unsel_col": Color(0.65, 0.95, 0.9, 0.6)},
		"body": {"btn": tab_body, "sel_col": Color(1.0, 1.0, 1.0, 1.0), "unsel_col": Color(1.0, 0.8, 0.8, 0.6)},
		"footwear": {"btn": tab_footwear, "sel_col": Color(1.0, 1.0, 1.0, 1.0), "unsel_col": Color(0.8, 0.9, 1.0, 0.6)},
		"titles": {"btn": tab_titles, "sel_col": Color(0.12, 0.1, 0.18, 1.0), "unsel_col": Color(0.4, 0.4, 0.5, 0.7)},
	}
	for cat in tab_configs.keys():
		var cfg = tab_configs[cat]
		var btn: Button = cfg["btn"]
		if btn:
			var is_active: bool = (cat == category)
			btn.button_pressed = is_active
			var col: Color = cfg["sel_col"] if is_active else cfg["unsel_col"]
			btn.add_theme_color_override("font_color", col)
			btn.add_theme_color_override("font_focus_color", col)
			btn.add_theme_color_override("font_hover_color", col)
			btn.add_theme_color_override("font_pressed_color", col)
			btn.add_theme_font_size_override("font_size", 15 if is_active else 14)
			btn.add_theme_constant_override("outline_size", 0)
	
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
	if gm and gm.has_method("_get_current_outfit_dict"):
		return gm._get_current_outfit_dict()
	if gm and "local_outfit" in gm:
		return gm.local_outfit
	var nm = get_node_or_null("/root/Main/NetworkManager")
	if nm and "local_outfit" in nm:
		return nm.local_outfit
	return {}

func _style_warm_button(btn: Button, bg: Color, border: Color, font_col: Color, font_sz: int = 13) -> void:
	var sb_normal := StyleBoxFlat.new()
	sb_normal.bg_color = bg
	sb_normal.border_color = border
	sb_normal.border_width_left = 2
	sb_normal.border_width_top = 2
	sb_normal.border_width_right = 2
	sb_normal.border_width_bottom = 4
	sb_normal.corner_radius_top_left = 8
	sb_normal.corner_radius_top_right = 8
	sb_normal.corner_radius_bottom_right = 8
	sb_normal.corner_radius_bottom_left = 8
	sb_normal.content_margin_left = 10.0
	sb_normal.content_margin_right = 10.0
	sb_normal.content_margin_top = 4.0
	sb_normal.content_margin_bottom = 6.0

	var sb_hover := sb_normal.duplicate() as StyleBoxFlat
	sb_hover.bg_color = bg.lightened(0.12)

	var sb_pressed := sb_normal.duplicate() as StyleBoxFlat
	sb_pressed.bg_color = bg.darkened(0.12)
	sb_pressed.border_width_bottom = 2

	var sb_disabled := sb_normal.duplicate() as StyleBoxFlat
	sb_disabled.bg_color = bg.darkened(0.35)
	sb_disabled.border_color = border.darkened(0.2)

	btn.add_theme_stylebox_override("normal", sb_normal)
	btn.add_theme_stylebox_override("hover", sb_hover)
	btn.add_theme_stylebox_override("pressed", sb_pressed)
	btn.add_theme_stylebox_override("disabled", sb_disabled)
	btn.add_theme_color_override("font_color", font_col)
	btn.add_theme_color_override("font_hover_color", font_col)
	btn.add_theme_color_override("font_focus_color", font_col)
	btn.add_theme_color_override("font_disabled_color", font_col.darkened(0.3))
	btn.add_theme_font_size_override("font_size", font_sz)
	btn.add_theme_constant_override("outline_size", 0)

func _create_item_card(data: Dictionary, current_outfit: Dictionary) -> Control:
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(260, 152)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var item_id = data.get("id")
	var cost: int = int(data.get("cost", 0))
	var req_rep: int = int(data.get("rep", 0))
	var is_owned: bool = economy_manager.is_unlocked(current_category, item_id)
	var is_equipped: bool = _is_item_equipped(current_category, item_id, current_outfit)

	var card_box := StyleBoxFlat.new()
	card_box.bg_color = Color("#322014") if is_equipped else Color("#22150d")
	card_box.border_color = Color("#e59b24") if is_equipped else Color("#452e1d")
	card_box.border_width_left = 2
	card_box.border_width_top = 2
	card_box.border_width_right = 2
	card_box.border_width_bottom = 4
	card_box.corner_radius_top_left = 12
	card_box.corner_radius_top_right = 12
	card_box.corner_radius_bottom_right = 12
	card_box.corner_radius_bottom_left = 12
	card_box.content_margin_left = 12.0
	card_box.content_margin_right = 12.0
	card_box.content_margin_top = 10.0
	card_box.content_margin_bottom = 12.0
	card.add_theme_stylebox_override("panel", card_box)
	
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	card.add_child(vbox)
	
	# Item Name & Description
	var name_lbl := Label.new()
	name_lbl.text = str(data.get("name", "Item"))
	name_lbl.add_theme_color_override("font_color", Color("#fff1db"))
	name_lbl.add_theme_font_size_override("font_size", 16)
	name_lbl.add_theme_constant_override("outline_size", 0)
	vbox.add_child(name_lbl)
	
	var desc_lbl := Label.new()
	desc_lbl.text = str(data.get("desc", ""))
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_lbl.add_theme_color_override("font_color", Color("#d4bfa5"))
	desc_lbl.add_theme_font_size_override("font_size", 12)
	desc_lbl.add_theme_constant_override("outline_size", 0)
	vbox.add_child(desc_lbl)
	
	# Price / Rep requirements
	var cost_lbl := Label.new()
	cost_lbl.add_theme_constant_override("outline_size", 0)
	cost_lbl.add_theme_font_size_override("font_size", 12)
	if is_owned:
		cost_lbl.text = "✓ NABILI NA / LIBRE"
		cost_lbl.add_theme_color_override("font_color", Color("#dfc79b"))
	else:
		var cost_str := "🪙 %d Barya" % cost
		if req_rep > 0:
			cost_str += " | ⭐ Rep: %d" % req_rep
		cost_lbl.text = cost_str
		if economy_manager.can_afford(cost, req_rep):
			cost_lbl.add_theme_color_override("font_color", Color("#ffcc33"))
		else:
			cost_lbl.add_theme_color_override("font_color", Color("#e0684f"))
	vbox.add_child(cost_lbl)
	
	# Action row: Preview + Equip/Buy
	var btn_row := HBoxContainer.new()
	btn_row.add_theme_constant_override("separation", 6)
	vbox.add_child(btn_row)

	if current_category != "titles":
		var prev_btn := Button.new()
		prev_btn.text = "TINGNAN"
		prev_btn.custom_minimum_size = Vector2(82, 38)
		_style_warm_button(prev_btn, Color("#422e20"), Color("#24160c"), Color("#f5e6d3"), 12)
		prev_btn.pressed.connect(func(): _preview_catalog_item(current_category, item_id))
		btn_row.add_child(prev_btn)

	var action_btn := Button.new()
	action_btn.custom_minimum_size = Vector2(0, 38)
	action_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	if is_owned:
		if is_equipped:
			action_btn.text = "✓ NAKASUOT"
			action_btn.disabled = true
			_style_warm_button(action_btn, Color("#4a3627"), Color("#26190e"), Color("#b8a28d"), 12)
		else:
			action_btn.text = "ISUOT"
			_style_warm_button(action_btn, Color("#d99221"), Color("#3d2204"), Color("#211303"), 13)
			action_btn.pressed.connect(func(): _equip_item(current_category, item_id))
	else:
		if economy_manager.can_afford(cost, req_rep):
			action_btn.text = "BILIHIN"
			_style_warm_button(action_btn, Color("#c4651b"), Color("#3d1c04"), Color("#ffffff"), 13)
			action_btn.pressed.connect(func(): _buy_item(current_category, item_id, cost, req_rep))
		else:
			action_btn.text = "KULANG BARYA/REP"
			action_btn.disabled = true
			_style_warm_button(action_btn, Color("#36271c"), Color("#21160d"), Color("#826d5c"), 11)
	
	btn_row.add_child(action_btn)
	return card

func _is_item_equipped(category: String, item_id: Variant, outfit: Dictionary) -> bool:
	match category:
		"archetypes":
			return int(outfit.get("archetype", outfit.get("base", 0))) == int(item_id)
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
		if am and am.has_method("play_ui_reward"):
			am.play_ui_reward()
		elif am and am.has_method("play_score_ding"):
			am.play_score_ding()
		_preview_catalog_item(category, item_id)
		_refresh_items()

func _equip_item(category: String, item_id: Variant) -> void:
	var am = get_node_or_null("/root/AudioManager")
	if am and am.has_method("play_ui_pop"):
		am.play_ui_pop()
	if category == "titles":
		economy_manager.equip_title(str(item_id))
	
	item_equipped.emit(category, item_id)
	
	# Update GameManager if available
	var gm = get_node_or_null("/root/Main")
	if gm and gm.has_method("apply_store_equip"):
		gm.apply_store_equip(category, item_id)
	
	_sync_preview_to_outfit(_get_current_outfit())
	_refresh_items()
