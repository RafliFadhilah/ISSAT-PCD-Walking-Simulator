extends CharacterBody3D

# Movement settings (from working complex systems)
var MOVE_SPEED: float = 8.0
var RUN_SPEED: float = 16.0
var JUMP_FORCE: float = 15.0
var ACCELERATION: float = 25.0
var DECELERATION: float = 30.0
var AIR_CONTROL: float = 0.3

# Physics settings (from working complex systems)
var gravity: float = 40.0
var max_fall_speed: float = 50.0

# Complex camera settings (increased sensitivity for better control)
var mouse_sensitivity: float = 0.00125
var camera_distance: float = 6.0
var camera_height: float = 1.5
var camera_smoothness: float = 2.0  # Reduced for more responsive feel
var max_pitch: float = 70.0
var min_pitch: float = -30.0

# Complex physics variables
var current_speed: float = 0.0
var target_speed: float = 0.0
var velocity_horizontal: Vector2 = Vector2.ZERO
var is_running: bool = false
var is_grounded: bool = false

# Camera variables
var camera_rotation: Vector2 = Vector2.ZERO
var target_camera_rotation: Vector2 = Vector2.ZERO

# Mouse/UI behavior
var require_right_mouse_to_rotate: bool = false
var last_mouse_delta: Vector2 = Vector2.ZERO

# Jump cooldown (from working simple version)
var jump_cooldown: float = 0.0
var jump_delay: float = 0.3

# Input action variables
var move_input: Vector2 = Vector2.ZERO

# Node references - flexible camera setup
@onready var camera_pivot: Node3D = $CameraPivot
var camera_arm: SpringArm3D
var camera: Camera3D

# Animation references
var animation_player: AnimationPlayer
var animation_tree: AnimationTree

# Model rotation
var player_model: Node3D

# Animation states
var current_animation_state: String = "breathing_idle"
var is_moving: bool = false
var is_turning: bool = false
var was_moving: bool = false
var movement_direction_changed: bool = false
var is_jumping: bool = false
var was_grounded: bool = true
var jump_initiated: bool = false  # True only when user presses space, not when falling
var velocity_at_jump: float = 0.0  # Store velocity when jump was initiated

# Turn detection
var last_movement_direction: Vector2 = Vector2.ZERO
var turn_threshold: float = 2.0  # Angle in radians for 180 turn detection

# Model rotation settings
var rotation_speed: float = 10.0  # How fast the model rotates to face movement direction

# Hips bone reference (for fixing position during jump)
var hips_bone: Node3D = null
var hips_default_y: float = 0.95  # Default Y position for Hips (adjust if needed)

# FPS monitoring
var fps_update_timer: float = 0.0
var fps_update_interval: float = 1.0  # Update FPS every 1 second
var frame_count: int = 0
var fps: float = 0.0

