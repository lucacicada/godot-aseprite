# ## References

# ASE files use Intel (little-endian) byte order.

# * `BYTE`: An 8-bit unsigned integer value
# * `WORD`: A 16-bit unsigned integer value
# * `SHORT`: A 16-bit signed integer value
# * `DWORD`: A 32-bit unsigned integer value
# * `LONG`: A 32-bit signed integer value
# * `FIXED`: A 32-bit fixed point (16.16) value
# * `FLOAT`: A 32-bit single-precision value
# * `DOUBLE`: A 64-bit double-precision value
# * `QWORD`: A 64-bit unsigned integer value
# * `LONG64`: A 64-bit signed integer value
# * `BYTE[n]`: "n" bytes.
# * `STRING`:
#   - `WORD`: string length (number of bytes)
#   - `BYTE[length]`: characters (in UTF-8)
#   The `'\0'` character is not included.
# * `POINT`:
#   - `LONG`: X coordinate value
#   - `LONG`: Y coordinate value
# * `SIZE`:
#   - `LONG`: Width value
#   - `LONG`: Height value
# * `RECT`:
#   - `POINT`: Origin coordinates
#   - `SIZE`: Rectangle size
# * `PIXEL`: One pixel, depending on the image pixel format:
#   - **RGBA**: `BYTE[4]`, each pixel have 4 bytes in this order Red, Green, Blue, Alpha.
#   - **Grayscale**: `BYTE[2]`, each pixel have 2 bytes in the order Value, Alpha.
#   - **Indexed**: `BYTE`, each pixel uses 1 byte (the index).
# * `TILE`: **Tilemaps**: Each tile can be a 8-bit (`BYTE`), 16-bit
#   (`WORD`), or 32-bit (`DWORD`) value and there are masks related to
#   the meaning of each bit.
# * `UUID`: A Universally Unique Identifier stored as `BYTE[16]`.

# Godot implementations, unsigned by default are used:

# BYTE: `fs.get_8()`
# WORD: `fs.get_16()`
# SHORT: `fs.get_16()`
# DWORD: `fs.get_32()`
# LONG: `fs.get_32()`
# FIXED: `fs.get_32() / 65536.0`
# FLOAT: `fs.get_32()`
# DOUBLE: `fs.get_64()`
# QWORD: `fs.get_64()`
# LONG64: `fs.get_64()`
# BYTE[n]: `fs.get_buffer(n)`
# STRING: `var size := fs.get_16(); var str := fs.get_buffer(size).get_string_from_utf8()`
# POINT: `Vector2(fs.get_32(), fs.get_32())`
# SIZE: `Vector2(fs.get_32(), fs.get_32())`
# RECT: `Rect2(fs.get_32(), fs.get_32(), fs.get_32(), fs.get_32())`
# PIXEL: `fs.get_buffer(4)` for RGBA, `fs.get_buffer(2)` for Grayscale, `fs.get_8()` for Indexed
# TILE: `fs.get_8()`, `fs.get_16()`, or `fs.get_32()` depending on the tile size
# UUID: `fs.get_buffer(16)`

## This class is used to read Aseprite files and extract metadata such as frames and layers.
class_name AsepriteFile extends RefCounted

const PALETTE_COLOR_FLAG_HAS_NAME: int = 1
const LAYER_TYPE_TILEMAP = 2

## Size of the file in bytes
var file_size: int = -1

## Number of frames in the sprite
var num_frames: int = 0

## Width in pixels
var width: int = 0

## Height in pixels
var height: int = 0

## Color depth (bits per pixel)
## 32 bpp = RGBA
## 16 bpp = Grayscale
## 8 bpp = Indexed
var color_depth: int = 0

## Flags (see NOTE.6):
## 1 = Layer opacity has valid value
## 2 = Layer blend mode/opacity is valid for groups (composite groups separately first when rendering)
## 4 = Layers have an UUID
var flags: int = 0

## Speed (milliseconds between frame, like in FLC files)
## DEPRECATED: You should use the frame duration field
## from each frame header
var speed: int = 0

## Palette entry (index) which represent transparent color
## in all non-background layers (only for Indexed sprites).
var palette_entry: int = 0

## Number of colors (0 means 256 for old sprites)
var num_colors: int = 0

## Pixel width (pixel ratio is "pixel width/pixel height").
## If this or pixel height field is zero, pixel ratio is 1:1
var pixel_width: int = 0

## Pixel height
var pixel_height: int = 0

## X position of the grid
var grid_x: int = 0

## Y position of the grid
var grid_y: int = 0

## Grid width (zero if there is no grid, grid size
## is 16x16 on Aseprite by default)
var grid_width: int = 0

## Grid height (zero if there is no grid)
var grid_height: int = 0

## The palette used in the sprite.
var palette: Palette = Palette.new()

## Frames in the sprite.
var frames: Array[Frame] = []

## Layers in the sprite.
var layers: Array[Layer] = []

## A tileset is a collection of individual tiles, arranged in a grid.
var tilesets: Array[Tileset] = []

var __consumed: bool = false

