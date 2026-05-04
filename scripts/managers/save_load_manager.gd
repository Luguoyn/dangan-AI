extends Node
# ============================================================
# SaveLoadManager — 存档/读档管理 (Autoload)
# ============================================================

const SAVE_DIR := "user://saves/"
const SAVE_EXTENSION := ".sav"

func _ready() -> void:
	DirAccess.make_dir_absolute(SAVE_DIR)

func save_game(slot: int) -> bool:
	var save_data := _build_save_data()
	var json := JSON.stringify(save_data, "\t")
	var path := _get_save_path(slot)
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_error("SaveLoadManager: Failed to open save file: " + path)
		return false
	file.store_string(json)
	file.close()
	return true

func load_game(slot: int) -> bool:
	var path := _get_save_path(slot)
	if not FileAccess.file_exists(path):
		push_error("SaveLoadManager: Save file not found: " + path)
		return false
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("SaveLoadManager: Failed to open save file: " + path)
		return false
	var json := file.get_as_text()
	file.close()
	var test: Variant = JSON.parse_string(json)
	if test == null:
		push_error("SaveLoadManager: Failed to parse save file: " + path)
		return false
	_apply_save_data(test)
	return true

func save_exists(slot: int) -> bool:
	return FileAccess.file_exists(_get_save_path(slot))

func delete_save(slot: int) -> void:
	var path := _get_save_path(slot)
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)

func get_save_slot_count() -> int:
	return 3

func _get_save_path(slot: int) -> String:
	return SAVE_DIR + str(slot) + SAVE_EXTENSION

func _build_save_data() -> Dictionary:
	return {
		"version": 1,
		"chapter": GameManager.current_chapter,
		"phase": GameManager.current_phase,
		"flags": GameManager.flags,
		"affection": GameManager.affection,
		"unlocked_skills": GameManager.unlocked_skills,
		"difficulty": GameManager.difficulty,
		"evidence_ids": EvidenceManager.get_all_evidence().map(func(ev): return ev.get("id", "")),
		"scene_id": SceneManager.get_current_scene_id()
	}

func _apply_save_data(data: Dictionary) -> void:
	GameManager.set_chapter(data.get("chapter", ""))
	GameManager.set_phase(data.get("phase", ""))
	GameManager.flags = data.get("flags", {})
	GameManager.affection = data.get("affection", {})
	GameManager.unlocked_skills = data.get("unlocked_skills", [])
	GameManager.set_difficulty(data.get("difficulty", "normal"))
