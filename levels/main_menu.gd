extends Control

const BASE_PATH := "D:/Projects/mdk/MDK-Game"

@export var background_rect :TextureRect
@export var godot_converter: GodotConverterHelpers
@export var main_menu_parent: Node
@export var levels_parent: Node
@export var load_scene: PackedScene

var files:MDKFiles

var normal_scale := Vector2(1.0, 1.0)
var grow_scale := Vector2(1.2, 1.2)

var buttons :Array[Button] = []

func _ready():
	for button:Button in find_children("*", "Button", true, false):
		button.pivot_offset = button.size/2;
		button.focus_entered.connect(_on_button_focus.bind(button))
		button.focus_exited.connect(_on_button_blur.bind(button))
		button.mouse_entered.connect(_on_button_focus.bind(button))
		button.mouse_exited.connect(_on_button_blur.bind(button))
		buttons.append(button)

	files = MDKFiles.get_instance()
	files.load_options_bni(BASE_PATH)
	files.load_globals(BASE_PATH)

	_load_background()
	_load_text()
	
func _on_button_focus(button: Node):
	_scale_to(button, grow_scale)

func _on_button_blur(button: Node):
	_scale_to(button, normal_scale)

func _scale_to(button: Node, target_scale: Vector2):
	var tween = button.create_tween()
	tween.tween_property(button, "scale", target_scale, 0.1)

	

func _load_background():
	var mdkimage := MDKImage.new("MDKOPT")
	var pal := files.options_bni.palette_images["MDKOPT"]
	mdkimage.width = pal.width
	mdkimage.height = pal.height
	mdkimage.data = pal.data

	var background_texture := await godot_converter.create_texture(self, mdkimage, pal.palette, {})
	
	background_rect.texture = background_texture
	background_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST


func _load_text():
	for child:Node in main_menu_parent.get_children():
		var label := child
		label.hide()

	var font := await godot_converter.create_bitmap_font(self, files.fti.fontbig, files.fti.sys_palette.colors);

	var default_theme := ThemeDB.get_default_theme()
	default_theme.set_font("font", "Label", font)
	default_theme.set_font_size("font_size", "Label", 20)
	default_theme.set_font("font", "Button", font)
	default_theme.set_font_size("font_size", "Button", 20)


	for child:Node in main_menu_parent.get_children():
		var label := child
		label.show()

func _on_level_pressed(level_number: int) -> void:
	var mdkLevel:MDKFiles.Levels
	match level_number: 
		1: mdkLevel = MDKFiles.Levels.LEVEL7
		2: mdkLevel = MDKFiles.Levels.LEVEL6
		3: mdkLevel = MDKFiles.Levels.LEVEL3
		4: mdkLevel = MDKFiles.Levels.LEVEL4
		5: mdkLevel = MDKFiles.Levels.LEVEL8
		6: mdkLevel = MDKFiles.Levels.LEVEL5
	Globals.change_scene_level_load(self, mdkLevel)


func _on_new_game_pressed() -> void:
	Globals.change_scene_level_load(self, MDKFiles.Levels.LEVEL7)


func _on_select_level_pressed() -> void:
	main_menu_parent.hide()
	levels_parent.show()


func _on_asset_browser_pressed() -> void:
	pass


func _on_quit_pressed() -> void:
	Globals.quit_game()
