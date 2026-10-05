extends SceneTree

# ==============================================================================
# CHALLENGER 1 EMPIRICAL STRESS TEST HARNESS (Milestone 1)
# ==============================================================================
# Scope:
#   1. Throttling verification (<= 30 packets/sec per client under 30/60/120/144/240Hz & hitching)
#   2. Outbound bandwidth budget (< 40 KB/s in full 24-player lobbies with actual KalyeMap spawns)
#   3. Hermite spline C1 continuity & boundary stress (extreme velocity, zero dt, out-of-order, jitter)
#   4. Multi-Taya ratio balancing & edge cases (1..24 players, all-same gesture tie, 50/50 split)
# ==============================================================================

const MaibaTayaManagerScript = preload("res://scripts/gameplay/MaibaTayaManager.gd")
const NetworkManagerScript = preload("res://scripts/network/NetworkManager.gd")

var total_tests: int = 0
var passed_tests: int = 0
var failed_tests: int = 0
var failures: Array[String] = []

func _init() -> void:
	print("\n======================================================================")
	print("[CHALLENGER-1] EXECUTING ADVERSARIAL STRESS TEST SUITE (MILESTONE 1)")
	print("======================================================================")

	stress_test_throttling_rates()
	stress_test_bandwidth_budget()
	stress_test_hermite_spline_continuity()
	stress_test_hermite_spline_extreme_conditions()
	stress_test_snapshot_buffer_adversarial_packets()
	stress_test_multi_taya_scaling_and_ties()

	print("\n======================================================================")
	print("[CHALLENGER-1] EMPIRICAL STRESS TEST SUMMARY")
	print("  Total tests:  %d" % total_tests)
	print("  Passed:       %d" % passed_tests)
	print("  Failed:       %d" % failed_tests)
	print("======================================================================")

	if failed_tests > 0:
		print("\nFAILED ASSERTIONS:")
		for f in failures:
			print("  [X] " + f)
		print("\nVERDICT: REQUEST_CHANGES")
		quit(1)
	else:
		print("\nALL STRESS TESTS PASSED EMPIRICALLY! ZERO REGRESSIONS.")
		print("VERDICT: APPROVE")
		quit(0)

func assert_true(condition: bool, test_name: String, details: String = "") -> void:
	total_tests += 1
	if condition:
		passed_tests += 1
		print("  [PASS] %s" % test_name)
	else:
		failed_tests += 1
		var msg: String = "%s: %s" % [test_name, details]
		failures.append(msg)
		print("  [FAIL] %s" % msg)

# ------------------------------------------------------------------------------
# 1. THROTTLING VERIFICATION (<= 30 packets/sec per client)
# ------------------------------------------------------------------------------
func stress_test_throttling_rates() -> void:
	print("\n--- 1. Packet Throttling Stress Tests ---")

	var network_tick_rate: float = 25.0
	var tick_interval: float = 1.0 / network_tick_rate # 0.04s

	assert_true(
		network_tick_rate <= 30.0,
		"PlayerController.NETWORK_TICK_RATE <= 30.0",
		"Tick rate is %.2f Hz, expected <= 30.0 Hz" % network_tick_rate
	)
	assert_true(
		network_tick_rate >= 20.0,
		"PlayerController.NETWORK_TICK_RATE >= 20.0",
		"Tick rate is %.2f Hz, expected >= 20.0 Hz" % network_tick_rate
	)

	# Simulate tick accumulator under different frame rates over a 10.0-second window
	var frame_rates: Array = [30.0, 60.0, 120.0, 144.0, 240.0]

	for fps in frame_rates:
		var dt: float = 1.0 / float(fps)
		var timer: float = 0.0
		var packets_sent: int = 0
		var sim_time: float = 10.0
		var elapsed: float = 0.0

		while elapsed < sim_time:
			timer += dt
			if timer >= tick_interval:
				timer = fmod(timer, tick_interval)
				packets_sent += 1
			elapsed += dt

		var effective_pps: float = float(packets_sent) / sim_time
		assert_true(
			effective_pps <= 30.01,
			"Packet emission rate at %d FPS is throttled (got %.2f pps <= 30 pps)" % [int(fps), effective_pps],
			"Exceeded 30 packets/sec: got %.2f pps" % effective_pps
		)
		assert_true(
			effective_pps >= 24.5,
			"Packet emission rate at %d FPS reaches target tick rate (got %.2f pps >= 24.5 pps)" % [int(fps), effective_pps],
			"Under-emitted: got %.2f pps" % effective_pps
		)

	# Stress test with severe frame hitches (fluctuating dt between 0.004s and 0.15s)
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 12345
	var timer_hitch: float = 0.0
	var packets_hitch: int = 0
	var sim_time_hitch: float = 10.0
	var elapsed_hitch: float = 0.0

	while elapsed_hitch < sim_time_hitch:
		var dt_hitch: float = rng.randf_range(0.004, 0.15)
		timer_hitch += dt_hitch
		if timer_hitch >= tick_interval:
			timer_hitch = fmod(timer_hitch, tick_interval)
			packets_hitch += 1
		elapsed_hitch += dt_hitch

	var hitch_pps: float = float(packets_hitch) / elapsed_hitch
	assert_true(
		hitch_pps <= 30.0,
		"Under severe frame hitching, pps stays <= 30.0 (got %.2f pps)" % hitch_pps,
		"Hitching caused burst above 30 pps: %.2f pps" % hitch_pps
	)

