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

fn load_image(path string) []Color {
	image := stbi.load(path, stbi.LoadParams{4}) or { panic('Image not found: ${path}') }
	data := &u8(image.data)
	mut output := []Color{cap: tile_size * tile_size}
	for i in 0 .. tile_size * tile_size {
		unsafe {
			output << Color{data[i * 4], data[i * 4 + 1], data[i * 4 + 2], data[i * 4 + 3]}
		}
	}
	return output
}

@[inline]
fn a_coords(y int, x int, size int) int {
	return y * size + x
}

@[inline]
fn ceil(nb f64) int {
	return -int(-nb)
}

fn rotate_img(a []Color, new_o Orientation, side_size int) []Color {
	match new_o {
		.north {
			return a
		}
		.south {
			return []Color{len: a.len, init: a[a.len - index - 1]}
		}
		.west {
			return []Color{len: a.len, init: a[(index % side_size + 1) * side_size - index / side_size - 1]}
		}
		.east {
			return []Color{len: a.len, init: a[(side_size - index % side_size - 1) * side_size +
				index / side_size]}
		}
	}
}

@[direct_array_access]
fn scale_img(a []Color, scale_goal f64, x_size int, y_size int) []Color {
	base_side_x := x_size
	base_side_y := y_size
	scaled_side_x := ceil(f64(base_side_x) * scale_goal)
	scaled_side_y := ceil(f64(base_side_y) * scale_goal)
	if scaled_side_y != base_side_y && scaled_side_x != base_side_x {
		mut new_a := []Color{len: scaled_side_y * scaled_side_x}
		for l in 0 .. scaled_side_y {
			for c in 0 .. scaled_side_x {
				// Index in the new array of the current pixel
				new_i := l * scaled_side_y + c

				// needs division (for proportionality) but only if needed :
				mut val_l := f64(l * (base_side_y - 1))
				mut val_c := f64(c * (base_side_x - 1))

				// if the division is a integer (it corresponds to an exact pixel)
				l_is_int := int(val_l) % (scaled_side_y - 1) != 0
				c_is_int := int(val_c) % (scaled_side_x - 1) != 0

				// divide
				val_l /= (scaled_side_y - 1)
				val_c /= (scaled_side_x - 1)
				int_val_l := int(val_l)
				int_val_c := int(val_c)

				// Take the right pixel values
				if l_is_int && c_is_int {
					new_a[new_i] = a[int(val_l) * base_side_x + int_val_c]
				} else if !(l_is_int || c_is_int) { // none of them
					new_a[new_i].r = u8(
						a[a_coords(int_val_l, int_val_c, base_side_x)].r * float_gap(val_c) * float_gap(val_l) +
						a[a_coords(int_val_l, ceil(val_c), base_side_x)].r * float_offset(val_c) * float_gap(val_l) +
						a[a_coords(ceil(val_l), int_val_c, base_side_x)].r * float_offset(val_l) * float_gap(val_c) +
						a[a_coords(ceil(val_l), ceil(val_c), base_side_x)].r * float_offset(val_l) * float_offset(val_c))
					new_a[new_i].g = u8(
						a[a_coords(int_val_l, int_val_c, base_side_x)].g * float_gap(val_c) * float_gap(val_l) +
						a[a_coords(int_val_l, ceil(val_c), base_side_x)].g * float_offset(val_c) * float_gap(val_l) +
						a[a_coords(ceil(val_l), int_val_c, base_side_x)].g * float_offset(val_l) * float_gap(val_c) +
						a[a_coords(ceil(val_l), ceil(val_c), base_side_x)].g * float_offset(val_l) * float_offset(val_c))
					new_a[new_i].b = u8(
						a[a_coords(int_val_l, int_val_c, base_side_x)].b * float_gap(val_c) * float_gap(val_l) +
						a[a_coords(int_val_l, ceil(val_c), base_side_x)].b * float_offset(val_c) * float_gap(val_l) +
						a[a_coords(ceil(val_l), int_val_c, base_side_x)].b * float_offset(val_l) * float_gap(val_c) +
						a[a_coords(ceil(val_l), ceil(val_c), base_side_x)].b * float_offset(val_l) * float_offset(val_c))
					new_a[new_i].a = u8(
						a[a_coords(int_val_l, int_val_c, base_side_x)].a * float_gap(val_c) * float_gap(val_l) +
						a[a_coords(int_val_l, ceil(val_c), base_side_x)].a * float_offset(val_c) * float_gap(val_l) +
						a[a_coords(ceil(val_l), int_val_c, base_side_x)].a * float_offset(val_l) * float_gap(val_c) +
						a[a_coords(ceil(val_l), ceil(val_c), base_side_x)].a * float_offset(val_l) * float_offset(val_c))
				} else if l_is_int { // exact line (not useful for squares I think but there if needed)
					new_a[new_i].r = u8(
						a[a_coords(int_val_l, int_val_c, base_side_x)].r * float_gap(val_c) +
						a[a_coords(int_val_l, ceil(val_c), base_side_x)].r * float_offset(val_c))
					new_a[new_i].g = u8(
						a[a_coords(int_val_l, int_val_c, base_side_x)].g * float_gap(val_c) +
						a[a_coords(int_val_l, ceil(val_c), base_side_x)].g * float_offset(val_c))
					new_a[new_i].b = u8(
						a[a_coords(int_val_l, int_val_c, base_side_x)].b * float_gap(val_c) +
						a[a_coords(int_val_l, ceil(val_c), base_side_x)].b * float_offset(val_c))
					new_a[new_i].a = u8(
						a[a_coords(int_val_l, int_val_c, base_side_x)].a * float_gap(val_c) +
						a[a_coords(int_val_l, ceil(val_c), base_side_x)].a * float_offset(val_c))
				} else { // exact collumn (not useful for squares I think but there if needed)
					new_a[new_i].r = u8(
						a[a_coords(int_val_l, int_val_c, base_side_x)].r * float_gap(val_l) +
						a[a_coords(ceil(val_l), int_val_c, base_side_x)].r * float_offset(val_l))
					new_a[new_i].g = u8(
						a[a_coords(int_val_l, int_val_c, base_side_x)].g * float_gap(val_l) +
						a[a_coords(ceil(val_l), int_val_c, base_side_x)].g * float_offset(val_l))
					new_a[new_i].b = u8(
						a[a_coords(int_val_l, int_val_c, base_side_x)].b * float_gap(val_l) +
						a[a_coords(ceil(val_l), int_val_c, base_side_x)].b * float_offset(val_l))
					new_a[new_i].a = u8(
						a[a_coords(int_val_l, int_val_c, base_side_x)].a * float_gap(val_l) +
						a[a_coords(ceil(val_l), int_val_c, base_side_x)].a * float_offset(val_l))
				}
			}
		}
		return new_a // needs to be cropped
	} else {
		return a
	}
}

