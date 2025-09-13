@tool
extends EditorImportPlugin

func _get_importer_name() -> String: return "aseprite.importer.texture2d"
func _get_visible_name() -> String: return "Texture2D (Aseprite)"
func _get_recognized_extensions() -> PackedStringArray: return ["aseprite"]
func _get_resource_type() -> String: return "Texture2D"
func _get_save_extension() -> String: return "res"
func _get_priority() -> float: return 2.0
func _get_import_order() -> int: return IMPORT_ORDER_DEFAULT
func _get_preset_count() -> int: return 2
func _get_preset_name(preset_index: int) -> String:
	match preset_index:
		1: return "Export"
		_: return "Default"

func _get_option_visibility(path: String, option_name: StringName, options: Dictionary) -> bool:
	if option_name == "export/path": return options.get("export/enabled", false)
	if option_name.begins_with("compress/"): return not options.get("export/enabled", false)
	return true

func _get_import_options(path: String, preset_index: int) -> Array[Dictionary]:
	return [
		{
			"name": "export/enabled",
			"default_value": preset_index == 1,
			"usage": PROPERTY_USAGE_DEFAULT | PROPERTY_USAGE_UPDATE_ALL_IF_MODIFIED
		},
		{
			"name": "export/path",
			"default_value": "",
			"property_hint": PROPERTY_HINT_SAVE_FILE,
			"hint_string": "*.png",
			"usage": PROPERTY_USAGE_DEFAULT | PROPERTY_USAGE_UPDATE_ALL_IF_MODIFIED
		},
		{
			"name": "compress/mode",
			"default_value": 0,
			"property_hint": PROPERTY_HINT_ENUM,
			"hint_string": "Lossless,Lossy,VRAM Compressed,VRAM Uncompressed,Basis Universal",
			"usage": PROPERTY_USAGE_DEFAULT | PROPERTY_USAGE_UPDATE_ALL_IF_MODIFIED
		}
	]

func _import(source_file: String, save_path: String, options: Dictionary, platform_variants: Array[String], gen_files: Array[String]) -> int:
	var err := OK

	var ase := AsepriteFile.open(source_file)

	if ase == null:
		err = AsepriteFile.get_open_error()
		push_error("Aseprite - Failed to open file: %s" % error_string(err))
		return err

	var canvas := Image.create_empty(ase.width, ase.height, false, Image.FORMAT_RGBA8)

	for layer_index in range(ase.layers.size()):
		var layer := ase.layers[layer_index]

		if layer.opacity == 0:
			continue

		if not layer.is_normal_layer():
			continue

		var img := ase.get_layer_frame_image(layer_index, 0)
		canvas.blit_rect(img, Rect2i(Vector2i.ZERO, img.get_size()), Vector2i.ZERO)

	if options.get("export/enabled", false):
		var option_export_path: String = options.get("export/path", "")

		# Automatically determine the export path if not set
		if option_export_path.is_empty():
			var basedir := source_file.get_base_dir()
			var filename := source_file.get_file().get_basename() + ".png"
			option_export_path = basedir.path_join(filename)

		err = DirAccess.make_dir_recursive_absolute(option_export_path.get_base_dir())
		if err != OK:
			return err

		err = canvas.save_png(option_export_path)
		if err != OK:
			return err

		EditorInterface.get_resource_filesystem().update_file(option_export_path)

		err = append_import_external_resource(option_export_path)
		if err != OK:
			return err

		var texture := ResourceLoader.load(option_export_path, "Texture2D", ResourceLoader.CACHE_MODE_REPLACE)
		if texture == null:
			return ERR_CANT_ACQUIRE_RESOURCE

		err = ResourceSaver.save(texture, save_path + "." + _get_save_extension())

		if err != OK:
			return err

		return err

	var texture := PortableCompressedTexture2D.new()
	texture.create_from_image(canvas, PortableCompressedTexture2D.COMPRESSION_MODE_LOSSLESS)

	err = ResourceSaver.save(texture, save_path + "." + _get_save_extension())

	return err
