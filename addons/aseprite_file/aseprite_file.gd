## This class is used to read Aseprite files and extract metadata such as frames and layers.
##
## Open and read a file:
## [codeblock]
## var ase := AsepriteFile.open("res://path/to/file.aseprite")
## [/codeblock]
##
## Open return [code]null[/code] if the file could not be opened, you can use [method get_open_error] to get the error code.
## [codeblock]
## var ase := AsepriteFile.open("res://path/to/file.aseprite")
## if ase == null:
##     var err := AsepriteFile.get_open_error()
##     print("Failed to open Aseprite file: %s" % error_string(err))
## [/codeblock]
class_name AsepriteFile extends RefCounted

const CHUNK_OLD_PALETTE_1 := ChunkType.OLD_PALETTE_1
const CHUNK_OLD_PALETTE_2 := ChunkType.OLD_PALETTE_2
const CHUNK_LAYER := ChunkType.LAYER
const CHUNK_CEL := ChunkType.CEL
const CHUNK_CEL_EXTRA := ChunkType.CEL_EXTRA
const CHUNK_COLOR_PROFILE := ChunkType.COLOR_PROFILE
const CHUNK_EXTERNAL_FILES := ChunkType.EXTERNAL_FILES
const CHUNK_MASK := ChunkType.MASK
const CHUNK_PATH := ChunkType.PATH
const CHUNK_TAGS := ChunkType.TAGS
const CHUNK_PALETTE := ChunkType.PALETTE
const CHUNK_USER_DATA := ChunkType.USER_DATA
const CHUNK_SLICE := ChunkType.SLICE
const CHUNK_TILESET := ChunkType.TILESET

const PALETTE_COLOR_FLAG_HAS_NAME := PaletteColorFlags.HAS_NAME

const LAYER_TYPE_NORMAL := LayerType.NORMAL
const LAYER_TYPE_GROUP := LayerType.GROUP
const LAYER_TYPE_TILEMAP := LayerType.TILEMAP

const LAYER_FLAG_VISIBLE := LayerFlags.VISIBLE
const LAYER_FLAG_EDITABLE := LayerFlags.EDITABLE
const LAYER_FLAG_LOCK_MOVEMENT := LayerFlags.LOCK_MOVEMENT
const LAYER_FLAG_BACKGROUND := LayerFlags.BACKGROUND
const LAYER_FLAG_PREFER_LINKED_CEL := LayerFlags.PREFER_LINKED_CELS
const LAYER_FLAG_GROUP_COLLAPSED := LayerFlags.GROUP_COLLAPSED
const LAYER_FLAG_REFERENCE_LAYER := LayerFlags.REFERENCE_LAYER

const LAYER_BLEND_NORMAL := LayerBlendMode.NORMAL
const LAYER_BLEND_MULTIPLY := LayerBlendMode.MULTIPLY
const LAYER_BLEND_SCREEN := LayerBlendMode.SCREEN
const LAYER_BLEND_OVERLAY := LayerBlendMode.OVERLAY
const LAYER_BLEND_DARKEN := LayerBlendMode.DARKEN
const LAYER_BLEND_LIGHTEN := LayerBlendMode.LIGHTEN
const LAYER_BLEND_COLOR_DODGE := LayerBlendMode.COLOR_DODGE
const LAYER_BLEND_COLOR_BURN := LayerBlendMode.COLOR_BURN
const LAYER_BLEND_HARD_LIGHT := LayerBlendMode.HARD_LIGHT
const LAYER_BLEND_SOFT_LIGHT := LayerBlendMode.SOFT_LIGHT
const LAYER_BLEND_DIFFERENCE := LayerBlendMode.DIFFERENCE
const LAYER_BLEND_EXCLUSION := LayerBlendMode.EXCLUSION
const LAYER_BLEND_HUE := LayerBlendMode.HUE
const LAYER_BLEND_SATURATION := LayerBlendMode.SATURATION
const LAYER_BLEND_COLOR := LayerBlendMode.COLOR
const LAYER_BLEND_LUMINOSITY := LayerBlendMode.LUMINOSITY
const LAYER_BLEND_ADDITION := LayerBlendMode.ADDITION
const LAYER_BLEND_SUBTRACT := LayerBlendMode.SUBTRACT
const LAYER_BLEND_DIVIDE := LayerBlendMode.DIVIDE

const CEL_TYPE_IMAGE := CelType.IMAGE
const CEL_TYPE_LINKED := CelType.LINKED_CEL
const CEL_TYPE_COMPRESSED_CEL := CelType.COMPRESSED_CEL
const CEL_TYPE_COMPRESSED_TILEMAP := CelType.COMPRESSED_TILEMAP

const CEL_EXTRA_FLAG_PRECISE_BOUNDS := CelExtraFlags.PRECISE_BOUNDS

const COLOR_PROFILE_TYPE_NONE := ColorProfileType.NO_PROFILE
const COLOR_PROFILE_TYPE_SRGB := ColorProfileType.SRGB
const COLOR_PROFILE_TYPE_ICC := ColorProfileType.EMBEDDED_ICC

const COLOR_PROFILE_FLAG_FIXED_GAMMA := ColorProfileFlags.USE_FIXED_GAMMA

