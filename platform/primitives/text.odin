package primitives

import "../../engine/"
import "core:fmt"
import "core:os"
import "core:time"
import gl "vendor:OpenGL"

import "../../platform"

draw_text :: proc(text: string, x: u32, y: u32, font: ^platform.SFT, shader: u32) {
	current_x := f32(x)

	for c in text {
		glyph := new(platform.SFT_Glyph)
		metrics := new(platform.SFT_GMetrics)

		platform.lookup(font, u8(c), glyph)
		platform.gmetrics(font, glyph^, metrics)

		// gp := make([]u8, metrics.minWidth * metrics.minHeight)

		image := platform.SFT_Image {
			width  = (metrics.minWidth + 3) & ~i32(3),
			height = metrics.minHeight,
		}
		gp := make([]u8, image.width * image.height)
		image.pixels = raw_data(gp)
		platform.render(font, glyph^, image)

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
			raw_data(gp),
		)

		gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.NEAREST)
		gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.NEAREST)

		gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_SWIZZLE_R, gl.RED)
		gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_SWIZZLE_G, gl.RED)
		gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_SWIZZLE_B, gl.RED)
		gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_SWIZZLE_A, gl.RED)

		vertices := [?]f32 {
			f32(0),
			f32(0),
			f32(0),
			f32(0),
			f32(1),
			f32(0),
			f32(1),
			f32(0),
			f32(1),
			f32(1),
			f32(1),
			f32(1),
			f32(0),
			f32(1),
			f32(0),
			f32(1),
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
			raw_data([]f32{f32(current_x), f32(f32(y) + f32(metrics.yOffset))}),
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
