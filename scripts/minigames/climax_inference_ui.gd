extends CanvasLayer
class_name ClimaxInferenceUI
# ============================================================
# Steps 46-48: 高潮再现推理 UI + 主逻辑
# ============================================================

signal climax_finished(success: bool)

var _config: Dictionary = {}
var _panel_slots: Array[Control] = []
var _tile_buttons: Array[Button] = []
var _selected_tile_index: int = -1
var _filled_panels: int = 0
var _time_left: float = 50.0

var _bg: ColorRect
var _title_label: Label
var _timer_bar: ProgressBar
var _panels_row: HBoxContainer
var _tiles_row: HBoxContainer

func _ready() -> void:
	_build_ui()

func start_climax(config_data: Dictionary) -> void:
	_config = config_data
	_selected_tile_index = -1
	_filled_panels = 0
	_time_left = config_data.get("time_limit", 50.0)
	_timer_bar.max_value = _time_left
	_timer_bar.value = _time_left
	_bg.show()
	show()
	_build_panels()
	_build_tiles()

func _build_ui() -> void:
	_bg = ColorRect.new()
	_bg.color = Color(0.05, 0.02, 0.08, 0.95)
	_bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_bg)

	_title_label = Label.new()
	_title_label.text = "高潮再现推理！"
	_title_label.position = Vector2(600, 30)
	_title_label.add_theme_font_size_override("font_size", 32)
	_title_label.add_theme_color_override("font_color", Color(1, 0.8, 0.2))
	add_child(_title_label)

	_timer_bar = ProgressBar.new()
	_timer_bar.position = Vector2(600, 80)
	_timer_bar.size = Vector2(400, 18)
	add_child(_timer_bar)

	_panels_row = HBoxContainer.new()
	_panels_row.position = Vector2(40, 160)
	_panels_row.add_theme_constant_override("separation", 20)
	add_child(_panels_row)

	_tiles_row = HBoxContainer.new()
	_tiles_row.position = Vector2(40, 550)
	_tiles_row.add_theme_constant_override("separation", 15)
	add_child(_tiles_row)

func _build_panels() -> void:
	for child in _panels_row.get_children():
		child.queue_free()
	_panel_slots.clear()
	var titles: Array = _config.get("panel_titles", [])
	for i in range(titles.size()):
		var panel := Control.new()
		panel.name = "Panel_%d" % i
		panel.custom_minimum_size = Vector2(200, 300)
		var pbg := ColorRect.new()
		pbg.color = Color(0.15, 0.1, 0.2)
		pbg.size = Vector2(200, 300)
		panel.add_child(pbg)
		var label := Label.new()
		label.text = titles[i]
		label.size = Vector2(190, 280)
		label.position = Vector2(5, 10)
		label.autowrap_mode = TextServer.AUTOWRAP_WORD
		label.add_theme_font_size_override("font_size", 15)
		label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
		panel.add_child(label)
		var slot_label := Label.new()
		slot_label.name = "SlotLabel"
		slot_label.text = "???"
		slot_label.position = Vector2(10, 250)
		slot_label.add_theme_font_size_override("font_size", 13)
		slot_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
		panel.add_child(slot_label)
		var btn := Button.new()
		btn.name = "PlaceBtn"
		btn.text = "放置"
		btn.position = Vector2(10, 260)
		btn.size = Vector2(180, 30)
		btn.pressed.connect(_on_place_tile.bind(i))
		panel.add_child(btn)
		_panels_row.add_child(panel)
		_panel_slots.append(panel)

func _build_tiles() -> void:
	for child in _tiles_row.get_children():
		child.queue_free()
	_tile_buttons.clear()
	var tile_texts: Array = _config.get("tile_texts", [])
	for i in range(tile_texts.size()):
		var btn := Button.new()
		btn.text = tile_texts[i]
		btn.toggle_mode = true
		btn.custom_minimum_size = Vector2(90, 50)
		btn.add_theme_font_size_override("font_size", 14)
		btn.pressed.connect(_on_tile_selected.bind(i))
		_tiles_row.add_child(btn)
		_tile_buttons.append(btn)

func _on_tile_selected(index: int) -> void:
	if _tile_buttons[index].disabled:
		return
	for i in range(_tile_buttons.size()):
		if i != index:
			_tile_buttons[i].button_pressed = false
	_selected_tile_index = index
	_title_label.text = "已选择: " + _tile_buttons[index].text + " — 点击面板放置"

func _on_place_tile(panel_index: int) -> void:
	if _selected_tile_index < 0:
		return
	var correct: Array = _config.get("correct_tile_for_panel", [])
	if panel_index >= correct.size():
		return
	if correct[panel_index] == _selected_tile_index:
		var tile := _tile_buttons[_selected_tile_index]
		tile.disabled = true
		tile.button_pressed = false
		tile.add_theme_color_override("font_color", Color(0.3, 1, 0.3))
		var slot_label := _panel_slots[panel_index].get_node("SlotLabel") as Label
		if slot_label:
			slot_label.text = tile.text
			slot_label.add_theme_color_override("font_color", Color(0.3, 1, 0.3))
		_panel_slots[panel_index].get_node("PlaceBtn").disabled = true
		_filled_panels += 1
		_selected_tile_index = -1
		_title_label.text = "正确！(%d/%d)" % [_filled_panels, correct.size()]
		if _filled_panels >= correct.size():
			_complete(true)
	else:
		_tile_buttons[_selected_tile_index].button_pressed = false
		_selected_tile_index = -1
		_title_label.text = "错误！-5 HP"
		DebateManager.damage_hp(5)
		if DebateManager.current_hp <= 0:
			_complete(false)

func _process(delta: float) -> void:
	_time_left -= delta
	if _time_left <= 0:
		_complete(false)
	_timer_bar.value = _time_left

func _complete(success: bool) -> void:
	var tween := create_tween()
	tween.tween_property(_bg, "color:a", 0.0, 0.5)
	tween.tween_callback(queue_free)
	climax_finished.emit(success)
	EventBus.climax_inference_finished.emit(success)
