package canvas

import "core:fmt"
import "core:time"
import gl "vendor:OpenGL"

import "../../platform"
import "../../types"
import "../../utils/gmath"

draw_rect_raw :: proc(
	resolution: [2]f32,
	x, y, w, h: f32,
	vertices: ^[]f32 = nil,
	color: types.Color = {0.0, 0.0, 0.0, 1.0},
	shader: u32 = 0,
	texture: u32 = 0,
) {
	_shader: u32
	if (shader == 0) {
		if (texture == 0) {
			_shader = platform.get_shader("Basic")
		} else {
			_shader = platform.get_shader("Texture")
		}
	} else {
		_shader = shader
	}

	quad, vbo := get_quad(vertices)
	defer gl.DeleteBuffers(1, &vbo)
	defer gl.DeleteVertexArrays(1, &quad)

	gl.UseProgram(_shader)

	// draw stuff
	_color := color
	_resolution := resolution

	projectionMatrix := gmath.ortho(0, resolution[0], resolution[1], 0)
	gl.Uniform1fv(
		gl.GetUniformLocation(_shader, cstring("iTime")),
		1,
		raw_data([]f32{f32(time.duration_seconds(platform.inst().time_elapsed))}),
	)
	gl.Uniform4fv(gl.GetUniformLocation(_shader, cstring("input")), 1, raw_data(&_color))
	gl.Uniform2fv(gl.GetUniformLocation(_shader, cstring("resolution")), 1, raw_data(&_resolution))
	gl.Uniform2fv(gl.GetUniformLocation(_shader, cstring("position")), 1, raw_data([]f32{x, y}))
	gl.Uniform2fv(gl.GetUniformLocation(_shader, cstring("size")), 1, raw_data([]f32{w, h}))
	gl.UniformMatrix4fv(
		gl.GetUniformLocation(_shader, cstring("projection")),
		1,
		false,
		raw_data(&projectionMatrix),
	)
	if (texture != 0) {
		gl.ActiveTexture(gl.TEXTURE0)
		gl.BindTexture(gl.TEXTURE_2D, texture)
		gl.Uniform1i(gl.GetUniformLocation(shader, cstring("uTexture")), 0)
	}

	gl.BindVertexArray(quad)
	gl.DrawArrays(gl.TRIANGLE_FAN, 0, 4)
	gl.BindVertexArray(0)
	gl.BindBuffer(gl.ARRAY_BUFFER, 0)
}

draw_rect :: proc(
	canvas: ^Canvas,
	x, y, width, height: f32,
	vertices: ^[]f32 = nil,
	color: types.Color,
	shader: u32 = 0,
	texture: u32 = 0,
) {
	draw_rect_raw(
		{f32(canvas.width), f32(canvas.height)},
		x,
		y,
		width,
		height,
		vertices,
		color,
		shader,
		texture,
	)
}
