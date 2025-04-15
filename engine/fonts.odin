package engine

import "core:c"
import "core:fmt"
import "core:os/os2"
import "core:strings"

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


FontManager :: struct {
	font_map:     map[string]string,
	loaded_fonts: map[string]SFT,
	load_font:    proc(fm: ^FontManager, filename: string, size: f64) -> SFT,
}

new_font_manager :: proc() -> FontManager {
	loaded_fonts := make(map[string]SFT)
	font_map := get_font_map()

	fm: FontManager

	fm.font_map = font_map
	fm.loaded_fonts = loaded_fonts
	fm.load_font = load_font

	return fm
}

load_font :: proc(fm: ^FontManager, name: string, size: f64) -> SFT {
	// Check if the font is already loaded
	if _sft, ok := fm.loaded_fonts[name]; ok {
		fmt.println("Font already loaded:", name)
		return _sft
	}

	fmt.println("Loading new font:", name)
	font: ^SFT_Font
	font = loadfile(strings.clone_to_cstring(fm.font_map[name]))
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

	fm.loaded_fonts[name] = sft

	return sft
}

get_font_map :: proc() -> map[string]string {
	fonts := make(map[string]string)

	_, out, _, _ := os2.process_exec({command = {"fc-list"}}, context.allocator)

	for line, i in strings.split(string(out), "\n") {
		if !strings.contains(line, "style=Regular") {
			continue
		}

		split := strings.split(line, ":")
		path := split[0]

		// Guard against odd lines
		if len(split) < 2 {
			continue
		}

		family_names := split[1]
		for fname in strings.split(family_names, ",") {
			fonts[strings.trim_left(fname, " ")] = path
		}
	}

	return fonts
}
