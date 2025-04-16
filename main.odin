package main

import "base:runtime"
import "core:c"
import "core:fmt"
import "core:strings"
import "core:time"

import "engine"
import wl "vendor/wayland-odin/wayland"
import gl "vendor:OpenGL"
import "vendor:egl"
import xlib "vendor:x11/xlib"
import "widgets"


draw :: proc(canvas: ^engine.Canvas, state: ^engine.State) {
	shader := state.shaders->get("Singularity")
	shader2 := state.shaders->get("Basic")

	gl.ClearColor(147.0 / 255.0, 204.0 / 255., 234. / 255., 1.0)
	gl.Clear(gl.COLOR_BUFFER_BIT)

	p.draw_rect(0, 0, 800, 600, shader, state)
	// p.draw_rect(50, 50, 200, 100, shader2, state)
	p.draw_text(state.text, 50, 200, state)


	gl.Flush()
}


WIDTH :: 800
HEIGHT :: 600

main :: proc() {
	state := engine.init(WIDTH, HEIGHT)
	canvas := engine.create_canvas(state, WIDTH, HEIGHT, engine.CanvasType.Window, draw)

	state.shaders->new("Basic", "shaders/basic_vert.glsl", "shaders/basic_frag.glsl")
	state.shaders->new("Singularity", "shaders/basic_vert.glsl", "shaders/singularity.glsl")
	state.shaders->new("Text", "shaders/solid_text_vert.glsl", "shaders/solid_text_frag.glsl")

	_widgets: [dynamic]widgets.Widget
	append(&_widgets, widgets.Label{})
	for state.running == true {
		state.time_elapsed = time.diff(state.start_time, time.now())

		// Consume all events and do eventual dispatching
		events := engine.consume_all_events(state.input)
		for event in events {
			#partial switch e in event {
			case engine.KeyPressed:
				{
					if e.key == xlib.KeySym.XK_Escape {
						state.running = false
					}
					if e.key == xlib.KeySym.XK_BackSpace {
						if len(state.text) > 0 {
							state.text, _ = strings.substring(
								state.text,
								0,
								strings.rune_count(state.text) - 1,
							)
						}
					}
					fmt.println("Key pressed: ", e.key)
				}
			case engine.KeyReleased:
				{
					// fmt.println("Key released: ", e.key)
				}
			case engine.TextInput:
				{
					// state.text = fmt.tprintf("%s%s", state.text, e.text)
					state.text = strings.concatenate([]string{state.text, e.text})
					fmt.println("Text input: ", e.text)
				}
			}
		}

		// this call will process all the wayland messages
		// - drawing will be done as a result
		// - event gathering
		// - etc
		wl.display_dispatch(state.display)
		egl.SwapBuffers(state.egl_render_context.display, canvas.egl_surface)
	}
}
