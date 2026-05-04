class_name HangmanConfigBase
extends Resource
@export var mode: String = "letter"
@export var hint_text: String = ""
@export var time_limit: float = 25.0

func load_base(data: Dictionary) -> void:
	mode = data.get("mode", "letter")
	hint_text = data.get("hint_text", "")
	time_limit = data.get("time_limit", 25.0)
