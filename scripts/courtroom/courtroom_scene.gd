extends Node3D
class_name CourtroomScene
# ============================================================
# Step 24+27: 3D 学级裁判场场景
# 构建 CSG 几何体、分配角色站位、管理摄像机
# ============================================================

const PODIUM_COUNT := 16
const STAGE_RADIUS := 6.0

var _camera: CourtroomCamera
var _podiums: Array[PodiumSlot] = []
var _dialogue_box: DialogueBox
var _hp_bar: HPBar
var _dialogue_box_added: bool = false
var _hp_bar_added: bool = false

func _ready() -> void:
	_build_environment()
	_build_stage()
	_build_camera()
	_build_podiums()
	_build_ui()
	_assign_characters_to_podiums()
	EventBus.trial_started.emit()
	print("[CourtroomScene] 裁判场初始化完成，%d 个站位已分配，按B返回2D场景" % PODIUM_COUNT)

func _input(event: InputEvent) -> void:
	if ScriptInterpreter.is_executing or ScriptInterpreter.is_waiting_input:
		return
	if event is InputEventKey:
		if event.keycode == KEY_B and event.pressed:
			SceneManager.load_scene("main")
		if event.keycode == KEY_SPACE and event.pressed:
			show_hp_bar()
			ScriptInterpreter.load_script("res://story/courtroom_test.script.json")

func _build_environment() -> void:
	var env := WorldEnvironment.new()
	var sky := PanoramaSkyMaterial.new()
	sky.sky_top_color = Color(0.02, 0.01, 0.05)
	sky.sky_horizon_color = Color(0.05, 0.02, 0.08)
	sky.ground_bottom_color = Color(0.08, 0.03, 0.1)
	env.environment = Environment.new()
	env.environment.sky = Sky.new()
	env.environment.sky.sky_material = sky
	env.environment.background_mode = Environment.BG_SKY
	env.environment.ambient_light_color = Color(0.15, 0.1, 0.2)
	env.environment.ambient_light_energy = 0.5
	env.environment.fog_enabled = true
	env.environment.fog_density = 0.01
	env.environment.fog_light_color = Color(0.4, 0.2, 0.4)
	add_child(env)

	var dir_light := DirectionalLight3D.new()
	dir_light.position = Vector3(5, 15, 5)
	dir_light.light_energy = 0.4
	dir_light.light_color = Color(0.9, 0.85, 0.95)
	add_child(dir_light)

	var spot1 := SpotLight3D.new()
	spot1.position = Vector3(-8, 12, 0)
	spot1.look_at(Vector3(0, 1, 0))
	spot1.light_color = Color(1, 0.8, 0.9)
	spot1.light_energy = 1.5
	add_child(spot1)

	var spot2 := SpotLight3D.new()
	spot2.position = Vector3(8, 12, 0)
	spot2.look_at(Vector3(0, 1, 0))
	spot2.light_color = Color(0.8, 0.8, 1)
	spot2.light_energy = 1.5
	add_child(spot2)

func _build_stage() -> void:
	var floor_mat := StandardMaterial3D.new()
	floor_mat.albedo_color = Color(0.08, 0.06, 0.1)

	var floor := CSGCylinder3D.new()
	floor.radius = 8.0
	floor.height = 0.3
	floor.position = Vector3(0, -0.15, 0)
	floor.material = floor_mat
	add_child(floor)

	var pillar := CSGCylinder3D.new()
	pillar.radius = 1.2
	pillar.height = 3.0
	pillar.position = Vector3(0, 1.5, 0)
	pillar.material = _make_metal_mat(Color(0.3, 0.1, 0.3))
	add_child(pillar)

	var throne := CSGBox3D.new()
	throne.size = Vector3(2.0, 1.5, 2.0)
	throne.position = Vector3(0, 3.7, 0)
	throne.material = _make_metal_mat(Color(0.5, 0.0, 0.0))
	add_child(throne)

	for i in range(0, 360, 45):
		var angle := deg_to_rad(float(i))
		var railing := CSGBox3D.new()
		railing.size = Vector3(0.2, 1.2, 0.15)
		var rx := cos(angle) * (STAGE_RADIUS + 0.5)
		var rz := sin(angle) * (STAGE_RADIUS + 0.5)
		railing.position = Vector3(rx, 0.6, rz)
		railing.look_at(Vector3(0, 0.6, 0), Vector3.UP)
		railing.material = _make_metal_mat(Color(0.2, 0.15, 0.2))
		add_child(railing)

