extends Node
# ============================================================
# MainGame — 2D 场景总控 (Autoload)
# 创建玩家、NPC、调查点、UI 层，连接各系统
# ============================================================

var _world: Node2D
var _player: PlayerController
var _dialogue_box: DialogueBox
var _choice_panel: ChoicePanel
var _screen_effects: ScreenEffects
var _npcs: Array[InteractableNPC] = []
var _investigation_points: Array[InvestigationPoint] = []

func _ready() -> void:
	_world = Node2D.new()
	_world.name = "GameWorld"
	add_child(_world)
	_create_2d_world()
	_create_ui_layers()
	_connect_signals()
	_place_demo_content()
	print("[MainGame] 2D 场景初始化完成。WASD/方向键移动，E键互动，T键进入裁判场。")

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.keycode == KEY_T and event.pressed:
		if ScriptInterpreter.is_executing or ScriptInterpreter.is_waiting_input:
			return
		if SceneManager.get_current_scene_id() == "courtroom_3d":
			return
		SceneManager.load_scene_direct("res://scenes/3d/courtroom.tscn")

func _create_2d_world() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.15, 0.12, 0.18)
	bg.size = Vector2(1920, 1080)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_world.add_child(bg)

	var floor := ColorRect.new()
	floor.color = Color(0.2, 0.16, 0.22)
	floor.size = Vector2(1600, 800)
	floor.position = Vector2(160, 200)
	floor.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_world.add_child(floor)

	var grid_lines := _create_grid(160, 200, 1600, 800)
	_world.add_child(grid_lines)

	var cam := Camera2D.new()
	cam.enabled = true
	cam.zoom = Vector2(1, 1)

	_player = PlayerController.new()
	_player.position = Vector2(960, 700)

	var player_sprite := ColorRect.new()
	player_sprite.color = Color(0.2, 0.8, 0.4)
	player_sprite.size = Vector2(32, 48)
	player_sprite.position = Vector2(-16, -40)
	_player.add_child(player_sprite)

	var player_label := Label.new()
	player_label.text = "苗木"
	player_label.position = Vector2(-12, 12)
	player_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	player_label.add_theme_font_size_override("font_size", 11)
	player_label.add_theme_color_override("font_color", Color(0.2, 0.9, 0.5))
	_player.add_child(player_label)

	_player.add_child(cam)
	_world.add_child(_player)

func _create_grid(x: float, y: float, w: float, h: float) -> Node2D:
	var grid := Node2D.new()
	var step := 80.0
	var col := Color(0.25, 0.2, 0.28, 0.3)
	var cx := x
	while cx <= x + w:
		var line := ColorRect.new()
		line.color = col
		line.size = Vector2(1, h)
		line.position = Vector2(cx - x, 0)
		line.mouse_filter = Control.MOUSE_FILTER_IGNORE
		grid.add_child(line)
		cx += step
	var cy := y
	while cy <= y + h:
		var line := ColorRect.new()
		line.color = col
		line.size = Vector2(w, 1)
		line.position = Vector2(0, cy - y)
		line.mouse_filter = Control.MOUSE_FILTER_IGNORE
		grid.add_child(line)
		cy += step
	grid.position = Vector2(x, y)
	return grid

func _create_ui_layers() -> void:
	_dialogue_box = DialogueBox.new()
	add_child(_dialogue_box)

	_choice_panel = ChoicePanel.new()
	add_child(_choice_panel)

	_screen_effects = ScreenEffects.new()
	add_child(_screen_effects)

func _place_demo_content() -> void:
	_add_npc("kirigiri", Vector2(600, 600))
	_add_npc("asahina", Vector2(800, 500))
	_add_npc("togami", Vector2(1200, 550))

	_add_investigation_point("desk_01", Vector2(400, 650))
	_add_investigation_point("cabinet_01", Vector2(1400, 700))
	_add_investigation_point("evidence_01", Vector2(960, 400))

