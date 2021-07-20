import ui
import blend2d
import math
import time
import gg

const (
	win_width  = 600
	win_height = 300
	start_count = 500
)

struct App {
mut:
	/// Main references
	window &ui.Window       = voidptr(0) // ui window reference
	gg     &gg.Context      = voidptr(0) // gg context reference
	ctx    &blend2d.Context = voidptr(0) // blend2d context reference
	img     blend2d.Image                // blend2d image data
	img_buf blend2d.ImageBuffer          // blend2d gg buffer
	/// UI
	// Widgets
	//QTimer _timer;
	limit_fps_check &ui.CheckBox
	count_slider &ui.Slider
	canvas &ui.Canvas
	angle f64 // = 0
	count int = start_count
	// FPS
	sw  time.StopWatch = time.new_stopwatch({})
	fps f32 // TODO
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
			on_check_changed: fn (mut app &App, val bool) {
				// _timer.setInterval(value ? 1000 / 120 : 0)
			}
		)
		// Slider
		count_slider: ui.slider(
			orientation: .horizontal
			width: 200 // TODO resizable
			height: 20
			min: 100
			max: 2000
			val: start_count
			on_value_changed: fn(mut app &App, slider &ui.Slider) {
				app.count = int(slider.val)
				update_title(mut app)
			}
		)
		// Canvas
		canvas: ui.canvas(
			{draw_fn: on_render}			
		)
	}

	// Main window reference
	app.window = ui.window({
		width: win_width
		height: win_height
		title: 'Example'
		state: app
		// mode: .resizable
		on_init: on_init
		// on_draw: on_render
	}, [
		ui.column({
			spacing: 20, 
			heights: [ui.compact, ui.stretch]
			margin: ui.Margin{5,5,5,5}
		}, [
			ui.row({
				widths: ui.compact
				heights: ui.compact
				spacing: 20
			}, [
				app.limit_fps_check,
				app.count_slider
			]),
			app.canvas
		])
	])
	
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
}

fn on_render(gg &gg.Context, mut app &App, canvas &ui.Canvas) {
// fn on_render(window &ui.Window) {
	// mut app := &App(window.state)

	ctx := app.ctx

	ctx.set_fill_color(blend2d.new_rgba32(0xFF000000))
	ctx.fill_all()

	p := blend2d.new_path()

	count := app.count

	cx := app.canvas.width / 2
	cy := app.canvas.height / 2

	max_dist := 1000.0
	base_angle := app.angle / 180.0 * math.pi

	for i in 0..count {
		t := f64(i) * 1.01 / 1000
		d := t * 1000.0 * 0.4 + 10
		a := base_angle + t * math.pi * 2 * 20
		x := cx + math.cos(a) * d
		y := cy + math.sin(a) * d
		r := math.min(t * 8 + 0.5, 10.0)
		p.add_circle(x, y, r)
	}

	ctx.set_fill_color(blend2d.new_rgba32(0xFFFFFFFF))
	ctx.fill_path(p)

	// Draw the Blend2D image
	app.img_buf.draw(app.gg)

	// Animate angle
	on_timer(mut app)
}

fn update_title(mut app &App) {
	title := 'Circles Example [${app.canvas.width}x${app.canvas.height}] [${app.count_slider.val} circles] [${app.fps:.1f} FPS]'
	if title != app.window.title {
		app.window.set_title(title)
	}
}

fn on_timer(mut app &App) {
	app.angle += 0.05
	if app.angle >= 360 {
		app.angle -= 360
	}
	// app.canvas.updateCanvas(true);
	update_title(mut app)
}

/// Notes
// The height of the checkbox cannot be set. Not implemented i v/ui yet.
// `window` cannot be declared in the initialization of `app` because that causes a 
//   comptime unhandled exception. Attributes likely not evaluated in order.
// After the ui functions are called, member variables are not set yet. You must
//   use the `on_init` function of `window` for post-initialized values.
// The canvas `draw_fn()` only draws on a canvas update, so ont must call 
//   `window.refresh()`.
