extends Area2D
class_name InvestigationPoint
# ============================================================
# Step 16: 调查点系统
# 玩家靠近时高亮，点击触发调查
# ============================================================

@export var point_id: String = ""
@export var interaction_range: float = 60.0
@export var is_one_shot: bool = true
@export var has_collision: bool = true

var _player: PlayerController
var _highlight: ColorRect
var _investigated: bool = false
var _can_interact: bool = false

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	_create_highlight()
	_add_collision_body()

func _add_collision_body() -> void:
	if not has_collision:
		return
	var static_body := StaticBody2D.new()
	static_body.name = "CollisionBody"
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(40, 40)
	shape.shape = rect
	static_body.add_child(shape)
	add_child(static_body)

func _create_highlight() -> void:
	_highlight = ColorRect.new()
	_highlight.color = Color(1, 1, 0, 0.3)
	_highlight.size = Vector2(32, 32)
	_highlight.position = Vector2(-16, -16)
	_highlight.hide()
	add_child(_highlight)

func _on_body_entered(body: Node2D) -> void:
	if body is PlayerController:
		_player = body
		_can_interact = true
		if not _investigated:
			_highlight.show()

func _on_body_exited(body: Node2D) -> void:
	if body is PlayerController:
		_player = null
		_can_interact = false
		_highlight.hide()

func _input(event: InputEvent) -> void:
	if not _can_interact or _investigated:
		return
	if event.is_action_pressed("interact"):
		if ScriptInterpreter.is_executing or ScriptInterpreter.is_waiting_input:
			return
		_investigated = true
		if is_one_shot:
			_highlight.hide()
		EventBus.investigation_point_clicked.emit(point_id)

func get_point_id() -> String:
	return point_id

func reset_point() -> void:
	_investigated = false
	if _can_interact:
		_highlight.show()
