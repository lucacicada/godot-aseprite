@tool
extends "./aseprite_import_plugin.gd"

func _get_importer_name() -> String: return "aseprite.importer.node2d"
func _get_visible_name() -> String: return "Node2D (Aseprite)"
func _get_resource_type() -> String: return "PackedScene"
func _get_save_extension() -> String: return "scn"

func _configure_presets() -> void:
	add_preset("Default", [
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
	])

func _configure_import_options(path: String, preset_index: int) -> void:
	var ase := AsepriteFile.open(path, AsepriteFile.OPEN_FLAGS_SKIP_BUFFER)

	if ase == null:
		push_warning("Aseprite - Failed to inspect file: %s" % error_string(AsepriteFile.get_open_error()))
		return

	var layers: Array[AsepriteFile.Layer] = ase.layers.duplicate()
	layers.reverse()

	for layer in layers:
		if layer.type != AsepriteFile.LAYER_TYPE_NORMAL:
			continue

		var is_noimport := layer.name.ends_with("-noimp") or layer.opacity == 0
		var import_type := 0

		if layer.name.containsn("collision") or layer.name.containsn("StaticBody2D") or layer.name.ends_with("-col"):
			import_type = 1 # Collision
		elif layer.name.containsn("Area2D") or layer.name.containsn("LightOccluder2D") or layer.name.ends_with("-area"):
			import_type = 2 # Area2D

		add_import_option_layer(ase, layer, {
			"name": "export",
			"default_value": not is_noimport,
		})

		add_import_option_layer(ase, layer, {
			"name": "export_path",
			"default_value": "",
			"property_hint": PROPERTY_HINT_SAVE_FILE,
			"hint_string": "*.png",
		})

		add_import_option_layer(ase, layer, {
			"name": "visible",
			"default_value": layer.is_visible(),
		})

		add_import_option_layer(ase, layer, {
			"name": "opacity",
			"default_value": layer.opacity,
			"property_hint": PROPERTY_HINT_RANGE,
			"hint_string": "0,255,1",
		})

		add_import_option_layer(ase, layer, {
			"name": "type",
			"default_value": import_type,
			"property_hint": PROPERTY_HINT_ENUM,
			"hint_string": "Sprite:0,Collision:1,Area:2",
		})

func _import(source_file: String, save_path: String, options: Dictionary, platform_variants: Array[String], gen_files: Array[String]) -> int:
	var err := OK

	var ase := AsepriteFile.open(source_file)

	if ase == null:
		push_warning("Aseprite - Failed to open file: %s" % error_string(AsepriteFile.get_open_error()))
		return ERR_CANT_OPEN

	var options_transform_anchor := options.get("sprite/offset", 0)

	var node2d := Node2D.new()
	node2d.name = options.get("root_node/name", "Node2D").validate_node_name()
	node2d.set_script(load(options.get("root_node/script", "")) if options.get("root_node/script", "") != "" else null)

	if err != OK:
		push_warning("Aseprite - Failed to pack scene: %s" % error_string(err))
		return err

	for layer_index in range(ase.layers.size()):
		var layer := ase.layers[layer_index]

		if ase.is_layer_frame_empty(layer_index, 0):
			continue

		var option_export: bool = get_import_option_layer(ase, layer, "export", options, true)
		var option_export_path: String = get_import_option_layer(ase, layer, "export_path", options, "")
		var option_visible: bool = get_import_option_layer(ase, layer, "visible", options, true)
		var option_type: int = get_import_option_layer(ase, layer, "type", options, 0)

		if not option_export:
			continue

		if option_type == 0:
			var sprite := Sprite2D.new()
			node2d.add_child(sprite)
			sprite.visible = option_visible
			sprite.owner = node2d
			sprite.name = layer.name.validate_node_name()

			match options_transform_anchor:
				0: # Bottom Left
					sprite.centered = false
					sprite.position.x = 0
					sprite.position.y = - ase.height
				1: # Bottom Right
					sprite.centered = false
					sprite.position.x = - ase.width
					sprite.position.y = - ase.height
				2: # Top Left
					sprite.centered = false
					sprite.position.x = 0
					sprite.position.y = 0
				3: # Top Right
					sprite.centered = false
					sprite.position.x = - ase.width
					sprite.position.y = 0
				4: # Center
					sprite.centered = true
					sprite.position.x = 0
					sprite.position.y = 0

			var layer_image := ase.get_layer_frame_image(layer_index, 0)

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

		elif option_type == 2:
			var frame_img := ase.get_layer_frame_image(layer_index, 0)
			var collision_bitmap = BitMap.new()
			collision_bitmap.create_from_image_alpha(frame_img)

			var polygons := collision_bitmap.opaque_to_polygons(Rect2(Vector2(), collision_bitmap.get_size()))

			var area2d := Area2D.new()
			node2d.add_child(area2d)
			area2d.name = layer.name.validate_node_name()
			area2d.visible = option_visible
			area2d.owner = node2d

			for points in polygons:
				# Offset the points
				for i in range(points.size()):
					points[i] = Vector2(points[i].x, points[i].y - ase.height)

				var collision_polygon := CollisionPolygon2D.new()
				area2d.add_child(collision_polygon)
				# collision_polygon.name = "CollisionPolygon2D_%s" % static_body.name
				collision_polygon.owner = node2d
				collision_polygon.polygon = points
			pass

		else:
			var frame_img := ase.get_layer_frame_image(layer_index, 0)
			var collision_bitmap = BitMap.new()
			collision_bitmap.create_from_image_alpha(frame_img)

			var polygons := collision_bitmap.opaque_to_polygons(Rect2(Vector2(), collision_bitmap.get_size()))

			var static_body := StaticBody2D.new()
			node2d.add_child(static_body)
			static_body.name = layer.name.validate_node_name()
			static_body.visible = option_visible
			static_body.owner = node2d

			# TODO: if the collision aproximate a rect, use a CollisionShape2D with RectangleShape2D
			for points in polygons:
				# Offset the points
				for i in range(points.size()):
					points[i] = Vector2(points[i].x, points[i].y - ase.height)

				var collision_polygon := CollisionPolygon2D.new()
				static_body.add_child(collision_polygon)
				# collision_polygon.name = "CollisionPolygon2D_%s" % static_body.name
				collision_polygon.owner = node2d
				collision_polygon.polygon = points

	var scene := PackedScene.new()
	err = scene.pack(node2d)

	var filename := save_path + "." + _get_save_extension()
	err = ResourceSaver.save(scene, filename)

	if err != OK:
		push_warning("Aseprite - Failed to save resource: %s" % error_string(err))
		return err

	return err
