package platform

import "core:c"
import "core:log"
import wl "vendor/wayland-odin/wayland"
import "vendor:egl"

foreign import foo "system:EGL"

@(default_calling_convention = "c", link_prefix = "egl")
foreign foo {
	GetError :: proc() -> i32 ---
	GetConfigs :: proc(display: egl.Display, config: ^egl.Config, config_size: i32, num_config: ^i32) -> egl.Boolean ---
	ChooseConfig :: proc(display: egl.Display, attrib_list: ^i32, configs: ^egl.Config, config_size: i32, num_config: ^i32) -> egl.Boolean ---
}

RenderContext :: struct {
	display: egl.Display,
	ctx:     egl.Context,
	config:  egl.Config,
}

eglGetPlatformDisplayEXT :: proc "c" (
	platform: int,
	native_display: rawptr,
	attrib_list: []c.int,
) -> egl.Display


EGL_PLATFORM_DEVICE_EXT :: 0x313F
EGL_PLATFORM_GBM_KHR :: 0x31D7
EGL_PLATFORM_WAYLAND_KHR :: 0x31D8

EGL_SAMPLE_BUFFERS :: 12338
EGL_SAMPLES :: 12338
EGL_CONTEXT_FLAGS_KHR :: 0x30FC

EGL_CONTEXT_OPENGL_DEBUG_BIT_KHR :: 0x00000001
EGL_CONTEXT_OPENGL_FORWARD_COMPATIBLE_BIT_KHR :: 0x00000002
EGL_CONTEXT_OPENGL_ROBUST_ACCESS_BIT_KHR :: 0x00000004
init_egl :: proc(display: ^wl.wl_display) -> RenderContext {
	major, minor, n: i32
	count: i32 = 0
	configs: [^]egl.Config
	egl_conf: egl.Config
	config_attribs: []i32 = {
		egl.SURFACE_TYPE,
		egl.WINDOW_BIT,
		egl.RED_SIZE,
		8,
		egl.GREEN_SIZE,
		8,
		egl.BLUE_SIZE,
		8,
		egl.ALPHA_SIZE,
		0, // Disable surface alpha for now
		egl.DEPTH_SIZE,
		24, // Request 24-bit depth buffer
		egl.RENDERABLE_TYPE,
		egl.OPENGL_BIT,
		EGL_SAMPLE_BUFFERS,
		0,
		EGL_SAMPLES,
		0,
		egl.NONE,
	}
	context_flags_bitfield: i32 = EGL_CONTEXT_OPENGL_DEBUG_BIT_KHR

	context_attribs: []i32 = {
		egl.CONTEXT_CLIENT_VERSION,
		3,
		EGL_CONTEXT_FLAGS_KHR,
		context_flags_bitfield,
		egl.NONE,
	}
	egl_display := egl.GetDisplay(egl.NativeDisplayType(display))

	GetError() // clear error code
	if (egl_display == egl.NO_DISPLAY) {
		log.error("Can't create egl display")
	} else {
		log.info("Created egl display")
	}
	if (!egl.Initialize(egl_display, &major, &minor)) {
		log.error("Can't initialise egl display")
		log.errorf("Error code: 0x%x\n", GetError())
	}
	log.debugf("EGL major: %d, minor %d", major, minor)
	if (!GetConfigs(egl_display, nil, 0, &count)) {
		log.error("Can't get configs")
		log.errorf("Error code: 0x%x", GetError())
	}
	log.debugf("EGL has %d configs", count)

	res := ChooseConfig(egl_display, raw_data(config_attribs), &egl_conf, 1, &n)
	if res == egl.FALSE {
		log.errorf("Error choosing config with error code: %x\n", GetError())
	}
	log.debugf("EGL chose %d configs", n)

	log.info(configs)
	log.info(egl_conf)

	samples: i32 = 0
	egl.GetConfigAttrib(egl_display, egl_conf, EGL_SAMPLES, &samples)
	log.infof("MSAA number of samples: %d", samples)

	sample_buffers: i32 = 0
	egl.GetConfigAttrib(egl_display, egl_conf, EGL_SAMPLE_BUFFERS, &sample_buffers)
	log.infof("MSAA number of sample buffers: %d", sample_buffers)

	egl.BindAPI(egl.OPENGL_API)
	egl_context := egl.CreateContext(
		egl_display,
		egl_conf,
		egl.NO_CONTEXT,
		raw_data(context_attribs),
	)
	log.info(egl_context)

	return RenderContext{ctx = egl_context, display = egl_display, config = egl_conf}
}
