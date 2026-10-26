extends SceneTree

## Automated Verification Suite: Throwables Forward Trajectory, Self-Hit Elimination & Banana Ground Snapping

const KalyeMatchMapScript = preload("res://scripts/gameplay/KalyeMatchMap.gd")
const PlayerControllerScript = preload("res://scripts/player/PlayerController.gd")
const PracticeBotScript = preload("res://scripts/player/PracticeBot.gd")
const ThrownProjectileScript = preload("res://scripts/gameplay/ThrownProjectile.gd")
const BananaTrapScript = preload("res://scripts/gameplay/BananaTrap.gd")

func _init() -> void:
	print("\n=======================================================")
	print("[TEST] Starting Throwables & Traps Verification Suite...")
	print("=======================================================")

	# 1. Load and instantiate map
	var map_scene = load("res://scenes/maps/KalyeMatchMap.tscn")
	assert(map_scene != null, "KalyeMatchMap scene must load")
	var map = map_scene.instantiate()
	root.add_child(map)

	await process_frame
	await physics_frame
	await physics_frame

	# 2. Spawn human player on road near jeep
	var player_scene = load("res://scenes/player/Player.tscn")
	assert(player_scene != null, "Player scene must load")
	var player = player_scene.instantiate() as PlayerController
	player.player_id = 1
	player.player_name = "Player1"
	player.current_role = PlayerController.Role.TAYA
	player.position = Vector3(-18.0, -5.0, 0.0) # On asphalt road
	root.add_child(player)

	# 3. Spawn bot runner 8 meters ahead
	var bot_scene = load("res://scenes/player/PracticeBot.tscn")
	assert(bot_scene != null, "PracticeBot scene must load")
	var bot = bot_scene.instantiate() as PracticeBot
	bot.player_id = 2
	bot.player_name = "BotRunner"
	bot.current_role = PlayerController.Role.RUNNER
	bot.position = Vector3(-18.0, -5.0, -8.0) # In front of player on road
	root.add_child(bot)

	await process_frame
	await physics_frame

	print("[PASS] KalyeMatchMap, Player (TAYA), and Bot (RUNNER) instantiated on road.")

	# =========================================================================
	# TEST 1: Thrown Tsinelas Forward Trajectory & Self-Hit Elimination
	# =========================================================================
	print("\n[CHECK 1] Testing Spartan Tsinelas Throw...")
	player.is_stunned = false
	player.stun_timer = 0.0
	bot.is_stunned = false
	bot.stun_timer = 0.0

	# Give player tsinelas and throw
	player.held_street_item = 0 # TSINELAS
	player._throw_tsinelas()

	# Find instantiated projectile in root
	var proj: ThrownProjectile = null
	for c in root.get_children():
		if c is ThrownProjectile and c.is_active:
			proj = c
			break
	assert(proj != null, "ThrownProjectile must be instantiated in tree")
	assert(proj.thrower_id == player.player_id, "Projectile must know thrower_id")
	assert(proj.thrower_node == player, "Projectile must have reference to thrower_node")

	# Verify start position is forward in front of player, outside body capsule
	var dist_from_player = player.global_position.distance_to(proj.global_position)
	assert(dist_from_player >= 0.70, "Projectile must spawn forward outside thrower capsule, got %.2fm" % dist_from_player)
	assert(proj.velocity.length() > 15.0, "Projectile must have forward launch velocity, got %.2f" % proj.velocity.length())

	# Process 5 physics frames of flight
	for i in range(5):
		await physics_frame

	assert(player.is_stunned == false, "Thrower MUST NOT hit themselves with their own tsinelas!")
	assert(proj.is_active == true, "Projectile must still be flying cleanly through the air after 5 frames!")
	print("[PASS] Tsinelas launched forward cleanly with zero self-hit and sustained mid-air flight.")

	# Cleanup test projectile
	proj.queue_free()
	await process_frame

	# =========================================================================
	# TEST 2: Chalk Bag Throw & Cloud Thrower Immunity
	# =========================================================================
	print("\n[CHECK 2] Testing Chalk Bag Throw & Cloud Thrower Immunity...")
	player.chalk_blind_timer = 0.0
	bot.chalk_blind_timer = 0.0

	player.held_street_item = 3 # CHALK_BAG
	player._throw_chalk_bag()

	var chalk_proj: ThrownProjectile = null
	for c in root.get_children():
		if c is ThrownProjectile and c.is_active:
			chalk_proj = c
			break
	assert(chalk_proj != null, "Chalk ThrownProjectile must be instantiated")
	assert(chalk_proj.thrower_node == player, "Chalk projectile must record thrower_node")

	# Verify forward launch
	var chalk_dist = player.global_position.distance_to(chalk_proj.global_position)
	assert(chalk_dist >= 0.70, "Chalk bag must spawn forward in front of player")

	# Detonate chalk bag cloud directly between player and bot
	var cloud_pos = Vector3(-18.0, -4.5, -4.0)
	chalk_proj._spawn_chalk_cloud(cloud_pos)

	# Verify thrower is immune to their own chalk dust
	assert(player.chalk_blind_timer == 0.0, "Thrower MUST NOT be blinded by their own chalk bag cloud!")
	# Verify bot runner within radius gets blinded
	assert(bot.chalk_blind_timer > 0.0, "Opponent runner within cloud radius MUST receive chalk blind!")
	print("[PASS] Chalk Bag launched forward; thrower immune to cloud while opponent blinded.")

	chalk_proj.queue_free()
	await process_frame

	# =========================================================================
	# TEST 3: Banana Peel Trap Road Ground Snapping (No Flying at Y=0.05)
	# =========================================================================
	print("\n[CHECK 3] Testing Banana Peel Trap Ground Snapping...")
	player.held_street_item = 1 # SAGING
	player._drop_banana()

	var trap: BananaTrap = null
	for c in root.get_children():
		if c is BananaTrap:
			trap = c
			break
	assert(trap != null, "BananaTrap must be instantiated in tree")

	# Let deferred ground snap execute
	await process_frame
	await physics_frame
	await physics_frame

	var trap_y = trap.global_position.y
	print("  Banana trap placed at global Y = %.3f (Player standing at Y = %.3f)" % [trap_y, player.global_position.y])
	assert(trap_y <= -4.80 and trap_y >= -5.20, "Banana trap must rest flat on road pavement (Y ~ -5.0m), got Y=%.3f" % trap_y)
	assert(absf(trap_y - 0.05) > 4.0, "Banana trap MUST NOT float at legacy Y=0.05m!")
	print("[PASS] Banana trap correctly snapped to road pavement level beneath player feet.")

	# =========================================================================
	# TEST 4: Banana Peel Trap Buoyancy on Flood Water
	# =========================================================================
	print("\n[CHECK 4] Testing Banana Peel Trap Buoyancy during Street Flood...")
	map.trigger_flood()
	# Fast-forward flood water
	var sfw = map.find_child("StreetFloodWater", true, false)
	sfw.position.y = map.FLOOD_HEIGHT_WET # -4.80m

	# Process trap in flooded state
	trap._process(0.016)
	var flooded_trap_y = trap.global_position.y
	print("  Flooded banana trap Y = %.3f (Water surface = %.3f)" % [flooded_trap_y, map.FLOOD_HEIGHT_WET])
	assert(flooded_trap_y >= map.FLOOD_HEIGHT_WET - 0.05, "Banana trap must float on flood water surface, got %.3f" % flooded_trap_y)
	assert(flooded_trap_y > trap_y + 0.15, "Flooded banana trap must be lifted above dry pavement level")

	# Drain flood and verify return to ground
	map.drain_flood()
	sfw.position.y = map.FLOOD_HEIGHT_DRY
	trap._process(0.016)
	var drained_trap_y = trap.global_position.y
	print("  Drained banana trap Y = %.3f" % drained_trap_y)
	assert(absf(drained_trap_y - trap_y) <= 0.05, "Drained banana trap must settle back down to road pavement")
	print("[PASS] Banana trap buoyant float on water surface and return to dry pavement verified.")

	trap.queue_free()
	bot.queue_free()
	player.queue_free()
	map.free()

	print("\n=======================================================")
	print("[ALL THROWABLES & TRAP TESTS PASSED] ZERO RUNTIME ERRORS!")
	print("=======================================================\n")
	quit(0)