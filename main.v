module main

import gg
import gx
import ggui
import math

const tile_size = 10
const theme = ggui.CatppuchinMocha{}
const buttons_shape = ggui.RoundedShape{20, 20, 5, .top_left}
const not_image = [
	Color{0, 0, 0, 255},
	Color{0, 0, 0, 255},
	Color{0, 0, 0, 255},
	Color{0, 0, 0, 255},
	Color{0, 0, 0, 255},
	Color{0, 0, 0, 255},
	Color{0, 0, 0, 255},
	Color{0, 0, 0, 255},
	Color{0, 0, 0, 255},
	Color{0, 0, 0, 255},
	Color{0, 0, 0, 255},
	Color{0, 0, 0, 255},
	Color{0, 0, 0, 255},
	Color{0, 0, 0, 255},
	Color{0, 0, 0, 255},
	Color{0, 0, 0, 255},
	Color{0, 0, 0, 255},
	Color{0, 0, 0, 255},
	Color{0, 0, 0, 255},
	Color{0, 0, 0, 255},
	Color{0, 0, 0, 255},
	Color{0, 0, 0, 255},
	Color{0, 0, 0, 255},
	Color{0, 0, 0, 255},
	Color{0, 0, 0, 255},
	Color{0, 0, 0, 255},
	Color{0, 0, 0, 255},
	Color{0, 0, 0, 255},
	Color{0, 0, 0, 255},
	Color{0, 0, 0, 255},
	Color{0, 0, 0, 255},
	Color{0, 0, 0, 255},
	Color{0, 0, 0, 255},
	Color{0, 0, 0, 255},
	Color{0, 0, 0, 255},
	Color{0, 0, 0, 255},
	Color{0, 0, 0, 255},
	Color{0, 0, 0, 255},
	Color{0, 0, 0, 255},
	Color{0, 0, 0, 255},
	Color{0, 0, 0, 255},
	Color{0, 0, 0, 255},
	Color{0, 0, 0, 255},
	Color{0, 0, 0, 255},
	Color{0, 0, 0, 255},
	Color{0, 0, 0, 255},
	Color{0, 0, 0, 255},
	Color{0, 0, 0, 255},
	Color{0, 0, 0, 255},
	Color{0, 0, 0, 255},
	Color{0, 0, 0, 255},
	Color{0, 0, 0, 255},
	Color{0, 0, 0, 255},
	Color{0, 0, 0, 255},
	Color{0, 0, 0, 255},
	Color{0, 0, 0, 255},
	Color{0, 0, 0, 255},
	Color{0, 0, 0, 255},
	Color{0, 0, 0, 255},
	Color{0, 0, 0, 255},
	Color{0, 0, 0, 255},
	Color{0, 0, 0, 255},
	Color{255, 0, 0, 255},
	Color{255, 0, 0, 255},
	Color{255, 0, 0, 255},
	Color{255, 0, 0, 255},
	Color{255, 0, 0, 255},
	Color{255, 0, 0, 255},
	Color{0, 0, 0, 255},
	Color{0, 0, 0, 255},
	Color{0, 0, 0, 255},
	Color{255, 0, 0, 255},
	Color{255, 0, 0, 255},
	Color{255, 0, 0, 255},
	Color{255, 0, 0, 255},
	Color{255, 0, 0, 255},
	Color{255, 0, 0, 255},
	Color{255, 0, 0, 255},
	Color{255, 0, 0, 255},
	Color{0, 0, 0, 255},
	Color{0, 0, 0, 255},
	Color{255, 0, 0, 255},
	Color{255, 0, 0, 255},
	Color{255, 0, 0, 255},
	Color{255, 0, 0, 255},
	Color{255, 0, 0, 255},
	Color{255, 0, 0, 255},
	Color{255, 0, 0, 255},
	Color{255, 0, 0, 255},
	Color{0, 0, 0, 255},
	Color{255, 0, 0, 255},
	Color{255, 0, 0, 255},
	Color{255, 0, 0, 255},
	Color{255, 0, 0, 255},
	Color{255, 0, 0, 255},
	Color{255, 0, 0, 255},
	Color{255, 0, 0, 255},
	Color{255, 0, 0, 255},
	Color{255, 0, 0, 255},
	Color{255, 0, 0, 255},
]

@[inline]
fn a_coords(y int, x int, size int) int {
	return y * size + x
}

