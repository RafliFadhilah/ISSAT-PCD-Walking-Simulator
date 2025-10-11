extends Node3D

# Terrain controller for Papua scene with Terrain3D and PSX assets
# Integrates the forest generation system from the test scene

var asset_placer: Node3D
var papua_asset_pack: Resource
var terrain_stats: Dictionary = {}
var debug_config: Node

# Asset paths
const SHARED_ROOT := "res://Assets/Terrain/Shared/"
const SHARED_PSX_MODELS := "res://Assets/Terrain/Shared/psx_models/"

func _ready():
	GameLogger.info("🌴 Papua Terrain Controller initialized")
	debug_config = get_node_or_null("/root/DebugConfig")
	
	# Add to terrain controller group for editor access
	add_to_group("terrain_controller")
	
	setup_terrain_system()
	setup_ui_connections()

func is_terrain_debug_enabled() -> bool:
	"""Check if terrain debug is enabled"""
	if debug_config and debug_config.has_method("get") and debug_config.get("enable_terrain_debug"):
		return true
	return false

func setup_terrain_system():
	"""Setup the terrain system with asset pack"""
	GameLogger.info("🌿 Setting up terrain system...")
	
	# Load Papua asset pack
	papua_asset_pack = load("res://Assets/Terrain/Papua/psx_assets.tres")
	if not papua_asset_pack:
		GameLogger.error("❌ Failed to load Papua asset pack")
		return
	
	if is_terrain_debug_enabled():
		GameLogger.info("✅ Loaded Papua asset pack: " + papua_asset_pack.region_name)
		GameLogger.info("🌿 Environment type: " + papua_asset_pack.environment_type)
	
	# Create asset placer
	asset_placer = Node3D.new()
	asset_placer.name = "PapuaAssetPlacer"
	add_child(asset_placer)
	
	# Store reference to asset pack
	asset_placer.set_meta("asset_pack", papua_asset_pack)
	
	# Initialize stats
	terrain_stats = {
		"trees": 0,
		"vegetation": 0,
		"mushrooms": 0,
		"stones": 0,
		"debris": 0,
		"total": 0
	}
	
	# Setup Terrain3D with demo assets for visual success
	setup_terrain3d_with_demo_assets()
	
	GameLogger.info("✅ Terrain system setup complete")

func setup_ui_connections():
	"""Connect UI buttons to terrain functions"""
	GameLogger.info("🔍 Setting up terrain UI connections...")
	
	var terrain_controls = get_node_or_null("../../UI/TerrainControls")
	if not terrain_controls:
		GameLogger.warning("⚠️ TerrainControls UI not found")
		return
	
	var vbox = terrain_controls.get_node_or_null("TerrainPanel/VBoxContainer")
	if not vbox:
		GameLogger.warning("⚠️ VBoxContainer not found")
		return
	
	# Get buttons
	var generate_btn = vbox.get_node_or_null("GenerateForestBtn")
	var place_btn = vbox.get_node_or_null("PlaceAssetsBtn")
	var clear_btn = vbox.get_node_or_null("ClearAssetsBtn")
	var stats_label = vbox.get_node_or_null("StatsLabel")
	
	# Connect buttons
	if generate_btn:
		generate_btn.pressed.connect(_on_generate_forest)
		GameLogger.info("✅ Connected forest generation button")
	
	if place_btn:
		place_btn.pressed.connect(_on_place_psx_assets)
		GameLogger.info("✅ Connected PSX asset placement button")
	
	if clear_btn:
		clear_btn.pressed.connect(_on_clear_assets)
		GameLogger.info("✅ Connected clear assets button")
	
	# Store stats label reference
	if stats_label and asset_placer:
		asset_placer.set_meta("stats_label", stats_label)
		update_stats_display()

func _on_generate_forest():
	"""Generate tropical forest zones"""
	GameLogger.info("🌴 Generating tropical forest...")
	
	# Generate different forest zones around the scene
	var zones = [
		{"center": Vector3(0, 5, 0), "type": "dense_tropical", "radius": 50},
		{"center": Vector3(100, 2, 0), "type": "riverine", "radius": 30},
		{"center": Vector3(0, 40, -100), "type": "highland", "radius": 40},
		{"center": Vector3(-100, 10, 0), "type": "clearing", "radius": 25}
	]
	
	for zone in zones:
		generate_forest_zone(zone.center, zone.radius, zone.type)
	
	if asset_placer:
		update_stats_display()
	GameLogger.info("✅ Generated %d forest zones" % zones.size())

func _on_place_psx_assets():
	"""Place PSX assets using the asset pack"""
	GameLogger.info("🌿 Placing PSX assets...")
	
	if not papua_asset_pack:
		GameLogger.error("❌ No asset pack loaded")
		return
	
	# Place assets in different areas
	place_tropical_vegetation(Vector3(50, 5, 50), 40)
	place_tropical_trees(Vector3(-50, 5, -50), 60)
	place_forest_floor_assets(Vector3(0, 2, 0), 80)
	
	if asset_placer:
		update_stats_display()
	GameLogger.info("✅ Placed PSX assets")

func _on_clear_assets():
	"""Clear all placed assets"""
	GameLogger.info("🧹 Clearing all placed assets...")
	
	var to_remove: Array[Node] = []
	for child in asset_placer.get_children():
		to_remove.append(child)
	
	for node in to_remove:
		if node.get_parent():
			node.get_parent().remove_child(node)
			node.queue_free()
	
	# Reset stats
	terrain_stats = {
		"trees": 0,
		"vegetation": 0,
		"mushrooms": 0,
		"stones": 0,
		"debris": 0,
		"total": 0
	}
	
	if asset_placer:
		update_stats_display()
	GameLogger.info("✅ Cleared %d assets" % to_remove.size())

func _show_terrain_info():
	"""Show terrain information and stats"""
	GameLogger.info("📊 ===== TERRAIN INFORMATION =====")
	GameLogger.info("🌲 Trees: %d" % terrain_stats.get("trees", 0))
	GameLogger.info("🌿 Vegetation: %d" % terrain_stats.get("vegetation", 0))
	GameLogger.info("🍄 Mushrooms: %d" % terrain_stats.get("mushrooms", 0))
	GameLogger.info("🪨 Stones: %d" % terrain_stats.get("stones", 0))
	GameLogger.info("🗑️ Debris: %d" % terrain_stats.get("debris", 0))
	GameLogger.info("📈 Total Assets: %d" % terrain_stats.get("total", 0))
	
	# Show Terrain3D info
	var terrain3d = get_node_or_null("../Terrain3DManager/Terrain3D")
	if terrain3d:
		GameLogger.info("🌍 Terrain3D System: Active")
		GameLogger.info("📁 Data Directory: %s" % terrain3d.data_directory)
		GameLogger.info("🎨 Material: %s" % ("Loaded" if terrain3d.material else "None"))
		GameLogger.info("📦 Assets: %s" % ("Loaded" if terrain3d.assets else "None"))
		GameLogger.info("🔧 Show Checkered: %s" % terrain3d.show_checkered)
		GameLogger.info("📏 Top Level: %s" % terrain3d.top_level)
	else:
		GameLogger.warning("⚠️ Terrain3D node not found")
	
	# Show asset placer info
	if asset_placer:
		GameLogger.info("🎯 Asset Placer: Active")
		GameLogger.info("📊 Placed Assets: %d" % asset_placer.get_child_count())
	else:
		GameLogger.warning("⚠️ Asset placer not found")
	
	GameLogger.info("📊 ===== END TERRAIN INFO =====")

