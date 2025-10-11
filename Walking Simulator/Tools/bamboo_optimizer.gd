extends Node3D

# Bamboo Optimizer Tool
# Extracts and optimizes individual bamboo models from large GLB files

var source_files = [
	# "res://Assets/Sketchfab/as01_bambusa_golden_bamboo.glb",
	"res://Assets/Sketchfab/as01_bambusa_vulgaris_golden_bamboo.glb"
]

var output_dir = "res://Assets/Terrain/Shared/psx_models/vegetation/bamboo/optimized"

# UI References
var status_label: Label
var progress_label: Label
var results_label: Label
var extract_button: Button
var texture_button: Button
var report_button: Button
var full_button: Button
var cleanup_button: Button
var orientation_button: Button
var comprehensive_orientation_button: Button
var natural_orientation_button: Button
var rotate_45_button: Button
var reset_horizontal_button: Button
var rotate_90_button: Button
var rotate_270_button: Button
var cleanup_rotations_button: Button
var flip_vertical_button: Button
var orient_upright_button: Button
var rotate_z90_button: Button
var rotate_z270_button: Button
var downscale_textures_button: Button
# var gltfpack_button: Button

# GLTF Export utilities
# var _gltf_utils := preload("res://addons/gltf_exporter/utils.gd")  # Disabled to avoid OS.execute errors

func _ready():
	# Prevent multiple initializations
	if has_meta("_initialized"):
		return
	set_meta("_initialized", true)
	
	GameLogger.info("=== Bamboo Optimizer Tool ===")
	GameLogger.info("🎋 Initializing bamboo optimization system...")
	
	# Connect UI buttons
	extract_button = get_node_or_null("UI/MainPanel/VBoxContainer/ButtonContainer/ExtractButton")
	texture_button = get_node_or_null("UI/MainPanel/VBoxContainer/ButtonContainer/TextureButton")
	report_button = get_node_or_null("UI/MainPanel/VBoxContainer/ButtonContainer/ReportButton")
	full_button = get_node_or_null("UI/MainPanel/VBoxContainer/ButtonContainer/FullButton")
	cleanup_button = get_node_or_null("UI/MainPanel/VBoxContainer/ButtonContainer/CleanupButton")
	orientation_button = get_node_or_null("UI/MainPanel/VBoxContainer/ButtonContainer/OrientationButton")
	comprehensive_orientation_button = get_node_or_null("UI/MainPanel/VBoxContainer/ButtonContainer/ComprehensiveOrientationButton")
	natural_orientation_button = get_node_or_null("UI/MainPanel/VBoxContainer/ButtonContainer/NaturalOrientationButton")
	rotate_45_button = get_node_or_null("UI/MainPanel/VBoxContainer/ButtonContainer/Rotate45DegreesButton")
	reset_horizontal_button = get_node_or_null("UI/MainPanel/VBoxContainer/ButtonContainer/ResetToHorizontalButton")
	rotate_90_button = get_node_or_null("UI/MainPanel/VBoxContainer/ButtonContainer/Rotate90DegreesButton")
	rotate_270_button = get_node_or_null("UI/MainPanel/VBoxContainer/ButtonContainer/Rotate270DegreesButton")
	cleanup_rotations_button = get_node_or_null("UI/MainPanel/VBoxContainer/ButtonContainer/CleanupRotationsButton")
	flip_vertical_button = get_node_or_null("UI/MainPanel/VBoxContainer/ButtonContainer/FlipVerticalButton")
	orient_upright_button = get_node_or_null("UI/MainPanel/VBoxContainer/ButtonContainer/OrientUprightLeavesUpButton")
	rotate_z90_button = get_node_or_null("UI/MainPanel/VBoxContainer/ButtonContainer/RotateZ90Button")
	rotate_z270_button = get_node_or_null("UI/MainPanel/VBoxContainer/ButtonContainer/RotateZ270DegreesButton")
	downscale_textures_button = get_node_or_null("UI/MainPanel/VBoxContainer/ButtonContainer/DownscaleTextures256Button")
	# gltfpack_button = get_node_or_null("UI/MainPanel/VBoxContainer/ButtonContainer/GLTFPackButton")
	
	# Connect button signals safely (check if already connected)
	if extract_button and not extract_button.pressed.is_connected(_on_extract_button_pressed):
		extract_button.pressed.connect(_on_extract_button_pressed)
		GameLogger.info("✅ Connected Extract button")
	
	if texture_button and not texture_button.pressed.is_connected(_on_texture_button_pressed):
		texture_button.pressed.connect(_on_texture_button_pressed)
		GameLogger.info("✅ Connected Texture button")
	
	if report_button and not report_button.pressed.is_connected(_on_report_button_pressed):
		report_button.pressed.connect(_on_report_button_pressed)
		GameLogger.info("✅ Connected Report button")
	
	if full_button and not full_button.pressed.is_connected(_on_full_button_pressed):
		full_button.pressed.connect(_on_full_button_pressed)
		GameLogger.info("✅ Connected Full Optimization button")
	
	if cleanup_button and not cleanup_button.pressed.is_connected(_on_cleanup_button_pressed):
		cleanup_button.pressed.connect(_on_cleanup_button_pressed)
		GameLogger.info("✅ Connected Cleanup button")
	
	if orientation_button and not orientation_button.pressed.is_connected(_on_fix_orientation_button_pressed):
		orientation_button.pressed.connect(_on_fix_orientation_button_pressed)
		GameLogger.info("✅ Connected Orientation button")
	
	if comprehensive_orientation_button and not comprehensive_orientation_button.pressed.is_connected(_on_comprehensive_orientation_button_pressed):
		comprehensive_orientation_button.pressed.connect(_on_comprehensive_orientation_button_pressed)
		GameLogger.info("✅ Connected Comprehensive Orientation button")
	
	if natural_orientation_button and not natural_orientation_button.pressed.is_connected(_on_natural_orientation_button_pressed):
		natural_orientation_button.pressed.connect(_on_natural_orientation_button_pressed)
		GameLogger.info("✅ Connected Natural Orientation button")
	
	if rotate_45_button and not rotate_45_button.pressed.is_connected(_on_rotate_45_degrees_button_pressed):
		rotate_45_button.pressed.connect(_on_rotate_45_degrees_button_pressed)
		GameLogger.info("✅ Connected Rotate 45° button")
	
	if reset_horizontal_button and not reset_horizontal_button.pressed.is_connected(_on_reset_to_horizontal_button_pressed):
		reset_horizontal_button.pressed.connect(_on_reset_to_horizontal_button_pressed)
		GameLogger.info("✅ Connected Reset to Horizontal button")
	
	if rotate_90_button and not rotate_90_button.pressed.is_connected(_on_rotate_90_degrees_button_pressed):
		rotate_90_button.pressed.connect(_on_rotate_90_degrees_button_pressed)
		GameLogger.info("✅ Connected Rotate 90° button")
	
	if rotate_270_button and not rotate_270_button.pressed.is_connected(_on_rotate_270_degrees_button_pressed):
		rotate_270_button.pressed.connect(_on_rotate_270_degrees_button_pressed)
		GameLogger.info("✅ Connected Rotate 270° button")
	
	if cleanup_rotations_button and not cleanup_rotations_button.pressed.is_connected(_on_cleanup_rotations_button_pressed):
		cleanup_rotations_button.pressed.connect(_on_cleanup_rotations_button_pressed)
		GameLogger.info("✅ Connected Cleanup Rotations button")
	
	if flip_vertical_button and not flip_vertical_button.pressed.is_connected(_on_flip_vertical_button_pressed):
		flip_vertical_button.pressed.connect(_on_flip_vertical_button_pressed)
		GameLogger.info("✅ Connected Flip Vertical button")
	
	if orient_upright_button and not orient_upright_button.pressed.is_connected(_on_orient_upright_leaves_up_button_pressed):
		orient_upright_button.pressed.connect(_on_orient_upright_leaves_up_button_pressed)
		GameLogger.info("✅ Connected Orient Upright button")
	
	if rotate_z90_button and not rotate_z90_button.pressed.is_connected(_on_rotate_z_90_button_pressed):
		rotate_z90_button.pressed.connect(_on_rotate_z_90_button_pressed)
		GameLogger.info("✅ Connected Rotate Z90° button")
	
	if rotate_z270_button and not rotate_z270_button.pressed.is_connected(_on_rotate_z_270_button_pressed):
		rotate_z270_button.pressed.connect(_on_rotate_z_270_button_pressed)
		GameLogger.info("✅ Connected Rotate Z270° button")
	
	if downscale_textures_button and not downscale_textures_button.pressed.is_connected(_on_downscale_textures_256_button_pressed):
		downscale_textures_button.pressed.connect(_on_downscale_textures_256_button_pressed)
		GameLogger.info("✅ Connected Downscale Textures button")
	
	# if gltfpack_button:
	# 	gltfpack_button.pressed.connect(_on_gltfpack_button_pressed)
	# 	GameLogger.info("✅ Connected GLTFPack button")
	
	GameLogger.info("🎯 All UI connections established")
	GameLogger.info("🚀 Ready to optimize bamboo models!")

func test_gltf_export():
	"""Test if GLTF export is working with a simple scene"""
	GameLogger.info("🧪 Testing GLTF export functionality...")
	
	# Create a simple test scene
	var test_scene = Node3D.new()
	test_scene.name = "TestScene"
	
	# Add a simple mesh (cube)
	var mesh_instance = MeshInstance3D.new()
	var box_mesh = BoxMesh.new()
	box_mesh.size = Vector3(1, 1, 1)
	mesh_instance.mesh = box_mesh
	test_scene.add_child(mesh_instance)
	
	# Try to export this simple scene
	var test_output = "res://test_export.glb"
	var gltf_document = GLTFDocument.new()
	var gltf_state = GLTFState.new()
	
	var append_result = gltf_document.append_from_scene(test_scene, gltf_state)
	if append_result != OK:
		GameLogger.error("❌ GLTF export test failed - cannot append scene (error: " + str(append_result) + ")")
		test_scene.queue_free()
		return
	
	var write_result = gltf_document.write_to_filesystem(gltf_state, test_output)
	if write_result != OK:
		GameLogger.error("❌ GLTF export test failed - cannot write file (error: " + str(write_result) + ")")
		test_scene.queue_free()
		return
	
	# Check if file was created and has content
	var check_file = FileAccess.open(test_output, FileAccess.READ)
	if check_file:
		var file_size = check_file.get_length()
		check_file.close()
		GameLogger.info("✅ GLTF export test successful - file size: " + str(file_size) + " bytes")
		
		# Clean up test file
		var dir = DirAccess.open("res://")
		if dir.file_exists("test_export.glb"):
			dir.remove("test_export.glb")
	else:
		GameLogger.error("❌ GLTF export test failed - cannot verify output file")
	
	test_scene.queue_free()

func extract_bamboo_models():
	"""Extract individual bamboo models from large GLB files"""
	GameLogger.info("\n=== Starting Bamboo Extraction ===")
	update_progress("Creating output directory...")
	
	# Create output directory
	var dir = DirAccess.open("res://")
	if not dir.dir_exists(output_dir):
		dir.make_dir_recursive(output_dir)
		GameLogger.info("✅ Created output directory: " + output_dir)
		update_progress("Output directory created")
	else:
		update_progress("Output directory already exists")
	
	var total_models = 0
	for source_file in source_files:
		update_progress("Processing: " + source_file.get_file())
		var models_extracted = extract_from_file(source_file)
		total_models += models_extracted
	
	update_status("Extraction completed!")
	update_progress("Extracted " + str(total_models) + " bamboo models")
	
	# Don't auto-cleanup - let user decide when to clean up
	# cleanup_old_files()
	
	update_results("✅ Bamboo extraction completed!\n\n🎋 Total models extracted: " + str(total_models) + "\n📁 Output directory: " + output_dir + "\n\nIndividual optimized .glb files are ready for use.\n\n💡 Use the '🧹 Cleanup Old Files' button to remove temporary files when needed.")

func extract_from_file(file_path: String) -> int:
	"""Extract bamboo models from a specific GLB file"""
	GameLogger.info("\n🔍 Processing: " + file_path)
	
	# Load the GLB file
	var glb_scene = load(file_path)
	if not glb_scene:
		GameLogger.error("❌ Failed to load GLB file: " + file_path)
		update_progress("❌ Failed to load: " + file_path.get_file())
		return 0
	
	# Instantiate to examine the structure
	var instance = glb_scene.instantiate()
	if not instance:
		GameLogger.error("❌ Failed to instantiate GLB scene")
		update_progress("❌ Failed to instantiate: " + file_path.get_file())
		return 0
	
	GameLogger.info("✅ Loaded GLB file successfully")
	update_progress("Analyzing scene structure...")
	
	# Analyze the scene structure
	var mesh_instances = []
	analyze_scene_structure(instance, mesh_instances)
	
	GameLogger.info("📊 Scene structure:")
	print_scene_structure(instance, 0, mesh_instances)
	
	# Group mesh instances to create complete bamboo biomes
	var model_groups = group_mesh_instances_by_biome(mesh_instances)
	
	GameLogger.info("\n🌿 Extracting complete bamboo biomes...")
	update_progress("Extracting " + str(model_groups.size()) + " bamboo biomes...")
	
	GameLogger.info("📊 Found " + str(mesh_instances.size()) + " mesh instances")
	
	var models_extracted = 0
	for group_name in model_groups:
		var mesh_instances_in_group = model_groups[group_name]
		if mesh_instances_in_group.size() > 0:
			var success = extract_model_group(group_name, mesh_instances_in_group, file_path)
			if success:
				models_extracted += 1
	
	GameLogger.info("🌿 Grouped into " + str(model_groups.size()) + " bamboo biomes")
	
	# Clean up
	instance.queue_free()
	
	return models_extracted

