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
const tcfg = gx.TextCfg {
	size: 30
}


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

enum Clicks as u8 {
	no
	left
	right
}

enum InputMode {
	no
	finished
	save_gate_name
	load_gate_name
	wait_for_action
	waiting_to_paste
	waiting_to_load
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
	is_placing					Clicks
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

	debug_mode bool

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

	select_mode bool
	start_creation_x int = -1000000000
	start_creation_y int = -1000000000
	start_creation_mouse_x int
	start_creation_mouse_y int
	end_creation_x int
	end_creation_y int
	end_creation_mouse_x int
	end_creation_mouse_y int
	wait_name_save bool
	wait_name_load bool

	input_mode InputMode
	input string

	copy_buffer []u8 
	gate_x int
	gate_y int
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

	app.ui_not = app.gg.create_image(os.resource_abs_path('on_not_gate.png'))!
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
		type_before := app.build_selected_type
		app.build_selected_type = .wire
		if app.build_selected_type != type_before {
			println('app.build_selected_type = .${app.build_selected_type}')
		}
	}
}

fn not_select(mut app ggui.Gui) {
	if mut app is App {
		type_before := app.build_selected_type
		app.build_selected_type = .not
		if app.build_selected_type != type_before {
			println('app.build_selected_type = .${app.build_selected_type}')
		}
	}
}

fn diode_select(mut app ggui.Gui) {
	if mut app is App {
		type_before := app.build_selected_type
		app.build_selected_type = .diode
		if app.build_selected_type != type_before {
			println('app.build_selected_type = .${app.build_selected_type}')
		}
	}
}

