module main

const off_not_image = load_image('off_not_gate.png')
const on_not_image = load_image('on_not_gate.png')
const off_diode_image = load_image('off_diode.png')
const on_diode_image = load_image('on_diode.png')
const off_wire_image = load_image('wire_off.png')
const on_wire_image = load_image('wire_on.png')
const off_junction = load_image("off_junction.png")
const on_off_junction = load_image("on_off_junction.png")
const off_on_junction = load_image("off_on_junction.png")
const on_junction = load_image("on_junction.png")


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
	on_off_junction_scaled := scale_img(on_off_junction, app.scale, tile_size, tile_size)
	off_on_junction_scaled := scale_img(off_on_junction, app.scale, tile_size, tile_size)
	on_junction_scaled := scale_img(on_junction, app.scale, tile_size, tile_size)

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
											.north { off_not_image_scaled_north }
											.south { off_not_image_scaled_south }
											.east { off_not_image_scaled_east }
											.west { off_not_image_scaled_west }
										}
									}
									true {
										match element.orientation {
											.north { on_not_image_scaled_north }
											.south { on_not_image_scaled_south }
											.east { on_not_image_scaled_east }
											.west { on_not_image_scaled_west }
										}
									}
								}
								for y in 0 .. scaled_tile_size {
									for x in 0 .. scaled_tile_size {
										app.screen_pixels[array_pos + y * app.screen_x + x] = good_image[y * scaled_tile_size + x].u32()
									}
								}
							}
							Wire {
								good_image := if app.wire_groups[element.id_glob_wire].on() {
									on_wire_scaled
								} else {
									off_wire_scaled
								}
								for y in 0 .. scaled_tile_size {
									for x in 0 .. scaled_tile_size {
										app.screen_pixels[array_pos + y * app.screen_x + x] = good_image[y * scaled_tile_size + x].u32()
									}
								}
							}
							Junction {
								top_id := app.get_tile_id_at(int(element.x), int(element.y - 1))
								right_id := app.get_tile_id_at(int(element.x + 1), int(element.y))
								bot_id := app.get_tile_id_at(int(element.x), int(element.y + 1))
								left_id := app.get_tile_id_at(int(element.x - 1), int(element.y))
								mut top_on := false
								if top_id != -1 {
									mut top_elem := app.elements[top_id]
									match mut top_elem {
										Wire {
											top_on = app.wire_groups[top_elem.id_glob_wire].on()
										}
										Not {
											input_coord_x, input_coord_y := input_coords_from_orientation(top_elem.orientation)
											if input_coord_x == 0 && input_coord_y == -1 {
												top_on = top_elem.state
											}
										}
										Diode {
											input_coord_x, input_coord_y := input_coords_from_orientation(top_elem.orientation)
											if input_coord_x == 0 && input_coord_y == -1 {
												top_on = top_elem.state
											}
										}
										Junction {
											mut i := 1
											mut other_side_id := app.get_tile_id_at(int(element.x), int(element.y - 1*i))
											for other_side_id != -1 && app.elements[other_side_id] is Junction {
												other_side_id = app.get_tile_id_at(int(element.x), int(element.y - 1*i))
												if other_side_id != -1 {
													mut other_side_elem := app.elements[other_side_id]
													match mut other_side_elem {
														Wire {top_on = app.wire_groups[other_side_elem.id_glob_wire].on()}
														Not {
															input_coord_x, input_coord_y := input_coords_from_orientation(other_side_elem.orientation)
															if input_coord_x == 0 && input_coord_y == -1 {
																top_on = other_side_elem.state
															}
														}
														Diode {
															input_coord_x, input_coord_y := input_coords_from_orientation(other_side_elem.orientation)
															if input_coord_x == 0 && input_coord_y == -1 {
																top_on = other_side_elem.state
															}
														}
														else {}
													}
												}
												i++
											}
										}
										else {panic("Elem type not supported")}
									} 
								}
								if bot_id != -1 {
									mut bot_elem := app.elements[bot_id]
									match mut bot_elem {
										Wire {
											top_on = app.wire_groups[bot_elem.id_glob_wire].on()
										}
										Not {
											input_coord_x, input_coord_y := input_coords_from_orientation(bot_elem.orientation)
											if input_coord_x == 0 && input_coord_y == 1 {
												top_on = bot_elem.state
											}
										}
										Diode {
											input_coord_x, input_coord_y := input_coords_from_orientation(bot_elem.orientation)
											if input_coord_x == 0 && input_coord_y == 1 {
												top_on = bot_elem.state
											}
										}
										Junction {
											mut i := 1
											mut other_side_id := app.get_tile_id_at(int(element.x), int(element.y + 1*i))
											for other_side_id != -1 && app.elements[other_side_id] is Junction {
												other_side_id = app.get_tile_id_at(int(element.x), int(element.y + 1*i))
												if other_side_id != -1 {
													mut other_side_elem := app.elements[other_side_id]
													match mut other_side_elem {
														Wire {top_on = app.wire_groups[other_side_elem.id_glob_wire].on()}
														Not {
															input_coord_x, input_coord_y := input_coords_from_orientation(other_side_elem.orientation)
															if input_coord_x == 0 && input_coord_y == 1 {
																top_on = other_side_elem.state
															}
														}
														Diode {
															input_coord_x, input_coord_y := input_coords_from_orientation(other_side_elem.orientation)
															if input_coord_x == 0 && input_coord_y == 1 {
																top_on = other_side_elem.state
															}
														}
														else {}
													}
												}
												i++
											}
										}
										else {panic("Elem type not supported")}
									}
								}
								mut right_on := false
								if right_id != -1 {
									mut right_elem := app.elements[right_id]
									match mut right_elem {
										Wire {
											right_on = app.wire_groups[right_elem.id_glob_wire].on()
										}
										Not {
											input_coord_x, input_coord_y := input_coords_from_orientation(right_elem.orientation)
											if input_coord_x == 1 && input_coord_y == 0 {
												right_on = right_elem.state
											}
										}
										Diode {
											input_coord_x, input_coord_y := input_coords_from_orientation(right_elem.orientation)
											if input_coord_x == 1 && input_coord_y == 0 {
												right_on = right_elem.state
											}
										}
										Junction {
											mut i := 1
											mut other_side_id := app.get_tile_id_at(int(element.x + 1*i), int(element.y))
											for other_side_id != -1 && app.elements[other_side_id] is Junction {
												other_side_id = app.get_tile_id_at(int(element.x + 1*i), int(element.y))
												if other_side_id != -1 {
													mut other_side_elem := app.elements[other_side_id]
													match mut other_side_elem {
														Wire {right_on = app.wire_groups[other_side_elem.id_glob_wire].on()}
														Not {
															input_coord_x, input_coord_y := input_coords_from_orientation(other_side_elem.orientation)
															if input_coord_x == 1 && input_coord_y == 0 {
																right_on = other_side_elem.state
															}
														}
														Diode {
															input_coord_x, input_coord_y := input_coords_from_orientation(other_side_elem.orientation)
															if input_coord_x == 1 && input_coord_y == 0 {
																right_on = other_side_elem.state
															}
														}
														else {}
													}
												}
												i++
											}
										}
										else {panic("Elem type not supported")}
									}
								}
								if left_id != -1 {
									mut left_elem := app.elements[left_id]
									match mut left_elem {
										Wire {
											right_on = app.wire_groups[left_elem.id_glob_wire].on()
										}
										Not {
											input_coord_x, input_coord_y := input_coords_from_orientation(left_elem.orientation)
											if input_coord_x == -1 && input_coord_y == 0 {
												right_on = left_elem.state
											}
										}
										Diode {
											input_coord_x, input_coord_y := input_coords_from_orientation(left_elem.orientation)
											if input_coord_x == -1 && input_coord_y == 0 {
												right_on = left_elem.state
											}
										}
										Junction {
											mut i := 1
											mut other_side_id := app.get_tile_id_at(int(element.x - 1*i), int(element.y))
											for other_side_id != -1 && app.elements[other_side_id] is Junction {
												other_side_id = app.get_tile_id_at(int(element.x - 1*i), int(element.y))
												if other_side_id != -1 {
													mut other_side_elem := app.elements[other_side_id]
													match mut other_side_elem {
														Wire {right_on = app.wire_groups[other_side_elem.id_glob_wire].on()}
														Not {
															input_coord_x, input_coord_y := input_coords_from_orientation(other_side_elem.orientation)
															if input_coord_x == -1 && input_coord_y == 0 {
																right_on = other_side_elem.state
															}
														}
														Diode {
															input_coord_x, input_coord_y := input_coords_from_orientation(other_side_elem.orientation)
															if input_coord_x == -1 && input_coord_y == 0 {
																right_on = other_side_elem.state
															}
														}
														else {}
													}
												}
												i++
											}
										}
										else {panic("Elem type not supported")}
									}
								}
								good_image := if right_on {
									if top_on {
										on_junction_scaled
									} else {
										on_off_junction_scaled
									}
								} else {
									if top_on {
										off_on_junction_scaled
									} else {
										off_junction_scaled
									}
								}
								for y in 0 .. scaled_tile_size {
									for x in 0 .. scaled_tile_size {
										app.screen_pixels[array_pos + y * app.screen_x + x] = good_image[y * scaled_tile_size + x].u32()
									}
								}
							}
							Diode {
								good_image := match element.state {
									false {
										match element.orientation {
											.north { off_diode_image_scaled_north }
											.south { off_diode_image_scaled_south }
											.east { off_diode_image_scaled_east }
											.west { off_diode_image_scaled_west }
										}
									}
									true {
										match element.orientation {
											.north { on_diode_image_scaled_north }
											.south { on_diode_image_scaled_south }
											.east { on_diode_image_scaled_east }
											.west { on_diode_image_scaled_west }
										}
									}
								}
								for y in 0 .. scaled_tile_size {
									for x in 0 .. scaled_tile_size {
										app.screen_pixels[array_pos + y * app.screen_x + x] = good_image[y * scaled_tile_size + x].u32()
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