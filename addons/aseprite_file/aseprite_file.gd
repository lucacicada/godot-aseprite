## This class is used to read Aseprite files and extract metadata such as frames and layers.
class_name AsepriteFile extends RefCounted

const CHUNK_OLD_PALETTE_1 := Chunk.ChunkType.OLD_PALETTE_1
const CHUNK_OLD_PALETTE_2 := Chunk.ChunkType.OLD_PALETTE_2
const CHUNK_LAYER := Chunk.ChunkType.LAYER
const CHUNK_CEL := Chunk.ChunkType.CEL
const CHUNK_CEL_EXTRA := Chunk.ChunkType.CEL_EXTRA
const CHUNK_COLOR_PROFILE := Chunk.ChunkType.COLOR_PROFILE
const CHUNK_EXTERNAL_FILES := Chunk.ChunkType.EXTERNAL_FILES
const CHUNK_MASK := Chunk.ChunkType.MASK
const CHUNK_PATH := Chunk.ChunkType.PATH
const CHUNK_TAGS := Chunk.ChunkType.TAGS
const CHUNK_PALETTE := Chunk.ChunkType.PALETTE
const CHUNK_USER_DATA := Chunk.ChunkType.USER_DATA
const CHUNK_SLICE := Chunk.ChunkType.SLICE
const CHUNK_TILESET := Chunk.ChunkType.TILESET

const PALETTE_COLOR_FLAG_HAS_NAME := PaletteColor.Flags.HAS_NAME

const LAYER_TYPE_NORMAL := Layer.Type.NORMAL
const LAYER_TYPE_GROUP := Layer.Type.GROUP
const LAYER_TYPE_TILEMAP := Layer.Type.TILEMAP

const LAYER_FLAG_VISIBLE := Layer.Flags.VISIBLE
const LAYER_FLAG_EDITABLE := Layer.Flags.EDITABLE
const LAYER_FLAG_LOCK_MOVEMENT := Layer.Flags.LOCK_MOVEMENT
const LAYER_FLAG_BACKGROUND := Layer.Flags.BACKGROUND
const LAYER_FLAG_PREFER_LINKED_CEL := Layer.Flags.PREFER_LINKED_CELS
const LAYER_FLAG_GROUP_COLLAPSED := Layer.Flags.GROUP_COLLAPSED
const LAYER_FLAG_REFERENCE_LAYER := Layer.Flags.REFERENCE_LAYER

const LAYER_BLEND_NORMAL := Layer.BlendMode.NORMAL
const LAYER_BLEND_MULTIPLY := Layer.BlendMode.MULTIPLY
const LAYER_BLEND_SCREEN := Layer.BlendMode.SCREEN
const LAYER_BLEND_OVERLAY := Layer.BlendMode.OVERLAY
const LAYER_BLEND_DARKEN := Layer.BlendMode.DARKEN
const LAYER_BLEND_LIGHTEN := Layer.BlendMode.LIGHTEN
const LAYER_BLEND_COLOR_DODGE := Layer.BlendMode.COLOR_DODGE
const LAYER_BLEND_COLOR_BURN := Layer.BlendMode.COLOR_BURN
const LAYER_BLEND_HARD_LIGHT := Layer.BlendMode.HARD_LIGHT
const LAYER_BLEND_SOFT_LIGHT := Layer.BlendMode.SOFT_LIGHT
const LAYER_BLEND_DIFFERENCE := Layer.BlendMode.DIFFERENCE
const LAYER_BLEND_EXCLUSION := Layer.BlendMode.EXCLUSION
const LAYER_BLEND_HUE := Layer.BlendMode.HUE
const LAYER_BLEND_SATURATION := Layer.BlendMode.SATURATION
const LAYER_BLEND_COLOR := Layer.BlendMode.COLOR
const LAYER_BLEND_LUMINOSITY := Layer.BlendMode.LUMINOSITY
const LAYER_BLEND_ADDITION := Layer.BlendMode.ADDITION
const LAYER_BLEND_SUBTRACT := Layer.BlendMode.SUBTRACT
const LAYER_BLEND_DIVIDE := Layer.BlendMode.DIVIDE

const CEL_TYPE_IMAGE := Cel.Type.IMAGE
const CEL_TYPE_LINKED := Cel.Type.LINKED_CEL
const CEL_TYPE_COMPRESSED_CEL := Cel.Type.COMPRESSED_CEL
const CEL_TYPE_COMPRESSED_TILEMAP := Cel.Type.COMPRESSED_TILEMAP

const CEL_EXTRA_FLAG_PRECISE_BOUNDS := CelExtra.Flags.PRECISE_BOUNDS

const COLOR_PROFILE_TYPE_NONE := ColorProfile.Type.NO_PROFILE
const COLOR_PROFILE_TYPE_SRGB := ColorProfile.Type.SRGB
const COLOR_PROFILE_TYPE_ICC := ColorProfile.Type.EMBEDDED_ICC

