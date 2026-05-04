class_name ClimaxInferenceConfig
extends Resource
# ============================================================
# Step 45: 高潮再现配置 Resource
# ============================================================

@export var config_id: String = ""
@export var panel_titles: Array[String] = []
@export var tile_texts: Array[String] = []
@export var correct_tile_for_panel: Array[int] = []
@export var time_limit: float = 50.0

func load_from_dict(data: Dictionary) -> void:
	config_id = data.get("config_id", "")
	panel_titles.assign(data.get("panel_titles", []))
	tile_texts.assign(data.get("tile_texts", []))
	correct_tile_for_panel.assign(data.get("correct_tile_for_panel", []))
	time_limit = data.get("time_limit", 50.0)
