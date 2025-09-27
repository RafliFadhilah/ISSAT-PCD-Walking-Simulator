class_name PlayerControllerRefactored
extends CharacterBody3D

## 🎮 Movement Settings
@export_group("Movement")
@export var move_speed: float = 8.0
@export var run_speed: float = 16.0
@export var jump_force: float = 15.0
@export var acceleration: float = 25.0
@export var deceleration: float = 30.0
@export var air_control: float = 0.3

## 📷 Camera Settings
@export_group("Camera")
@export var mouse_sensitivity: float = 0.002
@export var camera_distance: float = 6.0
@export var camera_height: float = 2.0
@export var camera_smoothness: float = 8.0
@export var max_pitch: float = 70.0
@export var min_pitch: float = -30.0

## 🔧 Physics Settings
@export_group("Physics")
@export var gravity: float = 40.0
@export var max_fall_speed: float = 50.0

## 🎯 Internal Variables
var current_speed: float = 0.0
var target_speed: float = 0.0
var velocity_horizontal: Vector2 = Vector2.ZERO
var camera_rotation: Vector2 = Vector2.ZERO
var is_running: bool = false
var is_grounded: bool = false

## 📱 Input Variables
var move_input: Vector2 = Vector2.ZERO
var look_input: Vector2 = Vector2.ZERO

## 🎥 Camera References
@onready var camera_pivot: Node3D = $CameraPivot
@onready var camera_arm: SpringArm3D = $CameraPivot/CameraArm
@onready var camera: Camera3D = $CameraPivot/CameraArm/Camera3D

func _ready():
	## Initialize the player controller with Godot 4.4.1 improvements
	print("🎮 PlayerControllerRefactored initialized")
	
	# Physics interpolation is enabled via project settings
	# No need to call RenderingServer.set_physics_interpolation() in 4.4.1
	
	# Set mouse mode to captured for smooth camera control
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	# Setup camera
	setup_camera()
	
	# Initialize physics with stable starting state
	velocity = Vector3.ZERO
	
	# Ensure we start on the ground
	if is_on_floor():
		velocity.y = 0.0
	
	print("✅ Player ready for exploration with jitter-free movement!")

func setup_camera():
	## Setup the following camera system
	if not camera_pivot:
		print("❌ CameraPivot not found - creating fallback camera")
		create_fallback_camera()
		return
	
	# Configure camera arm
	if camera_arm:
		camera_arm.spring_length = camera_distance
		camera_arm.position.y = camera_height
		print("✅ Camera arm configured")
	
	# Configure camera with jitter reduction settings
	if camera:
		camera.current = true
		camera.near = 0.1
		camera.far = 1000.0
		# Camera process callback is handled automatically in Godot 4.4.1
		print("✅ Camera configured")

func create_fallback_camera():
	## Create a fallback camera if the scene structure is missing
	print("🔧 Creating fallback camera system...")
	
	# Create camera pivot
	var pivot = Node3D.new()
	pivot.name = "CameraPivot"
	add_child(pivot)
	
	# Create camera arm
	var arm = SpringArm3D.new()
	arm.name = "CameraArm"
	arm.spring_length = camera_distance
	arm.position.y = camera_height
	arm.shape = SphereShape3D.new()
	arm.shape.radius = 0.1
	arm.margin = 0.1
	pivot.add_child(arm)
	
	# Create camera
	var cam = Camera3D.new()
	cam.name = "Camera"
	cam.current = true
	cam.near = 0.1
	cam.far = 1000.0
	arm.add_child(cam)
	
	# Update references
	camera_pivot = pivot
	camera_arm = arm
	camera = cam
	
	print("✅ Fallback camera system created")

func _physics_process(delta: float):
	## Main physics update loop
	var old_position = global_position
	
	handle_movement(delta)
	handle_camera_follow(delta)
	apply_gravity(delta)
	
	# Use move_and_slide with Godot 4.4.1 jitter fixes
	# The new parameters help reduce jitter and improve smoothness
	move_and_slide()
	
	# Minimal logging to avoid performance issues
	var is_grounded = is_on_floor()
	if is_grounded:
		print("GROUNDED! Position: ", global_position, " Velocity: ", velocity)