## Opens the Aseprite file for reading.
## Once a file is opened, it cannot be opened again, you need to create a new instance of this class.
func open(path: String) -> int:
	# Do not allow to re-open the file
	if __consumed: return ERR_ALREADY_IN_USE

	# Reset the state, in the future maybe we can reuse this instance
	self.file_size = -1
	self.palette = Palette.new()
	self.frames = []
	self.layers = []

	var fs := FileAccess.open(path, FileAccess.READ)
	if not fs: return FileAccess.get_open_error()

	# The file is too short to be a valid Aseprite file
	if fs.get_length() < 128:
		return ERR_FILE_EOF

	fs.big_endian = false

	# Read the header
	self.file_size = fs.get_32()

	# Check the magic number
	if fs.get_16() != 0xA5E0:
		return ERR_FILE_CORRUPT

	# The file is too short
	if fs.get_length() < self.file_size:
		return ERR_FILE_EOF

	self.num_frames = fs.get_16()
	self.width = fs.get_16()
	self.height = fs.get_16()
	self.color_depth = fs.get_16()
	self.flags = fs.get_32()
	self.speed = fs.get_16()

	# Two consecutive DWORDs must be zero
	if fs.get_32() != 0:
		return ERR_FILE_CORRUPT

	if fs.get_32() != 0:
		return ERR_FILE_CORRUPT

	self.palette_entry = fs.get_8()
	fs.seek(fs.get_position() + 3) # Skip 3 bytes
	self.num_colors = fs.get_16()
	self.pixel_width = fs.get_8()
	self.pixel_height = fs.get_8()
	self.grid_x = fs.get_16()
	self.grid_y = fs.get_16()
	self.grid_width = fs.get_16()
	self.grid_height = fs.get_16()
	fs.seek(fs.get_position() + 84) # Skip the rest of the header

	# Sanity check for header size
	if fs.get_position() != 128:
		return ERR_FILE_EOF

	# Read the frames
	for _frame_index in range(self.num_frames):
		var frame := Frame.new()
		frame._ase = weakref(self)
		self.frames.append(frame)

		# Read the frame header

		frame._position = fs.get_position()
		frame.frame_size = fs.get_32()

		# Aseprite - Invalid frame magic number
		if fs.get_16() != 0xF1FA:
			return ERR_FILE_CORRUPT

		frame.chunks_num_old = fs.get_16()
		frame.duration = fs.get_16()

		fs.seek(fs.get_position() + 2) # Skip 2 bytes

		frame.chunks_num_new = fs.get_32()

		# Per spec, use old chunks count if new chunks count is zero
		var chunks_num := frame.chunks_num_old if frame.chunks_num_new == 0 else frame.chunks_num_new

		# Read each chunk in the frame
		for chunk_index in range(chunks_num):
			var ase_chunk := Chunk.new()
			frame.chunks.append(ase_chunk)

			# Read the chunk header

			ase_chunk._position = fs.get_position()
			ase_chunk.chunk_size = fs.get_32()
			ase_chunk.chunk_type = fs.get_16()

			match ase_chunk.chunk_type:
				# Layer Chunk
				0x2004:
					var layer := Layer.new()
					layer._ase = weakref(self)
					self.layers.append(layer)

					# Read the layer data

					# WORD        Flags
					# WORD        Layer type
					# WORD        Layer child level (see NOTE.1)
					# WORD        Default layer width in pixels (ignored)
					# WORD        Default layer height in pixels (ignored)
					# WORD        Blend mode (see NOTE.6)
					# BYTE        Opacity (see NOTE.6)
					# BYTE[3]     For future (set to zero)
					# STRING      Layer name
					# + If layer type = 2
					#   DWORD     Tileset index
					# + If file header flags have bit 4:
					#   UUID      Layer's universally unique identifier

					layer._chunk_index = chunk_index
					layer.flags = fs.get_16()
					layer.type = fs.get_16()
					layer.child_level = fs.get_16()
					layer.default_width = fs.get_16()
					layer.default_height = fs.get_16()
					layer.blend_mode = fs.get_16()
					layer.opacity = fs.get_8()

					fs.seek(fs.get_position() + 3)

					layer.name = fs.get_buffer(fs.get_16()).get_string_from_utf8()

					if layer.type == 2:
						layer.tileset_index = fs.get_32()

					if layer.flags & 4:
						# UUID is 16 bytes long
						layer.uuid = fs.get_buffer(16).get_string_from_utf8()

				# Cel Chunk
				0x2005:
					var cel := Cel.new()
					cel._ase = weakref(self)
					frame.cels.append(cel)

					# Read the cel data

					# WORD        Layer index (see NOTE.2)
					# SHORT       X position
					# SHORT       Y position
					# BYTE        Opacity level
					# WORD        Cel Type
					# SHORT       Z-Index (see NOTE.5)
					# BYTE[5]     For future (set to zero)
					# + For cel type = 0 (Raw Image Data)
					#   WORD      Width in pixels
					#   WORD      Height in pixels
					#   PIXEL[]   Raw pixel data: row by row from top to bottom,
					#             for each scanline read pixels from left to right.
					# + For cel type = 1 (Linked Cel)
					#   WORD      Frame position to link with
					# + For cel type = 2 (Compressed Image)
					#   WORD      Width in pixels
					#   WORD      Height in pixels
					#   PIXEL[]   "Raw Cel" data compressed with ZLIB method (see NOTE.3)
					# + For cel type = 3 (Compressed Tilemap)
					#   WORD      Width in number of tiles
					#   WORD      Height in number of tiles
					#   WORD      Bits per tile (at the moment it's always 32-bit per tile)
					#   DWORD     Bitmask for tile ID (e.g. 0x1fffffff for 32-bit tiles)
					#   DWORD     Bitmask for X flip
					#   DWORD     Bitmask for Y flip
					#   DWORD     Bitmask for diagonal flip (swap X/Y axis)
					#   BYTE[10]  Reserved
					#   TILE[]    Row by row, from top to bottom tile by tile
					#             compressed with ZLIB method (see NOTE.3)

					cel._chunk_index = chunk_index
					cel.layer_index = fs.get_16()
					cel.x = fs.get_16()
					cel.y = fs.get_16()
					cel.opacity = fs.get_8()
					cel.type = fs.get_16()
					cel.z_index = fs.get_16()

					fs.seek(fs.get_position() + 5)

					if cel.type == 0:
						cel.w = fs.get_16()
						cel.h = fs.get_16()

						var buf = fs.get_buffer(ase_chunk.chunk_size - (fs.get_position() - ase_chunk._position))
						cel.buffer = buf

						# Aseprite - Cel buffer size mismatch
						if buf.size() != cel.w * cel.h * (self.color_depth / 8):
							return ERR_FILE_CORRUPT

					elif cel.type == 1:
						cel.link = fs.get_16()

					elif cel.type == 2:
						cel.w = fs.get_16()
						cel.h = fs.get_16()

						# ZLIB compressed buffer
						var buf := fs.get_buffer(ase_chunk.chunk_size - (fs.get_position() - ase_chunk._position))
						buf = buf.decompress_dynamic(-1, FileAccess.CompressionMode.COMPRESSION_DEFLATE)
						cel.buffer = buf

						# Aseprite - Cel buffer size mismatch
						if buf.size() != cel.w * cel.h * (self.color_depth / 8):
							return ERR_FILE_CORRUPT

					elif cel.type == 3:
						cel.w = fs.get_16()
						cel.h = fs.get_16()
						cel.bits_per_tile = fs.get_16()
						cel.bitmask_for_tile_id = fs.get_32()
						cel.bitmask_for_x_flip = fs.get_32()
						cel.bitmask_for_y_flip = fs.get_32()
						cel.bitmask_for_90cw_rotation = fs.get_32()

						fs.seek(fs.get_position() + 10) # Skip reserved bytes

						# ZLIB compressed buffer
						var buf := fs.get_buffer(ase_chunk.chunk_size - (fs.get_position() - ase_chunk._position))
						buf = buf.decompress_dynamic(-1, FileAccess.CompressionMode.COMPRESSION_DEFLATE)
						cel.buffer = buf

						# Aseprite - Cel buffer size mismatch
						if buf.size() != cel.w * cel.h * (cel.bits_per_tile / 8):
							return ERR_FILE_CORRUPT

				# Palette Chunk
				0x2019:
					self.palette = Palette.new()

					# Read the palette header

					# DWORD       New palette size (total number of entries)
					# DWORD       First color index to change
					# DWORD       Last color index to change
					# BYTE[8]     For future (set to zero)
					# + For each palette entry in [from,to] range (to-from+1 entries)
					#   WORD      Entry flags
					#   BYTE      Red (0-255)
					#   BYTE      Green (0-255)
					#   BYTE      Blue (0-255)
					#   BYTE      Alpha (0-255)
					#   + If has name bit in entry flags
					#     STRING  Color name

					self.palette._chunk_index = chunk_index
					self.palette.palette_size = fs.get_32()
					self.palette.first_color = fs.get_32()
					self.palette.last_color = fs.get_32()

					fs.seek(fs.get_position() + 8)

					# Read the palette colors

					for _palette_index in range(self.palette.palette_size):
						var palette_color := PaletteColor.new()
						self.palette.colors.append(palette_color)

						palette_color.flags = fs.get_16()
						palette_color.red = fs.get_8()
						palette_color.green = fs.get_8()
						palette_color.blue = fs.get_8()
						palette_color.alpha = fs.get_8()

						if palette_color.flags & PALETTE_COLOR_FLAG_HAS_NAME:
							palette_color.name = fs.get_buffer(fs.get_16()).get_string_from_utf8()

					assert(self.palette.palette_size == self.palette.colors.size(), "Aseprite - Palette size mismatch: expected %d, got %d" % [self.palette.palette_size, self.palette.colors.size()])

				# Tileset Chunk
				0x2023:
					var tileset := Tileset.new()
					tileset._ase = weakref(self)
					self.tilesets.append(tileset)

					tileset._chunk_index = chunk_index
					tileset.id = fs.get_32()
					tileset.flags = fs.get_32()
					tileset.tiles_count = fs.get_32()
					tileset.tile_width = fs.get_16()
					tileset.tile_height = fs.get_16()
					tileset.base_index = fs.get_16()
					fs.seek(fs.get_position() + 14) # Reserved bytes
					tileset.name = fs.get_buffer(fs.get_16()).get_string_from_utf8()

					if tileset.flags & 1 != 0:
						tileset.external_file_id = fs.get_16()
						tileset.external_id = fs.get_16()

					if tileset.flags & 2 != 0:
						var data_len := fs.get_32()

						assert(data_len == ase_chunk.chunk_size - (fs.get_position() - ase_chunk._position))

						# ZLIB compressed buffer
						var buf := fs.get_buffer(ase_chunk.chunk_size - (fs.get_position() - ase_chunk._position))
						buf = buf.decompress_dynamic(-1, FileAccess.CompressionMode.COMPRESSION_DEFLATE)
						tileset.buffer = buf

						# Aseprite - Cel buffer size mismatch
						if buf.size() != tileset.tile_width * tileset.tile_height * (self.color_depth / 8) * tileset.tiles_count:
							return ERR_FILE_CORRUPT

				_:
					# Ignore unsupported chunk types
					fs.seek(fs.get_position() + ase_chunk.chunk_size - 6)

			# Sanity check, make sure we have read the entire chunk
			if fs.get_position() != ase_chunk._position + ase_chunk.chunk_size:
				return ERR_FILE_EOF

		# Sanity check, this should never happen
		if chunks_num != frame.chunks.size():
			return ERR_FILE_CORRUPT

		# Sanity check, make sure we have read the entire frame
		if fs.get_position() != frame._position + frame.frame_size:
			return ERR_FILE_EOF

	# Sanity check, this should never happen
	if self.num_frames != self.frames.size():
		return ERR_FILE_CORRUPT

	# Sanity check, make sure we have read the entire file
	if fs.get_position() != self.file_size:
		return ERR_FILE_EOF

	__consumed = true

	return OK

