package fonts

import "../../vendor/libschrift-odin/sft"
import "core:log"
import "core:os/os2"
import "core:strings"

import gl "vendor:OpenGL"

Font :: struct {
	_font:        sft.SFT,
	cache:        map[u8]RenderedGlyph,
	line_metrics: ^FontLineMetrics,
	line_height:  f32,
	render_glyph: proc(font: ^Font, char: u8, previous_glyph: ^RenderedGlyph) -> RenderedGlyph,
}

FontLineMetrics :: sft.SFT_LMetrics

RenderedGlyph :: struct {
	metrics: ^sft.SFT_GMetrics,
	image:   sft.SFT_Image,
	kerning: ^sft.SFT_Kerning,
	glyph:   ^sft.SFT_Glyph,
	tex:     u32,
}

FontManager :: struct {
	font_map:     map[string]string,
	loaded_fonts: map[string]Font,
}


new_font_manager :: proc() -> FontManager {
	loaded_fonts := make(map[string]Font)
	font_map := get_font_map()

	fm: FontManager

	fm.font_map = font_map
	fm.loaded_fonts = loaded_fonts

	return fm
}


load_font_buffer :: proc(
	fm: ^FontManager,
	name: string,
	buffer: []u8,
	buf_size: u64,
	size: f64,
) -> Font {
	font := sft.loadmem(raw_data(buffer), uint(buf_size))

	sft_obj: sft.SFT
	sft_obj.font = font
	sft_obj.xScale = size
	sft_obj.yScale = size
	sft_obj.xOffset = 0.0
	sft_obj.yOffset = 0.0
	sft_obj.flags = sft.SFT_DOWNWARD_Y

	// Calculate line metrics
	lmetrics := new(sft.SFT_LMetrics)
	sft.lmetrics(&sft_obj, lmetrics)

	_font := Font {
		_font        = sft_obj,
		cache        = make(map[u8]RenderedGlyph),
		line_metrics = lmetrics,
		render_glyph = render_glyph,
		line_height  = f32(lmetrics.ascender + lmetrics.lineGap),
	}

	fm.loaded_fonts[name] = _font

	log.info(
		"Font metrics:",
		_font.line_metrics.ascender,
		_font.line_metrics.descender,
		_font.line_metrics.lineGap,
	)

	return _font
}

FontBuffer :: struct {
	buffer:   []u8,
	buf_size: u64,
}

load_font :: proc(fm: ^FontManager, name: string, size: f64, buffer := FontBuffer{}) -> Font {
	// Check if the font is already loaded
	if loaded_font, ok := fm.loaded_fonts[name]; ok {
		return loaded_font
	}

	font: ^sft.SFT_Font
	if buffer.buf_size == 0 {
		font_file := fm.font_map[name]
		log.info("Loading new font from file:", name, font_file)
		font = sft.loadfile(strings.clone_to_cstring(fm.font_map[name]))
	} else {
		log.info("Loading new font from mem:", name)
		font = sft.loadmem(raw_data(buffer.buffer), uint(buffer.buf_size))
	}
	if (font == nil) {
		panic("Failed to load font")
	}

	sft_obj: sft.SFT
	sft_obj.font = font
	sft_obj.xScale = size
	sft_obj.yScale = size
	sft_obj.xOffset = 0.0
	sft_obj.yOffset = 0.0
	sft_obj.flags = sft.SFT_DOWNWARD_Y

	// Calculate line metrics
	lmetrics := new(sft.SFT_LMetrics)
	sft.lmetrics(&sft_obj, lmetrics)

	_font := Font {
		_font        = sft_obj,
		cache        = make(map[u8]RenderedGlyph),
		line_metrics = lmetrics,
		render_glyph = render_glyph,
		line_height  = f32(lmetrics.ascender + lmetrics.lineGap),
	}

	fm.loaded_fonts[name] = _font

	log.info(
		"Font metrics:",
		_font.line_metrics.ascender,
		_font.line_metrics.descender,
		_font.line_metrics.lineGap,
	)

	return _font
}

@(private)
get_font_map :: proc() -> map[string]string {
	fonts := make(map[string]string)

	_, out, _, _ := os2.process_exec({command = {"fc-list"}}, context.allocator)

	for line in strings.split(string(out), "\n") {
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

render_glyph :: proc(font: ^Font, char: u8, previous_glyph: ^RenderedGlyph) -> RenderedGlyph {
	rg, ok := font.cache[char]

	if ok {
		return rg
	}

	glyph := new(sft.SFT_Glyph)
	metrics := new(sft.SFT_GMetrics)

	sft.lookup(&font._font, char, glyph)
	sft.gmetrics(&font._font, glyph^, metrics)

	image := sft.SFT_Image {
		width  = (metrics.minWidth + 3) & ~i32(3),
		height = metrics.minHeight,
	}
	gp := make([]u8, image.width * image.height)
	image.pixels = raw_data(gp)
	sft.render(&font._font, glyph^, image)

	kerning := new(sft.SFT_Kerning)
	if previous_glyph != nil {
		sft.kerning(&font._font, previous_glyph.glyph^, glyph^, kerning)
	}

	// Generate texture to cache
	tex: u32
	gl.GenTextures(1, &tex)
	gl.BindTexture(gl.TEXTURE_2D, tex)

	gl.TexImage2D(
		gl.TEXTURE_2D,
		0,
		gl.RED,
		image.width,
		image.height,
		0,
		gl.RED,
		gl.UNSIGNED_BYTE,
		raw_data(gp),
	)

	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.NEAREST)
	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.NEAREST)

	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_SWIZZLE_R, gl.RED)
	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_SWIZZLE_G, gl.RED)
	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_SWIZZLE_B, gl.RED)
	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_SWIZZLE_A, gl.RED)

	rg = RenderedGlyph {
		metrics = metrics,
		image   = image,
		kerning = kerning,
		glyph   = glyph,
		tex     = tex,
	}

	// Cache the result and return it
	font.cache[char] = rg
	return rg
}