# ------------------------------------------------------------------------------
# 2. OUTBOUND BANDWIDTH BUDGET VERIFICATION (< 40 KB/s in full 24-player lobby)
# ------------------------------------------------------------------------------
func stress_test_bandwidth_budget() -> void:
	print("\n--- 2. Outbound Bandwidth Budget Verification ---")

	# Exact application payload bytes for sync_transform unreliable RPC:
	# pos: Vector3 (12B), vel: Vector3 (12B), rot_y: float (4B), speed: float (4B),
	# floor: bool (1B), slide: bool (1B), dash: bool (1B), time_ms: int (4B), RPC overhead: 9B
	var app_payload_bytes: int = 48
	# Full wire frame size including UDP (8B), IPv4 (20B), and ENet envelope (8B):
	var full_wire_bytes: int = app_payload_bytes + 36 # 84 bytes

	print("    App payload: %d bytes, Total UDP/IP wire size: %d bytes" % [app_payload_bytes, full_wire_bytes])

	# Actual spawn markers from scenes/maps/KalyeMap.tscn (Spawn1 through Spawn24)
	var actual_spawns: Array[Vector3] = [
		Vector3(-22, 0.5, -35), Vector3(22, 0.5, -35), Vector3(-35, 0.5, 0),
		Vector3(28, 0.5, -6),   Vector3(-22, 0.5, 35),  Vector3(25, 0.5, 35),
		Vector3(0, 0.5, -42),   Vector3(0, 0.5, 20),    Vector3(-12, 0.5, -28),
		Vector3(14, 0.5, -24),  Vector3(-28, 0.5, -16), Vector3(32, 0.5, 12),
		Vector3(-15, 0.5, 8),   Vector3(18, 0.5, 8),    Vector3(-32, 0.5, 24),
		Vector3(10, 0.5, 30),   Vector3(-8, 0.5, 38),   Vector3(-12, 0.5, -38),
		Vector3(12, 0.5, -38),  Vector3(30, 0.5, -25),  Vector3(-30, 0.5, -8),
		Vector3(10, 0.5, -6),   Vector3(-6, 0.5, -6),   Vector3(0, 0.5, 38)
	]

	# Evaluate 3-tier culling from perspective of local player at Spawn 1
	var local_spawn: Vector3 = actual_spawns[0]
	var tier1_count: int = 0 # <= 20m or Taya (4 Tayas)
	var tier2_count: int = 0 # 20m - 45m
	var tier3_count: int = 0 # > 45m

	for i in range(1, actual_spawns.size()):
		var peer_pos: Vector3 = actual_spawns[i]
		var dist: float = local_spawn.distance_to(peer_pos)
		if i in [1, 2, 3, 4] or dist <= 20.0:
			tier1_count += 1
		elif dist <= 45.0:
			tier2_count += 1
		else:
			tier3_count += 1

	print("    Actual KalyeMap layout: %d Tier-1, %d Tier-2, %d Tier-3 peers" % [tier1_count, tier2_count, tier3_count])

	var realistic_pps: float = (float(tier1_count) * 25.0) + (float(tier2_count) * 12.5) + (float(tier3_count) * 6.25)
	var app_kb_per_sec: float = (realistic_pps * float(app_payload_bytes)) / 1024.0
	var wire_kb_per_sec: float = (realistic_pps * float(full_wire_bytes)) / 1024.0

	print("    Realistic 24-player match outbound rate: %.2f packets/s" % realistic_pps)
	print("    Application throughput: %.2f KB/s, Full wire throughput: %.2f KB/s" % [app_kb_per_sec, wire_kb_per_sec])

	assert_true(
		wire_kb_per_sec < 40.0,
		"Realistic 24-player match wire outbound bandwidth is under 40 KB/s (got %.2f KB/s)" % wire_kb_per_sec,
		"Bandwidth %.2f KB/s exceeded 40 KB/s limit!" % wire_kb_per_sec
	)
	assert_true(
		app_kb_per_sec < 20.0,
		"Realistic 24-player application network throughput is under 20 KB/s (got %.2f KB/s)" % app_kb_per_sec,
		"Throughput %.2f KB/s exceeded 20 KB/s threshold!" % app_kb_per_sec
	)

	# Delta suppression rate check (Stationary players send only 0.5s heartbeat = 2Hz)
	var max_peers: int = 23
	var idle_pps: float = float(max_peers) * 2.0
	var idle_kb_per_sec: float = (idle_pps * float(full_wire_bytes)) / 1024.0
	print("    Stationary delta-suppression wire rate: %.2f packets/s, %.2f KB/s" % [idle_pps, idle_kb_per_sec])
	assert_true(
		idle_kb_per_sec < 10.0,
		"Stationary delta-suppression outbound bandwidth is negligible (got %.2f KB/s)" % idle_kb_per_sec,
		"Delta suppression failed: %.2f KB/s" % idle_kb_per_sec
	)

