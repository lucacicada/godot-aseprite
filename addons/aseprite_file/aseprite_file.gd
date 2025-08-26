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

var tags: Array[Tag] = []

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

	var frames: Array[Frame] = []

	# Read the frames
	for _frame_index in range(self.num_frames):
		var frame := Frame.new()
		frames.append(frame)

		frame.frame_size = _reader.get_dword()

		# Aseprite - Invalid frame magic number
		if _reader.get_word() != 0xF1FA: return ERR_FILE_CORRUPT

		frame.chunks_num_old = _reader.get_word()
		frame.duration = _reader.get_word()
		_reader.skip(2) # For future (set to zero)
		frame.chunks_num_new = _reader.get_dword()

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
					var layer_chunk := Layer.new()

					frame.chunks.append(layer_chunk)

					layer_chunk.chunk_size = current_chunk_size
					layer_chunk.chunk_type = current_chunk_type

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

					layer_chunk.flags = _reader.get_word()
					layer_chunk.type = _reader.get_word()
					layer_chunk.child_level = _reader.get_word()
					layer_chunk.default_width = _reader.get_word()
					layer_chunk.default_height = _reader.get_word()
					layer_chunk.blend_mode = _reader.get_word()
					layer_chunk.opacity = _reader.get_byte()
					_reader.skip(3) # Skip 3 bytes for future use
					layer_chunk.name = _reader.get_string()
					if layer_chunk.type == 2: layer_chunk.tileset_index = _reader.get_dword()
					if layer_chunk.flags & 4: layer_chunk.uuid = _reader.get_uuid()

				# Cel Chunk
				0x2005:
					var cel_chunk := Cel.new()

					frame.chunks.append(cel_chunk)
					frame.cels.append(cel_chunk)

					cel_chunk.chunk_size = current_chunk_size
					cel_chunk.chunk_type = current_chunk_type

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

					cel_chunk.layer_index = _reader.get_word()
					cel_chunk.x = _reader.get_short()
					cel_chunk.y = _reader.get_short()
					cel_chunk.opacity = _reader.get_byte()
					cel_chunk.type = _reader.get_word()
					cel_chunk.z_index = _reader.get_short()
					_reader.skip(5) # Skip 5 bytes for future use

					if cel_chunk.type == 0:
						cel_chunk.w = _reader.get_word()
						cel_chunk.h = _reader.get_word()

						if flags & OPEN_FLAG_SKIP_BUFFER == 0:
							# 26 is the number of bytes in the header we have just read
							cel_chunk.buffer = _reader.get_buffer(current_chunk_size - 26)

							# Aseprite - Cel buffer size mismatch
							if cel_chunk.buffer.size() != cel_chunk.w * cel_chunk.h * (self.color_depth / 8):
								return ERR_FILE_CORRUPT
						else:
							_reader.skip(current_chunk_size - 26)

					elif cel_chunk.type == 1:
						cel_chunk.link = _reader.get_word()

					elif cel_chunk.type == 2:
						cel_chunk.w = _reader.get_word()
						cel_chunk.h = _reader.get_word()

						if flags & OPEN_FLAG_SKIP_BUFFER == 0:
							# 26 is the number of bytes in the header we have just read
							cel_chunk.buffer = _reader.get_buffer(current_chunk_size - 26)

							# ZLIB compressed buffer
							cel_chunk.buffer = cel_chunk.buffer.decompress(cel_chunk.w * cel_chunk.h * (self.color_depth / 8), FileAccess.CompressionMode.COMPRESSION_DEFLATE)
						else:
							_reader.skip(current_chunk_size - 26)

					elif cel_chunk.type == 3:
						cel_chunk.w = _reader.get_word()
						cel_chunk.h = _reader.get_word()
						cel_chunk.bits_per_tile = _reader.get_word()
						cel_chunk.bitmask_for_tile_id = _reader.get_dword()
						cel_chunk.bitmask_for_x_flip = _reader.get_dword()
						cel_chunk.bitmask_for_y_flip = _reader.get_dword()
						cel_chunk.bitmask_for_90cw_rotation = _reader.get_dword()
						_reader.skip(10) # Skip 10 bytes for reserved

						if flags & OPEN_FLAG_SKIP_BUFFER == 0:
							# 54 is the number of bytes in the header we have just read
							cel_chunk.buffer = _reader.get_buffer(current_chunk_size - 54)

							# ZLIB compressed buffer
							cel_chunk.buffer = cel_chunk.buffer.decompress(cel_chunk.w * cel_chunk.h * (cel_chunk.bits_per_tile / 8), FileAccess.CompressionMode.COMPRESSION_DEFLATE)
						else:
							_reader.skip(current_chunk_size - 54)

				# Cel Extra Chunk (0x2006)
				0x2006:
					var cel_extra_chunk := CelExtra.new()

					frame.chunks.append(cel_extra_chunk)

					cel_extra_chunk.chunk_size = current_chunk_size
					cel_extra_chunk.chunk_type = current_chunk_type

					# Adds extra information to the latest read cel.

					#     DWORD       Flags (set to zero)
					#                   1 = Precise bounds are set
					#     FIXED       Precise X position
					#     FIXED       Precise Y position
					#     FIXED       Width of the cel in the sprite (scaled in real-time)
					#     FIXED       Height of the cel in the sprite
					#     BYTE[16]    For future use (set to zero)

					cel_extra_chunk.flags = _reader.get_word()
					cel_extra_chunk.precise_x = _reader.get_fixed()
					cel_extra_chunk.precise_y = _reader.get_fixed()
					cel_extra_chunk.width = _reader.get_fixed()
					cel_extra_chunk.height = _reader.get_fixed()
					_reader.skip(16) # Skip 16 bytes for future use

					frame.cels[frame.cels.size() - 1].extra = cel_extra_chunk

				# Color Profile Chunk
				0x2007:
					var color_profile_chunk := ColorProfile.new()

					self.color_profile = color_profile_chunk
					frame.chunks.append(color_profile_chunk)

					color_profile_chunk.chunk_size = current_chunk_size
					color_profile_chunk.chunk_type = current_chunk_type

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

					color_profile_chunk.type = _reader.get_word()
					color_profile_chunk.flags = _reader.get_word()
					color_profile_chunk.fixed_gamma = _reader.get_fixed()
					_reader.skip(8)

					if color_profile_chunk.type == 2:
						var icc_data_len := _reader.get_dword()

						if flags & OPEN_FLAG_SKIP_BUFFER == 0:
							color_profile_chunk.icc_data = _reader.get_buffer(icc_data_len)
						else:
							_reader.skip(icc_data_len)

				# External Files Chunk
				0x2008:
					var external_files_chunk := ExternalFiles.new()

					frame.chunks.append(external_files_chunk)

					external_files_chunk.chunk_size = current_chunk_size
					external_files_chunk.chunk_type = current_chunk_type

					# DWORD       Number of entries
					# BYTE[8]     Reserved (set to zero)
					# + For each entry
					#   DWORD     Entry ID (this ID is referenced by tilesets, palettes, or extended properties)
					#   BYTE      Type
					#               0 - External palette
					#               1 - External tileset
					#               2 - Extension name for properties
					#               3 - Extension name for tile management (can exist one per sprite)
					#   BYTE[7]   Reserved (set to zero)
					#   STRING    External file name or extension ID (see NOTE.4)

					external_files_chunk.files_count = _reader.get_dword()
					_reader.skip(8) # Skip 8 bytes for future use

					for _file_index in range(external_files_chunk.files_count):
						var external_file := ExternalFile.new()

						external_files_chunk.files.append(external_file)

						external_file.id = _reader.get_dword()
						external_file.type = _reader.get_byte()
						_reader.skip(7) # Skip 7 bytes for future use
						external_file.name = _reader.get_string()

				# Tags Chunk
				0x2018:
					var tags_chunk := Tags.new()

					self.tags.append(tags_chunk)
					frame.chunks.append(tags_chunk)

					tags_chunk.chunk_size = current_chunk_size
					tags_chunk.chunk_type = current_chunk_type

					# WORD        Number of tags
					# BYTE[8]     For future (set to zero)
					# + For each tag
					#   WORD      From frame
					#   WORD      To frame
					#   BYTE      Loop animation direction
					#               0 = Forward
					#               1 = Reverse
					#               2 = Ping-pong
					#               3 = Ping-pong Reverse
					#   WORD      Repeat N times. Play this animation section N times:
					#               0 = Doesn't specify (plays infinite in UI, once on export,
					#                   for ping-pong it plays once in each direction)
					#               1 = Plays once (for ping-pong, it plays just in one direction)
					#               2 = Plays twice (for ping-pong, it plays once in one direction,
					#                   and once in reverse)
					#               n = Plays N times
					#   BYTE[6]   For future (set to zero)
					#   BYTE[3]   RGB values of the tag color
					#               Deprecated, used only for backward compatibility with Aseprite v1.2.x
					#               The color of the tag is the one in the user data field following
					#               the tags chunk
					#   BYTE      Extra byte (zero)
					#   STRING    Tag name

					tags_chunk.tags_count = _reader.get_word()
					_reader.skip(8) # Skip 8 bytes for future use

					for _tag_index in range(tags_chunk.tags_count):
						var tag := Tag.new()

						tags_chunk.tags.append(tag)

						tag.from_frame = _reader.get_word()
						tag.to_frame = _reader.get_word()
						tag.loop_direction = _reader.get_byte()
						tag.repeat = _reader.get_word()
						_reader.skip(6) # Skip 6 bytes for future use
						tag.color_r = _reader.get_byte()
						tag.color_g = _reader.get_byte()
						tag.color_b = _reader.get_byte()
						_reader.skip(1) # Skip 1 byte for future use
						tag.name = _reader.get_string()

				# Palette Chunk
				0x2019:
					var palette_chunk = Palette.new()

					self.palette = palette_chunk
					frame.chunks.append(palette_chunk)

					palette_chunk.chunk_size = current_chunk_size
					palette_chunk.chunk_type = current_chunk_type

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

					palette_chunk.colors_count = _reader.get_dword()
					palette_chunk.first_color = _reader.get_dword()
					palette_chunk.last_color = _reader.get_dword()
					_reader.skip(8) # Skip 8 bytes for future use

					# Read the palette colors

					for _palette_index in range(palette_chunk.colors_count):
						var palette_color := PaletteColor.new()

						palette_chunk.colors.append(palette_color)

						palette_color.flags = _reader.get_word()
						palette_color.red = _reader.get_byte()
						palette_color.green = _reader.get_byte()
						palette_color.blue = _reader.get_byte()
						palette_color.alpha = _reader.get_byte()

						if palette_color.flags & PALETTE_COLOR_FLAG_HAS_NAME:
							palette_color.name = _reader.get_string()

				# Slice Chunk
				0x2022:
					var slice_chunk := Slice.new()

					frame.chunks.append(slice_chunk)

					slice_chunk.chunk_size = current_chunk_size
					slice_chunk.chunk_type = current_chunk_type

					# DWORD       Number of "slice keys"
					# DWORD       Flags
					#               1 = It's a 9-patches slice
					#               2 = Has pivot information
					# DWORD       Reserved
					# STRING      Name
					# + For each slice key
					#   DWORD     Frame number (this slice is valid from
					#             this frame to the end of the animation)
					#   LONG      Slice X origin coordinate in the sprite
					#   LONG      Slice Y origin coordinate in the sprite
					#   DWORD     Slice width (can be 0 if this slice hidden in the
					#             animation from the given frame)
					#   DWORD     Slice height
					#   + If flags have bit 1
					#     LONG    Center X position (relative to slice bounds)
					#     LONG    Center Y position
					#     DWORD   Center width
					#     DWORD   Center height
					#   + If flags have bit 2
					#     LONG    Pivot X position (relative to the slice origin)
					#     LONG    Pivot Y position (relative to the slice origin)

					slice_chunk.keys_count = _reader.get_dword()
					slice_chunk.flags = _reader.get_dword()
					_reader.skip(4) # Skip 4 bytes for future use
					slice_chunk.name = _reader.get_string()

					for _key_index in range(slice_chunk.keys_count):
						var slice_key := SliceKey.new()

						slice_chunk.keys.append(slice_key)

						slice_key.frame_number = _reader.get_dword()
						slice_key.origin_x = _reader.get_long()
						slice_key.origin_y = _reader.get_long()
						slice_key.width = _reader.get_dword()
						slice_key.height = _reader.get_dword()

						if slice_chunk.flags & 1 != 0:
							slice_key.center_x = _reader.get_long()
							slice_key.center_y = _reader.get_long()
							slice_key.center_width = _reader.get_dword()
							slice_key.center_height = _reader.get_dword()

						if slice_chunk.flags & 2 != 0:
							slice_key.pivot_x = _reader.get_long()
							slice_key.pivot_y = _reader.get_long()

				# Tileset Chunk
				0x2023:
					var tileset_chunk := Tileset.new()

					frame.chunks.append(tileset_chunk)
					self.tilesets.append(tileset_chunk)

					tileset_chunk.chunk_size = current_chunk_size
					tileset_chunk.chunk_type = current_chunk_type

					tileset_chunk.id = _reader.get_dword()
					tileset_chunk.flags = _reader.get_dword()
					tileset_chunk.tiles_count = _reader.get_dword()
					tileset_chunk.tile_width = _reader.get_word()
					tileset_chunk.tile_height = _reader.get_word()
					tileset_chunk.base_index = _reader.get_word()
					_reader.skip(14)
					tileset_chunk.name = _reader.get_string()

					if tileset_chunk.flags & 1 != 0:
						tileset_chunk.external_file_id = _reader.get_word()
						tileset_chunk.external_id = _reader.get_word()

					if tileset_chunk.flags & 2 != 0:
						var data_len := _reader.get_dword()

						if flags & OPEN_FLAG_SKIP_BUFFER == 0:
							tileset_chunk.buffer = _reader.get_buffer(data_len)

							# ZLIB compressed buffer
							tileset_chunk.buffer = tileset_chunk.buffer.decompress(tileset_chunk.tile_width * tileset_chunk.tile_height * (self.color_depth / 8) * tileset_chunk.tiles_count, FileAccess.CompressionMode.COMPRESSION_DEFLATE)
						else:
							_reader.skip(data_len)

				_:
					# Ignore unsupported chunk types
					_reader.skip(current_chunk_size - 6)

					var unknown_chunk := UnsupportedChunk.new()

					frame.chunks.append(unknown_chunk)

					unknown_chunk.chunk_size = current_chunk_size
					unknown_chunk.chunk_type = current_chunk_type

	# Sanity check, make sure we have read the entire file
	if fs.get_position() != self.file_size:
		return ERR_FILE_EOF

	self.frames = frames

	for frame in frames:
		for chunk in frame.chunks:
			if chunk is AsepriteFile.Layer:
				self.layers.append(chunk)

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

	for index in range(cels.size()):
		var cel := cels[index]
		var img := get_frame_cel_image(frame_index, self.frames[frame_index].cels.find(cels[index]))

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

	return create_image_from_data(
		cel.w,
		cel.h,
		self.color_depth,
		self.palette,
		cel.buffer
	)