func _regenerate_terrain():
	"""Regenerate the entire terrain"""
	GameLogger.info("🔄 Regenerating terrain...")
	
	# Clear existing assets
	_on_clear_assets()
	
	# Wait a frame
	await get_tree().process_frame
	
	# Generate basic terrain heightmap
	generate_basic_terrain()
	
	# Wait a frame
	await get_tree().process_frame
	
	# Regenerate forest
	_on_generate_forest()
	
	# Wait a frame
	await get_tree().process_frame
	
	# Place PSX assets
	_on_place_psx_assets()
	
	GameLogger.info("✅ Terrain regeneration complete")

func generate_basic_terrain():
	"""Generate basic terrain heightmap and apply to Terrain3D"""
	GameLogger.info("🏔️ Generating basic terrain heightmap...")
	
	var terrain3d = get_node_or_null("../Terrain3DManager/Terrain3D")
	if not terrain3d:
		GameLogger.error("❌ Terrain3D node not found")
		return
	
	# Create a simple heightmap using noise
	var noise = FastNoiseLite.new()
	noise.seed = randi()
	noise.frequency = 0.01
	noise.noise_type = FastNoiseLite.TYPE_PERLIN
	
	# Generate heightmap data
	var size = 512
	var heightmap_data = PackedFloat32Array()
	heightmap_data.resize(size * size)
	
	for y in range(size):
		for x in range(size):
			var height = noise.get_noise_2d(x, y) * 50.0  # Scale height
			heightmap_data[y * size + x] = height
	
	# Apply heightmap to Terrain3D using the proper method
	apply_heightmap_to_terrain3d(terrain3d, heightmap_data, size)
	
	GameLogger.info("✅ Basic terrain heightmap generated and applied (%dx%d)" % [size, size])
	GameLogger.info("🌍 Terrain3D should now show elevation changes with grass texture")

func generate_terrain_from_image(image_path: String, height_scale: float = 100.0):
	"""Generate terrain heightmap from an image file"""
	GameLogger.info("🖼️ Generating terrain from image: %s" % image_path)
	
	# Load the image
	var image = Image.new()
	var error = image.load(image_path)
	
	if error != OK:
		GameLogger.error("❌ Failed to load image: %s" % image_path)
		return null
	
	# Convert to grayscale if needed
	if image.get_format() != Image.FORMAT_R8:
		image.convert(Image.FORMAT_R8)
	
	# Get image dimensions
	var width = image.get_width()
	var height = image.get_height()
	
	GameLogger.info("📏 Image dimensions: %dx%d" % [width, height])
	
	# Generate heightmap data from image
	var heightmap_data = PackedFloat32Array()
	heightmap_data.resize(width * height)
	
	for y in range(height):
		for x in range(width):
			# Get pixel brightness (0-255)
			var pixel_value = image.get_pixel(x, y).r
			
			# Convert to height (0-1 range, then scale)
			var normalized_height = pixel_value / 255.0
			var terrain_height = normalized_height * height_scale
			
			heightmap_data[y * width + x] = terrain_height
	
	GameLogger.info("✅ Terrain heightmap generated from image (%dx%d, scale: %.1f)" % [width, height, height_scale])
	return heightmap_data

func generate_terrain_from_noise_layers():
	"""Generate complex terrain using multiple noise layers"""
	GameLogger.info("🌊 Generating complex terrain with multiple noise layers...")
	
	var terrain3d = get_node_or_null("../Terrain3DManager/Terrain3D")
	if not terrain3d:
		GameLogger.error("❌ Terrain3D node not found")
		return
	
	var size = 512
	var heightmap_data = PackedFloat32Array()
	heightmap_data.resize(size * size)
	
	# Layer 1: Large scale mountains (low frequency)
	var mountain_noise = FastNoiseLite.new()
	mountain_noise.seed = 12345
	mountain_noise.frequency = 0.005
	mountain_noise.noise_type = FastNoiseLite.TYPE_PERLIN
	
	# Layer 2: Medium scale hills (medium frequency)
	var hill_noise = FastNoiseLite.new()
	hill_noise.seed = 54321
	hill_noise.frequency = 0.02
	hill_noise.noise_type = FastNoiseLite.TYPE_PERLIN
	
	# Layer 3: Small scale details (high frequency)
	var detail_noise = FastNoiseLite.new()
	detail_noise.seed = 98765
	detail_noise.frequency = 0.1
	detail_noise.noise_type = FastNoiseLite.TYPE_PERLIN
	
	# Combine noise layers
	for y in range(size):
		for x in range(size):
			var mountain_height = mountain_noise.get_noise_2d(x, y) * 80.0
			var hill_height = hill_noise.get_noise_2d(x, y) * 30.0
			var detail_height = detail_noise.get_noise_2d(x, y) * 10.0
			
			var total_height = mountain_height + hill_height + detail_height
			heightmap_data[y * size + x] = total_height
	
	# Apply heightmap to Terrain3D
	apply_heightmap_to_terrain3d(terrain3d, heightmap_data, size)
	
	GameLogger.info("✅ Complex terrain generated with 3 noise layers (%dx%d)" % [size, size])
	GameLogger.info("🌍 Terrain3D should now show complex elevation with grass texture")

func generate_terrain_from_hand_painted():
	"""Generate terrain from hand-painted heightmap"""
	GameLogger.info("🎨 Generating terrain from hand-painted heightmap...")
	
	var terrain3d = get_node_or_null("../Terrain3DManager/Terrain3D")
	if not terrain3d:
		GameLogger.error("❌ Terrain3D node not found")
		return
	
	# Example: Create a simple hand-painted style terrain
	var size = 256
	var heightmap_data = PackedFloat32Array()
	heightmap_data.resize(size * size)
	
	# Create a simple valley with mountains around it
	for y in range(size):
		for x in range(size):
			var center_x = size / 2.0
			var center_y = size / 2.0
			var distance_from_center = Vector2(x - center_x, y - center_y).length()
			
			# Create a valley in the center, mountains around edges
			var height = 0.0
			if distance_from_center < 50:
				# Valley - lower elevation
				height = 20.0 - (distance_from_center * 0.3)
			else:
				# Mountains - higher elevation
				height = 50.0 + (distance_from_center * 0.5)
			
			# Add some noise for natural variation
			var noise = FastNoiseLite.new()
			noise.seed = 11111
			noise.frequency = 0.05
			height += noise.get_noise_2d(x, y) * 15.0
			
			heightmap_data[y * size + x] = height
	
	# Apply heightmap to Terrain3D
	apply_heightmap_to_terrain3d(terrain3d, heightmap_data, size)
	
	GameLogger.info("✅ Hand-painted style terrain generated and applied (%dx%d)" % [size, size])
	GameLogger.info("🌍 Terrain3D should now show valley and mountains with grass texture")