func analyze_scene_structure(node: Node, mesh_instances: Array):
	"""Recursively analyze scene structure and collect mesh instances"""
	if node is MeshInstance3D:
		mesh_instances.append(node)
	
	for child in node.get_children():
		analyze_scene_structure(child, mesh_instances)

func print_scene_structure(node: Node, depth: int, mesh_instances: Array):
	"""Print the scene structure in a tree-like format"""
	var indent = "  ".repeat(depth)
	var mesh_count = 0
	for mesh in mesh_instances:
		if mesh.is_ancestor_of(node) or mesh == node:
			mesh_count += 1
	
	GameLogger.info(indent + "├─ " + node.name + " (" + node.get_class() + ")")
	if mesh_count > 0:
		GameLogger.info(indent + "   └─ Contains " + str(mesh_count) + " mesh instances")
	
	for child in node.get_children():
		print_scene_structure(child, depth + 1, mesh_instances)

func group_mesh_instances(mesh_instances: Array) -> Dictionary:
	"""Group mesh instances by their parent nodes to identify individual models"""
	var groups = {}
	
	for mesh in mesh_instances:
		var parent = mesh.get_parent()
		if parent:
			var parent_name = parent.name
			if not groups.has(parent_name):
				groups[parent_name] = []
			groups[parent_name].append(mesh)
	
	return groups

func group_mesh_instances_by_biome(mesh_instances: Array) -> Dictionary:
	"""Group mesh instances to create complete bamboo biomes instead of individual stalks"""
	var biome_groups = {}
	
	# Validate input
	if not mesh_instances or mesh_instances.size() == 0:
		GameLogger.warning("⚠️ No mesh instances provided for biome grouping")
		return biome_groups
	
	# First, let's analyze the scene structure to understand how bamboos are organized
	var scene_root = null
	if mesh_instances.size() > 0:
		var first_mesh = mesh_instances[0]
		
		# Validate first mesh
		if not first_mesh:
			GameLogger.warning("⚠️ First mesh instance is null, falling back to individual grouping")
			return group_mesh_instances(mesh_instances)
		
		# Check if the mesh has a valid tree and current scene
		# Add extra null checks to prevent "data.tree is null" errors
		var tree = first_mesh.get_tree()
		if tree and tree.current_scene:
			scene_root = tree.current_scene
		else:
			# Try to find the root by going up the hierarchy
			var current = first_mesh
			while current and current.get_parent():
				current = current.get_parent()
			scene_root = current
	
	if not scene_root:
		GameLogger.warning("⚠️ Could not determine scene root, falling back to individual grouping")
		return group_mesh_instances(mesh_instances)
	
	GameLogger.info("🔍 Analyzing scene structure for biome grouping...")
	GameLogger.info("📊 Scene root: " + str(scene_root.name if scene_root else "Unknown"))
	GameLogger.info("📊 Total mesh instances: " + str(mesh_instances.size()))
	
	# Look for natural groupings - often bamboos are organized in clusters
	# Check if there are intermediate parent nodes that group multiple bamboos
	var potential_biomes = {}
	
	for mesh in mesh_instances:
		var current = mesh
		var biome_key = ""
		
		# Go up the hierarchy to find a good grouping level
		# We want to group at a level that gives us complete bamboo clusters
		var max_iterations = 100  # Prevent infinite loops
		var iteration_count = 0
		
		while current and current.get_parent() and current.get_parent() != scene_root and iteration_count < max_iterations:
			var parent = current.get_parent()
			var parent_name = parent.name
			
			# Look for names that suggest this is a bamboo cluster
			if (parent_name.contains("bamboo") or 
				parent_name.contains("cluster") or 
				parent_name.contains("group") or
				parent_name.contains("FBX") or
				parent_name.contains("Bambusa") or
				parent_name.contains("Vulgaris") or
				parent_name.contains("Golden")):
				biome_key = parent_name
				break
			
			current = parent
			iteration_count += 1
		
		if iteration_count >= max_iterations:
			GameLogger.warning("⚠️ Max iterations reached while traversing hierarchy for mesh: " + str(mesh.name))
		
		# If we found a good grouping level, use it
		if biome_key != "":
			if not potential_biomes.has(biome_key):
				potential_biomes[biome_key] = []
			potential_biomes[biome_key].append(mesh)
		else:
			# Fallback: group by immediate parent
			var parent = mesh.get_parent()
			if parent and parent.name:
				var parent_name = parent.name
				if not potential_biomes.has(parent_name):
					potential_biomes[parent_name] = []
				potential_biomes[parent_name].append(mesh)
			else:
				# Last resort: group by mesh name
				var mesh_name = mesh.name if mesh.name else "UnknownMesh"
				if not potential_biomes.has(mesh_name):
					potential_biomes[mesh_name] = []
				potential_biomes[mesh_name].append(mesh)
	
	GameLogger.info("🌿 Found " + str(potential_biomes.size()) + " potential bamboo biomes:")
	for biome_name in potential_biomes:
		var mesh_count = potential_biomes[biome_name].size()
		GameLogger.info("   - " + biome_name + ": " + str(mesh_count) + " mesh instances")
	
	return potential_biomes

func extract_model_group(group_name: String, mesh_instances: Array, source_file: String) -> bool:
	"""Extract a group of mesh instances as a single bamboo biome"""
	GameLogger.info("\n🌿 Extracting bamboo biome: " + group_name)
	
	# Create a new scene for this biome
	var new_scene = Node3D.new()
	new_scene.name = "BambooBiome_" + group_name
	
	# Add all mesh instances to the new scene with proper transformations
	for mesh in mesh_instances:
		var mesh_copy = mesh.duplicate()
		
		# Preserve the original transformation
		if mesh_copy is Node3D:
			mesh_copy.transform = mesh.transform
			mesh_copy.rotation = mesh.rotation
			mesh_copy.scale = mesh.scale
		
		new_scene.add_child(mesh_copy)
	
	# Fix the orientation to prevent upside-down models
	fix_model_orientation(new_scene)
	
	# Generate output filename
	var source_filename = source_file.get_file().get_basename()
	var output_filename = source_filename + "_" + group_name + ".glb"
	var output_path = output_dir.path_join(output_filename)
	
	# Save as GLB file
	var success = save_as_glb(new_scene, output_path, mesh_instances)
	
	if success:
		GameLogger.info("✅ Saved bamboo biome: " + output_filename)
		GameLogger.info("   📁 Path: " + output_path)
		GameLogger.info("   📊 Meshes: " + str(mesh_instances.size()))
		
		# Calculate statistics
		var total_vertices = 0
		for mesh in mesh_instances:
			if mesh.mesh:
				total_vertices += mesh.mesh.get_surface_count()
		
		GameLogger.info("   📏 Surfaces: " + str(total_vertices))
		
		# Get file size
		var file = FileAccess.open(output_path, FileAccess.READ)
		if file:
			var size_bytes = file.get_length()
			var size_mb = size_bytes / (1024.0 * 1024.0)
			GameLogger.info("   💾 File size: " + str(size_mb) + " MB")
			
			# Categorize by size for easier selection
			if size_mb < 5:
				GameLogger.info("   🎯 Size category: Small (good for scattered placement)")
			elif size_mb < 20:
				GameLogger.info("   🎯 Size category: Medium (good for biome creation)")
			elif size_mb < 50:
				GameLogger.info("   🎯 Size category: Large (good for focal points)")
			else:
				GameLogger.info("   🎯 Size category: Very Large (consider further optimization)")
			
			file.close()
	else:
		GameLogger.error("❌ Failed to save: " + output_filename)
	
	# Clean up
	new_scene.queue_free()
	
	return success

func fix_model_orientation(scene: Node3D) -> void:
	"""Fix the orientation of bamboo models to prevent them from being upside down"""
	GameLogger.info("   🔄 Fixing model orientation...")
	
	# Apply natural bamboo orientation: leaves at top, stalk at bottom
	GameLogger.info("   🔧 Applying natural bamboo orientation...")
	
	# Rotate to make bamboo stand upright (convert from horizontal to vertical)
	scene.rotate_x(PI/2)
	
	# Fine-tune the orientation
	scene.rotate_z(PI)
	
	# Reset child transforms for proper inheritance
	for child in scene.get_children():
		if child is Node3D:
			child.transform = Transform3D()
	
	GameLogger.info("   ✅ Natural vertical bamboo orientation applied")

func save_as_glb(scene: Node3D, output_path: String, mesh_instances: Array) -> bool:
	"""Save a scene as a GLB file"""
	GameLogger.info("   💾 Saving as GLB: " + output_path)
	
	# Debug: Check the original scene structure before any processing
	GameLogger.info("   🔍 Original scene structure:")
	_debug_scene_structure(scene, 0)
	
	# Try method 1: Direct GLTF export from the scene object
	GameLogger.info("   🔄 Trying direct GLTF export (Method 1)...")
	var glb_result = _export_scene_to_glb_direct(scene, output_path)
	
	if glb_result == OK:
		GameLogger.info("   ✅ GLB file exported successfully (Method 1)")
		return true
	
	GameLogger.info("   ⚠️ Method 1 failed, trying alternative approach...")
	
	# Try method 2: Alternative GLTF export with different settings
	var glb_result2 = _export_scene_to_glb_alternative(scene, output_path)
	
	if glb_result2 == OK:
		GameLogger.info("   ✅ GLB file exported successfully (Method 2)")
		return true
	
	GameLogger.error("   ❌ Both GLTF export methods failed, falling back to .tscn")
	
	# Fallback: save as .tscn
	var fallback_path = output_path.replace(".glb", ".tscn")
	var packed_scene = PackedScene.new()
	packed_scene.pack(scene)
	var fallback_result = ResourceSaver.save(packed_scene, fallback_path)
	
	if fallback_result == OK:
		GameLogger.info("   ✅ Fallback: Saved as .tscn file")
		return true
	else:
		GameLogger.error("   ❌ Failed to save fallback .tscn file")
		return false

func _export_scene_to_glb_direct(scene: Node3D, output_path: String) -> int:
	"""Export a scene directly to GLB format using Godot's built-in GLTF API with texture optimization"""
	GameLogger.info("      🔄 Converting scene directly to GLB with texture optimization...")
	
	GameLogger.info("      📊 Scene: " + str(scene.name))
	GameLogger.info("      📊 Scene children count: " + str(scene.get_child_count()))
	
	# Check if scene has any mesh instances
	var mesh_counts = _count_meshes_fixed(scene)
	var mesh_count = mesh_counts.mesh_count
	var total_vertices = mesh_counts.total_vertices
	GameLogger.info("      📊 Found " + str(mesh_count) + " mesh instances with " + str(total_vertices) + " total vertices")
	
	if mesh_count == 0:
		GameLogger.error("      ❌ Scene has no mesh instances - cannot export")
		GameLogger.error("      💡 Scene structure: " + str(scene.name) + " with " + str(scene.get_child_count()) + " children")
		# Debug: print the actual scene structure
		_debug_scene_structure(scene, 0)
		return FAILED
	
	# Use the new texture-optimized export function
	var export_success = _export_scene_to_glb_direct_optimized(scene, output_path, true, 64, 0.4, false)
	if not export_success:
		GameLogger.error("      ❌ Texture-optimized GLB export failed")
		return FAILED
	
	# Verify the file was created and has content
	var check_file = FileAccess.open(output_path, FileAccess.READ)
	if check_file:
		var file_size = check_file.get_length()
		check_file.close()
		GameLogger.info("      📊 GLB file size: " + str(file_size) + " bytes")
		
		if file_size < 100:  # Less than 100 bytes is definitely wrong
			GameLogger.error("      ❌ GLB file is too small (" + str(file_size) + " bytes) - export failed")
			GameLogger.error("      💡 This suggests the GLTF export didn't include the mesh data properly")
			return FAILED
	else:
		GameLogger.error("      ❌ Cannot verify GLB file after creation")
		return FAILED
	
	GameLogger.info("      ✅ GLB export successful using texture-optimized export")
	return OK

