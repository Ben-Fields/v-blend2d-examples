import ui
import blend2d
import math
import gg
import gx
import rand

const (
	win_width  = 800
	win_height = 500
	renderer_types = [u32(0), 1, 2, 4, 8, 12, 16]
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
	// TODO: Debug- program crashes b/c out of memory access when ampersand (&) omitted
	//       (field becomes invalid even though it is initialized)
	//       (maybe an issue with C interop / opaque structs)
	gradient &blend2d.Gradient = blend2d.new_linear_gradient(100, 80, 35, 150, stops: [
		blend2d.gradient_stop(0.0, blend2d.rgb_hex_64(0x000000000000))
		blend2d.gradient_stop(1.0, blend2d.rgb_hex_64(0xFFFFFFFFFFFF))
	])
	pts [2]blend2d.Point = [
		blend2d.point(100, 80)
		blend2d.point(350, 150)
	]!
	gradient_type blend2d.GradientType = .linear
	gradient_extend_mode blend2d.ExtendMode = .pad
	num_points u32 = 2
	closest_vertex u32 = math.max_u32
	grabbed_vertex u32 = math.max_u32
	grabbed_x int
	grabbed_y int
	/// UI
	// Widgets
	gradient_type_select &ui.Dropdown
	extend_mode_select &ui.Dropdown
	parameter_slider &ui.Slider
	label_1 &ui.Label
	label_2 &ui.Label
	label_3 &ui.Label
	color_button &ui.Button
	randomize_button &ui.Button
	canvas &ui.Canvas
	update_canvas bool = true
}