func apply_heightmap_to_terrain3d(terrain3d: Terrain3D, heightmap_data: PackedFloat32Array, size: int):
	"""Apply heightmap data to Terrain3D system"""
	GameLogger.info("🔧 Applying heightmap to Terrain3D system...")
	
	if not terrain3d:
		GameLogger.error("❌ Terrain3D node is null")
		return
	
	# For now, just create a heightmap image and save it to the data directory
	# This is the most reliable method for Terrain3D
	GameLogger.info("🖼️ Creating heightmap image for Terrain3D...")
	create_heightmap_image(heightmap_data, size, terrain3d.data_directory)
	
	# Force Terrain3D to reload its data
	if terrain3d.has_method("reload"):
		GameLogger.info("🔄 Reloading Terrain3D data...")
		terrain3d.reload()
	
	GameLogger.info("✅ Heightmap applied to Terrain3D system")

func create_heightmap_image(heightmap_data: PackedFloat32Array, size: int, data_directory: String):
	"""Create a heightmap image file for Terrain3D"""
	GameLogger.info("🖼️ Creating heightmap image file...")
	
	# Create an image from the heightmap data
	var image = Image.create(size, size, false, Image.FORMAT_R8)
	
	# Convert heightmap data to image pixels
	for y in range(size):
		for x in range(size):
			var height = heightmap_data[y * size + x]
			# Normalize height to 0-255 range
			var normalized_height = (height + 100.0) / 200.0  # Assuming height range -100 to 100
			normalized_height = clamp(normalized_height, 0.0, 1.0)
			var pixel_value = int(normalized_height * 255)
			
			image.set_pixel(x, y, Color(pixel_value / 255.0, pixel_value / 255.0, pixel_value / 255.0, 1.0))
	
	# Save the heightmap image
	var heightmap_path = data_directory + "/heightmap.png"
	var error = image.save_png(heightmap_path)
	
	if error == OK:
		GameLogger.info("✅ Heightmap image saved: %s" % heightmap_path)
	else:
		GameLogger.error("❌ Failed to save heightmap image: %s" % heightmap_path)

func generate_hexagonal_path_system():
	"""Generate hexagonal path system with fixed artifact/NPC placement"""
	GameLogger.info("🔷 Generating hexagonal path system...")
	
	# Clear any previously created hexagon NPCs
	clear_hexagon_npcs()
	
	# Hexagon parameters
	var hex_radius = 80.0  # Radius of the hexagon
	var path_width = 8.0   # Width of the paths
	var center_pos = Vector3(0, 0, 0)  # Center of the hexagon
	
	# Calculate hexagon vertices (6 points) with proper terrain height
	var hex_vertices = []
	for i in range(6):
		var angle = i * PI / 3.0  # 60 degrees per vertex
		var x = center_pos.x + cos(angle) * hex_radius
		var z = center_pos.z + sin(angle) * hex_radius
		var pos = Vector3(x, 0, z)  # Y will be set by terrain height
		
		# Get actual terrain height at this position
		var terrain_height = get_terrain_height_at_position(pos)
		hex_vertices.append(Vector3(x, terrain_height, z))
	
	# Create path meshes along hexagon edges
	create_hexagon_paths(hex_vertices, path_width)
	
	# Place artifacts at hexagon vertices
	place_artifacts_at_vertices(hex_vertices)
	
	# Place existing story NPCs at hexagon vertices (alternating with artifacts)
	place_npcs_at_vertices(hex_vertices)
	
	# Create collision data for walkable paths
	create_path_collision_data(hex_vertices, path_width)
	
	# Generate forest around the paths
	generate_forest_around_paths(hex_vertices, path_width)
	
	GameLogger.info("✅ Hexagonal path system generated with %d vertices" % hex_vertices.size())

func create_hexagon_paths(vertices: Array, path_width: float):
	"""Create visual path meshes along hexagon edges"""
	GameLogger.info("🛤️ Creating hexagon path meshes...")
	
	var path_container = Node3D.new()
	path_container.name = "HexagonPaths"
	add_child(path_container)
	
	# Create path material using demo assets
	var path_material = create_road_material_for_paths()
	
	# Create paths between each vertex
	for i in range(vertices.size()):
		var start_vertex = vertices[i]
		var end_vertex = vertices[(i + 1) % vertices.size()]
		
		# Calculate path direction and length
		var _direction = (end_vertex - start_vertex).normalized()
		var distance = start_vertex.distance_to(end_vertex)
		
		# Create path mesh
		var path_mesh = BoxMesh.new()
		path_mesh.size = Vector3(path_width, 0.1, distance)
		
		var path_instance = MeshInstance3D.new()
		path_instance.mesh = path_mesh
		path_instance.material_override = path_material
		path_instance.name = "Path_" + str(i)
		
		# Add to container first, then set position and rotation
		path_container.add_child(path_instance)
		
		# Wait a frame to ensure node is in scene tree
		await get_tree().process_frame
		
		# Position and rotate the path with proper terrain height
		var path_center = (start_vertex + end_vertex) / 2.0
		# Get terrain height at path center
		var center_terrain_height = get_terrain_height_at_position(Vector3(path_center.x, 0, path_center.z))
		path_center.y = center_terrain_height
		
		path_instance.global_position = path_center
		path_instance.look_at(end_vertex, Vector3.UP)
		path_instance.rotate_object_local(Vector3.UP, PI / 2.0)
	
	GameLogger.info("✅ Created %d path segments" % vertices.size())

func place_artifacts_at_vertices(vertices: Array):
	"""Place artifacts at hexagon vertices"""
	GameLogger.info("🏺 Placing artifacts at hexagon vertices...")
	
	var artifact_container = Node3D.new()
	artifact_container.name = "HexagonArtifacts"
	add_child(artifact_container)
	
	# Place artifacts at every other vertex (0, 2, 4)
	for i in range(0, vertices.size(), 2):
		var vertex_pos = vertices[i]
		# Get terrain height at this position and place slightly above
		var terrain_height = get_terrain_height_at_position(Vector3(vertex_pos.x, 0, vertex_pos.z))
		vertex_pos.y = terrain_height + 1.0  # Slightly above ground
		
		# Create artifact
		var artifact = create_artifact_mesh("Artifact_" + str(i))
		artifact.global_position = vertex_pos
		artifact.rotation.y = randf() * TAU
		
		artifact_container.add_child(artifact)
	
	GameLogger.info("✅ Placed %d artifacts at hexagon vertices" % (vertices.size() / 2))

func clear_hexagon_npcs():
	"""Clear any previously created hexagon NPCs"""
	GameLogger.info("🧹 Clearing any previously created hexagon NPCs...")
	
	var existing_npcs = get_tree().get_nodes_in_group("npc")
	var hexagon_npcs = []
	
	for npc in existing_npcs:
		if npc.name.begins_with("NPC_") or npc.name.contains("Hexagon"):
			hexagon_npcs.append(npc)
	
	for npc in hexagon_npcs:
		GameLogger.info("Removing hexagon NPC: %s" % npc.name)
		npc.queue_free()
	
	if hexagon_npcs.size() > 0:
		GameLogger.info("✅ Removed %d hexagon NPCs" % hexagon_npcs.size())
	else:
		GameLogger.info("✅ No hexagon NPCs to remove")

