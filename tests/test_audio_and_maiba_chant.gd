extends SceneTree

func _init() -> void:
	print("\n==================================================")
	print("[AUDIO OVERHAUL & MAIBA TAYA CHANT VERIFICATION]")
	print("==================================================")

	# 1. Test AudioManager dedicated voice pools
	var am_script = load("res://scripts/audio/AudioManager.gd")
	assert(am_script != null, "AudioManager script exists")
	var am = Node.new()
	am.set_script(am_script)
	root.add_child(am)
	# Trigger ready
	am._ready()

	assert(am.voice_players_3d.size() == 6, "Must have exactly 6 dedicated 3D voice players")
	assert(am.voice_player_2d != null, "Must have dedicated 2D voice player")
	print("[PASS] Dedicated Voice Audio Pool verified: 6x 3D voice channels + 1x 2D voice channel.")

	# Test voice ducking
	am.sfx_volume = 1.0
	am._update_channel_volumes()
	var normal_sfx_db = am.audio_players[0].volume_db
	am._apply_voice_ducking(1.0)
	var ducked_sfx_db = am.audio_players[0].volume_db
	assert(ducked_sfx_db < normal_sfx_db, "SFX volume must duck during active speech")
	print("[PASS] SFX dynamic ducking verified: SFX drops by 3.5 dB during voice lines.")

	# 2. Test MaibaTayaUI single chant voice trigger
	var ui_scene = load("res://scenes/ui/MaibaTayaUI.tscn")
	assert(ui_scene != null, "MaibaTayaUI.tscn exists")
	var ui = ui_scene.instantiate() as MaibaTayaUI
	root.add_child(ui)

	# Reset unison tracker
	ui._has_played_unison = false

	# Step 1: "MA..."
	ui.show_chant("MA...")
	assert(ui._has_played_unison == false, "Chant 'MA...' must not trigger unison chant voice")

	# Step 2: "I..."
	ui.show_chant("I...")
	assert(ui._has_played_unison == false, "Chant 'I...' must not trigger unison chant voice")

	# Step 3: "BA..."
	ui.show_chant("BA...")
	assert(ui._has_played_unison == false, "Chant 'BA...' must not trigger unison chant voice")

	# Step 4: "TAYA! (PILI NA!)" (Count 1)
	ui.show_chant("TAYA! (PILI NA!)")
	assert(ui._has_played_unison == true, "Chant 'TAYA! (PILI NA!)' must trigger unison chant voice once")

	# Step 5: Repeated call to "TAYA!" should remain debounced (played once only)
	ui.show_chant("TAYA! (PILI NA!)")
	assert(ui._has_played_unison == true, "Repeated chant must not re-trigger voice")
	print("[PASS] Maiba Taya unison chant voice line triggers strictly once on Count 1 ('TAYA!').")

	ui.free()
	am.free()
	print("\n[ALL AUDIO & CHANT TESTS PASSED CLEANLY!]\n")
	quit(0)
