package platform

import "base:runtime"
import "core:c"
import "core:log"
import wl "vendor/wayland-odin/wayland"

layer_listener := wl.zwlr_layer_surface_v1_listener {
	configure = proc "c" (
		data: rawptr,
		surface: ^wl.zwlr_layer_surface_v1,
		serial: c.uint32_t,
		width: c.uint32_t,
		height: c.uint32_t,
	) {
		context = runtime.default_context()
		log.debug("layer_configure")
		cc := cast(^CanvasCallback)data
		canvas := cc.canvas
		// state := cc.platform_state

		width := i32(width)
		height := i32(height)

		egl_render_context := cc.platform_state.egl_render_context
		if !canvas.ready || canvas.width != width || canvas.height != height {
			create_egl_window(canvas, egl_render_context, width, height)
			if (!cc.platform_state.default_resources_loaded) {
				load_default_resources()
				cc.platform_state.default_resources_loaded = true
			}
			canvas.width = width
			canvas.height = height
			canvas.ready = true
		}


		wl.zwlr_layer_surface_v1_ack_configure(surface, serial)
		// wl.wl_surface_damage(canvas.surface, 0, 0, c.INT32_MAX, c.INT32_MAX)
		// wl.wl_surface_commit(canvas.surface)
	},
}

init_layer_canvas :: proc(cc: ^CanvasCallback, width: u32, height: u32) {
	canvas := cc.canvas
	platform := cc.platform_state
	layer_surface := wl.zwlr_layer_shell_v1_get_layer_surface(
		platform.zwlr_layer_shell_v1,
		canvas.surface,
		nil,
		wl.ZWLR_LAYER_SHELL_V1_LAYER_OVERLAY,
		"test",
	)

	// Store it in canvas for resizing
	canvas.layer_surface = layer_surface
	wl.zwlr_layer_surface_v1_add_listener(layer_surface, &layer_listener, cc)
	wl.zwlr_layer_surface_v1_set_size(layer_surface, u32(width), u32(height))
	wl.zwlr_layer_surface_v1_set_anchor(
		layer_surface,
		0,
		// wl.ZWLR_LAYER_SURFACE_V1_ANCHOR_BOTTOM | wl.ZWLR_LAYER_SURFACE_V1_ANCHOR_RIGHT,
	)
	wl.zwlr_layer_surface_v1_set_keyboard_interactivity(
		layer_surface,
		wl.ZWLR_LAYER_SURFACE_V1_KEYBOARD_INTERACTIVITY_ON_DEMAND,
	)

}
