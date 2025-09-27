extends Node3D

@onready var player: CharacterBody3D = $Player
@onready var camera_pivot: Node3D = $Player/CameraPivot
@onready var camera_arm: SpringArm3D = $Player/CameraPivot/CameraArm
@onready var camera: Camera3D = $Player/CameraPivot/CameraArm/Camera3D

# Simple movement settings (from working simple version)
var MOVE_SPEED: float = 6.0  # Reduced for better feel
var JUMP_SPEED: float = 3.0
var gravity: float = 35.0
var jump_cooldown: float = 0.0
var jump_delay: float = 0.3

# Complex camera settings (adjusted for better feel)
var mouse_sensitivity: float = 0.001  # Reduced from 0.002
var camera_distance: float = 6.0
var camera_height: float = 2.0
var camera_smoothness: float = 4.0    # Reduced from 8.0
var max_pitch: float = 70.0
var min_pitch: float = -30.0

# Camera variables
var camera_rotation: Vector2 = Vector2.ZERO
var target_camera_rotation: Vector2 = Vector2.ZERO

func _ready():
	print("Complex Camera Test initialized")
	print("Testing: Simple physics + Complex camera + Direct input")
	print("Controls: WASD = Move, SPACE = Jump, Mouse = Look, ESC = Exit")
	
	# Setup camera like PlayerControllerRefactored.gd
	setup_complex_camera()

func _physics_process(delta: float):
	# Simple movement like working version
	handle_simple_movement(delta)
	handle_simple_jumping(delta)
	apply_simple_gravity(delta)
	
	# Complex camera system
	handle_complex_camera(delta)
	
	# Move like the demo
	player.move_and_slide()
	
	# Logging
	log_camera_status()

func handle_simple_movement(delta: float):
	## Simple movement system (from working SimplePlayerTest.gd)
	var direction: Vector3 = get_camera_relative_input()
	var h_veloc: Vector2 = Vector2(direction.x, direction.z).normalized() * MOVE_SPEED
	
	# Set velocity like the demo
	player.velocity.x = h_veloc.x
	player.velocity.z = h_veloc.y

func handle_simple_jumping(delta: float):
	## Simple jumping system (from working SimplePlayerTest.gd)
	if Input.is_key_pressed(KEY_SPACE) and player.is_on_floor() and jump_cooldown <= 0.0:
		player.velocity.y = JUMP_SPEED + MOVE_SPEED * 0.016
		jump_cooldown = jump_delay
		print("SIMPLE JUMP! Velocity: ", player.velocity)
	
	# Update jump cooldown
	if jump_cooldown > 0.0:
		jump_cooldown -= delta

func apply_simple_gravity(delta: float):
	## Simple gravity (from working SimplePlayerTest.gd)
	player.velocity.y -= gravity * delta

func setup_complex_camera():
	## Setup complex camera system (from PlayerControllerRefactored.gd)
	if not camera_pivot or not camera_arm or not camera:
		print("❌ Complex camera setup failed - missing nodes")
		return
	
	# Set initial camera position
	camera_arm.spring_length = camera_distance
	camera_pivot.position.y = camera_height
	
	print("✅ Complex camera system initialized")

func handle_complex_camera(delta: float):
	## Complex camera handling (from PlayerControllerRefactored.gd)
	if not camera_pivot or not camera_arm or not camera:
		return
	
	# Handle mouse input for camera rotation
	handle_mouse_look()
	
	# Update camera rotation with smoothing
	camera_rotation = camera_rotation.lerp(target_camera_rotation, camera_smoothness * delta)
	
	# Apply camera rotation
	camera_pivot.rotation.y = camera_rotation.x
	camera_arm.rotation.x = camera_rotation.y

func handle_mouse_look():
	## Mouse look handling (from PlayerControllerRefactored.gd)
	var mouse_delta = Input.get_last_mouse_velocity()
	
	if mouse_delta.length() > 0:
		# Update target rotation
		target_camera_rotation.x -= mouse_delta.x * mouse_sensitivity
		target_camera_rotation.y -= mouse_delta.y * mouse_sensitivity
		
		# Clamp pitch
		target_camera_rotation.y = clamp(target_camera_rotation.y, deg_to_rad(min_pitch), deg_to_rad(max_pitch))

func get_camera_relative_input() -> Vector3:
	## Get input relative to complex camera system
	var input_dir: Vector3 = Vector3.ZERO
	
	if not camera:
		print("❌ No camera found for input")
		return input_dir
	
	# Use complex camera for input (like PlayerControllerRefactored.gd)
	if Input.is_key_pressed(KEY_A): # Left
		input_dir -= camera.global_transform.basis.x
	if Input.is_key_pressed(KEY_D): # Right
		input_dir += camera.global_transform.basis.x
	if Input.is_key_pressed(KEY_W): # Forward
		input_dir -= camera.global_transform.basis.z
	if Input.is_key_pressed(KEY_S): # Backward
		input_dir += camera.global_transform.basis.z
	
	return input_dir

func log_camera_status():
	## Log camera status for debugging
	if player.is_on_floor():
		if player.velocity.length() > 0.1:
			var jump_status = " (Can Jump)" if jump_cooldown <= 0.0 else " (Jump Cooldown: %.1f)" % jump_cooldown
			var camera_status = " (Camera: %.1f, %.1f)" % [camera_rotation.x, camera_rotation.y]
			print("CAMERA MOVING! Pos: ", player.global_position, " Vel: ", player.velocity, camera_status, jump_status)
		else:
			var jump_status = " (Can Jump)" if jump_cooldown <= 0.0 else " (Jump Cooldown: %.1f)" % jump_cooldown
			var camera_status = " (Camera: %.1f, %.1f)" % [camera_rotation.x, camera_rotation.y]
			print("CAMERA GROUNDED! Pos: ", player.global_position, " Vel: ", player.velocity, camera_status, jump_status)
	else:
		print("CAMERA FALLING: velocity.y=", player.velocity.y, " pos=", player.global_position)

func _input(event):
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_ESCAPE:
			print("ESC pressed - exiting complex camera test")
			get_tree().quit()
