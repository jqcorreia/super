package fonts

import "core:c"

foreign import sft "system:libschrift.a"


@(default_calling_convention = "c", link_prefix = "sft_")
foreign sft {
	loadfile :: proc(filename: cstring) -> ^SFT_Font ---
	lookup :: proc(font: ^SFT, ch: c.char, glyph: ^SFT_Glyph) ---
	gmetrics :: proc(font: ^SFT, glyph: SFT_Glyph, metrics: ^SFT_GMetrics) ---
	render :: proc(font: ^SFT, glyph: SFT_Glyph, image: SFT_Image) ---
}

SFT :: struct {
	font:    ^SFT_Font,
	xScale:  c.double,
	yScale:  c.double,
	xOffset: c.double,
	yOffset: c.double,
	flags:   c.int,
}

SFT_Font :: struct {} // Opaque struct


SFT_Glyph :: c.uint32_t

SFT_GMetrics :: struct {
	advanceWidth:    c.double,
	leftSideBearing: c.double,
	yOffset:         c.int,
	minWidth:        c.int,
	minHeight:       c.int,
}

SFT_Image :: struct {
	pixels: rawptr,
	width:  c.int,
	height: c.int,
}

SFT_DOWNWARD_Y :: 0x01
