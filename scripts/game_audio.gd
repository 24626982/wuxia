extends Node
## Persistent music and choice feedback across map changes.

const MUSIC = preload("res://assets/audio/game_bgm.mp3")
const CLICK = preload("res://assets/audio/choice_click.wav")

var music_player: AudioStreamPlayer
var click_player: AudioStreamPlayer


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	music_player = AudioStreamPlayer.new()
	music_player.name = "Music"
	var loop: AudioStreamMP3 = MUSIC.duplicate()
	loop.loop = true
	loop.loop_offset = 0.0
	music_player.stream = loop
	music_player.volume_db = -12.0
	add_child(music_player)
	music_player.play()
	click_player = AudioStreamPlayer.new()
	click_player.name = "ChoiceClick"
	click_player.stream = CLICK
	click_player.volume_db = -8.0
	add_child(click_player)


func play_choice_click() -> void:
	click_player.play()
