extends Node

# Procedural Sound Synthesizer for Batang Kalye
# Generates audio waveform buffers at runtime for retro/playful Filipino kalye sound effects!

var audio_players: Array[AudioStreamPlayer] = []
const POOL_SIZE: int = 8
var current_player_idx: int = 0

# Cached synthesized audio streams
var sfx_pickup: AudioStreamWAV
var sfx_bin_correct: AudioStreamWAV
var sfx_bin_wrong: AudioStreamWAV
var sfx_powerup: AudioStreamWAV
var sfx_tag_hit: AudioStreamWAV
var sfx_drop: AudioStreamWAV
var sfx_dog_bark: AudioStreamWAV
var sfx_stun: AudioStreamWAV
var sfx_danger: AudioStreamWAV
var sfx_tick: AudioStreamWAV
var sfx_elimination: AudioStreamWAV
var sfx_whistle: AudioStreamWAV
var sfx_jump: AudioStreamWAV
var sfx_land: AudioStreamWAV
var sfx_slide: AudioStreamWAV
var sfx_dash: AudioStreamWAV
var sfx_step_asphalt: AudioStreamWAV
var sfx_step_water: AudioStreamWAV
var sfx_tag_boom: AudioStreamWAV
var sfx_score_ding: AudioStreamWAV
var sfx_pant: AudioStreamWAV
var sfx_recover_breath: AudioStreamWAV
var sfx_tsinelas_throw: AudioStreamWAV
var sfx_tsinelas_slap: AudioStreamWAV
var sfx_banana_slip: AudioStreamWAV
var sfx_drum_hide: AudioStreamWAV
var sfx_drum_clang: AudioStreamWAV
var sfx_chalk_puff: AudioStreamWAV
var sfx_ice_candy: AudioStreamWAV

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	# Create pool of players
	for i in range(POOL_SIZE):
		var p := AudioStreamPlayer.new()
		p.bus = "Master"
		add_child(p)
		audio_players.append(p)

	_synthesize_all_sfx()

func _synthesize_all_sfx() -> void:
	sfx_pickup = _create_sweep_tone(700.0, 1400.0, 0.12, 0.6)
	sfx_bin_correct = _create_arpeggio([523.25, 659.25, 783.99, 1046.5], 0.08, 0.7) # C5, E5, G5, C6
	sfx_bin_wrong = _create_dual_thud(160.0, 110.0, 0.18, 0.5)
	sfx_powerup = _create_arpeggio([440.0, 554.37, 659.25, 880.0, 1108.73, 1318.5], 0.06, 0.8) # Stardust fanfare
	sfx_tag_hit = _create_noise_hit(0.15, 0.8)
	sfx_drop = _create_sweep_tone(400.0, 180.0, 0.10, 0.4)
	sfx_dog_bark = _create_dog_bark(0.22, 0.7)
	sfx_stun = _create_sweep_tone(600.0, 250.0, 0.35, 0.6)
	sfx_danger = _create_heartbeat(0.25, 0.6)
	sfx_tick = _create_clock_tick(0.04, 0.7)
	sfx_elimination = _create_explosion_boom(0.65, 0.85)
	sfx_whistle = _create_whistle(0.35, 0.65)
	sfx_jump = _create_sweep_tone(220.0, 520.0, 0.12, 0.5)
	sfx_land = _create_noise_hit(0.14, 0.6)
	sfx_slide = _create_slide_sound(0.25, 0.45)
	sfx_dash = _create_sweep_tone(950.0, 240.0, 0.16, 0.7)
	sfx_step_asphalt = _create_sweep_tone(200.0, 100.0, 0.04, 0.25)
	sfx_step_water = _create_noise_hit(0.08, 0.35)
	sfx_tag_boom = _create_explosion_boom(0.45, 0.9)
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

func play_sfx(stream: AudioStreamWAV, pitch_scale: float = 1.0) -> void:
	if not stream or audio_players.is_empty():
		return
	var player: AudioStreamPlayer = audio_players[current_player_idx]
	current_player_idx = (current_player_idx + 1) % POOL_SIZE
	player.stream = stream
	player.pitch_scale = pitch_scale + randf_range(-0.05, 0.05)
	player.play()

func play_pickup() -> void:
	play_sfx(sfx_pickup, randf_range(0.95, 1.1))

func play_bin_correct() -> void:
	play_sfx(sfx_bin_correct, 1.0)

func play_bin_wrong() -> void:
	play_sfx(sfx_bin_wrong, 1.0)

func play_powerup() -> void:
	play_sfx(sfx_powerup, 1.0)

func play_tag_hit() -> void:
	play_sfx(sfx_tag_hit, randf_range(0.9, 1.1))

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
	play_sfx(sfx_jump, randf_range(0.95, 1.1))

func play_land(speed: float = 5.0) -> void:
	var pitch: float = clampf(1.2 - (speed / 30.0), 0.7, 1.2)
	play_sfx(sfx_land, pitch)

func play_slide() -> void:
	play_sfx(sfx_slide, randf_range(0.95, 1.05))

func play_dash() -> void:
	play_sfx(sfx_dash, randf_range(0.98, 1.12))

func play_footstep(in_water: bool = false) -> void:
	if in_water:
		play_sfx(sfx_step_water, randf_range(0.85, 1.2))
	else:
		play_sfx(sfx_step_asphalt, randf_range(0.85, 1.2))

func play_tag_boom() -> void:
	play_sfx(sfx_tag_boom, 1.0)

func play_score_ding() -> void:
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
	wav.format = AudioStreamWAV.FORMAT_8_BITS
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
