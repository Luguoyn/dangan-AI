extends Node
# ============================================================
# ScriptInterpreter — 剧本解释器 (Autoload)
# 读取 JSON 剧本文件，逐条执行指令
# ============================================================

# --- 脚本执行状态 ---
var current_script: Array = []
var current_index: int = 0
var is_waiting_input: bool = false
var is_auto_mode: bool = false
var is_executing: bool = false

# --- 内部状态 ---
var _auto_timer: Timer
var _pending_choice_data: Dictionary = {}
var _pending_minigame_on_success: String = ""
var _pending_minigame_on_fail: String = ""
var _pending_save_prompt: bool = false
var _script_path: String = ""
var _script_id: String = ""

# --- 指令处理器映射 ---
var _handlers: Dictionary = {}

func _ready() -> void:
	_create_auto_timer()
	_register_handlers()
	_connect_signals()

func _create_auto_timer() -> void:
	_auto_timer = Timer.new()
	_auto_timer.name = "AutoTimer"
	_auto_timer.wait_time = 2.0
	_auto_timer.one_shot = true
	_auto_timer.timeout.connect(_on_auto_advance)
	add_child(_auto_timer)

func _connect_signals() -> void:
	EventBus.dialogue_next.connect(_on_dialogue_next)
	EventBus.choice_made.connect(_on_choice_made)
	EventBus.nonstop_debate_finished.connect(_on_minigame_finished.bind("nonstop_debate"))
	EventBus.rebuttal_finished.connect(_on_minigame_finished.bind("rebuttal"))
	EventBus.hangman_finished.connect(_on_minigame_finished.bind("hangman"))
	EventBus.climax_inference_finished.connect(_on_minigame_finished.bind("climax"))
	EventBus.skill_selected.connect(_on_skill_selected)

# ============================================================
# 公共 API
# ============================================================

func load_script(script_path: String) -> void:
	if not FileAccess.file_exists(script_path):
		push_error("ScriptInterpreter: Script not found: " + script_path)
		return
	var file: FileAccess = FileAccess.open(script_path, FileAccess.READ)
	if file == null:
		push_error("ScriptInterpreter: Cannot open: " + script_path)
		return
	var json_text := file.get_as_text()
	file.close()
	var data: Variant = JSON.parse_string(json_text)
	if data == null:
		push_error("ScriptInterpreter: Invalid JSON: " + script_path)
		return
	_script_path = script_path
	_script_id = data.get("script_id", script_path.get_file().get_basename())
	load_script_data(data)

func load_script_data(data: Dictionary) -> void:
	current_script = data.get("events", [])
	current_index = 0
	is_waiting_input = false
	is_executing = false
	_pending_choice_data.clear()
	_pending_minigame_on_success = ""
	_pending_minigame_on_fail = ""
	_pending_save_prompt = false
	is_executing = true
	_execute_next()

func next() -> void:
	if not is_executing:
		return
	if is_waiting_input:
		is_waiting_input = false
		_execute_next()

func jump_to_label(label_name: String) -> void:
	for i in range(current_script.size()):
		var cmd = current_script[i]
		if cmd is Dictionary and cmd.get("cmd", "") == "label" and cmd.get("name", "") == label_name:
			current_index = i
			return
	push_error("ScriptInterpreter: Label not found: " + label_name)

func start_script(script_path: String) -> void:
	load_script(script_path)

func pause_execution() -> void:
	is_executing = false

func resume_execution() -> void:
	is_executing = true
	if not is_waiting_input:
		_execute_next()

func set_auto_mode(enabled: bool) -> void:
	is_auto_mode = enabled
	if enabled and is_waiting_input and not _pending_choice_data:
		_auto_timer.start()
	else:
		_auto_timer.stop()

func get_current_script_id() -> String:
	return _script_id

# ============================================================
# 主执行循环
# ============================================================

func _execute_next() -> void:
	while current_index < current_script.size() and is_executing:
		var cmd = current_script[current_index]
		current_index += 1

		if not cmd is Dictionary:
			continue

		var cmd_type: String = cmd.get("cmd", "")
		if not _handlers.has(cmd_type):
			push_warning("ScriptInterpreter: Unknown command: " + cmd_type)
			continue

		var should_await: bool = _handlers[cmd_type].call(cmd)
		if should_await:
			is_waiting_input = true
			if is_auto_mode and not _pending_choice_data and not _pending_save_prompt and not _pending_minigame_on_success:
				_auto_timer.start()
			return

	# 脚本执行完毕
	is_executing = false
	_script_id = ""
	EventBus.script_finished.emit(_script_id)
	EventBus.command_executed.emit("script_end")

