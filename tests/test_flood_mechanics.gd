extends SceneTree

## Automated Verification Suite: Flood Mechanics & Map Update
## Tests new map instantiation, StreetFloodWater node, WaterZone, Clogged Drain meter, and HUD updates.

const KalyeMatchMapScript = preload("res://scripts/gameplay/KalyeMatchMap.gd")
const HUDScript = preload("res://scripts/ui/HUD.gd")

func _init() -> void:
	print("\n=======================================================")
	print("[TEST] Starting Flood Mechanics & Map Update Verification...")
	print("=======================================================")

	# 1. Load and instantiate KalyeMatchMap.tscn
	var map_scene: PackedScene = load("res://scenes/maps/KalyeMatchMap.tscn")
	if not map_scene:
		push_error("[FAIL] Could not load res://scenes/maps/KalyeMatchMap.tscn")
		quit(1)
		return
	print("[PASS] KalyeMatchMap.tscn loaded successfully.")

	var map = map_scene.instantiate() as Node3D
	if not map:
		push_error("[FAIL] Could not instantiate KalyeMatchMap!")
		quit(1)
		return
	root.add_child(map)
	print("[PASS] KalyeMatchMap instantiated with new updated nonflood map.")

	# 2. Verify StreetFloodWater and WaterZone
	var flood_water = map.get_node_or_null("StreetFloodWater")
	if not flood_water:
		push_error("[FAIL] StreetFloodWater node not found on KalyeMatchMap!")
		quit(1)
		return
	print("[PASS] StreetFloodWater node found.")

	var water_zone = flood_water.get_node_or_null("WaterZone")
	if not water_zone or not (water_zone is WaterZone):
		push_error("[FAIL] WaterZone Area3D not found on StreetFloodWater!")
		quit(1)
		return
	assert((water_zone.collision_mask & 2) != 0, "WaterZone Area3D must mask layer 2 (Players)")
	assert(water_zone.collision_layer == 4, "WaterZone Area3D must be on layer 4")
	print("[PASS] WaterZone Area3D verified on StreetFloodWater with collision_mask=2 (Player detection).")

	# 3. Verify initial dry state
	if map.is_flooded != false or map.flood_level != 0.0:
		push_error("[FAIL] Initial flood state should be dry (level=0.0, is_flooded=false)!")
		quit(1)
		return
	print("[PASS] Initial flood state is dry: flood_level=0%, is_flooded=false.")

	# 4. Test passive clog accumulation
	map.update_flood(10.0, true) # 10 seconds of neglect
	var expected_level: float = 10.0 * map.CLOG_RATE_PER_SEC
	if absf(map.flood_level - expected_level) > 0.5:
		push_error("[FAIL] Expected flood level ~%.1f, got %.1f" % [expected_level, map.flood_level])
		quit(1)
		return
	print("[PASS] Passive drain clog accumulation verified: %.1f%% after 10s." % map.flood_level)

	# 5. Test trash deposit relief
	var prev_level = map.flood_level
	map.reduce_flood(10.0)
	if absf(map.flood_level - (prev_level - 10.0)) > 0.1:
		push_error("[FAIL] reduce_flood failed to reduce flood level accurately!")
		quit(1)
		return
	print("[PASS] Trash deposit relief verified: reduced to %.1f%%." % map.flood_level)

	# 6. Test 100% threshold flood trigger
	map.update_flood(60.0, true) # Force to 100%
	if not map.is_flooded or map.flood_level < 100.0:
		push_error("[FAIL] Flood did not trigger when meter reached 100%!")
		quit(1)
		return
	print("[PASS] 100% Flood Trigger verified: is_flooded=true, flood_level=100%.")

	# 7. Test mid-round draining below 80%
	map.reduce_flood(25.0) # Drops to 75%
	if map.is_flooded or map.flood_level > 76.0:
		push_error("[FAIL] Flood did not drain when dropped below 80%!")
		quit(1)
		return
	print("[PASS] Mid-round drain recovery verified: drops to %.1f%%, is_flooded=false." % map.flood_level)

	# 8. Verify HUD Flood Meter
	var hud_scene: PackedScene = load("res://scenes/ui/HUD.tscn")
	var hud = hud_scene.instantiate()
	root.add_child(hud)
	hud.update_flood_meter(0.0, false)
	if not hud.flood_label or not hud.flood_label.text.contains("MALINIS"):
		push_error("[FAIL] HUD flood label text unexpected for clean state: %s" % (hud.flood_label.text if hud.flood_label else "null"))
		quit(1)
		return
	hud.update_flood_meter(100.0, true)
	if not hud.flood_label.text.contains("BUMABAHA"):
		push_error("[FAIL] HUD flood label text unexpected for flooded state: %s" % hud.flood_label.text)
		quit(1)
		return
	print("[PASS] HUD Flood Meter UI rendering verified (Malinis & Bumahaha states).")

	# 9. Test respawn_all_items() functionality
	var s_items = map.find_child("StreetItems", true, false)
	var t_items = map.find_child("TrashItems", true, false)
	assert(s_items != null and s_items.get_child_count() == 11, "Must have exactly 11 scattered street items")
	assert(t_items != null and t_items.get_child_count() == 10, "Must have exactly 10 scattered trash items")

	# Collect an item
	var first_item = s_items.get_child(0) as StreetItem
	first_item.is_collected = true
	var first_trash = t_items.get_child(0) as TrashItem
	first_trash.is_collected = true

	map.respawn_all_items()
	assert(first_item.is_collected == false, "respawn_all_items() must respawn street items")
	assert(first_trash.is_collected == false, "respawn_all_items() must respawn trash items")
	print("[PASS] respawn_all_items() verified: refreshes all 11 street items and 10 trash items.")

	# 10. Verify Flood Persistence across Pasa-Taya Round Progression
	map.set_flood_state(65.0, false)
	assert(map.flood_level == 65.0, "Flood set to 65.0% for round persistence test")
	# Round transition call (does NOT reset flood)
	map.respawn_all_items()
	assert(map.flood_level == 65.0, "Flood level must persist across round starts without reset")
	print("[PASS] Persistent flood verified: flood level carries over across rounds until trash is deposited.")

	# 11. Verify Item Ground Level (Dry) vs Floating Bobbing (Flooded)
	map.drain_flood()
	first_item._process(0.016)
	first_trash._process(0.016)
	assert(first_item.is_flooded == false and first_item.visual_root.position.y <= 0.05, "Item must rest level on ground when dry (y=0.04m), got %f" % first_item.visual_root.position.y)
	assert(first_trash.is_flooded == false and first_trash.visual_root.position.y <= 0.05, "Trash must rest level on ground when dry (y=0.03m), got %f" % first_trash.visual_root.position.y)
	print("[PASS] Grounded Items verified: Items rest level on asphalt (y<=0.05m) with no hovering when dry.")

	map.trigger_flood()
	first_item._process(0.016)
	first_trash._process(0.016)
	assert(first_item.is_flooded == true and first_item.visual_root.position.y >= 0.10, "Item must float on water surface when flooded, got %f" % first_item.visual_root.position.y)
	assert(first_trash.is_flooded == true and first_trash.visual_root.position.y >= 0.10, "Trash must float on water surface when flooded, got %f" % first_trash.visual_root.position.y)
	print("[PASS] Floated Items verified: Items float and bob dynamically on water surface when flooded.")

	# 12. Verify 3 Scattered Segregation Bins
	var bins = map.find_child("SegregationBins", true, false)
	assert(bins != null and bins.get_child_count() == 3, "Must have 3 scattered bins")
	var b_rec = bins.find_child("BinRecyclable", true, false)
	var b_bio = bins.find_child("BinBiodegradable", true, false)
	var b_non = bins.find_child("BinNonBio", true, false)
	assert(b_rec != null and b_bio != null and b_non != null, "All 3 distinct bins must be present")
	print("[PASS] 3 Distinct Segregation Bins verified at separate landmarks.")

	print("\n=======================================================")
	print("[ALL FLOOD & MAP TESTS PASSED] ZERO RUNTIME ERRORS!")
	print("=======================================================\n")

	hud.free()
	map.free()
	quit(0)
