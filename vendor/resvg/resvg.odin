package resvg
import "core:c"

options :: struct {}
render_tree :: struct {}

size :: struct {
	w: c.float,
	h: c.float,
}

foreign import resvg "../../libresvg.a"

@(default_calling_convention = "c", link_prefix = "resvg_")
foreign resvg {
	render :: proc() ---
	parse_tree_from_file :: proc(file_path: cstring, opt: ^options, tree: ^^render_tree) -> c.int32_t ---
	options_create :: proc() -> ^options ---
	init_log :: proc() ---
	get_image_size :: proc(rt: ^^render_tree) -> size ---
}


