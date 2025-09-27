extends Node

# Reusable GLTF export and texture optimization helpers for Godot 4.3

class_name GltfExportUtils

static func recompress_texture(tex: Texture2D, cache: Dictionary, out_dir: String, max_dim: int, jpeg_quality: float, prefer_jpeg: bool) -> Texture2D:
	if tex == null:
		return tex
	var key := tex.resource_path
	if cache.has(key):
		return cache[key]
	var img := tex.get_image()
	if img == null:
		cache[key] = tex
		return tex
	if img.is_compressed():
		img.decompress()
	var w := img.get_width()
	var h := img.get_height()
	if w > max_dim or h > max_dim:
		var new_w := max_dim if w >= h else int(w * float(max_dim) / float(h))
		var new_h := int(h * float(max_dim) / float(w)) if w >= h else max_dim
		img.resize(new_w, new_h, Image.INTERPOLATE_NEAREST)
	var has_alpha := img.detect_alpha() != Image.ALPHA_NONE
	var use_jpeg := prefer_jpeg and not has_alpha
	var dir := out_dir.path_join("textures_small")
	DirAccess.make_dir_recursive_absolute(dir)
	var base := (tex.resource_path.get_file().get_basename()).replace(" ", "_")
	while base.begins_with("tx_"):
		base = base.substr(3)
	var out_path := dir.path_join("tx_" + base + (".jpg" if use_jpeg else ".png"))
	if use_jpeg:
		img.save_jpg(out_path, int(clamp(jpeg_quality * 100.0, 1.0, 100.0)))
	else:
		img.save_png(out_path)
	var new_tex := ImageTexture.create_from_image(img)
	cache[key] = new_tex
	return new_tex

static func shrink_material_textures(mat: Material, cache: Dictionary, out_dir: String, max_dim: int, jpeg_quality: float) -> void:
	if mat == null:
		return
	if mat is StandardMaterial3D:
		var sm := mat as StandardMaterial3D
		if sm.albedo_texture != null:
			sm.albedo_texture = recompress_texture(sm.albedo_texture, cache, out_dir, max_dim, jpeg_quality, true)
		# Extreme PSX: remove normal/ORM
		sm.normal_texture = null
		sm.orm_texture = null
		if sm.emission_enabled and sm.emission_texture != null:
			sm.emission_texture = recompress_texture(sm.emission_texture, cache, out_dir, max_dim, jpeg_quality, true)

static func shrink_scene_textures(root: Node, out_dir: String, max_dim: int, jpeg_quality: float) -> void:
	var cache: Dictionary = {}
	var stack: Array = [root]
	while stack.size() > 0:
		var n: Node = stack.pop_back()
		if n is MeshInstance3D:
			var mi := n as MeshInstance3D
			if mi.material_override != null:
				shrink_material_textures(mi.material_override, cache, out_dir, max_dim, jpeg_quality)
			var m := mi.get_surface_override_material_count()
			for i in range(m):
				var sm := mi.get_surface_override_material(i)
				if sm != null:
					shrink_material_textures(sm, cache, out_dir, max_dim, jpeg_quality)
			var mesh := mi.mesh
			if mesh is ArrayMesh:
				var am := mesh as ArrayMesh
				var sc := am.get_surface_count()
				for si in range(sc):
					var mm := am.surface_get_material(si)
					if mm != null:
						shrink_material_textures(mm, cache, out_dir, max_dim, jpeg_quality)
		for c in n.get_children():
			if c is Node:
				stack.push_back(c)

static func export_scene_to_glb(scene_root: Node, save_path: String) -> bool:
	var doc := GLTFDocument.new()
	var state := GLTFState.new()
	var a := doc.append_from_scene(scene_root, state)
	if a != OK:
		return false
	var w := doc.write_to_filesystem(state, save_path)
	return w == OK

# GLTFPack Integration for further GLB optimization
static func optimize_glb_with_gltfpack(input_path: String, output_path: String, options: Dictionary = {}) -> bool:
	"""
	Optimize GLB file using gltfpack for maximum size reduction
	
	Options:
	- compression_level: 0-7 (default: 7 for maximum compression)
	- texture_quality: 0.0-1.0 (default: 0.8)
	- mesh_optimization: true/false (default: true)
	- texture_compression: "ktx2", "dxt", "etc2" (default: "ktx2")
	"""
	var default_options = {
		"compression_level": 7,
		"texture_quality": 0.8,
		"mesh_optimization": true,
		"texture_compression": "ktx2"
	}
	# Merge user options with defaults
	for key in options:
		default_options[key] = options[key]
	var gltfpack_path = _find_gltfpack_executable()
	if gltfpack_path == "":
		GameLogger.error("❌ gltfpack executable not found. Please install gltfpack from: https://github.com/zeux/meshoptimizer")
		return false
	var args = []
	# Compression
	args.append("-cc")
	# Texture quality
	args.append("-tq")
	args.append(str(default_options.texture_quality))
	# Texture compression is required when using -tq (texture quality)
	args.append("-tc")
	# Input/output - use explicit -i and -o flags
	args.append("-i")
	args.append(input_path)
	args.append("-o")
	args.append(output_path)
	# Execute gltfpack - try different Godot 4.3 signatures
	var output: Array = []
	var exit_code: int
	
	# Try the correct Godot 4.3 signature
	exit_code = OS.execute(gltfpack_path, args, true, output)
	
	if exit_code == 0:
		GameLogger.info("✅ GLB optimized with gltfpack: %s -> %s" % [input_path, output_path])
		return true
	else:
		GameLogger.error("❌ Failed to optimize GLB with gltfpack (exit %d)" % exit_code)
		if output.size() > 0:
			GameLogger.error("gltfpack output: %s" % "\n".join(output))
		return false

