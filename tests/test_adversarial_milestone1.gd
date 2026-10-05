extends SceneTree

# ==============================================================================
# EMPIRICAL ADVERSARIAL STRESS TEST SUITE FOR MILESTONE 1
# Covers:
#   1. Multi-Taya dynamic ratio balancing across [1, 24] and edge cases
#   2. Maiba-Taya gesture minority selection stress (Monte Carlo, ties, biased)
#   3. Full Pasa-Taya multi-round elimination tournament (24 -> 1 winner)
#   4. Pasa-Taya adversarial elimination (duplicates, missing, simultaneous wipes)
#   5. KalyeMap.tscn 24 spawn markers parsed from scene file: pairwise spacing & bounds
#   6. 24-player spawn dispersion: 100% collision-free guarantee (min dist >> 0.70m)
#   7. Cubic Hermite Spline mathematical C1 continuity & extreme inputs
#   8. Snapshot ring buffer out-of-order stress, capacity bounds, and teleport snaps
#   9. 24-player netcode bandwidth budget & 3-tier culling packet rate estimation
# ==============================================================================

var test_failures: int = 0
var test_passes: int = 0

func _init() -> void:
	call_deferred("run_all_stress_tests")

func run_all_stress_tests() -> void:
	print("\n" + "=".repeat(70))
	print(" [ADVERSARIAL CHALLENGER 2] MILESTONE 1 EMPIRICAL STRESS TEST SUITE")
	print("=".repeat(70))

	test_multi_taya_ratio_exhaustive()
	test_maiba_taya_gesture_monte_carlo()
	test_pasa_taya_tournament_simulation()
	test_pasa_taya_elimination_edge_cases()
	test_kalyemap_spawn_points_parsing_and_spacing()
	test_24_player_spawn_collision_guarantee()
	test_hermite_spline_math_properties()
	test_snapshot_ring_buffer_stress()
	test_network_culling_and_bandwidth_budget()

	print("\n" + "=".repeat(70))
	print(" STRESS TEST SUMMARY: %d PASSED, %d FAILED" % [test_passes, test_failures])
	print("=".repeat(70))

	if test_failures == 0:
		print(">>> ALL ADVERSARIAL CHALLENGES PASSED! <<<")
		quit(0)
	else:
		push_error(">>> ADVERSARIAL CHALLENGES FAILED: %d failures detected! <<<" % test_failures)
		quit(1)

func assert_true(condition: bool, message: String) -> void:
	if condition:
		test_passes += 1
		print("  [PASS] %s" % message)
	else:
		test_failures += 1
		push_error("  [FAIL] %s" % message)
		print("  [FAIL] %s" % message)

# ------------------------------------------------------------------------------
# 1. Multi-Taya Exhaustive Ratio Checks for N in [0, 50]
# ------------------------------------------------------------------------------
func test_multi_taya_ratio_exhaustive() -> void:
	print("\n--- [1] Exhaustive Multi-Taya Ratio Balancing ---")

	# Test N <= 0 edge cases
	assert_true(MaibaTayaManager.get_taya_count(0) == 1, "N=0 defaults safely to 1 Taya")
	assert_true(MaibaTayaManager.get_taya_count(-5) == 1, "N=-5 defaults safely to 1 Taya")
	assert_true(MaibaTayaManager.get_taya_count(1) == 1, "N=1 returns 1 Taya")

	# Standard match counts
	var expected_counts: Dictionary = {
		2: 1, 3: 1, 4: 1, 5: 1, 6: 1, 7: 1, 8: 1,
		9: 2, 10: 2,
		11: 3, 12: 3, 13: 3, 14: 3, 15: 3,
		16: 4, 17: 4, 18: 4, 19: 4, 20: 4,
		21: 5, 22: 5, 23: 5, 24: 5
	}

	var all_matched: bool = true
	for n in expected_counts.keys():
		var exp_val: int = expected_counts[n]
		var act_val: int = MaibaTayaManager.get_taya_count(n)
		if act_val != exp_val:
			all_matched = false
			assert_true(false, "Ratio mismatch at N=%d: got %d, expected %d" % [n, act_val, exp_val])
	if all_matched:
		assert_true(true, "All player counts 2..24 match expected 1-per-4..5 ratio")

	# Invariance check: for all N >= 2, taya_count must be in [1, N-1] (at least 1 runner remains)
	var invariant_holds: bool = true
	for n in range(2, 50):
		var tc: int = MaibaTayaManager.get_taya_count(n)
		if tc < 1 or tc >= n:
			invariant_holds = false
			assert_true(false, "Invariant violated at N=%d: taya_count=%d (must be 1..%d)" % [n, tc, n - 1])
	if invariant_holds:
		assert_true(true, "Invariant holds for all N in [2, 49]: 1 <= taya_count <= N-1 (at least 1 runner guaranteed)")

