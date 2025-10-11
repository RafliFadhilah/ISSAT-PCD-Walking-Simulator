extends Node3D

@onready var player: CharacterBody3D = $Player
@onready var camera: Camera3D = $Player/Camera3D

# Simple movement settings (from working simple version)
var MOVE_SPEED: float = 8.0
var JUMP_SPEED: float = 3.0
var gravity: float = 35.0
var jump_cooldown: float = 0.0
var jump_delay: float = 0.3

# Input action variables
var move_input: Vector2 = Vector2.ZERO
var is_running: bool = false

func _ready():
	print("Input Actions Test initialized")
	print("Testing: Simple physics + Simple camera + Input actions")
	print("Controls: WASD = Move, SPACE = Jump, ESC = Exit")
	print("Note: Requires input actions in project.godot")

func _physics_process(delta: float):
	# Get input using input actions (from PlayerControllerRefactored.gd)
	move_input = get_input_actions()
	
	# Simple movement like working version
	handle_simple_movement(delta)
	handle_simple_jumping(delta)
	apply_simple_gravity(delta)
	
	# Move like the demo
	player.move_and_slide()
	
	# Logging
	log_input_status()

func get_input_actions() -> Vector2:
	## Get input using input actions (from PlayerControllerRefactored.gd)
	var input = Vector2.ZERO
	
	# Use input actions instead of direct key presses
	if Input.is_action_pressed("move_forward"):
		input.y -= 1
		print("INPUT: move_forward pressed")
	if Input.is_action_pressed("move_back"):
		input.y += 1
		print("INPUT: move_back pressed")
	if Input.is_action_pressed("move_left"):
		input.x -= 1
		print("INPUT: move_left pressed")
	if Input.is_action_pressed("move_right"):
		input.x += 1
		print("INPUT: move_right pressed")
	
	# Check for running
	is_running = Input.is_action_pressed("sprint")
	if is_running:
		print("INPUT: sprint pressed")
	
	return input.normalized()

func handle_simple_movement(delta: float):
	## Simple movement system using input actions
	if move_input.length() > 0.1:
		# Get camera-relative direction
		var direction: Vector3 = get_camera_relative_input()
		var h_veloc: Vector2 = Vector2(direction.x, direction.z).normalized() * MOVE_SPEED
		
		# Set velocity like the demo
		player.velocity.x = h_veloc.x
		player.velocity.z = h_veloc.y
		
		print("INPUT MOVEMENT: input=", move_input, " direction=", direction, " velocity=", player.velocity)
	else:
		# Stop horizontal movement
		player.velocity.x = 0.0
		player.velocity.z = 0.0

func handle_simple_jumping(delta: float):
	## Simple jumping system (from working SimplePlayerTest.gd)
	if Input.is_action_pressed("ui_accept") and player.is_on_floor() and jump_cooldown <= 0.0:
		player.velocity.y = JUMP_SPEED + MOVE_SPEED * 0.016
		jump_cooldown = jump_delay
		print("INPUT JUMP! Velocity: ", player.velocity)
	
	# Update jump cooldown
	if jump_cooldown > 0.0:
		jump_cooldown -= delta

func apply_simple_gravity(delta: float):
	## Simple gravity (from working SimplePlayerTest.gd)
	player.velocity.y -= gravity * delta

func get_camera_relative_input() -> Vector3:
	## Get input relative to camera using input actions
	var input_dir: Vector3 = Vector3.ZERO
	
	if not camera:
		print("❌ No camera found for input")
		return input_dir
	
	# Use input actions for camera-relative movement
	if move_input.x < 0: # Left
		input_dir -= camera.global_transform.basis.x
	if move_input.x > 0: # Right
		input_dir += camera.global_transform.basis.x
	if move_input.y < 0: # Forward
		input_dir -= camera.global_transform.basis.z
	if move_input.y > 0: # Backward
		input_dir += camera.global_transform.basis.z
	
	return input_dir

func log_input_status():
	## Log input status for debugging
	if player.is_on_floor():
		if player.velocity.length() > 0.1:
			var jump_status = " (Can Jump)" if jump_cooldown <= 0.0 else " (Jump Cooldown: %.1f)" % jump_cooldown
			var input_status = " (Input: %s)" % move_input
			print("INPUT MOVING! Pos: ", player.global_position, " Vel: ", player.velocity, input_status, jump_status)
		else:
			var jump_status = " (Can Jump)" if jump_cooldown <= 0.0 else " (Jump Cooldown: %.1f)" % jump_cooldown
			var input_status = " (Input: %s)" % move_input
			print("INPUT GROUNDED! Pos: ", player.global_position, " Vel: ", player.velocity, input_status, jump_status)
	else:
		print("INPUT FALLING: velocity.y=", player.velocity.y, " pos=", player.global_position)

func _input(event):
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_ESCAPE:
			print("ESC pressed - exiting input actions test")
			get_tree().quit()
