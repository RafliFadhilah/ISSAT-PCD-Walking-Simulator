extends Control

# UI elements untuk loading dan hasil
var loading_ui: Control = null
var result_ui: Control = null
var recipe_panel: Control = null

signal retry_cooking()
signal exit_cooking()

func _ready() -> void:
	call_deferred("setup_ui_elements")

func setup_ui_elements() -> void:
	# Setup ui_manager sebagai fullscreen container
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE  # Ignore input ketika tidak ada overlay

	# Membuat panel resep di kiri atas
	recipe_panel = create_recipe_panel()
	recipe_panel.visible = false
	add_child(recipe_panel)

	# Membuat loading UI
	loading_ui = create_loading_screen()
	loading_ui.visible = false
	add_child(loading_ui)

	# Membuat result UI
	result_ui = create_result_dialog()
	result_ui.visible = false
	add_child(result_ui)

func create_recipe_panel() -> Control:
	var panel = Panel.new()
	panel.name = "RecipePanel"
	# Pojok kiri atas, lebar 320, tinggi 120
	panel.anchor_left = 0.0
	panel.anchor_top = 0.0
	panel.anchor_right = 0.0
	panel.anchor_bottom = 0.0
	panel.offset_left = 20
	panel.offset_top = 20
	panel.offset_right = 340
	panel.offset_bottom = 140
	panel.z_index = 2100
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var margin = MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	panel.add_child(margin)

	var label = Label.new()
	label.name = "RecipeLabel"
	label.text = "Resep:"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	label.add_theme_font_size_override("font_size", 18)
	label.add_theme_color_override("font_color", Color.WHITE)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 1)
	label.autowrap_mode = 1 # AUTOWRAP_WORD
	margin.add_child(label)

	return panel

func create_loading_screen() -> Control:
	var screen = Control.new()
	screen.name = "LoadingScreen"
	screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	screen.z_index = 2000  # Higher z-index
	screen.mouse_filter = Control.MOUSE_FILTER_STOP  # Block all mouse input
	
	# Background
	var bg = ColorRect.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0, 0, 0, 0.8)  # Darker background
	screen.add_child(bg)
	
	# Loading text
	var label = Label.new()
	label.text = "Sedang Memasak..."
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	label.add_theme_font_size_override("font_size", 32)  # Larger font
	label.add_theme_color_override("font_color", Color.WHITE)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 2)
	screen.add_child(label)
	
	return screen

func create_result_dialog() -> Control:
	var dialog = Control.new()
	dialog.name = "ResultDialog"
	dialog.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dialog.z_index = 2001  # Higher than loading screen
	dialog.mouse_filter = Control.MOUSE_FILTER_STOP  # Block input
	
	# Background
	var bg = ColorRect.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0, 0, 0, 0.7)
	dialog.add_child(bg)
	
	# Dialog panel
	var panel = Panel.new()
	panel.name = "Panel"
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	panel.size = Vector2(400, 250)  # Lebih besar
	panel.position = Vector2(-200, -125)
	dialog.add_child(panel)
	
	# Margin container
	var margin = MarginContainer.new()
	margin.name = "MarginContainer"
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 30)
	margin.add_theme_constant_override("margin_right", 30)
	margin.add_theme_constant_override("margin_top", 30)
	margin.add_theme_constant_override("margin_bottom", 30)
	panel.add_child(margin)
	
	# VBox container
	var vbox = VBoxContainer.new()
	vbox.name = "VBoxContainer"
	vbox.add_theme_constant_override("separation", 20)
	margin.add_child(vbox)
	
	# Result label
	var result_label = Label.new()
	result_label.name = "ResultLabel"
	result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result_label.add_theme_font_size_override("font_size", 24)  # Font lebih besar
	result_label.add_theme_color_override("font_color", Color.WHITE)
	result_label.text = "Placeholder"  # Default text untuk testing
	vbox.add_child(result_label)
	
	# Button container
	var button_container = HBoxContainer.new()
	button_container.name = "ButtonContainer"
	button_container.add_theme_constant_override("separation", 20)
	vbox.add_child(button_container)
	
	# Retry button
	var retry_btn = Button.new()
	retry_btn.name = "RetryButton"
	retry_btn.text = "Coba Lagi"
	retry_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	retry_btn.add_theme_font_size_override("font_size", 18)
	button_container.add_child(retry_btn)
	
	# Exit button
	var exit_btn = Button.new()
	exit_btn.name = "ExitButton"
	exit_btn.text = "Keluar"
	exit_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	exit_btn.add_theme_font_size_override("font_size", 18)
	button_container.add_child(exit_btn)
	
	# Connect buttons
	retry_btn.pressed.connect(_on_retry_pressed)
	exit_btn.pressed.connect(_on_exit_pressed)
	
	return dialog