const OPEN_FLAGS_SKIP_BUFFER := AsepriteReader.ReadFlags.SKIP_BUFFER

const MAGIC_NUMBER: int = 0xA5E0

## Size of the file in bytes
var file_size: int = -1

var magic_number: int = 0

## Number of frames in the sprite
var num_frames: int = 0

## Width in pixels
var width: int = 0

## Height in pixels
var height: int = 0

## Color depth:
## [br] • [code]32[/code] = RGBA, 8 bits per channel
## [br] • [code]16[/code] = Grayscale, 8 bits for luminance, 8 bits for alpha
## [br] • [code]8 [/code]= Indexed, 8 bits per pixel (palette index)
var color_depth: int = 0

## Flags (see NOTE.6):
## 1 = Layer opacity has valid value
## 2 = Layer blend mode/opacity is valid for groups (composite groups separately first when rendering)
## 4 = Layers have an UUID
var flags: int = 0

## Speed (milliseconds between frame, like in FLC files)
## [br]
## [b]DEPRECATED[/b]: You should use the frame duration field
## from each frame header
## @deprecated
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

# -- END OF HEADER --

## Frames in the sprite.
var frames: Array[Frame] = []

var external_files: Array[ExternalFile] = []

## Layers in the sprite.
var layers: Array[Layer] = []

## A tileset is a collection of individual tiles, arranged in a grid.
var tilesets: Array[Tileset] = []

## Tag list
var tags: Array[Tag] = []

## The palette used in the sprite.
var palette: Palette = Palette.new()

## The color profile used in the sprite.
var color_profile: ColorProfile = ColorProfile.new()

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

static var _last_open_error: Error = OK

## Returns the result of the last `open()` call in the current thread.
static func get_open_error() -> Error:
	return _last_open_error

## Open and read an Aseprite file from the specified path.
static func open(path: String, flags: AsepriteReader.ReadFlags = AsepriteReader.ReadFlags.DECOMPRESS) -> AsepriteFile:
	var reader := AsepriteReader.new()
	_last_open_error = reader.open(path, flags)

	if _last_open_error != OK:
		reader.close()
		return null

	var ase := reader.read_ase()

	if ase.magic_number != MAGIC_NUMBER:
		_last_open_error = ERR_FILE_CORRUPT
		reader.close()
		return null

	for frame in ase.frames:
		if frame.magic_number != Frame.MAGIC_NUMBER:
			_last_open_error = ERR_FILE_CORRUPT
			reader.close()
			return null

	return ase


## Represent a single frame.
class Frame extends RefCounted:
	const MAGIC_NUMBER := 0xF1FA

	## Bytes in this frame
	var frame_size: int = 0

	## Magic number (should be 0xF1FA)
	var magic_number: int = 0

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

	## The chunks in this frame.
	var chunks: Array[Chunk] = []

	## The cels in this frame.
	var cels: Array[Cel] = []

	## Return the number of chunks in this frame.
	func get_chunks_count() -> int:
		# Per spec, use old chunks count if new chunks count is zero
		return chunks_num_old if chunks_num_new == 0 else chunks_num_new


## Represent the chunk type.
enum ChunkType {
	## DEPRECATED
	##
	## @deprecated
	OLD_PALETTE_1 = 0x0004,

	## DEPRECATED
	##
	## @deprecated
	OLD_PALETTE_2 = 0x0011,

	## Layer chunk [code]0x2004[/code]
	LAYER = 0x2004,

	## Cel chunk [code]0x2005[/code]
	CEL = 0x2005,

	## Cel extra chunk [code]0x2006[/code]
	CEL_EXTRA = 0x2006,

	## Color profile chunk [code]0x2007[/code]
	COLOR_PROFILE = 0x2007,

	## External files chunk [code]0x2008[/code]
	EXTERNAL_FILES = 0x2008,

	## DEPRECATED
	##
	## @deprecated
	MASK = 0x2016,

	## Never used.
	PATH = 0x2017,

	## Tags chunk [code]0x2018[/code]
	TAGS = 0x2018,

	## Palette chunk [code]0x2019[/code]
	PALETTE = 0x2019,

	## User data chunk [code]0x2020[/code]
	USER_DATA = 0x2020,

	## Slice chunk [code]0x2022[/code]
	SLICE = 0x2022,

	## Tileset chunk [code]0x2023[/code]
	TILESET = 0x2023,
}

## Base class for all chunks.
class Chunk extends RefCounted:
	## Size of the chunk in bytes
	var chunk_size: int = 0

	## Chunk type
	var chunk_type: ChunkType = 0


## 0x2019
class Palette extends Chunk:
	## Number of colors in the palette
	var colors_count: int = 0

	## First color index to change
	var first_color: int = 0

	## Last color index to change
	var last_color: int = 0

	## Palette colors
	var colors: Array[PaletteColor] = []

	## Return the first color in the palette, or null if the palette is empty.
	func get_first_color() -> PaletteColor:
		return self.colors[self.first_color] if self.colors.size() > self.first_color else null

	## Return the last color in the palette, or null if the palette is empty.
	func get_last_color() -> PaletteColor:
		return self.colors[self.last_color] if self.colors.size() > self.last_color else null

