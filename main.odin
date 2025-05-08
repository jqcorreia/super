package main

import "base:runtime"
import "core:c"
import "core:fmt"
import "core:strings"
import "core:time"

import "engine"
import "platform"
import "platform/canvas"
import gl "vendor:OpenGL"
import "vendor:egl"
import "widgets"


WIDTH :: 800
HEIGHT :: 600


App :: struct {
	widget_list: [dynamic]widgets.WidgetType,
}

app := App{}

app_draw :: proc(canvas: ^canvas.Canvas) {
	shader := platform.inst().shaders->get("Singularity")
	shader2 := platform.inst().shaders->get("Basic")
	text_shader := platform.inst().shaders->get("Text")

	gl.ClearColor(147.0 / 255.0, 204.0 / 255., 234. / 255., 1.0)
	gl.Clear(gl.COLOR_BUFFER_BIT)

	canvas->draw_rect(0, 0, f32(canvas.width), f32(canvas.height), shader = shader)
	canvas->draw_text(50, 200, engine.state.text, &engine.state.font)

	for widget in app.widget_list {
		#partial switch w in widget {
		case widgets.Label:
			widgets.draw(w, canvas)
		}
	}
	gl.Flush()
}

// main :: proc() {
// 	canvas := engine.create_canvas(WIDTH, HEIGHT, canvas.CanvasType.Layer, app_draw)

// 	shaders := engine.platform.shaders
// 	shaders->new("Basic", "shaders/basic_vert.glsl", "shaders/basic_frag.glsl")
// 	shaders->new("Singularity", "shaders/basic_vert.glsl", "shaders/singularity.glsl")
// 	shaders->new("Text", "shaders/solid_text_vert.glsl", "shaders/solid_text_frag.glsl")


// 	append(
// 		&app.widget_list,
// 		widgets.Label{x = 0, y = 0, text = "Hello", font = &engine.state.font},
// 	)

// 	append(
// 		&app.widget_list,
// 		widgets.Label{x = 0, y = 100, text = "world", font = &engine.state.font},
// 	)

// 	for engine.state.running == true {
// 		engine.state.time_elapsed = time.diff(engine.state.start_time, time.now())

// 		// Consume all events and do eventual dispatching
// 		events := engine.platform.input->consume_all_events()
// 		for event in events {
// 			#partial switch e in event {
// 			case platform.KeyPressed:
// 				{
// 					if e.key == xlib.KeySym.XK_Escape {
// 						engine.state.running = false
// 					}
// 					if e.key == xlib.KeySym.XK_F1 {
// 						wl.zwlr_layer_surface_v1_set_size(
// 							canvas.layer_surface,
// 							u32(1000),
// 							u32(1000),
// 						)
// 					}
// 					if e.key == xlib.KeySym.XK_BackSpace {
// 						if len(engine.state.text) > 0 {
// 							engine.state.text, _ = strings.substring(
// 								engine.state.text,
// 								0,
// 								strings.rune_count(engine.state.text) - 1,
// 							)
// 						}
// 					}
// 					fmt.println("Key pressed: ", e.key)
// 				}
// 			case platform.KeyReleased:
// 				{
// 					// fmt.println("Key released: ", e.key)
// 				}
// 			case platform.TextInput:
// 				{
// 					// state.text = fmt.tprintf("%s%s", state.text, e.text)
// 					engine.state.text = strings.concatenate([]string{engine.state.text, e.text})
// 					fmt.println("Text input: ", e.text)
// 				}
// 			}
// 		}

// 		// this call will process all the wayland messages
// 		// - drawing will be done as a result
// 		// - event gathering
// 		// - etc
// 		// - Swap the buffers for the canvas
// 		engine.render(canvas)
// 	}
// }

draw :: proc(canvas: ^canvas.Canvas) {
	gl.ClearColor(147.0 / 255.0, 204.0 / 255., 234. / 255., 1.0)
	// gl.ClearColor(0.0, 0.0, 0.0, 1.0)
	gl.Clear(gl.COLOR_BUFFER_BIT)

	list := widgets.List {
		x     = 10,
		y     = 10,
		items = {},
	}

	// canvas->draw_rect(0, 0, 100, 100)
	// canvas->draw_rect(
	// 	0,
	// 	0,
	// 	f32(canvas.width),
	// 	f32(canvas.height),
	// 	shader = platform.inst().shaders->get("Cosmic"),
	// )
	// canvas->draw_text(200, 200, "Hello!", &engine.state.font)
	widgets.draw(list, canvas)

	gl.Flush()

}

main :: proc() {
	c1 := engine.create_canvas(WIDTH, HEIGHT, canvas.CanvasType.Layer, draw)

	platform.inst().shaders->new(
		"Singularity",
		"shaders/basic_vert.glsl",
		"shaders/singularity.glsl",
	)
	platform.inst().shaders->new("Starship", "shaders/basic_vert.glsl", "shaders/starship.glsl")
	platform.inst().shaders->new("Cosmic", "shaders/basic_vert.glsl", "shaders/cosmic.glsl")
	for engine.state.running == true {
		events := platform.inst().input->consume_all_events()
		for event in events {
			#partial switch e in event {
			case platform.KeyPressed:
				{
					if e.key == platform.KeySym.XK_Escape {
						engine.state.running = false
					}
				}
			}
		}
		engine.render(c1)
	}
}
