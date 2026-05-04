class_name HangmanWordConfig
extends HangmanConfigBase
@export var target_chars: Array[String] = []
@export var distractor_chars: Array[String] = []

func load_from_dict(data: Dictionary) -> void:
	load_base(data)
	target_chars.assign(data.get("target_chars", []))
	distractor_chars.assign(data.get("distractor_chars", []))
