@tool
extends EditorImportPlugin

func _get_importer_name() -> String: return "aseprite.importer.texture2d"
func _get_visible_name() -> String: return "Texture2D (Aseprite)"
func _get_recognized_extensions() -> PackedStringArray: return ["aseprite", "ase"]
func _get_resource_type() -> String: return "Texture2D"
func _get_save_extension() -> String: return "res"
func _get_priority() -> float: return 2.0
func _get_import_order() -> int: return IMPORT_ORDER_DEFAULT
func _get_preset_count() -> int: return 1
func _get_option_visibility(path: String, option_name: StringName, options: Dictionary) -> bool: return true
func _get_preset_name(preset_index: int) -> String: return "Default"
func _get_import_options(path: String, preset_index: int) -> Array[Dictionary]:
	return [
		{
			"name": "external/path",
			"default_value": "",
			"property_hint": PROPERTY_HINT_SAVE_FILE,
			"hint_string": "*.png",
		}
	]

func _import(source_file: String, save_path: String, options: Dictionary, platform_variants: Array[String], gen_files: Array[String]) -> int:
	var err := OK

	var ase := AsepriteFile.open(source_file)

	if ase == null:
		push_warning("Aseprite - Failed to open file: %s" % error_string(AsepriteFile.get_open_error()))
		return err

	var layer_index := ase.layers.find_custom(func(layer: AsepriteFile.Layer) -> bool:
		if layer.is_hidden():
			return false

		if layer.opacity == 0:
			return false

		if layer.type != 0:
			return false

		return true
	)

	if layer_index < 0:
		push_warning("Aseprite - No visible layers found in the file.")
		return FAILED

	if ase.is_layer_frame_empty(layer_index, 0):
		push_warning("Aseprite - The first frame of the visible layer is empty.")
		return FAILED

	var layer_image := ase.get_layer_frame_image(layer_index, 0)

	var option_export_path: String = options.get("external/path", "")

	if option_export_path.is_empty():
		var texture := PortableCompressedTexture2D.new()
		texture.create_from_image(layer_image, PortableCompressedTexture2D.COMPRESSION_MODE_LOSSLESS)

		err = ResourceSaver.save(texture, save_path + "." + _get_save_extension())

		if err != OK:
			push_warning("Aseprite - Failed to save resource: %s" % error_string(err))
			return err
	else:
		err = layer_image.save_png(option_export_path)

		if err != OK:
			push_warning("Aseprite - Failed to save image: %s" % error_string(err))
			return err

		EditorInterface.get_resource_filesystem().update_file(option_export_path)

		err = append_import_external_resource(option_export_path)
		if err != OK:
			push_warning("Aseprite - Failed to register external resource: %s" % error_string(err))
			return err

		var texture := ResourceLoader.load(option_export_path, "Texture2D", ResourceLoader.CACHE_MODE_REPLACE)

		err = ResourceSaver.save(texture, save_path + "." + _get_save_extension())

		if err != OK:
			push_warning("Aseprite - Failed to save resource: %s" % error_string(err))
			return err

	return err
