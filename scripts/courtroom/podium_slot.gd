extends Node3D
class_name PodiumSlot
# ============================================================
# Step 26: 3D 角色站位系统
# ============================================================

@export var podium_index: int = 0
@export var character_id: String = ""

var _billboard: Sprite3D
var _name_label: Label3D
var _highlight_mesh: MeshInstance3D
var _spotlight: SpotLight3D

func _ready() -> void:
	_create_billboard()
	_create_name_label()
	_create_highlight()

func _create_billboard() -> void:
	_billboard = Sprite3D.new()
	_billboard.name = "Billboard"
	_billboard.position = Vector3(0, 2.0, 0)
	_billboard.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(_billboard)

func _create_name_label() -> void:
	_name_label = Label3D.new()
	_name_label.name = "NameLabel"
	_name_label.position = Vector3(0, 3.0, 0)
	_name_label.font_size = 36
	_name_label.modulate = Color.WHITE
	_name_label.outline_size = 2
	add_child(_name_label)

func _create_highlight() -> void:
	_highlight_mesh = MeshInstance3D.new()
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = 1.5
	cylinder.bottom_radius = 1.5
	cylinder.height = 0.05
	_highlight_mesh.mesh = cylinder
	_highlight_mesh.position = Vector3(0, 0.02, 0)
	_highlight_mesh.visible = false
	add_child(_highlight_mesh)

	_spotlight = SpotLight3D.new()
	_spotlight.position = Vector3(0, 6, 2)
	_spotlight.rotation_degrees = Vector3(-60, 0, 0)
	_spotlight.light_color = Color(1, 1, 0.8, 1)
	_spotlight.light_energy = 0
	_spotlight.visible = false
	add_child(_spotlight)

func assign_character(char_id: String) -> void:
	character_id = char_id
	var cd := CharacterManager.get_character(char_id)
	if cd:
		_name_label.text = cd.display_name
		_billboard.modulate = cd.color
	else:
		_name_label.text = char_id

func highlight(active: bool) -> void:
	_highlight_mesh.visible = active
	_spotlight.visible = active
	if active:
		_spotlight.light_energy = 2.0
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color.YELLOW
		mat.emission_enabled = true
		mat.emission = Color.YELLOW
		mat.emission_energy_multiplier = 0.5
		_highlight_mesh.material_override = mat
	else:
		_spotlight.light_energy = 0

func get_name_tag_position() -> Vector3:
	return _name_label.global_position

func get_podium_position() -> Vector3:
	return global_position
