class_name SkillItem
extends Resource
# ============================================================
# Step 49: 技能数据 Resource
# ============================================================

@export var skill_id: String = ""
@export var skill_name: String = ""
@export var description: String = ""
@export var sp_cost: int = 1
@export var effect_type: String = ""
@export var effect_value: float = 0.0

func load_from_dict(data: Dictionary) -> void:
	skill_id = data.get("skill_id", "")
	skill_name = data.get("skill_name", "")
	description = data.get("description", "")
	sp_cost = data.get("sp_cost", 1)
	effect_type = data.get("effect_type", "")
	effect_value = data.get("effect_value", 0.0)
