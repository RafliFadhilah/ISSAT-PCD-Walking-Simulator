class_name CulturalNPC
extends CulturalInteractableObject

# Static variable to track which NPC has active dialogue
static var active_dialogue_npc: CulturalNPC = null

@export var npc_name: String
@export var cultural_region: String
@export var npc_type: String = "Guide"  # Guide, Vendor, Historian
@export var dialogue_data: Array[Dictionary] = []
@export var interaction_range: float = 3.0
@export var npc_model: PackedScene

# NPC behavior using State Pattern
var state_machine: NPCStateMachine
var player_distance: float = 0.0
var player: CharacterBody3D

# Dialogue state tracking
var dialogue_just_ended: bool = false
var dialogue_end_time: float = 0.0
var dialogue_cooldown_duration: float = 1.0  # Reduced to 1 second for better UX
var dialogue_history: Array = []  # Track dialogue history for navigation

# Cultural knowledge
var cultural_topics: Array[String] = []
var current_topic: String = ""

# Quest system variables
@export var quest_artifact_required: String = ""  # artifact yang diminta NPC ini
@export var quest_completed: bool = false  # apakah quest sudah selesai
@export var quest_title: String = ""  # judul quest
@export var quest_description: String = ""  # deskripsi quest



# Safe input handling for NPC
func safe_set_input_as_handled():
	# Simple wrapper for set_input_as_handled()
	var viewport = get_viewport()
	if viewport:
		viewport.set_input_as_handled()
		return true
	return false

func _ready():
	setup_npc()
	connect_signals()
	find_player()
	
	# Initialize state machine
	state_machine = NPCStateMachine.new(self)
	
	# Setup quest artifact based on NPC type and name
	setup_quest_artifact()
	
	# Initialize dialogue data if empty
	if dialogue_data.is_empty():
		setup_default_dialogue()
	
	if has_node("/root/DebugConfig") and not get_node("/root/DebugConfig").enable_npc_debug:
		return
	GameLogger.debug("NPC Ready: " + name)
	GameLogger.info("CulturalNPC initialized: " + npc_name + " (Type: " + npc_type + ") - Quest: " + quest_artifact_required)

func _input(event):
	# Only process input if this NPC is the active dialogue NPC
	if active_dialogue_npc != self:
		return
		
	# Handle dialogue input directly for better responsiveness
	if not has_active_dialogue():
		# If we don't have active dialogue but we're the active NPC, clear the static reference
		if active_dialogue_npc == self:
			active_dialogue_npc = null
		return
		
	if event is InputEventKey and event.pressed:
		# DEBUG: Log ALL key presses during dialogue
		GameLogger.info("CulturalNPC (" + npc_name + "): Key pressed during dialogue: " + str(event.physical_keycode) + " (" + str(char(event.physical_keycode)) + ")")
		
		# Get current dialogue
		var current_dialogue = dialogue_history.back() if dialogue_history.size() > 0 else get_initial_dialogue()
		var options = current_dialogue.get("options", [])
		
		GameLogger.debug("CulturalNPC (" + npc_name + "): Current dialogue has " + str(options.size()) + " options")
		
		# Handle number keys 1-4 for dialogue choices
		if event.physical_keycode >= KEY_1 and event.physical_keycode <= KEY_4:
			var choice_index = event.physical_keycode - KEY_1
			GameLogger.info("CulturalNPC (" + npc_name + "): Number key " + str(choice_index + 1) + " pressed, options available: " + str(options.size()))
			
			if choice_index < options.size():
				GameLogger.info("CulturalNPC (" + npc_name + "): EXECUTING dialogue choice " + str(choice_index + 1) + "!")
				_handle_dialogue_choice(choice_index)
				get_viewport().set_input_as_handled()
				return
			else:
				GameLogger.warning("CulturalNPC (" + npc_name + "): Choice index " + str(choice_index + 1) + " is out of range for " + str(options.size()) + " options")
		
		# Handle other dialogue controls
		elif event.physical_keycode == KEY_X:
			GameLogger.info("CulturalNPC (" + npc_name + "): X key pressed - ending dialogue")
			end_visual_dialogue()
			get_viewport().set_input_as_handled()
			return
		elif event.physical_keycode == KEY_LEFT:
			GameLogger.info("CulturalNPC (" + npc_name + "): Left arrow pressed - going back")
			_on_back_button_pressed()
			get_viewport().set_input_as_handled()
			return
		elif event.physical_keycode == KEY_RIGHT or event.physical_keycode == KEY_C:
			GameLogger.info("CulturalNPC (" + npc_name + "): Right arrow/C pressed - closing")
			_on_close_button_pressed()
			get_viewport().set_input_as_handled()
			return

func find_player():
	# Find the player in the scene tree
	var scene_tree = get_tree()
	if scene_tree:
		# Look for the player node by group first
		var player_node = scene_tree.get_first_node_in_group("player")
		if player_node and player_node is CharacterBody3D:
			player = player_node
			GameLogger.info("NPC " + npc_name + " found player: " + player.name)
		else:
			# Try to find by searching through the scene tree
			player_node = _find_player_in_tree(scene_tree.current_scene)
			
			if player_node and player_node is CharacterBody3D:
				player = player_node
				GameLogger.info("NPC " + npc_name + " found player by search: " + player.name)
			else:
				GameLogger.warning("NPC " + npc_name + " could not find player")

# Helper function to recursively search for player
func _find_player_in_tree(node: Node) -> Node:
	if not node:
		return null
	
	# Check if this node is the player (CharacterBody3D in player group)
	if node is CharacterBody3D and node.is_in_group("player"):
		return node
	
	# Search children
	for child in node.get_children():
		var result = _find_player_in_tree(child)
		if result:
			return result
	
	return null

func setup_npc():
	# Add to NPC group for InteractionController to find
	add_to_group("npc")
	
	# Set up interaction prompt
	interaction_prompt = "Talk to " + npc_name
	
	# Set interaction range (3 meters by default)
	interaction_range = 3.0
	
	# Load NPC model if provided
	if npc_model:
		var model_instance = npc_model.instantiate()
		add_child(model_instance)
	
	# Set up cultural topics based on region and type
	setup_cultural_topics()
	
	# Add interaction area for better detection
	setup_interaction_area()
	
	GameLogger.debug("NPC " + npc_name + " setup complete - Interaction range: " + str(interaction_range))

func setup_interaction_area():
	# Create an Area3D for better interaction detection
	var interaction_area = Area3D.new()
	interaction_area.name = "InteractionArea"
	
	# Create collision shape
	var collision_shape = CollisionShape3D.new()
	var sphere_shape = SphereShape3D.new()
	sphere_shape.radius = interaction_range
	collision_shape.shape = sphere_shape
	interaction_area.add_child(collision_shape)
	
	# Set collision layers to detect player (layer 1)
	interaction_area.collision_layer = 0  # Don't collide with anything
	interaction_area.collision_mask = 1   # Detect objects on layer 1 (player)
	
	# Add to NPC
	add_child(interaction_area)
	
	# Connect signals for better interaction detection
	interaction_area.body_entered.connect(_on_player_entered_area)
	interaction_area.body_exited.connect(_on_player_exited_area)
	
	GameLogger.debug("NPC " + npc_name + " interaction area set up with radius: " + str(interaction_range))

func _on_player_entered_area(body: Node3D):
	if body is CharacterBody3D and body.is_in_group("player"):
		GameLogger.info("Player entered interaction range of " + npc_name)
		# Visual feedback - could add a glow effect here
		show_interaction_available()

func _on_player_exited_area(body: Node3D):
	if body is CharacterBody3D and body.is_in_group("player"):
		GameLogger.info("Player exited interaction range of " + npc_name)
		# Hide visual feedback
		hide_interaction_available()

func show_interaction_available():
	# Add visual feedback when player is in range
	if has_node("NPCModel"):
		var model = get_node("NPCModel")
		if model:
			# Check if the model supports modulate property
			if model.has_method("set_modulate") or model.has_signal("modulate_changed"):
				# Add a subtle glow effect
				model.modulate = Color(1.2, 1.2, 1.0)  # Slight yellow tint
			else:
				# For nodes that don't support modulate, create a visual indicator
				_create_interaction_indicator()

func hide_interaction_available():
	# Remove visual feedback when player leaves range
	if has_node("NPCModel"):
		var model = get_node("NPCModel")
		if model:
			# Check if the model supports modulate property
			if model.has_method("set_modulate") or model.has_signal("modulate_changed"):
				model.modulate = Color.WHITE
			else:
				# Remove visual indicator
				_remove_interaction_indicator()

func _create_interaction_indicator():
	# Create a visual indicator for interaction availability
	var indicator = get_node_or_null("InteractionIndicator")
	if not indicator:
		# Wait until we're in the scene tree before creating the indicator
		if not is_inside_tree():
			# Schedule creation for next frame when we're in the tree
			call_deferred("_create_interaction_indicator")
			return
		
		indicator = CSGSphere3D.new()
		indicator.name = "InteractionIndicator"
		indicator.radius = 0.3
		
		# Use position instead of global_position to avoid timing issues
		indicator.position = Vector3(0, 2, 0)  # Above the NPC
		
		# Create material for the indicator
		var material = StandardMaterial3D.new()
		material.albedo_color = Color.YELLOW
		material.emission_enabled = true
		material.emission = Color.YELLOW
		material.emission_energy = 0.5
		indicator.material = material
		
		add_child(indicator)
		GameLogger.debug("Created interaction indicator for " + npc_name)

func _remove_interaction_indicator():
	# Remove the visual indicator
	var indicator = get_node_or_null("InteractionIndicator")
	if indicator:
		indicator.queue_free()
		GameLogger.debug("Removed interaction indicator for " + npc_name)

func connect_signals():
	# Connect to both GlobalSignals and EventBus for compatibility
	GlobalSignals.on_npc_interaction.connect(_on_npc_interaction)
	
	# Connect to EventBus (autoload singleton)
	if EventBus:
		EventBus.subscribe(self, _on_event_bus_npc_interaction, [EventBus.EventType.NPC_INTERACTION])

