package platform

import gl "vendor:OpenGL"

get_quad :: proc(_vertices: ^[]f32) -> (u32, u32) {
	vertices: []f32
	if _vertices != nil {
		vertices = _vertices^
	} else {
		vertices = []f32 {
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
	}


	vao: u32
	gl.GenVertexArrays(1, &vao)
	gl.BindVertexArray(vao)

	vbo: u32
	gl.GenBuffers(1, &vbo)
	gl.BindBuffer(gl.ARRAY_BUFFER, vbo)
	gl.BufferData(gl.ARRAY_BUFFER, size_of(vertices) * size_of(f32), &vertices[0], gl.STATIC_DRAW)

	gl.EnableVertexAttribArray(0)
	gl.VertexAttribPointer(0, 2, gl.FLOAT, gl.FALSE, 4 * size_of(f32), 0)

	gl.VertexAttribPointer(1, 2, gl.FLOAT, gl.FALSE, 4 * size_of(f32), 2 * size_of(f32))
	gl.EnableVertexAttribArray(1)

	return vao, vbo
}