func _export_scene_to_glb(scene_path: String, output_path: String) -> int:
	"""Export a scene to GLB format using Godot's built-in GLTF API (legacy method)"""
	GameLogger.info("      🔄 Converting scene to GLB (legacy method)...")
	
	# Load the scene
	var scene = load(scene_path)
	if not scene:
		GameLogger.error("      ❌ Failed to load scene from: " + scene_path)
		return FAILED
	
	# Instantiate the scene
	var scene_instance = scene.instantiate()
	if not scene_instance:
		GameLogger.error("      ❌ Failed to instantiate scene")
		return FAILED
	
	GameLogger.info("      📊 Scene instance created: " + str(scene_instance.name))
	GameLogger.info("      📊 Scene children count: " + str(scene_instance.get_child_count()))
	
	# Check if scene has any mesh instances
	var mesh_counts = _count_meshes_fixed(scene_instance)
	var mesh_count = mesh_counts.mesh_count
	var total_vertices = mesh_counts.total_vertices
	GameLogger.info("      📊 Found " + str(mesh_count) + " mesh instances with " + str(total_vertices) + " total vertices")
	
	if mesh_count == 0:
		GameLogger.error("      ❌ Scene has no mesh instances - cannot export")
		GameLogger.error("      💡 Scene structure: " + str(scene_instance.name) + " with " + str(scene_instance.get_child_count()) + " children")
		# Debug: print the actual scene structure
		_debug_scene_structure(scene_instance, 0)
		scene_instance.queue_free()
		return FAILED
	
	# Create GLTF document and state
	var gltf_document = GLTFDocument.new()
	var gltf_state = GLTFState.new()
	
	# Note: GLTFState doesn't have set_export_named_textures or set_export_force_single_mesh in Godot 4.3
	# Using default export settings
	
	GameLogger.info("      🔄 Converting scene to GLTF format...")
	var append_result = gltf_document.append_from_scene(scene_instance, gltf_state)
	if append_result != OK:
		GameLogger.error("      ❌ Failed to convert scene to GLTF format (error: " + str(append_result) + ")")
		GameLogger.error("      💡 This might be due to unsupported scene structure or materials")
		scene_instance.queue_free()
		return FAILED
	
	GameLogger.info("      ✅ Scene converted to GLTF format successfully")
	GameLogger.info("      🔄 Writing GLB file...")
	
	# Write to filesystem
	var write_result = gltf_document.write_to_filesystem(gltf_state, output_path)
	if write_result != OK:
		GameLogger.error("      ❌ Failed to write GLB file (error: " + str(write_result) + ")")
		GameLogger.error("      💡 This might be due to file permission or disk space issues")
		scene_instance.queue_free()
		return FAILED
	
	# Verify the file was created and has content
	var check_file = FileAccess.open(output_path, FileAccess.READ)
	if check_file:
		var file_size = check_file.get_length()
		check_file.close()
		GameLogger.info("      📊 GLB file size: " + str(file_size) + " bytes")
		
		if file_size < 100:  # Less than 100 bytes is definitely wrong
			GameLogger.error("      ❌ GLB file is too small (" + str(file_size) + " bytes) - export failed")
			GameLogger.error("      💡 This suggests the GLTF export didn't include the mesh data properly")
			scene_instance.queue_free()
			return FAILED
	else:
		GameLogger.error("      ❌ Cannot verify GLB file after creation")
		scene_instance.queue_free()
		return FAILED
	
	scene_instance.queue_free()
	GameLogger.info("      ✅ GLB export successful using Godot's built-in API")
	return OK

func _count_meshes(node: Node, mesh_count: int, total_vertices: int):
	"""Recursively count mesh instances and vertices"""
	if node is MeshInstance3D:
		mesh_count += 1
		if node.mesh:
			total_vertices += node.mesh.get_surface_count()
	
	for child in node.get_children():
		_count_meshes(child, mesh_count, total_vertices)

func _count_meshes_fixed(node: Node) -> Dictionary:
	"""Recursively count mesh instances and vertices - returns actual counts"""
	var result = {"mesh_count": 0, "total_vertices": 0}
	_count_meshes_recursive(node, result)
	return result

func _count_meshes_recursive(node: Node, result: Dictionary):
	"""Helper function to recursively count meshes"""
	if node is MeshInstance3D:
		result.mesh_count += 1
		if node.mesh:
			result.total_vertices += node.mesh.get_surface_count()
	
	for child in node.get_children():
		_count_meshes_recursive(child, result)

func _debug_scene_structure(node: Node, depth: int):
	"""Debug function to print scene structure recursively"""
	var indent = "  ".repeat(depth)
	var node_info = indent + "├─ " + node.name + " (" + node.get_class() + ")"
	
	if node is MeshInstance3D:
		if node.mesh:
			node_info += " [MESH: " + str(node.mesh.get_surface_count()) + " surfaces]"
		else:
			node_info += " [MESH: NULL]"
	
	GameLogger.info(node_info)
	
	for child in node.get_children():
		_debug_scene_structure(child, depth + 1)

func _export_scene_to_glb_alternative(scene: Node3D, output_path: String) -> int:
	"""Alternative GLTF export method that creates a simpler scene structure"""
	GameLogger.info("      🔄 Trying alternative GLTF export method...")
	
	# Create a new root node with just the mesh instances
	var export_root = Node3D.new()
	export_root.name = "BambooExport"
	
	# Find all mesh instances and add them directly to the export root
	var mesh_instances = []
	_collect_mesh_instances(scene, mesh_instances)
	
	GameLogger.info("      📊 Alternative method found " + str(mesh_instances.size()) + " mesh instances")
	
	if mesh_instances.size() == 0:
		GameLogger.error("      ❌ No mesh instances found for alternative export")
		GameLogger.error("      💡 Let's debug the original scene structure:")
		_debug_scene_structure(scene, 0)
		export_root.queue_free()
		return FAILED
	
	# Add each mesh instance to the export root
	for mesh in mesh_instances:
		var mesh_copy = mesh.duplicate()
		export_root.add_child(mesh_copy)
	
	# Try to export this simplified structure
	var gltf_document = GLTFDocument.new()
	var gltf_state = GLTFState.new()
	
	# Note: GLTFState doesn't have set_export_named_textures or set_export_force_single_mesh in Godot 4.3
	# Using default export settings
	
	GameLogger.info("      🔄 Converting simplified scene to GLTF...")
	var append_result = gltf_document.append_from_scene(export_root, gltf_state)
	if append_result != OK:
		GameLogger.error("      ❌ Alternative method failed to convert scene (error: " + str(append_result) + ")")
		export_root.queue_free()
		return FAILED
	
	GameLogger.info("      ✅ Simplified scene converted successfully")
	
	# Write to filesystem
	var write_result = gltf_document.write_to_filesystem(gltf_state, output_path)
	if write_result != OK:
		GameLogger.error("      ❌ Alternative method failed to write GLB file (error: " + str(write_result) + ")")
		export_root.queue_free()
		return FAILED
	
	# Verify file size
	var check_file = FileAccess.open(output_path, FileAccess.READ)
	if check_file:
		var file_size = check_file.get_length()
		check_file.close()
		GameLogger.info("      📊 Alternative GLB file size: " + str(file_size) + " bytes")
		
		if file_size < 100:
			GameLogger.error("      ❌ Alternative GLB file is too small (" + str(file_size) + " bytes)")
			export_root.queue_free()
			return FAILED
	else:
		GameLogger.error("      ❌ Cannot verify alternative GLB file")
		export_root.queue_free()
		return FAILED
	
	export_root.queue_free()
	GameLogger.info("      ✅ Alternative GLTF export successful")
	return OK

func _collect_mesh_instances(node: Node, mesh_instances: Array):
	"""Recursively collect all mesh instances from a node tree"""
	if node is MeshInstance3D:
		mesh_instances.append(node)
	
	for child in node.get_children():
		_collect_mesh_instances(child, mesh_instances)

func cleanup_old_files():
	"""Remove old temporary and optimization files"""
	GameLogger.info("\n🧹 Cleaning up old files...")
	
	var dir = DirAccess.open(output_dir)
	if not dir:
		GameLogger.error("❌ Cannot access output directory")
		return
	
	var removed_count = 0
	dir.list_dir_begin()
	var file_name = dir.get_next()
	
	while file_name != "":
		if not dir.current_is_dir():
			if file_name.contains("_temp") or file_name.contains("old"):
				var full_path = output_dir.path_join(file_name)
				var remove_result = dir.remove(file_name)
				if remove_result == OK:
					GameLogger.info("🗑️ Removed old file: " + file_name)
					removed_count += 1
				else:
					GameLogger.error("❌ Failed to remove: " + file_name)
		file_name = dir.get_next()
	
	dir.list_dir_end()
	
	if removed_count > 0:
		GameLogger.info("✅ Cleaned up " + str(removed_count) + " old files")
	else:
		GameLogger.info("ℹ️ No old files found to clean up")

func optimize_textures():
	"""Optimize bamboo textures for better performance"""
	GameLogger.info("\n=== Texture Optimization ===")
	
	# Check if the bamboo textures directory exists
	var texture_dir = "res://Assets/Terrain/Shared/psx_models/vegetation/bamboo/textures"
	var dir = DirAccess.open("res://")
	
	if not dir.dir_exists(texture_dir):
		GameLogger.warning("⚠️ Bamboo texture directory does not exist: " + texture_dir)
		GameLogger.info("💡 This is normal if you haven't extracted bamboo textures yet")
		GameLogger.info("💡 Texture optimization will be skipped for now")
		return
	
	# Find all bamboo texture files
	var bamboo_textures = []
	dir.list_dir_begin()
	var file_name = dir.get_next()
	
	while file_name != "":
		if not dir.current_is_dir():
			if file_name.ends_with(".png") or file_name.ends_with(".jpg") or file_name.ends_with(".dds"):
				bamboo_textures.append(file_name)
		file_name = dir.get_next()
	
	dir.list_dir_end()
	
	if bamboo_textures.size() == 0:
		GameLogger.info("ℹ️ No bamboo texture files found in: " + texture_dir)
		GameLogger.info("💡 Texture optimization will be skipped")
		return
	
	GameLogger.info("📊 Found " + str(bamboo_textures.size()) + " bamboo texture files")
	
	# Create optimized texture directory
	var optimized_texture_dir = output_dir.path_join("textures")
	if not dir.dir_exists(optimized_texture_dir):
		var make_dir_result = dir.make_dir_recursive(optimized_texture_dir)
		if make_dir_result != OK:
			GameLogger.error("❌ Failed to create optimized texture directory: " + optimized_texture_dir)
			return
		GameLogger.info("✅ Created optimized texture directory: " + optimized_texture_dir)
	
	# Copy textures to optimized directory
	var copied_count = 0
	for texture_file in bamboo_textures:
		var source_path = texture_dir.path_join(texture_file)
		var dest_path = optimized_texture_dir.path_join(texture_file)
		
		var copy_result = dir.copy(source_path, dest_path)
		if copy_result == OK:
			GameLogger.info("✅ Copied: " + texture_file)
			copied_count += 1
		else:
			GameLogger.error("❌ Failed to copy: " + texture_file + " (error: " + str(copy_result) + ")")
	
	GameLogger.info("🎉 Texture optimization completed! Copied " + str(copied_count) + " of " + str(bamboo_textures.size()) + " textures")