func _ready():
	GameLogger.info("Integrated Player Controller initialized")
	GameLogger.info("Features: Complex Physics + Complex Camera + Input Actions")
	GameLogger.info("Controls: WASD = Move, Shift = Run, Space = Jump, RMB = Look, ESC = Exit")
	
	# Set mouse mode to captured for camera control
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	# Add to player group for radar system
	add_to_group("player")
	
	# Robust camera node resolution (supports CameraArm or SpringArm3D)
	GameLogger.info("Resolving camera nodes...")
	GameLogger.info("CameraPivot exists: " + str(has_node("CameraPivot")))
	
	if has_node("CameraPivot"):
		GameLogger.info("CameraArm exists: " + str(has_node("CameraPivot/CameraArm")))
		GameLogger.info("SpringArm3D exists: " + str(has_node("CameraPivot/SpringArm3D")))
	
	# Try CameraArm first (for Fixed scene)
	if has_node("CameraPivot/CameraArm"):
		camera_arm = get_node("CameraPivot/CameraArm") as SpringArm3D
		if has_node("CameraPivot/CameraArm/Camera3D"):
			camera = get_node("CameraPivot/CameraArm/Camera3D") as Camera3D
			GameLogger.info("Camera resolved via CameraArm path")
		else:
			GameLogger.error("Camera3D not found under CameraArm")
	# Try SpringArm3D (for TerrainAssets scene)
	elif has_node("CameraPivot/SpringArm3D"):
		camera_arm = get_node("CameraPivot/SpringArm3D") as SpringArm3D
		if has_node("CameraPivot/SpringArm3D/Camera3D"):
			camera = get_node("CameraPivot/SpringArm3D/Camera3D") as Camera3D
			GameLogger.info("Camera resolved via SpringArm3D path")
		else:
			GameLogger.error("Camera3D not found under SpringArm3D")
	else:
		GameLogger.error("No camera arm found at CameraPivot/CameraArm or CameraPivot/SpringArm3D")
	
	# Ensure camera is current if found
	if camera:
		camera.current = true
	
	# Setup complex camera system
	setup_complex_camera()
	
	# Setup animation system
	setup_animation_system()
	
	# Setup model rotation system
	setup_model_rotation()
	
	# Setup Hips bone reference
	setup_hips_bone()
	
	# Start with idle animation to prevent starting in jump pose
	if animation_player:
		animation_player.play("breathing_idle")
		current_animation_state = "breathing_idle"
		GameLogger.info("Started with breathing_idle animation")

func _physics_process(delta: float):
	# Get input using input actions
	move_input = get_input_actions()
	# Only log when there's actual input
	if move_input.length() > 0.1:
		GameLogger.debug("_physics_process - move_input: " + str(move_input))
	
	# Complex physics system
	handle_complex_movement(delta)
	handle_complex_jumping(delta)
	apply_complex_gravity(delta)
	
	# Complex camera system
	handle_complex_camera(delta)
	
	# Animation system
	handle_animations(delta)
	
	# Model rotation system
	handle_model_rotation(delta)
	
	# Fix Hips position during jump animations (prevent sinking)
	fix_hips_position_during_jump()
	
	# Move like the demo
	move_and_slide()
	
	# Update FPS monitoring
	update_fps_monitoring(delta)
	
	# Logging
	log_integrated_status()

func get_input_actions() -> Vector2:
	## Get input using input actions (from working input actions test)
	var input = Vector2.ZERO
	var path: String = ""
	
	# Debug: Check if actions exist (reduced logging)
	if input == Vector2.ZERO:  # Only log when no input detected
		GameLogger.debug("=== INPUT DEBUG ===")
		GameLogger.debug("move_forward exists: " + str(InputMap.has_action("move_forward")))
		GameLogger.debug("move_back exists: " + str(InputMap.has_action("move_back")))
		GameLogger.debug("move_left exists: " + str(InputMap.has_action("move_left")))
		GameLogger.debug("move_right exists: " + str(InputMap.has_action("move_right")))
	
	# Prefer project input actions if present
	if InputMap.has_action("move_forward") and Input.is_action_pressed("move_forward"):
		input.y -= 1
		path = "actions"
		GameLogger.debug("W/Forward pressed via actions")
	if InputMap.has_action("move_back") and Input.is_action_pressed("move_back"):
		input.y += 1
		path = "actions"
		GameLogger.debug("S/Back pressed via actions")
	if InputMap.has_action("move_left") and Input.is_action_pressed("move_left"):
		input.x -= 1
		path = "actions"
		GameLogger.debug("A/Left pressed via actions")
	if InputMap.has_action("move_right") and Input.is_action_pressed("move_right"):
		input.x += 1
		path = "actions"
		GameLogger.debug("D/Right pressed via actions")
	
	# Fallback to ui_* if custom actions are missing
	if input == Vector2.ZERO:
		if InputMap.has_action("ui_up") and Input.is_action_pressed("ui_up"):
			input.y -= 1
			path = "ui"
		if InputMap.has_action("ui_down") and Input.is_action_pressed("ui_down"):
			input.y += 1
			path = "ui"
		if InputMap.has_action("ui_left") and Input.is_action_pressed("ui_left"):
			input.x -= 1
			path = "ui"
		if InputMap.has_action("ui_right") and Input.is_action_pressed("ui_right"):
			input.x += 1
			path = "ui"
	
	# Raw physical WASD fallback as last resort
	if input == Vector2.ZERO:
		if Input.is_physical_key_pressed(KEY_W):
			input.y -= 1
			path = "phys"
			GameLogger.debug("W pressed via physical key")
		if Input.is_physical_key_pressed(KEY_S):
			input.y += 1
			path = "phys"
			GameLogger.debug("S pressed via physical key")
		if Input.is_physical_key_pressed(KEY_A):
			input.x -= 1
			path = "phys"
			GameLogger.debug("A pressed via physical key")
		if Input.is_physical_key_pressed(KEY_D):
			input.x += 1
			path = "phys"
			GameLogger.debug("D pressed via physical key")
	
	# Check for running
	is_running = (InputMap.has_action("sprint") and Input.is_action_pressed("sprint")) or Input.is_physical_key_pressed(KEY_SHIFT)
	
	var normalized = input.normalized()
	if normalized == Vector2.ZERO:
		GameLogger.debug("Input: no direction detected (path=" + path + ")")
	else:
		GameLogger.debug("Input: " + str(normalized) + " (path=" + path + ", running=" + str(is_running) + ")")
	return normalized

