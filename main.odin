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
	// shader2 := state.shaders->get("Basic")

	gl.ClearColor(147.0 / 255.0, 204.0 / 255., 234. / 255., 1.0)
	gl.Clear(gl.COLOR_BUFFER_BIT)

	p.draw_rect(0, 0, 800, 600, shader, state)
	// p.draw_rect(50, 50, 200, 100, shader2, state)
	gl.Flush()
}


WIDTH :: 800
HEIGHT :: 600

main :: proc() {
	state := engine.init(WIDTH, HEIGHT)
	canvas := engine.create_canvas(state, WIDTH, HEIGHT, engine.CanvasType.Window, draw)

	state.shaders->new("Basic", "shaders/basic_vert.glsl", "shaders/basic_frag.glsl")
	state.shaders->new("Singularity", "shaders/basic_vert.glsl", "shaders/singularity.glsl")


	for state.running == true {
		state.time_elapsed = time.diff(state.start_time, time.now())

		// this call will process all the wayland messages
		// - drawing will be done as a result
		// - event gathering
		// - etc
		wl.display_dispatch(state.display)
		egl.SwapBuffers(state.egl_render_context.display, canvas.egl_surface)

		// Consume all events and do eventual dispatching
		events := engine.consume_all_events(state.input)
		for event in events {
			switch e in event {
			case engine.KeyPressed:
				{
					if e.key == 1 {
						state.running = false
					}
					fmt.println("Key pressed: ", e.key)
				}
			case engine.KeyReleased:
				{
					fmt.println("Key released: ", e.key)
				}
			}

		}
	}
}
