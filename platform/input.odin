package platform

import wl "../vendor/wayland-odin/wayland"
import "../vendor/xkbcommon"
import "base:runtime"
import "core:c"
import "core:log"
import "core:os"
import "core:strings"
import "core:sys/posix"
import "core:time"
import "vendor:x11/xlib"

KeySym :: xlib.KeySym

Modifiers :: enum u32 {
	Shift = 1,
	Ctrl  = 4,
	Alt   = 8,
	Super = 64,
}


KeyPressed :: struct {
	key:       KeySym,
	keycode:   u32,
	serial:    u32,
	modifiers: bit_set[Modifiers],
}

KeyReleased :: struct {
	key:    KeySym,
	serial: u32,
}

TextInput :: struct {
	text: string,
}

InputEvent :: union {
	KeyPressed,
	KeyReleased,
	TextInput,
}

Input :: struct {
	xkb:                     Xkb,
	events:                  [dynamic]InputEvent,
	consume_all_events:      proc(input: ^Input) -> [dynamic]InputEvent,
	current_modifiers:       bit_set[Modifiers],
	repeat_rate:             u32,
	repeat_delay:            u32,
	current_press:           KeyPressed,
	current_press_timestamp: time.Time,
	delay_hit:               bool,
}

Xkb :: struct {
	keymap:  ^xkbcommon.xkb_keymap,
	state:   ^xkbcommon.xkb_state,
	compose: ^xkbcommon.xkb_compose_state,
}

seat_listener := wl.wl_seat_listener {
	capabilities = proc "c" (data: rawptr, wl_seat: ^wl.wl_seat, capabilities: c.uint32_t) {
		context = runtime.default_context()
		log.debug("Input capabilities: ", capabilities)
		state := cast(^PlatformState)data
		pointer := wl.wl_seat_get_pointer(state.seat)
		wl.wl_pointer_add_listener(pointer, &pointer_listener, state)
		keyboard := wl.wl_seat_get_keyboard(state.seat)
		wl.wl_keyboard_add_listener(keyboard, &keyboard_listener, state)
	},
	name = proc "c" (data: rawptr, wl_seat: ^wl.wl_seat, name: cstring) {
		context = runtime.default_context()
		log.debug("Seat Name: ", name)
	},
}

keyboard_listener := wl.wl_keyboard_listener {
	keymap = proc "c" (
		data: rawptr,
		keyboard: ^wl.wl_keyboard,
		format: c.uint32_t,
		fd: c.int32_t,
		size: c.uint32_t,
	) {
		// This event contains a file descriptor for the current keymap in xkb format
		context = runtime.default_context()
		state := cast(^PlatformState)data
		log.debug("Keymap: ", format, fd, size)
		buf := posix.mmap(
			nil,
			uint(size),
			{posix.Prot_Flag_Bits.READ},
			{posix.Map_Flag_Bits.PRIVATE},
			cast(posix.FD)fd,
		)

		// Initialize xkb with context keymap and compose from locale
		ctx := xkbcommon.context_new(10)
		km := xkbcommon.keymap_new_from_string(
			ctx,
			cstring(buf),
			xkbcommon.keymap_format.XKB_KEYMAP_FORMAT_TEXT_V1,
			xkbcommon.keymap_compile_flags.XKB_KEYMAP_COMPILE_NO_FLAGS,
		)
		ks := xkbcommon.state_new(km)

		locale := os.get_env("LC_ALL")
		if len(locale) == 0 do locale = os.get_env("LANG")
		if len(locale) == 0 do locale = "POSIX"
		compose_table := xkbcommon.compose_table_new_from_locale(
			ctx,
			strings.clone_to_cstring(locale),
			0,
		)
		compose := xkbcommon.compose_state_new(compose_table, 0)

		state.input.xkb = Xkb {
			keymap  = km,
			state   = ks,
			compose = compose,
		}

		// Unmap and close fd
		posix.munmap(buf, uint(size))
		posix.close(cast(posix.FD)fd)
	},
	enter = proc "c" (
		data: rawptr,
		keyboard: ^wl.wl_keyboard,
		serial: c.uint32_t,
		surface: ^wl.wl_surface,
		keys: ^wl.wl_array,
	) {
	},
	leave = proc "c" (
		data: rawptr,
		keyboard: ^wl.wl_keyboard,
		serial: c.uint32_t,
		surface: ^wl.wl_surface,
	) {
	},
	key = key_handler,
	modifiers = proc "c" (
		data: rawptr,
		wl_keyboard: ^wl.wl_keyboard,
		serial: c.uint32_t,
		mods_depressed: c.uint32_t,
		mods_latched: c.uint32_t,
		mods_locked: c.uint32_t,
		group: c.uint32_t,
	) {
		context = runtime.default_context()
		state := cast(^PlatformState)data
		xkbcommon.state_update_mask(
			state.input.xkb.state,
			mods_depressed,
			mods_latched,
			mods_locked,
			0,
			0,
			0,
		)
		// This is shady but it works. Converting to u64 since bit_set[Modifiers] is a 8 byte value
		current_mods := transmute(bit_set[Modifiers])u64(mods_depressed)

		// This would be expanded version of the above
		// current_mods: bit_set[Modifiers]
		// if mods_depressed & u32(Modifiers.Alt) > 0 {
		// 	current_mods = current_mods + {.Alt}
		// }
		// if mods_depressed & u32(Modifiers.Ctrl) > 0 {
		// 	current_mods = current_mods + {.Ctrl}
		// }
		// if mods_depressed & u32(Modifiers.Shift) > 0 {
		// 	current_mods = current_mods + {.Shift}
		// }
		// if mods_depressed & u32(Modifiers.Super) > 0 {
		// 	current_mods = current_mods + {.Super}
		// }

		state.input.current_modifiers = current_mods
	},
	repeat_info = proc "c" (
		data: rawptr,
		wl_keyboard: ^wl.wl_keyboard,
		rate: c.int32_t,
		delay: c.int32_t,
	) {
		state := cast(^PlatformState)data

		state.input.repeat_rate = u32(rate)
		state.input.repeat_delay = u32(delay)
	},
}

