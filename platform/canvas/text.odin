package canvas

import "../../platform"
import fonts "../../platform/fonts"


draw_text_raw :: proc(
	resolution: [2]f32,
	x: f32,
	y: f32,
	text: string,
	font: ^fonts.Font,
	_shader: u32 = 0,
) -> (
	f32,
	f32,
) {
	shader := _shader == 0 ? platform.get_shader("Text") : _shader

	current_x := x
	buffers: [dynamic]fonts.RenderedGlyph

	previous_glyph: ^fonts.RenderedGlyph = nil

	total_line_height := font.line_height

	for c in text {
		rg := font->render_glyph(u8(c), previous_glyph)
		previous_glyph = &rg

		append(&buffers, rg)
	}

	for rg in buffers {
		metrics := rg.metrics
		image := rg.image

		tex := rg.tex

		draw_rect_raw(
			resolution,
			current_x + f32(metrics.leftSideBearing) + f32(rg.kerning.xShift),
			y + total_line_height + f32(metrics.yOffset),
			f32(image.width),
			f32(image.height),
			{shader = shader, texture = tex},
		)


		current_x += f32(metrics.advanceWidth)
	}

	return current_x, total_line_height
}

draw_text_canvas :: proc(
	canvas: ^Canvas,
	x: f32,
	y: f32,
	text: string,
	font: ^fonts.Font,
	_shader: u32 = 0,
) -> (
	f32,
	f32,
) {
	return draw_text_raw({f32(canvas.width), f32(canvas.height)}, x, y, text, font, _shader)
}

draw_text :: proc {
	draw_text_canvas,
	draw_text_raw,
}
