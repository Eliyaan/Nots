import gg
import math

fn (mut app App) preview(){
	if app.is_placing{
		app.preview_line(app.mouse_down_preview_x, app.mouse_down_preview_y, app.mouse_x, app.mouse_y) or {}
	}
	else{
		app.tile_preview(app.mouse_x, app.mouse_y)
	}
}

fn (mut app App) preview_line(start_x int, start_y int, end_x int, end_y int) ! {
	mut x := end_x - start_x
	mut y := end_y - start_y
	mut direction_x := 0
	mut direction_y := 0
	if x < 0 {
		x = math.abs(x)
		direction_x = -1
	} else if x > 0 {
		direction_x = 1
	}
	if y < 0 {
		y = math.abs(y)
		direction_y = -1
	} else if y > 0 {
		direction_y = 1
	}
	
	if !app.place_is_turn {
		if x > y {
			for i in 0 .. x + 1 {
				if direction_x == 1 {
					app.build_orientation = .east
				} else if direction_x == -1 {
					app.build_orientation = .west
				}
				app.tile_preview(start_x + i * direction_x, start_y)
			}
		} else {
			for i in 0 .. y + 1 {
				if direction_y == 1 {
					app.build_orientation = .south
				} else if direction_y == -1 {
					app.build_orientation = .north
				}
				app.tile_preview(start_x, start_y + i * direction_y)
			}
		}
	}else if x > y{
		for i in 0 .. x {
			if direction_x == 1 {
				app.build_orientation = .east
			} else if direction_x == -1 {
				app.build_orientation = .west
			}
			app.tile_preview(start_x + i * direction_x, start_y)
		}
		if y > 0 {
			tempo := app.build_selected_type
			app.build_selected_type = .wire
			app.tile_preview(end_x, start_y)
			app.build_selected_type = tempo

			for i in 1 .. y + 1 {
				if direction_y == 1 {
					app.build_orientation = .south
				} else if direction_y == -1 {
					app.build_orientation = .north
				}
				app.tile_preview(end_x, start_y + i * direction_y)
			}
		}else{app.tile_preview(end_x, end_y)}
		
	}else{
		for i in 0 .. y {
			if direction_y == 1 {
				app.build_orientation = .south
			} else if direction_y == -1 {
				app.build_orientation = .north
			}
			app.tile_preview(start_x , start_y + i * direction_y)
		}

		tempo := app.build_selected_type
		app.build_selected_type = .wire
		app.tile_preview(start_x, end_y)
		app.build_selected_type = tempo

		for i in 1 .. x + 1 {
			if direction_x == 1 {
				app.build_orientation = .east
			} else if direction_x == -1 {
				app.build_orientation = .west
			}
			app.tile_preview(start_x + i * direction_x, end_y)
		}
	}
}

fn (app App) tile_preview(x int, y int){
	half_scaled_tile_size := f32(ceil(tile_size * app.scale)) * 0.5
	preview_x := f32(x * ceil(tile_size * app.scale) + (app.viewport_x + app.screen_x/2) % ceil(tile_size * app.scale))
	preview_y := f32(y * ceil(tile_size * app.scale) + (app.viewport_y + app.screen_y/2) % ceil(tile_size * app.scale))
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
			color := gg.Color{100, 100, 100, 100}
			app.gg.draw_square_filled(preview_x, preview_y, ceil(tile_size * app.scale), color)
		}
		.diode {
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
	}
}