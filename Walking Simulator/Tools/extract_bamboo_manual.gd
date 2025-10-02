extends Node3D

# Manual Bamboo Extraction Tool
# Simple script for extracting bamboo models manually

var output_dir = "res://Assets/Terrain/Shared/psx_models/vegetation/bamboo/manual"

func _ready():
	GameLogger.info("=== Manual Bamboo Extraction ===")
	GameLogger.info("Starting extraction process...")
	
	# Create output directory
	var dir = DirAccess.open("res://")
	if not dir.dir_exists(output_dir):
		dir.make_dir_recursive(output_dir)
		GameLogger.info("✅ Created output directory: " + output_dir)
	
	# Run extraction
	extract_bamboo_models()
	
	GameLogger.info("\n=== Extraction Complete ===")
	GameLogger.info("Check the output directory for extracted models:")
	GameLogger.info(output_dir)

func extract_bamboo_models():
	"""Extract bamboo models from both source files"""
	
	GameLogger.info("\n🎋 Extracting from as01_bambusa_vulgaris_golden_bamboo.glb...")
	
	# Extract from vulgaris bamboo file
	var vulgaris_file = "res://Assets/Sketchfab/as01_bambusa_vulgaris_golden_bamboo.glb"
	var vulgaris_scene = load(vulgaris_file)
	
	if not vulgaris_scene:
		GameLogger.error("❌ Failed to load vulgaris bamboo file")
		return
	
	var vulgaris_instance = vulgaris_scene.instantiate()
	if not vulgaris_instance:
		GameLogger.error("❌ Failed to instantiate vulgaris bamboo scene")
		return
	
	GameLogger.info("✅ Loaded vulgaris bamboo file")
	GameLogger.info("📊 Analyzing scene structure...")
	
	var mesh_instances = []
	find_mesh_instances(vulgaris_instance, mesh_instances)
	
	GameLogger.info("📊 Found " + str(mesh_instances.size()) + " mesh instances")
	
	# Group by parent nodes
	var model_groups = {}
	for mesh in mesh_instances:
		var parent = mesh.get_parent()
		if parent:
			var parent_name = parent.name
			if not model_groups.has(parent_name):
				model_groups[parent_name] = []
			model_groups[parent_name].append(mesh)
	
	GameLogger.info("📦 Identified " + str(model_groups.size()) + " potential bamboo models")
	
	# Extract each group
	var model_count = 0
	for group_name in model_groups:
		var meshes = model_groups[group_name]
		if meshes.size() > 0:
			var success = save_model_group(meshes, "vulgaris_" + group_name)
			if success:
				model_count += 1
	
	GameLogger.info("✅ Extracted " + str(model_count) + " vulgaris bamboo models")
	
	# Clean up
	vulgaris_instance.queue_free()
	
	GameLogger.info("\n🎋 Extracting from as01_bambusa_golden_bamboo.glb...")
	
	# Extract from golden bamboo file
	var golden_file = "res://Assets/Sketchfab/as01_bambusa_golden_bamboo.glb"
	var golden_scene = load(golden_file)
	
	if not golden_scene:
		GameLogger.error("❌ Failed to load golden bamboo file")
		return
	
	var golden_instance = golden_scene.instantiate()
	if not golden_instance:
		GameLogger.error("❌ Failed to instantiate golden bamboo scene")
		return
	
	GameLogger.info("✅ Loaded golden bamboo file")
	GameLogger.info("📊 Analyzing scene structure...")
	
	mesh_instances.clear()
	find_mesh_instances(golden_instance, mesh_instances)
	
	GameLogger.info("📊 Found " + str(mesh_instances.size()) + " mesh instances")
	
	# Group by parent nodes
	model_groups.clear()
	for mesh in mesh_instances:
		var parent = mesh.get_parent()
		if parent:
			var parent_name = parent.name
			if not model_groups.has(parent_name):
				model_groups[parent_name] = []
			model_groups[parent_name].append(mesh)
	
	GameLogger.info("📦 Identified " + str(model_groups.size()) + " potential bamboo models")
	
	# Extract each group
	model_count = 0
	for group_name in model_groups:
		var meshes = model_groups[group_name]
		if meshes.size() > 0:
			var success = save_model_group(meshes, "golden_" + group_name)
			if success:
				model_count += 1
	
	GameLogger.info("✅ Extracted " + str(model_count) + " golden bamboo models")
	
	# Clean up
	golden_instance.queue_free()

func find_mesh_instances(node: Node, mesh_instances: Array):
	"""Find all MeshInstance3D nodes in the scene"""
	if node is MeshInstance3D:
		mesh_instances.append(node)
	
	for child in node.get_children():
		find_mesh_instances(child, mesh_instances)

func save_model_group(mesh_instances: Array, group_name: String) -> bool:
	"""Save a group of mesh instances as a single model"""
	
	# Create a new scene
	var new_scene = Node3D.new()
	new_scene.name = "BambooModel_" + group_name
	
	# Add all mesh instances
	for mesh in mesh_instances:
		var mesh_copy = mesh.duplicate()
		new_scene.add_child(mesh_copy)
	
	# Save as scene file
	var filename = group_name + ".tscn"
	var output_path = output_dir.path_join(filename)
	
	var packed_scene = PackedScene.new()
	packed_scene.pack(new_scene)
	
	var save_result = ResourceSaver.save(packed_scene, output_path)
	
	if save_result == OK:
		GameLogger.info("✅ Saved: " + filename + " (" + str(mesh_instances.size()) + " meshes)")
		# Clean up
		new_scene.queue_free()
		return true
	else:
		GameLogger.error("❌ Failed to save: " + filename)
		# Clean up
		new_scene.queue_free()
		return false

func _input(event):
	"""Handle input events"""
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_ESCAPE:
			GameLogger.info("\n🚪 ESC pressed - Exiting...")
			get_tree().quit()
		elif event.keycode == KEY_R:
			GameLogger.info("\n🔄 Restarting extraction...")
			extract_bamboo_models()