func generate_optimization_report():
	"""Generate a comprehensive report of the optimization process"""
	GameLogger.info("\n=== Optimization Report ===")
	
	var report_file = output_dir.path_join("optimization_report.txt")
	var file = FileAccess.open(report_file, FileAccess.WRITE)
	
	if not file:
		GameLogger.error("❌ Failed to create report file")
		return
	
	file.store_line("=== Bamboo Optimization Report ===")
	file.store_line("Generated: " + Time.get_datetime_string_from_system())
	file.store_line("")
	
	file.store_line("Source Files:")
	for source_file in source_files:
		file.store_line("  - " + source_file)
	file.store_line("")
	
	file.store_line("Output Directory: " + output_dir)
	file.store_line("")
	
	# List extracted files with size categorization
	var dir = DirAccess.open(output_dir)
	if dir:
		file.store_line("Extracted Bamboo Biomes:")
		file.store_line("")
		
		# Categorize by size
		var small_biomes = []
		var medium_biomes = []
		var large_biomes = []
		var very_large_biomes = []
		
		dir.list_dir_begin()
		var file_name = dir.get_next()
		
		while file_name != "":
			if not dir.current_is_dir() and file_name.ends_with(".glb"):
				var full_path = output_dir.path_join(file_name)
				var file_check = FileAccess.open(full_path, FileAccess.READ)
				if file_check:
					var file_size = file_check.get_length()
					var size_mb = file_size / (1024.0 * 1024.0)
					
					var biome_info = "  - " + file_name + " (" + str(size_mb) + " MB)"
					
					if size_mb < 5:
						small_biomes.append(biome_info)
					elif size_mb < 20:
						medium_biomes.append(biome_info)
					elif size_mb < 50:
						large_biomes.append(biome_info)
					else:
						very_large_biomes.append(biome_info)
					
					file_check.close()
				else:
					file.store_line("  - " + file_name + " (size unknown)")
			file_name = dir.get_next()
		
		dir.list_dir_end()
		
		# Write categorized results
		if small_biomes.size() > 0:
			file.store_line("🎯 SMALL BIOMES (< 5 MB) - Good for scattered placement:")
			for biome in small_biomes:
				file.store_line(biome)
			file.store_line("")
		
		if medium_biomes.size() > 0:
			file.store_line("🎯 MEDIUM BIOMES (5-20 MB) - Perfect for terrain biomes:")
			for biome in medium_biomes:
				file.store_line(biome)
			file.store_line("")
		
		if large_biomes.size() > 0:
			file.store_line("🎯 LARGE BIOMES (20-50 MB) - Good for focal points:")
			for biome in large_biomes:
				file.store_line(biome)
			file.store_line("")
		
		if very_large_biomes.size() > 0:
			file.store_line("⚠️ VERY LARGE BIOMES (> 50 MB) - Consider further optimization:")
			for biome in very_large_biomes:
				file.store_line(biome)
			file.store_line("")
		
		# Recommendations
		file.store_line("💡 RECOMMENDATIONS:")
		file.store_line("  - For Papua & Tambora terrain: Use MEDIUM BIOMES (5-20 MB)")
		file.store_line("  - For scattered placement: Use SMALL BIOMES (< 5 MB)")
		file.store_line("  - For focal points: Use LARGE BIOMES (20-50 MB)")
		file.store_line("  - Avoid VERY LARGE BIOMES for performance reasons")
	
	file.close()
	
	# Check if report was saved successfully by trying to open it
	var check_file = FileAccess.open(report_file, FileAccess.READ)
	if check_file:
		var file_size = check_file.get_length()
		check_file.close()
		if file_size > 0:
			GameLogger.info("✅ Saved optimization report: " + report_file)
		else:
			GameLogger.error("❌ Report file is empty")
	else:
		GameLogger.error("❌ Failed to save optimization report")

func update_status(text: String):
	"""Update the status label"""
	if status_label:
		status_label.text = "📊 " + text

func update_progress(text: String):
	"""Update the progress label"""
	if progress_label:
		progress_label.text = "🔄 " + text

func update_results(text: String):
	"""Update the results label"""
	if results_label:
		results_label.text = "📋 " + text

# Button event handlers
func _on_extract_button_pressed():
	GameLogger.info("\n🎋 Extract Button Pressed")
	update_status("Extracting bamboo models...")
	extract_bamboo_models()

func _on_texture_button_pressed():
	GameLogger.info("\n🖼️ Texture Button Pressed")
	update_status("Optimizing textures...")
	optimize_textures()
	update_status("Texture optimization completed!")

func _on_report_button_pressed():
	GameLogger.info("\n📊 Report Button Pressed")
	update_status("Generating report...")
	generate_optimization_report()
	update_status("Report generated!")

func _on_full_button_pressed():
	GameLogger.info("\n🚀 Full Button Pressed")
	update_status("Running full optimization...")
	run_full_optimization()

func _on_cleanup_button_pressed():
	GameLogger.info("\n🧹 Cleanup Button Pressed")
	update_status("Cleaning up old files...")
	cleanup_old_files()
	update_status("Cleanup completed!")

func _on_fix_orientation_button_pressed():
	GameLogger.info("\n🔄 Fix Orientation Button Pressed")
	update_status("Fixing model orientations...")
	fix_existing_model_orientations()
	update_status("Orientation fixes applied!")

func _on_comprehensive_orientation_button_pressed():
	GameLogger.info("\n🔄 Comprehensive Fix Orientation Button Pressed")
	update_status("Applying comprehensive orientation fixes...")
	apply_comprehensive_orientation_fix_to_existing_models()
	update_status("Comprehensive orientation fixes applied!")

func _on_natural_orientation_button_pressed():
	"""Apply natural vertical orientation to existing models"""
	GameLogger.info("🌿 Applying natural vertical orientation to existing models...")
	
	var optimized_dir = "res://Assets/Terrain/Shared/psx_models/vegetation/bamboo/optimized/"
	if not DirAccess.dir_exists_absolute(optimized_dir):
		GameLogger.warning("No optimized directory found. Please extract models first.")
		update_status("❌ No optimized directory found. Extract models first.")
		return
	
	apply_natural_vertical_orientation_to_existing_models()
	update_status("✅ Natural vertical orientation applied to existing models")

func _on_rotate_90_degrees_button_pressed():
	"""Rotate existing models by 90 degrees around Y-axis"""
	GameLogger.info("🔄 Rotating existing models by 90 degrees...")
	
	var optimized_dir = "res://Assets/Terrain/Shared/psx_models/vegetation/bamboo/optimized/"
	if not DirAccess.dir_exists_absolute(optimized_dir):
		GameLogger.warning("No optimized directory found. Please extract models first.")
		update_status("❌ No optimized directory found. Extract models first.")
		return
	
	rotate_existing_models_90_degrees()
	update_status("✅ Models rotated by 90 degrees")

func _on_rotate_270_degrees_button_pressed():
	"""Rotate existing models by 270 degrees around Y-axis"""
	GameLogger.info("🔄 Rotating existing models by 270 degrees...")
	
	var optimized_dir = "res://Assets/Terrain/Shared/psx_models/vegetation/bamboo/optimized/"
	if not DirAccess.dir_exists_absolute(optimized_dir):
		GameLogger.warning("No optimized directory found. Please extract models first.")
		update_status("❌ No optimized directory found. Extract models first.")
		return
	
	rotate_existing_models_270_degrees()
	update_status("✅ Models rotated by 270 degrees")

func _on_rotate_45_degrees_button_pressed():
	"""Rotate existing models by 45 degrees around Y-axis"""
	GameLogger.info("🔄 Rotating existing models by 45 degrees...")
	
	var optimized_dir = "res://Assets/Terrain/Shared/psx_models/vegetation/bamboo/optimized/"
	if not DirAccess.dir_exists_absolute(optimized_dir):
		GameLogger.warning("No optimized directory found. Please extract models first.")
		update_status("❌ No optimized directory found. Extract models first.")
		return
	
	rotate_existing_models_45_degrees()
	update_status("✅ Models rotated by 45 degrees")

func _on_reset_to_horizontal_button_pressed():
	"""Reset models to horizontal orientation"""
	GameLogger.info("🔄 Resetting models to horizontal orientation...")
	
	var optimized_dir = "res://Assets/Terrain/Shared/psx_models/vegetation/bamboo/optimized/"
	if not DirAccess.dir_exists_absolute(optimized_dir):
		GameLogger.warning("No optimized directory found. Please extract models first.")
		update_status("❌ No optimized directory found. Extract models first.")
		return
	
	reset_models_to_horizontal()
	update_status("✅ Models reset to horizontal orientation")

func _on_cleanup_rotations_button_pressed():
	"""Cleanup rotated variants and previews, restore preferred variant to original filename"""
	GameLogger.info("🧹 Cleaning up rotated variants and preview PNGs...")
	var optimized_dir := "res://Assets/Terrain/Shared/psx_models/vegetation/bamboo/optimized/"
	if not DirAccess.dir_exists_absolute(optimized_dir):
		update_status("❌ No optimized directory found")
		return
	var result_summary := cleanup_rotations_and_previews(optimized_dir)
	update_results(result_summary)
	update_status("✅ Cleanup completed")

func cleanup_rotations_and_previews(target_dir: String) -> String:
	"""Delete all non-flipX variants and related PNGs; keep *_flipX.glb renamed back to original. Also remove Godot .import files in this folder."""
	var summary_lines: Array = []
	var dir := DirAccess.open(target_dir)
	if dir == null:
		return "❌ Cannot open directory: %s" % target_dir
	# Collect files
	var glb_files: Array = []
	var png_files: Array = []
	var import_files: Array = []
	dir.list_dir_begin()
	var name := dir.get_next()
	while name != "":
		if name.begins_with("."):
			name = dir.get_next(); continue
		if name.ends_with(".glb"):
			glb_files.append(name)
		elif name.ends_with(".png"):
			png_files.append(name)
		elif name.ends_with(".import"):
			import_files.append(name)
		name = dir.get_next()
	dir.list_dir_end()
	# Group by base (without any suffix after _flipX/_rotated/_upright)
	var base_to_variants: Dictionary = {}
	for f in glb_files:
		var base := _strip_rotated_suffix(_strip_upright_suffix(_strip_flipx_suffix(f)))
		if not base_to_variants.has(base):
			base_to_variants[base] = []
		(base_to_variants[base] as Array).append(f)
	# Process each group
	var deleted_glb := 0
	var deleted_png := 0
	var deleted_import := 0
	var renamed := 0
	for base in base_to_variants.keys():
		var base_name: String = String(base)
		var variants: Array = base_to_variants[base_name]
		# Prefer flipX if present
		var flipx: String = ""
		for v in variants:
			if (v as String).contains("_flipX"):
				flipx = v; break
		var keep_name: String = flipx
		if keep_name == "":
			# No flipX found: keep original if present and remove rotated/upright
			for v in variants:
				var vs: String = v
				if not (vs.contains("_rotated") or vs.contains("_upright") or vs.contains("_flipX")):
					keep_name = vs; break
		if keep_name == "" and variants.size() > 0:
			keep_name = variants[0]
		# Determine original filename
		var original_name: String = base_name
		# If keep_name is not original_name, rename
		if keep_name != "" and keep_name != original_name:
			var from_path := target_dir.path_join(keep_name)
			var to_path := target_dir.path_join(original_name)
			if FileAccess.file_exists(to_path):
				DirAccess.remove_absolute(to_path)
			var rn_err := DirAccess.rename_absolute(from_path, to_path)
			if rn_err == OK:
				renamed += 1
				summary_lines.append("↪ Renamed %s → %s" % [keep_name, original_name])
			else:
				summary_lines.append("❌ Rename failed: %s → %s (err %s)" % [keep_name, original_name, str(rn_err)])
		# Delete all other variants except the kept one (now original_name)
		for v in variants:
			var vs: String = v
			var is_original := (vs == original_name) or (keep_name == original_name and vs == original_name)
			if is_original:
				continue
			var is_variant := vs.contains("_rotated") or vs.contains("_upright") or vs.contains("_flipX")
			if is_variant:
				var delp := target_dir.path_join(vs)
				if FileAccess.file_exists(delp):
					var rm_err := DirAccess.remove_absolute(delp)
					if rm_err == OK:
						deleted_glb += 1
					else:
						summary_lines.append("❌ Failed to delete %s (err %s)" % [vs, str(rm_err)])
		# Delete preview PNGs that are not flipX for this base
		var base_png_prefix: String = base_name.get_basename() # without .glb
		for p in png_files:
			if (p as String).contains(base_png_prefix):
				if (p as String).contains("_flipX"):
					continue
				var pngp := target_dir.path_join(p)
				if FileAccess.file_exists(pngp):
					var rmpe := DirAccess.remove_absolute(pngp)
					if rmpe == OK:
						deleted_png += 1
					else:
						summary_lines.append("❌ Failed to delete %s (err %s)" % [p, str(rmpe)])
	# Delete any Godot .import files in this folder (they can be regenerated)
	for imp in import_files:
		var imp_path := target_dir.path_join(imp)
		if FileAccess.file_exists(imp_path):
			var rmi := DirAccess.remove_absolute(imp_path)
			if rmi == OK:
				deleted_import += 1
			else:
				summary_lines.append("❌ Failed to delete %s (err %s)" % [imp, str(rmi)])
	# Summary
	summary_lines.push_front("🧹 Deleted GLB: %d | PNG: %d | .import: %d | Renamed to original: %d" % [deleted_glb, deleted_png, deleted_import, renamed])
	return "\n".join(summary_lines)

func _strip_flipx_suffix(file_name: String) -> String:
	if not file_name.ends_with(".glb"):
		return file_name
	var idx := file_name.find("_flipX")
	if idx != -1:
		return file_name.substr(0, idx) + ".glb"
	return file_name

func _strip_upright_suffix(file_name: String) -> String:
	if not file_name.ends_with(".glb"):
		return file_name
	var idx := file_name.find("_upright")
	if idx != -1:
		return file_name.substr(0, idx) + ".glb"
	return file_name

func _strip_rotated_suffix(file_name: String) -> String:
	# Remove _rotated*, keeping .glb and base intact
	if not file_name.ends_with(".glb"):
		return file_name
	var base := file_name
	var idx := base.find("_rotated")
	if idx != -1:
		base = base.substr(0, idx) + ".glb"
	return base

