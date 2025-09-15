@tool
extends EditorImportPlugin

func _get_importer_name() -> String: return "aseprite.importer.spriteframes"
func _get_visible_name() -> String: return "SpriteFrames (Aseprite)"
func _get_recognized_extensions() -> PackedStringArray: return ["aseprite"]
func _get_resource_type() -> String: return "SpriteFrames"
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

	return true

func _get_import_options(_path: String, preset_index: int) -> Array[Dictionary]:
	return [
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
			"name": "packing/type",
			"default_value": 0,
			"property_hint": PROPERTY_HINT_ENUM,
			"hint_string": "Rows,Columns,Packed",
		}
	]

func _import(source_file: String, save_path: String, options: Dictionary, platform_variants: Array[String], gen_files: Array[String]) -> int:
	var err := OK

	var ase := AsepriteFile.open(source_file)
	if ase == null:
		err = AsepriteFile.get_open_error()
		push_error("Aseprite - Failed to open file: %s" % error_string(err))
		return err

	var canvas := Image.create_empty(ase.width * ase.frames.size(), ase.height, false, Image.FORMAT_RGBA8)

	# Create the full atlas texture
	for tag_index in range(ase.tags.size()):
		var tag := ase.tags[tag_index]

		for frame_index in range(tag.from_frame, tag.to_frame + 1):
			for layer_index in range(ase.layers.size()):
				var layer := ase.layers[layer_index]

				if layer.opacity == 0: continue
				if layer.type != AsepriteFile.LAYER_TYPE_NORMAL: continue
				if not layer.is_visible(): continue

				var image := ase.get_layer_frame_image(layer_index, frame_index)
				canvas.blit_rect(image, Rect2i(Vector2i.ZERO, image.get_size()), Vector2i(ase.width * frame_index, 0))

	var atlas: Texture2D

	if not options.get("save_to_file/enabled", false):
		var texture := PortableCompressedTexture2D.new()
		texture.create_from_image(canvas, PortableCompressedTexture2D.COMPRESSION_MODE_LOSSLESS)
		atlas = texture
	else:
		var export_path := _resolve_path(String(options.get("save_to_file/path", "")))

		if export_path.is_empty():
			push_warning("Aseprite Importer - Export path is empty, using in-memory texture instead.")

			var texture := PortableCompressedTexture2D.new()
			texture.create_from_image(canvas, PortableCompressedTexture2D.COMPRESSION_MODE_LOSSLESS)
			atlas = texture

		else:
			var dir_name := export_path.get_base_dir()

			err = DirAccess.make_dir_recursive_absolute(dir_name)
			if err != OK: return err

			err = canvas.save_png(export_path)
			if err != OK: return err

			EditorInterface.get_resource_filesystem().update_file(export_path)

			err = append_import_external_resource(export_path)
			if err != OK: return err

			atlas = ResourceLoader.load(export_path, "Texture2D", ResourceLoader.CACHE_MODE_REPLACE)
			if atlas == null: return ERR_CANT_ACQUIRE_RESOURCE
			if not atlas is Texture2D: return ERR_INVALID_DATA

	var sprite_frames := SpriteFrames.new()

	# Clear built-in animations
	for anim in sprite_frames.get_animation_names():
		sprite_frames.remove_animation(anim)

	for tag_index in range(ase.tags.size()):
		var tag := ase.tags[tag_index]

		var frames_count := tag.to_frame - tag.from_frame + 1

		# in milliseconds
		var duration: int = 0

		for frame_index in range(tag.from_frame, tag.to_frame + 1):
			duration += ase.frames[frame_index].duration

		var animation_name := tag.name.strip_escapes().strip_edges().validate_node_name().to_snake_case()

		if not sprite_frames.has_animation(animation_name):
			sprite_frames.add_animation(animation_name)

		# Clear the animation, if two animations have the same name, the last one will override the first
		sprite_frames.clear(animation_name)
		sprite_frames.set_animation_loop(animation_name, false if frames_count == 1 else tag.repeat == 0)
		sprite_frames.set_animation_speed(animation_name, 1000.0 / (duration / frames_count))

		for frame_index in frames_count:
			var atlas_texture := AtlasTexture.new()
			atlas_texture.atlas = atlas
			atlas_texture.region = Rect2(ase.width * frame_index, 0, ase.width, ase.height)

			sprite_frames.add_frame(animation_name, atlas_texture)

	err = ResourceSaver.save(sprite_frames, save_path + "." + _get_save_extension())

	return err

# Convert a path to a fully qualified "res://" path
static func _resolve_path(path: String) -> String:
	if path.is_empty():
		push_warning("Aseprite Importer - The export path is empty.")
		return path

	if path.begins_with("uid://"):
		var uid := ResourceUID.text_to_id(path)

		if uid == ResourceUID.INVALID_ID:
			push_warning("Aseprite Importer - Invalid export path UID: \"%s\"" % path)
			return ""

		if not ResourceUID.has_id(uid):
			push_warning("Aseprite Importer - Unrecognized export path UID: \"%s\"" % path)
			return ""

		path = ResourceUID.get_id_path(uid)

	if not path.begins_with("res://") or path.contains("::"):
		push_warning("Aseprite Importer - Invalid resource export path: \"%s\"" % path)
		return ""

	return path
