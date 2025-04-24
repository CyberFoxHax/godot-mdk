# Copyright © 2021 Hugo Locurcio and contributors - MIT License
# See `LICENSE.md` included in the source distribution for details.
extends Node3D

const MOUSE_SENSITIVITY = 0.002
const RUN_SPEED = 8
const JUMP_VELOCITY = 0.7
const GRAVITY = 80

@export var bullet_scene: PackedScene


@onready var player_model := $MeshInstance3D as Node3D
@onready var kinematic_body := $CharacterBody3D as CharacterBody3D
@onready var pivot := $Pivot as Node3D
@onready var camera := $Pivot/Camera3D as Camera3D
@onready var hitscan_raycast := $Pivot/HitscanRayCast as RayCast3D
@onready var raycast_nw := $CharacterBody3D/RayCastNW as RayCast3D
@onready var raycast_ne := $CharacterBody3D/RayCastNE as RayCast3D
@onready var raycast_sw := $CharacterBody3D/RayCastSW as RayCast3D
@onready var raycast_se := $CharacterBody3D/RayCastSE as RayCast3D

## The player's current velocity in units per second.
var velocity := Vector3()

## If `true`, the player is currently in sniper mode (no movement possible).
var sniper_mode := false: set = set_sniper_mode

## Time waiting before the player can fire again (in seconds).
## All weapons are fully automatic in MDK, so the player does not need to click again to fire
## (they can just hold down the fire button).
var refire_timer := 0.0

var camera_speed:Vector2;
var life := 0.0
const grace_peried = 0.4


func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	pivot.rotation = rotation
	rotation = Vector3()

func _process(delta: float) -> void:
	life += delta
	refire_timer = max(0.0, refire_timer - delta)

	# Apply Doom-style friction.
	velocity.x *= 1 - 10 * delta
	velocity.y *= 1 - 0.5 * delta
	velocity.z *= 1 - 10 * delta

	# emulate MDK's weird camera
	if life > grace_peried:
		camera_speed *= delta*12
		camera.rotation.z = lerp(camera.rotation.z,-camera_speed.x/100, 0.1);
	else:
		camera_speed = Vector2(0,0)

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
	pivot.position = pivot.position.lerp(kinematic_body.position, 20*delta)
	player_model.position = player_model.position.lerp(kinematic_body.position, 50*delta)
	
	var direction = player_model.global_position - camera.global_position
	direction = direction.normalized()

	var angle = atan2(direction.x, direction.z)
	player_model.rotation = Vector3(0, angle+PI, camera.rotation.z)

	

func _input(event: InputEvent) -> void:
	if life < grace_peried:
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

	if event.is_action_pressed("toggle_mouse_capture"):
		if Input.get_mouse_mode() == Input.MOUSE_MODE_VISIBLE:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)


## Returns `true` if at least one of the raycasts is colliding, `false` otherwise.
## This is used for more reliable jump detection when walking on ledges.
func is_any_raycast_colliding() -> bool:
	for raycast in [raycast_nw, raycast_ne, raycast_sw, raycast_se]:
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
