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

# --- Procedural Waveform Generators ---
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
