package engine

import "base:runtime"
import "core:time"

import pl "../platform"
import fonts "../platform/fonts"
import "core:log"


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
	type: pl.CanvasType,
	draw_proc: pl.CanvasDrawProc,
) -> ^pl.Canvas {
	return pl.create_canvas(width, height, type, draw_proc)
}

render :: proc(canv: ^pl.Canvas) {
	pl.render(canv)
}