func _build_camera() -> void:
	_camera = CourtroomCamera.new()
	_camera.name = "CourtroomCamera"
	_camera.default_position = Vector3(0, 9, 14)
	_camera.default_look_at = Vector3(0, 1.5, 0)
	add_child(_camera)

func _build_podiums() -> void:
	for i in range(PODIUM_COUNT):
		var podium := PodiumSlot.new()
		podium.podium_index = i
		var angle := TAU * float(i) / float(PODIUM_COUNT)
		podium.position = Vector3(cos(angle) * STAGE_RADIUS, 0, sin(angle) * STAGE_RADIUS)
		podium.rotation_degrees.y = rad_to_deg(-angle) + 90
		add_child(podium)
		_podiums.append(podium)

		var marker := CSGBox3D.new()
		marker.size = Vector3(0.8, 0.1, 0.8)
		marker.position = Vector3(cos(angle) * STAGE_RADIUS, 0.05, sin(angle) * STAGE_RADIUS)
		marker.material = _make_metal_mat(Color(0.25, 0.15, 0.25))
		add_child(marker)

func _build_ui() -> void:
	EventBus.dialogue_show.connect(_on_dialogue_show)
	EventBus.dialogue_next.connect(_on_dialogue_next)
	EventBus.trial_ended.connect(_on_trial_ended_scene)

	_dialogue_box = DialogueBox.new()
	add_child(_dialogue_box)

	_hp_bar = HPBar.new()
	add_child(_hp_bar)

func _on_dialogue_show(data: Dictionary) -> void:
	var speaker: String = data.get("speaker", "")
	if speaker != "" and speaker != "narrator":
		clear_highlights()
		move_camera_to_speaker(speaker)

func _on_dialogue_next() -> void:
	clear_highlights()

func _on_trial_ended_scene(result: String) -> void:
	print("[Courtroom] 裁判结束: %s" % result)
	await get_tree().create_timer(2.0).timeout
	SceneManager.load_scene("main")

func _assign_characters_to_podiums() -> void:
	var alive := CharacterManager.get_alive_characters()
	if alive.is_empty():
		for i in range(mini(PODIUM_COUNT, 3)):
			var demo_ids := ["kirigiri", "asahina", "togami"]
			if i < demo_ids.size():
				_podiums[i].assign_character(demo_ids[i])
		return

	for i in range(mini(PODIUM_COUNT, alive.size())):
		_podiums[i].assign_character(alive[i].character_id)

func move_camera_to_speaker(char_id: String, shot_type: String = "closeup") -> void:
	for podium in _podiums:
		if podium.character_id == char_id:
			_camera.move_to_podium(podium.podium_index, shot_type)
			podium.highlight(true)
			return

func clear_highlights() -> void:
	for podium in _podiums:
		podium.highlight(false)

func get_podium(character_id: String) -> PodiumSlot:
	for p in _podiums:
		if p.character_id == character_id:
			return p
	return null

func get_camera() -> CourtroomCamera:
	return _camera

func show_hp_bar() -> void:
	_hp_bar.show_bar()

func hide_hp_bar() -> void:
	_hp_bar.hide_bar()

func _make_metal_mat(color: Color) -> Material:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.metallic = 0.8
	mat.roughness = 0.1
	return mat
