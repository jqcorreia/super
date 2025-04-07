package engine

import wl "../wayland-odin/wayland"
import "vendor:egl"

Surface :: struct {
	width:       i32,
	height:      i32,
	surface:     ^wl.wl_surface,
	egl_surface: egl.Surface,
}