## Palette color flags
enum PaletteColorFlags {
	## 1 = Has Name
	HAS_NAME = 1 << 0
}

## A single color in the palette.
class PaletteColor extends RefCounted:
	## Color flags
	var flags: PaletteColorFlags = 0

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

	func has_name() -> bool: return (self.flags & PaletteColorFlags.HAS_NAME) != 0

	## Convert to Godot Color
	func to_color() -> Color: return Color8(self.red, self.green, self.blue, self.alpha)

enum LayerType {
	## Normal layer
	NORMAL = 0,

	## Group layer
	GROUP = 1,

	## Tilemap layer
	TILEMAP = 2,
}

enum LayerFlags {
	## The layer is visible
	VISIBLE = 1 << 0,

	## The layer is editable
	EDITABLE = 1 << 1,

	## The layer movement is locked
	LOCK_MOVEMENT = 1 << 2,

	## The layer is a background layer
	BACKGROUND = 1 << 3,

	## The layer prefers linked cels over linked frames
	PREFER_LINKED_CELS = 1 << 4,

	## The layer group should be displayed collapsed
	GROUP_COLLAPSED = 1 << 5,

	## The layer is a reference layer
	REFERENCE_LAYER = 1 << 6,
}

enum LayerBlendMode {
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

## 0x2004
class Layer extends Chunk:
	## Layer flags
	var flags: LayerFlags

	## Layer type
	var type: LayerType

	## Layer child level
	var child_level: int

	## Default layer width in pixels (ignored)
	var default_width: int

	## Default layer height in pixels (ignored)
	var default_height: int

	## Blend mode
	var blend_mode: LayerBlendMode

	var opacity: int

	## Layer name
	var name: String = ""

	var tileset_index: int = -1
	var uuid: String = ""

	func is_normal_layer() -> bool: return self.type == LayerType.NORMAL
	func is_group_layer() -> bool: return self.type == LayerType.GROUP
	func is_tilemap_layer() -> bool: return self.type == LayerType.TILEMAP

	func has_flag(flag: LayerFlags) -> bool: return (self.flags & flag) != 0

	func is_visible() -> bool: return (self.flags & LayerFlags.VISIBLE) != 0
	func is_hidden() -> bool: return not self.is_visible()
	func is_editable() -> bool: return (self.flags & LayerFlags.EDITABLE) != 0
	func is_background() -> bool: return (self.flags & LayerFlags.BACKGROUND) != 0
	func is_reference_layer() -> bool: return (self.flags & LayerFlags.REFERENCE_LAYER) != 0

enum CelType {
	## Image cel
	IMAGE = 0,

	## Linked cel
	LINKED_CEL = 1,

	## Compressed cel
	COMPRESSED_CEL = 2,

	## Compressed tilemap
	COMPRESSED_TILEMAP = 3,
}

## 0x2005
class Cel extends Chunk:
	## Layer index
	var layer_index: int

	## X coordinate of the cell
	var x: int

	## Y coordinate of the cell
	var y: int

	## Opacity of the cell
	var opacity: int

	## Cell type
	var type: CelType

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

## Cel extra flags
enum CelExtraFlags {
	## Precise bounds are set
	PRECISE_BOUNDS = 1 << 0
}

## 0x2006
class CelExtra extends Chunk:
	var flags: CelExtraFlags = 0
	var precise_x: float = 0.0
	var precise_y: float = 0.0
	var width: float = 0.0
	var height: float = 0.0

	func has_precise_bounds() -> bool:
		return (self.flags & CelExtraFlags.PRECISE_BOUNDS) != 0

enum ColorProfileType {
	## no color profile (as in old .aseprite files)
	NO_PROFILE = 0,

	## use sRGB
	SRGB = 1,

	## use the embedded ICC profile
	EMBEDDED_ICC = 2,
}

## Color profile flags
enum ColorProfileFlags {
	## use special fixed gamma
	USE_FIXED_GAMMA = 1
}

## 0x2007
class ColorProfile extends Chunk:
	## Color profile type
	var type: ColorProfileType = 0

	## Flags
	var flags: ColorProfileFlags = 0

	## Fixed gamma (1.0 = linear)
	## Note: The gamma in sRGB is 2.2 in overall but it doesn't use
	## this fixed gamma, because sRGB uses different gamma sections
	## (linear and non-linear). If sRGB is specified with a fixed
	## gamma = 1.0, it means that this is Linear sRGB.
	var fixed_gamma: float = 0.0

	## ICC Color profile data, only if type == EMBEDDED_ICC
	var icc_data: PackedByteArray = []

	func has_fixed_gamma() -> bool:
		return (self.flags & ColorProfileFlags.USE_FIXED_GAMMA) != 0


## 0x2008
class ExternalFiles extends Chunk:
	var files_count: int = 0

	var files: Array[ExternalFile] = []

## Type of external file.
enum ExternalFileType {
	## External palette
	EXTERNAL_PALETTE = 0,
	## External tileset
	EXTERNAL_TILESET = 1,
	## Extension name for properties
	EXTENSION_PROPERTIES = 2,
	## Extension name for tile management (can exist one per sprite)
	EXTENSION_TILE_MANAGEMENT = 3,
}

## A single external file entry.
class ExternalFile extends RefCounted:
	## Entry ID (this ID is referenced by tilesets, palettes, or extended properties)
	var id: int = 0

