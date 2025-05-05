package engine

import wl "../vendor/wayland-odin/wayland"
import "../vendor/xkbcommon"

import "core:c"
import "core:fmt"
import "core:time"

// import "../widgets"
import pl "../platform"
import "../platform/canvas"
import "../vendor/libschrift-odin/sft"
import "base:runtime"
import gl "vendor:OpenGL"
import "vendor:egl"


State :: struct {
	start_time:   time.Time,
	time_elapsed: time.Duration,
	text:         string,
	running:      bool,
	font:         sft.SFT,
}


FONT :: "JetBrainsMono Nerd Font Mono"

state: ^State
platform: ^pl.PlatformState

@(init)
init :: proc() {
	state = new(State)
	platform = pl.init_platform()
	state.start_time = time.now()

	state.running = true

	// Load font(s)
	fm := pl.new_font_manager()

	state.font = fm->load_font(FONT, 72)
	state.text = ""
}

create_canvas :: proc(
	width: i32,
	height: i32,
	type: canvas.CanvasType,
	draw_proc: canvas.CanvasDrawProc,
) -> ^canvas.Canvas {
	return canvas.create_canvas(platform, width, height, type, draw_proc)
}

render :: proc() {
	pl.render(platform)
}