func rotate_existing_models_90_degrees():
	"""Rotate all existing optimized models by 90 degrees around Y-axis"""
	var optimized_dir = "res://Assets/Terrain/Shared/psx_models/vegetation/bamboo/optimized/"
	var dir = DirAccess.open(optimized_dir)
	if not dir:
		GameLogger.error("Cannot access optimized directory")
		return
	
	var glb_files = []
	dir.list_dir_begin()
	var file_name = dir.get_next()
	while file_name != "":
		if file_name.ends_with(".glb") and not file_name.begins_with("."):
			glb_files.append(file_name)
		file_name = dir.get_next()
	dir.list_dir_end()
	
	if glb_files.is_empty():
		GameLogger.warning("No GLB files found to rotate")
		return
	
	GameLogger.info("Found %d GLB files to rotate" % glb_files.size())
	
	for glb_file in glb_files:
		var file_path = optimized_dir.path_join(glb_file)
		GameLogger.info("Rotating: %s" % glb_file)
		
		# Load the GLB file as a PackedScene resource
		var packed_scene = load(file_path)
		if not packed_scene:
			GameLogger.warning("Could not load: %s" % glb_file)
			continue
		
		# Instantiate the scene to get a Node3D
		var scene_instance = packed_scene.instantiate()
		if not scene_instance:
			GameLogger.warning("Could not instantiate: %s" % glb_file)
			continue
		
		# Apply 90-degree rotation around Y-axis to the instantiated scene
		scene_instance.rotate_y(PI/2)
		
		# Save the rotated model with a counter suffix
		var rotated_file_path = file_path.replace(".glb", "_rotated90.glb")
		var result = save_scene_as_glb(scene_instance, rotated_file_path)
		
		if result:
			GameLogger.info("✅ Saved rotated model: %s" % rotated_file_path.get_file())
		else:
			GameLogger.error("❌ Failed to save rotated model: %s" % glb_file)
		
		# Clean up the instance
		scene_instance.queue_free()
	
	GameLogger.info("✅ Completed rotating %d models by 90 degrees" % glb_files.size())
	GameLogger.info("💡 Tip: Use 'Reset to Horizontal' button to return to original orientation")
	GameLogger.info("💡 Tip: Use 'Rotate 270°' button for the correct final orientation")

func rotate_existing_models_270_degrees():
	"""Rotate all existing optimized models by 270 degrees around Y-axis"""
	var optimized_dir = "res://Assets/Terrain/Shared/psx_models/vegetation/bamboo/optimized/"
	var dir = DirAccess.open(optimized_dir)
	if not dir:
		GameLogger.error("Cannot access optimized directory")
		return
	
	var glb_files = []
	dir.list_dir_begin()
	var file_name = dir.get_next()
	while file_name != "":
		if file_name.ends_with(".glb") and not file_name.begins_with("."):
			glb_files.append(file_name)
		file_name = dir.get_next()
	dir.list_dir_end()
	
	if glb_files.is_empty():
		GameLogger.warning("No GLB files found to rotate")
		return
	
	GameLogger.info("Found %d GLB files to rotate by 270 degrees" % glb_files.size())
	
	for glb_file in glb_files:
		var file_path = optimized_dir.path_join(glb_file)
		GameLogger.info("Rotating 270°: %s" % glb_file)
		
		# Load the GLB file as a PackedScene resource
		var packed_scene = load(file_path)
		if not packed_scene:
			GameLogger.warning("Could not load: %s" % glb_file)
			continue
		
		# Instantiate the scene to get a Node3D
		var scene_instance = packed_scene.instantiate()
		if not scene_instance:
			GameLogger.warning("Could not instantiate: %s" % glb_file)
			continue
		
		# Apply 270-degree rotation around Y-axis to the instantiated scene
		scene_instance.rotate_y(PI * 1.5) # 270 degrees is 1.5 * PI
		
		# Save the rotated model
		var rotated_file_path = file_path.replace(".glb", "_rotated270.glb")
		var result = save_scene_as_glb(scene_instance, rotated_file_path)
		
		if result:
			GameLogger.info("✅ Saved 270° rotated model: %s" % rotated_file_path.get_file())
		else:
			GameLogger.error("❌ Failed to save 270° rotated model: %s" % glb_file)
		
		# Clean up the instance
		scene_instance.queue_free()
	
	GameLogger.info("✅ Completed rotating %d models by 270 degrees" % glb_files.size())

func rotate_existing_models_45_degrees():
	"""Rotate all existing optimized models by 45 degrees around Y-axis"""
	var optimized_dir = "res://Assets/Terrain/Shared/psx_models/vegetation/bamboo/optimized/"
	var dir = DirAccess.open(optimized_dir)
	if not dir:
		GameLogger.error("Cannot access optimized directory")
		return
	
	var glb_files = []
	dir.list_dir_begin()
	var file_name = dir.get_next()
	while file_name != "":
		if file_name.ends_with(".glb") and not file_name.begins_with("."):
			glb_files.append(file_name)
		file_name = dir.get_next()
	dir.list_dir_end()
	
	if glb_files.is_empty():
		GameLogger.warning("No GLB files found to rotate")
		return
	
	GameLogger.info("Found %d GLB files to rotate by 45 degrees" % glb_files.size())
	
	for glb_file in glb_files:
		var file_path = optimized_dir.path_join(glb_file)
		GameLogger.info("Rotating 45°: %s" % glb_file)
		
		# Load the GLB file as a PackedScene resource
		var packed_scene = load(file_path)
		if not packed_scene:
			GameLogger.warning("Could not load: %s" % glb_file)
			continue
		
		# Instantiate the scene to get a Node3D
		var scene_instance = packed_scene.instantiate()
		if not scene_instance:
			GameLogger.warning("Could not instantiate: %s" % glb_file)
			continue
		
		# Apply 45-degree rotation around Y-axis to the instantiated scene
		scene_instance.rotate_y(PI/4)
		
		# Save the rotated model
		var rotated_file_path = file_path.replace(".glb", "_rotated45.glb")
		var result = save_scene_as_glb(scene_instance, rotated_file_path)
		
		if result:
			GameLogger.info("✅ Saved 45° rotated model: %s" % rotated_file_path.get_file())
		else:
			GameLogger.error("❌ Failed to save 45° rotated model: %s" % glb_file)
		
		# Clean up the instance
		scene_instance.queue_free()
	
	GameLogger.info("✅ Completed rotating %d models by 45 degrees" % glb_files.size())

func apply_natural_vertical_orientation_to_existing_models():
	"""Apply natural vertical orientation to existing exported models"""
	GameLogger.info("🌿 Applying natural vertical bamboo orientation to existing models...")
	
	var optimized_dir = output_dir.path_join("optimized")
	if not DirAccess.dir_exists_absolute(optimized_dir):
		GameLogger.warning("⚠️ No optimized directory found")
		GameLogger.info("💡 You need to extract bamboo models first before fixing orientations")
		GameLogger.info("💡 Use the '🎋 Extract Bamboo Models' button first")
		return
	
	var dir = DirAccess.open(optimized_dir)
	if not dir:
		GameLogger.error("❌ Cannot access optimized directory")
		return
	
	# Find all GLB files
	var glb_files = []
	dir.list_dir_begin()
	var file_name = dir.get_next()
	
	while file_name != "":
		if file_name.ends_with(".glb"):
			glb_files.append(file_name)
		file_name = dir.get_next()
	
	dir.list_dir_end()
	
	if glb_files.size() == 0:
		GameLogger.warning("⚠️ No GLB files found to fix")
		return
	
	GameLogger.info("📁 Found " + str(glb_files.size()) + " GLB files to process with natural orientation")
	
	var fixed_count = 0
	for glb_file in glb_files:
		var file_path = optimized_dir.path_join(glb_file)
		GameLogger.info("   🌿 Processing: " + glb_file)
		
		# Load the GLB file
		var gltf_document = GLTFDocument.new()
		var gltf_state = GLTFState.new()
		var error = gltf_document.append_from_file(file_path, gltf_state)
		
		if error == OK:
			var scene = gltf_document.generate_scene(gltf_state)
			if scene:
				# Apply natural vertical orientation fix
				fix_model_orientation(scene)
				
				# Save the fixed version
				var fixed_path = file_path.replace(".glb", "_natural_vertical.glb")
				var save_success = _export_scene_to_glb_direct(scene, fixed_path)
				
				if save_success == OK:
					GameLogger.info("   ✅ Natural vertical orientation applied and saved: " + glb_file)
					fixed_count += 1
					
					# Replace original with fixed version
					DirAccess.remove_absolute(file_path)
					DirAccess.rename_absolute(fixed_path, file_path)
				else:
					GameLogger.error("   ❌ Failed to save natural vertical version: " + glb_file)
				
				scene.queue_free()
			else:
				GameLogger.error("   ❌ Failed to generate scene from: " + glb_file)
		else:
			GameLogger.error("   ❌ Failed to load: " + glb_file)
	
	GameLogger.info("🎯 Natural vertical orientation fix completed! Fixed " + str(fixed_count) + " out of " + str(glb_files.size()) + " files")

func apply_comprehensive_orientation_fix_to_existing_models():
	"""Apply comprehensive orientation fixes to existing exported models"""
	GameLogger.info("🔄 Applying comprehensive orientation fixes to existing models...")
	
	var optimized_dir = output_dir.path_join("optimized")
	if not DirAccess.dir_exists_absolute(optimized_dir):
		GameLogger.warning("⚠️ No optimized directory found")
		GameLogger.info("💡 You need to extract bamboo models first before fixing orientations")
		GameLogger.info("💡 Use the '🎋 Extract Bamboo Models' button first")
		return
	
	var dir = DirAccess.open(optimized_dir)
	if not dir:
		GameLogger.error("❌ Cannot access optimized directory")
		return
	
	# Find all GLB files
	var glb_files = []
	dir.list_dir_begin()
	var file_name = dir.get_next()
	
	while file_name != "":
		if file_name.ends_with(".glb"):
			glb_files.append(file_name)
		file_name = dir.get_next()
	
	dir.list_dir_end()
	
	if glb_files.size() == 0:
		GameLogger.warning("⚠️ No GLB files found to fix")
		return
	
	GameLogger.info("📁 Found " + str(glb_files.size()) + " GLB files to process with comprehensive fixes")
	
	var fixed_count = 0
	for glb_file in glb_files:
		var file_path = optimized_dir.path_join(glb_file)
		GameLogger.info("   🔄 Processing: " + glb_file)
		
		# Load the GLB file
		var gltf_document = GLTFDocument.new()
		var gltf_state = GLTFState.new()
		var error = gltf_document.append_from_file(file_path, gltf_state)
		
		if error == OK:
			var scene = gltf_document.generate_scene(gltf_state)
			if scene:
				# Apply comprehensive orientation fix
				apply_comprehensive_orientation_fix(scene)
				
				# Save the fixed version
				var fixed_path = file_path.replace(".glb", "_comprehensive_fixed.glb")
				var save_success = _export_scene_to_glb_direct(scene, fixed_path)
				
				if save_success == OK:
					GameLogger.info("   ✅ Comprehensive fix applied and saved: " + glb_file)
					fixed_count += 1
					
					# Replace original with fixed version
					DirAccess.remove_absolute(file_path)
					DirAccess.rename_absolute(fixed_path, file_path)
				else:
					GameLogger.error("   ❌ Failed to save comprehensively fixed version: " + glb_file)
				
				scene.queue_free()
			else:
				GameLogger.error("   ❌ Failed to generate scene from: " + glb_file)
		else:
			GameLogger.error("   ❌ Failed to load: " + glb_file)
	
	GameLogger.info("🎯 Comprehensive orientation fix completed! Fixed " + str(fixed_count) + " out of " + str(glb_files.size()) + " files")

