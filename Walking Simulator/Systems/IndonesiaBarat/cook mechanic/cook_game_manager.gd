extends Node3D
@onready var root = get_parent()
@onready var foodBoxesParent = root.get_node("FoodBox")
@onready var hand = root.get_node("Hand")
@onready var pot_ui = root.get_node("Cooker/PotDisplayUI")
@onready var pot_manager = $PotManager

# Reference ke UI Manager yang sudah ada di scene
@onready var ui_manager: Control = self.get_node("UIManager")
@onready var foodBoxes = {
	"foodbox1" : foodBoxesParent.get_node("Foodbox1"), 
	"foodbox2" : foodBoxesParent.get_node("Foodbox2"),
	"foodbox3" : foodBoxesParent.get_node("Foodbox3"), 
	"foodbox4" : foodBoxesParent.get_node("Foodbox4"),
	"foodbox5" : foodBoxesParent.get_node("Foodbox5"),
	"foodbox6" : foodBoxesParent.get_node("Foodbox6"),
	}
@export var recipes_file_path: String = "res://Data/recipes.json"
@export var recipes_asset_path: String = "res://Assets/Hunyuan/Indonesia Barat/Recipes/"

const jsonTools = preload("res://Tools/JsonTools.gd")

var food_name : String = "Soto"
var json_tools_instance = jsonTools.new()
var recipe_ingredient = {}
var win_condition_met: bool = false

# Untuk artifact cooking
var is_artifact_cooking: bool = false


func _ready() -> void:
	# Hubungkan sinyal
	hand.connect("dropped_to_pot", Callable(self, "_on_hand_dropped_to_pot"))
	pot_manager.connect("inventory_updated", Callable(pot_ui, "_on_pot_manager_inventory_updated"))
	pot_manager.connect("inventory_updated", Callable(self, "_on_pot_manager_inventory_updated"))
	pot_ui.connect("cook_pressed", Callable(self, "_on_cook_pressed"))
	
	# Connect UI Manager signals dengan defer
	call_deferred("connect_ui_signals")
	
	# Setup game data
	call_deferred("setup_game_data")

func connect_ui_signals() -> void:
	# Connect UI Manager signals
	if ui_manager:
		ui_manager.connect("retry_cooking", Callable(self, "_on_retry_cooking"))
		ui_manager.connect("exit_cooking", Callable(self, "_on_exit_cooking"))

func setup_game_data() -> void:
	# Cari pot node, jika tidak ada gunakan GameManager sebagai reference
	var pot_node = root.get_node_or_null("Cooker/Pot")
	if not pot_node:
		pot_node = self  # Gunakan GameManager sebagai fallback
	# Set reference pot ke UI untuk floating display
	pot_ui.set_pot_reference(pot_node)

	# Check if cooking from artifact
	if Global.has_method("has_cooking_data") and Global.has_cooking_data():
		print("=== COOKING FROM ARTIFACT ===")
		is_artifact_cooking = true
		food_name = Global.current_cooking_food if Global.current_cooking_food != "" else "Soto"
		recipe_ingredient = Global.current_cooking_recipe
		print("Artifact recipe loaded: ", recipe_ingredient)
	else:
		print("=== COOKING FROM DEFAULT RECIPES ===")
		is_artifact_cooking = false
		# Muat data resep default
		load_food_data(food_name)
	
	# Load assets
	load_food_assets()
	
	# Tampilkan panel resep sejak awal
	show_recipe_from_start()
	# setup process manager

func show_recipe_from_start() -> void:
	# Bentuk string resep dari recipe_ingredient
	var recipe_text = "Resep %s yang harus dibuat:\n" % food_name
	for k in recipe_ingredient.keys():
		recipe_text += "- %s: %s\n" % [k, str(recipe_ingredient[k])]
	
	# Tampilkan panel resep sejak awal sesi cooking
	if ui_manager:
		ui_manager.show_recipe_panel(recipe_text)

