extends Control

@onready var webcam_feed = $MainContainer/WebcamContainer/WebcamPanel/WebcamFeed
@onready var camera_status_label = $MainContainer/WebcamContainer/WebcamPanel/WebcamFeed/CameraStatusLabel
@onready var mask_display = $MainContainer/WebcamContainer/WebcamPanel/WebcamFeed/MaskOverlay/MaskDisplay
@onready var mask_info_label = $MainContainer/InfoContainer/MaskInfoLabel
@onready var status_label = $MainContainer/InfoContainer/StatusLabel

# Webcam Manager - will be loaded manually
var webcam_manager: Node

var webcam_frames_received: int = 0

func _ready():
	print("=== TopengWebcamController._ready() ===")
	print("Scene tree ready, setting up webcam...")
	
	# Verify node paths
	print("Verifying node paths...")
	print("webcam_feed path exists: ", has_node("MainContainer/WebcamContainer/WebcamPanel/WebcamFeed"))
	print("camera_status_label path exists: ", has_node("MainContainer/WebcamContainer/WebcamPanel/WebcamFeed/CameraStatusLabel"))
	
	setup_webcam_manager()
	setup_mask_display()
	display_mask_info()

func setup_webcam_manager():
	"""Setup WebcamManagerUDP for real webcam"""
	print("=== Setting up WebcamManagerUDP ===")
	
	# Verify nodes are available
	if not webcam_feed:
		print("❌ ERROR: webcam_feed node not found!")
		return
	
	if not camera_status_label:
		print("❌ ERROR: camera_status_label node not found!")
		return
	
	# Setup placeholder image first
	setup_webcam_placeholder()
	
	# Load WebcamManagerUDP script for UDP connection
	var webcam_script = load("res://Scenes/EthnicityDetection/WebcamClient/WebcamManagerUDP.gd")
	if webcam_script == null:
		print("❌ ERROR: Could not load WebcamManagerUDP.gd script!")
		camera_status_label.text = "❌ Script load error"
		return
	
	print("Creating WebcamManagerUDP instance...")
	webcam_manager = webcam_script.new()
	add_child(webcam_manager)
	
	# Connect signals with error handling
	print("Connecting signals...")
	if webcam_manager.has_signal("frame_received"):
		webcam_manager.frame_received.connect(_on_webcam_frame_received)
		print("✅ frame_received signal connected")
	else:
		print("❌ ERROR: frame_received signal not found")
	
	if webcam_manager.has_signal("connection_changed"):
		webcam_manager.connection_changed.connect(_on_webcam_connection_changed)
		print("✅ connection_changed signal connected")
	else:
		print("❌ ERROR: connection_changed signal not found")
	
	if webcam_manager.has_signal("error_message"):
		webcam_manager.error_message.connect(_on_webcam_error)
		print("✅ error_message signal connected")
	else:
		print("❌ ERROR: error_message signal not found")
		
	# Update status
	camera_status_label.text = "🔗 Menghubungkan ke UDP webcam server (port 8888)..."
	camera_status_label.modulate = Color(1, 1, 0, 0.8)
	
	# Try connecting to webcam server
	print("Attempting UDP connection to webcam server...")
	webcam_manager.connect_to_webcam_server()
	print("WebcamManagerUDP setup complete")

func setup_webcam_placeholder():
	"""Create placeholder image for webcam"""
	var placeholder_image = Image.create(640, 480, false, Image.FORMAT_RGBA8)
	placeholder_image.fill(Color(0.2, 0.2, 0.3, 1.0))
	
	# Create border
	for x in range(640):
		for y in range(480):
			if x < 5 or x >= 635 or y < 5 or y >= 475:
				placeholder_image.set_pixel(x, y, Color(0.5, 0.5, 0.6, 1.0))
	
	var placeholder_texture = ImageTexture.new()
	placeholder_texture.set_image(placeholder_image)
	webcam_feed.texture = placeholder_texture

