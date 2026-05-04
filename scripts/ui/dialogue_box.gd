extends CanvasLayer
class_name DialogueBox
# ============================================================
# Step 17: 2D 对话框系统
# 底部对话框 + 逐字显示 + 点击推进 + 自动模式
# ============================================================

var _full_text: String = ""
var _displayed_text: String = ""
var _char_index: int = 0
var _is_text_complete: bool = false
var _typewriter_timer: float = 0.0
var _typewriter_speed: float = 0.03
var _is_auto_mode: bool = false
var _auto_timer: Timer

# UI Nodes
var _panel: Panel
var _speaker_label: Label
var _text_label: RichTextLabel
var _next_indicator: Label
var _auto_button: Button
var _visible: bool = false

func _ready() -> void:
	EventBus.dialogue_show.connect(_on_dialogue_show)
	_build_ui()
	_create_auto_timer()
	hide()

func _build_ui() -> void:
	_panel = Panel.new()
	_panel.size = Vector2(1920, 220)
	_panel.position = Vector2(0, 860)
	_panel.hide()
	add_child(_panel)

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.05, 0.1, 0.92)
	style.set_corner_radius_all(8)
	style.content_margin_left = 30
	style.content_margin_right = 30
	style.content_margin_top = 15
	style.border_width_top = 2
	style.border_color = Color(0.8, 0.1, 0.3)
	_panel.add_theme_stylebox_override("panel", style)

	_speaker_label = Label.new()
	_speaker_label.position = Vector2(40, 15)
	_speaker_label.add_theme_color_override("font_color", Color(0.9, 0.2, 0.3))
	_speaker_label.add_theme_font_size_override("font_size", 22)
	_speaker_label.size = Vector2(400, 30)
	_panel.add_child(_speaker_label)

	_text_label = RichTextLabel.new()
	_text_label.position = Vector2(40, 55)
	_text_label.size = Vector2(1820, 140)
	_text_label.bbcode_enabled = true
	_text_label.fit_content = true
	_text_label.scroll_active = false
	_text_label.add_theme_font_size_override("normal_font_size", 20)
	_text_label.add_theme_color_override("default_color", Color(0.95, 0.95, 0.95))
	_panel.add_child(_text_label)

	_next_indicator = Label.new()
	_next_indicator.text = "▼"
	_next_indicator.position = Vector2(1860, 175)
	_next_indicator.add_theme_font_size_override("font_size", 18)
	_next_indicator.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	_next_indicator.hide()
	_panel.add_child(_next_indicator)

	_auto_button = Button.new()
	_auto_button.text = "AUTO"
	_auto_button.position = Vector2(1820, 15)
	_auto_button.size = Vector2(60, 30)
	_auto_button.add_theme_font_size_override("font_size", 12)
	_auto_button.pressed.connect(_toggle_auto_mode)
	_panel.add_child(_auto_button)

func _create_auto_timer() -> void:
	_auto_timer = Timer.new()
	_auto_timer.one_shot = true
	_auto_timer.wait_time = 2.0
	_auto_timer.timeout.connect(_on_auto_advance)
	add_child(_auto_timer)

func _on_dialogue_show(data: Dictionary) -> void:
	var speaker: String = data.get("speaker", "???")
	var speaker_label: String = data.get("speaker_label", speaker)
	_full_text = data.get("text", "")
	_displayed_text = ""
	_char_index = 0
	_is_text_complete = false

	_speaker_label.text = "【" + speaker_label + "】"
	_text_label.text = ""
	_next_indicator.hide()
	_panel.show()
	show()

	_start_typewriter()

func _start_typewriter() -> void:
	while _char_index < _full_text.length():
		_displayed_text += _full_text[_char_index]
		_char_index += 1
		_text_label.text = _displayed_text
		await get_tree().create_timer(_typewriter_speed).timeout
	_is_text_complete = true
	_next_indicator.show()

func _input(event: InputEvent) -> void:
	if not visible:
		return
	var should_advance := false
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		should_advance = true
	if event.is_action_pressed("confirm") or event.is_action_pressed("fire_evidence"):
		should_advance = true
	if should_advance:
		_advance()
		get_viewport().set_input_as_handled()

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		_advance()

func _advance() -> void:
	if not _is_text_complete:
		_displayed_text = _full_text
		_char_index = _full_text.length()
		_text_label.text = _displayed_text
		_is_text_complete = true
		_next_indicator.show()
	else:
		_next_indicator.hide()
		_panel.hide()
		hide()
		EventBus.dialogue_next.emit()

func _toggle_auto_mode() -> void:
	_is_auto_mode = not _is_auto_mode
	_auto_button.text = "AUTO" if not _is_auto_mode else "MANUAL"
	if _is_auto_mode and _is_text_complete and visible:
		_auto_timer.start()

func _on_auto_advance() -> void:
	if _is_auto_mode and _is_text_complete and visible:
		_advance()
