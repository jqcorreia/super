package ui

import "core:fmt"

SplitType :: enum {
	Horizontal,
	Vertical,
}

Cell :: union {
	Split,
	Leaf,
}

Size :: struct {
	size:   u32,
	size_t: SizeType,
}
Split :: struct {
	using _:  Size,
	type:     SplitType,
	children: []Cell,
}

Leaf :: struct {
	using _: Size,
	widget:  ^WidgetBase,
}

SizeType :: enum {
	Abs,
	Per,
}
Layout :: struct {
	root: Cell,
}


@(private)
layout_resize_from_cell :: proc(cell: Cell, x, y, w, h, gap: u32) {
	fmt.println("-----------", x, y, w, h)
	switch c in cell {
	case Leaf:
		{
			wi := c.widget
			wi.x = f32(x + gap)
			wi.y = f32(y + gap)
			wi.w = f32(w - 2 * gap)
			wi.h = f32(h - 2 * gap)
		}
	case Split:
		{
			if c.type == .Vertical {
				accum_x: u32 = x
				accum_y: u32 = y

				sum_fixed_size: u32 = 0

				for split_c in c.children {
					switch sc in split_c {
					case Split:
						{
							if sc.size_t == .Abs {
								sum_fixed_size += sc.size
							}

						}
					case Leaf:
						{
							if sc.size_t == .Abs {
								sum_fixed_size += sc.size
							}
						}
					}
				}

				remaining_size := h - sum_fixed_size
				for split_c in c.children {
					h_step: u32 = 0
					switch sc in split_c {
					case Split:
						{
							h_step = sc.size_t == .Abs ? sc.size : remaining_size * (sc.size / 100)
						}
					case Leaf:
						{
							h_step = sc.size_t == .Abs ? sc.size : remaining_size * (sc.size / 100)
						}
					}
					layout_resize_from_cell(split_c, accum_x, accum_y, w, h_step, gap)
					accum_y += h_step
				}

			}

		}
	}

}
layout_resize_leafs :: proc(l: Layout, x, y, w, h, gap: u32) {

	layout_resize_from_cell(l.root, x, y, w, h, gap)
	fmt.println(l.root)
}
