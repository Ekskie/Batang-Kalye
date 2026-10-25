class_name QuickGuideUI
extends Control

## QuickGuideUI
## Interactive open notebook tutorial and onboarding guide for Batang Kalye.
## Displays content directly on Gabay_Background_v2.png with two-page spread,
## 4 edge colored category tabs, and selection text color indicators.

signal closed()

@onready var tab_maiba: Button = get_node_or_null("%TabMaiba")
@onready var tab_stamina: Button = get_node_or_null("%TabStamina")
@onready var tab_items: Button = get_node_or_null("%TabItems")
@onready var tab_modes: Button = get_node_or_null("%TabModes")

@onready var title_label: Label = get_node_or_null("%GuideTitle")
@onready var subtitle_label: Label = get_node_or_null("%GuideSubtitle")
@onready var body_label: RichTextLabel = get_node_or_null("%GuideBody")
@onready var right_body_label: RichTextLabel = get_node_or_null("%GuideRightBody")
@onready var tip_label: Label = get_node_or_null("%GuideTip")
@onready var close_btn: BaseButton = get_node_or_null("%CloseButton")
@onready var next_btn: Button = get_node_or_null("%NextButton")
@onready var prev_btn: Button = get_node_or_null("%PrevButton")

const SAVE_SEEN_PATH: String = "user://has_seen_quick_guide"

var current_tab_idx: int = 0

const TABS_DATA: Array[Dictionary] = [
	{
		"title": "MAIBA TAYA",
		"subtitle": "Ang tradisyonal na ritwal bago magsimula ang laro sa kalye.",
		"left_body": "[b]Paano Magsimula:[/b]\nBago sumabak sa takbuhan, lahat ng bata ay sabay-sabay na magcha-chant ng:\n[color=#8a4b08][b]\"Ma-i-ba... TAYA!\"[/b][/color]\n\nPiliin ang iyong kamay:\n• [b]Puti / Ibabaw[/b] (Palm UP)\n• [b]Itim / Ilalim[/b] (Palm DOWN)\n\nKung sino ang [color=#9c3d18][b]naiba ang kulay[/b][/color] sa karamihan, siya ang magiging unang [b]TAYA[/b] (Chaser)!\n\nSa malalaking laban (16–24 kalaro), minority gesture group ang magiging Taya.",
		"right_body": "[b]Tungkulin ng Taya:[/b]\n• May pulang aura at bilis-takbo.\n• Habulin ang mga Runner at gamitin ang [b]Hampas (Tag)[/b] button upang ipasa ang pagka-taya.\n\n[b]Tungkulin ng Runner:[/b]\n• Gamitin ang kanto, pader, at bubong para tumakas.\n• Mag-slide sa ilalim ng harang at maghagis ng tsinelas!",
		"tip": "💡 TIP NI KAP: Huwag tatayo sa gitna ng kalsada—gamitin ang mga eskinita para magtago!"
	},
	{
		"title": "DUAL STAMINA AT BILIS",
		"subtitle": "Kombinasyon ng bilis at tibay para hindi abutan ng hingal.",
		"left_body": "[b]1. Burst Sprint (Bilis-Bwelo):[/b]\nPindutin ang Takbo/Karipas button para sa mabilis na bwelo. Mabilis itong mauubos, pero agad babalik kapag naglakad o huminto.\n\n[b]2. Long-term Endurance (Resistensya):[/b]\nHuwag abusuhin ang sprint! Kapag naubos ang endurance, aabutin ka ng [color=#9c3d18][b]Hingal (Exhaustion)[/b][/color] at iika-ika kang maglalakad hanggang makabawi.",
		"right_body": "[b]3. Dulas (Slide):[/b]\nPindutin ang Dulas habang tumatakbo upang lumusot sa ilalim ng mga harang at umiwas sa tag slap!\n\n[b]4. Talon at Akyat:[/b]\nTalon sa ere para umakyat sa crates, barrels, at bubong para maging ligtas sa lupa.",
		"tip": "💡 TIP NI KAP: I-reserve ang iyong sprint kapag malapit na ang Taya; huwag aksayahin sa malayo!"
	},
	{
		"title": "MGA GAMIT SA KALYE",
		"subtitle": "Magpulot ng gamit sa aspalto para protektahan ang sarili.",
		"left_body": "[b]Mga Kagamitang Mapupulot:[/b]\n\n• [color=#8a4b08][b]Spartan Tsinelas:[/b][/color]\nIhagis sa kalaban para sampalin sa malayo at i-stun ang humahabol!\n\n• [color=#8a4b08][b]Balat ng Saging:[/b][/color]\nIlatag sa kalsada. Madudulas ang sinumang makatapak at babagal ang takbo.\n\n• [color=#8a4b08][b]Supot ng Chalk:[/b][/color]\nLumilikha ng usok na tatakip sa paningin ng humahabol.",
		"right_body": "• [color=#8a4b08][b]Asul na Drum:[/b][/color]\nPumasok sa loob para magtago nang tahimik hanggang 8 segundo.\n\n• [color=#8a4b08][b]Pito ng Barangay:[/b][/color]\nHipan ang pito para ma-stun ang Taya at ilantad ang markers.\n\n[b]Paano Gamitin:[/b]\nLumapit sa item at pindutin ang [b]Pulot[/b]. Pindutin ang [b]Tapon[/b] upang gamitin o ihagis.",
		"tip": "💡 TIP NI KAP: Pwede mong palitan ang gamit anumang oras sa pamamagitan ng pagpulot ng bago!"
	},
	{
		"title": "BASURA AT MODES",
		"subtitle": "Mag-linis ng kalye at piliin ang iyong paboritong laro.",
		"left_body": "[b]Waste Segregation para sa Powerup:[/b]\nMagpulot ng kalat sa kalsada at ilagay sa tamang basurahan:\n• [b]Biodegradable (Nabubulok)[/b]\n• [b]Non-Biodegradable (Di-nabubulok)[/b]\n• [b]Recyclable (Muling Magagamit)[/b]\n\nMakakakuha ka ng [color=#8a4b08][b]+30 Score, Barya[/b][/color], at agarang [b]Kidlat Dash Powerup[/b]!",
		"right_body": "[b]Tatlong Laro ng Lahi Modes:[/b]\n\n1. [color=#9c3d18][b]Pasa-Taya (Bomb Tag):[/b][/color]\nIpasa ang Taya bago maubos ang timer! Ang huling taya ay eliminated.\n\n2. [color=#9c3d18][b]Hawaan (Zombie Tag):[/b][/color]\nLahat ng mahuli ay magiging Taya rin hanggang maubos ang Runners.\n\n3. [color=#8a4b08][b]Walang Bawian (Points Tag):[/b][/color]\nTagisan ng puntos sa loob ng itinakdang oras.",
		"tip": "💡 TIP NI KAP: Ang mga naipong Barya ay magagamit sa Tindahan ni Aling Delia para sa bagong porma!"
	}
]

