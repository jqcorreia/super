package platform

import wl "../vendor/wayland-odin/wayland"
import "core:c"
import "core:fmt"
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
	major, minor, n, size: i32
	count: i32 = 0
	configs: [^]egl.Config
	egl_conf: egl.Config
	i: int
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
		8,
		egl.RENDERABLE_TYPE,
		egl.OPENGL_ES2_BIT,
		egl.NONE,
	}
	context_attribs: []i32 = {egl.CONTEXT_CLIENT_VERSION, 2, egl.NONE}
	egl_display := egl.GetDisplay(egl.NativeDisplayType(display))

	GetError() // clear error code
	if (egl_display == egl.NO_DISPLAY) {
		fmt.println("Can't create egl display")
	} else {
		fmt.println("Created egl display")
	}
	if (!egl.Initialize(egl_display, &major, &minor)) {
		fmt.println("Can't initialise egl display")
		fmt.printf("Error code: 0x%x\n", GetError())
	}
	fmt.printf("EGL major: %d, minor %d\n", major, minor)
	if (!GetConfigs(egl_display, nil, 0, &count)) {
		fmt.println("Can't get configs")
		fmt.printf("Error code: 0x%x\n", GetError())
	}
	fmt.printf("EGL has %d configs\n", count)

	res := ChooseConfig(egl_display, raw_data(config_attribs), &egl_conf, 1, &n)
	if res == egl.FALSE {
		fmt.printf("Error choosing config with error code: %x\n", GetError())
	}
	fmt.printf("EGL chose %d configs\n", n)

	fmt.println(configs)
	fmt.println(egl_conf)

	egl_context := egl.CreateContext(
		egl_display,
		egl_conf,
		egl.NO_CONTEXT,
		raw_data(context_attribs),
	)
	fmt.println(egl_context)

	return RenderContext{ctx = egl_context, display = egl_display, config = egl_conf}
}
