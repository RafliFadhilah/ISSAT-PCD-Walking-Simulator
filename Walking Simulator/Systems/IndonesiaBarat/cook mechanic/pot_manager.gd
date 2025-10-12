extends Node3D

@onready var pot_inventory: Dictionary = {}

# UI elements untuk loading dan hasil
var loading_ui: Control = null
var result_ui: Control = null

signal inventory_updated(inventory : Dictionary)
signal cooking_started()
signal cooking_finished(success: bool)
var normalized_inventory = Helper.normalize_dict(pot_inventory)

func _ready() -> void:
	# Defer UI setup to avoid parent busy error
	call_deferred("setup_ui_elements")

func setup_ui_elements() -> void:
	# Cek apakah ResultDialog sudah ada di scene tree
	var existing_result_dialog = get_tree().get_first_node_in_group("result_dialog")
	if not existing_result_dialog:
		existing_result_dialog = get_node_or_null("../ResultDialog")
	
	if existing_result_dialog:
		print("Menggunakan ResultDialog yang sudah ada di scene")
		result_ui = existing_result_dialog
		call_deferred("setup_existing_result_dialog")
	else:
		print("Membuat ResultDialog baru")
		result_ui = create_result_dialog()
		result_ui.visible = false
		get_tree().current_scene.call_deferred("add_child", result_ui)
	
	# Membuat loading UI (selalu buat baru karena sederhana)
	loading_ui = create_loading_screen()
	loading_ui.visible = false
	get_tree().current_scene.call_deferred("add_child", loading_ui)

func setup_existing_result_dialog() -> void:
	# Setup untuk ResultDialog yang sudah ada di scene
	if result_ui:
		result_ui.visible = false
		
		# Cari dan connect tombol jika ada
		var retry_btn = result_ui.get_node_or_null("RetryButton") 
		if not retry_btn:
			retry_btn = result_ui.get_node_or_null("Panel/RetryButton")
		if not retry_btn:
			retry_btn = result_ui.get_node_or_null("**/RetryButton")
			
		var exit_btn = result_ui.get_node_or_null("ExitButton")
		if not exit_btn:
			exit_btn = result_ui.get_node_or_null("Panel/ExitButton") 
		if not exit_btn:
			exit_btn = result_ui.get_node_or_null("**/ExitButton")
		
		# Connect button signals jika ditemukan
		if retry_btn and not retry_btn.pressed.is_connected(_on_retry_pressed):
			retry_btn.pressed.connect(_on_retry_pressed)
		if exit_btn and not exit_btn.pressed.is_connected(_on_exit_pressed):
			exit_btn.pressed.connect(_on_exit_pressed)

func create_loading_screen() -> Control:
	var screen = Control.new()
	screen.name = "LoadingScreen"
	screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	screen.z_index = 1000
	
	# Background
	var bg = ColorRect.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0, 0, 0, 0.7)
	screen.add_child(bg)
	
	# Loading text
	var label = Label.new()
	label.text = "Sedang Memasak..."
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	label.add_theme_font_size_override("font_size", 24)
	label.add_theme_color_override("font_color", Color.WHITE)
	screen.add_child(label)
	
	return screen

func create_result_dialog() -> Control:
	var dialog = Control.new()
	dialog.name = "ResultDialog"
	dialog.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dialog.z_index = 1001
	
	# Background
	var bg = ColorRect.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0, 0, 0, 0.7)
	dialog.add_child(bg)
	
	# Dialog panel
	var panel = Panel.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	panel.size = Vector2(300, 200)
	panel.position = Vector2(-150, -100)
	dialog.add_child(panel)
	
	# Margin container langsung di panel
	var margin = MarginContainer.new()
	margin.name = "MarginContainer"
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_bottom", 20)
	panel.add_child(margin)
	
	# VBox container di dalam margin
	var vbox = VBoxContainer.new()
	vbox.name = "VBoxContainer"
	vbox.add_theme_constant_override("separation", 15)
	margin.add_child(vbox)
	
	# Result label
	var result_label = Label.new()
	result_label.name = "ResultLabel"
	result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result_label.add_theme_font_size_override("font_size", 18)
	vbox.add_child(result_label)
	
	# Button container
	var button_container = HBoxContainer.new()
	button_container.add_theme_constant_override("separation", 10)
	vbox.add_child(button_container)
	
	# Retry button
	var retry_btn = Button.new()
	retry_btn.name = "RetryButton"
	retry_btn.text = "Coba Lagi"
	retry_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button_container.add_child(retry_btn)
	
	# Exit button
	var exit_btn = Button.new()
	exit_btn.name = "ExitButton"
	exit_btn.text = "Keluar"
	exit_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button_container.add_child(exit_btn)
	
	# Connect buttons
	retry_btn.pressed.connect(_on_retry_pressed)
	exit_btn.pressed.connect(_on_exit_pressed)
	
	return dialog

