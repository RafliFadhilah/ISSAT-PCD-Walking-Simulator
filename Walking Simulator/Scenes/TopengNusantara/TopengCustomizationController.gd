extends Control

@onready var pilih_button = $MainContainer/CustomizationContainer/ButtonContainer/PilihButton
@onready var preview_text = $MainContainer/PreviewContainer/PreviewPanel/PreviewDisplay/PreviewText

# Base buttons
@onready var base_none_button = $MainContainer/CustomizationContainer/BaseContainer/BaseOptionsContainer/BaseNoneButton
@onready var base1_button = $MainContainer/CustomizationContainer/BaseContainer/BaseOptionsContainer/Base1Button
@onready var base2_button = $MainContainer/CustomizationContainer/BaseContainer/BaseOptionsContainer/Base2Button
@onready var base3_button = $MainContainer/CustomizationContainer/BaseContainer/BaseOptionsContainer/Base3Button

# Mata buttons
@onready var mata_none_button = $MainContainer/CustomizationContainer/MataContainer/MataOptionsContainer/MataNoneButton
@onready var mata1_button = $MainContainer/CustomizationContainer/MataContainer/MataOptionsContainer/Mata1Button
@onready var mata2_button = $MainContainer/CustomizationContainer/MataContainer/MataOptionsContainer/Mata2Button
@onready var mata3_button = $MainContainer/CustomizationContainer/MataContainer/MataOptionsContainer/Mata3Button

# Mulut buttons
@onready var mulut_none_button = $MainContainer/CustomizationContainer/MulutContainer/MulutOptionsContainer/MulutNoneButton
@onready var mulut1_button = $MainContainer/CustomizationContainer/MulutContainer/MulutOptionsContainer/Mulut1Button
@onready var mulut2_button = $MainContainer/CustomizationContainer/MulutContainer/MulutOptionsContainer/Mulut2Button
@onready var mulut3_button = $MainContainer/CustomizationContainer/MulutContainer/MulutOptionsContainer/Mulut3Button

var selected_base: int = -1
var selected_mata: int = -1
var selected_mulut: int = -1

var base_buttons: Array[Button] = []
var mata_buttons: Array[Button] = []
var mulut_buttons: Array[Button] = []

func _ready():
	print("=== TopengCustomizationController._ready() ===")
	
	# Store buttons in arrays for easier management (index 0 = None, 1-3 = options)
	base_buttons = [base_none_button, base1_button, base2_button, base3_button]
	mata_buttons = [mata_none_button, mata1_button, mata2_button, mata3_button]
	mulut_buttons = [mulut_none_button, mulut1_button, mulut2_button, mulut3_button]
	
	# Initially disable the Pilih button
	pilih_button.disabled = true
	
	# Update preview
	update_preview()
	
	print("Topeng Customization scene initialized")

func _on_base_button_pressed(base_id: int):
	"""Handle base selection"""
	print("Base %d selected" % base_id)
	selected_base = base_id
	
	# Update button appearances for base
	update_base_selection()
	
	# Check if we can enable Pilih button
	check_completion()
	
	# Update preview
	update_preview()

func _on_mata_button_pressed(mata_id: int):
	"""Handle mata selection"""
	print("Mata %d selected" % mata_id)
	selected_mata = mata_id
	
	# Update button appearances for mata
	update_mata_selection()
	
	# Check if we can enable Pilih button
	check_completion()
	
	# Update preview
	update_preview()

func _on_mulut_button_pressed(mulut_id: int):
	"""Handle mulut selection"""
	print("Mulut %d selected" % mulut_id)
	selected_mulut = mulut_id
	
	# Update button appearances for mulut
	update_mulut_selection()
	
	# Check if we can enable Pilih button
	check_completion()
	
	# Update preview
	update_preview()

func update_base_selection():
	"""Update visual appearance of base buttons"""
	for button in base_buttons:
		button.modulate = Color.WHITE
	
	if selected_base >= 0 and selected_base < base_buttons.size():
		base_buttons[selected_base].modulate = Color.GREEN

func update_mata_selection():
	"""Update visual appearance of mata buttons"""
	for button in mata_buttons:
		button.modulate = Color.WHITE
	
	if selected_mata >= 0 and selected_mata < mata_buttons.size():
		mata_buttons[selected_mata].modulate = Color.GREEN

func update_mulut_selection():
	"""Update visual appearance of mulut buttons"""
	for button in mulut_buttons:
		button.modulate = Color.WHITE
	
	if selected_mulut >= 0 and selected_mulut < mulut_buttons.size():
		mulut_buttons[selected_mulut].modulate = Color.GREEN

func check_completion():
	"""Check if all components are selected and enable/disable Pilih button"""
	# Now allow completion with None (0) selections as well
	if selected_base >= 0 and selected_mata >= 0 and selected_mulut >= 0:
		pilih_button.disabled = false
	else:
		pilih_button.disabled = true

func update_preview():
	"""Update the preview text with current selections"""
	var preview_parts = []
	
	if selected_base >= 0:
		if selected_base == 0:
			preview_parts.append("Base: None (Tidak digunakan)")
		else:
			preview_parts.append("Base: " + str(selected_base))
	else:
		preview_parts.append("Base: Belum dipilih")
	
	if selected_mata >= 0:
		if selected_mata == 0:
			preview_parts.append("Mata: None (Tidak digunakan)")
		else:
			preview_parts.append("Mata: " + str(selected_mata))
	else:
		preview_parts.append("Mata: Belum dipilih")
	
	if selected_mulut >= 0:
		if selected_mulut == 0:
			preview_parts.append("Mulut: None (Tidak digunakan)")
		else:
			preview_parts.append("Mulut: " + str(selected_mulut))
	else:
		preview_parts.append("Mulut: Belum dipilih")
	
	preview_text.text = "Pratinjau Topeng Custom\n\n" + "\n".join(preview_parts)
	
	if selected_base >= 0 and selected_mata >= 0 and selected_mulut >= 0:
		preview_text.text += "\n\n✅ Siap digunakan!"

func _on_pilih_button_pressed():
	"""Handle Pilih button - save custom mask and go to webcam scene"""
	if selected_base >= 0 and selected_mata >= 0 and selected_mulut >= 0:
		print("Custom mask created: Base=%d, Mata=%d, Mulut=%d" % [selected_base, selected_mata, selected_mulut])
		
		# Save custom mask data to global
		Global.selected_mask_type = "custom"
		Global.selected_mask_id = -1
		Global.custom_mask_components = {
			"base": selected_base,
			"mata": selected_mata,
			"mulut": selected_mulut
		}
		
		# Go to webcam scene
		get_tree().change_scene_to_file("res://Scenes/TopengNusantara/TopengWebcamScene.tscn")
	else:
		print("Not all components selected")

func _on_back_button_pressed():
	"""Return to mask selection"""
	print("Back button pressed - returning to mask selection")
	get_tree().change_scene_to_file("res://Scenes/TopengNusantara/TopengSelectionScene.tscn")