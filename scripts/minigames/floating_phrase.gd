class_name FloatingPhrase
extends Control

var phrase_data: DebatePhrase
var _segments: Array = []
var _hotspot_map: Dictionary = {}
var _direction: Vector2
var _lifetime_left: float = 10.0
var _screen_size: Vector2 = Vector2(1920, 1080)
var _bg: ColorRect
var _ph_width: float = 400.0

func setup(data: DebatePhrase) -> void:
	phrase_data = data
	if get_viewport():
		_screen_size = get_viewport().get_visible_rect().size

	_bg = ColorRect.new()
	_bg.color = Color(0, 0, 0, 0.5)
	_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_bg)

	if data.speaker_id != "":
		var cd = CharacterManager.get_character(data.speaker_id)
		var tag = Label.new()
		tag.text = cd.display_name if cd else data.speaker_id
		tag.position = Vector2(6, 0)
		tag.add_theme_font_size_override("font_size", 13)
		tag.add_theme_color_override("font_color", Color(0.6, 0.8, 1))
		add_child(tag)

	var x_pos = 6.0
	var total_w = 12.0
	var parts = _build_segments(data.text, data.hotspots)

	for part_dict in parts:
		var label = Label.new()
		label.text = str(part_dict.get("text", ""))
		label.position = Vector2(x_pos, 18)
		label.size = Vector2(100, 40)
		label.add_theme_font_size_override("font_size", 30)
		label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
		label.add_theme_constant_override("outline_size", 4)
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE

		var is_real = part_dict.get("is_real", false)
		var is_fake = part_dict.get("is_fake", false)
		if is_real:
			label.add_theme_color_override("font_color", Color(1, 0.95, 0.2))
		elif is_fake:
			label.add_theme_color_override("font_color", Color(1, 0.5, 0.1))
		else:
			label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))

		add_child(label)

		var seg_w = float(len(part_dict.get("text", ""))) * 30.0
		label.size = Vector2(seg_w, 40)
		if is_real or is_fake:
			_hotspot_map[x_pos] = {"x": x_pos, "w": seg_w, "part": part_dict}

		x_pos += seg_w
		total_w += seg_w
		_segments.append(label)

	_ph_width = total_w
	_bg.size = Vector2(_ph_width, 64)
	self.size = Vector2(_ph_width, 64)

	_direction = Vector2(cos(randf() * TAU), sin(randf() * TAU))
	_lifetime_left = data.lifetime
	position = Vector2(
		clampf(randf_range(50, _screen_size.x - _ph_width - 50), 5, _screen_size.x - _ph_width - 5),
		clampf(randf_range(140, _screen_size.y - 250), 100, _screen_size.y - size.y - 170)
	)

func _build_segments(text, hotspots):
	if hotspots.is_empty():
		return [{"text": text, "is_real": false, "is_fake": false}]
	var remaining = text
	var segments = []
	for h in hotspots:
		var kw = str(h.get("text", ""))
		var idx = remaining.find(kw)
		if idx >= 0:
			if idx > 0:
				segments.append({"text": remaining.substr(0, idx), "is_real": false, "is_fake": false})
			var real = h.get("is_real", false)
			var sd = {"text": kw, "is_real": real, "is_fake": not real}
			if real:
				sd["required_evidence_id"] = h.get("required_evidence_id", "")
			sd["fail_dialogue"] = h.get("fail_dialogue", "")
			segments.append(sd)
			remaining = remaining.substr(idx + kw.length())
		else:
			var real = h.get("is_real", false)
			segments.append({"text": kw, "is_real": real, "is_fake": not real})
	if remaining.length() > 0:
		segments.append({"text": remaining, "is_real": false, "is_fake": false})
	return segments

func _process(delta: float) -> void:
	position += _direction * phrase_data.speed * delta
	_lifetime_left -= delta

	position.x = clampf(position.x, 0, _screen_size.x - _ph_width)
	position.y = clampf(position.y, 100, _screen_size.y - size.y - 180)
	if position.x <= 0 or position.x >= _screen_size.x - _ph_width:
		_direction.x *= -1
	if position.y <= 100 or position.y >= _screen_size.y - size.y - 180:
		_direction.y *= -1

	if _lifetime_left <= 0:
		queue_free()

func has_point(point: Vector2) -> bool:
	return Rect2(global_position, size).has_point(point)

func find_hotspot_at(screen_point: Vector2) -> Dictionary:
	var local = screen_point - global_position
	for key in _hotspot_map:
		var info = _hotspot_map[key]
		var x0 = info.get("x", 0.0)
		var w = info.get("w", 0.0)
		if local.x >= x0 and local.x <= x0 + w and local.y >= 0 and local.y <= 64:
			return info.get("part", {})
	return {}

func play_hit_effect() -> void:
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.3)
	tween.tween_callback(queue_free)

func play_miss_effect() -> void:
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color.RED, 0.15)
	tween.tween_property(self, "modulate", Color.WHITE, 0.25)
