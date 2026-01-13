package engine

import "base:runtime"
import "core:fmt"
import "core:time"

import pl "../platform"
import "../platform/canvas"
import fonts "../platform/fonts"
import wl "../vendor/wayland-odin/wayland"
import "core:log"
import "vendor:egl"


EngineState :: struct {
	start_time:   time.Time,
	time_elapsed: time.Duration,
	running:      bool,
	font:         fonts.Font,
	images:       pl.ImageManager,
}


FONT :: "JetBrainsMono Nerd Font"

state: ^EngineState

@(init)
init :: proc "contextless" () {
	context = runtime.default_context()
	context.logger = log.create_console_logger()

	state = new(EngineState)
	pl.init_platform()
	state.start_time = time.now()

	state.running = true

	fm := fonts.new_font_manager()

	font_buf := #load("../assets/JetBrainsMonoNerdFont-Regular.ttf")

	state.font = fonts.load_font(
		&fm,
		FONT,
		24,
		fonts.FontBuffer{buffer = font_buf, buf_size = u64(len(font_buf))},
	)

	state.images = pl.new_image_manager()
}

create_canvas :: proc(
	width: u32,
	height: u32,
	type: canvas.CanvasType,
	draw_proc: canvas.CanvasDrawProc,
) -> ^canvas.Canvas {
	return canvas.create_canvas(pl.inst(), width, height, type, draw_proc)
}
render :: proc(canv: ^canvas.Canvas) {
	if canv.frame_requested {
		canv->draw_proc()
		callback := wl.wl_surface_frame(canv.surface)
		canv.frame_requested = false
		cc := new(canvas.CanvasCallback)
		cc.platform_state = pl.inst()
		cc.canvas = canv
		wl.wl_callback_add_listener(callback, &canvas.frame_callback, cc)
		egl.SwapBuffers(pl.inst().egl_render_context.display, canv.egl_surface)
	}
	pl.render(pl.inst())
}
