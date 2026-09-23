extends CanvasLayer
var world: Node
var opened := false
var button: Button
var log_button: Button
var save_dialog: FileDialog
var shade: ColorRect
var entries: VBoxContainer
var scroll: ScrollContainer
const Journal = preload("res://scripts/clue_journal.gd")

func _ready() -> void:
	layer = 30
	button = Button.new()
	button.text = "線索"
	button.position = Vector2(855, 490)
	button.size = Vector2(85, 36)
	button.add_theme_font_override("font", world.objective.get_theme_font("font"))
	button.pressed.connect(open_book)
	add_child(button)
	log_button = Button.new()
	log_button.text = "記錄"
	log_button.position = Vector2(760, 490)
	log_button.size = Vector2(85, 36)
	log_button.add_theme_font_override("font", world.objective.get_theme_font("font"))
	log_button.pressed.connect(download_log)
	add_child(log_button)
	if not OS.has_feature("web"):
		save_dialog = FileDialog.new()
		save_dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
		save_dialog.access = FileDialog.ACCESS_FILESYSTEM
		save_dialog.use_native_dialog = true
		save_dialog.mode_overrides_title = false
		save_dialog.title = "儲存遊戲記錄"
		save_dialog.filters = PackedStringArray(["*.txt;文字檔;text/plain"])
		save_dialog.file_selected.connect(_save_log_to)
		add_child(save_dialog)
	shade = ColorRect.new()
	shade.color = Color(0.02, 0.04, 0.035, 0.86)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(shade)
	var panel := Panel.new()
	panel.position = Vector2(100, 35)
	panel.size = Vector2(760, 470)
	var style := StyleBoxFlat.new()
	style.bg_color = Color("192b28")
	style.border_color = Color("bdab78")
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	panel.add_theme_stylebox_override("panel", style)
	shade.add_child(panel)
	var title := Label.new()
	title.text = "線索簿｜所見與來處"
	title.position = Vector2(24, 16)
	title.add_theme_font_override("font", world.objective.get_theme_font("font"))
	title.add_theme_font_size_override("font_size", 22)
	panel.add_child(title)
	var close := Button.new()
	close.text = "關閉 Esc"
	close.position = Vector2(625, 14)
	close.size = Vector2(110, 34)
	close.pressed.connect(close_book)
	panel.add_child(close)
	scroll = ScrollContainer.new()
	scroll.position = Vector2(24, 65)
	scroll.size = Vector2(712, 380)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	panel.add_child(scroll)
	entries = VBoxContainer.new()
	entries.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	entries.add_theme_constant_override("separation", 14)
	scroll.add_child(entries)
	shade.hide()

func _process(_delta: float) -> void:
	button.visible = not opened and not world.dialogue.active and not world.director.busy
	log_button.visible = button.visible


func download_log() -> void:
	if OS.has_feature("web"):
		_show_save_result(ActivityLog.download_web())
		return
	var downloads := OS.get_system_dir(OS.SYSTEM_DIR_DOWNLOADS)
	if not downloads.is_empty():
		save_dialog.current_dir = downloads
	save_dialog.current_file = ActivityLog.suggested_filename()
	save_dialog.popup_centered(Vector2i(720, 480))
	log_button.release_focus()


func _save_log_to(path: String) -> void:
	_show_save_result(ActivityLog.save_to(path))


func _show_save_result(saved_to: String) -> void:
	log_button.text = "已下載" if not saved_to.is_empty() else "失敗"
	log_button.release_focus()
	await get_tree().create_timer(1.5).timeout
	if is_instance_valid(log_button):
		log_button.text = "記錄"

func open_book() -> void:
	if world.dialogue.active or world.director.busy: return
	Journal.collect(world.story_flags, world.story_stage, world.story.dialogues)
	for child in entries.get_children():
		entries.remove_child(child)
		child.queue_free()
	var records: Dictionary = world.story_flags.get("_clue_journal", {})
	if records.is_empty(): add_text("尚未取得線索。與掌門交談，再循人物與物件查訪。", Color("dedbcc"))
	for item in records.values():
		add_text(item.title, Color("f5d47d"))
		add_text(item.body, Color("ede9dd"))
		add_text("取得方式｜" + item.source, Color("9de2cd"))
		entries.add_child(HSeparator.new())
	scroll.scroll_vertical = 0
	opened = true
	world.player.movement_enabled = false
	shade.show()

func add_text(value: String, color: Color) -> void:
	var label := Label.new()
	label.text = value
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.add_theme_font_override("font", world.objective.get_theme_font("font"))
	label.add_theme_font_size_override("font_size", 17)
	label.add_theme_color_override("font_color", color)
	entries.add_child(label)

func close_book() -> void:
	opened = false
	shade.hide()
	world.player.movement_enabled = not world.dialogue.active and not world.director.busy
	button.release_focus()

func _input(event: InputEvent) -> void:
	if not opened: return
	if event.is_action_pressed("cancel_dialogue"):
		close_book()
		get_viewport().set_input_as_handled()
	elif event is InputEventKey and not event.is_action_pressed("ui_up") and not event.is_action_pressed("ui_down") and not event.is_action_pressed("ui_accept") and not event.is_action_pressed("ui_focus_next"):
		get_viewport().set_input_as_handled()
