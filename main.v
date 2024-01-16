module main

import gg
import gx
import ggui
import math

const tile_size = 10
const theme     = ggui.CatppuchinMocha{}
const buttons_shape	= ggui.RoundedShape{20, 20, 5, .top_left}

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
}

enum Orientation as u8 {
	north
	south
	east
	west
}

interface Element {
mut:
	destroyed bool
	in_gate bool
	x i64
	y i64
}

@[heap]
struct Chunk {
mut:
	x i64
	y i64
	tiles [][]i64 = [][]i64{len:16, init:[]i64{len:16, init:-1}}
}

struct App {
mut:
    gg    &gg.Context = unsafe { nil }
	elements []Element
	destroyed []i64
	chunks []Chunk  // reopti les chunks pour éviter les cache misses en séparant les coords des 2D arrays
	wire_groups []GlobalWire
	queue []i64
	queue_gwires []i64

	no_of_the_frame int
	update_every_x_frame int = 10
	updates_per_frame int = 1

	gui		&ggui.Gui = unsafe { nil }
	clickables []ggui.Clickable
	gui_elements []ggui.Element

	mouse_x int
	mouse_y int

	build_selected_type Variant
	build_orientation Orientation

	debug_mode bool = true

	istream_idx int
	screen_pixels [768][1366]u32 = [768][1366]u32{init:[1366]u32{init:u32(0xFF555555)}}
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
        sample_count: 6
    )
	app.build_selected_type = .wire
	app.build_orientation = .west

	// do your test/base placings here if needed

	/*
	app.build_orientation = .west
	app.build_selected_type = .not
	app.place_in(1, 11)!
	app.build_selected_type = .wire
	app.place_in(0,  11)!
	app.place_in(2, 11)!
	app.place_in(0,  12)!
	app.place_in(1, 12)!
	app.place_in(3, 12)!
	app.place_in(2, 12)!
	// app.place_in(4, 13)!
	// app.place_in(5, 14)!
	// app.place_in(3, 13)!
	*/
	/*
	app.build_orientation = .north
	app.build_selected_type = .not
	app.place_in(1, 11)!
	app.build_selected_type = .wire
	app.place_in(1,  10)!
	app.place_in(2, 10)!
	app.place_in(2,  11)!
	app.place_in(1, 12)!
	*/

	not_text := ggui.Text{0, 0, 0, "!", gx.TextCfg{color:theme.base, size:20, align:.center, vertical_align:.middle}}
	wire_text := ggui.Text{0, 0, 0, "-", gx.TextCfg{color:theme.base, size:20, align:.center, vertical_align:.middle}}
	minus_text := ggui.Text{0, 0, 0, "-", gx.TextCfg{color:theme.base, size:20, align:.center, vertical_align:.middle}}
	plus_text := ggui.Text{0, 0, 0, "+", gx.TextCfg{color:theme.base, size:20, align:.center, vertical_align:.middle}}
	_ := gx.TextCfg{color:theme.text, size:20, align:.right, vertical_align:.top}

	app.clickables << ggui.Button{0, 20, 5, buttons_shape, wire_text, theme.red, wire_select}
	app.clickables << ggui.Button{0, 45, 5, buttons_shape, not_text, theme.green, not_select}

	app.clickables << ggui.Button{0, 60, 5, buttons_shape, minus_text, theme.red, slower_updates}
	app.clickables << ggui.Button{0, 85, 5, buttons_shape, plus_text, theme.green, faster_updates}

    app.gui_elements << ggui.Rect{x:0, y:0, shape:ggui.RoundedShape{160, 30, 5, .top_left}, color:theme.mantle}

	app.build_selected_type = .wire	
    //lancement du programme/de la fenêtre
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

fn faster_updates(mut app ggui.Gui) {
	if mut app is App {
		if app.update_every_x_frame == 1 {
			app.updates_per_frame = match app.updates_per_frame {
				1 { 3 }
				3 { 5 }
				5 { 9 }
				9 { 19 }
				19 { 49 }
				49 { 99 }
				else { app.updates_per_frame }
			}
		} else {
			app.update_every_x_frame = match app.update_every_x_frame {
				60 { 30 }
				30 { 10 }
				10 { 5 }
				5 { 3 }
				3 { 2 }
				2 { 1 }
				else { app.update_every_x_frame }
			}
		}
	}
}

fn slower_updates(mut app ggui.Gui) {
	if mut app is App {
		if app.update_every_x_frame == 1 {
			app.updates_per_frame = match app.updates_per_frame {
				3 { 1 }
				5 { 3 }
				9 { 5 }
				19 { 9 }
				49 { 19 }
				99 { 49 }
				else { app.updates_per_frame }
			}
			if app.updates_per_frame == 1 {
				app.update_every_x_frame = 2
			}
		} else {
			app.update_every_x_frame = match app.update_every_x_frame {
				30 { 60 }
				10 { 30 }
				5 { 10 }
				3 { 5 }
				2 { 3 }
				1 { 2 }
				else { app.update_every_x_frame }
			}
		}
	}
}