func _add_npc(char_id: String, pos: Vector2) -> void:
	var cd := CharacterManager.get_character(char_id)
	var display_name := char_id
	var npc_color := Color(0.5, 0.5, 0.5)
	if cd:
		display_name = cd.display_name
		npc_color = cd.color

	var npc := InteractableNPC.new()
	npc.character_id = char_id
	npc.position = pos

	var sprite := ColorRect.new()
	sprite.color = npc_color
	sprite.size = Vector2(40, 60)
	sprite.position = Vector2(-20, -50)
	npc.add_child(sprite)

	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 60
	shape.shape = circle
	npc.add_child(shape)

	var name_label := Label.new()
	name_label.text = display_name
	name_label.position = Vector2(-30, 20)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 12)
	name_label.add_theme_color_override("font_color", Color.WHITE)
	npc.add_child(name_label)

	_world.add_child(npc)
	_npcs.append(npc)

func _add_investigation_point(point_id: String, pos: Vector2) -> void:
	var point := InvestigationPoint.new()
	point.point_id = point_id
	point.position = pos

	var sprite := ColorRect.new()
	sprite.color = Color(0.3, 0.8, 0.3, 0.5)
	sprite.size = Vector2(30, 30)
	sprite.position = Vector2(-15, -15)
	point.add_child(sprite)

	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(60, 60)
	shape.shape = rect
	point.add_child(shape)

	var id_label := Label.new()
	id_label.text = point_id
	id_label.position = Vector2(-25, 20)
	id_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	id_label.add_theme_font_size_override("font_size", 10)
	id_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	point.add_child(id_label)

	_world.add_child(point)
	_investigation_points.append(point)

func _connect_signals() -> void:
	EventBus.npc_interacted.connect(_on_npc_interacted)
	EventBus.investigation_point_clicked.connect(_on_investigation_point_clicked)
	EventBus.scene_loaded.connect(_on_scene_changed)

var _ui_active: bool = true

func _on_scene_changed(scene_id: String) -> void:
	if scene_id != "main":
		_ui_active = false
		if _dialogue_box:
			_dialogue_box.hide()
			if EventBus.dialogue_show.is_connected(_dialogue_box._on_dialogue_show):
				EventBus.dialogue_show.disconnect(_dialogue_box._on_dialogue_show)
		if _choice_panel:
			_choice_panel.hide()
		if _screen_effects:
			_screen_effects.hide()
		if _world:
			_world.hide()
	else:
		_ui_active = true
		if _dialogue_box and not EventBus.dialogue_show.is_connected(_dialogue_box._on_dialogue_show):
			EventBus.dialogue_show.connect(_dialogue_box._on_dialogue_show)
		if _world:
			_world.show()

func _on_npc_interacted(char_id: String) -> void:
	print("[NPC] 与 %s 对话" % char_id)
	var script_map := {
		"kirigiri": "res://story/demo_interaction.script.json",
		"asahina":  "res://story/demo_asahina.script.json",
		"togami":   "res://story/demo_togami.script.json",
	}
	var script_path: String = script_map.get(char_id, "res://story/demo_interaction.script.json")
	if FileAccess.file_exists(script_path):
		ScriptInterpreter.load_script(script_path)
	else:
		EventBus.dialogue_show.emit({
			"speaker": "system",
			"speaker_label": "系统",
			"text": "（剧本文件未找到: %s）" % script_path
		})

func _on_investigation_point_clicked(point_id: String) -> void:
	print("[调查] 调查点: %s" % point_id)

	var ev_data := {
		"id": "ev_" + point_id,
		"name": "调查发现: " + point_id,
		"description": "在 %s 处发现了可疑物品。" % point_id,
		"type": "physical"
	}
	EvidenceManager.add_evidence(ev_data)

	var msg := {
		"speaker": "narrator",
		"speaker_label": "系统",
		"text": "发现了新的证据！[%s] 已添加到言弹列表。" % point_id,
		"expression": "normal"
	}
	EventBus.dialogue_show.emit(msg)

func get_player() -> PlayerController:
	return _player
