@tool
extends EditorImportPlugin

func _get_importer_name() -> String: return "aseprite.importer.texture2d"
func _get_visible_name() -> String: return "Texture2D (Aseprite)"
func _get_recognized_extensions() -> PackedStringArray: return ["aseprite"]
func _get_resource_type() -> String: return "Texture2D"
func _get_save_extension() -> String: return "res"
func _get_priority() -> float: return 2.0
func _get_import_order() -> int: return IMPORT_ORDER_DEFAULT
func _get_preset_count() -> int: return 1
func _get_preset_name(preset_index: int) -> String: return "Default"

func _get_option_visibility(path: String, option_name: StringName, options: Dictionary) -> bool:
	# If path is empty, the user is editing the default project settings
	if path.is_empty():
		# Hide all options related to saving to file
		# these options make sense only when importing a specific file
		if option_name.begins_with("save_to_file/"):
			return false

	if option_name == "save_to_file/path":
		return options.get("save_to_file/enabled", false) == true

	return true

func _get_import_options(path: String, preset_index: int) -> Array[Dictionary]:
	var options: Array[Dictionary] = [
		{
			"name": "save_to_file/enabled",
			"default_value": false,
			"usage": PROPERTY_USAGE_DEFAULT | PROPERTY_USAGE_UPDATE_ALL_IF_MODIFIED
		},
		{
			"name": "save_to_file/path",
			"default_value": "",
			"property_hint": PROPERTY_HINT_SAVE_FILE,
			"hint_string": "*.png",
		},

		{
			"name": "import/only_visible_layers",
			"default_value": true,
		},
		{
			"name": "import/first_frame_only",
			"default_value": true,
		},
	]

	return options

func _import(source_file: String, save_path: String, options: Dictionary, platform_variants: Array[String], gen_files: Array[String]) -> int:
	var err := OK

	var ase := AsepriteFile.open(source_file)
	if ase == null:
		err = AsepriteFile.get_open_error()
		push_error("Aseprite - Failed to open file: %s" % error_string(err))
		return err

	var import_only_visible_layers: bool = options.get("import/only_visible_layers", true) == true
	var import_first_frame_only: bool = options.get("import/first_frame_only", true) == true

	var canvas := Image.create_empty(ase.width, ase.height, false, Image.FORMAT_RGBA8)

	for layer_index in range(ase.layers.size()):
		var layer := ase.layers[layer_index]

		# Skip fully transparent layers
		if layer.opacity == 0:
			continue

		# Skip group layers, they are empty
		if layer.is_group_layer():
			continue

		if import_only_visible_layers and not layer.is_visible():
			continue

		var img := ase.get_layer_frame_image(layer_index, 0)
		canvas.blit_rect(img, Rect2i(Vector2i.ZERO, img.get_size()), Vector2i.ZERO)

	var texture = null

	if options.get("save_to_file/enabled", false) == true:
		var export_to_file_path := String(options.get("save_to_file/path", ""))

		# The user have not set a valid path
		if export_to_file_path.is_empty():
			push_error("Aseprite Importer - The export path is empty.")
			return ERR_INVALID_PARAMETER

		# Support for "uid://" paths
		# Godot create a UID when setting a path from the file dialog
		# On re-import, the path will be a "uid://" path
		if export_to_file_path.begins_with("uid://"):
			var uid := ResourceUID.text_to_id(export_to_file_path)

			if uid == ResourceUID.INVALID_ID:
				push_error("Aseprite Importer - Invalid export path UID: \"%s\"" % export_to_file_path)
				return ERR_INVALID_PARAMETER

			# Check if the UID has been loaded in the project
			elif not ResourceUID.has_id(uid):
				push_error("Aseprite Importer - Cannot find export path UID: \"%s\"" % export_to_file_path)
				return ERR_INVALID_PARAMETER

			export_to_file_path = ResourceUID.get_id_path(uid)

			# Make the path is a resource file path
			# :: is used for nested path in sub-resources, which is not supported here
			if not export_to_file_path.begins_with("res://") or export_to_file_path.contains("::"):
				push_error("Aseprite Importer - Invalid resource export path: \"%s\"" % export_to_file_path)
				return ERR_INVALID_PARAMETER

		var export_to_file_path_ext := export_to_file_path.get_extension().to_lower()

		if export_to_file_path_ext not in ["png", "webp"]:
			push_error("Aseprite Importer - Unsupported export file extension: \"%s\". Supported extensions are: .png, .webp." % export_to_file_path_ext)
			return ERR_INVALID_PARAMETER

		# Create the directory
		# Godot typically create the directory from the file dialog
		# It is safe to create a directory, we do not run the risk to delete existing files
		err = DirAccess.make_dir_recursive_absolute(export_to_file_path.get_base_dir())
		if err != OK:
			return err

		match export_to_file_path_ext:
			"jpg", "jpeg":
				err = canvas.save_jpg(export_to_file_path)
			"webp":
				err = canvas.save_webp(export_to_file_path)
			_:
				err = canvas.save_png(export_to_file_path)

		if err != OK:
			return err

		EditorInterface.get_resource_filesystem().update_file(export_to_file_path)

		err = append_import_external_resource(export_to_file_path)
		if err != OK:
			return err

		texture = ResourceLoader.load(export_to_file_path, "Texture2D", ResourceLoader.CACHE_MODE_REPLACE)

		if texture == null:
			return ERR_CANT_ACQUIRE_RESOURCE

		if not texture is Texture2D:
			return ERR_CANT_ACQUIRE_RESOURCE

	else:
		texture = PortableCompressedTexture2D.new()
		texture.create_from_image(canvas, PortableCompressedTexture2D.COMPRESSION_MODE_LOSSLESS)

	err = ResourceSaver.save(texture, save_path + "." + _get_save_extension())

	return err