func handle_movement(delta: float):
	## Handle player movement - simplified like demo for stability
	# Get input
	move_input = get_movement_input()
	
	# Simple direct movement like the demo
	if move_input.length() > 0.1:
		var move_direction = get_movement_direction()
		var speed = run_speed if is_running else move_speed
		
		# Direct velocity assignment like demo
		velocity.x = move_direction.x * speed
		velocity.z = move_direction.y * speed
		
		# Movement logging removed for performance
	else:
		# Stop horizontal movement
		velocity.x = 0.0
		velocity.z = 0.0
	
	# Handle jumping
	handle_jumping()

func get_movement_input() -> Vector2:
	## Get movement input from WASD keys with improved reliability
	var input = Vector2.ZERO
	
	# Use input actions instead of direct key presses for better reliability
	if Input.is_action_pressed("move_forward"):
		input.y -= 1
	if Input.is_action_pressed("move_back"):
		input.y += 1
	if Input.is_action_pressed("move_left"):
		input.x -= 1
	if Input.is_action_pressed("move_right"):
		input.x += 1
	
	# Check for running
	is_running = Input.is_action_pressed("sprint")
	
	var normalized_input = input.normalized()
	# Only log input when it changes to reduce spam
	if normalized_input.length() > 0 and normalized_input != move_input:
		GameLogger.debug("Input changed: %s" % normalized_input)
	
	return normalized_input

func get_movement_direction() -> Vector2:
	## Calculate movement direction relative to camera
	if not camera:
		GameLogger.debug("No camera found, using raw input")
		return move_input
	
	# Get camera basis vectors
	var camera_basis = camera.global_transform.basis
	var forward = Vector2(-camera_basis.z.x, -camera_basis.z.z).normalized()
	var right = Vector2(camera_basis.x.x, camera_basis.x.z).normalized()
	
	# Calculate movement direction
	var movement_direction = forward * -move_input.y + right * move_input.x
	
	# Log camera-based movement calculation
	GameLogger.debug("Camera forward: %s, right: %s, movement: %s" % [forward, right, movement_direction])
	
	return movement_direction

func handle_jumping():
	## Handle jumping mechanics
	if Input.is_action_just_pressed("ui_accept") or Input.is_action_just_pressed("ui_select"):
		if is_on_floor():
			velocity.y = jump_force
			print("🦘 Jump!")

func apply_gravity(delta: float):
	## Apply gravity like the demo - simple and effective
	# Simple gravity like demo: velocity.y -= 40 * delta
	velocity.y -= gravity * delta
	
	# Gravity logging removed for performance

func handle_camera_follow(delta: float):
	## Handle camera following the player smoothly with jitter reduction
	if not camera_pivot:
		return
	
	# Update camera rotation based on look input with improved smoothing
	if look_input.length() > 0:
		# Rotate player horizontally (Y rotation) with smooth interpolation
		var target_y_rotation = -look_input.x * mouse_sensitivity
		rotate_y(target_y_rotation)
		
		# Rotate camera pivot vertically (X rotation) with clamping
		var target_x_rotation = camera_pivot.rotation.x - look_input.y * mouse_sensitivity
		target_x_rotation = clamp(target_x_rotation, deg_to_rad(min_pitch), deg_to_rad(max_pitch))
		camera_pivot.rotation.x = target_x_rotation
		
		# Clear look input
		look_input = Vector2.ZERO
	
	# Smooth camera follow with improved stability
	if camera_arm:
		var target_position = Vector3(0, camera_height, 0)
		# Use more stable interpolation for camera positioning
		camera_arm.position = camera_arm.position.lerp(target_position, camera_smoothness * delta)
		
		# Ensure camera arm maintains stable distance
		if abs(camera_arm.spring_length - camera_distance) > 0.1:
			camera_arm.spring_length = lerp(camera_arm.spring_length, camera_distance, camera_smoothness * delta)

