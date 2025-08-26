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
var _options_path: String = ""
var _options_ase: AsepriteFile = null

func _get_import_options(path: String, preset_index: int) -> Array:
	_options = _get_presets()[preset_index]["options"].duplicate(true)

	_options_ase = null
	_options_path = path

	_configuring_options = true
	_configure_input_options(path, preset_index)
	_configuring_options = false

	_options_ase = null
	_options_path = ""

	var options = _options.duplicate()
	_options = []

	return options

func _get_option_visibility(path: String, option_name: StringName, options: Dictionary) -> bool:
	return true

func _configure_input_options(path: String, preset_index: int) -> void:
	pass

# see: https://github.com/godotengine/godot/blob/17fb6e3bd06f6425ad9ec0d93718ce8f848fc3fc/editor/import/editor_import_plugin.cpp#L120
# "name"
# "default_value"
# "property_hint" = PROPERTY_HINT_NONE
# "hint_string"
# "usage" = PROPERTY_USAGE_DEFAULT
func add_import_option(value: Dictionary) -> void:
	assert(_configuring_options, "add_import_option can only be called from _configure_input_options")
	_options.append(value)

func add_import_option_layer(layer: AsepriteFile.Layer, value: Dictionary) -> void:
	assert(_configuring_options, "add_import_option_layer can only be called from _configure_input_options")
	assert(_options_ase, "add_import_option_layer can only be called after get_layers")

	value.set("name", _get_layer_option_name(_options_ase, layer, value.get("name", "")))

	add_import_option(value)

func get_layers() -> Array[AsepriteFile.Layer]:
	assert(_configuring_options, "get_layers can only be called from _configure_input_options")
	return _get_ase().layers.duplicate()

func _get_ase() -> AsepriteFile:
	assert(_configuring_options, "_get_ase can only be called from _configure_input_options")

	if _options_ase:
		return _options_ase

	_options_ase = AsepriteFile.new()
	var err := _options_ase.open(_options_path, AsepriteFile.OPEN_FLAG_SKIP_BUFFER)
	if err != OK:
		_options_ase.close()
		push_warning("Aseprite - Failed to inspect file: %s" % error_string(err))

	return _options_ase

static func _normalize_layer_name(name: String) -> String:
	return name.validate_node_name().replace(" ", "_").replace("/", "_").replace("\\", "_").to_lower()

static func _get_layer_option_name(ase_file: AsepriteFile, layer: AsepriteFile.Layer, option: String) -> String:
	var stack: Array[String] = []
	for layer_index in range(ase_file.layers.size()):
		var current_layer := ase_file.layers[layer_index]

		while stack.size() > current_layer.child_level:
			stack.pop_back()

		var seg := "%s_(#%s)" % [_normalize_layer_name(layer.name), layer_index]
		var base_name := "/".join(["layers"] + stack + [seg])
		stack.append(seg)

		if current_layer == layer:
			return "%s/%s" % [base_name, option]

	return ""