func _process(delta):
	if player:
		player_distance = position.distance_to(player.position)
	
	# Update state machine
	if state_machine:
		state_machine.update(delta)

func _interact():
	# Trust the InteractionController's RayCast detection (like PedestalInteraction.gd)
	# The InteractionController only calls _interact() when player is in range
	if not can_interact:
		GameLogger.debug("Interaction blocked - can_interact is false for " + npc_name)
		return
	
	# Check if there's already an active dialogue with another NPC
	if active_dialogue_npc != null and active_dialogue_npc != self:
		GameLogger.debug("Interaction blocked - another NPC (" + active_dialogue_npc.npc_name + ") has active dialogue")
		return
	
	# Check if dialogue just ended and we're still in cooldown
	if dialogue_just_ended:
		var current_time = Time.get_unix_time_from_system()
		if current_time - dialogue_end_time < dialogue_cooldown_duration:
			GameLogger.debug("Interaction blocked - dialogue cooldown active for " + npc_name + " (time remaining: " + str(dialogue_cooldown_duration - (current_time - dialogue_end_time)) + "s)")
			return
		else:
			dialogue_just_ended = false
			# Reset can_interact to allow new interaction after cooldown
			can_interact = true
			GameLogger.debug("Dialogue cooldown expired, allowing interaction for " + npc_name)
		
	GameLogger.info("Starting interaction with " + npc_name)
	
	# Visual feedback for interaction
	show_interaction_feedback()
	
	# Change to interacting state
	if state_machine:
		state_machine.change_state(state_machine.get_interacting_state())
	
	# Emit interaction event
	emit_interaction_event()
	
	# Start dialogue with visual UI
	start_visual_dialogue()
	
	# Disable interaction temporarily to prevent spam during active dialogue
	can_interact = false
	GameLogger.debug("Interaction disabled during dialogue for " + npc_name)

func start_visual_dialogue():
	# Set this NPC as the active dialogue NPC
	active_dialogue_npc = self
	GameLogger.info("CulturalNPC (" + npc_name + "): Starting visual dialogue - set as active dialogue NPC")
	
	# Get initial dialogue
	var initial_dialogue = get_initial_dialogue()
	if initial_dialogue.is_empty():
		GameLogger.warning("No dialogue data found for " + npc_name)
		active_dialogue_npc = null  # Clear if no dialogue
		return
	
	# Display dialogue UI
	display_dialogue_ui(initial_dialogue)
	
	# NOTE: We now use _input() method for input handling instead of timer polling
	# Timer system is disabled to prevent conflicts

func display_dialogue_ui(dialogue: Dictionary):
	# Close all existing dialogue UIs first to prevent conflicts
	close_all_dialogue_uis()
	
	# Add to dialogue history
	dialogue_history.append(dialogue)
	
	# Create a beautiful vintage-style dialogue UI
	var dialogue_ui = get_node_or_null("DialogueUI")
	if not dialogue_ui:
		dialogue_ui = Control.new()
		dialogue_ui.name = "DialogueUI"
		dialogue_ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		dialogue_ui.mouse_filter = Control.MOUSE_FILTER_STOP
		add_child(dialogue_ui)
		
		# Create background with vintage texture
		var background = ColorRect.new()
		background.color = Color(0.05, 0.05, 0.08, 0.9)
		background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		dialogue_ui.add_child(background)
		
		# Create main dialogue panel with vintage styling
		var dialogue_panel = Panel.new()
		dialogue_panel.name = "DialoguePanel"
		dialogue_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
		dialogue_panel.offset_left = -500
		dialogue_panel.offset_top = -300
		dialogue_panel.offset_right = 500
		dialogue_panel.offset_bottom = 300
		
		# Create vintage panel style with Bezier curves
		var panel_style = StyleBoxFlat.new()
		panel_style.bg_color = Color(0.1, 0.15, 0.25, 0.95)  # Dark blue vintage color
		panel_style.border_color = Color(0.8, 0.75, 0.6, 1.0)  # Vintage cream border
		panel_style.border_width_left = 3
		panel_style.border_width_top = 3
		panel_style.border_width_right = 3
		panel_style.border_width_bottom = 3
		panel_style.corner_radius_top_left = 15
		panel_style.corner_radius_top_right = 15
		panel_style.corner_radius_bottom_left = 15
		panel_style.corner_radius_bottom_right = 15
		panel_style.shadow_color = Color(0, 0, 0, 0.3)
		panel_style.shadow_size = 8
		panel_style.shadow_offset = Vector2(4, 4)
		dialogue_panel.add_theme_stylebox_override("panel", panel_style)
		
		dialogue_ui.add_child(dialogue_panel)
		
		# Create vintage header with icon and title
		var header_container = HBoxContainer.new()
		header_container.name = "HeaderContainer"
		header_container.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
		header_container.offset_left = 20
		header_container.offset_top = 15
		header_container.offset_right = -20
		header_container.offset_bottom = 70
		header_container.add_theme_constant_override("separation", 15)
		dialogue_panel.add_child(header_container)
		
		# Create chat bubble icon using 2D primitives
		var chat_icon = Control.new()
		chat_icon.name = "ChatIcon"
		chat_icon.custom_minimum_size = Vector2(40, 40)
		chat_icon.draw.connect(_draw_chat_icon.bind(chat_icon))
		header_container.add_child(chat_icon)
		
		# Create title label with vintage styling
		var title_label = Label.new()
		title_label.name = "TitleLabel"
		title_label.text = "DIALOG\nHISTORY"
		title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		title_label.add_theme_font_size_override("font_size", 18)
		title_label.add_theme_color_override("font_color", Color(0.8, 0.75, 0.6, 1.0))
		title_label.add_theme_constant_override("line_spacing", 2)
		header_container.add_child(title_label)
		
		# Add spacer to push next icon to right
		var header_spacer = Control.new()
		header_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		header_container.add_child(header_spacer)
		
		# Create next arrow icon
		var next_icon = Control.new()
		next_icon.name = "NextIcon"
		next_icon.custom_minimum_size = Vector2(30, 30)
		next_icon.draw.connect(_draw_next_icon.bind(next_icon))
		header_container.add_child(next_icon)
		
		# Create message area with vintage styling
		var message_container = VBoxContainer.new()
		message_container.name = "MessageContainer"
		message_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		message_container.offset_left = 30
		message_container.offset_top = 90
		message_container.offset_right = -30
		message_container.offset_bottom = -80
		message_container.add_theme_constant_override("separation", 15)
		dialogue_panel.add_child(message_container)
		
		# Create NPC name label with vintage styling
		var npc_name_label = Label.new()
		npc_name_label.name = "NPCNameLabel"
		npc_name_label.text = npc_name
		npc_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		npc_name_label.add_theme_font_size_override("font_size", 24)
		npc_name_label.add_theme_color_override("font_color", Color(1, 0.8, 0.4, 1.0))  # Golden color
		message_container.add_child(npc_name_label)
		
		# Create message text with vintage styling
		var message_text = RichTextLabel.new()
		message_text.name = "MessageText"
		message_text.size_flags_vertical = Control.SIZE_EXPAND_FILL
		message_text.bbcode_enabled = true
		message_text.fit_content = true
		message_text.add_theme_font_size_override("normal_font_size", 20)
		message_text.add_theme_color_override("default_color", Color(0.9, 0.85, 0.7, 1.0))  # Vintage cream text
		message_text.add_theme_constant_override("line_spacing", 4)
		message_container.add_child(message_text)
		
		# Create options container with vintage styling
		var options_container = VBoxContainer.new()
		options_container.name = "OptionsContainer"
		options_container.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
		options_container.offset_left = 30
		options_container.offset_top = -150
		options_container.offset_right = -30
		options_container.offset_bottom = -60
		options_container.add_theme_constant_override("separation", 8)
		dialogue_panel.add_child(options_container)
		
		# Create navigation buttons with vintage styling
		var nav_container = HBoxContainer.new()
		nav_container.name = "NavigationContainer"
		nav_container.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
		nav_container.offset_left = 20
		nav_container.offset_top = -50
		nav_container.offset_right = 180
		nav_container.offset_bottom = -20
		nav_container.add_theme_constant_override("separation", 10)
		dialogue_panel.add_child(nav_container)
		
		# Create back button with vintage styling
		var back_button = Button.new()
		back_button.name = "BackButton"
		back_button.text = "← Back (←)"
		back_button.custom_minimum_size = Vector2(100, 30)
		back_button.pressed.connect(_on_back_button_pressed)
		nav_container.add_child(back_button)
		
		# Create close button with vintage styling
		var close_button = Button.new()
		close_button.name = "CloseButton"
		close_button.text = "Close (→/C)"
		close_button.custom_minimum_size = Vector2(100, 30)
		close_button.pressed.connect(_on_close_button_pressed)
		nav_container.add_child(close_button)
		
		# Style the buttons with vintage appearance
		_style_vintage_button(back_button)
		_style_vintage_button(close_button)
		
		# Create keyboard controls indicator
		var controls_label = Label.new()
		controls_label.name = "ControlsLabel"
		controls_label.text = "Controls: [1-3] Choose option, [←] Back, [→/C] Close, [X] Exit Dialog, [Space] Skip animation"
		controls_label.add_theme_font_size_override("font_size", 12)
		controls_label.add_theme_color_override("font_color", Color(0.8, 0.75, 0.6, 0.8))
		controls_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		controls_label.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
		controls_label.offset_left = 20
		controls_label.offset_top = -30
		controls_label.offset_right = -20
		controls_label.offset_bottom = -10
		dialogue_panel.add_child(controls_label)
	
	# Update dialogue content
	var message_text_node = dialogue_ui.get_node("DialoguePanel/MessageContainer/MessageText")
	var options_container_node = dialogue_ui.get_node("DialoguePanel/OptionsContainer")
	
	if message_text_node:
		var text_content = dialogue.get("message", "Hello! How can I help you?")
		GameLogger.debug("Displaying dialog text: " + text_content)
		# Use typewriter animation to prevent accidental fast clicking
		start_typewriter_animation(message_text_node, "[i]" + text_content + "[/i]")
	else:
		GameLogger.warning("MessageText node not found in dialog UI")
	
	# Get options first for logging
	var options = dialogue.get("options", [])
	
	# Clear and add options with vintage styling
	if options_container_node:
		# Clear existing options
		for child in options_container_node.get_children():
			child.queue_free()
		
		# Add numbered options with vintage styling
		for i in range(options.size()):
			var option = options[i]
			var option_button = Button.new()
			option_button.text = str(i + 1) + ". " + option.get("text", "Option " + str(i + 1))
			option_button.custom_minimum_size = Vector2(0, 35)
			option_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			
			# Style with vintage appearance
			_style_vintage_button(option_button)
			
			# Connect button press
			option_button.pressed.connect(_handle_dialogue_choice.bind(i))
			
			options_container_node.add_child(option_button)
	
	dialogue_ui.visible = true
	GameLogger.info("=== DIALOGUE STARTED ===")
	GameLogger.info("NPC: " + dialogue.get("message", "Hello!"))
	GameLogger.info("Options available: " + str(options.size()))
	
	# DEBUG: Verify UI state after creation
	call_deferred("_verify_dialogue_ui_state")

