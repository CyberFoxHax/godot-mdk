extends Node3D

@export var camera: Camera3D
@export var speed: float = 10.0
@export var run_speed: float = 40.0
@export var jump_speed: float = 5.0
@export var mouse_sensitivity: float = 0.005

var velocity: Vector3 = Vector3.ZERO
var mouse_captured: bool = true

func _ready():
    Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _input(event):
    if event is InputEventMouseMotion and mouse_captured:
        rotate_y(-event.relative.x * mouse_sensitivity)
        camera.rotate_x(-event.relative.y * mouse_sensitivity)
        camera.rotation.x = clamp(camera.rotation.x, -PI/2, PI/2)
    
    if event is InputEventKey and event.is_action_pressed("pause"):
        mouse_captured = not mouse_captured
        Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED if mouse_captured else Input.MOUSE_MODE_VISIBLE)
    
    if event is InputEventMouseButton and event.pressed and not mouse_captured:
        mouse_captured = true
        Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _physics_process(delta):
    var move_dir = Vector3.ZERO
    
    if mouse_captured:
        var forward = -camera.global_transform.basis.z.normalized()
        var right = camera.global_transform.basis.x.normalized()
        
        if Input.is_action_pressed("move_forward"):
            move_dir += forward
        if Input.is_action_pressed("move_backward"):
            move_dir -= forward
        if Input.is_action_pressed("move_left"):
            move_dir -= right
        if Input.is_action_pressed("move_right"):
            move_dir += right
        if Input.is_action_pressed("jump"):
            move_dir += Vector3.UP
            
        move_dir = move_dir.normalized()
        
        var current_speed = run_speed if Input.is_action_pressed("run") else speed
        velocity = move_dir * current_speed
        
    global_transform.origin += velocity * delta