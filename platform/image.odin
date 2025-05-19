package platform

import "core:c"
import "core:fmt"
import "core:strings"
import gl "vendor:OpenGL"
import "vendor:stb/image"

ImageMap :: map[string]Image
Image :: struct {
	w, h, c: u32,
	buf:     []u8,
	texture: u32,
}

ImageManager :: struct {
	images: ImageMap,
	load:   proc(_: ^ImageManager, _: string) -> Image,
}

@(private)
load_image :: proc(manager: ^ImageManager, path: string) -> Image {
	img, ok := manager.images[path]

	if !ok {
		w, h, c: c.int

		buf := image.load(strings.clone_to_cstring(path), &w, &h, &c, 0)


		texture: u32
		gl.GenTextures(1, &texture)
		fmt.println(texture)

		gl.BindTexture(gl.TEXTURE_2D, texture)
		gl.TexImage2D(gl.TEXTURE_2D, 0, gl.RGBA, i32(w), i32(h), 0, gl.RGBA, gl.UNSIGNED_BYTE, buf)
		gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.NEAREST)
		gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.NEAREST)

		i := Image {
			w       = u32(w),
			h       = u32(h),
			c       = u32(c),
			buf     = buf[0:w * h * c],
			texture = texture,
		}
		manager.images[path] = i
		return i
	} else {
		return img
	}
}


new_image_manager :: proc() -> ImageManager {
	return ImageManager{images = make(ImageMap), load = load_image}
}