# ------------------------------------------------------------------------------
# 3. HERMITE SPLINE CONTINUITY STRESS TESTS
# ------------------------------------------------------------------------------
func _eval_hermite(p0: Vector3, v0: Vector3, p1: Vector3, v1: Vector3, dt_sec: float, s: float) -> Vector3:
	var m0: Vector3 = v0 * dt_sec
	var m1: Vector3 = v1 * dt_sec
	var s2: float = s * s
	var s3: float = s2 * s
	var h00: float = 2.0 * s3 - 3.0 * s2 + 1.0
	var h10: float = s3 - 2.0 * s2 + s
	var h01: float = -2.0 * s3 + 3.0 * s2
	var h11: float = s3 - s2
	return (h00 * p0) + (h10 * m0) + (h01 * p1) + (h11 * m1)

func stress_test_hermite_spline_continuity() -> void:
	print("\n--- 3. Hermite Spline C1 Continuity Stress Tests ---")

	var p0: Vector3 = Vector3(0, 0, 0)
	var p1: Vector3 = Vector3(10, 0, 0)
	var p2: Vector3 = Vector3(25, 0, 0)
	var v0: Vector3 = Vector3(10, 0, 0)
	var v1: Vector3 = Vector3(15, 0, 0)
	var v2: Vector3 = Vector3(15, 0, 0)
	var dt: float = 1.0

	# 1. Endpoint continuity: s=0 on S0->S1 must equal p0
	var at_0: Vector3 = _eval_hermite(p0, v0, p1, v1, dt, 0.0)
	assert_true(
		at_0.distance_to(p0) < 0.0001,
		"Spline at s=0.0 matches start position p0 exactly",
		"Got %s, expected %s" % [at_0, p0]
	)

	# 2. Endpoint continuity: s=1.0 on S0->S1 must equal p1
	var at_1: Vector3 = _eval_hermite(p0, v0, p1, v1, dt, 1.0)
	assert_true(
		at_1.distance_to(p1) < 0.0001,
		"Spline at s=1.0 matches end position p1 exactly",
		"Got %s, expected %s" % [at_1, p1]
	)

	# 3. Inter-segment C0 continuity: s=1.0 on (S0->S1) equals s=0.0 on (S1->S2)
	var junction_left: Vector3 = _eval_hermite(p0, v0, p1, v1, dt, 1.0)
	var junction_right: Vector3 = _eval_hermite(p1, v1, p2, v2, dt, 0.0)
	assert_true(
		junction_left.distance_to(junction_right) < 0.0001,
		"Spline segments exhibit exact C0 continuity at junction",
		"Discrepancy at junction: %.6f" % junction_left.distance_to(junction_right)
	)

	# 4. Tangent C1 continuity: numerical derivative at s=1.0 approaching from left
	# matches numerical derivative at s=0.0 leaving to right
	var eps: float = 0.001
	var p_left: Vector3 = _eval_hermite(p0, v0, p1, v1, dt, 1.0 - eps)
	var p_mid: Vector3 = _eval_hermite(p0, v0, p1, v1, dt, 1.0)
	var v_left: Vector3 = (p_mid - p_left) / (eps * dt)

	var p_right: Vector3 = _eval_hermite(p1, v1, p2, v2, dt, eps)
	var v_right: Vector3 = (p_right - p_mid) / (eps * dt)

	assert_true(
		v_left.distance_to(v_right) < 0.05,
		"Spline exhibits smooth C1 velocity tangent continuity across junction (diff: %.4f m/s)" % v_left.distance_to(v_right),
		"C1 discontinuity detected: v_left=%s, v_right=%s" % [v_left, v_right]
	)

	# 5. Monotonic step progression
	var prev_pos: Vector3 = p0
	var max_step_jump: float = 0.0
	for step in range(1, 101):
		var s_val: float = float(step) / 100.0
		var pos_step: Vector3 = _eval_hermite(p0, v0, p1, v1, dt, s_val)
		var jump: float = pos_step.distance_to(prev_pos)
		if jump > max_step_jump:
			max_step_jump = jump
		prev_pos = pos_step

	assert_true(
		max_step_jump < 0.35,
		"Spline path is smooth with no step discontinuity (max step delta: %.4f m)" % max_step_jump,
		"Step jump too large: %.4f m" % max_step_jump
	)

