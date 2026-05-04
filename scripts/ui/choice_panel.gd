extends CanvasLayer
class_name ChoicePanel
# ============================================================
# Step 19: 分支选项 UI
# 显示提示 + 2-4 选项按钮 + 键盘/鼠标支持
# ============================================================

var _choices: Array = []
var _buttons: Array[Button] = []
var _selected_index: int = 0
var _bg: ColorRect
var _prompt_label: Label
var _button_container: VBoxContainer

func _ready() -> void:
	EventBus.choice_presented.connect(_on_choice_presented)
	_build_ui()
	hide()

func _build_ui() -> void:
	_bg = ColorRect.new()
	_bg.color = Color(0, 0, 0, 0.6)
	_bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bg.hide()
	add_child(_bg)

	var center := Panel.new()
	center.size = Vector2(600, 300)
	center.position = Vector2(660, 390)
	center.add_theme_stylebox_override("panel", _make_panel_style())
	center.hide()
	_bg.add_child(center)

	_prompt_label = Label.new()
	_prompt_label.position = Vector2(20, 20)
	_prompt_label.size = Vector2(560, 50)
	_prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_prompt_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_prompt_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	_prompt_label.add_theme_font_size_override("font_size", 22)
	_prompt_label.add_theme_color_override("font_color", Color.WHITE)
	center.add_child(_prompt_label)

	_button_container = VBoxContainer.new()
	_button_container.position = Vector2(30, 85)
	_button_container.size = Vector2(540, 200)
	_button_container.add_theme_constant_override("separation", 8)
	center.add_child(_button_container)

func _make_panel_style() -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = Color(0.08, 0.08, 0.15, 0.95)
	s.set_corner_radius_all(12)
	s.border_width_top = 2
	s.border_color = Color(0.8, 0.2, 0.4)
	return s

func _on_choice_presented(data: Dictionary) -> void:
	_choices = data.get("choices", [])
	var prompt: String = data.get("prompt", "")
	_selected_index = 0

	_prompt_label.text = prompt

	for b in _buttons:
		b.queue_free()
	_buttons.clear()

	for i in range(_choices.size()):
		var choice := _choices[i] as Dictionary
		var btn := Button.new()
		btn.text = choice.get("text", "Option %d" % i)
		btn.size_flags_horizontal = Control.SIZE_FILL
		btn.custom_minimum_size = Vector2(0, 42)
		btn.add_theme_font_size_override("font_size", 18)
		btn.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
		btn.pressed.connect(_on_button_pressed.bind(i))
		_button_container.add_child(btn)
		_buttons.append(btn)

	_highlight_selection()
	_bg.show()
	show()

func _highlight_selection() -> void:
	for i in range(_buttons.size()):
		if i == _selected_index:
			_buttons[i].add_theme_color_override("font_color", Color(1, 0.8, 0.2))
			_buttons[i].add_theme_font_size_override("font_size", 20)
		else:
			_buttons[i].add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
			_buttons[i].add_theme_font_size_override("font_size", 18)

func _input(event: InputEvent) -> void:
	if not visible:
		return

	if event.is_action_pressed("move_up"):
		_selected_index = max(0, _selected_index - 1)
		_highlight_selection()
		get_viewport().set_input_as_handled()

	elif event.is_action_pressed("move_down"):
		_selected_index = min(_buttons.size() - 1, _selected_index + 1)
		_highlight_selection()
		get_viewport().set_input_as_handled()

	elif event.is_action_pressed("confirm"):
		_confirm_selection()
		get_viewport().set_input_as_handled()

	elif event.is_action_pressed("cancel"):
		_confirm_selection()

func _on_button_pressed(index: int) -> void:
	_selected_index = index
	_confirm_selection()

func _confirm_selection() -> void:
	_bg.hide()
	hide()
	EventBus.choice_made.emit(_selected_index)
