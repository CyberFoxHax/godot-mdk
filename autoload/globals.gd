extends Node
class_name MyGlobal

var resources: MyGlobalResource = null

const RESOURCE_UID:String = "uid://dtypd2ue5m3p1"
var MDK_PATH:String

func _ready() -> void:
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
		print("Using MDK installation folder: %s" % ProjectSettings.globalize_path(MDK_PATH))
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
	print(v)
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