## Public methods untuk dipanggil dari cook_game_manager
func show_loading() -> void:
	if loading_ui:
		mouse_filter = Control.MOUSE_FILTER_STOP
		loading_ui.visible = true
		print("Loading screen ditampilkan")

# Tampilkan resep di kiri atas (selalu visible selama sesi cooking)
func show_recipe_panel(recipe_text: String) -> void:
	if recipe_panel:
		var label = recipe_panel.get_node_or_null("MarginContainer/RecipeLabel")
		if not label:
			# Fallback: cari secara rekursif
			label = find_recipe_label(recipe_panel)
		if label:
			label.text = recipe_text
		else:
			print("ERROR: RecipeLabel tidak ditemukan di panel resep!")
		recipe_panel.visible = true
		# Pastikan z_index panel resep lebih tinggi dari loading dan result UI
		recipe_panel.z_index = max(loading_ui.z_index, result_ui.z_index) + 1
		print("Panel resep ditampilkan")

# Cari RecipeLabel secara rekursif
func find_recipe_label(node: Node) -> Label:
	if node.name == "RecipeLabel" and node is Label:
		return node
	for child in node.get_children():
		var result = find_recipe_label(child)
		if result:
			return result
	return null

func hide_recipe_panel() -> void:
	if recipe_panel:
		recipe_panel.visible = false
		print("Panel resep disembunyikan")

func hide_loading() -> void:
	if loading_ui:
		loading_ui.visible = false
		# Kembalikan ke ignore ketika tidak ada overlay aktif
		if not result_ui.visible:
			mouse_filter = Control.MOUSE_FILTER_IGNORE
		print("Loading screen disembunyikan")

func show_result(success: bool) -> void:
	if result_ui:
		# Set ui_manager untuk menangkap input saat result dialog
		mouse_filter = Control.MOUSE_FILTER_STOP
		
		# Coba berbagai path untuk mencari ResultLabel
		var result_label = null
		var possible_paths = [
			"Panel/MarginContainer/VBoxContainer/ResultLabel",
			"ResultLabel",
			"Panel/ResultLabel"
		]
		
		for path in possible_paths:
			result_label = result_ui.get_node_or_null(path)
			if result_label:
				break
		
		# Jika tidak ditemukan, cari secara rekursif
		if not result_label:
			result_label = find_result_label(result_ui)
		
		if result_label:
			if success:
				result_label.text = "Masakan Berhasil!\nSelamat, resep cocok!"
				result_label.add_theme_color_override("font_color", Color.GREEN)
			else:
				result_label.text = "Masakan Gagal!\nBahan tidak sesuai resep."
				result_label.add_theme_color_override("font_color", Color.RED)
		else:
			print("ERROR: ResultLabel tidak ditemukan! Struktur result_ui:")
			debug_print_structure(result_ui, 0)
		
		result_ui.visible = true
	print("Result dialog ditampilkan: ", "Berhasil" if success else "Gagal")

func find_result_label(node: Node) -> Label:
	if node.name == "ResultLabel" and node is Label:
		return node
	
	for child in node.get_children():
		var result = find_result_label(child)
		if result:
			return result
	
	return null

func debug_print_structure(node: Node, depth: int) -> void:
	var indent = ""
	for i in range(depth):
		indent += "  "
	print(indent + node.name + " (" + node.get_class() + ")")
	for child in node.get_children():
		debug_print_structure(child, depth + 1)

func hide_result() -> void:
	if result_ui:
		result_ui.visible = false
		# Kembalikan ke ignore ketika tidak ada overlay aktif
		if not loading_ui.visible:
			mouse_filter = Control.MOUSE_FILTER_IGNORE
	print("Result dialog disembunyikan")

# Button handlers
func _on_retry_pressed() -> void:
	print("=== RETRY PRESSED ===")
	hide_result()
	emit_signal("retry_cooking")

func _on_exit_pressed() -> void:
	print("=== EXIT PRESSED ===")
	hide_result()
	emit_signal("exit_cooking")
