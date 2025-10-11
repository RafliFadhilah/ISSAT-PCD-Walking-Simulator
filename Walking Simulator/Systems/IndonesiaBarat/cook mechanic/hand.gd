extends Node3D

@onready var pick_anchor: Node3D = $PickAnchor

var object_origin_position = null
var object_origin_foodbox = null
var held_object: Node3D = null
signal dropped_to_pot(food)


func handle_click(result: Dictionary) -> void:
	if result.size() > 0 and Input.is_action_just_pressed("mouse_left"):
		var collider = result.collider
		if collider:
			var foodbox = collider.get_parent()
			
			# Cari bahan makanan di foodbox
			var food_in_box = null
			for child in foodbox.get_children():
				if child.is_in_group("BahanMakanan"):
					food_in_box = child
					break
			
			if held_object == null:
				# Pickup jika tangan kosong
				if food_in_box:
					print("Pickup:", food_in_box.name)
					pickup_food(food_in_box)
			else:

				# Cek interactable hanya untuk drop/swap
				if foodbox.is_in_group("Pot"):
						print("Drop to pot:", held_object.name)
						# Jika pot, selalu drop ke asal
						emit_signal("dropped_to_pot", held_object)
						drop_object(object_origin_foodbox)  # Selalu drop ke foodbox asal
				
				if not foodbox.is_in_group("Interactable"):
					return
				
				if food_in_box:
					# Swap jika ada makanan di box
					print("Swap:", held_object.name, "<->", food_in_box.name)
					swap_objects(food_in_box, foodbox)
				else:
					# Drop ke box kosong (hanya jika interactable)
					print("Drop:", held_object.name, "to empty box")
					drop_object(foodbox)

func pickup_food(food: Node3D) -> void:
	print("Picking up:", food.name)
	
	# Simpan reference sebelum dipindah
	var original_parent = food.get_parent()
	object_origin_position = food.transform
	object_origin_foodbox = original_parent
	
	# Pindahkan food ke tangan
	food.get_parent().remove_child(food)
	pick_anchor.add_child(food)
	
	# Simpan info asal dan reset posisi
	food.set_meta("original_parent", original_parent)
	food.position = Vector3.ZERO
	
	held_object = food

func drop_object(_target_foodbox: Node3D) -> void:
	if not held_object:
		return
	
	# Remove dari tangan
	pick_anchor.remove_child(held_object)
	
	# Add ke foodbox asal
	object_origin_foodbox.add_child(held_object)
	
	# Kembalikan ke posisi awal
	held_object.transform = object_origin_position
	held_object = null	

func swap_objects(food_in_box: Node3D, _target_foodbox: Node3D) -> void:
	if not held_object:
		return
	
	print("Swapping:", held_object.name, "<->", food_in_box.name)
	
	# Simpan reference
	var temp_held = held_object
	var box_parent = food_in_box.get_parent()
	var food_in_box_original_transform = food_in_box.transform
	
	# Remove kedua objek dari parent
	pick_anchor.remove_child(temp_held)
	box_parent.remove_child(food_in_box)
	
	# Drop temp_held ke foodbox asalnya
	object_origin_foodbox.add_child(temp_held)
	temp_held.transform = object_origin_position
	
	pick_anchor.add_child(food_in_box)
	food_in_box.position = Vector3.ZERO
	
	# Update origin untuk food yang baru dipegang
	object_origin_position = food_in_box_original_transform
	object_origin_foodbox = box_parent
	
	# Update held_object reference
	held_object = food_in_box
	
	print("Swap complete! Now holding:", held_object.name)
