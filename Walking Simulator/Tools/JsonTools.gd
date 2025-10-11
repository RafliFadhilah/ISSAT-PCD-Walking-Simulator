
func load_json(file_path: String) -> Dictionary:
	print("Loading JSON from:", file_path)
	var file = FileAccess.open(file_path, FileAccess.READ)
	var json = JSON.new()
	if file == null:
		push_error("Gagal membuka file: %s" % file_path)
		return json.get_data()

	var json_text = file.get_as_text()
	file.close()

	var parse_result = json.parse(json_text)

	if parse_result != OK:
		push_error("Error parsing JSON di %s" % file_path)
		return json.get_data()

	return json.get_data()
