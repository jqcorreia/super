package platform

import "./fonts"
import "core:c"
import "core:fmt"
import "core:os/os2"
import "core:strings"

get_font_map :: proc() -> map[string]string {
	fonts := make(map[string]string)

	_, out, _, _ := os2.process_exec({command = {"fc-list"}}, context.allocator)

	for line, i in strings.split(string(out), "\n") {
		if !strings.contains(line, "style=Regular") {
			continue
		}

		split := strings.split(line, ":")
		path := split[0]

		// Guard against odd lines
		if len(split) < 2 {
			continue
		}

		family_names := split[1]
		for fname in strings.split(family_names, ",") {
			fonts[strings.trim_left(fname, " ")] = path
		}
	}

	return fonts
}