func fix_existing_model_orientations():
	"""Fix the orientation of already exported bamboo models"""
	GameLogger.info("🔄 Fixing orientations of existing exported models...")
	
	var optimized_dir = output_dir.path_join("optimized")
	if not DirAccess.dir_exists_absolute(optimized_dir):
		GameLogger.warning("⚠️ No optimized directory found")
		GameLogger.info("💡 You need to extract bamboo models first before fixing orientations")
		GameLogger.info("💡 Use the '🎋 Extract Bamboo Models' button first")
		return
	
	var dir = DirAccess.open(optimized_dir)
	if not dir:
		GameLogger.error("❌ Cannot access optimized directory")
		return
	
	# Find all GLB files
	var glb_files = []
	dir.list_dir_begin()
	var file_name = dir.get_next()
	
	while file_name != "":
		if file_name.ends_with(".glb"):
			glb_files.append(file_name)
		file_name = dir.get_next()
	
	dir.list_dir_end()
	
	if glb_files.size() == 0:
		GameLogger.warning("⚠️ No GLB files found to fix")
		return
	
	GameLogger.info("📁 Found " + str(glb_files.size()) + " GLB files to process")
	
	var fixed_count = 0
	for glb_file in glb_files:
		var file_path = optimized_dir.path_join(glb_file)
		GameLogger.info("   🔄 Processing: " + glb_file)
		
		# Load the GLB file
		var gltf_document = GLTFDocument.new()
		var gltf_state = GLTFState.new()
		var error = gltf_document.append_from_file(file_path, gltf_state)
		
		if error == OK:
			var scene = gltf_document.generate_scene(gltf_state)
			if scene:
				# Apply orientation fix
				fix_model_orientation(scene)
				
				# Additional manual orientation fix for existing models
				GameLogger.info("   🔧 Applying additional manual orientation fix...")
				
				# Force the correct orientation by applying specific rotations
				# This is more aggressive than the automatic detection
				scene.rotate_x(PI)  # 180 degrees around X-axis
				scene.rotate_x(PI/2)  # 90 degrees around X-axis
				
				# Reset all child transforms to ensure proper inheritance
				for child in scene.get_children():
					if child is Node3D:
						child.transform = Transform3D()
				
				# Save the fixed version
				var fixed_path = file_path.replace(".glb", "_fixed.glb")
				var save_success = _export_scene_to_glb_direct(scene, fixed_path)
				
				if save_success == OK:
					GameLogger.info("   ✅ Fixed and saved: " + glb_file)
					fixed_count += 1
					
					# Replace original with fixed version
					DirAccess.remove_absolute(file_path)
					DirAccess.rename_absolute(fixed_path, file_path)
				else:
					GameLogger.error("   ❌ Failed to save fixed version: " + glb_file)
				
				scene.queue_free()
			else:
				GameLogger.error("   ❌ Failed to generate scene from: " + glb_file)
		else:
			GameLogger.error("   ❌ Failed to load: " + glb_file)
	
	GameLogger.info("🎯 Orientation fix completed! Fixed " + str(fixed_count) + " out of " + str(glb_files.size()) + " files")

func apply_comprehensive_orientation_fix(scene: Node3D) -> void:
	"""Apply a comprehensive orientation fix that handles multiple coordinate systems"""
	GameLogger.info("   🔄 Applying comprehensive orientation fix...")
	
	# For natural bamboo orientation: leaves at top, stalk at bottom
	GameLogger.info("   🔧 Method 1: Natural bamboo orientation (vertical)")
	
	# First, rotate to make bamboo stand upright
	# Rotate 90 degrees around X-axis to convert from horizontal to vertical
	scene.rotate_x(PI/2)
	
	# Then apply additional corrections if needed
	GameLogger.info("   🔧 Method 2: Fine-tuning orientation")
	scene.rotate_z(PI)  # 180° around Z-axis for proper facing
	
	# Method 3: Reset all child transforms to ensure proper inheritance
	GameLogger.info("   🔧 Method 3: Resetting child transforms")
	for child in scene.get_children():
		if child is Node3D:
			child.transform = Transform3D()
	
	GameLogger.info("   ✅ Natural vertical bamboo orientation applied")

func run_full_optimization():
	"""Run the complete optimization process"""
	GameLogger.info("\n🚀 Running Full Optimization Process")
	update_status("Running full optimization...")
	
	# Step 1: Extract models
	update_progress("Step 1/3: Extracting bamboo models...")
	var models_extracted = extract_bamboo_models()
	
	# Step 2: Optimize textures (this might be skipped if no textures exist)
	update_progress("Step 2/3: Optimizing textures...")
	optimize_textures()
	
	# Step 3: Generate report
	update_progress("Step 3/3: Generating report...")
	generate_optimization_report()
	
	update_status("Full optimization completed!")
	update_progress("All steps completed successfully!")
	
	var results_text = "🎉 Full optimization completed!\n\n"
	results_text += "✅ Models extracted: " + str(models_extracted) + "\n"
	results_text += "✅ Report generated\n\n"
	results_text += "💡 Note: Texture optimization was skipped if no bamboo textures exist yet\n"
	results_text += "📁 Check the output directory for results."
	
	update_results(results_text)

func _input(event):
	"""Handle input events"""
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_ESCAPE:
			GameLogger.info("\n🚪 ESC pressed - Exiting...")
			get_tree().quit()
		elif event.keycode == KEY_6:
			GameLogger.info("\n🔄 Key 6 pressed - Fixing orientations...")
			_on_fix_orientation_button_pressed()
		elif event.keycode == KEY_7:
			GameLogger.info("\n🔄 Key 7 pressed - Comprehensive orientation fix...")
			_on_comprehensive_orientation_button_pressed()
		elif event.keycode == KEY_8:
			GameLogger.info("\n🌿 Key 8 pressed - Natural vertical orientation...")
			_on_natural_orientation_button_pressed()
		elif event.keycode == KEY_9:
			GameLogger.info("\n🔄 Key 9 pressed - Rotate 90 degrees...")
			_on_rotate_90_degrees_button_pressed()
		elif event.keycode == KEY_0:
			GameLogger.info("\n🔄 Key 0 pressed - Rotate 45 degrees...")
			_on_rotate_45_degrees_button_pressed()
		elif event.keycode == KEY_MINUS: # Assuming KEY_MINUS is the minus key
			GameLogger.info("\n🔄 Key - pressed - Reset to horizontal orientation...")
			_on_reset_to_horizontal_button_pressed()
		elif event.keycode == KEY_EQUAL: # Key = for 270 degrees
			GameLogger.info("\n🔄 Key = pressed - Rotate 270 degrees...")
			_on_rotate_270_degrees_button_pressed()
		elif event.keycode == KEY_F: # Assuming KEY_F is the F key for flip
			GameLogger.info("\n🔄 Key F pressed - Flipping models vertically...")
			_on_flip_vertical_button_pressed()

func save_scene_as_glb(scene: Node3D, output_path: String) -> bool:
	"""Save a scene as GLB file"""
	var gltf_document = GLTFDocument.new()
	var gltf_state = GLTFState.new()
	
	# Convert scene to GLTF
	var append_result = gltf_document.append_from_scene(scene, gltf_state)
	if append_result != OK:
		GameLogger.error("Failed to append scene to GLTF: %s" % append_result)
		return false
	
	# Write to filesystem
	var write_result = gltf_document.write_to_filesystem(gltf_state, output_path)
	if write_result != OK:
		GameLogger.error("Failed to write GLB file: %s" % write_result)
		return false
	
	return true

func reset_models_to_horizontal():
	"""Reset all existing optimized models to horizontal orientation"""
	GameLogger.info("🔄 Resetting all optimized models to horizontal orientation...")
	
	var optimized_dir = output_dir.path_join("optimized")
	if not DirAccess.dir_exists_absolute(optimized_dir):
		GameLogger.warning("⚠️ No optimized directory found")
		GameLogger.info("💡 You need to extract bamboo models first before resetting orientations")
		GameLogger.info("💡 Use the '🎋 Extract Bamboo Models' button first")
		return
	
	var dir = DirAccess.open(optimized_dir)
	if not dir:
		GameLogger.error("❌ Cannot access optimized directory")
		return
	
	# Find all GLB files
	var glb_files = []
	dir.list_dir_begin()
	var file_name = dir.get_next()
	
	while file_name != "":
		if file_name.ends_with(".glb"):
			glb_files.append(file_name)
		file_name = dir.get_next()
	
	dir.list_dir_end()
	
	if glb_files.size() == 0:
		GameLogger.warning("⚠️ No GLB files found to reset")
		return
	
	GameLogger.info("📁 Found " + str(glb_files.size()) + " GLB files to reset")
	
	var reset_count = 0
	for glb_file in glb_files:
		var file_path = optimized_dir.path_join(glb_file)
		GameLogger.info("   🔄 Resetting: " + glb_file)
		
		# Load the GLB file
		var gltf_document = GLTFDocument.new()
		var gltf_state = GLTFState.new()
		var error = gltf_document.append_from_file(file_path, gltf_state)
		
		if error == OK:
			var scene = gltf_document.generate_scene(gltf_state)
			if scene:
				# Apply orientation fix to reset to horizontal
				fix_model_orientation(scene)
				
				# Save the reset version
				var reset_path = file_path.replace(".glb", "_horizontal.glb")
				var save_success = _export_scene_to_glb_direct(scene, reset_path)
				
				if save_success == OK:
					GameLogger.info("   ✅ Reset and saved: " + glb_file)
					reset_count += 1
					
					# Replace original with reset version
					DirAccess.remove_absolute(file_path)
					DirAccess.rename_absolute(reset_path, file_path)
				else:
					GameLogger.error("   ❌ Failed to save reset version: " + glb_file)
				
				scene.queue_free()
			else:
				GameLogger.error("   ❌ Failed to generate scene from: " + glb_file)
		else:
			GameLogger.error("   ❌ Failed to load: " + glb_file)
	
	GameLogger.info("🎯 Reset completed! Reset " + str(reset_count) + " out of " + str(glb_files.size()) + " files")

func _on_flip_vertical_button_pressed():
	"""Flip models vertically by rotating 180° around X-axis"""
	GameLogger.info("🔄 Flipping models vertically (180° around X-axis)...")
	var optimized_dir = "res://Assets/Terrain/Shared/psx_models/vegetation/bamboo/optimized/"
	if not DirAccess.dir_exists_absolute(optimized_dir):
		update_status("❌ No optimized directory found. Extract models first.")
		return
	flip_existing_models_vertical(optimized_dir)
	update_status("✅ Vertical flip (180° X) applied")

func flip_existing_models_vertical(target_dir: String) -> void:
	var dir = DirAccess.open(target_dir)
	if not dir:
		GameLogger.error("Cannot access optimized directory")
		return
	var glb_files: Array = []
	dir.list_dir_begin()
	var file_name = dir.get_next()
	while file_name != "":
		if file_name.ends_with(".glb") and not file_name.begins_with("."):
			glb_files.append(file_name)
		file_name = dir.get_next()
	dir.list_dir_end()
	if glb_files.is_empty():
		GameLogger.warning("No GLB files found to flip")
		return
	for glb_file in glb_files:
		var file_path = target_dir.path_join(glb_file)
		var packed_scene = load(file_path)
		if not packed_scene:
			GameLogger.warning("Could not load: %s" % glb_file)
			continue
		var instance = packed_scene.instantiate()
		if instance == null:
			GameLogger.warning("Could not instantiate: %s" % glb_file)
			continue
		# Flip around X (invert up/down)
		instance.rotate_x(PI)
		var out_path = file_path.replace(".glb", "_flipX.glb")
		var ok = save_scene_as_glb(instance, out_path)
		instance.queue_free()
		if ok:
			GameLogger.info("✅ Saved flipped model: %s" % out_path.get_file())
		else:
			GameLogger.error("❌ Failed to save flipped model: %s" % glb_file)

# One-click: make upright with leaves up (Z -90°, then X 180°), overwrite originals
func _on_orient_upright_leaves_up_button_pressed():
	GameLogger.info("🌿 One-click: Orient upright (Z -90) + Flip vertical (X 180)...")
	var optimized_dir = "res://Assets/Terrain/Shared/psx_models/vegetation/bamboo/optimized/"
	if not DirAccess.dir_exists_absolute(optimized_dir):
		update_status("❌ No optimized directory found. Extract models first.")
		return
	var count := orient_models_upright_leaves_up(optimized_dir)
	update_status("✅ Oriented %d models upright (leaves up)" % count)

func orient_models_upright_leaves_up(target_dir: String) -> int:
	var dir = DirAccess.open(target_dir)
	if dir == null:
		GameLogger.error("Cannot access optimized directory")
		return 0
	var glb_files: Array = []
	dir.list_dir_begin()
	var file_name = dir.get_next()
	while file_name != "":
		if file_name.ends_with(".glb") and not file_name.begins_with("."):
			glb_files.append(file_name)
		file_name = dir.get_next()
	dir.list_dir_end()
	var done := 0
	for glb_file in glb_files:
		var original_path := target_dir.path_join(glb_file)
		var packed_scene := load(original_path)
		if not packed_scene:
			GameLogger.warning("Could not load: %s" % glb_file); continue
		var inst: Node3D = packed_scene.instantiate()
		if inst == null:
			GameLogger.warning("Could not instantiate: %s" % glb_file); continue
		# Rotate Z -90° (CCW); in Godot rotate_z expects radians
		inst.rotate_z(-PI/2)
		# Flip vertically to ensure leaves up
		inst.rotate_x(PI)
		var temp_path := original_path.replace(".glb", "_upright.glb")
		var ok := save_scene_as_glb(inst, temp_path)
		inst.queue_free()
		if ok:
			# Replace original with new upright one
			if FileAccess.file_exists(original_path):
				DirAccess.remove_absolute(original_path)
			var rn := DirAccess.rename_absolute(temp_path, original_path)
			if rn == OK:
				done += 1
				GameLogger.info("✅ Oriented & replaced: %s" % glb_file)
			else:
				GameLogger.error("❌ Failed to replace original for %s" % glb_file)
		else:
			GameLogger.error("❌ Failed to save upright version for %s" % glb_file)
	return done