# ============================================================
# 信号响应
# ============================================================

func _on_dialogue_next() -> void:
	_auto_timer.stop()
	if is_waiting_input and not _pending_choice_data and not _pending_save_prompt:
		is_waiting_input = false
		_execute_next()

func _on_choice_made(choice_index: int) -> void:
	if _pending_choice_data.is_empty():
		return
	var choices: Array = _pending_choice_data.get("choices", [])
	if choice_index < 0 or choice_index >= choices.size():
		return
	var selected = choices[choice_index]
	var jump_target: String = selected.get("jump", "")

	# 处理好感度变化
	var affection_changes: Dictionary = selected.get("affection", {})
	for char_id in affection_changes:
		GameManager.add_affection(char_id, affection_changes[char_id])

	# 处理错误惩罚
	if _pending_choice_data.has("correct_index") and _pending_choice_data.has("wrong_penalty"):
		var correct_idx: int = _pending_choice_data.get("correct_index", -1)
		if choice_index != correct_idx:
			var penalty: int = _pending_choice_data.get("wrong_penalty", 0)
			if penalty > 0:
				EventBus.hp_changed.emit(-1, 100)  # 扣HP由DebateManager最终处理

	_pending_choice_data.clear()

	if jump_target != "":
		jump_to_label(jump_target)
		is_waiting_input = false
		_execute_next()
	else:
		is_waiting_input = false
		_execute_next()

func _on_minigame_finished(is_success: bool, minigame_name: String) -> void:
	if _pending_minigame_on_success == "" and _pending_minigame_on_fail == "":
		return
	var jump_target := _pending_minigame_on_fail
	if is_success:
		jump_target = _pending_minigame_on_success
	_pending_minigame_on_success = ""
	_pending_minigame_on_fail = ""
	if jump_target != "":
		jump_to_label(jump_target)
	is_waiting_input = false
	_execute_next()

func _on_skill_selected(_skill_ids: Array) -> void:
	is_waiting_input = false
	_execute_next()

func _on_auto_advance() -> void:
	if is_auto_mode and is_waiting_input and not _pending_choice_data and not _pending_save_prompt:
		next()

# ============================================================
# 条件判断
# ============================================================

func _evaluate_condition(condition: String) -> bool:
	condition = condition.strip_edges()

	# has_evidence:ID
	if condition.begins_with("has_evidence:"):
		return EvidenceManager.has_evidence(condition.substr(14))

	# phase:NAME
	if condition.begins_with("phase:"):
		return GameManager.current_phase == condition.substr(6)

	# difficulty:NAME
	if condition.begins_with("difficulty:"):
		return GameManager.difficulty == condition.substr(11)

	# flag:NAME [comparison]
	if condition.begins_with("flag:"):
		return _evaluate_flag_condition(condition.substr(5))

	# affection:NAME [comparison]
	if condition.begins_with("affection:"):
		return _evaluate_affection_condition(condition.substr(10))

	return false

func _evaluate_flag_condition(expr: String) -> bool:
	expr = expr.strip_edges()
	if ">=" in expr:
		var parts := expr.split(">=")
		return GameManager.flags.get(parts[0].strip_edges(), 0) >= int(parts[1].strip_edges())
	if "<=" in expr:
		var parts := expr.split("<=")
		return GameManager.flags.get(parts[0].strip_edges(), 0) <= int(parts[1].strip_edges())
	if ">" in expr:
		var parts := expr.split(">")
		return GameManager.flags.get(parts[0].strip_edges(), 0) > int(parts[1].strip_edges())
	if "<" in expr:
		var parts := expr.split("<")
		return GameManager.flags.get(parts[0].strip_edges(), 0) < int(parts[1].strip_edges())
	if "==" in expr:
		var parts := expr.split("==")
		return GameManager.flags.get(parts[0].strip_edges(), 0) == int(parts[1].strip_edges())
	return GameManager.get_flag(expr)