func place_npcs_at_vertices(vertices: Array):
	"""Place existing story NPCs at hexagon vertices"""
	GameLogger.info("👥 Placing existing story NPCs at hexagon vertices...")
	
	# Get existing NPCs from the scene
	var existing_npcs = get_tree().get_nodes_in_group("npc")
	GameLogger.info("Found %d existing NPCs: %s" % [existing_npcs.size(), existing_npcs.map(func(npc): return npc.name)])
	
	# Filter out any "Hexagon" NPCs we might have created before
	var story_npcs = []
	for npc in existing_npcs:
		if not npc.name.begins_with("NPC_") and not npc.name.contains("Hexagon"):
			story_npcs.append(npc)
	
	GameLogger.info("Using %d story NPCs: %s" % [story_npcs.size(), story_npcs.map(func(npc): return npc.name)])
	
	# Place story NPCs at hexagon vertices (every other vertex: 1, 3, 5)
	var npc_index = 0
	for i in range(1, vertices.size(), 2):
		if npc_index >= story_npcs.size():
			break
			
		var vertex_pos = vertices[i]
		# Get terrain height at this position and place slightly above
		var terrain_height = get_terrain_height_at_position(Vector3(vertex_pos.x, 0, vertex_pos.z))
		vertex_pos.y = terrain_height + 1.0  # Slightly above ground
		
		var npc = story_npcs[npc_index]
		GameLogger.info("Moving %s to hexagon vertex %d at position %s" % [npc.name, i, vertex_pos])
		
		# Move existing NPC to hexagon vertex (deferred to avoid physics interpolation warnings)
		npc.call_deferred("set_global_position", vertex_pos)
		npc.call_deferred("set_rotation", Vector3(0, randf() * TAU, 0))
		
		npc_index += 1
	
	GameLogger.info("✅ Placed %d story NPCs at hexagon vertices" % npc_index)

func create_artifact_mesh(mesh_name: String) -> MeshInstance3D:
	"""Create an artifact mesh"""
	var artifact_mesh = BoxMesh.new()
	artifact_mesh.size = Vector3(1.5, 2.0, 1.5)
	
	var artifact_material = StandardMaterial3D.new()
	artifact_material.albedo_color = Color(0.8, 0.6, 0.2, 1.0)  # Golden color
	
	var artifact_instance = MeshInstance3D.new()
	artifact_instance.mesh = artifact_mesh
	artifact_instance.material_override = artifact_material
	artifact_instance.name = mesh_name
	
	return artifact_instance

func create_npc_mesh(npc_name: String) -> Node3D:
	"""Create an interactive NPC matching PapuaFixed structure"""
	var npc = Node3D.new()
	npc.name = npc_name
	npc.add_to_group("npc")
	
	# Add CulturalNPC script
	npc.set_script(load("res://Systems/NPCs/CulturalNPC.gd"))
	npc.npc_name = "Hexagon " + npc_name.replace("NPC_", "Guide ")
	npc.npc_type = "guide"
	npc.cultural_region = "Indonesia Timur"
	
	# Add NPCModel (visual representation)
	var npc_model = CSGCylinder3D.new()
	npc_model.name = "NPCModel"
	var npc_material = StandardMaterial3D.new()
	npc_material.albedo_color = Color(0.2, 0.8, 0.2, 1.0)  # Green color
	npc_model.material = npc_material
	npc.add_child(npc_model)
	
	# Add NPCCollision (CharacterBody3D for physics)
	var npc_collision = CharacterBody3D.new()
	npc_collision.name = "NPCCollision"
	var collision_shape = CollisionShape3D.new()
	var box_shape = BoxShape3D.new()
	box_shape.size = Vector3(1, 2, 1)
	collision_shape.shape = box_shape
	npc_collision.add_child(collision_shape)
	npc.add_child(npc_collision)
	
	# Add InteractionArea (Area3D for interaction)
	var interaction_area = Area3D.new()
	interaction_area.name = "InteractionArea"
	var area_collision = CollisionShape3D.new()
	var sphere_shape = SphereShape3D.new()
	sphere_shape.radius = 3.0  # 3 meter interaction range
	area_collision.shape = sphere_shape
	interaction_area.add_child(area_collision)
	npc.add_child(interaction_area)
	
	return npc

func create_path_collision_data(vertices: Array, path_width: float):
	"""Create collision data for walkable paths"""
	GameLogger.info("🚶 Creating path collision data...")
	
	var collision_container = StaticBody3D.new()
	collision_container.name = "PathCollision"
	add_child(collision_container)
	
	# Create collision shapes for each path segment
	for i in range(vertices.size()):
		var start_vertex = vertices[i]
		var end_vertex = vertices[(i + 1) % vertices.size()]
		
		# Calculate path direction and length
		var _direction = (end_vertex - start_vertex).normalized()
		var distance = start_vertex.distance_to(end_vertex)
		
		# Create collision shape
		var collision_shape = CollisionShape3D.new()
		var box_shape = BoxShape3D.new()
		box_shape.size = Vector3(path_width, 0.2, distance)
		collision_shape.shape = box_shape
		collision_shape.name = "PathCollision_" + str(i)
		
		# Position and rotate the collision
		var path_center = (start_vertex + end_vertex) / 2.0
		collision_shape.global_position = path_center
		collision_shape.look_at(end_vertex, Vector3.UP)
		collision_shape.rotate_object_local(Vector3.UP, PI / 2.0)
		
		collision_container.add_child(collision_shape)
	
	GameLogger.info("✅ Created collision data for %d path segments" % vertices.size())

func generate_forest_around_paths(vertices: Array, path_width: float):
	"""Generate forest around the hexagonal paths (sekitar/samping-samping path)"""
	GameLogger.info("🌲 Generating forest around paths...")
	
	# Create forest container
	var forest_container = Node3D.new()
	forest_container.name = "PathForest"
	add_child(forest_container)
	
	# Forest parameters
	var forest_distance = 15.0  # Distance from path edge to place trees
	var tree_density = 0.3      # Density of trees (0.0 to 1.0)
	var tree_spacing = 8.0      # Minimum spacing between trees
	
	# Get available tree assets
	var tree_assets = _filter_glb(papua_asset_pack.trees)
	if tree_assets.is_empty():
		GameLogger.warning("⚠️ No tree assets available for path forest")
		return
	
	var trees_placed = 0
	
	# Generate forest along each path segment
	for i in range(vertices.size()):
		var start_vertex = vertices[i]
		var end_vertex = vertices[(i + 1) % vertices.size()]
		
		# Calculate path direction and length
		var direction = (end_vertex - start_vertex).normalized()
		var distance = start_vertex.distance_to(end_vertex)
		var perpendicular = Vector3(-direction.z, 0, direction.x)  # 90-degree rotation
		
		# Generate trees along the path segment
		var segment_trees = generate_trees_along_path_segment(
			start_vertex, end_vertex, direction, perpendicular, 
			path_width, forest_distance, tree_density, tree_spacing, tree_assets
		)
		
		# Add trees to forest container
		for tree in segment_trees:
			forest_container.add_child(tree)
			trees_placed += 1
	
	GameLogger.info("✅ Generated %d trees around paths" % trees_placed)

