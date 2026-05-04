extends CanvasLayer
class_name SkillSelectPanel
# ============================================================
# Step 50: 技能选择面板
# ============================================================

signal skills_confirmed(selected_ids: Array)

var _skills: Array = []
var _selected: Array = []
var _max_sp: int = 5

var _bg: ColorRect
var _title: Label
var _container: VBoxContainer
var _confirm_btn: Button

func _ready() -> void:
	EventBus.skill_select_requested.connect(_on_skill_select_requested)
	_build_ui()
	hide()

func _build_ui() -> void:
	_bg = ColorRect.new()
	_bg.color = Color(0, 0, 0, 0.8)
	_bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_bg)

	_title = Label.new()
	_title.text = "选择技能 (剩余SP: 5)"
	_title.position = Vector2(600, 100)
	_title.add_theme_font_size_override("font_size", 26)
	_title.add_theme_color_override("font_color", Color(1, 0.8, 0.2))
	add_child(_title)

	_container = VBoxContainer.new()
	_container.position = Vector2(500, 160)
	_container.custom_minimum_size = Vector2(600, 400)
	add_child(_container)

	_confirm_btn = Button.new()
	_confirm_btn.text = "确认"
	_confirm_btn.position = Vector2(800, 600)
	_confirm_btn.size = Vector2(200, 45)
	_confirm_btn.add_theme_font_size_override("font_size", 20)
	_confirm_btn.pressed.connect(_on_confirm)
	add_child(_confirm_btn)

func _on_skill_select_requested() -> void:
	_skills = GameManager.get_unlocked_skills()
	_selected.clear()
	_refresh_list()
	show()

func _refresh_list() -> void:
	for child in _container.get_children():
		child.queue_free()

	var presets := {
		"voice_beauty": {"name": "美声", "desc": "无休止议论中准星范围扩大30%", "sp": 2},
		"focus": {"name": "专注", "desc": "拼字时间+10秒", "sp": 1},
		"keen_eye": {"name": "锐眼", "desc": "高潮再现错误扣HP减半", "sp": 2},
		"iron_will": {"name": "铁壁", "desc": "反论判定容差+20%", "sp": 2},
		"flash_insight": {"name": "一闪", "desc": "无休止议论中自动高亮目标1秒", "sp": 3},
	}

	var used_sp := 0
	for sid in _selected:
		var info = presets.get(sid, {})
		used_sp += info.get("sp", 1)

	_title.text = "选择技能 (剩余SP: %d)" % (_max_sp - used_sp)

	for sid in _skills:
		var info = presets.get(sid, {"name": sid, "desc": "", "sp": 1})
		var btn := Button.new()
		btn.text = "[%s SP:%d] %s - %s" % [info["name"], info["sp"], info["desc"], "✓" if sid in _selected else ""]
		btn.size_flags_horizontal = Control.SIZE_FILL
		btn.custom_minimum_size = Vector2(0, 40)
		btn.pressed.connect(_on_skill_toggle.bind(sid, info["sp"]))
		_container.add_child(btn)

func _on_skill_toggle(skill_id: String, sp: int) -> void:
	if skill_id in _selected:
		_selected.erase(skill_id)
	else:
		var used := 0
		for sid in _selected:
			var presets = {"voice_beauty": 2, "focus": 1, "keen_eye": 2, "iron_will": 2, "flash_insight": 3}
			used += presets.get(sid, 1)
		if used + sp <= _max_sp:
			_selected.append(skill_id)
	_refresh_list()

func _on_confirm() -> void:
	EventBus.skill_selected.emit(_selected)
	hide()
