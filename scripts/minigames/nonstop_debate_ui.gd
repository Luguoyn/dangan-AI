extends CanvasLayer
class_name NonStopDebateUI
# ============================================================
# Steps 32+34+35: 无休止议论 主 UI + 准星 + 主逻辑
# ============================================================

signal debate_finished(success: bool)

var _config: NonStopDebateConfig
var _phrases: Array[FloatingPhrase] = []
var _noise_phrases: Array[FloatingPhrase] = []
var _spawn_index: int = 0
var _contradiction_hit_count: int = 0
var _total_contradictions: int = 0
var _is_evidence_ring_open: bool = false
var _selected_evidence_id: String = ""
var _current_target: FloatingPhrase
var _can_aim: bool = false

# UI elements
var _bg: ColorRect
var _crosshair: Control
var _ring_container: Control
var _ring_buttons: Array[Button] = []
var _hp_label: Label
var _info_label: Label
var _phrase_container: Control
var _noise_timer: Timer
var _spawn_timer: Timer

func _ready() -> void:
	_build_ui()

func start_debate(config: NonStopDebateConfig) -> void:
	_config = config
	_spawn_index = 0
	_contradiction_hit_count = 0
	_phrases.clear()
	_clear_old_phrases()
	_total_contradictions = _count_contradictions()
	_can_aim = true
	_info_label.text = "找到矛盾！瞄准黄色发言，按Tab选择言弹发射！"
	_start_spawning()
	_start_noise()

func _build_ui() -> void:
	_bg = ColorRect.new()
	_bg.color = Color(0, 0, 0, 0.75)
	_bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_bg)

	_phrase_container = Control.new()
	_phrase_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_phrase_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_phrase_container)

	_crosshair = Control.new()
	_crosshair.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_crosshair)
	var ch := ColorRect.new()
	ch.color = Color(0, 1, 1, 0.7)
	ch.size = Vector2(30, 2)
	ch.position = Vector2(-15, -1)
	_crosshair.add_child(ch)
	var cv := ColorRect.new()
	cv.color = Color(0, 1, 1, 0.7)
	cv.size = Vector2(2, 30)
	cv.position = Vector2(-1, -15)
	_crosshair.add_child(cv)

	_ring_container = Control.new()
	_ring_container.hide()
	add_child(_ring_container)

	_info_label = Label.new()
	_info_label.position = Vector2(30, 120)
	_info_label.add_theme_font_size_override("font_size", 18)
	_info_label.add_theme_color_override("font_color", Color(1, 0.9, 0.4))
	add_child(_info_label)

	_hp_label = Label.new()
	_hp_label.position = Vector2(30, 60)
	_hp_label.add_theme_font_size_override("font_size", 22)
	_hp_label.add_theme_color_override("font_color", Color(0.2, 1, 0.4))
	add_child(_hp_label)

	_noise_timer = Timer.new()
	_noise_timer.wait_time = 1.5
	_noise_timer.one_shot = false
	_noise_timer.timeout.connect(_spawn_noise)
	add_child(_noise_timer)

	_spawn_timer = Timer.new()
	_spawn_timer.one_shot = true
	_spawn_timer.timeout.connect(_spawn_next_phrase)
	add_child(_spawn_timer)

func _process(_delta: float) -> void:
	if not _can_aim:
		return
	_crosshair.position = get_viewport().get_mouse_position()
	_check_phrase_hover()
	_hp_label.text = "HP %d/%d" % [DebateManager.current_hp, DebateManager.max_hp]

func _check_phrase_hover() -> void:
	_current_target = null
	_crosshair.modulate = Color(0, 1, 1, 0.7)
	for phrase in _phrases:
		if is_instance_valid(phrase) and phrase.has_point(_crosshair.position):
			if phrase.is_contradiction():
				_current_target = phrase
				_crosshair.modulate = Color(1, 0.8, 0.2, 1.0)
			else:
				_crosshair.modulate = Color(0.5, 0.5, 0.5, 0.5)

func _start_spawning() -> void:
	_spawn_timer.start(0.3)

func _spawn_next_phrase() -> void:
	if _spawn_index >= _config.phrases.size():
		return
	var dp := _config.phrases[_spawn_index]
	_spawn_index += 1
	var phrase := FloatingPhrase.new()
	phrase.setup(dp)
	_phrase_container.add_child(phrase)
	_phrases.append(phrase)
	if _spawn_index < _config.phrases.size():
		_spawn_timer.start(_config.spawn_interval)

func _start_noise() -> void:
	if _config.noise_texts.size() > 0:
		_noise_timer.start()

