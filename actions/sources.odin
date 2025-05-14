package actions

import "core:encoding/ini"
import "core:fmt"
import "core:os"
import "core:strings"


// refactor this whole mess into a proper abstraction...
Action :: struct {
	name:    string,
	icon:    u32,
	command: string,
}

ApplicationsSource :: struct {}

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

			de, ok := res["Desktop Entry"]
			if ok {
				name, _ := de["Name"]
				exec, _ := de["Exec"]
				if ok {
					append(&applications, Action{name = name, command = exec})
				}
			}
		}
	}

	return applications[:]
}

get_actions :: proc {
	get_application_actions,
}

// do_action :: proc {
//     do_application_action
// }
