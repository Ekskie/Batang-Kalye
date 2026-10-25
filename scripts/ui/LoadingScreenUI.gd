class_name LoadingScreenUI
extends Control

signal loading_completed

@export var frame_fps: float = 24.0
@export var min_display_seconds: float = 0.0

@onready var runner_rect: TextureRect = %RunnerRect
@onready var progress_bar: ProgressBar = %ProgressBar
@onready var tip_label: Label = %TipLabel
@onready var title_label: Label = %TitleLabel

var _frames: Array[Texture2D] = []
var _current_frame: int = 0
var _frame_timer: float = 0.0
var _elapsed_time: float = 0.0
var _is_active: bool = false
var _target_progress: float = 0.0
var _current_progress: float = 0.0
var _finish_pending: bool = false

const STREET_TIPS: Array[String] = [
	"TIP: Mag-slide sa ilalim ng mga sampayan at mesa upang makaiwas sa Taya!",
	"TIP: Mag-ipon ng Barya sa kalye upang makabili ng pampabilis sa Tindahan ni Chris!",
	"TIP: Pindutin ang Karipas (Dash) para makalusot kapag cornered na ng kalaban!",
	"TIP: Pulutin ang mga balat ng saging at lata sa kalye upang ibato sa humahabol!",
	"TIP: Kapag hingal na ang iyong karakter, maglakad muna upang muling makahinga!",
	"TIP: Pindutin ang Taympers kung nais i-pause ang laro o baguhin ang mga setting!"
]

func _ready() -> void:
	_load_runner_frames()
	visible = false
	modulate = Color(1, 1, 1, 0)
	if tip_label:
		tip_label.text = STREET_TIPS.pick_random()

func _load_runner_frames() -> void:
	_frames.clear()
	for i in range(1, 29):
		var num_str := "%04d" % i
		var path := "res://assets/Backgrounds/Renders_Menu_Backgrounds/Running PNGs/%s.png" % num_str
		if ResourceLoader.exists(path):
			var tex: Texture2D = load(path)
			if tex:
				_frames.append(tex)
	if not _frames.is_empty() and runner_rect:
		runner_rect.texture = _frames[0]

func _process(delta: float) -> void:
	if not _is_active:
		return

	_elapsed_time += delta

	# Animate running boy
	if not _frames.is_empty() and runner_rect:
		_frame_timer += delta
		var frame_interval := 1.0 / maxf(frame_fps, 1.0)
		if _frame_timer >= frame_interval:
			_frame_timer = fmod(_frame_timer, frame_interval)
			_current_frame = (_current_frame + 1) % _frames.size()
			runner_rect.texture = _frames[_current_frame]

	# Smooth progress bar interpolation
	_current_progress = move_toward(_current_progress, _target_progress, delta * 3.5)
	if progress_bar:
		progress_bar.value = _current_progress * 100.0

	# Check if finish was requested and minimum time elapsed
	if _finish_pending and _elapsed_time >= min_display_seconds:
		_finish_pending = false
		_target_progress = 1.0
		_do_fade_out()

func show_loading(task_title: String = "Teka lang...") -> void:
	_is_active = true
	_finish_pending = false
	_elapsed_time = 0.0
	_current_progress = 0.0
	_target_progress = 0.15
	if progress_bar:
		progress_bar.value = 0.0
	if tip_label:
		tip_label.text = STREET_TIPS.pick_random()
	if title_label:
		title_label.text = task_title

	visible = true
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 1.0, 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func set_progress(val_01: float) -> void:
	_target_progress = clampf(val_01, 0.0, 1.0)

func finish_loading() -> void:
	_finish_pending = true
	_target_progress = 1.0
	if _elapsed_time >= min_display_seconds:
		_finish_pending = false
		_do_fade_out()

func _do_fade_out() -> void:
	if progress_bar:
		progress_bar.value = 100.0
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 0.0, 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_callback(func():
		_is_active = false
		visible = false
		loading_completed.emit()
	)
