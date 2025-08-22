@tool
extends EditorImportPlugin

var presets := [
	{
		"name": "Default",
		"options": []
	},
]

func _get_importer_name() -> String:
	return "aseprite.importer.node2d"

func _get_visible_name() -> String:
	return "Node2D (Aseprite)"

func _get_recognized_extensions() -> PackedStringArray:
	return ["aseprite", "ase"]

func _get_resource_type() -> String:
	return "PackedScene"

func _get_save_extension() -> String:
	return "scn"

func _get_priority() -> float:
	return 1.0

func _get_import_order() -> int:
	return IMPORT_ORDER_DEFAULT

func _get_preset_count() -> int:
	return presets.size()

func _get_preset_name(preset_index: int) -> String:
	return presets[preset_index]["name"]

func _get_import_options(path: String, preset_index: int) -> Array[Dictionary]:
	var options: Array[Dictionary] = [
		{
			"name": "root_node/name",
			"default_value": "Node2D",
		},
		{
			"name": "root_node/script",
			"default_value": "",
			"property_hint": PROPERTY_HINT_FILE,
			"hint_string": "*.gd",
		},
		{
			"name": "sprite/offset",
			"default_value": 4,
			"property_hint": PROPERTY_HINT_ENUM,
			"hint_string": "Bottom Left:0,Bottom Right:1,Top Left:2,Top Right:3,Center:4",
		}
	]

	var ase_file := AsepriteFile.new()
	var err := ase_file.open(path, AsepriteFile.OPEN_FLAG_SKIP_BUFFER)
	if err != OK:
		ase_file.close()
		push_warning("Aseprite - Failed to inspect file: %s" % error_string(err))
		return []

	var stack: Array[String] = []

	for layer_index in range(ase_file.layers.size()):
		var layer := ase_file.layers[layer_index]
		var level := layer.child_level

		while stack.size() > level:
			stack.pop_back()

		var seg := "%s_(#%s)" % [_normalize_layer_name(layer.name), layer_index]
		var base_name := "/".join(["layers"] + stack + [seg])
		stack.append(seg)

		if layer.type != AsepriteFile.LAYER_TYPE_NORMAL:
			continue

		options.append_array([
			{
				"name": base_name + "/visible",
				"default_value": layer.is_visible(),
			},
			{
				"name": base_name + "/export_path",
				"default_value": "",
				"property_hint": PROPERTY_HINT_SAVE_FILE,
				"hint_string": "*.png",
			}
		])

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

	var options_transform_anchor := options.get("sprite/offset", 0)

	var node2d := Node2D.new()
	node2d.name = options.get("root_node/name", "Node2D").validate_node_name()
	node2d.set_script(load(options.get("root_node/script", "")) if options.get("root_node/script", "") != "" else null)

	if err != OK:
		push_warning("Aseprite - Failed to pack scene: %s" % error_string(err))
		return err

	for layer_index in range(ase_file.layers.size()):
		var layer := ase_file.layers[layer_index]

		if ase_file.is_layer_frame_empty(layer_index, 0):
			continue

		# Skip fully transparent layers
		if layer.opacity == 0:
			continue

		var sprite := Sprite2D.new()
		node2d.add_child(sprite)
		sprite.owner = node2d
		sprite.name = layer.name.validate_node_name()

		match options_transform_anchor:
			0: # Bottom Left
				sprite.centered = false
				sprite.position.x = 0
				sprite.position.y = - ase_file.height
			1: # Bottom Right
				sprite.centered = false
				sprite.position.x = - ase_file.width
				sprite.position.y = - ase_file.height
			2: # Top Left
				sprite.centered = false
				sprite.position.x = 0
				sprite.position.y = 0
			3: # Top Right
				sprite.centered = false
				sprite.position.x = - ase_file.width
				sprite.position.y = 0
			4: # Center
				sprite.centered = true
				sprite.position.x = 0
				sprite.position.y = 0

		var option_export_path: String = options.get("layers/%s_(#%s)/export_path" % [_normalize_layer_name(layer.name), layer_index], "")

		var layer_image := ase_file.get_layer_frame_image(layer_index, 0)

		if option_export_path.is_empty():
			var texture := PortableCompressedTexture2D.new()
			texture.create_from_image(layer_image, PortableCompressedTexture2D.COMPRESSION_MODE_LOSSLESS)
			sprite.texture = texture
		else:
			err = layer_image.save_png(option_export_path)

			if err != OK:
				push_warning("Aseprite - Failed to save image: %s" % error_string(err))
				return err

			# We absolutely MUST refresh the filesystem here, or Godot won't see the newly created file
			EditorInterface.get_resource_filesystem().update_file(option_export_path)

			gen_files.append(option_export_path)

			err = append_import_external_resource(option_export_path)
			if err != OK:
				push_warning("Aseprite - Failed to register external resource: %s" % error_string(err))
				return err

			sprite.texture = ResourceLoader.load(option_export_path, "Texture2D", ResourceLoader.CACHE_MODE_REPLACE)

	var scene := PackedScene.new()
	err = scene.pack(node2d)

	var filename := save_path + "." + _get_save_extension()
	err = ResourceSaver.save(scene, filename)

	if err != OK:
		push_warning("Aseprite - Failed to save resource: %s" % error_string(err))
		return err

	return err

static func _normalize_layer_name(name: String) -> String:
	return name.validate_node_name().replace(" ", "_").replace("/", "_").replace("\\", "_").to_lower()
