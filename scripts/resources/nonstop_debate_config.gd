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
@export var camera_transition: String = "rotate"
@export var camera_lock: String = "drift"

func load_from_dict(data: Dictionary) -> void:
	config_id = data.get("config_id", "")
	spawn_interval = data.get("spawn_interval", 1.8)
	require_sequential = data.get("require_sequential", true)
	available_evidence_ids.assign(data.get("available_evidence_ids", []))
	noise_texts.assign(data.get("noise_texts", []))
	camera_transition = data.get("camera_transition", "rotate")
	camera_lock = data.get("camera_lock", "drift")
	phrases.clear()
	for p in data.get("phrases", []):
		var dp := DebatePhrase.new()
		dp.text = p.get("text", "")
		dp.speaker_id = p.get("speaker_id", "")
		dp.speed = p.get("speed", 60.0)
		dp.lifetime = p.get("lifetime", 10.0)
		dp.speak_duration = p.get("speak_duration", 3.0)
		# 新格式：hotspots 数组
		var hlist: Array = p.get("hotspots", [])
		var arr: Array[Dictionary] = []
		for h: Dictionary in hlist:
			arr.append(h)
		dp.hotspots = arr
		phrases.append(dp)