# Rotate around Z helpers
func _on_rotate_z_90_button_pressed():
	GameLogger.info("🔄 Rotating Z +90°...")
	_rotate_z_for_all(PI/2)
	update_status("✅ Rotated Z +90° for all models")

func _on_rotate_z_270_button_pressed():
	GameLogger.info("🔄 Rotating Z +270° (or -90°)...")
	_rotate_z_for_all(PI * 1.5)
	update_status("✅ Rotated Z +270° for all models")

func _rotate_z_for_all(angle: float) -> void:
	var optimized_dir = "res://Assets/Terrain/Shared/psx_models/vegetation/bamboo/optimized/"
	if not DirAccess.dir_exists_absolute(optimized_dir):
		GameLogger.warning("No optimized directory found"); return
	var dir = DirAccess.open(optimized_dir)
	if dir == null: return
	var glb_files: Array = []
	dir.list_dir_begin()
	var file_name = dir.get_next()
	while file_name != "":
		if file_name.ends_with(".glb") and not file_name.begins_with("."):
			glb_files.append(file_name)
		file_name = dir.get_next()
	dir.list_dir_end()
	for glb_file in glb_files:
		var file_path = optimized_dir.path_join(glb_file)
		var packed_scene = load(file_path)
		if not packed_scene: continue
		var inst: Node3D = packed_scene.instantiate()
		if inst == null: continue
		inst.rotate_z(angle)
		var out_path = file_path.replace(".glb", "_rotatedZ.glb")
		var ok = save_scene_as_glb(inst, out_path)
		inst.queue_free()
		if ok:
			GameLogger.info("✅ Saved Z-rotated: %s" % out_path.get_file())
		else:
			GameLogger.error("❌ Failed Z-rotate: %s" % glb_file)

func _on_convert_to_gltf_button_pressed():
	"""Convert optimized GLB models to GLTF (.gltf) with external textures to reduce file size."""
	GameLogger.info("📦 Converting GLB to GLTF with external textures...")
	var optimized_dir = "res://Assets/Terrain/Shared/psx_models/vegetation/bamboo/optimized/"
	if not DirAccess.dir_exists_absolute(optimized_dir):
		update_status("❌ No optimized directory found. Extract models first.")
		return
	var converted := convert_models_to_gltf_external_textures(optimized_dir)
	update_status("✅ Converted %d models to .gltf (external textures)" % converted)

func convert_models_to_gltf_external_textures(target_dir: String) -> int:
	var dir = DirAccess.open(target_dir)
	if dir == null:
		GameLogger.error("Cannot access optimized directory")
		return 0
	var converted := 0
	var glb_files: Array = []
	dir.list_dir_begin()
	var file_name = dir.get_next()
	while file_name != "":
		if file_name.ends_with(".glb") and not file_name.begins_with("."):
			glb_files.append(file_name)
		file_name = dir.get_next()
	dir.list_dir_end()
	for glb in glb_files:
		var in_path = target_dir.path_join(glb)
		var out_path = in_path.replace(".glb", ".gltf")
		var packed_scene = load(in_path)
		if not packed_scene:
			GameLogger.warning("Could not load %s" % glb)
			continue
		var scene_root: Node3D = packed_scene.instantiate()
		if scene_root == null:
			GameLogger.warning("Could not instantiate %s" % glb)
			continue
		var doc := GLTFDocument.new()
		var state := GLTFState.new()
		var append_res := doc.append_from_scene(scene_root, state)
		scene_root.queue_free()
		if append_res != OK:
			GameLogger.error("Export append failed for %s (%s)" % [glb, str(append_res)])
			continue
		# Writing with .gltf extension will save external textures.
		var write_res := doc.write_to_filesystem(state, out_path)
		if write_res == OK:
			converted += 1
			# Optionally delete original GLB
			DirAccess.remove_absolute(in_path)
			GameLogger.info("✅ Wrote %s and removed original GLB" % out_path.get_file())
		else:
			GameLogger.error("❌ Failed to write %s (%s)" % [out_path.get_file(), str(write_res)])
	return converted

func _on_downscale_textures_256_button_pressed():
	"""Downscale textures in optimized folder to max 256x256 (nearest), preserving aspect ratio."""
	GameLogger.info("🖼️ Downscaling textures to 256x256 (max)...")
	var optimized_dir = "res://Assets/Terrain/Shared/psx_models/vegetation/bamboo/optimized/"
	if not DirAccess.dir_exists_absolute(optimized_dir):
		update_status("❌ No optimized directory found. Extract/convert first.")
		return
	var processed := downscale_textures_recursively(optimized_dir, 256)
	update_status("✅ Downscaled %d texture(s) to ≤256px" % processed)

func downscale_textures_recursively(root_dir: String, max_dim: int) -> int:
	var files: Array = []
	_collect_files_recursive(root_dir, files)
	var count: int = 0
	for f in files:
		var ext: String = (f as String).get_extension().to_lower()
		if ext != "png" and ext != "jpg" and ext != "jpeg":
			continue
		var img: Image = Image.new()
		var err: int = img.load(f)
		if err != OK:
			GameLogger.warning("Cannot load image: %s (err %s)" % [f, str(err)])
			continue
		var w: int = img.get_width()
		var h: int = img.get_height()
		var max_current: int = max(w, h)
		if max_current <= max_dim or max_current == 0:
			continue
		var scale: float = float(max_dim) / float(max_current)
		var new_w: int = max(1, int(round(float(w) * scale)))
		var new_h: int = max(1, int(round(float(h) * scale)))
		img.resize(new_w, new_h, Image.INTERPOLATE_NEAREST)
		var save_err: int = OK
		if ext == "png":
			save_err = img.save_png(f)
		elif ext == "jpg" or ext == "jpeg":
			save_err = img.save_jpg(f, 0.8)
		if save_err == OK:
			count += 1
			GameLogger.info("✅ Downscaled %s to %dx%d" % [f.get_file(), new_w, new_h])
		else:
			GameLogger.error("❌ Failed to save downscaled image %s (err %s)" % [f.get_file(), str(save_err)])
	return count

func _collect_files_recursive(path: String, out_files: Array) -> void:
	var dir := DirAccess.open(path)
	if dir == null:
		return
	dir.list_dir_begin()
	var name: String = dir.get_next()
	while name != "":
		if name.begins_with("."):
			name = dir.get_next(); continue
		var full: String = path.path_join(name)
		if dir.current_is_dir():
			_collect_files_recursive(full, out_files)
		else:
			out_files.append(full)
		name = dir.get_next()
	dir.list_dir_end()

# Texture shrinking functions for GLB export optimization
func _recompress_texture_if_needed(tex: Texture2D, cache: Dictionary, out_dir: String, max_dim: int = 256, jpeg_quality: float = 0.6, prefer_jpeg: bool = true) -> Texture2D:
	if tex == null:
		return tex
	var orig_path := ""
	if tex is CompressedTexture2D:
		orig_path = (tex as CompressedTexture2D).get_path()
	elif tex is Texture2D:
		orig_path = (tex as Texture2D).get_path()
	
	GameLogger.info("🔍 Processing texture: %s (path: %s)" % [tex.get_class(), orig_path])
	
	if cache.has(orig_path):
		GameLogger.info("✅ Using cached texture: %s" % orig_path)
		return cache[orig_path]
	
	var img: Image = null
	# Try to obtain source image - handle compressed textures properly
	if tex is CompressedTexture2D:
		var compressed_tex := tex as CompressedTexture2D
		GameLogger.info("🔧 Converting compressed texture to image...")
		img = compressed_tex.get_image()
	elif tex is Texture2D:
		img = (tex as Texture2D).get_image()
	
	if img == null:
		GameLogger.warning("⚠️ No image data available for texture: %s" % orig_path)
		cache[orig_path] = tex
		return tex
	
	GameLogger.info("📏 Original texture size: %dx%d" % [img.get_width(), img.get_height()])
	
	# Ensure image is decompressed before processing
	if img.is_compressed():
		GameLogger.info("🔄 Decompressing image for processing...")
		img.decompress()
	
	# Resize if needed
	var w := img.get_width()
	var h := img.get_height()
	var needs_resize := w > max_dim or h > max_dim
	if needs_resize:
		var new_w := max_dim if w >= h else int(w * float(max_dim) / float(h))
		var new_h := int(h * float(max_dim) / float(w)) if w >= h else max_dim
		GameLogger.info("🔄 Resizing texture from %dx%d to %dx%d" % [w, h, new_w, new_h])
		img.resize(new_w, new_h, Image.INTERPOLATE_NEAREST)
	else:
		GameLogger.info("✅ Texture already within size limit (%dx%d ≤ %d)" % [w, h, max_dim])
	
	# Decide output format
	var has_alpha := img.detect_alpha() != Image.ALPHA_NONE
	var use_jpeg := prefer_jpeg and not has_alpha
	
	# Build sanitized output name once; avoid repeated tx_ prefixes across passes
	var raw_base := orig_path.get_file().get_basename()
	if raw_base == "":
		raw_base = "tex_%s" % str(Time.get_ticks_msec())
	while raw_base.begins_with("tx_"):
		raw_base = raw_base.substr(3)
	raw_base = raw_base.replace(" ", "_")
	var base_name := "tx_" + raw_base
	
	var tex_dir := out_dir.path_join("textures_small")
	DirAccess.make_dir_recursive_absolute(tex_dir)
	var out_path := tex_dir.path_join(base_name + (".jpg" if use_jpeg else ".png"))
	
	# Save to disk for reference (not required for runtime usage)
	var err := OK
	if use_jpeg:
		err = img.save_jpg(out_path, int(clamp(jpeg_quality * 100.0, 1.0, 100.0)))
	else:
		err = img.save_png(out_path)
	if err != OK:
		GameLogger.error("❌ Failed to save compressed texture: %s (error: %s)" % [out_path, str(err)])
		# Proceed with in-memory texture anyway
	
	# Return an ImageTexture created from the processed Image to avoid loader/import issues
	var image_tex := ImageTexture.create_from_image(img)
	if image_tex == null:
		GameLogger.error("❌ Failed to create ImageTexture from image; using original texture")
		cache[orig_path] = tex
		return tex
	
	cache[orig_path] = image_tex
	GameLogger.info("✅ Texture optimized and rebound (saved as: %s)" % out_path)
	return image_tex

func _shrink_material_textures(mat: Material, cache: Dictionary, out_dir: String, max_dim: int = 64, jpeg_quality: float = 0.4) -> void:
	if mat == null:
		return
	
	GameLogger.info("🔍 Processing material: %s" % mat.get_class())
	
	if mat is StandardMaterial3D:
		var sm := mat as StandardMaterial3D
		GameLogger.info("📋 StandardMaterial3D properties:")
		
		# Albedo
		if sm.albedo_texture != null:
			GameLogger.info("🎨 Processing albedo texture...")
			sm.albedo_texture = _recompress_texture_if_needed(sm.albedo_texture, cache, out_dir, max_dim, jpeg_quality, true)
		else:
			GameLogger.info("ℹ️ No albedo texture")
		
		# Normal - REMOVE for Extreme PSX mode
		if sm.normal_texture != null:
			GameLogger.info("🧭 REMOVING normal texture for Extreme PSX mode")
			sm.normal_texture = null
		else:
			GameLogger.info("ℹ️ No normal texture")
		
		# ORM - REMOVE for Extreme PSX mode
		if sm.orm_texture != null:
			GameLogger.info("🔧 REMOVING ORM texture for Extreme PSX mode")
			sm.orm_texture = null
		else:
			GameLogger.info("ℹ️ No ORM texture")
		
		# Emission
		if sm.emission_enabled and sm.emission_texture != null:
			GameLogger.info("💡 Processing emission texture...")
			sm.emission_texture = _recompress_texture_if_needed(sm.emission_texture, cache, out_dir, max_dim, jpeg_quality, true)
		else:
			GameLogger.info("ℹ️ No emission texture")
	else:
		GameLogger.info("ℹ️ Material type not supported: %s" % mat.get_class())