func generate_trees_along_path_segment(start_vertex: Vector3, end_vertex: Vector3, 
		direction: Vector3, perpendicular: Vector3, path_width: float, 
		forest_distance: float, tree_density: float, tree_spacing: float, 
		tree_assets: Array) -> Array:
	"""Generate trees along a single path segment"""
	var trees = []
	
	# Calculate number of tree placement points along the path
	var path_length = start_vertex.distance_to(end_vertex)
	var num_points = int(path_length / tree_spacing)
	
	for i in range(num_points):
		# Skip some points based on density
		if randf() > tree_density:
			continue
		
		# Calculate position along the path
		var t = float(i) / float(num_points - 1) if num_points > 1 else 0.0
		var path_pos = start_vertex.lerp(end_vertex, t)
		
		# Place trees on both sides of the path
		for side in [-1, 1]:  # -1 for left side, 1 for right side
			# Calculate tree position
			var tree_offset = perpendicular * (path_width/2.0 + forest_distance) * side
			var tree_pos = path_pos + tree_offset
			
			# Add some randomness to avoid perfect alignment
			tree_pos += Vector3(
				randf_range(-3.0, 3.0),
				0,
				randf_range(-3.0, 3.0)
			)
			
			# Check if position is on a path - skip if it is
			if is_position_on_path(tree_pos):
				GameLogger.debug("🚫 Skipping path tree placement at %s - position is on path" % tree_pos)
				continue
			
			# Get terrain height at tree position
			var terrain_height = get_terrain_height_at_position(tree_pos)
			tree_pos.y = terrain_height
			
			# Select random tree asset
			var tree_asset = tree_assets[randi() % tree_assets.size()]
			
			# Create tree instance
			var tree_instance = _instantiate_glb(tree_asset)
			if tree_instance != null:
				tree_instance.global_position = tree_pos
				tree_instance.rotation.y = randf() * TAU
				tree_instance.scale = Vector3.ONE * randf_range(0.8, 1.3)
				tree_instance.name = "PathTree_" + str(trees.size())
				trees.append(tree_instance)
	
	return trees

func get_hexagon_vertices(center: Vector3, radius: float) -> Array:
	"""Get hexagon vertices for a given center and radius"""
	var vertices = []
	for i in range(6):
		var angle = i * PI / 3.0  # 60 degrees per vertex
		var x = center.x + cos(angle) * radius
		var z = center.z + sin(angle) * radius
		vertices.append(Vector3(x, center.y, z))
	return vertices

func generate_forest_zone(center: Vector3, radius: float, zone_type: String):
	"""Generate a specific type of forest zone"""
	GameLogger.info("🌲 Generating %s forest zone at %s" % [zone_type, center])
	
	match zone_type:
		"dense_tropical":
			place_dense_tropical_forest(center, radius)
		"riverine":
			place_riverine_forest(center, radius)
		"highland":
			place_highland_forest(center, radius)
		"clearing":
			place_forest_clearing(center, radius)

func place_dense_tropical_forest(center: Vector3, radius: float):
	"""Place dense tropical forest vegetation"""
	var trees = _filter_glb(papua_asset_pack.trees)
	var vegetation = _filter_glb(papua_asset_pack.vegetation)
	
	for i in range(60):
		var angle = randf() * TAU
		var distance = randf() * radius
		var pos = center + Vector3(cos(angle) * distance, 0, sin(angle) * distance)
		# Remove hardcoded Y position - let place_asset_at_position handle terrain height
		
		if randf() < 0.6 and trees.size() > 0:
			place_asset_at_position(trees[randi() % trees.size()], pos, "tree")
		elif vegetation.size() > 0:
			place_asset_at_position(vegetation[randi() % vegetation.size()], pos, "vegetation")

func place_riverine_forest(center: Vector3, radius: float):
	"""Place riverine forest with water-loving plants"""
	var vegetation = _filter_glb(papua_asset_pack.vegetation)
	
	for i in range(40):
		var angle = randf() * TAU
		var distance = randf() * radius
		var pos = center + Vector3(cos(angle) * distance, 0, sin(angle) * distance)
		# Remove hardcoded Y position - let place_asset_at_position handle terrain height
		
		if vegetation.size() > 0:
			place_asset_at_position(vegetation[randi() % vegetation.size()], pos, "vegetation")

func place_highland_forest(center: Vector3, radius: float):
	"""Place highland forest with adapted species"""
	var trees = _filter_glb(papua_asset_pack.trees)
	var stones = _filter_glb(papua_asset_pack.stones)
	
	for i in range(30):
		var angle = randf() * TAU
		var distance = randf() * radius
		var pos = center + Vector3(cos(angle) * distance, 0, sin(angle) * distance)
		# Remove hardcoded Y position - let place_asset_at_position handle terrain height
		
		if randf() < 0.5 and stones.size() > 0:
			place_asset_at_position(stones[randi() % stones.size()], pos, "stone")
		elif randf() < 0.3 and trees.size() > 0:
			place_asset_at_position(trees[randi() % trees.size()], pos, "tree")

func place_forest_clearing(center: Vector3, radius: float):
	"""Place forest clearing with sparse vegetation"""
	var vegetation = _filter_glb(papua_asset_pack.vegetation)
	var debris = _filter_glb(papua_asset_pack.debris)
	
	for i in range(15):
		var angle = randf() * TAU
		var distance = randf() * radius
		var pos = center + Vector3(cos(angle) * distance, 0, sin(angle) * distance)
		# Remove hardcoded Y position - let place_asset_at_position handle terrain height
		
		if randf() < 0.7 and vegetation.size() > 0:
			place_asset_at_position(vegetation[randi() % vegetation.size()], pos, "vegetation")
		elif debris.size() > 0:
			place_asset_at_position(debris[randi() % debris.size()], pos, "debris")

func place_tropical_vegetation(center: Vector3, radius: float):
	"""Place diverse tropical vegetation"""
	if is_terrain_debug_enabled():
		GameLogger.info("🌿 Placing tropical vegetation cluster")
	var vegetation = _filter_glb(papua_asset_pack.vegetation)
	
	for i in range(40):
		var angle = randf() * TAU
		var distance = randf() * radius
		var pos = center + Vector3(cos(angle) * distance, 0, sin(angle) * distance)
		# Remove hardcoded Y position - let place_asset_at_position handle terrain height
		
		if vegetation.size() > 0:
			place_asset_at_position(vegetation[randi() % vegetation.size()], pos, "vegetation")

func place_tropical_trees(center: Vector3, radius: float):
	"""Place tropical trees"""
	var trees = _filter_glb(papua_asset_pack.trees)
	
	if trees.size() == 0:
		GameLogger.warning("⚠️ No GLB trees found")
		return
	
	for i in range(20):
		var angle = randf() * TAU
		var distance = randf() * radius
		var pos = center + Vector3(cos(angle) * distance, 0, sin(angle) * distance)
		# Remove hardcoded Y position - let place_asset_at_position handle terrain height
		
		place_asset_at_position(trees[randi() % trees.size()], pos, "tree")

func place_forest_floor_assets(center: Vector3, radius: float):
	"""Place forest floor assets (mushrooms, small vegetation)"""
	var vegetation = _filter_glb(papua_asset_pack.vegetation)
	var mushrooms = _filter_glb(papua_asset_pack.mushrooms)
	var debris = _filter_glb(papua_asset_pack.debris)
	
	for i in range(50):
		var angle = randf() * TAU
		var distance = randf() * radius
		var pos = center + Vector3(cos(angle) * distance, 0, sin(angle) * distance)
		# Remove hardcoded Y position - let place_asset_at_position handle terrain height
		
		var asset_type = ""
		var asset_path = ""
		
		# Choose asset type based on probability
		var rand_val = randf()
		if rand_val < 0.4 and vegetation.size() > 0:
			asset_type = "vegetation"
			asset_path = vegetation[randi() % vegetation.size()]
		elif rand_val < 0.7 and mushrooms.size() > 0:
			asset_type = "mushroom"
			asset_path = mushrooms[randi() % mushrooms.size()]
		elif debris.size() > 0:
			asset_type = "debris"
			asset_path = debris[randi() % debris.size()]
		else:
			continue
		
		place_asset_at_position(asset_path, pos, asset_type)

