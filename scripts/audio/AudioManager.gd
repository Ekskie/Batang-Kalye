extends Node

# Procedural Sound Synthesizer for Batang Kalye
# Generates audio waveform buffers at runtime for retro/playful Filipino kalye sound effects!

var audio_players: Array[AudioStreamPlayer] = []
const POOL_SIZE: int = 8
var current_player_idx: int = 0

var audio_players_3d: Array[AudioStreamPlayer3D] = []
const POOL_3D_SIZE: int = 8
var current_player_3d_idx: int = 0

# Cached synthesized audio streams (polymorphic AudioStream supporting WAV, OGG, and MP3)
var sfx_pickup: AudioStream
var sfx_bin_correct: AudioStream
var sfx_bin_wrong: AudioStream
var sfx_powerup: AudioStream
var sfx_tag_hit: AudioStream
var sfx_tag_swing: AudioStream
var sfx_drop: AudioStream
var sfx_dog_bark: AudioStream
var sfx_stun: AudioStream
var sfx_danger: AudioStream
var sfx_tick: AudioStream
var sfx_elimination: AudioStream
var sfx_whistle: AudioStream
var sfx_jump: AudioStream
var sfx_land: AudioStream
var sfx_slide: AudioStream
var sfx_dash: AudioStream
var sfx_step_asphalt: AudioStream
var sfx_step_wood: AudioStream
var sfx_step_metal: AudioStream
var sfx_step_grass: AudioStream
var sfx_step_water: AudioStream
var sfx_tag_boom: AudioStream
var sfx_score_ding: AudioStream
var sfx_pant: AudioStream
var sfx_recover_breath: AudioStream
var sfx_tsinelas_throw: AudioStream
var sfx_tsinelas_slap: AudioStream
var sfx_banana_slip: AudioStream
var sfx_drum_hide: AudioStream
var sfx_drum_clang: AudioStream
var sfx_chalk_puff: AudioStream
var sfx_ice_candy: AudioStream
var sfx_vault: AudioStream
var sfx_vote_select: AudioStream
var sfx_vote_win: AudioStream
var sfx_infection_spread: AudioStream
var sfx_final_survivor_sting: AudioStream

# Pre-recorded Voice Lines & Environmental Ambience Streams
var vo_taya_ka: AudioStream
var vo_huli: AudioStream
var vo_aray: AudioStream
var vo_sapul: AudioStream
var vo_safe: AudioStream
var vo_hup: AudioStream
var vo_dulas: AudioStream
var amb_rooster: AudioStream
var amb_trike_horn: AudioStream

# Studio Game SFX & Voice Packs (CHIFREQ Soundworks)
var sfx_jumps: Array[AudioStream] = []
var sfx_runs: Array[AudioStream] = []
var sfx_walks: Array[AudioStream] = []
var sfx_slides: Array[AudioStream] = []

var sfx_ui_click: AudioStream
var sfx_ui_pop: AudioStream
var sfx_ui_cancel: AudioStream
var sfx_ui_reward: AudioStream
var sfx_ui_game_over: AudioStream

var voice_packs: Dictionary = {
	"male_1": { "aray": [], "takbo": [], "taya": [] },
	"male_2": { "aray": [], "takbo": [], "taya": [] },
	"female_1": { "aray": [], "takbo": [], "taya": [] },
	"female_2": { "aray": [], "takbo": [], "taya": [] },
}
var vo_maiba_taya_unison: AudioStream
var vo_nanay_lines: Array[AudioStream] = []
var vo_nanay_hoy: AudioStream

var _ambient_event_timer: float = 0.0
var _next_ambient_event_time: float = 14.0

# Music & Ambience players and volume state
var music_player: AudioStreamPlayer
var ambience_player: AudioStreamPlayer
var current_music_track: String = ""
var music_tracks: Dictionary = {}
var ambience_stream: AudioStreamWAV

var _music_speed_tween: Tween = null
var is_music_sped_up: bool = false
var _last_footstep_msec: int = 0

var sfx_volume: float = 1.0
var music_volume: float = 0.80
var ambience_volume: float = 0.85

var _music_fade_tween: Tween = null
var _is_music_fading: bool = false
const MUSIC_GAIN_OFFSET_DB: float = -6.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_setup_audio_bus_processing()
	# Create pool of 2D / non-positional players
	for i in range(POOL_SIZE):
		var p := AudioStreamPlayer.new()
		p.bus = "Master"
		add_child(p)
		audio_players.append(p)

	# Create pool of 3D positional players
	for i in range(POOL_3D_SIZE):
		var p3d := AudioStreamPlayer3D.new()
		p3d.bus = "Master"
		p3d.max_distance = 35.0
		p3d.attenuation_model = AudioStreamPlayer3D.ATTENUATION_INVERSE_DISTANCE
		add_child(p3d)
		audio_players_3d.append(p3d)

	music_player = AudioStreamPlayer.new()
	music_player.name = "MusicPlayer"
	music_player.bus = "Master"
	music_player.finished.connect(_on_music_player_finished)
	add_child(music_player)

	ambience_player = AudioStreamPlayer.new()
	ambience_player.name = "AmbiencePlayer"
	ambience_player.bus = "Master"
	add_child(ambience_player)

	_synthesize_all_sfx()
	_load_voice_and_ambient_assets()
	_synthesize_ambience_and_music()
	_load_game_audio_collection()
	_update_channel_volumes()
	start_street_ambience()
	play_music_track("ambient")

func _setup_audio_bus_processing() -> void:
	var master_idx = AudioServer.get_bus_index("Master")
	if master_idx >= 0:
		var has_limiter := false
		for i in range(AudioServer.get_bus_effect_count(master_idx)):
			if AudioServer.get_bus_effect(master_idx, i) is AudioEffectLimiter:
				has_limiter = true
				break
		if not has_limiter:
			var limiter := AudioEffectLimiter.new()
			limiter.ceiling_db = -1.0
			limiter.threshold_db = -3.5
			limiter.soft_clip_db = 2.0
			AudioServer.add_bus_effect(master_idx, limiter)

func _process(delta: float) -> void:
	if ambience_volume <= 0.01:
		return
	_ambient_event_timer += delta
	if _ambient_event_timer >= _next_ambient_event_time:
		_ambient_event_timer = 0.0
		_next_ambient_event_time = randf_range(18.0, 35.0)
		if randf() > 0.45:
			play_ambient_rooster()
		else:
			play_ambient_trike_horn()

