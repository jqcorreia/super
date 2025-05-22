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

Split :: struct {
	type:     SplitType,
	children: []Cell,
}

Leaf :: struct {
	widget: ^WidgetBase,
	size:   u32,
	size_t: SizeType,
}

SizeType :: enum {
	Abs,
	Per,
}
Layout :: struct {
	root: Cell,
}


layout_resize_leafs :: proc(l: Layout, w, h: u32) {

	fmt.println(l.root)
}
