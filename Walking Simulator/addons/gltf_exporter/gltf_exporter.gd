@tool
extends EditorPlugin

# GLTF Exporter Addon
# Allows programmatic export of scenes to GLTF/GLB format
# Adapted from the OBJ exporter pattern

const PLUGIN_NAME = "GLTF Exporter"

func _enter_tree():
	# Add the export functionality
	add_tool_menu_item("Export GLTF/GLB", _export_gltf)
	print("GLTF Exporter plugin loaded")

func _exit_tree():
	# Clean up when plugin is disabled
	remove_tool_menu_item("Export GLTF/GLB")
	print("GLTF Exporter plugin unloaded")

func _export_gltf():
	"""Export the current scene to GLTF/GLB format"""
	var current_scene = get_editor_interface().get_edited_scene_root()
	if not current_scene:
		print("No scene to export")
		return
	
	# Show export dialog
	_show_export_dialog(current_scene)

func _show_export_dialog(scene: Node):
	"""Show the export dialog for GLTF/GLB export"""
	var dialog = AcceptDialog.new()
	dialog.title = "Export GLTF/GLB"
	dialog.dialog_text = "Choose export format and options"
	
	# Add format selection
	var format_container = VBoxContainer.new()
	var format_label = Label.new()
	format_label.text = "Export Format:"
	format_container.add_child(format_label)
	
	var format_option = OptionButton.new()
	format_option.add_item("GLTF (.gltf)", 0)
	format_option.add_item("GLB (.glb)", 1)
	format_option.select(1)  # Default to GLB
	format_container.add_child(format_option)
	
	# Add options
	var options_container = VBoxContainer.new()
	
	var embed_images = CheckBox.new()
	embed_images.text = "Embed Images"
	embed_images.button_pressed = true
	options_container.add_child(embed_images)
	
	var embed_buffers = CheckBox.new()
	embed_buffers.text = "Embed Buffers"
	embed_buffers.button_pressed = true
	options_container.add_child(embed_buffers)
	
	var export_materials = CheckBox.new()
	export_materials.text = "Export Materials"
	export_materials.button_pressed = true
	options_container.add_child(export_materials)
	
	var export_meshes = CheckBox.new()
	export_meshes.text = "Export Meshes"
	export_meshes.button_pressed = true
	options_container.add_child(export_meshes)
	
	# Add to dialog
	dialog.add_child(format_container)
	dialog.add_child(options_container)
	
	# Connect signals
	dialog.confirmed.connect(_on_export_confirmed.bind(scene, format_option, embed_images, embed_buffers, export_materials, export_meshes))
	
	# Show dialog
	get_editor_interface().get_base_control().add_child(dialog)
	dialog.popup_centered()

func _on_export_confirmed(scene: Node, format_option: OptionButton, embed_images: CheckBox, embed_buffers: CheckBox, export_materials: CheckBox, export_meshes: CheckBox):
	"""Handle export confirmation"""
	var format = format_option.get_selected_id()
	var format_name = "gltf" if format == 0 else "glb"
	
	# Get export options
	var options = {
		"embed_images": embed_images.button_pressed,
		"embed_buffers": embed_buffers.button_pressed,
		"export_materials": export_materials.button_pressed,
		"export_meshes": export_meshes.button_pressed
	}
	
	# Show file dialog
	var file_dialog = FileDialog.new()
	file_dialog.title = "Save GLTF/GLB File"
	file_dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	file_dialog.add_filter("*." + format_name, format_name.upper() + " Files")
	file_dialog.current_file = scene.name + "." + format_name
	
	file_dialog.file_selected.connect(_on_file_selected.bind(scene, format, options))
	
	get_editor_interface().get_base_control().add_child(file_dialog)
	file_dialog.popup_centered()

func _on_file_selected(file_path: String, format: int, options: Dictionary):
	"""Handle file selection and perform export"""
	print("Exporting to: " + file_path)
	print("Format: " + ("GLTF" if format == 0 else "GLB"))
	print("Options: ", options)
	
	# Perform the actual export
	var result = export_scene_to_gltf(file_path, format, options)
	if result == OK:
		print("✅ Export successful!")
	else:
		print("❌ Export failed!")

func export_scene_to_gltf(file_path: String, format: int, options: Dictionary) -> int:
	"""Export a scene to GLTF/GLB format using Godot's built-in GLTF API"""
	print("🔄 Starting GLTF export...")
	
	# Get the current scene root
	var current_scene = get_editor_interface().get_edited_scene_root()
	if not current_scene:
		print("❌ No scene to export")
		return FAILED
	
	# Use Godot's built-in GLTF export API as documented
	var gltf_document = GLTFDocument.new()
	var gltf_state = GLTFState.new()
	
	# Convert the scene to GLTF format
	var append_result = gltf_document.append_from_scene(current_scene, gltf_state)
	if append_result != OK:
		print("❌ Failed to convert scene to GLTF format")
		return FAILED
	
	# Save as GLTF/GLB - the file extension determines the format
	var write_result = gltf_document.write_to_filesystem(gltf_state, file_path)
	if write_result != OK:
		print("❌ Failed to write GLTF/GLB file")
		return FAILED
	
	print("✅ GLTF/GLB export successful using Godot's built-in API")
	return OK

# Public API for other scripts to use
func export_scene(scene_path: String, output_path: String, format: String = "glb") -> int:
	"""Public method to export a scene to GLTF/GLB format"""
	print("🔄 Exporting scene: " + scene_path + " to " + output_path)
	
	# Load the scene
	var scene = load(scene_path)
	if not scene:
		print("❌ Failed to load scene: " + scene_path)
		return FAILED
	
	# Instantiate the scene to get the actual node tree
	var scene_instance = scene.instantiate()
	if not scene_instance:
		print("❌ Failed to instantiate scene")
		return FAILED
	
	# Use Godot's built-in GLTF export API as documented
	var gltf_document = GLTFDocument.new()
	var gltf_state = GLTFState.new()
	
	# Convert the scene to GLTF format
	var append_result = gltf_document.append_from_scene(scene_instance, gltf_state)
	if append_result != OK:
		print("❌ Failed to convert scene to GLTF format")
		scene_instance.queue_free()
		return FAILED
	
	# Save as GLTF/GLB - the file extension determines the format
	var write_result = gltf_document.write_to_filesystem(gltf_state, output_path)
	if write_result != OK:
		print("❌ Failed to write GLTF/GLB file")
		scene_instance.queue_free()
		return FAILED
	
	# Clean up
	scene_instance.queue_free()
	
	print("✅ GLTF/GLB export successful using Godot's built-in API")
	return OK

func shrink_scene_textures(root: Node, out_dir: String, max_dim: int, jpeg_quality: float) -> void:
	GltfExportUtils.shrink_scene_textures(root, out_dir, max_dim, jpeg_quality)

func export_scene_to_glb(scene_root: Node, save_path: String) -> bool:
	return GltfExportUtils.export_scene_to_glb(scene_root, save_path)
