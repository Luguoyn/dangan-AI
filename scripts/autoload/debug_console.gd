extends Node
# ============================================================
# Step 59: DebugConsole — 调试控制台 (Autoload)
# ============================================================

var _console_visible: bool = false
var _input_line: LineEdit
var _output_label: RichTextLabel
var _panel: Panel
var _quick_buttons: Array[Button] = []

func _ready() -> void:
	_build_console()

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.keycode == KEY_QUOTELEFT and event.pressed:
		_toggle()

func _toggle() -> void:
	_console_visible = not _console_visible
	_panel.visible = _console_visible
	if _console_visible:
		_input_line.grab_focus()
		_refresh_status()

func _build_console() -> void:
	_panel = Panel.new()
	_panel.size = Vector2(600, 400)
	_panel.position = Vector2(30, 640)
	_panel.visible = false
	add_child(_panel)

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0.9)
	style.set_corner_radius_all(6)
	_panel.add_theme_stylebox_override("panel", style)

	_output_label = RichTextLabel.new()
	_output_label.position = Vector2(10, 10)
	_output_label.size = Vector2(580, 300)
	_output_label.bbcode_enabled = true
	_output_label.add_theme_font_size_override("normal_font_size", 13)
	_panel.add_child(_output_label)

	_input_line = LineEdit.new()
	_input_line.position = Vector2(10, 320)
	_input_line.size = Vector2(520, 30)
	_input_line.placeholder_text = "输入命令..."
	_input_line.text_submitted.connect(_on_command)
	_panel.add_child(_input_line)

	var btns := ["+HP 50", "全证据", "好感+10", "跳裁判", "清日志"]
	for i in range(btns.size()):
		var btn := Button.new()
		btn.text = btns[i]
		btn.size = Vector2(90, 25)
		btn.position = Vector2(10 + i * 105, 355)
		btn.add_theme_font_size_override("font_size", 11)
		btn.pressed.connect(_on_quick.bind(i))
		_panel.add_child(btn)
		_quick_buttons.append(btn)

func _on_command(text: String) -> void:
	var parts := text.strip_edges().split(" ", false)
	if parts.is_empty():
		return
	var cmd := parts[0].to_lower()
	match cmd:
		"hp":
			DebateManager.current_hp = clampi(int(parts[1]) if parts.size() > 1 else 100, 0, DebateManager.max_hp)
			EventBus.hp_changed.emit(DebateManager.current_hp, DebateManager.max_hp)
		"all_evidence":
			for ev in ["ev_knife_01", "ev_clock_01", "ev_test_01", "ev_desk_01"]:
				EvidenceManager.add_evidence({"id": ev, "name": ev, "description": "调试证据", "type": "physical"})
		"affection":
			if parts.size() >= 3:
				GameManager.add_affection(parts[1], int(parts[2]))
		"skill":
			if parts.size() >= 2:
				GameManager.unlock_skill(parts[1])
		"goto":
			if parts.size() >= 2:
				SceneManager.load_scene_direct("res://scenes/" + parts[1])
		"script":
			if parts.size() >= 2:
				ScriptInterpreter.load_script("res://story/" + parts[1])
		"flag":
			if parts.size() >= 2:
				GameManager.set_flag(parts[1])
		"log":
			Logger.export_to_file()
		_:
			_output_label.text += "\n[color=red]未知命令: %s[/color]" % cmd
	_refresh_status()
	_input_line.clear()

func _on_quick(index: int) -> void:
	match index:
		0: _on_command("hp 100")
		1: _on_command("all_evidence")
		2: _on_command("affection kirigiri 10")
		3: SceneManager.load_scene_direct("res://scenes/3d/courtroom.tscn")
		4: Logger._log_entries.clear()

func _refresh_status() -> void:
	var hp := "HP: %d/%d" % [DebateManager.current_hp, DebateManager.max_hp]
	var ev := "证据: %d" % EvidenceManager.get_evidence_count()
	var flags := "旗标: %d" % GameManager.flags.size()
	var aff := "好感: %d角色" % GameManager.get_all_affection().size()
	_output_label.text = "[color=yellow]%s | %s | %s | %s[/color]" % [hp, ev, flags, aff]
