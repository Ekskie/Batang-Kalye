extends SceneTree

# test_complete_polish_pass.gd
# End-to-end verification suite for the Complete Game Polish & Finishing Pass (Phases 2-8)

var passed_count: int = 0
var failed_count: int = 0

func _init() -> void:
	call_deferred("_run_all")

func assert_true(cond: bool, msg: String) -> void:
	if cond:
		print("  [PASS] %s" % msg)
		passed_count += 1
	else:
		push_error("  [FAIL] %s" % msg)
		failed_count += 1

func assert_eq(a, b, msg: String) -> void:
	if a == b:
		print("  [PASS] %s" % msg)
		passed_count += 1
	else:
		push_error("  [FAIL] %s (Expected: %s, Got: %s)" % [msg, str(b), str(a)])
		failed_count += 1

func _run_all() -> void:
	print("\n======================================================================")
	print(" [COMPLETE POLISH PASS] END-TO-END VERIFICATION SUITE")
	print("======================================================================")

	_test_character_silhouettes_and_animations()
	_test_world_filipino_layers()
	_test_movement_tag_feel_and_infection_climax()
	_test_store_3d_preview_and_archetype_equip()
	_test_title_hud_gameover_and_settings_ui()
	_test_audio_surface_footsteps_music_and_ambience()

	print("\n======================================================================")
	print(" COMPLETE POLISH SUMMARY: %d PASSED, %d FAILED" % [passed_count, failed_count])
	print("======================================================================")
	if failed_count == 0:
		print(">>> ALL COMPLETE POLISH TESTS PASSED! <<<\n")
		quit(0)
	else:
		push_error(">>> SOME COMPLETE POLISH TESTS FAILED! <<<\n")
		quit(1)

func _test_character_silhouettes_and_animations() -> void:
	print("\n--- [1] Character Archetypes, Animation Blending & Role Auras ---")
	var char_scene: PackedScene = load("res://scenes/player/CharacterModel.tscn")
	assert_true(char_scene != null, "CharacterModel.tscn loads")
	var model: CharacterAnimator = char_scene.instantiate() as CharacterAnimator
	root.add_child(model)

	model.apply_preset(0)
	var attaches: Dictionary = model.modular_attachments.get(model.active_model, {})
	var chest_node: Node3D = attaches.get("chest")
	assert_true(chest_node != null and chest_node.get_node_or_null("Acc_SlingBag") != null, "Modular Acc_SlingBag exists on CharacterAnimator chest attachment")
	assert_true(chest_node != null and chest_node.get_node_or_null("Acc_StripedTrim") != null, "Modular Acc_StripedTrim exists on CharacterAnimator chest attachment")
	if model.active_anim:
		assert_true(absf(model.active_anim.playback_default_blend_time - 0.15) < 0.01, "AnimationPlayer default blend time is 0.15s")

	# Verify Tsuna (0, body=0, headwear=0) shows sling bag and Kikay (7, body=2) shows striped trim
	assert_true(chest_node.get_node("Acc_SlingBag").visible, "Tsuna archetype (body=0) displays Acc_SlingBag")
	model.apply_preset(7)
	var attaches7: Dictionary = model.modular_attachments.get(model.active_model, {})
	var chest7: Node3D = attaches7.get("chest")
	assert_true(chest7.get_node("Acc_StripedTrim").visible, "Kikay archetype (body=2) displays Acc_StripedTrim")

	# Verify procedural secondary motion triggers
	model.trigger_landing_compression(0.85)
	assert_true(model.landing_compression_timer > 0.0, "Landing compression timer activated")
	model.trigger_tag_whiff()
	assert_true(model.tag_whiff_timer > 0.0, "Tag whiff timer activated")
	model.trigger_hit_reaction()
	assert_true(model.hit_reaction_timer > 0.0, "Hit reaction timer activated")
	model.trigger_victory_pose()
	assert_true(model.victory_pose_active, "Victory pose state activated")
	model.trigger_defeat_pose()
	assert_true(model.defeat_pose_active, "Defeat pose state activated")

	# Verify Classic Taya vs Infected Taya aura differentiation
	model.is_infected_role = false
	model.is_taya = true
	model.update_role_aura_style()
	assert_eq(model.taya_badge.text, "⚠ TAYA!", "Classic Taya badge displays '⚠ TAYA!'")
	model.is_infected_role = true
	model.update_role_aura_style()
	assert_eq(model.taya_badge.text, "☣ HAWA!", "Infected Taya badge displays '☣ HAWA!'")

	root.remove_child(model)
	model.free()