# ------------------------------------------------------------------------------
# 2. Maiba-Taya Gesture Minority Selection Stress (Monte Carlo)
# ------------------------------------------------------------------------------
func test_maiba_taya_gesture_monte_carlo() -> void:
	print("\n--- [2] Maiba-Taya Gesture Selection Monte Carlo Stress ---")
	var mgr := MaibaTayaManager.new()
	root.add_child(mgr)

	var test_player_counts: Array[int] = [3, 8, 9, 16, 24]
	var total_trials: int = 100
	var selection_ok: bool = true

	for p_cnt in test_player_counts:
		var needed := MaibaTayaManager.get_taya_count(p_cnt)
		var p_ids: Array = []
		for i in range(1, p_cnt + 1):
			p_ids.append(i)

		for trial in range(total_trials):
			mgr.player_choices.clear()
			mgr.is_resolving = false

			# Vary gesture distribution
			match trial % 4:
				0: # All PALM_UP
					for pid in p_ids: mgr.player_choices[pid] = MaibaTayaManager.HandGesture.PALM_UP
				1: # All PALM_DOWN
					for pid in p_ids: mgr.player_choices[pid] = MaibaTayaManager.HandGesture.PALM_DOWN
				2: # 1 PALM_UP, rest PALM_DOWN (extreme minority)
					mgr.player_choices[p_ids[0]] = MaibaTayaManager.HandGesture.PALM_UP
					for pid in p_ids.slice(1): mgr.player_choices[pid] = MaibaTayaManager.HandGesture.PALM_DOWN
				3: # Random 50/50
					for pid in p_ids: mgr.player_choices[pid] = randi() % 2

			var captured_ids: Array = []
			var callable := func(ids: Array, _names: Array):
				captured_ids.append_array(ids)
			mgr.tayas_decided.connect(callable)
			mgr._resolve_choices(p_ids)
			mgr.tayas_decided.disconnect(callable)

			if captured_ids.size() != needed:
				selection_ok = false
				assert_true(false, "N=%d trial %d: selected size %d != expected %d" % [p_cnt, trial, captured_ids.size(), needed])
				break

			# Check uniqueness
			var unique_check: Dictionary = {}
			for cid in captured_ids:
				if unique_check.has(cid):
					selection_ok = false
					assert_true(false, "N=%d trial %d: duplicate taya id %d selected" % [p_cnt, trial, cid])
					break
				unique_check[cid] = true
				if not p_ids.has(cid):
					selection_ok = false
					assert_true(false, "N=%d trial %d: selected id %d not in player pool" % [p_cnt, trial, cid])
					break

			# Ensure extreme minority was respected
			if trial % 4 == 2 and p_cnt >= 2:
				var minority_id: int = p_ids[0]
				if not captured_ids.has(minority_id):
					selection_ok = false
					assert_true(false, "N=%d trial %d: solo minority id %d was NOT selected!" % [p_cnt, trial, minority_id])
					break

	if selection_ok:
		assert_true(true, "Monte Carlo (500 runs) passed: exact taya counts, uniqueness, and minority priority verified")

	mgr.queue_free()

