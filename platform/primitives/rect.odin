package primitives

import "../../engine"
import "core:time"
import gl "vendor:OpenGL"

// https://www.songho.ca/opengl/gl_projectionmatrix.html
ortho :: proc(l: f32, r: f32, b: f32, t: f32) -> [16]f32 {
	return [16]f32 {
		2.0 / (r - l),
		0.0,
		0.0,
		0.0,
		0.0,
		2.0 / (t - b),
		0.0,
		0.0,
		0.0,
		0.0,
		-1.0,
		0.0,
		-(r + l) / (r - l),
		-(t + b) / (t - b),
		0.0,
		1.0,
	}
}

draw_rect :: proc(x, y, width, height: f32, shader: u32, state: ^engine.State) {
	vertices := [?]f32{f32(0), f32(0), f32(1), f32(0), f32(1), f32(1), f32(0), f32(1)}

	vao: u32
	gl.GenVertexArrays(1, &vao)
	gl.BindVertexArray(vao)

	vbo: u32
	gl.GenBuffers(1, &vbo)
	gl.BindBuffer(gl.ARRAY_BUFFER, vbo)
	gl.BufferData(gl.ARRAY_BUFFER, size_of(vertices), &vertices[0], gl.STATIC_DRAW)

	gl.EnableVertexAttribArray(0)
	gl.VertexAttribPointer(0, 2, gl.FLOAT, gl.FALSE, 0, 0)

	gl.UseProgram(shader)

	// draw stuff
	color := []f32{1.0, 0.0, 0.0, 1.0}
	projectionMatrix := ortho(0, 800, 600, 0)
	gl.Uniform1fv(
		gl.GetUniformLocation(shader, cstring("iTime")),
		1,
		raw_data([]f32{f32(time.duration_seconds(state.time_elapsed))}),
	)
	gl.Uniform4fv(gl.GetUniformLocation(shader, cstring("input")), 1, raw_data(color))
	gl.Uniform2fv(gl.GetUniformLocation(shader, cstring("position")), 1, raw_data([]f32{x, y}))
	gl.Uniform2fv(
		gl.GetUniformLocation(shader, cstring("resolution")),
		1,
		raw_data([]f32{width, height}),
	)
	gl.Uniform2fv(
		gl.GetUniformLocation(shader, cstring("size")),
		1,
		raw_data([]f32{width, height}),
	)
	gl.UniformMatrix4fv(
		gl.GetUniformLocation(shader, cstring("projection")),
		1,
		false,
		raw_data(&projectionMatrix),
	)
	gl.BindVertexArray(vao)
	gl.DrawArrays(gl.TRIANGLE_FAN, 0, 4)

	gl.BindVertexArray(0)
	gl.BindBuffer(gl.ARRAY_BUFFER, 0)
	gl.DeleteBuffers(1, &vbo)
	gl.DeleteVertexArrays(1, &vao)
}