func _evaluate_affection_condition(expr: String) -> bool:
	expr = expr.strip_edges()
	if ">=" in expr:
		var parts := expr.split(">=")
		return GameManager.get_affection(parts[0].strip_edges()) >= int(parts[1].strip_edges())
	if "<=" in expr:
		var parts := expr.split("<=")
		return GameManager.get_affection(parts[0].strip_edges()) <= int(parts[1].strip_edges())
	if ">" in expr:
		var parts := expr.split(">")
		return GameManager.get_affection(parts[0].strip_edges()) > int(parts[1].strip_edges())
	if "<" in expr:
		var parts := expr.split("<")
		return GameManager.get_affection(parts[0].strip_edges()) < int(parts[1].strip_edges())
	if "==" in expr:
		var parts := expr.split("==")
		return GameManager.get_affection(parts[0].strip_edges()) == int(parts[1].strip_edges())
	return GameManager.get_affection(expr) > 0

# ============================================================
# 步骤 10: 基础演出指令处理器
# ============================================================

func _handle_dialogue(cmd: Dictionary) -> bool:
	var enriched := cmd.duplicate()
	if not enriched.has("speaker_label") or str(enriched.get("speaker_label", "")) == "":
		var speaker_id: String = enriched.get("speaker", "")
		var cd := CharacterManager.get_character(speaker_id)
		if cd:
			enriched["speaker_label"] = cd.get_display_label()
	EventBus.dialogue_show.emit(enriched)
	return true

func _handle_set_bg(cmd: Dictionary) -> bool:
	var bg_id: String = cmd.get("bg_id", "")
	var transition: String = cmd.get("transition", "fade")
	EventBus.background_change_requested.emit(bg_id, transition)
	return false

func _handle_bgm(cmd: Dictionary) -> bool:
	var action: String = cmd.get("action", "play")
	var bgm_id: String = cmd.get("bgm_id", "")
	var volume: float = cmd.get("volume", 0.8)
	var fade: float = cmd.get("fade_duration", 0.0)
	EventBus.bgm_requested.emit(action, bgm_id, volume, fade)
	return false

func _handle_sfx(cmd: Dictionary) -> bool:
	var sfx_id: String = cmd.get("sfx_id", "")
	var volume: float = cmd.get("volume", 1.0)
	EventBus.sfx_requested.emit(sfx_id, volume)
	return false

func _handle_screen_effect(cmd: Dictionary) -> bool:
	var effect: String = cmd.get("effect", "")
	var intensity: float = cmd.get("intensity", 0.5)
	var duration: float = cmd.get("duration", 0.5)
	EventBus.screen_effect_requested.emit(effect, intensity, duration)
	return false

func _handle_show_character(cmd: Dictionary) -> bool:
	var char_id: String = cmd.get("character", "")
	var expression: String = cmd.get("expression", "normal")
	var position: String = cmd.get("position", "center")
	EventBus.show_character_requested.emit(char_id, expression, position)
	return false

func _handle_hide_character(cmd: Dictionary) -> bool:
	var char_id: String = cmd.get("character", "")
	EventBus.hide_character_requested.emit(char_id)
	return false

func _handle_load_scene(cmd: Dictionary) -> bool:
	var scene_id: String = cmd.get("scene", "")
	var transition: String = cmd.get("transition", "fade")
	SceneManager.load_scene(scene_id, transition)
	return false

func _handle_comment(_cmd: Dictionary) -> bool:
	return false

func _handle_label(_cmd: Dictionary) -> bool:
	return false

func _handle_jump(cmd: Dictionary) -> bool:
	var target: String = cmd.get("target", "")
	if target == "":
		return false
	if target.begins_with("label:"):
		target = target.substr(6)
	jump_to_label(target)
	return false

# ============================================================
# 步骤 11: 游戏逻辑指令处理器
# ============================================================

func _handle_add_evidence(cmd: Dictionary) -> bool:
	var evidence: Dictionary = cmd.get("evidence", {})
	EvidenceManager.add_evidence(evidence)
	return false

func _handle_remove_evidence(cmd: Dictionary) -> bool:
	var ev_id: String = cmd.get("evidence_id", "")
	EvidenceManager.remove_evidence(ev_id)
	return false

func _handle_update_evidence(cmd: Dictionary) -> bool:
	var ev_id: String = cmd.get("evidence_id", "")
	var updates := {
		"name": cmd.get("new_name", ""),
		"description": cmd.get("new_description", "")
	}
	EvidenceManager.update_evidence(ev_id, updates)
	return false

func _handle_choice(cmd: Dictionary) -> bool:
	_pending_choice_data = cmd
	EventBus.choice_presented.emit(cmd)
	return true

func _handle_if(cmd: Dictionary) -> bool:
	var condition: String = cmd.get("condition", "")
	var result := _evaluate_condition(condition)
	var jump_target: String
	if result:
		jump_target = cmd.get("jump_true", "")
	else:
		jump_target = cmd.get("jump_false", "")
	if jump_target != "":
		if jump_target.begins_with("label:"):
			jump_target = jump_target.substr(6)
		jump_to_label(jump_target)
	return false

