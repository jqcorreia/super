package engine

import wl "../wayland-odin/wayland"
import "core:fmt"
import "vendor:egl"

Canvas :: struct {
	width:       i32,
	height:      i32,
	surface:     ^wl.wl_surface,
	egl_surface: egl.Surface,
}

create_canvas :: proc(state: ^State, width: i32, height: i32) -> Canvas {
	canvas: Canvas = {}
	canvas.width = width
	canvas.height = height
	canvas.surface = wl.wl_compositor_create_surface(state.compositor)

	if canvas.surface == nil {
		fmt.println("Error creating surface")
		return canvas
	}

	egl_window := wl.egl_window_create(canvas.surface, width, height)
	egl_surface := egl.CreateWindowSurface(
		state.egl_render_context.display,
		state.egl_render_context.config,
		egl.NativeWindowType(egl_window),
		nil,
	)

	if egl_surface == egl.NO_SURFACE {
		fmt.println("Error creating window surface")

	}
	if (!egl.MakeCurrent(
			   state.egl_render_context.display,
			   egl_surface,
			   egl_surface,
			   state.egl_render_context.ctx,
		   )) {
		fmt.println("Error making current!")
	}

	canvas.egl_surface = egl_surface

	return canvas
}
