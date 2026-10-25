extends SceneTree

## Automated Verification Suite: GameOverUI (Uwian Na! Minimalist Results Redesign)
## Tests instantiation, 3D MVP viewport, minimalist leaderboard rows, header chips, and action buttons.

const GameOverUIScript = preload("res://scripts/ui/GameOverUI.gd")

func _init() -> void:
	print("\n=======================================================")
	print("[TEST] Starting GameOverUI Verification Suite...")
	print("=======================================================")

	var go_scene: PackedScene = load("res://scenes/ui/GameOverUI.tscn")
	if not go_scene:
		push_error("[FAIL] Could not load res://scenes/ui/GameOverUI.tscn")
		quit(1)
		return
	print("[PASS] GameOverUI.tscn loaded successfully.")

	var go_ui = go_scene.instantiate()
	if not go_ui:
		push_error("[FAIL] Could not instantiate GameOverUI")
		quit(1)
		return
	print("[PASS] GameOverUI instantiated successfully.")

	root.add_child(go_ui)

	# Mock match data with 4 players
	var mock_players: Array[Dictionary] = [
		{
			"id": 1,
			"name": "Totoy",
			"score": 1080,
			"status": "LIGTAS",
			"huli": 4,
			"dulas": 1,
			"basura": 3,
			"patama": 2,
			"tago": 1,
			"character": 2, # Totoy
			"is_taya": false,
			"surv": 120.0,
			"distance": 350.0,
			"escapes": 4
		},
		{
			"id": 2,
			"name": "Tsuna",
			"score": 650,
			"status": "LIGTAS",
			"huli": 2,
			"dulas": 0,
			"basura": 1,
			"patama": 0,
			"tago": 2,
			"character": 0,
			"is_taya": false,
			"surv": 100.0,
			"distance": 220.0,
			"escapes": 2
		},
		{
			"id": 3,
			"name": "Kalbo",
			"score": 420,
			"status": "TAYA",
			"huli": 5,
			"dulas": 2,
			"basura": 0,
			"patama": 3,
			"tago": 0,
			"character": 1,
			"is_taya": true,
			"surv": 45.0,
			"distance": 400.0,
			"escapes": 1
		},
		{
			"id": 4,
			"name": "Nene",
			"score": 310,
			"status": "OUT",
			"huli": 1,
			"dulas": 1,
			"basura": 0,
			"patama": 0,
			"tago": 0,
			"character": 3,
			"is_taya": false,
			"surv": 30.0,
			"distance": 80.0,
			"escapes": 0
		}
	]

	var mock_meta: Dictionary = {
		"mode_name": "Pasa-Taya Elimination",
		"duration": 185.0,
		"taya_name": "Kalbo",
		"max_players": 8
	}

	var mock_awards: Dictionary = {
		"taya_master": "Kalbo",
		"escape_artist": "Totoy",
		"vault_king": "Totoy",
		"sprint_king": "Tsuna",
		"basura": "Totoy"
	}

	# 1. Test display_game_over
	go_ui.display_game_over(mock_players, mock_meta, mock_awards)
	if not go_ui.visible:
		push_error("[FAIL] GameOverUI is not visible after display_game_over()")
		quit(1)
		return
	print("[PASS] display_game_over() sets visibility to true.")

	# 2. Verify Minimalist Leaderboard Rows
	if not go_ui.rows_container or go_ui.rows_container.get_child_count() != 4:
		push_error("[FAIL] RowsContainer did not populate 4 player rows!")
		quit(1)
		return
	print("[PASS] 4 Minimalist leaderboard player rows populated successfully.")

	# 3. Verify Top Player (MVP) 3D Viewport
	if not go_ui.mvp_preview_root:
		push_error("[FAIL] mvp_preview_root node is null!")
		quit(1)
		return
	if not go_ui.mvp_model:
		push_error("[FAIL] mvp_model was not instantiated into SubViewport!")
		quit(1)
		return
	print("[PASS] Live 3D MVP character model instantiated and active in SubViewport.")

	if go_ui.mvp_name_label.text != "TOTOY":
		push_error("[FAIL] Expected MVP name TOTOY, got: %s" % go_ui.mvp_name_label.text)
		quit(1)
		return
	print("[PASS] MVP Champion details populated: %s (%s)" % [go_ui.mvp_name_label.text, go_ui.mvp_role_badge.text])

	# 4. Verify Minimalist Header Chips
	if not go_ui.mode_label or not go_ui.meta_summary_label:
		push_error("[FAIL] Header chips are null!")
		quit(1)
		return
	if not go_ui.mode_label.text.contains("PASA-TAYA ELIMINATION"):
		push_error("[FAIL] Mode label text unexpected: %s" % go_ui.mode_label.text)
		quit(1)
		return
	print("[PASS] Minimalist Header chips populated: %s | %s" % [go_ui.mode_label.text, go_ui.meta_summary_label.text])

	# 5. Verify Three Action Buttons & Signals
	var rematch_emitted := [false]
	var store_emitted := [false]
	var lobby_emitted := [false]

	go_ui.rematch_requested.connect(func(): rematch_emitted[0] = true)
	go_ui.store_requested.connect(func(): store_emitted[0] = true)
	go_ui.lobby_requested.connect(func(): lobby_emitted[0] = true)

	if not go_ui.btn_rematch or not go_ui.btn_store or not go_ui.btn_lobby:
		push_error("[FAIL] One or more action buttons are null!")
		quit(1)
		return
	print("[PASS] All action buttons (Rematch, Store, Lobby) verified.")

	go_ui.btn_rematch.emit_signal("pressed")
	if not rematch_emitted[0]:
		push_error("[FAIL] btn_rematch did not emit rematch_requested!")
		quit(1)
		return
	print("[PASS] btn_rematch emitted rematch_requested.")

	go_ui.btn_store.emit_signal("pressed")
	if not store_emitted[0]:
		push_error("[FAIL] btn_store did not emit store_requested!")
		quit(1)
		return
	print("[PASS] btn_store emitted store_requested.")

	go_ui.btn_lobby.emit_signal("pressed")
	if not lobby_emitted[0]:
		push_error("[FAIL] btn_lobby did not emit lobby_requested!")
		quit(1)
		return
	print("[PASS] btn_lobby emitted lobby_requested.")

	print("\n=======================================================")
	print("[ALL GAMEOVER UI TESTS PASSED] ZERO RUNTIME ERRORS!")
	print("=======================================================\n")

	go_ui.queue_free()
	quit(0)