func _setup_dialogue_input_handling():
	# CRITICAL: Check if we're still valid before creating timer
	if not is_inside_tree() or not is_instance_valid(self):
		GameLogger.warning("CulturalNPC: Cannot setup input handling - node not in tree or invalid")
		return
	
	# Enhanced debug logging for input handling setup
	if has_node("/root/DebugConfig") and get_node("/root/DebugConfig").enable_npc_input_debug:
		GameLogger.debug("CulturalNPC: Setting up input handling for " + npc_name + " - is_inside_tree: " + str(is_inside_tree()) + ", is_instance_valid: " + str(is_instance_valid(self)))
	
	# Clean up any existing timer first
	var existing_timer = get_node_or_null("DialogueInputTimer")
	if existing_timer:
		existing_timer.stop()
		existing_timer.queue_free()
		GameLogger.debug("CulturalNPC: Cleaned up existing input timer")
	
	# Create a timer to check for input during dialogue
	var input_timer = Timer.new()
	input_timer.name = "DialogueInputTimer"
	input_timer.wait_time = 0.1  # Check every 0.1 seconds
	
	# Connect with a lambda that includes safety checks
	input_timer.timeout.connect(func():
		# CRITICAL: Check if we're still valid before processing
		if not is_instance_valid(self) or not is_inside_tree():
			GameLogger.warning("CulturalNPC: Timer fired but node no longer valid or scene being destroyed, cleaning up")
			if is_instance_valid(input_timer):
				input_timer.stop()
				input_timer.queue_free()
			return
		
		# Enhanced debug logging for timer execution
		if has_node("/root/DebugConfig") and get_node("/root/DebugConfig").enable_timer_debug:
			GameLogger.debug("CulturalNPC: Input timer fired for " + npc_name + " - is_inside_tree: " + str(is_inside_tree()) + ", is_instance_valid: " + str(is_instance_valid(self)))
		
		# Call the actual input check function
		_check_dialogue_input()
	)
	
	add_child(input_timer)
	input_timer.start()
	GameLogger.debug("CulturalNPC: Created new input timer with safety checks")

func _check_dialogue_input():
	# Enhanced debug logging for input check
	if has_node("/root/DebugConfig") and get_node("/root/DebugConfig").enable_tree_debug:
		GameLogger.debug("CulturalNPC: Input check for " + npc_name + " - is_inside_tree: " + str(is_inside_tree()) + ", is_instance_valid: " + str(is_instance_valid(self)))
	
	# CRITICAL: Check if we're still in the tree before ANY processing
	if not is_inside_tree() or not is_instance_valid(self):
		GameLogger.warning("CulturalNPC: Node not in tree, invalid, or scene being destroyed during input check, cleaning up")
		var input_timer = get_node_or_null("DialogueInputTimer")
		if input_timer:
			input_timer.stop()
			input_timer.queue_free()
		return
	
	# Additional safety check - ensure we have a valid viewport
	var viewport = get_viewport()
	if not viewport or not is_instance_valid(viewport):
		GameLogger.warning("CulturalNPC: No valid viewport during input check, cleaning up")
		var input_timer = get_node_or_null("DialogueInputTimer")
		if input_timer:
			input_timer.stop()
			input_timer.queue_free()
		return
	
	# Check if dialogue UI exists and is visible
	var dialogue_ui = get_node_or_null("DialogueUI")
	if not dialogue_ui or not dialogue_ui.visible:
		# Clean up timer if dialogue is not active
		var input_timer = get_node_or_null("DialogueInputTimer")
		if input_timer:
			input_timer.stop()
			input_timer.queue_free()
		return
	
	# Get current dialogue from history (most recent)
	var current_dialogue = dialogue_history.back() if dialogue_history.size() > 0 else get_initial_dialogue()
	var options = current_dialogue.get("options", [])
	
	# Check for number keys 1-N
	for i in range(options.size()):
		if Input.is_action_just_pressed("dialogue_choice_" + str(i + 1)) or Input.is_key_pressed(KEY_1 + i):
			_handle_dialogue_choice(i)
			# Consume the input to prevent it from bubbling up to menu system
			safe_set_input_as_handled()
			return
	
	# Check for X key to close dialogue
	if Input.is_action_just_pressed("dialogue_cancel") or Input.is_key_pressed(KEY_X):
		# Exit dialogue with X
		GameLogger.info("Dialogue cancelled with X key")
		end_visual_dialogue()
		# Consume the input to prevent it from bubbling up to menu system
		safe_set_input_as_handled()
		return
	
	# Check for back button (Left Arrow)
	if Input.is_action_just_pressed("dialogue_back") or Input.is_key_pressed(KEY_LEFT):
		_on_back_button_pressed()
		# Consume the input to prevent it from bubbling up to menu system
		safe_set_input_as_handled()
		return
	
	# Check for close button (Right Arrow or C key)
	if Input.is_key_pressed(KEY_RIGHT) or Input.is_key_pressed(KEY_C):
		_on_close_button_pressed()
		# Consume the input to prevent it from bubbling up to menu system
		safe_set_input_as_handled()
		return

func handle_dialogue_option(option: Dictionary):
	"""Handle dialogue option selection (for compatibility with CookingGameNPC)"""
	var action = option.get("action", "")
	var consequence = option.get("consequence", "")
	var next_dialogue_id = option.get("next_dialogue", "")
	
	GameLogger.info("Player selected dialogue option: " + option.get("text", "Unknown"))
	
	# Handle common actions
	if action == "end_dialogue":
		end_visual_dialogue()
		return
	
	# Handle consequence and next dialogue like the original system
	_process_dialogue_consequence(consequence, next_dialogue_id, option)

func _process_dialogue_consequence(consequence: String, next_dialogue_id: String, _option: Dictionary):
	"""Process dialogue consequence and navigation (extracted from _handle_dialogue_choice)"""
	if next_dialogue_id != "":
		# If there's a next dialogue, navigate to it
		var next_dialogue = get_dialogue_by_id(next_dialogue_id)
		if not next_dialogue.is_empty():
			GameLogger.info("Navigating to dialogue: " + next_dialogue_id)
			# Add to dialogue history
			dialogue_history.append(next_dialogue)
			display_dialogue_ui(next_dialogue)
			
			# If there's also a consequence, handle it after navigation
			if consequence == "share_knowledge":
				GameLogger.info("Sharing knowledge after navigation")
				share_cultural_knowledge()
		else:
			GameLogger.warning("Could not find dialogue with id: " + next_dialogue_id)
			# Fall back to consequence handling
			_handle_consequence_only(consequence)
	else:
		# No next dialogue, handle consequence only
		_handle_consequence_only(consequence)

func _handle_consequence_only(consequence: String):
	"""Handle dialogue consequence without navigation"""
	if consequence == "share_knowledge":
		share_cultural_knowledge()
	elif consequence == "end_dialogue" or consequence == "end_conversation":
		# Handle both "end_dialogue" and "end_conversation" for compatibility
		GameLogger.info("CulturalNPC (" + npc_name + "): Ending dialogue due to consequence: " + consequence)
		end_visual_dialogue()
	elif consequence == "check_artifact":
		# Check if player has the required artifact
		_handle_check_artifact()
	elif consequence == "complete_quest":
		# Complete the quest by taking the artifact
		_handle_complete_quest()
	elif consequence == "quest_accept":
		# Player accepts the quest
		GameLogger.info("Player accepted quest: " + quest_title)
	# Add other consequence handling as needed

func _handle_check_artifact():
	"""Check if player has required artifact and handle accordingly"""
	if has_required_artifact():
		GameLogger.info("Player has required artifact: " + quest_artifact_required)
		# Player has the artifact, proceed with giving it
		var give_dialogue = get_dialogue_by_id("give_artifact")
		if not give_dialogue.is_empty():
			dialogue_history.append(give_dialogue)
			display_dialogue_ui(give_dialogue)
	else:
		GameLogger.info("Player doesn't have required artifact: " + quest_artifact_required)
		# Player doesn't have the artifact
		var no_artifact_message = "I don't see the " + quest_artifact_required + " in your belongings. Please explore the area to find it first."
		update_dialogue_text(no_artifact_message)

func _handle_complete_quest():
	"""Complete the quest by taking the artifact from player"""
	if give_artifact_to_npc():
		GameLogger.info("Quest completed successfully for " + npc_name)
		# Navigate to quest completed dialogue
		var completed_dialogue = get_dialogue_by_id("quest_completed")
		if not completed_dialogue.is_empty():
			dialogue_history.append(completed_dialogue)
			display_dialogue_ui(completed_dialogue)
	else:
		GameLogger.warning("Failed to complete quest for " + npc_name)
		update_dialogue_text("There seems to be a problem. Please try again.")

