package engine

import "core:fmt"
import gl "vendor:OpenGL"

Shaders :: struct {
	shaders: map[string]u32,
	new:     proc(
		shaders: ^Shaders,
		name: string,
		vertex_shader_path: string,
		fragment_shader_path: string,
	),
	get:     proc(shaders: ^Shaders, name: string) -> u32,
}

load_shader :: proc(vertex_shader_path: string, fragment_shader_path: string) -> u32 {
	shader, result := gl.load_shaders_file(vertex_shader_path, fragment_shader_path)

	assert(
		result,
		fmt.tprintf("Failed to load shader: %s %s", vertex_shader_path, fragment_shader_path),
	)

	return shader
}

create_shaders_controller :: proc() -> Shaders {
	shaders: Shaders
	shaders.shaders = map[string]u32{}
	shaders.new =
	proc(
		shaders: ^Shaders,
		name: string,
		vertex_shader_path: string,
		fragment_shader_path: string,
	) {
		shaders.shaders[name] = load_shader(vertex_shader_path, fragment_shader_path)
	}
	shaders.get = proc(shaders: ^Shaders, name: string) -> u32 {
		shader, ok := shaders.shaders[name]
		assert(ok, fmt.tprintf("Shader not found: %s", name))
		return shader
	}
	return shaders
}