	## Type
	var type: ExternalFileType

	## External file name or extension ID (see NOTE.4)
	var filename: String = ""


## 0x2018
class Tags extends Chunk:
	var tags_count: int = 0

	var tags: Array[Tag] = []

enum TagLoopDirection {
	FORWARD = 0,
	REVERSE = 1,
	PING_PONG = 2,
	PING_PONG_REVERSE = 3,
}

## A tag entry.
class Tag extends RefCounted:
	var from_frame: int = 0
	var to_frame: int = 0
	var loop_direction: TagLoopDirection
	var repeat: int = 0

	## Deprecated, used only for backward compatibility with Aseprite v1.2.x
	## The color of the tag is the one in the user data field following the tags chunk
	## @deprecated
	var color_r: int = 0

	## Deprecated, used only for backward compatibility with Aseprite v1.2.x
	## The color of the tag is the one in the user data field following the tags chunk
	## @deprecated
	var color_g: int = 0

	## Deprecated, used only for backward compatibility with Aseprite v1.2.x
	## The color of the tag is the one in the user data field following the tags chunk
	## @deprecated
	var color_b: int = 0

	var name: String = ""


# 0x2020
class UserData extends Chunk:
	enum Flags {
		## Has text data
		HAS_TEXT = 1 << 0,
		## Has color data
		HAS_COLOR = 1 << 1,
		## Has properties data
		HAS_PROPERTIES = 1 << 2,
	}

	var flags: UserData.Flags = 0

	var text: String = ""

	var color_r: int = 0
	var color_g: int = 0
	var color_b: int = 0
	var color_a: int = 0

	var properties_size: int = 0
	var properties_maps_count: int = 0

	var maps: Array[PropertyMap] = []

class PropertyMap extends RefCounted:
	var key: int = 0
	var properties_count: int = 0

	var properties: Array[UserDataProperty] = []

class UserDataProperty extends RefCounted:
	var name: String = ""
	var type: int = 0

enum SliceFlags {
	## It's a 9-patches slice
	NINE_PATCHES = 1 << 0,
	## Has pivot information
	HAS_PIVOT = 1 << 1,
}

## 0x2022
class Slice extends Chunk:
	var keys_count: int = 0
	var flags: SliceFlags = 0
	var name: String = ""

	var keys: Array[SliceKey] = []

## A slice key.
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

enum TilesetFlags {
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

## 0x2023
class Tileset extends Chunk:
	var id: int = 0
	var flags: TilesetFlags = 0
	var tiles_count: int = 0
	var tile_width: int = 0
	var tile_height: int = 0
	var base_index: int = 0
	var name: String = ""
	var external_file_id: int = -1
	var external_id: int = -1
	var buffer: PackedByteArray = []


## 0x0004, 0x0011, 0x2016, 0x2017
class UnsupportedChunk extends Chunk:
	pass


# #FileAccess does not extend StreamPeer...
# Additionally, get_xxx() do not return an error if the stream is empty
# we are supposed to check get_available_bytes() first
# however i am unsure if get_available_bytes() == 0 means we cant read no more

## Reader for Aseprite files.
##
## Supports reading from a file path, FileAccess, StreamPeer or PackedByteArray.
## [br]
## [br]
## To read from a file path, you can use:
## [codeblock]
## var reader := AsepriteReader.new()
##
## # Open for read, skip buffer data
## var err := reader.open("res://path/to/file.aseprite", AsepriteReader.ReadFlags.SKIP_BUFFER)
##
## # Read the header
## var header := reader.read_header()
##
## # For each frame, read the frame data
## for frame_index in range(header.num_frames):
##     # Read the frame
##     var frame := reader.read_frame()
##
##     # Now we can read each chunk in the frame
##     for chunk_index in range(frame.get_chunks_count()):
##         # Read the chunk header
##         var chunk_header := read_chunk_header()
##
##         # Do something with the chunk type
##         match chunk_header.chunk_type:
##            # Remember to read the chunk data, if you do not need it, read as empty chunk
##             _: read_empty_chunk()
## [/codeblock]
class AsepriteReader extends RefCounted:
	enum ReadFlags {
		NONE = 0,

		## Do not read binary data.
		SKIP_BUFFER = 1 << 0,

		## Automatically decompress gzipped data.
		DECOMPRESS = 1 << 1,
	}

	var _stream: Variant = null
	var _flags: ReadFlags = 0

	## Open a file or stream for reading.
	func open(data: Variant, flags: ReadFlags = ReadFlags.DECOMPRESS) -> Error:
		if data is FileAccess:
			data.big_endian = false
			_stream = data
			return OK

		elif data is PackedByteArray:
			var buffer := StreamPeerBuffer.new()
			buffer.data_array = data
			buffer.big_endian = false
			_stream = buffer
			return OK

		elif data is StreamPeer:
			data.big_endian = false
			_stream = data
			return OK

		elif data is String:
			var file := FileAccess.open(data, FileAccess.READ)
			if file == null:
				return FileAccess.get_open_error()
			else:
				file.big_endian = false
				_stream = file
				return OK