func _synthesize_all_sfx() -> void:
	sfx_pickup = _create_sweep_tone(700.0, 1400.0, 0.12, 0.6)
	sfx_bin_correct = _create_arpeggio([523.25, 659.25, 783.99, 1046.5], 0.08, 0.7) # C5, E5, G5, C6
	sfx_bin_wrong = _create_dual_thud(160.0, 110.0, 0.18, 0.5)
	sfx_powerup = _create_arpeggio([440.0, 554.37, 659.25, 880.0, 1108.73, 1318.5], 0.06, 0.8) # Stardust fanfare
	sfx_tag_hit = _create_noise_hit(0.15, 0.65)
	sfx_tag_swing = _create_sweep_tone(450.0, 160.0, 0.12, 0.4)
	sfx_drop = _create_sweep_tone(400.0, 180.0, 0.10, 0.4)
	sfx_dog_bark = _create_dog_bark(0.22, 0.7)
	sfx_stun = _create_sweep_tone(600.0, 250.0, 0.35, 0.6)
	sfx_danger = _create_heartbeat(0.25, 0.5)
	sfx_tick = _create_clock_tick(0.03, 0.25)
	sfx_elimination = _create_explosion_boom(0.65, 0.85)
	sfx_whistle = _create_whistle(0.35, 0.65)
	sfx_jump = _create_sweep_tone(220.0, 520.0, 0.12, 0.5)
	sfx_land = _create_noise_hit(0.14, 0.55)
	sfx_slide = _create_slide_sound(0.25, 0.45)
	sfx_dash = _create_sweep_tone(950.0, 240.0, 0.16, 0.7)
	sfx_step_asphalt = _create_sweep_tone(210.0, 105.0, 0.045, 0.18)
	sfx_step_wood = _create_dual_thud(260.0, 145.0, 0.055, 0.20)
	sfx_step_metal = _create_sweep_tone(340.0, 220.0, 0.045, 0.16)
	sfx_step_grass = _create_pant_sound(0.045, 0.14)
	sfx_step_water = _create_sweep_tone(280.0, 180.0, 0.05, 0.16)
	sfx_tag_boom = _create_explosion_boom(0.45, 0.8)
	sfx_score_ding = _create_arpeggio([587.33, 880.0, 1174.66], 0.06, 0.75)
	sfx_pant = _create_pant_sound(0.24, 0.6)
	sfx_recover_breath = _create_sweep_tone(300.0, 600.0, 0.22, 0.45)
	sfx_tsinelas_throw = _create_sweep_tone(900.0, 320.0, 0.12, 0.55)
	sfx_tsinelas_slap = _create_noise_hit(0.18, 0.95)
	sfx_banana_slip = _create_slide_whistle(0.38, 0.75)
	sfx_drum_hide = _create_dual_thud(130.0, 80.0, 0.22, 0.6)
	sfx_drum_clang = _create_gong_clang(0.45, 0.85)
	sfx_chalk_puff = _create_sweep_tone(600.0, 150.0, 0.16, 0.5)
	sfx_ice_candy = _create_arpeggio([523.25, 659.25, 783.99, 1046.5, 1318.51], 0.05, 0.8)
	sfx_vault = _create_sweep_tone(260.0, 620.0, 0.15, 0.6)
	sfx_vote_select = _create_sweep_tone(440.0, 880.0, 0.08, 0.5)
	sfx_vote_win = _create_arpeggio([523.25, 659.25, 783.99, 1046.50, 1318.51], 0.07, 0.8)
	sfx_infection_spread = _create_arpeggio([392.0, 311.13, 261.63, 523.25], 0.065, 0.78)
	sfx_final_survivor_sting = _create_arpeggio([523.25, 659.25, 783.99, 1046.50, 1567.98], 0.085, 0.88)

func _synthesize_ambience_and_music() -> void:
	ambience_stream = _create_street_ambience_loop(3.2, 0.14)
	music_tracks["lobby"] = _create_music_loop([261.63, 329.63, 392.00, 329.63, 293.66, 369.99, 440.00, 392.00], 0.24, 0.16)
	music_tracks["chase"] = _create_music_loop([329.63, 392.00, 440.00, 493.88, 523.25, 493.88, 440.00, 392.00], 0.16, 0.18)
	music_tracks["final_seconds"] = _create_music_loop([440.00, 523.25, 587.33, 659.25, 587.33, 523.25, 659.25, 783.99], 0.11, 0.20)
	music_tracks["victory"] = _create_music_loop([523.25, 659.25, 783.99, 1046.50, 783.99, 1046.50, 659.25, 783.99], 0.20, 0.18)
	music_tracks["defeat"] = _create_music_loop([392.00, 349.23, 329.63, 293.66, 261.63, 293.66, 329.63, 261.63], 0.28, 0.15)

func set_sfx_volume(val: float) -> void:
	sfx_volume = clampf(val, 0.0, 1.0)
	_update_channel_volumes()

func set_music_volume(val: float) -> void:
	music_volume = clampf(val, 0.0, 1.0)
	_update_channel_volumes()

func set_ambience_volume(val: float) -> void:
	ambience_volume = clampf(val, 0.0, 1.0)
	_update_channel_volumes()

func _get_target_music_db() -> float:
	return (linear_to_db(maxf(0.0001, music_volume)) + MUSIC_GAIN_OFFSET_DB) if music_volume > 0.01 else -80.0

func _update_channel_volumes() -> void:
	var sfx_db: float = linear_to_db(maxf(0.0001, sfx_volume)) if sfx_volume > 0.01 else -80.0
	for p in audio_players:
		if is_instance_valid(p):
			p.volume_db = sfx_db
	for p3d in audio_players_3d:
		if is_instance_valid(p3d):
			p3d.volume_db = sfx_db
	# Professional level mixing: Energetic & Vibrant Kalye Vibe (-6 dB base offset)
	if is_instance_valid(music_player) and not _is_music_fading:
		music_player.volume_db = _get_target_music_db()
	if is_instance_valid(ambience_player):
		# Muted 8-bit synthetic random noise loop to prevent sandpaper 'kiskis' background rasp
		ambience_player.volume_db = -80.0

func start_street_ambience() -> void:
	# Disabled 8-bit synthetic noise loop so it doesn't clash with studio audio
	if is_instance_valid(ambience_player) and ambience_player.playing:
		ambience_player.stop()

func _on_music_player_finished() -> void:
	# Automatic loop replay safety: ensures music continuously plays even if a track finishes
	if is_instance_valid(music_player) and not music_player.playing and current_music_track != "":
		if music_tracks.has(current_music_track):
			music_player.stream = music_tracks[current_music_track]
			music_player.volume_db = _get_target_music_db()
			music_player.play()

