class_name FloatingPhrase
extends Control
# ============================================================
# Step 33: 飘动文字组件 — 句中矛盾词紧密排列
# ============================================================

var phrase_data: DebatePhrase
var _segments: Array[Control] = []
var _hotspot_map: Dictionary = {}
var _direction: Vector2
var _lifetime_left: float
var _screen_size: Vector2
var _bg: ColorRect

func setup(data: DebatePhrase) -> void:
	phrase_data = data

	_bg = ColorRect.new()
	_bg.color = Color(0, 0, 0, 0.5)
	_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_bg)

	# 发言人标签
	if data.speaker_id != "":
		var cd := CharacterManager.get_character(data.speaker_id)
		var tag := Label.new()
		tag.text = cd.display_name if cd else data.speaker_id
		tag.position = Vector2(6, 0)
		tag.add_theme_font_size_override("font_size", 13)
		tag.add_theme_color_override("font_color", Color(0.6, 0.8, 1))
		add_child(tag)

	var x_pos: float = 6
	var full_width: float = 12

	var parts := _build_text_segments(data.text, data.hotspots)
	for part in parts:
		var label := Label.new()
		label.text = part["text"]
		label.position = Vector2(x_pos, 18)
		label.add_theme_font_size_override("font_size", 30)
		label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
		label.add_theme_constant_override("outline_size", 4)
		label.mouse_filter = Control.MOUSE_FILTER_STOP

		if part["is_real"]:
			label.add_theme_color_override("font_color", Color(1, 0.95, 0.2))
		elif part["is_fake"]:
			label.add_theme_color_override("font_color", Color(1, 0.5, 0.1))
		else:
			label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))

		var seg := Control.new()
		seg.mouse_filter = Control.MOUSE_FILTER_STOP
		seg.add_child(label)
		seg.size = label.size + Vector2(0, 4)
		seg.position = Vector2(x_pos, 16)
		add_child(seg)

		if part["is_real"] or part["is_fake"]:
			_hotspot_map[seg] = part

		x_pos += label.size.x  # 无空格紧密排列
		full_width += label.size.x
		_segments.append(seg)

	_bg.size = Vector2(full_width, 64)
	_bg.position = Vector2(0, 0)
	self.size = Vector2(full_width, 64)

	_screen_size = get_viewport().get_visible_rect().size if get_viewport() else Vector2(1920, 1080)
	var angle := randf() * TAU
	_direction = Vector2(cos(angle), sin(angle))
	_lifetime_left = data.lifetime
	position = Vector2(randf_range(20, _screen_size.x - full_width - 20), randf_range(120, _screen_size.y - 200))

func _build_text_segments(full_text: String, hotspots: Array) -> Array[Dictionary]:
	if hotspots.is_empty():
		return [{"text": full_text, "is_real": false, "is_fake": false}]

	var remaining := full_text
	var segments: Array[Dictionary] = []

	for h in hotspots:
		var keyword: String = h.get("text", "")
		var idx := remaining.find(keyword)
		if idx >= 0:
			if idx > 0:
				segments.append({"text": remaining.substr(0, idx), "is_real": false, "is_fake": false})
			var is_real: bool = h.get("is_real", false)
			var seg_data := {"text": keyword, "is_real": is_real, "is_fake": not is_real}
			if is_real:
				seg_data["required_evidence_id"] = h.get("required_evidence_id", "")
			seg_data["fail_dialogue"] = h.get("fail_dialogue", "")
			segments.append(seg_data)
			remaining = remaining.substr(idx + keyword.length())
		else:
			var is_real: bool = h.get("is_real", false)
			segments.append({"text": keyword, "is_real": is_real, "is_fake": not is_real})

	if remaining.length() > 0:
		segments.append({"text": remaining, "is_real": false, "is_fake": false})

	return segments

func _process(delta: float) -> void:
	position += _direction * phrase_data.speed * delta
	_lifetime_left -= delta

	# 边界检测，不超出屏幕
	var margin := 10.0
	if position.x < margin:
		position.x = margin
		_direction.x *= -1
	if position.x + size.x > _screen_size.x - margin:
		position.x = _screen_size.x - size.x - margin
		_direction.x *= -1
	if position.y < 100:
		position.y = 100
		_direction.y *= -1
	if position.y + size.y > _screen_size.y - 180:
		position.y = _screen_size.y - size.y - 180
		_direction.y *= -1

	if _lifetime_left <= 0:
		queue_free()

func get_text_rect() -> Rect2:
	return Rect2(global_position, size)

func find_hotspot_at(point: Vector2) -> Dictionary:
	for seg in _segments:
		if is_instance_valid(seg):
			var r := Rect2(seg.global_position, seg.size)
			if r.has_point(point):
				return _hotspot_map.get(seg, {})
	return {}

func has_point(point: Vector2) -> bool:
	return get_text_rect().has_point(point)

func play_hit_effect() -> void:
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.3)
	tween.tween_callback(queue_free)

func play_miss_effect() -> void:
	var tween := create_tween()
	tween.tween_property(self, "modulate", Color.RED, 0.15)
	tween.tween_property(self, "modulate", Color.WHITE, 0.25)
