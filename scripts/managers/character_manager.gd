extends Node
# ============================================================
# Step 22: CharacterManager — 角色数据管理 (Autoload)
# ============================================================

var _characters: Dictionary = {}

signal character_died(character_id: String)
signal character_revived(character_id: String)

func _ready() -> void:
	_load_characters()

func _load_characters() -> void:
	var path := "res://resources/characters/characters.json"
	if not FileAccess.file_exists(path):
		push_error("CharacterManager: characters.json not found: " + path)
		return
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return
	var text := file.get_as_text()
	file.close()
	var data: Variant = JSON.parse_string(text)
	if data == null or not data is Array:
		push_error("CharacterManager: Invalid characters.json format")
		return
	for entry: Dictionary in data:
		var cd := CharacterData.new()
		cd.character_id = entry.get("character_id", "")
		cd.display_name = entry.get("display_name", "")
		cd.title = entry.get("title", "")
		cd.color = Color.from_string(entry.get("color", "#FFFFFF"), Color.WHITE)
		cd.voice_pack = entry.get("voice_pack", "")
		cd.is_playable = entry.get("is_playable", false)
		cd.survival = entry.get("survival", true)
		var portrait_data: Dictionary = entry.get("portraits", {})
		cd.portrait_paths = portrait_data
		_characters[cd.character_id] = cd
	print("[CharacterManager] 已加载 %d 个角色数据" % _characters.size())

func get_character(char_id: String) -> CharacterData:
	return _characters.get(char_id, null)

func get_all_characters() -> Array[CharacterData]:
	var result: Array[CharacterData] = []
	for cd in _characters.values():
		result.append(cd)
	return result

func get_alive_characters() -> Array[CharacterData]:
	var result: Array[CharacterData] = []
	for cd in _characters.values():
		if cd.survival:
			result.append(cd)
	return result

func get_dead_characters() -> Array[CharacterData]:
	var result: Array[CharacterData] = []
	for cd in _characters.values():
		if not cd.survival:
			result.append(cd)
	return result

func get_character_count() -> int:
	return _characters.size()

func get_alive_count() -> int:
	return get_alive_characters().size()

func set_character_dead(char_id: String) -> void:
	var cd := get_character(char_id)
	if cd == null:
		return
	cd.survival = false
	character_died.emit(char_id)

func set_character_alive(char_id: String) -> void:
	var cd := get_character(char_id)
	if cd == null:
		return
	cd.survival = true
	character_revived.emit(char_id)

func get_display_name(char_id: String) -> String:
	var cd := get_character(char_id)
	if cd:
		return cd.display_name
	return char_id

func get_character_color(char_id: String) -> Color:
	var cd := get_character(char_id)
	if cd:
		return cd.color
	return Color(0.5, 0.5, 0.5)
