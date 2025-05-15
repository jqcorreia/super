package actions

import "../engine"
import "core:encoding/ini"
import "core:fmt"
import "core:os"
import "core:os/os2"
import "core:strings"

Action :: union {
	ApplicationAction,
	SecretAction,
}

ApplicationAction :: struct {
	name:    string,
	icon:    u32,
	command: string,
}

SecretAction :: struct {
	name: string,
	icon: u32,
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

			de, ok := res["Desktop Entry"]
			if ok {
				name, _ := de["Name"]
				exec, _ := de["Exec"]
				if ok {
					append(&applications, ApplicationAction{name = name, command = exec})
				}
			}
		}
	}

	return applications[:]
}

do_application_action :: proc(action: ApplicationAction) {
	p, e := os2.process_start({command = strings.split(action.command, " ")})
	fmt.println(p, e)

	engine.state.running = false
}

do_secret_action :: proc(action: SecretAction) {
	// fn execute(&self, ctx: &mut App) {
	//     let pass_args = vec![
	//         "-c".to_string(),
	//         format!("pass {}", self.secret_name.to_string()),
	//     ];
	//     let pass_otp_args = vec![
	//         "-c".to_string(),
	//         format!("pass otp {}", self.secret_name.to_string()),
	//     ];

	//     let output = Command::new("sh").args(pass_args.clone()).output();
	//     let ot = String::from_utf8(output.unwrap().stdout).unwrap();

	//     if ot.starts_with("otpauth://") {
	//         let otp_output = Command::new("sh").args(pass_otp_args.clone()).output();
	//         let oot = String::from_utf8(otp_output.unwrap().stdout).unwrap();
	//         ctx.clipboard = Some(oot.clone());
	//     } else {
	//         ctx.clipboard = Some(ot);
	//     }
	//     ctx.should_hide = true;
	// }

	pass_command := []string{"sh", "-c", fmt.tprintf("pass %s | wl-copy", action.name)}

	fmt.println("shhhhhhh", action.name)
	// _, out, _, e := os2.process_exec({command = pass_command}, context.allocator)
	p, e := os2.process_start({command = pass_command})

	engine.state.running = false
}

get_secret_actions :: proc() -> []Action {
	secrets: [dynamic]Action

	secrets_path := fmt.tprintf("%s/.password-store", os.get_env("HOME"))
	home, _ := os.open(secrets_path)
	fis, _ := os.read_dir(home, -1)

	for fi in fis {
		if strings.starts_with(fi.name, ".") {
			continue
		}
		secret_name := strings.split(fi.name, ".gpg")[0]
		append(&secrets, SecretAction{name = secret_name})
	}

	return secrets[:]
}

do_action :: proc(action: Action) {
	switch a in action {
	case ApplicationAction:
		{
			_do_action(a)
		}
	case SecretAction:
		{
			_do_action(a)
		}
	}
}

_do_action :: proc {
	do_application_action,
	do_secret_action,
}
