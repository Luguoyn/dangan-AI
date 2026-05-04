extends CanvasLayer
class_name RebuttalUI
# ============================================================
# Steps 37+38: 反论 UI + 主逻辑
# ============================================================

signal rebuttal_finished(success: bool)

var _config: RebuttalConfig
var _slash_index: int = 0
var _active_slashes: Array[Control] = []
var _judge_x: float = 350.0
var _combo: int = 0
var _can_slash: bool = false

var _opponent_label: Label
var _combo_label: Label
var _prompt_label: Label
var _judge_line: ColorRect
var _bg: ColorRect

func _ready() -> void:
	_build_ui()

func start_rebuttal(config: RebuttalConfig) -> void:
	_config = config
	_slash_index = 0
	_combo = 0
	_can_slash = true
	_active_slashes.clear()
	_opponent_label.text = "VS " + CharacterManager.get_display_name(config.opponent_id)
	_combo_label.text = ""
	_prompt_label.text = "按空格键斩断！"
	_bg.show()
	show()
	_spawn_slashes()

func _build_ui() -> void:
	_bg = ColorRect.new()
	_bg.color = Color(0.1, 0.0, 0.05, 0.85)
	_bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_bg)

	_opponent_label = Label.new()
	_opponent_label.position = Vector2(30, 40)
	_opponent_label.add_theme_font_size_override("font_size", 28)
	_opponent_label.add_theme_color_override("font_color", Color(1, 0.3, 0.3))
	add_child(_opponent_label)

	_combo_label = Label.new()
	_combo_label.position = Vector2(30, 80)
	_combo_label.add_theme_font_size_override("font_size", 20)
	_combo_label.add_theme_color_override("font_color", Color(1, 0.8, 0.2))
	add_child(_combo_label)

	_judge_line = ColorRect.new()
	_judge_line.color = Color(1, 0.3, 0.3, 0.5)
	_judge_line.size = Vector2(4, 200)
	_judge_line.position = Vector2(_judge_x, 300)
	add_child(_judge_line)

	_prompt_label = Label.new()
	_prompt_label.position = Vector2(_judge_x - 80, 520)
	_prompt_label.add_theme_font_size_override("font_size", 22)
	_prompt_label.add_theme_color_override("font_color", Color(1, 1, 0.8))
	add_child(_prompt_label)

func _spawn_slashes() -> void:
	for i in range(_config.slash_lines.size()):
		var text := _config.slash_lines[i]
		var timing := _config.slash_timings[i]
		var speed := _config.slash_speeds[i]
		await get_tree().create_timer(maxf(0.5, timing - (1.0 if i > 0 else 0.0))).timeout
		if not _can_slash:
			return
		_create_slash(text, speed)

func _create_slash(text: String, speed: float) -> void:
	var slash := Control.new()
	slash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(slash)

	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 32)
	label.add_theme_color_override("font_color", Color(1, 0.5, 0.5))
	slash.add_child(label)

	slash.position = Vector2(1920, randf_range(320, 480))
	_active_slashes.append(slash)

	var tween := slash.create_tween()
	var travel_time := (1920 - _judge_x + 100) / speed
	tween.tween_property(slash, "position:x", _judge_x - 200, travel_time)
	tween.tween_callback(_on_slash_passed.bind(slash))

func _input(event: InputEvent) -> void:
	if not _can_slash:
		return
	if event.is_action_pressed("slash"):
		_check_slash()

func _check_slash() -> void:
	if _active_slashes.is_empty():
		return
	var best: Control
	var best_dist := 9999.0
	for s in _active_slashes:
		if not is_instance_valid(s):
			continue
		var dist := absf(s.position.x - _judge_x)
		if dist < best_dist:
			best_dist = dist
			best = s
	if best == null:
		return
	var window := DebateManager.get_diff_param("rebuttal_judge_window", 50)
	if best_dist < window:
		_on_slash_success(best, best_dist)
	else:
		_on_slash_fail()

func _on_slash_success(slash: Control, dist: float) -> void:
	_combo += 1
	var rating := "Good"
	if dist < 15:
		rating = "Perfect!"
	elif dist < 30:
		rating = "Great!"
	_combo_label.text = "%s  x%d" % [rating, _combo]
	_active_slashes.erase(slash)
	slash.queue_free()
	DebateManager.heal_hp(2)
	if _active_slashes.is_empty() and _slash_index >= _config.slash_lines.size():
		_complete(true)

func _on_slash_fail() -> void:
	_combo = 0
	_combo_label.text = "Miss!"
	DebateManager.damage_hp(10)
	if DebateManager.current_hp <= 0:
		_complete(false)

func _on_slash_passed(slash: Control) -> void:
	if is_instance_valid(slash):
		_active_slashes.erase(slash)
		slash.queue_free()
	_combo = 0
	_combo_label.text = "Miss..."
	DebateManager.damage_hp(5)
	_slash_index += 1
	if _slash_index >= _config.slash_lines.size():
		_complete(true)

func _complete(success: bool) -> void:
	_can_slash = false
	for s in _active_slashes:
		if is_instance_valid(s):
			s.queue_free()
	_active_slashes.clear()
	var tween := create_tween()
	tween.tween_property(_bg, "color:a", 0.0, 0.5)
	tween.tween_callback(queue_free)
	rebuttal_finished.emit(success)
	EventBus.rebuttal_finished.emit(success)
