package engine

import wl "../wayland-odin/wayland"
import "../xkbcommon"
import "base:runtime"
import "core:c"
import "core:fmt"
import "core:sys/posix"

KeyPressed :: struct {
	key: c.uint32_t,
}

KeyReleased :: struct {
	key: c.uint32_t,
}

InputEvent :: union {
	KeyPressed,
	KeyReleased,
}

Input :: struct {
	events: [dynamic]InputEvent,
}

seat_listener := wl.wl_seat_listener {
	capabilities = proc "c" (data: rawptr, wl_seat: ^wl.wl_seat, capabilities: c.uint32_t) {
		context = runtime.default_context()
		fmt.println("Input capabilities: ", capabilities)
		state := cast(^State)data
		pointer := wl.wl_seat_get_pointer(state.seat)
		wl.wl_pointer_add_listener(pointer, &pointer_listener, state)
		keyboard := wl.wl_seat_get_keyboard(state.seat)
		wl.wl_keyboard_add_listener(keyboard, &keyboard_listener, state)
	},
	name = proc "c" (data: rawptr, wl_seat: ^wl.wl_seat, name: cstring) {
		context = runtime.default_context()
		fmt.println("Name: ", name)
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
		// This event contains a file descriptor for the current keymap in xkb formaty
		context = runtime.default_context()
		state := cast(^State)data
		fmt.println("Keymap: ", format, fd, size)
		buf := posix.mmap(
			nil,
			uint(size),
			{posix.Prot_Flag_Bits.READ},
			{posix.Map_Flag_Bits.PRIVATE},
			cast(posix.FD)fd,
		)
		fmt.println(cast(cstring)buf)
		ctx := xkbcommon.context_new(10)
		km := xkbcommon.keymap_new_from_string(
			ctx,
			cstring(buf),
			xkbcommon.keymap_format.XKB_KEYMAP_FORMAT_TEXT_V1,
			xkbcommon.keymap_compile_flags.XKB_KEYMAP_COMPILE_NO_FLAGS,
		)
		ks := xkbcommon.state_new(km)
		state.keymap_state = ks
		fmt.println(km)
		fmt.println(ks)
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
	key = proc "c" (
		data: rawptr,
		keyboard: ^wl.wl_keyboard,
		serial: c.uint32_t,
		time: c.uint32_t,
		key: c.uint32_t,
		state: c.uint32_t,
	) {
		context = runtime.default_context()
		_state := cast(^State)data
		keycode := key + 8 // This converts evdev events 
		if state == 0 {
			event := KeyPressed {
				key = key,
			}
			buf: [16]u8
			xkbcommon.state_key_get_utf8(_state.keymap_state, keycode, cstring(&buf[0]), 128)
			fmt.println("!!!!", buf)
			fmt.println("????", string(buf[:]))

			// fmt.println(xkbcommon.state_key_get_one_sym(_state.keymap_state, keycode))
			append(&_state.input.events, event)
		}

		if state == 1 {
			event := KeyReleased {
				key = key,
			}
			state := cast(^State)data
			append(&_state.input.events, event)
		}
	},
	modifiers = proc "c" (
		data: rawptr,
		wl_keyboard: ^wl.wl_keyboard,
		serial: c.uint32_t,
		mods_depressed: c.uint32_t,
		mods_latched: c.uint32_t,
		mods_locked: c.uint32_t,
		group: c.uint32_t,
	) {
	},
	repeat_info = proc "c" (
		data: rawptr,
		wl_keyboard: ^wl.wl_keyboard,
		rate: c.int32_t,
		delay: c.int32_t,
	) {},
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
		fmt.println("Pointer enter")
	},
	leave = proc "c" (
		data: rawptr,
		wl_pointer: ^wl.wl_pointer,
		serial: c.uint32_t,
		surface: ^wl.wl_surface,
	) {
		context = runtime.default_context()
		fmt.println("Pointer leave")
	},
	motion = proc "c" (
		data: rawptr,
		wl_pointer: ^wl.wl_pointer,
		time: c.uint32_t,
		surface_x: wl.wl_fixed_t,
		surface_y: wl.wl_fixed_t,
	) {
		context = runtime.default_context()
		// fmt.println("Pointer motion", surface_x, surface_y)
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

init_input :: proc(state: ^State) {
	fmt.println("Initializing input controller.")
	input := new(Input)
	input.events = make([dynamic]InputEvent)

	wl.wl_seat_add_listener(state.seat, &seat_listener, state)
	state.input = input
}

consume_all_events :: proc(input: ^Input) -> [dynamic]InputEvent {
	events: [dynamic]InputEvent
	for event in input.events {
		append(&events, event)
	}
	clear(&input.events)

	return events
}
