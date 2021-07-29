import ui
import blend2d
import math
import time
import gg
import gx

const (
	win_width  = 600
	win_height = 300
	limited_frame_time = time.second / 120
)

struct App {
mut:
	/// Main references
	window &ui.Window       = voidptr(0) // ui window reference
	gg     &gg.Context      = voidptr(0) // gg context reference
	ctx    &blend2d.Context = voidptr(0) // blend2d context reference
	img     blend2d.Image                // blend2d image data
	img_buf blend2d.ImageBuffer          // blend2d gg buffer
	/// State
	time f64 // = 0
	count int // = 0
	/// UI
	// Widgets
	limit_fps_check &ui.CheckBox
	canvas &ui.Canvas
	// FPS
	fps_sw  time.StopWatch = time.new_stopwatch()
	fps f32
	title_sw time.StopWatch = time.new_stopwatch()
}

[console]
fn main() {
	/// UI Setup
	// Create and store widget data
	mut app := &App{
		// Check box
		limit_fps_check: ui.checkbox(
			text: 'Limit FPS'
			checked: true
			text_cfg: gx.TextCfg{
				color: gx.white
			}
		)
		// Canvas
		canvas: ui.canvas(
			draw_fn: on_render
		)
	}

	// Main window reference
	app.window = ui.window(
		width: win_width
		height: win_height
		title: 'Bounces Example'
		state: app
		mode: .max_size
		on_init: on_init
		on_resize: on_resize
		bg_color: gx.rgb(20, 20, 20)
		children: [
			ui.column(
				spacing: 20,
				margin: ui.Margin{0, 0, 0, 0}
				children: [
					ui.row(
						widths: ui.compact
						heights: ui.compact
						spacing: 20
						margin: ui.Margin{0, 10, 0, 10}
						children: [
							app.limit_fps_check
						]
					),
					app.canvas
				]
			)
		]
	)
	
	// gg alias
	app.gg = app.window.ui.gg

	// Go!
	ui.run(app.window)
}

fn on_init(window &ui.Window) {
	mut app := &App(window.state)

	/// Information
	println("Canvas: ${app.canvas.width} x ${app.canvas.height}, ${app.gg.scale}x scale")

	/// Blend2D Setup
	// Create image data based on the canvas size, determined by UI layout.
	app.img = blend2d.new_image(int(app.canvas.width * app.gg.scale), int(app.canvas.height * app.gg.scale)) or {
		println("Error: Could not create Blend2D image. $err")
		exit(1)
	}
	// Attach a rendering context into `img`.
	app.ctx = blend2d.new_context(app.img) or {
		println("Error: Could not create Blend2D context. $err")
		exit(1)
	}
	// Set matrix to account for DPI scaling.
	app.ctx.scale(app.gg.scale)
	app.ctx.user_to_meta()
	// Init Blend2D image buffer; draw at canvas position
	app.img_buf = blend2d.new_image_buffer(app.img)
	app.img_buf.x = app.canvas.x
	app.img_buf.y = app.canvas.y

	/// Window setup
	// Window title
	update_title(mut app)
	// Continuous refresh (ui auto-enables `gg.ui_mode`, limiting calls to the frame function)
	app.gg.ui_mode = false
	// Fix y position of elements
	app.limit_fps_check.y = 13
}

fn on_render(gg &gg.Context, mut app &App, canvas &ui.Canvas) {
	// Limit frame rate if user desires
	if !app.limit_fps_check.checked || app.fps_sw.elapsed() >= limited_frame_time {
		// Update the Blend2D iamge
		ctx := app.ctx

		ctx.set_fill_color(blend2d.rgb_hex(0x000000))
		ctx.fill_all()

		k_margin_size := f64(7)
		k_square_size := f64(45)
		k_full_size := f64(k_square_size + k_margin_size * 2)
		k_half_size := f64(k_full_size / 2)
		w := int((app.canvas.width + k_full_size - 1) / k_full_size)
		h := int((app.canvas.height + k_full_size - 1) / k_full_size)

		count := w * h
		app.count = count

		mut ix := f64(0)
		mut iy := f64(0)
		start := f64(0)
		now := app.time

		gr := blend2d.new_linear_gradient(0, 0, 0, 0)
		// TODO - stops not necessary. Add func without stops / without type (linear / radial)
		// From Blend2D API to consider:
		// gr := blend2d.Gradient{}
		// gr := blend2d.new_gradient()
		// gr.set_type(.linear)

		for i in 0..count {
			x := ix * k_full_size
			y := iy * k_full_size

			dur := f64((now - start) + (i * 50))
			pos := f64(math.fmod(dur, 3000.0) / 3000.0)
			bounce_pos := f64(math.abs(pos * 2 - 1))
			r := f64((bounce_pos * 50 + 50) / 100)
			b := f64(((1 - bounce_pos) * 50) / 100)

			rotation := f64(pos * (math.pi * 2))
			radius := f64(bounce_pos * 25)

			ctx.save()
			ctx.rotate(rotation, x + k_half_size, y + k_half_size)
			ctx.translate(x, y)

			gr.reset_stops()
			gr.add_stop(0, blend2d.rgb_hex(0xFF7F00))
			gr.add_stop(1, blend2d.rgb(byte(r * 255), 0, byte(b * 255)))
			gr.set_linear_values(0, k_margin_size, 0, k_margin_size + k_square_size)

			ctx.set_fill_gradient(gr)
			ctx.fill_round_rect(k_margin_size, k_margin_size, k_square_size, k_square_size, radius)
			ctx.restore()

			ix += 1
			if ix >= w {
				ix = 0
				iy += 1
			}
		}

		// Draw the Blend2D image
		app.img_buf.draw(app.gg)

		// Animate
		update_values(mut app)
	} else {
		app.img_buf.draw_cached(app.gg)
	}
}

fn update_values(mut app &App) {
	// Update display values
	app.time += 2
	// Update FPS
	app.fps = f32(1 / app.fps_sw.elapsed().seconds())
	app.fps_sw.restart()
	// Update title
	if app.title_sw.elapsed().seconds() > 0.2 {
		// (called every frame, so limit update)
		app.title_sw.restart()
		update_title(mut app)
	}
}

fn update_title(mut app &App) {
	title := 'Bounces Example [${app.canvas.width}x${app.canvas.height}] [${app.count} objects] [${app.fps:.1f} FPS]'
	if title != app.window.title {
		app.window.set_title(title)
	}
}

[manualfree]
fn on_resize(w int, h int, window &ui.Window) {
	mut app := &App(window.state)
	if (app.canvas.width > 0 && app.canvas.height > 0) && (app.canvas.width != app.img.width() || app.canvas.height != app.img.height()) {
		// Destroy current image
		app.ctx.free()
		app.img.free()
		// Re-init Belnd2D image
		on_init(window)
	}
}