@[inline]
fn ceil(nb f64) int {
	return -int(-nb)
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

struct App {
mut:
	gg           &gg.Context = unsafe { nil }
	elements     []Element
	destroyed    []i64
	chunks       []Chunk
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
	screen_pixels [768][1366]u32 = [768][1366]u32{init: [1366]u32{init: u32(0xFFBBBBBB)}}
	viewport_x    int
	viewport_y    int

	scale f64 = 2
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

	// calculate the rotations of the image

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
	app.place_in(4, 13)!
	app.place_in(5, 14)!
	app.place_in(3, 13)!
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

	/*
	app.place_in(1, 2)!
	app.place_in(2, 2)!
	app.place_in(2, 3)!
	app.place_in(1, 4)!
	app.place_in(1, 5)!
	app.place_in(1, 7)!
	app.place_in(2, 7)!
	app.place_in(2, 6)!
	app.place_in(2, 5)!
	app.place_in(2, 4)!
	app.build_selected_type = .not
	app.build_orientation = .north
	app.place_in(1, 6)!
	app.place_in(1, 3)!
	app.update()
	app.delete_in(1, 5)!
	app.delete_in(2, 5)!
	*/

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
	app.screen_pixels = [768][1366]u32{init: [1366]u32{init: u32(0xFFBBBBBB)}}
	not_image_scaled := scale_img(not_image, app.scale, tile_size, tile_size)
	for chunk in app.chunks {
		for line in chunk.tiles {
			for id_element in line {
				if id_element >= 0 {
					mut element := &app.elements[id_element]
					place_x := element.x * ceil(tile_size * app.scale) +
						ceil(tile_size * app.scale) - 1 + app.viewport_x
					place_y := element.y * ceil(tile_size * app.scale) +
						ceil(tile_size * app.scale) - 1 + app.viewport_y
					if place_x >= ceil(tile_size * app.scale) - 1 && place_x < 1366
						&& place_y >= ceil(tile_size * app.scale) - 1 && place_y < 768 {
						match mut element {
							Not {
								rotation := match element.orientation {
									.north { -90 }
									.south { 90 }
									.east { 0 }
									.west { 180 }
								}
								for y in 0 .. ceil(tile_size * app.scale) {
									for x in 0 .. ceil(tile_size * app.scale) {
										app.screen_pixels[element.y * ceil(tile_size * app.scale) +
											y + app.viewport_y][
											element.x * ceil(tile_size * app.scale) + x +
											app.viewport_x] = not_image_scaled[
											y * ceil(tile_size * app.scale) + x].u32()
									}
								}
							}
							Wire {
								color := if app.wire_groups[element.id_glob_wire].on() {
									u32(0xFF12_D0_EF)
								} else {
									u32(0xFF00_0000)
								}
								for y in 0 .. ceil(tile_size * app.scale) {
									for x in 0 .. ceil(tile_size * app.scale) {
										app.screen_pixels[element.y * ceil(tile_size * app.scale) +
											y + app.viewport_y][
											element.x * ceil(tile_size * app.scale) + x +
											app.viewport_x] = color
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
	app.draw_image()
	match app.build_selected_type {
		.not {
			color := gg.Color{50, 100, 100, 100}
			app.gg.draw_square_filled(f32(app.mouse_x * ceil(tile_size * app.scale) +
				app.viewport_x % ceil(tile_size * app.scale)), f32(
				app.mouse_y * ceil(tile_size * app.scale) +
				app.viewport_y % ceil(tile_size * app.scale)), ceil(tile_size * app.scale),
				gg.Color{100, 100, 100, 100})
			rotation := match app.build_orientation {
				.north { -90 }
				.south { 90 }
				.east { 0 }
				.west { 180 }
			}
			app.gg.draw_polygon_filled(f32(app.mouse_x * ceil(tile_size * app.scale) +
				app.viewport_x % ceil(tile_size * app.scale)) +
				f32(ceil(tile_size * app.scale)) / 2.0,
				f32(app.mouse_y * ceil(tile_size * app.scale) +
				app.viewport_y % ceil(tile_size * app.scale)) +
				f32(ceil(tile_size * app.scale)) / 2.0, f32(ceil(tile_size * app.scale)) / 2.0,
				3, rotation, color)
		}
		.wire {
			color := gg.Color{100, 100, 100, 100}
			app.gg.draw_square_filled(f32(app.mouse_x * ceil(tile_size * app.scale) +
				app.viewport_x % ceil(tile_size * app.scale)), f32(
				app.mouse_y * ceil(tile_size * app.scale) +
				app.viewport_y % ceil(tile_size * app.scale)), ceil(tile_size * app.scale),
				color)
		}
		else {}
	}
	app.gui.render()
	app.gg.show_fps()
	app.gg.end()
}

fn on_event(e &gg.Event, mut app App) {
	app.mouse_x, app.mouse_y = app.mouse_to_coords(e.mouse_x - app.viewport_x % ceil(tile_size * app.scale),
		e.mouse_y - app.viewport_y % ceil(tile_size * app.scale))
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
					if app.scale > 0.11 {
						app.scale -= 0.1
					}
				}
				.p {
					app.scale += 0.1
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
				match e.mouse_button {
					.left {
						app.place_in(app.mouse_x - (app.viewport_x) / ceil(tile_size * app.scale),
							app.mouse_y - (app.viewport_y) / ceil(tile_size * app.scale)) or {}
					}
					.right {
						app.delete_in(app.mouse_x - (app.viewport_x) / ceil(tile_size * app.scale),
							app.mouse_y - (app.viewport_y) / ceil(tile_size * app.scale)) or {}
					}
					else {}
				}
			} else {
				app.gui.check_clicks(e.mouse_x, e.mouse_y)
			}
		}
		else {}
	}
}

fn (mut app App) get_chunk_at_coords(x int, y int) &Chunk {
	chunk_y := int(math.floor(f64(y) / 16.0))
	chunk_x := int(math.floor(f64(x) / 16.0))
	for chunk in app.chunks {
		if chunk.x == chunk_x && chunk.y == chunk_y {
			return &chunk
		}
	}
	app.chunks << Chunk{chunk_x, chunk_y, [][]i64{len: 16, init: []i64{len: 16, init: -1}}}
	return &app.chunks[app.chunks.len - 1]
}

fn (mut app App) get_tile_id_at(x int, y int) i64 {
	chunk := app.get_chunk_at_coords(x, y)
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
	istream_image.update_pixel_data(unsafe { &u8(&app.screen_pixels) })
	size := gg.window_size_real_pixels()
	app.gg.draw_image(0, 0, size.width, size.height, istream_image)
}

fn graphics_init(mut app App) {
	app.istream_idx = app.gg.new_streaming_image(1366, 768, 4, pixel_format: .rgba8)
}