fn on_frame(mut app App) {
	app.no_of_the_frame++
	app.no_of_the_frame = app.no_of_the_frame % app.update_every_x_frame
	if app.no_of_the_frame == 0 {
		for _ in 0..app.updates_per_frame {
			app.update()
		}
	}
	

    //Draw
    app.gg.begin()
	for chunk in app.chunks {
		for line in chunk.tiles {
			for nb_element in line {
				if nb_element >= 0 {
					mut element := &app.elements[nb_element]
					match mut element {
						Not {
							color := if element.state {gx.green} else {gx.red}
							app.gg.draw_square_filled(f32(element.x*tile_size), f32(element.y*tile_size), tile_size, gx.black)
							rotation := match element.orientation {
								.north { -90 }
								.south { 90 }
								.east { 0 }
								.west { 180 }
							}
							app.gg.draw_polygon_filled(f32(element.x*tile_size)+tile_size/2.0, f32(element.y*tile_size)+tile_size/2.0, tile_size/2.0, 3, rotation, color)
						}
						Wire {
							// color := if app.wire_groups[element.id_glob_wire].on() {gg.Color{239, 208, 18, 255}} else {gx.black}
							color := if app.wire_groups[element.id_glob_wire].on() {u32(0xFF12_D0_EF)} else {u32(0xFF00_0000)}
							//app.gg.draw_square_filled(f32(element.x*tile_size), f32(element.y*tile_size), tile_size, color)
							for y in 0..tile_size {
								for x in 0..tile_size {
									app.screen_pixels[element.y*tile_size+y][element.x*tile_size+x] = color
								}
							}
						}
						else {}
					}
				}
			}
		}
	}
	app.draw_image()
	match app.build_selected_type {
		.not {
			color := gg.Color{50, 100, 100, 100}
			app.gg.draw_square_filled(f32(app.mouse_x*tile_size), f32(app.mouse_y*tile_size), tile_size, gg.Color{100, 100, 100, 100})
			rotation := match app.build_orientation {
				.north { -90 }
				.south { 90 }
				.east { 0 }
				.west { 180 }
			}
			app.gg.draw_polygon_filled(f32(app.mouse_x*tile_size)+tile_size/2.0, f32(app.mouse_y*tile_size)+tile_size/2.0, tile_size/2.0, 3, rotation, color)
		}
		.wire {
			color := gg.Color{100, 100, 100, 100}
			app.gg.draw_square_filled(f32(app.mouse_x*tile_size), f32(app.mouse_y*tile_size), tile_size, color)
		}
		else {}
	}
	app.gui.render()
	app.gg.show_fps()
    app.gg.end()
}

fn on_event(e &gg.Event, mut app App){
	app.mouse_x, app.mouse_y = mouse_to_coords(e.mouse_x, e.mouse_y)
    match e.typ {
        .key_down {
            match e.key_code {
                .escape {app.gg.quit()}
				.up {app.build_orientation = .north}
				.down {app.build_orientation = .south}
				.left {app.build_orientation = .west}
				.right {app.build_orientation = .east}
				.enter {
					match app.build_selected_type {
						.not {app.build_selected_type = .wire}
						.wire {app.build_selected_type = .not}
						else {app.build_selected_type = .not}
					}
				}
                else {}
            }
			if app.debug_mode {
				println("app.build_selected_type = .$app.build_selected_type")
				println("app.build_orientation = .$app.build_orientation")
			}
        }
        .mouse_up {
			if !(e.mouse_x < 160 && e.mouse_y < 30) {
				match e.mouse_button{
					.left{
						app.place_in(app.mouse_x, app.mouse_y) or {}
					}
					.right {
						app.delete_in(app.mouse_x, app.mouse_y) or {}
					}
					else{}
				}
			} else {
				app.gui.check_clicks(e.mouse_x, e.mouse_y)
			}
		}
        else {}
    }
}

fn (mut app App) get_chunk_at_coords(x int, y int) &Chunk {
	chunk_y := int(math.floor(f64(y)/16.0))
	chunk_x := int(math.floor(f64(x)/16.0))
	for chunk in app.chunks {
		if chunk.x == chunk_x && chunk.y == chunk_y {
			return &chunk
		}
	}
	app.chunks << Chunk{chunk_x, chunk_y, [][]i64{len:16, init:[]i64{len:16, init:-1}}}
	return &app.chunks[app.chunks.len-1]
}

fn (mut app App) get_tile_id_at(x int, y int) i64 {
	chunk := app.get_chunk_at_coords(x, y)
	return chunk.tiles[math.abs(y-chunk.y*16)][math.abs(x-chunk.x*16)]
}

fn mouse_to_coords(x f32, y f32) (int, int) {
	return int(x)/tile_size, int(y)/tile_size
}

// returns the relative coordinates of the input of a not gate
fn input_coords_from_orientation(ori Orientation) (int, int) {
	return match ori {
		.north {
			0, 1
		}
		.south {
			0, -1
		}
		.east {
			-1, 0
		}
		.west {
			1, 0
		}
	}
}


// returns the relative coordinates of the output of a not gate
fn output_coords_from_orientation(ori Orientation) (int, int) {
	return match ori {
		.north {
			0, -1
		}
		.south {
			0, 1
		}
		.east {
			1, 0
		}
		.west {
			-1, 0
		}
	}
}

fn (mut app App) draw_image() {
	mut istream_image := app.gg.get_cached_image_by_idx(app.istream_idx)
	istream_image.update_pixel_data(unsafe { &u8(&app.screen_pixels) })
	size := gg.window_size_real_pixels()
	app.gg.draw_image(0, 0, size.width, size.height, istream_image)
}

fn graphics_init(mut app App) {
	app.istream_idx = app.gg.new_streaming_image(1366, 768, 4, pixel_format: .rgba8)
}