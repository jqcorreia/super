package main

import "base:runtime"
import "core:c"
import "core:fmt"
import "core:os"
import "core:os/os2"
import "core:slice"
import "core:strings"
import "core:time"

import "actions"
import "core:encoding/ini"
import "engine"
import "platform"
import "platform/canvas"
import gl "vendor:OpenGL"
import "vendor:egl"
import "widgets"


WIDTH :: 800
HEIGHT :: 600


App :: struct {
	widget_list: [dynamic]widgets.Widget,
}

app := App{}

draw :: proc(canvas: ^canvas.Canvas) {
	gl.ClearColor(147.0 / 255.0, 204.0 / 255., 234. / 255., 1.0)
	// gl.ClearColor(0.0, 0.0, 0.0, 1.0)
	gl.Clear(gl.COLOR_BUFFER_BIT)
	gl.Enable(gl.BLEND)

	canvas->draw_rect(
		0,
		0,
		f32(canvas.width),
		f32(canvas.height),
		color = {0.0, 0.0, 1.0, 1.0},
		shader = platform.inst().shaders->get("Cosmic"),
	)

	for &widget in app.widget_list {
		#partial switch &w in widget {
		case widgets.List(string):
			widgets.draw(&w, canvas)
		case widgets.List(actions.Action):
			widgets.draw(&w, canvas)
		case widgets.InputText:
			widgets.draw(&w, canvas)
		}
	}

	// canvas->draw_rect(
	// 	0,
	// 	0,
	// 	f32(canvas.width),
	// 	f32(canvas.height),
	// 	color = {0.0, 0.0, 1.0, 1.0},
	// 	shader = platform.inst().shaders->get("Border"),
	// )
	gl.Disable(gl.BLEND)

	gl.Flush()
}


main :: proc() {
	action_items: [dynamic]actions.Action

	app_items := actions.get_application_actions()
	secrets_items := actions.get_secret_actions()
	for i in app_items {
		append(&action_items, i)
	}
	for i in secrets_items {
		append(&action_items, i)
	}

	// action_items += actions.get_secret_actions()
	fmt.println("Number of apps detected:", len(action_items))

	c1 := engine.create_canvas(WIDTH, HEIGHT, canvas.CanvasType.Layer, draw)

	search := widgets.InputText {
		x    = 0,
		y    = 0,
		w    = f32(c1.width),
		h    = 50,
		font = engine.state.font,
		text = "",
	}

	list := widgets.List(actions.Action) {
		x     = 0,
		y     = 50,
		w     = f32(c1.width),
		h     = f32(c1.height) - 50,
		items = action_items[:],
		font  = &engine.state.font,
		// draw_item = widgets.list_draw_action,
	}

	append(&app.widget_list, search)
	append(&app.widget_list, list)

	platform.inst().shaders->new(
		"Singularity",
		"shaders/basic_vert.glsl",
		"shaders/singularity.glsl",
	)
	platform.inst().shaders->new("Starship", "shaders/basic_vert.glsl", "shaders/starship.glsl")
	platform.inst().shaders->new("Cosmic", "shaders/basic_vert.glsl", "shaders/cosmic.glsl")
	platform.inst().shaders->new(
		"Border",
		"shaders/basic_vert.glsl",
		"shaders/border_rect_frag.glsl",
	)

	previous_search := ""

	for engine.state.running == true {
		s := &app.widget_list[0].(widgets.InputText)
		l := &app.widget_list[1].(widgets.List(actions.Action))

		// Really simple 'search'
		if s.text != previous_search {
			if s.text == "" {
				l.items = action_items[:]
			} else {
				new_items: [dynamic]actions.Action
				for i in action_items {
					#partial switch i in i {
					case actions.ApplicationAction:
						{
							if strings.contains(
								strings.to_lower(i.name),
								strings.to_lower(s.text),
							) {
								append(&new_items, i)
							}
						}
					case actions.SecretAction:
						{
							if strings.contains(
								strings.to_lower(i.name),
								strings.to_lower(s.text),
							) {
								append(&new_items, i)
							}
						}
					}
				}
				l.items = new_items[:]
			}
			widgets.list_reset(l)
			previous_search = s.text
		}

		events := platform.inst().input->consume_all_events()
		for event in events {
			#partial switch e in event {
			case platform.KeyPressed:
				{
					if e.key == platform.KeySym.XK_Escape {
						engine.state.running = false
					}
					if e.key == platform.KeySym.XK_Return {
						selected_action := l.items[l.selected_index]
						actions.do_action(selected_action)
					}
				}
			}
			for &widget in app.widget_list {
				#partial switch &w in widget {
				case widgets.List(actions.Action):
					widgets.update(&w, event)
				case widgets.List(string):
					widgets.update(&w, event)
				case widgets.InputText:
					widgets.update(&w, event)
				}
			}
		}
		engine.render(c1)
	}
}
