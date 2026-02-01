package sft

import "core:c"

foreign import sft "system:libschrift.a"


@(default_calling_convention = "c", link_prefix = "sft_")
foreign sft {
	loadfile :: proc(filename: cstring) -> ^SFT_Font ---
	loadmem :: proc(mem: rawptr, size: c.size_t) -> ^SFT_Font ---
	lookup :: proc(font: ^SFT, ch: c.char, glyph: ^SFT_Glyph) ---
	gmetrics :: proc(font: ^SFT, glyph: SFT_Glyph, metrics: ^SFT_GMetrics) ---
	render :: proc(font: ^SFT, glyph: SFT_Glyph, image: SFT_Image) ---
	lmetrics :: proc(font: ^SFT, metrics: ^SFT_LMetrics) ---
	kerning :: proc(font: ^SFT, leftGlyph: SFT_Glyph, rightGlyph: SFT_Glyph, kerning: ^SFT_Kerning) ---
}

SFT :: struct {
	font:    ^SFT_Font,
	xScale:  c.double,
	yScale:  c.double,
	xOffset: c.double,
	yOffset: c.double,
	flags:   c.int,
}

SFT_Font :: struct {
} // Opaque struct


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

SFT_LMetrics :: struct {
	ascender:  c.double,
	descender: c.double,
	lineGap:   c.double,
}
SFT_Kerning :: struct {
	xShift: c.double,
	yShift: c.double,
}
