import rand

fn (mut app App) test() {
	size := 5
	for y in 0..size {
		for x in 0..size {
			app.delete_in(x, y) or {}
		}
	}
	println("NOUVEAU TEST : prendre tout ce qu'il y a en dessous")
	for _ in 0..100 {
		r := rand.int_in_range(0, 11) or {0}
		if r < 3 {
			x := rand.int_in_range(0, size) or {0}
			y := rand.int_in_range(0, size) or {5}
			if app.get_tile_id_at(x, y) == -1 {
				if app.build_selected_type != .wire {
					app.build_selected_type = .wire
					println('app.build_selected_type = .${app.build_selected_type}')
				}
				app.place_in(x, y) or {}
			}
		} else if r < 5 {
			x := rand.int_in_range(0, size) or {0}
			y := rand.int_in_range(0, size) or {5}
			if app.get_tile_id_at(x, y) == -1 {
				if app.build_selected_type != .junction {
					app.build_selected_type = .junction
					println('app.build_selected_type = .${app.build_selected_type}')
				}
				app.place_in(x, y) or {}
			}
		} else if r < 7 {
			x := rand.int_in_range(0, size) or {0}
			y := rand.int_in_range(0, size) or {5}
			if app.get_tile_id_at(x, y) == -1 {
				if app.build_selected_type != .not {
					app.build_selected_type = .not
					println('app.build_selected_type = .${app.build_selected_type}')
				}
				old_ori := app.build_orientation
				match rand.int_in_range(0, 4) or {0} {
					0 {app.build_orientation=.north}
					1 {app.build_orientation=.south}
					2 {app.build_orientation=.east}
					3 {app.build_orientation=.west}
					else {}
				}
				if old_ori != app.build_orientation {
					println('app.build_orientation = .${app.build_orientation}')
				}
				app.place_in(x, y) or {}
			}
		} else if r < 8 {
			x := rand.int_in_range(0, size) or {0}
			y := rand.int_in_range(0, size) or {5}
			if app.get_tile_id_at(x, y) != -1 {
				app.delete_in(x, y) or {}
			}
		} else if r < 9 && (app.queue.len != 0 || app.queue_gwires.len != 0){
			app.update()
			println("app.update()")
		}
	}
	app.check(size)
}

