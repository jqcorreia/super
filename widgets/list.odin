package widgets
import "../platform"

import "../platform/canvas"

import gl "vendor:OpenGL"
import "core:fmt"
List :: struct {
	x:    f32,
	y:    f32,
	items: [dynamic]string,
	font: ^platform.Font
}

list_draw :: proc(list: List, canvas: ^canvas.Canvas) {
    // fbo, fboTexture : u32
    // gl.GenFramebuffers(1, &fbo)
    // gl.BindFramebuffer(gl.FRAMEBUFFER, fbo)

    // // Create texture to render into
    // gl.GenTextures(1, &fboTexture)
    // gl.BindTexture(gl.TEXTURE_2D, fboTexture)
    // gl.TexImage2D(gl.TEXTURE_2D, 0, gl.RGBA, 1024, 1024, 0, gl.RGBA, gl.UNSIGNED_BYTE, nil)
    // gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR)
    // gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR)

    // gl.FramebufferTexture2D(gl.FRAMEBUFFER, gl.COLOR_ATTACHMENT0, gl.TEXTURE_2D, fboTexture, 0);

    // // Check status
    // if (gl.CheckFramebufferStatus(gl.FRAMEBUFFER) != gl.FRAMEBUFFER_COMPLETE) {
    //     fmt.println("FBO not complete!");
    // }

    // canvas->draw_rect(list.x, list.y, 100, 100, color = [4]f32{ 1.0, 1.0, 1.0, 1.0})
    // gl.BindFramebuffer(gl.FRAMEBUFFER, 0)

    canvas->draw_rect(0, 0, 100, 100)
}
