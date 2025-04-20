package platform

import "./fonts"
import "core:c"
import "core:fmt"
import "core:strings"

FontManager :: struct {
	font_map:     map[string]string,
	loaded_fonts: map[string]fonts.SFT,
	load_font:    proc(fm: ^FontManager, filename: string, size: f64) -> fonts.SFT,
}

new_font_manager :: proc() -> FontManager {
	loaded_fonts := make(map[string]fonts.SFT)
	when ODIN_OS == .JS {
		// In WebAssembly, we can't use fc-list directly.
		// Instead, we can use a hardcoded font map or a different method to get the font paths.
		// For now, let's just create an empty map.
		font_map := make(map[string]string)
	} else {
		font_map := get_font_map()
	}


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
	sft: fonts.SFT = load_font_from_file(fm, fm.font_map[name], size)

	fm.loaded_fonts[name] = sft

	return sft
}

load_font_from_file :: proc(fm: ^FontManager, filename: string, size: f64) -> fonts.SFT {
	font: ^fonts.SFT_Font
	font = fonts.loadfile(strings.clone_to_cstring(filename))
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

	return sft
}
