extends SceneTree
## Audits authored runtime files, not the editor's auto-generated UID metadata.

var failures: int = 0


func _initialize() -> void:
	for folder in ["res://scripts", "res://scenes"]:
		for file_name in DirAccess.get_files_at(folder):
			if not (file_name.ends_with(".gd") or file_name.ends_with(".tscn")):
				continue
			var path: String = folder.path_join(file_name)
			var source := FileAccess.get_file_as_string(path)
			_check(not source.contains("uid://"), "Path-based authored references: " + path)
			for network_token in ["http://", "https://", "HTTPRequest", "HTTPClient", "WebSocket", "TCPServer", "StreamPeerTCP", "PacketPeerUDP", "OS.shell_open"]:
				_check(not source.contains(network_token), "No " + network_token + " in " + file_name, false)
			if source.contains("JavaScriptBridge"):
				_check(file_name == "activity_log.gd" and source.contains("download_buffer") and not source.contains(".eval"), "Browser bridge is limited to local log download")
			if file_name.ends_with(".tscn"):
				var regex := RegEx.new()
				regex.compile('path="([^"]+)"')
				for match_result in regex.search_all(source):
					var resource_path := match_result.get_string(1)
					_check(resource_path.begins_with("res://") and FileAccess.file_exists(resource_path), "Dependency exists locally: " + resource_path)
	var story_path := "res://data/prologue.json"
	_check(FileAccess.file_exists(story_path), "Story JSON exists locally")
	_check(JSON.parse_string(FileAccess.get_file_as_string(story_path)) is Dictionary, "Story JSON parses locally")
	_check(JSON.parse_string(FileAccess.get_file_as_string("res://data/residence.json")) is Dictionary, "Residence JSON parses locally")
	var config := ConfigFile.new()
	_check(config.load("res://export_presets.cfg") == OK, "Native export preset exists")
	_check(config.get_value("preset.0", "platform") == "Windows Desktop", "Exports native desktop, not Web")
	var include_filters: PackedStringArray = String(config.get_value("preset.0", "include_filter")).split(",")
	_check("data/*.json" in include_filters, "Story JSON is included in build")
	_check(config.get_value("preset.0.options", "binary_format/embed_pck") == true, "Game resource pack embeds in executable")
	print("OFFLINE_AUDIT: ", "PASS" if failures == 0 else "FAIL", " (", failures, " failures)")
	quit(0 if failures == 0 else 1)


func _check(condition: bool, description: String, verbose: bool = true) -> void:
	if verbose or not condition:
		print("PASS: " if condition else "FAIL: ", description)
	if not condition:
		failures += 1
