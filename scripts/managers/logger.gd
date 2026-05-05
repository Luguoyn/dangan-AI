extends Node
# ============================================================
# Step 59+60: Logger — 日志系统 (Autoload)
# ============================================================

var _log_entries: Array[Dictionary] = []
var _max_entries: int = 500

func _ready() -> void:
	log_info("Logger initialized")

func log_info(msg: String) -> void:
	_add_entry("INFO", msg)
	print("[INFO] " + msg)

func log_warning(msg: String) -> void:
	_add_entry("WARN", msg)
	push_warning("[WARN] " + msg)

func log_error(msg: String) -> void:
	_add_entry("ERROR", msg)
	push_error("[ERROR] " + msg)

func log_command(cmd_type: String, details: String = "") -> void:
	_add_entry("CMD", cmd_type + (": " + details if details else ""))

func _add_entry(level: String, message: String) -> void:
	_log_entries.append({
		"time": Time.get_time_string_from_system(),
		"level": level,
		"message": message
	})
	if _log_entries.size() > _max_entries:
		_log_entries.pop_front()

func get_recent_logs(count: int = 50) -> Array[Dictionary]:
	var start := maxi(0, _log_entries.size() - count)
	return _log_entries.slice(start)

func export_to_file(path: String = "user://game.log") -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return
	for entry in _log_entries:
		file.store_line("[%s] [%s] %s" % [entry["time"], entry["level"], entry["message"]])
	file.close()

func clear_logs() -> void:
	_log_entries.clear()