		else:
			return ERR_INVALID_PARAMETER

	## Closes the underlying resources used by this instance.
	func close() -> Error:
		if _stream is FileAccess: _stream.close()
		if _stream: _stream.free()
		_stream = null
		return OK

	## Returns the number of bytes available.
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

	## Read a 8-bit unsigned integer value
	func get_byte() -> int:
		if _stream is FileAccess: return _stream.get_8()
		if _stream is StreamPeer: return _stream.get_8()
		return -1

	## Read a 16-bit unsigned integer value
	func get_word() -> int:
		if _stream is FileAccess: return _stream.get_16()
		if _stream is StreamPeer: return _stream.get_16()
		return -1

	## Read a 32-bit unsigned integer value
	func get_dword() -> int:
		if _stream is FileAccess: return _stream.get_32()
		if _stream is StreamPeer: return _stream.get_32()
		return -1

	## Read a 16-bit signed integer value
	func get_short() -> int:
		if _stream is FileAccess: return _stream.get_16()
		if _stream is StreamPeer: return _stream.get_16()
		return -1

	## Read a 32-bit signed integer value
	func get_long() -> int:
		if _stream is FileAccess: return _stream.get_32()
		if _stream is StreamPeer: return _stream.get_32()
		return -1

	## Read a 32-bit fixed point (16.16) value
	func get_fixed() -> float:
		if _stream is FileAccess: return _stream.get_32() << 16
		if _stream is StreamPeer: return _stream.get_32() << 16
		return 0.0

	## Read a 32-bit single-precision value
	func get_float() -> float:
		if _stream is FileAccess: return _stream.get_float()
		if _stream is StreamPeer: return _stream.get_float()
		return 0.0

	## Read a 64-bit double-precision value
	func get_double() -> float:
		if _stream is FileAccess: return _stream.get_double()
		if _stream is StreamPeer: return _stream.get_double()
		return 0.0

	## Read a 64-bit unsigned integer value
	func get_qword() -> int:
		if _stream is FileAccess: return _stream.get_64()
		if _stream is StreamPeer: return _stream.get_64()
		return -1

	## Read a 64-bit signed integer value
	func get_long64() -> int:
		if _stream is FileAccess: return _stream.get_64()
		if _stream is StreamPeer: return _stream.get_64()
		return -1

	## Read a string prefixed with a 16-bit length
	func get_string() -> String:
		return get_buffer(get_word()).get_string_from_utf8()

	## Read a buffer of given length
	func get_buffer(length: int) -> PackedByteArray:
		if _stream is FileAccess: return _stream.get_buffer(length)
		# TODO: [0] is error, [1] is data, return the error also
		if _stream is StreamPeer: return _stream.get_data(length)[1]
		return PackedByteArray()

	## Read a point (LONG, LONG)
	func get_point() -> Vector2:
		return Vector2(get_long(), get_long())

	## Read a size (LONG, LONG)
	func get_size() -> Vector2:
		return Vector2(get_long(), get_long())

	## Read a rect (LONG, LONG, LONG, LONG)
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

	## Read a UUID (16 bytes) and return it as a lowercased hex string
	func get_uuid() -> String:
		var buf := get_buffer(16)

		if buf.size() != 16:
			return ""

		var hex := ""
		for i in range(buf.size()):
			hex += "%02x" % buf[i]

		return hex

	## Read a buffer, optionally decompressing it.
	func read_buffer(length: int, decompress_size: int = 0) -> PackedByteArray:
		if _flags & ReadFlags.SKIP_BUFFER != 0:
			skip(length)
			return []

		var buf := get_buffer(length)

		if _flags & ReadFlags.DECOMPRESS != 0 and decompress_size > 0:
			buf = buf.decompress(decompress_size, FileAccess.CompressionMode.COMPRESSION_DEFLATE)

		return buf

	# A 128-byte header (same as FLC/FLI header, but with other magic number):
	# DWORD       File size
	# WORD        Magic number (0xA5E0)
	# WORD        Frames
	# WORD        Width in pixels
	# WORD        Height in pixels
	# WORD        Color depth (bits per pixel)
	# DWORD       Flags (see NOTE.6):
	# WORD        Speed (milliseconds between frame, like in FLC files)
	# DWORD       Set be 0
	# DWORD       Set be 0
	# BYTE        Palette entry (index) which represent transparent color in all non-background layers (only for Indexed sprites).
	# BYTE[3]     Ignore these bytes
	# WORD        Number of colors (0 means 256 for old sprites)
	# BYTE        Pixel width (pixel ratio is "pixel width/pixel height"). If this or pixel height field is zero, pixel ratio is 1:1
	# BYTE        Pixel height
	# SHORT       X position of the grid
	# SHORT       Y position of the grid
	# WORD        Grid width (zero if there is no grid, grid size is 16x16 on Aseprite by default)
	# WORD        Grid height (zero if there is no grid)
	# BYTE[84]    For future (set to zero)
	func read_header() -> AsepriteFile:
		var ase := AsepriteFile.new()

		ase.file_size = get_dword()
		ase.magic_number = get_word()

		# Do not read past the magic number if it's invalid
		if ase.magic_number != AsepriteFile.MAGIC_NUMBER:
			# push_warning("Aseprite - Invalid file magic number")
			return ase

