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

draw_text :: proc(canvas: ^Canvas, x: f32, y: f32, text: string, font: ^fonts.SFT, shader: u32) {
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

		vertices := [?]f32 {
			0.0,
			0.0,
			0.0,
			0.0,
			1.0,
			0.0,
			1.0,
			0.0,
			1.0,
			1.0,
			1.0,
			1.0,
			0.0,
			1.0,
			0.0,
			1.0,
		}

		vao: u32
		gl.GenVertexArrays(1, &vao)
		gl.BindVertexArray(vao)

		vbo: u32
		gl.GenBuffers(1, &vbo)
		gl.BindBuffer(gl.ARRAY_BUFFER, vbo)
		gl.BufferData(gl.ARRAY_BUFFER, size_of(vertices), &vertices[0], gl.STATIC_DRAW)

		gl.VertexAttribPointer(0, 2, gl.FLOAT, gl.FALSE, 4 * size_of(f32), 0)
		gl.EnableVertexAttribArray(0)

		gl.VertexAttribPointer(1, 2, gl.FLOAT, gl.FALSE, 4 * size_of(f32), 2 * size_of(f32))
		gl.EnableVertexAttribArray(1)

		gl.UseProgram(shader)


		gl.Uniform2fv(
			gl.GetUniformLocation(shader, cstring("position")),
			1,
			raw_data(
				[]f32 {
					f32(f32(current_x) + f32(metrics.leftSideBearing)) + f32(rg.kerning.xShift),
					f32(f32(y) + total_line_height + f32(metrics.yOffset)),
				},
			),
		)
		gl.Uniform2fv(
			gl.GetUniformLocation(shader, cstring("size")),
			1,
			raw_data([]f32{f32(image.width), f32(image.height)}),
		)

		projectionMatrix := ortho(0, 800, 600, 0)

		gl.UniformMatrix4fv(
			gl.GetUniformLocation(shader, cstring("projection")),
			1,
			false,
			raw_data(&projectionMatrix),
		)

		// gl.ActiveTexture(gl.TEXTURE0)
		// gl.BindTexture(gl.TEXTURE_2D, tex)

		gl.Uniform1i(gl.GetUniformLocation(shader, cstring("fontTexture")), 0)
		gl.BindVertexArray(vao)
		gl.Enable(gl.BLEND)
		gl.BlendFunc(gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA)
		gl.DrawArrays(gl.TRIANGLE_FAN, 0, 4)

		gl.BindVertexArray(0)
		gl.BindBuffer(gl.ARRAY_BUFFER, 0)
		gl.DeleteBuffers(1, &vbo)
		gl.DeleteVertexArrays(1, &vao)

		current_x += f32(metrics.advanceWidth)
	}
}
