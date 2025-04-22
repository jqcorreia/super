package platform

import fonts "../vendor/libschrift-odin/sft"
import "core:c"
import "core:fmt"
import "core:os/os2"
import "core:strings"

FontManager :: struct {
	font_map:     map[string]string,
	loaded_fonts: map[string]fonts.SFT,
	load_font:    proc(fm: ^FontManager, filename: string, size: f64) -> fonts.SFT,
}

new_font_manager :: proc() -> FontManager {
	loaded_fonts := make(map[string]fonts.SFT)
	font_map := get_font_map()

	fm: FontManager

	fm.font_map = font_map
	fm.loaded_fonts = loaded_fonts
	fm.load_font = load_font

	return fm
}

load_font :: proc(fm: ^FontManager, name: string, size: f64) -> fonts.SFT {
	// Check if the font is already loaded
	if _sft, ok := fm.loaded_fonts[name]; ok {
		fmt.println("Font already loaded:", name)
		return _sft
	}

	fmt.println("Loading new font:", name)
	font: ^fonts.SFT_Font
	font = fonts.loadfile(strings.clone_to_cstring(fm.font_map[name]))
	if (font == nil) {
		panic("Failed to load font")
	}

	sft: fonts.SFT
	sft.font = font
	sft.xScale = size
	sft.yScale = size
	sft.xOffset = 0.0
	sft.yOffset = 0.0
	sft.flags = fonts.SFT_DOWNWARD_Y

	fm.loaded_fonts[name] = sft

	lmetrics := new(fonts.SFT_LMetrics)
	fonts.lmetrics(&sft, lmetrics)
	fmt.println("Font metrics:", lmetrics.ascender, lmetrics.descender, lmetrics.lineGap)
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