		ase.num_frames = get_word()
		ase.width = get_word()
		ase.height = get_word()
		ase.color_depth = get_word()
		ase.flags = get_dword()
		ase.speed = get_word()

		# # Two consecutive DWORDs must be zero
		# if get_dword() != 0: return ERR_FILE_CORRUPT
		# if get_dword() != 0: return ERR_FILE_CORRUPT
		skip(8)

		ase.palette_entry = get_byte()
		skip(3)
		ase.num_colors = get_word()
		ase.pixel_width = get_byte()
		ase.pixel_height = get_byte()
		ase.grid_x = get_word()
		ase.grid_y = get_word()
		ase.grid_width = get_word()
		ase.grid_height = get_word()
		skip(84)

		return ase

	# DWORD       Bytes in this frame
	# WORD        Magic number (always 0xF1FA)
	# WORD        Old field which specifies the number of "chunks" in this frame. If this value is 0xFFFF, we might have more chunks to read in this frame (so we have to use the new field)
	# WORD        Frame duration (in milliseconds)
	# BYTE[2]     For future (set to zero)
	# DWORD       New field which specifies the number of "chunks" in this frame (if this is 0, use the old field)
	func read_frame() -> AsepriteFile.Frame:
		var frame := AsepriteFile.Frame.new()

		frame.frame_size = get_dword()
		frame.magic_number = get_word()

		# Do not read past the magic number if it's invalid
		if frame.magic_number != AsepriteFile.Frame.MAGIC_NUMBER:
			# push_warning("Aseprite - Invalid frame magic number")
			return frame

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
	func read_layer_chunk(chunk_header: ChunkHeader) -> AsepriteFile.Layer:
		var layer := AsepriteFile.Layer.new()

		layer.chunk_size = chunk_header.size if chunk_header else 0
		layer.chunk_type = chunk_header.type if chunk_header else 0

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
	func read_cel_chunk(chunk_header: ChunkHeader, color_depth: int) -> AsepriteFile.Cel:
		var cel := AsepriteFile.Cel.new()

		cel.chunk_size = chunk_header.size if chunk_header else 0
		cel.chunk_type = chunk_header.type if chunk_header else 0

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
			# cel of type 0 are never compressed
			cel.buffer = read_buffer(cel.chunk_size - 26, 0)

		elif cel.type == 1:
			cel.link = get_word()

		elif cel.type == 2:
			cel.w = get_word()
			cel.h = get_word()
			cel.buffer = read_buffer(cel.chunk_size - 26, cel.w * cel.h * (color_depth / 8))

		elif cel.type == 3:
			cel.w = get_word()
			cel.h = get_word()
			cel.bits_per_tile = get_word()
			cel.bitmask_for_tile_id = get_dword()
			cel.bitmask_for_x_flip = get_dword()
			cel.bitmask_for_y_flip = get_dword()
			cel.bitmask_for_90cw_rotation = get_dword()
			skip(10)
			cel.buffer = read_buffer(cel.chunk_size - 54, cel.w * cel.h * (cel.bits_per_tile / 8))

		return cel

	# 0x2006
	#     DWORD       Flags (set to zero) 1 = Precise bounds are set
	#     FIXED       Precise X position
	#     FIXED       Precise Y position
	#     FIXED       Width of the cel in the sprite (scaled in real-time)
	#     FIXED       Height of the cel in the sprite
	#     BYTE[16]    For future use (set to zero)
	func read_cel_extra_chunk(chunk_header: ChunkHeader) -> AsepriteFile.CelExtra:
		var cel_extra := AsepriteFile.CelExtra.new()

		cel_extra.chunk_size = chunk_header.size if chunk_header else 0
		cel_extra.chunk_type = chunk_header.type if chunk_header else 0

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
	func read_color_profile_chunk(chunk_header: ChunkHeader) -> AsepriteFile.ColorProfile:
		var color_profile := AsepriteFile.ColorProfile.new()

		color_profile.chunk_size = chunk_header.size if chunk_header else 0
		color_profile.chunk_type = chunk_header.type if chunk_header else 0

		color_profile.type = get_word()
		color_profile.flags = get_word()
		color_profile.fixed_gamma = get_fixed()
		skip(8)

		if color_profile.type == 2:
			var icc_data_len := get_dword()
			color_profile.icc_data = read_buffer(icc_data_len, 0)

		return color_profile

	# 0x2008
	# DWORD       Number of entries
	# BYTE[8]     Reserved (set to zero)
	# + For each entry
	#   DWORD     Entry ID (this ID is referenced by tilesets, palettes, or extended properties)
	#   BYTE      Type
	#   BYTE[7]   Reserved (set to zero)
	#   STRING    External file name or extension ID (see NOTE.4)
	func read_external_files_chunk(chunk_header: ChunkHeader) -> AsepriteFile.ExternalFiles:
		var external_files := AsepriteFile.ExternalFiles.new()

		external_files.chunk_size = chunk_header.size if chunk_header else 0
		external_files.chunk_type = chunk_header.type if chunk_header else 0

		external_files.files_count = get_dword()
		skip(8)

