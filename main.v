module main

import gg
import gx
import ggui
import math
import stbi

const tile_size = 128
const theme = ggui.CatppuchinMocha{}
const buttons_shape = ggui.RoundedShape{20, 20, 5, .top_left}
const not_image = load_image('off_not_gate.png')
const on_not_image = load_image('on_not_gate.png')

enum Id {
	@none
}

fn id(id Id) int {
	return int(id)
}

enum Variant as u8 {
	@none
	not
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
}

fn main() {
	mut app := &App{}
	app.gui = &ggui.Gui(app)
	app.gg = gg.new_context(
		fullscreen: true
		create_window: true
		window_title: '- Nots -'
		user_data: app
		bg_color: gx.white
		frame_fn: on_frame
		event_fn: on_event
		init_fn: graphics_init
		sample_count: 4
	)
	app.build_selected_type = .wire
	app.build_orientation = .west

	// calculate the rotations of the image

	// do your test/base placings here if needed

	not_text := ggui.Text{0, 0, 0, '!', gx.TextCfg{
		color: theme.base
		size: 20
		align: .center
		vertical_align: .middle
	}}
	wire_text := ggui.Text{0, 0, 0, '-', gx.TextCfg{
		color: theme.base
		size: 20
		align: .center
		vertical_align: .middle
	}}
	minus_text := ggui.Text{0, 0, 0, '-', gx.TextCfg{
		color: theme.base
		size: 20
		align: .center
		vertical_align: .middle
	}}
	plus_text := ggui.Text{0, 0, 0, '+', gx.TextCfg{
		color: theme.base
		size: 20
		align: .center
		vertical_align: .middle
	}}
	_ := gx.TextCfg{
		color: theme.text
		size: 20
		align: .right
		vertical_align: .top
	}

	app.clickables << ggui.Button{0, 20, 5, buttons_shape, wire_text, theme.red, wire_select}
	app.clickables << ggui.Button{0, 45, 5, buttons_shape, not_text, theme.green, not_select}

	app.clickables << ggui.Button{0, 60, 5, buttons_shape, minus_text, theme.red, slower_updates}
	app.clickables << ggui.Button{0, 85, 5, buttons_shape, plus_text, theme.green, faster_updates}

	app.gui_elements << ggui.Rect{
		x: 0
		y: 0
		shape: ggui.RoundedShape{160, 30, 5, .top_left}
		color: theme.mantle
	}

	app.build_selected_type = .wire

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
	half_scaled_tile_size := f32(ceil(tile_size * app.scale)) * 0.5
	preview_x := f32(app.mouse_x * ceil(tile_size * app.scale) + (app.viewport_x + app.screen_x/2) % ceil(tile_size * app.scale))
	preview_y := f32(app.mouse_y * ceil(tile_size * app.scale) + (app.viewport_y + app.screen_y/2) % ceil(tile_size * app.scale))
	match app.build_selected_type {
		.not {
			color := gg.Color{50, 100, 100, 100}
			app.gg.draw_square_filled(preview_x, preview_y, ceil(tile_size * app.scale), gg.Color{100, 100, 100, 100})
			rotation := match app.build_orientation {
				.north { -90 }
				.south { 90 }
				.east { 0 }
				.west { 180 }
			}
			app.gg.draw_polygon_filled(preview_x + half_scaled_tile_size, preview_y + half_scaled_tile_size, half_scaled_tile_size, 3, rotation, color)
		}
		.wire {
			color := gg.Color{100, 100, 100, 100}
			app.gg.draw_square_filled(preview_x, preview_y, ceil(tile_size * app.scale), color)
		}
		.junction {
			color := gg.Color{255, 0, 255, 100}
			app.gg.draw_square_filled(preview_x, preview_y, ceil(tile_size * app.scale), color)
		}
		else {}
	}
	app.gui.render()
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
						.not { app.build_selected_type = .wire }
						.wire { app.build_selected_type = .junction }
						.junction { app.build_selected_type = .not }
						else { app.build_selected_type = .not }
					}
				}
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
				else {}
			}
			if app.debug_mode && (app.build_orientation != orientation_before
				|| app.build_selected_type != type_before) {
				println('app.build_selected_type = .${app.build_selected_type}')
				println('app.build_orientation = .${app.build_orientation}')
			}
		}
		.mouse_up {
			if !(e.mouse_x < 160 && e.mouse_y < 30) {
				place_pos_x := app.mouse_x - (app.viewport_x + app.screen_x/2) / ceil(tile_size * app.scale) 
				place_pos_y := app.mouse_y - (app.viewport_y + app.screen_y/2) / ceil(tile_size * app.scale)
				match e.mouse_button {
					.left {
						app.place_in(place_pos_x, place_pos_y) or {}
					}
					.right {
						app.delete_in(place_pos_x, place_pos_y) or {}
					}
					else {}
				}
			} else {
				app.gui.check_clicks(e.mouse_x, e.mouse_y)
			}
			app.middle_click_held = false
		}
		.mouse_down {
			if e.mouse_button == .middle {
				app.middle_click_held = true
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
	app.screen_pixels = []u32{len: app.screen_y * app.screen_x, init: u32(0xFFBBBBBB)}
	app.blank_screen = []u32{len: app.screen_y * app.screen_x, init: u32(0xFFBBBBBB)}
}
