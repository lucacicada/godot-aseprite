@tool
extends EditorImportPlugin

func _get_importer_name() -> String: return "aseprite.importer.tileset"
func _get_visible_name() -> String: return "TileSet (Aseprite)"
func _get_recognized_extensions() -> PackedStringArray: return ["aseprite"]
func _get_resource_type() -> String: return "TileSet"
func _get_save_extension() -> String: return "res"
func _get_priority() -> float: return 1.0
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

	if option_name == "tile_set/tile_layout":
		return options.get("tile_set/tile_shape", TileSet.TILE_SHAPE_SQUARE) != TileSet.TILE_SHAPE_SQUARE

	if option_name == "tile_set/tile_offset_axis":
		return options.get("tile_set/tile_shape", TileSet.TILE_SHAPE_SQUARE) != TileSet.TILE_SHAPE_SQUARE

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

# How Aseprite tilesets work:
# A tileset is a collection of tiles
# A tilemap layer uses a grid to place tiles from a specific tileset
#
# Frame 0 is the base frame, each frame after is the cell animation frame
#
# Each tileset is a terrain-set
# Each layer in a tileset is a terrain
# If a tile do not exist in a layer, it is not part of a terrain and thus cannot have a bitmask set
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

	# Find a default bitmask layer, if any
	var default_bitmask_layer_index := ase.layers.find_custom(func(layer: AsepriteFile.Layer) -> bool:
		return layer.child_level == 0 and layer.is_normal_layer() and layer.name.containsn("Default Bitmask")
	)

	var tile_set := TileSet.new()

	for tileset_index in range(ase.tilesets.size()):
		var tileset := ase.tilesets[tileset_index]

		# Debug info, usefull for users, Aseprite tilemaps are very finicky
		print_rich("[color=#808080]Tileset: Name \"%s\", Index %d, Tile Size %dx%d, Tiles Count: %d[/color]" % [
			tileset.name,
			tileset_index,
			tileset.tile_width,
			tileset.tile_height,
			tileset.tiles_count,
		])

		var canvas := Image.create_empty(
			tileset.tile_width * tileset.tiles_count,
			tileset.tile_height,
			false,
			Image.FORMAT_RGBA8,
		)

		for tile_id in range(tileset.tiles_count):
			var tile_image := ase.get_tile_image(tileset_index, tile_id)
			canvas.blit_rect(
				tile_image,
				Rect2i(Vector2i.ZERO, tile_image.get_size()),
				Vector2i(tileset.tile_width * tile_id, 0),
			)

		var texture := PortableCompressedTexture2D.new()
		texture.create_from_image(canvas, PortableCompressedTexture2D.COMPRESSION_MODE_LOSSLESS)

		var atlas_source := TileSetAtlasSource.new()
		atlas_source.texture = texture
		atlas_source.texture_region_size = Vector2i(tileset.tile_width, tileset.tile_height)
		atlas_source.separation = Vector2i(0, 0)
		atlas_source.margins = Vector2i(0, 0)
		atlas_source.resource_name = tileset.name

		for tile_id in range(tileset.tiles_count):
			atlas_source.create_tile(Vector2i(tile_id, 0))

		var source_layer_index := ase.layers.find_custom(func(layer: AsepriteFile.Layer) -> bool:
			return layer.is_tilemap_layer() and layer.tileset_index == tileset_index
		)
		var source_layer := null if source_layer_index == -1 else ase.layers[source_layer_index]

		# Use this layer to fund matching properties
		var bitmask_layer_index: int = -1
		var collision_layer_index: int = -1
		var occlusion_layer_index: int = -1

		if source_layer:
			var source_layer_name := source_layer.name.strip_escapes().strip_edges().to_lower()
			bitmask_layer_index = ase.layers.find_custom(func(layer: AsepriteFile.Layer) -> bool:
				var layer_name := layer.name.strip_escapes().strip_edges().to_lower()
				return layer.is_normal_layer() and layer_name.ends_with("bitmask") and layer_name.begins_with(source_layer_name)
			)
			collision_layer_index = ase.layers.find_custom(func(layer: AsepriteFile.Layer) -> bool:
				var layer_name := layer.name.strip_escapes().strip_edges().to_lower()
				return layer.is_normal_layer() and layer_name.ends_with("collision") and layer_name.begins_with(source_layer_name)
			)
			occlusion_layer_index = ase.layers.find_custom(func(layer: AsepriteFile.Layer) -> bool:
				var layer_name := layer.name.strip_escapes().strip_edges().to_lower()
				return layer.is_normal_layer() and layer_name.ends_with("occlusion") and layer_name.begins_with(source_layer_name)
			)

		var tile_id_to_canvas_position: Dictionary[int, Vector2i] = {}

		if source_layer_index != -1:
			var cel_index := ase.frames[0].cels.find_custom(func(cel: AsepriteFile.Cel) -> bool:
				return cel.type == AsepriteFile.CelType.COMPRESSED_TILEMAP and cel.layer_index == source_layer_index
			)

			if cel_index != -1:
				var source_cel := ase.frames[0].cels[cel_index]

				var stream := StreamPeerBuffer.new()
				stream.data_array = source_cel.buffer
				stream.big_endian = false

				for tile_y in range(source_cel.h):
					for tile_x in range(source_cel.w):
						var dword := stream.get_32()
						var tile_id := dword & source_cel.bitmask_for_tile_id
						var relative_origin = Vector2i(tile_x, tile_y) * Vector2i(tileset.tile_width, tileset.tile_height)
						tile_id_to_canvas_position[tile_id] = relative_origin + Vector2i(source_cel.x, source_cel.y)

				# Create the terrain
				var terrain_set_index := tile_set.get_terrain_sets_count()
				tile_set.add_terrain_set(terrain_set_index)
				tile_set.set_terrain_set_mode(tileset_index, TileSet.TERRAIN_MODE_MATCH_CORNERS_AND_SIDES)

				var terrain_index := tile_set.get_terrains_count(terrain_set_index)
				tile_set.add_terrain(terrain_set_index, terrain_index)
				tile_set.set_terrain_name(terrain_set_index, terrain_index, ase.layers[source_layer_index].name)
				tile_set.set_terrain_color(terrain_set_index, terrain_index, Color8(200, 100, 100))

				for tile_id in range(tileset.tiles_count):
					# The order is important, we need to ser the terrain_set first
					atlas_source.set("%s:%s/0/terrain_set" % [tile_id, 0], terrain_set_index)
					atlas_source.set("%s:%s/0/terrain" % [tile_id, 0], terrain_index)

					if tile_id_to_canvas_position.has(tile_id):
						var source_pos := tile_id_to_canvas_position[tile_id]

						# TODO: so inefficient to create a new image for every tile...
						var img: Image = null

						if bitmask_layer_index != -1:
							img = ase.get_layer_frame_image(bitmask_layer_index, 0)
						elif default_bitmask_layer_index != -1:
							img = ase.get_layer_frame_image(default_bitmask_layer_index, 0)

						if img:
							var bitmask_image := Image.create_empty(tileset.tile_width, tileset.tile_height, false, Image.FORMAT_RGBA8)
							bitmask_image.blit_rect(
								img,
								Rect2i(source_pos, Vector2i(tileset.tile_width, tileset.tile_height)),
								Vector2i.ZERO,
							)

							# Assume Match Corners and Sides for now
							bitmask_image.resize(3, 3, Image.INTERPOLATE_TRILINEAR)

							var bitmap := BitMap.new()
							bitmap.create_from_image_alpha(bitmask_image, 0.8)

							if bitmap.get_bit(2, 1): atlas_source.set("%s:%s/0/terrains_peering_bit/right_side" % [tile_id, 0], 0)
							if bitmap.get_bit(2, 2): atlas_source.set("%s:%s/0/terrains_peering_bit/bottom_right_corner" % [tile_id, 0], 0)
							if bitmap.get_bit(1, 2): atlas_source.set("%s:%s/0/terrains_peering_bit/bottom_side" % [tile_id, 0], 0)
							if bitmap.get_bit(0, 2): atlas_source.set("%s:%s/0/terrains_peering_bit/bottom_left_corner" % [tile_id, 0], 0)
							if bitmap.get_bit(0, 1): atlas_source.set("%s:%s/0/terrains_peering_bit/left_side" % [tile_id, 0], 0)
							if bitmap.get_bit(0, 0): atlas_source.set("%s:%s/0/terrains_peering_bit/top_left_corner" % [tile_id, 0], 0)
							if bitmap.get_bit(1, 0): atlas_source.set("%s:%s/0/terrains_peering_bit/top_side" % [tile_id, 0], 0)
							if bitmap.get_bit(2, 0): atlas_source.set("%s:%s/0/terrains_peering_bit/top_right_corner" % [tile_id, 0], 0)


		tile_set.add_source(atlas_source)

	return ResourceSaver.save(tile_set, save_path + "." + _get_save_extension())