## Closes the currently opened file and prevents subsequent read.
func close() -> void:
	pass

## Determines if the layer frame is empty.
## A layer frame is considered empty if it has no cel for that specified frame.
##
## Note: This method does not check for layer opacity, visibility, nor does it check for the size of the cel, nor if the cel is fully transparent.
## It only counts the number of cels in the frame which belong to the layer.
func is_layer_frame_empty(layer_index: int, frame_index: int) -> bool:
	# Count the number of cels in the frame which belong to the layer
	return self.frames[frame_index].cels.reduce(func(count: int, cel: AsepriteFile.Cel):
		return count + 1 if cel.layer_index == layer_index else count, 0
	) == 0

## Extract the image for the specified layer and frame.
##
## Note: The image format is RGBA8 regardless of the original color depth.
func get_layer_frame_image(layer_index: int, frame_index: int) -> Image:
	var cels: Array[Cel] = self.frames[frame_index].cels.filter(func(cel: AsepriteFile.Cel): return cel.layer_index == layer_index)

	# `sort_custom` sorts in place, we have used `filter` above which returns a new array so it's fine
	cels.sort_custom(func(a: AsepriteFile.Cel, b: AsepriteFile.Cel):
		var orderA := a.layer_index + a.z_index
		var orderB := b.layer_index + b.z_index
		return orderA - orderB || a.z_index - b.z_index
	)

	# TODO: print a warn, or assert
	if cels.size() == 0:
		return null

	var canvas := Image.create_empty(
		self.width,
		self.height,
		false,
		Image.FORMAT_RGBA8
	)

	for cel_index in range(cels.size()):
		var cel := cels[cel_index]
		var img := get_frame_cel_image(frame_index, cel_index)

		canvas.blit_rect(
			img,
			Rect2i(0, 0, img.get_width(), img.get_height()),
			Vector2i(cel.x, cel.y)
		)

	return canvas

