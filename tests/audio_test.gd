extends SceneTree

var failures := 0


func _initialize() -> void:
	_run.call_deferred()


func _check(value: bool, message: String) -> void:
	print("PASS: " if value else "FAIL: ", message)
	if not value:
		failures += 1


func _run() -> void:
	var audio = root.get_node("GameAudio")
	_check(audio.music_player.playing, "BGM starts automatically")
	_check(audio.music_player.stream is AudioStreamMP3, "BGM uses the supplied MP3")
	_check(audio.music_player.stream.loop, "BGM loops")
	_check(audio.music_player.stream.get_length() > 0, "BGM has playable audio")
	var dialogue = load("res://scenes/dialogue.tscn").instantiate()
	root.add_child(dialogue)
	dialogue.choose(0)
	_check(not audio.click_player.playing, "Inactive choices remain silent")
	dialogue.begin(&"audio_test", [{"text": "Test", "choices": [
		{"label": "First", "reply": [{"text": "Reply"}]},
		{"label": "Second", "reply": [{"text": "Reply"}]}
	]}])
	dialogue.choose(-1)
	_check(not audio.click_player.playing, "Invalid choices remain silent")
	dialogue.choice_buttons[0].pressed.emit()
	_check(audio.click_player.playing, "Mouse choice triggers feedback")
	dialogue.cancel()
	dialogue.queue_free()
	await process_frame
	_check(audio.music_player.playing, "Music survives dialogue removal")
	var music_player = audio.music_player
	change_scene_to_file("res://scenes/town.tscn")
	await process_frame
	await process_frame
	_check(audio.music_player == music_player and music_player.playing, "Map change keeps the same music player")
	quit(1 if failures else 0)