func get_tile_image(tileset_index: int, tile_id: int) -> Image:
	# Let Godot to throw "index out of bounds" error if any of the indexes are invalid
	var tileset := self.tilesets[tileset_index]

	# Compressed Tileset image (see NOTE.3): (Tile Width) x (Tile Height x Number of Tiles)
	var stride := tileset.tile_width * tileset.tile_height * (self.color_depth / 8)

	var buffer_pos := tile_id * stride
	var buf := tileset.buffer.slice(buffer_pos, buffer_pos + stride)

	return create_image_from_data(
		tileset.tile_width,
		tileset.tile_height,
		self.color_depth,
		self.palette,
		buf
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
	var colors_count: int = 0
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
		return Color8(self.red, self.green, self.blue, self.alpha)

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

## 0x2008
class ExternalFiles extends Chunk:
	var files_count: int = 0

	var files: Array[ExternalFile] = []

class ExternalFile extends RefCounted:
	enum Type {
		## External palette
		EXTERNAL_PALETTE = 0,
		## External tileset
		EXTERNAL_TILESET = 1,
		## Extension name for properties
		EXTENSION_PROPERTIES = 2,
		## Extension name for tile management (can exist one per sprite)
		EXTENSION_TILE_MANAGEMENT = 3,
	}

	## Entry ID (this ID is referenced by tilesets, palettes, or extended properties)
	var id: int = 0

	## Type
	var type: ExternalFile.Type

	## External file name or extension ID (see NOTE.4)
	var filename: String = ""

## 0x2018
class Tags extends Chunk:
	var tags_count: int = 0

	var tags: Array[Tag] = []

class Tag extends RefCounted:
	enum LoopDirection {
		FORWARD = 0,
		REVERSE = 1,
		PING_PONG = 2,
		PING_PONG_REVERSE = 3,
	}

	var from_frame: int = 0
	var to_frame: int = 0
	var loop_direction: LoopDirection
	var repeat: int = 0

	## @deprecated
	var color_r: int = 0
	## @deprecated
	var color_g: int = 0
	## @deprecated
	var color_b: int = 0

	var name: String = ""

## 0x2022
class Slice extends Chunk:
	enum Flags {
		## It's a 9-patches slice
		NINE_PATCHES = 1 << 0,
		## Has pivot information
		HAS_PIVOT = 1 << 1,
	}

	var keys_count: int = 0
	var flags: Flags = 0
	var name: String = ""

	var keys: Array[SliceKey] = []

class SliceKey extends RefCounted:
	var frame_number: int = 0
	var x: int = 0
	var y: int = 0
	var width: int = 0
	var height: int = 0

	var center_x: int = 0
	var center_y: int = 0
	var center_width: int = 0
	var center_height: int = 0

	var pivot_x: int = 0
	var pivot_y: int = 0

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

class UnsupportedChunk extends Chunk:
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
			_stream = data

		elif data is PackedByteArray:
			var buffer := StreamPeerBuffer.new()
			buffer.data_array = data
			buffer.big_endian = false
			_stream = buffer

		elif data is StreamPeer:
			data.big_endian = false
			_stream = data

	func close() -> void:
		if _stream is FileAccess: _stream.close()
		_stream = null

	func get_available_bytes() -> int:
		if _stream is FileAccess: return _stream.get_length() - _stream.get_position()
		if _stream is StreamPeer: return _stream.get_available_bytes()
		return 0

	# Skip n bytes, return the amount of bytes skipped.
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
		return get_buffer(get_word()).get_string_from_utf8()

	func get_buffer(length: int) -> PackedByteArray:
		if _stream is FileAccess: return _stream.get_buffer(length)
		# TODO: [0] is error, [1] is data, return the error also
		if _stream is StreamPeer: return _stream.get_data(length)[1]
		return PackedByteArray()

	func get_point() -> Vector2:
		return Vector2(get_long(), get_long())

	func get_size() -> Vector2:
		return Vector2(get_long(), get_long())

	func get_rect() -> Rect2:
		return Rect2(get_long(), get_long(), get_long(), get_long())

	## Get pixel color as RGBA8, 0 to 255 range
	## Indexed color (8-bit) returns [R, 0, 0, 255]
	## Grayscale (16-bit) returns [V, V, V, A]
	## RGBA (32-bit) returns [R, G, B, A]
	func get_pixel(color_depth: int) -> Array[int]:
		if color_depth == 8:
			var r := get_byte()
			return [r, 0, 0, 255]

		if color_depth == 16:
			var v := get_byte()
			var a := get_byte()
			return [v, v, v, a]

		if color_depth == 32:
			var r := get_byte()
			var g := get_byte()
			var b := get_byte()
			var a := get_byte()
			return [r, g, b, a]

		return [0, 0, 0, 0]

	func get_uuid() -> String:
		var buf := get_buffer(16)

		if buf.size() != 16:
			return ""

		var hex := ""
		for i in range(buf.size()):
			hex += "%02x" % buf[i]

		return hex

	func read_buffer(length: int, flags: ReadFlags = 0, decompress_size: int = 0) -> PackedByteArray:
		if flags & ReadFlags.SKIP_BUFFER != 0:
			skip(length)
			return []

		var buf := get_buffer(length)

		if flags & ReadFlags.DECOMPRESS != 0 and decompress_size > 0:
			buf = buf.decompress(decompress_size, FileAccess.CompressionMode.COMPRESSION_DEFLATE)

		return buf

	# DWORD       Bytes in this frame
	# WORD        Magic number (always 0xF1FA)
	# WORD        Old field which specifies the number of "chunks" in this frame. If this value is 0xFFFF, we might have more chunks to read in this frame (so we have to use the new field)
	# WORD        Frame duration (in milliseconds)
	# BYTE[2]     For future (set to zero)
	# DWORD       New field which specifies the number of "chunks" in this frame (if this is 0, use the old field)
	func read_frame() -> Frame:
		var frame := Frame.new()

		frame.frame_size = get_dword()

		# Aseprite - Invalid frame magic number
		if get_word() != 0xF1FA:
			push_warning("Aseprite - Invalid frame magic number")
			return null

		frame.chunks_num_old = get_word()
		frame.duration = get_word()
		skip(2)
		frame.chunks_num_new = get_dword()

		return frame

	# DWORD       Chunk size
	# WORD        Chunk type
	func read_chunk_header() -> ChunkHeader:
		var header := ChunkHeader.new()

		header.size = get_dword()
		header.type = get_word()

		return header

	# 0x2004
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
	func read_layer_chunk(header: ChunkHeader) -> Layer:
		var layer := Layer.new()

		layer.chunk_size = header.size if header else 0
		layer.chunk_type = header.type if header else 0

		layer.flags = get_word()
		layer.type = get_word()
		layer.child_level = get_word()
		layer.default_width = get_word()
		layer.default_height = get_word()
		layer.blend_mode = get_word()
		layer.opacity = get_byte()
		skip(3)
		layer.name = get_string()

		if layer.type == 2:
			layer.tileset_index = get_dword()

		if layer.flags & 4:
			layer.uuid = get_uuid()

		return layer

	# 0x2005
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
	#   PIXEL[]   Raw pixel data: row by row from top to bottom, for each scanline read pixels from left to right.
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
	#   TILE[]    Row by row, from top to bottom tile by tile compressed with ZLIB method (see NOTE.3)
	func read_cel_chunk(header: ChunkHeader, color_depth: int, flags: ReadFlags = 0) -> Cel:
		var cel := Cel.new()

		cel.chunk_size = header.size if header else 0
		cel.chunk_type = header.type if header else 0

		cel.layer_index = get_word()
		cel.x = get_short()
		cel.y = get_short()
		cel.opacity = get_byte()
		cel.type = get_word()
		cel.z_index = get_short()
		skip(5)

		if cel.type == 0:
			cel.w = get_word()
			cel.h = get_word()
			# cel of type 0 are never compressed (flags & ~ReadFlags.DECOMPRESS)
			cel.buffer = read_buffer(cel.chunk_size - 26, flags, 0)

		elif cel.type == 1:
			cel.link = get_word()

		elif cel.type == 2:
			cel.w = get_word()
			cel.h = get_word()
			cel.buffer = read_buffer(cel.chunk_size - 26, flags, cel.w * cel.h * (color_depth / 8))

		elif cel.type == 3:
			cel.w = get_word()
			cel.h = get_word()
			cel.bits_per_tile = get_word()
			cel.bitmask_for_tile_id = get_dword()
			cel.bitmask_for_x_flip = get_dword()
			cel.bitmask_for_y_flip = get_dword()
			cel.bitmask_for_90cw_rotation = get_dword()
			skip(10)
			cel.buffer = read_buffer(cel.chunk_size - 54, flags, cel.w * cel.h * (cel.bits_per_tile / 8))

		return cel

	# 0x2006
	#     DWORD       Flags (set to zero) 1 = Precise bounds are set
	#     FIXED       Precise X position
	#     FIXED       Precise Y position
	#     FIXED       Width of the cel in the sprite (scaled in real-time)
	#     FIXED       Height of the cel in the sprite
	#     BYTE[16]    For future use (set to zero)
	func read_cel_extra_chunk(header: ChunkHeader) -> CelExtra:
		var cel_extra := CelExtra.new()

		cel_extra.chunk_size = header.size if header else 0
		cel_extra.chunk_type = header.type if header else 0

		cel_extra.flags = get_word()
		cel_extra.precise_x = get_fixed()
		cel_extra.precise_y = get_fixed()
		cel_extra.width = get_fixed()
		cel_extra.height = get_fixed()
		skip(16)

		return cel_extra

	# 0x2007
	# WORD        Type
	# WORD        Flags
	# FIXED       Fixed gamma (1.0 = linear)
	# BYTE[8]     Reserved (set to zero)
	# + If type = ICC:
	#   DWORD     ICC profile data length
	#   BYTE[]    ICC profile data. More info: http://www.color.org/ICC1V42.pdf
	func read_color_profile_chunk(header: ChunkHeader, flags: ReadFlags = 0) -> ColorProfile:
		var color_profile := ColorProfile.new()

		color_profile.chunk_size = header.size if header else 0
		color_profile.chunk_type = header.type if header else 0

		color_profile.type = get_word()
		color_profile.flags = get_word()
		color_profile.fixed_gamma = get_fixed()
		skip(8)

		if color_profile.type == 2:
			var icc_data_len := get_dword()
			color_profile.icc_data = read_buffer(icc_data_len, flags, 0)

		return color_profile

	# 0x2008
	# DWORD       Number of entries
	# BYTE[8]     Reserved (set to zero)
	# + For each entry
	#   DWORD     Entry ID (this ID is referenced by tilesets, palettes, or extended properties)
	#   BYTE      Type
	#   BYTE[7]   Reserved (set to zero)
	#   STRING    External file name or extension ID (see NOTE.4)
	func read_external_files_chunk(header: ChunkHeader) -> ExternalFiles:
		var external_files := ExternalFiles.new()

		external_files.chunk_size = header.size if header else 0
		external_files.chunk_type = header.type if header else 0

		external_files.files_count = get_dword()
		skip(8)

		for i in range(external_files.files_count):
			var file := ExternalFile.new()

			file.id = get_dword()
			file.type = get_byte()
			skip(7)
			file.filename = get_string()

			external_files.files.append(file)

		return external_files

	# 0x2018
	# WORD        Number of tags
	# BYTE[8]     For future (set to zero)
	# + For each tag
	#   WORD      From frame
	#   WORD      To frame
	#   BYTE      Loop animation direction
	#   WORD      Repeat N times. Play this animation section N times:
	#   BYTE[6]   For future (set to zero)
	#   BYTE[3]   RGB values of the tag color
	#   BYTE      Extra byte (zero)
	#   STRING    Tag name
	func read_tags_chunk(header: ChunkHeader) -> Tags:
		var tags := Tags.new()

		tags.chunk_size = header.size if header else 0
		tags.chunk_type = header.type if header else 0

		tags.tags_count = get_word()
		skip(8)

		for i in range(tags.tags_count):
			var tag := Tag.new()

			tag.from_frame = get_word()
			tag.to_frame = get_word()
			tag.loop_direction = get_byte()
			tag.repeat = get_word()
			skip(6)
			tag.color_r = get_byte()
			tag.color_g = get_byte()
			tag.color_b = get_byte()
			skip(1)
			tag.name = get_string()

			tags.tags.append(tag)

		return tags

	# 0x2019
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
	func read_palette_chunk(header: ChunkHeader) -> Palette:
		var palette := Palette.new()

		palette.chunk_size = header.size if header else 0
		palette.chunk_type = header.type if header else 0

		palette.colors_count = get_dword()
		palette.first_color = get_dword()
		palette.last_color = get_dword()
		skip(8)

		for i in range(palette.colors_count):
			var color := PaletteColor.new()

			color.flags = get_word()
			color.red = get_byte()
			color.green = get_byte()
			color.blue = get_byte()
			color.alpha = get_byte()

			if color.flags & PaletteColor.Flags.HAS_NAME != 0:
				color.name = get_string()

			palette.colors.append(color)

		return palette

	# 0x2022
	# DWORD       Number of "slice keys"
	# DWORD       Flags
	# DWORD       Reserved
	# STRING      Name
	# + For each slice key
	#   DWORD     Frame number (this slice is valid from this frame to the end of the animation)
	#   LONG      Slice X origin coordinate in the sprite
	#   LONG      Slice Y origin coordinate in the sprite
	#   DWORD     Slice width (can be 0 if this slice hidden in the animation from the given frame)
	#   DWORD     Slice height
	#   + If flags have bit 1
	#     LONG    Center X position (relative to slice bounds)
	#     LONG    Center Y position
	#     DWORD   Center width
	#     DWORD   Center height
	#   + If flags have bit 2
	#     LONG    Pivot X position (relative to the slice origin)
	#     LONG    Pivot Y position (relative to the slice origin)
	func read_slice_chunk(header: ChunkHeader) -> Slice:
		var slice := Slice.new()

		slice.chunk_size = header.size if header else 0
		slice.chunk_type = header.type if header else 0

		slice.keys_count = get_dword()
		slice.flags = get_dword()
		skip(4)
		slice.name = get_string()

		for i in range(slice.keys_count):
			var key := SliceKey.new()

			key.frame_number = get_dword()
			key.origin_x = get_long()
			key.origin_y = get_long()
			key.width = get_dword()
			key.height = get_dword()

			if slice.flags & Slice.Flags.NINE_PATCHES != 0:
				key.center_x = get_long()
				key.center_y = get_long()
				key.center_width = get_dword()
				key.center_height = get_dword()

			if slice.flags & Slice.Flags.HAS_PIVOT != 0:
				key.pivot_x = get_long()
				key.pivot_y = get_long()

			slice.keys.append(key)

		return slice

	# 0x2023
    # DWORD       Tileset ID
    # DWORD       Tileset flags
    # DWORD       Number of tiles
    # WORD        Tile Width
    # WORD        Tile Height
    # SHORT       Base Index: Number to show in the screen from the tile with index 1 and so on (by default this is field is 1, so the data that is displayed is equivalent to the data in memory). But it can be 0 to display zero-based indexing (this field isn't used for the representation of the data in the file, it's just for UI purposes).
    # BYTE[14]    Reserved
    # STRING      Name of the tileset
    # + If flag 1 is set
    #   DWORD     ID of the external file. This ID is one entry of the the External Files Chunk.
    #   DWORD     Tileset ID in the external file
    # + If flag 2 is set
    #   DWORD     Data length of the compressed Tileset image
    #   PIXEL[]   Compressed Tileset image (see NOTE.3): (Tile Width) x (Tile Height x Number of Tiles)
	func read_tileset_chunk(header: ChunkHeader, color_depth: int, flags: ReadFlags = 0) -> Tileset:
		var tileset := Tileset.new()

		tileset.chunk_size = header.size if header else 0
		tileset.chunk_type = header.type if header else 0

		tileset.id = get_dword()
		tileset.flags = get_dword()
		tileset.tiles_count = get_dword()
		tileset.tile_width = get_word()
		tileset.tile_height = get_word()
		tileset.base_index = get_word()
		skip(14)
		tileset.name = get_string()

		if tileset.flags & 1 != 0:
			tileset.external_file_id = get_word()
			tileset.external_id = get_word()

		if tileset.flags & 2 != 0:
			var data_len := get_dword()
			tileset.buffer = read_buffer(data_len, flags, tileset.tile_width * tileset.tile_height * (color_depth / 8) * tileset.tiles_count)

		return tileset

	enum ReadFlags {
		SKIP_BUFFER = 1 << 0,
		DECOMPRESS = 1 << 1,
	}

	class ChunkHeader extends RefCounted:
		var size: int = 0
		var type: int = 0
