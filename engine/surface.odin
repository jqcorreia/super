package engine

import wl "../wayland-odin/wayland"
import "core:fmt"
import "vendor:egl"

Surface :: struct {
	width:       i32,
	height:      i32,
	surface:     ^wl.wl_surface,
	egl_surface: egl.Surface,
}

create_surface :: proc(state: ^State, width: i32, height: i32) -> Surface {
	surface: Surface = {}
	surface.width = width
	surface.height = height
	surface.surface = wl.wl_compositor_create_surface(state.compositor)

	if surface.surface == nil {
		fmt.println("Error creating surface")
		return surface
	}

	egl_window := wl.egl_window_create(state.surface, width, height)
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


	return surface
}
