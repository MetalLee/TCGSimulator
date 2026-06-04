extends Node

signal save_completed(success: bool)
signal load_completed(success: bool)
signal save_reset

const SAVE_PATH: String = "user://save_game.json"
const SAVE_FILE_NAME: String = "save_game.json"


func _ready() -> void:
	if not load_game():
		save_game()


func save_game() -> bool:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("SaveService could not open save file for writing.")
		save_completed.emit(false)
		return false

	file.store_string(JSON.stringify(GameState.to_save_data(), "\t"))
	save_completed.emit(true)
	return true


func load_game() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		GameState.new_game()
		load_completed.emit(false)
		return false

	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		push_error("SaveService could not open save file for reading.")
		GameState.new_game()
		load_completed.emit(false)
		return false

	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		push_warning("SaveService ignored invalid save data.")
		GameState.new_game()
		load_completed.emit(false)
		return false

	GameState.load_from_data(parsed as Dictionary)
	load_completed.emit(true)
	return true


func reset_save() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		var dir := DirAccess.open("user://")
		if dir == null:
			push_warning("SaveService could not open user save directory.")
		else:
			var error: Error = dir.remove(SAVE_FILE_NAME)
			if error != OK:
				push_warning("SaveService could not remove save file. Error: %d" % int(error))

	GameState.new_game()
	save_reset.emit()
