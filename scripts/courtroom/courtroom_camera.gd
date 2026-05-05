extends Camera3D
class_name CourtroomCamera
# ============================================================
# Step 25: 学级裁判摄像机系统
# ============================================================

@export var default_position := Vector3(0, 8, 12)
@export var default_look_at := Vector3(0, 1.5, 0)
@export var overview_position := Vector3(0, 14, 0)

var _is_animating: bool = false

func _ready() -> void:
	position = default_position
	look_at(default_look_at)

func move_to_podium(podium_index: int, shot_type: String = "closeup") -> void:
	var podium_pos := _get_podium_pos(podium_index)
	var to_center := (Vector3.ZERO - podium_pos).normalized()
	var dist: float
	var height: float

	match shot_type:
		"closeup":  dist = 3.0; height = 1.8
		"medium":   dist = 5.0; height = 2.5
		"wide":     dist = 8.0; height = 4.0
		_:          dist = 3.0; height = 1.8

	var cam_pos := podium_pos + to_center * dist + Vector3.UP * height
	var look_pos := podium_pos + Vector3.UP * 1.5
	_animate_to(cam_pos, look_pos)

func move_to_center() -> void:
	_animate_to(overview_position, Vector3(0, 1.5, 0))

func move_to_overview() -> void:
	position = overview_position
	rotation_degrees = Vector3(-90, 0, 0)

func shake(intensity: float, duration: float) -> void:
	var original := position
	var elapsed := 0.0
	while elapsed < duration and is_instance_valid(self):
		var offset := Vector3(
			randf_range(-intensity, intensity),
			randf_range(-intensity, intensity),
			randf_range(-intensity, intensity)
		)
		position = original + offset
		await get_tree().process_frame
		elapsed += get_process_delta_time()
	position = original

func pan(from_podium: int, to_podium: int, duration: float = 1.0) -> void:
	var from_pos := _get_podium_pos(from_podium)
	var to_pos := _get_podium_pos(to_podium)
	var mid := (from_pos + to_pos) / 2.0 + Vector3.UP * 5.0
	var tween := create_tween()
	tween.tween_property(self, "position", mid, duration * 0.5)
	var end_pos := to_pos + (Vector3.ZERO - to_pos).normalized() * 4.0 + Vector3.UP * 3.0
	tween.tween_property(self, "position", end_pos, duration * 0.5)
	tween.parallel().tween_method(_look_at_target.bind(to_pos), 0.0, 1.0, duration)

func _animate_to(target_pos: Vector3, look_target: Vector3) -> void:
	_is_animating = true
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "position", target_pos, 0.8).set_ease(Tween.EASE_IN_OUT)
	tween.tween_method(_look_at_target.bind(look_target), 0.0, 1.0, 0.8)
	tween.chain().tween_callback(func(): _is_animating = false)

func _look_at_target(_t: float, target: Vector3) -> void:
	look_at(target)

func _get_podium_pos(podium_index: int) -> Vector3:
	var parent := get_parent()
	if parent:
		for child in parent.get_children():
			if child is PodiumSlot and child.podium_index == podium_index:
				return child.global_position
	var angle := TAU * float(podium_index) / 16.0
	return Vector3(cos(angle) * 6.0, 0, sin(angle) * 6.0)
