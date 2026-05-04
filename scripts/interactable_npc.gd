extends Area2D
class_name InteractableNPC
# ============================================================
# Step 15: NPC 交互系统
# 玩家靠近时显示提示，按键触发对话
# ============================================================

@export var character_id: String = ""
@export var interaction_range: float = 80.0
@export var prompt_offset: Vector2 = Vector2(0, -40)

var _player: PlayerController
var _prompt_label: Label
var _can_interact: bool = false

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	_create_prompt()
	_add_collision_body()

func _add_collision_body() -> void:
	var static_body := StaticBody2D.new()
	static_body.name = "CollisionBody"
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 24.0
	shape.shape = circle
	static_body.add_child(shape)
	add_child(static_body)

func _create_prompt() -> void:
	_prompt_label = Label.new()
	_prompt_label.text = "[E] 对话"
	_prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_prompt_label.add_theme_font_size_override("font_size", 14)
	_prompt_label.add_theme_color_override("font_color", Color.WHITE)
	_prompt_label.position = prompt_offset
	_prompt_label.hide()
	add_child(_prompt_label)

func _on_body_entered(body: Node2D) -> void:
	if body is PlayerController:
		_player = body
		_can_interact = true
		_prompt_label.show()

func _on_body_exited(body: Node2D) -> void:
	if body is PlayerController:
		_player = null
		_can_interact = false
		_prompt_label.hide()

func _input(event: InputEvent) -> void:
	if not _can_interact:
		return
	if event.is_action_pressed("interact"):
		if ScriptInterpreter.is_executing or ScriptInterpreter.is_waiting_input:
			return
		EventBus.npc_interacted.emit(character_id)
		_prompt_label.hide()
		await get_tree().create_timer(1.0).timeout
		if _can_interact:
			_prompt_label.show()

func get_character_id() -> String:
	return character_id
