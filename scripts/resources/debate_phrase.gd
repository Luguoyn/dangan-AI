class_name DebatePhrase extends Resource
# ============================================================
# Step 31: 单条辩论发言 Resource
# ============================================================

@export var text: String = ""
@export var speaker_id: String = ""
@export var is_contradiction: bool = false
@export var required_evidence_id: String = ""
@export var speed: float = 60.0
@export var lifetime: float = 10.0
