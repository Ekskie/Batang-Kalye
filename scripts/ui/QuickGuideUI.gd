class_name QuickGuideUI
extends Control

## QuickGuideUI
## 4-tab interactive onboarding and tutorial modal for international & new players.

signal closed()

@onready var tab_maiba: Button = get_node_or_null("%TabMaiba")
@onready var tab_stamina: Button = get_node_or_null("%TabStamina")
@onready var tab_items: Button = get_node_or_null("%TabItems")
@onready var tab_modes: Button = get_node_or_null("%TabModes")

@onready var title_label: Label = get_node_or_null("%GuideTitle")
@onready var subtitle_label: Label = get_node_or_null("%GuideSubtitle")
@onready var body_label: RichTextLabel = get_node_or_null("%GuideBody")
@onready var tip_label: Label = get_node_or_null("%GuideTip")
@onready var close_btn: Button = get_node_or_null("%CloseButton")
@onready var next_btn: Button = get_node_or_null("%NextButton")
@onready var prev_btn: Button = get_node_or_null("%PrevButton")

const SAVE_SEEN_PATH: String = "user://has_seen_quick_guide"

var current_tab_idx: int = 0

const TABS_DATA: Array[Dictionary] = [
	{
		"title": "🖐️ MAIBA TAYA (Puti o Itim?)",
		"subtitle": "Ang tradisyonal na ritwal bago magsimula ang laro sa kalye.",
		"body": "[b]Paano magsimula:[/b]\nBago sumabak sa takbuhan, lahat ng bata ay sabay-sabay na magcha-chant ng [color=#ffd700]\"Ma-i-ba... TAYA!\"[/color]\n\nPiliin ang iyong kamay:\n• [b]🖐️ Puti / Ibabaw[/b] (Palm UP)\n• [b]🤚 Itim / Ilalim[/b] (Palm DOWN)\n\nKung sino ang [color=#ff6666]naiba ang kulay[/color] sa karamihan, siya ang magiging unang [b]TAYA[/b] (Chaser)!\n\nSa malalaking laban (16–24 players), awtomatikong pipiliin ang minority gesture group para maging maraming Taya.",
		"tip": "💡 Tip: Kung Taya ka, may fiery red aura ka at adrenaline speed boost!"
	},
	{
		"title": "⚡ DUAL STAMINA AT PAGGALAW",
		"subtitle": "Kombinasyon ng bilis at tibay para hindi abutan ng hingal.",
		"body": "[b]1. Burst Sprint (Bilis-Bwelo):[/b]\nPindutin ang Sprint para sa mabilis na takbo. Dahan-dahan itong mauubos, pero mabilis babalik kapag naglakad o huminto ka.\n\n[b]2. Long-term Endurance (Resistensya):[/b]\nHuwag abusuhin ang sprint! Kapag naubos ang iyong endurance, aabutin ka ng [color=#ff5555]Hingal (Exhaustion)[/color] at iika-ika kang maglalakad hanggang makabawi ka ng hangin.\n\n[b]3. Dulas (Slide):[/b]\nPindutin ang Dulas habang tumatakbo upang lumusot sa ilalim ng mga harang at umiwas sa tag slap!\n\n[b]4. Talon at Double Jump:[/b]\nTalon sa ere para umakyat sa mga bubong o crates. Mag-unlock ng Double Jump gamit ang Powerups!",
		"tip": "💡 Tip: Huwag ubusin ang stamina habang malayo pa ang Taya; i-reserve ito sa oras ng gipitan!"
	},
	{
		"title": "🩴 MGA GAMIT SA KALYE (Street Items)",
		"subtitle": "Gamitin ang mga bagay sa barangay para protektahan ang sarili.",
		"body": "Magpulot ng gamit sa aspalto at gamitin ito sa tamang pagkakataon:\n\n• [color=#4da6ff][b]Spartan Tsinelas[/b][/color]: Ihagis sa kalaban para sampalin sa malayo at pigilan ang paglapit!\n• [color=#ffd700][b]Balat ng Saging[/b][/color]: Ilatag sa kalsada. Madudulas ang sinumang makatapak at babagal ang takbo.\n• [color=#ffaa33][b]Pito ng Barangay[/b][/color]: Hipan ang pito para ma-stun ang Taya at ilantad ang radar markers ng lahat ng nagtatago.\n• [color=#cccccc][b]Supot ng Chalk[/b][/color]: Ihagis para lumikha ng makapal na usok na tatakip sa paningin ng humahabol.\n• [color=#33cc66][b]Asul na Drum[/b][/color]: Pumasok sa loob para magtago nang tahimik hanggang 8 segundo.",
		"tip": "💡 Tip: Maaari kang magtapon o magpalit ng gamit anumang oras gamit ang Drop button."
	},
	{
		"title": "♻️ SEGREGATION AT GAME MODES",
		"subtitle": "Mag-linis ng kalye at piliin ang iyong paboritong istilo ng laro.",
		"body": "[b]Waste Segregation para sa Powerup:[/b]\nMagpulot ng kalat sa kalsada at ilagay sa tamang basurahan (Biodegradable, Non-Bio, Recyclable) para sa [color=#ffd700]+30 Score, Barya[/color], at agarang [b]Imagination Powerup[/b] tulad ng Kidlat Dash at Water-Run!\n\n[b]Tatlong Laro ng Lahi Modes:[/b]\n1. [color=#ff4444][b]Pasa-Taya (Bomb Tag)[/b][/color]: Ipasa ang Taya sa iba bago maubos ang round timer! Ang huling may hawak ay ma-e-eliminate (Matira Matibay)!\n2. [color=#aa44ff][b]Hawaan (Zombie Tag)[/b][/color]: Lahat ng mahuli ay magiging Taya rin hanggang sa maubos ang lahat ng Runner.\n3. [color=#44ff88][b]Walang Bawian (Points Tag)[/b][/color]: Tagisan ng puntos sa loob ng oras.",
		"tip": "💡 Tip: Ang mga Barya at Street Rep na iyong maiipon ay magagamit sa Tindahan ni Aling Nena!"
	}
]