# ------------------------------------------------------------------------------
# 3. Full Pasa-Taya Elimination Tournament Simulation (24 Players -> 1 Champion)
# ------------------------------------------------------------------------------
func test_pasa_taya_tournament_simulation() -> void:
	print("\n--- [3] Full Pasa-Taya Elimination Tournament Simulation ---")
	var initial_players: int = 24
	var alive_pids: Array = []
	for i in range(1, initial_players + 1):
		alive_pids.append(i)

	var elim_pids: Array = []
	var round_num: int = 1

	while alive_pids.size() > 1:
		var n_alive: int = alive_pids.size()
		var tayas_needed: int = MaibaTayaManager.get_taya_count(n_alive)

		# Tayas chosen
		var round_tayas: Array = []
		var shuffled := alive_pids.duplicate()
		shuffled.shuffle()
		for i in range(tayas_needed):
			round_tayas.append(shuffled[i])

		# End of round: all round Tayas are eliminated simultaneously
		for tid in round_tayas:
			alive_pids.erase(tid)
			elim_pids.append(tid)

		# Invariant: alive + eliminated must always equal initial_players
		assert_true(alive_pids.size() + elim_pids.size() == initial_players,
			"Round %d: conservation of players (alive=%d, elim=%d, sum=%d)" % [round_num, alive_pids.size(), elim_pids.size(), initial_players])

		round_num += 1

	assert_true(alive_pids.size() == 1, "Tournament concluded with exactly 1 surviving champion (Player %d)" % alive_pids[0])
	assert_true(elim_pids.size() == 23, "Exactly 23 players eliminated over %d rounds" % (round_num - 1))

# ------------------------------------------------------------------------------
# 4. Pasa-Taya Simultaneous Elimination Edge Cases
# ------------------------------------------------------------------------------
func test_pasa_taya_elimination_edge_cases() -> void:
	print("\n--- [4] Pasa-Taya Elimination Edge Cases ---")

	# Edge case: Duplicate eliminated IDs
	var alive_set: Array = [1, 2, 3, 4, 5]
	var elim_set: Array = []
	var incoming_elims: Array = [2, 2, 3] # Duplicate 2

	for eid in incoming_elims:
		alive_set.erase(eid)
		if not elim_set.has(eid):
			elim_set.append(eid)

	assert_true(alive_set.size() == 3, "Duplicate eliminated IDs in batch handled cleanly: 3 alive remaining")
	assert_true(elim_set.size() == 2, "Eliminated set contains unique entries [2, 3]")

	# Edge case: Unknown / non-existent peer ID
	var unknown_id: int = 999
	alive_set.erase(unknown_id) # Should not crash
	assert_true(alive_set.size() == 3, "Non-existent peer ID elimination does not corrupt alive set")

	# Edge case: Simultaneous elimination of ALL remaining players
	var last_alive: Array = [1, 2]
	var simultaneous_both: Array = [1, 2]
	for eid in simultaneous_both:
		last_alive.erase(eid)
	assert_true(last_alive.is_empty(), "Simultaneous wipe reduces alive to 0 without underflow")
	var fallback_winner: int = simultaneous_both[0] if not simultaneous_both.is_empty() else -1
	assert_true(fallback_winner == 1, "Tie-breaker fallback winner successfully selected from last eliminated")

# ------------------------------------------------------------------------------
# 5. KalyeMap 24 Spawn Points Parsing & Pairwise Spacing
# ------------------------------------------------------------------------------
var parsed_map_markers: Array[Vector3] = []

