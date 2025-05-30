package platform

import wl "../vendor/wayland-odin/wayland"
import "core:c"
import "core:log"
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
		egl.RENDERABLE_TYPE,
		egl.OPENGL_ES2_BIT,
		egl.NONE,
	}
	context_attribs: []i32 = {egl.CONTEXT_CLIENT_VERSION, 2, egl.NONE}
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

	egl_context := egl.CreateContext(
		egl_display,
		egl_conf,
		egl.NO_CONTEXT,
		raw_data(context_attribs),
	)
	log.info(egl_context)

	return RenderContext{ctx = egl_context, display = egl_display, config = egl_conf}
}
