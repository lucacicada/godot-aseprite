@tool
extends EditorPlugin

var importer_staticbody2d: EditorImportPlugin
var importer_imagetexture: EditorImportPlugin
var importer_tileset: EditorImportPlugin

func _enter_tree() -> void:
	importer_staticbody2d = preload("./aseprite_importer_staticbody2d.gd").new()
	add_import_plugin(importer_staticbody2d)

	importer_imagetexture = preload("./aseprite_importer_imagetexture.gd").new()
	add_import_plugin(importer_imagetexture)

	importer_tileset = preload("./aseprite_importer_tileset.gd").new()
	add_import_plugin(importer_tileset)

func _exit_tree() -> void:
	if importer_staticbody2d:
		remove_import_plugin(importer_staticbody2d)
		importer_staticbody2d.free()
		importer_staticbody2d = null

	if importer_imagetexture:
		remove_import_plugin(importer_imagetexture)
		importer_imagetexture.free()
		importer_imagetexture = null

	if importer_tileset:
		remove_import_plugin(importer_tileset)
		importer_tileset.free()
		importer_tileset = null
