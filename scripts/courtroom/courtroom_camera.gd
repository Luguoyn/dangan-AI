extends Camera3D
class_name CourtroomCamera
# ============================================================
# Step 25: 学级裁判摄像机系统
# ============================================================

@export var default_position := Vector3(0, 8, 12)
@export var default_look_at := Vector3(0, 1.5, 0)
@export var closeup_offset := Vector3(0, 1.8, -4.0)
@export var medium_offset := Vector3(0, 2.5, -7.0)
@export var wide_offset := Vector3(0, 5.0, -12.0)
@export var overview_position := Vector3(0, 14, 0)
@export var overview_rotation := Vector3(-90, 0, 0) as Vector3

var _is_animating: bool = false
var _target_node: Node3D

func _ready() -> void:
	position = default_position
	look_at(default_look_at)

func move_to_podium(podium_index: int, shot_type: String = "closeup") -> void:
	var target_pos: Vector3
	var offset: Vector3

	match shot_type:
		"closeup":  offset = closeup_offset
		"medium":   offset = medium_offset
		"wide":     offset = wide_offset
		_:          offset = closeup_offset

	var podium_node := _find_podium(podium_index)
	if podium_node:
		target_pos = podium_node.global_position + offset
	else:
		target_pos = _calculate_podium_position(podium_index) + offset

	_animate_to(target_pos, target_pos - offset)

func move_to_center() -> void:
	_animate_to(overview_position, Vector3(0, 1.5, 0))

func move_to_overview() -> void:
	position = overview_position
	rotation_degrees = overview_rotation

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
	var from_pos := _calculate_podium_position(from_podium)
	var to_pos := _calculate_podium_position(to_podium)
	var mid := (from_pos + to_pos) / 2.0 + Vector3(0, 3, 6)
	var tween := create_tween()
	tween.tween_property(self, "position", mid, duration * 0.5)
	tween.tween_property(self, "position", to_pos + Vector3(0, 2, -5), duration * 0.5)
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

func _find_podium(podium_index: int) -> Node3D:
	var parent := get_parent()
	if parent:
		for child in parent.get_children():
			if child is PodiumSlot and child.podium_index == podium_index:
				return child
	return null

func _calculate_podium_position(podium_index: int) -> Vector3:
	var angle := TAU * float(podium_index) / 16.0
	var radius := 6.0
	return Vector3(cos(angle) * radius, 0, sin(angle) * radius)
