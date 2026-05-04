class_name RebuttalConfig extends Resource
# ============================================================
# Step 36: 反论配置 Resource
# ============================================================

@export var config_id: String = ""
@export var opponent_id: String = ""
@export var slash_lines: Array[String] = []
@export var slash_timings: Array[float] = []
@export var slash_speeds: Array[float] = []
@export var on_success_dialogue: String = ""

func load_from_dict(data: Dictionary) -> void:
	config_id = data.get("config_id", "")
	opponent_id = data.get("opponent_id", "")
	slash_lines.assign(data.get("slash_lines", []))
	slash_timings.assign(data.get("slash_timings", []))
	slash_speeds.assign(data.get("slash_speeds", []))
	on_success_dialogue = data.get("on_success_dialogue", "")
