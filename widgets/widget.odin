package widgets

import "../engine"
import "../platform"
import "../platform/canvas"
import "core:fmt"


WidgetType :: union {
	Label,
    List,
}

draw :: proc {
	label_draw,
    list_draw
}