		for i in range(external_files.files_count):
			var file := AsepriteFile.ExternalFile.new()

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
	func read_tags_chunk(chunk_header: ChunkHeader) -> AsepriteFile.Tags:
		var tags := AsepriteFile.Tags.new()

		tags.chunk_size = chunk_header.size if chunk_header else 0
		tags.chunk_type = chunk_header.type if chunk_header else 0

		tags.tags_count = get_word()
		skip(8)

		for i in range(tags.tags_count):
			var tag := AsepriteFile.Tag.new()

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
	func read_palette_chunk(chunk_header: ChunkHeader) -> AsepriteFile.Palette:
		var palette := AsepriteFile.Palette.new()

		palette.chunk_size = chunk_header.size if chunk_header else 0
		palette.chunk_type = chunk_header.type if chunk_header else 0

		palette.colors_count = get_dword()
		palette.first_color = get_dword()
		palette.last_color = get_dword()
		skip(8)

		for i in range(palette.colors_count):
			var color := AsepriteFile.PaletteColor.new()

			color.flags = get_word()
			color.red = get_byte()
			color.green = get_byte()
			color.blue = get_byte()
			color.alpha = get_byte()

			if color.flags & PaletteColorFlags.HAS_NAME != 0:
				color.name = get_string()

			palette.colors.append(color)

		return palette

	# 0x2020
	# Specifies the user data (color/text/properties) to be associated with
	# the last read chunk/object. E.g. If the last chunk we've read is a
	# layer and then this chunk appears, this user data belongs to that
	# layer, if we've read a cel, it belongs to that cel, etc. There are
	# some special cases:

	# 1. After a Tags chunk, there will be several user data chunks, one for
	#    each tag, you should associate the user data in the same order as
	#    the tags are in the Tags chunk.
	# 2. After the Tileset chunk, it could be followed by a user data chunk
	#    (empty or not) and then all the user data chunks of the tiles
	#    ordered by tile index, or it could be followed by none user data
	#    chunk (if the file was created in an older Aseprite version of if
	#    no tile has user data).
	# 3. In Aseprite v1.3 a sprite has associated user data, to consider
	#    this case there is an User Data Chunk at the first frame after the
	#    Palette Chunk.

	# The data of this chunk is as follows:

	#     DWORD       Flags
	#                   1 = Has text
	#                   2 = Has color
	#                   4 = Has properties
	#     + If flags have bit 1
	#       STRING    Text
	#     + If flags have bit 2
	#       BYTE      Color Red (0-255)
	#       BYTE      Color Green (0-255)
	#       BYTE      Color Blue (0-255)
	#       BYTE      Color Alpha (0-255)
	#     + If flags have bit 4
	#       DWORD     Size in bytes of all properties maps stored in this chunk
	#                 The size includes the this field and the number of property maps
	#                 (so it will be a value greater or equal to 8 bytes).
	#       DWORD     Number of properties maps
	#       + For each properties map:
	#         DWORD     Properties maps key
	#                   == 0 means user properties
	#                   != 0 means an extension Entry ID (see External Files Chunk))
	#         DWORD     Number of properties
	#         + For each property:
	#           STRING    Name
	#           WORD      Type
	#           + If type==0x0001 (bool)
	#             BYTE    == 0 means FALSE
	#                     != 0 means TRUE
	#           + If type==0x0002 (int8)
	#             BYTE
	#           + If type==0x0003 (uint8)
	#             BYTE
	#           + If type==0x0004 (int16)
	#             SHORT
	#           + If type==0x0005 (uint16)
	#             WORD
	#           + If type==0x0006 (int32)
	#             LONG
	#           + If type==0x0007 (uint32)
	#             DWORD
	#           + If type==0x0008 (int64)
	#             LONG64
	#           + If type==0x0009 (uint64)
	#             QWORD
	#           + If type==0x000A
	#             FIXED
	#           + If type==0x000B
	#             FLOAT
	#           + If type==0x000C
	#             DOUBLE
	#           + If type==0x000D
	#             STRING
	#           + If type==0x000E
	#             POINT
	#           + If type==0x000F
	#             SIZE
	#           + If type==0x0010
	#             RECT
	#           + If type==0x0011 (vector)
	#             DWORD     Number of elements
	#             WORD      Element's type.
	#             + If Element's type == 0 (all elements are not of the same type)
	#               For each element:
	#                 WORD      Element's type
	#                 BYTE[]    Element's value. Structure depends on the
	#                           element's type
	#             + Else (all elements are of the same type)
	#               For each element:
	#                 BYTE[]    Element's value. Structure depends on the
	#                           element's type
	#           + If type==0x0012 (nested properties map)
	#             DWORD     Number of properties
	#             BYTE[]    Nested properties data
	#                       Structure is the same as indicated in this loop
	#           + If type==0x0013
	#             UUID
	func _read_user_data_chunk(chunk_header: ChunkHeader) -> AsepriteFile.UserData:
		var user_data := AsepriteFile.UserData.new()

		user_data.chunk_size = chunk_header.size if chunk_header else 0
		user_data.chunk_type = chunk_header.type if chunk_header else 0

		user_data.flags = get_dword()

		if user_data.flags & 1 != 0:
			user_data.text = get_string()

