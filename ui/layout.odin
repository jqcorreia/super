package ui

import "core:fmt"

SplitType :: enum {
	Horizontal,
	Vertical,
}


CellType :: union {
	Split,
	Leaf,
}

Cell :: struct {
	using base: Size,
	type:       CellType,
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
	switch c in cell.type {
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
					if split_c.size_t == .Abs {
						sum_fixed_size += split_c.size
					}
				}

				remaining_size := h - sum_fixed_size
				for split_c in c.children {
					h_step: u32 = 0
					h_step =
						split_c.size_t == .Abs ? split_c.size : remaining_size * (split_c.size / 100)
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
