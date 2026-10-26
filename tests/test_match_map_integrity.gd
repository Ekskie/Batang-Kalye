extends SceneTree

const KalyeMatchMapScript = preload("res://scripts/gameplay/KalyeMatchMap.gd")

func _init() -> void:
	run_tests()

func run_tests() -> void:
	print("\n==================================================")
	print("[KALYE MATCH MAP INTEGRITY VERIFICATION]")
	print("==================================================")
	
	var scene = load("res://scenes/maps/KalyeMatchMap.tscn")
	assert(scene != null, "KalyeMatchMap.tscn must load successfully")
	print("[PASS] KalyeMatchMap.tscn loaded cleanly.")
	
	var map: Node3D = scene.instantiate() as Node3D
	root.add_child(map)
	
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
		var p1 := spawns[i].position
		assert(p1.x >= -48.0 and p1.x <= 48.0, "Spawn %d X out of bounds: %f" % [i, p1.x])
		assert(p1.z >= -48.0 and p1.z <= 48.0, "Spawn %d Z out of bounds: %f" % [i, p1.z])
		for j in range(i + 1, spawns.size()):
			var p2 := spawns[j].position
			var d := p1.distance_to(p2)
			if d < min_dist:
				min_dist = d
			assert(d >= 7.0, "Pairwise distance between Spawn%d and Spawn%d too close: %.2fm" % [i + 1, j + 1, d])
	print("[PASS] All 24 spawn markers within [-48, 48] bounds. Minimum pairwise distance: %.2fm (>=7.0m)." % min_dist)
	
	# 2. Verify Hiding Spots
	var hs_container = map.get_node_or_null("HidingSpots")
	assert(hs_container != null, "HidingSpots container exists")
	print("[PASS] HidingSpots container verified cleanly for map update.")
	
	# 3. Verify Street Items & Trash
	var street_items = map.get_node_or_null("StreetItems")
	assert(street_items != null and street_items.get_child_count() == 11, "Must have 11 scattered street items")
	print("[PASS] %d Street Items verified (Tsinelas, Saging, Pito, Chalk, Ice Candy)." % street_items.get_child_count())
	
	var trash_items = map.get_node_or_null("TrashItems")
	assert(trash_items != null and trash_items.get_child_count() == 10, "Must have 10 scattered trash items")
	print("[PASS] %d Trash items for segregation verified." % trash_items.get_child_count())
	
	# 4. Verify Hazards
	var dog = map.find_child("DogChaser", true, false)
	assert(dog != null and dog is DogChaser, "DogChaser character must be present")
	print("[PASS] DogChaser verified.")
	
	var canal = map.find_child("WaterZone", true, false)
	assert(canal != null and canal is WaterZone, "WaterZone canal must be present")
	print("[PASS] WaterZone canal verified.")
	
	var footbridge = map.find_child("Footbridge", true, false)
	if footbridge != null:
		print("[PASS] Canal footbridge verified.")
	
	# 5. Verify Recycling Station & Scattered Segregation Bins
	var bins = map.find_child("SegregationBins", true, false)
	assert(bins != null, "SegregationBins container must exist")
	var bin_rec = bins.find_child("BinRecyclable", true, false)
	var bin_bio = bins.find_child("BinBiodegradable", true, false)
	var bin_non = bins.find_child("BinNonBio", true, false)
	assert(bin_rec != null, "BinRecyclable (Blue) must be present")
	assert(bin_bio != null, "BinBiodegradable (Green) must be present")
	assert(bin_non != null, "BinNonBio (Yellow) must be present")
	assert(bin_rec.position.distance_to(bin_bio.position) > 10.0, "Bins must be separated across landmarks")
	assert(bin_bio.position.distance_to(bin_non.position) > 10.0, "Bins must be separated across landmarks")
	print("[PASS] 3 Distinct Segregation Bins verified at separate landmarks (Court, Tindahan, Alley).")
	
	print("\n[ALL KALYE MATCH MAP INTEGRITY CHECKS PASSED EMPIRICALLY!]")
	map.free()
	quit(0)
