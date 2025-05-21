package xdg

import "core:encoding/ini"
import "core:fmt"
import "core:os"
import "core:path/filepath"
import "core:slice"
import "core:strconv"
import "core:strings"

Icon :: struct {
	path: string,
}

IconLookup :: struct {
	name: string,
	size: u32,
}

IconManager :: struct {
	icon_map: map[IconLookup]Icon,
	sizes:    map[u32]bool, // Use this as a set
}

icon_manager: IconManager

icon_manager_get_icon :: proc(il: IconLookup) -> (Icon, bool) {
	if il.name != "" && il.name[0] == '/' {
		// This means that this is a file just the Icon with this path
		return Icon{path = il.name}, true
	}

	if icon, ok := icon_manager.icon_map[il]; ok {
		return icon, ok
	}

	sizes, _ := slice.map_keys(icon_manager.sizes)
	slice.reverse_sort(sizes)

	// Scan different sizes until one appears
	// In this case we are going from largest to smallest
	// FIXME(quadrado): We can do better here to try and find the closest match
	for size in sizes {
		if icon, size_ok := icon_manager.icon_map[IconLookup{name = il.name, size = size}];
		   size_ok {
			return icon, size_ok
		}
	}
	return Icon{}, false
}

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
@(init)
generate_icon_map :: proc() {
	icon_manager.icon_map = make(map[IconLookup]Icon)
	icon_manager.sizes = make(map[u32]bool)

	home := os.get_env("HOME")
	xdg_data_dirs :=
		os.lookup_env("XDG_DATA_DIRS") or_else fmt.tprintf("/usr/share:%s/.local/share", home)

	base_folders := strings.split(xdg_data_dirs, ":")
	themes: []string = {"hicolor"}
	for theme in themes {
		for base_folder in base_folders {
			path := fmt.tprintf("%s/icons/%s/index.theme", base_folder, theme)
			res, _, _ := ini.load_map_from_path(path, context.temp_allocator)
			dirs: []string
			if it, ok := res["Icon Theme"]; ok {
				if _dirs, ok2 := it["Directories"]; ok2 {
					dirs = strings.split(_dirs, ",")
				}
			}

			// fmt.println(dirs)
			for base_folder2 in base_folders {
				for dir in dirs {
					if section, ok3 := res[dir]; ok3 {
						size, _ := strconv.parse_int(section["Size"] or_else "1")
						scale, _ := strconv.parse_int(section["Scale"] or_else "1")
						// fmt.println(section, size, scale)
						if scale > 1 {
							// Ignore scaled icon for now
							continue
						}
						d := fmt.tprintf("%s/icons/%s/%s", base_folder2, theme, dir)
						h, _ := os.open(d)
						fis, _ := os.read_dir(h, -1)
						for fi in fis {
							stem := filepath.stem(fi.name)
							icon_manager.icon_map[IconLookup{name = stem, size = u32(size)}] =
								Icon {
									path = fi.fullpath,
								}
						}
						icon_manager.sizes[u32(size)] = true
					}
				}
			}
		}
	}

	//let home = std::env::var("HOME").unwrap();
	//let mut map: HashMap<IconConfig, String> = HashMap::new();
	//let mut sizes: HashSet<u32> = HashSet::new();

	//let env_folders = std::env::var("XDG_DATA_DIRS")
	//    .unwrap_or(format!("/usr/share:{}/.local/share", home).to_string());

	//let base_folders = env_folders.split(":");

	//let mut themes = vec!["hicolor".to_string()];

	//if let Some(theme_name) = get_gtk_settings_theme() {
	//    themes.push(theme_name);
	//}
	//for theme in themes {
	//    // Try to find and parse the index.theme file for the theme being processed
	//    for base_folder in base_folders.clone() {
	//        let path = format!("{}/icons/{}/index.theme", base_folder, theme);

	//        let ini: IniMap = match parse_ini_file(path.clone()) {
	//            Ok(i) => i,
	//            Err(_) => continue,
	//        };

	//        let dirs: Vec<String> = ini
	//            .get("Icon Theme")
	//            .unwrap()
	//            .get("Directories")
	//            .unwrap()
	//            .split(",")
	//            .map(|x| x.to_string())
	//            .filter(|x| !x.is_empty())
	//            .collect();

	//        // Traverse the base_folders again to include all the icons that may exist for this theme
	//        for base_folder in base_folders.clone() {
	//            for dir in dirs.iter() {
	//                if ini.get(dir).is_none() {
	//                    debug!("Section {} not found", dir);
	//                    continue;
	//                }
	//                let section = ini.get(dir).unwrap();
	//                let size: u32 = section.get("Size").unwrap().parse().unwrap();
	//                let scale = section.get("Scale").map_or("1", |v| v);

	//                if scale.parse::<u32>().unwrap() > 1 {
	//                    //FIXME(quadrado): For now ignore scaled icons
	//                    continue;
	//                }
	//                sizes.insert(size);

	//                let d = format!("{}/icons/{}/{}", base_folder, theme, dir);
	//                if let Ok(files) = fs::read_dir(d) {
	//                    for file in files {
	//                        let fpath =
	//                            file.unwrap().path().into_os_string().into_string().unwrap();

	//                        let fname_no_ext = std::path::Path::new(&fpath)
	//                            .file_stem()
	//                            .unwrap()
	//                            .to_os_string()
	//                            .to_str()
	//                            .unwrap()
	//                            .to_string();

	//                        //fpath.split("/").last().unwrap().split(".").next().unwrap();

	//                        // println!("{} {}", fname_no_ext, fpath);
	//                        let icon_config = IconConfig {
	//                            size,
	//                            name: fname_no_ext,
	//                        };
	//                        map.insert(icon_config, fpath);
	//                    }
	//                }
	//            }
	//        }
	//        // index.theme found and processed, can exit now
	//        break;
	//    }
	//}

	//// Process /usr/share/pixmaps
	//if let Ok(files) = fs::read_dir("/usr/share/pixmaps/") {
	//    for file in files {
	//        if file.as_ref().unwrap().file_type().unwrap().is_dir() {
	//            continue;
	//        }
	//        let fpath = file.unwrap().path().into_os_string().into_string().unwrap();
	//        let fname_no_ext = fpath.split("/").last().unwrap().split(".").next().unwrap();

	//        let icon_config = IconConfig {
	//            size: 32, //FIXME(quadrado): Don't use this fixed size that means nothing. Need
	//            //to open the image and calculate the proper size.
	//            name: fname_no_ext.to_string(),
	//        };
	//        map.insert(icon_config, fpath);
	//    }
	//}

	//(map, sizes)
}
