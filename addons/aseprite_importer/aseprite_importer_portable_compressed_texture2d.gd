@tool
extends EditorImportPlugin

var presets := [
	{
		"name": "Default",
		"options": [
		]
	},
]

func _get_importer_name() -> String:
	return "aseprite.importer.portable_compressed_texture2d"

func _get_visible_name() -> String:
	return "PortableCompressedTexture2D (Aseprite)"

func _get_recognized_extensions() -> PackedStringArray:
	return ["aseprite", "ase"]

func _get_resource_type() -> String:
	return "PortableCompressedTexture2D"

func _get_save_extension() -> String:
	return "res"

func _get_priority() -> float:
	return 1.0

func _get_import_order() -> int:
	return IMPORT_ORDER_DEFAULT

func _get_preset_count() -> int:
	return presets.size()

func _get_preset_name(preset_index: int) -> String:
	return presets[preset_index]["name"]

func _get_import_options(path: String, preset_index: int) -> Array:
	var options = presets[preset_index]["options"].duplicate(true)
	return options

func _get_option_visibility(path: String, option_name: StringName, options: Dictionary) -> bool:
	return true

func _import(source_file: String, save_path: String, options: Dictionary, platform_variants: Array[String], gen_files: Array[String]) -> int:
	var err := OK

	var ase_file := AsepriteFile.new()

	err = ase_file.open(source_file)

	if err != OK:
		push_warning("Aseprite - Failed to open file: %s" % error_string(err))
		return err

	if ase_file.layers.size() == 0:
		push_warning("Aseprite - No layers found in the file.")
		return ERR_FILE_CORRUPT

	if ase_file.frames.size() == 0:
		push_warning("Aseprite - No frames found in the file.")
		return ERR_FILE_CORRUPT

	var layer_index := ase_file.layers.find_custom(func(layer: AsepriteFile.Layer) -> bool:
		if layer.is_hidden():
			return false

		if layer.opacity == 0:
			return false

		if layer.type != 0:
			return false

		return true
	)

	if layer_index == -1:
		push_warning("Aseprite - No visible layers found in the file.")
		return FAILED

	if ase_file.is_layer_frame_empty(layer_index, 0):
		push_warning("Aseprite - The first frame of the visible layer is empty.")
		return FAILED

	var layer_image := ase_file.get_layer_frame_image(layer_index, 0)
	var texture := PortableCompressedTexture2D.new()
	texture.create_from_image(layer_image, PortableCompressedTexture2D.COMPRESSION_MODE_LOSSLESS)

	err = ResourceSaver.save(texture, save_path + "." + _get_save_extension())

	if err != OK:
		push_warning("Aseprite - Failed to save resource: %s" % error_string(err))
		return err

	return err
