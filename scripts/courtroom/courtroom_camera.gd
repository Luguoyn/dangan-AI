extends Camera3D
class_name CourtroomCamera
# ============================================================
# 学级裁判摄像机系统 — 预设运镜
# ============================================================

@export var default_position := Vector3(0, 8, 12)
@export var overview_position := Vector3(0, 14, 0)

enum TransitionStyle { CUT, ROTATE, SWEEP, ZOOM_PUNCH }
enum LockStyle { STEADY, DRIFT, BREATHE, DOLLY }

var _is_animating: bool = false
var _last_podium: int = -1
var _idle_time: float = 0.0
var _target_height: float = 1.8
var _current_angle: float = 0.0
var _current_dist: float = 3.0
var _transition_style: TransitionStyle = TransitionStyle.ROTATE
var _lock_style: LockStyle = LockStyle.DRIFT

# 动画临时状态
var _tween_from_angle: float = 0.0
var _tween_to_angle: float = 0.0
var _tween_from_dist: float = 3.0
var _tween_to_dist: float = 3.0
var _tween_from_height: float = 1.8
var _tween_to_height: float = 1.8

func _ready() -> void:
	position = default_position
	look_at(Vector3(0, 1.5, 0))

func set_transition_style(style_name: String) -> void:
	match style_name:
		"cut": _transition_style = TransitionStyle.CUT
		"rotate": _transition_style = TransitionStyle.ROTATE
		"sweep": _transition_style = TransitionStyle.SWEEP
		"zoom": _transition_style = TransitionStyle.ZOOM_PUNCH

func set_lock_style(style_name: String) -> void:
	match style_name:
		"steady": _lock_style = LockStyle.STEADY
		"drift": _lock_style = LockStyle.DRIFT
		"breathe": _lock_style = LockStyle.BREATHE
		"dolly": _lock_style = LockStyle.DOLLY

func move_to_podium(podium_index: int, shot_type: String = "closeup") -> void:
	var angle := TAU * float(podium_index) / 16.0
	var dist: float = 3.0
	var height: float = 1.8
	match shot_type: "closeup": dist = 3.0; height = 1.8; "medium": dist = 5.0; height = 2.5; "wide": dist = 8.0; height = 4.0

	if _last_podium >= 0 and _last_podium != podium_index:
		match _transition_style:
			TransitionStyle.CUT:
				position = _angle_to_pos(angle, dist, height)
				look_at(_look_at_podium(angle))
			TransitionStyle.ROTATE:
				_start_tween(_current_angle, angle, _current_dist, dist, _target_height, height, 0.6, false)
			TransitionStyle.SWEEP:
				_start_tween(_current_angle, angle, 8.0, dist, 4.0, height, 0.8, true)
			TransitionStyle.ZOOM_PUNCH:
				position = _angle_to_pos(angle, 10.0, 5.0)
				look_at(_look_at_podium(angle))
				_start_tween(angle, angle, 10.0, dist, 5.0, height, 0.35, false)
	else:
		_animate_to(_angle_to_pos(angle, dist, height), _look_at_podium(angle), 0.5)

	_current_angle = angle
	_current_dist = dist
	_target_height = height
	_last_podium = podium_index
	_idle_time = 0.0

func _start_tween(fa: float, ta: float, fd: float, td: float, fh: float, th: float, dur: float, _sweep_in: bool) -> void:
	_is_animating = true
	_tween_from_angle = fa
	_tween_to_angle = ta
	_tween_from_dist = fd
	_tween_to_dist = td
	_tween_from_height = fh
	_tween_to_height = th
	var tween := create_tween()
	tween.tween_method(_tween_step, 0.0, 1.0, dur).set_ease(Tween.EASE_IN_OUT)
	tween.chain().tween_callback(_on_anim_done)

func _tween_step(t: float) -> void:
	var a := lerp_angle(_tween_from_angle, _tween_to_angle, t)
	var d := lerpf(_tween_from_dist, _tween_to_dist, t)
	var h := lerpf(_tween_from_height, _tween_to_height, t)
	position = _angle_to_pos(a, d, h)
	look_at(_look_at_podium(a))

func _process(delta: float) -> void:
	if _is_animating or _last_podium < 0:
		return
	_idle_time += delta
	var base := _angle_to_pos(_current_angle, _current_dist, _target_height)
	match _lock_style:
		LockStyle.STEADY:
			pass
		LockStyle.DRIFT:
			position = base + Vector3(sin(_idle_time * 1.3) * 0.12, sin(_idle_time * 0.7 + 1) * 0.08, cos(_idle_time * 1.1) * 0.10)
		LockStyle.BREATHE:
			var z := 1.0 + sin(_idle_time * 0.6) * 0.08
			position = _angle_to_pos(_current_angle, _current_dist * z, _target_height)
		LockStyle.DOLLY:
			var s := sin(_idle_time * 0.5) * 0.25
			position = base + Vector3(cos(_current_angle) * s, 0, sin(_current_angle) * s)
	look_at(_look_at_podium(_current_angle))

func move_to_center() -> void:
	_animate_to(overview_position, Vector3(0, 1.5, 0), 0.5)
	_last_podium = -1

func move_to_overview() -> void:
	position = overview_position
	rotation_degrees = Vector3(-90, 0, 0)
	_last_podium = -1

func shake(intensity: float, duration: float) -> void:
	var orig := position
	var e := 0.0
	while e < duration and is_instance_valid(self):
		position = orig + Vector3(randf_range(-intensity,intensity),randf_range(-intensity,intensity),randf_range(-intensity,intensity))
		await get_tree().process_frame
		e += get_process_delta_time()
	position = orig

func _animate_to(target_pos: Vector3, look_target: Vector3, duration: float) -> void:
	_is_animating = true
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "position", target_pos, duration).set_ease(Tween.EASE_IN_OUT)
	tween.tween_method(_look_at_target.bind(look_target), 0.0, 1.0, duration)
	tween.chain().tween_callback(_on_anim_done)

func _on_anim_done() -> void: _is_animating = false
func _look_at_target(_t: float, target: Vector3) -> void: look_at(target)
func _look_at_podium(angle: float) -> Vector3: return Vector3(cos(angle) * 6.0, 1.5, sin(angle) * 6.0)
func _angle_to_pos(angle: float, dist: float, height: float) -> Vector3:
	var px := cos(angle) * 6.0; var pz := sin(angle) * 6.0
	var d := Vector3(-px, 0, -pz).normalized()
	return Vector3(px, 0, pz) + d * dist + Vector3.UP * height
