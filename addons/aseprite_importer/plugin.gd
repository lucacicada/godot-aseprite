@tool
extends EditorPlugin

const IMPORTER_PORTABLE_COMPRESSED_TEXTURE2D := preload("./aseprite_importer_portable_compressed_texture2d.gd")
const IMPORTER_STATIC_BODY2D := preload("./aseprite_importer_static_body2d.gd")
const IMPORTER_TILES := preload("./aseprite_importer_tileset.gd")

var importer_portable_compressed_texture2d: EditorImportPlugin = IMPORTER_PORTABLE_COMPRESSED_TEXTURE2D.new()
var importer_static_body2d: EditorImportPlugin = IMPORTER_STATIC_BODY2D.new()
var importer_tileset: EditorImportPlugin = IMPORTER_TILES.new()

func _enter_tree() -> void:
	add_import_plugin(importer_portable_compressed_texture2d)
	add_import_plugin(importer_static_body2d)
	add_import_plugin(importer_tileset)

func _exit_tree() -> void:
	remove_import_plugin(importer_portable_compressed_texture2d)
	remove_import_plugin(importer_static_body2d)
	remove_import_plugin(importer_tileset)
