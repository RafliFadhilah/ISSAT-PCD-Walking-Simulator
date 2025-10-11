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
@export var recipes_file_path: String = "res://Data/recipes.json"
@export var recipes_asset_path: String = "res://Assets/Hunyuan/Indonesia Barat/Recipes/"

const jsonTools = preload("res://Tools/JsonTools.gd")

var json_tools_instance = jsonTools.new()
var recipe_ingredient = {}
var win_condition_met: bool = false


func _ready() -> void:
	# Hubungkan sinyal
	hand.connect("dropped_to_pot", Callable(self, "_on_hand_dropped_to_pot"))
	pot_manager.connect("inventory_updated", Callable(pot_ui, "_on_pot_manager_inventory_updated"))
	pot_manager.connect("inventory_updated", Callable(self, "_on_pot_manager_inventory_updated"))
	pot_ui.connect("cook_pressed", Callable(self, "_on_cook_pressed"))
	
	# Cari pot node, jika tidak ada gunakan GameManager sebagai reference
	var pot_node = root.get_node_or_null("Cooker/Pot")
	if not pot_node:
		pot_node = self  # Gunakan GameManager sebagai fallback
	# Set reference pot ke UI untuk floating display
	pot_ui.set_pot_reference(pot_node)

	# Muat data resep dan asset
	load_food_data("Soto")
	load_food_assets()
	# setup process manager

func _on_hand_dropped_to_pot(food: Node3D) -> void:
	print("Menerima sinyal dropped_to_pot dari tangan:", food.name)
	pot_manager.add(food)

func _on_cook_pressed() -> void:
	pot_manager.cook(recipe_ingredient)
	

func load_food_data(recipe_name: String) -> void:
	# Muat data resep data dan asset dari file JSON
	var recipe_data = json_tools_instance.load_json(recipes_file_path)
	
	if recipe_data == null:
		print("Gagal memuat data resep dari:", recipes_file_path)
		return

	if recipe_name in recipe_data.keys():
		recipe_ingredient = recipe_data[recipe_name].get('ingredients', {})
		print("Data resep berhasil dimuat:", recipe_ingredient)
	else:
		print("resep tidak ada")

func load_food_assets() -> void:
	var ingredient_scenes = json_tools_instance.load_json("res://Data/ingredients_asset.json")
	if ingredient_scenes == null:
		printerr("Gagal memuat data asset dari: res://Data/ingredients_asset.json")
		return

	# Ambil semua path scene yang sesuai bahan di resep
	var packed_scenes: Array = []
	var temp = {}
	for ingredient in ingredient_scenes.keys():
		temp[ingredient] = ingredient_scenes[ingredient]
		packed_scenes.append(temp)


	# Isi tiap foodbox dengan bahan yang sesuai
	var i = 0
	for foodbox in foodBoxes.values():
		if i >= packed_scenes.size():
			break

		var anchor = foodbox.get_node_or_null("Anchor")
		if anchor:
			# Bersihkan anchor
			for child in anchor.get_children():
				child.queue_free()
			print("loading scene : ", packed_scenes[i], " into ", foodbox.name)
			var scene = load(packed_scenes[i].values()[0])
			if scene:
				var instance = scene.instantiate()
				instance.name = packed_scenes[i].keys()[0]
				instance.add_to_group("BahanMakanan")
				anchor.add_child(instance)
				
				print("Menambahkan bahan ke foodbox:", instance.name)
		i += 1