func _on_hand_dropped_to_pot(food: Node3D) -> void:
	print("Menerima sinyal dropped_to_pot dari tangan:", food.name)
	pot_manager.add(food)

func _on_cook_pressed() -> void:
	start_cooking_process()

func start_cooking_process() -> void:
	# Bentuk string resep dari recipe_ingredient
	var recipe_text = "Resep yang harus dibuat:\n"
	for k in recipe_ingredient.keys():
		recipe_text += "- %s: %s\n" % [k, str(recipe_ingredient[k])]

	# Panel resep selalu muncul selama sesi cooking
	ui_manager.show_recipe_panel(recipe_text)
	ui_manager.show_loading()

	# Disable input selama cooking
	disable_cooking_input()

	# Simulasi waktu memasak
	await get_tree().create_timer(2.0).timeout

	# Proses memasak
	var success = check_recipe_match()

	# Sembunyikan loading dan tampilkan hasil melalui UI Manager
	ui_manager.hide_loading()
	ui_manager.show_result(success)

	# Reset pot jika berhasil
	if success:
		pot_manager.pot_inventory.clear()
		pot_manager.emit_signal("inventory_updated", pot_manager.pot_inventory)

# UI handling sekarang dilakukan oleh display_ui
# cook_game_manager hanya menangani game logic dan memanggil display_ui

func disable_cooking_input() -> void:
	# Sembunyikan seluruh pot UI saat cooking
	if pot_ui:
		pot_ui.visible = false
	
	print("UI Pot disembunyikan selama cooking")

func enable_cooking_input() -> void:
	# Tampilkan kembali pot UI setelah cooking selesai
	if pot_ui:
		pot_ui.visible = true
	
	print("UI Pot ditampilkan kembali")

func check_recipe_match() -> bool:
	var normalized_recipe = Helper.normalize_dict(recipe_ingredient)
	var normalized_pot = Helper.normalize_dict(pot_manager.pot_inventory)
	
	print("Memasak bahan-bahan:", normalized_pot)
	print("Resep yang diperlukan:", normalized_recipe)
	
	if normalized_recipe == normalized_pot:
		print("Resep cocok! Masakan berhasil dibuat.")
		return true
	else:
		print("Bahan tidak sesuai resep. Masakan gagal.")
		return false
	

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
	for ingredient in ingredient_scenes.keys():
		var temp = {}
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

func _on_retry_cooking() -> void:
	print("=== RETRY COOKING ===")
	# Reset pot inventory
	pot_manager.pot_inventory.clear()
	pot_manager.emit_signal("inventory_updated", pot_manager.pot_inventory)

	# Tampilkan kembali resep (jangan sembunyikan saat retry)
	show_recipe_from_start()

	# Tampilkan kembali pot UI untuk cooking ulang
	enable_cooking_input()

	print("Pot direset untuk memasak ulang.")

func _on_exit_cooking() -> void:
	print("=== EXIT COOKING ===")
	# Reset pot inventory
	pot_manager.pot_inventory.clear() 
	pot_manager.emit_signal("inventory_updated", pot_manager.pot_inventory)

	# Sembunyikan panel resep
	ui_manager.hide_recipe_panel()

	# Tampilkan kembali pot UI 
	enable_cooking_input()

	# If cooking from artifact, return to PasarScene
	if is_artifact_cooking:
		return_to_pasar_scene()
	else:
		print("Keluar dari mode memasak.")

func return_to_pasar_scene():
	print("=== RETURNING TO PASAR SCENE ===")

	# Recapture mouse for FPS control when returning to PasarScene
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	# Clear Global cooking data
	if Global.has_method("clear_cooking_data"):
		Global.clear_cooking_data()
	else:
		Global.current_cooking_recipe = {}
		Global.current_cooking_food = ""
	
	# Return to PasarScene
	var pasar_scene_path = "res://Scenes/IndonesiaBarat/PasarScene.tscn"
	get_tree().change_scene_to_file(pasar_scene_path)
