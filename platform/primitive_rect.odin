package platform

import "core:time"
import gl "vendor:OpenGL"


DrawRectParams :: struct {
	vertices:       ^[]f32,
	color:          Color,
	shader:         ^Shader,
	texture:        u32,
	flip_texture_y: bool,
	tag:            string,
}

draw_rect_raw :: proc(
	resolution: [2]f32,
	x, y, w, h: f32,
	params: DrawRectParams = {color = {0, 0, 0, 1.0}},
) {
	shader: ^Shader
	if (params.shader == nil) {
		// Sane default shaders
		if (params.texture == 0) {
			shader = get_shader("Basic")
		} else {
			shader = get_shader("Texture")
		}
	} else {
		shader = params.shader
	}

	vao := platform.unit_square_vao
	gl.UseProgram(shader.program)

	// draw stuff
	color := params.color
	_resolution := resolution

	projectionMatrix := ortho(0, resolution[0], resolution[1], 0)
	gl.Uniform1fv(
		gl.GetUniformLocation(shader.program, cstring("iTime")),
		1,
		raw_data([]f32{f32(time.duration_seconds(inst().time_elapsed))}),
	)
	gl.Uniform4fv(gl.GetUniformLocation(shader.program, cstring("input")), 1, raw_data(&color))
	gl.Uniform2fv(
		gl.GetUniformLocation(shader.program, cstring("resolution")),
		1,
		raw_data(&_resolution),
	)
	gl.Uniform2fv(
		gl.GetUniformLocation(shader.program, cstring("position")),
		1,
		raw_data([]f32{x, y}),
	)
	gl.Uniform2fv(gl.GetUniformLocation(shader.program, cstring("size")), 1, raw_data([]f32{w, h}))
	gl.UniformMatrix4fv(
		gl.GetUniformLocation(shader.program, cstring("projection")),
		1,
		false,
		raw_data(&projectionMatrix),
	)
	if (params.texture != 0) {
		gl.ActiveTexture(gl.TEXTURE0)
		gl.BindTexture(gl.TEXTURE_2D, params.texture)
		gl.Uniform1i(gl.GetUniformLocation(shader.program, cstring("uTexture")), 0)
		gl.Uniform1i(
			gl.GetUniformLocation(shader.program, cstring("flipped")),
			i32(params.flip_texture_y),
		)
	}

	gl.BindVertexArray(vao)
	gl.DrawArrays(gl.TRIANGLE_FAN, 0, 4)
	gl.BindVertexArray(0)
	gl.BindTexture(gl.TEXTURE_2D, 0)
}

draw_rect_canvas :: proc(
	canvas: ^Canvas,
	x, y, width, height: f32,
	params: DrawRectParams = DrawRectParams{color = {0.0, 0.0, 0.0, 1.0}},
) {
	draw_rect_raw({f32(canvas.width), f32(canvas.height)}, x, y, width, height, params)
}

draw_rect :: proc {
	draw_rect_canvas,
	draw_rect_raw,
}
