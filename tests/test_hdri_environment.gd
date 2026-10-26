extends SceneTree

func _init() -> void:
	run_tests()

func run_tests() -> void:
	print("\n=======================================================")
	print("[TEST] Verifying HDRI Sky & Golden Hour Environment...")
	print("=======================================================")

	# 1. VERIFY KALYE MATCH MAP (SUBURBAN KALYE)
	print("\n[1] Testing Suburban Kalye (KalyeMatchMap.tscn)...")
	var match_map_scene = load("res://scenes/maps/KalyeMatchMap.tscn")
	assert(match_map_scene != null, "KalyeMatchMap.tscn must load successfully")
	var match_map = match_map_scene.instantiate()
	root.add_child(match_map)

	var we_match: WorldEnvironment = match_map.find_child("WorldEnvironment", true, false)
	assert(we_match != null, "KalyeMatchMap must have WorldEnvironment")
	var env_match: Environment = we_match.environment
	assert(env_match != null, "KalyeMatchMap must have Environment resource")

	assert(env_match.background_mode == Environment.BG_SKY, "background_mode must be BG_SKY (2)")
	assert(env_match.sky != null, "sky must not be null")
	assert(env_match.sky.sky_material is PanoramaSkyMaterial, "sky_material must be PanoramaSkyMaterial")

	var pano_match: PanoramaSkyMaterial = env_match.sky.sky_material
	assert(pano_match.panorama != null, "panorama texture must be loaded")
	assert(pano_match.panorama.resource_path == "res://assets/models/HDRI/HDRI.hdr", "panorama must be HDRI.hdr")
	print("  -> Panorama texture verified: %s (%s)" % [pano_match.panorama.resource_path, pano_match.panorama.get_class()])

	assert(env_match.ambient_light_source == Environment.AMBIENT_SOURCE_SKY, "ambient_light_source must be AMBIENT_SOURCE_SKY (3)")
	assert(env_match.reflected_light_source == Environment.REFLECTION_SOURCE_SKY, "reflected_light_source must be REFLECTION_SOURCE_SKY (2)")
	assert(env_match.fog_enabled == true, "fog_enabled must be true")
	print("  -> Ambient light source: SKY, Reflected light source: SKY, Fog enabled: %s" % str(env_match.fog_enabled))
	print("  -> Fog depth range: %.1fm to %.1fm, Color: %s" % [env_match.fog_depth_begin, env_match.fog_depth_end, str(env_match.fog_light_color)])

	var sun_match: DirectionalLight3D = match_map.find_child("SunLight", true, false)
	assert(sun_match != null and sun_match.shadow_enabled, "SunLight must exist with shadows enabled")
	print("  -> SunLight: color=%s, energy=%.2f, shadow_enabled=%s" % [str(sun_match.light_color), sun_match.light_energy, str(sun_match.shadow_enabled)])
	print("[PASS] KalyeMatchMap HDRI & Golden Hour atmosphere verified cleanly.")

	match_map.free()

	# 2. VERIFY CLASSIC KALYE (KALYEMAP)
	print("\n[2] Testing Classic Kalye (KalyeMap.tscn)...")
	var classic_map_scene = load("res://scenes/maps/KalyeMap.tscn")
	assert(classic_map_scene != null, "KalyeMap.tscn must load successfully")
	var classic_map = classic_map_scene.instantiate()
	root.add_child(classic_map)

	var we_classic: WorldEnvironment = classic_map.find_child("WorldEnvironment", true, false)
	assert(we_classic != null, "KalyeMap must have WorldEnvironment")
	var env_classic: Environment = we_classic.environment
	assert(env_classic != null, "KalyeMap must have Environment resource")

	assert(env_classic.background_mode == Environment.BG_SKY, "background_mode must be BG_SKY (2)")
	assert(env_classic.sky != null, "sky must not be null")
	assert(env_classic.sky.sky_material is PanoramaSkyMaterial, "sky_material must be PanoramaSkyMaterial")

	var pano_classic: PanoramaSkyMaterial = env_classic.sky.sky_material
	assert(pano_classic.panorama != null, "panorama texture must be loaded")
	assert(pano_classic.panorama.resource_path == "res://assets/models/HDRI/HDRI.hdr", "panorama must be HDRI.hdr")
	print("  -> Panorama texture verified: %s (%s)" % [pano_classic.panorama.resource_path, pano_classic.panorama.get_class()])

	assert(env_classic.ambient_light_source == Environment.AMBIENT_SOURCE_SKY, "ambient_light_source must be AMBIENT_SOURCE_SKY (3)")
	assert(env_classic.reflected_light_source == Environment.REFLECTION_SOURCE_SKY, "reflected_light_source must be REFLECTION_SOURCE_SKY (2)")
	assert(env_classic.fog_enabled == true, "fog_enabled must be true")
	print("  -> Ambient light source: SKY, Reflected light source: SKY, Fog enabled: %s" % str(env_classic.fog_enabled))
	print("  -> Fog depth range: %.1fm to %.1fm, Color: %s" % [env_classic.fog_depth_begin, env_classic.fog_depth_end, str(env_classic.fog_light_color)])

	var sun_classic: DirectionalLight3D = classic_map.find_child("SunLight", true, false)
	assert(sun_classic != null and sun_classic.shadow_enabled, "SunLight must exist with shadows enabled")
	print("  -> SunLight: color=%s, energy=%.2f, shadow_enabled=%s" % [str(sun_classic.light_color), sun_classic.light_energy, str(sun_classic.shadow_enabled)])
	print("[PASS] KalyeMap HDRI & Golden Hour atmosphere verified cleanly.")

	classic_map.free()

	print("\n=======================================================")
	print("[ALL HDRI ATMOSPHERE VERIFICATIONS PASSED CLEANLY!]")
	print("=======================================================")
	quit(0)
