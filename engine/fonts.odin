package engine

import "core:c"
import "core:strings"

foreign import sft "system:libschrift.a"


@(default_calling_convention = "c", link_prefix = "sft_")
foreign sft {
	loadfile :: proc(filename: cstring) -> ^SFT_Font ---
	lookup :: proc(font: ^SFT, ch: c.char, glyph: ^SFT_Glyph) ---
	gmetrics :: proc(glyph: SFT_Glyph, metrics: ^SFT_GMetrics) ---
}

// struct SFT
// {
// 	SFT_Font *font;
// 	double    xScale;
// 	double    yScale;
// 	double    xOffset;
// 	double    yOffset;
// 	int       flags;
// };

// struct SFT_Font
// {
// 	const uint8_t *memory;
// 	uint_fast32_t  size;
// #if defined(_WIN32)
// 	HANDLE         mapping;
// #endif
// 	int            source;

// 	uint_least16_t unitsPerEm;
// 	int_least16_t  locaFormat;
// 	uint_least16_t numLongHmtx;
// };

SFT :: struct {
	font:    ^SFT_Font,
	xScale:  c.double,
	yScale:  c.double,
	xOffset: c.double,
	yOffset: c.double,
	flags:   c.int,
}

SFT_Font :: struct {
}
SFT_Glyph :: struct {
}
SFT_GMetrics :: struct {
}

SFT_DOWNWARD_Y :: 0x01

load_font :: proc(filename: string, size: f64) -> SFT {
	font: ^SFT_Font
	font = loadfile(strings.clone_to_cstring(filename))
	if (font == nil) {
		panic("Failed to load font")
	}
	sft: SFT
	sft.font = font
	sft.xScale = size
	sft.yScale = size
	sft.xOffset = 0.0
	sft.yOffset = 0.0
	sft.flags = SFT_DOWNWARD_Y

	return sft
}
