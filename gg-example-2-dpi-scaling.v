// This example demonstrates drawing Blend2D generated graphics in a window using
// `gg`, V's wrapper for `sokol`, a multi-platform API for 3D rendering.

// This example accounts for image scaling caused by system scale factors.
// System scale factors are set by the user and change the so-called "DPI" (Dots-per-Inch) 
// and of graphics on the screen (or more accurately, their final size, retaining sharpness).

// This example does not account for the window refresh rate. The result is that the 
// circle will move different speeds depending on system performance, as well as system 
// limiting of the refresh rate, such as when the window is dragged or resized.

// Copyright Ben Fields. This example is provided under an MIT License.

module main

import gx
import gg
import blend2d

struct App {
	mut:
	// gg (3D API) context
	g       &gg.Context = voidptr(0)
	// Blend2D image data
	img     blend2d.Image
	img_buf blend2d.ImageBuffer
	// Circle x-position variable
	x_pos   int
}

// The `[console]` attribute is required for console output until fixed in V
[console]
fn main() {
	println('Begin main.')

	// Initialize gg (sokol wrapper)
	mut app := &App {
		g: 0
	}
	app.g = gg.new_context({
		bg_color: gx.black
		width: 480
		height: 480
		use_ortho: true 
		create_window: true
		window_title: 'V Blend2D Test' 
		user_data: app
		init_fn: init_img
		frame_fn: frame
	})
	app.g.run()

	println('End main.')
}

fn frame(mut app App) {
	// Reset the sokol.gl matrix
	app.g.begin()

	// Custom update the Blend2D image
	update_img(mut app)

	// Draw the Blend2D image
	app.img_buf.draw(app.g)

	// Draw all queued commands inside the (single) sokol render pass
	app.g.end()

	// Move the circle
	app.x_pos += 1
	if app.x_pos > app.g.width/2 + 150 {
		// Reset position offscreen (r = 150)
		app.x_pos = -app.g.width/2 - 150
	}
}

fn init_img(mut app App) {
	/// Init Blend2d image.
	// The initial image must be scaled based on the DPI in order to contain all the 
	// necessary pixels, but later operations do not need to account for the scaling 
	// as long as we update the Meta matrix.
	app.img = blend2d.new_image(int(app.g.width * app.g.scale), int(app.g.height * app.g.scale)) or {
		println("Error: Could not create image. $err")
		return
	}

	// Init Blend2D image buffer
	app.img_buf = blend2d.new_image_buffer(app.img)
}

fn update_img(mut app App) {
	// Attach a rendering context into `img`.
	ctx := blend2d.new_context(app.img) or {
		println("Could not craete context. $err")
		return
	}

	/// Update the Meta matrix to account for DPI-scaling
	// There are two transformation matrices provided: The Meta and User matrices.
	// Both are applied. The user matrix is modified by all the transformation 
	// functions, and it may be transferred to the Meta matrix. Thus, generally, 
	// the Meta matrix is for persistent transformations, like DPI-scaling, and
	// the User matrix for drawing particular shapes.
	ctx.scale(app.g.scale)
	ctx.user_to_meta()

	// Clear the image.
	ctx.set_comp_op(.src_copy)
	ctx.fill_all()

	// Draw a circle.
	ctx.set_comp_op(.src_over)
	ctx.set_fill_color(blend2d.new_rgba32(0xFF226622))
	ctx.fill_circle(app.g.width/2 + app.x_pos, app.g.height/2, 150)

	// Draw a frame around the image.
	ctx.set_stroke_color(blend2d.new_rgba32(0xFF222266))
	ctx.set_stroke_width(3)
	ctx.stroke_rect(0, 0, app.g.width, app.g.height)

	// Detach the rendering context from `img`.
	ctx.end()
}
