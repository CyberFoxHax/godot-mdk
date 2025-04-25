extends Node
class_name MyGlobal

var resources: MyGlobalResource = null

const RESOURCE_UID:String = "uid://dtypd2ue5m3p1"

func _ready() -> void:
	if resources == null and ResourceLoader.exists(RESOURCE_UID):
		resources = ResourceLoader.load(RESOURCE_UID) as MyGlobalResource
	on_pause.connect(on_paused_handler)

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
