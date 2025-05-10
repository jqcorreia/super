package canvas

import "../../platform"
import fonts "../../vendor/libschrift-odin/sft"
import "core:fmt"
import "core:os"
import "core:time"
import gl "vendor:OpenGL"


RenderedGlyph :: struct {
	metrics: ^fonts.SFT_GMetrics,
	image:   fonts.SFT_Image,
	kerning: ^fonts.SFT_Kerning,
}

draw_text_raw :: proc(
	resolution: [2]f32,
	x: f32,
	y: f32,
	text: string,
	font: ^platform.Font,
	_shader: u32 = 0,
) -> f32 {
	shader := _shader == 0 ? platform.inst().shaders->get("Text") : _shader

	current_x := f32(x)
	buffers: [dynamic]RenderedGlyph

	previous_glyph: fonts.SFT_Glyph = 0

	lmetrics: fonts.SFT_LMetrics
	fonts.lmetrics(font, &lmetrics)

	total_line_height := f32(lmetrics.ascender + lmetrics.lineGap)

	for c in text {
		glyph := new(fonts.SFT_Glyph)
		metrics := new(fonts.SFT_GMetrics)

		fonts.lookup(font, u8(c), glyph)
		fonts.gmetrics(font, glyph^, metrics)

		image := fonts.SFT_Image {
			width  = (metrics.minWidth + 3) & ~i32(3),
			height = metrics.minHeight,
		}
		gp := make([]u8, image.width * image.height)
		image.pixels = raw_data(gp)
		fonts.render(font, glyph^, image)

		kerning := new(fonts.SFT_Kerning)
		if previous_glyph != 0 {
			fonts.kerning(font, previous_glyph, glyph^, kerning)
			previous_glyph = glyph^
		} else {
			previous_glyph = glyph^
		}

		append(&buffers, RenderedGlyph{metrics = metrics, image = image, kerning = kerning})
	}

	for rg in buffers {
		metrics := rg.metrics
		image := rg.image
		gp := image.pixels

		tex: u32
		gl.GenTextures(1, &tex)
		gl.ActiveTexture(gl.TEXTURE0)
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
			gp,
		)

		gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.NEAREST)
		gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.NEAREST)

		gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_SWIZZLE_R, gl.RED)
		gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_SWIZZLE_G, gl.RED)
		gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_SWIZZLE_B, gl.RED)
		gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_SWIZZLE_A, gl.RED)

		gl.Enable(gl.BLEND)
		gl.BlendFunc(gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA)

		draw_rect_raw(
			resolution,
			f32(f32(current_x) + f32(metrics.leftSideBearing)) + f32(rg.kerning.xShift),
			f32(f32(y) + total_line_height + f32(metrics.yOffset)),
			f32(image.width),
			f32(image.height),
			shader = platform.inst().shaders->get("Text"),
			texture = tex,
		)

		gl.Disable(gl.BLEND)

		current_x += f32(metrics.advanceWidth)
	}

	return total_line_height
}

draw_text :: proc(
	canvas: ^Canvas,
	x: f32,
	y: f32,
	text: string,
	font: ^platform.Font,
	_shader: u32 = 0,
) -> f32 {
	return draw_text_raw({f32(canvas.width), f32(canvas.height)}, x, y, text, font, _shader)
}