[console]
fn main() {
	/// UI Setup
	// Create and store widget data
	mut app := &App{
		// Gradient type dropdown
		gradient_type_select: ui.dropdown(
			width: 100
			def_text: 'Linear'
			on_selection_changed: fn (mut app App, dd &ui.Dropdown) {
				app.gradient_type = blend2d.GradientType(dd.selected_index)
				app.num_points = if app.gradient_type == .conical { u32(1) } else { 2 }
				app.update_canvas = true
			}
			items: [
				ui.DropdownItem{
					text: 'Linear'
				},
				ui.DropdownItem{
					text: 'Radial'
				},
				ui.DropdownItem{
					text: 'Concial'
				},
			]
		)
		// Gradient extend mode dropdown
		extend_mode_select: ui.dropdown(
			width: 100
			def_text: 'Pad'
			on_selection_changed: fn (mut app App, dd &ui.Dropdown) {
				app.gradient_extend_mode = blend2d.ExtendMode(dd.selected_index)
				app.update_canvas = true
			}
			items: [
				ui.DropdownItem{
					text: 'Pad'
				},
				ui.DropdownItem{
					text: 'Repeat'
				},
				ui.DropdownItem{
					text: 'Reflect'
				},
			]
		)
		// Slider
		parameter_slider: ui.slider(
			orientation: .horizontal
			width: 200
			height: 20
			min: 1
			max: 500
			val: 250
			on_value_changed: fn(mut app &App, slider &ui.Slider) {
				app.update_canvas = true
			}
		)
		// Labels
		label_1: ui.label(
			text: 'Gradient:'
			text_cfg: gx.TextCfg{
				color: gx.white
			}
		)
		label_2: ui.label(
			text: 'Extend Mode:'
			text_cfg: gx.TextCfg{
				color: gx.white
			}
		)
		label_3: ui.label(
			text: 'Radius:'
			text_cfg: gx.TextCfg{
				color: gx.white
			}
		)
		// Buttons
		color_button: ui.button(
			text: 'Colors'
			width: 70
			height: 25
			onclick: fn (mut app App, btn &ui.Button) {
				random_color := fn () blend2d.Rgba {
					return blend2d.rgb(rand.byte(), rand.byte(), rand.byte())
				}
				app.gradient.reset_stops()
				app.gradient.add_stop(0.0, random_color())
				app.gradient.add_stop(0.5, random_color())
				app.gradient.add_stop(1.0, random_color())
				app.update_canvas = true
			}
		)
		randomize_button: ui.button(
			text: 'Random'
			width: 70
			height: 25
			onclick: fn (mut app App, btn &ui.Button) {
				app.pts[0].x = rand.f64_in_range(0,1) * (app.canvas.width - 1) + 0.5
				app.pts[0].y = rand.f64_in_range(0,1) * (app.canvas.height - 1) + 0.5
				app.pts[1].x = rand.f64_in_range(0,1) * (app.canvas.width - 1) + 0.5
				app.pts[1].y = rand.f64_in_range(0,1) * (app.canvas.height - 1) + 0.5
				app.update_canvas = true
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
		title: 'Gradients Example'
		state: app
		mode: .max_size
		on_init: on_init
		on_resize: on_resize
		bg_color: gx.rgb(20, 20, 20)
		on_mouse_down: on_mouse_press
		on_mouse_up: on_mouse_release
		on_mouse_move: on_mouse_move
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
							app.gradient_type_select
							app.label_2
							app.extend_mode_select
						]
					)
					ui.row(
						widths: ui.compact
						heights: ui.compact
						spacing: 10
						margin: ui.Margin{0, 10, 0, 10}
						children: [
							app.color_button
							app.randomize_button
							app.label_3
							app.parameter_slider
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
	// Continuous refresh (ui auto-enables `gg.ui_mode`, limiting calls to the frame function)
	app.gg.ui_mode = false
	// Fix y position of elements
	app.label_1.y = 15
	app.gradient_type_select.y = 10
	app.label_2.y = 15
	app.extend_mode_select.y = 10
	app.color_button.y = 50
	app.randomize_button.y = 50
	app.label_3.y = 55
	app.parameter_slider.y = 52
}

fn on_render(gg &gg.Context, mut app &App, canvas &ui.Canvas) {
	// Canvas updates are on request
	if app.update_canvas {
		// Attach a rendering context to `img`.
		ctx := blend2d.new_context(app.img, thread_count: 0) or {
			println("Error: Could not create Blend2D context. $err")
			exit(1)
		}
		// Set matrix to account for DPI scaling.
		ctx.scale(app.gg.scale)
		ctx.user_to_meta()

		// Update the Blend2D image
		grad := app.gradient

		grad.set_type(app.gradient_type)
		grad.set_extend_mode(app.gradient_extend_mode)

		if app.gradient_type == .linear {
			grad.set_linear_values(app.pts[0].x, app.pts[0].y, app.pts[1].x, app.pts[1].y)
		} else if app.gradient_type == .radial {
			grad.set_radial_values(app.pts[0].x, app.pts[0].y, app.pts[1].x, app.pts[1].y, app.parameter_slider.val)
		} else {
			grad.set_conical_values(app.pts[0].x, app.pts[0].y, app.parameter_slider.val)
		}

		ctx.set_fill_gradient(grad)
		ctx.fill_all()

		for i in 0..app.num_points {
			ctx.set_fill_color(if i == app.closest_vertex {blend2d.rgb_hex(0x00FFFF)} else {blend2d.rgb_hex(0x007FFF)})
			ctx.fill_circle(app.pts[i].x, app.pts[i].y, 2)
		}

		// Draw the Blend2D image
		app.img_buf.draw(app.gg)

		app.update_canvas = false

		// TEMPORARY: Normally, autofree would put this here, but it is not finished.
		ctx.free()

		// free() syncs the threads and detaches the rendering context (in addition to freeing the ctx data).
	} else {
		app.img_buf.draw_cached(app.gg)
	}
}

fn on_mouse_press(e ui.MouseEvent, window &ui.Window) {
	mut app := &App(window.state)
	if e.button == .left {		
		if app.closest_vertex != math.max_u32 {
			app.grabbed_vertex = app.closest_vertex
			app.grabbed_x = e.x - app.canvas.x
			app.grabbed_y = e.y - app.canvas.y
			app.update_canvas = true
		}
	}
}

fn on_mouse_release(e ui.MouseEvent, window &ui.Window) {
	mut app := &App(window.state)
	if e.button == .left {
		if app.grabbed_vertex != math.max_u32 {
			app.grabbed_vertex = math.max_u32
			app.update_canvas = true
		}
	}
}

fn on_mouse_move(e ui.MouseMoveEvent, window &ui.Window) {
	mut app := &App(window.state)
	mx := e.x - app.canvas.x
	my := e.y - app.canvas.y
	if app.grabbed_vertex == math.max_u32 {
		app.closest_vertex = get_closest_vertex(app, blend2d.point(mx, my), 15)
		app.update_canvas = true
	} else {
		app.pts[app.grabbed_vertex] = blend2d.point(mx, my)
		app.update_canvas = true
	}
}

fn get_closest_vertex(app &App, p blend2d.Point, max_distance f64) u32 {
	mut closest_index := math.max_u32
	mut closest_distance := math.max_f64
	for i in 0..app.num_points {
		d := math.hypot(app.pts[i].x - p.x, app.pts[i].y - p.y)
		if d < closest_distance && d < max_distance {
			closest_index = i
			closest_distance = d
		}
	}
	return closest_index
}

[manualfree]
fn on_resize(w int, h int, window &ui.Window) {
	mut app := &App(window.state)
	if (app.canvas.width > 0 && app.canvas.height > 0) && (app.canvas.width != app.img.width() || app.canvas.height != app.img.height()) {
		// Destroy current image
		app.img.free()
		// Re-init Blend2D image
		on_init(window)
		app.update_canvas = true
	}
	// Else the window is probably just minimized (can't create 0px image anyway).
}