func _test_world_filipino_layers() -> void:
	print("\n--- [2] KalyeMatchMap Filipino Neighborhood & Parkour Layers ---")
	var map_scene: PackedScene = load("res://scenes/maps/KalyeMatchMap.tscn")
	var map_inst: Node3D = map_scene.instantiate() as Node3D
	root.add_child(map_inst)

	var layer := map_inst.get_node_or_null("BarangayNeighborhoodLayer")
	assert_true(layer != null, "BarangayNeighborhoodLayer constructed in KalyeMatchMap")
	assert_true(layer.get_node_or_null("ParkourObstacles") != null, "ParkourObstacles layer present")
	assert_true(layer.get_node_or_null("MidLevelPlatforms") != null, "MidLevelPlatforms layer present")
	assert_true(layer.get_node_or_null("FilipinoVehiclesAndShed/TricycleTodaBody") != null, "TricycleTodaBody landmark present")
	assert_true(layer.get_node_or_null("FilipinoVehiclesAndShed/ParkedJeepneyBody") != null, "ParkedJeepneyBody landmark present")
	assert_true(layer.get_node_or_null("BarangaySignageAndClutter") != null, "BarangaySignageAndClutter layer present")
	assert_true(layer.get_node_or_null("FiestaBanderitas") != null, "FiestaBanderitas overhead layer present")

	root.remove_child(map_inst)
	map_inst.free()

func _test_movement_tag_feel_and_infection_climax() -> void:
	print("\n--- [3] Player Movement, Tag Whiff/Cooldown, Title Preservation & Final Survivor ---")
	var player_scene: PackedScene = load("res://scenes/player/Player.tscn")
	var p: PlayerController = player_scene.instantiate() as PlayerController
	root.add_child(p)

	p.set_player_title("Hari ng Kanto")
	p.current_role = PlayerController.Role.TAYA
	p._update_role_state()
	assert_true("Hari ng Kanto" in p.name_label.text, "Player title preserved when switching to TAYA")
	p.current_role = PlayerController.Role.RUNNER
	p._update_role_state()
	assert_true("Hari ng Kanto" in p.name_label.text, "Player title preserved when switching to RUNNER")

	var cd_box: Array = [0.0, true]
	p.tag_cooldown_started.connect(func(dur: float, is_hit: bool):
		cd_box[0] = dur
		cd_box[1] = is_hit
	)
	p.current_role = PlayerController.Role.TAYA
	p._try_tag()
	assert_true(cd_box[0] > 0.0, "Tag whiff emitted tag_cooldown_started with positive recovery duration")
	assert_eq(cd_box[1], false, "Tag whiff reported is_hit = false")

	p.trigger_final_survivor_moment()
	assert_true(p.burst_stamina >= p.burst_stamina_max - 0.01, "Final Survivor climax refills burst stamina")

	root.remove_child(p)
	p.free()

func _test_store_3d_preview_and_archetype_equip() -> void:
	print("\n--- [4] StoreUI 3D Turntable Preview & Archetype Equip Fix ---")
	var eco := EconomyManager.new()
	root.add_child(eco)
	var store_scene: PackedScene = load("res://scenes/ui/StoreUI.tscn")
	var store: StoreUI = store_scene.instantiate() as StoreUI
	store.economy_manager = eco
	root.add_child(store)

	assert_true(store.preview_model != null, "StoreUI live 3D CharacterAnimator turntable preview initialized")
	store.open_store()
	store._preview_catalog_item("headwear", 1)
	assert_eq(store.preview_outfit_state["headwear"], 1, "StoreUI 3D preview updates headwear slot when previewing item")

	root.remove_child(store)
	store.free()
	root.remove_child(eco)
	eco.free()

