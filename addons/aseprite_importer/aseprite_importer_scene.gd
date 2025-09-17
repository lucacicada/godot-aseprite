## Importer for Aseprite's [code].aseprite[/code] scene file format.

@tool
class_name EditorSceneFormatImporterAseprite
extends EditorSceneFormatImporter

func _get_extensions() -> PackedStringArray: return ["aseprite"]

# Hide default options that are unused
#
# For a list of built-in options, see:
# https://github.com/godotengine/godot/blob/4.4/editor/import/3d/resource_importer_scene.cpp#L2384
func _get_option_visibility(path: String, _for_animation: bool, option: String):
	# Only toggle visibility for .aseprite files
	if path.is_empty() or not path.get_extension().to_lower() in _get_extensions():
		return null

	if option in [
		"nodes/root_type",
		"nodes/root_name",
		"nodes/root_script",
	]:
		return true

	for prefix in [
		"nodes/",
		"animation/",
		"materials/",
		"skins/",
		"meshes/",
		"import_script/",
	]:
		if option.begins_with(prefix):
			return false

	return true

func _get_import_options(path: String) -> void:
	# Only show the options for .aseprite files or when the path is empty indicating the user is browsing the project settings
	if not path.is_empty() and not path.get_extension().to_lower() in _get_extensions():
		return

	# add_import_option_advanced(
	# 	TYPE_OBJECT,
	# 	"aseprite/nodes/root_script",
	# 	null,
	# 	PROPERTY_HINT_RESOURCE_TYPE,
	# 	"Script",
	# )

	add_import_option_advanced(
		TYPE_INT,
		"aseprite/sprites/offset",
		Control.PRESET_CENTER,
		PROPERTY_HINT_ENUM,
		"Top Left:%d,Top Right:%d,Bottom Left:%d,Bottom Right:%d,Center Left:%d,Center Top:%d,Center Right:%d,Center Bottom:%d,Center:%d"
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
		],
	)
	add_import_option_advanced(
		TYPE_FLOAT,
		"aseprite/sprites/y_sort_origin",
		0.0,
	)

	add_import_option_advanced(
		TYPE_INT,
		"aseprite/collision/collision_layer",
		1,
		PROPERTY_HINT_LAYERS_2D_PHYSICS,
	)
	add_import_option_advanced(
		TYPE_INT,
		"aseprite/collision/collision_mask",
		1,
		PROPERTY_HINT_LAYERS_2D_PHYSICS,
	)
	add_import_option_advanced(
		TYPE_FLOAT,
		"aseprite/collision/collision_priority",
		1.0,
	)

	add_import_option_advanced(
		TYPE_BOOL,
		"aseprite/occluder/sdf_collision",
		true,
	)
	add_import_option_advanced(
		TYPE_INT,
		"aseprite/occluder/light_mask",
		1,
		PROPERTY_HINT_LAYERS_2D_RENDER,
	)
	add_import_option_advanced(
		TYPE_BOOL,
		"aseprite/occluder/polygon_closed",
		true,
	)
	add_import_option_advanced(
		TYPE_INT,
		"aseprite/occluder/polygon_cull_mode",
		OccluderPolygon2D.CULL_DISABLED,
		PROPERTY_HINT_ENUM,
		"Disabled,ClockWise,CounterClockWise"
	)

	add_import_option_advanced(
		TYPE_FLOAT,
		"aseprite/navigation_obstacle/radius",
		0.0,
		PROPERTY_HINT_RANGE,
		"0.0,500,0.01,suffix:px",
	)
	add_import_option_advanced(
		TYPE_BOOL,
		"aseprite/navigation_obstacle/affect_navigation_mesh",
		false,
	)
	add_import_option_advanced(
		TYPE_BOOL,
		"aseprite/navigation_obstacle/carve_navigation_mesh",
		false,
	)
	add_import_option_advanced(
		TYPE_BOOL,
		"aseprite/navigation_obstacle/avoidance_enabled",
		true,
	)
	add_import_option_advanced(
		TYPE_INT,
		"aseprite/navigation_obstacle/avoidance_layers",
		1,
		PROPERTY_HINT_LAYERS_AVOIDANCE,
	)

