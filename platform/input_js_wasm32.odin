package platform

import "core:fmt"

KeyPressed :: struct {
	key: u32, //TODO we don't know yet what is this in wasm
}

KeyReleased :: struct {
	key: u32, //TODO we don't know yet what is this in wasm
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
	events:             [dynamic]InputEvent,
	consume_all_events: proc(input: ^Input) -> [dynamic]InputEvent,
}


init_input :: proc(state: ^PlatformState) {
	fmt.println("Initializing input controller.")
	input := new(Input)
	input.events = make([dynamic]InputEvent)
	input.consume_all_events = consume_all_events

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
