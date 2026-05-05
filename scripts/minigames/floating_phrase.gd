class_name FloatingPhrase
extends Control
# ============================================================
# Step 33: 飘动文字组件
# ============================================================

var phrase_data: DebatePhrase
var _label: RichTextLabel
var _direction: Vector2
var _lifetime_left: float
var _screen_size: Vector2

func setup(data: DebatePhrase) -> void:
	phrase_data = data

	var bg := ColorRect.new()
	bg.color = Color(0, 0, 0, 0.5)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	_label = RichTextLabel.new()
	_label.bbcode_enabled = true
	_label.scroll_active = false
	_label.size = Vector2(900, 60)
	_label.add_theme_font_size_override("normal_font_size", 28)
	_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	_label.add_theme_constant_override("outline_size", 4)
	add_child(_label)

	if data.is_contradiction:
		_label.text = "[color=#FFEE55]【%s】[/color]" % data.text
	else:
		_label.text = "[color=#DDDDDD]%s[/color]" % data.text

	bg.size = Vector2(900, 60)
	bg.position = Vector2(0, 0)

	self.size = Vector2(900, 60)

	var angle := randf() * TAU
	_direction = Vector2(cos(angle), sin(angle))
	_lifetime_left = data.lifetime
	position = Vector2(randf_range(200, 1720), randf_range(100, 800))

func _ready() -> void:
	_screen_size = get_viewport().get_visible_rect().size
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _process(delta: float) -> void:
	position += _direction * phrase_data.speed * delta
	_lifetime_left -= delta

	if position.x < 0 or position.x > _screen_size.x:
		_direction.x *= -1
	if position.y < 50 or position.y > _screen_size.y - 150:
		_direction.y *= -1

	if _lifetime_left <= 0:
		queue_free()

func get_text_rect() -> Rect2:
	return Rect2(global_position, _label.size)

func is_contradiction() -> bool:
	return phrase_data.is_contradiction

func get_required_evidence_id() -> String:
	return phrase_data.required_evidence_id

func play_hit_effect() -> void:
	if phrase_data.is_contradiction:
		_label.text = "[color=red]%s[/color]" % phrase_data.text
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.3)
	tween.tween_callback(queue_free)

func play_miss_effect() -> void:
	var tween := create_tween()
	tween.tween_property(self, "modulate", Color.RED, 0.1)
	tween.tween_property(self, "modulate", Color.WHITE, 0.3)

func has_point(point: Vector2) -> bool:
	return get_text_rect().has_point(point)
