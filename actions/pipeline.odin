package actions

import "core:fmt"
import "core:io"
import "core:os/os2"
import "core:strings"

import "../engine"

PipelineAction :: struct {
	name:   string,
	output: string,
}

compute_pipeline_actions :: proc() -> []Action {
	actions: [dynamic]Action
	buf: []u8 = make([]u8, 1000)
	io.read_full(os2.stdin.stream, buf)

	for line in strings.split(string(buf), "\n") {
		append(&actions, PipelineAction{name = line, output = line})
	}
	return actions[:]
}

do_pipeline_action :: proc(action: PipelineAction) {
	fmt.println(action.output)

	engine.state.running = false
}
