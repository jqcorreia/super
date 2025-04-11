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
	shader := state.shaders->get("Singularity")

	gl.ClearColor(147.0 / 255.0, 204.0 / 255., 234. / 255., 1.0)
	// gl.ClearColor(0.0, 0.0, 0.0, 0.0)
	gl.Clear(gl.COLOR_BUFFER_BIT)

	p.draw_rect(0, 0, 800, 600, shader, state)
	gl.Flush()

	// egl.SwapBuffers(state.egl_render_context.display, canvas.egl_surface)
}


WIDTH :: 800
HEIGHT :: 600

main :: proc() {
	state := engine.init(WIDTH, HEIGHT)
	canvas := engine.create_canvas(state, WIDTH, HEIGHT, engine.CanvasType.Window)
	engine.set_draw_callback(state, canvas, draw)

	state.shaders->new("Basic", "shaders/basic_vert.glsl", "shaders/basic_frag.glsl")
	state.shaders->new("Singularity", "shaders/basic_vert.glsl", "shaders/singularity.glsl")


	// pointer := wl.wl_seat_get_pointer(state.seat)
	// wl.wl_keyboard_add_listener(keyboard, &keyboard_listener, nil)

	for {
		state.time_elapsed = time.diff(state.start_time, time.now())
		wl.display_dispatch(state.display)
		egl.SwapBuffers(state.egl_render_context.display, canvas.egl_surface)
	}
}
