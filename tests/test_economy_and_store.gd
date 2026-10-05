extends SceneTree

# ==============================================================================
# EMPIRICAL TEST SUITE: MILESTONE 2 (Sari-Sari Store & Economy Meta-Loop)
# ==============================================================================

var test_passes: int = 0
var test_failures: int = 0

func _init() -> void:
	call_deferred("run_all_tests")

func assert_true(cond: bool, msg: String) -> void:
	if cond:
		test_passes += 1
		print("  [PASS] %s" % msg)
	else:
		test_failures += 1
		push_error("  [FAIL] %s" % msg)
		print("  [FAIL] %s" % msg)

func run_all_tests() -> void:
	print("\n" + "=".repeat(70))
	print(" [MILESTONE 2 TEST SUITE] SARI-SARI STORE & PERSISTENT ECONOMY")
	print("=".repeat(70))

	test_economy_initialization()
	test_match_earnings_formula()
	test_transaction_safety_and_duplicate_prevention()
	test_persistence_integrity()
	test_store_ui_instantiation_and_tabs()
	test_title_equipping()

	print("\n" + "=".repeat(70))
	print(" M2 TEST SUMMARY: %d PASSED, %d FAILED" % [test_passes, test_failures])
	print("=".repeat(70))

	if test_failures == 0:
		print(">>> ALL MILESTONE 2 TESTS PASSED! <<<")
		quit(0)
	else:
		push_error(">>> MILESTONE 2 TESTS FAILED: %d failures detected! <<<" % test_failures)
		quit(1)

func test_economy_initialization() -> void:
	print("\n--- [1] EconomyManager Initialization & Defaults ---")
	var eco := EconomyManager.new()
	assert_true(eco != null, "EconomyManager instantiated successfully")
	assert_true(eco.barya >= 150, "Initial barya is at least 150 (got %d)" % eco.barya)
	assert_true(eco.street_rep >= 10, "Initial street rep is at least 10 (got %d)" % eco.street_rep)
	assert_true(eco.is_unlocked("archetypes", 0), "Archetype 0 (Tsuna) unlocked by default")
	assert_true(eco.is_unlocked("archetypes", 2), "Archetype 2 (Totoy) unlocked by default")
	assert_true(eco.is_unlocked("headwear", 0), "Headwear 0 (Wala) unlocked by default")
	assert_true(eco.is_unlocked("body", 0), "Body 0 (Street T-Shirt) unlocked by default")
	assert_true(eco.is_unlocked("footwear", 0), "Footwear 0 (Spartan) unlocked by default")
	assert_true(eco.is_unlocked("titles", "Batang Kalye"), "Title 'Batang Kalye' unlocked by default")
	eco.free()

func test_match_earnings_formula() -> void:
	print("\n--- [2] Match Earnings Formula & Calculation ---")
	var eco := EconomyManager.new()
	eco.barya = 100
	eco.street_rep = 50

	# score=200, tags=3, recycled=2, is_winner=true
	# base: 30 barya, 15 rep
	# tags: 3 * 20 = 60 barya, 3 * 5 = 15 rep
	# recycled: 2 * 25 = 50 barya, 2 * 10 = 20 rep
	# score: int(200 * 0.08) = 16 barya
	# win: 150 barya, 50 rep
	# Total earned barya: 30 + 60 + 50 + 16 + 150 = 306
	# Total earned rep: 15 + 15 + 20 + 50 = 100
	var res := eco.award_match_earnings(200, 3, 2, true)
	assert_true(res["barya_earned"] == 306, "Earned barya matches exact formula: 306 (got %d)" % res["barya_earned"])
	assert_true(res["rep_earned"] == 100, "Earned rep matches exact formula: 100 (got %d)" % res["rep_earned"])
	assert_true(eco.barya == 406, "Wallet barya balance correctly updated to 406 (got %d)" % eco.barya)
	assert_true(eco.street_rep == 150, "Wallet rep balance correctly updated to 150 (got %d)" % eco.street_rep)
	eco.free()

