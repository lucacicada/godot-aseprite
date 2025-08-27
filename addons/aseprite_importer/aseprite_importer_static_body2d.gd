@tool
extends EditorImportPlugin

var presets := [
	{
		"name": "Default",

		# Each option; "name" and "default_value" are mandatory
		# see: https://github.com/godotengine/godot/blob/4.4/editor/import/editor_import_plugin.cpp#L123
		"options": [
			{
				"name": "first_frame_only",
				"default_value": false,
			},
			{
				"name": "layer/only_visible_layers",
				"default_value": false,
			},
			{
				"name": "sheet/sheet_type",
				"default_value": "horizontal",
				"property_hint": PROPERTY_HINT_ENUM,
				"hint_string": "horizontal,vertical,packed,columns",
			},
			{
				"name": "sheet/sheet_columns",
				"default_value": 12,
			},
		]
	},
]

func _get_importer_name() -> String:
	return "aseprite.importer.staticbody2d"

func _get_visible_name() -> String:
	return "StaticBody2D (Aseprite)"

func _get_recognized_extensions() -> PackedStringArray:
	return ["aseprite", "ase"]

func _get_resource_type() -> String:
	return "PackedScene"

func _get_save_extension() -> String:
	return "tscn"

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
	# If we are selecting only a single frame, sheet options are not relevant
	if options.get("first_frame_only", false) == true and option_name.begins_with("sheet/"):
		return false

	if option_name == "sheet/sheet_columns" and options.has("sheet/sheet_type"):
		return options.get("sheet/sheet_type") == "columns"

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

	# Create the StaticBody2D scene
	var static_body := StaticBody2D.new()
	static_body.name = source_file.get_file().get_basename()

	# var collision_shape := CollisionShape2D.new()
	# static_body.add_child(collision_shape)
	# collision_shape.owner = static_body
	# collision_shape.name = "CollisionShape2D"
	# collision_shape.shape = RectangleShape2D.new()
	# collision_shape.shape.size = Vector2()

	for layer_index in range(ase.layers.size()):
		var layer := ase.layers[layer_index]

		# Skip fully transparent layers
		if layer.opacity == 0:
			continue

		# Follow: https://docs.godotengine.org/en/3.5/tutorials/assets_pipeline/importing_scenes.html#remove-nodes-noimp
		if layer.name.ends_with("-noimp"):
			continue

		if layer.name.containsn("collision") or layer.name.ends_with("-col"):
			if ase.is_layer_frame_empty(layer_index, 0):
				push_warning("Aseprite - Collision layer is empty: %s" % layer.name)
				continue

			var frame_img := ase.get_layer_frame_image(layer_index, 0)
			var collision_bitmap = BitMap.new()
			collision_bitmap.create_from_image_alpha(frame_img)

			var polygons := collision_bitmap.opaque_to_polygons(Rect2(Vector2(), collision_bitmap.get_size()))

			# TODO: if the collision aproximate a rect, use a CollisionShape2D with RectangleShape2D
			for points in polygons:
				# Offset the points
				for i in range(points.size()):
					points[i] = Vector2(points[i].x, points[i].y - ase.height)

				var collision_polygon := CollisionPolygon2D.new()
				static_body.add_child(collision_polygon)
				collision_polygon.owner = static_body
				collision_polygon.polygon = points

			continue

		var frame_canvas: Array[Image] = []

		for frame_index in range(ase.frames.size()):
			var frame := ase.frames[frame_index]

			if not ase.is_layer_frame_empty(layer_index, frame_index):
				var frame_img := ase.get_layer_frame_image(layer_index, frame_index)
				frame_canvas.append(frame_img)

		if frame_canvas.is_empty():
			continue

		if frame_canvas.size() == 1:
			var sprite := Sprite2D.new()
			static_body.add_child(sprite)
			sprite.owner = static_body
			sprite.name = layer.name
			sprite.centered = false
			sprite.position.y = - ase.height

			var layer_image := frame_canvas[0]

			if layer_image:
				var texture := PortableCompressedTexture2D.new()
				texture.create_from_image(layer_image, PortableCompressedTexture2D.COMPRESSION_MODE_LOSSLESS)
				sprite.texture = texture

		else:
			var anim_sprite := AnimatedSprite2D.new()
			static_body.add_child(anim_sprite)
			anim_sprite.owner = static_body
			anim_sprite.name = layer.name
			anim_sprite.centered = false
			anim_sprite.position.y = - ase.height

			var anim_sprite_frames := SpriteFrames.new()
			anim_sprite.frames = anim_sprite_frames
			# TODO: read the loop and speed from the frames
			anim_sprite_frames.set_animation_loop("default", false)
			anim_sprite_frames.set_animation_speed("default", 10.0)

			for layer_image in frame_canvas:
				var texture := PortableCompressedTexture2D.new()
				texture.create_from_image(layer_image, PortableCompressedTexture2D.COMPRESSION_MODE_LOSSLESS)

				anim_sprite_frames.add_frame("default", texture)

	var scene := PackedScene.new()
	err = scene.pack(static_body)

	if err != OK:
		printerr("Aseprite - %s" % error_string(err))
		return err

	var filename := save_path + "." + _get_save_extension()
	err = ResourceSaver.save(scene, filename)

	if err != OK:
		printerr("Aseprite - %s" % error_string(err))
		return err

	return OK
