package fonts

import fonts "../../vendor/libschrift-odin/sft"
import "core:c"
import "core:fmt"
import "core:os/os2"
import "core:strings"

Font :: fonts.SFT

FontManager :: struct {
	font_map:     map[string]string,
	font_atlas:   map[string]map[u8]RenderedGlyph,
	loaded_fonts: map[string]Font,
	load_font:    proc(fm: ^FontManager, filename: string, size: f64) -> fonts.SFT,
	render_glyph: proc(
		fm: ^FontManager,
		char: u8,
		font_name: string,
		previous_glyph: ^RenderedGlyph = nil,
	) -> RenderedGlyph,
}

RenderedGlyph :: struct {
	metrics: ^fonts.SFT_GMetrics,
	image:   fonts.SFT_Image,
	kerning: ^fonts.SFT_Kerning,
	glyph:   ^fonts.SFT_Glyph,
}

new_font_manager :: proc() -> FontManager {
	loaded_fonts := make(map[string]Font)
	font_atlas := make(map[string]map[string]RenderedGlyph)
	font_map := get_font_map()

	fm: FontManager

	fm.font_map = font_map
	fm.loaded_fonts = loaded_fonts
	fm.load_font = load_font
	fm.render_glyph = render_glyph

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

render_glyph :: proc(
	fm: ^FontManager,
	char: u8,
	font_name: string,
	previous_glyph: ^RenderedGlyph,
) -> RenderedGlyph {
	font := &fm.loaded_fonts[font_name]
	rg, ok := fm.font_atlas[font_name][char]

	if ok {
		return rg
	}
	glyph := new(fonts.SFT_Glyph)
	metrics := new(fonts.SFT_GMetrics)

	fonts.lookup(font, char, glyph)
	fonts.gmetrics(font, glyph^, metrics)

	image := fonts.SFT_Image {
		width  = (metrics.minWidth + 3) & ~i32(3),
		height = metrics.minHeight,
	}
	gp := make([]u8, image.width * image.height)
	image.pixels = raw_data(gp)
	fonts.render(font, glyph^, image)

	kerning := new(fonts.SFT_Kerning)
	if previous_glyph != nil {
		fonts.kerning(font, previous_glyph.glyph^, glyph^, kerning)
	}

	return RenderedGlyph{metrics = metrics, image = image, kerning = kerning, glyph = glyph}
}
