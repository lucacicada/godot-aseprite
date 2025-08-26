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

## Supported Chunks
- [x] Layer Chunk [0x2004](./aseprite_file.gd#L1688)
- [x] Cel Chunk [0x2005](./aseprite_file.gd#L1740)
- [x] Cel Extra Chunk [0x2006](./aseprite_file.gd#L1788)
- [x] Color Profile Chunk [0x2007](./aseprite_file.gd#L1811)
- [x] External Files Chunk [0x2008](./aseprite_file.gd#L1836)
- [x] Tags Chunk [0x2018](./aseprite_file.gd#L1869)
- [x] Palette Chunk [0x2019](./aseprite_file.gd#L1909)
- [ ] User Data Chunk (0x2020)
- [x] Slice Chunk [0x2022](./aseprite_file.gd#L1955)
- [x] Tileset Chunk [0x2023](./aseprite_file.gd#L2004)
