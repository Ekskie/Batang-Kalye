class_name EconomyManager
extends Node

## EconomyManager
## Handles persistent player economy: Barya (coins), Street Rep (reputation),
## Tindahan ni Aling Nena item purchases, and user://player_customization.cfg storage.

signal wallet_updated(barya: int, street_rep: int)
signal item_purchased(category: String, item_id: Variant)
signal title_equipped(title: String)

const SAVE_PATH: String = "user://player_customization.cfg"
const STARTING_BARYA: int = 150
const STARTING_REP: int = 10

var barya: int = STARTING_BARYA
var street_rep: int = STARTING_REP

var unlocked_archetypes: Array[int] = [0, 2] # Tsuna and Totoy free by default
var unlocked_headwear: Array[int] = [0]      # Wala free
var unlocked_body: Array[int] = [0]          # Street T-Shirt free
var unlocked_footwear: Array[int] = [0]      # Spartan Asul/Puti free
var unlocked_titles: Array[String] = ["Batang Kalye"]
var equipped_title: String = "Batang Kalye"

# Catalog specifications for Tindahan ni Aling Nena
const CATALOG: Dictionary = {
	"archetypes": [
		{ "id": 0, "name": "Tsuna (Anime Kid)", "cost": 0, "rep": 0, "desc": "Mabilis at maliksi, bida sa anime." },
		{ "id": 1, "name": "Kalbo (Street Brawler)", "cost": 75, "rep": 0, "desc": "Matapang sa gitna ng initan." },
		{ "id": 2, "name": "Totoy (Sando Runner)", "cost": 0, "rep": 0, "desc": "Klasikong batang Pinoy na laging naka-sando." },
		{ "id": 3, "name": "Nene (Liksi Kid)", "cost": 100, "rep": 20, "desc": "Mabilis lumusot sa mga eskinita." },
		{ "id": 4, "name": "Tisoy (Pormang Kanto)", "cost": 150, "rep": 40, "desc": "Laging porma kahit pinagpapawisan." },
		{ "id": 5, "name": "Baldo (Basketbolista)", "cost": 200, "rep": 60, "desc": "Hari ng half-court at tres." },
		{ "id": 6, "name": "Nonoy (Pawisin)", "cost": 175, "rep": 50, "desc": "Laging may dalang bimpo sa likod." },
		{ "id": 7, "name": "Kikay (Bibbo)", "cost": 250, "rep": 80, "desc": "Makulay at bibbo sa buong barangay." }
	],
	"headwear": [
		{ "id": 0, "name": "Wala", "cost": 0, "rep": 0, "desc": "Presko sa ulo." },
		{ "id": 1, "name": "Baligtad na Snapback", "cost": 80, "rep": 10, "desc": "Astig na pormang kalye." },
		{ "id": 2, "name": "Good Morning Towel", "cost": 120, "rep": 25, "desc": "Pampunas ng pawis sa batok." },
		{ "id": 3, "name": "Bandana sa Noo", "cost": 100, "rep": 15, "desc": "Para sa matinding takbuhan." },
		{ "id": 4, "name": "Athletic Sweatband", "cost": 150, "rep": 35, "desc": "Pang-esports na dating." }
	],
	"body": [
		{ "id": 0, "name": "Street T-Shirt", "cost": 0, "rep": 0, "desc": "Pang-araw-araw na t-shirt." },
		{ "id": 1, "name": "Sando #23", "cost": 100, "rep": 20, "desc": "Inspirasyon ni Michael Jordan sa liga." },
		{ "id": 2, "name": "Striped Pambahay", "cost": 75, "rep": 10, "desc": "Damit pambahay na ginawang panlaro." },
		{ "id": 3, "name": "Sleeveless Sando", "cost": 90, "rep": 15, "desc": "Malamig sa katawan." }
	],
	"footwear": [
		{ "id": 0, "name": "Spartan Asul/Puti", "cost": 0, "rep": 0, "desc": "Tibay at lakas ng Spartan." },
		{ "id": 1, "name": "Islander Pula", "cost": 120, "rep": 20, "desc": "Mabigat at matibay, hindi madaling maputol." },
		{ "id": 2, "name": "Black Rubber Slide", "cost": 95, "rep": 15, "desc": "Modernong pampatagtag sa aspalto." },
		{ "id": 3, "name": "Paang Hubad", "cost": 50, "rep": 5, "desc": "Tunog ng yabag sa lupa, walang takot." }
	],
	"titles": [
		{ "id": "Batang Kalye", "name": "Batang Kalye", "cost": 0, "rep": 0, "desc": "Ang orihinal na manlalaro ng lahi." },
		{ "id": "Kidlat ng Barangay", "name": "Kidlat ng Barangay", "cost": 150, "rep": 30, "desc": "Hindi mahabol kahit anong bilis." },
		{ "id": "Hari ng Dulas", "name": "Hari ng Dulas", "cost": 180, "rep": 40, "desc": "Eksperto sa pag-slide sa ilalim ng harang." },
		{ "id": "Ninja ng Drum", "name": "Ninja ng Drum", "cost": 220, "rep": 50, "desc": "Mahiwagang naglalaho sa mga sulok." },
		{ "id": "Basura King", "name": "Basura King", "cost": 120, "rep": 20, "desc": "Mabilis mag-segregate para sa kalikasan." },
		{ "id": "Aling Nena's Favorite", "name": "Aling Nena's Favorite", "cost": 400, "rep": 100, "desc": "Pinakapaboritong customer sa tindahan." }
	]
}

