class_name HUD
extends Control

@export var start_menu_parent: Control
@export var main_menu_scene: PackedScene

var normal_scale := Vector2(1.0, 1.0)
var grow_scale := Vector2(1.2, 1.2)

func start_menu_visible(v:bool):
	start_menu_parent.visible = v
	

func _ready() -> void:
	start_menu_visible(false)
	Globals.on_pause.connect(_on_paused)
	
	for button:Button in find_children("*", "Button", true, false):
		button.pivot_offset = button.size/2;
		button.focus_entered.connect(_on_button_focus.bind(button))
		button.focus_exited.connect(_on_button_blur.bind(button))
		button.mouse_entered.connect(_on_button_focus.bind(button))
		button.mouse_exited.connect(_on_button_blur.bind(button))
		
func _on_button_focus(button: Node):
	_scale_to(button, grow_scale)

func _on_button_blur(button: Node):
	_scale_to(button, normal_scale)

func _scale_to(button: Node, target_scale: Vector2):
	var tween = button.create_tween()
	tween.tween_property(button, "scale", target_scale, 0.1)

func _on_paused(ispaused:bool):
	start_menu_parent.visible = ispaused

func _on_resume_pressed() -> void:
	Globals.on_pause.emit(false)

func _on_restart_pressed() -> void:
	Globals.restart_level(self)

func _on_title_screen_pressed() -> void:
	Globals.change_scene_main_menu(self)

func _on_quit_game_pressed() -> void:
	Globals.quit_game()