func handle_complex_movement(delta: float):
	## Complex movement with acceleration/deceleration (from working complex physics)
	is_grounded = is_on_floor()
	
	# Get camera-relative direction
	var direction: Vector3 = get_camera_relative_input()
	var input_vector = Vector2(direction.x, direction.z)
	
	# Debug input
	if input_vector.length() > 0.1:
		GameLogger.debug("Movement input: " + str(input_vector) + " (move_input: " + str(move_input) + ")")
	
	# Determine target speed
	if input_vector.length() > 0.1:
		target_speed = RUN_SPEED if is_running else MOVE_SPEED
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
	velocity.x = velocity_horizontal.x
	velocity.z = velocity_horizontal.y

func handle_complex_jumping(delta: float):
	## Complex jumping system (from working complex physics)
	if ((InputMap.has_action("ui_accept") and Input.is_action_pressed("ui_accept")) or Input.is_physical_key_pressed(KEY_SPACE)) and is_grounded and jump_cooldown <= 0.0:
		# Store velocity before jump
		velocity_at_jump = Vector2(velocity.x, velocity.z).length()
		
		# Use same jump animation for both idle and running
		var jump_anim = "jump_while_run"  # Always use run jump animation
		play_animation(jump_anim)
		current_animation_state = jump_anim
		
		# Then apply physics
		velocity.y = JUMP_FORCE
		jump_cooldown = jump_delay
		is_jumping = true
		jump_initiated = true  # Mark that user intentionally jumped
		GameLogger.debug("INTEGRATED JUMP! Animation: " + jump_anim + " Velocity: " + str(velocity) + " Horizontal: " + str(velocity_at_jump))
	
	# Update jump cooldown
	if jump_cooldown > 0.0:
		jump_cooldown -= delta
	
	# Reset jumping flag when landing
	if is_grounded and was_grounded == false:
		is_jumping = false
		jump_initiated = false  # Reset jump flag
		GameLogger.debug("Landed - resetting jump flag")
	
	# Update was_grounded for next frame
	was_grounded = is_grounded

func apply_complex_gravity(delta: float):
	## Complex gravity with fall speed limiting (from working complex physics)
	if not is_grounded:
		velocity.y -= gravity * delta
		velocity.y = max(velocity.y, -max_fall_speed)
	else:
		# Ensure we're properly grounded
		if velocity.y < 0:
			velocity.y = 0