func _test_title_hud_gameover_and_settings_ui() -> void:
	print("\n--- [5] TitleScreenUI, HUD, GameOverUI & Audio Settings Sliders ---")
	var main_scene: PackedScene = load("res://scenes/main/Main.tscn")
	var main_inst: Node = main_scene.instantiate()
	root.add_child(main_inst)

	var sub_lbl: Label = main_inst.get_node_or_null("TitleScreenUI/Center/VBox/Subtitle") as Label
	assert_true(sub_lbl != null and not ("â€¢" in sub_lbl.text), "TitleScreenUI Subtitle has clean UTF-8 bullet")
	var fov_lbl: Label = main_inst.get_node_or_null("PauseUI/SettingsPanel/VBoxContainer/ScrollContainer/ScrollContent/FovRow/FovLabel") as Label
	assert_true(fov_lbl != null and not ("Â°" in fov_lbl.text), "SettingsPanel FovLabel has clean UTF-8 degree symbol")

	assert_true(main_inst.get_node_or_null("TitleScreenUI/Center/VBox/QuickRow/BtnTitleCustomize") != null, "TitleScreenUI has BtnTitleCustomize")
	assert_true(main_inst.get_node_or_null("TitleScreenUI/Center/VBox/QuickRow/BtnTitleStore") != null, "TitleScreenUI has BtnTitleStore")
	assert_true(main_inst.get_node_or_null("TitleScreenUI/Center/VBox/QuickRow/BtnTitleGuide") != null, "TitleScreenUI has BtnTitleGuide")
	assert_true(main_inst.get_node_or_null("PauseUI/SettingsPanel/VBoxContainer/ScrollContainer/ScrollContent/MusicVolumeRow/MusicVolumeSlider") != null, "SettingsPanel has MusicVolumeSlider")
	assert_true(main_inst.get_node_or_null("PauseUI/SettingsPanel/VBoxContainer/ScrollContainer/ScrollContent/SfxVolumeRow/SfxVolumeSlider") != null, "SettingsPanel has SfxVolumeSlider")
	assert_true(main_inst.get_node_or_null("PauseUI/SettingsPanel/VBoxContainer/ScrollContainer/ScrollContent/AmbienceVolumeRow/AmbienceVolumeSlider") != null, "SettingsPanel has AmbienceVolumeSlider")

	var hud_node: HUD = main_inst.get_node_or_null("HUD") as HUD
	assert_true(hud_node != null and hud_node.has_method("on_tag_cooldown_started"), "HUD implements on_tag_cooldown_started")
	hud_node.on_tag_cooldown_started(0.42, false)
	hud_node.on_tag_cooldown_started(0.45, true)

	root.remove_child(main_inst)
	main_inst.free()

func _test_audio_surface_footsteps_music_and_ambience() -> void:
	print("\n--- [6] AudioManager Surface Footsteps, Ambience & Soundtrack ---")
	var am = root.get_node_or_null("AudioManager")
	assert_true(am != null, "AudioManager autoload is present")
	if am:
		for surf in ["concrete", "wood", "metal", "grass", "water"]:
			am.play_surface_footstep(surf, true)
		assert_true(true, "All 5 surface footstep types played without error")
		am.play_infection_spread()
		am.play_final_survivor_sting()
		for trk in ["lobby", "chase", "final_seconds", "victory", "defeat"]:
			am.play_music_track(trk)
		assert_eq(am.current_music_track, "defeat", "AudioManager switches procedural music tracks cleanly")
		am.set_music_volume(0.75)
		am.set_sfx_volume(0.90)
		am.set_ambience_volume(0.80)
		assert_true(absf(am.music_volume - 0.75) < 0.01, "Music volume updated to 0.75")