func _handle_dialogue_choice(choice_index: int):
	# Check if we're still in the tree before processing choice
	if not is_inside_tree() or not is_instance_valid(self):
		GameLogger.warning("CulturalNPC: Node not in tree or invalid during dialogue choice, ignoring")
		return
	
	# Get current dialogue from history (most recent)
	var current_dialogue = dialogue_history.back() if dialogue_history.size() > 0 else get_initial_dialogue()
	var options = current_dialogue.get("options", [])
	
	if choice_index >= options.size():
		return
	
	var selected_option = options[choice_index]
	var consequence = selected_option.get("consequence", "")
	var next_dialogue_id = selected_option.get("next_dialogue", "")
	
	GameLogger.info("Player chose: " + selected_option.get("text", "Option " + str(choice_index + 1)))
	
	# Use the extracted dialogue processing function
	_process_dialogue_consequence(consequence, next_dialogue_id, selected_option)

func update_dialogue_text(new_text: String):
	var dialogue_ui = get_node_or_null("DialogueUI")
	if dialogue_ui:
		var message_text = dialogue_ui.get_node_or_null("DialoguePanel/MessageContainer/MessageText")
		if message_text:
			start_typewriter_animation(message_text, "[i]" + new_text + "[/i]")

func start_typewriter_animation(message_text: RichTextLabel, full_text: String):
	# Check if we're still valid before starting animation
	if not is_inside_tree() or not is_instance_valid(self):
		GameLogger.warning("CulturalNPC: Cannot start typewriter animation - node not in tree or invalid")
		return
	
	GameLogger.debug("Starting typewriter animation for text: " + full_text)
	
	# Remove any existing timer first
	var existing_timer = get_node_or_null("TypewriterTimer")
	if existing_timer:
		existing_timer.stop()
		existing_timer.queue_free()
	
	# Clear the text first
	message_text.text = ""
	
	# Create a new timer
	var typewriter_timer = Timer.new()
	typewriter_timer.name = "TypewriterTimer"
	typewriter_timer.wait_time = 0.05  # Slightly slower for better visibility
	add_child(typewriter_timer)
	
	# Store animation state in the timer to avoid variable scope issues
	typewriter_timer.set_meta("current_char_index", 0)
	typewriter_timer.set_meta("is_bbcode_tag", false)
	typewriter_timer.set_meta("bbcode_tag", "")
	typewriter_timer.set_meta("full_text", full_text)
	typewriter_timer.set_meta("message_text", message_text)
	
	# Connect the timer
	typewriter_timer.timeout.connect(func():
		# Get stored values
		var current_char_index = typewriter_timer.get_meta("current_char_index", 0)
		var is_bbcode_tag = typewriter_timer.get_meta("is_bbcode_tag", false)
		var bbcode_tag = typewriter_timer.get_meta("bbcode_tag", "")
		var stored_full_text = typewriter_timer.get_meta("full_text", "")
		var stored_message_text = typewriter_timer.get_meta("message_text", null)
		
		# Check if the message_text is still valid
		if not is_instance_valid(stored_message_text):
			GameLogger.warning("MessageText is no longer valid, stopping animation")
			typewriter_timer.stop()
			typewriter_timer.queue_free()
			return
			
		# Check for skip animation input (Space or Enter)
		if Input.is_action_just_pressed("ui_accept") or Input.is_key_pressed(KEY_SPACE):
			# Skip to end
			GameLogger.debug("Skipping animation to end")
			stored_message_text.text = stored_full_text
			typewriter_timer.stop()
			typewriter_timer.queue_free()
			return
			
		# Process multiple characters per frame for better performance
		var chars_to_process = 2  # Process 2 characters per frame
		for i in range(chars_to_process):
			if current_char_index >= stored_full_text.length():
				# Animation complete
				GameLogger.debug("Animation complete")
				typewriter_timer.stop()
				typewriter_timer.queue_free()
				return
				
			var current_char = stored_full_text[current_char_index]
			
			# Handle BBCode tags
			if current_char == "[":
				is_bbcode_tag = true
				bbcode_tag = "["
			elif current_char == "]" and is_bbcode_tag:
				bbcode_tag += "]"
				stored_message_text.text += bbcode_tag
				is_bbcode_tag = false
				bbcode_tag = ""
			elif is_bbcode_tag:
				bbcode_tag += current_char
			else:
				# Add regular character
				stored_message_text.text += current_char
			
			current_char_index += 1
			GameLogger.debug("Added character: " + current_char + " (index: " + str(current_char_index) + "/" + str(stored_full_text.length()) + ")")
		
		# Update stored values for next iteration
		typewriter_timer.set_meta("current_char_index", current_char_index)
		typewriter_timer.set_meta("is_bbcode_tag", is_bbcode_tag)
		typewriter_timer.set_meta("bbcode_tag", bbcode_tag)
	)
	
	# Start the animation
	GameLogger.debug("Starting typewriter timer")
	typewriter_timer.start()

func end_visual_dialogue():
	# Check if we're still valid before processing
	if not is_instance_valid(self):
		GameLogger.warning("CulturalNPC: Node invalid during end_visual_dialogue, skipping")
		return
	
	# Clear active dialogue NPC if this NPC is the active one
	if active_dialogue_npc == self:
		active_dialogue_npc = null
		GameLogger.info("CulturalNPC (" + npc_name + "): Cleared active dialogue NPC")
	
	# Close only THIS NPC's dialogue UI, not all UIs to allow other NPCs to interact
	close_npc_dialogue_ui()
	
	# Clean up input timer
	var input_timer = get_node_or_null("DialogueInputTimer")
	if input_timer:
		input_timer.stop()
		input_timer.queue_free()
		GameLogger.debug("CulturalNPC: Input timer cleaned up")
	
	# Clean up typewriter timer if it exists
	var typewriter_timer = get_node_or_null("TypewriterTimer")
	if typewriter_timer:
		typewriter_timer.stop()
		typewriter_timer.queue_free()
		GameLogger.debug("CulturalNPC: Typewriter timer cleaned up")
	
	# Mark dialogue as ended ONLY for this specific NPC
	mark_dialogue_ended()
	
	GameLogger.info("=== DIALOGUE ENDED for " + npc_name + " ===")

func close_all_dialogue_uis():
	# Close dialogue UI from ALL NPCs to prevent conflicts
	var all_npcs = get_tree().get_nodes_in_group("npc")
	for npc in all_npcs:
		if npc.has_method("close_npc_dialogue_ui"):
			npc.close_npc_dialogue_ui()
		else:
			# Fallback: directly close dialogue UI
			var dialogue_ui = npc.get_node_or_null("DialogueUI")
			if dialogue_ui:
				dialogue_ui.visible = false
				GameLogger.debug("Closed dialogue UI for NPC: " + npc.name)

func close_npc_dialogue_ui():
	# Close this NPC's dialogue UI
	var dialogue_ui = get_node_or_null("DialogueUI")
	if dialogue_ui:
		dialogue_ui.visible = false
		GameLogger.debug("Closed dialogue UI for NPC: " + npc_name)

func show_interaction_feedback():
	# Visual feedback when interaction starts
	if has_node("NPCModel"):
		var model = get_node("NPCModel")
		if model:
			# Check if the model supports modulate property
			if model.has_method("set_modulate") or model.has_signal("modulate_changed"):
				# Flash green briefly
				var tween = create_tween()
				tween.tween_property(model, "modulate", Color.GREEN, 0.1)
				tween.tween_property(model, "modulate", Color.WHITE, 0.1)
			else:
				# For nodes that don't support modulate, flash the indicator
				_flash_interaction_indicator()

func _flash_interaction_indicator():
	# Flash the interaction indicator briefly
	var indicator = get_node_or_null("InteractionIndicator")
	if indicator:
		var tween = create_tween()
		tween.tween_property(indicator, "scale", Vector3(1.5, 1.5, 1.5), 0.1)
		tween.tween_property(indicator, "scale", Vector3(1.0, 1.0, 1.0), 0.1)
		GameLogger.debug("Flashed interaction indicator for " + npc_name)

func emit_interaction_event():
	# Emit to both systems for compatibility
	GlobalSignals.on_npc_interaction.emit(npc_name, cultural_region)
	
	# Emit to EventBus (autoload singleton)
	if EventBus:
		EventBus.emit_npc_interaction(npc_name, cultural_region)
		GameLogger.info("Emitted NPC interaction event for " + npc_name)
	else:
		GameLogger.error("EventBus not available for " + npc_name)

func setup_default_dialogue():
	# Set up default dialogue based on NPC type and region
	match npc_type:
		"Guide":
			setup_guide_dialogue()
		"Historian":
			setup_historian_dialogue()
		"Vendor":
			setup_vendor_dialogue()
		_:
			setup_generic_dialogue()
	
	# Add quest dialogues for Papua NPCs if not already present
	if cultural_region == "Indonesia Timur" and quest_artifact_required != "":
		add_quest_dialogues()

