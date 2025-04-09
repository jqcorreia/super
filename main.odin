package main

import "base:runtime"
import "core:c"
import "core:fmt"
import "core:time"

import "engine"
import "render"
import p "render/primitives"
import gl "vendor:OpenGL"
import "vendor:egl"
import wl "wayland-odin/wayland"

draw :: proc(canvas: ^engine.Canvas, state: ^engine.State) {
	// if (!egl.MakeCurrent(
	// 		   state.egl_render_context.display,
	// 		   canvas.egl_surface,
	// 		   canvas.egl_surface,
	// 		   state.egl_render_context.ctx,
	// 	   )) {
	// 	fmt.println("Error making current!")
	// }
	shader := state.shader_programs["Singularity"]

	gl.ClearColor(147.0 / 255.0, 204.0 / 255., 234. / 255., 1.0)
	// gl.ClearColor(0.0, 0.0, 0.0, 0.0)
	gl.Clear(gl.COLOR_BUFFER_BIT)

	p.draw_rect(0, 0, 800, 600, shader, state)
	gl.Flush()

	// egl.SwapBuffers(state.egl_render_context.display, canvas.egl_surface)
}

load_shader :: proc(vertex_shader_path: string, fragment_shader_path: string) -> u32 {
	shaders, result := gl.load_shaders_file(vertex_shader_path, fragment_shader_path)

	fmt.println(result)
	return shaders
}

keyboard_listener := wl.wl_keyboard_listener {
	keymap = proc "c" (
		data: rawptr,
		keyboard: ^wl.wl_keyboard,
		format: c.uint32_t,
		fd: c.int32_t,
		size: c.uint32_t,
	) {
	},
	enter = proc "c" (
		data: rawptr,
		keyboard: ^wl.wl_keyboard,
		serial: c.uint32_t,
		surface: ^wl.wl_surface,
		keys: ^wl.wl_array,
	) {
	},
	leave = proc "c" (
		data: rawptr,
		keyboard: ^wl.wl_keyboard,
		serial: c.uint32_t,
		surface: ^wl.wl_surface,
	) {
	},
	key = proc "c" (
		data: rawptr,
		keyboard: ^wl.wl_keyboard,
		serial: c.uint32_t,
		time: c.uint32_t,
		key: c.uint32_t,
		state: c.uint32_t,
	) {
		// context = runtime.default_context()
		// fmt.println("Key pressed: ", key, " state: ", state)
	},
	modifiers = proc "c" (
		data: rawptr,
		wl_keyboard: ^wl.wl_keyboard,
		serial: c.uint32_t,
		mods_depressed: c.uint32_t,
		mods_latched: c.uint32_t,
		mods_locked: c.uint32_t,
		group: c.uint32_t,
	) {
	},
	repeat_info = proc "c" (
		data: rawptr,
		wl_keyboard: ^wl.wl_keyboard,
		rate: c.int32_t,
		delay: c.int32_t,
	) {},
}

pointer_listener := wl.wl_pointer_listener {
	enter = proc "c" (
		data: rawptr,
		pointer: ^wl.wl_pointer,
		serial: c.uint32_t,
		surface: ^wl.wl_surface,
		x: c.int32_t,
		y: c.int32_t,
	) {
	},
	leave = proc "c" (
		data: rawptr,
		pointer: ^wl.wl_pointer,
		serial: c.uint32_t,
		surface: ^wl.wl_surface,
	) {
	},
	motion = proc "c" (
		data: rawptr,
		wl_pointer: ^wl.wl_pointer,
		time: c.uint32_t,
		x: wl.wl_fixed_t,
		y: wl.wl_fixed_t,
	) {
	},
	button = proc "c" (
		data: rawptr,
		wl_pointer: ^wl.wl_pointer,
		serial: c.uint32_t,
		time: c.uint32_t,
		button: c.uint32_t,
		state: c.uint32_t,
	) {
	},
}

WIDTH :: 800
HEIGHT :: 600

seat_listener := wl.wl_seat_listener {
	capabilities = proc "c" (data: rawptr, wl_seat: ^wl.wl_seat, capabilities: c.uint32_t) {
		context = runtime.default_context()
		fmt.println("Capabilities: ", capabilities)
		state := cast(^engine.State)data
		fmt.println("State: ", state)
		pointer := wl.wl_seat_get_pointer(state.seat)
	},
	name = proc "c" (data: rawptr, wl_seat: ^wl.wl_seat, name: cstring) {
		context = runtime.default_context()
		fmt.println("Name: ", name)
	},
}
main :: proc() {
	state := engine.init(WIDTH, HEIGHT)
	canvas := engine.create_canvas(state, WIDTH, HEIGHT, engine.CanvasType.Window)
	engine.set_draw_callback(state, canvas, draw)

	// canvas2 := engine.create_canvas(&state, WIDTH, HEIGHT, engine.CanvasType.Layer)
	// engine.set_draw_callback(&state, canvas2, draw)

	state.shader_programs["Basic"] = load_shader(
		"shaders/basic_vert.glsl",
		"shaders/basic_frag.glsl",
	)

	state.shader_programs["Singularity"] = load_shader(
		"shaders/basic_vert.glsl",
		"shaders/singularity.glsl",
	)

	wl.wl_seat_add_listener(state.seat, &seat_listener, state)
	wl.display_dispatch(state.display)

	// pointer := wl.wl_seat_get_pointer(state.seat)
	// wl.wl_keyboard_add_listener(keyboard, &keyboard_listener, nil)

	for {
		state.time_elapsed = time.diff(state.start_time, time.now())
		wl.display_dispatch(state.display)
		egl.SwapBuffers(state.egl_render_context.display, canvas.egl_surface)
	}
}