const COLOR_PROFILE_FLAG_FIXED_GAMMA := ColorProfile.Flags.USE_FIXED_GAMMA

const OPEN_FLAG_SKIP_BUFFER: int = 1 << 0

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

## Frames in the sprite.
var frames: Array[Frame] = []

## Layers in the sprite.
var layers: Array[Layer] = []

## A tileset is a collection of individual tiles, arranged in a grid.
var tilesets: Array[Tileset] = []

## The palette used in the sprite.
var palette: Palette = Palette.new()

## The color profile used in the sprite.
var color_profile: ColorProfile = ColorProfile.new()

# func get_frames() -> Array[Frame]:
# 	return self.frames.duplicate()

# func get_chunks() -> Array[Chunk]:
# 	var items: Array[Chunk] = []

# 	for frame in self.frames:
# 		items.append_array(frame.chunks)

# 	return items

# func get_layers() -> Array[Layer]:
# 	var items: Array[Layer] = []

# 	for frame in self.frames:
# 		for chunk in frame.chunks:
# 			if chunk is AsepriteFile.Layer:
# 				items.append(chunk)

# 	return items

# func get_tilesets() -> Array[Tileset]:
# 	var items: Array[Tileset] = []

# 	for frame in self.frames:
# 		for chunk in frame.chunks:
# 			if chunk is AsepriteFile.Tileset:
# 				items.append(chunk)

# 	return items

# func get_palette() -> Palette:
# 	for frame in self.frames:
# 		for chunk in frame.chunks:
# 			if chunk is AsepriteFile.Palette:
# 				return chunk

# 	return Palette.new()

# func get_color_profile() -> ColorProfile:
# 	for frame in self.frames:
# 		for chunk in frame.chunks:
# 			if chunk is AsepriteFile.ColorProfile:
# 				return chunk

# 	return ColorProfile.new()

var _reader: AsepriteFileReader = null

