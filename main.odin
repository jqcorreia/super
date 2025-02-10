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

done :: proc "c" (data: rawptr, wl_callback: ^wl.wl_callback, callback_data: c.uint32_t) {
	context = runtime.default_context()
	// fmt.println("done")
	state := cast(^state.State)data

	wl_callback_destroy(wl_callback)
	wl_callback := wl.wl_surface_frame(state.surface)
	wl.wl_callback_add_listener(wl_callback, &frame_callback_listener, state)

	// Maybe render code goes here
}

frame_callback_listener := wl.wl_callback_listener {
	done = done,
}

surface_configure :: proc "c" (data: rawptr, surface: ^wl.xdg_surface, serial: c.uint32_t) {
	context = runtime.default_context()
	fmt.println("surface_configure")
	state := cast(^state.State)data
	//fmt.println("surface configure")
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

draw :: proc(shader: u32) {
	gl.ClearColor(147.0 / 255.0, 204.0 / 255., 234. / 255., 1.0)
	gl.Clear(gl.COLOR_BUFFER_BIT)

	vertices := [?]f32{-0.5, -0.5, 0.0, 0.5, -0.5, 0.0, 0.0, 0.5, 0.0}

	vao: u32
	gl.GenVertexArrays(1, &vao)
	gl.BindVertexArray(vao)

	vbo: u32
	gl.GenBuffers(1, &vbo)
	gl.BindBuffer(gl.ARRAY_BUFFER, vbo)
	gl.BufferData(gl.ARRAY_BUFFER, size_of(vertices), &vertices[0], gl.STATIC_DRAW)

	gl.EnableVertexAttribArray(0)
	gl.VertexAttribPointer(0, 3, gl.FLOAT, gl.FALSE, 0, 0)

	// setup vao
	// vao: u32
	// gl.GenVertexArrays(1, &vao)

	// gl.BindVertexArray(vao)

	// // setup vbo
	// vertex_data := [?]f32{-0.3, -0.3, 0.3, -0.3, 0.0, 0.5}

	// vbo: u32
	// gl.GenBuffers(1, &vbo)

	// gl.BindBuffer(gl.ARRAY_BUFFER, vbo)
	// gl.BufferData(gl.ARRAY_BUFFER, size_of(vertex_data), &vertex_data[0], gl.STATIC_DRAW)

	// gl.EnableVertexAttribArray(0)
	// gl.VertexAttribPointer(0, 2, gl.FLOAT, gl.FALSE, 0, 0)

	// draw stuff
	gl.UseProgram(shader)
	color := []f32{1.0, 0.0, 0.0, 0.0}
	gl.Uniform4fv(gl.GetUniformLocation(shader, cstring("input")), 1, raw_data(color))
	gl.BindVertexArray(vao)
	gl.DrawArraysInstanced(gl.TRIANGLES, 0, 3, 2)
	gl.Flush()
}

load_shader :: proc() -> u32 {
	shaders, result := gl.load_shaders_file("shaders/basic.vs", "shaders/basic.fs")

	fmt.println(result)
	return shaders
}

main :: proc() {
	using state
	state := init()

	shader := load_shader()

	fmt.println(shader)
	xdg_surface := wl.xdg_wm_base_get_xdg_surface(state.xdg_base, state.surface)
	toplevel := wl.xdg_surface_get_toplevel(xdg_surface)
	wl.xdg_toplevel_set_title(toplevel, "Odin Wayland")

	wl.wl_surface_commit(state.surface) // This first commit is needed by egl or egl.SwapBuffers() will panic
	wl.xdg_surface_add_listener(xdg_surface, &surface_listener, &state)

	wl_callback := wl.wl_surface_frame(state.surface)
	wl.wl_callback_add_listener(wl_callback, &frame_callback_listener, &state)
	wl.wl_surface_commit(state.surface)

	for {
		wl.display_dispatch(state.display)
		draw(shader)
		egl.SwapBuffers(state.egl.display, state.egl.surface)
	}
}