		if user_data.flags & 2 != 0:
			user_data.color_r = get_byte()
			user_data.color_g = get_byte()
			user_data.color_b = get_byte()
			user_data.color_a = get_byte()

		if user_data.flags & 4 != 0:
			user_data.properties_size = get_dword()
			user_data.properties_maps_count = get_dword()

			for __ in range(user_data.properties_maps_count):
				var properties_map := AsepriteFile.PropertyMap.new()

				user_data.maps.append(properties_map)

				properties_map.key = get_dword()
				properties_map.properties_count = get_dword()

				for ___ in range(properties_map.properties_count):
					var property := AsepriteFile.UserDataProperty.new()

					properties_map.properties.append(property)

					property.name = get_string()
					property.type = get_word()

		return user_data

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
	func read_slice_chunk(chunk_header: ChunkHeader) -> AsepriteFile.Slice:
		var slice := AsepriteFile.Slice.new()

		slice.chunk_size = chunk_header.size if chunk_header else 0
		slice.chunk_type = chunk_header.type if chunk_header else 0

		slice.keys_count = get_dword()
		slice.flags = get_dword()
		skip(4)
		slice.name = get_string()

		for i in range(slice.keys_count):
			var key := AsepriteFile.SliceKey.new()

			key.frame_number = get_dword()
			key.origin_x = get_long()
			key.origin_y = get_long()
			key.width = get_dword()
			key.height = get_dword()

			if slice.flags & SliceFlags.NINE_PATCHES != 0:
				key.center_x = get_long()
				key.center_y = get_long()
				key.center_width = get_dword()
				key.center_height = get_dword()

			if slice.flags & SliceFlags.HAS_PIVOT != 0:
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
	func read_tileset_chunk(chunk_header: ChunkHeader, color_depth: int) -> AsepriteFile.Tileset:
		var tileset := AsepriteFile.Tileset.new()

		tileset.chunk_size = chunk_header.size if chunk_header else 0
		tileset.chunk_type = chunk_header.type if chunk_header else 0

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
			tileset.buffer = read_buffer(data_len, tileset.tile_width * tileset.tile_height * (color_depth / 8) * tileset.tiles_count)

		return tileset

	func read_empty_chunk(chunk_header: ChunkHeader) -> AsepriteFile.UnsupportedChunk:
		var chunk := AsepriteFile.UnsupportedChunk.new()

		chunk.chunk_size = chunk_header.size if chunk_header else 0
		chunk.chunk_type = chunk_header.type if chunk_header else 0

		skip(chunk.chunk_size - 6)

		return chunk

	func read_chunk(header: AsepriteFile) -> AsepriteFile.Chunk:
		var chunk_header := read_chunk_header()
		var color_depth := header.color_depth

		match chunk_header.type:
			ChunkType.LAYER: return read_layer_chunk(chunk_header)
			ChunkType.CEL: return read_cel_chunk(chunk_header, color_depth)
			ChunkType.CEL_EXTRA: return read_cel_extra_chunk(chunk_header)
			ChunkType.COLOR_PROFILE: return read_color_profile_chunk(chunk_header)
			ChunkType.EXTERNAL_FILES: return read_external_files_chunk(chunk_header)
			ChunkType.TAGS: return read_tags_chunk(chunk_header)
			ChunkType.PALETTE: return read_palette_chunk(chunk_header)
			ChunkType.SLICE: return read_slice_chunk(chunk_header)
			ChunkType.TILESET: return read_tileset_chunk(chunk_header, color_depth)
			_: return read_empty_chunk(chunk_header)

	func read_ase() -> AsepriteFile:
		var ase := read_header()

		if ase.magic_number != AsepriteFile.MAGIC_NUMBER:
			return ase

		for __ in range(ase.num_frames):
			var frame := read_frame()

			if frame.magic_number != AsepriteFile.Frame.MAGIC_NUMBER:
				return ase

			ase.frames.append(frame)

			for ___ in range(frame.get_chunks_count()):
				frame.chunks.append(read_chunk(ase))

		for frame in ase.frames:
			for chunk in frame.chunks:
				if chunk is AsepriteFile.Layer: ase.layers.append(chunk)
				elif chunk is AsepriteFile.Cel: frame.cels.append(chunk)
				elif chunk is AsepriteFile.CelExtra: frame.cels[frame.cels.size() - 1].extra = chunk
				elif chunk is AsepriteFile.ExternalFiles: ase.external_files = chunk.files
				elif chunk is AsepriteFile.ColorProfile: ase.color_profile = chunk
				elif chunk is AsepriteFile.Tags: ase.tags.append(chunk)
				elif chunk is AsepriteFile.Palette: ase.palette = chunk
				elif chunk is AsepriteFile.Tileset: ase.tilesets.append(chunk)

		ase.frames.make_read_only()
		ase.layers.make_read_only()
		ase.tilesets.make_read_only()
		ase.tags.make_read_only()
		ase.external_files.make_read_only()

		for frame in ase.frames:
			frame.chunks.make_read_only()
			frame.cels.make_read_only()

		return ase


	## Represent a chunk header
	## DWORD       Chunk size
	## WORD        Chunk type
	class ChunkHeader extends RefCounted:
		var size: int = 0
		var type: int = 0
