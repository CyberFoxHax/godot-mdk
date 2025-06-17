# Copyright © 2021 Hugo Locurcio and contributors - MIT License
# See `LICENSE.md` included in the source distribution for details.
class_name Player
extends Node3D

const MOUSE_SENSITIVITY := 0.002
const RUN_SPEED := 8
const JUMP_VELOCITY := 0.7
const GRAVITY := 80
const GRACE_PERIOD = 0.4

@export var bullet_scene: PackedScene

@export var hud: HUD
@export var player_model: Node3D
@export var kinematic_body: CharacterBody3D
@export var pivot: Node3D
@export var camera: Camera3D
@export var hitscan_raycast: RayCast3D
@export var raycasts: Array[RayCast3D]

## The player's current velocity in units per second.
var velocity := Vector3()

var sniper_mode := false: set = set_sniper_mode

## Time waiting before the player can fire again (in seconds).
## All weapons are fully automatic in MDK, so the player does not need to click again to fire
## (they can just hold down the fire button).
var refire_timer := 0.0

var camera_speed:Vector2;
var time_alive := 0.0

func get_player_position() -> Vector3:
	return pivot.global_position

func set_y_rotation_degrees(v:float):
	pivot.rotation_degrees = Vector3(0,v,0)
	rotation = Vector3()

func _ready() -> void:
	Globals.on_paused_handler(false)
	rotation = Vector3()

func _process(delta: float) -> void:
	# emulate MDK's weird camera
	if time_alive > GRACE_PERIOD:
		camera_speed *= delta*12
		camera.rotation.z = lerp(camera.rotation.z,-camera_speed.x/100, 0.1);
	else:
		camera_speed = Vector2(0,0)

	pivot.position = pivot.position.lerp(kinematic_body.position, 20*delta)
	player_model.position = player_model.position.lerp(kinematic_body.position, 50*delta)
	
	var direction = player_model.global_position - camera.global_position
	direction = direction.normalized()

	var angle = atan2(direction.x, direction.z)
	player_model.rotation = Vector3(0, angle+PI, camera.rotation.z)

func _physics_process(delta: float) -> void:
	time_alive += delta
	refire_timer = max(0.0, refire_timer - delta)

	# Apply Doom-style friction.
	velocity.x *= 1 - 10 * delta
	velocity.y *= 1 - 0.5 * delta
	velocity.z *= 1 - 10 * delta

	# Apply movement keys.
	# Player can't move while in sniper mode, as in the original game.
	if not sniper_mode:
		velocity += (
			pivot.transform.basis.x * (Input.get_action_strength("move_right") - Input.get_action_strength("move_left")) * RUN_SPEED +
			pivot.transform.basis.z * (Input.get_action_strength("move_backward") - Input.get_action_strength("move_forward")) * RUN_SPEED
		)

	var any_raycast_colliding := is_any_raycast_colliding()

	# Apply jumping.
	if not sniper_mode and Input.is_action_just_pressed("jump") and any_raycast_colliding:
		# Movement is is applied only once.
		# Compensate for `move_and_slide()`'s automatic delta calculation.
		velocity.y += JUMP_VELOCITY / delta

	# Apply gravity.
	if not any_raycast_colliding:
		velocity.y -= GRAVITY * delta

	kinematic_body.set_velocity(velocity)
	kinematic_body.move_and_slide()

	if Input.is_action_pressed("attack") and is_zero_approx(refire_timer):
		if sniper_mode:
			refire_timer = 0.5
		else:
			refire_timer = 0.133333

		if hitscan_raycast.is_colliding():
			var bullet := bullet_scene.instantiate()
			get_parent().add_child(bullet)
			bullet.global_transform.origin = hitscan_raycast.get_collision_point()
	

func _input(event: InputEvent) -> void:
	if time_alive < GRACE_PERIOD:
		return
	if event is InputEventMouseMotion:
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			pivot.rotate(Vector3.UP, -event.relative.x * MOUSE_SENSITIVITY)
			camera_speed += event.relative

	if event.is_action_pressed("toggle_sniper_mode"):
		self.sniper_mode = not sniper_mode

	if event.is_action_pressed("use_item"):
		print("use_item")

	if event.is_action_pressed("previous_item"):
		print("previous_item")

	if event.is_action_pressed("next_item"):
		print("next_item")

	if event.is_action_pressed("pause"):
		Globals.on_pause.emit(!Globals.is_paused)



## Returns `true` if at least one of the raycasts is colliding, `false` otherwise.
## This is used for more reliable jump detection when walking on ledges.
func is_any_raycast_colliding() -> bool:
	for raycast in raycasts:
		if raycast.is_colliding():
			return true

	return false


func set_sniper_mode(p_sniper_mode: bool) -> void:
	sniper_mode = p_sniper_mode

	if sniper_mode:
		# Go first person and lower FOV.
		camera.fov = 25
		camera.position.z = 0
	else:
		# Go third person and default FOV.
		camera.fov = 75
		camera.position.z = 7