## Opens the Aseprite file for reading.
## Once a file is opened, it cannot be opened again, you need to create a new instance of this class.
func open(path: String, flags: int = 0) -> int:
	# Do not allow to re-open the file
	if _reader: return ERR_ALREADY_IN_USE

	# Reset the state, in the future maybe we can reuse this instance
	self.file_size = -1
	self.palette = Palette.new()
	self.frames = []
	self.layers = []

	var fs := FileAccess.open(path, FileAccess.READ)
	if not fs: return FileAccess.get_open_error()

	# The file is too short to be a valid Aseprite file
	if fs.get_length() < 128: return ERR_FILE_EOF

	self._reader = AsepriteFileReader.new()
	self._reader.open(fs)

	# region Read the header

	self.file_size = _reader.get_dword()

	# Check the magic number
	if _reader.get_word() != 0xA5E0: return ERR_FILE_CORRUPT

	self.num_frames = _reader.get_word()
	self.width = _reader.get_word()
	self.height = _reader.get_word()
	self.color_depth = _reader.get_word()
	self.flags = _reader.get_dword()
	self.speed = _reader.get_word()

	# # Two consecutive DWORDs must be zero
	# if _reader.get_dword() != 0: return ERR_FILE_CORRUPT
	# if _reader.get_dword() != 0: return ERR_FILE_CORRUPT
	_reader.skip(8) # Skip 2*4 bytes

	self.palette_entry = _reader.get_byte()
	_reader.skip(3) # Skip 3 bytes
	self.num_colors = _reader.get_word()
	self.pixel_width = _reader.get_byte()
	self.pixel_height = _reader.get_byte()
	self.grid_x = _reader.get_word()
	self.grid_y = _reader.get_word()
	self.grid_width = _reader.get_word()
	self.grid_height = _reader.get_word()
	_reader.skip(84)

	# endregion

	# Sanity check for header size
	if fs.get_position() != 128: return ERR_FILE_EOF

	# Read the frames
	for _frame_index in range(self.num_frames):
		var frame := Frame.new()
		self.frames.append(frame)

		# region Read the frame header

		frame.frame_size = _reader.get_dword()

		# Aseprite - Invalid frame magic number
		if _reader.get_word() != 0xF1FA: return ERR_FILE_CORRUPT

		frame.chunks_num_old = _reader.get_word()
		frame.duration = _reader.get_word()
		_reader.skip(2) # For future (set to zero)
		frame.chunks_num_new = _reader.get_dword()

		# endregion

		# Per spec, use old chunks count if new chunks count is zero
		var chunks_num := frame.chunks_num_old if frame.chunks_num_new == 0 else frame.chunks_num_new

		# Read each chunk in the frame
		for chunk_index in range(chunks_num):
			# Read the chunk header
			var current_chunk_size := _reader.get_dword()
			var current_chunk_type := _reader.get_word()

			match current_chunk_type:
				# Layer Chunk
				0x2004:
					var layer := Layer.new()

					frame.chunks.append(layer)
					self.layers.append(layer)

					layer.chunk_size = current_chunk_size
					layer.chunk_type = current_chunk_type


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

					layer.flags = _reader.get_word()
					layer.type = _reader.get_word()
					layer.child_level = _reader.get_word()
					layer.default_width = _reader.get_word()
					layer.default_height = _reader.get_word()
					layer.blend_mode = _reader.get_word()
					layer.opacity = _reader.get_byte()
					_reader.skip(3) # Skip 3 bytes for future use
					layer.name = _reader.get_string()
					if layer.type == 2: layer.tileset_index = _reader.get_dword()
					if layer.flags & 4: layer.uuid = _reader.get_uuid()

				# Cel Chunk
				0x2005:
					var cel := Cel.new()

					frame.chunks.append(cel)
					frame.cels.append(cel)

					cel.chunk_size = current_chunk_size
					cel.chunk_type = current_chunk_type

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

					cel.layer_index = _reader.get_word()
					cel.x = _reader.get_word()
					cel.y = _reader.get_word()
					cel.opacity = _reader.get_byte()
					cel.type = _reader.get_word()
					cel.z_index = _reader.get_word()
					_reader.skip(5) # Skip 5 bytes for future use

					if cel.type == 0:
						cel.w = _reader.get_word()
						cel.h = _reader.get_word()

						if flags & OPEN_FLAG_SKIP_BUFFER == 0:
							# 26 is the number of bytes in the header we have just read
							cel.buffer = _reader.get_buffer(current_chunk_size - 26)

							# Aseprite - Cel buffer size mismatch
							if cel.buffer.size() != cel.w * cel.h * (self.color_depth / 8):
								return ERR_FILE_CORRUPT
						else:
							_reader.skip(current_chunk_size - 26)

					elif cel.type == 1:
						cel.link = _reader.get_word()

					elif cel.type == 2:
						cel.w = _reader.get_word()
						cel.h = _reader.get_word()

						if flags & OPEN_FLAG_SKIP_BUFFER == 0:
							# 26 is the number of bytes in the header we have just read
							cel.buffer = _reader.get_buffer(current_chunk_size - 26)

							# ZLIB compressed buffer
							cel.buffer = cel.buffer.decompress(cel.w * cel.h * (self.color_depth / 8), FileAccess.CompressionMode.COMPRESSION_DEFLATE)

							# Cel buffer size mismatch
							if cel.buffer.size() != cel.w * cel.h * (self.color_depth / 8):
								return ERR_FILE_CORRUPT
						else:
							_reader.skip(current_chunk_size - 26)

					elif cel.type == 3:
						cel.w = _reader.get_word()
						cel.h = _reader.get_word()
						cel.bits_per_tile = _reader.get_word()
						cel.bitmask_for_tile_id = _reader.get_dword()
						cel.bitmask_for_x_flip = _reader.get_dword()
						cel.bitmask_for_y_flip = _reader.get_dword()
						cel.bitmask_for_90cw_rotation = _reader.get_dword()
						_reader.skip(10) # Skip 10 bytes for reserved

						if flags & OPEN_FLAG_SKIP_BUFFER == 0:
							# 54 is the number of bytes in the header we have just read
							cel.buffer = _reader.get_buffer(current_chunk_size - 54)

							# ZLIB compressed buffer
							cel.buffer = cel.buffer.decompress(cel.w * cel.h * (cel.bits_per_tile / 8), FileAccess.CompressionMode.COMPRESSION_DEFLATE)

							# Cel buffer size mismatch
							if cel.buffer.size() != cel.w * cel.h * (cel.bits_per_tile / 8):
								return ERR_FILE_CORRUPT
						else:
							_reader.skip(current_chunk_size - 54)

				# Cel Extra Chunk (0x2006)
				0x2006:
					var cel_extra := CelExtra.new()

					frame.chunks.append(cel_extra)

					cel_extra.chunk_size = current_chunk_size
					cel_extra.chunk_type = current_chunk_type

					# Adds extra information to the latest read cel.

					#     DWORD       Flags (set to zero)
					#                   1 = Precise bounds are set
					#     FIXED       Precise X position
					#     FIXED       Precise Y position
					#     FIXED       Width of the cel in the sprite (scaled in real-time)
					#     FIXED       Height of the cel in the sprite
					#     BYTE[16]    For future use (set to zero)

					cel_extra.flags = _reader.get_word()
					cel_extra.precise_x = _reader.get_fixed()
					cel_extra.precise_y = _reader.get_fixed()
					cel_extra.width = _reader.get_fixed()
					cel_extra.height = _reader.get_fixed()
					_reader.skip(16) # Skip 16 bytes for future use

					frame.cels[frame.cels.size() - 1].extra = cel_extra

				# Color Profile Chunk
				0x2007:
					self.color_profile = ColorProfile.new()

					frame.chunks.append(self.color_profile)

					self.color_profile.chunk_size = current_chunk_size
					self.color_profile.chunk_type = current_chunk_type

					#   Color profile for RGB or grayscale values.

					# WORD        Type
					#               0 - no color profile (as in old .aseprite files)
					#               1 - use sRGB
					#               2 - use the embedded ICC profile
					# WORD        Flags
					#               1 - use special fixed gamma
					# FIXED       Fixed gamma (1.0 = linear)
					#             Note: The gamma in sRGB is 2.2 in overall but it doesn't use
					#             this fixed gamma, because sRGB uses different gamma sections
					#             (linear and non-linear). If sRGB is specified with a fixed
					#             gamma = 1.0, it means that this is Linear sRGB.
					# BYTE[8]     Reserved (set to zero)
					# + If type = ICC:
					#   DWORD     ICC profile data length
					#   BYTE[]    ICC profile data. More info: http://www.color.org/ICC1V42.pdf

					self.color_profile.type = _reader.get_word()
					self.color_profile.flags = _reader.get_word()
					self.color_profile.fixed_gamma = _reader.get_fixed()
					_reader.skip(8)

					if self.color_profile.type == 2:
						var icc_data_len := _reader.get_dword()

						if flags & OPEN_FLAG_SKIP_BUFFER == 0:
							self.color_profile.icc_data = _reader.get_buffer(icc_data_len)
						else:
							_reader.skip(icc_data_len)

				# Palette Chunk
				0x2019:
					self.palette = Palette.new()

					frame.chunks.append(self.palette)

					self.palette.chunk_size = current_chunk_size
					self.palette.chunk_type = current_chunk_type

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

					self.palette.palette_size = _reader.get_dword()
					self.palette.first_color = _reader.get_dword()
					self.palette.last_color = _reader.get_dword()
					_reader.skip(8) # Skip 8 bytes for future use

					# Read the palette colors

					for _palette_index in range(self.palette.palette_size):
						var palette_color := PaletteColor.new()

						self.palette.colors.append(palette_color)

						palette_color.flags = _reader.get_word()
						palette_color.red = _reader.get_byte()
						palette_color.green = _reader.get_byte()
						palette_color.blue = _reader.get_byte()
						palette_color.alpha = _reader.get_byte()

						if palette_color.flags & PALETTE_COLOR_FLAG_HAS_NAME:
							palette_color.name = _reader.get_string()

					assert(self.palette.palette_size == self.palette.colors.size(), "Aseprite - Palette size mismatch: expected %d, got %d" % [self.palette.palette_size, self.palette.colors.size()])

				# Tileset Chunk
				0x2023:
					var tileset := Tileset.new()

					frame.chunks.append(tileset)
					self.tilesets.append(tileset)

					tileset.chunk_size = current_chunk_size
					tileset.chunk_type = current_chunk_type

					tileset.id = _reader.get_dword()
					tileset.flags = _reader.get_dword()
					tileset.tiles_count = _reader.get_dword()
					tileset.tile_width = _reader.get_word()
					tileset.tile_height = _reader.get_word()
					tileset.base_index = _reader.get_word()
					_reader.skip(14)
					tileset.name = _reader.get_string()

					if tileset.flags & 1 != 0:
						tileset.external_file_id = _reader.get_word()
						tileset.external_id = _reader.get_word()

					if tileset.flags & 2 != 0:
						var data_len := _reader.get_dword()

						if flags & OPEN_FLAG_SKIP_BUFFER == 0:
							tileset.buffer = _reader.get_buffer(data_len)

							# ZLIB compressed buffer
							tileset.buffer = tileset.buffer.decompress(tileset.tile_width * tileset.tile_height * (self.color_depth / 8) * tileset.tiles_count, FileAccess.CompressionMode.COMPRESSION_DEFLATE)

							# Cel buffer size mismatch
							if tileset.buffer.size() != tileset.tile_width * tileset.tile_height * (self.color_depth / 8) * tileset.tiles_count:
								return ERR_FILE_CORRUPT
						else:
							_reader.skip(data_len)

				_:
					# Ignore unsupported chunk types
					_reader.skip(current_chunk_size - 6)

					var unknown_chunk := UnknownChunk.new()

					frame.chunks.append(unknown_chunk)

					unknown_chunk.chunk_size = current_chunk_size
					unknown_chunk.chunk_type = current_chunk_type

	# Sanity check, make sure we have read the entire file
	if fs.get_position() != self.file_size:
		return ERR_FILE_EOF

	return OK