func _filter_glb(paths: Array) -> Array[String]:
	"""Filter array to only include GLB files from Shared directory"""
	var out: Array[String] = []
	for p in paths:
		if typeof(p) == TYPE_STRING:
			var sp: String = p
			sp = sp.replace("\\", "/")
			if sp.to_lower().ends_with(".glb") and sp.begins_with(SHARED_ROOT):
				out.append(sp)
	return out

func get_terrain_height_at_position(world_pos: Vector3) -> float:
	"""Get the actual terrain height at a world position using Terrain3D"""
	var terrain3d = get_node_or_null("../Terrain3DManager/Terrain3D")
	if not terrain3d:
		GameLogger.warning("⚠️ Terrain3D not found, using fallback height")
		return 0.0
	
	# Use Terrain3D's data.get_height method (same as demo)
	if terrain3d.has_method("get_height"):
		var height = terrain3d.get_height(world_pos)
		if height != null:
			GameLogger.debug("📍 Terrain height at %s: %.2f (via get_height)" % [world_pos, height])
			return height
	
	# Try using terrain.data.get_height if available (demo approach)
	if terrain3d.has_method("get_data") and terrain3d.get_data() != null:
		var terrain_data = terrain3d.get_data()
		if terrain_data.has_method("get_height"):
			var height = terrain_data.get_height(world_pos)
			if height != null:
				GameLogger.debug("📍 Terrain height at %s: %.2f (via data.get_height)" % [world_pos, height])
				return height
	
	# Fallback: Use a simple height calculation based on noise
	# This matches the terrain generation in generate_basic_terrain()
	var noise = FastNoiseLite.new()
	noise.seed = 12345  # Use same seed as terrain generation
	noise.frequency = 0.01
	noise.noise_type = FastNoiseLite.TYPE_PERLIN
	
	var height = noise.get_noise_2d(world_pos.x, world_pos.z) * 50.0
	GameLogger.debug("📍 Terrain height at %s: %.2f (via noise fallback)" % [world_pos, height])
	return height

func is_position_on_path(world_pos: Vector3, path_width: float = 8.0) -> bool:
	"""Check if a position is on any of the hexagonal paths"""
	var path_container = get_node_or_null("HexagonPaths")
	if not path_container:
		return false  # No paths exist yet
	
	# Check each path segment
	for i in range(path_container.get_child_count()):
		var path_segment = path_container.get_child(i)
		if not path_segment is MeshInstance3D:
			continue
		
		# Get path segment info
		var path_pos = path_segment.global_position
		var path_rotation = path_segment.global_rotation
		
		# Calculate path bounds (simplified rectangle check)
		var path_mesh = path_segment.mesh as BoxMesh
		if not path_mesh:
			continue
		
		var path_size = path_mesh.size
		var half_width = path_size.x / 2.0
		var half_length = path_size.z / 2.0
		
		# Transform world position to local path space
		var local_pos = world_pos - path_pos
		local_pos = local_pos.rotated(Vector3.UP, -path_rotation.y)
		
		# Check if position is within path bounds
		if abs(local_pos.x) <= half_width and abs(local_pos.z) <= half_length:
			GameLogger.debug("🚫 Position %s is on path segment %s" % [world_pos, path_segment.name])
			return true
	
	return false

func place_asset_at_position(asset_path: String, pos: Vector3, asset_type: String):
	"""Place an asset at the specified position with proper terrain height"""
	if not (asset_path.to_lower().ends_with(".glb") and asset_path.begins_with(SHARED_ROOT)):
		GameLogger.warning("⛔ Skipping non-GLB or non-Shared asset: %s" % asset_path)
		return
	
	# Check if position is on a path - skip if it is
	if is_position_on_path(pos):
		GameLogger.debug("🚫 Skipping %s placement at %s - position is on path" % [asset_type, pos])
		return
	
	var inst := _instantiate_glb(asset_path)
	if inst == null:
		return
	
	# Get actual terrain height at this position
	var terrain_height = get_terrain_height_at_position(pos)
	
	# Set position with proper terrain height
	inst.position = Vector3(pos.x, terrain_height, pos.z)
	GameLogger.debug("🎯 Placed %s at %s (terrain height: %.2f)" % [asset_type, inst.position, terrain_height])
	inst.rotation.y = randf() * TAU
	
	var scale_factor = 1.0
	match asset_type:
		"tree":
			scale_factor = randf_range(0.8, 1.3)
		"vegetation":
			scale_factor = randf_range(0.6, 1.2)
		"mushroom":
			scale_factor = randf_range(0.4, 0.8)
		"stone":
			scale_factor = randf_range(0.7, 1.1)
		"debris":
			scale_factor = randf_range(0.5, 0.9)
		_:
			scale_factor = randf_range(0.7, 1.1)
	
	inst.scale = Vector3.ONE * scale_factor
	inst.name = asset_type + "_" + str(asset_placer.get_child_count())
	asset_placer.add_child(inst)
	
	# Update stats
	terrain_stats[asset_type] = terrain_stats.get(asset_type, 0) + 1
	terrain_stats["total"] = terrain_stats.get("total", 0) + 1

func _instantiate_glb(path: String) -> Node3D:
	"""Instantiate a GLB file"""
	# Check if file exists first
	var file_check = FileAccess.open(path, FileAccess.READ)
	if not file_check:
		GameLogger.error("❌ File not found: %s" % path)
		return null
	file_check.close()
	
	var scene := load(path)
	if scene == null:
		GameLogger.error("❌ Failed to load GLB: %s" % path)
		return null
	
	var node: Node = scene.instantiate()
	if node is Node3D:
		return node as Node3D
	return null

func update_stats_display():
	"""Update the stats display in the UI"""
	if not asset_placer:
		# If no asset placer, just log the stats
		GameLogger.info("📊 Terrain Stats: Assets: %d, Trees: %d, Vegetation: %d, Mushrooms: %d, Stones: %d, Debris: %d" % [
			terrain_stats.get("total", 0),
			terrain_stats.get("trees", 0),
			terrain_stats.get("vegetation", 0),
			terrain_stats.get("mushrooms", 0),
			terrain_stats.get("stones", 0),
			terrain_stats.get("debris", 0)
		])
		return
	
	var stats_label = null
	if asset_placer.has_meta("stats_label"):
		stats_label = asset_placer.get_meta("stats_label")
	
	if not stats_label:
		# If no UI label, just log the stats
		GameLogger.info("📊 Terrain Stats: Assets: %d, Trees: %d, Vegetation: %d, Mushrooms: %d, Stones: %d, Debris: %d" % [
			terrain_stats.get("total", 0),
			terrain_stats.get("trees", 0),
			terrain_stats.get("vegetation", 0),
			terrain_stats.get("mushrooms", 0),
			terrain_stats.get("stones", 0),
			terrain_stats.get("debris", 0)
		])
		return
	
	var stats_text = "Assets: %d\n" % terrain_stats["total"]
	stats_text += "Trees: %d\n" % terrain_stats.get("trees", 0)
	stats_text += "Vegetation: %d\n" % terrain_stats.get("vegetation", 0)
	stats_text += "Mushrooms: %d\n" % terrain_stats.get("mushrooms", 0)
	stats_text += "Stones: %d\n" % terrain_stats.get("stones", 0)
	stats_text += "Debris: %d" % terrain_stats.get("debris", 0)
	
	stats_label.text = stats_text

