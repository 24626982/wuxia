extends Node
## Keeps a small, session-only activity log and exports it as a UTF-8 text file.

var entries: PackedStringArray = []
var session_started_at := ""


func start_session() -> void:
	entries.clear()
	session_started_at = _timestamp()
	entries.append("[%s] 開始遊戲" % session_started_at)


func record_interaction(display_name: String) -> void:
	if entries.is_empty():
		start_session()
	var clean_name := display_name.replace(" · ", " ").replace("・", " ").strip_edges()
	entries.append("[%s] 與〖%s〗互動" % [_timestamp(), clean_name])


func contents() -> String:
	return "\n".join(entries) + ("\n" if not entries.is_empty() else "")


func suggested_filename() -> String:
	if entries.is_empty():
		start_session()
	return "遊戲記錄_%s.txt" % session_started_at.replace("-", "").replace(" ", "_").replace(":", "")


func download_web() -> String:
	var filename := suggested_filename()
	JavaScriptBridge.download_buffer(contents().to_utf8_buffer(), filename, "text/plain;charset=utf-8")
	return filename


func save_to(path: String) -> String:
	if not path.to_lower().ends_with(".txt"):
		path += ".txt"
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_error("無法寫入遊戲記錄：" + path)
		return ""
	file.store_buffer(contents().to_utf8_buffer())
	return path


func _timestamp() -> String:
	var now := Time.get_datetime_dict_from_system()
	return "%04d-%02d-%02d %02d:%02d" % [now.year, now.month, now.day, now.hour, now.minute]
