extends Node
class_name MyGlobal

var resources: MyGlobalResource = null

const RESOURCE_UID:String = "uid://dtypd2ue5m3p1"
var MDK_PATH:String

const LOGGING_INFO := false
const LOGGING_WARN := true
const LOGGING_ERROR := true
const LOGGING_DEBUG := true

func _ready() -> void:
	if not LOGGING_DEBUG: print("* logging DEBUG is disabled")
	if not LOGGING_INFO:  print("* logging INFO is disabled")
	if not LOGGING_WARN:  print("* logging WARN is disabled")
	if not LOGGING_ERROR: print("* logging ERROR is disabled")

	if resources == null and ResourceLoader.exists(RESOURCE_UID):
		resources = ResourceLoader.load(RESOURCE_UID) as MyGlobalResource
	on_pause.connect(on_paused_handler)

	var try_dirs := [
		# Local (for development purposes).
		"res://MDK",
		# Windows GOG path.
		"C:/GOG Games/MDK",
		# Windows GOG path (via WINE).
		OS.get_environment("HOME").path_join(".wine/drive_c/GOG Games/MDK"),
		OS.get_executable_path().get_base_dir(),
		OS.get_executable_path().get_base_dir().path_join("MDK"),
		OS.get_environment("PWD"),
		OS.get_environment("CD"),
	]
	if(FileAccess.file_exists("res://MDK/mdk_path.txt")):
		var paths = FileAccess.get_file_as_string("res://MDK/mdk_path.txt").split("\n")
		for path in paths:
			try_dirs.append(path)
	for try_dir in try_dirs:
		var traverse = try_dir.path_join("TRAVERSE")
		var stream = try_dir.path_join("STREAM")
		var misc = try_dir.path_join("MISC")
		var fall3d = try_dir.path_join("FALL3D")
		if [traverse, stream, misc, fall3d].all(DirAccess.dir_exists_absolute):
			MDK_PATH = try_dir
			break

	if not MDK_PATH.is_empty():
		MyGlobal.print_info("Using MDK installation folder: %s" % ProjectSettings.globalize_path(MDK_PATH))
	else:
		var msg = "Couldn't find a MDK installation folder! You need the full version of MDK from GOG or Steam to play.\nIt can be installed in the default location or copied in the Godot project folder as \"mdk\"."
		if OS.has_feature("editor"):
			printerr(msg)
		else:
			OS.alert(msg)
		get_tree().quit(1)

# Settings.file.get_value("game", "skill", Skill.MEDIUM)

var is_paused: bool

signal on_pause(paused:bool)
signal on_death()
signal on_fall3d_complete(l:MDKFiles.Levels)
signal on_level_complete(l:MDKFiles.Levels)
signal on_stream_complete(l:MDKFiles.Levels)

var last_level: MDKFiles.Levels
func change_scene_main_menu(ctx:Node):
	ctx.get_tree().change_scene_to_packed(resources.main_menu)

func quit_game():
	get_tree().quit()

func change_scene_level_load(ctx:Node, v:MDKFiles.Levels):
	last_level = v
	LevelLoad._static_load_level_has_value = true
	LevelLoad._static_load_level = v
	on_paused_handler(false)
	ctx.get_tree().change_scene_to_packed(resources.load_level)


func restart_level(ctx:Node):
	LevelLoad._static_load_level_has_value = true
	LevelLoad._static_load_level = last_level
	on_paused_handler(false)
	ctx.get_tree().change_scene_to_packed(resources.load_level)


func on_paused_handler(ispaused:bool):
	is_paused = ispaused

	if is_paused:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

## Prints an info message with optional object details and rich text formatting.
## @param message: The message to print, can be a string or object.
## @param prefix: Custom prefix for the message (default: "INFO").
static func print_debug(message, prefix: String = "DEBUG") -> void:
	if not LOGGING_DEBUG:
		return
	var output = _format_message(message, prefix, "green")
	print_rich(output)

## Prints an info message with optional object details and rich text formatting.
## @param message: The message to print, can be a string or object.
## @param prefix: Custom prefix for the message (default: "INFO").
static func print_info(message, prefix: String = "INFO") -> void:
	if not LOGGING_INFO:
		return
	var output = _format_message(message, prefix, "gray")
	print_rich(output)

## Prints a warning message with optional object details and rich text formatting.
## @param message: The message to print, can be a string or object.
## @param prefix: Custom prefix for the message (default: "WARNING").
static func print_warn(message, prefix: String = "WARNING") -> void:
	if not LOGGING_WARN:
		return
	var output = _format_message(message, prefix, "yellow")
	print_rich(output)

## Prints an error message with optional object details, using Godot's error system.
## @param message: The message to print, can be a string or object.
## @param prefix: Custom prefix for the message (default: "ERROR").
static func print_error(message, prefix: String = "ERROR") -> void:
	if not LOGGING_ERROR:
		return
	var output = _format_message(message, prefix, "red")
	push_error(output)
	print_rich(output)

## Internal helper to format messages, including object inspection.
## @param message: The message or object to format.
## @param prefix: The prefix for the message.
## @param color: The color for rich text output.
## @returns: Formatted string with rich text.
static func _format_message(message, prefix: String, color: String) -> String:
	var formatted = "[color=%s][%s][/color] " % [color, prefix]
	
	if message is Object:
		formatted += _format_object(message)
	else:
		formatted += str(message)
	
	return formatted

## Formats an object's properties for readable output.
## @param obj: The object to inspect.
## @returns: String representation of the object's properties.
static func _format_object(obj: Object) -> String:
	if obj == null:
		return "[null]"
	
	var output = "[%s@%s]" % [obj.get_class(), obj.get_instance_id()]
	var props = []
	
	for property in obj.get_property_list():
		if property.usage & PROPERTY_USAGE_SCRIPT_VARIABLE:
			props.append("%s: %s" % [property.name, obj.get(property.name)])
	
	if props.size() > 0:
		output += " { %s }" % ", ".join(props)
	
	return output