## Extract the image for the specified cel in the specified frame.
##
## Note: The image format is RGBA8 regardless of the original color depth.
func get_frame_cel_image(frame_index: int, cel_index: int) -> Image:
	# Let Godot to throw "index out of bounds" error if any of the indexes are invalid
	var cel := self.frames[frame_index].cels[cel_index]

	# Special case for tilemap cels
	if cel.type == 3:
		assert(cel.bits_per_tile == 32, "Aseprite - Unsupported bits per tile: %d" % cel.bits_per_tile)

		var layer := self.layers[cel.layer_index]

		assert(layer.type == LAYER_TYPE_TILEMAP, "Aseprite - Cel layer is not a tilemap layer")

		var tileset := self.tilesets[layer.tileset_index]

		var canvas := Image.create_empty(
			cel.w * tileset.tile_width,
			cel.h * tileset.tile_height,
			false,
			Image.FORMAT_RGBA8
		)

		# Assert the cel.buffer.size() is precise multiple of 4 (cel.bits_per_tile / 8)
		assert(cel.buffer.size() % (cel.bits_per_tile / 8) == 0, "Aseprite - Cel buffer size is not a multiple of %d: %d" % [(cel.bits_per_tile / 8), cel.buffer.size()])

		# TODO: does godot support buffer-reader of some sort?
		for i in range(cel.buffer.size() / 4):
			var x1 := cel.buffer[i * 4 + 0]
			var x2 := cel.buffer[i * 4 + 1]
			var x3 := cel.buffer[i * 4 + 2]
			var x4 := cel.buffer[i * 4 + 3]

			# Expand little endian DWORD
			var dword := (x4 << 24) | (x3 << 16) | (x2 << 8) | x1

			var tile_id := dword & cel.bitmask_for_tile_id
			var x_flip := (dword & cel.bitmask_for_x_flip) != 0
			var y_flip := (dword & cel.bitmask_for_y_flip) != 0
			var rotation := (dword & cel.bitmask_for_90cw_rotation) != 0

			var img := tileset.get_tile_image(tile_id)

			# TODO: account for x_flip, y_flip and rotation!
			# Only if the layer is a tilemap layer those bits are be 0!
			canvas.blit_rect(
				img,
				Rect2i(0, 0, img.get_width(), img.get_height()),
				Vector2i(
					# Cel is arranged like an image, it has a stride and height
					(i % cel.w) * tileset.tile_width,
					(i / cel.w) * tileset.tile_height
				),
			)

		return canvas

	# Godot expands 8-bit indexed images to 32-bit RGBA8
	if self.color_depth == 8:
		var rgba8_buf := PackedByteArray()
		rgba8_buf.resize(cel.w * cel.h * 4)

		for i in range(cel.buffer.size()):
			var color_index := cel.buffer[i]

			# TODO: handle palette index out of bounds
			var color := self.palette.colors[color_index]

			rgba8_buf[i * 4 + 0] = color.red
			rgba8_buf[i * 4 + 1] = color.green
			rgba8_buf[i * 4 + 2] = color.blue
			rgba8_buf[i * 4 + 3] = color.alpha

		return Image.create_from_data(
			cel.w,
			cel.h,
			false,
			Image.FORMAT_RGBA8,
			rgba8_buf,
		)

	if self.color_depth == 16:
		var img := Image.create_from_data(
			cel.w,
			cel.h,
			false,
			Image.FORMAT_LA8,
			cel.buffer,
		)

		# Godot correcly conver 16-bit grayscale images to 32-bit RGBA8 images
		# In grayscale, RGB channels are all set to the same value
		# R = BYTE[0]
		# G = BYTE[0]
		# B = BYTE[0]
		# A = BYTE[1]
		img.convert(Image.FORMAT_RGBA8)

		return img

	return Image.create_from_data(
		cel.w,
		cel.h,
		false,
		Image.FORMAT_RGBA8,
		cel.buffer,
	)