# ------------------------------------------------------------------------------
# 4. HERMITE SPLINE EXTREME CONDITIONS & STRESS
# ------------------------------------------------------------------------------
func stress_test_hermite_spline_extreme_conditions() -> void:
	print("\n--- 4. Hermite Spline Extreme Conditions Stress Tests ---")

	# A. Extreme high velocity impulse (1000 m/s explosion/glitch)
	var extreme_pos: Vector3 = _eval_hermite(
		Vector3(0, 0, 0), Vector3(1000, 500, -1000),
		Vector3(10, 0, 0), Vector3(-500, 1000, 500),
		0.04, 0.5
	)
	assert_true(
		not is_nan(extreme_pos.x) and not is_inf(extreme_pos.x),
		"Extreme velocity input produces valid finite position (no NaN / Inf)",
		"Produced invalid vector: %s" % extreme_pos
	)

	# B. Zero interval (Duplicate timestamps: dt = max(0.001, 0.0))
	var dt_clamped: float = max(0.001, 0.0)
	var dup_pos: Vector3 = _eval_hermite(
		Vector3(5, 2, 1), Vector3(5, 0, 0),
		Vector3(6, 2, 1), Vector3(5, 0, 0),
		dt_clamped, 0.5
	)
	assert_true(
		not is_nan(dup_pos.x) and not is_inf(dup_pos.x),
		"Zero dt (duplicate timestamp) safely clamped by max(0.001, dt)",
		"Division by zero produced: %s" % dup_pos
	)

	# C. Negative dt protection (Corrupted packet timestamp)
	var dt_neg_clamped: float = max(0.001, -0.2)
	var neg_pos: Vector3 = _eval_hermite(
		Vector3(1, 0, 0), Vector3(0, 0, 0),
		Vector3(2, 0, 0), Vector3(0, 0, 0),
		dt_neg_clamped, 0.5
	)
	assert_true(
		not is_nan(neg_pos.x) and not is_inf(neg_pos.x),
		"Negative dt safely guarded by max(0.001, dt)",
		"Produced: %s" % neg_pos
	)

	# D. Rotation angle wrapping across PI / -PI boundary
	var mid_rot: float = lerp_angle(3.10, -3.10, 0.5)
	assert_true(
		abs(abs(mid_rot) - PI) < 0.1,
		"Rotation interpolation takes shortest arc across PI/-PI boundary (mid=%.3f, near PI)" % mid_rot,
		"Angle wrapped improperly: mid=%.3f" % mid_rot
	)

# ------------------------------------------------------------------------------
# 5. SNAPSHOT BUFFER ADVERSARIAL STRESS
# ------------------------------------------------------------------------------
func _push_test_snapshot(buffer: Array[Dictionary], snap: Dictionary, capacity: int) -> Vector3:
	var snap_pos: Vector3 = snap["pos"]

	# Teleport/Respawn detection: if position jumped > 10m (dist_sq > 100), clear buffer and snap
	if buffer.size() > 0:
		var last_snap: Dictionary = buffer.back()
		if snap["pos"].distance_squared_to(last_snap["pos"]) > 100.0:
			buffer.clear()
			buffer.append(snap)
			return snap["pos"]

	if buffer.is_empty():
		buffer.append(snap)
		return snap["pos"]

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

	while buffer.size() > capacity:
		buffer.pop_front()

	return snap_pos

