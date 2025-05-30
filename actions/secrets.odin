package actions

import "../engine"
import "core:fmt"
import "core:os"
import "core:os/os2"
import "core:strings"

SecretAction :: struct {
	name: string,
	icon: u32,
}

do_secret_action :: proc(action: SecretAction) {
	// This weird dance is needed for 2 reasons
	// - There is no way of knowing if a pass secret is otp unless you decode it first and check
	// - If you call process_exec with wl-copy, given that it is a process that doesn't exit, we just hang
	// - Do the check and call the process_start() that doesn't hang and let wl-copy do it's thing
	pass_command := []string{"sh", "-c", fmt.tprintf("pass %s", action.name)}
	_, out, _, _ := os2.process_exec({command = pass_command}, context.allocator)

	out_s := string(out)
	if strings.starts_with(out_s, "otpauth://") {
		pass_command_otp := []string{"sh", "-c", fmt.tprintf("pass otp %s", action.name)}
		_, out_otp, _, _ := os2.process_exec({command = pass_command_otp}, context.allocator)
		_, _ = os2.process_start({command = {"wl-copy", strings.trim(string(out_otp), "\n")}})
	} else {
		_, _ = os2.process_start({command = {"wl-copy", strings.trim(string(out_s), "\n")}})
	}

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
