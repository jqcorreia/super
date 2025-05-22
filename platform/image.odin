package platform

import "../vendor/resvg"
import "core:c"
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
		buf: []u8

		if strings.ends_with(path, ".svg") {
			opts := resvg.options_create()
			tree := new(resvg.render_tree)

			// resvg.init_log()
			resvg.parse_tree_from_file(strings.clone_to_cstring(path), opts, &tree)
			if tree == nil {
				// For now flag this as the image being wrong so we dont keep
				// reloading a wrong or corrupted image
				return Image{texture = 0}
			}
			isize := resvg.get_image_size(tree)
			w = i32(isize.w)
			h = i32(isize.h)
			c = 4

			buf = make([]byte, int(isize.w * isize.h * f32(c)))
			resvg.render(
				tree,
				resvg.transform_identity(),
				u32(isize.w),
				u32(isize.h),
				raw_data(buf),
			)
		} else {
			lbuf := image.load(strings.clone_to_cstring(path), &w, &h, &c, 0)
			buf = lbuf[0:w * h * c]
		}

		texture: u32
		gl.GenTextures(1, &texture)
		gl.BindTexture(gl.TEXTURE_2D, texture)
		gl.TexImage2D(
			gl.TEXTURE_2D,
			0,
			gl.RGBA,
			i32(w),
			i32(h),
			0,
			gl.RGBA,
			gl.UNSIGNED_BYTE,
			raw_data(buf),
		)
		gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.NEAREST)
		gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.NEAREST)

		gl.BindTexture(gl.TEXTURE_2D, 0)
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
