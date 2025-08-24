# Godot Aseprite

<p align="center"><img src="ase256.png" alt="Aseprite Logo"/></p>

Aseprite file parser for Godot Engine.

## Supported Chunks
- [ ] Old palette chunk (0x0004)
- [ ] Old palette chunk (0x0011)
- [x] Layer Chunk (0x2004)
- [x] Cel Chunk (0x2005)
- [x] Cel Extra Chunk (0x2006)
- [x] Color Profile Chunk (0x2007)
- [ ] External Files Chunk (0x2008)
- [ ] Mask Chunk (0x2016) DEPRECATED
- [ ] Path Chunk (0x2017) Never used
- [x] Tags Chunk (0x2018)
- [x] Palette Chunk (0x2019)
- [ ] User Data Chunk (0x2020)
- [x] Slice Chunk (0x2022)
- [x] Tileset Chunk (0x2023)

## Script

The script is in a single GDScript file [addons/aseprite_file/aseprite_file.gd](addons/aseprite_file/aseprite_file.gd)

You can use it as a plugin or copy the file in your project.

## ERR_FILE_CORRUPT

The parser perform several strict checks to ensure the file is valid.
At the moment, it return a generic `ERR_FILE_CORRUPT` error if the file is malformed.
In the future, a warning message will be printed.

## Security note

Be careful using this parser for untrusted files, especially if you plan to use it for network shared resources.

The .aseprite format can be used to store filenames, potentially leaking personal info.

A malicious file could also contain a large amount of transparent pixels, when uncompressed, it could take a lot of memory.
Transparent pixels can be compressed efficiently, the raw data is `w * h * color_depth`, on very large image dimensions, this could lead to the uncompressed data being very large.

~~This parser is vulnerable to gzip bombs as `decompress_dynamic` calls are unbounded (`-1`).~~

~~The compression format used by Aseprite is ZLIB; it does not store the uncompressed size of the deflated buffer. Without this information, it is not possible to know at runtime how large the uncompressed buffer will be.~~

~~A heuristic could be implemented to limit this class of attacks, `compressed_size * 5.7` is a good estimate, exceeding an order of magnitude is likely a malformed file. A compression rate of `10:1` is extreme for images.~~

Edit: This parser is **NOT** vulnerable to gzip bombs, it turns out I already contradicted myself in the code, the `decompress_dynamic` call has been replaced with `decompress` with the appropriate expected size.