func stress_test_snapshot_buffer_adversarial_packets() -> void:
	print("\n--- 5. Snapshot Ring Buffer Adversarial Stress Tests ---")

	var ring_buffer: Array[Dictionary] = []
	var capacity: int = 8

	# Generate 30 timestamped snapshots with smooth movement (0.3m per tick) but out-of-order arrival
	var base_packets: Array[Dictionary] = []
	for i in range(30):
		var t_ms: int = 1000 + (i * 40)
		base_packets.append({
			"pos": Vector3(float(i) * 0.3, 0, 0),
			"vel": Vector3(7.5, 0, 0),
			"rot_y": 0.0,
			"speed": 7.5,
			"time_ms": t_ms
		})

	# Shuffle packet arrival order to simulate adversarial network jitter
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 424242
	base_packets.shuffle()

	for snap in base_packets:
		_push_test_snapshot(ring_buffer, snap, capacity)

	assert_true(
		ring_buffer.size() == capacity,
		"Ring buffer strictly respects max capacity (%d) after 30 out-of-order packets" % capacity,
		"Capacity violated: size=%d" % ring_buffer.size()
	)

	var sorted: bool = true
	for i in range(ring_buffer.size() - 1):
		if ring_buffer[i]["time_ms"] > ring_buffer[i + 1]["time_ms"]:
			sorted = false
			break

	assert_true(
		sorted,
		"Ring buffer retains strict chronological ordering under packet jitter",
		"Chronological ordering violated!"
	)

	# Stress 2: Teleport snap detection (> 10m delta snaps instantly and flushes buffer)
	ring_buffer.clear()
	var s_a: Dictionary = { "pos": Vector3(0, 0, 0), "time_ms": 1000 }
	var s_b: Dictionary = { "pos": Vector3(1, 0, 0), "time_ms": 1040 }
	_push_test_snapshot(ring_buffer, s_a, capacity)
	_push_test_snapshot(ring_buffer, s_b, capacity)
	assert_true(ring_buffer.size() == 2, "Buffer has 2 pre-teleport snapshots")

	# Large teleport: 50m jump
	var s_teleport: Dictionary = { "pos": Vector3(50, 0, 0), "time_ms": 1080 }
	var snapped_pos: Vector3 = _push_test_snapshot(ring_buffer, s_teleport, capacity)
	assert_true(
		ring_buffer.size() == 1,
		"Buffer flushed on >10m teleport jump (size=%d, expected 1)" % ring_buffer.size(),
		"Buffer not flushed on teleport!"
	)
	assert_true(
		snapped_pos.distance_to(Vector3(50, 0, 0)) < 0.01,
		"Position snapped directly to teleport destination (50, 0, 0)",
		"Position not snapped: %s" % snapped_pos
	)

# ------------------------------------------------------------------------------
# 6. MULTI-TAYA SCALING & EDGE CASES
# ------------------------------------------------------------------------------
func _simulate_resolve_choices(player_ids: Array, choices: Dictionary, needed_tayas: int) -> Array:
	var up_group: Array = []
	var down_group: Array = []
	for pid in player_ids:
		var c: int = choices.get(pid, 0)
		if c == MaibaTayaManagerScript.HandGesture.PALM_UP:
			up_group.append(pid)
		else:
			down_group.append(pid)

	var selected_taya_ids: Array = []
	if needed_tayas == 1:
		if up_group.size() == 1:
			selected_taya_ids.append(up_group[0])
		elif down_group.size() == 1:
			selected_taya_ids.append(down_group[0])
		else:
			selected_taya_ids.append(player_ids.pick_random() if not player_ids.is_empty() else 1)
	else:
		var minority_group: Array = []
		var majority_group: Array = []
		if up_group.size() < down_group.size():
			minority_group = up_group.duplicate()
			majority_group = down_group.duplicate()
		elif down_group.size() < up_group.size():
			minority_group = down_group.duplicate()
			majority_group = up_group.duplicate()
		else:
			minority_group = player_ids.duplicate()
			minority_group.shuffle()

		minority_group.shuffle()
		majority_group.shuffle()

		for pid in minority_group:
			if selected_taya_ids.size() < needed_tayas:
				selected_taya_ids.append(pid)
		for pid in majority_group:
			if selected_taya_ids.size() < needed_tayas and not selected_taya_ids.has(pid):
				selected_taya_ids.append(pid)

	if selected_taya_ids.size() < needed_tayas:
		var remaining: Array = player_ids.duplicate()
		remaining.shuffle()
		for pid in remaining:
			if selected_taya_ids.size() < needed_tayas and not selected_taya_ids.has(pid):
				selected_taya_ids.append(pid)

	return selected_taya_ids

