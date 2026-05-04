class_name CharacterData extends Resource
# ============================================================
# Step 21: CharacterData — 角色数据 Resource
# ============================================================

@export var character_id: String = ""
@export var display_name: String = ""
@export var title: String = ""
@export var color: Color = Color.WHITE
@export var portrait_paths: Dictionary = {}
@export var voice_pack: String = ""
@export var is_playable: bool = false
@export var survival: bool = true

func get_display_label() -> String:
	if title != "":
		return "%s（%s）" % [display_name, title]
	return display_name

func get_portrait(expression: String = "normal") -> String:
	if portrait_paths.has(expression):
		return portrait_paths[expression]
	if portrait_paths.has("normal"):
		return portrait_paths["normal"]
	return ""
