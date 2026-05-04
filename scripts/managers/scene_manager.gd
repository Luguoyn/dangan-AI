extends Node
# ============================================================
# SceneManager — 场景加载/切换管理 (Autoload)
# ============================================================

var _current_scene_id: String = ""
var _scene_registry: Dictionary = {}
var _is_loading: bool = false

signal transition_started
signal transition_finished(new_scene_id: String)

func _ready() -> void:
	EventBus.scene_load_requested.connect(_on_scene_load_requested)

func register_scene(scene_id: String, scene_path: String) -> void:
	_scene_registry[scene_id] = scene_path

func load_scene(scene_id: String, transition: String = "fade") -> void:
	if _is_loading:
		return
	if not _scene_registry.has(scene_id):
		push_error("SceneManager: Unknown scene_id: " + scene_id)
		return

	var path = _scene_registry[scene_id]
	_is_loading = true
	transition_started.emit()
	await _play_transition_out(transition)
	await _load_scene_internal(path)
	_current_scene_id = scene_id
	await _play_transition_in(transition)
	_is_loading = false
	transition_finished.emit(scene_id)
	EventBus.scene_loaded.emit(scene_id)

func load_scene_direct(path: String, transition: String = "fade") -> void:
	if _is_loading:
		return
	_is_loading = true
	transition_started.emit()
	await _play_transition_out(transition)
	await _load_scene_internal(path)
	_current_scene_id = path.get_file().get_basename()
	await _play_transition_in(transition)
	_is_loading = false
	transition_finished.emit(_current_scene_id)
	EventBus.scene_loaded.emit(_current_scene_id)

func get_current_scene_id() -> String:
	return _current_scene_id

func _load_scene_internal(path: String) -> void:
	var loader = ResourceLoader.load_threaded_request(path, "", true)
	if loader == null:
		push_error("SceneManager: Failed to load scene: " + path)
		return

	while true:
		var status = ResourceLoader.load_threaded_get_status(path)
		match status:
			ResourceLoader.THREAD_LOAD_LOADED:
				break
			ResourceLoader.THREAD_LOAD_FAILED:
				push_error("SceneManager: Failed to load: " + path)
				return
		await get_tree().process_frame

	var scene = ResourceLoader.load_threaded_get(path)
	get_tree().change_scene_to_packed(scene)

func _play_transition_out(transition: String) -> void:
	if transition == "instant":
		return
	_create_transition_overlay()
	var overlay = get_node_or_null("/root/TransitionOverlay")
	if overlay == null:
		return
	if transition == "fade":
		overlay.modulate.a = 0.0
		overlay.show()
		var tween = create_tween()
		tween.tween_property(overlay, "modulate:a", 1.0, 0.5)

func _play_transition_in(transition: String) -> void:
	if transition == "instant":
		return
	var overlay = get_node_or_null("/root/TransitionOverlay")
	if overlay == null:
		return
	if transition == "fade":
		var tween = create_tween()
		tween.tween_property(overlay, "modulate:a", 0.0, 0.5)
		await tween.finished
		overlay.hide()

func _create_transition_overlay() -> void:
	if has_node("/root/TransitionOverlay"):
		return
	var overlay = ColorRect.new()
	overlay.name = "TransitionOverlay"
	overlay.color = Color.BLACK
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.hide()
	get_tree().root.add_child(overlay)

func _on_scene_load_requested(scene_path: String) -> void:
	load_scene_direct(scene_path)
