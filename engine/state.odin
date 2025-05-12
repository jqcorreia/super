package engine

import wl "../vendor/wayland-odin/wayland"
import "../vendor/xkbcommon"

import "core:c"
import "core:fmt"
import "core:time"

import pl "../platform"
import "../platform/canvas"
import fonts "../platform/fonts"
import "../vendor/libschrift-odin/sft"
import "base:runtime"
import gl "vendor:OpenGL"
import "vendor:egl"


EngineState :: struct {
	start_time:   time.Time,
	time_elapsed: time.Duration,
	text:         string,
	running:      bool,
	font:         fonts.Font,
}


FONT :: "JetBrainsMono Nerd Font Mono"

state: ^EngineState

@(init)
init :: proc() {
	state = new(EngineState)
	pl.init_platform()
	state.start_time = time.now()

	state.running = true

	fm := fonts.new_font_manager()

	state.font = fm->load_font(FONT, 72)
	state.text = ""
}

create_canvas :: proc(
	width: i32,
	height: i32,
	type: canvas.CanvasType,
	draw_proc: canvas.CanvasDrawProc,
) -> ^canvas.Canvas {
	return canvas.create_canvas(pl.inst(), width, height, type, draw_proc)
}

render :: proc(canvas: ^canvas.Canvas) {
	pl.render(pl.inst())
	egl.SwapBuffers(pl.inst().egl_render_context.display, canvas.egl_surface)
}
