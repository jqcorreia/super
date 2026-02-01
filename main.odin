package main

import "core:strings"

import "actions"
import "core:fmt"
import "core:log"
import "core:mem"
import "core:os/os2"
import "core:sys/posix"
import "engine"
import pl "platform"
import "ui"
import gl "vendor:OpenGL"


WIDTH :: 800
HEIGHT :: 600


App :: struct {
	widget_list: [dynamic]ui.Widget,
}

app := App{}

draw :: proc(canvas: ^pl.Canvas) {
	gl.ClearColor(147.0 / 255.0, 204.0 / 255., 234. / 255., 1.0)
	gl.Clear(gl.COLOR_BUFFER_BIT)

	if ui.current_theme.background.color != nil {
		pl.draw_rect(
			canvas,
			0,
			0,
			f32(canvas.width),
			f32(canvas.height),
			{color = ui.current_theme.background.color^},
		)
	}
	if ui.current_theme.background.shader != "" {
		pl.draw_rect(
			canvas,
			0,
			0,
			f32(canvas.width),
			f32(canvas.height),
			{shader = pl.get_shader(ui.current_theme.background.shader)},
		)

	}

	gl.Enable(gl.BLEND)
	gl.BlendFunc(gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA)

	for &widget in app.widget_list {
		ui.draw_widget(&widget, canvas)
	}

	gl.Disable(gl.BLEND)
	gl.Flush()
}

check_stdin :: proc() -> bool {
	return cast(bool)posix.isatty(cast(posix.FD)(os2.fd(os2.stdin)))
}


main :: proc() {
	when ODIN_DEBUG {
		track: mem.Tracking_Allocator
		mem.tracking_allocator_init(&track, context.allocator)
		context.allocator = mem.tracking_allocator(&track)

		defer {
			if len(track.allocation_map) > 0 {
				fmt.eprintf("=== %v allocations not freed: ===\n", len(track.allocation_map))
				for _, entry in track.allocation_map {
					fmt.eprintf("- %v bytes @ %v\n", entry.size, entry.location)
				}
			}
			if len(track.bad_free_array) > 0 {
				fmt.eprintf("=== %v incorrect frees: ===\n", len(track.bad_free_array))
				for entry in track.bad_free_array {
					fmt.eprintf("- %p @ %v\n", entry.memory, entry.location)
				}
			}
			mem.tracking_allocator_destroy(&track)
		}
	}
	context.logger = log.create_console_logger()

	action_items: [dynamic]actions.Action

	if !check_stdin() {
		for i in actions.compute_pipeline_actions() {
			append(&action_items, i)
		}
	} else {
		app_items := actions.get_application_actions()
		secrets_items := actions.get_secret_actions()

		for i in app_items {
			append(&action_items, i)
		}
		for i in secrets_items {
			append(&action_items, i)
		}
	}


	// action_items += actions.get_secret_actions()
	log.log(.Debug, "Number of apps detected:", len(action_items))

	c1 := engine.create_canvas(WIDTH, HEIGHT, .Window, draw)

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
		root = {
			size = 100,
			size_t = .Abs,
			type = ui.Split {
				type = .Vertical,
				children = {
					{type = ui.Leaf{widget = &search}, size = 60, size_t = .Abs},
					{type = ui.Leaf{widget = &list}, size = 100, size_t = .Per},
				},
			},
		},
	}

	ui.layout_resize_leafs(layout, 0, 0, u32(c1.width), u32(c1.height), 4)

	append(&app.widget_list, search)
	append(&app.widget_list, list)

	pl.new_shader(
		"Singularity",
		#load("shaders/basic_vert.glsl"),
		#load("shaders/singularity.glsl"),
	)
	pl.new_shader("Starship", #load("shaders/basic_vert.glsl"), #load("shaders/starship.glsl"))
	pl.new_shader("Cosmic", #load("shaders/basic_vert.glsl"), #load("shaders/cosmic.glsl"))

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

		events := pl.inst().input->consume_all_events()
		for event in events {
			#partial switch e in event {
			case pl.KeyPressed:
				{
					if e.key == pl.KeySym.XK_Escape && e.modifiers == {} {
						engine.state.running = false
					}
					if e.key == pl.KeySym.XK_Return {
						selected_action := l.items[l.selected_index]
						actions.do_action(selected_action)
					}
					if e.key == pl.KeySym.XK_F1 {
						ui.change_theme()
						// ui.current_theme = ui.other_theme
					}
				}
			}
			for &widget in app.widget_list {
				ui.update_widget(&widget, event)
			}
		}
		engine.render(c1)
	}
}