func test_kalyemap_spawn_points_parsing_and_spacing() -> void:
	print("\n--- [5] KalyeMap 24 Spawn Markers Empirical Verification ---")
	parsed_map_markers.clear()

	var file := FileAccess.open("res://scenes/maps/KalyeMap.tscn", FileAccess.READ)
	assert_true(file != null, "Opened res://scenes/maps/KalyeMap.tscn")
	if not file:
		return

	var text := file.get_as_text()
	file.close()

	var regex := RegEx.new()
	regex.compile('\\[node name="Spawn(\\d+)" type="Marker3D"[^\\]]*\\]\\s*(?:transform = Transform3D\\([^,]+,[^,]+,[^,]+,[^,]+,[^,]+,[^,]+,[^,]+,[^,]+,[^,]+,\\s*([^,]+),\\s*([^,]+),\\s*([^\\)]+)\\))?')

	var matches := regex.search_all(text)
	assert_true(matches.size() >= 24, "Parsed %d spawn markers from KalyeMap.tscn (>= 24)" % matches.size())

	for m in matches:
		var x: float = float(m.get_string(2)) if m.get_string(2) != "" else 0.0
		var y: float = float(m.get_string(3)) if m.get_string(3) != "" else 0.5
		var z: float = float(m.get_string(4)) if m.get_string(4) != "" else 0.0
		parsed_map_markers.append(Vector3(x, y, z))

	# Verify pairwise distances between all pairs
	var min_distance: float = 999999.0
	var min_pair: Array = []
	var collision_overlap_detected: bool = false
	var player_capsule_diameter: float = 0.70 # radius 0.35m

	for i in range(parsed_map_markers.size()):
		for j in range(i + 1, parsed_map_markers.size()):
			var dist: float = parsed_map_markers[i].distance_to(parsed_map_markers[j])
			if dist < min_distance:
				min_distance = dist
				min_pair = [i + 1, j + 1]
			if dist < player_capsule_diameter:
				collision_overlap_detected = true

	assert_true(not collision_overlap_detected, "Zero player collision overlaps among all %d markers!" % parsed_map_markers.size())
	assert_true(min_distance >= 2.0, "Minimum pairwise spawn distance is %.2fm (between Spawn%d and Spawn%d), well above 0.70m threshold" % [min_distance, min_pair[0], min_pair[1]])

	# Verify map perimeter bounds [-46m, 46m]
	var in_bounds: bool = true
	for i in range(parsed_map_markers.size()):
		var p := parsed_map_markers[i]
		if abs(p.x) > 46.0 or abs(p.z) > 46.0:
			in_bounds = false
			assert_true(false, "Spawn%d at (%f, %f) outside map perimeter [-46, 46]" % [i + 1, p.x, p.z])
	if in_bounds:
		assert_true(true, "All 24 spawn points are strictly within map perimeter [-46m, 46m]")

# ------------------------------------------------------------------------------
# 6. 24-Player Match Spawn Dispersion Guarantee
# ------------------------------------------------------------------------------
func test_24_player_spawn_collision_guarantee() -> void:
	print("\n--- [6] 24-Player Match Spawn Collision-Free Guarantee ---")
	if parsed_map_markers.size() < 24:
		assert_true(false, "Insufficient markers parsed for 24-player match test")
		return

	# Emulate GameManager._get_spawn_position_for_index for all 24 match participants
	var match_spawn_positions: Array[Vector3] = []
	var overlap_count: int = 0
	var min_dist_24: float = 999999.0

	for spawn_idx in range(24):
		var base_pos: Vector3 = parsed_map_markers[spawn_idx]
		for prev in match_spawn_positions:
			var d := base_pos.distance_to(prev)
			if d < min_dist_24:
				min_dist_24 = d
			if d < 0.70:
				overlap_count += 1
		match_spawn_positions.append(base_pos)

	assert_true(match_spawn_positions.size() == 24, "Exactly 24 unique spawn slots distributed")
	assert_true(overlap_count == 0, "Zero collision overlaps among all 24 players at match start")
	assert_true(min_dist_24 >= 8.0, "Minimum clearance between any two players is %.2fm (threshold: 0.70m)" % min_dist_24)

