extends Node
# ============================================================
# TestRunner — 自动测试 ScriptInterpreter (Autoload)
# 游戏启动后自动加载并执行测试剧本
# 通过自动模拟用户输入完成全流程验证
# ============================================================

var _test_passed: int = 0
var _test_total: int = 0
var _auto_choices: Array = [0]
var _auto_choice_index: int = 0

func _ready() -> void:
	EventBus.dialogue_show.connect(_on_dialogue_show)
	EventBus.dialogue_next.connect(_on_dialogue_next_debug)
	EventBus.choice_presented.connect(_on_choice_presented)
	EventBus.choice_made.connect(_on_choice_made_debug)
	EventBus.evidence_added.connect(_on_evidence_added)
	EventBus.evidence_updated.connect(_on_evidence_updated)
	EventBus.evidence_removed.connect(_on_evidence_removed)
	EventBus.nonstop_debate_finished.connect(_on_nonstop_debate_finished)
	EventBus.save_prompt_requested.connect(_on_save_prompt)
	EventBus.skill_select_requested.connect(_on_skill_select)
	EventBus.trial_ended.connect(_on_trial_ended)
	EventBus.script_finished.connect(_on_script_finished)
	EventBus.start_nonstop_debate.connect(_on_start_nonstop_debate)
	EventBus.start_rebuttal.connect(_on_start_rebuttal)
	EventBus.start_hangman.connect(_on_start_hangman)
	EventBus.start_climax_inference.connect(_on_start_climax_inference)
	await get_tree().process_frame
	_begin_test()

func _begin_test() -> void:
	print("\n========================================")
	print("  ScriptInterpreter 全指令自动化测试")
	print("========================================\n")
	ScriptInterpreter.load_script("res://story/test.script.json")

# --- 自动模拟用户输入 ---

func _on_dialogue_show(data: Dictionary) -> void:
	var speaker: String = data.get("speaker", "???")
	var text: String = data.get("text", "")
	print("[DIALOGUE] %s: %s" % [speaker, text])
	await get_tree().create_timer(0.05).timeout
	ScriptInterpreter.next()

func _on_dialogue_next_debug() -> void:
	pass

func _on_choice_presented(data: Dictionary) -> void:
	var prompt: String = data.get("prompt", "")
	var choices: Array = data.get("choices", [])
	print("[CHOICE] %s" % prompt)
	for i in range(choices.size()):
		print("  %d: %s → jump: %s" % [i, choices[i].get("text", ""), choices[i].get("jump", "")])
	await get_tree().create_timer(0.05).timeout
	var idx: int = data.get("correct_index", 0)
	print("  → 自动选择选项%d (正确选项)\n" % idx)
	EventBus.choice_made.emit(idx)

func _on_choice_made_debug(_idx: int) -> void:
	pass

func _on_evidence_added(ev_id: String) -> void:
	print("[EVIDENCE ADDED] %s" % ev_id)

func _on_evidence_updated(ev_id: String) -> void:
	print("[EVIDENCE UPDATED] %s" % ev_id)

func _on_evidence_removed(ev_id: String) -> void:
	print("[EVIDENCE REMOVED] %s" % ev_id)

func _on_nonstop_debate_finished(is_success: bool) -> void:
	print("[MINIGAME] Nonstop Debate finished: %s" % ("SUCCESS" if is_success else "FAIL"))

func _on_save_prompt(text: String) -> void:
	print("[SAVE PROMPT] %s" % text)
	await get_tree().create_timer(0.05).timeout
	ScriptInterpreter.next()

func _on_skill_select() -> void:
	print("[SKILL SELECT] requested")
	await get_tree().create_timer(0.05).timeout
	EventBus.skill_selected.emit(["voice_beauty"])

func _on_trial_ended(result: String) -> void:
	print("[TRIAL ENDED] result: %s" % result)

# --- 自动完成小游戏（测试用） ---

func _on_start_nonstop_debate(config_id: String) -> void:
	print("[MINIGAME START] Nonstop Debate: %s" % config_id)
	await get_tree().create_timer(0.1).timeout
	EventBus.nonstop_debate_finished.emit(true)

func _on_start_rebuttal(config_id: String) -> void:
	print("[MINIGAME START] Rebuttal: %s" % config_id)
	await get_tree().create_timer(0.1).timeout
	EventBus.rebuttal_finished.emit(true)

func _on_start_hangman(config_id: String, mode: String) -> void:
	print("[MINIGAME START] Hangman (%s): %s" % [mode, config_id])
	await get_tree().create_timer(0.1).timeout
	EventBus.hangman_finished.emit(true)

func _on_start_climax_inference(config_id: String) -> void:
	print("[MINIGAME START] Climax Inference: %s" % config_id)
	await get_tree().create_timer(0.1).timeout
	EventBus.climax_inference_finished.emit(true)

func _on_script_finished(script_id: String) -> void:
	print("\n========================================")
	print("  测试剧本执行完毕！")
	_verify_state()
	print("========================================")

func _verify_state() -> void:
	print("\n--- 状态验证 ---")

	var flag_ok := GameManager.get_flag("test_flag_01")
	print("  flag:test_flag_01 = %s  %s" % [flag_ok, "OK" if flag_ok else "FAIL"])

	var aff := GameManager.get_affection("kirigiri")
	print("  affection:kirigiri = %d  %s" % [aff, "OK" if aff >= 5 else "FAIL"])

	var has_ev := EvidenceManager.has_evidence("ev_test_01")
	print("  has_evidence:ev_test_01 = %s  %s (应为 false, 已remove)" % [has_ev, "OK" if not has_ev else "FAIL"])

	var has_skill := GameManager.has_skill("voice_beauty")
	print("  unlocked:voice_beauty = %s  %s" % [has_skill, "OK" if has_skill else "FAIL"])

	var ev_count := EvidenceManager.get_evidence_count()
	print("  evidence_count = %d  %s (应为 0)" % [ev_count, "OK" if ev_count == 0 else "FAIL"])

	print("\n  如果以上全部显示 OK，则 ScriptInterpreter 完全正常。")
	print("  如有 FAIL，请检查对应指令处理器。\n")
