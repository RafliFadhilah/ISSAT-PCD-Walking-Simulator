extends Node3D

## Test script for PlayerControllerRefactored
## Demonstrates smooth movement and following camera system

var player: Node  # Changed to Node to accept any player controller type
var status_label: Label
var jitter_helper: JitterTestHelper
var start_jitter_button: Button
var stop_jitter_button: Button
var results_jitter_button: Button

# FPS monitoring
var fps_label: Label
var fps_update_timer: float = 0.0
var fps_update_interval: float = 0.5  # Update FPS every 0.5 seconds
var frame_count: int = 0
var fps: float = 0.0

func _ready():
	print("=== PlayerControllerRefactored Test ===")
	print("🎮 Testing enhanced player movement and camera system")
	
	# Get player reference
	player = get_node_or_null("Player")
	if not player:
		print("❌ Player not found")
		return
	
	print("✅ Found player: " + str(player.get_path()))
	
	# Get UI references
	status_label = get_node_or_null("UI/TestPanel/VBoxContainer/StatusLabel")
	if status_label:
		status_label.text = "Status: Player Ready"
		print("✅ UI status label found")
	
	# Get FPS label reference
	fps_label = get_node_or_null("UI/TestPanel/VBoxContainer/FPSLabel")
	if fps_label:
		fps_label.text = "FPS: --"
		print("✅ FPS label found")
	else:
		print("⚠️ FPS label not found - will create one")
		create_fps_label()
	
	# Get jitter helper reference
	jitter_helper = get_node_or_null("JitterTestHelper")
	if jitter_helper:
		print("✅ Jitter test helper found")
	
	# Get jitter test buttons
	start_jitter_button = get_node_or_null("UI/TestPanel/VBoxContainer/JitterButtonContainer/StartJitterButton")
	stop_jitter_button = get_node_or_null("UI/TestPanel/VBoxContainer/JitterButtonContainer/StopJitterButton")
	results_jitter_button = get_node_or_null("UI/TestPanel/VBoxContainer/JitterButtonContainer/ResultsJitterButton")
	
	# Connect button signals
	if start_jitter_button:
		start_jitter_button.pressed.connect(_on_start_jitter_test)
		print("✅ Start jitter button connected")
	if stop_jitter_button:
		stop_jitter_button.pressed.connect(_on_stop_jitter_test)
		print("✅ Stop jitter button connected")
	if results_jitter_button:
		results_jitter_button.pressed.connect(_on_print_jitter_results)
		print("✅ Results jitter button connected")
	
	# Setup test environment
	setup_test_environment()
	
	print("🎯 Test environment ready!")
	print("🚀 Try moving around with WASD and looking with the mouse!")

func setup_test_environment():
	## Setup the test environment
	print("🔧 Setting up test environment...")
	
	# Create some test collectibles
	create_test_collectibles()
	
	# Create some test NPCs
	create_test_npcs()
	
	print("✅ Test environment setup complete")

func create_test_collectibles():
	## Create test collectible objects
	print("💎 Creating test collectibles...")
	
	var collectibles = [
		{"name": "Ancient Coin", "pos": Vector3(15, 1, 15), "color": Color.YELLOW},
		{"name": "Mysterious Gem", "pos": Vector3(-15, 1, -15), "color": Color.CYAN},
		{"name": "Rare Artifact", "pos": Vector3(15, 1, -15), "color": Color.MAGENTA},
		{"name": "Lost Relic", "pos": Vector3(-15, 1, 15), "color": Color.ORANGE}
	]
	
	for collectible in collectibles:
		var coin = CSGBox3D.new()
		coin.size = Vector3(0.5, 0.5, 0.5)
		coin.position = collectible.pos
		coin.material = StandardMaterial3D.new()
		coin.material.albedo_color = collectible.color
		coin.material.emission = collectible.color * 0.3
		coin.name = collectible.name
		
		add_child(coin)
		print("✅ Created collectible: %s at %s" % [collectible.name, collectible.pos])

func create_test_npcs():
	## Create test NPCs for interaction testing
	print("👥 Creating test NPCs...")
	
	var npcs = [
		{"name": "Village Elder", "pos": Vector3(25, 1, 0), "color": Color.BLUE},
		{"name": "Traveling Merchant", "pos": Vector3(-25, 1, 0), "color": Color.GREEN},
		{"name": "Mysterious Wanderer", "pos": Vector3(0, 1, -25), "color": Color.PURPLE}
	]
	
	for npc in npcs:
		var npc_body = CSGBox3D.new()
		npc_body.size = Vector3(1, 2, 1)
		npc_body.position = npc.pos
		npc_body.material = StandardMaterial3D.new()
		npc_body.material.albedo_color = npc.color
		npc_body.name = npc.name
		
		add_child(npc_body)
		print("✅ Created NPC: %s at %s" % [npc.name, npc.pos])

func _process(delta):
	## Update test scene logic
	if player and status_label:
		update_status_display()
	
	# Update FPS monitoring
	update_fps_monitoring(delta)

