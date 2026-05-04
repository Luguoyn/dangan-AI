class_name HangmanLetterConfig
extends HangmanConfigBase
@export var target_word: String = ""
@export var available_letters: Array[String] = []
@export var rotation_speed: float = 90.0

func load_from_dict(data: Dictionary) -> void:
	load_base(data)
	target_word = data.get("target_word", "")
	available_letters.assign(data.get("available_letters", []))
	rotation_speed = data.get("rotation_speed", 90.0)
