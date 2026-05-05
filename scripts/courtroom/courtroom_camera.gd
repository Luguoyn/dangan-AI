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
var _current_shot: String = "closeup"
var _transition_style: TransitionStyle = TransitionStyle.ROTATE
var _lock_style: LockStyle = LockStyle.DRIFT

func _ready() -> void:
	position = default_position
	look_at(Vector3(0, 1.5, 0))

func set_transition_style(style_name: String) -> void:
	match style_name:
		"cut":   _transition_style = TransitionStyle.CUT
		"rotate": _transition_style = TransitionStyle.ROTATE
		"sweep":  _transition_style = TransitionStyle.SWEEP
		"zoom":   _transition_style = TransitionStyle.ZOOM_PUNCH

func set_lock_style(style_name: String) -> void:
	match style_name:
		"steady":  _lock_style = LockStyle.STEADY
		"drift":   _lock_style = LockStyle.DRIFT
		"breathe": _lock_style = LockStyle.BREATHE
		"dolly":   _lock_style = LockStyle.DOLLY

func move_to_podium(podium_index: int, shot_type: String = "closeup") -> void:
	var angle := TAU * float(podium_index) / 16.0
	var dist: float = _shot_dist(shot_type)
	var height: float = _shot_height(shot_type)
	_current_shot = shot_type

	var target_angle := angle

	if _last_podium >= 0 and _last_podium != podium_index:
		match _transition_style:
			TransitionStyle.CUT:
				var pos := _angle_to_pos(target_angle, dist, height)
				position = pos
				look_at(_look_at_podium(target_angle))
			TransitionStyle.ROTATE:
				_rotate_around_center(_current_angle, target_angle, _current_dist, dist, _target_height, height)
			TransitionStyle.SWEEP:
				_sweep_around(_current_angle, target_angle, dist, height)
			TransitionStyle.ZOOM_PUNCH:
				_zoom_punch(target_angle, dist, height)
	else:
		var pos := _angle_to_pos(target_angle, dist, height)
		_animate_to(pos, _look_at_podium(target_angle), 0.5)

	_current_angle = target_angle
	_current_dist = dist
	_target_height = height
	_last_podium = podium_index
	_idle_time = 0.0

func _shot_dist(shot: String) -> float:
	match shot: "closeup": return 3.0; "medium": return 5.0; "wide": return 8.0; _: return 3.0

func _shot_height(shot: String) -> float:
	match shot: "closeup": return 1.8; "medium": return 2.5; "wide": return 4.0; _: return 1.8

# --- 运镜预设 ---

func _rotate_around_center(from_a: float, to_a: float, from_d: float, to_d: float, from_h: float, to_h: float) -> void:
	_is_animating = true
	var dur := 0.6
	var _ra := from_a; var _rb := to_a; var _rd1 := from_d; var _rd2 := to_d; var _rh1 := from_h; var _rh2 := to_h
	var tween := create_tween()
	tween.tween_method(_rot_step.bind(_ra, _rb, _rd1, _rd2, _rh1, _rh2), 0.0, 1.0, dur).set_ease(Tween.EASE_IN_OUT)
	tween.chain().tween_callback(_on_anim_done)

func _rot_step(t: float, a1: float, a2: float, d1: float, d2: float, h1: float, h2: float) -> void:
	var a := lerp_angle(a1, a2, t)
	var d := lerpf(d1, d2, t)
	var h := lerpf(h1, h2, t)
	position = _angle_to_pos(a, d, h)
	look_at(_look_at_podium(a))

func _zoom_punch(to_a: float, to_d: float, to_h: float) -> void:
	_is_animating = true
	var pos := _angle_to_pos(to_a, to_d, to_h)
	# 先退远再快速推近
	position = _angle_to_pos(to_a, 10.0, 5.0)
	look_at(_look_at_podium(to_a))
	var tween := create_tween()
	tween.tween_property(self, "position", pos, 0.35).set_ease(Tween.EASE_IN)
	tween.tween_method(_look_at_target.bind(_look_at_podium(to_a)), 0.0, 1.0, 0.35)
	tween.chain().tween_callback(_on_anim_done)

func _cam_at(t: float, from_a: float, to_a: float, from_d: float, to_d: float, from_h: float, to_h: float) -> void:
	var a := lerp_angle(from_a, to_a, t)
	var d := lerpf(from_d, to_d, t)
	var h := lerpf(from_h, to_h, t)
	position = _angle_to_pos(a, d, h)
	look_at(_look_at_podium(a))

# --- 锁定后运镜 ---

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
			var zoom := 1.0 + sin(_idle_time * 0.6) * 0.08
			position = _angle_to_pos(_current_angle, _current_dist * zoom, _target_height)
		LockStyle.DOLLY:
			var slide := sin(_idle_time * 0.5) * 0.25
			position = base + Vector3(cos(_current_angle) * slide, 0, sin(_current_angle) * slide)
	look_at(_look_at_podium(_current_angle))

# --- 辅助 ---

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
		position = orig + Vector3(randf_range(-intensity, intensity), randf_range(-intensity, intensity), randf_range(-intensity, intensity))
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