## Return the image in the `Image.FORMAT_RGBA8` format.
static func create_image_from_data(width: int, height: int, color_depth: int, palette: Palette, data: PackedByteArray) -> Image:
	# Assert the buffer size
	assert(data.size() == width * height * (color_depth / 8), "Aseprite - Image buffer size mismatch: expected %d, got %d" % [width * height * (color_depth / 8), data.size()])

	# Godot expands 8-bit indexed images to 32-bit RGBA8
	if color_depth == 8:
		assert(palette, "Aseprite - No palette set for the image")

		# TODO: is there a way to create a PackedByteArray with a specific size?
		var buffer := PackedByteArray()
		buffer.resize(width * height * 4)

		for i in range(data.size()):
			var color_index := data[i]

			# TODO: handle palette index out of bounds
			var color := palette.colors[color_index]

			buffer[i * 4 + 0] = color.red
			buffer[i * 4 + 1] = color.green
			buffer[i * 4 + 2] = color.blue
			buffer[i * 4 + 3] = color.alpha

		return Image.create_from_data(
			width,
			height,
			false,
			Image.FORMAT_RGBA8,
			buffer,
		)

	if color_depth == 16:
		var img := Image.create_from_data(
			width,
			height,
			false,
			Image.FORMAT_LA8,
			data,
		)

		# Godot correctly convert 16-bit grayscale images to 32-bit RGBA8 images
		# In grayscale, RGB channels are all set to the same value
		# R = BYTE[0]
		# G = BYTE[0]
		# B = BYTE[0]
		# A = BYTE[1]
		img.convert(Image.FORMAT_RGBA8)

		return img

	assert(color_depth == 32, "Aseprite - Unsupported color depth: %d" % color_depth)

	return Image.create_from_data(
		width,
		height,
		false,
		Image.FORMAT_RGBA8,
		data,
	)

## Get a raw image from the buffer.
## For 8-bit: `Image.FORMAT_R8`, the palette indes is stored in the RED channel.
## For 16-bit: `Image.FORMAT_LA8`, Luminance store the RGB channels, R=G=B = Luminance
## For 32-bit: `Image.FORMAT_RGBA8`, 8 bits per channel, RGBA order.
static func create_raw_image_from_data(width: int, height: int, color_depth: int, data: PackedByteArray) -> Image:
	# Assert color depth
	assert(color_depth in [8, 16, 32], "Aseprite - Unsupported color depth: %d" % color_depth)

	# Assert buffer size
	assert(data.size() == width * height * (color_depth / 8), "Aseprite - Image buffer size mismatch: expected %d, got %d" % [width * height * (color_depth / 8), data.size()])

	var format := Image.FORMAT_RGBA8

	match color_depth:
		8:
			format = Image.FORMAT_R8
		16:
			format = Image.FORMAT_LA8
		_:
			format = Image.FORMAT_RGBA8

	return Image.create_from_data(
		width,
		height,
		false,
		format,
		data,
	)