@[inline]
fn float_offset(f f64) f64 {
	return f - int(f)
}

@[inline]
fn float_gap(f f64) f64 {
	return 1 - float_offset(f)
}

struct Color {
mut:
	r u8
	g u8
	b u8
	a u8
}

fn (c Color) u32() u32 {
	return (u32(c.a) << 24) | (u32(c.b) << 16) | (u32(c.g) << 8) | c.r
}

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
	in_gate   bool
	x         i64
	y         i64
}

@[heap]
struct Chunk {
mut:
	x     i64
	y     i64
	tiles [][]i64 = [][]i64{len: 16, init: []i64{len: 16, init: -1}}
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
		else {}
	}
	app.gui.render()
	app.gg.show_fps()
	app.gg.end()
}

@[direct_array_access]
fn (mut app App) draw_elements() {
	scaled_tile_size := ceil(tile_size * app.scale)
	scaled_image_not := scale_img(not_image, app.scale, tile_size, tile_size)
	not_image_scaled_north := rotate_img(scaled_image_not, .north, scaled_tile_size)
	not_image_scaled_south := rotate_img(scaled_image_not, .south, scaled_tile_size)
	not_image_scaled_east := rotate_img(scaled_image_not, .east, scaled_tile_size)
	not_image_scaled_west := rotate_img(scaled_image_not, .west, scaled_tile_size)
	on_scaled_image_not := scale_img(on_not_image, app.scale, tile_size, tile_size)
	on_not_image_scaled_north := rotate_img(on_scaled_image_not, .north, scaled_tile_size)
	on_not_image_scaled_south := rotate_img(on_scaled_image_not, .south, scaled_tile_size)
	on_not_image_scaled_east := rotate_img(on_scaled_image_not, .east, scaled_tile_size)
	on_not_image_scaled_west := rotate_img(on_scaled_image_not, .west, scaled_tile_size)
	for chunk in app.chunks {
		for line in chunk.tiles {
			for id_element in line {
				if id_element >= 0 {
					mut element := &app.elements[id_element]
					scaled_elem_x := element.x * scaled_tile_size
					scaled_elem_y := element.y * scaled_tile_size
					place_x := scaled_elem_x + scaled_tile_size - 1 + app.viewport_x + app.screen_x/2
					place_y := scaled_elem_y + scaled_tile_size - 1 + app.viewport_y + app.screen_y/2

					if place_x >= scaled_tile_size - 1 && place_x < app.screen_x
						&& place_y >= scaled_tile_size - 1 && place_y < app.screen_y {
						array_pos := (scaled_elem_y + app.viewport_y + app.screen_y/2) * app.screen_x + scaled_elem_x + app.viewport_x + app.screen_x/2
						match mut element {
							Not {
								good_image := match element.state {
									false {
										match element.orientation {
											.north { &not_image_scaled_north }
											.south { &not_image_scaled_south }
											.east { &not_image_scaled_east }
											.west { &not_image_scaled_west }
										}
									}
									true {
										match element.orientation {
											.north { &on_not_image_scaled_north }
											.south { &on_not_image_scaled_south }
											.east { &on_not_image_scaled_east }
											.west { &on_not_image_scaled_west }
										}
									}
								}
								for y in 0 .. scaled_tile_size {
									for x in 0 .. scaled_tile_size {
										app.screen_pixels[array_pos + y * app.screen_x + x] = unsafe {good_image[y * scaled_tile_size + x].u32()}
									}
								}
							}
							Wire {
								color := if app.wire_groups[element.id_glob_wire].on() {
									u32(0xFF12_D0_EF)
								} else {
									u32(0xFF00_0000)
								}
								for y in 0 .. scaled_tile_size {
									for x in 0 .. scaled_tile_size {
										app.screen_pixels[array_pos + y * app.screen_x + x] = color
									}
								}
							}
							else {}
						}
					}
				}
			}
		}
	}
}