## Closes the currently opened file and prevents subsequent read.
func close() -> void:
	if _reader: _reader.close()

## Determines if the layer frame is empty.
## A layer frame is considered empty if it has no cel for that specified frame.
##
## Note: This method does not check for layer opacity, visibility, nor does it check for the size of the cel, nor if the cel is fully transparent.
## It only counts the number of cels in the frame which belong to the layer.
func is_layer_frame_empty(layer_index: int, frame_index: int) -> bool:
	return not self.frames[frame_index].cels.any(func(cel: AsepriteFile.Cel):
		return cel.layer_index == layer_index
	)

## Extract the image for the specified layer and frame.
##
## Note: The image format is RGBA8 regardless of the original color depth.
func get_layer_frame_image(layer_index: int, frame_index: int) -> Image:
	var cels: Array[Cel] = self.frames[frame_index].cels.filter(func(cel: AsepriteFile.Cel):
		return cel.layer_index == layer_index
	)

	# `sort_custom` sorts in place, we have used `filter` above which returns a new array so it's fine
	cels.sort_custom(func(a: AsepriteFile.Cel, b: AsepriteFile.Cel):
		var orderA := a.layer_index + a.z_index
		var orderB := b.layer_index + b.z_index
		return orderA - orderB || a.z_index - b.z_index
	)

	# Just print an empty image if there are no cels
	# Use is_layer_frame_empty to check if the layer frame is empty
	# if cels.size() == 0: return null

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

			var img := get_tile_image(layer.tileset_index, tile_id)

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

