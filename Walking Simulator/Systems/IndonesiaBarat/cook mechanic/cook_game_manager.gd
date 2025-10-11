extends Node3D
@onready var root = get_parent()
@onready var foodBoxesParent = root.get_node("FoodBox")
@onready var hand = root.get_node("Hand")
@onready var pot_ui = root.get_node("Cooker/PotDisplayUI")
@onready var pot_manager = $PotManager
@onready var foodBoxes = {
	"foodbox1" : foodBoxesParent.get_node("Foodbox1"), 
	"foodbox2" : foodBoxesParent.get_node("Foodbox2"),
	"foodbox3" : foodBoxesParent.get_node("Foodbox3"), 
	"foodbox4" : foodBoxesParent.get_node("Foodbox4")}
@onready var recipes = null


func _ready() -> void:
	hand.connect("dropped_to_pot", Callable(self, "_on_hand_dropped_to_pot"))
	pot_manager.connect("inventory_updated", Callable(pot_ui, "_on_pot_manager_inventory_updated"))
	pot_ui.connect("cook_pressed", Callable(self, "_on_cook_pressed"))
	
	# Cari pot node, jika tidak ada gunakan GameManager sebagai reference
	var pot_node = root.get_node_or_null("Cooker/Pot")
	if not pot_node:
		pot_node = self  # Gunakan GameManager sebagai fallback
	
	# Set reference pot ke UI untuk floating display
	pot_ui.set_pot_reference(pot_node)

func _on_hand_dropped_to_pot(food: Node3D) -> void:
	print("Menerima sinyal dropped_to_pot dari tangan:", food.name)
	pot_manager.add(food)

func _on_cook_pressed() -> void:
	pot_manager.cook()

func load_food(Recipe : String) -> void:
	var dir = DirAccess.open(recipes)
	
	if not dir:
		print("❌ Folder resep tidak ditemukan:", recipes)
		return
	
	# List semua file di dalam folder resep
	dir.list_dir_begin()
	var file_name = dir.get_next()
	var food_count = 0
	
	while file_name != "":
		if file_name.ends_with(".tscn"):
			var scene_path = recipes + file_name
			var food_scene = load(scene_path)
			if food_scene:
				var food_instance = food_scene.instantiate()
				
				# Tempatkan di FoodBox kosong berikutnya
				var placed = false
				for key in foodBoxes.keys():
					var box = foodBoxes[key]
					if box.get_child_count() == 0:
						box.add_child(food_instance)
						print("✅", file_name, "ditambahkan ke", key)
						placed = true
						food_count += 1
						break
				if not placed:
					print("⚠️ Tidak ada FoodBox kosong untuk:", file_name)
			else:
				print("❌ Gagal memuat scene:", scene_path)
		
		file_name = dir.get_next()
	
	dir.list_dir_end()
	print("🍲 Total bahan dimuat:", food_count)
