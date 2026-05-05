class_name DebatePhrase extends Resource
# ============================================================
# Step 31: 单条辩论发言 Resource
# ============================================================

@export var text: String = ""
@export var speaker_id: String = ""
@export var hotspots: Array[Dictionary] = []
@export var speed: float = 60.0
@export var lifetime: float = 10.0
@export var speak_duration: float = 3.0

# hotspots format: [{"text":"矛盾词","is_real":false},{"text":"真矛盾","is_real":true,"required_evidence_id":"ev_01"}]

func get_real_hotspot() -> Dictionary:
	for h in hotspots:
		if h.get("is_real", false):
			return h
	return {}

func has_hotspots() -> bool:
	return hotspots.size() > 0