func _ready() -> void:
	var on_tab = func(idx: int):
		var am = get_node_or_null("/root/AudioManager")
		if am and am.has_method("play_ui_click"): am.play_ui_click()
		_show_tab(idx)

	if tab_maiba: tab_maiba.pressed.connect(func(): on_tab.call(0))
	if tab_stamina: tab_stamina.pressed.connect(func(): on_tab.call(1))
	if tab_items: tab_items.pressed.connect(func(): on_tab.call(2))
	if tab_modes: tab_modes.pressed.connect(func(): on_tab.call(3))

	if next_btn: next_btn.pressed.connect(_on_next_pressed)
	if prev_btn: prev_btn.pressed.connect(_on_prev_pressed)
	if close_btn: close_btn.pressed.connect(_on_close_pressed)

	_show_tab(0)

func open_guide() -> void:
	visible = true
	_show_tab(0)

func close_guide() -> void:
	visible = false
	_mark_seen()
	closed.emit()

func _on_close_pressed() -> void:
	var am = get_node_or_null("/root/AudioManager")
	if am and am.has_method("play_ui_cancel"):
		am.play_ui_cancel()
	close_guide()

func _on_next_pressed() -> void:
	var am = get_node_or_null("/root/AudioManager")
	if am and am.has_method("play_ui_click"):
		am.play_ui_click()
	var next_idx := (current_tab_idx + 1) % TABS_DATA.size()
	_show_tab(next_idx)

func _on_prev_pressed() -> void:
	var am = get_node_or_null("/root/AudioManager")
	if am and am.has_method("play_ui_click"):
		am.play_ui_click()
	var prev_idx := (current_tab_idx - 1 + TABS_DATA.size()) % TABS_DATA.size()
	_show_tab(prev_idx)

func _show_tab(idx: int) -> void:
	current_tab_idx = idx
	var data: Dictionary = TABS_DATA[idx]

	if title_label: title_label.text = data.get("title", "")
	if subtitle_label: subtitle_label.text = data.get("subtitle", "")
	if body_label: body_label.text = data.get("left_body", data.get("body", ""))
	if right_body_label: right_body_label.text = data.get("right_body", "")
	if tip_label: tip_label.text = data.get("tip", "")

	_update_tab_indicators(idx)

	if prev_btn: prev_btn.disabled = (idx == 0)
	if next_btn:
		if idx == TABS_DATA.size() - 1:
			next_btn.text = "TARA SA KALYE! ▶"
		else:
			next_btn.text = "SUSUNOD ▶"

func _update_tab_indicators(idx: int) -> void:
	var tabs = [
		{"btn": tab_maiba, "sel_col": Color(0.14, 0.09, 0.04, 1.0), "unsel_col": Color(0.35, 0.28, 0.12, 0.65)},
		{"btn": tab_stamina, "sel_col": Color(1.0, 1.0, 1.0, 1.0), "unsel_col": Color(0.85, 1.0, 0.95, 0.65)},
		{"btn": tab_items, "sel_col": Color(1.0, 1.0, 1.0, 1.0), "unsel_col": Color(1.0, 0.88, 0.88, 0.65)},
		{"btn": tab_modes, "sel_col": Color(1.0, 1.0, 1.0, 1.0), "unsel_col": Color(0.85, 0.92, 1.0, 0.65)},
	]
	for i in range(tabs.size()):
		var t = tabs[i]
		var b: Button = t["btn"]
		if not b:
			continue
		var is_sel: bool = (i == idx)
		b.button_pressed = is_sel
		var col: Color = t["sel_col"] if is_sel else t["unsel_col"]
		b.add_theme_color_override("font_color", col)
		b.add_theme_color_override("font_focus_color", col)
		b.add_theme_color_override("font_hover_color", col)
		b.add_theme_color_override("font_pressed_color", col)

static func has_seen_guide() -> bool:
	return FileAccess.file_exists(SAVE_SEEN_PATH)

func _mark_seen() -> void:
	var f := FileAccess.open(SAVE_SEEN_PATH, FileAccess.WRITE)
	if f:
		f.store_string("seen")
		f.close()
