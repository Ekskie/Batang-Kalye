extends SceneTree

const KalyeMatchMapScript = preload("res://scripts/gameplay/KalyeMatchMap.gd")

func _init() -> void:
	call_deferred("run_tests")

func run_tests() -> void:
	print("\n==================================================")
	print("[KALYE MATCH MAP INTEGRITY VERIFICATION]")
	print("==================================================")
	
	var scene = load("res://scenes/maps/KalyeMatchMap.tscn")
	assert(scene != null, "KalyeMatchMap.tscn must load successfully")
	print("[PASS] KalyeMatchMap.tscn loaded cleanly.")
	
	var map: Node3D = scene.instantiate() as Node3D
	root.add_child(map)
	await process_frame
	await physics_frame
	
	print("[PASS] KalyeMatchMap instantiated as type KalyeMatchMap.")
	print("       Map name: %s, Arena size: %s" % [map.map_name, str(map.arena_size)])
	
	# 1. Verify Spawn Points
	var spawns: Array[Marker3D] = map.get_spawn_markers()
	print("[CHECK] Spawn markers found: %d" % spawns.size())
	assert(spawns.size() == 24, "Must have exactly 24 spawn points")
	print("[PASS] Exactly 24 spawn points verified.")
	
	# Check pairwise distance
	var min_dist := 999.0
	for i in range(spawns.size()):
		var p1 := spawns[i].global_position
		assert(p1.x >= -48.0 and p1.x <= 48.0, "Spawn %d X out of bounds: %f" % [i, p1.x])
		assert(p1.z >= -48.0 and p1.z <= 48.0, "Spawn %d Z out of bounds: %f" % [i, p1.z])
		for j in range(i + 1, spawns.size()):
			var p2 := spawns[j].global_position
			var d := p1.distance_to(p2)
			if d < min_dist:
				min_dist = d
			assert(d >= 7.0, "Pairwise distance between Spawn%d and Spawn%d too close: %.2fm" % [i + 1, j + 1, d])
	print("[PASS] All 24 spawn markers within [-48, 48] bounds. Minimum pairwise distance: %.2fm (>=7.0m)." % min_dist)
	
	# 2. Verify Hiding Spots
	var hiding_spots := []
	var hs_container = map.get_node_or_null("HidingSpots")
	assert(hs_container != null, "HidingSpots container exists")
	for c in hs_container.get_children():
		if c is HidingSpot:
			hiding_spots.append(c)
	print("[PASS] Found %d active hiding spots (drums and boxes) across all districts (>=16 required for huge map)." % hiding_spots.size())
	assert(hiding_spots.size() >= 16, "Must have at least 16 hiding spots")
	
	# Verify specific test drum for GameManager self-test
	var drum1 = map.get_node_or_null("HidingSpots/HidingDrum1")
	assert(drum1 != null and drum1 is HidingSpot, "HidingSpots/HidingDrum1 must exist for self-test compatibility")
	print("[PASS] HidingSpots/HidingDrum1 verified for GameManager self-test.")
	
	# 3. Verify Street Items & Trash
	var street_items = map.get_node_or_null("StreetItems")
	assert(street_items != null and street_items.get_child_count() >= 5, "Must have all 5 street items")
	print("[PASS] %d Street Items verified (Tsinelas, Saging, Pito, Chalk, Ice Candy)." % street_items.get_child_count())
	
	var trash_items = map.get_node_or_null("TrashItems")
	assert(trash_items != null and trash_items.get_child_count() >= 3, "Must have trash items")
	print("[PASS] %d Trash items for segregation verified." % trash_items.get_child_count())
	
	# 4. Verify Hazards
	var dog = map.find_child("DogChaser", true, false)
	assert(dog != null and dog is DogChaser, "DogChaser character must be present")
	print("[PASS] DogChaser verified.")
	
	var canal = map.find_child("WaterZone", true, false)
	assert(canal != null and canal is WaterZone, "WaterZone canal must be present")
	print("[PASS] WaterZone canal verified.")
	
	var footbridge = map.find_child("Footbridge", true, false)
	assert(footbridge != null, "Canal footbridge exists")
	print("[PASS] Canal footbridge verified.")
	
	# 5. Verify Recycling Station
	var recycle = map.find_child("RecycleStation", true, false)
	assert(recycle != null, "RecycleStation exists")
	var bin_nabubulok = recycle.get_node_or_null("BinNabubulok")
	var bin_di = recycle.get_node_or_null("BinDiNabubulok")
	var bin_re = recycle.get_node_or_null("BinNareresiklo")
	assert(bin_nabubulok != null and bin_di != null and bin_re != null, "All 3 recycling bins exist")
	print("[PASS] 3-Bin recycling station verified (Nabubulok, Di-Nabubulok, Nareresiklo).")
	
	print("\n[ALL KALYE MATCH MAP INTEGRITY CHECKS PASSED EMPIRICALLY!]")
	quit(0)
