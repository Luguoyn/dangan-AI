extends CanvasLayer
class_name HangmanUI
# ============================================================
# Steps 39-44: 拼字统一UI (三种模式)
# ============================================================

signal hangman_finished(success: bool)

var _mode: String = "letter"
var _letter_config: Dictionary = {}
var _kanji_config: Dictionary = {}
var _word_config: Dictionary = {}
var _progress: Array[String] = []
var _target_index: int = 0

var _time_left: float = 25.0
var _hint_label: Label
var _slots_container: HBoxContainer
var _timer_bar: ProgressBar
var _main_container: Control
var _bg: ColorRect

# Letter mode
var _letter_nodes: Array[Label] = []
var _ring_angle: float = 0.0
var _letter_candidates: Array[String] = []

# Kanji mode
var _fragment_buttons: Array[Button] = []

# Word mode
var _char_buttons: Array[Button] = []

func _ready() -> void:
	_build_ui()

func start_hangman(mode: String, config_data: Dictionary) -> void:
	_mode = mode
	_progress.clear()
	_target_index = 0
	match mode:
		"letter": _letter_config = config_data
		"kanji":  _kanji_config = config_data
		"word":   _word_config = config_data

	_time_left = config_data.get("time_limit", 25.0)
	_hint_label.text = config_data.get("hint_text", "")
	_timer_bar.max_value = _time_left
	_timer_bar.value = _time_left
	_bg.show()
	show()

	match mode:
		"letter": _setup_letter_mode()
		"kanji":  _setup_kanji_mode()
		"word":   _setup_word_mode()

func _build_ui() -> void:
	_bg = ColorRect.new()
	_bg.color = Color(0.05, 0.02, 0.1, 0.92)
	_bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_bg)

	_hint_label = Label.new()
	_hint_label.position = Vector2(100, 60)
	_hint_label.add_theme_font_size_override("font_size", 24)
	_hint_label.add_theme_color_override("font_color", Color(1, 0.9, 0.4))
	add_child(_hint_label)

	_slots_container = HBoxContainer.new()
	_slots_container.position = Vector2(400, 150)
	_slots_container.add_theme_constant_override("separation", 10)
	add_child(_slots_container)

	_timer_bar = ProgressBar.new()
	_timer_bar.position = Vector2(400, 220)
	_timer_bar.size = Vector2(400, 20)
	add_child(_timer_bar)

	_main_container = Control.new()
	_main_container.position = Vector2(200, 300)
	_main_container.size = Vector2(1500, 500)
	add_child(_main_container)

func _process(delta: float) -> void:
	_time_left -= delta
	if _time_left <= 0:
		_complete(false)
		return
	_timer_bar.value = _time_left

	if _mode == "letter":
		_ring_angle += deg_to_rad(_letter_config.get("rotation_speed", 90.0)) * delta
		_update_letter_ring()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("confirm"):
		match _mode:
			"letter": _on_letter_confirm()
			_: pass

func _setup_letter_mode() -> void:
	_clear_main()
	_letter_candidates.assign(_letter_config.get("available_letters", []))
	_letter_nodes.clear()
	_target_index = 0
	var target: String = _letter_config.get("target_word", "")
	_progress.resize(target.length())
	_progress.fill("_")
	_update_slots()

	var count := _letter_candidates.size()
	for i in range(count):
		var label := Label.new()
		label.text = _letter_candidates[i]
		label.add_theme_font_size_override("font_size", 36)
		label.add_theme_color_override("font_color", Color(0.7, 0.7, 1))
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.size = Vector2(60, 50)
		_main_container.add_child(label)
		_letter_nodes.append(label)

func _update_letter_ring() -> void:
	var count := _letter_nodes.size()
	if count == 0:
		return
	var radius := 150.0
	var center := _main_container.size / 2
	for i in range(count):
		var angle := TAU * float(i) / float(count) + _ring_angle
		_letter_nodes[i].position = center + Vector2(cos(angle), sin(angle)) * radius - Vector2(30, 25)

func _on_letter_confirm() -> void:
	var target: String = _letter_config.get("target_word", "")
	if _target_index >= target.length():
		return
	var top_idx := _find_topmost_letter()
	if top_idx < 0 or top_idx >= _letter_candidates.size():
		return
	var selected := _letter_candidates[top_idx]
	var expected := target[_target_index]
	if selected == expected:
		_progress[_target_index] = selected
		_target_index += 1
		_update_slots()
		if _target_index >= target.length():
			_complete(true)
	else:
		DebateManager.damage_hp(5)
		if DebateManager.current_hp <= 0:
			_complete(false)