func setup_mask_display():
	"""Setup the mask overlay display"""
	print("Setting up mask display...")
	
	# Create a placeholder mask texture
	var mask_image = Image.create(200, 200, false, Image.FORMAT_RGBA8)
	mask_image.fill(Color(1, 1, 1, 0))  # Transparent
	
	# Draw a simple mask placeholder
	for x in range(50, 150):
		for y in range(50, 150):
			var distance_from_center = Vector2(x - 100, y - 100).length()
			if distance_from_center < 50:
				# Create a simple circular mask placeholder
				var alpha = 0.3
				mask_image.set_pixel(x, y, Color(0.8, 0.6, 0.4, alpha))
	
	var mask_texture = ImageTexture.new()
	mask_texture.set_image(mask_image)
	mask_display.texture = mask_texture

func display_mask_info():
	"""Display information about the selected mask"""
	var mask_info = ""
	
	if Global.selected_mask_type == "preset":
		mask_info = "Topeng Preset #" + str(Global.selected_mask_id)
		status_label.text = "Status: Menampilkan topeng preset"
	elif Global.selected_mask_type == "custom":
		var components = Global.custom_mask_components
		mask_info = "Topeng Custom (Base: %d, Mata: %d, Mulut: %d)" % [components.base, components.mata, components.mulut]
		status_label.text = "Status: Menampilkan topeng custom"
	else:
		mask_info = "Topeng: Tidak ada yang dipilih"
		status_label.text = "Status: Tidak ada topeng"
	
	mask_info_label.text = mask_info
	print("Displaying mask info: " + mask_info)

func _on_webcam_frame_received(texture: ImageTexture):
	"""Optimized frame handler"""
	if not webcam_feed:
		return
	
	webcam_feed.texture = texture
	webcam_frames_received += 1
	
	# Less frequent UI updates
	if webcam_frames_received % 30 == 1:  # Update every 30 frames
		camera_status_label.text = "📹 Webcam aktif (%d frames)" % webcam_frames_received
		camera_status_label.modulate = Color(0, 1, 0, 0.8)

func _on_webcam_connection_changed(connected: bool):
	"""Handle webcam connection status changes"""
	print("Webcam connection changed: ", connected)
	if connected:
		camera_status_label.text = "✅ Webcam terhubung!"
		camera_status_label.modulate = Color(0, 1, 0, 0.8)
		status_label.text = "Status: Webcam siap dengan topeng"
	else:
		camera_status_label.text = "❌ Koneksi webcam terputus"
		camera_status_label.modulate = Color(1, 0, 0, 0.8)
		status_label.text = "Status: Menghubungkan ulang..."

func _on_webcam_error(message: String):
	"""Handle webcam errors"""
	print("Webcam error: ", message)
	camera_status_label.text = "❌ Error: " + message
	camera_status_label.modulate = Color(1, 0, 0, 0.8)
	status_label.text = "Status: " + message

func _on_pilih_topeng_button_pressed():
	"""Return to mask selection"""
	print("Pilih Topeng button pressed - returning to mask selection")
	cleanup_resources()
	get_tree().change_scene_to_file("res://Scenes/TopengNusantara/TopengSelectionScene.tscn")

func _on_menu_utama_button_pressed():
	"""Return to main menu"""
	print("Menu Utama button pressed - returning to main menu")
	cleanup_resources()
	get_tree().change_scene_to_file("res://Scenes/MainMenu/MainMenu.tscn")

func cleanup_resources():
	"""Clean up webcam resources"""
	print("Cleaning up webcam resources...")
	
	if webcam_manager:
		# Disconnect signals if they exist
		if webcam_manager.has_signal("frame_received") and webcam_manager.frame_received.is_connected(_on_webcam_frame_received):
			webcam_manager.frame_received.disconnect(_on_webcam_frame_received)
		
		if webcam_manager.has_signal("connection_changed") and webcam_manager.connection_changed.is_connected(_on_webcam_connection_changed):
			webcam_manager.connection_changed.disconnect(_on_webcam_connection_changed)
		
		if webcam_manager.has_signal("error_message") and webcam_manager.error_message.is_connected(_on_webcam_error):
			webcam_manager.error_message.disconnect(_on_webcam_error)
		
		# Free the webcam manager
		if webcam_manager.has_method("disconnect_webcam"):
			webcam_manager.disconnect_webcam()
		
		webcam_manager.queue_free()
		webcam_manager = null
		print("Webcam manager cleaned up")

func _notification(what):
	"""Handle scene exit cleanup"""
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_EXIT_TREE:
		cleanup_resources()
