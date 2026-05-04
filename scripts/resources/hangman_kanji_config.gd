class_name HangmanKanjiConfig
extends HangmanConfigBase
@export var target_kanji: String = ""
@export var components_in_order: Array[String] = []
@export var distractor_components: Array[String] = []
@export var fragment_speed: float = 120.0

func load_from_dict(data: Dictionary) -> void:
	load_base(data)
	target_kanji = data.get("target_kanji", "")
	components_in_order.assign(data.get("components_in_order", []))
	distractor_components.assign(data.get("distractor_components", []))
	fragment_speed = data.get("fragment_speed", 120.0)