@[direct_array_access]
fn (mut app App) undraw_elements() {
	scaled_tile_size := ceil(tile_size * app.scale)
	for chunk in app.chunks {
		for line in chunk.tiles {
			for id_element in line {
				if id_element >= 0 {
					mut element := &app.elements[id_element]
					scaled_elem_x := element.x * scaled_tile_size
					scaled_elem_y := element.y * scaled_tile_size
					place_x := scaled_elem_x + scaled_tile_size - 1 + app.viewport_x + app.screen_x/2
					place_y := scaled_elem_y + scaled_tile_size - 1 + app.viewport_y + app.screen_y/2

					if place_x >= scaled_tile_size - 1 && place_x < app.screen_x 
						&& place_y >= scaled_tile_size - 1 && place_y < app.screen_y {
						array_pos := (scaled_elem_y + app.viewport_y + app.screen_y/2) * app.screen_x + scaled_elem_x + app.viewport_x + app.screen_x/2
						match mut element {
							Not {
								for y in 0 .. scaled_tile_size {
									for x in 0 .. scaled_tile_size {
										app.screen_pixels[array_pos + y * app.screen_x + x] = u32(0xFFBBBBBB)
									}
								}
							}
							Wire {
								for y in 0 .. scaled_tile_size {
									for x in 0 .. scaled_tile_size {
										app.screen_pixels[array_pos + y * app.screen_x + x] = u32(0xFFBBBBBB)
									}
								}
							}
							else {}
						}
					}
				}
			}
		}
	}
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
						.wire { app.build_selected_type = .not }
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

fn (mut app App) get_chunk_id_at_coords(x int, y int) int {
	chunk_y := int(math.floor(f64(y) / 16.0))
	chunk_x := int(math.floor(f64(x) / 16.0))
	for i, chunk in app.chunks {
		if chunk.x == chunk_x && chunk.y == chunk_y {
			return i
		}
	}
	app.chunks << Chunk{chunk_x, chunk_y, [][]i64{len: 16, init: []i64{len: 16, init: -1}}}
	return app.chunks.len - 1
}

fn (mut app App) get_tile_id_at(x int, y int) i64 {
	chunk := app.chunks[app.get_chunk_id_at_coords(x, y)]
	return chunk.tiles[math.abs(y - chunk.y * 16)][math.abs(x - chunk.x * 16)]
}

fn (app App) mouse_to_coords(x f32, y f32) (int, int) {
	return int(x) / ceil(tile_size * app.scale), int(y) / ceil(tile_size * app.scale)
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