pointer_listener := wl.wl_pointer_listener {
	enter = proc "c" (
		data: rawptr,
		wl_pointer: ^wl.wl_pointer,
		serial: c.uint32_t,
		surface: ^wl.wl_surface,
		surface_x: wl.wl_fixed_t,
		surface_y: wl.wl_fixed_t,
	) {
		context = runtime.default_context()
	},
	leave = proc "c" (
		data: rawptr,
		wl_pointer: ^wl.wl_pointer,
		serial: c.uint32_t,
		surface: ^wl.wl_surface,
	) {
		context = runtime.default_context()
	},
	motion = proc "c" (
		data: rawptr,
		wl_pointer: ^wl.wl_pointer,
		time: c.uint32_t,
		surface_x: wl.wl_fixed_t,
		surface_y: wl.wl_fixed_t,
	) {
		context = runtime.default_context()
	},
	button = proc "c" (
		data: rawptr,
		wl_pointer: ^wl.wl_pointer,
		serial: c.uint32_t,
		time: c.uint32_t,
		button: c.uint32_t,
		state: c.uint32_t,
	) {},
	axis = proc "c" (
		data: rawptr,
		wl_pointer: ^wl.wl_pointer,
		time: c.uint32_t,
		axis: c.uint32_t,
		value: wl.wl_fixed_t,
	) {},
	frame = proc "c" (data: rawptr, wl_pointer: ^wl.wl_pointer) {},
	axis_source = proc "c" (data: rawptr, wl_pointer: ^wl.wl_pointer, axis_source: c.uint32_t) {},
	axis_stop = proc "c" (
		data: rawptr,
		wl_pointer: ^wl.wl_pointer,
		time: c.uint32_t,
		axis: c.uint32_t,
	) {},
	axis_discrete = proc "c" (
		data: rawptr,
		wl_pointer: ^wl.wl_pointer,
		axis: c.uint32_t,
		discrete: c.int32_t,
	) {},
	axis_value120 = proc "c" (
		data: rawptr,
		wl_pointer: ^wl.wl_pointer,
		axis: c.uint32_t,
		value120: c.int32_t,
	) {},
	axis_relative_direction = proc "c" (
		data: rawptr,
		wl_pointer: ^wl.wl_pointer,
		axis: c.uint32_t,
		direction: c.uint32_t,
	) {},
}