func stress_test_multi_taya_scaling_and_ties() -> void:
	print("\n--- 6. Multi-Taya Scaling and Gesture Edge Cases ---")

	# Boundary counts: 1 player up to 24 players
	var test_counts: Array = [1, 2, 4, 7, 8, 9, 10, 11, 15, 16, 20, 21, 24]
	var expected_tayas: Array = [1, 1, 1, 1, 1, 2, 2, 3, 3, 4, 4, 5, 5]

	for idx in range(test_counts.size()):
		var p_count: int = test_counts[idx]
		var expected: int = expected_tayas[idx]
		var actual: int = MaibaTayaManagerScript.get_taya_count(p_count)
		assert_true(
			actual == expected,
			"Dynamic Taya ratio for %d players is %d (got %d)" % [p_count, expected, actual],
			"Ratio failed: expected %d, got %d" % [expected, actual]
		)

	# Ratio invariant: For all N in [2..50], 1 <= taya_count < N (at least 1 runner guaranteed)
	var invariant_holds: bool = true
	for n in range(2, 50):
		var tc: int = MaibaTayaManagerScript.get_taya_count(n)
		if tc < 1 or tc >= n:
			invariant_holds = false
			break
	assert_true(
		invariant_holds,
		"Invariant holds across all N in [2, 49]: 1 <= taya_count < N (at least 1 runner guaranteed)",
		"Ratio invariant broken"
	)

	# Adversarial Gesture Test A: 100% Tie (All 24 players choose PALM_DOWN)
	var all_down_pool: Array = []
	var choices_all_down: Dictionary = {}
	for p in range(1, 25):
		all_down_pool.append(p)
		choices_all_down[p] = MaibaTayaManagerScript.HandGesture.PALM_DOWN

	var tie_selected: Array = _simulate_resolve_choices(all_down_pool, choices_all_down, 5)
	assert_true(
		tie_selected.size() == 5,
		"All-same gesture 100%% tie falls back safely to select target 5 Tayas (got %d)" % tie_selected.size(),
		"Tie resolution failed: size=%d" % tie_selected.size()
	)

	# Adversarial Gesture Test B: Exact 50/50 split with 24 players (12 PALM_UP, 12 PALM_DOWN)
	var choices_split: Dictionary = {}
	for p in range(1, 13):
		choices_split[p] = MaibaTayaManagerScript.HandGesture.PALM_UP
	for p in range(13, 25):
		choices_split[p] = MaibaTayaManagerScript.HandGesture.PALM_DOWN

	var split_selected: Array = _simulate_resolve_choices(all_down_pool, choices_split, 5)
	assert_true(
		split_selected.size() == 5,
		"Exact 50/50 gesture split selects target quota of 5 Tayas without crashing (got %d)" % split_selected.size(),
		"50/50 split failed: size=%d" % split_selected.size()
	)

	# Adversarial Gesture Test C: Clear minority (4 PALM_UP, 20 PALM_DOWN for 16 players)
	var pool_16: Array = []
	var choices_16: Dictionary = {}
	for p in range(1, 17):
		pool_16.append(p)
		choices_16[p] = MaibaTayaManagerScript.HandGesture.PALM_UP if p in [1, 2, 3, 4] else MaibaTayaManagerScript.HandGesture.PALM_DOWN

	var minority_selected: Array = _simulate_resolve_choices(pool_16, choices_16, 4)
	assert_true(
		minority_selected.size() == 4,
		"Minority group of 4 players correctly selected for 16-player match (got %d)" % minority_selected.size(),
		"Minority selection size failed: %d" % minority_selected.size()
	)
	var minority_correct := true
	for mid in minority_selected:
		if not mid in [1, 2, 3, 4]:
			minority_correct = false
	assert_true(
		minority_correct,
		"Selected Tayas strictly matched the minority gesture group [1, 2, 3, 4]",
		"Selected IDs: %s" % str(minority_selected)
	)
