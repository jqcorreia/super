package platform

import "core:fmt"
import gl "vendor:OpenGL"

Shaders :: struct {
	shaders: map[string]u32,
}

load_shader_from_paths :: proc(vertex_shader_path: string, fragment_shader_path: string) -> u32 {
	shader, result := gl.load_shaders_file(vertex_shader_path, fragment_shader_path)

	assert(
		result,
		fmt.tprintf(
			"Failed to load shader from paths: %s %s",
			vertex_shader_path,
			fragment_shader_path,
		),
	)

	return shader
}

load_shader_from_strings :: proc(vertex_shader_source: []u8, fragment_shader_source: []u8) -> u32 {
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

	return shader
}

new_shader_from_source :: proc(
	name: string,
	vertex_shader_path: []u8,
	fragment_shader_path: []u8,
) {
	shaders := inst().shaders
	shaders.shaders[name] = load_shader(vertex_shader_path, fragment_shader_path)
	fmt.println(name, shaders.shaders[name])
}

new_shader_from_path :: proc(
	name: string,
	vertex_shader_path: string,
	fragment_shader_path: string,
) {
	shaders := inst().shaders
	shaders.shaders[name] = load_shader(vertex_shader_path, fragment_shader_path)
}

load_shader :: proc {
	load_shader_from_strings,
	load_shader_from_paths,
}

new_shader :: proc {
	new_shader_from_path,
	new_shader_from_source,
}


get_shader :: proc(name: string) -> u32 {
	shaders := inst().shaders
	shader, ok := shaders.shaders[name]
	assert(ok, fmt.tprintf("Shader not found: %s", name))
	return shader
}
create_shaders_controller :: proc() -> ^Shaders {
	shaders := new(Shaders)
	shaders.shaders = map[string]u32{}
	return shaders
}

basic_vert := #load("../shaders/basic_vert.glsl")
solid_text_vert := #load("../shaders/solid_text_vert.glsl")
basic_frag := #load("../shaders/basic_frag.glsl")
rounded_rect_frag := #load("../shaders/rounded_rect_frag.glsl")
texture_frag := #load("../shaders/texture_frag.glsl")
solid_text_frag := #load("../shaders/solid_text_frag.glsl")
border_rect_frag := #load("../shaders/border_rect_frag.glsl")

create_default_shaders :: proc() {
	new_shader("Basic", basic_vert, basic_frag)
	new_shader("Rounded", basic_vert, rounded_rect_frag)
	new_shader("Border", basic_vert, border_rect_frag)
	new_shader("Text", solid_text_vert, solid_text_frag)
	new_shader("Texture", solid_text_vert, texture_frag)
}
