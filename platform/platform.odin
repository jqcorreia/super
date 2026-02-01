package platform

import "../platform/fonts"
import "core:c"
import "core:time"
import wl "vendor/wayland-odin/wayland"
import gl "vendor:OpenGL"
import "vendor:egl"

PlatformState :: struct {
	display:                  ^wl.wl_display,
	compositor:               ^wl.wl_compositor,
	xdg_base:                 ^wl.xdg_wm_base,
	zwlr_layer_shell_v1:      ^wl.zwlr_layer_shell_v1,
	seat:                     ^wl.wl_seat,
	data_device_manager:      ^wl.wl_data_device_manager,
	egl_render_context:       RenderContext,
	input:                    ^Input,
	shaders:                  ^Shaders,
	default_resources_loaded: bool,
	start_time:               time.Time,
	last_frame_time:          time.Time,
	time_elapsed:             time.Duration,
	delta_time:               time.Duration,
	font_manager:             fonts.FontManager,
	images:                   ImageManager,
	unit_square_vao:          u32,
	fps:                      u32,
}

@(private)
platform: ^PlatformState

inst :: proc() -> ^PlatformState {
	return platform
}

registry_listener := wl.wl_registry_listener {
	global        = global,
	global_remove = global_remove,
}

display_listener := wl.wl_display_listener{}

global :: proc "c" (
	data: rawptr,
	registry: ^wl.wl_registry,
	name: c.uint32_t,
	interface: cstring,
	version: c.uint32_t,
) {
	if interface == wl.wl_compositor_interface.name {
		state: ^PlatformState = cast(^PlatformState)data
		state.compositor = cast(^wl.wl_compositor)(wl.wl_registry_bind(
				registry,
				name,
				&wl.wl_compositor_interface,
				version,
			))
	}

	if interface == wl.xdg_wm_base_interface.name {
		state: ^PlatformState = cast(^PlatformState)data
		state.xdg_base = cast(^wl.xdg_wm_base)(wl.wl_registry_bind(
				registry,
				name,
				&wl.xdg_wm_base_interface,
				version,
			))
	}
	if interface == wl.zwlr_layer_shell_v1_interface.name {
		state: ^PlatformState = cast(^PlatformState)data
		state.zwlr_layer_shell_v1 = cast(^wl.zwlr_layer_shell_v1)(wl.wl_registry_bind(
				registry,
				name,
				&wl.zwlr_layer_shell_v1_interface,
				version,
			))
	}
	if interface == wl.wl_seat_interface.name {
		state: ^PlatformState = cast(^PlatformState)data
		state.seat = cast(^wl.wl_seat)(wl.wl_registry_bind(
				registry,
				name,
				&wl.wl_seat_interface,
				version,
			))
	}

	if interface == wl.wl_data_device_manager_interface.name {
		state: ^PlatformState = cast(^PlatformState)data
		state.data_device_manager = cast(^wl.wl_data_device_manager)(wl.wl_registry_bind(
				registry,
				name,
				&wl.wl_data_device_manager_interface,
				version,
			))
	}
}

global_remove :: proc "c" (data: rawptr, registry: ^wl.wl_registry, name: c.uint32_t) {
}

init_platform :: proc() {
	platform = new(PlatformState)
	display := wl.display_connect(nil)
	platform.display = display

	// Get registry, add a global listener and get things started
	// Do a roundtrip in order to get registry info and populate the wayland part of state
	registry := wl.wl_display_get_registry(display)
	wl.wl_registry_add_listener(registry, &registry_listener, platform)
	wl.display_roundtrip(display)

	// Initialize EGL and OpenGL
	rctx := init_egl(display)
	platform.egl_render_context = rctx

	// Load the OpenGL functions up to a given version.
	// 4.6 is the latest
	gl.load_up_to(int(4), 6, egl.gl_set_proc_address)

	// Initialize input controller
	init_input(platform)

	// Initialize clipboard controller
	// init_clipboard(platform)

	// Initialize shaders controller
	platform.shaders = create_shaders_controller()
	platform.default_resources_loaded = false

	// Font manager
	platform.font_manager = fonts.new_font_manager()
	// Image manager
	platform.images = new_image_manager()

	// Start time keeping
	platform.start_time = time.now()
	platform.last_frame_time = time.now()
}

load_default_resources :: proc() {
	// load default shaders
	new_shader("Basic", basic_vert, basic_frag)
	new_shader("Circle", basic_vert, circle_frag)
	new_shader("Rounded", basic_vert, rounded_rect_frag)
	new_shader("Border", basic_vert, border_rect_frag)
	new_shader("Text", solid_text_vert, solid_text_frag)
	new_shader("Texture", solid_text_vert, texture_frag)

	// create unit_square_vao, this will be used to draw all the rects
	platform.unit_square_vao, _ = get_quad(nil)
}

render :: proc(canvas: ^Canvas) {
	platform.time_elapsed = time.diff(platform.start_time, time.now())
	if canvas.redraw {

		// First draw canvas
		canvas_pre_draw(canvas)
		canvas->draw_proc()
		canvas_post_draw(canvas)

		// Get the callback and flag it already to not redraw
		callback := wl.wl_surface_frame(canvas.surface)
		canvas.redraw = false

		// Add the listener
		wl.wl_callback_add_listener(callback, &frame_callback, canvas)

		// Swap the buffers
		egl.SwapBuffers(platform.egl_render_context.display, canvas.egl_surface)

		// Calculate passage of time
		// FIMXE(quadrado): This delta time would be frame render timing.
		// Probably not the best to use to calculate movement or simulate stuff
		platform.delta_time = time.diff(platform.last_frame_time, time.now())
		platform.last_frame_time = time.now()
		platform.fps = u32(1000 / time.duration_milliseconds(platform.delta_time))
	}
	wl.display_dispatch(platform.display)
	wl.display_flush(platform.display)

}
