#+build js
package main

import "core:fmt"
import "engine"

WIDTH :: 800
HEIGHT :: 600

main :: proc() {
	fmt.println("Hello, WebAssembly!")

	state := engine.init(WIDTH, HEIGHT)
}
