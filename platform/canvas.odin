package platform

import wl "vendor/wayland-odin/wayland"

import "base:runtime"
import "core:c"
import "core:fmt"
import "core:log"
import gl "vendor:OpenGL"
import "vendor:egl"


CanvasDrawProc :: proc(_: ^Canvas)

Canvas :: struct {
	width:         i32,
	height:        i32,
	surface:       ^wl.wl_surface,
	layer_surface: ^wl.zwlr_layer_surface_v1,
	egl_surface:   egl.Surface,
	egl_window:    ^wl.egl_window,
	draw_proc:     CanvasDrawProc,
	ready:         bool,
	redraw:        bool,
	num_samples:   i32,
	msaa:          CanvasMSAABuffers,
}

CanvasMSAABuffers :: struct {
	fbo:         u32,
	color_rbo:   u32,
	depth_rbo:   u32,
	resolve_fbo: u32,
	resolve_tex: u32,
}

CanvasType :: enum {
	Layer,
	Window,
	Modal,
}

CanvasCallback :: struct {
	platform_state: ^PlatformState,
	canvas:         ^Canvas,
}


resize_egl_window :: proc(
	canvas: ^Canvas,
	egl_render_context: RenderContext,
	width: i32,
	height: i32,
) {
	log.debug("Resize EGL window")
	wl.egl_window_resize(canvas.egl_window, c.int(width), c.int(height), 0, 0)

	// Resize viewport since EGL only resizes the buffer and doesn't touch OpenGL state at all
	gl.Viewport(0, 0, width, height)

	canvas.width = width
	canvas.height = height
	gl.DeleteRenderbuffers(1, &canvas.msaa.color_rbo)
	gl.DeleteRenderbuffers(1, &canvas.msaa.depth_rbo)
	gl.DeleteFramebuffers(1, &canvas.msaa.fbo)
	canvas.msaa = canvas_create_msaa_buffers(canvas)
}

create_egl_window :: proc(
	canvas: ^Canvas,
	egl_render_context: RenderContext,
	width: i32,
	height: i32,
) {
	log.debug("Recreate EGL window")
	egl_window := wl.egl_window_create(canvas.surface, canvas.width, canvas.height)
	egl_surface := egl.CreateWindowSurface(
		egl_render_context.display,
		egl_render_context.config,
		egl.NativeWindowType(egl_window),
		nil,
	)

	if egl_surface == egl.NO_SURFACE {
		log.error("Error creating window surface")
	}
	if (!egl.MakeCurrent(
			   egl_render_context.display,
			   egl_surface,
			   egl_surface,
			   egl_render_context.ctx,
		   )) {
		log.error("Error making current!")
	}

	canvas.egl_surface = egl_surface
	canvas.egl_window = egl_window
}

done :: proc "c" (data: rawptr, wl_callback: ^wl.wl_callback, callback_data: c.uint32_t) {
	context = runtime.default_context()
	canvas := cast(^Canvas)data

	canvas.redraw = true
	wl.wl_callback_destroy(wl_callback)
	// callback := wl.wl_surface_frame(canvas.surface)
	// wl.wl_callback_add_listener(callback, &frame_callback, canvas)

	// if canvas.ready {
	// 	canvas->draw_proc()
	// }
}

frame_callback := wl.wl_callback_listener {
	done = done,
}

create_canvas :: proc(
	width: u32,
	height: u32,
	type: CanvasType,
	draw_proc: CanvasDrawProc,
	num_samples: i32 = 0,
) -> ^Canvas {
	platform := inst()
	canvas := new(Canvas)
	canvas.width = i32(width)
	canvas.height = i32(height)
	canvas.surface = wl.wl_compositor_create_surface(platform.compositor)
	canvas.redraw = true

	if canvas.surface == nil {
		log.debug("Error creating surface")
		return canvas
	}

	cc := new(CanvasCallback, context.temp_allocator)
	cc.canvas = canvas
	cc.platform_state = platform

	log.debug("Create canvas")
	if type == CanvasType.Window {
		init_window_canvas(cc)
	}
	if type == CanvasType.Layer {
		init_layer_canvas(cc, width, height)
	}

	canvas.draw_proc = draw_proc

	wl_callback := wl.wl_surface_frame(canvas.surface)
	wl.wl_callback_add_listener(wl_callback, &frame_callback, canvas)
	wl.wl_surface_commit(canvas.surface)

	// Why should I need 2 of these in order to trigger the listeners and all that?
	// This makes me use display_dispatch_pending in the render loop in order not to block
	wl.display_dispatch(platform.display)
	wl.display_dispatch(platform.display)

	if num_samples > 0 {
		canvas.msaa = canvas_create_msaa_buffers(canvas)
		canvas.num_samples = num_samples
	}
	log.info("OpenGL version:", gl.GetString(gl.VERSION))
	log.info("Shading language version:", gl.GetString(gl.SHADING_LANGUAGE_VERSION))
	return canvas
}