static func _build_tileset_data(ase: AsepriteFile) -> Dictionary:
	var data: Dictionary = {}

	for tileset_index in range(ase.tilesets.size()):
		var tileset := ase.tilesets[tileset_index]

		# For each tile, find where they are used
		for tile_id in range(tileset.tiles_count):
			for source_layer_index in range(ase.layers.size()):
				var source_layer := ase.layers[source_layer_index]

				if not source_layer.is_tilemap_layer():
					continue

				if source_layer.tileset_index != tileset_index:
					continue

				for frame_index in range(ase.frames.size()):
					for cel_index in range(ase.frames[frame_index].cels.size()):
						var cel := ase.frames[frame_index].cels[cel_index]

						if cel.type != AsepriteFile.CelType.COMPRESSED_TILEMAP:
							continue

						if cel.layer_index != source_layer_index:
							continue

						var source_cel := ase.frames[0].cels[cel_index]

						var stream := StreamPeerBuffer.new()
						stream.data_array = source_cel.buffer
						stream.big_endian = false

						for tile_y in range(source_cel.h):
							for tile_x in range(source_cel.w):
								var current_tile_id := stream.get_32() & source_cel.bitmask_for_tile_id

								# x and y are in tile units, convert to pixel units, then add the cel offset
								var coords = (Vector2i(tile_x, tile_y) * Vector2i(tileset.tile_width, tileset.tile_height)) + Vector2i(source_cel.x, source_cel.y)

								data["%d:%d/%d/source_layer_index" % [tileset_index, tile_id, frame_index]] = source_layer_index
								data["%d:%d/%d/source_layer_coords" % [tileset_index, current_tile_id, frame_index]] = coords

	# Construct the atlas
	for tileset_index in range(ase.tilesets.size()):
		var tileset := ase.tilesets[tileset_index]
		for tile_id in range(tileset.tiles_count):
			pass

	return data
