package engine

import "core:time"

import "../platform"
import "../platform/fonts"

State :: struct {
	platform_state: ^platform.PlatformState,
	start_time:     time.Time,
	time_elapsed:   time.Duration,
	text:           string,
	running:        bool,
	font:           fonts.SFT,
}


FONT :: "JetBrainsMono Nerd Font Mono"
// FONT :: "FreeSerif"

init :: proc(width: i32, height: i32) -> ^State {
	state := new(State)
	state.start_time = time.now()
	state.platform_state = platform.init_platform()

	state.running = true

	// Load font(s)
	fm := platform.new_font_manager()
	state.font = fm->load_font(FONT, 100)

	state.text = ""

	return state
}
