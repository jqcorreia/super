package main

import "core:fmt"
import "core:strings"

import "actions"
import "engine"
import "platform"
import cv "platform/canvas"
import "ui"
import gl "vendor:OpenGL"


WIDTH :: 800
HEIGHT :: 600


App :: struct {
	widget_list: [dynamic]ui.Widget,
}

app := App{}

draw :: proc(canvas: ^cv.Canvas) {
	gl.ClearColor(147.0 / 255.0, 204.0 / 255., 234. / 255., 1.0)
	gl.Clear(gl.COLOR_BUFFER_BIT)

	cv.draw_rect(
		canvas,
		0,
		0,
		f32(canvas.width),
		f32(canvas.height),
		{color = {0.0, 0.0, 0.0, 1.0}, shader = platform.get_shader("Singularity")},
	)

	gl.Enable(gl.BLEND)
	gl.BlendFunc(gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA)

	for &widget in app.widget_list {
		#partial switch &w in widget {
		case ui.List(string):
			ui.draw(&w, canvas)
		case ui.List(actions.Action):
			ui.draw(&w, canvas)
		case ui.InputText:
			ui.draw(&w, canvas)
		}
	}
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

	c1 := engine.create_canvas(WIDTH, HEIGHT, cv.CanvasType.Window, draw)

	search := ui.InputText {
		x    = 0,
		y    = 0,
		w    = f32(c1.width),
		h    = 50,
		font = engine.state.font,
		text = "",
	}

	list := ui.List(actions.Action) {
		x     = 0,
		y     = 50,
		w     = f32(c1.width),
		h     = f32(c1.height) - 50,
		items = action_items[:],
		font  = &engine.state.font,
	}

	layout: ui.Layout = {
		root = ui.Split {
			type = .Vertical,
			size = 100,
			size_t = .Abs,
			children = {
				ui.Leaf{widget = &search, size = 50, size_t = .Abs},
				ui.Leaf{widget = &list, size = 100, size_t = .Per},
			},
		},
	}
	ui.layout_resize_leafs(layout, 0, 0, u32(c1.width), u32(c1.height), 0)
	fmt.println(search, list)

	append(&app.widget_list, search)
	append(&app.widget_list, list)

	fmt.println("LOOOOAD")
	platform.new_shader(
		"Singularity",
		#load("shaders/basic_vert.glsl"),
		#load("shaders/singularity.glsl"),
	)
	platform.new_shader(
		"Starship",
		#load("shaders/basic_vert.glsl"),
		#load("shaders/starship.glsl"),
	)
	platform.new_shader("Cosmic", #load("shaders/basic_vert.glsl"), #load("shaders/cosmic.glsl"))

	previous_search := ""

	for engine.state.running == true {
		s := &app.widget_list[0].(ui.InputText)
		l := &app.widget_list[1].(ui.List(actions.Action))

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
			ui.list_reset(l)
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
				case ui.List(actions.Action):
					ui.update(&w, event)
				case ui.List(string):
					ui.update(&w, event)
				case ui.InputText:
					ui.update(&w, event)
				}
			}
		}
		engine.render(c1)
	}
}