class Frame extends RefCounted:
	var _ase: WeakRef

	## Position n bytes of this frame in the original source stream.
	var _position: int = -1

	## Bytes in this frame
	var frame_size: int = 0

	## Old field which specifies the number of "chunks"
	## in this frame. If this value is 0xFFFF, we might
	## have more chunks to read in this frame
	## (so we have to use the new field)
	var chunks_num_old: int = 0

	## Frame duration (in milliseconds)
	var duration: int = 0

	## New field which specifies the number of "chunks"
	## in this frame (if this is 0, use the old field)
	var chunks_num_new: int = 0

	var chunks: Array[Chunk] = []

	var cels: Array[Cel] = []

	# func get_chunks_count() -> int:
	# 	# Per spec, use old chunks count if new chunks count is zero
	# 	return chunks_num_old if chunks_num_new == 0 else chunks_num_new

	func get_image(layer_index: int) -> Image:
		var ase_file := _ase.get_ref() as AsepriteFile if _ase else null
		if not ase_file: return null

		var cels := self.cels

		cels = cels.filter(func(cel: AsepriteFile.Cel): return cel.layer_index == layer_index)
		# cels = cels.filter(func(cel: AsepriteFile.Cel): return cel.type == 0 or cel.type == 2)

		cels.sort_custom(func(a: AsepriteFile.Cel, b: AsepriteFile.Cel):
			var orderA := a.layer_index + a.z_index
			var orderB := b.layer_index + b.z_index
			return orderA - orderB || a.z_index - b.z_index
		)

		# Skip empty cels
		if cels.size() == 0:
			return null

		var canvas := Image.create_empty(ase_file.width, ase_file.height, false, Image.FORMAT_RGBA8)

		for cel_index in range(cels.size()):
			var cel := cels[cel_index]
			var img := cel.get_image()

			if not img:
				continue

			canvas.blit_rect(
				img,
				Rect2i(0, 0, img.get_width(), img.get_height()),
				Vector2i(cel.x, cel.y)
			)

		return canvas

class Chunk extends RefCounted:
	## Position in bytes of this chunk in the original source stream.
	var _position: int = -1

	var chunk_size: int = 0

	## Chunk type
	## Old palette chunk (0x0004)
	## Old palette chunk (0x0011)
	## Layer Chunk (0x2004)
	## Cel Chunk (0x2005)
	## Cel Extra Chunk (0x2006)
	## Color Profile Chunk (0x2007)
	## External Files Chunk (0x2008)
	## Mask Chunk (0x2016) DEPRECATED
	## Path Chunk (0x2017)
	## Tags Chunk (0x2018)
	## Palette Chunk (0x2019)
	## User Data Chunk (0x2020)
	## Slice Chunk (0x2022)
	## Tileset Chunk (0x2023)
	var chunk_type: int = 0

## 0x2019
class Palette extends RefCounted:
	## The index of the chunk that this layer belongs to.
	var _chunk_index: int = -1

	var palette_size: int = 0
	var first_color: int = 0
	var last_color: int = 0

	## Palette colors
	var colors: Array[PaletteColor] = []

class PaletteColor extends RefCounted:
	## Color flags
	## 1 = Has Name
	var flags: int = 0

	## Red component (0-255)
	var red: int = 0

	## Green component (0-255)
	var green: int = 0

	## Blue component (0-255)
	var blue: int = 0

	## Alpha component (0-255)
	var alpha: int = 0

	## Color name (if flags & 1)
	var name: String = ""

## 0x2004
class Layer extends RefCounted:
	var _ase: WeakRef

	## The index of the chunk that this layer belongs to.
	var _chunk_index: int = -1

	## Layer flags
    ## 1 = Visible
    ## 2 = Editable
    ## 4 = Lock movement
    ## 8 = Background
    ## 16 = Prefer linked cels
    ## 32 = The layer group should be displayed collapsed
    ## 64 = The layer is a reference layer
	var flags: int

	## Layer type
	## 0 = Normal (image) layer
	## 1 = Group
	## 2 = Tilemap
	var type: int

	## Layer child level
	var child_level: int

	## Default layer width in pixels (ignored)
	var default_width: int

	## Default layer height in pixels (ignored)
	var default_height: int

	## Blend mode
    ## - Normal         = 0
    ## - Multiply       = 1
    ## - Screen         = 2
    ## - Overlay        = 3
    ## - Darken         = 4
    ## - Lighten        = 5
    ## - Color Dodge    = 6
    ## - Color Burn     = 7
    ## - Hard Light     = 8
    ## - Soft Light     = 9
    ## - Difference     = 10
    ## - Exclusion      = 11
    ## - Hue            = 12
    ## - Saturation     = 13
    ## - Color          = 14
    ## - Luminosity     = 15
    ## - Addition       = 16
    ## - Subtract       = 17
    ## - Divide         = 18
	var blend_mode: int

	var opacity: int

	## Layer name
	var name: String = ""

	var tileset_index: int = -1
	var uuid: String = ""