static func _find_gltfpack_executable() -> String:
	"""Find gltfpack executable in common locations"""
	var possible_paths = [
		"gltfpack",
		"./gltfpack",
		"../gltfpack",
		"bin/gltfpack",
		"tools/gltfpack",
		"Tools/gltfpack.exe",
		"../Tools/gltfpack.exe",
		"C:/Program Files/gltfpack/gltfpack.exe",
		"D:/tools/gltfpack/gltfpack.exe",
		"/usr/local/bin/gltfpack",
		"/opt/gltfpack/gltfpack"
	]
	for path in possible_paths:
		if _is_executable(path):
			return path
	return ""

static func _is_executable(path: String) -> bool:
	var file = FileAccess.open(path, FileAccess.READ)
	if file:
		file.close()
		return true
	return false

static func _execute_gltfpack(executable: String, args: Array) -> bool:
	GameLogger.info("🔧 Executing: %s %s" % [executable, " ".join(args)])
	var output: Array = []
	# Use the correct Godot 4.3 OS.execute signature
	var exit_code: int = OS.execute(executable, args, true, output)
	var success := exit_code == 0
	if success:
		GameLogger.info("✅ gltfpack executed successfully (exit code: %d)" % exit_code)
	else:
		GameLogger.error("❌ gltfpack failed (exit code: %d)" % exit_code)
		if output.size() > 0:
			GameLogger.error("gltfpack output: %s" % "\n".join(output))
	return success

static func batch_optimize_glb_files(input_dir: String, output_dir: String, options: Dictionary = {}) -> Dictionary:
	var results = {
		"success_count": 0,
		"failure_count": 0,
		"original_sizes": {},
		"optimized_sizes": {},
		"compression_ratios": {}
	}
	var dir = DirAccess.open(input_dir)
	if dir == null:
		GameLogger.error("❌ Cannot open input directory: %s" % input_dir)
		return results
	var output_dir_access = DirAccess.open(output_dir)
	if output_dir_access == null:
		var temp_dir = DirAccess.open(output_dir.get_base_dir())
		if temp_dir:
			temp_dir.make_dir_recursive(output_dir.get_file())
		output_dir_access = DirAccess.open(output_dir)
	dir.list_dir_begin()
	var filename = dir.get_next()
	while filename != "":
		if filename.to_lower().ends_with(".glb"):
			var input_path = input_dir.path_join(filename)
			var output_path = output_dir.path_join(filename.replace(".glb", "_optimized.glb"))
			var original_size = _get_file_size(input_path)
			results.original_sizes[filename] = original_size
			GameLogger.info("🔧 Optimizing: %s (%.2f MB)" % [filename, original_size / (1024.0 * 1024.0)])
			if optimize_glb_with_gltfpack(input_path, output_path, options):
				var optimized_size = _get_file_size(output_path)
				results.optimized_sizes[filename] = optimized_size
				var compression_ratio = float(optimized_size) / float(original_size)
				results.compression_ratios[filename] = compression_ratio
				GameLogger.info("✅ Optimized: %s (%.2f MB -> %.2f MB, %.1f%% of original)" % [
					filename,
					original_size / (1024.0 * 1024.0),
					optimized_size / (1024.0 * 1024.0),
					compression_ratio * 100.0
				])
				results.success_count += 1
			else:
				GameLogger.error("❌ Failed to optimize: %s" % filename)
				results.failure_count += 1
		filename = dir.get_next()
	dir.list_dir_end()
	GameLogger.info("📊 Batch optimization complete: %d success, %d failures" % [results.success_count, results.failure_count])
	return results

static func _get_file_size(file_path: String) -> int:
	var file = FileAccess.open(file_path, FileAccess.READ)
	if file:
		var size = file.get_length()
		file.close()
		return size
	return 0

static func get_optimization_presets() -> Dictionary:
	return {
		"extreme_psx": {
			"compression_level": 7,
			"texture_quality": 0.4,
			"mesh_optimization": true,
			"texture_compression": "ktx2"
		},
		"balanced": {
			"compression_level": 5,
			"texture_quality": 0.7,
			"mesh_optimization": true,
			"texture_compression": "ktx2"
		},
		"quality": {
			"compression_level": 3,
			"texture_quality": 0.9,
			"mesh_optimization": false,
			"texture_compression": "ktx2"
		},
		"mobile": {
			"compression_level": 6,
			"texture_quality": 0.6,
			"mesh_optimization": true,
			"texture_compression": "etc2"
		}
	}

static func optimize_with_preset(input_path: String, output_path: String, preset_name: String) -> bool:
	var presets = get_optimization_presets()
	if not presets.has(preset_name):
		GameLogger.error("❌ Unknown preset: %s. Available presets: %s" % [preset_name, ", ".join(presets.keys())])
		return false
	var options = presets[preset_name]
	GameLogger.info("🎯 Using optimization preset: %s" % preset_name)
	return optimize_glb_with_gltfpack(input_path, output_path, options)