func add(food: Node3D) -> void:
	if food.has_meta("added_to_pot") and food.get_meta("added_to_pot"):
		print("Bahan ini sudah ditambahkan ke pot!")
		return
	
	# Tambahkan bahan ke pot
	if pot_inventory.has(food.name):
		pot_inventory[food.name] += 1
	else:
		pot_inventory[food.name] = 1
	print("Bahan ditambahkan ke pot:", food.name, "Jumlah sekarang:", pot_inventory[food.name])
	
	# Emit signal untuk update UI
	print("pot inventory:", pot_inventory)
	emit_signal("inventory_updated", pot_inventory)


func cook(inventory: Dictionary) -> void:
	if not pot_inventory:
		print("Pot kosong, tidak ada bahan untuk dimasak.")
		return

	# Tampilkan loading screen
	show_loading()
	
	# Simulasi waktu memasak
	await get_tree().create_timer(2.0).timeout
	
	# Proses memasak
	inventory = Helper.normalize_dict(inventory)
	pot_inventory = Helper.normalize_dict(pot_inventory)
	print("Memasak bahan-bahan:", pot_inventory)
	
	var success = false
	if inventory == pot_inventory:
		print("Resep cocok! Masakan berhasil dibuat.")
		success = true
	else:
		print("inventory : ", inventory, "pot_inventory:", pot_inventory)
		print("Bahan tidak sesuai resep. Masakan gagal.")
		success = false
	
	# Hide loading screen
	hide_loading()
	
	# Tampilkan hasil
	show_result(success)

func show_loading() -> void:
	if loading_ui:
		loading_ui.visible = true
	emit_signal("cooking_started")

func hide_loading() -> void:
	if loading_ui:
		loading_ui.visible = false

func show_result(success: bool) -> void:
	if result_ui:
		# Coba berbagai path untuk mencari result label
		var result_label = null
		var possible_paths = [
			"Panel/MarginContainer/VBoxContainer/ResultLabel",
			"ResultLabel", 
			"Panel/ResultLabel",
			"**/ResultLabel"  # Pencarian rekursif
		]
		
		for path in possible_paths:
			result_label = result_ui.get_node_or_null(path)
			if result_label:
				break
		
		if result_label:
			if success:
				result_label.text = "Masakan Berhasil!\nSelamat, resep cocok!"
				result_label.add_theme_color_override("font_color", Color.GREEN)
			else:
				result_label.text = "Masakan Gagal!\nBahan tidak sesuai resep."
				result_label.add_theme_color_override("font_color", Color.RED)
		else:
			# Jika tidak ada label khusus, buat pesan sederhana ke console
			if success:
				print("=== MASAKAN BERHASIL! ===")
				print("Selamat, resep cocok!")
			else:
				print("=== MASAKAN GAGAL! ===") 
				print("Bahan tidak sesuai resep.")
			
			# Debug info
			print("ResultLabel tidak ditemukan. Struktur ResultDialog:")
			_debug_print_structure(result_ui, 0)
		
		result_ui.visible = true
	
	emit_signal("cooking_finished", success)

func _debug_print_structure(node: Node, depth: int) -> void:
	var indent = ""
	for i in range(depth):
		indent += "  "
	print(indent + node.name + " (" + node.get_class() + ")")
	for child in node.get_children():
		_debug_print_structure(child, depth + 1)

func _on_retry_pressed() -> void:
	print("=== RETRY PRESSED ===")
	# Reset pot inventory
	pot_inventory.clear()
	emit_signal("inventory_updated", pot_inventory)
	
	# Hide result dialog
	if result_ui:
		result_ui.visible = false
	
	print("Pot direset untuk memasak ulang.")

func _on_exit_pressed() -> void:
	print("=== EXIT PRESSED ===")
	# Reset pot inventory  
	pot_inventory.clear()
	emit_signal("inventory_updated", pot_inventory)
	
	# Hide result dialog
	if result_ui:
		result_ui.visible = false
	
	print("Keluar dari memasak.")
	
	# Optional: Tambahan logic untuk keluar dari cooking mode
	# Misalnya kembali ke menu utama atau disable cooking UI

func display_inventory() -> void:
	if pot_inventory.is_empty():
		print("Pot kosong.")
	else:
		print("Isi pot saat ini:")
		for food_name in pot_inventory.keys():
			print("- %s: %d" % [food_name, pot_inventory[food_name]])
