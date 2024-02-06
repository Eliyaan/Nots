module main

import gg
import gx
import ggui
import os


const tile_size = 128
const theme = ggui.CatppuchinMocha{}
const buttons_shape = ggui.RoundedShape{20, 20, 5, .top_left}
const space = 100
const bt_scale = 70
const bt_offset  = 20
const elem_button_shape = ggui.RoundedShape{bt_scale, bt_scale, 10, .top_left}


enum Id {
	@none
}

fn id(id Id) int {
	return int(id)
}

enum Variant as u8 {
	not
	diode
	wire
	junction
}

interface Element {
mut:
	destroyed bool
	in_gate   bool
	x         i64
	y         i64
}

@[heap]
struct App {
mut:
	gg        &gg.Context = unsafe { nil }
	elements  []Element
	destroyed []i64
	chunks    []Chunk
	// reopti les chunks pour éviter les cache misses en séparant les coords des 2D arrays
	wire_groups  []GlobalWire
	queue        []i64
	queue_gwires []i64

	no_of_the_frame      int
	update_every_x_frame int = 10
	updates_per_frame    int = 1

	gui          &ggui.Gui = unsafe { nil }
	clickables   []ggui.Clickable
	gui_elements []ggui.Element

	mouse_x        int
	mouse_y        int
	screen_mouse_x int
	screen_mouse_y int

	//Used for preview
	is_placing		bool
	mouse_down_preview_x		int
	mouse_down_preview_y		int

	//Used for place
	mouse_down_x		int
	mouse_down_y		int
	mouse_up_x			int
	mouse_up_y			int
	place_is_turn		bool

	build_selected_type Variant
	build_orientation   Orientation

	debug_mode bool = true

	istream_idx   int
	screen_pixels []u32
	blank_screen  []u32
	screen_x      int
	screen_y      int
	viewport_x    int
	viewport_y    int
	middle_click_held bool

	scale f64 = 0.5

	ui_not 			gg.Image
	ui_diode		gg.Image
	ui_junction		gg.Image
	ui_wire 		gg.Image
}

fn main() {
	mut app := &App{}
	app.gui = &ggui.Gui(app)
	app.gg = gg.new_context(
		fullscreen: true
		create_window: true
		window_title: '- Nots -'
		user_data: app
		bg_color: gx.Color{187, 187, 187, 255}
		frame_fn: on_frame
		event_fn: on_event
		init_fn: graphics_init
		sample_count: 4
	)
	app.build_orientation = .west

	app.ui_not = app.gg.create_image(os.resource_abs_path('off_not_gate.png'))!
	app.ui_diode = app.gg.create_image(os.resource_abs_path('off_diode.png'))!
	app.ui_junction = app.gg.create_image(os.resource_abs_path('off_junction.png'))!
	app.ui_wire = app.gg.create_image(os.resource_abs_path('wire_off.png'))!

	// calculate the rotations of the image

	// do your test/base placings here if needed

	empty_text := ggui.Text{0, 0, 0, '', gx.TextCfg{
		color: theme.base
		size: 20
		align: .center
		vertical_align: .middle
	}}

	
	app.clickables << ggui.Button{0, bt_offset, bt_offset, elem_button_shape, empty_text, gg.Color{200, 200, 200, 100}, not_select}
	app.clickables << ggui.Button{0, bt_offset, bt_offset + space * 1, elem_button_shape, empty_text, gg.Color{200, 200, 200, 100}, diode_select}
	app.clickables << ggui.Button{0, bt_offset, bt_offset + space * 2, elem_button_shape, empty_text, gg.Color{200, 200, 200, 100}, wire_select}
	app.clickables << ggui.Button{0, bt_offset, bt_offset + space * 3, elem_button_shape, empty_text, gg.Color{200, 200, 200, 100}, junction_select}

/*
TO NOT FORGET 
	app.clickables << ggui.Button{0, 00, 450, buttons_shape, minus_text, theme.red, slower_updates}
	app.clickables << ggui.Button{0, 25, 450, buttons_shape, plus_text, theme.green, faster_updates}
*/

	app.gui_elements << ggui.Rect{
		x: 5
		y: 0
		shape: ggui.RoundedShape{100, 410, 10, .top_left}
		color: gg.Color{100, 100, 100, 100}
	}

	// lancement du programme/de la fenêtre
	app.gg.run()
}

