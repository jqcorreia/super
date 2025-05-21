package canvas

import "core:time"
import gl "vendor:OpenGL"

import "../../platform"
import "../../types"
import "../../utils/gmath"

DrawRectParams :: struct {
	vertices:       ^[]f32,
	color:          types.Color,
	shader:         u32,
	texture:        u32,
	flip_texture_y: bool,
	tag:            string,
}
draw_rect_raw :: proc(
	resolution: [2]f32,
	x, y, w, h: f32,
	params: DrawRectParams = {color = {0, 0, 0, 1.0}},
) {
	shader: u32
	if (params.shader == 0) {
		// Sane default shaders
		if (params.texture == 0) {
			shader = platform.get_shader("Basic")
		} else {
			shader = platform.get_shader("Texture")
		}
	} else {
		shader = params.shader
	}

	quad, vbo := get_quad(params.vertices)
	defer gl.DeleteBuffers(1, &vbo)
	defer gl.DeleteVertexArrays(1, &quad)

	gl.UseProgram(shader)

	// draw stuff
	color := params.color
	_resolution := resolution

	projectionMatrix := gmath.ortho(0, resolution[0], resolution[1], 0)
	gl.Uniform1fv(
		gl.GetUniformLocation(shader, cstring("iTime")),
		1,
		raw_data([]f32{f32(time.duration_seconds(platform.inst().time_elapsed))}),
	)
	gl.Uniform4fv(gl.GetUniformLocation(shader, cstring("input")), 1, raw_data(&color))
	gl.Uniform2fv(gl.GetUniformLocation(shader, cstring("resolution")), 1, raw_data(&_resolution))
	gl.Uniform2fv(gl.GetUniformLocation(shader, cstring("position")), 1, raw_data([]f32{x, y}))
	gl.Uniform2fv(gl.GetUniformLocation(shader, cstring("size")), 1, raw_data([]f32{w, h}))
	gl.UniformMatrix4fv(
		gl.GetUniformLocation(shader, cstring("projection")),
		1,
		false,
		raw_data(&projectionMatrix),
	)
	if (params.texture != 0) {
		gl.ActiveTexture(gl.TEXTURE0)
		gl.BindTexture(gl.TEXTURE_2D, params.texture)
		gl.Uniform1i(gl.GetUniformLocation(shader, cstring("uTexture")), 0)
		gl.Uniform1i(gl.GetUniformLocation(shader, cstring("flipped")), i32(params.flip_texture_y))
	}

	gl.BindVertexArray(quad)
	gl.DrawArrays(gl.TRIANGLE_FAN, 0, 4)
	gl.BindVertexArray(0)
	gl.BindBuffer(gl.ARRAY_BUFFER, 0)
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
