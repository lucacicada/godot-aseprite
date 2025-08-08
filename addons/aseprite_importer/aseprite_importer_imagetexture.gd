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
	return "aseprite.importer.imagetexture"

func _get_visible_name() -> String:
	return "ImageTexture (Aseprite)"

func _get_recognized_extensions() -> PackedStringArray:
	return ["aseprite", "ase"]

func _get_resource_type() -> String:
	return "ImageTexture"

func _get_save_extension() -> String:
	return "tres"

func _get_priority() -> float:
	return 1.0

func _get_import_order() -> int:
	return 0

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
	var container = PackedDataContainer.new()
	return ResourceSaver.save(container, "%s.%s" % [save_path, _get_save_extension()])

	var err := OK

	var ase_file := AsepriteFile.new()

	err = ase_file.open(source_file)
	if err != OK:
		push_warning("Aseprite - Failed to open file: %s" % error_string(err))
		return err

	if ase_file.layers.size() == 0:
		push_warning("Aseprite - No layers found in the file.")
		return ERR_FILE_CANT_OPEN

	if ase_file.frames.size() == 0:
		push_warning("Aseprite - No frames found in the file.")
		return ERR_FILE_CANT_OPEN


	for layer_index in range(ase_file.layers.size()):
		var layer := ase_file.layers[layer_index]

		# Skip fully transparent layers
		if layer.opacity == 0:
			continue

		# Follow: https://docs.godotengine.org/en/3.5/tutorials/assets_pipeline/importing_scenes.html#remove-nodes-noimp
		if layer.name.ends_with("-noimp"):
			continue

		if layer.name.containsn("collision") or layer.name.ends_with("-col"):
			continue


		var frame := ase_file.frames[0]
		var frame_img := frame.get_image(layer_index)

		if not frame_img:
			push_warning("Aseprite - No image found for layer '%s'." % layer.name)
			return ERR_FILE_CANT_OPEN

		err = frame_img.save_png(source_file + ".png")

		if err != OK:
			push_error("Aseprite - %s" % error_string(err))
			return err

		gen_files.append(source_file + ".png")
		append_import_external_resource(source_file + ".png")

		var filename := save_path + "." + _get_save_extension()
		err = ResourceSaver.save(ResourceLoader.load(source_file + ".png"), filename)

		return err


	return OK
