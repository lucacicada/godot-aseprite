## Post importer for Aseprite's [code].aseprite[/code] scene file format.

@tool
class_name EditorScenePostImportPluginAseprite
extends EditorScenePostImportPlugin

func _get_internal_import_options(category: int) -> void:
	if INTERNAL_IMPORT_CATEGORY_NODE == category:
		add_import_option_advanced(
			TYPE_BOOL,
			"node/visible",
			true,
		)

		add_import_option_advanced(
			TYPE_STRING,
			"node/name",
			"",
		)
		add_import_option_advanced(
			TYPE_BOOL,
			"node/unique_name",
			false,
		)

		# add_import_option_advanced(
		# 	TYPE_OBJECT,
		# 	"node/script",
		# 	null,
		# 	PROPERTY_HINT_RESOURCE_TYPE,
		# 	"*.gd",
		# )

		# # Collision
		# add_import_option_advanced(
		# 	TYPE_INT,
		# 	"node_collision/collision_layer",
		# 	1,
		# 	PROPERTY_HINT_LAYERS_2D_PHYSICS,
		# )
		# add_import_option_advanced(
		# 	TYPE_INT,
		# 	"node_collision/collision_mask",
		# 	1,
		# 	PROPERTY_HINT_LAYERS_2D_PHYSICS,
		# )
		# add_import_option_advanced(
		# 	TYPE_FLOAT,
		# 	"node_collision/collision_priority",
		# 	1.0,
		# )

		# # Occluder
		# add_import_option_advanced(
		# 	TYPE_BOOL,
		# 	"node_occluder/sdf_collision",
		# 	true,
		# )
		# add_import_option_advanced(
		# 	TYPE_INT,
		# 	"node_occluder/occluder_light_mask",
		# 	1,
		# 	PROPERTY_HINT_LAYERS_2D_RENDER,
		# )

		# # NavigationObstacle2D
		# add_import_option_advanced(
		# 	TYPE_FLOAT,
		# 	"node_navigation_obstacle/radius",
		# 	0.0,
		# 	PROPERTY_HINT_RANGE,
		# 	"0.0,500,0.01,suffix:px",
		# )
		# add_import_option_advanced(
		# 	TYPE_BOOL,
		# 	"node_navigation_obstacle/affect_navigation_mesh",
		# 	false,
		# )
		# add_import_option_advanced(
		# 	TYPE_BOOL,
		# 	"node_navigation_obstacle/carve_navigation_mesh",
		# 	false,
		# )
		# add_import_option_advanced(
		# 	TYPE_BOOL,
		# 	"node_navigation_obstacle/avoidance_enabled",
		# 	true,
		# )
		# add_import_option_advanced(
		# 	TYPE_INT,
		# 	"node_navigation_obstacle/avoidance_layers",
		# 	1,
		# 	PROPERTY_HINT_LAYERS_AVOIDANCE,
		# )

func _pre_process(scene: Node) -> void:
	# Resert the texture filter to nearest
	# This is not strictly necessary, however i suspect Godot will break the importer at some point in the future
	if scene is CanvasItem:
		scene.texture_filter = CanvasItem.TEXTURE_FILTER_PARENT_NODE

func _internal_process(category: int, base_node: Node, node: Node, resource: Resource) -> void:
	# Godot will call this code for every type of import, including 3D scenes
	# This check is necessary, somehow Godot do not set the options properly for custom importers
	if base_node is Node3D:
		return

	if INTERNAL_IMPORT_CATEGORY_NODE != category:
		return

	# From this point forward, get_option_value() might get an error if the option is not found
	# We cannot check if an option exists, Godot do not offer such functionality
	var node_name = get_option_value("node/name")
	var node_script := get_option_value("node/script")

	if node_name is String and not node_name.is_empty():
		node.unique_name_in_owner = get_option_value("node/unique_name") == true
		node.name = node_name

	if node_script is String and not node_script.is_empty():
		var script := ResourceLoader.load(node_script, "Script")
		if script is Script:
			node.set_script(script)
		else:
			push_warning("Aseprite Importer: Failed to load script: %s" % node_script)

	# var node_type = get_option_value("node/type")
	# if node_type is String and not node_type.is_empty():
	# 	if not ClassDB.class_exists(node_type):
	# 		push_error("Invalid node type: %s" % node_type)
	# 		return

	# 	if not ClassDB.can_instantiate(node_type):
	# 		push_error("Cannot instantiate node type: %s" % node_type)
	# 		return

	# 	var new_node = ClassDB.instantiate(node_type) as Node
	# 	new_node.name = node.name
	# 	var owner = node.owner
	# 	node.replace_by(new_node, true)
	# 	new_node.owner = owner
	# 	node.free()
