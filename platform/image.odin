package platform

import "core:c"
import "core:fmt"
import "core:os"
import "core:strings"
import "vendor/resvg"
import gl "vendor:OpenGL"
import "vendor:stb/image"

import "core:log"

ImageMap :: map[string]Image
Image :: struct {
	w, h, c: u32,
	buf:     []u8,
	texture: u32,
}

ImageManager :: struct {
	images: ImageMap,
	load:   proc(
		_: string,
		config: SamplingConfig = {min_filter = gl.LINEAR_MIPMAP_LINEAR, mag_filter = gl.LINEAR},
		flip_y: bool = false,
	) -> Image,
}

SamplingConfig :: struct {
	min_filter: i32,
	mag_filter: i32,
	wrap_s:     i32,
	wrap_t:     i32,
}

load_image :: proc(
	path: string,
	config: SamplingConfig = {min_filter = gl.LINEAR_MIPMAP_LINEAR, mag_filter = gl.LINEAR},
	flip_y: bool = false,
) -> Image {
	manager := &inst().images
	img, ok := manager.images[path]

	if !os.exists(path) {
		panic(fmt.tprintln("File ", path, " not found"))
	}
	if !ok {
		log.infof("Loading image %s", path)
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
			image.set_flip_vertically_on_load(flip_y ? 1 : 0)
			lbuf := image.load(strings.clone_to_cstring(path), &w, &h, &c, 4)
			buf = lbuf[0:w * h * c]
		}

		texture: u32
		format: u32 = gl.RGBA

		gl.GenTextures(1, &texture)
		gl.BindTexture(gl.TEXTURE_2D, texture)
		gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, config.min_filter)
		gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, config.mag_filter)
		gl.TexParameterf(gl.TEXTURE_2D, gl.TEXTURE_MAX_ANISOTROPY, 16.0) // if supported

		if config.wrap_t > 0 {
			gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, config.wrap_t)
		}
		if config.wrap_s > 0 {
			gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, config.wrap_s)
		}
		gl.TexImage2D(
			gl.TEXTURE_2D,
			0,
			i32(format),
			i32(w),
			i32(h),
			0,
			u32(format),
			gl.UNSIGNED_BYTE,
			raw_data(buf),
		)
		gl.GenerateMipmap(gl.TEXTURE_2D)
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


load_image_from_buffer :: proc(
	buf: []u8,
	config: SamplingConfig = {min_filter = gl.LINEAR_MIPMAP_LINEAR, mag_filter = gl.LINEAR},
	flip_y: bool = false,
) -> Image {
	w, h, c: c.int

	image.set_flip_vertically_on_load(flip_y ? 1 : 0)
	lbuf := image.load_from_memory(raw_data(buf), i32(len(buf)), &w, &h, &c, 4)
	ibuf: []u8 = lbuf[0:w * h * c]

	texture: u32
	format: u32 = gl.RGBA

	gl.GenTextures(1, &texture)
	gl.BindTexture(gl.TEXTURE_2D, texture)
	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, config.min_filter)
	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, config.mag_filter)
	gl.TexParameterf(gl.TEXTURE_2D, gl.TEXTURE_MAX_ANISOTROPY, 16.0) // if supported

	if config.wrap_t > 0 {
		gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, config.wrap_t)
	}
	if config.wrap_s > 0 {
		gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, config.wrap_s)
	}
	gl.TexImage2D(
		gl.TEXTURE_2D,
		0,
		i32(format),
		i32(w),
		i32(h),
		0,
		u32(format),
		gl.UNSIGNED_BYTE,
		raw_data(ibuf),
	)
	gl.GenerateMipmap(gl.TEXTURE_2D)
	gl.BindTexture(gl.TEXTURE_2D, 0)
	i := Image {
		w       = u32(w),
		h       = u32(h),
		c       = u32(c),
		buf     = ibuf[0:w * h * c],
		texture = texture,
	}

	return i
}

new_image_manager :: proc() -> ImageManager {
	return ImageManager{images = make(ImageMap), load = load_image}
}