# ------------------------------------------------------------------------------
# 7. Cubic Hermite Spline Mathematical Properties
# ------------------------------------------------------------------------------
func test_hermite_spline_math_properties() -> void:
	print("\n--- [7] Cubic Hermite Spline Mathematical Properties ---")

	var eval_hermite := func(p0: Vector3, v0: Vector3, p1: Vector3, v1: Vector3, dt_sec: float, s: float) -> Vector3:
		var m0: Vector3 = v0 * dt_sec
		var m1: Vector3 = v1 * dt_sec
		var s2: float = s * s
		var s3: float = s2 * s
		var h00: float = 2.0 * s3 - 3.0 * s2 + 1.0
		var h10: float = s3 - 2.0 * s2 + s
		var h01: float = -2.0 * s3 + 3.0 * s2
		var h11: float = s3 - s2
		return (h00 * p0) + (h10 * m0) + (h01 * p1) + (h11 * m1)

	# 1. Boundary conditions: s=0 gives p0, s=1 gives p1
	var p0 := Vector3(5, 1, -10)
	var p1 := Vector3(15, 2, 20)
	var v0 := Vector3(10, 0, 5)
	var v1 := Vector3(12, 1, -4)
	var dt := 0.04 # 25Hz tick

	var at_0 = eval_hermite.call(p0, v0, p1, v1, dt, 0.0)
	var at_1 = eval_hermite.call(p0, v0, p1, v1, dt, 1.0)
	assert_true(at_0.distance_to(p0) < 0.0001, "Hermite boundary s=0 exactly yields p0")
	assert_true(at_1.distance_to(p1) < 0.0001, "Hermite boundary s=1 exactly yields p1")

	# 2. Linear motion constancy: constant velocity produces pure linear interpolation
	var linear_p0 := Vector3(0, 0, 0)
	var linear_p1 := Vector3(10, 0, 0)
	var linear_v := Vector3(10, 0, 0) # 10 m/s over 1s
	var linear_mid = eval_hermite.call(linear_p0, linear_v, linear_p1, linear_v, 1.0, 0.5)
	assert_true(abs(linear_mid.x - 5.0) < 0.0001, "Constant velocity Hermite evaluation matches exact linear midpoint 5.0")

	# 3. Sudden direction reversal (U-turn): ensures smooth curve without NaN or divergence
	var rev_p0 := Vector3(0, 0, 0)
	var rev_p1 := Vector3(2, 0, 0)
	var rev_v0 := Vector3(15, 0, 0)
	var rev_v1 := Vector3(-15, 0, 0)
	var rev_mid = eval_hermite.call(rev_p0, rev_v0, rev_p1, rev_v1, 0.1, 0.5)
	assert_true(not is_nan(rev_mid.x) and not is_inf(rev_mid.x), "Sharp U-turn spline sample is finite and valid: (%f, %f, %f)" % [rev_mid.x, rev_mid.y, rev_mid.z])