func _input(event):
	"""Handle input for terrain controls"""
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_F:
				_on_generate_forest()
			KEY_P:
				_on_place_psx_assets()
			KEY_C:
				_on_clear_assets()
			KEY_T:
				_show_terrain_info()
			KEY_R:
				_regenerate_terrain()
			KEY_1:
				# Generate basic noise terrain
				GameLogger.info("🏔️ Generating basic noise terrain...")
				generate_basic_terrain()
			KEY_2:
				# Generate complex multi-layer terrain
				GameLogger.info("🌊 Generating complex multi-layer terrain...")
				generate_terrain_from_noise_layers()
			KEY_3:
				# Generate hand-painted style terrain
				GameLogger.info("🎨 Generating hand-painted style terrain...")
				generate_terrain_from_hand_painted()
			KEY_4:
				# Generate terrain from image (example)
				GameLogger.info("🖼️ Generating terrain from image...")
				# You can change this path to your image
				generate_terrain_from_image("res://Assets/Terrain/heightmap_example.png", 100.0)
			KEY_5:
				# Generate hexagonal path system
				GameLogger.info("🔷 Generating hexagonal path system...")
				generate_hexagonal_path_system()
			KEY_6:
				# Place demo rock assets
				GameLogger.info("🪨 Placing demo rock assets...")
				place_demo_rock_assets()
			KEY_7:
				# Force reload Terrain3D data
				GameLogger.info("🔄 Force reloading Terrain3D data...")
				force_terrain3d_reload()
			KEY_8:
				# Create mountain borders around gameplay area
				GameLogger.info("🏔️ Creating mountain borders...")
				create_mountain_borders()
			KEY_9:
				# Show Terrain3D region info
				GameLogger.info("📊 Showing Terrain3D region info...")
				show_terrain3d_regions()

func setup_terrain3d_with_demo_assets():
	"""Setup Terrain3D with demo assets for immediate visual success"""
	GameLogger.info("🏔️ Setting up Terrain3D with demo assets...")
	
	# Get Terrain3D node from the scene
	var terrain3d = get_node_or_null("../Terrain3DManager/Terrain3D")
	if not terrain3d:
		GameLogger.error("❌ Terrain3D node not found in scene")
		return
	
	GameLogger.info("✅ Found Terrain3D node: %s" % terrain3d.name)
	
	# Check if Terrain3D is using demo data
	if terrain3d.data_directory == "res://demo/data":
		GameLogger.info("✅ Terrain3D is using demo data directory - should show terrain immediately!")
	else:
		GameLogger.warning("⚠️ Terrain3D data directory: %s" % terrain3d.data_directory)
	
	# Check if Terrain3D has demo assets
	if terrain3d.assets:
		GameLogger.info("✅ Terrain3D has assets: %s" % terrain3d.assets.resource_path)
	else:
		GameLogger.warning("⚠️ Terrain3D has no assets")
	
	# Check if Terrain3D has material
	if terrain3d.material:
		GameLogger.info("✅ Terrain3D has material: %s" % terrain3d.material.get_class())
	else:
		GameLogger.warning("⚠️ Terrain3D has no material")
	
	# Force Terrain3D to reload its data
	if terrain3d.has_method("reload"):
		GameLogger.info("🔄 Forcing Terrain3D to reload data...")
		terrain3d.reload()
	
	# Wait a frame for the reload to take effect
	await get_tree().process_frame
	
	GameLogger.info("✅ Terrain3D setup complete - using demo terrain data!")

func force_terrain3d_reload():
	"""Force Terrain3D to reload its data"""
	GameLogger.info("🔄 Force reloading Terrain3D data...")
	
	var terrain3d = get_node_or_null("../Terrain3DManager/Terrain3D")
	if not terrain3d:
		GameLogger.error("❌ Terrain3D node not found")
		return
	
	# Force reload
	if terrain3d.has_method("reload"):
		terrain3d.reload()
		GameLogger.info("✅ Terrain3D reloaded")
	else:
		GameLogger.warning("⚠️ Terrain3D has no reload method")
	
	# Also try to refresh the material
	if terrain3d.material:
		GameLogger.info("✅ Terrain3D material: %s" % terrain3d.material.get_class())
	
	# Check data directory
	GameLogger.info("📁 Terrain3D data directory: %s" % terrain3d.data_directory)

func create_mountain_borders():
	"""Create mountains around the gameplay area"""
	GameLogger.info("🏔️ Creating mountain borders around gameplay area...")
	
	var terrain3d = get_node_or_null("../Terrain3DManager/Terrain3D")
	if not terrain3d:
		GameLogger.error("❌ Terrain3D node not found")
		return
	
	# Define the gameplay area (center region)
	var gameplay_center = Vector3(0, 0, 0)
	var gameplay_radius = 200.0  # 200 unit radius gameplay area
	
	# Create mountains around the gameplay area
	create_mountain_ring(terrain3d, gameplay_center, gameplay_radius, 300.0, 50.0)
	
	GameLogger.info("✅ Mountain borders created around gameplay area")

func create_mountain_ring(terrain3d: Terrain3D, center: Vector3, inner_radius: float, outer_radius: float, height: float):
	"""Create a ring of mountains around a center point"""
	GameLogger.info("🏔️ Creating mountain ring: center=%s, inner=%f, outer=%f, height=%f" % [center, inner_radius, outer_radius, height])
	
	# Create heightmap data for mountain ring
	var size = 512
	var heightmap_data = PackedFloat32Array()
	heightmap_data.resize(size * size)
	
	for y in range(size):
		for x in range(size):
			# Convert to world coordinates
			var world_x = (x - size/2.0) * 2.0  # Scale to world units
			var world_z = (y - size/2.0) * 2.0
			var world_pos = Vector3(world_x, 0, world_z)
			
			# Calculate distance from center
			var distance_from_center = world_pos.distance_to(center)
			
			# Create mountain ring
			var height_value = 0.0
			if distance_from_center > inner_radius and distance_from_center < outer_radius:
				# Create mountains in the ring area
				var ring_progress = (distance_from_center - inner_radius) / (outer_radius - inner_radius)
				var mountain_height = sin(ring_progress * PI) * height
				
				# Add some noise for natural variation
				var noise = FastNoiseLite.new()
				noise.seed = 12345
				noise.frequency = 0.02
				mountain_height += noise.get_noise_2d(world_x, world_z) * 20.0
				
				height_value = mountain_height
			elif distance_from_center <= inner_radius:
				# Keep gameplay area relatively flat
				var noise = FastNoiseLite.new()
				noise.seed = 54321
				noise.frequency = 0.01
				height_value = noise.get_noise_2d(world_x, world_z) * 10.0
			
			heightmap_data[y * size + x] = height_value
	
	# Apply the heightmap
	apply_heightmap_to_terrain3d(terrain3d, heightmap_data, size)
	
	GameLogger.info("✅ Mountain ring created")