func setup_guide_dialogue():
	match cultural_region:
		"Indonesia Barat":
			dialogue_data = [
				{
					"id": "greeting",
					"message": "Selamat datang! Welcome to our traditional market. I can guide you through the rich cultural heritage of Indonesia Barat.",
					"options": [
						{
							"text": "Tell me about the market history",
							"next_dialogue": "market_history",
							"consequence": "share_knowledge"
						},
						{
							"text": "What food should I try?",
							"next_dialogue": "food_recommendations",
							"consequence": "share_knowledge"
						},
						{
							"text": "Goodbye",
							"consequence": "end_conversation"
						}
					]
				},
				{
					"id": "market_history",
					"message": "Traditional markets in Indonesia Barat have been centers of trade and culture for centuries. They represent the heart of community life and preserve our culinary traditions.",
					"options": [
						{
							"text": "Tell me more about the food",
							"next_dialogue": "food_recommendations",
							"consequence": "share_knowledge"
						},
						{
							"text": "Continue exploring",
							"next_dialogue": "greeting"
						},
						{
							"text": "Thank you",
							"consequence": "end_conversation"
						}
					]
				},
				{
					"id": "food_recommendations",
					"message": "You must try Soto, our traditional soup! Also Lotek, a healthy vegetable dish, and Sate for grilled meat. Each has its own unique story and preparation method.",
					"options": [
						{
							"text": "Tell me about market history",
							"next_dialogue": "market_history",
							"consequence": "share_knowledge"
						},
						{
							"text": "Continue exploring",
							"next_dialogue": "greeting"
						},
						{
							"text": "Thank you for the recommendations",
							"consequence": "end_conversation"
						}
					]
				}
			]
		"Indonesia Tengah":
			dialogue_data = [
				{
					"id": "greeting",
					"message": "Welcome to Mount Tambora! I am a historian specializing in the 1815 eruption. This was one of the most significant volcanic events in human history.",
					"options": [
						{
							"text": "Tell me about the 1815 eruption",
							"next_dialogue": "eruption_details",
							"consequence": "share_knowledge"
						},
						{
							"text": "What was the global impact?",
							"next_dialogue": "global_impact",
							"consequence": "share_knowledge"
						},
						{
							"text": "Goodbye",
							"consequence": "end_conversation"
						}
					]
				},
				{
					"id": "eruption_details",
					"message": "The 1815 eruption of Mount Tambora was a VEI-7 event, the most powerful volcanic eruption in recorded history. It ejected over 150 cubic kilometers of material.",
					"options": [
						{
							"text": "What was the global impact?",
							"next_dialogue": "global_impact",
							"consequence": "share_knowledge"
						},
						{
							"text": "Thank you",
							"consequence": "end_conversation"
						}
					]
				},
				{
					"id": "global_impact",
					"message": "The eruption caused the 'Year Without a Summer' in 1816, leading to crop failures, famine, and social unrest worldwide. It affected global climate for years.",
					"options": [
						{
							"text": "Thank you for the history lesson",
							"consequence": "end_conversation"
						}
					]
				}
			]
		"Indonesia Timur":
			dialogue_data = [
				{
					"id": "greeting",
					"message": "Welcome to Papua! I can guide you through the rich cultural heritage of this region. We have ancient artifacts and traditional customs that have been preserved for centuries.",
					"options": [
						{
							"text": "Tell me about the ancient artifacts",
							"next_dialogue": "ancient_artifacts",
							"consequence": "share_knowledge"
						},
						{
							"text": "What are the traditional customs?",
							"next_dialogue": "traditional_customs",
							"consequence": "share_knowledge"
						},
						{
							"text": "I need help with something special (Quest)",
							"next_dialogue": "quest_check",
							"consequence": "quest"
						},
						{
							"text": "Goodbye",
							"consequence": "end_conversation"
						}
					]
				},
				{
					"id": "ancient_artifacts",
					"message": "The megalithic sites in Papua contain ancient artifacts that provide insights into early human settlement. These include stone tools, ceremonial objects, and traditional ornaments.",
					"options": [
						{
							"text": "Tell me about traditional customs",
							"next_dialogue": "traditional_customs",
							"consequence": "share_knowledge"
						},
						{
							"text": "About the quest you mentioned",
							"next_dialogue": "quest_check",
							"consequence": "quest"
						},
						{
							"text": "Thank you",
							"consequence": "end_conversation"
						}
					]
				},
				{
					"id": "traditional_customs",
					"message": "Papua's traditional customs include elaborate ceremonies, unique art forms, and distinctive social structures. Each ethnic group has its own unique cultural practices.",
					"options": [
						{
							"text": "Tell me about ancient artifacts",
							"next_dialogue": "ancient_artifacts",
							"consequence": "share_knowledge"
						},
						{
							"text": "About the quest you mentioned",
							"next_dialogue": "quest_check",
							"consequence": "quest"
						},
						{
							"text": "Thank you for sharing",
							"consequence": "end_conversation"
						}
					]
				},
				{
					"id": "quest_check",
					"message": "I am collecting traditional artifacts to preserve our cultural heritage. I specifically need a sacred Noken bag - it's a symbol of Papua's identity and UNESCO-recognized heritage.",
					"options": [
						{
							"text": "I have the Noken you need! (Give Artifact)",
							"next_dialogue": "give_artifact",
							"consequence": "check_artifact"
						},
						{
							"text": "Tell me more about Noken",
							"next_dialogue": "quest_info",
							"consequence": "share_knowledge"
						},
						{
							"text": "I'll help you find it",
							"next_dialogue": "quest_accept",
							"consequence": "quest_accept"
						},
						{
							"text": "Maybe later",
							"next_dialogue": "greeting"
						}
					]
				},
				{
					"id": "quest_info",
					"message": "Noken is a traditional multifunctional bag made from pandan or orchid fibers. It's used for carrying babies, food, and tools. It represents the wisdom and skill of Papua's women artisans.",
					"options": [
						{
							"text": "I have one to give you",
							"next_dialogue": "give_artifact",
							"consequence": "check_artifact"
						},
						{
							"text": "I'll help you find it",
							"next_dialogue": "quest_accept",
							"consequence": "quest_accept"
						},
						{
							"text": "Go back to main topic",
							"next_dialogue": "greeting"
						}
					]
				},
				{
					"id": "quest_accept",
					"message": "Thank you for offering to help! Please explore the area and look for a traditional Noken bag. I'll be here waiting when you find it.",
					"options": [
						{
							"text": "I understand, I'll find it",
							"next_dialogue": "greeting"
						}
					]
				},
				{
					"id": "give_artifact",
					"message": "You have the sacred Noken! This is exactly what I needed for our cultural heritage collection. Thank you so much for preserving our traditions!",
					"options": [
						{
							"text": "You're welcome, happy to help",
							"next_dialogue": "quest_completed",
							"consequence": "complete_quest"
						}
					]
				},
				{
					"id": "quest_completed",
					"message": "Thanks to you, this beautiful Noken will be preserved and displayed for future generations to learn about Papua's cultural heritage. You have my eternal gratitude!",
					"options": [
						{
							"text": "Tell me about other artifacts",
							"next_dialogue": "ancient_artifacts",
							"consequence": "share_knowledge"
						},
						{
							"text": "What about traditional customs?",
							"next_dialogue": "traditional_customs",
							"consequence": "share_knowledge"
						},
						{
							"text": "I'm glad I could help",
							"consequence": "end_conversation"
						}
					]
				}
			]

func setup_historian_dialogue():
	# Historian-specific dialogue with deeper historical content
	match cultural_region:
		"Indonesia Timur":
			dialogue_data = [
				{
					"id": "greeting",
					"message": "Greetings, I am an archaeologist studying the rich history of Papua. This region holds fascinating archaeological discoveries that span thousands of years.",
					"options": [
						{
							"text": "Tell me about Papua's archaeological sites",
							"next_dialogue": "archaeological_sites",
							"consequence": "share_knowledge"
						},
						{
							"text": "What ancient civilizations lived here?",
							"next_dialogue": "ancient_civilizations",
							"consequence": "share_knowledge"
						},
						{
							"text": "I heard you need help with research (Quest)",
							"next_dialogue": "quest_check",
							"consequence": "quest"
						},
						{
							"text": "Goodbye",
							"consequence": "end_conversation"
						}
					]
				},
				{
					"id": "archaeological_sites",
					"message": "Papua contains numerous megalithic sites and cave paintings dating back over 40,000 years. These sites reveal evidence of early human migration and sophisticated cultural practices.",
					"options": [
						{
							"text": "What about ancient civilizations?",
							"next_dialogue": "ancient_civilizations",
							"consequence": "share_knowledge"
						},
						{
							"text": "Tell me more about the cave paintings",
							"next_dialogue": "cave_paintings",
							"consequence": "share_knowledge"
						},
						{
							"text": "About your research project",
							"next_dialogue": "quest_check",
							"consequence": "quest"
						},
						{
							"text": "Thank you for the information",
							"consequence": "end_conversation"
						}
					]
				},
				{
					"id": "ancient_civilizations",
					"message": "The ancestors of Papua's indigenous peoples developed complex societies with unique technologies, including sophisticated agricultural terracing and metallurgy techniques.",
					"options": [
						{
							"text": "Tell me about archaeological sites",
							"next_dialogue": "archaeological_sites",
							"consequence": "share_knowledge"
						},
						{
							"text": "What about cave paintings?",
							"next_dialogue": "cave_paintings",
							"consequence": "share_knowledge"
						},
						{
							"text": "About your research project",
							"next_dialogue": "quest_check",
							"consequence": "quest"
						},
						{
							"text": "Fascinating, thank you",
							"consequence": "end_conversation"
						}
					]
				},
				{
					"id": "cave_paintings",
					"message": "The cave paintings in Papua are among the world's oldest rock art, depicting animals, human figures, and spiritual symbols that provide insights into ancient beliefs and daily life.",
					"options": [
						{
							"text": "Tell me about archaeological sites",
							"next_dialogue": "archaeological_sites",
							"consequence": "share_knowledge"
						},
						{
							"text": "What about ancient civilizations?",
							"next_dialogue": "ancient_civilizations",
							"consequence": "share_knowledge"
						},
						{
							"text": "About your research project",
							"next_dialogue": "quest_check",
							"consequence": "quest"
						},
						{
							"text": "Amazing discoveries, thank you",
							"consequence": "end_conversation"
						}
					]
				},
				{
					"id": "quest_check",
					"message": "For my archaeological research, I desperately need a Kapak Dani - a traditional axe that represents Papua's ancient craftsmanship. It would complete my study on indigenous tool-making techniques.",
					"options": [
						{
							"text": "I have a Kapak Dani for you! (Give Artifact)",
							"next_dialogue": "give_artifact",
							"consequence": "check_artifact"
						},
						{
							"text": "Tell me about Kapak Dani",
							"next_dialogue": "quest_info",
							"consequence": "share_knowledge"
						},
						{
							"text": "I'll help you find one",
							"next_dialogue": "quest_accept",
							"consequence": "quest_accept"
						},
						{
							"text": "Maybe later",
							"next_dialogue": "greeting"
						}
					]
				},
				{
					"id": "quest_info",
					"message": "Kapak Dani is a traditional axe crafted by the Dani tribe. It represents centuries of metallurgy knowledge and is both a tool and a symbol of strength. Each one tells a story of Papua's craftsmanship heritage.",
					"options": [
						{
							"text": "I have one to give you",
							"next_dialogue": "give_artifact",
							"consequence": "check_artifact"
						},
						{
							"text": "I'll help you find one",
							"next_dialogue": "quest_accept",
							"consequence": "quest_accept"
						},
						{
							"text": "Go back to main topic",
							"next_dialogue": "greeting"
						}
					]
				},
				{
					"id": "quest_accept",
					"message": "Excellent! Please explore the area carefully. Traditional tools like the Kapak Dani are often found near ancient settlements or ceremonial sites. I'll be here waiting for your discovery.",
					"options": [
						{
							"text": "I'll find it for your research",
							"next_dialogue": "greeting"
						}
					]
				},
				{
					"id": "give_artifact",
					"message": "Incredible! This Kapak Dani is exactly what I needed for my research! The craftsmanship is extraordinary - you can see the ancient metallurgy techniques in every detail. Thank you so much!",
					"options": [
						{
							"text": "Happy to help your research",
							"next_dialogue": "quest_completed",
							"consequence": "complete_quest"
						}
					]
				},
				{
					"id": "quest_completed",
					"message": "This Kapak Dani will be invaluable for my archaeological documentation. Future researchers will learn so much about Papua's ancient craftsmanship techniques thanks to your contribution!",
					"options": [
						{
							"text": "Tell me about archaeological sites",
							"next_dialogue": "archaeological_sites",
							"consequence": "share_knowledge"
						},
						{
							"text": "What about ancient civilizations?",
							"next_dialogue": "ancient_civilizations",
							"consequence": "share_knowledge"
						},
						{
							"text": "Glad I could contribute to research",
							"consequence": "end_conversation"
						}
					]
				}
			]
		_:
			# Fallback for other regions
			setup_guide_dialogue()