func setup_complex_camera():
	## Setup complex camera system (from working complex camera)
	if not camera_pivot or not camera_arm or not camera:
		GameLogger.error("❌ Complex camera setup failed - missing nodes")
		return
	
	# Set initial camera position
	camera_arm.spring_length = camera_distance
	camera_pivot.position.y = camera_height
	
	# Ensure camera is looking forward, not down
	camera_pivot.rotation = Vector3.ZERO
	camera_arm.rotation = Vector3.ZERO
	camera.rotation = Vector3.ZERO
	
	# Set initial camera rotation to look forward
	target_camera_rotation = Vector2.ZERO
	camera_rotation = Vector2.ZERO
	
	GameLogger.info("✅ Complex camera system initialized")
	GameLogger.info("Camera position: " + str(camera.global_position))
	GameLogger.info("Camera rotation: " + str(camera.global_rotation))
	GameLogger.info("Camera pivot position: " + str(camera_pivot.global_position))
	GameLogger.info("Camera arm position: " + str(camera_arm.global_position))
	GameLogger.info("Player position: " + str(global_position))

func handle_complex_camera(delta: float):
	## Complex camera handling (from working complex camera)
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
	## Mouse look handling (from working complex camera)
	# Only rotate when RMB is held if required, so UI remains usable
	if require_right_mouse_to_rotate and not Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		GameLogger.debug("Mouse look blocked - RMB required but not pressed")
		return
	
	var mouse_delta = last_mouse_delta
	last_mouse_delta = Vector2.ZERO
	
	if mouse_delta.length() > 0.0:
		GameLogger.debug("Mouse look processing - delta: " + str(mouse_delta))
		# Update target rotation
		target_camera_rotation.x -= mouse_delta.x * mouse_sensitivity
		target_camera_rotation.y -= mouse_delta.y * mouse_sensitivity
		
		# Clamp pitch
		target_camera_rotation.y = clamp(target_camera_rotation.y, deg_to_rad(min_pitch), deg_to_rad(max_pitch))
		GameLogger.debug("Target camera rotation: " + str(target_camera_rotation))

func get_camera_relative_input() -> Vector3:
	## Get input relative to complex camera system (from working complex camera)
	var input_dir: Vector3 = Vector3.ZERO
	
	# Only log when there's actual input
	if move_input.length() > 0.1:
		GameLogger.debug("get_camera_relative_input called - move_input: " + str(move_input))
	
	if not camera:
		GameLogger.error("❌ No camera found for input")
		return input_dir
	
	GameLogger.debug("Camera found - using for input calculation")
	
	# Use complex camera for input
	if move_input.x < 0: # Left
		input_dir -= camera.global_transform.basis.x
		GameLogger.debug("Left input detected")
	if move_input.x > 0: # Right
		input_dir += camera.global_transform.basis.x
		GameLogger.debug("Right input detected")
	if move_input.y < 0: # Forward
		input_dir -= camera.global_transform.basis.z
		GameLogger.debug("Forward input detected")
	if move_input.y > 0: # Backward
		input_dir += camera.global_transform.basis.z
		GameLogger.debug("Backward input detected")
	
	GameLogger.debug("Final input_dir: " + str(input_dir))
	return input_dir

