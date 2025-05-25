package actions

import "../engine"
import "core:encoding/ini"
import "core:fmt"
import "core:os"
import "core:os/os2"
import "core:strings"

import "../platform"

ApplicationAction :: struct {
	name:    string,
	icon:    string,
	command: string,
}
get_application_actions :: proc() -> []Action {
	applications: [dynamic]Action
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

			de, ok_entry := res["Desktop Entry"]
			if ok_entry {
				name, _ := de["Name"]
				exec, _ := de["Exec"]
				icon, _ := de["Icon"]
				append(&applications, ApplicationAction{name = name, command = exec, icon = icon})
			}
		}
	}

	return applications[:]
}

do_application_action :: proc(action: ApplicationAction) {
	// This removes the XDG placeholders like %F and %U and all that crap that we dont care
	// At least we don't care right now...
	clean_command := strings.trim(strings.split(action.command, "%")[0], " \n")
	_, _ = os2.process_start({command = strings.split(clean_command, " ")})

	engine.state.running = false
}

get_icon :: proc(name: string) -> platform.Image {
	path: string
	if strings.starts_with(name, "/") {
		path = name
	} else {

	}

	return engine.state.images->load(path)
}