func play_music_track(track_name: String) -> void:
	if not is_instance_valid(music_player):
		return
	var resolved_track := track_name
	if track_name in ["lobby", "title", "menu", "store", "customization", "ambient"]:
		resolved_track = "ambient" if music_tracks.has("ambient") else ("lobby" if music_tracks.has("lobby") else track_name)
	elif track_name in ["match", "game", "in_game", "chase", "gameplay"]:
		resolved_track = "in_game" if music_tracks.has("in_game") else ("chase" if music_tracks.has("chase") else track_name)

	if current_music_track == resolved_track and music_player.playing:
		return
	if not music_tracks.has(resolved_track):
		return

	var target_stream: AudioStream = music_tracks[resolved_track]
	var target_db: float = _get_target_music_db()

	if _music_fade_tween and _music_fade_tween.is_valid():
		_music_fade_tween.kill()
	if _music_speed_tween and _music_speed_tween.is_valid():
		_music_speed_tween.kill()
	is_music_sped_up = false
	if is_instance_valid(music_player):
		music_player.pitch_scale = 1.0

	# If nothing is currently playing or this is the first play, start immediately
	if not music_player.playing or current_music_track == "":
		current_music_track = resolved_track
		music_player.stream = target_stream
		music_player.volume_db = target_db
		music_player.play()
		return

	# Smooth 0.6s crossfade (0.3s fade out, 0.3s fade in)
	_is_music_fading = true
	_music_fade_tween = create_tween()
	_music_fade_tween.tween_property(music_player, "volume_db", -80.0, 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_music_fade_tween.tween_callback(func():
		current_music_track = resolved_track
		music_player.stream = target_stream
		music_player.play()
	)
	_music_fade_tween.tween_property(music_player, "volume_db", target_db, 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_music_fade_tween.tween_callback(func():
		_is_music_fading = false
	)

func set_music_speed(target_speed: float = 1.0, duration: float = 0.4) -> void:
	if not is_instance_valid(music_player):
		return
	if _music_speed_tween and _music_speed_tween.is_valid():
		_music_speed_tween.kill()
	is_music_sped_up = (target_speed > 1.05)
	if duration <= 0.01:
		music_player.pitch_scale = target_speed
		return
	_music_speed_tween = create_tween()
	_music_speed_tween.tween_property(music_player, "pitch_scale", target_speed, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func stop_music() -> void:
	if _music_fade_tween and _music_fade_tween.is_valid():
		_music_fade_tween.kill()
	if _music_speed_tween and _music_speed_tween.is_valid():
		_music_speed_tween.kill()
	_is_music_fading = false
	is_music_sped_up = false
	if is_instance_valid(music_player):
		music_player.stop()
		music_player.pitch_scale = 1.0
	current_music_track = ""

func play_sfx(stream: AudioStream, pitch_scale: float = 1.0, volume_offset_db: float = 0.0) -> void:
	if not stream or audio_players.is_empty() or sfx_volume <= 0.01:
		return
	var player: AudioStreamPlayer = audio_players[current_player_idx]
	current_player_idx = (current_player_idx + 1) % POOL_SIZE
	var base_sfx_db: float = linear_to_db(maxf(0.0001, sfx_volume)) if sfx_volume > 0.01 else -80.0
	player.volume_db = base_sfx_db + volume_offset_db
	player.stream = stream
	player.pitch_scale = pitch_scale + randf_range(-0.04, 0.04)
	player.play()

func play_sfx_3d(stream: AudioStream, global_pos: Vector3, max_distance: float = 35.0, pitch_scale: float = 1.0, volume_offset_db: float = 0.0) -> void:
	if not stream or audio_players_3d.is_empty() or sfx_volume <= 0.01:
		return
	var player: AudioStreamPlayer3D = audio_players_3d[current_player_3d_idx]
	current_player_3d_idx = (current_player_3d_idx + 1) % POOL_3D_SIZE
	var base_sfx_db: float = linear_to_db(maxf(0.0001, sfx_volume)) if sfx_volume > 0.01 else -80.0
	player.volume_db = base_sfx_db + volume_offset_db
	player.global_position = global_pos
	player.max_distance = max_distance
	player.stream = stream
	player.pitch_scale = pitch_scale + randf_range(-0.04, 0.04)
	player.play()

func play_whiff() -> void:
	play_sfx(sfx_tag_swing, randf_range(0.95, 1.15))

func play_pickup() -> void:
	play_sfx(sfx_pickup, randf_range(0.95, 1.1))

func play_bin_correct() -> void:
	if sfx_ui_reward:
		play_sfx(sfx_ui_reward, 1.0)
	else:
		play_sfx(sfx_bin_correct, 1.0)

func play_bin_wrong() -> void:
	play_sfx(sfx_bin_wrong, 1.0)

func play_powerup() -> void:
	play_sfx(sfx_powerup, 1.0)

func play_tag_hit() -> void:
	play_sfx(sfx_tag_hit, randf_range(0.9, 1.1))

func play_tag_swing() -> void:
	play_sfx(sfx_tag_swing, randf_range(0.95, 1.15))

func play_drop() -> void:
	play_sfx(sfx_drop, randf_range(0.95, 1.05))

func play_dog_bark() -> void:
	play_sfx(sfx_dog_bark, randf_range(0.9, 1.1))

func play_stun() -> void:
	play_sfx(sfx_stun, 1.0)

func play_danger() -> void:
	play_sfx(sfx_danger, 1.0)

func play_tick() -> void:
	play_sfx(sfx_tick, randf_range(0.98, 1.02))

func play_elimination() -> void:
	play_sfx(sfx_elimination, 1.0)

func play_whistle() -> void:
	play_sfx(sfx_whistle, 1.0)

func play_jump() -> void:
	if not sfx_jumps.is_empty():
		var stream: AudioStream = sfx_jumps[randi() % sfx_jumps.size()]
		play_sfx(stream, randf_range(0.96, 1.04), -10.0)
	else:
		play_sfx(sfx_jump, randf_range(0.95, 1.1), -10.0)

func play_land(speed: float = 5.0) -> void:
	var pitch: float = clampf(1.2 - (speed / 30.0), 0.7, 1.2)
	play_sfx(sfx_land, pitch, -10.0)

func play_slide() -> void:
	if not sfx_slides.is_empty():
		var stream: AudioStream = sfx_slides[randi() % sfx_slides.size()]
		play_sfx(stream, randf_range(0.96, 1.04), -12.0)
	else:
		play_sfx(sfx_slide, randf_range(0.95, 1.05), -12.0)

func play_dash() -> void:
	play_sfx(sfx_dash, randf_range(0.98, 1.12), -6.0)

func play_footstep(in_water: bool = false) -> void:
	var now := Time.get_ticks_msec()
	if now - _last_footstep_msec < 95:
		return
	_last_footstep_msec = now
	if in_water:
		play_sfx(sfx_step_water, randf_range(0.85, 1.2), -14.0)
	else:
		if not sfx_walks.is_empty():
			play_sfx(sfx_walks[randi() % sfx_walks.size()], randf_range(0.96, 1.04), -20.0)
		else:
			play_sfx(sfx_step_asphalt, randf_range(0.85, 1.2), -18.0)

func play_surface_footstep(surface: String, is_sprinting: bool = false) -> void:
	var now := Time.get_ticks_msec()
	if now - _last_footstep_msec < 95:
		return
	_last_footstep_msec = now
	var pitch_boost: float = 0.06 if is_sprinting else 0.0
	match surface:
		"water":
			play_sfx(sfx_step_water, randf_range(0.88, 1.18) + pitch_boost, -14.0)
		"metal":
			play_sfx(sfx_step_metal, randf_range(0.92, 1.15) + pitch_boost, -15.0)
		"wood":
			play_sfx(sfx_step_wood, randf_range(0.90, 1.12) + pitch_boost, -15.0)
		"grass":
			play_sfx(sfx_step_grass, randf_range(0.90, 1.15) + pitch_boost, -18.0)
		_:
			if is_sprinting and not sfx_runs.is_empty():
				var stream: AudioStream = sfx_runs[randi() % sfx_runs.size()]
				play_sfx(stream, randf_range(0.96, 1.04), -17.0)
			elif not is_sprinting and not sfx_walks.is_empty():
				var stream: AudioStream = sfx_walks[randi() % sfx_walks.size()]
				play_sfx(stream, randf_range(0.96, 1.04), -20.0)
			else:
				play_sfx(sfx_step_asphalt, randf_range(0.88, 1.18) + pitch_boost, -18.0)

func play_surface_footstep_3d(surface: String, global_pos: Vector3, is_sprinting: bool = false) -> void:
	var now := Time.get_ticks_msec()
	if now - _last_footstep_msec < 85:
		return
	_last_footstep_msec = now
	var pitch_boost: float = 0.06 if is_sprinting else 0.0
	match surface:
		"water":
			play_sfx_3d(sfx_step_water, global_pos, 14.0, randf_range(0.88, 1.18) + pitch_boost, -16.0)
		"metal":
			play_sfx_3d(sfx_step_metal, global_pos, 14.0, randf_range(0.92, 1.15) + pitch_boost, -17.0)
		"wood":
			play_sfx_3d(sfx_step_wood, global_pos, 14.0, randf_range(0.90, 1.12) + pitch_boost, -17.0)
		"grass":
			play_sfx_3d(sfx_step_grass, global_pos, 14.0, randf_range(0.90, 1.15) + pitch_boost, -20.0)
		_:
			if is_sprinting and not sfx_runs.is_empty():
				var stream: AudioStream = sfx_runs[randi() % sfx_runs.size()]
				play_sfx_3d(stream, global_pos, 14.0, randf_range(0.96, 1.04), -20.0)
			elif not is_sprinting and not sfx_walks.is_empty():
				var stream: AudioStream = sfx_walks[randi() % sfx_walks.size()]
				play_sfx_3d(stream, global_pos, 14.0, randf_range(0.96, 1.04), -23.0)
			else:
				play_sfx_3d(sfx_step_asphalt, global_pos, 14.0, randf_range(0.88, 1.18) + pitch_boost, -21.0)

# --- UI Sound Effects (CHIFREQ Soundworks) ---
func play_ui_click(pitch_scale: float = 1.0) -> void:
	if sfx_ui_click:
		play_sfx(sfx_ui_click, pitch_scale, -12.0)
	else:
		play_sfx(sfx_tick, pitch_scale, -12.0)

func play_ui_pop(pitch_scale: float = 1.0) -> void:
	if sfx_ui_pop:
		play_sfx(sfx_ui_pop, pitch_scale, -8.0)
	else:
		play_sfx(sfx_pickup, pitch_scale, -8.0)

func play_ui_cancel(pitch_scale: float = 1.0) -> void:
	if sfx_ui_cancel:
		play_sfx(sfx_ui_cancel, pitch_scale, -10.0)
	else:
		play_sfx(sfx_drop, pitch_scale, -10.0)

func play_ui_reward(pitch_scale: float = 1.0) -> void:
	if sfx_ui_reward:
		play_sfx(sfx_ui_reward, pitch_scale, -8.0)
	else:
		play_sfx(sfx_score_ding, pitch_scale, -8.0)

func play_ui_game_over(pitch_scale: float = 1.0) -> void:
	if sfx_ui_game_over:
		play_sfx(sfx_ui_game_over, pitch_scale, -6.0)
	else:
		play_sfx(sfx_elimination, pitch_scale, -6.0)

func play_infection_spread() -> void:
	play_sfx(sfx_infection_spread, randf_range(0.95, 1.05))

func play_final_survivor_sting() -> void:
	play_sfx(sfx_final_survivor_sting, 1.0)

func play_tag_boom() -> void:
	play_sfx(sfx_tag_boom, 1.0)

func play_score_ding() -> void:
	if sfx_ui_reward:
		play_sfx(sfx_ui_reward, 1.0)
	else:
		play_sfx(sfx_score_ding, 1.0)

func play_pant() -> void:
	play_sfx(sfx_pant, randf_range(0.95, 1.08))

func play_recover_breath() -> void:
	play_sfx(sfx_recover_breath, 1.0)

func play_tsinelas_throw() -> void:
	play_sfx(sfx_tsinelas_throw, randf_range(0.95, 1.1))

func play_tsinelas_slap() -> void:
	play_sfx(sfx_tsinelas_slap, randf_range(0.9, 1.15))

func play_banana_slip() -> void:
	play_sfx(sfx_banana_slip, randf_range(0.95, 1.05))

func play_drum_hide() -> void:
	play_sfx(sfx_drum_hide, 1.0)

func play_drum_clang() -> void:
	play_sfx(sfx_drum_clang, 1.0)

func play_chalk_puff() -> void:
	play_sfx(sfx_chalk_puff, randf_range(0.9, 1.1))

func play_ice_candy() -> void:
	play_sfx(sfx_ice_candy, 1.0)

func play_vault() -> void:
	play_sfx(sfx_vault, randf_range(0.95, 1.15))

func play_vote() -> void:
	play_sfx(sfx_vote_select, randf_range(0.95, 1.05))

func play_vote_win() -> void:
	play_sfx(sfx_vote_win, 1.0)

# --- Voice Lines & Character Pitch Shifting ---

func _load_audio_file(res_path: String) -> AudioStream:
	if ResourceLoader.exists(res_path):
		var res = ResourceLoader.load(res_path)
		if res is AudioStream:
			return res
	if FileAccess.file_exists(res_path):
		var loaded_wav = AudioStreamWAV.load_from_file(res_path)
		if loaded_wav:
			return loaded_wav
	return null

func _load_voice_and_ambient_assets() -> void:
	vo_taya_ka = _load_audio_file("res://assets/audio/vo/vo_taya_ka.wav")
	vo_huli = _load_audio_file("res://assets/audio/vo/vo_huli.wav")
	vo_aray = _load_audio_file("res://assets/audio/vo/vo_aray.wav")
	vo_sapul = _load_audio_file("res://assets/audio/vo/vo_sapul.wav")
	vo_safe = _load_audio_file("res://assets/audio/vo/vo_safe.wav")
	vo_hup = _load_audio_file("res://assets/audio/vo/vo_hup.wav")
	vo_dulas = _load_audio_file("res://assets/audio/vo/vo_dulas.wav")

	amb_rooster = _load_audio_file("res://assets/audio/ambience/amb_rooster.wav")
	amb_trike_horn = _load_audio_file("res://assets/audio/ambience/amb_trike_horn.wav")

func _load_game_audio_collection() -> void:
	# 1. Action SFX
	var jump_paths := [
		"res://assets/Game SFX/SFX/Action SFX/Jump/Jumping SFX - Jumping 1.wav",
		"res://assets/Game SFX/SFX/Action SFX/Jump/Jumping SFX - Jumping 2.wav",
		"res://assets/Game SFX/SFX/Action SFX/Jump/Jumping SFX - Jumping 3.wav"
	]
	for p in jump_paths:
		var s := _load_audio_file(p)
		if s: sfx_jumps.append(s)

	var run_paths := [
		"res://assets/Game SFX/SFX/Action SFX/Running/RUNNING SFX - Running 1.wav",
		"res://assets/Game SFX/SFX/Action SFX/Running/RUNNING SFX - Running 2.wav",
		"res://assets/Game SFX/SFX/Action SFX/Running/RUNNING SFX - Running 3.wav"
	]
	for p in run_paths:
		var s := _load_audio_file(p)
		if s: sfx_runs.append(s)

	var walk_paths := [
		"res://assets/Game SFX/SFX/Action SFX/Walking/WALKING SFX - Walking 1.wav",
		"res://assets/Game SFX/SFX/Action SFX/Walking/WALKING SFX - Walking 2.wav",
		"res://assets/Game SFX/SFX/Action SFX/Walking/WALKING SFX - Walking 3.wav"
	]
	for p in walk_paths:
		var s := _load_audio_file(p)
		if s: sfx_walks.append(s)

	var slide_paths := [
		"res://assets/Game SFX/SFX/Action SFX/Slide/Slide SFX - Slide 1.wav",
		"res://assets/Game SFX/SFX/Action SFX/Slide/Slide SFX - Slide 2.wav",
		"res://assets/Game SFX/SFX/Action SFX/Slide/Slide SFX - Slide 3.wav"
	]
	for p in slide_paths:
		var s := _load_audio_file(p)
		if s: sfx_slides.append(s)

	# 2. UI SFX
	sfx_ui_click = _load_audio_file("res://assets/Game SFX/SFX/UI/UI SFX - Standard Button Click.wav")
	sfx_ui_pop = _load_audio_file("res://assets/Game SFX/SFX/UI/UI SFX - Primary Action Pop.wav")
	sfx_ui_cancel = _load_audio_file("res://assets/Game SFX/SFX/UI/UI SFX - Back _ Cancel Bloop.wav")
	sfx_ui_reward = _load_audio_file("res://assets/Game SFX/SFX/UI/UI SFX - Reward Sparkle Chime.wav")
	sfx_ui_game_over = _load_audio_file("res://assets/Game SFX/SFX/UI/UI SFX - Game Over.wav")

	# 3. Voice Packs
	# Male 1 (Tsuna, Totoy, Nonoy)
	var m1_aray := [
		"res://assets/Game SFX/Voice Packs/Male 1/Aray!/Aray 1.wav",
		"res://assets/Game SFX/Voice Packs/Male 1/Aray!/Aray 2.wav",
		"res://assets/Game SFX/Voice Packs/Male 1/Aray!/Aray 3.wav",
		"res://assets/Game SFX/Voice Packs/Male 1/Aray!/Aray 4.wav",
		"res://assets/Game SFX/Voice Packs/Male 1/Aray!/Aray 5.wav"
	]
	for p in m1_aray:
		var s := _load_audio_file(p)
		if s: voice_packs["male_1"]["aray"].append(s)

	var m1_takbo := [
		"res://assets/Game SFX/Voice Packs/Male 1/Takbo!/Voice Over_Lines 2 - Voice_Audio.wav",
		"res://assets/Game SFX/Voice Packs/Male 1/Takbo!/Voice Over_Lines 2 - Voice_Audio (1).wav",
		"res://assets/Game SFX/Voice Packs/Male 1/Takbo!/Voice Over_Lines 2 - Voice_Audio (2).wav"
	]
	for p in m1_takbo:
		var s := _load_audio_file(p)
		if s: voice_packs["male_1"]["takbo"].append(s)

	var m1_taya := [
		"res://assets/Game SFX/Voice Packs/Male 1/Taya!/Taya 1.wav",
		"res://assets/Game SFX/Voice Packs/Male 1/Taya!/Taya 2.wav",
		"res://assets/Game SFX/Voice Packs/Male 1/Taya!/Taya 3.wav",
		"res://assets/Game SFX/Voice Packs/Male 1/Taya!/Taya 4.wav",
		"res://assets/Game SFX/Voice Packs/Male 1/Taya!/Taya 5.wav"
	]
	for p in m1_taya:
		var s := _load_audio_file(p)
		if s: voice_packs["male_1"]["taya"].append(s)

	# Male 2 (Kalbo, Tisoy, Baldo)
	var m2_aray := [
		"res://assets/Game SFX/Voice Packs/Male 2/Aray!/New Project - Aray.wav",
		"res://assets/Game SFX/Voice Packs/Male 2/Aray!/New Project - Aray (1).wav",
		"res://assets/Game SFX/Voice Packs/Male 2/Aray!/New Project - Aray (2).wav",
		"res://assets/Game SFX/Voice Packs/Male 2/Aray!/New Project - Aray (3).wav"
	]
	for p in m2_aray:
		var s := _load_audio_file(p)
		if s: voice_packs["male_2"]["aray"].append(s)

	var m2_takbo := [
		"res://assets/Game SFX/Voice Packs/Male 2/Takbo!/New Project - Takbo.wav",
		"res://assets/Game SFX/Voice Packs/Male 2/Takbo!/New Project - Takbo (1).wav",
		"res://assets/Game SFX/Voice Packs/Male 2/Takbo!/New Project - Takbo (2).wav",
		"res://assets/Game SFX/Voice Packs/Male 2/Takbo!/New Project - Takbo (3).wav"
	]
	for p in m2_takbo:
		var s := _load_audio_file(p)
		if s: voice_packs["male_2"]["takbo"].append(s)

	var m2_taya := [
		"res://assets/Game SFX/Voice Packs/Male 2/Taya!/New Project - Taya.wav",
		"res://assets/Game SFX/Voice Packs/Male 2/Taya!/New Project - Taya (1).wav",
		"res://assets/Game SFX/Voice Packs/Male 2/Taya!/New Project - Taya (2).wav",
		"res://assets/Game SFX/Voice Packs/Male 2/Taya!/New Project - Taya (3).wav"
	]
	for p in m2_taya:
		var s := _load_audio_file(p)
		if s: voice_packs["male_2"]["taya"].append(s)

	# Female 1 (Nene)
	var f1_aray := [
		"res://assets/Game SFX/Voice Packs/Female 1/Aray!/Aray 1 - Voice_Audio.wav",
		"res://assets/Game SFX/Voice Packs/Female 1/Aray!/Aray 2 - Voice_Audio.wav",
		"res://assets/Game SFX/Voice Packs/Female 1/Aray!/Aray 3 - Voice_Audio.wav",
		"res://assets/Game SFX/Voice Packs/Female 1/Aray!/Aray 4 - Voice_Audio.wav",
		"res://assets/Game SFX/Voice Packs/Female 1/Aray!/Aray 5 - Voice_Audio.wav"
	]
	for p in f1_aray:
		var s := _load_audio_file(p)
		if s: voice_packs["female_1"]["aray"].append(s)

	var f1_takbo := [
		"res://assets/Game SFX/Voice Packs/Female 1/Takbo!/Takbo 1 - Voice_Audio.wav",
		"res://assets/Game SFX/Voice Packs/Female 1/Takbo!/Takbo 2 - Voice_Audio.wav",
		"res://assets/Game SFX/Voice Packs/Female 1/Takbo!/Takbo 3 - Voice_Audio.wav"
	]
	for p in f1_takbo:
		var s := _load_audio_file(p)
		if s: voice_packs["female_1"]["takbo"].append(s)

	var f1_taya := [
		"res://assets/Game SFX/Voice Packs/Female 1/Taya!/Taya 1 - Voice_Audio.wav",
		"res://assets/Game SFX/Voice Packs/Female 1/Taya!/Taya 2 - Voice_Audio.wav",
		"res://assets/Game SFX/Voice Packs/Female 1/Taya!/Taya 3 - Voice_Audio.wav",
		"res://assets/Game SFX/Voice Packs/Female 1/Taya!/Taya 4 - Voice_Audio.wav"
	]
	for p in f1_taya:
		var s := _load_audio_file(p)
		if s: voice_packs["female_1"]["taya"].append(s)

	# Female 2 (Kikay)
	var f2_aray := [
		"res://assets/Game SFX/Voice Packs/Female 2/Aray/Voice Over_Lines 1 - Aray.wav",
		"res://assets/Game SFX/Voice Packs/Female 2/Aray/Voice Over_Lines 1 - Aray (1).wav",
		"res://assets/Game SFX/Voice Packs/Female 2/Aray/Voice Over_Lines 1 - Aray (2).wav",
		"res://assets/Game SFX/Voice Packs/Female 2/Aray/Voice Over_Lines 1 - Aray (3).wav"
	]
	for p in f2_aray:
		var s := _load_audio_file(p)
		if s: voice_packs["female_2"]["aray"].append(s)

	var f2_takbo := [
		"res://assets/Game SFX/Voice Packs/Female 2/Takbo/Voice Over_Lines 1 - Takbo.wav",
		"res://assets/Game SFX/Voice Packs/Female 2/Takbo/Voice Over_Lines 1 - Takbo (1).wav",
		"res://assets/Game SFX/Voice Packs/Female 2/Takbo/Voice Over_Lines 1 - Takbo (2).wav",
		"res://assets/Game SFX/Voice Packs/Female 2/Takbo/Voice Over_Lines 1 - Takbo (3).wav",
		"res://assets/Game SFX/Voice Packs/Female 2/Takbo/Voice Over_Lines 1 - Takbo (4).wav"
	]
	for p in f2_takbo:
		var s := _load_audio_file(p)
		if s: voice_packs["female_2"]["takbo"].append(s)

	var f2_taya := [
		"res://assets/Game SFX/Voice Packs/Female 2/Taya/Voice Over_Lines 1 - Taya!.wav",
		"res://assets/Game SFX/Voice Packs/Female 2/Taya/Voice Over_Lines 1 - Taya.wav",
		"res://assets/Game SFX/Voice Packs/Female 2/Taya/Voice Over_Lines 1 - Voice_Audio.wav"
	]
	for p in f2_taya:
		var s := _load_audio_file(p)
		if s: voice_packs["female_2"]["taya"].append(s)

	# 4. Maiba Taya Unison & Nanay
	vo_maiba_taya_unison = _load_audio_file("res://assets/Game SFX/Voice Packs/Maiba taya! (Unison)/Maibay_Taya.wav")

	var nanay_paths := [
		"res://assets/Game SFX/Voice Packs/Nanay V.O/Voice Over_Lines 1 - Hoy Gabi na umuwi na kayo.wav",
		"res://assets/Game SFX/Voice Packs/Nanay V.O/Voice Over_Lines 1 - Hoy Gabi na umuwi na kayo (1).wav",
		"res://assets/Game SFX/Voice Packs/Nanay V.O/Voice Over_Lines 1 - Hoy Gabi na umuwi na kayo (2).wav"
	]
	for p in nanay_paths:
		var s := _load_audio_file(p)
		if s: vo_nanay_lines.append(s)
	vo_nanay_hoy = _load_audio_file("res://assets/Game SFX/Voice Packs/Nanay V.O/Voice Over_Lines 1 - Hoy.wav")

	# 5. Studio BGM Tracks
	var bgm_amb = _load_audio_file("res://assets/Game SFX/BGM/Game Ambient Music.wav")
	if bgm_amb is AudioStreamWAV:
		bgm_amb.loop_mode = AudioStreamWAV.LOOP_FORWARD
		bgm_amb.loop_begin = 0
		var amb_samples: int = int(round(bgm_amb.get_length() * bgm_amb.mix_rate))
		bgm_amb.loop_end = amb_samples
	if bgm_amb:
		music_tracks["ambient"] = bgm_amb
		music_tracks["lobby"] = bgm_amb

	var bgm_ingame = _load_audio_file("res://assets/Game SFX/BGM/IN GAME BGM.wav")
	if bgm_ingame is AudioStreamWAV:
		bgm_ingame.loop_mode = AudioStreamWAV.LOOP_FORWARD
		bgm_ingame.loop_begin = 0
		var ingame_samples: int = int(round(bgm_ingame.get_length() * bgm_ingame.mix_rate))
		bgm_ingame.loop_end = ingame_samples
	if bgm_ingame:
		music_tracks["in_game"] = bgm_ingame
		music_tracks["match"] = bgm_ingame
		music_tracks["chase"] = bgm_ingame

func get_character_pitch_scale(character_type: int) -> float:
	match character_type:
		1: # Kalbo (gruff, deeper pitch)
			return 0.90
		2: # Totoy (youthful, energetic)
			return 1.10
		3: # Tisoy (cool, laid-back)
			return 0.98
		4: # Nene (high, bright, animated)
			return 1.22
		_: # Tsuna / default
			return 1.00

func get_voice_pack_for_character(char_type: int) -> String:
	match char_type:
		3: # Nene
			return "female_1"
		7: # Kikay
			return "female_2"
		1, 4, 5: # Kalbo, Tisoy, Baldo
			return "male_2"
		_: # Tsuna (0), Totoy (2), Nonoy (6)
			return "male_1"

func play_voice_line(voice_pack_key: String, line_type: String, global_pos: Vector3, pitch_offset: float = 0.0) -> void:
	var pack = voice_packs.get(voice_pack_key, voice_packs.get("male_1"))
	if pack and pack.has(line_type):
		var lines: Array = pack[line_type]
		if not lines.is_empty():
			var stream: AudioStream = lines[randi() % lines.size()]
			if stream:
				play_sfx_3d(stream, global_pos, 32.0, 1.0 + pitch_offset + randf_range(-0.03, 0.03), -4.0)
				return
	# Fallback if specific line not found
	match line_type:
		"aray":
			if vo_aray: play_vo_3d(vo_aray, global_pos, 0, pitch_offset)
		"taya":
			var s: AudioStream = vo_huli if randf() > 0.5 else vo_taya_ka
			if s: play_vo_3d(s, global_pos, 0, pitch_offset)
		"takbo":
			if vo_dulas: play_vo_3d(vo_dulas, global_pos, 0, pitch_offset)

func play_vo_3d(stream: AudioStream, global_pos: Vector3, char_type: int = 0, pitch_offset: float = 0.0) -> void:
	if not stream:
		return
	var base_pitch: float = get_character_pitch_scale(char_type) + pitch_offset
	play_sfx_3d(stream, global_pos, 28.0, base_pitch)

func play_vo_taya(global_pos: Vector3, char_type: int = 0) -> void:
	var pack_key := get_voice_pack_for_character(char_type)
	play_voice_line(pack_key, "taya", global_pos)

func play_vo_takbo(global_pos: Vector3, char_type: int = 0) -> void:
	var pack_key := get_voice_pack_for_character(char_type)
	play_voice_line(pack_key, "takbo", global_pos)

func play_vo_huli(global_pos: Vector3, char_type: int = 0) -> void:
	var pack_key := get_voice_pack_for_character(char_type)
	play_voice_line(pack_key, "taya", global_pos)

func play_vo_aray(global_pos: Vector3, char_type: int = 0) -> void:
	var pack_key := get_voice_pack_for_character(char_type)
	play_voice_line(pack_key, "aray", global_pos)

func play_vo_sapul(global_pos: Vector3, char_type: int = 0) -> void:
	var pack_key := get_voice_pack_for_character(char_type)
	play_voice_line(pack_key, "aray", global_pos)

func play_vo_safe(global_pos: Vector3, char_type: int = 0) -> void:
	if vo_safe:
		play_vo_3d(vo_safe, global_pos, char_type)

func play_vo_hup(global_pos: Vector3, char_type: int = 0) -> void:
	if vo_hup:
		play_vo_3d(vo_hup, global_pos, char_type)

func play_vo_dulas(global_pos: Vector3, char_type: int = 0) -> void:
	var pack_key := get_voice_pack_for_character(char_type)
	play_voice_line(pack_key, "aray", global_pos)

func play_maiba_taya_unison() -> void:
	if vo_maiba_taya_unison:
		play_sfx(vo_maiba_taya_unison, 1.0)
	else:
		play_powerup()

func play_nanay_callout(global_pos: Vector3 = Vector3.ZERO) -> void:
	if not vo_nanay_lines.is_empty():
		var stream: AudioStream = vo_nanay_lines[randi() % vo_nanay_lines.size()]
		if global_pos != Vector3.ZERO:
			play_sfx_3d(stream, global_pos, 80.0, randf_range(0.98, 1.02))
		else:
			play_sfx(stream, 1.0)
	else:
		play_whistle()

func play_nanay_hoy(global_pos: Vector3 = Vector3.ZERO) -> void:
	if vo_nanay_hoy:
		if global_pos != Vector3.ZERO:
			play_sfx_3d(vo_nanay_hoy, global_pos, 80.0, randf_range(0.98, 1.02))
		else:
			play_sfx(vo_nanay_hoy, 1.0)
	else:
		play_whistle()

func play_ambient_rooster(global_pos: Vector3 = Vector3.ZERO) -> void:
	if amb_rooster:
		if global_pos != Vector3.ZERO:
			play_sfx_3d(amb_rooster, global_pos, 75.0, randf_range(0.95, 1.05))
		else:
			play_sfx(amb_rooster, randf_range(0.95, 1.05))

func play_ambient_trike_horn(global_pos: Vector3 = Vector3.ZERO) -> void:
	if amb_trike_horn:
		if global_pos != Vector3.ZERO:
			play_sfx_3d(amb_trike_horn, global_pos, 60.0, randf_range(0.95, 1.08))
		else:
			play_sfx(amb_trike_horn, randf_range(0.95, 1.08))

# --- Procedural Waveform Generators ---
func _create_pant_sound(duration: float, volume: float = 0.5) -> AudioStreamWAV:
	var sample_rate: int = 22050
	var num_samples: int = int(sample_rate * duration)
	var data := PackedByteArray()
	data.resize(num_samples)

	for i in range(num_samples):
		var t: float = float(i) / float(num_samples)
		var envelope: float = sin(t * PI)
		var noise: float = randf_range(-0.75, 0.75)
		var s: float = noise * envelope * volume
		data[i] = int(clampf((s + 1.0) * 127.5, 0.0, 255.0))

	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = sample_rate
	wav.data = data
	return wav
func _create_slide_sound(duration: float, volume: float = 0.5) -> AudioStreamWAV:
	var sample_rate: int = 22050
	var num_samples: int = int(sample_rate * duration)
	var data := PackedByteArray()
	data.resize(num_samples)

	var phase: float = 0.0
	for i in range(num_samples):
		var t: float = float(i) / float(num_samples)
		var freq: float = lerp(450.0, 180.0, t)
		phase += 2.0 * PI * freq / sample_rate
		var noise: float = randf_range(-0.55, 0.55)
		var envelope: float = sin(t * PI)
		var s: float = (noise * 0.7 + sin(phase) * 0.3) * envelope * volume
		data[i] = int(clamp((s + 1.0) * 127.5, 0.0, 255.0))

	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_8_BITS
	wav.mix_rate = sample_rate
	wav.data = data
	return wav
func _create_sweep_tone(start_freq: float, end_freq: float, duration: float, volume: float = 0.5) -> AudioStreamWAV:
	var sample_rate: int = 22050
	var num_samples: int = int(sample_rate * duration)
	var data := PackedByteArray()
	data.resize(num_samples)

	var phase: float = 0.0
	for i in range(num_samples):
		var t: float = float(i) / float(num_samples)
		var freq: float = lerp(start_freq, end_freq, t)
		phase += 2.0 * PI * freq / sample_rate
		var envelope: float = 1.0 - t
		var sample: float = sin(phase) * envelope * volume
		var byte_val: int = int(clamp((sample + 1.0) * 127.5, 0.0, 255.0))
		data[i] = byte_val

	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_8_BITS
	wav.mix_rate = sample_rate
	wav.data = data
	return wav

func _create_arpeggio(freqs: Array, note_duration: float, volume: float = 0.5) -> AudioStreamWAV:
	var sample_rate: int = 22050
	var samples_per_note: int = int(sample_rate * note_duration)
	var total_samples: int = samples_per_note * freqs.size()
	var data := PackedByteArray()
	data.resize(total_samples)

	var write_idx: int = 0
	for freq in freqs:
		var f: float = freq
		var phase: float = 0.0
		for i in range(samples_per_note):
			var t: float = float(i) / float(samples_per_note)
			phase += 2.0 * PI * f / sample_rate
			var envelope: float = (1.0 - t * 0.7) * (1.0 if t > 0.05 else t / 0.05)
			# Mix sine and slight triangle for warm retro chime
			var s: float = (sin(phase) * 0.7 + asin(sin(phase)) * (2.0 / PI) * 0.3) * envelope * volume
			data[write_idx] = int(clamp((s + 1.0) * 127.5, 0.0, 255.0))
			write_idx += 1

	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_8_BITS
	wav.mix_rate = sample_rate
	wav.data = data
	return wav

func _create_dual_thud(f1: float, f2: float, duration: float, volume: float = 0.5) -> AudioStreamWAV:
	var sample_rate: int = 22050
	var num_samples: int = int(sample_rate * duration)
	var data := PackedByteArray()
	data.resize(num_samples)

	var phase1: float = 0.0
	var phase2: float = 0.0
	for i in range(num_samples):
		var t: float = float(i) / float(num_samples)
		phase1 += 2.0 * PI * f1 / sample_rate
		phase2 += 2.0 * PI * f2 / sample_rate
		var envelope: float = (1.0 - t) * (1.0 - t)
		var s: float = (sin(phase1) * 0.6 + sin(phase2) * 0.4) * envelope * volume
		data[i] = int(clamp((s + 1.0) * 127.5, 0.0, 255.0))

	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_8_BITS
	wav.mix_rate = sample_rate
	wav.data = data
	return wav

func _create_noise_hit(duration: float, volume: float = 0.5) -> AudioStreamWAV:
	var sample_rate: int = 22050
	var num_samples: int = int(sample_rate * duration)
	var data := PackedByteArray()
	data.resize(num_samples)

	var phase: float = 0.0
	for i in range(num_samples):
		var t: float = float(i) / float(num_samples)
		var freq: float = lerp(350.0, 80.0, t)
		phase += 2.0 * PI * freq / sample_rate
		var noise: float = randf_range(-0.4, 0.4)
		var envelope: float = (1.0 - t) * (1.0 - t)
		var s: float = (sin(phase) * 0.6 + noise * 0.4) * envelope * volume
		data[i] = int(clamp((s + 1.0) * 127.5, 0.0, 255.0))

	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_8_BITS
	wav.mix_rate = sample_rate
	wav.data = data
	return wav

func _create_dog_bark(duration: float, volume: float = 0.5) -> AudioStreamWAV:
	var sample_rate: int = 22050
	var num_samples: int = int(sample_rate * duration)
	var data := PackedByteArray()
	data.resize(num_samples)

	var phase: float = 0.0
	for i in range(num_samples):
		var t: float = float(i) / float(num_samples)
		# Bark pitch envelope: quick rise then fall
		var f: float = 280.0 + sin(t * PI) * 180.0
		phase += 2.0 * PI * f / sample_rate
		var noise: float = randf_range(-0.25, 0.25)
		var envelope: float = sin(t * PI) * (1.0 - t * 0.3)
		var s: float = (sin(phase) * 0.75 + noise * 0.25) * envelope * volume
		data[i] = int(clamp((s + 1.0) * 127.5, 0.0, 255.0))

	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_8_BITS
	wav.mix_rate = sample_rate
	wav.data = data
	return wav

func _create_heartbeat(duration: float, volume: float = 0.5) -> AudioStreamWAV:
	var sample_rate: int = 22050
	var num_samples: int = int(sample_rate * duration)
	var data := PackedByteArray()
	data.resize(num_samples)

	var phase: float = 0.0
	for i in range(num_samples):
		var t: float = float(i) / float(num_samples)
		var f: float = 65.0 - t * 25.0
		phase += 2.0 * PI * f / sample_rate
		var envelope: float = (1.0 - t) * (1.0 - t)
		var s: float = sin(phase) * envelope * volume
		data[i] = int(clamp((s + 1.0) * 127.5, 0.0, 255.0))

	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_8_BITS
	wav.mix_rate = sample_rate
	wav.data = data
	return wav

func _create_clock_tick(duration: float, volume: float = 0.5) -> AudioStreamWAV:
	var sample_rate: int = 22050
	var num_samples: int = int(sample_rate * duration)
	var data := PackedByteArray()
	data.resize(num_samples)

	var phase: float = 0.0
	for i in range(num_samples):
		var t: float = float(i) / float(num_samples)
		var freq: float = 2400.0 - t * 1400.0
		phase += 2.0 * PI * freq / sample_rate
		var envelope: float = exp(-t * 28.0)
		var noise: float = randf_range(-0.35, 0.35) * exp(-t * 35.0)
		var s: float = (sin(phase) * 0.7 + noise * 0.3) * envelope * volume
		data[i] = int(clamp((s + 1.0) * 127.5, 0.0, 255.0))

	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_8_BITS
	wav.mix_rate = sample_rate
	wav.data = data
	return wav

func _create_explosion_boom(duration: float, volume: float = 0.5) -> AudioStreamWAV:
	var sample_rate: int = 22050
	var num_samples: int = int(sample_rate * duration)
	var data := PackedByteArray()
	data.resize(num_samples)

	var phase: float = 0.0
	for i in range(num_samples):
		var t: float = float(i) / float(num_samples)
		var freq: float = lerp(160.0, 28.0, t * t)
		phase += 2.0 * PI * freq / sample_rate
		var envelope: float = (1.0 - t) * (1.0 - t)
		var noise: float = randf_range(-0.55, 0.55) * (1.0 - t * 0.8)
		var s: float = (sin(phase) * 0.5 + noise * 0.5) * envelope * volume
		data[i] = int(clamp((s + 1.0) * 127.5, 0.0, 255.0))

	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_8_BITS
	wav.mix_rate = sample_rate
	wav.data = data
	return wav

func _create_whistle(duration: float, volume: float = 0.5) -> AudioStreamWAV:
	var sample_rate: int = 22050
	var num_samples: int = int(sample_rate * duration)
	var data := PackedByteArray()
	data.resize(num_samples)

	var phase: float = 0.0
	for i in range(num_samples):
		var t: float = float(i) / float(num_samples)
		# Fast trill/warble characteristic of a referee whistle
		var warble: float = sin(t * 110.0) * 220.0
		var freq: float = 2750.0 + warble
		phase += 2.0 * PI * freq / sample_rate
		# Two short bursts (peep-peep)
		var burst: float = 1.0
		if t > 0.42 and t < 0.55:
			burst = 0.1
		var envelope: float = sin(t * PI) * burst
		var s: float = sin(phase) * envelope * volume
		data[i] = int(clamp((s + 1.0) * 127.5, 0.0, 255.0))

	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_8_BITS
	wav.mix_rate = sample_rate
	wav.data = data
	return wav

func _create_slide_whistle(duration: float, volume: float = 0.5) -> AudioStreamWAV:
	var sample_rate: int = 22050
	var num_samples: int = int(sample_rate * duration)
	var data := PackedByteArray()
	data.resize(num_samples)

	var phase: float = 0.0
	for i in range(num_samples):
		var t: float = float(i) / float(num_samples)
		# Rising cartoon slide up then quick downward drop
		var freq: float = 400.0 + sin(t * PI * 0.7) * 900.0
		phase += 2.0 * PI * freq / sample_rate
		var envelope: float = (1.0 - t * 0.2) if t < 0.8 else (1.0 - t) * 5.0
		var s: float = sin(phase) * envelope * volume
		data[i] = int(clamp((s + 1.0) * 127.5, 0.0, 255.0))

	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_8_BITS
	wav.mix_rate = sample_rate
	wav.data = data
	return wav

func _create_gong_clang(duration: float, volume: float = 0.5) -> AudioStreamWAV:
	var sample_rate: int = 22050
	var num_samples: int = int(sample_rate * duration)
	var data := PackedByteArray()
	data.resize(num_samples)

	var phase1: float = 0.0
	var phase2: float = 0.0
	var phase3: float = 0.0
	for i in range(num_samples):
		var t: float = float(i) / float(num_samples)
		phase1 += 2.0 * PI * 180.0 / sample_rate
		phase2 += 2.0 * PI * 290.0 / sample_rate
		phase3 += 2.0 * PI * 510.0 / sample_rate
		var envelope: float = exp(-t * 8.0)
		var noise: float = randf_range(-0.3, 0.3) * exp(-t * 25.0)
		var s: float = (sin(phase1) * 0.4 + sin(phase2) * 0.3 + sin(phase3) * 0.2 + noise * 0.1) * envelope * volume
		data[i] = int(clamp((s + 1.0) * 127.5, 0.0, 255.0))

	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_8_BITS
	wav.mix_rate = sample_rate
	wav.data = data
	return wav

func _create_street_ambience_loop(duration: float, volume: float = 0.14) -> AudioStreamWAV:
	var sample_rate: int = 11025
	var num_samples: int = int(sample_rate * duration)
	var data := PackedByteArray()
	data.resize(num_samples)

	var bird_phase: float = 0.0
	var trike_phase: float = 0.0
	for i in range(num_samples):
		var t: float = float(i) / float(num_samples)
		# Gentle tropical afternoon breeze
		var breeze: float = randf_range(-0.18, 0.18) * (0.6 + 0.4 * sin(t * TAU * 2.0))
		# Distant maya bird chirps at two intervals in the loop
		var bird: float = 0.0
		if (t > 0.18 and t < 0.23) or (t > 0.64 and t < 0.68):
			var local_t: float = fmod(t * 20.0, 1.0)
			var b_freq: float = 2400.0 + sin(local_t * TAU * 3.0) * 450.0
			bird_phase += TAU * b_freq / sample_rate
			bird = sin(bird_phase) * sin(local_t * PI) * 0.35
		# Subtle distant tricycle put-put hum
		trike_phase += TAU * 42.0 / sample_rate
		var trike: float = sin(trike_phase) * (0.5 + 0.5 * sin(t * TAU * 14.0)) * 0.14
		var s: float = (breeze + bird + trike) * volume
		data[i] = int(clampf((s + 1.0) * 127.5, 0.0, 255.0))

	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_8_BITS
	wav.mix_rate = sample_rate
	wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
	wav.loop_begin = 0
	wav.loop_end = num_samples
	wav.data = data
	return wav

func _create_music_loop(freqs: Array, note_duration: float, volume: float = 0.18) -> AudioStreamWAV:
	var sample_rate: int = 11025
	var samples_per_note: int = max(1, int(sample_rate * note_duration))
	var total_samples: int = samples_per_note * freqs.size()
	var data := PackedByteArray()
	data.resize(total_samples)

	var write_idx: int = 0
	for note_idx in range(freqs.size()):
		var f: float = float(freqs[note_idx])
		var bass_f: float = f * 0.5
		var phase: float = 0.0
		var bass_phase: float = 0.0
		for i in range(samples_per_note):
			var t: float = float(i) / float(samples_per_note)
			phase += TAU * f / sample_rate
			bass_phase += TAU * bass_f / sample_rate
			# Plucky acoustic/marimba envelope + warm bass + light shaker on off-beats
			var pluck_env: float = exp(-t * 4.5) * minf(1.0, t * 25.0)
			var bass_env: float = (1.0 - t * 0.65)
			var shaker: float = randf_range(-0.15, 0.15) * exp(-t * 14.0) if (note_idx % 2 == 1) else 0.0
			var lead: float = (sin(phase) * 0.65 + asin(sin(phase)) * (2.0 / PI) * 0.35) * pluck_env
			var bass: float = sin(bass_phase) * 0.45 * bass_env
			var s: float = (lead + bass + shaker) * volume
			data[write_idx] = int(clampf((s + 1.0) * 127.5, 0.0, 255.0))
			write_idx += 1

	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_8_BITS
	wav.mix_rate = sample_rate
	wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
	wav.loop_begin = 0
	wav.loop_end = total_samples
	wav.data = data
	return wav
