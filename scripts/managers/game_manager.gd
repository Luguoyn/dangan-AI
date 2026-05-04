extends Node
# ============================================================
# GameManager — 游戏主管理器 (Autoload)
# 顶层协调器，维护全局游戏状态
# ============================================================

# --- 全局状态 ---
var flags: Dictionary = {}
var affection: Dictionary = {}
var unlocked_skills: Array[String] = []
var current_chapter: String = ""
var current_phase: String = ""
var difficulty: String = "normal"

# --- 标记位操作 ---
func set_flag(flag_name: String, value: bool = true) -> void:
	flags[flag_name] = value

func get_flag(flag_name: String) -> bool:
	return flags.get(flag_name, false)

func has_flag(flag_name: String) -> bool:
	return flags.has(flag_name)

func clear_flag(flag_name: String) -> void:
	flags.erase(flag_name)

# --- 好感度操作 ---
func add_affection(char_id: String, amount: int) -> void:
	if not affection.has(char_id):
		affection[char_id] = 0
	affection[char_id] += amount
	# 死去的角色不再累计好感度
	var cd := CharacterManager.get_character(char_id)
	if cd and not cd.survival:
		return
	affection[char_id] = clampi(affection[char_id], -100, 100)

func get_affection(char_id: String) -> int:
	return affection.get(char_id, 0)

func set_affection(char_id: String, value: int) -> void:
	affection[char_id] = value

func has_affection(char_id: String, threshold: int = 0) -> bool:
	return get_affection(char_id) >= threshold

func get_affection_level(char_id: String) -> String:
	var val := get_affection(char_id)
	if val >= 80:
		return "挚友"
	elif val >= 50:
		return "好友"
	elif val >= 20:
		return "友好"
	elif val >= 0:
		return "普通"
	elif val >= -20:
		return "冷淡"
	else:
		return "敌视"

func get_all_affection() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for char_id in affection:
		var cd := CharacterManager.get_character(char_id)
		result.append({
			"character_id": char_id,
			"display_name": cd.display_name if cd else char_id,
			"value": affection[char_id],
			"level": get_affection_level(char_id)
		})
	return result

# --- 技能操作 ---
func unlock_skill(skill_id: String) -> void:
	if skill_id not in unlocked_skills:
		unlocked_skills.append(skill_id)

func has_skill(skill_id: String) -> bool:
	return skill_id in unlocked_skills

func get_unlocked_skills() -> Array[String]:
	return unlocked_skills.duplicate()

# --- 章节/阶段管理 ---
func set_chapter(chapter_id: String) -> void:
	current_chapter = chapter_id

func set_phase(phase: String) -> void:
	current_phase = phase

# --- 难度设置 ---
func set_difficulty(diff: String) -> void:
	difficulty = diff

func get_difficulty() -> String:
	return difficulty

# --- 重置游戏状态 ---
func reset_state() -> void:
	flags.clear()
	affection.clear()
	unlocked_skills.clear()
	current_chapter = ""
	current_phase = ""
	difficulty = "normal"