func setup_animation_system():
	"""Setup animation system for player model"""
	GameLogger.info("Setting up animation system...")
	
	# Find AnimationPlayer - check common paths including Skeleton3D
	animation_player = find_child("AnimationPlayer", true, false) as AnimationPlayer
	if not animation_player:
		animation_player = get_node_or_null("AnimationPlayer")
	if not animation_player:
		animation_player = get_node_or_null("PlayerModel/AnimationPlayer")
	if not animation_player:
		animation_player = get_node_or_null("Model/AnimationPlayer")
	if not animation_player:
		animation_player = get_node_or_null("Skeleton3D/AnimationPlayer")
	if not animation_player:
		# Check if AnimationPlayer is sibling to Skeleton3D
		var skeleton = find_child("Skeleton3D", true, false)
		if skeleton and skeleton.get_parent():
			animation_player = skeleton.get_parent().get_node_or_null("AnimationPlayer")
	
	if animation_player:
		GameLogger.info("✅ AnimationPlayer found: " + str(animation_player.get_path()))
		print_available_animations()
	else:
		GameLogger.error("❌ AnimationPlayer not found")
		# Debug: List all children to see what's available
		print_node_structure(self, 0)
	
	# Find AnimationTree if available
	animation_tree = find_child("AnimationTree", true, false) as AnimationTree
	if not animation_tree:
		animation_tree = get_node_or_null("AnimationTree")
	if not animation_tree:
		animation_tree = get_node_or_null("PlayerModel/AnimationTree")
	if not animation_tree:
		animation_tree = get_node_or_null("Model/AnimationTree")
	if not animation_tree:
		animation_tree = get_node_or_null("Skeleton3D/AnimationTree")
	if not animation_tree:
		# Check if AnimationTree is sibling to Skeleton3D
		var skeleton = find_child("Skeleton3D", true, false)
		if skeleton and skeleton.get_parent():
			animation_tree = skeleton.get_parent().get_node_or_null("AnimationTree")
	
	if animation_tree:
		GameLogger.info("✅ AnimationTree found: " + str(animation_tree.get_path()))
		# Disable AnimationTree initially - we'll use direct AnimationPlayer control
		# AnimationTree can interfere with direct animation playback
		animation_tree.active = false
		GameLogger.info("🔧 AnimationTree disabled - using AnimationPlayer directly")
	else:
		GameLogger.info("ℹ️ AnimationTree not found - using AnimationPlayer directly")

func print_node_structure(node: Node, depth: int):
	"""Print node structure for debugging"""
	var indent = ""
	for i in range(depth):
		indent += "  "
	
	print(indent + node.name + " (" + node.get_class() + ")")
	
	if depth < 3:  # Limit depth to avoid spam
		for child in node.get_children():
			print_node_structure(child, depth + 1)

func setup_model_rotation():
	"""Setup model rotation system"""
	GameLogger.info("Setting up model rotation system...")
	
	# Find the Skeleton3D - check common paths
	player_model = find_child("Skeleton3D", true, false) as Skeleton3D
	if not player_model:
		player_model = get_node_or_null("Skeleton3D")
	if not player_model:
		player_model = get_node_or_null("PlayerModel/Skeleton3D")
	if not player_model:
		player_model = get_node_or_null("Model/Skeleton3D")
	if not player_model:
		# Try to find the parent node that contains Skeleton3D
		var skeleton = find_child("Skeleton3D", true, false)
		if skeleton:
			player_model = skeleton.get_parent() as Node3D
	
	if player_model:
		GameLogger.info("✅ Player model (Skeleton3D) found: " + str(player_model.get_path()))
		GameLogger.info("Model type: " + str(player_model.get_class()))
		# Ensure model starts facing forward (Z-negative in Godot)
		player_model.rotation.y = 0.0
	else:
		GameLogger.error("❌ Skeleton3D not found for rotation")
		# Debug: List all children to see what's available
		print_node_structure(self, 0)

func setup_hips_bone():
	"""Setup Hips bone reference to fix position during jump animations"""
	GameLogger.info("Setting up Hips bone reference...")
	
	# Find the Hips bone (mixamorig_Hips for Mixamo models)
	hips_bone = find_child("mixamorig_Hips", true, false) as Node3D
	if not hips_bone and player_model:
		# Try searching within player_model
		hips_bone = player_model.find_child("mixamorig_Hips", true, false) as Node3D
	
	if hips_bone:
		# Store default Y position
		hips_default_y = hips_bone.position.y
		GameLogger.info("✅ Hips bone found: " + str(hips_bone.get_path()))
		GameLogger.info("Default Hips Y position: " + str(hips_default_y))
	else:
		GameLogger.warning("⚠️ Hips bone (mixamorig_Hips) not found - jump fix disabled")

