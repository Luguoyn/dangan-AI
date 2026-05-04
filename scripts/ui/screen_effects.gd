extends CanvasLayer
class_name ScreenEffects
# ============================================================
# Step 20: 屏幕特效系统
# shake / flash / vignette / blood / noise
# ============================================================

var _flash_rect: ColorRect
var _vignette_rect: ColorRect
var _blood_rect: ColorRect
var _noise_rect: ColorRect
var _original_camera_pos: Vector2
var _camera_ref: Camera2D

func _ready() -> void:
	EventBus.screen_effect_requested.connect(_on_effect_requested)
	_build_effects()

func _build_effects() -> void:
	_flash_rect = ColorRect.new()
	_flash_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_flash_rect.color = Color(1, 1, 1, 0)
	_flash_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_flash_rect)

	_vignette_rect = ColorRect.new()
	_vignette_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_vignette_rect.color = Color(0, 0, 0, 0)
	_vignette_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_vignette_rect)

	_blood_rect = ColorRect.new()
	_blood_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_blood_rect.color = Color(0.6, 0, 0, 0)
	_blood_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_blood_rect)

	_noise_rect = ColorRect.new()
	_noise_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_noise_rect.color = Color(1, 1, 1, 0)
	_noise_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_noise_rect)

func _on_effect_requested(effect: String, intensity: float, duration: float) -> void:
	match effect:
		"shake":
			_do_shake(intensity, duration)
		"flash":
			_do_flash(Color(1, 1, 1, intensity), duration)
		"red_flash":
			_do_flash(Color(1, 0, 0, intensity), duration)
		"vignette":
			_do_vignette(intensity, duration)
		"blood":
			_do_blood(intensity, duration)
		"noise":
			_do_noise(intensity, duration)

func _do_shake(intensity: float, duration: float) -> void:
	var cam := _get_camera()
	if cam == null:
		return
	var original := cam.position
	var elapsed := 0.0
	while elapsed < duration:
		var offset := Vector2(randf_range(-intensity * 10, intensity * 10), randf_range(-intensity * 10, intensity * 10))
		cam.position = original + offset
		await get_tree().process_frame
		elapsed += get_process_delta_time()
	cam.position = original

func _do_flash(color: Color, duration: float) -> void:
	_flash_rect.color = color
	var tween := create_tween()
	tween.tween_property(_flash_rect, "color", Color(color.r, color.g, color.b, 0), duration)

func _do_vignette(intensity: float, duration: float) -> void:
	_vignette_rect.color = Color(0, 0, 0, intensity * 0.7)
	var tween := create_tween()
	tween.tween_property(_vignette_rect, "color", Color(0, 0, 0, 0), duration)

func _do_blood(intensity: float, duration: float) -> void:
	_blood_rect.color = Color(0.6, 0, 0, intensity * 0.5)
	var tween := create_tween()
	tween.tween_property(_blood_rect, "color", Color(0.6, 0, 0, 0), duration)

func _do_noise(intensity: float, duration: float) -> void:
	var elapsed := 0.0
	while elapsed < duration:
		_noise_rect.color = Color(1, 1, 1, randf() * intensity * 0.3)
		await get_tree().process_frame
		elapsed += get_process_delta_time()
	_noise_rect.color = Color(1, 1, 1, 0)

func _get_camera() -> Camera2D:
	if _camera_ref:
		return _camera_ref
	var tree := get_tree()
	if tree and tree.current_scene:
		for child in tree.current_scene.get_children():
			if child is Camera2D:
				_camera_ref = child
				return _camera_ref
	return null
