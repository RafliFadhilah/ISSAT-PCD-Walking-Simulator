extends CulturalInteractableObject

@export var item_name: String
@export var cultural_region: String
@export var collection_animation: PackedScene
@export var collection_sound: AudioStream

var is_collected: bool = false

func _ready():
	# Add to artifact group for radar detection
	add_to_group("artifact")
	
	# Set up interaction prompt
	interaction_prompt = "Press E to collect " + item_name
	
	# Debug print
	print("WorldCulturalItem ready: ", item_name, " in region: ", cultural_region)
	print("Interaction prompt: ", interaction_prompt)
	print("Can interact: ", can_interact)
	
	# Connect to global signals
	GlobalSignals.on_collect_artifact.connect(_on_artifact_collected)

func _interact():
	print("_interact() called on: ", item_name)
	if not is_collected:
		print("Item not collected yet, calling collect_item()")
		collect_item()
	else:
		print("Item already collected!")

func collect_item():
	if is_collected:
		return
	
	is_collected = true
	can_interact = false  # Disable further interaction
	
	print("=== COLLECTING ARTIFACT ===")
	print("Item name: ", item_name)
	print("Cultural region: ", cultural_region)
	
	# Load the cultural item resource
	var item_path = "res://Systems/Items/ItemData/" + item_name + ".tres"
	print("Item path: ", item_path)
	print("Resource exists: ", ResourceLoader.exists(item_path))
	
	if ResourceLoader.exists(item_path):
		var _item = load(item_path)  # Loaded but not used in current implementation
		print("Loaded item resource: ", _item)
		
		# Add to player inventory
		print("Calling Global.collect_artifact...")
		Global.collect_artifact(cultural_region, item_name)
		
		# Emit collection signal
		GlobalSignals.on_collect_artifact.emit(item_name, cultural_region)
		
		# Play collection effects
		play_collection_effects()
		
		# Hide the item (but keep StaticBody3D for collision temporarily)
		visible = false
		
		# Disable collision after a short delay to prevent collision detection
		call_deferred("_disable_collision")
		
		# Optional: Show collection message
		show_collection_message(item_name)
	else:
		print("Warning: Cultural item resource not found: ", item_path)

func _disable_collision():
	# Disable StaticBody3D collision
	var static_body = get_node_or_null("StaticBody3D")
	if static_body:
		static_body.collision_layer = 0
		static_body.collision_mask = 0
		print("Disabled collision for collected artifact: ", item_name)

func play_collection_effects():
	# Play collection sound
	if collection_sound:
		var audio_player = AudioStreamPlayer3D.new()
		audio_player.stream = collection_sound
		audio_player.volume_db = -10.0
		add_child(audio_player)
		audio_player.play()
		
		# Remove audio player after playing
		await audio_player.finished
		audio_player.queue_free()
	
	# Play collection animation if available
	if collection_animation:
		var anim_instance = collection_animation.instantiate()
		add_child(anim_instance)
		await get_tree().create_timer(2.0).timeout
		anim_instance.queue_free()

func show_collection_message(_item_name: String):
	# Create a simple collection message
	var message = "Collected: " + item_name  # Use the exported variable
	print(message)
	
	# You can implement a more sophisticated UI message here
	# For now, we'll use the existing interaction system

func _on_artifact_collected(artifact_name: String, _region: String):
	# This function can be used for additional collection logic
	if artifact_name == item_name:
		print("Artifact collected: ", artifact_name, " from ", _region)