func _ready() -> void:
	if tab_maiba: tab_maiba.pressed.connect(func(): _show_tab(0))
	if tab_stamina: tab_stamina.pressed.connect(func(): _show_tab(1))
	if tab_items: tab_items.pressed.connect(func(): _show_tab(2))
	if tab_modes: tab_modes.pressed.connect(func(): _show_tab(3))
	
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
	close_guide()

func _on_next_pressed() -> void:
	var next_idx := (current_tab_idx + 1) % TABS_DATA.size()
	_show_tab(next_idx)

func _on_prev_pressed() -> void:
	var prev_idx := (current_tab_idx - 1 + TABS_DATA.size()) % TABS_DATA.size()
	_show_tab(prev_idx)

func _show_tab(idx: int) -> void:
	current_tab_idx = idx
	var data: Dictionary = TABS_DATA[idx]
	
	if title_label: title_label.text = data.get("title", "")
	if subtitle_label: subtitle_label.text = data.get("subtitle", "")
	if body_label: body_label.text = data.get("body", "")
	if tip_label: tip_label.text = data.get("tip", "")
	
	# Update Tab buttons highlight
	if tab_maiba: tab_maiba.button_pressed = (idx == 0)
	if tab_stamina: tab_stamina.button_pressed = (idx == 1)
	if tab_items: tab_items.button_pressed = (idx == 2)
	if tab_modes: tab_modes.button_pressed = (idx == 3)
	
	if prev_btn: prev_btn.disabled = (idx == 0)
	if next_btn: next_btn.text = "TAPOS / ISARA" if (idx == TABS_DATA.size() - 1) else "SUSUNOD ▶"

func _mark_seen() -> void:
	var f := FileAccess.open(SAVE_SEEN_PATH, FileAccess.WRITE)
	if f:
		f.store_string("seen")
		f.close()

static func has_seen_guide() -> bool:
	return FileAccess.file_exists(SAVE_SEEN_PATH)
