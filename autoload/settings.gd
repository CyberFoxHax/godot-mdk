# Copyright © 2021 Hugo Locurcio and contributors - MIT License
# See `LICENSE.md` included in the source distribution for details.
extends Node

## The ConfigFile path to use for user configuration.
const CONFIG_PATH = "user://settings.ini"

var file := ConfigFile.new()


func _ready() -> void:
	# Keep the fullscreen toggle functional while the game is paused.
	process_mode = Node.PROCESS_MODE_ALWAYS

	# Loads existing configuration (if any) for use anywhere.
	# warning-ignore:return_value_discarded
	file.load(CONFIG_PATH)

	get_window().mode = Window.MODE_EXCLUSIVE_FULLSCREEN if (bool(file.get_value("video", "fullscreen", false))) else Window.MODE_WINDOWED


func _input(event: InputEvent) -> void:
	# Fullscreen toggle.
	# This can be done from anywhere, so it should be in a singleton.
	if event.is_action_pressed("toggle_fullscreen"):
		set_fullscreen(!((get_window().mode == Window.MODE_EXCLUSIVE_FULLSCREEN) or (get_window().mode == Window.MODE_FULLSCREEN)))


## Sets fullscreen status and persists it to the settings file automatically.
func set_fullscreen(fullscreen: bool) -> void:
	get_window().mode = Window.MODE_EXCLUSIVE_FULLSCREEN if (fullscreen) else Window.MODE_WINDOWED
	set_value("video", "fullscreen", fullscreen)


## Automatically saves the ConfigFile to the default path after setting the value.
## This method should be used over `Settings.file.set_value()` as it's more resilient
## to crashes.
func set_value(section: String, key: String, value) -> void:
	file.set_value(section, key, value)
	var file_error := file.save(CONFIG_PATH)

	if file_error != OK:
		push_error("An error occurred while trying to save configuration files (error code %d)." % file_error)
