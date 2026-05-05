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
var _real_contradiction_hit: bool = false
var _is_evidence_ring_open: bool = false
var _selected_evidence_id: String = ""
var _current_target: FloatingPhrase
var _current_hotspot: Dictionary = {}
var _can_aim: bool = false

# UI elements
var _bg: ColorRect
var _crosshair: Control
var _ring_container: Control
var _ring_buttons: Array[Button] = []
var _hp_label: Label
var _info_label: Label
var _speaker_label: Label
var _phrase_container: Control
var _noise_timer: Timer
var _spawn_timer: Timer
var _courtroom_ref: Node

func _ready() -> void:
	_build_ui()

func start_debate(config: NonStopDebateConfig) -> void:
	_config = config
	_spawn_index = 0
	_contradiction_hit_count = 0
	_real_contradiction_hit = false
	_phrases.clear()
	_clear_old_phrases()
	_total_contradictions = _count_contradictions()
	_can_aim = true
	_info_label.text = "瞄准句中亮色词语！金色=真矛盾 橙色=假矛盾 Tab选言弹发射"
	_courtroom_ref = _find_courtroom()
	_apply_camera_presets()
	_start_spawning()
	_start_noise()

func _find_courtroom() -> Node:
	var tree := get_tree()
	if tree:
		var scene := tree.current_scene
		if scene and scene is CourtroomScene:
			return scene
	return null

func _apply_camera_presets() -> void:
	if not _courtroom_ref:
		return
	var cam: CourtroomCamera = _courtroom_ref.get_camera()
	if not cam:
		return
	cam.set_transition_style(_config.camera_transition)
	cam.set_lock_style(_config.camera_lock)

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

	_speaker_label = Label.new()
	_speaker_label.position = Vector2(30, 150)
	_speaker_label.add_theme_font_size_override("font_size", 22)
	_speaker_label.add_theme_color_override("font_color", Color(1, 1, 1))
	add_child(_speaker_label)

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
	_current_hotspot.clear()
	_crosshair.modulate = Color(0, 1, 1, 0.7)
	for phrase in _phrases:
		if not is_instance_valid(phrase):
			continue
		if not phrase.has_point(_crosshair.position):
			continue
		var hs := phrase.find_hotspot_at(_crosshair.position)
		if hs.is_empty():
			_crosshair.modulate = Color(0.5, 0.5, 0.5, 0.5)
		elif hs.get("is_real", false):
			_current_target = phrase
			_current_hotspot = hs
			_crosshair.modulate = Color(1, 0.95, 0.3, 1.0)
		elif hs.get("is_fake", false):
			_current_target = phrase
			_current_hotspot = hs
			_crosshair.modulate = Color(1, 0.5, 0.1, 0.9)
		else:
			_crosshair.modulate = Color(0.5, 0.5, 0.5, 0.5)
		return

func _start_spawning() -> void:
	_spawn_timer.start(0.5)

func _spawn_next_phrase() -> void:
	# 一轮发言结束 → 主角思考 → 重新循环
	if _spawn_index >= _config.phrases.size():
		if _real_contradiction_hit:
			return
		# 清除旧发言
		for p in _phrases:
			if is_instance_valid(p):
				p.queue_free()
		_phrases.clear()
		# 主角总结思考 — 复用裁判场对话框
		_speaker_label.text = ""
		_info_label.text = ""
		_bg.hide()
		_crosshair.hide()
		EventBus.dialogue_show.emit({
			"speaker": "naegi",
			"text": "大家都在说什么……真正的矛盾到底在哪里？我得冷静下来好好想想……",
			"camera": "closeup"
		})
		await EventBus.dialogue_next
		_bg.show()
		_crosshair.show()
		_spawn_timer.start(0.5)
		_spawn_index = 0
		return

	# 清除上一轮的发言
	for p in _phrases:
		if is_instance_valid(p):
			p.queue_free()
	_phrases.clear()

	var dp := _config.phrases[_spawn_index]
	_spawn_index += 1

	_highlight_debate_speaker(dp.speaker_id)

	var phrase := FloatingPhrase.new()
	phrase.setup(dp)
	_phrase_container.add_child(phrase)
	_phrases.append(phrase)

	# 等待发言时间后进入下一轮
	_spawn_timer.start(dp.speak_duration)

func _highlight_debate_speaker(speaker_id: String) -> void:
	if speaker_id == "":
		return
	var cd := CharacterManager.get_character(speaker_id)
	var name_str := cd.display_name if cd else speaker_id
	_speaker_label.text = "▼ 发言中: %s" % name_str

	if _courtroom_ref:
		_courtroom_ref.clear_highlights()
		_courtroom_ref.move_camera_to_speaker(speaker_id, "closeup")

func _wait_dialogue_close() -> void:
	await EventBus.dialogue_next

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
	ndp.hotspots = []
	ndp.speed = randf_range(80, 140)
	ndp.lifetime = randf_range(3, 6)
	var fp := FloatingPhrase.new()
	fp.setup(ndp)
	fp.modulate.a = 0.5
	_phrase_container.add_child(fp)
	_noise_phrases.append(fp)

func _unhandled_input(event: InputEvent) -> void:
	if not _can_aim:
		return
	if event.is_action_pressed("open_evidence_ring"):
		_toggle_evidence_ring()
		get_viewport().set_input_as_handled()
		return
	if _is_evidence_ring_open:
		return
	var should_fire := false
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		should_fire = true
	elif event.is_action_pressed("fire_evidence"):
		should_fire = true
	if should_fire:
		if _current_target and not _current_hotspot.is_empty():
			if _selected_evidence_id == "":
				_auto_select_evidence()
			_fire_evidence()
			get_viewport().set_input_as_handled()

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
	if not _current_hotspot.is_empty():
		_selected_evidence_id = _current_hotspot.get("required_evidence_id", "")

