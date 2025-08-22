# Godot Aseprite File

Open a file

```gdscript
var ase_file:= AsepriteFile.new()
var err := ase_file.open("res://path/to/file.aseprite")
if err != OK:
    push_error("Failed to open Aseprite file")
    return
```

Get an image for a specific layer, to get the first frame, pass 0 as the frame index

```gdscript
var layer_index := 0
var frame_index := 0
var image := ase_file.get_layer_frame_image(layer_index, frame_index)
image.save_png("res://path/to/save/image.png")
```

Print all layer names

```gdscript
for layer in ase_file.layers:
    print(layer.name)
```
