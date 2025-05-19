package canvas

import "../../platform"
import "core:fmt"

draw_image :: proc(cv: ^Canvas, x, y: f32, image: platform.Image) {
	fmt.println(image.texture)
	draw_rect(cv, x, y, f32(image.w), f32(image.h), texture = image.texture, color = {0, 0, 0, 1})
}