fn (mut app App) check(size int) {
	mut too_much_updates := 0
	for app.queue.len + app.queue_gwires.len != 0 && too_much_updates < 10 {
		app.update()
		too_much_updates++
	}
	if too_much_updates >= 10 {
		println("Too much updates; maybe a clock so will no do the tests")
	} else {
		for y in 0..size {
			for x in 0..size {
				id := app.get_tile_id_at(x, y)
				if id != -1 {
					mut elem := app.elements[id]
					match mut elem {
						Not {
							input_x, input_y := input_coords_from_orientation(elem.orientation)
							input_id := app.get_tile_id_at(x + input_x, y + input_y)
							if input_id != -1 {
								mut input_elem := app.elements[input_id]
								match mut input_elem {
									Not {
										if elem.orientation == input_elem.orientation {
											if elem.state == input_elem.state {
												panic("BUG: Not gate ${x} ${y} id:${id} not matching its input Not gate state id:${input_id}")
											}
										}
									}
									Wire {
										if app.wire_groups[input_elem.id_glob_wire].on() == elem.state {
											panic("BUG: Not gate ${x} ${y} id:${id} not matching its input Wire gate state id:${input_id}")
										}
										if id !in app.wire_groups[input_elem.id_glob_wire].outputs {
											panic("BUG: Not is not in the outputs of its input wire")
										}
									}
									Junction {
										mut i := 1
										mut other_side_id := app.get_tile_id_at(x + input_x*i, y + input_y*i)
										for other_side_id != -1 && app.elements[other_side_id] is Junction {
											other_side_id = app.get_tile_id_at(x + input_x*i, y + input_y*i)
											i++
										}
										if other_side_id >= 0 {
											mut other_side_elem := app.elements[other_side_id]
											match mut other_side_elem { 
												Wire {
													if app.wire_groups[other_side_elem.id_glob_wire].on() == elem.state {
														panic("BUG: Not gate ${x} ${y} id:${id} not matching its input Wire gate state id:${other_side_id}")
													}
													if id !in app.wire_groups[other_side_elem.id_glob_wire].outputs {
														panic("BUG: Not is not in the outputs of its input wire (through junction)")
													}
												}
												Not {
													if elem.orientation == other_side_elem.orientation {
														if elem.state == other_side_elem.state {
															panic("BUG: Not gate ${x} ${y} id:${id} state:${elem.state} not matching its input Not gate state id:${other_side_id} state:${other_side_elem.state} queue:${app.queue}")
														}
													}
												}
												else {}
											}
										} else {
											if !elem.state {
												panic("BUG: Not ${x} ${y} id:${id} is OFF with no input")
											}
										}
									}
									else {panic("TODO: elem type not handled")}
								}
							} else {
								if !elem.state {
									panic("BUG: Not ${x} ${y} id:${id} is OFF with no input")
								}
							}
						}
						Junction {
							// junctions do not have state
						}
						Wire {
							mut nb_inputs := 0
							for input_id in app.wire_groups[elem.id_glob_wire].inputs {
								mut input_elem := app.elements[input_id]
								if mut input_elem is Not {
									if input_elem.state {
										output_x, output_y := output_coords_from_orientation(input_elem.orientation)
										output_id := app.get_tile_id_at(int(input_elem.x + output_x), int(input_elem.y + output_y))
										if output_id != -1 {
											mut output_elem := app.elements[output_id]
											match mut output_elem {
												Wire {
													if output_elem.id_glob_wire == elem.id_glob_wire {
														nb_inputs += 1
													} else {
														panic("BUG: Not in the inputs of the wire but its output is another wire gid:${output_elem.id_glob_wire}")
													}
												}
												Junction {
													mut i := 1
													mut other_side_id := app.get_tile_id_at(int(input_elem.x + output_x*i), int(input_elem.y + output_y*i))
													for other_side_id != -1 && app.elements[other_side_id] is Junction {
														other_side_id = app.get_tile_id_at(int(input_elem.x + output_x*i), int(input_elem.y + output_y*i))
														i++
													}
													if other_side_id >= 0 {
														mut other_side_elem := app.elements[other_side_id]
														match mut other_side_elem { 
															Wire {
																if other_side_elem.id_glob_wire == elem.id_glob_wire {
																	nb_inputs += 1
																} else {
																	panic("BUG: Not in the inputs of the wire but its output is another wire gid:${other_side_elem.id_glob_wire}")
																}
															}
															else {panic("BUG: output of a Not ${input_elem.x} ${input_elem.y} id:${input_id} (that is in a wire's input) is connected to no wire id:${other_side_id}")}
														}
													} else {
														panic("BUG: Not ${input_elem.x} ${input_elem.y} id:${input_id} is in the inputs:${app.wire_groups[elem.id_glob_wire].inputs} of a wire but NOT has no output id:${other_side_id}")
													}
												}
												else {panic("BUG: output of a Not ${input_elem.x} ${input_elem.y} id:${input_id} (that is in a wire's input) is connected to no wire and no junction id:${output_id}")}
											}
										} else {
											panic("BUG: output of a Not ${input_elem.x} ${input_elem.y} id:${input_id} (that is in a wire's input) is connected to nothing id:${output_id}")
										}
									} else {
										panic("BUG: Not ${input_elem.x} ${input_elem.y} id:${input_id} state:${input_elem.state} OFF in the inputs of a wire id:${elem.id_glob_wire} inputs:${app.wire_groups[elem.id_glob_wire].inputs}")
									}
								} else {
									panic("BUG: not a Not in a wire's output")
								}
							}
							if nb_inputs != app.wire_groups[elem.id_glob_wire].inputs.len {
								panic("BUG: Should have already thrown out a panic")
							}
						}
						else {panic("TODO: elem type not handled")}
					}
				}
			}
		}
	}
}