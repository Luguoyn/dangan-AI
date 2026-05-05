extends Camera3D
class_name CourtroomCamera
# ============================================================
# Step 25: 学级裁判摄像机系统
# ============================================================

@export var default_position := Vector3(0, 8, 12)
@export var overview_position := Vector3(0, 14, 0)

var _is_animating: bool = false
var _last_podium: int = -1
var _idle_time: float = 0.0
var _target_angle: float = 0.0
var _target_dist: float = 3.0
var _target_height: float = 1.8
var _current_angle: float = 0.0
var _current_dist: float = 3.0

func _ready() -> void:
	position = default_position
	look_at(Vector3(0, 1.5, 0))

func move_to_podium(podium_index: int, shot_type: String = "closeup") -> void:
	var angle := TAU * float(podium_index) / 16.0
	var dist: float
	var height: float

	match shot_type:
		"closeup":  dist = 3.0; height = 1.8
		"medium":   dist = 5.0; height = 2.5
		"wide":     dist = 8.0; height = 4.0
		_:          dist = 3.0; height = 1.8

	var target_angle := angle
	var target_dist := dist
	var target_height := height

	if _last_podium >= 0 and _last_podium != podium_index:
		_rotate_around_center(_current_angle, target_angle, _current_dist, target_dist, target_height)
	else:
		var pos := _angle_to_pos(target_angle, target_dist, target_height)
		_animate_to(pos, _look_at_podium(target_angle), 0.5)

	_current_angle = target_angle
	_current_dist = target_dist
	_target_height = target_height
	_last_podium = podium_index
	_idle_time = 0.0

func _rotate_around_center(from_angle: float, to_angle: float, from_dist: float, to_dist: float, to_height: float) -> void:
	_is_animating = true
	var duration := 0.6
	var tween := create_tween()

	# 绕中心旋转：只改变角度，dist和height在旋转中渐变
	tween.tween_method(
		func(t: float):
			var a := lerp_angle(from_angle, to_angle, t)
			var d := lerpf(from_dist, to_dist, t)
			var h := lerpf(_target_height, to_height, t)
			position = _angle_to_pos(a, d, h)
			look_at(_look_at_podium(a))
		,
		0.0, 1.0, duration
	).set_ease(Tween.EASE_IN_OUT)
	tween.chain().tween_callback(func(): _is_animating = false)

func move_to_center() -> void:
	_animate_to(overview_position, Vector3(0, 1.5, 0), 0.5)
	_last_podium = -1

func move_to_overview() -> void:
	position = overview_position
	rotation_degrees = Vector3(-90, 0, 0)
	_last_podium = -1

func shake(intensity: float, duration: float) -> void:
	var original := position
	var elapsed := 0.0
	while elapsed < duration and is_instance_valid(self):
		position = original + Vector3(
			randf_range(-intensity, intensity),
			randf_range(-intensity, intensity),
			randf_range(-intensity, intensity)
		)
		await get_tree().process_frame
		elapsed += get_process_delta_time()
	position = original

func _animate_to(target_pos: Vector3, look_target: Vector3, duration: float = 0.8) -> void:
	_is_animating = true
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "position", target_pos, duration).set_ease(Tween.EASE_IN_OUT)
	tween.tween_method(_look_at_target.bind(look_target), 0.0, 1.0, duration)
	tween.chain().tween_callback(func(): _is_animating = false)

func _look_at_target(_t: float, target: Vector3) -> void:
	look_at(target)

func _angle_to_pos(angle: float, dist: float, height: float) -> Vector3:
	var podium_x := cos(angle) * 6.0
	var podium_z := sin(angle) * 6.0
	var to_center := Vector3(-podium_x, 0, -podium_z).normalized()
	return Vector3(podium_x, 0, podium_z) + to_center * dist + Vector3.UP * height

func _look_at_podium(angle: float) -> Vector3:
	return Vector3(cos(angle) * 6.0, 1.5, sin(angle) * 6.0)

func _process(delta: float) -> void:
	if _is_animating:
		return
	if _last_podium < 0:
		return
	_idle_time += delta
	var drift := Vector3(
		sin(_idle_time * 1.3) * 0.12,
		sin(_idle_time * 0.7 + 1.0) * 0.08,
		cos(_idle_time * 1.1) * 0.10
	)
	position = _angle_to_pos(_current_angle, _current_dist, _target_height) + drift
	look_at(_look_at_podium(_current_angle))
