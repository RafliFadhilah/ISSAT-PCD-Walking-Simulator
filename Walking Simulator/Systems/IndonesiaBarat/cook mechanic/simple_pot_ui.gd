extends Control

@onready var ingredients_container = get_node("VBoxContainer/IngredientsContainer")

func update_display(inventory: Dictionary) -> void:
	# Clear semua children dari ingredients list
	for child in ingredients_container.get_children():
		child.queue_free()
	
	if inventory.is_empty():
		# Tampilkan pesan pot kosong
		var empty_label = Label.new()
		empty_label.text = "Pot kosong"
		empty_label.add_theme_color_override("font_color", Color.GRAY)
		ingredients_container.add_child(empty_label)
	else:
		# Tampilkan setiap bahan dan jumlahnya
		for food_name in inventory.keys():
			var ingredient_container = HBoxContainer.new()
			
			# Label nama bahan
			var name_label = Label.new()
			name_label.text = food_name
			name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			name_label.add_theme_color_override("font_color", Color.WHITE)
			
			# Label jumlah
			var count_label = Label.new()
			count_label.text = "x" + str(inventory[food_name])
			count_label.add_theme_color_override("font_color", Color.YELLOW)
			count_label.size_flags_horizontal = Control.SIZE_SHRINK_END
			
			ingredient_container.add_child(name_label)
			ingredient_container.add_child(count_label)
			ingredients_container.add_child(ingredient_container)
