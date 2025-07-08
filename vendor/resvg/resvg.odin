package resvg
import "core:c"

options :: struct {
}
render_tree :: struct {
}

size :: struct {
	w: c.float,
	h: c.float,
}

transform :: struct {
	a, b, c, d, e, f: c.float,
}

@(private)
LIB :: (
    "libresvg.a"         when #exists("libresvg.a") else
    "system:libresvg.a"  when #exists("/usr/lib/libresvg.a") else
    ""
)

when LIB == "" {
    #panic("Could not find the compiled resvg lib. It can be compiled by running `make -C \"vendor/resvg\"`")
}

foreign import resvg {
    LIB when LIB != "" else "system:libresvg.a",
}

@(default_calling_convention = "c", link_prefix = "resvg_")
foreign resvg {
	render :: proc(tree: ^render_tree, transform: transform, w, h: c.uint32_t, pixmap: [^]u8) ---
	parse_tree_from_file :: proc(file_path: cstring, opt: ^options, tree: ^^render_tree) -> c.int32_t ---
	options_create :: proc() -> ^options ---
	init_log :: proc() ---
	get_image_size :: proc(rt: ^render_tree) -> size ---
	transform_identity :: proc() -> transform ---
}