func _import_scene(path: String, _flags: int, options: Dictionary) -> Object:
	var ase := AsepriteFile.open(path)
	if ase == null:
		push_error("Failed to open Aseprite file: %s" % error_string(AsepriteFile.get_open_error()))
		return null

	var options_y_sort_origin: float = options.get("aseprite/sprites/y_sort_origin", 0.0)
	var options_sprite_offset: int = options.get("aseprite/sprites/offset", Control.PRESET_CENTER)

	var options_scene_root_type: String = options.get("nodes/root_type", "")

	var root_script: Script = null

	var root_script_path := options.get("nodes/root_script")

	if root_script_path is Script:
		root_script = root_script_path

	if root_script_path is String and not root_script_path.is_empty():
		if ResourceLoader.exists(root_script_path, "Script"):
			var script := ResourceLoader.load(root_script_path, "Script")
			if script is Script:
				root_script = script

	# Validate the root node name
	if options_scene_root_type.is_empty():
		# Guess the node type
		options_scene_root_type = "Node2D"

		var hint_character := ase.layers.any(func(layer: AsepriteFile.Layer) -> bool:
			if layer.child_level == 0 and (layer.name.containsn("player") or layer.name.containsn("character") or layer.name.containsn("hero") or layer.name.containsn("main")):
				return true
			return false
		)

		var hint_collision := ase.layers.any(func(layer: AsepriteFile.Layer) -> bool:
			if layer.child_level == 0 and layer.name.containsn("collision"):
				return true
			return false
		)

		if hint_character: options_scene_root_type = "CharacterBody2D"
		elif hint_collision: options_scene_root_type = "StaticBody2D"

		# If we have a custom script, guess its type by default
		if root_script:
			var script_base_type := root_script.get_instance_base_type()
			if ClassDB.is_parent_class(script_base_type, "Node"):
				options_scene_root_type = script_base_type

	if options_scene_root_type != "Node":
		# Sanity check, ensure the class actually exists
		if not ClassDB.class_exists(options_scene_root_type):
			push_error("Aseprite Importer - Root must be a Node, got \"%s\"" % options_scene_root_type)
			return null

		if not ClassDB.can_instantiate(options_scene_root_type):
			push_error("Aseprite Importer - Root type is \"%s\" not instantiable" % options_scene_root_type)
			return null

		# We must have a Node root
		if not ClassDB.is_parent_class(options_scene_root_type, "Node"):
			push_error("Aseprite Importer - Root must be a Node, got \"%s\"" % options_scene_root_type)
			return null

		# No 3D nodes allowed, they will break the importer
		if ClassDB.is_parent_class(options_scene_root_type, "Node3D"):
			push_error("Aseprite Importer - 3D nodes are not supported")
			return null

	var root_node := ClassDB.instantiate(options_scene_root_type) as Node

	assert(root_node is Node, "unexpected \"is_parent_class check\" failure")

	root_node.name = path.get_file().get_basename().to_pascal_case()

	# var root_script: String = options.get("nodes/root_script", "")
	# if not root_script.is_empty():
	# 	var script := ResourceLoader.load(root_script)
	# 	if script is Script:
	# 		root_node.set_script(script)
	# 	else:
	# 		push_warning("Aseprite Importer - Failed to load root script")

	if root_node is CollisionObject2D:
		root_node.collision_layer = options.get("collision/collision_layer", 1)
		root_node.collision_mask = options.get("collision/collision_mask", 1)
		root_node.collision_priority = options.get("collision/collision_priority", 1.0)

	if root_node is LightOccluder2D:
		root_node.occluder_light_mask = options.get("occluder/light_mask", 1)
		root_node.sdf_collision = options.get("occluder/sdf_collision", true)

	if root_node is NavigationObstacle2D:
		root_node.radius = options.get("navigation_obstacle/radius", 0.0)
		root_node.avoidance_enabled = options.get("navigation_obstacle/avoidance_enabled", true)
		root_node.avoidance_layers = options.get("navigation_obstacle/avoidance_layers", 1)
		root_node.affect_navigation_mesh = options.get("navigation_obstacle/affect_navigation_mesh", false)
		root_node.carve_navigation_mesh = options.get("navigation_obstacle/carve_navigation_mesh", false)

	for layer_index in range(ase.layers.size()):
		var layer := ase.layers[layer_index]

		if layer.type != AsepriteFile.LAYER_TYPE_NORMAL:
			continue

		if layer.opacity == 0:
			continue

		if layer.name.ends_with("-noimp"):
			continue

		if ase.is_layer_frame_empty(layer_index, 0):
			continue

		if layer.name.replace("_", "").replace("-", "").containsn("YSort"):
			var img := ase.get_layer_frame_image(layer_index, 0)

			var y_sort := 0

			# Find the y-sort, scan the image, the first row that has all transparent pixels is the y-sort
			for y in range(img.get_height()):
				var all_transparent := true
				for x in range(img.get_width()):
					if img.get_pixelv(Vector2i(x, y)).a > 0.0:
						all_transparent = false
						break
				if all_transparent:
					y_sort = y
					break

			options_y_sort_origin = ase.height - y_sort

			break

	for layer_index in range(ase.layers.size()):
		var layer := ase.layers[layer_index]
		var layer_node_name := layer.name.strip_escapes().strip_edges().validate_node_name()

		if layer.type != AsepriteFile.LAYER_TYPE_NORMAL:
			continue

		if layer.opacity == 0:
			continue

		if layer.name.ends_with("-noimp"):
			continue

		if ase.is_layer_frame_empty(layer_index, 0):
			continue

		if layer.name.replace("_", "").replace("-", "").containsn("YSort"):
			continue

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
				navigation_obstacle.avoidance_enabled = options.get("navigation_obstacle/avoidance_enabled", true)
				navigation_obstacle.avoidance_layers = options.get("navigation_obstacle/avoidance_layers", 1)
				navigation_obstacle.affect_navigation_mesh = options.get("navigation_obstacle/affect_navigation_mesh", false)
				navigation_obstacle.carve_navigation_mesh = options.get("navigation_obstacle/carve_navigation_mesh", false)

				# The outline vertices of the obstacle.
				# If the vertices are winded in clockwise order agents will be pushed in by the obstacle, else they will be pushed out.
				# Outlines can not be crossed or overlap.
				# Should the vertices using obstacle be warped to a new position agent's
				# can not predict this movement and may get trapped inside the obstacle.
				navigation_obstacle.vertices = points

				root_node.add_child(navigation_obstacle, true)
				navigation_obstacle.owner = root_node

			continue

		if layer.name.containsn("Occlude") or layer.name.containsn("Occlusion"):
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
				occluder_polygon.closed = options.get("occluder/polygon_closed", true)
				occluder_polygon.cull_mode = options.get("occluder/polygon_cull_mode", OccluderPolygon2D.CULL_DISABLED)
				occluder_polygon.polygon = points

				light_occluder.occluder = occluder_polygon

			continue

		if layer.name.containsn("Area2D") or layer.name.containsn("HitBox") or layer.name.containsn("HurtBox"):
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

		if layer.name.containsn("Collision"):
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

				# collision_polygon.unique_name_in_owner = true
				collision_polygon.name = layer_node_name
				collision_polygon.polygon = points

				root_node.add_child(collision_polygon, true)
				collision_polygon.owner = root_node

			continue

		var unique_frame_count := 0
		for frame_index in range(ase.frames.size()):
			var frame := ase.frames[frame_index]

			var cels := frame.cels.filter(func(cel: AsepriteFile.Cel): return cel.layer_index == layer_index)
			var cels_all_linked := cels.all(func(cel: AsepriteFile.Cel): return cel.type == AsepriteFile.CEL_TYPE_LINKED)

			if cels_all_linked:
				continue

			unique_frame_count += 1

		if unique_frame_count == 0:
			continue

		# Sprite2D
		if unique_frame_count == 1:
			var sprite := Sprite2D.new()
			sprite.visible = layer.is_visible()
			sprite.name = layer_node_name
			root_node.add_child(sprite, true)
			sprite.owner = root_node

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

			sprite.offset.y += options_y_sort_origin

			var layer_image := ase.get_layer_frame_image(layer_index, 0)
			var texture := PortableCompressedTexture2D.new()
			texture.create_from_image(layer_image, PortableCompressedTexture2D.COMPRESSION_MODE_LOSSLESS)
			sprite.texture = texture

			continue

		if unique_frame_count > 1:
			var animated_sprite := AnimatedSprite2D.new()
			animated_sprite.visible = layer.is_visible()
			animated_sprite.name = layer_node_name
			root_node.add_child(animated_sprite, true)
			animated_sprite.owner = root_node

			var sprite_frames := SpriteFrames.new()
			animated_sprite.frames = sprite_frames

			# Clear any existing animations such as "default"
			for anim in sprite_frames.get_animation_names():
				sprite_frames.remove_animation(anim)

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

			animated_sprite.offset += Vector2(0, options_y_sort_origin)

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

					# var atlas := ImageTexture.create_from_image(canvas)
					var texture := PortableCompressedTexture2D.new()
					texture.create_from_image(canvas, PortableCompressedTexture2D.COMPRESSION_MODE_LOSSLESS)
					var atlas := texture

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

				# var atlas := ImageTexture.create_from_image(canvas)
				var texture := PortableCompressedTexture2D.new()
				texture.create_from_image(canvas, PortableCompressedTexture2D.COMPRESSION_MODE_LOSSLESS)
				var atlas := texture

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

			continue

	# Add the debug importer node
	if root_node is Node2D:
		var importer := ImporterRoot.new()
		importer.name = "PreviewDebugNode"
		importer.target_node = root_node
		importer.size = Vector2(ase.width, ase.height)

		match options_sprite_offset:
			Control.PRESET_TOP_LEFT: importer.anchor = Vector2(ase.width / 2.0, ase.height / 2.0)
			Control.PRESET_TOP_RIGHT: importer.anchor = Vector2(-ase.width / 2.0, ase.height / 2.0)
			Control.PRESET_BOTTOM_LEFT: importer.anchor = Vector2(ase.width / 2.0, -ase.height / 2.0)
			Control.PRESET_BOTTOM_RIGHT: importer.anchor = Vector2(-ase.width / 2.0, -ase.height / 2.0)
			Control.PRESET_CENTER_LEFT: importer.anchor = Vector2(ase.width / 2.0, 0)
			Control.PRESET_CENTER_TOP: importer.anchor = Vector2(0, ase.height / 2.0)
			Control.PRESET_CENTER_RIGHT: importer.anchor = Vector2(-ase.width / 2.0, 0)
			Control.PRESET_CENTER_BOTTOM: importer.anchor = Vector2(0, -ase.height / 2.0)

		importer.anchor += Vector2(0, options_y_sort_origin)

		# Defer adding the node, to avoid issues with the editor
		root_node.ready.connect(func() -> void:
			root_node.add_child(importer, true, Node.INTERNAL_MODE_BACK)
		)

	return root_node

