@tool
extends EditorImportPlugin

var presets := [
	{
		"name": "Default",
		"options": [
		]
	},
]

func _get_importer_name() -> String: return "aseprite.importer.tileset"
func _get_visible_name() -> String: return "TileSet (Aseprite)"
func _get_recognized_extensions() -> PackedStringArray: return ["aseprite", "ase"]
func _get_resource_type() -> String: return "TileSet"
func _get_save_extension() -> String: return "tres"
func _get_priority() -> float: return 1.0
func _get_import_order() -> int: return IMPORT_ORDER_DEFAULT
func _get_preset_count() -> int: return presets.size()
func _get_preset_name(preset_index: int) -> String: return presets[preset_index]["name"]

func _get_import_options(path: String, preset_index: int) -> Array:
	var options = presets[preset_index]["options"].duplicate(true)
	return options

func _get_option_visibility(path: String, option_name: StringName, options: Dictionary) -> bool:
	return true

func _import(source_file: String, save_path: String, options: Dictionary, platform_variants: Array[String], gen_files: Array[String]) -> int:
	var err := OK

	var ase := AsepriteFile.open(source_file)
	if ase == null:
		push_warning("Aseprite - Failed to open file: %s" % error_string(AsepriteFile.get_open_error()))
		return err

	if ase.layers.size() == 0:
		push_warning("Aseprite - No layers found in the file.")
		return ERR_FILE_CANT_OPEN

	if ase.frames.size() == 0:
		push_warning("Aseprite - No frames found in the file.")
		return ERR_FILE_CANT_OPEN

	if ase.tilesets.size() == 0:
		push_warning("Aseprite - No tilesets found in the file.")
		return ERR_FILE_CANT_OPEN

	var res := TileSet.new()

	for layer_index in range(ase.layers.size()):
		var layer := ase.layers[layer_index]

		if layer.type != AsepriteFile.LAYER_TYPE_TILEMAP:
			continue

		var tileset := ase.tilesets[layer.tileset_index]

		var canvas := ase.get_layer_frame_image(layer_index, 0)

		var texture := PortableCompressedTexture2D.new()
		texture.create_from_image(canvas, PortableCompressedTexture2D.COMPRESSION_MODE_LOSSLESS)

		var tile_set_atlas_source := TileSetAtlasSource.new()
		tile_set_atlas_source.texture = texture
		tile_set_atlas_source.texture_region_size = Vector2i(tileset.tile_width, tileset.tile_height)
		tile_set_atlas_source.separation = Vector2i(0, 0)
		tile_set_atlas_source.margins = Vector2i(0, 0)

		for x in range(ase.width / tileset.tile_width):
			for y in range(canvas.get_height() / tileset.tile_height):
				tile_set_atlas_source.create_tile(Vector2i(x, y))

		tile_set_atlas_source.clear_tiles_outside_texture()

		res.add_source(tile_set_atlas_source)

	var filename := save_path + "." + _get_save_extension()
	err = ResourceSaver.save(res, filename)

	if err != OK:
		printerr("Aseprite - %s" % error_string(err))
		return err

	# Signal the editor we have generated a file
	gen_files.append(filename)

	return OK