func _spawn_noise() -> void:
	if _config.noise_texts.is_empty():
		return
	var text := _config.noise_texts[randi() % _config.noise_texts.size()]
	var ndp := DebatePhrase.new()
	ndp.text = text
	ndp.speaker_id = ""
	ndp.is_contradiction = false
	ndp.speed = randf_range(80, 140)
	ndp.lifetime = randf_range(3, 6)
	var fp := FloatingPhrase.new()
	fp.setup(ndp)
	fp.modulate.a = 0.5
	_phrase_container.add_child(fp)
	_noise_phrases.append(fp)

func _input(event: InputEvent) -> void:
	if not _can_aim:
		return
	if event.is_action_pressed("open_evidence_ring"):
		_toggle_evidence_ring()
	if event.is_action_pressed("fire_evidence") and not _is_evidence_ring_open:
		if _current_target and _current_target.is_contradiction():
			if _selected_evidence_id == "":
				_auto_select_evidence()
			_fire_evidence()

func _toggle_evidence_ring() -> void:
	if _is_evidence_ring_open:
		_close_evidence_ring()
	else:
		_open_evidence_ring()

func _open_evidence_ring() -> void:
	_is_evidence_ring_open = true
	_clear_ring_buttons()
	var evidence_list := EvidenceManager.get_all_evidence()
	var radius := 120.0
	var count := evidence_list.size()
	for i in range(count):
		var ev := evidence_list[i] as Dictionary
		var angle := TAU * float(i) / float(count) - PI / 2
		var btn := Button.new()
		btn.text = str(ev.get("name", "???"))
		btn.position = Vector2(cos(angle), sin(angle)) * radius - Vector2(60, 15)
		btn.size = Vector2(120, 30)
		btn.add_theme_font_size_override("font_size", 10)
		btn.pressed.connect(_on_evidence_selected.bind(ev.get("id", "")))
		_ring_container.add_child(btn)
		_ring_buttons.append(btn)
	_ring_container.position = _crosshair.position
	_ring_container.show()

func _close_evidence_ring() -> void:
	_is_evidence_ring_open = false
	_clear_ring_buttons()
	_ring_container.hide()

func _clear_ring_buttons() -> void:
	for btn in _ring_buttons:
		btn.queue_free()
	_ring_buttons.clear()

func _on_evidence_selected(ev_id: String) -> void:
	_selected_evidence_id = ev_id
	_close_evidence_ring()
	_info_label.text = "言弹已选择: " + ev_id + " — 点击瞄准的黄色矛盾发言发射！"

func _auto_select_evidence() -> void:
	if _current_target:
		_selected_evidence_id = _current_target.get_required_evidence_id()

func _fire_evidence() -> void:
	if not _current_target:
		return
	var bullet := ColorRect.new()
	bullet.color = Color(0.2, 0.8, 1, 0.8)
	bullet.size = Vector2(8, 8)
	bullet.position = _crosshair.position
	add_child(bullet)
	var target_pos := _current_target.global_position + _current_target.size / 2
	var tween := create_tween()
	tween.tween_property(bullet, "position", target_pos, 0.2)
	tween.tween_callback(_on_bullet_arrive.bind(bullet))

func _on_bullet_arrive(bullet: ColorRect) -> void:
	bullet.queue_free()
	if not is_instance_valid(_current_target):
		return
	var required := _current_target.get_required_evidence_id()
	if _selected_evidence_id == required:
		_current_target.play_hit_effect()
		_contradiction_hit_count += 1
		DebateManager.heal_hp(5)
		_info_label.text = "就是这个！！（已击破 %d/%d）" % [_contradiction_hit_count, _total_contradictions]
		_selected_evidence_id = ""
		if _contradiction_hit_count >= _total_contradictions:
			_complete_debate(true)
	else:
		_current_target.play_miss_effect()
		DebateManager.damage_hp(10)
		_info_label.text = "不对……选错了！-10 HP"
		if DebateManager.current_hp <= 0:
			_complete_debate(false)

func _complete_debate(success: bool) -> void:
	_can_aim = false
	_noise_timer.stop()
	_spawn_timer.stop()
	_clear_old_phrases()
	_clear_ring_buttons()
	_ring_container.hide()
	var tween := create_tween()
	tween.tween_property(_bg, "color:a", 0.0, 0.5)
	tween.tween_callback(queue_free)
	if success:
		debate_finished.emit(true)
		EventBus.nonstop_debate_finished.emit(true)
	else:
		debate_finished.emit(false)
		EventBus.nonstop_debate_finished.emit(false)

func _clear_old_phrases() -> void:
	for p in _phrases:
		if is_instance_valid(p):
			p.queue_free()
	_phrases.clear()
	for p in _noise_phrases:
		if is_instance_valid(p):
			p.queue_free()
	_noise_phrases.clear()

func _count_contradictions() -> int:
	var count := 0
	for p in _config.phrases:
		if p.is_contradiction:
			count += 1
	return count