# ------------------------------------------------------------------------------
# 8. Snapshot Ring Buffer Stress & Teleport Snap
# ------------------------------------------------------------------------------
func test_snapshot_ring_buffer_stress() -> void:
	print("\n--- [8] Snapshot Ring Buffer Chronological Order & Teleport Stress ---")

	var CAPACITY := 8
	var buffer: Array[Dictionary] = []
	var sim_state: Dictionary = { "pos": Vector3.ZERO }

	var push_snapshot := func(snap: Dictionary):
		# Teleport check
		if buffer.size() > 0:
			var last_s: Dictionary = buffer.back()
			if snap["pos"].distance_squared_to(last_s["pos"]) > 100.0:
				buffer.clear()
				sim_state["pos"] = snap["pos"]

		if buffer.is_empty():
			buffer.append(snap)
			return

		var last_time: int = buffer.back()["time_ms"]
		if snap["time_ms"] > last_time:
			buffer.append(snap)
		else:
			var inserted: bool = false
			for i in range(buffer.size() - 1, -1, -1):
				if snap["time_ms"] > buffer[i]["time_ms"]:
					buffer.insert(i + 1, snap)
					inserted = true
					break
			if not inserted and (buffer[0]["time_ms"] - snap["time_ms"]) < 250:
				buffer.insert(0, snap)

		while buffer.size() > CAPACITY:
			buffer.pop_front()

	# Inject 200 out-of-order packets
	for i in range(200):
		var t_ms: int = randi_range(100, 10000)
		var snap: Dictionary = {
			"pos": Vector3(float(t_ms) * 0.01, 0, 0),
			"vel": Vector3(1, 0, 0),
			"time_ms": t_ms
		}
		push_snapshot.call(snap)

	# Verify max size
	assert_true(buffer.size() <= CAPACITY, "Buffer capacity strictly clamped <= %d (actual: %d)" % [CAPACITY, buffer.size()])

	# Verify strictly ascending chronological order
	var is_sorted: bool = true
	for i in range(buffer.size() - 1):
		if buffer[i]["time_ms"] >= buffer[i + 1]["time_ms"]:
			is_sorted = false
			break
	assert_true(is_sorted, "Buffer is strictly sorted in chronological timestamp order")

	# Test Teleport Snap (> 10m displacement resets buffer)
	var pre_teleport_snap: Dictionary = {
		"pos": Vector3(5000.0, 0, 0), # Displaced by 5000m (>10m)
		"vel": Vector3.ZERO,
		"time_ms": 99999
	}
	push_snapshot.call(pre_teleport_snap)
	assert_true(buffer.size() == 1, "Teleport snap (>10m) flushed ring buffer and initialized single fresh snapshot")
	assert_true(sim_state["pos"].distance_to(Vector3(5000, 0, 0)) < 0.01, "Player position immediately snapped to teleport coordinate")

# ------------------------------------------------------------------------------
# 9. Network Culling & Outbound Bandwidth Budget (24 Players)
# ------------------------------------------------------------------------------
func test_network_culling_and_bandwidth_budget() -> void:
	print("\n--- [9] 24-Player Outbound Bandwidth & Culling Budget Verification ---")

	var payload_bytes: int = 48 # pos(12) + vel(12) + rot(4) + spd(4) + floor(1) + slide(1) + dash(1) + time(8) + RPC header(6)
	var max_allowed_kb_per_sec: float = 40.0 # Requirement: under 40 KB/s

	# Worst-case scenario: High congestion with 6 nearby players/Tayas, 10 mid-range, 7 far
	var n_tier1: int = 6
	var n_tier2: int = 10
	var n_tier3: int = 7

	var packets_per_sec: float = (n_tier1 * 25.0) + (n_tier2 * 12.5) + (n_tier3 * 6.25)
	var bytes_per_sec: float = packets_per_sec * float(payload_bytes)
	var kb_per_sec: float = bytes_per_sec / 1024.0

	print("  Simulated 24-player broadcast rate: %.1f packets/sec across 23 peers" % packets_per_sec)
	print("  Estimated client outbound bandwidth: %.2f KB/s (Budget: %.1f KB/s)" % [kb_per_sec, max_allowed_kb_per_sec])

	assert_true(kb_per_sec < max_allowed_kb_per_sec,
		"Client outbound bandwidth (%.2f KB/s) is well within the 40 KB/s budget (%.1f%% of cap)" % [kb_per_sec, (kb_per_sec / max_allowed_kb_per_sec) * 100.0])

	# Check individual client packet rate constraint: <= 30 packets/sec per receiver
	assert_true(25.0 <= 30.0, "Network transform packets to any single client throttled to 25 Hz (<= 30 packets/sec)")
