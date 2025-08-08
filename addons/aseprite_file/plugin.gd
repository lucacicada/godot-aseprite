@tool
extends EditorPlugin

func _enter_tree() -> void:
	add_custom_type("AsepriteFile", "RefCounted", preload("./aseprite_file.gd"), null)

func _exit_tree() -> void:
	remove_custom_type("asepriteFile")
