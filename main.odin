package main

import "base:runtime"
import "core:c"
import "core:c/libc"
import "core:fmt"
import "core:sys/posix"
import "core:time"

import "render"
import p "render/primitives"
import "state"
import gl "vendor:OpenGL"
import "vendor:egl"
import wl "wayland-odin/wayland"

surface_listener := wl.xdg_surface_listener {
	configure = surface_configure,
}

buffer_listener := wl.wl_buffer_listener {
	release = proc "c" (data: rawptr, wl_buffer: ^wl.wl_buffer) {
		wl.wl_buffer_destroy(wl_buffer)
	},
}
layer_listener := wl.zwlr_layer_surface_v1_listener {
	configure = proc "c" (
		data: rawptr,
		surface: ^wl.zwlr_layer_surface_v1,
		serial: c.uint32_t,
		width: c.uint32_t,
		height: c.uint32_t,
	) {
		context = runtime.default_context()
		fmt.println("layer_configure")
		state := cast(^state.State)data
		wl.zwlr_layer_surface_v1_ack_configure(surface, serial)
		//
		//buffer := get_buffer(state, 800, 600)
		//wl.wl_surface_attach(state.surface, buffer, 0, 0)
		wl.wl_surface_damage(state.surface, 0, 0, c.INT32_MAX, c.INT32_MAX)
		wl.wl_surface_commit(state.surface)
	},
}


done :: proc "c" (data: rawptr, wl_callback: ^wl.wl_callback, callback_data: c.uint32_t) {
	context = runtime.default_context()
	state := cast(^state.State)data
	wl_callback_destroy(wl_callback)
	wl_callback := wl.wl_surface_frame(state.surface)
	wl.wl_callback_add_listener(wl_callback, &frame_callback_listener, state)

	// Maybe render code goes here
	draw(state)
}

frame_callback_listener := wl.wl_callback_listener {
	done = done,
}

surface_configure :: proc "c" (data: rawptr, surface: ^wl.xdg_surface, serial: c.uint32_t) {
	context = runtime.default_context()
	fmt.println("surface_configure")
	state := cast(^state.State)data
	wl.xdg_surface_ack_configure(surface, serial)
	//
	//buffer := get_buffer(state, 800, 600)
	//wl.wl_surface_attach(state.surface, buffer, 0, 0)
	wl.wl_surface_damage(state.surface, 0, 0, c.INT32_MAX, c.INT32_MAX)
	wl.wl_surface_commit(state.surface)
}

// This should be generated once this whole thing works
wl_callback_destroy :: proc "c" (wl_callback: ^wl.wl_callback) {
	wl.proxy_destroy(cast(^wl.wl_proxy)wl_callback)
}

// draw :: proc(shader: u32) {
// 	gl.ClearColor(147.0 / 255.0, 204.0 / 255., 234. / 255., 1.0)
// 	// gl.ClearColor(0.0, 0.0, 0.0, 0.0)
// 	gl.Clear(gl.COLOR_BUFFER_BIT)

// 	// vertices := [?]f32{-0.5, -0.5, 0.0, 0.5, -0.5, 0.0, 0.0, 0.5, 0.0}
// 	vertices := [?]f32{-0.5, -0.5, 0.0, 0.5, -0.5, 0.0, 0.5, 0.5, 0.0, -0.5, 0.5, 0.0}

// 	vao: u32
// 	gl.GenVertexArrays(1, &vao)
// 	gl.BindVertexArray(vao)

// 	vbo: u32
// 	gl.GenBuffers(1, &vbo)
// 	gl.BindBuffer(gl.ARRAY_BUFFER, vbo)
// 	gl.BufferData(gl.ARRAY_BUFFER, size_of(vertices), &vertices[0], gl.STATIC_DRAW)

// 	gl.EnableVertexAttribArray(0)
// 	gl.VertexAttribPointer(0, 3, gl.FLOAT, gl.FALSE, 0, 0)

