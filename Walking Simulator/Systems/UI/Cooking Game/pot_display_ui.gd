extends Control

signal cook_pressed

var background: Panel = null
var title_label: Label = null
var ingredients_container: VBoxContainer = null
var cook_button: Button = null

var pot_node: Node3D = null
var camera: Camera3D = null
var offset: Vector3 = Vector3(0, 2, 0)  # Offset di atas pot

func _ready() -> void:
	# Cari atau buat UI elements
	setup_ui_elements()
	
	# Set ukuran UI
	size = Vector2(280, 150)
	# Pastikan UI selalu di atas 3D dan tidak mengganggu input
	z_index = 4096
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# Posisi di tengah layar
	var viewport_size = get_viewport().get_visible_rect().size
	position = Vector2(
		(viewport_size.x - size.x) / 2,
		(viewport_size.y - size.y) / 2
	)
	
	# Cari camera di scene
	camera = get_viewport().get_camera_3d()
	
	# Show UI langsung untuk testing
	visible = true
	print("PotDisplayUI ready and visible at center")

func setup_ui_elements():
	# Buat UI secara programatik jika tidak ada
	if not get_node_or_null("Background"):
		create_ui_structure()
	
	# Set references
	background = get_node_or_null("Background")
	title_label = get_node_or_null("MarginContainer/VBoxContainer/TitleLabel")
	ingredients_container = get_node_or_null("MarginContainer/VBoxContainer/IngredientsContainer")
	cook_button = get_node_or_null("MarginContainer/VBoxContainer/CookButton")
	
	# Setup title jika ada
	if title_label:
		title_label.text = "Isi Pot"
	
	# Initial display
	update_display({})

func create_ui_structure():
	# Background Panel terlebih dahulu (agar berada di belakang konten)
	var bg = Panel.new()
	bg.name = "Background"
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0.6) # lebih transparan seperti sebelumnya
	style.border_width_left = 1
	style.border_width_right = 1
	style.border_width_top = 1
	style.border_width_bottom = 1
	style.border_color = Color(1, 1, 1, 0.6)
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	style.shadow_size = 6
	style.shadow_color = Color(0, 0, 0, 0.4)
	bg.add_theme_stylebox_override("panel", style)
	add_child(bg)

	# Main container dengan margin (ditambahkan setelah background agar tampil di atas)
	var margin_container = MarginContainer.new()
	margin_container.name = "MarginContainer"
	margin_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin_container.add_theme_constant_override("margin_left", 8)
	margin_container.add_theme_constant_override("margin_right", 8)
	margin_container.add_theme_constant_override("margin_top", 8)
	margin_container.add_theme_constant_override("margin_bottom", 8)
	add_child(margin_container)
	
	# Main container
	var vbox = VBoxContainer.new()
	vbox.name = "VBoxContainer"
	vbox.add_theme_constant_override("separation", 5)
	margin_container.add_child(vbox)
	
	# Title
	var title = Label.new()
	title.name = "TitleLabel"
	title.text = "Isi Pot"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	title.add_theme_color_override("font_outline_color", Color.BLACK)
	title.add_theme_constant_override("outline_size", 4)
	title.add_theme_font_size_override("font_size", 20)
	vbox.add_child(title)
	
	# Separator
	var sep = HSeparator.new()
	vbox.add_child(sep)
	
	# Ingredients container langsung (tanpa scroll)
	var ingredients = VBoxContainer.new()
	ingredients.name = "IngredientsContainer"
	ingredients.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(ingredients)

	# Separator bawah
	var sep2 = HSeparator.new()
	vbox.add_child(sep2)

	# Tombol Cook
	var btn = Button.new()
	btn.name = "CookButton"
	btn.text = "Masak"
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.add_theme_font_size_override("font_size", 18)
	btn.add_theme_color_override("font_color", Color(1,1,1,1))
	btn.add_theme_color_override("font_outline_color", Color(0,0,0,1))
	btn.add_theme_constant_override("outline_size", 3)
	vbox.add_child(btn)
	btn.pressed.connect(func(): emit_signal("cook_pressed"))

