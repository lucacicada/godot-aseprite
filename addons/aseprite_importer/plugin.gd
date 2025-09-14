@tool
extends EditorPlugin

const IMPORTER_SCENE := preload("./aseprite_importer_scene.gd")
const IMPORTER_SCENE_POST := preload("./aseprite_importer_scene_post_import.gd")
const IMPORTER_SPRITE_FRAMES := preload("./aseprite_importer_sprite_frames.gd")
const IMPORTER_TEXTURE2D := preload("./aseprite_importer_texture2d.gd")
const IMPORTER_TILES := preload("./aseprite_importer_tileset.gd")

var importer_scene: EditorSceneFormatImporter = IMPORTER_SCENE.new()
var importer_scene_post: EditorScenePostImportPlugin = IMPORTER_SCENE_POST.new()
var importer_sprite_frames: EditorImportPlugin = IMPORTER_SPRITE_FRAMES.new()
var importer_texture2d: EditorImportPlugin = IMPORTER_TEXTURE2D.new()
var importer_tileset: EditorImportPlugin = IMPORTER_TILES.new()

func _enter_tree() -> void:
	add_scene_format_importer_plugin(importer_scene)
	add_scene_post_import_plugin(importer_scene_post)
	add_import_plugin(importer_sprite_frames)
	add_import_plugin(importer_texture2d)
	add_import_plugin(importer_tileset)

func _exit_tree() -> void:
	remove_scene_format_importer_plugin(importer_scene)
	remove_scene_post_import_plugin(importer_scene_post)
	remove_import_plugin(importer_sprite_frames)
	remove_import_plugin(importer_texture2d)
	remove_import_plugin(importer_tileset)