func _input(event: InputEvent):
	## Handle input events
	if event is InputEventMouseMotion:
		# Handle mouse look
		look_input = event.relative
		get_viewport().set_input_as_handled()
	
	elif event is InputEventKey:
		if event.pressed:
			handle_key_input(event.keycode)

func handle_key_input(keycode: int):
	## Handle keyboard input
	match keycode:
		KEY_ESCAPE:
			exit_scene()
		KEY_M:
			toggle_mouse_mode()
		KEY_V:
			toggle_camera_view()
		KEY_F:
			toggle_fullscreen()
		KEY_T:
			print_debug_info()

func toggle_mouse_mode():
	## Toggle between captured and visible mouse modes
	var current_mode = Input.get_mouse_mode()
	var new_mode = Input.MOUSE_MODE_VISIBLE if current_mode == Input.MOUSE_MODE_CAPTURED else Input.MOUSE_MODE_CAPTURED
	Input.set_mouse_mode(new_mode)
	print("🖱️ Mouse mode: %s" % ("Visible" if new_mode == Input.MOUSE_MODE_VISIBLE else "Captured"))

func toggle_camera_view():
	## Toggle between first and third person views
	if camera_arm:
		var target_distance = 0.0 if camera_arm.spring_length > 0 else camera_distance
		var tween = create_tween()
		tween.tween_property(camera_arm, "spring_length", target_distance, 0.3)
		print("📷 Camera view: %s" % ("First Person" if target_distance == 0.0 else "Third Person"))

func toggle_fullscreen():
	## Toggle fullscreen mode
	var viewport = get_viewport()
	if viewport and viewport.window:
		viewport.window.mode = Window.MODE_FULLSCREEN if viewport.window.mode != Window.MODE_FULLSCREEN else Window.MODE_WINDOWED
		print("🖥️ Fullscreen: %s" % ("ON" if viewport.window.mode == Window.MODE_FULLSCREEN else "OFF"))

func exit_scene():
	## Exit the current scene
	print("🚪 Exiting scene...")
	get_tree().quit()

func print_debug_info():
	## Print debug information about the player state
	print("=== PLAYER DEBUG INFO ===")
	print("Position: %s" % global_position)
	print("Velocity: %s" % velocity)
	print("Speed: %.2f" % current_speed)
	print("Running: %s" % is_running)
	print("Grounded: %s" % is_on_floor())
	print("Camera Rotation: %s" % camera_pivot.rotation if camera_pivot else "No camera")
	print("========================")

## 🎯 Public API Functions

func get_player_position() -> Vector3:
	## Get the current player position
	return global_position

func set_player_position(new_position: Vector3):
	## Set the player position (useful for teleportation)
	global_position = new_position
	print("🚀 Player teleported to: %s" % new_position)

func get_movement_speed() -> float:
	## Get the current movement speed
	return current_speed

func set_movement_speed(new_speed: float):
	## Set the movement speed
	move_speed = new_speed
	run_speed = new_speed * 2.0
	print("⚡ Movement speed set to: %.2f" % new_speed)

func is_player_running() -> bool:
	## Check if the player is currently running
	return is_running

func get_camera_distance() -> float:
	## Get the current camera distance
	return camera_arm.spring_length if camera_arm else camera_distance

func set_camera_distance(new_distance: float):
	## Set the camera distance
	if camera_arm:
		camera_arm.spring_length = new_distance
		print("📏 Camera distance set to: %.2f" % new_distance)

## 🎮 Input Action Mapping
## Make sure these actions are defined in Project Settings > Input Map:
## - move_forward (W key)
## - move_back (S key)  
## - move_left (A key)
## - move_right (D key)
## - jump (Space key)
## - sprint (Shift key)