## 0x2005
class Cel extends RefCounted:
	var _ase: WeakRef

	## The index of the chunk that this layer belongs to.
	var _chunk_index: int = -1

	## Layer index
	var layer_index: int

	## X coordinate of the cell
	var x: int

	## Y coordinate of the cell
	var y: int

	## Opacity of the cell
	var opacity: int

	## Cell type
	## 0 = Image
	## 1 = Linked Cel
	## 2 = Compressed Cel
	## 3 = Compressed Tilemap
	var type: int

	## Z index of the cell
	var z_index: int

	## Width in pixels
	## If type == 3: Width in number of tiles
	var w: int = 0
	var h: int = 0

	## Link to another cel (if type == 1)
	var link: int = -1

	## For type == 3
	var bits_per_tile: int = 0
	var bitmask_for_tile_id: int = 0
	var bitmask_for_x_flip: int = 0
	var bitmask_for_y_flip: int = 0
	var bitmask_for_90cw_rotation: int = 0

	var buffer: PackedByteArray = []

	# TODO: add support for compressed tilemaps and linked cels
	func get_image() -> Image:
		var ase_file := _ase.get_ref() as AsepriteFile if _ase else null
		if not ase_file: return null

		if self.type == 3:
			assert(self.bits_per_tile == 32, "Aseprite - Unsupported bits per tile: %d" % self.bits_per_tile)

			var layer := ase_file.layers[self.layer_index]

			assert(layer.type == LAYER_TYPE_TILEMAP, "Aseprite - Cel is not a tilemap layer")

			var tileset := ase_file.tilesets[layer.tileset_index]

			var canvas := Image.create_empty(
				self.w * tileset.tile_width,
				self.h * tileset.tile_height,
				false,
				Image.FORMAT_RGBA8
			)

			for i in range(self.buffer.size() / 4):
				var x1 := self.buffer[i * 4 + 0]
				var x2 := self.buffer[i * 4 + 1]
				var x3 := self.buffer[i * 4 + 2]
				var x4 := self.buffer[i * 4 + 3]

				var dword := (x4 << 24) | (x3 << 16) | (x2 << 8) | x1

				var tile_id := dword & self.bitmask_for_tile_id
				var x_flip := (dword & self.bitmask_for_x_flip) != 0
				var y_flip := (dword & self.bitmask_for_y_flip) != 0
				var rotation := (dword & self.bitmask_for_90cw_rotation) != 0

				var img := tileset.get_tile_image(tile_id)

				canvas.blit_rect(
					img,
					Rect2i(0, 0, img.get_width(), img.get_height()),
					Vector2i(
						(i % self.w) * tileset.tile_width,
						(i / self.w) * tileset.tile_height
					),
				)

			return canvas

		# Godot expands 8-bit indexed images to 32-bit RGBA8
		if ase_file.color_depth == 8:
			var rgba8_buf := PackedByteArray()
			rgba8_buf.resize(self.w * self.h * 4)

			for i in range(self.buffer.size()):
				var color_index := self.buffer[i]

				# TODO: handle palette index out of bounds
				var color := ase_file.palette.colors[color_index]

				rgba8_buf[i * 4 + 0] = color.red
				rgba8_buf[i * 4 + 1] = color.green
				rgba8_buf[i * 4 + 2] = color.blue
				rgba8_buf[i * 4 + 3] = color.alpha

			return Image.create_from_data(
				self.w,
				self.h,
				false,
				Image.FORMAT_RGBA8,
				rgba8_buf,
			)

		if ase_file.color_depth == 16:
			var img := Image.create_from_data(
				self.w,
				self.h,
				false,
				Image.FORMAT_LA8,
				self.buffer,
			)

			# Godot correcly conver 16-bit grayscale images to 32-bit RGBA8 images
			# In grayscale, RGB channels are all set to the same value
			# R = BYTE[0]
			# G = BYTE[0]
			# B = BYTE[0]
			# A = BYTE[1]
			img.convert(Image.FORMAT_RGBA8)

			return img

		return Image.create_from_data(
			self.w,
			self.h,
			false,
			Image.FORMAT_RGBA8,
			self.buffer,
		)

