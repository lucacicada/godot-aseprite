@tool
extends EditorPlugin

const IMPORTER_SCENE := preload("./aseprite_importer_scene.gd")
const IMPORTER_TEXTURE2D := preload("./aseprite_importer_texture2d.gd")
const IMPORTER_TILES := preload("./aseprite_importer_tileset.gd")

var importer_scene: EditorImportPlugin = IMPORTER_SCENE.new()
var importer_texture2d: EditorImportPlugin = IMPORTER_TEXTURE2D.new()
var importer_tileset: EditorImportPlugin = IMPORTER_TILES.new()

func _enter_tree() -> void:
	add_import_plugin(importer_scene)
	add_import_plugin(importer_texture2d)
	add_import_plugin(importer_tileset)

	add_project_setting({
		"name": "aseprite/import/sprite_offset",
		"default_value": Control.PRESET_CENTER,
		"type": TYPE_INT,
		"hint": PROPERTY_HINT_ENUM,

		# Reuse the built-ins from Control.LayoutPreset for convenience.
		"hint_string": "Top Left:%d,Top Right:%d,Bottom Left:%d,Bottom Right:%d,Center Left:%d,Center Top:%d,Center Right:%d,Center Bottom:%d,Center:%d"
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
	})

func _exit_tree() -> void:
	remove_import_plugin(importer_scene)
	remove_import_plugin(importer_texture2d)
	remove_import_plugin(importer_tileset)

static func add_project_setting(hint: Dictionary) -> void:
	var key: String = hint.get("name")
	var default_value = hint.get("default_value", null)

	if not ProjectSettings.has_setting(key):
		ProjectSettings.set(key, default_value)

	ProjectSettings.set_initial_value(key, default_value)
	ProjectSettings.add_property_info(hint)