func _ready() -> void:
	load_economy()

func load_economy() -> void:
	var cfg := ConfigFile.new()
	var err := cfg.load(SAVE_PATH)
	if err == OK:
		barya = int(cfg.get_value("economy", "barya", STARTING_BARYA))
		street_rep = int(cfg.get_value("economy", "street_rep", STARTING_REP))
		
		var loaded_arch = cfg.get_value("economy", "unlocked_archetypes", [0, 2])
		unlocked_archetypes.clear()
		for a in loaded_arch:
			unlocked_archetypes.append(int(a))
		if not unlocked_archetypes.has(0):
			unlocked_archetypes.append(0)
		if not unlocked_archetypes.has(2):
			unlocked_archetypes.append(2)

		var loaded_head = cfg.get_value("economy", "unlocked_headwear", [0])
		unlocked_headwear.clear()
		for h in loaded_head:
			unlocked_headwear.append(int(h))
		if not unlocked_headwear.has(0):
			unlocked_headwear.append(0)

		var loaded_body = cfg.get_value("economy", "unlocked_body", [0])
		unlocked_body.clear()
		for b in loaded_body:
			unlocked_body.append(int(b))
		if not unlocked_body.has(0):
			unlocked_body.append(0)

		var loaded_foot = cfg.get_value("economy", "unlocked_footwear", [0])
		unlocked_footwear.clear()
		for f in loaded_foot:
			unlocked_footwear.append(int(f))
		if not unlocked_footwear.has(0):
			unlocked_footwear.append(0)

		var loaded_titles = cfg.get_value("economy", "unlocked_titles", ["Batang Kalye"])
		unlocked_titles.clear()
		for t in loaded_titles:
			unlocked_titles.append(str(t))
		if not unlocked_titles.has("Batang Kalye"):
			unlocked_titles.append("Batang Kalye")

		equipped_title = str(cfg.get_value("economy", "equipped_title", "Batang Kalye"))
	else:
		save_economy()

func save_economy() -> void:
	var cfg := ConfigFile.new()
	cfg.load(SAVE_PATH) # Preserve other sections like [player], [outfit]
	
	cfg.set_value("economy", "barya", barya)
	cfg.set_value("economy", "street_rep", street_rep)
	cfg.set_value("economy", "unlocked_archetypes", unlocked_archetypes)
	cfg.set_value("economy", "unlocked_headwear", unlocked_headwear)
	cfg.set_value("economy", "unlocked_body", unlocked_body)
	cfg.set_value("economy", "unlocked_footwear", unlocked_footwear)
	cfg.set_value("economy", "unlocked_titles", unlocked_titles)
	cfg.set_value("economy", "equipped_title", equipped_title)
	
	var err := cfg.save(SAVE_PATH)
	if err != OK:
		push_error("Failed to save economy state: %d" % err)
	else:
		wallet_updated.emit(barya, street_rep)

func award_match_earnings(score: int, tags: int, recycled: int, is_winner: bool) -> Dictionary:
	var base_barya: int = 30
	var base_rep: int = 15
	
	var tag_barya: int = tags * 20
	var tag_rep: int = tags * 5
	
	var recycle_barya: int = recycled * 25
	var recycle_rep: int = recycled * 10
	
	var score_barya: int = int(score * 0.08)
	var win_barya: int = 150 if is_winner else 0
	var win_rep: int = 50 if is_winner else 0
	
	var earned_barya: int = base_barya + tag_barya + recycle_barya + score_barya + win_barya
	var earned_rep: int = base_rep + tag_rep + recycle_rep + win_rep
	
	barya += earned_barya
	street_rep += earned_rep
	
	save_economy()
	
	return {
		"barya_earned": earned_barya,
		"rep_earned": earned_rep,
		"total_barya": barya,
		"total_rep": street_rep,
		"is_winner": is_winner
	}

func can_afford(cost: int, req_rep: int = 0) -> bool:
	return barya >= cost and street_rep >= req_rep

func is_unlocked(category: String, item_id: Variant) -> bool:
	match category:
		"archetypes":
			return unlocked_archetypes.has(int(item_id))
		"headwear":
			return unlocked_headwear.has(int(item_id))
		"body":
			return unlocked_body.has(int(item_id))
		"footwear":
			return unlocked_footwear.has(int(item_id))
		"titles":
			return unlocked_titles.has(str(item_id))
	return false

func purchase_item(category: String, item_id: Variant, cost: int, req_rep: int = 0) -> bool:
	if is_unlocked(category, item_id):
		return true # Already owned
	if not can_afford(cost, req_rep):
		return false # Insufficient funds or rep
	
	barya -= cost
	match category:
		"archetypes":
			unlocked_archetypes.append(int(item_id))
		"headwear":
			unlocked_headwear.append(int(item_id))
		"body":
			unlocked_body.append(int(item_id))
		"footwear":
			unlocked_footwear.append(int(item_id))
		"titles":
			unlocked_titles.append(str(item_id))
	
	save_economy()
	item_purchased.emit(category, item_id)
	return true

func equip_title(title_id: String) -> bool:
	if is_unlocked("titles", title_id):
		equipped_title = title_id
		save_economy()
		title_equipped.emit(title_id)
		return true
	return false