fn junction_select(mut app ggui.Gui) {
	if mut app is App {
		type_before := app.build_selected_type
		app.build_selected_type = .junction
		if app.build_selected_type != type_before {
			println('app.build_selected_type = .${app.build_selected_type}')
		}
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
	if app.select_mode || app.input_mode == .waiting_to_paste || app.input_mode == .waiting_to_load  {
		if app.input_mode == .waiting_to_paste {
			app.box_preview()
		} else if app.input_mode == .waiting_to_load {
			app.cursor_preview(app.mouse_x, app.mouse_y)
		} else {
			if app.start_creation_x != -1000000000 && app.start_creation_y != -1000000000  {
				app.box_preview()
			}
		}
	}
	else if app.input_mode == .waiting_to_load {
		app.cursor_preview(app.mouse_x, app.mouse_y)
	} else {
		if !(app.screen_mouse_x < 100 && app.screen_mouse_y < 410) {
			app.preview()
		}
	}
	app.gui.render()
	app.gg.draw_rounded_rect_filled(bt_offset, bt_offset + space * int(app.build_selected_type), bt_scale, bt_scale, 10, gg.Color{80, 80, 80, 150})
	app.gg.draw_image(bt_offset, bt_offset, bt_scale, bt_scale, app.ui_not)
	app.gg.draw_image(bt_offset, bt_offset + space * 1, bt_scale, bt_scale, app.ui_diode)
	app.gg.draw_image(bt_offset, bt_offset + space * 2, bt_scale, bt_scale, app.ui_wire)
	app.gg.draw_image(bt_offset, bt_offset + space * 3, bt_scale, bt_scale, app.ui_junction)
	if app.input_mode != .no {
		match app.input_mode {
			.save_gate_name { app.gg.draw_text(110, 20, "Gate name: " + app.input, tcfg) }
			.load_gate_name { app.gg.draw_text(110, 20, "Gate name: " + app.input, tcfg) }
			else {}
		}
	}
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
			if app.input_mode == .no || app.input_mode == .wait_for_action || app.input_mode == .waiting_to_load {
				match e.key_code {
					/* gg doesn't detect numbers on top of keyboard
					._1 {app.build_selected_type = .not}
					._2 {app.build_selected_type = .diode}
					._3 {app.build_selected_type = .wire}
					._4 {app.build_selected_type = .junction}
					*/
					.b {
						app.select_mode = !app.select_mode
						if !app.select_mode {
							app.start_creation_x = -1000000000
							app.start_creation_y = -1000000000
						}
					}
					.l {
						app.input_mode = .load_gate_name
					}
					.escape {
						if (app.start_creation_x != -1000000000 && app.start_creation_y != -1000000000) || app.input_mode == .waiting_to_paste || app.input_mode == .waiting_to_load {
							app.start_creation_x = -1000000000
							app.start_creation_y = -1000000000
							app.select_mode = false
							app.input_mode = .no
						}
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
					.s {
						if app.select_mode {
							app.wait_name_save = true
							app.input_mode = .save_gate_name
						} 
					}
					.delete {
						if app.select_mode && app.start_creation_y != -1000000000 && app.start_creation_y != -1000000000 {
							if app.start_creation_x > app.end_creation_x {
								app.end_creation_x, app.start_creation_x = app.start_creation_x, app.end_creation_x
							}
							if app.start_creation_y > app.end_creation_y {
								app.end_creation_y, app.start_creation_y = app.start_creation_y, app.end_creation_y
							}
							for y in app.start_creation_y .. app.end_creation_y + 1 {
								for x in app.start_creation_x .. app.end_creation_x + 1 {
									app.delete_in(x, y) or {}
								}
							}
							app.start_creation_x = -1000000000
							app.start_creation_y = -1000000000
							app.input_mode = .no
						} 
					}
					.enter {
						match app.build_selected_type {
							.not { app.build_selected_type = .diode }
							.diode { app.build_selected_type = .wire }
							.wire { app.build_selected_type = .junction }
							.junction { app.build_selected_type = .not }
						}
					}
					.c {
						if app.select_mode && app.start_creation_y != -1000000000 && app.start_creation_y != -1000000000 {
							app.copy_buffer = app.gate_buffer()
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
						dump("pasting")
						app.input_mode = .waiting_to_paste
					}
					.space{
						app.place_is_turn	= 	!app.place_is_turn
					}
					.t {
						if app.debug_mode {
							app.test(6)
						}
					}
					else {dump(e.key_code)}
				}
			} else {
				match e.key_code {
					.enter {
						if app.input.len > 0 {
							match app.input_mode {
								.save_gate_name {
									app.save_gate(app.input)
									app.input_mode = .no
								}
								.load_gate_name { app.input_mode = .waiting_to_load }
								else {app.input_mode = .no}
							}
						}
						app.start_creation_x = -1000000000
						app.start_creation_y = -1000000000
					}
					.escape {
						app.start_creation_x = -1000000000
						app.start_creation_y = -1000000000
						app.input_mode = .no
					}
					.left_shift {}
					.backspace { if app.input.len > 0 { app.input = app.input[..app.input.len-1] } }
					else { app.input = app.input + e.key_code.str() }
				}
			}
			if app.debug_mode && (app.build_orientation != orientation_before
				|| app.build_selected_type != type_before) {
				println('app.build_selected_type = .${app.build_selected_type}')
				println('app.build_orientation = .${app.build_orientation}')
			}
		}
		.mouse_up {
			if app.select_mode {
				match e.mouse_button {
					.left {
						match app.input_mode {
							.waiting_to_paste { 
								app.place_gate(app.copy_buffer) or {} 
								app.input_mode = .no

								app.start_creation_x = -1000000000
								app.start_creation_y = -1000000000
							}
							.waiting_to_load {
								app.load_gate(app.input) or {}
							}
							else {								
								app.end_creation_x, app.end_creation_y = app.mouse_x - (app.viewport_x + app.screen_x/2) / ceil(tile_size * app.scale) , app.mouse_y - (app.viewport_y + app.screen_y/2) / ceil(tile_size * app.scale) 
								app.end_creation_mouse_x, app.end_creation_mouse_y = app.mouse_x, app.mouse_y
								app.input_mode = .wait_for_action
							}
						}
					}
					else {}
				}
			} else {
				if !(e.mouse_x < 100 && e.mouse_y < 410) {
					match app.input_mode {
						.waiting_to_paste { 
							match e.mouse_button {
								.left {
									app.place_gate(app.copy_buffer) or {} 
									app.input_mode = .no

									app.start_creation_x = -1000000000
									app.start_creation_y = -1000000000
								}
								else {}
							}
						}
						.waiting_to_load {
							match e.mouse_button {
								.left {
									app.load_gate(app.input) or {}
								}
								else {}
							}
						}
						else {								
							place_pos_x := app.mouse_x - (app.viewport_x + app.screen_x/2) / ceil(tile_size * app.scale) 
							place_pos_y := app.mouse_y - (app.viewport_y + app.screen_y/2) / ceil(tile_size * app.scale)
							app.mouse_up_x = place_pos_x
							app.mouse_up_y = place_pos_y
							match e.mouse_button {
								.left {
									if app.is_placing == Clicks.left{
										app.line_in(app.mouse_down_x, app.mouse_down_y, app.mouse_up_x, app.mouse_up_y) or {}
										app.is_placing = Clicks.no
									}
								}
								.right {
									if app.is_placing == Clicks.right{
										app.delete_line_in(app.mouse_down_x, app.mouse_down_y, app.mouse_up_x, app.mouse_up_y) or {}
										app.is_placing = Clicks.no
									}
								}
								else {}
							}
						}
					}
				} else {
					app.gui.check_clicks(e.mouse_x, e.mouse_y)
				}
			}
			app.middle_click_held = false
		}
		.mouse_down {
			if app.input_mode != .waiting_to_paste && app.input_mode != .waiting_to_load {
				match e.mouse_button {
					.middle {
						app.middle_click_held = true
					}
					.left {					
						if !(e.mouse_x < 100 && e.mouse_y < 410) {
							if app.select_mode {
								app.input_mode = .no
								app.start_creation_x, app.start_creation_y = app.mouse_x - (app.viewport_x + app.screen_x/2) / ceil(tile_size * app.scale) , app.mouse_y - (app.viewport_y + app.screen_y/2) / ceil(tile_size * app.scale) 
								app.start_creation_mouse_x, app.start_creation_mouse_y = app.mouse_x, app.mouse_y
							}
							else if app.is_placing == Clicks.no {
								app.is_placing = Clicks.left
								app.mouse_down_x = app.mouse_x - (app.viewport_x + app.screen_x/2) / ceil(tile_size * app.scale) 
								app.mouse_down_y = app.mouse_y - (app.viewport_y + app.screen_y/2) / ceil(tile_size * app.scale)
								app.mouse_down_preview_x = app.mouse_x
								app.mouse_down_preview_y = app.mouse_y
							}
						}
					}
					.right {
						if !(e.mouse_x < 100 && e.mouse_y < 410) && app.is_placing == Clicks.no {
							app.is_placing = Clicks.right
							app.mouse_down_x = app.mouse_x - (app.viewport_x + app.screen_x/2) / ceil(tile_size * app.scale) 
							app.mouse_down_y = app.mouse_y - (app.viewport_y + app.screen_y/2) / ceil(tile_size * app.scale)
							app.mouse_down_preview_x	= app.mouse_x
							app.mouse_down_preview_y 	= app.mouse_y
						}
					}
					else{}
				}
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
