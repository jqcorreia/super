package main

import "core:fmt"
import "core:os"
import "core:strings"
import "sft"


load_font :: proc(filename: string, size: f64) -> sft.SFT {
	font: ^sft.SFT_Font
	font = sft.loadfile(strings.clone_to_cstring(filename))
	if (font == nil) {
		panic("Failed to load font")
	}

	s: sft.SFT
	s.font = font
	s.xScale = size
	s.yScale = size
	s.xOffset = 0.0
	s.yOffset = 0.0
	s.flags = sft.SFT_DOWNWARD_Y


	return s
}

CHAR :: 'A'

// First arg must be a valid .ttf file path
main :: proc() {
	font := load_font(os.args[1], 36)

	glyph := new(sft.SFT_Glyph)
	metrics := new(sft.SFT_GMetrics)

	sft.lookup(&font, u8(CHAR), glyph)
	sft.gmetrics(&font, glyph^, metrics)

	image := sft.SFT_Image {
		width  = (metrics.minWidth + 3) & ~i32(3), // Round to 4-bytes
		height = metrics.minHeight,
	}
	gp := make([]u8, image.width * image.height)
	image.pixels = raw_data(gp)
	sft.render(&font, glyph^, image)

	// gp will hold the buffer with alpha values for the rendered 'Z' char
	for y in 0 ..< image.height {

		for x in 0 ..< image.width {
			val := gp[y * image.width + x]

			fmt.print(val > 0 ? "1 " : "0 ")
		}
		fmt.println()
	}
}
