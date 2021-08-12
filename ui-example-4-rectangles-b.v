import ui
import blend2d
import math
import gg
import gx
import rand
import time

// This example has two versions to demonstrate that both `ctx.sync()` and `ctx.end()`
// may be used in the case of multithreaded rendering to synchronize the threads, 
// forcing commands to complete so that the output may be used by the main thread 
// (for rendering in this case). `ctx.free()`, normally inserted by V's autofree engine, 
// also calls `ctx.end()`, so synchronization and cleanup are easy when the context is 
// limited to the scope of a single function.

// In this version, the context is created at program start, and `ctx.sync()` is used to
// block mexecution of the  main thread until all commands have completed modification of 
// the image.

const (
	win_width  = 800
	win_height = 500
	limited_frame_time = time.second / 120
	renderer_types = [u32(0), 1, 2, 4, 8, 12, 16]
	comp_ops = [blend2d.CompOp.src_over, .src_copy, .dst_atop, .xor, .plus, .screen, .lighten, .hard_light, .difference]
	start_count = 200
	max_count = 10000
)

enum ShapeType {
	rect
	rect_path
	round_rect
	poly_path
}

struct App {
mut:
	/// Main references
	window &ui.Window       = voidptr(0) // ui window reference
	gg     &gg.Context      = voidptr(0) // gg context reference
	ctx    &blend2d.Context = voidptr(0) // blend2d context reference
	img     blend2d.Image                // blend2d image data
	img_buf blend2d.ImageBuffer          // blend2d gg buffer
	/// State
	coords []blend2d.Point = []blend2d.Point{len: 0, cap: max_count}
	steps []blend2d.Point = []blend2d.Point{len: 0, cap: max_count}
	colors []blend2d.Rgba = []blend2d.Rgba{len: 0, cap: max_count}
	comp_op blend2d.CompOp = .src_over
	shape_type ShapeType = .rect
	rect_size f64 = 64
	/// UI
	// Widgets
	renderer_select &ui.Dropdown
	limit_fps_check &ui.CheckBox
	size_slider &ui.Slider
	count_slider &ui.Slider
	comp_op_select &ui.Dropdown
	shape_type_select &ui.Dropdown
	spacer &ui.Canvas
	label_1 &ui.Label
	label_2 &ui.Label
	label_3 &ui.Label
	label_4 &ui.Label
	label_5 &ui.Label
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
				thread_count := renderer_types[dd.selected_index]
				app.ctx.end()
				app.ctx.free()
				// Attach a rendering context to `img`.
				app.ctx = blend2d.new_context(app.img, thread_count: thread_count) or {
					println("Error: Could not create Blend2D context. $err")
					exit(1)
				}
				// Set matrix to account for DPI scaling.
				app.ctx.scale(app.gg.scale)
				app.ctx.user_to_meta()
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
		// Limit FPS check box
		limit_fps_check: ui.checkbox(
			text: 'Limit FPS'
			checked: true
			text_cfg: gx.TextCfg{
				color: gx.white
			}
		)
		// Composition operator dropdown
		comp_op_select: ui.dropdown(
			width: 100
			def_text: 'Src Over'
			on_selection_changed: fn (mut app App, dd &ui.Dropdown) {
				app.comp_op = blend2d.CompOp(comp_ops[dd.selected_index])
			}
			items: [
				ui.DropdownItem{
					text: 'Src Over'
				},
				ui.DropdownItem{
					text: 'Src Copy'
				},
				ui.DropdownItem{
					text: 'Dst Atop'
				},
				ui.DropdownItem{
					text: 'Xor'
				},
				ui.DropdownItem{
					text: 'Plus'
				},
				ui.DropdownItem{
					text: 'Screen'
				},
				ui.DropdownItem{
					text: 'Lighten'
				},
				ui.DropdownItem{
					text: 'Hard Light'
				},
				ui.DropdownItem{
					text: 'Difference'
				},
			]
		)
		// Shape type dropdown
		shape_type_select: ui.dropdown(
			width: 110
			def_text: 'Rect'
			on_selection_changed: fn (mut app App, dd &ui.Dropdown) {
				app.shape_type = ShapeType(dd.selected_index)
			}
			items: [
				ui.DropdownItem{
					text: 'Rect'
				},
				ui.DropdownItem{
					text: 'Rect Path'
				},
				ui.DropdownItem{
					text: 'Round Rect'
				},
				ui.DropdownItem{
					text: 'Polygon'
				},
			]
		)
		// Size slider
		size_slider: ui.slider(
			orientation: .horizontal
			width: 200
			height: 20
			min: 8
			max: 128
			val: 64
			on_value_changed: fn(mut app &App, slider &ui.Slider) {
				app.rect_size = slider.val
			}
		)
		// Count slider
		count_slider: ui.slider(
			orientation: .horizontal
			width: 200
			height: 20
			min: 1
			max: max_count
			val: start_count
			on_value_changed: fn(mut app &App, slider &ui.Slider) {
				size := int(slider.val)
				set_count(mut app, size)
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
			text: 'Comp Op:'
			text_cfg: gx.TextCfg{
				color: gx.white
			}
		)
		label_3: ui.label(
			text: 'Shape:'
			text_cfg: gx.TextCfg{
				color: gx.white
			}
		)
		label_4: ui.label(
			text: 'Count:'
			text_cfg: gx.TextCfg{
				color: gx.white
			}
		)
		label_5: ui.label(
			text: 'Size:'
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
		title: 'Gradients Example'
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
							app.comp_op_select
							app.label_3
							app.shape_type_select
						]
					),
					ui.row(
						widths: ui.compact
						heights: ui.compact
						spacing: 10
						margin: ui.Margin{0, 10, 0, 10}
						children: [
							app.label_4
							app.count_slider
							app.label_5
							app.size_slider
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
	// Attach a rendering context to `img`.
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
	app.limit_fps_check.y = 15
	app.label_1.y = 15
	app.renderer_select.y = 10
	app.label_2.y = 15
	app.comp_op_select.y = 10
	app.label_3.y = 15
	app.shape_type_select.y = 10
	app.label_4.y = 55
	app.count_slider.y = 52
	app.label_5.y = 55
	app.size_slider.y = 52

	/// Example init
	// Populate rectangles
	if app.coords.len == 0 {
		set_count(mut app, start_count)
	}
}

fn on_render(gg &gg.Context, mut app &App, canvas &ui.Canvas) {
	// Limit frame rate if user desires
	if !app.limit_fps_check.checked || app.fps_sw.elapsed() >= limited_frame_time {
		// Update the Blend2D iamge
		ctx := app.ctx

		ctx.set_fill_color(blend2d.rgb_hex(0x000000))
		ctx.fill_all()

		size := app.coords.len
		rect_size := app.rect_size
		half_size := rect_size * 0.5

		ctx.set_comp_op(app.comp_op)
		match app.shape_type {
			.rect {
				for i in 0..size {
					x := app.coords[i].x - half_size
					y := app.coords[i].y - half_size
					ctx.set_fill_color(app.colors[i])
					ctx.fill_rect(x, y, rect_size, rect_size)
				}
			}
			.rect_path {
				for i in 0..size {
					x := app.coords[i].x - half_size
					y := app.coords[i].y - half_size
					path := blend2d.new_path()
					path.add_rect(x, y, rect_size, rect_size)
					ctx.set_fill_color(app.colors[i])
					ctx.fill_path(path)
				}
			}
			.round_rect {
				for i in 0..size {
					x := app.coords[i].x - half_size
					y := app.coords[i].y - half_size
					ctx.set_fill_color(app.colors[i])
					ctx.fill_round_rect(x, y, rect_size, rect_size, 10)
				}
			}
			.poly_path {
				for i in 0..size {
					x := app.coords[i].x - half_size
					y := app.coords[i].y - half_size
					path := blend2d.new_path()
					path.move_to(x + rect_size / 2, y)
					path.line_to(x + rect_size, y + rect_size / 3)
					path.line_to(x + rect_size - rect_size / 3, y + rect_size)
					path.line_to(x + rect_size / 3, y + rect_size)
					path.line_to(x, y + rect_size / 3)
					ctx.set_fill_color(app.colors[i])
					ctx.fill_path(path)
				}
			}
		}

		// Sync the threads before drawing
		ctx.sync()

		// Draw the Blend2D image
		app.img_buf.draw(app.gg)

		// Animate
		update_values(mut app)
	} else {
		app.img_buf.draw_cached(app.gg)
	}
}

fn update_values(mut app &App) {
	w := app.img.width()
	h := app.img.height()

	size := app.coords.len

	for i in 0..size {
		mut vertex := &app.coords[i]
		mut step := &app.steps[i]
		unsafe {*vertex += step}
		vertex.x += step.x
		if vertex.x <= 0 || vertex.x >= w {
			step.x = -step.x
			vertex.x = math.min(vertex.x + step.x, w)
		}
		if vertex.y <= 0 || vertex.y >= h {
			step.y = -step.y
			vertex.y = math.min(vertex.y + step.y, h)
		}
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

fn set_count (mut app App, size int) {
	w := app.img.width()
	h := app.img.height()
	mut i := app.coords.len
	app.coords.trim(size)
	app.steps.trim(size)
	app.colors.trim(size)
	rand_sign := fn() int {
		return if rand.intn(2) == 0 { -1 } else { 1 }
	}
	for i < size {
		app.coords << blend2d.point(rand.f64n(w), rand.f64n(h))
		app.steps << blend2d.point(
			(rand.f64n(0.5) + 0.05) * rand_sign(), 
			(rand.f64n(0.5) + 0.05) * rand_sign()
		)
		app.colors << blend2d.rgba_hex(rand.u32())
		i += 1
	}
}

fn update_title(mut app &App) {
	title := 'Rectangles Example [${app.canvas.width}x${app.canvas.height}] [Size=${app.rect_size:.1f} Count=${app.coords.len}] [${app.fps:.1f} FPS]'
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
		// Re-init Blend2D image
		on_init(window)
	}
	// Else the window is probably just minimized (can't create 0px image anyway).
}
