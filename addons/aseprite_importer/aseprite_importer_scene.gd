@tool
extends EditorImportPlugin

func _get_importer_name() -> String: return "aseprite.importer.scene"
func _get_visible_name() -> String: return "Scene (Aseprite)"
func _get_recognized_extensions() -> PackedStringArray: return ["aseprite"]
func _get_resource_type() -> String: return "PackedScene"
func _get_save_extension() -> String: return "scn"
func _get_priority() -> float: return 1.0
func _get_import_order() -> int: return IMPORT_ORDER_DEFAULT
func _get_preset_count() -> int: return 6
func _get_preset_name(preset_index: int) -> String:
	match preset_index:
		1: return "Node2D"
		2: return "StaticBody2D"
		3: return "RigidBody2D"
		4: return "CharacterBody2D"
		5: return "Area2D"
		_: return "Default"

func _get_option_visibility(_path: String, option_name: StringName, options: Dictionary) -> bool:
	return true

func _get_import_options(path: String, preset_index: int) -> Array[Dictionary]:
	var root_types := [
		"",
		"Node2D",
		"StaticBody2D",
		"RigidBody2D",
		"CharacterBody2D",
		"Area2D"
	]

	var options: Array[Dictionary] = [
		{
			"name": "nodes/root_type",
			"default_value": root_types[preset_index] if preset_index >= 0 and preset_index < root_types.size() else root_types[0],
			"property_hint": PROPERTY_HINT_TYPE_STRING,
			"hint_string": "Node",
			"usage": PROPERTY_USAGE_DEFAULT | PROPERTY_USAGE_UPDATE_ALL_IF_MODIFIED
		},

		{
			"name": "nodes/root_name",
			"default_value": "",
		},
		{
			"name": "nodes/root_script",
			"default_value": "",
			"property_hint": PROPERTY_HINT_FILE,
			"hint_string": "*.gd",
		},
		{
			"name": "sprites/offset",
			"default_value": - 1,
			"property_hint": PROPERTY_HINT_ENUM,
			"hint_string": "Default:-1,Top Left:%d,Top Right:%d,Bottom Left:%d,Bottom Right:%d,Center Left:%d,Center Top:%d,Center Right:%d,Center Bottom:%d,Center:%d"
			% [
				Control.PRESET_TOP_LEFT,
				Control.PRESET_TOP_RIGHT,
				Control.PRESET_BOTTOM_LEFT,
				Control.PRESET_BOTTOM_RIGHT,
				Control.PRESET_CENTER_LEFT,
				Control.PRESET_CENTER_TOP,
				Control.PRESET_CENTER_RIGHT,
				Control.PRESET_CENTER_BOTTOM,
				Control.PRESET_CENTER,
			]
		},
		{
			"name": "import/only_visible_layers",
			"default_value": false,
		},

		{
			"name": "collision/collision_layer",
			"default_value": 1,
			"property_hint": PROPERTY_HINT_LAYERS_2D_PHYSICS,
		},
		{
			"name": "collision/collision_mask",
			"default_value": 1,
			"property_hint": PROPERTY_HINT_LAYERS_2D_PHYSICS,
		},
		{
			"name": "collision/collision_priority",
			"default_value": 1.0,
		},

		{
			"name": "occluder/sdf_collision",
			"default_value": true,
		},
		{
			"name": "occluder/occluder_light_mask",
			"default_value": 1,
			"property_hint": PROPERTY_HINT_LAYERS_2D_RENDER
		},

		{
			"name": "navigation_obstacle/radius",
			"default_value": 0.0,
			"property_hint": PROPERTY_HINT_RANGE,
			"hint_string": "0.0,500,0.01,suffix:px"
		},

		{
			"name": "navigation_mesh/affect_navigation_mesh",
			"default_value": false,
		},
		{
			"name": "navigation_mesh/carve_navigation_mesh",
			"default_value": false,
		},

		{
			"name": "avoidance/avoidance_enabled",
			"default_value": true,
		},
		{
			"name": "avoidance/avoidance_layers",
			"default_value": 1,
			"property_hint": PROPERTY_HINT_LAYERS_2D_NAVIGATION
		},
	]

	return options