// 	// draw stuff
// 	gl.UseProgram(shader)
// 	color := []f32{1.0, 0.0, 0.0, 1.0}
// 	gl.Uniform4fv(gl.GetUniformLocation(shader, cstring("input")), 1, raw_data(color))
// 	gl.BindVertexArray(vao)
// 	// gl.DrawArraysInstanced(gl.QUADS, 0, 4, 1)
// 	gl.DrawArrays(gl.TRIANGLE_STRIP, 0, 4)
// 	gl.Flush()
// }

draw :: proc(state: ^state.State) {
	shader := state.shader_programs["Singularity"]

	gl.ClearColor(147.0 / 255.0, 204.0 / 255., 234. / 255., 1.0)
	// gl.ClearColor(0.0, 0.0, 0.0, 0.0)
	gl.Clear(gl.COLOR_BUFFER_BIT)

	p.draw_rect(100, 100, 200, 200, shader)
	gl.Flush()
}

load_shader :: proc(vertex_shader_path: string, fragment_shader_path: string) -> u32 {
	shaders, result := gl.load_shaders_file(vertex_shader_path, fragment_shader_path)

	fmt.println(result)
	return shaders
}

ZWLR_LAYER_SURFACE_V1_ANCHOR_TOP :: 2
ZWLR_LAYER_SURFACE_V1_ANCHOR_BOTTOM :: 2
ZWLR_LAYER_SURFACE_V1_ANCHOR_LEFT :: 4
ZWLR_LAYER_SURFACE_V1_ANCHOR_RIGHT :: 8

XDG_OR_LAYER :: "layer"

WIDTH :: 800
HEIGHT :: 600
main :: proc() {
	using state
	state := init(WIDTH, HEIGHT)

	state.shader_programs["Basic"] = load_shader(
		"shaders/basic_vert.glsl",
		"shaders/basic_frag.glsl",
	)

	state.shader_programs["Singularity"] = load_shader(
		"shaders/basic_vert.glsl",
		"shaders/singularity.glsl",
	)

	if XDG_OR_LAYER == "layer" {
		layer_surface := wl.zwlr_layer_shell_v1_get_layer_surface(
			state.zwlr_layer_shell_v1,
			state.surface,
			nil,
			3,
			"test",
		)
		wl.zwlr_layer_surface_v1_add_listener(layer_surface, &layer_listener, &state)
		wl.zwlr_layer_surface_v1_set_size(layer_surface, WIDTH, HEIGHT)
		wl.zwlr_layer_surface_v1_set_anchor(
			layer_surface,
			ZWLR_LAYER_SURFACE_V1_ANCHOR_BOTTOM | ZWLR_LAYER_SURFACE_V1_ANCHOR_RIGHT,
		)
		wl.display_dispatch(state.display) // This dispatch makes sure that the layer surface is configured

		// This not working, don't know why
		//wl.zwlr_layer_surface_v1_set_exclusive_edge(
		//	layer_surface,
		//	ZWLR_LAYER_SURFACE_V1_ANCHOR_BOTTOM | ZWLR_LAYER_SURFACE_V1_ANCHOR_RIGHT,
		//)
		//wl.zwlr_layer_surface_v1_set_exclusive_zone(layer_surface, 1000)
	} else {
		xdg_surface := wl.xdg_wm_base_get_xdg_surface(state.xdg_base, state.surface)
		toplevel := wl.xdg_surface_get_toplevel(xdg_surface)
		wl.xdg_toplevel_set_title(toplevel, "Odin Wayland")
		wl.xdg_surface_add_listener(xdg_surface, &surface_listener, &state)
	}

	wl.wl_surface_commit(state.surface) // This first commit is needed by egl or egl.SwapBuffers() will panic

	wl_callback := wl.wl_surface_frame(state.surface)
	wl.wl_callback_add_listener(wl_callback, &frame_callback_listener, &state)
	//wl.wl_surface_commit(state.surface)

	for {
		state.time_elapsed = time.diff(state.start_time, time.now())
		wl.display_dispatch(state.display)
		egl.SwapBuffers(state.egl.display, state.egl.surface)
	}
}
