extends CanvasLayer
class_name HPBar
# ============================================================
# Step 30: 精神力 HP 血条显示
# ============================================================

@export var max_hp: int = 100
var current_hp: int = 100

var _bg: ColorRect
var _fill: ColorRect
var _label: Label
var _hearts_label: Label
var _visible: bool = false

func _ready() -> void:
	EventBus.hp_changed.connect(_on_hp_changed)
	EventBus.hp_depleted.connect(_on_hp_depleted)
	_build_ui()
	hide()

func _build_ui() -> void:
	_bg = ColorRect.new()
	_bg.color = Color(0.1, 0.1, 0.1, 0.8)
	_bg.size = Vector2(300, 30)
	_bg.position = Vector2(30, 30)
	add_child(_bg)

	_fill = ColorRect.new()
	_fill.color = Color(0.2, 0.9, 0.4)
	_fill.size = Vector2(296, 26)
	_fill.position = Vector2(32, 32)
	add_child(_fill)

	_label = Label.new()
	_label.position = Vector2(40, 30)
	_label.add_theme_font_size_override("font_size", 16)
	_label.add_theme_color_override("font_color", Color.WHITE)
	_label.text = "精神力"
	add_child(_label)

	_hearts_label = Label.new()
	_hearts_label.position = Vector2(180, 30)
	_hearts_label.add_theme_font_size_override("font_size", 16)
	_hearts_label.add_theme_color_override("font_color", Color(1, 0.4, 0.6))
	add_child(_hearts_label)

func set_hp(hp: int, max_val: int = -1) -> void:
	if max_val > 0:
		max_hp = max_val
	current_hp = clampi(hp, 0, max_hp)
	_update_display()

func _on_hp_changed(current: int, _max: int) -> void:
	current_hp = clampi(current, 0, max_hp)
	_update_display()
	_flash_bar()

func _on_hp_depleted() -> void:
	current_hp = 0
	_fill.color = Color(0.9, 0.1, 0.1)
	_update_display()

func _update_display() -> void:
	var ratio := float(current_hp) / float(max_hp)
	_fill.size.x = 296.0 * ratio

	if ratio > 0.5:
		_fill.color = _fill.color.lerp(Color(0.2, 0.9, 0.4), 0.3)
	elif ratio > 0.25:
		_fill.color = _fill.color.lerp(Color(0.9, 0.7, 0.2), 0.3)
	else:
		_fill.color = _fill.color.lerp(Color(0.9, 0.1, 0.1), 0.3)

	_hearts_label.text = "HP %d/%d" % [current_hp, max_hp]

func _flash_bar() -> void:
	var tween := create_tween()
	tween.tween_property(_fill, "modulate:a", 0.3, 0.1)
	tween.tween_property(_fill, "modulate:a", 1.0, 0.1)

func show_bar() -> void:
	show()
	_visible = true

func hide_bar() -> void:
	hide()
	_visible = false