func fix_hips_position_during_jump():
	"""Fix Hips bone position during jump animations to prevent character sinking"""
	if not hips_bone or not animation_player:
		return
	
	# Only fix during jump animation
	if animation_player.is_playing():
		var current_animation = animation_player.current_animation
		if current_animation == "jump_while_run":
			# Restore Hips to default Y position (animation might have modified it)
			if abs(hips_bone.position.y - hips_default_y) > 0.01:
				hips_bone.position.y = hips_default_y
				GameLogger.debug("Fixed Hips Y: " + str(hips_default_y))

func print_available_animations():
	"""Print all available animations for debugging"""
	if not animation_player:
		return
	
	var animations = animation_player.get_animation_list()
	GameLogger.info("Available animations:")
	for anim_name in animations:
		GameLogger.info("  - " + anim_name)

func handle_animations(delta: float):
	"""Handle animation state transitions"""
	if not animation_player:
		return
	
	# Store previous movement state
	was_moving = is_moving
	
	# Determine current movement state
	var input_magnitude = move_input.length()
	is_moving = input_magnitude > 0.1 and velocity.length() > 0.1
	
	# Detect direction changes for turning animations
	detect_direction_change()
	
	# Determine which animation to play
	var target_animation = get_target_animation()
	
	# Play animation if it changed
	if target_animation != current_animation_state:
		play_animation(target_animation)
		current_animation_state = target_animation

func handle_model_rotation(delta: float):
	"""Handle model rotation to face movement direction"""
	if not player_model:
		return
	
	# Get camera-relative movement direction
	var direction = get_camera_relative_input()
	
	# Only rotate if there's significant movement input
	if direction.length() > 0.1:
		# Calculate target rotation based on movement direction
		var target_angle = atan2(direction.x, direction.z)
		
		# Smoothly rotate model towards target angle
		var current_angle = player_model.rotation.y
		var angle_diff = angle_difference(current_angle, target_angle)
		
		# Apply smooth rotation
		if abs(angle_diff) > 0.01:  # Only rotate if there's a meaningful difference
			var rotation_step = rotation_speed * delta
			if abs(angle_diff) < rotation_step:
				player_model.rotation.y = target_angle
			else:
				player_model.rotation.y += sign(angle_diff) * rotation_step
			
			GameLogger.debug("Model rotation: current=" + str(rad_to_deg(current_angle)) + "° target=" + str(rad_to_deg(target_angle)) + "°")

func angle_difference(from: float, to: float) -> float:
	"""Calculate the shortest angle difference between two angles"""
	var diff = to - from
	# Normalize to [-PI, PI]
	while diff > PI:
		diff -= TAU
	while diff < -PI:
		diff += TAU
	return diff

func detect_direction_change():
	"""Detect if player is making a significant direction change (180° turn)"""
	if move_input.length() > 0.1:
		var current_direction = move_input.normalized()
		
		if last_movement_direction.length() > 0.1:
			var dot_product = current_direction.dot(last_movement_direction)
			# If dot product is close to -1, it's approximately a 180° turn
			if dot_product < -0.7:  # Approximately 135°+ turn
				movement_direction_changed = true
				GameLogger.debug("Direction change detected: " + str(rad_to_deg(acos(clamp(dot_product, -1.0, 1.0)))) + "°")
			else:
				movement_direction_changed = false
		
		last_movement_direction = current_direction
	else:
		movement_direction_changed = false

func get_target_animation() -> String:
	"""Determine which animation should be playing based on current state"""
	
	# Handle jumping (highest priority) - only if user initiated jump, not falling
	if jump_initiated and (is_jumping or not is_grounded):
		# Always use jump_while_run for all jumps (both idle and running)
		GameLogger.debug("Jump animation: jump_while_run (velocity_at_jump: " + str(velocity_at_jump) + ")")
		return "jump_while_run"
	
	# Handle 180° turn animations
	if movement_direction_changed and is_moving:
		if is_running:
			return "running_turn_180"
		else:
			return "walking_turn_180"
	
	# Handle transition animations
	if not was_moving and is_moving:
		# Starting to move
		if is_running:
			return "running"  # No specific "start_running" animation listed
		else:
			return "start_walking"
	elif was_moving and not is_moving:
		# Stopping movement
		if velocity.length() > 2.0:  # Still has momentum
			return "run_to_stop"
		else:
			return "stop_walking"
	
	# Handle continuous movement
	if is_moving:
		if is_running:
			return "running"
		else:
			return "walking"
	
	# Handle idle
	return "breathing_idle"

