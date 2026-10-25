extends SceneTree

# tests/test_audio_immersion_and_vfx_juice.gd
# Verification suite for Authentic Pinoy Audio Immersion & Visual Game Juice

var passed: int = 0
var failed: int = 0

func _init() -> void:
	call_deferred("_run_all_tests")

func assert_true(cond: bool, msg: String) -> void:
	if cond:
		print("  [PASS] %s" % msg)
		passed += 1
	else:
		push_error("  [FAIL] %s" % msg)
		failed += 1

func assert_eq(a, b, msg: String) -> void:
	if a == b:
		print("  [PASS] %s" % msg)
		passed += 1
	else:
		push_error("  [FAIL] %s (Expected %s, Got %s)" % [msg, str(b), str(a)])
		failed += 1

func _run_all_tests() -> void:
	print("\n======================================================================")
	print(" [AUDIO IMMERSION & VISUAL GAME JUICE VERIFICATION SUITE] ")
	print("======================================================================")

	await _test_audio_assets_and_loading()
	await _test_character_archetype_pitch_scales()
	await _test_comic_floating_text_popups()
	await _test_particles_and_player_juice()
	await _test_canal_water_splash_juice()

	print("\n======================================================================")
	print(" SUITE SUMMARY: %d Passed, %d Failed" % [passed, failed])
	print("======================================================================")
	if failed == 0:
		print(" ALL AUDIO IMMERSION & GAME JUICE TESTS PASSED SUCCESSFULLY!")
		quit(0)
	else:
		print(" VERIFICATION SUITE COMPLETED WITH FAILURES.")
		quit(1)

func _test_audio_assets_and_loading() -> void:
	print("\n--- 1. Testing Starter WAV Assets & AudioManager Loading ---")
	var am = root.get_node_or_null("AudioManager")
	if not am:
		var am_script = load("res://scripts/audio/AudioManager.gd")
		assert_true(am_script != null, "AudioManager script loads cleanly")
		am = Node.new()
		am.set_script(am_script)
		am.name = "AudioManager"
		root.add_child(am)
		await process_frame

	assert_true(am != null, "AudioManager instance available")

	# Check voice files
	var vo_files := [
		"res://assets/audio/vo/vo_taya_ka.wav",
		"res://assets/audio/vo/vo_huli.wav",
		"res://assets/audio/vo/vo_aray.wav",
		"res://assets/audio/vo/vo_sapul.wav",
		"res://assets/audio/vo/vo_safe.wav",
		"res://assets/audio/vo/vo_hup.wav",
		"res://assets/audio/vo/vo_dulas.wav"
	]
	for vf in vo_files:
		assert_true(FileAccess.file_exists(vf), "VO file exists on disk: %s" % vf.get_file())

	# Check ambient files
	var amb_files := [
		"res://assets/audio/ambience/amb_rooster.wav",
		"res://assets/audio/ambience/amb_trike_horn.wav"
	]
	for af in amb_files:
		assert_true(FileAccess.file_exists(af), "Ambience file exists on disk: %s" % af.get_file())

	# Check loaded streams on AudioManager
	assert_true(am.vo_taya_ka != null, "am.vo_taya_ka loaded successfully")
	assert_true(am.vo_huli != null, "am.vo_huli loaded successfully")
	assert_true(am.vo_aray != null, "am.vo_aray loaded successfully")
	assert_true(am.vo_sapul != null, "am.vo_sapul loaded successfully")
	assert_true(am.vo_safe != null, "am.vo_safe loaded successfully")
	assert_true(am.vo_hup != null, "am.vo_hup loaded successfully")
	assert_true(am.vo_dulas != null, "am.vo_dulas loaded successfully")
	assert_true(am.amb_rooster != null, "am.amb_rooster loaded successfully")
	assert_true(am.amb_trike_horn != null, "am.amb_trike_horn loaded successfully")

