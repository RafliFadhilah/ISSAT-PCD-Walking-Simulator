extends CulturalInteractableObject

@export var item_name: String
@export var cultural_region: String
@export var collection_animation: PackedScene
@export var collection_sound: AudioStream

@export_group("Visual Animation")
@export var enable_floating: bool = true
@export var float_amplitude: float = 0.3  ## Height of floating motion (meters)
@export var float_speed: float = 2.0  ## Speed of floating motion
@export var enable_rotation: bool = true
@export var rotation_speed: Vector3 = Vector3(0, 1.0, 0)  ## Rotation speed per axis (radians/sec)
@export var start_offset: float = 0.0  ## Phase offset for multiple artifacts

var is_collected: bool = false

# Animation variables
var original_position: Vector3
var time_passed: float = 0.0

const jsonTools = preload("res://Tools/JsonTools.gd")

func _ready():
	# Store original position for floating animation
	original_position = position
	
	# Random start offset if not set
	if start_offset == 0.0:
		start_offset = randf() * TAU  # Random phase between 0 and 2π
	time_passed = start_offset
	
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

func _process(delta: float):
	if is_collected:
		return
	
	# Update time
	time_passed += delta
	
	# Floating animation
	if enable_floating:
		var float_offset = sin(time_passed * float_speed) * float_amplitude
		position.y = original_position.y + float_offset
	
	# Rotation animation
	if enable_rotation:
		rotation += rotation_speed * delta

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
	
	# Check if this is a food artifact that triggers cooking game
	var food_recipes = ["Soto", "Lotek", "Sate"]
	if item_name in food_recipes:
		print("=== TRIGGERING COOKING GAME FOR FOOD ARTIFACT ===")
		
		# Load recipe data from JSON
		var recipes_json = load_recipe_data()
		if recipes_json and recipes_json.has(item_name):
			var recipe_data = recipes_json[item_name]["ingredients"]
			print("Recipe data loaded: ", recipe_data)
			
			# Show cooking prompt
			var cooking_prompt = "Apakah kamu mau memasak " + item_name + " sekarang?"
			var should_cook = await show_cooking_prompt(cooking_prompt)
			
			if should_cook:
				# Launch cooking game with recipe
				launch_cooking_game(recipe_data)
				return  # Exit early for cooking game
	
	# Normal artifact collection (non-cooking items)
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

func load_recipe_data() -> Dictionary:
	print("=== LOADING RECIPE DATA FROM JSON ===")
	var json_tools_instance = jsonTools.new()
	var recipes = json_tools_instance.load_json("res://Data/recipes.json")
	
	if recipes != null:
		print("Recipes loaded successfully: ", recipes)
		return recipes
	else:
		print("Failed to load recipes from JSON file")
		return {}

func play_collection_effects():
	# Play collection sound if available
	if collection_sound:
		print("Playing collection sound")
		# AudioManager integration would go here
	
	# Play collection animation if available
	if collection_animation:
		print("Playing collection animation")
		# Animation playing logic would go here

func show_collection_message(artifact_name: String):
	print("Collection message: Successfully collected " + artifact_name + "!")
	# This could show a UI notification or toast message

func _disable_collision():
	# Find and disable the collision shape
	var static_body = get_node_or_null("StaticBody3D")
	if static_body:
		static_body.set_collision_layer(0)
		static_body.set_collision_mask(0)
		print("Collision disabled for collected artifact: ", item_name)

func show_cooking_prompt(message: String) -> bool:
	print("=== COOKING PROMPT ===")
	print("Message: ", message)
	
	# For now, automatically return true to start cooking
	# You can implement a proper UI dialog here later
	await get_tree().create_timer(0.1).timeout  # Small delay for realism
	return true

func launch_cooking_game(recipe_data: Dictionary):
	print("=== LAUNCHING COOKING GAME FROM ARTIFACT ===")
	print("Recipe: ", recipe_data)
	
	# Create cooking launcher if not exists
	var launcher = get_tree().get_first_node_in_group("cooking_launcher")
	if not launcher:
		# Create launcher node
		var cooking_launcher_script = preload("res://Systems/UI/Cooking Game/CookingGameLauncher.gd")
		launcher = Node.new()
		launcher.set_script(cooking_launcher_script)
		launcher.add_to_group("cooking_launcher")
		get_tree().root.add_child(launcher)
	
	# Launch cooking game
	launcher.launch_cooking_game(item_name, recipe_data)

func _on_artifact_collected(artifact_name: String, _region: String):
	# This function can be used for additional collection logic
	if artifact_name == item_name:
		print("Artifact collected: ", artifact_name, " from ", _region)