# Resolve a script from a Variant that can be either a Script or a String path
static func _resolve_script(value: Variant) -> Script:
	if value is Script:
		return value

	if value is not String or value.is_empty():
		return value

	if not ResourceLoader.exists(value, "Script"):
		return null

	return ResourceLoader.load(value, "Script") as Script

static func _resolve_path(value: Variant) -> String:
	if value is not String or value.is_empty():
		return ""

	if value.begins_with("uid://"):
		var uid := ResourceUID.text_to_id(value)

		if uid == ResourceUID.INVALID_ID or not ResourceUID.has_id(uid):
			return ""

		value = ResourceUID.get_id_path(uid)

	if not value.begins_with("res://") or value.contains("::"):
		return ""

	return value

# Debug node, to render 2d-nodes in a viewport properly
class ImporterRoot extends Node2D:
	var target_node: Node
	var size: Vector2
	var anchor: Vector2

	var _drag := false
	var _start_drag_pos := Vector2.ZERO
	var _position_offset := Vector2.ZERO

	func _ready() -> void:
		assert(target_node != null, "ImporterRoot requires a target_node to function")

		# Draw on top of everything else
		z_index = RenderingServer.CANVAS_ITEM_Z_MAX

		# Set a background to cover the default 3d light
		var canvas := CanvasLayer.new()
		canvas.layer = -1
		add_child(canvas)

		var color_rect := ColorRect.new()
		color_rect.color = ProjectSettings.get_setting("rendering/environment/defaults/default_clear_color", Color(0.3, 0.3, 0.3, 1))
		color_rect.anchor_top = 0.0
		color_rect.anchor_bottom = 1.0
		color_rect.anchor_left = 0.0
		color_rect.anchor_right = 1.0
		color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		canvas.add_child(color_rect)

		# Correct the parten texture_filter
		if target_node is CanvasItem:
			target_node.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

	func _process(_delta: float) -> void:
		if not is_inside_tree():
			return

		var parent := target_node as Node2D
		if not is_instance_valid(parent) or not parent.is_inside_tree():
			return

		var viewport := parent.get_viewport()
		if viewport == null:
			return

		queue_redraw()

		# Simulate dragging the scene around
		if viewport.get_visible_rect().has_point(get_global_mouse_position()):
			var is_dragging := Input.is_mouse_button_pressed(MouseButton.MOUSE_BUTTON_LEFT)

			if not _drag and is_dragging:
				_start_drag_pos = get_global_mouse_position()
				_drag = true
			elif _drag and not is_dragging:
				_drag = false

			if Input.is_mouse_button_pressed(MouseButton.MOUSE_BUTTON_RIGHT):
				_drag = false
				_position_offset = Vector2.ZERO

		if not _drag:
			# _position_offset = Vector2.ZERO
			pass
		else:
			var current_pos = get_global_mouse_position()
			_position_offset += current_pos - _start_drag_pos
			_start_drag_pos = current_pos

		var viewport_size := viewport.get_visible_rect().size

		# Center and scale the parent node to fit in the viewport
		var scale := minf(viewport_size.x / size.x, viewport_size.y / size.y) * 0.9
		parent.scale = Vector2(scale, scale)

		var viewport_center := viewport_size / 2
		parent.position = viewport_center - anchor * scale
		parent.position += _position_offset

	func _draw() -> void:
		# draw the bounding box in thin gray
		var bounding_box := Rect2(-size / 2.0, size)
		bounding_box.position += anchor

		draw_rect(bounding_box, Color(0.5, 0.5, 0.5, 1.0), false, 1.0 / global_scale.x)

		# Draw the y-sort origin line
		draw_line(Vector2(bounding_box.position.x, 0), Vector2(bounding_box.position.x + bounding_box.size.x, 0), Color.MAGENTA, 2.0 / global_scale.x)