func update_status_display():
	## Update the status display with player information
	var status_text = "Status: Active\n"
	
	# Handle different player controller types safely
	if player.has_method("get_player_position"):
		status_text += "Position: %s\n" % player.get_player_position()
	else:
		status_text += "Position: %s\n" % player.global_position
	
	if player.has_method("get_movement_speed"):
		status_text += "Speed: %.1f\n" % player.get_movement_speed()
	else:
		status_text += "Speed: %.1f\n" % player.velocity.length()
	
	if player.has_method("is_player_running"):
		status_text += "Running: %s\n" % ("Yes" if player.is_player_running() else "No")
	else:
		status_text += "Running: %s\n" % ("Unknown")
	
	if player.has_method("get_camera_distance"):
		status_text += "Camera: %.1f" % player.get_camera_distance()
	else:
		status_text += "Camera: Integrated"
	
	status_label.text = status_text

## 🎮 Test Functions

func test_player_teleportation():
	## Test player teleportation functionality
	print("🚀 Testing player teleportation...")
	
	if player:
		var test_positions = [
			Vector3(0, 1, 0),      # Center
			Vector3(20, 1, 20),    # Corner
			Vector3(-20, 1, -20),  # Opposite corner
			Vector3(0, 1, 10)      # Start position
		]
		
		for i in range(test_positions.size()):
			var pos = test_positions[i]
			if player.has_method("set_player_position"):
				player.set_player_position(pos)
			else:
				player.global_position = pos
			print("   Teleported to position %d: %s" % [i + 1, pos])
			await get_tree().create_timer(1.0).timeout
		
		print("✅ Teleportation test complete")

func test_camera_system():
	## Test camera system functionality
	print("📷 Testing camera system...")
	
	if player:
		# Test camera distance changes
		var test_distances = [2.0, 4.0, 6.0, 8.0, 6.0]
		
		for distance in test_distances:
			if player.has_method("set_camera_distance"):
				player.set_camera_distance(distance)
				print("   Camera distance set to: %.1f" % distance)
			else:
				print("   Camera system: Integrated (no distance control)")
			await get_tree().create_timer(0.5).timeout
		
		print("✅ Camera system test complete")

func test_movement_system():
	## Test movement system functionality
	print("🏃 Testing movement system...")
	
	if player:
		# Test speed changes
		var test_speeds = [4.0, 8.0, 12.0, 16.0, 8.0]
		
		for speed in test_speeds:
			if player.has_method("set_movement_speed"):
				player.set_movement_speed(speed)
				print("   Movement speed set to: %.1f" % speed)
			else:
				print("   Movement system: Integrated (speed: %.1f)" % speed)
			await get_tree().create_timer(0.5).timeout
		
		print("✅ Movement system test complete")

## 🎯 Input Testing

func _input(event):
	## Handle input for testing
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_1:
				print("🧪 Test 1: Player Teleportation")
				test_player_teleportation()
			KEY_2:
				print("🧪 Test 2: Camera System")
				test_camera_system()
			KEY_3:
				print("🧪 Test 3: Movement System")
				test_movement_system()
			KEY_R:
				print("🔄 Resetting player position")
				if player:
					if player.has_method("set_player_position"):
						player.set_player_position(Vector3(0, 1, 10))
					else:
						player.global_position = Vector3(0, 1, 10)
			KEY_H:
				print("📋 Test Help:")
				print("   1 - Test teleportation")
				print("   2 - Test camera system")
				print("   3 - Test movement system")
				print("   R - Reset player position")
				print("   J - Start jitter test")
				print("   K - Stop jitter test")
				print("   L - Print jitter results")
				print("   H - Show this help")

## 🎮 Jitter Test Button Handlers

func _on_start_jitter_test():
	## Handle start jitter test button press
	if jitter_helper:
		jitter_helper.start_jitter_test()
		print("🧪 Jitter test started via button")

func _on_stop_jitter_test():
	## Handle stop jitter test button press
	if jitter_helper:
		jitter_helper.stop_jitter_test()
		print("🛑 Jitter test stopped via button")

func _on_print_jitter_results():
	## Handle print jitter results button press
	if jitter_helper:
		jitter_helper.print_test_results()
		print("📊 Jitter results printed via button")

## 📊 Performance Monitoring

func create_fps_label():
	## Create FPS label if it doesn't exist
	var ui_container = get_node_or_null("UI/TestPanel/VBoxContainer")
	if ui_container:
		fps_label = Label.new()
		fps_label.name = "FPSLabel"
		fps_label.text = "FPS: --"
		fps_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		
		# Insert after StatusLabel
		var status_index = ui_container.get_child_count() - 1  # Before the last separator
		ui_container.add_child(fps_label)
		ui_container.move_child(fps_label, status_index)
		
		print("✅ FPS label created")

func update_fps_monitoring(delta):
	## Update FPS monitoring
	if not fps_label:
		return
	
	frame_count += 1
	fps_update_timer += delta
	
	# Update FPS display every update_interval seconds
	if fps_update_timer >= fps_update_interval:
		fps = frame_count / fps_update_timer
		frame_count = 0
		fps_update_timer = 0.0
		
		# Update FPS label with color coding
		var fps_text = "FPS: %.1f" % fps
		if fps >= 60:
			fps_text += " (Excellent)"
		elif fps >= 30:
			fps_text += " (Good)"
		else:
			fps_text += " (Poor)"
		
		fps_label.text = fps_text

func _notification(what):
	## Handle scene notifications
	if what == NOTIFICATION_READY:
		print("🎮 Test scene ready")
	elif what == NOTIFICATION_PROCESS:
		# FPS monitoring is now handled in _process function
		pass