func play_animation(animation_name: String):
	"""Play the specified animation"""
	if not animation_player:
		GameLogger.error("AnimationPlayer not found!")
		return
	
	# Check if animation exists
	if not animation_player.has_animation(animation_name):
		GameLogger.error("Animation not found: " + animation_name)
		GameLogger.error("Available animations: " + str(animation_player.get_animation_list()))
		return
	
	GameLogger.debug("Playing animation: " + animation_name)
	
	# Handle different animation types
	match animation_name:
		"breathing_idle":
			animation_player.play(animation_name)
		"jump_while_run":
			GameLogger.info("🎬 Playing jump_while_run animation!")
			animation_player.play(animation_name)
			# Continue running after jump finishes if still moving
			animation_player.animation_finished.connect(_on_jump_run_finished, CONNECT_ONE_SHOT)
		"start_walking":
			animation_player.play(animation_name)
			# Queue walking animation after start_walking finishes
			animation_player.animation_finished.connect(_on_start_walking_finished, CONNECT_ONE_SHOT)
		"walking":
			animation_player.play(animation_name)
		"running":
			animation_player.play(animation_name)
		"stop_walking":
			animation_player.play(animation_name)
			# Queue idle after stop_walking finishes
			animation_player.animation_finished.connect(_on_stop_walking_finished, CONNECT_ONE_SHOT)
		"run_to_stop":
			animation_player.play(animation_name)
			# Queue idle after run_to_stop finishes
			animation_player.animation_finished.connect(_on_run_to_stop_finished, CONNECT_ONE_SHOT)
		"walking_turn_180":
			animation_player.play(animation_name)
			# Continue with walking after turn
			animation_player.animation_finished.connect(_on_walking_turn_finished, CONNECT_ONE_SHOT)
		"running_turn_180":
			animation_player.play(animation_name)
			# Continue with running after turn
			animation_player.animation_finished.connect(_on_running_turn_finished, CONNECT_ONE_SHOT)
		"taking_item":
			animation_player.play(animation_name)
			# Return to previous state after taking item
			animation_player.animation_finished.connect(_on_taking_item_finished, CONNECT_ONE_SHOT)
		_:
			animation_player.play(animation_name)

func _on_start_walking_finished(anim_name: String):
	"""Called when start_walking animation finishes"""
	if anim_name == "start_walking" and is_moving and not is_running:
		play_animation("walking")
		current_animation_state = "walking"

func _on_jump_run_finished(anim_name: String):
	"""Called when jump_while_run animation finishes"""
	if anim_name == "jump_while_run":
		jump_initiated = false  # Reset jump flag after animation
		is_jumping = false  # Reset jumping state
		# Return to appropriate state based on current movement
		if is_moving:
			if is_running:
				play_animation("running")
				current_animation_state = "running"
			else:
				play_animation("walking")
				current_animation_state = "walking"
		else:
			play_animation("breathing_idle")
			current_animation_state = "breathing_idle"

func _on_stop_walking_finished(anim_name: String):
	"""Called when stop_walking animation finishes"""
	if anim_name == "stop_walking" and not is_moving:
		play_animation("breathing_idle")
		current_animation_state = "breathing_idle"

func _on_run_to_stop_finished(anim_name: String):
	"""Called when run_to_stop animation finishes"""
	if anim_name == "run_to_stop" and not is_moving:
		play_animation("breathing_idle")
		current_animation_state = "breathing_idle"