func setup_vendor_dialogue():
	# Vendor-specific dialogue focused on traditional crafts and trade
	match cultural_region:
		"Indonesia Timur":
			dialogue_data = [
				{
					"id": "greeting",
					"message": "Welcome to my workshop! I am a traditional artisan specializing in Papua's ancient crafts. Each piece I create carries the wisdom of our ancestors.",
					"options": [
						{
							"text": "What traditional crafts do you make?",
							"next_dialogue": "traditional_crafts",
							"consequence": "share_knowledge"
						},
						{
							"text": "Tell me about the materials you use",
							"next_dialogue": "materials",
							"consequence": "share_knowledge"
						},
						{
							"text": "I heard you need inspiration (Quest)",
							"next_dialogue": "quest_check",
							"consequence": "quest"
						},
						{
							"text": "Goodbye",
							"consequence": "end_conversation"
						}
					]
				},
				{
					"id": "traditional_crafts",
					"message": "I specialize in creating Noken bags, traditional masks, koteka, and ceremonial weapons like the Kapak Dani. Each piece has cultural significance and tells a story.",
					"options": [
						{
							"text": "What materials do you use?",
							"next_dialogue": "materials",
							"consequence": "share_knowledge"
						},
						{
							"text": "How are these techniques passed down?",
							"next_dialogue": "techniques",
							"consequence": "share_knowledge"
						},
						{
							"text": "Tell me about Noken bags",
							"next_dialogue": "noken_details",
							"consequence": "share_knowledge"
						},
						{
							"text": "Thank you for sharing",
							"consequence": "end_conversation"
						}
					]
				},
				{
					"id": "materials",
					"message": "We use natural materials from the forest: pandan leaves for Noken, bird feathers for decoration, wood from sacred trees, and stones for tools. Everything is sustainably harvested.",
					"options": [
						{
							"text": "What crafts do you make with these?",
							"next_dialogue": "traditional_crafts",
							"consequence": "share_knowledge"
						},
						{
							"text": "How do you learn these techniques?",
							"next_dialogue": "techniques",
							"consequence": "share_knowledge"
						},
						{
							"text": "Tell me about Noken bags",
							"next_dialogue": "noken_details",
							"consequence": "share_knowledge"
						},
						{
							"text": "Interesting, thank you",
							"consequence": "end_conversation"
						}
					]
				},
				{
					"id": "techniques",
					"message": "These techniques are passed down through generations in our families. Young artisans learn by watching and practicing under the guidance of master craftsmen, preserving our cultural heritage.",
					"options": [
						{
							"text": "What traditional crafts do you make?",
							"next_dialogue": "traditional_crafts",
							"consequence": "share_knowledge"
						},
						{
							"text": "What materials do you use?",
							"next_dialogue": "materials",
							"consequence": "share_knowledge"
						},
						{
							"text": "Tell me about Noken bags",
							"next_dialogue": "noken_details",
							"consequence": "share_knowledge"
						},
						{
							"text": "Thank you for preserving these traditions",
							"consequence": "end_conversation"
						}
					]
				},
				{
					"id": "noken_details",
					"message": "Noken is a traditional multifunctional bag made from pandan or orchid fibers. It's not just a bag - it's a symbol of Papua's identity, used for carrying babies, food, and tools.",
					"options": [
						{
							"text": "What other crafts do you make?",
							"next_dialogue": "traditional_crafts",
							"consequence": "share_knowledge"
						},
						{
							"text": "What materials do you use?",
							"next_dialogue": "materials",
							"consequence": "share_knowledge"
						},
						{
							"text": "How do you learn these techniques?",
							"next_dialogue": "techniques",
							"consequence": "share_knowledge"
						},
						{
							"text": "Amazing cultural heritage, thank you",
							"consequence": "end_conversation"
						}
					]
				},
				{
					"id": "quest_check",
					"message": "As an artisan, I need inspiration for my next masterpiece. I'm looking for a Cenderawasih Pegunungan sculpture - it represents Papua's natural beauty and would inspire my future works.",
					"options": [
						{
							"text": "I have the sculpture you need! (Give Artifact)",
							"next_dialogue": "give_artifact",
							"consequence": "check_artifact"
						},
						{
							"text": "Tell me about Cenderawasih Pegunungan",
							"next_dialogue": "quest_info",
							"consequence": "share_knowledge"
						},
						{
							"text": "I'll help you find it",
							"next_dialogue": "quest_accept",
							"consequence": "quest_accept"
						},
						{
							"text": "Maybe later",
							"next_dialogue": "greeting"
						}
					]
				},
				{
					"id": "quest_info",
					"message": "Cenderawasih Pegunungan is the Bird of Paradise, a symbol of Papua's incredible biodiversity. The sculpture captures the essence of our natural heritage and inspires artistic creation.",
					"options": [
						{
							"text": "I have one for you",
							"next_dialogue": "give_artifact",
							"consequence": "check_artifact"
						},
						{
							"text": "I'll help you find it",
							"next_dialogue": "quest_accept",
							"consequence": "quest_accept"
						},
						{
							"text": "Go back to main topic",
							"next_dialogue": "greeting"
						}
					]
				},
				{
					"id": "quest_accept",
					"message": "Wonderful! Look for the Cenderawasih Pegunungan sculpture around the area. It represents the spirit of Papua's nature and will be perfect for inspiring my artistic vision.",
					"options": [
						{
							"text": "I'll find it for your art",
							"next_dialogue": "greeting"
						}
					]
				},
				{
					"id": "give_artifact",
					"message": "Magnificent! This Cenderawasih Pegunungan sculpture is absolutely perfect! The artistry is breathtaking - I can already envision the masterpieces this will inspire. Thank you so much!",
					"options": [
						{
							"text": "Happy to inspire your art",
							"next_dialogue": "quest_completed",
							"consequence": "complete_quest"
						}
					]
				},
				{
					"id": "quest_completed",
					"message": "With this beautiful sculpture as inspiration, I will create works that honor both Papua's natural beauty and our artistic traditions. Your contribution will inspire generations of art!",
					"options": [
						{
							"text": "Tell me about your crafts",
							"next_dialogue": "traditional_crafts",
							"consequence": "share_knowledge"
						},
						{
							"text": "What materials do you use?",
							"next_dialogue": "materials",
							"consequence": "share_knowledge"
						},
						{
							"text": "Glad I could inspire your art",
							"consequence": "end_conversation"
						}
					]
				}
			]
		_:
			# Fallback for other regions
			setup_guide_dialogue()

func setup_generic_dialogue():
	dialogue_data = [
		{
			"id": "greeting",
			"message": "Hello! Welcome to " + cultural_region + ". How can I help you today?",
			"options": [
				{
					"text": "Tell me about this region",
					"consequence": "share_knowledge"
				},
				{
					"text": "Goodbye",
					"consequence": "end_conversation"
				}
			]
		}
	]

func get_dialogue_by_id(dialogue_id: String) -> Dictionary:
	GameLogger.debug("Looking for dialogue with id: " + dialogue_id + " (total dialogues: " + str(dialogue_data.size()) + ")")
	for dialogue in dialogue_data:
		if dialogue.get("id") == dialogue_id:
			GameLogger.debug("Found dialogue: " + dialogue_id)
			return dialogue
	GameLogger.warning("Dialogue not found: " + dialogue_id)
	return {}

func get_initial_dialogue() -> Dictionary:
	if dialogue_data.size() > 0:
		var initial = dialogue_data[0]
		# Update quest dialogue based on completion status
		update_quest_dialogue_options()
		return initial
	return {}

func update_quest_dialogue_options():
	"""Update dialogue options based on quest completion status"""
	if cultural_region != "Indonesia Timur" or quest_artifact_required == "":
		return
	
	# Find quest_check dialogue and update it based on quest status
	for dialogue in dialogue_data:
		if dialogue.get("id") == "quest_check":
			if quest_completed:
				# Quest completed - change to show completed status
				dialogue["message"] = "Thanks to your help, I now have the " + quest_artifact_required + " I needed! It's perfectly preserved in our cultural heritage collection."
				dialogue["options"] = [
					{
						"text": "Tell me about the " + quest_artifact_required,
						"next_dialogue": "quest_completed",
						"consequence": "share_knowledge"
					},
					{
						"text": "I'm glad I could help",
						"next_dialogue": "greeting"
					}
				]
			# If quest not completed, keep original options
			break

