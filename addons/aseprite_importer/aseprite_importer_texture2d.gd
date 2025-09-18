@tool
extends EditorImportPlugin

const PACKING_TYPE_HORIZONTAL_STRIP := 0
const PACKING_TYPE_VERTICAL_STRIP := 1
const PACKING_TYPE_BY_ROWS := 2
const PACKING_TYPE_BY_COLUMNS := 3
const PACKING_TYPE_PACKED := 4

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
		return options.get("save_to_file/enabled") == true

	# Packing options have no effect when importing only the first frame
	if option_name.begins_with("packing/") and options.get("import/first_frame_only") == true:
		return false

	if option_name == "packing/constraints/fixed_rows": return options.get("packing/type") == PACKING_TYPE_BY_COLUMNS
	if option_name == "packing/constraints/fixed_columns": return options.get("packing/type") == PACKING_TYPE_BY_ROWS
	if option_name == "packing/constraints/fixed_width": return options.get("packing/type") in [PACKING_TYPE_BY_ROWS, PACKING_TYPE_PACKED]
	if option_name == "packing/constraints/fixed_height": return options.get("packing/type") in [PACKING_TYPE_BY_COLUMNS, PACKING_TYPE_PACKED]
	if option_name == "packing/constraints/fixed_size": return options.get("packing/type") == PACKING_TYPE_PACKED

	# When packed, always merge duplicates
	if option_name == "packing/merge_duplicates":
		return options.get("packing/type") != PACKING_TYPE_PACKED

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
			"usage": PROPERTY_USAGE_DEFAULT | PROPERTY_USAGE_UPDATE_ALL_IF_MODIFIED
		},

		{
			"name": "packing/merge_duplicates",
			"default_value": false,
		},
		{
			"name": "packing/ignore_empty",
			"default_value": false,
		},

		{
			"name": "packing/type",
			"default_value": PACKING_TYPE_HORIZONTAL_STRIP,
			"property_hint": PROPERTY_HINT_ENUM,
			"hint_string": "Horizontal Strip,Vertical Strip,By Rows,By Columns,Packed",
			"usage": PROPERTY_USAGE_DEFAULT | PROPERTY_USAGE_UPDATE_ALL_IF_MODIFIED
		},

		{
			"name": "packing/constraints/fixed_rows",
			"default_value": 0,
			"property_hint": PROPERTY_HINT_RANGE,
			"hint_string": "0,256,or_greater",
		},
		{
			"name": "packing/constraints/fixed_columns",
			"default_value": 0,
			"property_hint": PROPERTY_HINT_RANGE,
			"hint_string": "0,256,or_greater",
		},

		{
			"name": "packing/constraints/fixed_width",
			"default_value": 0,
			"property_hint": PROPERTY_HINT_RANGE,
			"hint_string": "0,2048,or_greater,suffix:px",
		},
		{
			"name": "packing/constraints/fixed_height",
			"default_value": 0,
			"property_hint": PROPERTY_HINT_RANGE,
			"hint_string": "0,2048,or_greater,suffix:px",
		},
		{
			"name": "packing/constraints/fixed_size",
			"default_value": Vector2i(0, 0),
			"hint_string": "suffix:px",
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
	var packing_type := int(options.get("packing/type", 0))

	var frame_count := 1 if import_first_frame_only else ase.frames.size()

	var canvas := Image.create_empty(
		ase.width * (frame_count if packing_type == PACKING_TYPE_HORIZONTAL_STRIP else 1),
		ase.height * (frame_count if packing_type == PACKING_TYPE_VERTICAL_STRIP else 1),
		false,
		Image.FORMAT_RGBA8
	)

	for frame_index in range(frame_count):
		# Duplicate as the array as it's used eslewhere plus it's readonly
		var cels: Array[AsepriteFile.Cel] = ase.frames[frame_index].cels.duplicate()

		cels.sort_custom(func(a: AsepriteFile.Cel, b: AsepriteFile.Cel):
			var orderA := a.layer_index + a.z_index
			var orderB := b.layer_index + b.z_index
			return (orderA < orderB) || (orderA == orderB && a.z_index - b.z_index)
		)

		for idx in range(cels.size()):
			var cel := cels[idx]

			# Grab the "real" cel index, "idx" is the index in the sorted array
			# not the index in the frame cels array
			var cel_index := ase.frames[frame_index].cels.find(cel)
			var img := ase.get_frame_cel_image(frame_index, cel_index)

			var layer := ase.layers[cel.layer_index]

			# Adjust the opacity
			for y in range(img.get_height()):
				for x in range(img.get_width()):
					var c := img.get_pixel(x, y)

					# First apply the cel opacity
					c.a *= cel.opacity / 255.0

					# Then apply the layer opacity
					c.a *= layer.opacity / 255.0

					img.set_pixel(x, y, c)

			var dst := Vector2i(cel.x, cel.y)

			if packing_type == PACKING_TYPE_HORIZONTAL_STRIP:
				# Horizontal strip
				dst += Vector2i(frame_index * ase.width, 0)

			elif packing_type == PACKING_TYPE_VERTICAL_STRIP:
				# Vertical strip
				dst += Vector2i(0, frame_index * ase.height)

			canvas.blend_rect(
				img,
				Rect2i(0, 0, img.get_width(), img.get_height()),
				dst
			)

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
