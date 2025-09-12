@tool
extends EditorImportPlugin

func _get_importer_name() -> String: return "aseprite.importer.tileset"
func _get_visible_name() -> String: return "TileSet (Aseprite)"
func _get_recognized_extensions() -> PackedStringArray: return ["aseprite"]
func _get_resource_type() -> String: return "TileSet"
func _get_save_extension() -> String: return "tres"
func _get_priority() -> float: return 1.0
func _get_import_order() -> int: return IMPORT_ORDER_DEFAULT
func _get_preset_count() -> int: return 1
func _get_preset_name(preset_index: int) -> String: return "Default"

func _get_option_visibility(path: String, option_name: StringName, options: Dictionary) -> bool:
	if option_name == "export/path":
		return options.get("export/enabled", false)

	if option_name == "tile_set/tile_layout":
		return options.get("tile_set/tile_shape", TileSet.TILE_SHAPE_SQUARE) != TileSet.TILE_SHAPE_SQUARE

	if option_name == "tile_set/tile_offset_axis":
		return options.get("tile_set/tile_shape", TileSet.TILE_SHAPE_SQUARE) != TileSet.TILE_SHAPE_SQUARE

	return true

func _get_import_options(path: String, preset_index: int) -> Array[Dictionary]:
	var options: Array[Dictionary] = [
		{
			"name": "export/enabled",
			"default_value": false,
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
			"name": "tile_set/tile_shape",
			"default_value": TileSet.TILE_SHAPE_SQUARE,
			"property_hint": PROPERTY_HINT_ENUM,
			"hint_string": "Square,Isometric,Half-Offset Square,Hexagon",
			"usage": PROPERTY_USAGE_DEFAULT | PROPERTY_USAGE_UPDATE_ALL_IF_MODIFIED
		},
		{
			"name": "tile_set/tile_layout",
			"default_value": TileSet.TILE_LAYOUT_STACKED,
			"property_hint": PROPERTY_HINT_ENUM,
			"hint_string": "Stacked,Stacked Offset,Stairs Right,Stairs Down,Diamond Right,Diamond Down",
		},
		{
			"name": "tile_set/tile_offset_axis",
			"default_value": TileSet.TILE_OFFSET_AXIS_HORIZONTAL,
			"property_hint": PROPERTY_HINT_ENUM,
			"hint_string": "Horizontal Offset,Vertical Offset",
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

	if ase.tilesets.size() == 0:
		push_error("Aseprite - No tilesets found in file, convert a layer into a tilemap in Aseprite first.")
		return ERR_INVALID_DATA

	var tile_set := TileSet.new()

	# Use the first tileset to set the tile size
	for tileset in ase.tilesets:
		tile_set.tile_size = Vector2i(tileset.tile_width, tileset.tile_height)
		break

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

		tile_set.add_source(tile_set_atlas_source)

	var filename := save_path + "." + _get_save_extension()
	err = ResourceSaver.save(tile_set, filename)

	if err != OK:
		return err

	return OK
