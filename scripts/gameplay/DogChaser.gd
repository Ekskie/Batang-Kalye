class_name DogChaser
extends CharacterBody3D

@export var patrol_speed: float = 4.5
@export var chase_speed: float = 10.0
@export var detection_radius: float = 10.0
@export var attack_radius: float = 1.5
@export var stun_duration: float = 1.5
@export var patrol_center: Vector3 = Vector3(0, 0, 40)
@export var patrol_range: float = 12.0

var gravity: float = -20.0
var target_player: PlayerController = null
var is_chasing: bool = false
var patrol_target: Vector3 = Vector3.ZERO
var patrol_timer: float = 0.0
var stun_cooldowns: Dictionary = {}

func _ready() -> void:
	_pick_new_patrol_target()

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		velocity.y = 0.0

	var to_remove: Array = []
	for pid in stun_cooldowns.keys():
		stun_cooldowns[pid] -= delta
		if stun_cooldowns[pid] <= 0.0:
			to_remove.append(pid)
	for pid in to_remove:
		stun_cooldowns.erase(pid)

	_find_closest_player()

	if is_chasing and is_instance_valid(target_player):
		_chase_target(delta)
		_check_attack()
	else:
		is_chasing = false
		_patrol(delta)

	move_and_slide()

func _find_closest_player() -> void:
	var players_container: Node3D = null
	for child in get_tree().root.get_children():
		var pc = child.get_node_or_null("Players")
		if pc:
			players_container = pc
			break
	if not players_container:
		return

	var closest_dist: float = detection_radius
	var closest: PlayerController = null

	for player in players_container.get_children():
		if player is PlayerController:
			var pc: PlayerController = player as PlayerController
			if pc.current_role != PlayerController.Role.RUNNER:
				continue
			if pc.is_stunned:
				continue
			var dist: float = global_position.distance_to(pc.global_position)
			if dist < closest_dist:
				closest_dist = dist
				closest = pc

	if closest:
		target_player = closest
		is_chasing = true
	else:
		if is_instance_valid(target_player):
			var d: float = global_position.distance_to(target_player.global_position)
			if d > detection_radius * 1.4:
				target_player = null
				is_chasing = false


func _chase_target(_delta: float) -> void:
	var dir: Vector3 = (target_player.global_position - global_position)
	dir.y = 0.0
	if dir.length() > 0.2:
		dir = dir.normalized()
		velocity.x = dir.x * chase_speed
		velocity.z = dir.z * chase_speed
		var look_target: Vector3 = global_position + dir
		look_at(Vector3(look_target.x, global_position.y, look_target.z), Vector3.UP)
	else:
		velocity.x = 0.0
		velocity.z = 0.0

func _check_attack() -> void:
	if not is_instance_valid(target_player):
		return
	var dist: float = global_position.distance_to(target_player.global_position)
	if dist < attack_radius:
		var pid: int = target_player.player_id
		if not stun_cooldowns.has(pid):
			target_player.apply_stun(stun_duration)
			stun_cooldowns[pid] = stun_duration + 2.5
			if Engine.has_singleton("AudioManager"):
				AudioManager.play_dog_bark()
				AudioManager.play_stun()
			elif has_node("/root/AudioManager"):
				get_node("/root/AudioManager").play_dog_bark()
				get_node("/root/AudioManager").play_stun()


func _patrol(delta: float) -> void:
	patrol_timer -= delta
	var dist_to_target: float = global_position.distance_to(patrol_target)

	if patrol_timer <= 0.0 or dist_to_target < 1.0:
		_pick_new_patrol_target()
		return

	var dir: Vector3 = (patrol_target - global_position)
	dir.y = 0.0
	if dir.length() > 0.2:
		dir = dir.normalized()
		velocity.x = dir.x * patrol_speed
		velocity.z = dir.z * patrol_speed
		var look_target: Vector3 = global_position + dir
		look_at(Vector3(look_target.x, global_position.y, look_target.z), Vector3.UP)
	else:
		velocity.x = 0.0
		velocity.z = 0.0

func _pick_new_patrol_target() -> void:
	patrol_target = patrol_center + Vector3(
		randf_range(-patrol_range, patrol_range),
		0,
		randf_range(-patrol_range, patrol_range)
	)
	patrol_timer = randf_range(3.0, 7.0)
