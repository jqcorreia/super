package main

import "base:runtime"
import "core:c"
import "core:fmt"
import "core:os"
import "core:strings"
import "core:time"

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

	for &widget in app.widget_list {
		#partial switch &w in widget {
		case widgets.List(string):
			widgets.draw(&w, canvas)
		case widgets.InputText:
			widgets.draw(&w, canvas)
		}
	}

	gl.Enable(gl.BLEND)
	canvas->draw_rect(
		0,
		0,
		f32(canvas.width),
		f32(canvas.height),
		color = {0.0, 0.0, 1.0, 1.0},
		shader = platform.inst().shaders->get("Border"),
	)
	gl.Disable(gl.BLEND)

	gl.Flush()
}

get_applications :: proc() -> []string {
	applications: [dynamic]string
	paths: [dynamic]string = {}
	home := os.get_env("HOME")
	xdg_data_dirs, ok := os.lookup_env("XDG_DATA_DIRS")

	if ok {
		for base_data in strings.split(xdg_data_dirs, ":") {
			append(&paths, fmt.tprintf("%s/applications", base_data))
		}
	} else {
		append(&paths, fmt.tprintf("%s/.local/share/applications", home))
		append(&paths, "/usr/share/applications")
	}


	for path in paths {
		// List dir files
		h, _ := os.open(path)
		fis, _ := os.read_dir(h, -1)

		for fi in fis {
			res, _, _ := ini.load_map_from_path(fi.fullpath, context.temp_allocator)

			de, ok := res["Desktop Entry"]
			if ok {
				name, ok := de["Name"]

				if ok {
					append(&applications, name)
				}
			}
		}
	}

	return applications[:]
}

main :: proc() {
	sys_apps := get_applications()
	fmt.println("Number of apps detected:", len(sys_apps))

	c1 := engine.create_canvas(WIDTH, HEIGHT, canvas.CanvasType.Layer, draw)

	search := widgets.InputText {
		x    = 0,
		y    = 0,
		font = engine.state.font,
		text = "",
	}

	list := widgets.List(string) {
		x         = 0,
		y         = 200,
		w         = f32(c1.width),
		h         = f32(c1.height) - 200,
		items     = sys_apps,
		font      = &engine.state.font,
		draw_item = widgets.list_default_draw_item,
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
		l := &app.widget_list[1].(widgets.List(string))

		// Really simple 'search'
		if s.text != previous_search {
			if s.text == "" {
				l.items = sys_apps
			} else {
				new_items: [dynamic]string
				for i in sys_apps {
					if strings.contains(strings.to_lower(i), strings.to_lower(s.text)) {
						append(&new_items, i)
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
				}
			}
			for &widget in app.widget_list {
				#partial switch &w in widget {
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
