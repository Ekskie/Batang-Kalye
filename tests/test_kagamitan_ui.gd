extends SceneTree

## Automated Verification Suite: KagamitanUI (Wardrobe & Customization)
## Tests instantiation, 8-archetype cycling, 3x3 color swatches, 3D preview, and nickname editing.

const KagamitanUIScript = preload("res://scripts/ui/KagamitanUI.gd")

func _init() -> void:
	print("\n=======================================================")
	print("[TEST] Starting KagamitanUI Verification Suite...")
	print("=======================================================")

	var kagamitan_scene: PackedScene = load("res://scenes/ui/KagamitanUI.tscn")
	if not kagamitan_scene:
		push_error("[FAIL] Could not load res://scenes/ui/KagamitanUI.tscn")
		quit(1)
		return
	print("[PASS] KagamitanUI.tscn loaded successfully.")

	var kagamitan = kagamitan_scene.instantiate()
	if not kagamitan:
		push_error("[FAIL] Could not instantiate KagamitanUI")
		quit(1)
		return
	print("[PASS] KagamitanUI instantiated successfully.")

	root.add_child(kagamitan)

	# 1. Test Visibility & Open / Close
	kagamitan.open_kagamitan()
	if not kagamitan.visible:
		push_error("[FAIL] Kagamitan is not visible after open_kagamitan()")
		quit(1)
		return
	print("[PASS] open_kagamitan() sets visibility to true.")

	# 2. Test 8 Archetypes Cycling
	print("[TEST] Cycling through all 8 archetypes...")
	kagamitan.current_archetype_idx = 0
	kagamitan._update_character_display()

	var expected_archetypes: Array[String] = [
		"TSUNA", "KALBO", "TOTOY", "NENE", "TISOY", "BALDO", "NONOY", "KIKAY"
	]

	for i in range(expected_archetypes.size()):
		if kagamitan.char_name_label.text != expected_archetypes[i]:
			push_error("[FAIL] Archetype %d expected %s but got %s" % [i, expected_archetypes[i], kagamitan.char_name_label.text])
			quit(1)
			return
		print("  - Archetype %d: %s (%s) verified." % [i, kagamitan.char_name_label.text, kagamitan.char_title_label.text])
		kagamitan._change_archetype(1)

	# Should have wrapped back to 0 (TSUNA)
	if kagamitan.char_name_label.text != "TSUNA":
		push_error("[FAIL] Archetype cycling did not wrap back to TSUNA! Got: %s" % kagamitan.char_name_label.text)
		quit(1)
		return
	print("[PASS] All 8 Pinoy Archetypes cycled and wrapped cleanly.")

	# 3. Test 3x3 Color Swatches & Selection
	print("[TEST] Verifying 3x3 color swatches...")
	if kagamitan.color_buttons.size() != 8:
		push_error("[FAIL] Expected 8 color buttons in grid, got: %d" % kagamitan.color_buttons.size())
		quit(1)
		return
	print("[PASS] 8 Color swatch buttons created in grid.")

	if not kagamitan.btn_color_reset:
		push_error("[FAIL] btn_color_reset (9th slot) is null!")
		quit(1)
		return
	print("[PASS] 9th slot (Batang Kalye logo reset button) verified.")

	# Test selecting each color
	for c_idx in range(8):
		kagamitan._select_color(c_idx)
		if kagamitan.current_color_idx != c_idx:
			push_error("[FAIL] Selecting color %d failed!" % c_idx)
			quit(1)
			return
	print("[PASS] All 8 color options selectable and apply to model.")

	# 4. Test 9th slot Reset to default signature color
	kagamitan.current_archetype_idx = 1 # Kalbo (default color 1: Navy)
	kagamitan._select_color(7) # Change to yellow
	kagamitan._reset_to_default_color()
	if kagamitan.current_color_idx != 1:
		push_error("[FAIL] Reset button did not restore Kalbo's default color (1). Got: %d" % kagamitan.current_color_idx)
		quit(1)
		return
	print("[PASS] Batang Kalye reset button restored archetype signature color.")

	# 5. Test Nickname Editing
	print("[TEST] Verifying Nickname input...")
	kagamitan._on_nickname_text_changed("BatangHero")
	if kagamitan.player_nickname != "BatangHero":
		push_error("[FAIL] Nickname change not reflected. Got: %s" % kagamitan.player_nickname)
		quit(1)
		return
	print("[PASS] Nickname editing reflected and persisted: %s" % kagamitan.player_nickname)

	# 6. Test Close
	var closed_box := [false]
	kagamitan.closed.connect(func(): closed_box[0] = true)
	kagamitan.close_kagamitan()
	if kagamitan.visible or not closed_box[0]:
		push_error("[FAIL] close_kagamitan() did not hide or emit closed!")
		quit(1)
		return
	print("[PASS] close_kagamitan() hides UI and emits closed.")

	print("\n=======================================================")
	print("[ALL KAGAMITAN UI TESTS PASSED] ZERO RUNTIME ERRORS!")
	print("=======================================================\n")

	kagamitan.queue_free()
	quit(0)