key_handler :: proc "c" (
	data: rawptr,
	keyboard: ^wl.wl_keyboard,
	serial: c.uint32_t,
	t: c.uint32_t,
	key: c.uint32_t,
	state: c.uint32_t,
) {
	context = runtime.default_context()
	_state := cast(^PlatformState)data

	// This converts evdev events to xkb events 
	keycode := key + 8
	key_sym := xkbcommon.state_key_get_one_sym(_state.input.xkb.state, keycode)

	if state == 0 {
		event := KeyReleased {
			key = key_sym,
		}
		append(&_state.input.events, event)
		_state.input.current_press = {}
		_state.input.current_press_timestamp = time.now()
		_state.input.delay_hit = false
	}

	if state == 1 {
		event := KeyPressed {
			key       = key_sym,
			keycode   = keycode,
			modifiers = _state.input.current_modifiers,
		}

		process_key_press(_state.input, event)
	}
}

is_modifier := proc(key_sym: KeySym) -> bool {
	if key_sym != KeySym.XK_Control_L &&
	   key_sym != KeySym.XK_Control_R &&
	   key_sym != KeySym.XK_Shift_L &&
	   key_sym != KeySym.XK_Shift_R &&
	   key_sym != KeySym.XK_Alt_L &&
	   key_sym != KeySym.XK_Alt_L &&
	   key_sym != KeySym.XK_BackSpace &&
	   key_sym != KeySym.XK_Escape {
		return false
	}
	return true
}


process_key_press :: proc(input: ^Input, key_pressed: KeyPressed, repeating: bool = false) {
	key_sym := key_pressed.key
	keycode := key_pressed.keycode

	append(&input.events, key_pressed)
	if !repeating {
		input.current_press = key_pressed
		input.current_press_timestamp = time.now()
		input.delay_hit = false
	}


	if !is_modifier(key_sym) {
		xkbcommon.compose_state_feed(input.xkb.compose, c.uint32_t(key_sym))
		status := xkbcommon.compose_state_get_status(input.xkb.compose)
		buf: []byte = make([]byte, 4)
		if status == xkbcommon.xkb_compose_status.XKB_COMPOSE_COMPOSED {
			size := xkbcommon.compose_state_get_utf8(input.xkb.compose, cstring(&buf[0]), 4)
			if size > 0 {
				append(&input.events, TextInput{text = string(buf[:size])})
			}
		} else if status == xkbcommon.xkb_compose_status.XKB_COMPOSE_CANCELLED ||
		   status == xkbcommon.xkb_compose_status.XKB_COMPOSE_COMPOSING {
		} else if status == xkbcommon.xkb_compose_status.XKB_COMPOSE_NOTHING {
			size := xkbcommon.state_key_get_utf8(input.xkb.state, keycode, cstring(&buf[0]), 4)
			if size > 0 {
				append(&input.events, TextInput{text = string(buf[:size])})
			}
		} else {
			size := xkbcommon.compose_state_get_utf8(input.xkb.compose, cstring(&buf[0]), 4)
			if size > 0 {
				append(&input.events, TextInput{text = string(buf[:size])})
			}
		}
	}
}

init_input :: proc(state: ^PlatformState) {
	log.info("Initializing input controller.")
	input := new(Input)
	input.events = make([dynamic]InputEvent)
	input.consume_all_events = consume_all_events

	wl.wl_seat_add_listener(state.seat, &seat_listener, state)
	state.input = input
}

consume_all_events :: proc(input: ^Input) -> [dynamic]InputEvent {
	// FIXME(quadrado): This repeating code should go elsewhere, probably on platform update function
	if input.current_press != {} {
		diff := time.diff(input.current_press_timestamp, time.now())

		if input.delay_hit {
			if diff > time.Duration(input.repeat_rate) * time.Millisecond {
				process_key_press(input, input.current_press, repeating = true)
				// append(&input.events, input.current_press)
				input.current_press_timestamp = time.now()
			}
		} else {
			if diff > time.Duration(input.repeat_delay) * time.Millisecond {
				process_key_press(input, input.current_press, repeating = true)
				// append(&input.events, input.current_press)
				input.delay_hit = true
				input.current_press_timestamp = time.now()
			}
		}
	}

	events: [dynamic]InputEvent
	for event in input.events {
		append(&events, event)
	}
	clear(&input.events)

	return events
}
