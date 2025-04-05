# Super Wayland Application Guide

## Build Commands
- Build and run: `odin run .`
- Check syntax: `odin check .`
- Build only: `odin build .`
- Build with debug info: `odin build . -debug`

## Code Style Guidelines
- Package names: lowercase, single word (e.g., `main`, `render`, `state`)
- Imports: Group standard library first, then vendor packages, then local imports
- Struct fields: snake_case with proper alignment in definitions
- Procedures: snake_case (e.g., `init_egl`, `surface_configure`)
- Constants: SCREAMING_SNAKE_CASE (e.g., `ZWLR_LAYER_SURFACE_V1_ANCHOR_TOP`)
- Callbacks: Use full `proc "c"` syntax with context handling when needed
- Error handling: Explicit checks with descriptive error messages
- Use Odin's `using` directive sparingly and only when appropriate
- Follow existing code patterns for Wayland/EGL integration

## Project Structure
- `main.odin`: Application entry point
- `state/`: State management for the application
- `render/`: EGL and rendering functionality
- `shaders/`: GLSL shader files (.vs, .fs)
- `wayland-odin/`: Wayland binding implementation