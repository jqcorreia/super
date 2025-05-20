package canvas

import "../../platform"

draw_image_raw :: proc(
	resolution: [2]f32,
	x, y: f32,
	image: platform.Image,
	w: f32 = 0,
	h: f32 = 0,
) {
	_w, _h: f32 = 0.0, 0.0

	if w != 0 && h != 0 {
		_w = w
		_h = h
	} else {
		_w = f32(image.w)
		_h = f32(image.h)
	}
	draw_rect_raw(resolution, x, y, _w, _h, texture = image.texture, color = {0, 0, 0, 1})
}
draw_image :: proc(cv: ^Canvas, x, y: f32, image: platform.Image, w: f32 = 0, h: f32 = 0) {
	draw_image_raw({f32(cv.width), f32(cv.height)}, x, y, image, w, h)
}
