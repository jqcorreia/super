package actions

import "../engine"
import "core:encoding/ini"
import "core:fmt"
import "core:os"
import "core:os/os2"
import "core:strings"

import "../platform"
import "../utils/xdg"

ApplicationAction :: struct {
	name:    string,
	icon:    xdg.Icon,
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
				append(
					&applications,
					ApplicationAction{name = name, command = exec, icon = xdg.icon_map[icon]},
				)
			}
		}
	}

	return applications[:]
}

do_application_action :: proc(action: ApplicationAction) {
	// This removes the XDG placeholders like %F and %U and all that crap that we dont care
	// At least we don't care right now...
	clean_command := strings.trim(strings.split(action.command, "%")[0], " \n")
	p, e := os2.process_start({command = strings.split(clean_command, " ")})

	fmt.println(p, e)

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

// impl IconFinder {

//     pub fn new() -> IconFinder {
//         let (map, sizes) = generate_map();
//         IconFinder { map, sizes }
//     }
//     pub fn get_icon(&self, name: String) -> Option<String> {
//         let candidate: String;

//         // First check if icon identifier is a path
//         if name.starts_with("/") && fs::metadata(name.clone()).is_ok() {
//             candidate = name.clone();
//         } else {
//             let icon_config = IconConfig { name, size: 32 };
//             let opt = self.map.get(&icon_config);
//             opt?;
//             candidate = self.map.get(&icon_config).unwrap().to_string();
//         }

//         // Check if candidate is indeed a file
//         match std::fs::read(&candidate) {
//             Ok(_) => Some(candidate),
//             Err(_) => None,
//         }
//     }

//     pub fn get_icon_with_size(&self, name: String, size: u32) -> Option<String> {
//         fn check_file(path: String) -> Option<String> {
//             match std::fs::read(&path) {
//                 Ok(_) => Some(path),
//                 Err(_) => None,
//             }
//         }

//         // First check if icon identifier is a path
//         if name.starts_with("/") && fs::metadata(name.clone()).is_ok() {
//             return check_file(name);
//         }

//         // Check for exact match
//         if let Some(path) = self.map.get(&IconConfig {
//             name: name.clone(),
//             size,
//         }) {
//             return check_file(path.to_string());
//         }

//         // Scan different sizes until one appears
//         // In this case we are going from largest to smallest
//         // FIXME(quadrado): We can do better here to try and find the closest match
//         let mut _sizes: Vec<u32> = self.sizes.clone().into_iter().collect::<Vec<u32>>();
//         _sizes.sort();
//         _sizes.reverse();

//         for _size in _sizes {
//             let icon_config = IconConfig {
//                 name: name.clone(),
//                 size: _size,
//             };
//             if let Some(path) = self.map.get(&icon_config) {
//                 return check_file(path.to_string());
//             }
//         }
//         None
//     }
// }