fn wire_select(mut app ggui.Gui) {
	if mut app is App {
		app.build_selected_type = .wire
	}
}

fn not_select(mut app ggui.Gui) {
	if mut app is App {
		app.build_selected_type = .not
	}
}

fn diode_select(mut app ggui.Gui) {
	if mut app is App {
		app.build_selected_type = .diode
	}
}

fn junction_select(mut app ggui.Gui) {
	if mut app is App {
		app.build_selected_type = .junction
	}
}

fn on_frame(mut app App) {
	app.no_of_the_frame++
	app.no_of_the_frame = app.no_of_the_frame % app.update_every_x_frame
	if app.no_of_the_frame == 0 {
		for _ in 0 .. app.updates_per_frame {
			app.update()
		}
	}

	// Draw
	app.gg.begin()

	// calculate the images at the right scale
	app.draw_elements()
	app.draw_image()
	app.undraw_elements()
	if !(app.screen_mouse_x < 100 && app.screen_mouse_y < 410) {
		app.preview()
	}
	app.gui.render()
	app.gg.draw_rounded_rect_filled(bt_offset, bt_offset + space * int(app.build_selected_type), bt_scale, bt_scale, 10, gg.Color{80, 80, 80, 150})
	app.gg.draw_image(bt_offset, bt_offset, bt_scale, bt_scale, app.ui_not)
	app.gg.draw_image(bt_offset, bt_offset + space * 1, bt_scale, bt_scale, app.ui_diode)
	app.gg.draw_image(bt_offset, bt_offset + space * 2, bt_scale, bt_scale, app.ui_wire)
	app.gg.draw_image(bt_offset, bt_offset + space * 3, bt_scale, bt_scale, app.ui_junction)
	app.gg.show_fps()
	app.gg.end()
}

