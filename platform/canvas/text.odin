package canvas

import "../../platform"
import fonts "../../platform/fonts"
import "core:fmt"
import "core:os"
import "core:time"
import gl "vendor:OpenGL"


draw_text_raw :: proc(
	resolution: [2]f32,
	x: f32,
	y: f32,
	text: string,
	font: ^fonts.Font,
	_shader: u32 = 0,
) -> f32 {
	shader := _shader == 0 ? platform.inst().shaders->get("Text") : _shader

	current_x := x
	buffers: [dynamic]fonts.RenderedGlyph

	previous_glyph: ^fonts.RenderedGlyph = nil

	total_line_height := f32(font.line_metrics.ascender + font.line_metrics.lineGap)

	for c in text {
		rg := font->render_glyph(u8(c), previous_glyph)
		previous_glyph = &rg

		append(&buffers, rg)
	}

	for rg in buffers {
		metrics := rg.metrics
		image := rg.image
		gp := image.pixels

		tex := rg.tex

		gl.Enable(gl.BLEND)
		gl.BlendFunc(gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA)

		draw_rect_raw(
			resolution,
			current_x + f32(metrics.leftSideBearing) + f32(rg.kerning.xShift),
			y + total_line_height + f32(metrics.yOffset),
			f32(image.width),
			f32(image.height),
			shader = platform.inst().shaders->get("Text"),
			texture = tex,
		)

		gl.Disable(gl.BLEND)

		current_x += f32(metrics.advanceWidth)
	}

	return total_line_height
	// return 100
}

draw_text :: proc(
	canvas: ^Canvas,
	x: f32,
	y: f32,
	text: string,
	font: ^fonts.Font,
	_shader: u32 = 0,
) -> f32 {
	return draw_text_raw({f32(canvas.width), f32(canvas.height)}, x, y, text, font, _shader)
}