# Legacy methods for backward compatibility
func start_interaction():
	# This is now handled by the state machine
	if state_machine:
		state_machine.change_state(state_machine.get_interacting_state())

func start_dialogue():
	# This is now handled by the dialogue system
	pass

func show_dialogue_ui(_dialogue: Dictionary):
	# This is now handled by the dialogue system
	pass

func show_default_dialogue():
	# This is now handled by the dialogue system
	pass

func setup_cultural_topics():
	match cultural_region:
		"Indonesia Barat":
			cultural_topics = [
				"Traditional Market Culture",
				"Street Food History", 
				"Sunda and Javanese Traditions"
			]
		"Indonesia Tengah":
			cultural_topics = [
				"Mount Tambora Eruption",
				"Historical Impact",
				"Geological Significance"
			]
		"Indonesia Timur":
			cultural_topics = [
				"Papua Cultural Heritage",
				"Ancient Artifacts",
				"Traditional Customs"
			]

func setup_quest_artifact():
	# Setup quest artifacts based on NPC type and name in Papua region
	if cultural_region == "Indonesia Timur":
		match npc_name:
			"Cultural Guide":
				quest_artifact_required = "noken"
				quest_title = "Sacred Noken Collection"
				quest_description = "I need the traditional Noken bag to complete my cultural heritage display. Can you help me find it?"
			"Archaeologist":
				quest_artifact_required = "kapak_dani"
				quest_title = "Ancient Tool Research"
				quest_description = "For my archaeological research, I need the Kapak Dani - a traditional axe that represents Papua's craftsmanship heritage."
			"Tribal Elder":
				quest_artifact_required = "koteka"
				quest_title = "Traditional Attire Preservation"
				quest_description = "The Koteka is an important piece of our cultural identity. I need it to teach younger generations about our traditions."
			"Artisan":
				quest_artifact_required = "cenderawasih_pegunungan"
				quest_title = "Bird of Paradise Art"
				quest_description = "As an artisan, I need the Cenderawasih Pegunungan sculpture to inspire my future works and show visitors Papua's natural beauty."
	
	GameLogger.info("Quest assigned to " + npc_name + ": " + quest_artifact_required)

func add_quest_dialogues():
	"""Add quest dialogues to NPCs that don't have them yet (like Tribal Elder)"""
	# Check if quest dialogues already exist
	var has_quest_dialogue = false
	for dialogue in dialogue_data:
		if dialogue.get("id") == "quest_check":
			has_quest_dialogue = true
			break
	
	if has_quest_dialogue:
		return  # Quest dialogues already exist
	
	# Add quest option to greeting if it doesn't exist
	var greeting_dialogue = null
	for dialogue in dialogue_data:
		if dialogue.get("id") == "greeting":
			greeting_dialogue = dialogue
			break
	
	if greeting_dialogue:
		# Add quest option to greeting
		var quest_option = {
			"text": "I heard you need something special (Quest)",
			"next_dialogue": "quest_check",
			"consequence": "quest"
		}
		greeting_dialogue.get("options", []).insert(-1, quest_option)  # Insert before "Goodbye"
		
		# Add quest dialogues based on artifact type
		var quest_dialogues = get_quest_dialogues_for_artifact(quest_artifact_required)
		dialogue_data.append_array(quest_dialogues)
		
		GameLogger.info("Added quest dialogues for " + npc_name + " (" + quest_artifact_required + ")")

func get_quest_dialogues_for_artifact(artifact_name: String) -> Array:
	"""Generate quest dialogues based on artifact type"""
	match artifact_name:
		"koteka":
			return [
				{
					"id": "quest_check",
					"message": "I am preserving our traditional attire for future generations. I need a Koteka - it's an important symbol of Papua's cultural identity and traditional clothing.",
					"options": [
						{
							"text": "I have a Koteka for you! (Give Artifact)",
							"next_dialogue": "give_artifact",
							"consequence": "check_artifact"
						},
						{
							"text": "Tell me about Koteka",
							"next_dialogue": "quest_info",
							"consequence": "share_knowledge"
						},
						{
							"text": "I'll help you find it",
							"next_dialogue": "quest_accept",
							"consequence": "quest_accept"
						},
						{
							"text": "Maybe later",
							"next_dialogue": "greeting"
						}
					]
				},
				{
					"id": "quest_info",
					"message": "Koteka is traditional clothing of Papua highlands, representing our cultural identity. It's important for teaching younger generations about our heritage and traditions.",
					"options": [
						{
							"text": "I have one for you",
							"next_dialogue": "give_artifact",
							"consequence": "check_artifact"
						},
						{
							"text": "I'll help you find it",
							"next_dialogue": "quest_accept",
							"consequence": "quest_accept"
						},
						{
							"text": "Go back to main topic",
							"next_dialogue": "greeting"
						}
					]
				},
				{
					"id": "quest_accept",
					"message": "Thank you for helping preserve our traditions! Please look for a Koteka in the area. It's essential for our cultural education programs.",
					"options": [
						{
							"text": "I'll find it for cultural preservation",
							"next_dialogue": "greeting"
						}
					]
				},
				{
					"id": "give_artifact",
					"message": "Excellent! This Koteka is exactly what we needed for our cultural preservation program. Now I can properly teach the younger generation about our traditional attire. Thank you!",
					"options": [
						{
							"text": "Happy to preserve traditions",
							"next_dialogue": "quest_completed",
							"consequence": "complete_quest"
						}
					]
				},
				{
					"id": "quest_completed",
					"message": "Thanks to your help, this Koteka will be preserved and used to educate future generations about Papua's traditional clothing and cultural identity. You've made a lasting contribution!",
					"options": [
						{
							"text": "Tell me more about traditions",
							"next_dialogue": "traditional_customs",
							"consequence": "share_knowledge"
						},
						{
							"text": "Glad I could help preserve culture",
							"consequence": "end_conversation"
						}
					]
				}
			]
		_:
			return []  # Default empty if no specific quest dialogue

func has_required_artifact() -> bool:
	# Check if player has the required artifact in inventory
	var inventory = get_node("/root/Player/CulturalInventory")
	if not inventory:
		inventory = get_tree().get_first_node_in_group("inventory")
	
	if inventory and inventory.has_method("has_item"):
		return inventory.has_item(quest_artifact_required)
	
	GameLogger.warning("Could not find inventory to check for artifact: " + quest_artifact_required)
	return false

func give_artifact_to_npc() -> bool:
	# Remove artifact from player inventory and mark quest complete
	var inventory = get_node("/root/Player/CulturalInventory")
	if not inventory:
		inventory = get_tree().get_first_node_in_group("inventory")
	
	if inventory and inventory.has_method("remove_item"):
		if inventory.remove_item(quest_artifact_required):
			quest_completed = true
			GameLogger.info("Quest completed! " + npc_name + " received " + quest_artifact_required)
			return true
	
	GameLogger.warning("Failed to remove artifact from inventory: " + quest_artifact_required)
	return false

func share_cultural_knowledge():
	if cultural_topics.size() > 0:
		var topic = cultural_topics[randi() % cultural_topics.size()]
		var knowledge = get_knowledge_for_topic(topic)
		
		GlobalSignals.on_learn_cultural_info.emit(knowledge, cultural_region)
		
		# Also emit to EventBus (autoload singleton)
		if EventBus:
			EventBus.emit_cultural_info_learned(knowledge, cultural_region)
		
		GameLogger.info(npc_name + " shares knowledge about: " + topic)

func mark_dialogue_ended():
	dialogue_just_ended = true
	dialogue_end_time = Time.get_unix_time_from_system()
	# Only disable interaction for THIS specific NPC during cooldown
	can_interact = false
	GameLogger.debug("Dialogue ended for " + npc_name + " - cooldown started, interaction disabled for this NPC only")
	
	# Start a timer to re-enable interaction after cooldown for THIS NPC
	var cooldown_timer = get_tree().create_timer(dialogue_cooldown_duration)
	cooldown_timer.timeout.connect(_on_dialogue_cooldown_expired)

func _on_dialogue_cooldown_expired():
	# Only re-enable interaction for THIS specific NPC
	dialogue_just_ended = false
	can_interact = true
	GameLogger.debug("Dialogue cooldown expired for " + npc_name + " - interaction re-enabled for this NPC")

func get_knowledge_for_topic(topic: String) -> String:
	# This would be loaded from a knowledge database
	var knowledge_data = {
		"Traditional Market Culture": "Traditional markets in Indonesia Barat are vibrant centers of commerce and culture, where local vendors sell everything from fresh produce to traditional crafts.",
		"Street Food History": "Indonesian street food has a rich history dating back centuries, with each region having its own unique culinary traditions.",
		"Sunda and Javanese Traditions": "The Sunda and Javanese people have distinct cultural traditions that have been preserved and passed down through generations.",
		"Mount Tambora Eruption": "The 1815 eruption of Mount Tambora was one of the most powerful volcanic events in recorded history, affecting global climate for years.",
		"Historical Impact": "The Tambora eruption had profound effects on agriculture, leading to the 'Year Without a Summer' in 1816.",
		"Geological Significance": "Mount Tambora's eruption created the largest caldera in Indonesia and changed the landscape dramatically.",
		"Papua Cultural Heritage": "Papua is home to diverse ethnic groups, each with unique cultural practices and traditions.",
		"Ancient Artifacts": "The megalithic sites in Papua contain ancient artifacts that provide insights into early human settlement.",
		"Traditional Customs": "Papua's traditional customs include elaborate ceremonies, unique art forms, and distinctive social structures."
	}
	
	return knowledge_data.get(topic, "Knowledge about " + topic + " is being researched.")

func end_interaction():
	# This is now handled by the state machine
	if state_machine:
		state_machine.change_state(state_machine.get_idle_state())

func _on_npc_interaction(_npc_name_interacted: String, _region: String):
	# This function can be used for additional interaction logic
	if _npc_name_interacted == npc_name:
		GameLogger.info("NPC interaction started with: " + npc_name)

