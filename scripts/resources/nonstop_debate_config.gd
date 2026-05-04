class_name NonStopDebateConfig extends Resource
# ============================================================
# Step 31: 无休止议论配置 Resource
# ============================================================

@export var config_id: String = ""
@export var phrases: Array[DebatePhrase] = []
@export var noise_texts: Array[String] = []
@export var spawn_interval: float = 1.8
@export var require_sequential: bool = true
@export var available_evidence_ids: Array[String] = []

func load_from_dict(data: Dictionary) -> void:
	config_id = data.get("config_id", "")
	spawn_interval = data.get("spawn_interval", 1.8)
	require_sequential = data.get("require_sequential", true)
	available_evidence_ids.assign(data.get("available_evidence_ids", []))
	noise_texts.assign(data.get("noise_texts", []))
	phrases.clear()
	for p in data.get("phrases", []):
		var dp := DebatePhrase.new()
		dp.text = p.get("text", "")
		dp.speaker_id = p.get("speaker_id", "")
		dp.is_contradiction = p.get("is_contradiction", false)
		dp.required_evidence_id = p.get("required_evidence_id", "")
		dp.speed = p.get("speed", 60.0)
		dp.lifetime = p.get("lifetime", 10.0)
		phrases.append(dp)