func _handle_set_flag(cmd: Dictionary) -> bool:
	var flag_name: String = cmd.get("flag", "")
	var value: bool = cmd.get("value", true)
	GameManager.set_flag(flag_name, value)
	return false

func _handle_affection(cmd: Dictionary) -> bool:
	var char_id: String = cmd.get("character", "")
	var amount: int = cmd.get("amount", 0)
	GameManager.add_affection(char_id, amount)
	return false

func _handle_unlock_skill(cmd: Dictionary) -> bool:
	var skill_id: String = cmd.get("skill_id", "")
	GameManager.unlock_skill(skill_id)
	return false

func _handle_save_prompt(cmd: Dictionary) -> bool:
	var text: String = cmd.get("text", "要存档吗？")
	_pending_save_prompt = true
	EventBus.save_prompt_requested.emit(text)
	return true

func _handle_skill_select(_cmd: Dictionary) -> bool:
	EventBus.skill_select_requested.emit()
	return true

# ============================================================
# 步骤 12: 学级裁判指令处理器（小游戏占位符）
# ============================================================

func _handle_nonstop_debate(cmd: Dictionary) -> bool:
	var config_id: String = cmd.get("config_id", "")
	_pending_minigame_on_success = cmd.get("on_success", "")
	_pending_minigame_on_fail = cmd.get("on_fail", "")
	EventBus.start_nonstop_debate.emit(config_id)
	return true

func _handle_rebuttal(cmd: Dictionary) -> bool:
	var config_id: String = cmd.get("config_id", "")
	_pending_minigame_on_success = cmd.get("on_success", "")
	_pending_minigame_on_fail = cmd.get("on_fail", "")
	EventBus.start_rebuttal.emit(config_id)
	return true

func _handle_hangman(cmd: Dictionary) -> bool:
	var config_id: String = cmd.get("config_id", "")
	var mode: String = cmd.get("mode", "letter")
	_pending_minigame_on_success = cmd.get("on_success", "")
	_pending_minigame_on_fail = cmd.get("on_fail", "")
	EventBus.start_hangman.emit(config_id, mode)
	return true

func _handle_climax_inference(cmd: Dictionary) -> bool:
	var config_id: String = cmd.get("config_id", "")
	_pending_minigame_on_success = cmd.get("on_success", "")
	_pending_minigame_on_fail = cmd.get("on_fail", "")
	EventBus.start_climax_inference.emit(config_id)
	return true

func _handle_trial_result(cmd: Dictionary) -> bool:
	var result: String = cmd.get("result", "guilty")
	EventBus.trial_ended.emit(result)
	return false

# ============================================================
# 步骤 10-12: 注册所有处理器
# ============================================================

func _register_handlers() -> void:
	# 步骤 10 — 基础演出指令
	_handlers["dialogue"] = _handle_dialogue
	_handlers["set_bg"] = _handle_set_bg
	_handlers["bgm"] = _handle_bgm
	_handlers["sfx"] = _handle_sfx
	_handlers["screen_effect"] = _handle_screen_effect
	_handlers["show_character"] = _handle_show_character
	_handlers["hide_character"] = _handle_hide_character
	_handlers["load_scene"] = _handle_load_scene
	_handlers["comment"] = _handle_comment
	_handlers["label"] = _handle_label
	_handlers["jump"] = _handle_jump

	# 步骤 11 — 游戏逻辑指令
	_handlers["add_evidence"] = _handle_add_evidence
	_handlers["remove_evidence"] = _handle_remove_evidence
	_handlers["update_evidence"] = _handle_update_evidence
	_handlers["choice"] = _handle_choice
	_handlers["if"] = _handle_if
	_handlers["set_flag"] = _handle_set_flag
	_handlers["affection"] = _handle_affection
	_handlers["unlock_skill"] = _handle_unlock_skill
	_handlers["save_prompt"] = _handle_save_prompt
	_handlers["skill_select"] = _handle_skill_select

	# 步骤 12 — 学级裁判指令
	_handlers["start_nonstop_debate"] = _handle_nonstop_debate
	_handlers["start_rebuttal"] = _handle_rebuttal
	_handlers["start_hangman"] = _handle_hangman
	_handlers["start_climax_inference"] = _handle_climax_inference
	_handlers["trial_result"] = _handle_trial_result
