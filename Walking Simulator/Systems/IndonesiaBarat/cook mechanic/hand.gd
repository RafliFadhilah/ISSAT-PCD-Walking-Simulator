extends Node3D

@onready var pick_anchor: Node3D = $PickAnchor

var object_origin_position: Transform3D
var object_origin_foodbox: Node = null    # Foodbox asal (parent dari Anchor)
var held_object: Node3D = null
signal dropped_to_pot(food)

func handle_click(result: Dictionary) -> void:
	if result.size() == 0 or not Input.is_action_just_pressed("mouse_left"):
		return
	var hit: Node = result.collider
	if hit == null:
		return

	# Naik ke atas sampai ketemu node yang punya "Anchor" atau yang digroup "Pot"
	var root_box: Node = hit
	while root_box != null \
		and root_box.get_node_or_null("Anchor") == null \
		and not root_box.is_in_group("Pot") \
		and root_box.get_parent() != null:
		root_box = root_box.get_parent()
	if root_box == null:
		return

	var anchor := root_box.get_node_or_null("Anchor") as Node3D
	var container: Node3D = anchor if anchor != null else (root_box as Node3D)

	var is_pot := root_box.is_in_group("Pot")

	# Cari bahan pada container (Anchor)
	var food_in_box: Node3D = null
	if container != null:
		for c in container.get_children():
			if c is Node3D and c.is_in_group("BahanMakanan"):
				food_in_box = c
				break

	# Jika belum memegang apa pun
	if held_object == null:
		if is_pot:
			return # klik pot tanpa memegang apa-apa: abaikan
		if food_in_box != null:
			pickup_food(food_in_box)
		return

	# Jika sedang memegang sesuatu
	if is_pot:
		emit_signal("dropped_to_pot", held_object)
		drop_object(null) # selalu balik ke origin
		return

	# Swap: yang di tangan balik ke origin, yang di box jadi dipegang
	if food_in_box != null:
		swap_objects(food_in_box, container)
	else:
		# Klik box kosong: balikkan ke origin
		drop_object(null)

func pickup_food(food: Node3D) -> void:
	# Simpan posisi lokal terhadap Anchor, dan simpan Foodbox (parent dari Anchor)
	var original_anchor := food.get_parent() as Node3D
	object_origin_position = food.transform
	object_origin_foodbox = original_anchor.get_parent()  # FoodboxX

	# Pindahkan ke tangan
	original_anchor.remove_child(food)
	pick_anchor.add_child(food)
	food.position = Vector3.ZERO
	held_object = food

func drop_object(_ignored: Node3D) -> void:
	if held_object == null:
		return
	# Balik ke foodbox asal (Anchor di dalam Foodbox asal)
	var target_root := object_origin_foodbox
	if target_root == null:
		return
	var target_anchor := target_root.get_node_or_null("Anchor") as Node3D
	if target_anchor == null:
		return

	pick_anchor.remove_child(held_object)
	target_anchor.add_child(held_object)
	held_object.transform = object_origin_position
	held_object = null

func swap_objects(food_in_box: Node3D, container: Node3D) -> void:
	if held_object == null:
		return
	# Simpan origin si calon yang akan dipegang
	var new_origin_transform := food_in_box.transform
	var new_origin_box := container.get_parent()  # FoodboxX

	# Kembalikan yang di tangan ke origin
	drop_object(null)

	# Ambil yang di box
	var anchor := food_in_box.get_parent()
	(anchor as Node).remove_child(food_in_box)
	pick_anchor.add_child(food_in_box)
	food_in_box.position = Vector3.ZERO

	# Set origin untuk objek baru di tangan
	object_origin_position = new_origin_transform
	object_origin_foodbox = new_origin_box
	held_object = food_in_box