func set_pot_reference(pot: Node3D) -> void:
	pot_node = pot
	visible = true

# Temporary disable floating - untuk testing
#func _process(_delta: float) -> void:
	# Update posisi UI mengikuti pot jika ada
	#if pot_node and camera:
		#var pot_world_pos = pot_node.global_position + offset
		#var screen_pos = camera.unproject_position(pot_world_pos)
		
		# Set posisi UI di screen
		#global_position = screen_pos - size / 2

func update_display(inventory: Dictionary) -> void:
	# Pastikan ingredients_container ada
	if not ingredients_container:
		ingredients_container = get_node_or_null("MarginContainer/VBoxContainer/IngredientsContainer")
	
	if not ingredients_container:
		return
	
	# Clear semua children dari ingredients list
	for child in ingredients_container.get_children():
		child.queue_free()
	
	if inventory.is_empty():
		# Tampilkan pesan pot kosong
		var empty_label = Label.new()
		empty_label.text = "Pot kosong"
		empty_label.add_theme_color_override("font_color", Color(1, 1, 1, 1))
		empty_label.add_theme_color_override("font_outline_color", Color.BLACK)
		empty_label.add_theme_constant_override("outline_size", 4)
		empty_label.add_theme_font_size_override("font_size", 18)
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		ingredients_container.add_child(empty_label)
	else:
		# Tampilkan setiap bahan dan jumlahnya
		for food_name in inventory.keys():
			var ingredient_container = HBoxContainer.new()
			
			# Label nama bahan
			var name_label = Label.new()
			name_label.text = food_name
			name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			name_label.add_theme_color_override("font_color", Color(1, 1, 1, 1))
			name_label.add_theme_color_override("font_outline_color", Color.BLACK)
			name_label.add_theme_constant_override("outline_size", 4)
			name_label.add_theme_font_size_override("font_size", 18)
			
			# Label jumlah
			var count_label = Label.new()
			count_label.text = "x" + str(inventory[food_name])
			count_label.add_theme_color_override("font_color", Color(0.1, 1.0, 0.1, 1))
			count_label.add_theme_color_override("font_outline_color", Color.BLACK)
			count_label.add_theme_constant_override("outline_size", 4)
			count_label.add_theme_font_size_override("font_size", 18)
			count_label.size_flags_horizontal = Control.SIZE_SHRINK_END
			count_label.custom_minimum_size.x = 56  # Lebih besar untuk font besar
			
			ingredient_container.add_child(name_label)
			ingredient_container.add_child(count_label)
			ingredients_container.add_child(ingredient_container)

	# Setelah memperbarui konten, sesuaikan ukuran panel agar muat konten
	call_deferred("resize_to_content")

	# Enable/disable tombol Cook
	if cook_button == null:
		cook_button = get_node_or_null("MarginContainer/VBoxContainer/CookButton")
	if cook_button:
		cook_button.disabled = inventory.is_empty()

func resize_to_content():
	await get_tree().process_frame
	var margin_container: MarginContainer = get_node_or_null("MarginContainer")
	if not margin_container:
		return
	var vbox: VBoxContainer = margin_container.get_node_or_null("VBoxContainer")
	if not vbox:
		return
	# Ambil minimum size gabungan konten
	var content_size: Vector2 = vbox.get_combined_minimum_size()
	var padding := Vector2(16, 16) # sesuai margin kiri/kanan/atas/bawah
	# Batasi lebar minimum agar judul tidak terpotong
	var min_width: float = max(220.0, content_size.x + padding.x)
	var min_height: float = max(80.0, content_size.y + padding.y)
	size = Vector2(min_width, min_height)
	# Tetap posisikan di tengah layar
	center_ui()

func _on_pot_manager_inventory_updated(inventory: Dictionary) -> void:
	print("UI received inventory update:", inventory)
	update_display(inventory)

func center_ui():
	# Re-center UI di layar
	var viewport_size = get_viewport().get_visible_rect().size
	position = Vector2(
		(viewport_size.x - size.x) / 2,
		((viewport_size.y - size.y) / 2) 
	)
