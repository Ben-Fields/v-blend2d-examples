import ui
import blend2d
import math
import time
import gg
import gx

const (
	win_width  = 800
	win_height = 500
	limited_frame_time = time.second / 30
	renderer_types = [u32(0), 1, 2, 4, 8, 12, 16]
	start_count = 500
)

struct App {
mut:
	/// Main references
	window &ui.Window       = voidptr(0) // ui window reference
	gg     &gg.Context      = voidptr(0) // gg context reference
	img     blend2d.Image                // blend2d image data
	img_buf blend2d.ImageBuffer          // blend2d gg buffer
	/// State
	renderer_type u32
	angle f64 // = 0
	count int = start_count
	/// UI
	// Widgets
	renderer_select &ui.Dropdown
	label_1 &ui.Label
	limit_fps_check &ui.CheckBox
	spacer &ui.Canvas
	count_slider &ui.Slider
	label_2 &ui.Label
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
		// Renderer dropdown
		renderer_select: ui.dropdown(
			width: 115
			def_text: 'Blend2D'
			on_selection_changed: fn (mut app App, dd &ui.Dropdown) {
				app.renderer_type = renderer_types[dd.selected_index]
			}
			items: [
				ui.DropdownItem{
					text: 'Blend2D'
				},
				ui.DropdownItem{
					text: 'Blend2D 1T'
				},
				ui.DropdownItem{
					text: 'Blend2D 2T'
				},
				ui.DropdownItem{
					text: 'Blend2D 4T'
				},
				ui.DropdownItem{
					text: 'Blend2D 8T'
				},
				ui.DropdownItem{
					text: 'Blend2D 12T'
				},
				ui.DropdownItem{
					text: 'Blend2D 16T'
				}
			]
		)
		// Check box
		limit_fps_check: ui.checkbox(
			text: 'Limit FPS'
			checked: true
			text_cfg: gx.TextCfg{
				color: gx.white
			}
		)
		// Slider
		count_slider: ui.slider(
			orientation: .horizontal
			width: 200
			height: 20
			min: 100
			max: 2000
			val: start_count
			on_value_changed: fn(mut app &App, slider &ui.Slider) {
				app.count = int(slider.val)
				update_title(mut app)
			}
		)
		// Labels
		label_1: ui.label(
			text: 'Renderer:'
			text_cfg: gx.TextCfg{
				color: gx.white
			}
		)
		label_2: ui.label(
			text: 'Count:'
			text_cfg: gx.TextCfg{
				color: gx.white
			}
		)
		spacer: ui.canvas(
			width: 1
			height: 1
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
		title: 'Circles Example'
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
						spacing: 10
						margin: ui.Margin{0, 10, 0, 10}
						children: [
							app.label_1
							app.renderer_select
							app.limit_fps_check
							app.spacer
							app.label_2
							app.count_slider
						]
					)
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
	app.label_1.y = 15
	app.renderer_select.y = 10
	app.limit_fps_check.y = 15
	app.label_2.y = 15
	app.count_slider.y = 12
}

fn on_render(gg &gg.Context, mut app &App, canvas &ui.Canvas) {
	// Limit frame rate if user desires
	if !app.limit_fps_check.checked || app.fps_sw.elapsed() >= limited_frame_time {
		// Attach a rendering context to `img`.
		ctx := blend2d.new_context(app.img, thread_count: app.renderer_type) or {
			println("Error: Could not create Blend2D context. $err")
			exit(1)
		}
		// Set matrix to account for DPI scaling.
		ctx.scale(app.gg.scale)
		ctx.user_to_meta()

		// Update the Blend2D image
		ctx.set_fill_color(blend2d.rgb_hex(0x000000))
		ctx.fill_all()

		p := blend2d.new_path()

		count := app.count
		cx := app.canvas.width / 2
		cy := app.canvas.height / 2

		base_angle := app.angle / 180.0 * math.pi

		for i in 0..count {
			t := f64(i) * 1.01 / 1000
			d := t * 1000 * 0.4 + 10
			a := base_angle + t * math.pi * 2 * 20
			x := cx + math.cos(a) * d
			y := cy + math.sin(a) * d
			r := math.min(t * 8 + 0.5, 10)
			p.add_circle(x, y, r)
		}

		ctx.set_fill_color(blend2d.rgb_hex(0xFFFFFF))
		ctx.fill_path(p)

		// Draw the Blend2D image
		app.img_buf.draw(app.gg)

		// Animate angle
		update_values(mut app)

		// TEMPORARY: Normally, autofree would put this here, but it is not finished.
		ctx.free()

		// free() syncs the threads and detaches the rendering context (in addition to freeing the ctx data).
	} else {
		app.img_buf.draw_cached(app.gg)
	}
}

fn update_values(mut app &App) {
	// Update display values
	app.angle += 0.05
	if app.angle >= 360 {
		app.angle -= 360
	}
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
	title := 'Circles Example [${app.canvas.width}x${app.canvas.height}] [${app.count} circles] [${app.fps:.1f} FPS]'
	if title != app.window.title {
		app.window.set_title(title)
	}
}

[manualfree]
fn on_resize(w int, h int, window &ui.Window) {
	mut app := &App(window.state)
	if (app.canvas.width > 0 && app.canvas.height > 0) && (app.canvas.width != app.img.width() || app.canvas.height != app.img.height()) {
		// Destroy current image
		app.img.free()
		// Re-init Blend2D image
		on_init(window)
	}
}