func _import(source_file: String, save_path: String, options: Dictionary, platform_variants: Array[String], gen_files: Array[String]) -> int:
	var err := OK

	var ase := AsepriteFile.open(source_file)

	if ase == null:
		err = AsepriteFile.get_open_error()
		return err

	var options_scene_root_type: String = options.get("nodes/root_type", "")
	var options_scene_root_name: String = options.get("nodes/root_name", "")
	var options_scene_root_script: String = options.get("nodes/root_script", "")
	var options_sprite_offset: int = options.get("sprites/offset", Control.PRESET_CENTER)

	# Validate the root node name
	options_scene_root_name = options_scene_root_name.strip_escapes().strip_edges().validate_node_name()
	options_scene_root_name = "Node2D" if options_scene_root_name.is_empty() else options_scene_root_name

	# Use the project settings default if the option is set to -1
	if options_sprite_offset < 0:
		options_sprite_offset = ProjectSettings.get_setting("aseprite/import/sprite_offset", Control.PRESET_CENTER)

	# Automatically determine the root node type if not specified
	if options_scene_root_type.is_empty():
		# Hight priority to CharacterBody2D if a layer with that name exists
		if ase.layers.any(func(layer: AsepriteFile.Layer):
			return layer.type == AsepriteFile.LAYER_TYPE_NORMAL and layer.opacity > 0 and not layer.name.ends_with("-noimp") and layer.name.containsn("CharacterBody2D")
		):
			options_scene_root_type = "CharacterBody2D"

		# We have a collision layer, use StaticBody2D as the root node
		elif ase.layers.any(func(layer: AsepriteFile.Layer):
			return layer.type == AsepriteFile.LAYER_TYPE_NORMAL and layer.opacity > 0 and not layer.name.ends_with("-noimp") and layer.name.containsn("Collision")
		):
			var hint_idle := ase.tags.any(func(tag: AsepriteFile.Tag): return tag.name.containsn("idle"))
			if hint_idle:
				options_scene_root_type = "CharacterBody2D"
			else:
				options_scene_root_type = "StaticBody2D"

		# We have an Area2D layer, use Area2D as the root node
		elif ase.layers.any(func(layer: AsepriteFile.Layer):
			return layer.type == AsepriteFile.LAYER_TYPE_NORMAL and layer.opacity > 0 and not layer.name.ends_with("-noimp") and (
				layer.name.containsn("Area2D") or
				layer.name.containsn("HitBox") or
				layer.name.containsn("HurtBox")
			)
		):
			options_scene_root_type = "Area2D"

		# Default to Node2D
		else:
			options_scene_root_type = "Node2D"

	var root_node: Node = null

	if ClassDB.can_instantiate(options_scene_root_type):
		root_node = ClassDB.instantiate(options_scene_root_type) as Node

	if root_node == null:
		push_warning("Aseprite Importer - Invalid root node type: \"%s\", fallback to Node2D" % options_scene_root_type)
		root_node = Node2D.new()

	root_node.name = options_scene_root_name

	if root_node is CollisionObject2D:
		root_node.collision_layer = options.get("collision/collision_layer", 1)
		root_node.collision_mask = options.get("collision/collision_mask", 1)
		root_node.collision_priority = options.get("collision/collision_priority", 1.0)

	if root_node is NavigationObstacle2D:
		root_node.radius = options.get("navigation_obstacle/radius", 0.0)
		root_node.avoidance_enabled = options.get("avoidance/avoidance_enabled", true)
		root_node.avoidance_layers = options.get("avoidance/avoidance_layers", 1)
		root_node.affect_navigation_mesh = options.get("navigation_mesh/affect_navigation_mesh", false)
		root_node.carve_navigation_mesh = options.get("navigation_mesh/carve_navigation_mesh", false)

	if root_node is LightOccluder2D:
		root_node.sdf_collision = options.get("occluder/sdf_collision", true)
		root_node.occluder_light_mask = options.get("occluder/occluder_light_mask", 1)

	if not options_scene_root_script.is_empty():
		var script_res := ResourceLoader.load(options_scene_root_script, "Script")
		if script_res == null or not script_res is Script:
			push_warning("Aseprite Importer - Failed to load script: %s" % options_scene_root_script)
		else:
			root_node.set_script(script_res as Script)

	for layer_index in range(ase.layers.size()):
		var layer := ase.layers[layer_index]

		# Skip GROUP and TILEMAP layers
		if layer.type != AsepriteFile.LAYER_TYPE_NORMAL:
			continue

		# Skip layer with 0 opacity or marked as no import
		if layer.opacity == 0 or layer.name.ends_with("-noimp"):
			continue

		var layer_node_name := layer.name.strip_escapes().strip_edges().validate_node_name()
		layer_node_name = "Layer_%d" % layer_index if layer_node_name.is_empty() else layer_node_name

		if layer.name.containsn("Obstacle"):
			var collision_bitmap = BitMap.new()
			collision_bitmap.create_from_image_alpha(ase.get_layer_frame_image(layer_index, 0))
			var polygons := collision_bitmap.opaque_to_polygons(Rect2(Vector2(), collision_bitmap.get_size()))

			# Offset the points, the polygons are aligned top-left when created from bitmap
			for points in polygons:
				match options_sprite_offset:
					Control.PRESET_TOP_LEFT:
						for i in range(points.size()): points[i] = Vector2(points[i].x, points[i].y)
					Control.PRESET_TOP_RIGHT:
						for i in range(points.size()): points[i] = Vector2(points[i].x - ase.width, points[i].y)
					Control.PRESET_BOTTOM_LEFT:
						for i in range(points.size()): points[i] = Vector2(points[i].x, points[i].y - ase.height)
					Control.PRESET_BOTTOM_RIGHT:
						for i in range(points.size()): points[i] = Vector2(points[i].x - ase.width, points[i].y - ase.height)
					Control.PRESET_CENTER_LEFT:
						for i in range(points.size()): points[i] = Vector2(points[i].x, points[i].y - ase.height / 2)
					Control.PRESET_CENTER_TOP:
						for i in range(points.size()): points[i] = Vector2(points[i].x - ase.width / 2, points[i].y)
					Control.PRESET_CENTER_RIGHT:
						for i in range(points.size()): points[i] = Vector2(points[i].x - ase.width, points[i].y - ase.height / 2)
					Control.PRESET_CENTER_BOTTOM:
						for i in range(points.size()): points[i] = Vector2(points[i].x - ase.width / 2, points[i].y - ase.height)
					_:
						for i in range(points.size()): points[i] = Vector2(points[i].x - ase.width / 2, points[i].y - ase.height / 2)

			for points in polygons:
				var navigation_obstacle := NavigationObstacle2D.new()

				navigation_obstacle.name = layer_node_name
				navigation_obstacle.visible = layer.is_visible()

				navigation_obstacle.radius = options.get("navigation_obstacle/radius", 0.0)
				navigation_obstacle.avoidance_enabled = options.get("avoidance/avoidance_enabled", true)
				navigation_obstacle.avoidance_layers = options.get("avoidance/avoidance_layers", 1)
				navigation_obstacle.affect_navigation_mesh = options.get("navigation_mesh/affect_navigation_mesh", false)
				navigation_obstacle.carve_navigation_mesh = options.get("navigation_mesh/carve_navigation_mesh", false)

				# The outline vertices of the obstacle.
				# If the vertices are winded in clockwise order agents will be pushed in by the obstacle, else they will be pushed out.
				# Outlines can not be crossed or overlap.
				# Should the vertices using obstacle be warped to a new position agent's
				# can not predict this movement and may get trapped inside the obstacle.
				navigation_obstacle.vertices = points

				root_node.add_child(navigation_obstacle, true)
				navigation_obstacle.owner = root_node

			continue

		elif layer.name.containsn("Occlude") or layer.name.containsn("Occlusion"):
			var collision_bitmap = BitMap.new()
			collision_bitmap.create_from_image_alpha(ase.get_layer_frame_image(layer_index, 0))
			var polygons := collision_bitmap.opaque_to_polygons(Rect2(Vector2(), collision_bitmap.get_size()))

			# Offset the points, the polygons are aligned top-left when created from bitmap
			for points in polygons:
				match options_sprite_offset:
					Control.PRESET_TOP_LEFT:
						for i in range(points.size()): points[i] = Vector2(points[i].x, points[i].y)
					Control.PRESET_TOP_RIGHT:
						for i in range(points.size()): points[i] = Vector2(points[i].x - ase.width, points[i].y)
					Control.PRESET_BOTTOM_LEFT:
						for i in range(points.size()): points[i] = Vector2(points[i].x, points[i].y - ase.height)
					Control.PRESET_BOTTOM_RIGHT:
						for i in range(points.size()): points[i] = Vector2(points[i].x - ase.width, points[i].y - ase.height)
					Control.PRESET_CENTER_LEFT:
						for i in range(points.size()): points[i] = Vector2(points[i].x, points[i].y - ase.height / 2)
					Control.PRESET_CENTER_TOP:
						for i in range(points.size()): points[i] = Vector2(points[i].x - ase.width / 2, points[i].y)
					Control.PRESET_CENTER_RIGHT:
						for i in range(points.size()): points[i] = Vector2(points[i].x - ase.width, points[i].y - ase.height / 2)
					Control.PRESET_CENTER_BOTTOM:
						for i in range(points.size()): points[i] = Vector2(points[i].x - ase.width / 2, points[i].y - ase.height)
					_:
						for i in range(points.size()): points[i] = Vector2(points[i].x - ase.width / 2, points[i].y - ase.height / 2)

			for points in polygons:
				var light_occluder := LightOccluder2D.new()

				light_occluder.name = layer_node_name
				light_occluder.visible = layer.is_visible()
				light_occluder.occluder_light_mask = 1
				light_occluder.sdf_collision = true

				light_occluder.sdf_collision = options.get("occluder/sdf_collision", true)
				light_occluder.occluder_light_mask = options.get("occluder/occluder_light_mask", 1)

				root_node.add_child(light_occluder, true)
				light_occluder.owner = root_node

				var occluder_polygon := OccluderPolygon2D.new()
				occluder_polygon.polygon = points
				occluder_polygon.cull_mode = OccluderPolygon2D.CULL_DISABLED

				light_occluder.occluder = occluder_polygon

			continue

		elif layer.name.containsn("Area2D") or layer.name.containsn("HitBox") or layer.name.containsn("HurtBox"):
			var area2d := Area2D.new()

			area2d.name = layer_node_name
			area2d.visible = layer.is_visible()

			area2d.collision_layer = options.get("collision/collision_layer", 1)
			area2d.collision_mask = options.get("collision/collision_mask", 1)
			area2d.collision_priority = options.get("collision/collision_priority", 1.0)

			root_node.add_child(area2d, true)
			area2d.owner = root_node

			# Create the collision shapes
			var collision_bitmap = BitMap.new()
			collision_bitmap.create_from_image_alpha(ase.get_layer_frame_image(layer_index, 0))
			var polygons := collision_bitmap.opaque_to_polygons(Rect2(Vector2(), collision_bitmap.get_size()))

			# Offset the points, the polygons are aligned top-left when created from bitmap
			for points in polygons:
				match options_sprite_offset:
					Control.PRESET_TOP_LEFT:
						for i in range(points.size()): points[i] = Vector2(points[i].x, points[i].y)
					Control.PRESET_TOP_RIGHT:
						for i in range(points.size()): points[i] = Vector2(points[i].x - ase.width, points[i].y)
					Control.PRESET_BOTTOM_LEFT:
						for i in range(points.size()): points[i] = Vector2(points[i].x, points[i].y - ase.height)
					Control.PRESET_BOTTOM_RIGHT:
						for i in range(points.size()): points[i] = Vector2(points[i].x - ase.width, points[i].y - ase.height)
					Control.PRESET_CENTER_LEFT:
						for i in range(points.size()): points[i] = Vector2(points[i].x, points[i].y - ase.height / 2)
					Control.PRESET_CENTER_TOP:
						for i in range(points.size()): points[i] = Vector2(points[i].x - ase.width / 2, points[i].y)
					Control.PRESET_CENTER_RIGHT:
						for i in range(points.size()): points[i] = Vector2(points[i].x - ase.width, points[i].y - ase.height / 2)
					Control.PRESET_CENTER_BOTTOM:
						for i in range(points.size()): points[i] = Vector2(points[i].x - ase.width / 2, points[i].y - ase.height)
					_:
						for i in range(points.size()): points[i] = Vector2(points[i].x - ase.width / 2, points[i].y - ase.height / 2)

			for points in polygons:
				var collision_polygon := CollisionPolygon2D.new()

				collision_polygon.name = "%sCollision" % layer_node_name
				collision_polygon.polygon = points

				area2d.add_child(collision_polygon, true)
				collision_polygon.owner = root_node

			continue

		elif layer.name.containsn("Collision"):
			var collision_bitmap = BitMap.new()
			collision_bitmap.create_from_image_alpha(ase.get_layer_frame_image(layer_index, 0))

			var polygons := collision_bitmap.opaque_to_polygons(Rect2(Vector2(), collision_bitmap.get_size()))

			# Offset the points, the polygons are aligned top-left when created from bitmap
			for points in polygons:
				match options_sprite_offset:
					Control.PRESET_TOP_LEFT:
						for i in range(points.size()): points[i] = Vector2(points[i].x, points[i].y)
					Control.PRESET_TOP_RIGHT:
						for i in range(points.size()): points[i] = Vector2(points[i].x - ase.width, points[i].y)
					Control.PRESET_BOTTOM_LEFT:
						for i in range(points.size()): points[i] = Vector2(points[i].x, points[i].y - ase.height)
					Control.PRESET_BOTTOM_RIGHT:
						for i in range(points.size()): points[i] = Vector2(points[i].x - ase.width, points[i].y - ase.height)
					Control.PRESET_CENTER_LEFT:
						for i in range(points.size()): points[i] = Vector2(points[i].x, points[i].y - ase.height / 2)
					Control.PRESET_CENTER_TOP:
						for i in range(points.size()): points[i] = Vector2(points[i].x - ase.width / 2, points[i].y)
					Control.PRESET_CENTER_RIGHT:
						for i in range(points.size()): points[i] = Vector2(points[i].x - ase.width, points[i].y - ase.height / 2)
					Control.PRESET_CENTER_BOTTOM:
						for i in range(points.size()): points[i] = Vector2(points[i].x - ase.width / 2, points[i].y - ase.height)
					_:
						for i in range(points.size()): points[i] = Vector2(points[i].x - ase.width / 2, points[i].y - ase.height / 2)

			for points in polygons:
				var collision_polygon := CollisionPolygon2D.new()

				collision_polygon.name = layer_node_name
				collision_polygon.polygon = points

				root_node.add_child(collision_polygon, true)
				collision_polygon.owner = root_node

			continue

		# Sprite or AnimatedSprite
		elif ase.frames.size() == 1:
			var sprite := Sprite2D.new()

			sprite.name = layer_node_name
			sprite.visible = layer.is_visible()

			root_node.add_child(sprite, true)
			sprite.owner = root_node

			var texture := PortableCompressedTexture2D.new()
			texture.create_from_image(ase.get_layer_frame_image(layer_index, 0), PortableCompressedTexture2D.COMPRESSION_MODE_LOSSLESS)

			sprite.texture = texture

			match options_sprite_offset:
				Control.PRESET_TOP_LEFT:
					sprite.centered = false
					sprite.offset = Vector2(0, 0)
				Control.PRESET_TOP_RIGHT:
					sprite.centered = false
					sprite.offset = Vector2(-ase.width, 0)
				Control.PRESET_BOTTOM_LEFT:
					sprite.centered = false
					sprite.offset = Vector2(0, -ase.height)
				Control.PRESET_BOTTOM_RIGHT:
					sprite.centered = false
					sprite.offset = Vector2(-ase.width, -ase.height)
				Control.PRESET_CENTER_LEFT:
					sprite.centered = false
					sprite.offset = Vector2(0, -ase.height / 2)
				Control.PRESET_CENTER_TOP:
					sprite.centered = false
					sprite.offset = Vector2(-ase.width / 2, 0)
				Control.PRESET_CENTER_RIGHT:
					sprite.centered = false
					sprite.offset = Vector2(-ase.width, -ase.height / 2)
				Control.PRESET_CENTER_BOTTOM:
					sprite.centered = false
					sprite.offset = Vector2(-ase.width / 2, -ase.height)
				_:
					sprite.centered = true
					sprite.offset = Vector2(0, 0)

		else:
			var animated_sprite := AnimatedSprite2D.new()

			animated_sprite.name = layer_node_name
			animated_sprite.visible = layer.is_visible()

			root_node.add_child(animated_sprite, true)
			animated_sprite.owner = root_node

			match options_sprite_offset:
				Control.PRESET_TOP_LEFT:
					animated_sprite.centered = false
					animated_sprite.offset = Vector2(0, 0)
				Control.PRESET_TOP_RIGHT:
					animated_sprite.centered = false
					animated_sprite.offset = Vector2(-ase.width, 0)
				Control.PRESET_BOTTOM_LEFT:
					animated_sprite.centered = false
					animated_sprite.offset = Vector2(0, -ase.height)
				Control.PRESET_BOTTOM_RIGHT:
					animated_sprite.centered = false
					animated_sprite.offset = Vector2(-ase.width, -ase.height)
				Control.PRESET_CENTER_LEFT:
					animated_sprite.centered = false
					animated_sprite.offset = Vector2(0, -ase.height / 2)
				Control.PRESET_CENTER_TOP:
					animated_sprite.centered = false
					animated_sprite.offset = Vector2(-ase.width / 2, 0)
				Control.PRESET_CENTER_RIGHT:
					animated_sprite.centered = false
					animated_sprite.offset = Vector2(-ase.width, -ase.height / 2)
				Control.PRESET_CENTER_BOTTOM:
					animated_sprite.centered = false
					animated_sprite.offset = Vector2(-ase.width / 2, -ase.height)
				_:
					animated_sprite.centered = true
					animated_sprite.offset = Vector2(0, 0)

			var sprite_frames := SpriteFrames.new()
			animated_sprite.sprite_frames = sprite_frames

			if ase.tags.size() > 0:
				for tag_index in range(ase.tags.size()):
					var tag := ase.tags[tag_index]

					var frames_count := tag.to_frame - tag.from_frame + 1
					var canvas := Image.create_empty(ase.width * frames_count, ase.height, false, Image.FORMAT_RGBA8)

					# in milliseconds
					var duration: int = 0

					for frame_index in range(tag.from_frame, tag.to_frame + 1):
						duration += ase.frames[frame_index].duration

						var image := ase.get_layer_frame_image(layer_index, frame_index)
						canvas.blit_rect(image, Rect2i(Vector2i.ZERO, image.get_size()), Vector2i(ase.width * (frame_index - tag.from_frame), 0))

					var fps := 1000.0 / (duration / frames_count)

					var atlas := ImageTexture.create_from_image(canvas)

					var animation_name := tag.name.validate_node_name().strip_escapes().strip_edges().to_snake_case()

					if not sprite_frames.has_animation(animation_name):
						sprite_frames.add_animation(animation_name)

					sprite_frames.clear(animation_name)
					sprite_frames.set_animation_loop(animation_name, false if frames_count == 1 else tag.repeat == 0)
					sprite_frames.set_animation_speed(animation_name, fps)

					var hint_default := tag.name.containsn("default") or tag.name.containsn("idle")
					if hint_default or tag_index == 0:
						animated_sprite.animation = animation_name

					# auto-play on load
					if tag.name.containsn("idle"):
						animated_sprite.autoplay = animation_name

					for frame_index in frames_count:
						var atlas_texture := AtlasTexture.new()
						atlas_texture.atlas = atlas
						atlas_texture.region = Rect2(ase.width * frame_index, 0, ase.width, ase.height)

						sprite_frames.add_frame(animation_name, atlas_texture)

			else:
				var frames_count := ase.frames.size()
				var canvas := Image.create_empty(ase.width * frames_count, ase.height, false, Image.FORMAT_RGBA8)

				# in milliseconds
				var duration: int = 0

				for frame_index in range(ase.frames.size()):
					duration += ase.frames[frame_index].duration

					var image := ase.get_layer_frame_image(layer_index, frame_index)
					canvas.blit_rect(image, Rect2i(Vector2i.ZERO, image.get_size()), Vector2i(ase.width * frame_index, 0))

				var fps := 1000.0 / (duration / frames_count)

				var atlas := ImageTexture.create_from_image(canvas)

				var animation_name := layer.name.validate_node_name().strip_escapes().strip_edges().to_snake_case()

				if not sprite_frames.has_animation(animation_name):
					sprite_frames.add_animation(animation_name)

				sprite_frames.clear(animation_name)
				sprite_frames.set_animation_loop(animation_name, true) # TODO: check for the layer name, if it contains "noloop" or "once" disable loop
				sprite_frames.set_animation_speed(animation_name, fps)

				var hint_default := layer.name.containsn("default") or layer.name.containsn("idle")
				if hint_default:
					animated_sprite.animation = animation_name

				# auto-play on load
				if layer.name.containsn("idle"):
					animated_sprite.autoplay = animation_name

				for frame_index in frames_count:
					var atlas_texture := AtlasTexture.new()
					atlas_texture.atlas = atlas
					atlas_texture.region = Rect2(ase.width * frame_index, 0, ase.width, ase.height)

					sprite_frames.add_frame(animation_name, atlas_texture)

	var scene := PackedScene.new()
	err = scene.pack(root_node)

	if err != OK:
		return err

	err = ResourceSaver.save(scene, save_path + "." + _get_save_extension())

	if err != OK:
		return err

	return err
