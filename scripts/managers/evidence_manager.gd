extends Node
# ============================================================
# EvidenceManager — 言弹数据管理 (Autoload)
# ============================================================

var _evidence_list: Dictionary = {}

func add_evidence(data: Dictionary) -> void:
	var ev_id = data.get("id", "")
	if ev_id == "":
		return
	if _evidence_list.has(ev_id):
		update_evidence(ev_id, data)
		return
	_evidence_list[ev_id] = data
	EventBus.evidence_added.emit(ev_id)

func add_evidence_from_item(item: EvidenceItem) -> void:
	if _evidence_list.has(item.id):
		return
	_evidence_list[item.id] = {
		"id": item.id,
		"name": item.name,
		"description": item.description,
		"icon": item.icon,
		"type": item.type
	}
	EventBus.evidence_added.emit(item.id)

func get_evidence(ev_id: String) -> Dictionary:
	return _evidence_list.get(ev_id, {})

func get_all_evidence() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for ev in _evidence_list.values():
		result.append(ev)
	return result

func has_evidence(ev_id: String) -> bool:
	return _evidence_list.has(ev_id)

func update_evidence(ev_id: String, updates: Dictionary) -> void:
	if not _evidence_list.has(ev_id):
		return
	var ev = _evidence_list[ev_id]
	for key in updates:
		ev[key] = updates[key]
	EventBus.evidence_updated.emit(ev_id)

func remove_evidence(ev_id: String) -> void:
	if _evidence_list.has(ev_id):
		_evidence_list.erase(ev_id)
		EventBus.evidence_removed.emit(ev_id)

func clear_all() -> void:
	_evidence_list.clear()

func get_evidence_count() -> int:
	return _evidence_list.size()
