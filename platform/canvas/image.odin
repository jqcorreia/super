package canvas

import "../../platform"

draw_image :: proc(cv: ^Canvas, x, y: f32, image: platform.Image) {
	draw_rect(cv, x, y, f32(image.w), f32(image.h), texture = image.texture, color = {0, 0, 0, 1})
}
