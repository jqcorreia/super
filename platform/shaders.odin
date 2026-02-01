package platform

import "core:fmt"
import "core:strings"
import gl "vendor:OpenGL"


Shaders :: struct {
	shaders: map[string]^Shader,
}

Shader :: struct {
	program: u32,
}


shader_set_uniform_matrix4x4f32 :: proc(
	shader: u32,
	name: string,
	value: ^matrix[4, 4]f32,
	count: i32 = 1,
	transpose: bool = false,
) {
	location := gl.GetUniformLocation(shader, strings.clone_to_cstring(name))
	gl.UniformMatrix4fv(location, count, transpose, raw_data(value))
}

shader_set_uniform_vec2f32 :: proc(shader: u32, name: string, value: ^[2]f32, count: i32 = 1) {
	location := gl.GetUniformLocation(shader, strings.clone_to_cstring(name))
	gl.Uniform2fv(location, count, raw_data(value))
}

shader_set_uniform_vec3f32 :: proc(shader: u32, name: string, value: ^[3]f32, count: i32 = 1) {
	location := gl.GetUniformLocation(shader, strings.clone_to_cstring(name))
	gl.Uniform3fv(location, count, raw_data(value))
}

shader_set_uniform_vec4f32 :: proc(shader: u32, name: string, value: ^[4]f32, count: i32 = 1) {
	location := gl.GetUniformLocation(shader, strings.clone_to_cstring(name))
	gl.Uniform4fv(location, count, raw_data(value))
}

shader_set_uniform_i32 :: proc(shader: u32, name: string, value: i32, count: i32 = 1) {
	location := gl.GetUniformLocation(shader, strings.clone_to_cstring(name))
	gl.Uniform1i(location, value)
}

shader_set_uniform_f32 :: proc(shader: u32, name: string, value: f32, count: i32 = 1) {
	location := gl.GetUniformLocation(shader, strings.clone_to_cstring(name))
	gl.Uniform1f(location, value)
}

shader_set_uniform :: proc {
	shader_set_uniform_matrix4x4f32,
	shader_set_uniform_vec2f32,
	shader_set_uniform_vec3f32,
	shader_set_uniform_vec4f32,
	shader_set_uniform_i32,
	shader_set_uniform_f32,
}

load_shader_from_paths :: proc(
	vertex_shader_path: string,
	fragment_shader_path: string,
) -> ^Shader {
	shader, result := gl.load_shaders_file(vertex_shader_path, fragment_shader_path)

	assert(
		result,
		fmt.tprintf(
			"Failed to load shader from paths: %s %s",
			vertex_shader_path,
			fragment_shader_path,
		),
	)

	shader_obj := new(Shader)
	shader_obj.program = shader

	return shader_obj
}

load_shader_from_strings :: proc(
	vertex_shader_source: []u8,
	fragment_shader_source: []u8,
) -> ^Shader {
	shader, result := gl.load_shaders_source(
		string(vertex_shader_source),
		string(fragment_shader_source),
	)

	assert(
		result,
		fmt.tprintf(
			"Failed to load shader from sources: %s %s",
			vertex_shader_source,
			fragment_shader_source,
		),
	)
	shader_obj := new(Shader)
	shader_obj.program = shader

	return shader_obj
}

new_shader_from_source :: proc(
	name: string,
	vertex_shader_source: []u8,
	fragment_shader_source: []u8,
) {
	shaders := inst().shaders
	shader := load_shader(vertex_shader_source, fragment_shader_source)
	gl.ObjectLabel(
		gl.PROGRAM,
		shader.program,
		-1,
		strings.clone_to_cstring(fmt.tprintf("shader-%s", name)),
	)
	shaders.shaders[name] = shader
}

new_shader_from_path :: proc(
	name: string,
	vertex_shader_path: string,
	fragment_shader_path: string,
) {
	shaders := inst().shaders
	shader := load_shader(vertex_shader_path, fragment_shader_path)
	gl.ObjectLabel(
		gl.PROGRAM,
		shader.program,
		-1,
		strings.clone_to_cstring(fmt.tprintf("shader-%s", name)),
	)
	shaders.shaders[name] = shader
}

load_shader :: proc {
	load_shader_from_strings,
	load_shader_from_paths,
}

new_shader :: proc {
	new_shader_from_path,
	new_shader_from_source,
}


get_shader :: proc(name: string) -> ^Shader {
	shaders := inst().shaders
	shader, ok := shaders.shaders[name]
	assert(ok, fmt.tprintf("Shader not found: %s", name))
	return shader
}
create_shaders_controller :: proc() -> ^Shaders {
	shaders := new(Shaders)
	shaders.shaders = map[string]^Shader{}
	return shaders
}

basic_vert := #load("shaders/basic_vert.glsl")
solid_text_vert := #load("shaders/solid_text_vert.glsl")
basic_frag := #load("shaders/basic_frag.glsl")
circle_frag := #load("shaders/circle_frag.glsl")
rounded_rect_frag := #load("shaders/rounded_rect_frag.glsl")
texture_frag := #load("shaders/texture_frag.glsl")
solid_text_frag := #load("shaders/solid_text_frag.glsl")
border_rect_frag := #load("shaders/border_rect_frag.glsl")