fn on_event(e &gg.Event, mut app App) {
	app.mouse_x, app.mouse_y = app.mouse_to_coords(e.mouse_x - (app.viewport_x + app.screen_x/2) % ceil(tile_size * app.scale),
		e.mouse_y - (app.viewport_y + app.screen_y/2) % ceil(tile_size * app.scale))
	old_m_x, old_m_y := app.screen_mouse_x, app.screen_mouse_y
	app.screen_mouse_x, app.screen_mouse_y = int(e.mouse_x), int(e.mouse_y)
	match e.typ {
		.key_down {
			orientation_before := app.build_orientation
			type_before := app.build_selected_type
			match e.key_code {
				/* gg doesn't detect numbers on top of keyboard
				._1 {app.build_selected_type = .not}
				._2 {app.build_selected_type = .diode}
				._3 {app.build_selected_type = .wire}
				._4 {app.build_selected_type = .junction}
				*/
				.escape {
					app.gg.quit()
				}
				.up {
					app.build_orientation = .north
				}
				.down {
					app.build_orientation = .south
				}
				.left {
					app.build_orientation = .west
				}
				.right {
					app.build_orientation = .east
				}
				.enter {
					match app.build_selected_type {
						.not { app.build_selected_type = .diode }
						.diode { app.build_selected_type = .wire }
						.wire { app.build_selected_type = .junction }
						.junction { app.build_selected_type = .not }
					}
				}
				/*
				.w {
					app.viewport_y += 5
				}
				.s {
					app.viewport_y -= 5
				}
				.a {
					app.viewport_x += 5
				}
				.d {
					app.viewport_x -= 5
				}
				*/
				.semicolon {
					old := app.scale
					if app.scale > 0.021 {
						app.scale -= 0.01
					}
					app.viewport_x = int(f64(app.viewport_x) * (app.scale / old) ) 
					app.viewport_y = int(f64(app.viewport_y) * (app.scale / old) )
				}
				.p {
					old := app.scale
					app.scale += 0.01
					app.viewport_x = int(f64(app.viewport_x) * (app.scale / old) )
					app.viewport_y = int(f64(app.viewport_y) * (app.scale / old) )
				}
				.space{
					app.place_is_turn	= 	!app.place_is_turn
				}
				.t {
					if app.debug_mode {
						app.test(6)
					}
				}
				else {}
			}
			if app.debug_mode && (app.build_orientation != orientation_before
				|| app.build_selected_type != type_before) {
				println('app.build_selected_type = .${app.build_selected_type}')
				println('app.build_orientation = .${app.build_orientation}')
			}
		}
		.mouse_up {
			if !(e.mouse_x < 100 && e.mouse_y < 410) {
				place_pos_x := app.mouse_x - (app.viewport_x + app.screen_x/2) / ceil(tile_size * app.scale) 
				place_pos_y := app.mouse_y - (app.viewport_y + app.screen_y/2) / ceil(tile_size * app.scale)
				app.is_placing = false
				app.mouse_up_x = place_pos_x
				app.mouse_up_y = place_pos_y
				match e.mouse_button {
					.left {
						app.line_in(app.mouse_down_x, app.mouse_down_y, app.mouse_up_x, app.mouse_up_y) or {}
					}
					.right {
						app.delete_line_in(app.mouse_down_x, app.mouse_down_y, app.mouse_up_x, app.mouse_up_y) or {}
					}
					else {}
				}
			} else {
				app.gui.check_clicks(e.mouse_x, e.mouse_y)
			}
			app.middle_click_held = false
		}
		.mouse_down {
			match e.mouse_button {
				.middle {
					app.middle_click_held = true
				}
				.left {
					if !(e.mouse_x < 100 && e.mouse_y < 410) {
						app.is_placing = true
						app.mouse_down_x = app.mouse_x - (app.viewport_x + app.screen_x/2) / ceil(tile_size * app.scale) 
						app.mouse_down_y = app.mouse_y - (app.viewport_y + app.screen_y/2) / ceil(tile_size * app.scale)
						app.mouse_down_preview_x	= app.mouse_x
						app.mouse_down_preview_y 	= app.mouse_y
					}
				}
				.right {
					if !(e.mouse_x < 100 && e.mouse_y < 410) {
						app.is_placing = true
						app.mouse_down_x = app.mouse_x - (app.viewport_x + app.screen_x/2) / ceil(tile_size * app.scale) 
						app.mouse_down_y = app.mouse_y - (app.viewport_y + app.screen_y/2) / ceil(tile_size * app.scale)
						app.mouse_down_preview_x	= app.mouse_x
						app.mouse_down_preview_y 	= app.mouse_y
					}
				}
				else{}
			}
		}
		.mouse_scroll {
			old := app.scale
			app.scale += 0.003*e.scroll_y
			if app.scale < 0.020 {
				app.scale = 0.020
			}
			app.viewport_x = int(f64(app.viewport_x) * (app.scale / old) )
			app.viewport_y = int(f64(app.viewport_y) * (app.scale / old) )
		}
		else {}
	}
	if app.middle_click_held {
		app.viewport_x += int((app.screen_mouse_x - old_m_x))
		app.viewport_y += int((app.screen_mouse_y - old_m_y))
	}
}

fn (mut app App) draw_image() {
	mut istream_image := app.gg.get_cached_image_by_idx(app.istream_idx)
	istream_image.update_pixel_data(app.screen_pixels.data)
	app.gg.draw_image(0, 0, app.screen_x, app.screen_y, istream_image)
}

fn graphics_init(mut app App) {
	size := app.gg.window_size()
	app.screen_x = size.width
	app.screen_y = size.height
	app.istream_idx = app.gg.new_streaming_image(size.width, size.height, 4, pixel_format: .rgba8)
	app.screen_pixels = []u32{len: app.screen_y * app.screen_x, init: u32(0x0)}
	app.blank_screen = []u32{len: app.screen_y * app.screen_x, init: u32(0x0)}
}
