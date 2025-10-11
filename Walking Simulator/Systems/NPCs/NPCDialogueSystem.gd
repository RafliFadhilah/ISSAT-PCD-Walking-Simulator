class_name NPCDialogueSystem
extends RefCounted

# Dialogue system for NPCs
# Implements Single Responsibility Principle - handles only dialogue functionality

var npc: CulturalNPC
var current_dialogue_index: int = 0
var dialogue_data: Array[Dictionary] = []
var is_dialogue_active: bool = false
var current_message: String = ""
var current_options: Array = []  # Changed from Array[Dictionary] to Array to avoid type mismatch
var message_display_timer: float = 0.0
var message_display_duration: float = 3.0

func _init(npc_reference: CulturalNPC):
	npc = npc_reference
	dialogue_data = npc.dialogue_data

func start_dialogue():
	is_dialogue_active = true
	current_dialogue_index = 0
	message_display_timer = 0.0
	
	# Emit dialogue start signal
	EventBus.emit_event(EventBus.EventType.NPC_INTERACTION, {
		"npc_name": npc.npc_name,
		"dialogue_id": "start",
		"action": "dialogue_start"
	}, 2, "dialogue_system")
	
	show_current_dialogue()

func update(delta: float):
	if not is_dialogue_active:
		return
	
	message_display_timer += delta
	
	# Auto-advance dialogue after a certain time
	if message_display_timer >= message_display_duration:
		advance_dialogue()

func show_current_dialogue():
	if current_dialogue_index >= dialogue_data.size():
		# No more dialogue, show default
		show_default_dialogue()
		return
	
	var dialogue = dialogue_data[current_dialogue_index]
	current_message = dialogue.get("message", "")
	current_options = dialogue.get("options", [])
	
	# Filter options based on quest status
	current_options = filter_options_by_quest_status(current_options)
	
	# Emit dialogue update signal
	EventBus.emit_event(EventBus.EventType.UI_UPDATE, {
		"update_type": "dialogue_update",
		"npc_name": npc.npc_name,
		"message": current_message,
		"options": current_options
	}, 3, "dialogue_system")
	
	GameLogger.info(npc.npc_name + ": " + current_message)
	
	# Show options if available
	if current_options.size() > 0:
		for i in range(current_options.size()):
			GameLogger.info(str(i + 1) + ". " + current_options[i].get("text", ""))

func show_default_dialogue():
	var message = get_default_message()
	current_message = message
	current_options = []
	
	# Emit default dialogue signal
	EventBus.emit_event(EventBus.EventType.UI_UPDATE, {
		"update_type": "dialogue_default",
		"npc_name": npc.npc_name,
		"message": message
	}, 3, "dialogue_system")
	
	GameLogger.info(npc.npc_name + ": " + message)

func get_default_message() -> String:
	match npc.npc_type:
		"Guide":
			return "Welcome to " + npc.cultural_region + "! I can guide you through the cultural highlights."
		"Vendor":
			return "Welcome! I sell traditional items from " + npc.cultural_region + "."
		"Historian":
			return "Greetings! I can tell you about the history of " + npc.cultural_region + "."
		_:
			return "Hello! Welcome to " + npc.cultural_region + "."

func advance_dialogue():
	current_dialogue_index += 1
	message_display_timer = 0.0
	
	if current_dialogue_index >= dialogue_data.size():
		# End dialogue
		end_dialogue()
	else:
		show_current_dialogue()

func continue_dialogue():
	advance_dialogue()

func select_choice(choice_index: int):
	if choice_index >= 0 and choice_index < current_options.size():
		var selected_option = current_options[choice_index]
		var next_dialogue_id = selected_option.get("next_dialogue", "")
		
		# Handle choice consequences
		handle_choice_consequence(selected_option)
		
		# Move to next dialogue or end
		if next_dialogue_id != "":
			# Find dialogue with matching ID
			for i in range(dialogue_data.size()):
				if dialogue_data[i].get("id", "") == next_dialogue_id:
					current_dialogue_index = i
					show_current_dialogue()
					return
		
		# If no next dialogue specified, advance normally
		advance_dialogue()

func handle_choice_consequence(option: Dictionary):
	var consequence = option.get("consequence", "")
	
	match consequence:
		"share_knowledge":
			npc.share_cultural_knowledge()
		"give_item":
			# Handle giving item to player
			var item_name = option.get("item_name", "")
			if item_name != "":
				give_item_to_player(item_name)
		"give_artifact_to_npc":
			# Handle player giving artifact to NPC
			handle_give_artifact_to_npc(option)
		"end_conversation", "end_dialogue":
			end_dialogue()