func _test_character_archetype_pitch_scales() -> void:
	print("\n--- 2. Testing Character Archetype Pitch Shifting ---")
	var am = root.get_node_or_null("AudioManager")
	assert_true(am != null, "AudioManager is active")
	if not am:
		return

	# Archetypes: 0=Tsuna, 1=Kalbo, 2=Totoy, 3=Tisoy, 4=Nene
	var p_tsuna: float = am.get_character_pitch_scale(0)
	var p_kalbo: float = am.get_character_pitch_scale(1)
	var p_totoy: float = am.get_character_pitch_scale(2)
	var p_tisoy: float = am.get_character_pitch_scale(3)
	var p_nene: float = am.get_character_pitch_scale(4)

	assert_true(is_equal_approx(p_tsuna, 1.00), "Tsuna pitch scale is standard 1.00 (got %.2f)" % p_tsuna)
	assert_true(p_kalbo < 0.95, "Kalbo pitch scale is deeper < 0.95 (got %.2f)" % p_kalbo)
	assert_true(p_totoy > 1.05, "Totoy pitch scale is energetic > 1.05 (got %.2f)" % p_totoy)
	assert_true(p_tisoy < 1.01 and p_tisoy > 0.95, "Tisoy pitch scale is cool ~0.98 (got %.2f)" % p_tisoy)
	assert_true(p_nene > 1.18, "Nene pitch scale is high-pitched > 1.18 (got %.2f)" % p_nene)

	# Test 3D VO helper methods execute without crashing
	am.play_vo_taya(Vector3(0, 1, 0), 0)
	am.play_vo_huli(Vector3(0, 1, 0), 2)
	am.play_vo_aray(Vector3(0, 1, 0), 1)
	am.play_vo_sapul(Vector3(0, 1, 0), 3)
	am.play_vo_safe(Vector3(0, 1, 0), 4)
	am.play_vo_hup(Vector3(0, 1, 0), 0)
	am.play_vo_dulas(Vector3(0, 1, 0), 2)
	am.play_ambient_rooster()
	am.play_ambient_trike_horn()
	assert_true(true, "All 3D VO and ambient playback methods executed cleanly")

func _test_comic_floating_text_popups() -> void:
	print("\n--- 3. Testing Comic 3D Floating Text Popups ---")
	var ft_scene = load("res://scenes/player/FloatingText.tscn")
	assert_true(ft_scene != null, "FloatingText.tscn loads cleanly")
	if not ft_scene:
		return

	var ft: FloatingText = ft_scene.instantiate() as FloatingText
	root.add_child(ft)
	ft.setup("HULI KA! +1", Color(1.0, 0.88, 0.2))
	await process_frame

	assert_true(ft.label != null, "FloatingText has valid Label3D")
	assert_true(ft.label.text == "HULI KA! +1", "Text correctly configured on Label3D")
	assert_true(ft.label.font != null, "Custom font loaded on FloatingText Label3D")
	assert_true(ft.label.font_size >= 32, "Font size is chunky for mobile readability (>=32, got %d)" % ft.label.font_size)
	assert_true(ft.label.outline_size >= 8, "Dark ink outline size >= 8 for comic pop (got %d)" % ft.label.outline_size)
	assert_true(absf(ft.tilt_angle) > 0.001, "Comic tilt angle applied non-zero (%.2f deg)" % ft.tilt_angle)

	# Process frames to verify spring pop scaling
	ft._process(0.10)
	assert_true(ft.scale.x > 0.5, "FloatingText scales up dynamically during pop (scale: %.2f)" % ft.scale.x)

	ft.queue_free()
	await process_frame

func _test_particles_and_player_juice() -> void:
	print("\n--- 4. Testing Particle Juice & Player Movement Hookups ---")
	var player_scene = load("res://scenes/player/Player.tscn")
	assert_true(player_scene != null, "Player.tscn loads cleanly")
	if not player_scene:
		return

	var player = player_scene.instantiate()
	root.add_child(player)
	await process_frame
	await process_frame

	assert_true(player.slide_dust != null, "SlideDust CPUParticles3D node exists on Player")
	assert_true(player.water_splash != null, "WaterSplash CPUParticles3D node exists on Player")
	assert_true(player.powerup_aura != null, "PowerupAura CPUParticles3D node exists on Player")

	# Test get_character_type()
	var ctype: int = player.get_character_type()
	assert_true(ctype >= 0 and ctype <= 4, "player.get_character_type() returns valid archetype (%d)" % ctype)

	# Test slide dust activation
	player.is_sliding = true
	player.slide_timer = 0.5
	player._process(0.016)
	assert_true(player.slide_dust.emitting, "SlideDust emits during active slide")

	player.is_sliding = false
	player.slide_timer = 0.0

	# Test vault landing triggers slide dust restart
	player._trigger_vault(Vector3.ZERO, Vector3(0, 1.2, 1), Vector3(0, 0, 2))
	assert_true(player.is_vaulting, "Player entered is_vaulting on _trigger_vault")
	player._process_vault(player.vault_duration + 0.05)
	assert_true(not player.is_vaulting, "Player finished vault and landed")
	assert_true(player.slide_dust.emitting, "SlideDust emitted upon vault landing impact")

	player.queue_free()
	await process_frame

func _test_canal_water_splash_juice() -> void:
	print("\n--- 5. Testing Canal Water Splash Juice ---")
	var player_scene = load("res://scenes/player/Player.tscn")
	var player = player_scene.instantiate()
	root.add_child(player)
	await process_frame

	player.set_in_water(true)
	assert_true(player.is_in_water, "player.is_in_water is true")
	assert_true(player.water_splash.emitting, "WaterSplash particles emit when stepping into water")

	player.set_in_water(false)
	assert_true(not player.is_in_water, "player.is_in_water is false after exit")

	player.queue_free()
	await process_frame
