extends Control

@onready var pilih_button = $MainContainer/ButtonContainer/PilihButton

# Mask buttons
@onready var face1_button = $MainContainer/MaskContainer/GridContainer/Face1Container/Face1Button
@onready var face2_button = $MainContainer/MaskContainer/GridContainer/Face2Container/Face2Button
@onready var face3_button = $MainContainer/MaskContainer/GridContainer/Face3Container/Face3Button
@onready var face4_button = $MainContainer/MaskContainer/GridContainer/Face4Container/Face4Button
@onready var face5_button = $MainContainer/MaskContainer/GridContainer/Face5Container/Face5Button
@onready var face6_button = $MainContainer/MaskContainer/GridContainer/Face6Container/Face6Button
@onready var face7_button = $MainContainer/MaskContainer/GridContainer/Face7Container/Face7Button
@onready var custom_button = $MainContainer/MaskContainer/GridContainer/CustomContainer/CustomButton

var selected_mask_id: int = -1
var is_custom_selected: bool = false
var mask_buttons: Array[Button] = []

func _ready():
	print("=== TopengSelectionController._ready() ===")
	
	# Store all mask buttons in array for easier management
	mask_buttons = [face1_button, face2_button, face3_button, face4_button, face5_button, face6_button, face7_button, custom_button]
	
	# Verify all buttons are properly loaded
	for i in range(mask_buttons.size()):
		if mask_buttons[i] == null:
			print("ERROR: Button %d is null!" % (i + 1))
		else:
			print("Button %d loaded successfully" % (i + 1))
	
	# Initially disable the Pilih button until something is selected
	pilih_button.disabled = true
	print("Pilih button initially disabled: %s" % pilih_button.disabled)
	
	# Set custom button appearance
	custom_button.text = "+"
	
	print("Topeng Selection scene initialized")

func _on_face_button_pressed(face_id: int):
	"""Handle preset face button press"""
	print("Face %d button pressed" % face_id)
	
	selected_mask_id = face_id
	is_custom_selected = false
	
	# Update button appearances
	update_button_selection()
	
	# Enable the Pilih button
	pilih_button.disabled = false
	print("Pilih button enabled - disabled status: %s" % pilih_button.disabled)

func _on_custom_button_pressed():
	"""Handle custom button press"""
	print("Custom button pressed")
	
	selected_mask_id = -1
	is_custom_selected = true
	
	# Update button appearances
	update_button_selection()
	
	# Enable the Pilih button
	pilih_button.disabled = false
	print("Pilih button enabled for custom - disabled status: %s" % pilih_button.disabled)

func update_button_selection():
	"""Update visual appearance of buttons to show selection"""
	# Reset all buttons to normal appearance
	for button in mask_buttons:
		button.modulate = Color.WHITE
	
	# Highlight selected button
	if is_custom_selected:
		custom_button.modulate = Color.GREEN
		print("Custom button highlighted")
	elif selected_mask_id > 0 and selected_mask_id <= 7:
		mask_buttons[selected_mask_id - 1].modulate = Color.GREEN
		print("Face %d button highlighted" % selected_mask_id)

func _on_pilih_button_pressed():
	"""Handle Pilih button press"""
	print("=== Pilih button pressed ===")
	print("is_custom_selected: %s" % is_custom_selected)
	print("selected_mask_id: %d" % selected_mask_id)
	
	if is_custom_selected:
		print("Going to customization scene")
		# Pass data that this came from custom selection
		Global.selected_mask_type = "custom"
		Global.selected_mask_id = -1
		get_tree().change_scene_to_file("res://Scenes/TopengNusantara/TopengCustomizationScene.tscn")
	elif selected_mask_id > 0:
		print("Going to webcam scene with mask ID: %d" % selected_mask_id)
		# Pass data that this is a preset mask
		Global.selected_mask_type = "preset"
		Global.selected_mask_id = selected_mask_id
		get_tree().change_scene_to_file("res://Scenes/TopengNusantara/TopengWebcamScene.tscn")
	else:
		print("No mask selected - this should not happen")

func _on_back_button_pressed():
	"""Return to main menu"""
	print("Back button pressed - returning to main menu")
	get_tree().change_scene_to_file("res://Scenes/MainMenu/MainMenu.tscn")