func handle_give_artifact_to_npc(_option: Dictionary):
	var required_artifact = npc.quest_artifact_required
	
	GameLogger.info("=== ARTIFACT GIVING PROCESS ===")
	GameLogger.info("NPC: " + npc.npc_name + ", Required artifact: " + required_artifact)
	GameLogger.info("Quest completed status: " + str(npc.quest_completed))
	
	if required_artifact == "":
		GameLogger.warning("NPC " + npc.npc_name + " has no quest artifact requirement")
		return
	
	# Check if player has the required artifact
	var inventory = get_inventory()
	if not inventory:
		GameLogger.error("Could not find player inventory")
		current_message = "There seems to be a problem with the inventory system. Please try again."
		current_options = []
		return
	
	GameLogger.info("Inventory found: " + str(inventory))
	GameLogger.info("Checking if player has artifact: " + required_artifact)
	
	if inventory.has_item(required_artifact):
		GameLogger.info("Player HAS the required artifact: " + required_artifact)
		# Player has the artifact - proceed with quest completion
		if inventory.remove_item(required_artifact):
			npc.quest_completed = true
			GameLogger.info("SUCCESS: Artifact removed from inventory and quest completed!")
			
			# Show quest completion message
			current_message = "Thank you so much! This " + required_artifact + " will be very valuable for " + npc.quest_description
			current_options = [
				{
					"text": "You're Welcome!",
					"consequence": "end_conversation"
				}
			]
			
			# Emit quest completion event
			EventBus.emit_event(EventBus.EventType.NPC_INTERACTION, {
				"npc_name": npc.npc_name,
				"quest_title": npc.quest_title,
				"artifact_given": required_artifact,
				"action": "quest_completed"
			}, 2, "dialogue_system")
			
			GameLogger.info("Quest completed: " + npc.quest_title + " for NPC " + npc.npc_name)
		else:
			GameLogger.error("FAILED to remove artifact from inventory: " + required_artifact)
			current_message = "There was a problem removing the item from your inventory. Please try again."
			current_options = []
	else:
		GameLogger.info("Player does NOT have the required artifact: " + required_artifact)
		# Player doesn't have the artifact - show quest reminder
		current_message = "I still need a " + required_artifact + " for my quest: " + npc.quest_description + ". Please bring it to me when you find one!"
		current_options = [
			{
				"text": "Ok!",
				"consequence": "end_conversation"
			}
		]
		
		GameLogger.info("Player attempted to give artifact but doesn't have: " + required_artifact)

func get_inventory():
	# Since this is a RefCounted class, we need to access through the NPC
	# Try global reference first
	var inventory = Global.cultural_inventory
	if inventory:
		return inventory
	
	if npc and npc.has_method("get_tree"):
		var tree = npc.get_tree()
		if tree:
			# Try to find the inventory
			inventory = tree.get_first_node_in_group("inventory")
			if not inventory:
				# Try alternative path
				inventory = tree.get_root().get_node_or_null("Player/CulturalInventory")
			
			if inventory:
				return inventory
	
	return null

func filter_options_by_quest_status(options: Array) -> Array:
	GameLogger.info("=== FILTERING OPTIONS ===")
	GameLogger.info("NPC: " + npc.npc_name + ", Quest completed: " + str(npc.quest_completed))
	GameLogger.info("Original options count: " + str(options.size()))
	
	if npc.quest_completed:
		# Remove quest-related options if quest is completed
		var filtered_options = []
		for option in options:
			var consequence = option.get("consequence", "")
			if consequence != "give_artifact_to_npc":
				filtered_options.append(option)
			else:
				GameLogger.info("REMOVED quest option: " + option.get("text", ""))
		
		GameLogger.info("Filtered options count: " + str(filtered_options.size()))
		return filtered_options
	
	GameLogger.info("Quest not completed, returning all options")
	return options

func give_item_to_player(item_name: String):
	# Create item using factory
	var item_config = {
		"type": "artifact",
		"display_name": item_name,
		"description": "A gift from " + npc.npc_name,
		"region": npc.cultural_region
	}
	
	var item = CulturalItemFactory.create_item_from_config(item_config)
	if item:
		# Emit item given signal
		EventBus.emit_event(EventBus.EventType.ARTIFACT_COLLECTED, {
			"artifact_name": item_name,
			"region": npc.cultural_region,
			"source": "npc_gift",
			"npc_name": npc.npc_name
		}, 2, "dialogue_system")

func end_dialogue():
	is_dialogue_active = false
	
	# Mark dialogue as ended in the NPC
	npc.mark_dialogue_ended()
	
	# Emit dialogue end signal
	EventBus.emit_event(EventBus.EventType.NPC_INTERACTION, {
		"npc_name": npc.npc_name,
		"action": "dialogue_end"
	}, 2, "dialogue_system")
	
	GameLogger.info("Dialogue with " + npc.npc_name + " ended")

func is_active() -> bool:
	return is_dialogue_active