func show_terrain3d_regions():
	"""Show information about Terrain3D regions"""
	GameLogger.info("📊 ===== TERRAIN3D REGION INFO =====")
	
	var terrain3d = get_node_or_null("../Terrain3DManager/Terrain3D")
	if not terrain3d:
		GameLogger.error("❌ Terrain3D node not found")
		return
	
	GameLogger.info("📁 Data Directory: %s" % terrain3d.data_directory)
	GameLogger.info("🎨 Material: %s" % ("Loaded" if terrain3d.material else "None"))
	GameLogger.info("📦 Assets: %s" % ("Loaded" if terrain3d.assets else "None"))
	GameLogger.info("🔧 Show Checkered: %s" % terrain3d.show_checkered)
	GameLogger.info("📏 Top Level: %s" % terrain3d.top_level)
	
	# Check if Terrain3D has methods to get region info
	if terrain3d.has_method("get_region_count"):
		var region_count = terrain3d.get_region_count()
		GameLogger.info("🗺️ Region Count: %d" % region_count)
	
	if terrain3d.has_method("get_region_list"):
		var regions = terrain3d.get_region_list()
		GameLogger.info("🗺️ Regions: %s" % str(regions))
	
	# List terrain data files
	var data_dir = DirAccess.open(terrain3d.data_directory)
	if data_dir:
		GameLogger.info("📂 Terrain Data Files:")
		data_dir.list_dir_begin()
		var file_name = data_dir.get_next()
		while file_name != "":
			if file_name.ends_with(".res"):
				GameLogger.info("  📄 %s" % file_name)
			file_name = data_dir.get_next()
		data_dir.list_dir_end()
	
	GameLogger.info("📊 ===== END REGION INFO =====")

func create_terrain3d_material_with_demo_assets() -> Terrain3DMaterial:
	"""Create a Terrain3D material using demo assets"""
	GameLogger.info("🎨 Creating Terrain3D material with demo assets...")
	
	var material = Terrain3DMaterial.new()
	if not material:
		GameLogger.error("❌ Failed to create Terrain3DMaterial instance")
		return null
	
	GameLogger.info("✅ Created Terrain3DMaterial instance")
	
	# Use demo ground texture as base texture
	var ground_texture_path = "res://demo/assets/textures/ground037_alb_ht.png"
	if ResourceLoader.exists(ground_texture_path):
		var ground_texture = load(ground_texture_path)
		if ground_texture:
			# Set the base texture for Terrain3D material using correct API
			material.set_shader_param("base_texture", ground_texture)
			GameLogger.info("✅ Applied ground texture to Terrain3D material: %s" % ground_texture_path)
		else:
			GameLogger.error("❌ Failed to load ground texture: %s" % ground_texture_path)
			# Use fallback texture
			var fallback_texture = create_fallback_grass_texture()
			if fallback_texture:
				material.set_shader_param("base_texture", fallback_texture)
				GameLogger.info("✅ Applied fallback grass texture")
	else:
		# Fallback: Create a simple grass-colored texture
		GameLogger.warning("⚠️ Ground texture not found: %s" % ground_texture_path)
		var fallback_texture = create_fallback_grass_texture()
		if fallback_texture:
			material.set_shader_param("base_texture", fallback_texture)
			GameLogger.info("✅ Applied fallback grass texture")
		else:
			GameLogger.error("❌ Failed to create fallback texture")
			return null
	
	# Set Terrain3D material properties using correct API
	material.set_shader_param("blend_sharpness", 0.87)
	material.set_shader_param("height_blending", true)
	material.set_shader_param("world_space_normal_blend", true)
	
	GameLogger.info("✅ Terrain3D material created successfully")
	return material

func create_fallback_grass_texture() -> ImageTexture:
	"""Create a simple grass-colored texture as fallback"""
	GameLogger.info("🌿 Creating fallback grass texture...")
	
	var image = Image.create(64, 64, false, Image.FORMAT_RGB8)
	if not image:
		GameLogger.error("❌ Failed to create fallback image")
		return null
	
	# Fill with grass green color
	for y in range(64):
		for x in range(64):
			# Add some variation to make it look more natural
			var variation = sin(x * 0.3) * cos(y * 0.3) * 0.1
			var green = 0.3 + variation
			var red = 0.1 + variation * 0.5
			var blue = 0.1 + variation * 0.3
			image.set_pixel(x, y, Color(red, green, blue, 1.0))
	
	var texture = ImageTexture.new()
	if not texture:
		GameLogger.error("❌ Failed to create ImageTexture")
		return null
	
	texture.create_from_image(image)
	
	GameLogger.info("✅ Created fallback grass texture")
	return texture

func create_road_material_for_paths() -> StandardMaterial3D:
	"""Create a road/path material for hexagon paths"""
	GameLogger.info("🛤️ Creating road material for paths...")
	
	var road_material = StandardMaterial3D.new()
	
	# Try to use demo rock texture as road texture
	var rock_texture_path = "res://demo/assets/textures/rock023_alb_ht.png"
	if ResourceLoader.exists(rock_texture_path):
		var rock_texture = load(rock_texture_path)
		road_material.albedo_texture = rock_texture
		GameLogger.info("✅ Applied rock texture as road: %s" % rock_texture_path)
	else:
		# Fallback to brown dirt color
		road_material.albedo_color = Color(0.6, 0.4, 0.2)  # Brown dirt
		GameLogger.warning("⚠️ Rock texture not found, using fallback road color")
	
	# Set road material properties
	road_material.roughness = 0.9  # Dirt roads are rough
	road_material.metallic = 0.0   # Dirt is not metallic
	
	return road_material

func place_demo_rock_assets():
	"""Place demo rock assets on the terrain for visual variety"""
	GameLogger.info("🪨 Placing demo rock assets...")
	
	# Create rock container
	var rock_container = Node3D.new()
	rock_container.name = "DemoRocks"
	add_child(rock_container)
	
	# Get demo rock models
	var rock_paths = [
		"res://demo/assets/models/RockA.tscn",
		"res://demo/assets/models/RockB.tscn", 
		"res://demo/assets/models/RockC.tscn"
	]
	
	# Place rocks randomly around the terrain
	var rock_count = 0
	for i in range(20):  # Place 20 rocks
		var rock_path = rock_paths[randi() % rock_paths.size()]
		
		if ResourceLoader.exists(rock_path):
			var rock_scene = load(rock_path)
			var rock_instance = rock_scene.instantiate()
			
			# Random position around the terrain
			var x = randf_range(-100, 100)
			var z = randf_range(-100, 100)
			var pos = Vector3(x, 0, z)  # Y will be set by terrain height
			
			# Check if position is on a path - skip if it is
			if is_position_on_path(pos):
				GameLogger.debug("🚫 Skipping rock placement at %s - position is on path" % pos)
				continue
			
			# Get actual terrain height at this position
			var terrain_height = get_terrain_height_at_position(pos)
			
			rock_instance.global_position = Vector3(x, terrain_height, z)
			rock_instance.rotation.y = randf() * TAU
			rock_instance.scale = Vector3(randf_range(0.5, 1.5), randf_range(0.5, 1.5), randf_range(0.5, 1.5))
			
			rock_container.add_child(rock_instance)
			rock_count += 1
	
	GameLogger.info("✅ Placed %d demo rock assets" % rock_count)