canvas_create_msaa_buffers :: proc(canvas: ^Canvas) -> CanvasMSAABuffers {
	// Create multisampled buffers
	msaaFBO: u32 = 0
	colorRB: u32 = 0
	depthRB: u32 = 0

	samples: i32 = canvas.num_samples
	width: i32 = canvas.width
	height: i32 = canvas.height

	// FBO
	gl.GenFramebuffers(1, &msaaFBO)
	gl.BindFramebuffer(gl.FRAMEBUFFER, msaaFBO)

	// Multisampled color renderbuffer
	gl.GenRenderbuffers(1, &colorRB)
	gl.BindRenderbuffer(gl.RENDERBUFFER, colorRB)
	gl.RenderbufferStorageMultisample(gl.RENDERBUFFER, samples, gl.RGBA8, width, height)
	gl.FramebufferRenderbuffer(gl.FRAMEBUFFER, gl.COLOR_ATTACHMENT0, gl.RENDERBUFFER, colorRB)

	// Multisampled depth renderbuffer
	gl.GenRenderbuffers(1, &depthRB)
	gl.BindRenderbuffer(gl.RENDERBUFFER, depthRB)
	gl.RenderbufferStorageMultisample(
		gl.RENDERBUFFER,
		samples,
		gl.DEPTH_COMPONENT24,
		width,
		height,
	)
	gl.FramebufferRenderbuffer(gl.FRAMEBUFFER, gl.DEPTH_ATTACHMENT, gl.RENDERBUFFER, depthRB)

	// Validate FBO
	if (gl.CheckFramebufferStatus(gl.FRAMEBUFFER) != gl.FRAMEBUFFER_COMPLETE) {
		// handle error
	}

	gl.BindFramebuffer(gl.FRAMEBUFFER, 0)

	// Create resolve framebuffer and texture
	// This texture is meant to be then rendered directly to the whole screen
	resolveFBO: u32 = 0
	resolveTex: u32 = 0

	gl.GenFramebuffers(1, &resolveFBO)
	gl.BindFramebuffer(gl.FRAMEBUFFER, resolveFBO)

	gl.GenTextures(1, &resolveTex)
	gl.BindTexture(gl.TEXTURE_2D, resolveTex)
	gl.TexImage2D(gl.TEXTURE_2D, 0, gl.RGBA8, width, height, 0, gl.RGBA, gl.UNSIGNED_BYTE, nil)
	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR)
	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR)

	gl.FramebufferTexture2D(gl.FRAMEBUFFER, gl.COLOR_ATTACHMENT0, gl.TEXTURE_2D, resolveTex, 0)
	gl.BindFramebuffer(gl.FRAMEBUFFER, 0)
	gl.Flush()

	return {
		fbo = msaaFBO,
		color_rbo = colorRB,
		depth_rbo = depthRB,
		resolve_fbo = resolveFBO,
		resolve_tex = resolveTex,
	}
}

canvas_pre_draw :: proc(canvas: ^Canvas) {
	if canvas.num_samples == 0 do return

	gl.BindFramebuffer(gl.FRAMEBUFFER, canvas.msaa.fbo)
}

canvas_post_draw :: proc(canvas: ^Canvas) {
	if canvas.num_samples == 0 do return

	width, height := canvas.width, canvas.height

	gl.BindFramebuffer(gl.READ_FRAMEBUFFER, canvas.msaa.fbo)
	gl.BindFramebuffer(gl.DRAW_FRAMEBUFFER, canvas.msaa.resolve_fbo)

	gl.BlitFramebuffer(0, 0, width, height, 0, 0, width, height, gl.COLOR_BUFFER_BIT, gl.LINEAR)

	gl.BindFramebuffer(gl.DRAW_FRAMEBUFFER, 0)

	gl.Disable(gl.DEPTH_TEST)
	gl.DepthMask(gl.FALSE)
	draw_rect(
		canvas,
		0.0,
		0.0,
		f32(width),
		f32(height),
		{texture = canvas.msaa.resolve_tex, flip_texture_y = true},
	)
	gl.Enable(gl.DEPTH_TEST)
	gl.DepthMask(gl.TRUE)
}