func test_transaction_safety_and_duplicate_prevention() -> void:
	print("\n--- [3] Transaction Safety & Duplicate Prevention ---")
	var eco := EconomyManager.new()
	eco.barya = 200
	eco.street_rep = 100
	eco.unlocked_headwear = [0]

	# Item 1 costs 80 barya, rep 10
	var buy_ok := eco.purchase_item("headwear", 1, 80, 10)
	assert_true(buy_ok, "Purchased headwear 1 successfully")
	assert_true(eco.barya == 120, "Deducted exact cost: balance is 120 (got %d)" % eco.barya)
	assert_true(eco.is_unlocked("headwear", 1), "Headwear 1 is now marked unlocked")

	# Duplicate purchase attempt
	var dup_ok := eco.purchase_item("headwear", 1, 80, 10)
	assert_true(dup_ok, "Duplicate purchase returns true (idempotent)")
	assert_true(eco.barya == 120, "Balance not deducted on duplicate purchase (still %d)" % eco.barya)

	# Insufficient funds attempt (Cost 500 > Balance 120)
	var poor_ok := eco.purchase_item("headwear", 4, 500, 10)
	assert_true(not poor_ok, "Purchase rejected due to insufficient barya")
	assert_true(not eco.is_unlocked("headwear", 4), "Headwear 4 remains locked")
	assert_true(eco.barya == 120, "Balance remains intact after failed purchase")

	# Insufficient rep attempt (Cost 50 <= Balance 120, but Rep 999 > Rep 100)
	var unrep_ok := eco.purchase_item("headwear", 3, 50, 999)
	assert_true(not unrep_ok, "Purchase rejected due to insufficient street rep")
	assert_true(not eco.is_unlocked("headwear", 3), "Headwear 3 remains locked")
	eco.free()

func test_persistence_integrity() -> void:
	print("\n--- [4] Persistence Integrity to user://player_customization.cfg ---")
	var eco := EconomyManager.new()
	eco.barya = 350
	eco.street_rep = 75
	eco.unlocked_titles = ["Batang Kalye", "Kidlat ng Barangay"]
	eco.equipped_title = "Kidlat ng Barangay"
	eco.save_economy()

	var cfg := ConfigFile.new()
	var err := cfg.load(EconomyManager.SAVE_PATH)
	assert_true(err == OK, "Loaded save file user://player_customization.cfg successfully")
	assert_true(int(cfg.get_value("economy", "barya", 0)) == 350, "Saved barya matches 350")
	assert_true(int(cfg.get_value("economy", "street_rep", 0)) == 75, "Saved street_rep matches 75")
	assert_true(str(cfg.get_value("economy", "equipped_title", "")) == "Kidlat ng Barangay", "Saved title matches 'Kidlat ng Barangay'")

	# Reload into fresh instance
	var eco2 := EconomyManager.new()
	eco2.load_economy()
	assert_true(eco2.barya == 350, "Reloaded barya matches in new instance (got %d)" % eco2.barya)
	assert_true(eco2.street_rep == 75, "Reloaded street_rep matches in new instance (got %d)" % eco2.street_rep)
	assert_true(eco2.equipped_title == "Kidlat ng Barangay", "Reloaded title matches in new instance")
	eco.free()
	eco2.free()

func test_store_ui_instantiation_and_tabs() -> void:
	print("\n--- [5] StoreUI Instantiation & Category Tabs ---")
	var store_scene: PackedScene = preload("res://scenes/ui/StoreUI.tscn")
	assert_true(store_scene != null, "StoreUI.tscn loaded successfully")

	var store := store_scene.instantiate() as StoreUI
	assert_true(store != null, "StoreUI instantiated successfully")

	var root_ctrl := Control.new()
	root.add_child(root_ctrl)
	root_ctrl.add_child(store)

	store.open_store()
	assert_true(store.visible, "StoreUI is visible when opened")

	# Test all categories
	for cat in ["archetypes", "headwear", "body", "footwear", "titles"]:
		store._switch_tab(cat)
		assert_true(store.current_category == cat, "Switched active category to '%s'" % cat)
		assert_true(store.items_container.get_child_count() > 0, "Item cards populated for '%s' (count: %d)" % [cat, store.items_container.get_child_count()])

	store.close_store()
	assert_true(not store.visible, "StoreUI closed successfully")
	root_ctrl.queue_free()

func test_title_equipping() -> void:
	print("\n--- [6] Title Equipping & State ---")
	var eco := EconomyManager.new()
	eco.unlocked_titles = ["Batang Kalye", "Hari ng Dulas"]
	var ok := eco.equip_title("Hari ng Dulas")
	assert_true(ok, "Equipped unlocked title 'Hari ng Dulas'")
	assert_true(eco.equipped_title == "Hari ng Dulas", "Equipped title verified")

	var lock_ok := eco.equip_title("Ninja ng Drum")
	assert_true(not lock_ok, "Cannot equip locked title 'Ninja ng Drum'")
	assert_true(eco.equipped_title == "Hari ng Dulas", "Equipped title unchanged after invalid equip")
	eco.free()
