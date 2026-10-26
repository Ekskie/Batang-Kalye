extends SceneTree

func _init() -> void:
	run_tests()

func run_tests() -> void:
	print("\n==================================================")
	print("[TEST: UWIAN NA UI & COLLISION FIXES VERIFICATION]")
	print("==================================================")

	# --- 1. VERIFY UWIAN NA UI LAYERING ---
	print("\n[1] Verifying UwianNaUI Layering vs PauseUI...")
	var uwian_scene = load("res://scenes/ui/UwianNaUI.tscn")
	assert(uwian_scene != null, "UwianNaUI.tscn must load")
	var uwian_instance = uwian_scene.instantiate() as Control
	root.add_child(uwian_instance)

	assert(uwian_instance.z_index == 150, "UwianNaUI scene root z_index must be 150 (got %d)" % uwian_instance.z_index)
	assert(uwian_instance.z_as_relative == false, "UwianNaUI z_as_relative must be false")

	# Test open() method setting z_index
	uwian_instance.open()
	assert(uwian_instance.z_index == 150, "open() must maintain z_index 150")
	assert(uwian_instance.visible == true, "open() must make modal visible")
	print("  -> UwianNaUI scene has z_index = %d, z_as_relative = %s, open() works properly." % [uwian_instance.z_index, str(uwian_instance.z_as_relative)])

	# Test in Main.tscn
	var main_scene = load("res://scenes/main/Main.tscn")
	assert(main_scene != null, "Main.tscn must load")
	var main_instance = main_scene.instantiate()

	var main_pause = main_instance.get_node_or_null("PauseUI")
	var main_uwian = main_instance.get_node_or_null("UwianNaUI")
	assert(main_pause != null, "Main must have PauseUI")
	assert(main_uwian != null, "Main must have UwianNaUI")

	print("  -> Main.tscn PauseUI z_index: %d" % main_pause.z_index)
	print("  -> Main.tscn UwianNaUI z_index: %d" % main_uwian.z_index)
	assert(main_uwian.z_index > main_pause.z_index, "UwianNaUI z_index (%d) MUST be higher than PauseUI z_index (%d)!" % [main_uwian.z_index, main_pause.z_index])
	print("[PASS] UwianNaUI guaranteed to render on top of PauseUI.")

	# --- 2. VERIFY KALYE MATCH MAP COLLISION FIXES ---
	print("\n[2] Verifying KalyeMatchMap Collisions & Backface...")
	var map_scene = load("res://scenes/maps/KalyeMatchMap.tscn")
	assert(map_scene != null, "KalyeMatchMap.tscn must load")
	var map_instance = map_scene.instantiate() as Node3D
	root.add_child(map_instance)
	if not map_instance.is_node_ready():
		map_instance._ready()

	# Count total StaticBody3D generated inside the environment GLB
	var env_node = map_instance.find_child("Batang Kalye", true, false)
	assert(env_node != null, "Batang Kalye must exist in map")

	var total_static_bodies := 0
	var total_backface_shapes := 0
	var structural_checked := {
		"walkable_060": false, # Barangay Hall
		"walkable_065": false, # Tindahan ni Aling Nena
		"walkable_097": false, # Sidewalks
		"walkable_099": false  # Porch & curb
	}

	for child in env_node.get_children():
		var sb = null
		for c in child.get_children():
			if c is StaticBody3D:
				sb = c
				break
		if sb != null:
			total_static_bodies += 1
			for sbc in sb.get_children():
				if sbc is CollisionShape3D and sbc.shape is ConcavePolygonShape3D:
					if sbc.shape.backface_collision:
						total_backface_shapes += 1
		for k in structural_checked.keys():
			if k.to_lower() in child.name.to_lower():
				if sb != null:
					structural_checked[k] = true

	print("  -> Total StaticBody3Ds created on GLB meshes: %d" % total_static_bodies)
	print("  -> Total ConcavePolygonShape3Ds with backface_collision = true: %d" % total_backface_shapes)
	assert(total_static_bodies >= 240, "Must create collision on at least 240 structural meshes (got %d)" % total_static_bodies)
	assert(total_backface_shapes == total_static_bodies, "All generated trimesh shapes must have backface_collision enabled!")

	for k in structural_checked.keys():
		print("  -> Structural mesh '%s' has collision: %s" % [k, str(structural_checked[k])])
		assert(structural_checked[k] == true, "Mesh '%s' MUST have collision!" % k)

	print("[PASS] All structural meshes have trimesh collision with backface_collision enabled.")

	# Cleanup
	uwian_instance.free()
	main_instance.free()
	map_instance.free()

	print("\n==================================================")
	print("[ALL VERIFICATIONS PASSED CLEANLY!]")
	print("==================================================")
	quit(0)