## 0x2023
class Tileset extends RefCounted:
	var _ase: WeakRef

	## The index of the chunk that this tileset belongs to.
	var _chunk_index: int = -1

	var id: int = 0
	var flags: int = 0
	var tiles_count: int = 0
	var tile_width: int = 0
	var tile_height: int = 0
	var base_index: int = 0
	var name: String = ""
	var external_file_id: int = -1
	var external_id: int = -1
	var buffer: PackedByteArray = []

	func get_image() -> Image:
		var ase_file := _ase.get_ref() as AsepriteFile if _ase else null
		assert(ase_file, "Aseprite - No reference to AsepriteFile")
		if not ase_file: return null

		# Godot expands 8-bit indexed images to 32-bit RGBA8
		if ase_file.color_depth == 8:
			var rgba8_buf := PackedByteArray()
			rgba8_buf.resize(self.tile_width * self.tile_height * 4)

			for i in range(self.buffer.size()):
				var color_index := self.buffer[i]

				# TODO: handle palette index out of bounds
				var color := ase_file.palette.colors[color_index]

				rgba8_buf[i * 4 + 0] = color.red
				rgba8_buf[i * 4 + 1] = color.green
				rgba8_buf[i * 4 + 2] = color.blue
				rgba8_buf[i * 4 + 3] = color.alpha

			return Image.create_from_data(
				self.tile_width,
				self.tile_height,
				false,
				Image.FORMAT_RGBA8,
				rgba8_buf,
			)

		if ase_file.color_depth == 16:
			var img := Image.create_from_data(
				self.tile_width,
				self.tile_height,
				false,
				Image.FORMAT_LA8,
				self.buffer,
			)

			# Godot correcly conver 16-bit grayscale images to 32-bit RGBA8 images
			# In grayscale, RGB channels are all set to the same value
			# R = BYTE[0]
			# G = BYTE[0]
			# B = BYTE[0]
			# A = BYTE[1]
			img.convert(Image.FORMAT_RGBA8)

			return img

		return Image.create_from_data(
			self.tile_width,
			self.tile_height,
			false,
			Image.FORMAT_RGBA8,
			self.buffer,
		)

	func get_tile_image(tile_id: int) -> Image:
		var ase_file := _ase.get_ref() as AsepriteFile if _ase else null
		assert(ase_file, "Aseprite - No reference to AsepriteFile")
		if not ase_file: return null

		# Compressed Tileset image (see NOTE.3): (Tile Width) x (Tile Height x Number of Tiles)
		var stride := self.tile_width * self.tile_height * (ase_file.color_depth / 8)

		var buffer_pos := tile_id * stride
		var buf := self.buffer.slice(buffer_pos, buffer_pos + stride)

		# Godot expands 8-bit indexed images to 32-bit RGBA8
		if ase_file.color_depth == 8:
			var rgba8_buf := PackedByteArray()
			rgba8_buf.resize(self.tile_width * self.tile_height * 4)

			for i in range(buf.size()):
				var color_index := buf[i]

				# TODO: handle palette index out of bounds
				var color := ase_file.palette.colors[color_index]

				rgba8_buf[i * 4 + 0] = color.red
				rgba8_buf[i * 4 + 1] = color.green
				rgba8_buf[i * 4 + 2] = color.blue
				rgba8_buf[i * 4 + 3] = color.alpha

			return Image.create_from_data(
				self.tile_width,
				self.tile_height,
				false,
				Image.FORMAT_RGBA8,
				rgba8_buf,
			)

		if ase_file.color_depth == 16:
			var img := Image.create_from_data(
				self.tile_width,
				self.tile_height,
				false,
				Image.FORMAT_LA8,
				buf,
			)

			# Godot correcly conver 16-bit grayscale images to 32-bit RGBA8 images
			# In grayscale, RGB channels are all set to the same value
			# R = BYTE[0]
			# G = BYTE[0]
			# B = BYTE[0]
			# A = BYTE[1]
			img.convert(Image.FORMAT_RGBA8)

			return img

		return Image.create_from_data(
			self.tile_width,
			self.tile_height,
			false,
			Image.FORMAT_RGBA8,
			buf,
		)

# FileAccess does not extend StreamPeer...
class _BinaryReader extends RefCounted:
	var stream: Variant

	func open(data: Variant):
		if data is FileAccess:
			data.big_endian = false
			self.stream = data

		elif data is StreamPeerBuffer:
			data.big_endian = false
			self.stream = data

		elif data is PackedByteArray:
			var buffer := StreamPeerBuffer.new()
			buffer.data_array = data
			buffer.big_endian = false
			self.stream = buffer

	func get_length() -> int:
		if stream is FileAccess: return stream.get_length()
		if stream is StreamPeerBuffer: return stream.get_size()
		return -1

	func get_position() -> int:
		if stream is FileAccess: return stream.get_position()
		if stream is StreamPeerBuffer: return stream.get_position()
		return -1

	func seek(position: int) -> void:
		if stream is FileAccess: stream.seek(position)
		if stream is StreamPeerBuffer: stream.seek(position)

	func get_byte() -> int:
		if stream is FileAccess: return stream.get_8()
		if stream is StreamPeerBuffer: return stream.get_8()
		return -1

	func get_word() -> int:
		if stream is FileAccess: return stream.get_16()
		if stream is StreamPeerBuffer: return stream.get_16()
		return -1

	func get_short() -> int:
		if stream is FileAccess: return stream.get_16()
		if stream is StreamPeerBuffer: return stream.get_16()
		return -1

	func get_dword() -> int:
		if stream is FileAccess: return stream.get_32()
		if stream is StreamPeerBuffer: return stream.get_32()
		return -1

	func get_long() -> int:
		if stream is FileAccess: return stream.get_32()
		if stream is StreamPeerBuffer: return stream.get_32()
		return -1

	func get_string() -> String:
		if stream is FileAccess: return stream.get_buffer(stream.get_16()).get_string_from_utf8()

		if stream is StreamPeerBuffer:
			var pos: int = stream.get_position()
			var buf: PackedByteArray = stream.data_array
			var string_len: int = stream.get_16()
			return buf.slice(pos, pos + string_len).get_string_from_utf8()

		return ""
