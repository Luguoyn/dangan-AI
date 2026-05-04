extends CharacterBody2D
class_name PlayerController
# ============================================================
# Step 14: 玩家移动控制
# WASD/方向键 8方向移动 + 鼠标点击移动 + 碰撞检测
# ============================================================

@export var speed: float = 200.0
@export var min_click_distance: float = 4.0

var _click_target: Vector2 = Vector2.INF
var _is_moving_to_click: bool = false

func _ready() -> void:
	_setup_collision()

func _setup_collision() -> void:
	var shape := CollisionShape2D.new()
	shape.shape = CircleShape2D.new()
	shape.shape.radius = 16.0
	add_child(shape)

func _physics_process(delta: float) -> void:
	var direction := Vector2.ZERO

	# 键盘移动
	direction.x = Input.get_axis("move_left", "move_right")
	direction.y = Input.get_axis("move_up", "move_down")

	if direction.length() > 0:
		direction = direction.normalized()
		velocity = direction * speed
		_is_moving_to_click = false
	else:
		velocity = Vector2.ZERO

	move_and_slide()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var click_pos := get_viewport().get_mouse_position()
		# 将屏幕坐标转换为本地坐标需要 camera
		# 简化为: 获取全局鼠标位置
		if has_node("Camera2D"):
			click_pos = get_global_mouse_position()
		_click_target = get_global_mouse_position()
		_is_moving_to_click = false
		_move_toward(_click_target)

func _move_toward(target: Vector2) -> void:
	var tween := create_tween()
	var distance := global_position.distance_to(target)
	if distance < min_click_distance:
		return
	var duration := distance / speed
	tween.tween_property(self, "global_position", target, duration)
	tween.finished.connect(func(): _is_moving_to_click = false)
