extends Node
# ============================================================
# Step 29: DebateManager — 辩论总控 (Autoload)
# 裁判场状态、HP 系统、小游戏调度、难度配置
# ============================================================

signal minigame_requested(minigame_type: String, config_id: String)

var max_hp: int = 100
var current_hp: int = 100
var equipped_skills: Array = []
var is_trial_active: bool = false
var difficulty_config: Dictionary = {}

func _ready() -> void:
	_load_difficulty_config()
	EventBus.trial_started.connect(_on_trial_started)
	EventBus.trial_ended.connect(_on_trial_ended)
	EventBus.nonstop_debate_finished.connect(_on_minigame_result.bind("nonstop_debate"))
	EventBus.rebuttal_finished.connect(_on_minigame_result.bind("rebuttal"))
	EventBus.hangman_finished.connect(_on_minigame_result.bind("hangman"))
	EventBus.climax_inference_finished.connect(_on_minigame_result.bind("climax"))
	EventBus.start_nonstop_debate.connect(_on_start_nonstop_debate)

var _active_debate_ui: Node

func _on_start_nonstop_debate(config_id: String) -> void:
	if is_instance_valid(_active_debate_ui):
		return
	var path := "res://resources/debate_configs/" + config_id + ".json"
	if not FileAccess.file_exists(path):
		push_error("DebateManager: Config not found: " + path)
		return
	var file := FileAccess.open(path, FileAccess.READ)
	var text := file.get_as_text()
	file.close()
	var data: Variant = JSON.parse_string(text)
	var config := NonStopDebateConfig.new()
	config.load_from_dict(data)
	var ui := NonStopDebateUI.new()
	_active_debate_ui = ui
	ui.debate_finished.connect(func(_s): _active_debate_ui = null)
	get_tree().root.add_child(ui)
	ui.start_debate(config)

func _load_difficulty_config() -> void:
	difficulty_config = {
		"kind": {
			"max_hp": 120, "hp_damage_mult": 0.7, "hp_heal_amount": 8,
			"evidence_ring_time": 0.6, "nonstop_yellow_linger": 12.0,
			"hangman_time_bonus": 10.0, "rebuttal_judge_window": 80,
			"climax_time_limit": 75.0
		},
		"normal": {
			"max_hp": 100, "hp_damage_mult": 1.0, "hp_heal_amount": 5,
			"evidence_ring_time": 0.4, "nonstop_yellow_linger": 8.0,
			"hangman_time_bonus": 0.0, "rebuttal_judge_window": 50,
			"climax_time_limit": 60.0
		},
		"mean": {
			"max_hp": 80, "hp_damage_mult": 1.5, "hp_heal_amount": 3,
			"evidence_ring_time": 0.2, "nonstop_yellow_linger": 5.0,
			"hangman_time_bonus": -5.0, "rebuttal_judge_window": 30,
			"climax_time_limit": 45.0
		}
	}

func _on_trial_started() -> void:
	is_trial_active = true
	_apply_difficulty()
	reset_hp()

func _on_trial_ended(_result: String) -> void:
	is_trial_active = false

func _apply_difficulty() -> void:
	var diff: String = GameManager.get_difficulty()
	var config: Dictionary = difficulty_config.get(diff, difficulty_config["normal"])
	max_hp = config.get("max_hp", 100)
	current_hp = max_hp

func reset_hp() -> void:
	_apply_difficulty()
	EventBus.hp_changed.emit(current_hp, max_hp)

func damage_hp(amount: int) -> void:
	if not is_trial_active:
		return
	var diff_config := _get_current_diff()
	var multiplied := int(amount * diff_config.get("hp_damage_mult", 1.0))
	current_hp = maxi(0, current_hp - multiplied)
	EventBus.hp_changed.emit(current_hp, max_hp)
	if current_hp <= 0:
		EventBus.hp_depleted.emit()

func heal_hp(amount: int) -> void:
	if not is_trial_active:
		return
	var diff_config := _get_current_diff()
	var heal := maxi(1, amount)
	current_hp = mini(max_hp, current_hp + heal)
	EventBus.hp_changed.emit(current_hp, max_hp)

func get_diff_param(key: String, default: Variant = null) -> Variant:
	var diff_config := _get_current_diff()
	return diff_config.get(key, default)

func _get_current_diff() -> Dictionary:
	var diff: String = GameManager.get_difficulty()
	return difficulty_config.get(diff, difficulty_config["normal"])

func equip_skill(skill_id: String) -> void:
	if skill_id not in equipped_skills:
		equipped_skills.append(skill_id)

func unequip_skill(skill_id: String) -> void:
	equipped_skills.erase(skill_id)

func has_skill_equipped(skill_id: String) -> bool:
	return skill_id in equipped_skills

func _on_minigame_result(is_success: bool, _minigame: String) -> void:
	if is_success:
		heal_hp(get_diff_param("hp_heal_amount", 5))