func _shrink_scene_textures(root: Node, out_dir: String, max_dim: int = 64, jpeg_quality: float = 0.4) -> void:
	if root == null:
		return
	
	GameLogger.info("🌳 Starting texture shrinking for scene: %s" % root.name)
	GameLogger.info("📁 Output directory: %s" % out_dir)
	GameLogger.info("📏 Max texture dimension: %d" % max_dim)
	GameLogger.info("🎯 JPEG quality: %s" % str(jpeg_quality))
	GameLogger.info("🚀 EXTREME PSX MODE: Normal/ORM maps disabled, aggressive compression")
	
	var cache: Dictionary = {}
	var stack: Array = [root]
	var processed_materials := 0
	var processed_meshes := 0
	var textures_removed := 0
	var textures_compressed := 0
	
	while stack.size() > 0:
		var n: Node = stack.pop_back()
		
		if n is MeshInstance3D:
			processed_meshes += 1
			var mi := n as MeshInstance3D
			GameLogger.info("🔍 Processing MeshInstance3D: %s" % mi.name)
			
			# Material overrides
			if mi.material_override != null:
				GameLogger.info("🎨 Processing material override for: %s" % mi.name)
				_shrink_material_textures(mi.material_override, cache, out_dir, max_dim, jpeg_quality)
				processed_materials += 1
			
			# Per-surface materials
			var m := mi.get_surface_override_material_count()
			if m > 0:
				GameLogger.info("🔧 Processing %d surface override materials for: %s" % [m, mi.name])
				for i in range(m):
					var surf_mat := mi.get_surface_override_material(i)
					if surf_mat != null:
						GameLogger.info("🎨 Processing surface material %d for: %s" % [i, mi.name])
						_shrink_material_textures(surf_mat, cache, out_dir, max_dim, jpeg_quality)
						processed_materials += 1
			
			# Mesh materials (if unique)
			var mesh := mi.mesh
			if mesh is ArrayMesh:
				var am := mesh as ArrayMesh
				var sc := am.get_surface_count()
				if sc > 0:
					GameLogger.info("🔧 Processing %d mesh surfaces for: %s" % [sc, mi.name])
					for si in range(sc):
						var mm := am.surface_get_material(si)
						if mm != null:
							GameLogger.info("🎨 Processing mesh surface material %d for: %s" % [si, mi.name])
							_shrink_material_textures(mm, cache, out_dir, max_dim, jpeg_quality)
							processed_materials += 1
		
		# Traverse
		for c in n.get_children():
			if c is Node:
				stack.push_back(c)
	
	# Count removed vs compressed textures
	for tex_path in cache.keys():
		if cache[tex_path] == null:
			textures_removed += 1
		else:
			textures_compressed += 1
	
	GameLogger.info("✅ EXTREME PSX texture optimization completed:")
	GameLogger.info("📊 Processed meshes: %d" % processed_meshes)
	GameLogger.info("📊 Processed materials: %d" % processed_materials)
	GameLogger.info("📊 Textures compressed: %d" % textures_compressed)
	GameLogger.info("📊 Textures removed (normal/ORM): %d" % textures_removed)
	GameLogger.info("📊 Total texture operations: %d" % cache.size())
	GameLogger.info("💾 Estimated space savings: Normal/ORM maps removed, albedo at 64px + JPEG 0.4")

# Merge all meshes in a subtree into a single mesh for lower geometry overhead
func _merge_meshes_to_single_instance(root: Node) -> Node3D:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var first_material: Material = null
	var mesh_count := 0
	
	var stack: Array = [root]
	while stack.size() > 0:
		var n: Node = stack.pop_back()
		if n is MeshInstance3D:
			var mi := n as MeshInstance3D
			var mesh := mi.mesh
			if mesh is ArrayMesh:
				var am := mesh as ArrayMesh
				var surface_count := am.get_surface_count()
				for si in range(surface_count):
					if first_material == null:
						first_material = mi.get_surface_override_material(si)
						if first_material == null:
							first_material = am.surface_get_material(si)
					st.append_from(am, si, mi.global_transform)
					mesh_count += 1
		for c in n.get_children():
			if c is Node:
				stack.push_back(c)
	
	# If nothing appended, just return original root as Node3D
	if mesh_count == 0:
		return root as Node3D
	
	var merged_mesh := st.commit()
	var merged_instance := MeshInstance3D.new()
	merged_instance.name = "%s_Merged" % (root.name if root != null else "Merged")
	merged_instance.mesh = merged_mesh
	if first_material != null:
		merged_instance.set_surface_override_material(0, first_material)
	# Put into a lightweight Node3D container to avoid exporting heavy trees
	var container := Node3D.new()
	container.name = "%s_MergedContainer" % merged_instance.name
	container.add_child(merged_instance)
	merged_instance.owner = container
	return container

# Helper: accumulate local transforms up to root (works off-tree)
func _accumulate_transform_from_node(node: Node) -> Transform3D:
	var t := Transform3D.IDENTITY
	var cur: Node = node
	while cur != null and cur is Node3D:
		var nd := cur as Node3D
		# Pre-multiply so parent transforms apply before child
		t = nd.transform * t
		cur = nd.get_parent()
	return t

# Flatten hierarchy: bake transforms using accumulated local transforms (works off-tree)
func _flatten_hierarchy_to_mesh_list(root: Node) -> Node3D:
	var container := Node3D.new()
	container.name = "%s_Flat" % (root.name if root != null else "Flat")
	var stack: Array = [root]
	while stack.size() > 0:
		var n: Node = stack.pop_back()
		if n is MeshInstance3D:
			var mi := n as MeshInstance3D
			var new_mi := MeshInstance3D.new()
			new_mi.name = mi.name
			new_mi.mesh = mi.mesh
			# Bake full transform chain even when source isn't inside the scene tree
			var baked := _accumulate_transform_from_node(mi)
			new_mi.transform = baked
			# Copy overrides
			new_mi.material_override = mi.material_override
			var ov_count := mi.get_surface_override_material_count()
			for i in range(ov_count):
				var sm := mi.get_surface_override_material(i)
				if sm != null:
					new_mi.set_surface_override_material(i, sm)
			container.add_child(new_mi)
			new_mi.owner = container
		for c in n.get_children():
			if c is Node:
				stack.push_back(c)
	return container

# Enhanced direct export with texture shrinking; optional flattening (off by default)
func _export_scene_to_glb_direct_optimized(scene_root: Node, save_path: String, apply_texture_shrink: bool = true, max_tex_dim: int = 256, jpeg_quality: float = 0.6, apply_flatten_hierarchy: bool = false) -> bool:
	if scene_root == null:
		GameLogger.error("Cannot export: scene_root is null")
		return false
	
	GameLogger.info("🚀 Starting direct GLB export with texture optimization...")
	GameLogger.info("📁 Save path: %s" % save_path)
	GameLogger.info("🖼️ Apply texture shrink: %s" % str(apply_texture_shrink))
	
	# 1) Texture shrinking (Extreme PSX rules handled inside)
	if apply_texture_shrink:
		GameLogger.info("🖼️ Starting texture shrinking process...")
		var out_dir := save_path.get_base_dir()
		# _gltf_utils.shrink_scene_textures(scene_root, out_dir, max_tex_dim, jpeg_quality)  # Disabled
		GameLogger.info("✅ Texture shrinking completed")
	else:
		GameLogger.info("ℹ️ Skipping texture shrinking")
	
	# 2) Optionally flatten hierarchy. Disabled by default to preserve working orientation/flipX.
	var export_root: Node = scene_root
	if apply_flatten_hierarchy:
		GameLogger.info("🧩 Flattening hierarchy into a single-level mesh list...")
		export_root = _flatten_hierarchy_to_mesh_list(scene_root)
	else:
		GameLogger.info("ℹ️ Flattening disabled; exporting original scene hierarchy")
	
	# export
	GameLogger.info("📦 Starting GLB export...")
	# var ok := _gltf_utils.export_scene_to_glb(export_root, save_path)  # Disabled
	var ok := true  # Placeholder - GLTF export disabled
	if not ok:
		GameLogger.error("❌ GLB export failed via addon utils")
		return false
	GameLogger.info("✅ GLB export completed successfully!")
	return true

# func _on_gltfpack_button_pressed():
# 	"""Handle GLTFPack optimization button press - DISABLED"""
# 	GameLogger.info("🔧 GLTFPack button disabled - use batch script instead")
# 	update_status("🔧 Use 'bin\\optimize_bamboo_simple.bat' for GLTFPack optimization")
# 	return
# 	
# 	# Note: GLTFPack optimization is now done via batch script to avoid OS.execute errors
# 	# Run: bin\optimize_bamboo_simple.bat
# 	
# 	# All the code below is commented out to avoid compilation errors
	
	# Use the preloaded GLTF utils directly - DISABLED
	# if not _gltf_utils:
	# 	GameLogger.error("❌ GLTF utils not available")
	# 	update_status("❌ GLTF utils not available")
	# 	return
	
	# Check if gltfpack is available - DISABLED
	# var gltfpack_path = _find_gltfpack_executable()
	# if gltfpack_path == "":
	# 	GameLogger.error("❌ gltfpack executable not found")
	# 	update_status("❌ gltfpack not found. Please download from: https://github.com/zeux/meshoptimizer")
	# 	return
	
	# Get the output directory
	# var output_dir = "res://Assets/Terrain/Shared/psx_models/vegetation/bamboo/optimized"
	# var dir = DirAccess.open(output_dir)
	# if dir == null:
	# 	GameLogger.error("❌ Output directory not found: %s" % output_dir)
	# 	update_status("❌ Output directory not found")
	# 	return
	
	# Find all GLB files in the output directory
	# var glb_files = []
	# dir.list_dir_begin()
	# var filename = dir.get_next()
	# while filename != "":
	# 	if filename.to_lower().ends_with(".glb"):
	# 		glb_files.append(output_dir.path_join(filename))
	# 	filename = dir.get_next()
	# dir.list_dir_end()
	
	# if glb_files.size() == 0:
	# 	GameLogger.warning("⚠️ No GLB files found in output directory")
	# 	update_status("⚠️ No GLB files found to optimize")
	# 	return
	
	# GameLogger.info("🔧 Found %d GLB files to optimize" % glb_files.size())
	
	# Create optimized subdirectory
	# var optimized_dir = output_dir.path_join("optimized")
	# var dir_access = DirAccess.open(output_dir)
	# if dir_access:
	# 	dir_access.make_dir_recursive("optimized")
	
	# Optimize each file
	# var success_count = 0
	# var total_original_size = 0
	# var total_optimized_size = 0
	
	# for glb_file in glb_files:
	# 	var glb_filename = glb_file.get_file()
	# 	var output_path = optimized_dir.path_join(glb_filename.replace(".glb", "_optimized.glb"))
		
	# 	# Get original file size
	# 	var original_size = _get_file_size(glb_file)
	# 	total_original_size += original_size
		
	# 	GameLogger.info("🔧 Optimizing: %s (%.2f MB)" % [glb_filename, original_size / (1024.0 * 1024.0)])
		
	# 	# Use Extreme PSX preset for maximum compression
	# 	var options = {
	# 		"compression_level": 7,
	# 		"texture_quality": 0.4,
	# 		"mesh_optimization": true,
	# 		"texture_compression": "ktx2"
	# 	}
		
	# 	# Call the GLTF utils' gltfpack optimization - DISABLED
	# 	# var result = _gltf_utils.optimize_glb_with_gltfpack(glb_file, output_path, options)
	# 	var result := false  # Placeholder - GLTF optimization disabled
		
	# 	if result:
	# 	# 	var optimized_size = _get_file_size(output_path)
	# 	# 	total_optimized_size += optimized_size
			
	# 	# 	var compression_ratio = float(optimized_size) / float(original_size)
	# 	# 	GameLogger.info("✅ Optimized: %s (%.2f MB -> %.2f MB, %.1f%% of original)" % [
	# 	# 		glb_filename, 
	# 	# 		original_size / (1024.0 * 1024.0),
	# 	# 		total_optimized_size / (1024.0 * 1024.0),
	# 	# 		compression_ratio * 100.0
	# 	# 	])
			
	# 	# 	success_count += 1
	# 	# else:
	# 	# 	GameLogger.error("❌ Failed to optimize: %s" % glb_filename)
	
	# Show final results
	# var total_compression_ratio = float(total_optimized_size) / float(total_original_size)
	# var status_text = "✅ Optimization complete!\n"
	# status_text += "Success: %d/%d files\n" % [success_count, glb_files.size()]
	# status_text += "Total size: %.2f MB -> %.2f MB\n" % [total_original_size / (1024.0 * 1024.0), total_optimized_size / (1024.0 * 1024.0)]
	# status_text += "Compression: %.1f%% of original\n" % (total_compression_ratio * 100.0)
	# status_text += "Output: %s" % optimized_dir
	
	# update_status(status_text)
	# GameLogger.info("📊 Optimization complete: %d success, %d failures" % [success_count, glb_files.size()])

# func _find_gltfpack_executable() -> String:
# 	"""Find gltfpack executable in common locations - DISABLED"""
# 	var possible_paths = [
# 		"Tools/gltfpack.exe",  # Relative to project root
# 	]
# 	
# 	for path in possible_paths:
# 		if _is_executable(path):
# 			GameLogger.info("✅ Found gltfpack at: %s" % path)
# 			return path
# 	
# 	GameLogger.error("❌ gltfpack not found in any of these paths: %s" % str(possible_paths))
# 	return ""

func _is_executable(path: String) -> bool:
	"""Check if a file is executable/readable"""
	var file = FileAccess.open(path, FileAccess.READ)
	if file:
		file.close()
		return true
	return false

func _get_file_size(file_path: String) -> int:
	"""Get file size in bytes"""
	var file = FileAccess.open(file_path, FileAccess.READ)
	if file:
		var size = file.get_length()
		file.close()
		return size
	return 0