func _find_topmost_letter() -> int:
	var best_idx := -1
	var min_y := INF
	for i in range(_letter_nodes.size()):
		var y := _letter_nodes[i].position.y
		if y < min_y:
			min_y = y
			best_idx = i
	return best_idx

func _setup_kanji_mode() -> void:
	_clear_main()
	_target_index = 0
	var target: String = _kanji_config.get("target_kanji", "")
	_progress = [target]
	_update_slots()

	var all_items: Array[Dictionary] = []
	for comp in _kanji_config.get("components_in_order", []):
		all_items.append({"text": comp, "correct": true, "order": all_items.size()})
	for comp in _kanji_config.get("distractor_components", []):
		all_items.append({"text": comp, "correct": false, "order": -1})
	all_items.shuffle()

	for item in all_items:
		var btn := Button.new()
		btn.text = item["text"]
		btn.add_theme_font_size_override("font_size", 28)
		btn.size = Vector2(80, 50)
		btn.position = Vector2(randf_range(0, 1000), randf_range(0, 300))
		btn.pressed.connect(_on_fragment_clicked.bind(btn, item))
		_main_container.add_child(btn)
		_fragment_buttons.append(btn)

func _on_fragment_clicked(btn: Button, item: Dictionary) -> void:
	var order_idx := item.get("order", -1)
	if item.get("correct", false) and order_idx == _target_index:
		_target_index += 1
		btn.modulate = Color.GREEN
		btn.disabled = true
		if _target_index >= _kanji_config.get("components_in_order", []).size():
			_complete(true)
	else:
		btn.modulate = Color.RED
		DebateManager.damage_hp(5)
		if DebateManager.current_hp <= 0:
			_complete(false)

func _setup_word_mode() -> void:
	_clear_main()
	_target_index = 0
	_progress = _word_config.get("target_chars", [])
	for i in range(_progress.size()):
		_progress[i] = "_"
	_update_slots()

	var all_chars: Array[Dictionary] = []
	for ch in _word_config.get("target_chars", []):
		all_chars.append({"char": ch, "correct": true})
	for ch in _word_config.get("distractor_chars", []):
		all_chars.append({"char": ch, "correct": false})
	all_chars.shuffle()

	for item in all_chars:
		var btn := Button.new()
		btn.text = item["char"]
		btn.add_theme_font_size_override("font_size", 28)
		btn.size = Vector2(70, 50)
		btn.position = Vector2(randf_range(0, 1000), randf_range(0, 300))
		btn.pressed.connect(_on_char_clicked.bind(btn, item))
		_main_container.add_child(btn)
		_char_buttons.append(btn)

func _on_char_clicked(btn: Button, item: Dictionary) -> void:
	if not item.get("correct", false):
		btn.modulate = Color.RED
		DebateManager.damage_hp(5)
		return
	var expected := _word_config.get("target_chars", [])[_target_index]
	if item["char"] == expected:
		_progress[_target_index] = expected
		_target_index += 1
		btn.modulate = Color.GREEN
		btn.disabled = true
		_update_slots()
		if _target_index >= _word_config.get("target_chars", []).size():
			_complete(true)
	else:
		btn.modulate = Color.RED
		DebateManager.damage_hp(5)

func _update_slots() -> void:
	for child in _slots_container.get_children():
		child.queue_free()
	for ch in _progress:
		var slot := Label.new()
		slot.text = ch
		slot.add_theme_font_size_override("font_size", 36)
		if ch == "_":
			slot.add_theme_color_override("font_color", Color(0.4, 0.4, 0.4))
		else:
			slot.add_theme_color_override("font_color", Color(0.2, 1, 0.4))
		_slots_container.add_child(slot)

func _clear_main() -> void:
	for child in _main_container.get_children():
		child.queue_free()
	_letter_nodes.clear()
	_fragment_buttons.clear()
	_char_buttons.clear()

func _complete(success: bool) -> void:
	var tween := create_tween()
	tween.tween_property(_bg, "color:a", 0.0, 0.5)
	tween.tween_callback(queue_free)
	hangman_finished.emit(success)
	EventBus.hangman_finished.emit(success)
