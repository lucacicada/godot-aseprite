@tool
extends EditorImportPlugin

var _configuring_presets := false
var _presets: Array[Dictionary] = []

func _get_presets() -> Array[Dictionary]:
	_presets = []
	_configuring_presets = true
	_configure_presets()
	_configuring_presets = false
	var presets = _presets.duplicate()
	_presets = []

	if presets.size() == 0:
		presets.append({"name": "Default", "options": []})

	return presets

func _configure_presets() -> void:
	pass

func add_preset(name: String, options: Array[Dictionary]) -> void:
	assert(_configuring_presets, "add_preset can only be called from _configure_presets")
	_presets.append({"name": name, "options": options})

func _get_recognized_extensions() -> PackedStringArray: return ["aseprite", "ase"]
func _get_priority() -> float: return 1.0
func _get_import_order() -> int: return IMPORT_ORDER_DEFAULT
func _get_preset_count() -> int: return _get_presets().size()
func _get_preset_name(preset_index: int) -> String: return _get_presets()[preset_index]["name"]

var _configuring_options := false
var _options: Array = []

func _get_import_options(path: String, preset_index: int) -> Array:
	_options = _get_presets()[preset_index]["options"].duplicate(true)

	_configuring_options = true
	_configure_import_options(path, preset_index)
	_configuring_options = false

	var options = _options.duplicate()
	_options = []

	return options

func _get_option_visibility(path: String, option_name: StringName, options: Dictionary) -> bool:
	return true

func _configure_import_options(path: String, preset_index: int) -> void:
	pass

# see: https://github.com/godotengine/godot/blob/17fb6e3bd06f6425ad9ec0d93718ce8f848fc3fc/editor/import/editor_import_plugin.cpp#L120
# "name"
# "default_value"
# "property_hint" = PROPERTY_HINT_NONE
# "hint_string"
# "usage" = PROPERTY_USAGE_DEFAULT
func add_import_option(value: Dictionary) -> void:
	assert(_configuring_options, "add_import_option can only be called from _configure_import_options")
	_options.append(value)

func add_import_option_layer(ase: AsepriteFile, layer: AsepriteFile.Layer, value: Dictionary) -> void:
	assert(_configuring_options, "add_import_option_layer can only be called from _configure_input_options")

	value.set("name", _get_layer_option_name(ase, layer, value.get("name", "")))

	add_import_option(value)

func get_import_option_layer(ase: AsepriteFile, layer: AsepriteFile.Layer, option: String, options: Dictionary, default: Variant = null) -> Variant:
	var name := _get_layer_option_name(ase, layer, option)
	return options.get(name, default)

static func _get_layer_option_name(ase: AsepriteFile, layer: AsepriteFile.Layer, option: String) -> String:
	var stack: Array[String] = []
	for layer_index in range(ase.layers.size()):
		var current_layer := ase.layers[layer_index]

		while stack.size() > current_layer.child_level:
			stack.pop_back()

		# Normalize the layer name to avoid issues with special characters
		var layer_name := current_layer.name.validate_node_name().replace(" ", "_").replace("/", "_").replace("\\", "_").to_lower()

		var seg := "%s_(#%s)" % [layer_name, layer_index]
		var base_name := "/".join(["layers"] + stack + [seg])
		stack.append(seg)

		if current_layer == layer:
			return "%s/%s" % [base_name, option]

	return ""
