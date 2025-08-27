# Godot Aseprite File

Open a file

```gdscript
var ase := AsepriteFile.open("res://path/to/file.aseprite")
if ase == null:
    push_warning("Failed to open: %s" % error_string(AsepriteFile.get_open_error()))
    return
```

Get an image for a specific layer, to get the first frame, pass 0 as the frame index

```gdscript
var layer_index := 0
var frame_index := 0
var image := ase.get_layer_frame_image(layer_index, frame_index)
image.save_png("res://path/to/save/image.png")
```

Print all layer names

```gdscript
for layer in ase.layers:
    print(layer.name)
```

## Supported Chunks
- [x] Layer Chunk [0x2004]
- [x] Cel Chunk [0x2005]
- [x] Cel Extra Chunk [0x2006]
- [x] Color Profile Chunk [0x2007]
- [x] External Files Chunk [0x2008]
- [x] Tags Chunk [0x2018]
- [x] Palette Chunk [0x2019]
- [ ] User Data Chunk [0x2020]
- [x] Slice Chunk [0x2022]
- [x] Tileset Chunk [0x2023]