func _fire_evidence() -> void:
	if not _current_target:
		return
	# 射击动画：子弹+拖尾
	var bullet := ColorRect.new()
	bullet.color = Color(0.3, 0.9, 1)
	bullet.size = Vector2(10, 10)
	bullet.position = _crosshair.position - Vector2(5, 5)
	add_child(bullet)

	var trail := ColorRect.new()
	trail.color = Color(0.2, 0.7, 1, 0.5)
	trail.size = Vector2(6, 6)
	trail.position = bullet.position
	add_child(trail)

	var target_pos := _current_target.global_position + _current_target.size / 2
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(bullet, "position", target_pos, 0.15).set_ease(Tween.EASE_IN)
	tween.tween_property(trail, "position", target_pos, 0.18).set_ease(Tween.EASE_IN)
	tween.tween_property(trail, "modulate:a", 0.0, 0.18)
	tween.chain().tween_callback(_on_bullet_arrive.bind(bullet, trail))

func _on_bullet_arrive(bullet: ColorRect, trail: ColorRect) -> void:
	bullet.queue_free()
	trail.queue_free()
	if not is_instance_valid(_current_target) or _current_hotspot.is_empty():
		return

	# 击中假矛盾 → 扣血 + 错误对话 → 重启循环
	if _current_hotspot.get("is_fake", false):
		_selected_evidence_id = ""
		DebateManager.damage_hp(8)
		_can_aim = false
		var fail_text: String = _current_hotspot.get("fail_dialogue", "这不是真正的矛盾……")
		await _show_fail_dialogue(fail_text)
		_restart_debate_cycle()
		return

	# 击中真矛盾 → 检查证据
	if _current_hotspot.get("is_real", false):
		var required: String = _current_hotspot.get("required_evidence_id", "")
		if _selected_evidence_id == required:
			# 正确！→ BREAK特效 → 结束
			_selected_evidence_id = ""
			_can_aim = false
			_real_contradiction_hit = true
			DebateManager.heal_hp(5)
			_current_target.queue_free()
			_phrases.erase(_current_target)
			await _show_break_effect()
			_complete_debate(true)
			return
		else:
			# 证据错误 → 错误对话 → 重启循环
			_selected_evidence_id = ""
			DebateManager.damage_hp(10)
			_can_aim = false
			_current_target.play_miss_effect()
			var fail_text: String = _current_hotspot.get("fail_dialogue", "这个证据不对！")
			await _show_fail_dialogue(fail_text)
			_restart_debate_cycle()
			return

	# 击中普通文字
	DebateManager.damage_hp(3)
	_info_label.text = "这不是矛盾！-3 HP"
	_selected_evidence_id = ""

func _show_fail_dialogue(text: String) -> void:
	_bg.hide()
	_crosshair.hide()
	_info_label.text = ""
	_speaker_label.text = ""
	EventBus.dialogue_show.emit({"speaker": "naegi", "text": text, "camera": "closeup"})
	await EventBus.dialogue_next
	_bg.show()
	_crosshair.show()

func _restart_debate_cycle() -> void:
	_spawn_index = 0
	for p in _phrases:
		if is_instance_valid(p):
			p.queue_free()
	_phrases.clear()
	_can_aim = true
	_info_label.text = "再仔细想想……瞄准句中亮色词语！"
	_spawn_timer.start(0.5)

func _show_break_effect() -> void:
	# 屏幕碎裂特效 → BREAK文字
	var flash := ColorRect.new()
	flash.color = Color(1, 1, 1, 0.7)
	flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(flash)
	var t1 := create_tween()
	t1.tween_property(flash, "color:a", 0.0, 0.3)
	t1.tween_callback(flash.queue_free)

	var break_label := Label.new()
	break_label.text = "BREAK"
	break_label.add_theme_font_size_override("font_size", 80)
	break_label.add_theme_color_override("font_color", Color(1, 0.2, 0.2))
	break_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	break_label.size = Vector2(400, 100)
	break_label.position = Vector2(760, 440)
	add_child(break_label)

	# 碎片效果：多个小色块向外飞出
	for i in range(12):
		var shard := ColorRect.new()
		shard.color = Color(randf(), randf(), randf(), 0.8)
		shard.size = Vector2(randf_range(20, 60), randf_range(20, 60))
		shard.position = break_label.position + Vector2(200, 50)
		add_child(shard)
		var angle := TAU * float(i) / 12.0
		var end_pos := shard.position + Vector2(cos(angle) * 300, sin(angle) * 200)
		var t2 := create_tween()
		t2.tween_property(shard, "position", end_pos, 0.6)
		t2.parallel().tween_property(shard, "modulate:a", 0.0, 0.6)
		t2.tween_callback(shard.queue_free)

	var t3 := create_tween()
	t3.tween_property(break_label, "modulate:a", 1.0, 0.1)
	t3.tween_property(break_label, "modulate:a", 0.5, 0.1)
	t3.tween_property(break_label, "modulate:a", 1.0, 0.1)
	t3.tween_interval(1.0)
	t3.tween_property(break_label, "modulate:a", 0.0, 0.5)
	t3.tween_callback(break_label.queue_free)
	_selected_evidence_id = ""

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
		if p.has_hotspots():
			count += 1
	return count
