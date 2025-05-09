package widgets
import "../platform"

import "../platform/canvas"

import "../utils/gmath"
import "core:fmt"
import "core:time"
import gl "vendor:OpenGL"
List :: struct {
	x:     f32,
	y:     f32,
	items: [dynamic]string,
	font:  ^platform.Font,
}

list_draw :: proc(list: List, canvas: ^canvas.Canvas) {
	fbo, fboTexture: u32
	gl.GenFramebuffers(1, &fbo)
	gl.BindFramebuffer(gl.FRAMEBUFFER, fbo)

	// Create texture to render into
	gl.GenTextures(1, &fboTexture)
	gl.BindTexture(gl.TEXTURE_2D, fboTexture)
	gl.TexImage2D(gl.TEXTURE_2D, 0, gl.RGBA, 1024, 1024, 0, gl.RGBA, gl.UNSIGNED_BYTE, nil)
	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR)
	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR)

	gl.FramebufferTexture2D(gl.FRAMEBUFFER, gl.COLOR_ATTACHMENT0, gl.TEXTURE_2D, fboTexture, 0)

	// Check status
	if (gl.CheckFramebufferStatus(gl.FRAMEBUFFER) != gl.FRAMEBUFFER_COMPLETE) {
		fmt.println("FBO not complete!")
	}

	// Draw calls
	gl.ClearColor(0.0, 0.0, 0.0, 1.0)
	gl.Clear(gl.COLOR_BUFFER_BIT)
	// canvas->draw_rect(
	// 	0,
	// 	0,
	// 	100,
	// 	100,
	// 	color = {1.0, 1.0, 1.0, 0.0},
	// 	shader = platform.inst().shaders->get("Basic"),
	// )

	x: f32 = 0.0
	y: f32 = 0.0
	width: f32 = 100.0
	height: f32 = 100.0
	cw: f32 = 1024.0
	ch: f32 = 1024.0

	_color := [4]f32{1.0, 1.0, 0.0, 1.0}

	_shader := platform.inst().shaders->get("Basic")
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

	gl.UseProgram(_shader)

	// draw stuff

	projectionMatrix := gmath.ortho(0, f32(cw), f32(ch), 0)
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
		raw_data([]f32{cw, ch}),
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

	gl.BindFramebuffer(gl.FRAMEBUFFER, 0)


	// Draw texture in place
	canvas->draw_rect(
		list.x,
		list.y,
		500,
		500,
		shader = platform.inst().shaders->get("Texture"),
		texture = fboTexture,
	)
}
