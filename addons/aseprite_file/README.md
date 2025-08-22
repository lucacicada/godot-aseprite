# Godot Aseprite File

Open a file

```gdscript
var ase_file:= AsepriteFile.new()
var err := ase_file.open("res://path/to/file.aseprite")
if err != OK:
    push_error("Failed to open Aseprite file")
    return
```

Print all layers name

```gdscript
for layer in ase_file.layers:
    print(layer.name)
```
