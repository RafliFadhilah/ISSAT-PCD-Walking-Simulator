extends Node3D

@onready var player: CharacterBody3D = $Player
@onready var camera: Camera3D = $Player/Camera3D

# Movement settings (from PlayerControllerRefactored.gd)
var MOVE_SPEED: float = 8.0
var RUN_SPEED: float = 16.0
var JUMP_FORCE: float = 15.0
var ACCELERATION: float = 25.0
var DECELERATION: float = 30.0
var AIR_CONTROL: float = 0.3

# Physics settings (from PlayerControllerRefactored.gd)
var gravity: float = 40.0
var max_fall_speed: float = 50.0

# Complex physics variables
var current_speed: float = 0.0
var target_speed: float = 0.0
var velocity_horizontal: Vector2 = Vector2.ZERO
var is_running: bool = false
var is_grounded: bool = false

# Jump cooldown (from working simple version)
var jump_cooldown: float = 0.0
var jump_delay: float = 0.3

func _ready():
	print("Complex Physics Test initialized")
	print("Testing: Complex physics + Simple camera + Direct input")
	print("Controls: WASD = Move, SPACE = Jump, ESC = Exit")

func _physics_process(delta: float):
	# Get input like the simple version
	var direction: Vector3 = get_camera_relative_input()
	var input_vector = Vector2(direction.x, direction.z)
	
	# Complex physics system (from PlayerControllerRefactored.gd)
	handle_complex_movement(delta, input_vector)
	handle_complex_jumping(delta)
	apply_complex_gravity(delta)
	
	# Move like the demo
	player.move_and_slide()
	
	# Logging with physics status
	log_physics_status()

func handle_complex_movement(delta: float, input_vector: Vector2):
	## Complex movement with acceleration/deceleration
	is_grounded = player.is_on_floor()
	
	# Determine target speed
	if input_vector.length() > 0.1:
		target_speed = RUN_SPEED if is_running else MOVE_SPEED
		is_running = Input.is_key_pressed(KEY_SHIFT)
	else:
		target_speed = 0.0
	
	# Apply acceleration/deceleration
	var acceleration_rate = ACCELERATION if target_speed > current_speed else DECELERATION
	current_speed = move_toward(current_speed, target_speed, acceleration_rate * delta)
	
	# Calculate movement direction
	var movement_direction = input_vector.normalized() if input_vector.length() > 0.1 else Vector2.ZERO
	
	# Apply movement with complex physics
	if is_grounded:
		# Ground movement
		velocity_horizontal = movement_direction * current_speed
	else:
		# Air movement with reduced control
		var air_movement = movement_direction * current_speed * AIR_CONTROL
		velocity_horizontal = velocity_horizontal.lerp(air_movement, 0.1)
	
	# Apply horizontal velocity
	player.velocity.x = velocity_horizontal.x
	player.velocity.z = velocity_horizontal.y

func handle_complex_jumping(delta: float):
	## Complex jumping system
	if Input.is_key_pressed(KEY_SPACE) and is_grounded and jump_cooldown <= 0.0:
		player.velocity.y = JUMP_FORCE
		jump_cooldown = jump_delay
		print("COMPLEX JUMP! Velocity: ", player.velocity)
	
	# Update jump cooldown
	if jump_cooldown > 0.0:
		jump_cooldown -= delta

func apply_complex_gravity(delta: float):
	## Complex gravity with fall speed limiting
	if not is_grounded:
		player.velocity.y -= gravity * delta
		player.velocity.y = max(player.velocity.y, -max_fall_speed)
	else:
		# Ensure we're properly grounded
		if player.velocity.y < 0:
			player.velocity.y = 0

func log_physics_status():
	## Log physics status for debugging
	if is_grounded:
		if player.velocity.length() > 0.1:
			var jump_status = " (Can Jump)" if jump_cooldown <= 0.0 else " (Jump Cooldown: %.1f)" % jump_cooldown
			var speed_status = " (Speed: %.1f/%.1f)" % [current_speed, target_speed]
			print("COMPLEX MOVING! Pos: ", player.global_position, " Vel: ", player.velocity, speed_status, jump_status)
		else:
			var jump_status = " (Can Jump)" if jump_cooldown <= 0.0 else " (Jump Cooldown: %.1f)" % jump_cooldown
			print("COMPLEX GROUNDED! Pos: ", player.global_position, " Vel: ", player.velocity, jump_status)
	else:
		print("COMPLEX FALLING: velocity.y=", player.velocity.y, " pos=", player.global_position)

# Returns the input vector relative to the camera - same as simple version
func get_camera_relative_input() -> Vector3:
	var input_dir: Vector3 = Vector3.ZERO
	if Input.is_key_pressed(KEY_A): # Left
		input_dir -= camera.global_transform.basis.x
	if Input.is_key_pressed(KEY_D): # Right
		input_dir += camera.global_transform.basis.x
	if Input.is_key_pressed(KEY_W): # Forward
		input_dir -= camera.global_transform.basis.z
	if Input.is_key_pressed(KEY_S): # Backward
		input_dir += camera.global_transform.basis.z
	return input_dir

func _input(event):
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_ESCAPE:
			print("ESC pressed - exiting complex physics test")
			get_tree().quit()