func get_tile_image(tileset_index: int, tile_id: int) -> Image:
	# Let Godot to throw "index out of bounds" error if any of the indexes are invalid
	var tileset := self.tilesets[tileset_index]

	# Compressed Tileset image (see NOTE.3): (Tile Width) x (Tile Height x Number of Tiles)
	var stride := tileset.tile_width * tileset.tile_height * (self.color_depth / 8)

	var buffer_pos := tile_id * stride
	var buf := tileset.buffer.slice(buffer_pos, buffer_pos + stride)


	# Godot expands 8-bit indexed images to 32-bit RGBA8
	if self.color_depth == 8:
		var rgba8_buf := PackedByteArray()
		rgba8_buf.resize(tileset.tile_width * tileset.tile_height * 4)

		for i in range(buf.size()):
			var color_index := buf[i]

			# TODO: handle palette index out of bounds
			var color := self.palette.colors[color_index]

			rgba8_buf[i * 4 + 0] = color.red
			rgba8_buf[i * 4 + 1] = color.green
			rgba8_buf[i * 4 + 2] = color.blue
			rgba8_buf[i * 4 + 3] = color.alpha

		return Image.create_from_data(
			tileset.tile_width,
			tileset.tile_height,
			false,
			Image.FORMAT_RGBA8,
			rgba8_buf,
		)

	if self.color_depth == 16:
		var img := Image.create_from_data(
			tileset.tile_width,
			tileset.tile_height,
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

## Represent a single frame.
class Frame extends RefCounted:
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

	func get_chunks_count() -> int:
		# Per spec, use old chunks count if new chunks count is zero
		return chunks_num_old if chunks_num_new == 0 else chunks_num_new

	# func get_cels() -> Array[Cel]:
	# 	return chunks.filter(func(c: Chunk): c is Cel)

## Base class for all chunks.
class Chunk extends RefCounted:
	enum ChunkType {
		OLD_PALETTE_1 = 0x0004, # DEPRECATED
		OLD_PALETTE_2 = 0x0011, # DEPRECATED
		LAYER = 0x2004,
		CEL = 0x2005,
		CEL_EXTRA = 0x2006,
		COLOR_PROFILE = 0x2007,
		EXTERNAL_FILES = 0x2008,
		MASK = 0x2016, # DEPRECATED
		PATH = 0x2017,
		TAGS = 0x2018,
		PALETTE = 0x2019,
		USER_DATA = 0x2020,
		SLICE = 0x2022,
		TILESET = 0x2023,
	}

	var chunk_size: int = 0

	## Chunk type
	var chunk_type: ChunkType = 0

## 0x2019
class Palette extends Chunk:
	var palette_size: int = 0
	var first_color: int = 0
	var last_color: int = 0

	## Palette colors
	var colors: Array[PaletteColor] = []

	func get_first_color() -> PaletteColor:
		return self.colors[self.first_color] if self.colors.size() > self.first_color else null

	func get_last_color() -> PaletteColor:
		return self.colors[self.last_color] if self.colors.size() > self.last_color else null

class PaletteColor extends RefCounted:
	enum Flags {
		## 1 = Has Name
		HAS_NAME = 1 << 0
	}

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

	func has_name() -> bool:
		return (self.flags & Flags.HAS_NAME) != 0

	## Convert to Godot Color
	func to_color() -> Color:
		return Color(
			float(self.red) / 255.0,
			float(self.green) / 255.0,
			float(self.blue) / 255.0,
			float(self.alpha) / 255.0,
		)

## 0x2004
class Layer extends Chunk:
	enum Type {
		NORMAL = 0,
		GROUP = 1,
		TILEMAP = 2,
	}

	enum Flags {
		VISIBLE = 1 << 0,
		EDITABLE = 1 << 1,
		LOCK_MOVEMENT = 1 << 2,
		BACKGROUND = 1 << 3,
		## The layer prefers linked cels over linked frames
		PREFER_LINKED_CELS = 1 << 4,
		## The layer group should be displayed collapsed
		GROUP_COLLAPSED = 1 << 5,
		## The layer is a reference layer
		REFERENCE_LAYER = 1 << 6,
	}

	enum BlendMode {
		NORMAL = 0,
		MULTIPLY = 1,
		SCREEN = 2,
		OVERLAY = 3,
		DARKEN = 4,
		LIGHTEN = 5,
		COLOR_DODGE = 6,
		COLOR_BURN = 7,
		HARD_LIGHT = 8,
		SOFT_LIGHT = 9,
		DIFFERENCE = 10,
		EXCLUSION = 11,
		HUE = 12,
		SATURATION = 13,
		COLOR = 14,
		LUMINOSITY = 15,
		ADDITION = 16,
		SUBTRACT = 17,
		DIVIDE = 18,
	}

	## Layer flags
	var flags: Flags

	## Layer type
	var type: Type

	## Layer child level
	var child_level: int

	## Default layer width in pixels (ignored)
	var default_width: int

	## Default layer height in pixels (ignored)
	var default_height: int

	## Blend mode
	var blend_mode: BlendMode

	var opacity: int

	## Layer name
	var name: String = ""

	var tileset_index: int = -1
	var uuid: String = ""

	func is_visible() -> bool:
		return (self.flags & 1) != 0

	func is_hidden() -> bool:
		return not self.is_visible()

	func is_group() -> bool:
		return self.type == 1

## 0x2005
class Cel extends Chunk:
	enum Type {
		IMAGE = 0,
		LINKED_CEL = 1,
		COMPRESSED_CEL = 2,
		COMPRESSED_TILEMAP = 3,
	}

	## Layer index
	var layer_index: int

	## X coordinate of the cell
	var x: int

	## Y coordinate of the cell
	var y: int

	## Opacity of the cell
	var opacity: int

	## Cell type
	var type: Cel.Type

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

	var extra: CelExtra = null

## 0x2006
class CelExtra extends Chunk:
	enum Flags {
		## Precise bounds are set
		PRECISE_BOUNDS = 1 << 0
	}

	var flags: int = 0
	var precise_x: float = 0.0
	var precise_y: float = 0.0
	var width: float = 0.0
	var height: float = 0.0

	func has_precise_bounds() -> bool:
		return (self.flags & Flags.PRECISE_BOUNDS) != 0

## 0x2007
class ColorProfile extends Chunk:
	enum Type {
		## no color profile (as in old .aseprite files)
		NO_PROFILE = 0,
		## use sRGB
		SRGB = 1,
		## use the embedded ICC profile
		EMBEDDED_ICC = 2,
	}

	enum Flags {
		## use special fixed gamma
		USE_FIXED_GAMMA = 1
	}

	## Color profile type
	var type: int = 0

	## Flags
	var flags: int = 0

	## Fixed gamma (1.0 = linear)
	## Note: The gamma in sRGB is 2.2 in overall but it doesn't use
	## this fixed gamma, because sRGB uses different gamma sections
	## (linear and non-linear). If sRGB is specified with a fixed
	## gamma = 1.0, it means that this is Linear sRGB.
	var fixed_gamma: float = 0.0

	## ICC Color profile data, only if type == EMBEDDED_ICC
	var icc_data: PackedByteArray = []

	func has_fixed_gamma() -> bool:
		return (self.flags & Flags.USE_FIXED_GAMMA) != 0

## 0x2023
class Tileset extends Chunk:
	enum Flags {
		## Include link to external file
		INCLUDE_LINK_TO_EXTERNAL_FILE = 1 << 0,

		## Include tiles inside this file
		INCLUDE_TILES_INSIDE_FILE = 1 << 1,

		## Tilemaps using this tileset use tile ID=0 as empty tile
		## (this is the new format). In rare cases this bit is off,
		## and the empty tile will be equal to 0xffffffff (used in
		## internal versions of Aseprite)
		TILEMAPS_USE_ID0_AS_EMPTY_TILE = 1 << 2,

		## Aseprite will try to match modified tiles with their X
		## flipped version automatically in Auto mode when using
		## this tileset.
		AUTO_X_FLIP = 1 << 3,

		## Same for Y flips
		AUTO_Y_FLIP = 1 << 4,

		## Same for D(iagonal) flips
		AUTO_DIAGONAL_FLIP = 1 << 5,
	}

	var id: int = 0
	var flags: Flags = 0
	var tiles_count: int = 0
	var tile_width: int = 0
	var tile_height: int = 0
	var base_index: int = 0
	var name: String = ""
	var external_file_id: int = -1
	var external_id: int = -1
	var buffer: PackedByteArray = []

class UnknownChunk extends Chunk:
	pass

# FileAccess does not extend StreamPeer...
# Additionally, get_xxx() do not return an error if the stream is empty
# we are supposed to check get_available_bytes() first
# however i am unusre if get_available_bytes() == 0 means we cant read no more
class AsepriteFileReader extends RefCounted:
	var _stream: Variant = null

	func open(data: Variant):
		if data is FileAccess:
			data.big_endian = false
			self._stream = data

		elif data is PackedByteArray:
			var buffer := StreamPeerBuffer.new()
			buffer.data_array = data
			buffer.big_endian = false
			self._stream = buffer

		elif data is StreamPeer:
			data.big_endian = false
			self._stream = data

	func close() -> void:
		if _stream is FileAccess: _stream.close()
		_stream = null

	func get_available_bytes() -> int:
		if _stream is FileAccess: return _stream.get_length() - _stream.get_position()
		if _stream is StreamPeer: return _stream.get_available_bytes()
		return 0

	# Skip `bytes`, return the amount of bytes skipped.
	# If the stream is at the end, it will return 0.
	func skip(bytes: int) -> int:
		# Sanity check, just ignore zero and negative values
		if bytes <= 0: return 0

		if _stream is FileAccess:
			var len: int = _stream.get_length()
			var pos: int = _stream.get_position()

			# We cant read past the end of the stream
			if pos + bytes > len:
				bytes = len - pos
				if bytes <= 0: return 0

			_stream.seek(pos + bytes)
			return bytes

		elif _stream is StreamPeerBuffer:
			var len: int = _stream.data_array.size()
			var pos: int = _stream.get_position()

			# We cant read past the end of the stream
			if pos + bytes > len:
				bytes = len - pos
				if bytes <= 0: return 0

			_stream.seek(pos + bytes)
			return bytes

		# StreamPeer might read from the network, we cant just move forward
		elif _stream is StreamPeer:
			var index := 0

			# I miss the regular old-school for loops...
			for _i in range(bytes):
				# If get_available_bytes is 0, we are at the end of the stream
				# I suspect some future StreamPeer might return 0 even tho there are bytes available
				if _stream.get_available_bytes() == 0:
					return index

				_stream.get_8()
				index += 1

			return index

		return 0

	## An 8-bit unsigned integer value
	func get_byte() -> int:
		if _stream is FileAccess: return _stream.get_8()
		if _stream is StreamPeer: return _stream.get_8()
		return -1

	## A 16-bit unsigned integer value
	func get_word() -> int:
		if _stream is FileAccess: return _stream.get_16()
		if _stream is StreamPeer: return _stream.get_16()
		return -1

	## A 32-bit unsigned integer value
	func get_dword() -> int:
		if _stream is FileAccess: return _stream.get_32()
		if _stream is StreamPeer: return _stream.get_32()
		return -1

	## A 16-bit signed integer value
	func get_short() -> int:
		if _stream is FileAccess: return _stream.get_16()
		if _stream is StreamPeer: return _stream.get_16()
		return -1

	## A 32-bit signed integer value
	func get_long() -> int:
		if _stream is FileAccess: return _stream.get_32()
		if _stream is StreamPeer: return _stream.get_32()
		return -1

	## A 32-bit fixed point (16.16) value
	func get_fixed() -> float:
		if _stream is FileAccess: return _stream.get_32() << 16
		if _stream is StreamPeer: return _stream.get_32() << 16
		return 0.0

	## A 32-bit single-precision value
	func get_float() -> float:
		if _stream is FileAccess: return _stream.get_float()
		if _stream is StreamPeer: return _stream.get_float()
		return 0.0

	## A 64-bit double-precision value
	func get_double() -> float:
		if _stream is FileAccess: return _stream.get_double()
		if _stream is StreamPeer: return _stream.get_double()
		return 0.0

	## A 64-bit unsigned integer value
	func get_qword() -> int:
		if _stream is FileAccess: return _stream.get_64()
		if _stream is StreamPeer: return _stream.get_64()
		return -1

	## A 64-bit signed integer value
	func get_long64() -> int:
		if _stream is FileAccess: return _stream.get_64()
		if _stream is StreamPeer: return _stream.get_64()
		return -1

	func get_string() -> String:
		return self.get_buffer(self.get_word()).get_string_from_utf8()

	func get_buffer(length: int) -> PackedByteArray:
		if _stream is FileAccess: return _stream.get_buffer(length)
		# TODO: [0] is error, [1] is data, return the error also
		if _stream is StreamPeer: return _stream.get_data(length)[1]
		return PackedByteArray()

	func get_point() -> Vector2:
		return Vector2(self.get_long(), self.get_long())

	func get_size() -> Vector2:
		return Vector2(self.get_long(), self.get_long())

	func get_rect() -> Rect2:
		return Rect2(
			self.get_long(),
			self.get_long(),
			self.get_long(),
			self.get_long()
		)

	func get_pixel(color_depth: int) -> Color:
		if color_depth == 8:
			var r := self.get_byte()
			return Color(r, 0, 0, 255)

		if color_depth == 16:
			var v := self.get_byte()
			var a := self.get_byte()
			return Color(v, v, v, a)

		if color_depth == 32:
			var r := self.get_byte()
			var g := self.get_byte()
			var b := self.get_byte()
			var a := self.get_byte()
			return Color(r, g, b, a)

		return Color(0, 0, 0, 0)

	func get_uuid() -> String:
		var buf := self.get_buffer(16)

		if buf.size() != 16:
			return ""

		var hex := ""
		for i in range(buf.size()):
			hex += "%02x" % buf[i]

		return hex

	func read_header():
		## Header
		# A 128-byte header (same as FLC/FLI header, but with other magic number):
		#     DWORD       File size
		#     WORD        Magic number (0xA5E0)
		#     WORD        Frames
		#     WORD        Width in pixels
		#     WORD        Height in pixels
		#     WORD        Color depth (bits per pixel)
		#                   32 bpp = RGBA
		#                   16 bpp = Grayscale
		#                   8 bpp = Indexed
		#     DWORD       Flags (see NOTE.6):
		#                   1 = Layer opacity has valid value
		#                   2 = Layer blend mode/opacity is valid for groups
		#                       (composite groups separately first when rendering)
		#                   4 = Layers have an UUID
		#     WORD        Speed (milliseconds between frame, like in FLC files)
		#                 DEPRECATED: You should use the frame duration field
		#                 from each frame header
		#     DWORD       Set be 0
		#     DWORD       Set be 0
		#     BYTE        Palette entry (index) which represent transparent color
		#                 in all non-background layers (only for Indexed sprites).
		#     BYTE[3]     Ignore these bytes
		#     WORD        Number of colors (0 means 256 for old sprites)
		#     BYTE        Pixel width (pixel ratio is "pixel width/pixel height").
		#                 If this or pixel height field is zero, pixel ratio is 1:1
		#     BYTE        Pixel height
		#     SHORT       X position of the grid
		#     SHORT       Y position of the grid
		#     WORD        Grid width (zero if there is no grid, grid size
		#                 is 16x16 on Aseprite by default)
		#     WORD        Grid height (zero if there is no grid)
		#     BYTE[84]    For future (set to zero)
		var file_size := self.get_dword()

		# Invalid magic number
		if self.get_word() != 0xA5E0: return ERR_FILE_CORRUPT

		var num_frames := self.get_word()
		var width := self.get_word()
		var height := self.get_word()
		var color_depth := self.get_word()
		var flags := self.get_dword()
		var speed := self.get_word()

		# Two consecutive DWORDs must be zero
		if self.get_dword() != 0: return ERR_FILE_CORRUPT
		if self.get_dword() != 0: return ERR_FILE_CORRUPT

		var palette_transparent_index := self.get_byte()
		self.skip(3)
		var num_colors := self.get_word()
		var pixel_width := self.get_byte()
		var pixel_height := self.get_byte()
		var grid_x := self.get_short()
		var grid_y := self.get_short()
		var grid_width := self.get_word()
		var grid_height := self.get_word()
		self.skip(84)

	func read_frame():
		# After the header come the "frames" data. Each frame has this little
		# header of 16 bytes:
		#     DWORD       Bytes in this frame
		#     WORD        Magic number (always 0xF1FA)
		#     WORD        Old field which specifies the number of "chunks"
		#                 in this frame. If this value is 0xFFFF, we might
		#                 have more chunks to read in this frame
		#                 (so we have to use the new field)
		#     WORD        Frame duration (in milliseconds)
		#     BYTE[2]     For future (set to zero)
		#     DWORD       New field which specifies the number of "chunks"
		#                 in this frame (if this is 0, use the old field)
		# Then each chunk format is:
		#     DWORD       Chunk size
		#     WORD        Chunk type
		#     BYTE[]      Chunk data
		# The chunk size includes the DWORD of the size itself, and the WORD of
		# the chunk type, so a chunk size must be equal or greater than 6 bytes
		# at least.
		var frame := Frame.new()

		frame.frame_size = self.get_dword()
		if self.get_word() != 0xF1FA: return null
		frame.chunks_num_old = self.get_word()
		frame.duration = self.get_word()
		self.skip(2) # For future (set to zero)
		frame.chunks_num_new = self.get_dword()

		return frame
