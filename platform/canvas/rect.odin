package canvas

import "core:fmt"
import "core:time"
import gl "vendor:OpenGL"

import "../../platform"
import "../../types"
import "../../utils/gmath"


draw_rect :: proc(
	canvas: ^Canvas,
	x, y, width, height: f32,
	color: types.Color,
	shader: u32 = 0,
	texture: u32 = 0,
) {
	_shader := (shader == 0 ? platform.inst().shaders->get("Basic") : shader)
	fmt.println(_shader)
	// _shader: u32
	// if (shader == 0) {
	// 	if (texture == 0) {
	// 		_shader = platform.inst().shaders->get("Basic")
	// 	} else {
	// 		_shader = platform.inst().shaders->get("Basic")
	// 		fmt.println(_shader)
	// 	}
	// } else {
	// 	_shader = shader
	// }

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

	gl.EnableVertexAttribArray(0)
	gl.VertexAttribPointer(0, 2, gl.FLOAT, gl.FALSE, 4 * size_of(f32), 0)

	gl.VertexAttribPointer(1, 2, gl.FLOAT, gl.FALSE, 4 * size_of(f32), 2 * size_of(f32))
	gl.EnableVertexAttribArray(1)

	gl.UseProgram(shader)

	// draw stuff
	_color := color

	projectionMatrix := gmath.ortho(0, f32(canvas.width), f32(canvas.height), 0)
	gl.Uniform1fv(
		gl.GetUniformLocation(_shader, cstring("iTime")),
		1,
		raw_data([]f32{f32(time.duration_seconds(platform.inst().time_elapsed))}),
	)
	gl.Uniform4fv(gl.GetUniformLocation(_shader, cstring("input")), 1, raw_data(&_color))
	gl.Uniform2fv(gl.GetUniformLocation(_shader, cstring("position")), 1, raw_data([]f32{x, y}))
	gl.Uniform2fv(
		gl.GetUniformLocation(_shader, cstring("resolution")),
		1,
		raw_data([]f32{width, height}),
	)
	gl.Uniform2fv(
		gl.GetUniformLocation(_shader, cstring("size")),
		1,
		raw_data([]f32{width, height}),
	)
	gl.UniformMatrix4fv(
		gl.GetUniformLocation(_shader, cstring("projection")),
		1,
		false,
		raw_data(&projectionMatrix),
	)
	// if (texture != 0) {
	// 	gl.ActiveTexture(gl.TEXTURE0)
	// 	gl.BindTexture(gl.TEXTURE_2D, texture)
	// 	gl.Uniform1i(gl.GetUniformLocation(shader, cstring("uTexture")), 0)
	// }

	gl.BindVertexArray(vao)
	gl.DrawArrays(gl.TRIANGLE_FAN, 0, 4)

	gl.BindVertexArray(0)
	gl.BindBuffer(gl.ARRAY_BUFFER, 0)
	gl.DeleteBuffers(1, &vbo)
	gl.DeleteVertexArrays(1, &vao)
}
