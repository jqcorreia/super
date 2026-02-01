package platform

import fonts "./fonts"

draw_text_raw :: proc(
	resolution: [2]f32,
	x: f32,
	y: f32,
	text: string,
	font: ^fonts.Font,
	color: Color = {1, 1, 1, 1},
	_shader: ^Shader = nil,
) -> (
	f32,
	f32,
) {
	shader := _shader == nil ? get_shader("Text") : _shader

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
			{shader = shader, texture = tex, color = color},
		)


		current_x += f32(metrics.advanceWidth)
	}

	return current_x - x, total_line_height // current_x - x is equal to total_line_width
}

text_size :: proc(text: string, font: ^fonts.Font) -> (f32, f32) {
	w: f32 = 0
	h: f32 = font.line_height

	buffers: [dynamic]fonts.RenderedGlyph
	previous_glyph: ^fonts.RenderedGlyph = nil

	for c in text {
		rg := font->render_glyph(u8(c), previous_glyph)
		previous_glyph = &rg

		append(&buffers, rg)
	}

	for rg in buffers {
		metrics := rg.metrics
		w += f32(metrics.advanceWidth)
	}

	return w, h
}

text_size_u32 :: proc(text: string, font: ^fonts.Font) -> (u32, u32) {
	w: f32 = 0
	h: f32 = font.line_height

	buffers: [dynamic]fonts.RenderedGlyph
	previous_glyph: ^fonts.RenderedGlyph = nil

	for c in text {
		rg := font->render_glyph(u8(c), previous_glyph)
		previous_glyph = &rg

		append(&buffers, rg)
	}

	for rg in buffers {
		metrics := rg.metrics
		w += f32(metrics.advanceWidth)
	}

	return u32(w), u32(h)
}

draw_text_canvas :: proc(
	canvas: ^Canvas,
	x: f32,
	y: f32,
	text: string,
	font: ^fonts.Font,
	_shader: ^Shader = nil,
	color: Color = {1.0, 1.0, 1.0, 1.0},
) -> (
	f32,
	f32,
) {
	return draw_text_raw({f32(canvas.width), f32(canvas.height)}, x, y, text, font, color, _shader)
}

draw_text :: proc {
	draw_text_canvas,
	draw_text_raw,
}