func _on_event_bus_npc_interaction(_event: EventBus.Event):
	# Handle EventBus NPC interaction events
	if _event.data.get("npc_name") == npc_name:
		GameLogger.debug("EventBus NPC interaction with: " + npc_name)

func _on_back_button_pressed():
	# Check if we're still valid before processing
	if not is_inside_tree() or not is_instance_valid(self):
		GameLogger.warning("CulturalNPC: Node not in tree or invalid during back button press, ignoring")
		return
	
	GameLogger.info("Back button pressed - History size: " + str(dialogue_history.size()))
	# Debug: Print all dialogue history
	for i in range(dialogue_history.size()):
		var dialogue = dialogue_history[i]
		GameLogger.debug("History[" + str(i) + "]: " + dialogue.get("id", "unknown"))
	
	# Go back to previous dialogue or close if at beginning
	if dialogue_history.size() > 1:
		dialogue_history.pop_back()  # Remove current
		var previous_dialogue = dialogue_history.back()
		GameLogger.info("Going back to: " + previous_dialogue.get("id", "unknown"))
		display_dialogue_ui(previous_dialogue)
	else:
		GameLogger.info("No more history, closing dialogue")
		end_visual_dialogue()

func _on_close_button_pressed():
	# Check if we're still valid before processing
	if not is_inside_tree() or not is_instance_valid(self):
		GameLogger.warning("CulturalNPC: Node not in tree or invalid during close button press, ignoring")
		return
	
	end_visual_dialogue()

func _draw_chat_icon(control: Control):
	# Draw vintage chat bubble icon using 2D primitives
	var _rect = Rect2(Vector2.ZERO, control.get_size())
	
	# Draw chat bubble body
	control.draw_rect(Rect2(5, 5, 30, 25), Color(0.8, 0.75, 0.6, 1.0), false, 2.0)
	control.draw_rect(Rect2(7, 7, 26, 21), Color(0.1, 0.15, 0.25, 1.0))
	
	# Draw chat bubble tail using Bezier curve
	var points = PackedVector2Array()
	points.append(Vector2(15, 30))
	points.append(Vector2(10, 35))
	points.append(Vector2(8, 32))
	
	# Draw the tail
	for i in range(points.size() - 1):
		control.draw_line(points[i], points[i + 1], Color(0.8, 0.75, 0.6, 1.0), 2.0)

func _draw_next_icon(control: Control):
	# Draw vintage next arrow using 2D primitives
	var center = control.get_size() / 2
	
	# Draw arrow triangle
	var points = PackedVector2Array()
	points.append(Vector2(center.x - 8, center.y - 6))
	points.append(Vector2(center.x + 8, center.y))
	points.append(Vector2(center.x - 8, center.y + 6))
	
	# Fill triangle
	control.draw_colored_polygon(points, Color(0.8, 0.75, 0.6, 1.0))
	
	# Draw border
	control.draw_polyline(points, Color(0.6, 0.55, 0.4, 1.0), 1.0, true)

func _style_vintage_button(button: Button):
	# Create vintage button style
	var normal_style = StyleBoxFlat.new()
	normal_style.bg_color = Color(0.15, 0.2, 0.3, 0.9)
	normal_style.border_color = Color(0.8, 0.75, 0.6, 1.0)
	normal_style.border_width_left = 2
	normal_style.border_width_top = 2
	normal_style.border_width_right = 2
	normal_style.border_width_bottom = 2
	normal_style.corner_radius_top_left = 8
	normal_style.corner_radius_top_right = 8
	normal_style.corner_radius_bottom_left = 8
	normal_style.corner_radius_bottom_right = 8
	button.add_theme_stylebox_override("normal", normal_style)
	
	# Hover style
	var hover_style = StyleBoxFlat.new()
	hover_style.bg_color = Color(0.2, 0.25, 0.35, 0.95)
	hover_style.border_color = Color(1, 0.9, 0.7, 1.0)
	hover_style.border_width_left = 2
	hover_style.border_width_top = 2
	hover_style.border_width_right = 2
	hover_style.border_width_bottom = 2
	hover_style.corner_radius_top_left = 8
	hover_style.corner_radius_top_right = 8
	hover_style.corner_radius_bottom_left = 8
	hover_style.corner_radius_bottom_right = 8
	button.add_theme_stylebox_override("hover", hover_style)
	
	# Pressed style
	var pressed_style = StyleBoxFlat.new()
	pressed_style.bg_color = Color(0.1, 0.15, 0.25, 1.0)
	pressed_style.border_color = Color(0.6, 0.55, 0.4, 1.0)
	pressed_style.border_width_left = 2
	pressed_style.border_width_top = 2
	pressed_style.border_width_right = 2
	pressed_style.border_width_bottom = 2
	pressed_style.corner_radius_top_left = 8
	pressed_style.corner_radius_top_right = 8
	pressed_style.corner_radius_bottom_left = 8
	pressed_style.corner_radius_bottom_right = 8
	button.add_theme_stylebox_override("pressed", pressed_style)
	
	# Text styling
	button.add_theme_font_size_override("font_size", 16)
	button.add_theme_color_override("font_color", Color(0.9, 0.85, 0.7, 1.0))

func _notification(what: int):
	if what == NOTIFICATION_READY:
		GameLogger.debug("CulturalNPC: _notification(READY) called for " + npc_name)
	elif what == NOTIFICATION_PREDELETE:
		GameLogger.debug("CulturalNPC: _notification(PREDELETE) called for " + npc_name)
		# Force cleanup of all timers before deletion
		for child in get_children():
			if child is Timer and is_instance_valid(child):
				child.stop()
				child.queue_free()
				GameLogger.debug("CulturalNPC: Timer cleaned up in PREDELETE: " + child.name)

func _exit_tree():
	GameLogger.debug("CulturalNPC: _exit_tree() called for " + npc_name)
	

	
	# Enhanced debug logging for cleanup process
	if has_node("/root/DebugConfig") and get_node("/root/DebugConfig").enable_timer_debug:
		GameLogger.debug("CulturalNPC: Starting cleanup for " + npc_name + " - is_inside_tree: " + str(is_inside_tree()) + ", is_instance_valid: " + str(is_instance_valid(self)))
	
	# CRITICAL: Clean up ALL timers immediately to prevent !is_inside_tree() errors
	var input_timer = get_node_or_null("DialogueInputTimer")
	if input_timer and is_instance_valid(input_timer):
		input_timer.stop()
		input_timer.queue_free()
		GameLogger.debug("CulturalNPC: Input timer cleaned up in _exit_tree")
	else:
		GameLogger.debug("CulturalNPC: No input timer found to clean up in _exit_tree")
	
	var typewriter_timer = get_node_or_null("TypewriterTimer")
	if typewriter_timer and is_instance_valid(typewriter_timer):
		typewriter_timer.stop()
		typewriter_timer.queue_free()
		GameLogger.debug("CulturalNPC: Typewriter timer cleaned up in _exit_tree")
	else:
		GameLogger.debug("CulturalNPC: No typewriter timer found to clean up in _exit_tree")
	
	# Clean up ANY other timers that might exist
	for child in get_children():
		if child is Timer and is_instance_valid(child):
			child.stop()
			child.queue_free()
			GameLogger.debug("CulturalNPC: Additional timer cleaned up: " + child.name)
	
	# Also clean up any timers stored in metadata
	var dialogue_ui = get_node_or_null("DialogueUI")
	if dialogue_ui:
		var message_text = dialogue_ui.get_node_or_null("DialoguePanel/MessageContainer/MessageText")
		if message_text and message_text.has_meta("typewriter_timer"):
			var meta_timer = message_text.get_meta("typewriter_timer")
			if meta_timer and is_instance_valid(meta_timer):
				meta_timer.stop()
				meta_timer.queue_free()
				GameLogger.debug("CulturalNPC: Meta timer cleaned up in _exit_tree")
	
	# Disconnect signals to prevent callbacks after node removal
	if GlobalSignals.on_npc_interaction.is_connected(_on_npc_interaction):
		GlobalSignals.on_npc_interaction.disconnect(_on_npc_interaction)
	
	# EventBus cleanup - use proper unsubscribe method
	if EventBus:
		EventBus.unsubscribe(self)
	
	GameLogger.debug("CulturalNPC: Cleanup complete for " + npc_name)

func has_active_dialogue() -> bool:
	"""Check if this NPC currently has an active dialogue"""
	var dialogue_ui = get_node_or_null("DialogueUI")
	var is_active = dialogue_ui and dialogue_ui.visible
	
	# DEBUG: Log active dialogue state
	if is_active:
		GameLogger.debug("CulturalNPC (" + npc_name + "): Has active dialogue - UI visible: " + str(dialogue_ui.visible))
	
	return is_active

func is_dialogue_input_active() -> bool:
	"""Check if dialogue input handling is currently active"""
	var input_timer = get_node_or_null("DialogueInputTimer")
	return input_timer and not input_timer.is_stopped()

func _verify_dialogue_ui_state():
	"""Debug function to verify dialogue UI state"""
	var dialogue_ui = get_node_or_null("DialogueUI")
	if dialogue_ui:
		GameLogger.info("CulturalNPC (" + npc_name + "): DialogueUI state verification:")
		GameLogger.info("  - UI exists: true")
		GameLogger.info("  - UI visible: " + str(dialogue_ui.visible))
		GameLogger.info("  - Dialogue history size: " + str(dialogue_history.size()))
		GameLogger.info("  - has_active_dialogue(): " + str(has_active_dialogue()))
		
		# Check current dialogue
		if dialogue_history.size() > 0:
			var current_dialogue = dialogue_history.back()
			var options = current_dialogue.get("options", [])
			GameLogger.info("  - Current dialogue options: " + str(options.size()))
			for i in range(options.size()):
				GameLogger.info("    Option " + str(i + 1) + ": " + options[i].get("text", ""))
		else:
			GameLogger.warning("  - No dialogue in history!")
	else:
		GameLogger.error("CulturalNPC (" + npc_name + "): DialogueUI not found!")
