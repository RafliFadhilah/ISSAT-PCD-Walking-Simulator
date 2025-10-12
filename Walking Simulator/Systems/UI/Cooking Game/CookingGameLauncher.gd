extends Node
class_name CookingGameLauncher

# Singleton untuk launch cooking game dari artifact collection
signal cooking_game_started(recipe_data: Dictionary)
signal cooking_game_finished(success: bool)

var current_recipe: Dictionary = {}
var current_food_name: String = ""

func launch_cooking_game(food_name: String, recipe_data: Dictionary) -> void:
	print("=== LAUNCHING COOKING GAME ===")
	print("Food: ", food_name)
	print("Recipe: ", recipe_data)
	
	# Store data untuk cooking game
	current_recipe = recipe_data
	current_food_name = food_name
	
	# Set global data agar cook_game_manager bisa ambil
	if Global.has_method("set_cooking_data"):
		Global.set_cooking_data(food_name, recipe_data)
	else:
		# Fallback: set langsung ke Global
		Global.current_cooking_recipe = recipe_data
		Global.current_cooking_food = food_name
	
	# Emit signal
	cooking_game_started.emit(recipe_data)
	
	# Load cooking scene
	var cooking_scene_path = "res://Scenes/IndonesiaBarat/BaseCook.tscn"
	
	# Pindah ke scene
	get_tree().change_scene_to_file(cooking_scene_path)

func get_current_recipe() -> Dictionary:
	return current_recipe

func get_current_food_name() -> String:
	return current_food_name

func finish_cooking_game(success: bool) -> void:
	print("=== COOKING GAME FINISHED ===")
	print("Success: ", success)
	
	cooking_game_finished.emit(success)
	
	# Clear data
	current_recipe.clear()
	current_food_name = ""
	
	# Kembali ke PasarScene
	var pasar_scene_path = "res://Scenes/IndonesiaBarat/PasarScene.tscn"
	get_tree().change_scene_to_file(pasar_scene_path)
