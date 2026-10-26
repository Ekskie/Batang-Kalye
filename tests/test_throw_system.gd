extends SceneTree

func _init() -> void:
	print("--- STARTING THROW SYSTEM TEST SUITE ---")
	var passes: int = 0
	var fails: int = 0

	var root_node := Node3D.new()
	root.add_child(root_node)

	await process_frame
	await physics_frame

	# Test 1: Projectile Visuals for Spartan Tsinelas
	var proj_scene: PackedScene = load("res://scenes/gameplay/ThrownProjectile.tscn")
	if not proj_scene:
		print("[FAIL] Could not load ThrownProjectile.tscn")
		quit(1)
		return

	var p_tsinelas: ThrownProjectile = proj_scene.instantiate() as ThrownProjectile
	p_tsinelas.setup(ThrownProjectile.ProjectileType.TSINELAS, Vector3(0, 1.5, 0), Vector3(0, 0, -1), 1, "Player 1", null)
	root_node.add_child(p_tsinelas)
	await process_frame

	# Verify visual_mesh has child mesh instances
	var vm = p_tsinelas.get_node_or_null("VisualMesh")
	if vm and vm.get_child_count() >= 2:
		print("[PASS] Spartan Tsinelas projectile visuals built successfully (sole & strap present: count=%d)" % vm.get_child_count())
		passes += 1
	else:
		print("[FAIL] Spartan Tsinelas visual mesh missing or empty! count=%s" % (str(vm.get_child_count()) if vm else "null"))
		fails += 1

	# Verify flight trail is active
	var trail = p_tsinelas.get_node_or_null("FlightTrail")
	if trail and trail is CPUParticles3D and trail.emitting:
		print("[PASS] Spartan Tsinelas flight trail active and emitting")
		passes += 1
	else:
		print("[FAIL] Spartan Tsinelas flight trail missing or not emitting!")
		fails += 1

	# Test 2: Projectile Visuals for Chalk Bag
	var p_chalk: ThrownProjectile = proj_scene.instantiate() as ThrownProjectile
	p_chalk.setup(ThrownProjectile.ProjectileType.CHALK_BAG, Vector3(2, 1.5, 0), Vector3(0, 0, -1), 1, "Player 1", null)
	root_node.add_child(p_chalk)
	await process_frame

	var vm_chalk = p_chalk.get_node_or_null("VisualMesh")
	if vm_chalk and vm_chalk.get_child_count() >= 1:
		print("[PASS] Chalk Bag projectile visuals built successfully (count=%d)" % vm_chalk.get_child_count())
		passes += 1
	else:
		print("[FAIL] Chalk Bag visual mesh missing or empty!")
		fails += 1

	var chalk_trail = p_chalk.get_node_or_null("FlightTrail")
	if chalk_trail and chalk_trail is CPUParticles3D and chalk_trail.emitting:
		print("[PASS] Chalk Bag dust trail active and emitting")
		passes += 1
	else:
		print("[FAIL] Chalk Bag dust trail missing or not emitting!")
		fails += 1

	# Test 3: Character Model Hand Attachments & Aiming / Throw Animations
	var char_scene: PackedScene = load("res://scenes/player/CharacterModel.tscn")
	if not char_scene:
		print("[FAIL] Could not load CharacterModel.tscn")
		quit(1)
		return

	var char_anim: CharacterAnimator = char_scene.instantiate() as CharacterAnimator
	root_node.add_child(char_anim)
	await process_frame

	# Test Handheld Tsinelas during Aim
	char_anim.set_aiming_throw(true, 0)
	if char_anim.is_aiming_throw and char_anim.held_throwable_type == 0:
		print("[PASS] CharacterAnimator enters aiming throw state with Tsinelas")
		passes += 1
	else:
		print("[FAIL] CharacterAnimator failed to set aiming throw state!")
		fails += 1

	# Verify Handheld item visible
	var r_hand = char_anim.get_node_or_null("ModelTsuna/Armature/Skeleton3D/Attach_RHand")
	if r_hand:
		var held_tsin = r_hand.get_node_or_null("HeldTsinelas")
		if held_tsin and held_tsin.visible:
			print("[PASS] Miniature Spartan Tsinelas visible in Attach_RHand during aiming")
			passes += 1
		else:
			print("[FAIL] HeldTsinelas not visible in right hand during aim!")
			fails += 1
	else:
		print("[FAIL] Attach_RHand not found on ModelTsuna!")
		fails += 1

	# Test Chalk Bag Aim
	char_anim.set_aiming_throw(true, 3)
	if r_hand:
		var held_chalk = r_hand.get_node_or_null("HeldChalkBag")
		var held_tsin = r_hand.get_node_or_null("HeldTsinelas")
		if held_chalk and held_chalk.visible and (held_tsin and not held_tsin.visible):
			print("[PASS] Miniature Chalk Bag visible in Attach_RHand during aiming (Tsinelas hidden)")
			passes += 1
		else:
			print("[FAIL] HeldChalkBag not visible or Tsinelas not hidden during aim!")
			fails += 1

	# Test Throw Action Trigger
	char_anim.trigger_throw_animation(0)
	if char_anim.is_throwing and not char_anim.is_aiming_throw:
		print("[PASS] trigger_throw_animation sets is_throwing = true and clears is_aiming_throw")
		passes += 1
	else:
		print("[FAIL] trigger_throw_animation state error!")
		fails += 1

	# Simulate animate step across release threshold
	char_anim.animate(0.15, 0.0, true, 7.0)
	if r_hand:
		var held_tsin2 = r_hand.get_node_or_null("HeldTsinelas")
		if held_tsin2 and not held_tsin2.visible:
			print("[PASS] Handheld item hides after swing apex release threshold")
			passes += 1
		else:
			print("[FAIL] Handheld item did not hide after release threshold!")
			fails += 1

	# Test 4: PlayerController integration
	var player_scene = load("res://scenes/player/Player.tscn")
	var player: PlayerController = player_scene.instantiate() as PlayerController
	player.player_id = 99
	player.player_name = "ThrowTester"
	root_node.add_child(player)
	await process_frame
	await physics_frame

	# Give player Tsinelas & start aim
	player.held_street_item = 0
	player.held_street_item_count = 1
	player._on_item_input_pressed()
	if player.is_aiming_throw and player.model and player.model.is_aiming_throw:
		print("[PASS] PlayerController _on_item_input_pressed enters aiming mode and updates model")
		passes += 1
	else:
		print("[FAIL] PlayerController aiming mode not propagated to model!")
		fails += 1

	# Release throw
	player._on_item_input_released()
	if not player.is_aiming_throw and player.model and player.model.is_throwing:
		print("[PASS] PlayerController _on_item_input_released triggers model throw animation")
		passes += 1
	else:
		print("[FAIL] PlayerController release failed to trigger throw animation on model!")
		fails += 1

	# Verify projectile spawned in tree
	var spawned_proj: ThrownProjectile = null
	for c in root_node.get_children():
		if c is ThrownProjectile and c.thrower_id == 99:
			spawned_proj = c
			break
	if spawned_proj != null and spawned_proj.is_active:
		print("[PASS] Projectile spawned in scene tree with active flight state")
		passes += 1
	else:
		print("[FAIL] Projectile not found in scene tree!")
		fails += 1

	# Clean up
	root_node.free()

	print("--- TEST RESULTS: %d PASS, %d FAIL ---" % [passes, fails])
	if fails == 0:
		print("[ALL TESTS PASSED]")
		quit(0)
	else:
		quit(1)