func _on_walking_turn_finished(anim_name: String):
	"""Called when walking_turn_180 animation finishes"""
	if anim_name == "walking_turn_180":
		movement_direction_changed = false  # Reset turn flag
		if is_moving and not is_running:
			play_animation("walking")
			current_animation_state = "walking"

func _on_running_turn_finished(anim_name: String):
	"""Called when running_turn_180 animation finishes"""
	if anim_name == "running_turn_180":
		movement_direction_changed = false  # Reset turn flag
		if is_moving and is_running:
			play_animation("running")
			current_animation_state = "running"

func _on_taking_item_finished(anim_name: String):
	"""Called when taking_item animation finishes"""
	if anim_name == "taking_item":
		# Return to appropriate state
		if is_moving:
			if is_running:
				play_animation("running")
				current_animation_state = "running"
			else:
				play_animation("walking")
				current_animation_state = "walking"
		else:
			play_animation("breathing_idle")
			current_animation_state = "breathing_idle"

func trigger_take_item_animation():
	"""Trigger the taking_item animation (call this when player interacts with items)"""
	play_animation("taking_item")
	current_animation_state = "taking_item"

func log_integrated_status():
	## Log integrated status for debugging
	if is_grounded:
		if velocity.length() > 0.1:
			var jump_status = " (Can Jump)" if jump_cooldown <= 0.0 else " (Jump Cooldown: %.1f)" % jump_cooldown
			var speed_status = " (Speed: %.1f/%.1f)" % [current_speed, target_speed]
			var camera_status = " (Camera: %.1f, %.1f)" % [camera_rotation.x, camera_rotation.y]
			var input_status = " (Input: %s)" % move_input
			GameLogger.debug("INTEGRATED MOVING! Pos: " + str(global_position) + " Vel: " + str(velocity) + speed_status + camera_status + input_status + jump_status)
		else:
			var jump_status = " (Can Jump)" if jump_cooldown <= 0.0 else " (Jump Cooldown: %.1f)" % jump_cooldown
			var camera_status = " (Camera: %.1f, %.1f)" % [camera_rotation.x, camera_rotation.y]
			var input_status = " (Input: %s)" % move_input
			GameLogger.debug("INTEGRATED GROUNDED! Pos: " + str(global_position) + " Vel: " + str(velocity) + camera_status + input_status + jump_status)
	else:
		GameLogger.debug("INTEGRATED FALLING: velocity.y=" + str(velocity.y) + " pos=" + str(global_position))

func update_fps_monitoring(delta: float):
	## Update FPS monitoring
	frame_count += 1
	fps_update_timer += delta
	
	# Update FPS display every update_interval seconds
	if fps_update_timer >= fps_update_interval:
		fps = frame_count / fps_update_timer
		frame_count = 0
		fps_update_timer = 0.0
		
		# Print FPS to console
		var fps_text = "FPS: %.1f" % fps
		if fps >= 60:
			fps_text += " (Excellent)"
		elif fps >= 30:
			fps_text += " (Good)"
		else:
			fps_text += " (Poor)"
		
		GameLogger.debug(fps_text)

func _input(event):
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_M:
			# Toggle mouse mode with M key
			if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
				Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
				GameLogger.info("Mouse mode: VISIBLE")
			else:
				Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
				GameLogger.info("Mouse mode: CAPTURED")
		elif event.keycode == KEY_ESCAPE:
			# ESC for exit
			GameLogger.info("ESC pressed - exiting game")
			get_tree().quit()
		elif event.keycode == KEY_E:
			# E key for taking items (example)
			GameLogger.info("Take item triggered")
			trigger_take_item_animation()
	
	# Handle mouse input for camera
	if event is InputEventMouseMotion:
		GameLogger.debug("Mouse motion detected - mode: " + str(Input.get_mouse_mode()) + ", delta: " + str(event.relative))
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			last_mouse_delta = event.relative
			GameLogger.debug("Mouse delta captured: " + str(last_mouse_delta))
