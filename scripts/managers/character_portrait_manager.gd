extends Node
# ============================================================
# Step 18: CharacterPortraitManager — 角色立绘显示系统 (Autoload)
# 管理屏幕上的角色立绘（左/中/右位置）
# ============================================================

@export var portrait_paths: Dictionary = {}
@export var default_portrait: Texture2D

const POS_LEFT := Vector2(200, 540)
const POS_CENTER := Vector2(960, 540)
const POS_RIGHT := Vector2(1720, 540)

var _active_portraits: Dictionary = {}
var _portrait_base: CanvasLayer

func _ready() -> void:
	EventBus.show_character_requested.connect(_on_show_character)
	EventBus.hide_character_requested.connect(_on_hide_character)
	_create_base_layer()

func _create_base_layer() -> void:
	_portrait_base = CanvasLayer.new()
	_portrait_base.name = "PortraitLayer"
	_portrait_base.layer = 10
	get_tree().root.add_child(_portrait_base)
	get_tree().root.move_child(_portrait_base, 0)

func _on_show_character(char_id: String, expression: String, position: String) -> void:
	_hide_character_internal(char_id)
	var rect := TextureRect.new()
	rect.name = "Portrait_" + char_id
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL

	var texture := _get_portrait_texture(char_id, expression)
	if texture:
		rect.texture = texture
		var size := texture.get_size()
		var scale_factor := 0.5
		rect.size = size * scale_factor

	match position:
		"left":   rect.position = POS_LEFT - rect.size / 2
		"right":  rect.position = POS_RIGHT - rect.size / 2
		_:        rect.position = POS_CENTER - rect.size / 2

	rect.modulate.a = 0.0
	_portrait_base.add_child(rect)
	_active_portraits[char_id] = {"node": rect, "position": position}

	var tween := rect.create_tween()
	tween.tween_property(rect, "modulate:a", 1.0, 0.3)

func _on_hide_character(char_id: String) -> void:
	_hide_character_internal(char_id)

func _hide_character_internal(char_id: String) -> void:
	if _active_portraits.has(char_id):
		var data = _active_portraits[char_id]
		var node: TextureRect = data["node"]
		if is_instance_valid(node):
			var tween := node.create_tween()
			tween.tween_property(node, "modulate:a", 0.0, 0.2)
			tween.tween_callback(node.queue_free)
		_active_portraits.erase(char_id)

func hide_all() -> void:
	for char_id in _active_portraits.keys():
		_hide_character_internal(char_id)
	_active_portraits.clear()

func set_portrait(char_id: String, expression: String, texture: Texture2D) -> void:
	if not portrait_paths.has(char_id):
		portrait_paths[char_id] = {}
	portrait_paths[char_id][expression] = texture

func _get_portrait_texture(char_id: String, expression: String) -> Texture2D:
	if portrait_paths.has(char_id) and portrait_paths[char_id].has(expression):
		return portrait_paths[char_id][expression]
	if default_portrait:
		return default_portrait
	return null

func get_active_count() -> int:
	return _active_portraits.size()
