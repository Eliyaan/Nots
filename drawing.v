module main

const off_not_image = load_image('off_not_gate.png')
const on_not_image = load_image('on_not_gate.png')
const off_diode_image = load_image('off_diode.png')
const on_diode_image = load_image('on_diode.png')
const off_wire_image = load_image('wire_off.png')
const on_wire_image = load_image('wire_on.png')
const off_junction = load_image("off_junction.png")


@[direct_array_access]
fn (mut app App) draw_elements() {
	scaled_tile_size := ceil(tile_size * app.scale)

	off_scaled_image_not := scale_img(off_not_image, app.scale, tile_size, tile_size)
	off_not_image_scaled_north := rotate_img(off_scaled_image_not, .north, scaled_tile_size)
	off_not_image_scaled_south := rotate_img(off_scaled_image_not, .south, scaled_tile_size)
	off_not_image_scaled_east := rotate_img(off_scaled_image_not, .east, scaled_tile_size)
	off_not_image_scaled_west := rotate_img(off_scaled_image_not, .west, scaled_tile_size)

	on_scaled_image_not := scale_img(on_not_image, app.scale, tile_size, tile_size)
	on_not_image_scaled_north := rotate_img(on_scaled_image_not, .north, scaled_tile_size)
	on_not_image_scaled_south := rotate_img(on_scaled_image_not, .south, scaled_tile_size)
	on_not_image_scaled_east := rotate_img(on_scaled_image_not, .east, scaled_tile_size)
	on_not_image_scaled_west := rotate_img(on_scaled_image_not, .west, scaled_tile_size)

	off_wire_scaled := scale_img(off_wire_image, app.scale, tile_size, tile_size)
	on_wire_scaled := scale_img(on_wire_image, app.scale, tile_size, tile_size)

	off_scaled_image_diode := scale_img(off_diode_image, app.scale, tile_size, tile_size)
	off_diode_image_scaled_north := rotate_img(off_scaled_image_diode, .north, scaled_tile_size)
	off_diode_image_scaled_south := rotate_img(off_scaled_image_diode, .south, scaled_tile_size)
	off_diode_image_scaled_east := rotate_img(off_scaled_image_diode, .east, scaled_tile_size)
	off_diode_image_scaled_west := rotate_img(off_scaled_image_diode, .west, scaled_tile_size)

	on_scaled_image_diode := scale_img(on_diode_image, app.scale, tile_size, tile_size)
	on_diode_image_scaled_north := rotate_img(on_scaled_image_diode, .north, scaled_tile_size)
	on_diode_image_scaled_south := rotate_img(on_scaled_image_diode, .south, scaled_tile_size)
	on_diode_image_scaled_east := rotate_img(on_scaled_image_diode, .east, scaled_tile_size)
	on_diode_image_scaled_west := rotate_img(on_scaled_image_diode, .west, scaled_tile_size)

	off_junction_scaled := scale_img(off_junction, app.scale, tile_size, tile_size)

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
											.north { &off_not_image_scaled_north }
											.south { &off_not_image_scaled_south }
											.east { &off_not_image_scaled_east }
											.west { &off_not_image_scaled_west }
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
								good_image := if app.wire_groups[element.id_glob_wire].on() {
									&on_wire_scaled
								} else {
									&off_wire_scaled
								}
								for y in 0 .. scaled_tile_size {
									for x in 0 .. scaled_tile_size {
										app.screen_pixels[array_pos + y * app.screen_x + x] = unsafe {good_image[y * scaled_tile_size + x].u32()}
									}
								}
							}
							Junction {
								for y in 0 .. scaled_tile_size {
									for x in 0 .. scaled_tile_size {
										app.screen_pixels[array_pos + y * app.screen_x + x] = unsafe {off_junction_scaled[y * scaled_tile_size + x].u32()}
									}
								}
							}
							Diode {
								good_image := match element.state {
									false {
										match element.orientation {
											.north { &off_diode_image_scaled_north }
											.south { &off_diode_image_scaled_south }
											.east { &off_diode_image_scaled_east }
											.west { &off_diode_image_scaled_west }
										}
									}
									true {
										match element.orientation {
											.north { &on_diode_image_scaled_north }
											.south { &on_diode_image_scaled_south }
											.east { &on_diode_image_scaled_east }
											.west { &on_diode_image_scaled_west }
										}
									}
								}
								for y in 0 .. scaled_tile_size {
									for x in 0 .. scaled_tile_size {
										app.screen_pixels[array_pos + y * app.screen_x + x] = unsafe {good_image[y * scaled_tile_size + x].u32()}
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
										app.screen_pixels[array_pos + y * app.screen_x + x] = u32(0)
									}
								}
							}
							Wire {
								for y in 0 .. scaled_tile_size {
									for x in 0 .. scaled_tile_size {
										app.screen_pixels[array_pos + y * app.screen_x + x] = u32(0)
									}
								}
							}
							Junction {
								for y in 0 .. scaled_tile_size {
									for x in 0 .. scaled_tile_size {
										app.screen_pixels[array_pos + y * app.screen_x + x] = u32(0)
									}
								}
							}
							Diode {
								for y in 0 .. scaled_tile_size {
									for x in 0 .. scaled_tile_size {
										app.screen_pixels[array_pos + y * app.screen_x + x] = u32(0)
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