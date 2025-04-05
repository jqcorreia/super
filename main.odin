package main

import "core:c"
import "core:c/libc"
import "core:fmt"
import "render"
import wl "wayland-odin/wayland"

import "core:sys/posix"

import "base:runtime"
import gl "vendor:OpenGL"
import "vendor:egl"

import "state"

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
		fmt.println("surface_configure")
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
	draw(state.shader_program)
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

draw_rect :: proc(x, y, width, height: f32, shader: u32) {
	vertices := [?]f32 {
		f32(x),
		f32(y),
		0.0,
		f32(x + width),
		f32(y),
		0.0,
		f32(x + width),
		f32(y + height),
		0.0,
		f32(x),
		f32(y + height),
		0.0,
	}

	vao: u32
	gl.GenVertexArrays(1, &vao)
	gl.BindVertexArray(vao)

	vbo: u32
	gl.GenBuffers(1, &vbo)
	gl.BindBuffer(gl.ARRAY_BUFFER, vbo)
	gl.BufferData(gl.ARRAY_BUFFER, size_of(vertices), &vertices[0], gl.STATIC_DRAW)

	gl.EnableVertexAttribArray(0)
	gl.VertexAttribPointer(0, 3, gl.FLOAT, gl.FALSE, 0, 0)

	// draw stuff
	color := []f32{1.0, 1.0, 1.0, 1.0}
	gl.Uniform4fv(gl.GetUniformLocation(shader, cstring("input")), 1, raw_data(color))
	gl.UseProgram(shader)
	gl.BindVertexArray(vao)
	gl.DrawArrays(gl.TRIANGLE_FAN, 0, 4)
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

draw :: proc(shader: u32) {
	gl.ClearColor(147.0 / 255.0, 204.0 / 255., 234. / 255., 1.0)
	// gl.ClearColor(0.0, 0.0, 0.0, 0.0)
	gl.Clear(gl.COLOR_BUFFER_BIT)

	draw_rect(0, 0, 50, 50, shader)
	gl.Flush()
}

load_shader :: proc() -> u32 {
	shaders, result := gl.load_shaders_file("shaders/basic.vs", "shaders/basic.fs")

	fmt.println(result)
	return shaders
}

ZWLR_LAYER_SURFACE_V1_ANCHOR_TOP :: 2
ZWLR_LAYER_SURFACE_V1_ANCHOR_BOTTOM :: 2
ZWLR_LAYER_SURFACE_V1_ANCHOR_LEFT :: 4
ZWLR_LAYER_SURFACE_V1_ANCHOR_RIGHT :: 8

XDG_OR_LAYER :: "layer"

main :: proc() {
	using state
	state := init()

	shader := load_shader()
	state.shader_program = shader

	if XDG_OR_LAYER == "layer" {
		layer_surface := wl.zwlr_layer_shell_v1_get_layer_surface(
			state.zwlr_layer_shell_v1,
			state.surface,
			nil,
			3,
			"test",
		)
		wl.zwlr_layer_surface_v1_add_listener(layer_surface, &layer_listener, &state)
		wl.zwlr_layer_surface_v1_set_size(layer_surface, 320, 100)
		wl.zwlr_layer_surface_v1_set_anchor(
			layer_surface,
			ZWLR_LAYER_SURFACE_V1_ANCHOR_BOTTOM | ZWLR_LAYER_SURFACE_V1_ANCHOR_RIGHT,
		)
	} else {
		xdg_surface := wl.xdg_wm_base_get_xdg_surface(state.xdg_base, state.surface)
		toplevel := wl.xdg_surface_get_toplevel(xdg_surface)
		wl.xdg_toplevel_set_title(toplevel, "Odin Wayland")
		wl.xdg_surface_add_listener(xdg_surface, &surface_listener, &state)
	}


	wl.wl_surface_commit(state.surface) // This first commit is needed by egl or egl.SwapBuffers() will panic

	wl_callback := wl.wl_surface_frame(state.surface)
	wl.wl_callback_add_listener(wl_callback, &frame_callback_listener, &state)
	wl.wl_surface_commit(state.surface)

	for {
		wl.display_dispatch(state.display)
		egl.SwapBuffers(state.egl.display, state.egl.surface)
	}
}
