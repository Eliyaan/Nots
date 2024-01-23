module main

import math

fn (mut app App) place_in(x int, y int) ! {
	match app.build_selected_type {
		.@none {}
		.not {
			app.not_place_in(x, y)!
		}
		.wire {
			app.wire_place_in(x, y)!
		}
		.junction {
			app.junction_place_in(x, y)!
		}
	}
}

fn (mut app App) junction_place_in(x int, y int) ! {
	panic("not implemented")
}

fn (mut app App) not_place_in(x int, y int) ! {
	mut id := i64(0)
	if app.destroyed.len == 0 {
		id = app.elements.len
	} else { // replace the element
		id = app.destroyed[0]
		app.destroyed.delete(0)
	}
	place_chunk_id := app.get_chunk_id_at_coords(x, y)
	place_chunk := app.chunks[place_chunk_id]
	if place_chunk.tiles[math.abs(y - place_chunk.y * 16)][math.abs(x - place_chunk.x * 16)] < 0 {
		app.chunks[place_chunk_id].tiles[math.abs(y - place_chunk.y * 16)][math.abs(x - place_chunk.x * 16)] = id
	} else {
		return error('Not in an empty space')
	}
	if app.debug_mode {
		println('app.place_in(${x}, ${y})!')
	}

	output_x, output_y := output_coords_from_orientation(app.build_orientation)
	mut output := app.get_tile_id_at(x + output_x, y + output_y)

	if output != -1 {
		if app.elements[output].destroyed {
			output = -1
		} else {
			output_elem := app.elements[output]
			match output_elem {
				Not {
					if output_elem.orientation != app.build_orientation {
						output = -1
					}
				}
				else {}
			}
		}
	}

	input_x, input_y := input_coords_from_orientation(app.build_orientation)
	input := app.get_tile_id_at(x + input_x, y + input_y)

	mut state := true // because a not gate without input is a not gate with off input
	if input >= 0 {
		mut elem_input := app.elements[input]
		match mut elem_input {
			Not {
				if elem_input.orientation == app.build_orientation {
					elem_input.output = id
					state = !elem_input.state
				}
			}
			Wire {
				state = !app.wire_groups[elem_input.id_glob_wire].on()
				app.wire_groups[elem_input.id_glob_wire].outputs << id
			}
			Junction {
				mut i := 2
				mut other_side_id := app.get_tile_id_at(x + input_x*i, y + input_y*i)
				for other_side_id != -1 && app.elements[other_side_id] is Junction {
					other_side_id = app.get_tile_id_at(x + input_x*i, y + input_y*i)
					mut other_side_input := app.elements[other_side_id]
					match mut other_side_input {
						Not {
							if other_side_input.orientation == app.build_orientation {
								other_side_input.output = id
								state = !other_side_input.state
								app.elements[other_side_id] = other_side_input
							}
						}
						Wire {
							state = !app.wire_groups[other_side_input.id_glob_wire].on()
							app.wire_groups[other_side_input.id_glob_wire].outputs << id
						}
						else {}
					}
				}
			}
			else {}
		}
		app.elements[input] = elem_input
	}
	if id == app.elements.len {
		app.elements << Not{
			output: output
			state: state
			orientation: app.build_orientation
			destroyed: false
			in_gate: false
			x: x
			y: y
		}
	} else {
		app.elements[id] = Not{
			output: output
			state: state
			orientation: app.build_orientation
			destroyed: false
			in_gate: false
			x: x
			y: y
		}
	}

	if output >= 0 {
		app.queue << id
	}
}

fn (mut app App) wire_place_in(x int, y int) ! {
	mut id := i64(0)
	if app.destroyed.len == 0 {
		id = app.elements.len
	} else {
		// replace element
		id = app.destroyed[0]
		app.destroyed.delete(0)
	}
	place_chunk_id := app.get_chunk_id_at_coords(x, y)
	place_chunk := app.chunks[place_chunk_id]
	if place_chunk.tiles[math.abs(y - place_chunk.y * 16)][math.abs(x - place_chunk.x * 16)] < 0 {
		app.chunks[place_chunk_id].tiles[math.abs(y - place_chunk.y * 16)][math.abs(x - place_chunk.x * 16)] = id
	} else {
		return error('Not in an empty space')
	}
	if app.debug_mode {
		println('app.place_in(${x}, ${y})!')
	}

	mut adjacent_gwire_ids := []i64{}
	mut inputs := []i64{}
	mut outputs := []i64{}

	for pos in [[0, 1], [0, -1], [1, 0], [-1, 0]] {
		elem_id := app.get_tile_id_at(x + pos[0], y + pos[1])
		if elem_id >= 0 {
			mut elem := app.elements[elem_id]
			if !elem.destroyed {
				match mut elem {
					Wire {
						adjacent_gwire_ids << elem.id_glob_wire
					}
					Not {
						output_x, output_y := output_coords_from_orientation(elem.orientation)
						input_x, input_y := input_coords_from_orientation(elem.orientation)
						if pos[0] == output_x && pos[1] == output_y {
							outputs << elem_id
						} else if pos[0] == input_x && pos[1] == input_y {
							if elem.state {
								inputs << elem_id
							}
							elem.output = id
						}
					}
					Junction {
						mut i := 2
						mut other_side_id := app.get_tile_id_at(x + pos[0]*i, y + pos[1]*i)
						for other_side_id != -1 && app.elements[other_side_id] is Junction {
							other_side_id = app.get_tile_id_at(x + pos[0]*i, y + pos[1]*i)
							mut other_side_elem := app.elements[other_side_id]
							match mut other_side_elem {
								Not {
									output_x, output_y := output_coords_from_orientation(other_side_elem.orientation)
									input_x, input_y := input_coords_from_orientation(other_side_elem.orientation)
									if pos[0] == output_x && pos[1] == output_y {
										outputs << elem_id
									} else if pos[0] == input_x && pos[1] == input_y {
										if other_side_elem.state {
											inputs << elem_id
										}
										other_side_elem.output = id
										app.elements[other_side_id] = other_side_elem
									}
								}
								Wire {
									adjacent_gwire_ids << other_side_elem.id_glob_wire
								}
								else {}
							}
						}
					}
					else {}
				}
			}
			app.elements[elem_id] = elem
		}
	}

	mut gwire_id := i64(0)
	if adjacent_gwire_ids.len == 0 {
		gwire_id = app.wire_groups.len
		app.wire_groups << GlobalWire{
			wires: [id]
			inputs: inputs
			outputs: outputs
		}
		if outputs.len > 0 {
			app.queue_gwires << gwire_id
		}
	} else if adjacent_gwire_ids.len == 1 {
		gwire_id = adjacent_gwire_ids[0]
		app.wire_groups[gwire_id].wires << id
		app.wire_groups[gwire_id].inputs << inputs
		app.wire_groups[gwire_id].outputs << outputs
		if app.wire_groups[gwire_id].on() {
			if app.wire_groups[gwire_id].inputs.len == inputs.len {
				app.queue_gwires << gwire_id // update the wire as it changed of state
			} else {
				for id_output in outputs { // new outputs
					mut elem := app.elements[id_output]
					if mut elem is Not {
						elem.state = false
						app.queue << id_output // to stop thinking of it everytime I read this line, the state could only be true for a unconnected not gate
					}
				}
			}
		}
	} else {
		mut tmp_map := map[i64]bool{}
		for k in adjacent_gwire_ids {
			tmp_map[k] = false
		}
		adjacent_gwire_ids = tmp_map.keys()
		adjacent_gwire_ids.sort(a > b)
		for i in 1 .. adjacent_gwire_ids.len {
			pos_if_in_queue := app.queue_gwires.index(i)
			if pos_if_in_queue != -1 {
				
				app.queue_gwires[pos_if_in_queue] = adjacent_gwire_ids[0]
			}
			app.wire_groups[adjacent_gwire_ids[0]].inputs << app.wire_groups[adjacent_gwire_ids[i]].inputs
			app.wire_groups[adjacent_gwire_ids[0]].outputs << app.wire_groups[adjacent_gwire_ids[i]].outputs
			app.wire_groups[adjacent_gwire_ids[0]].wires << app.wire_groups[adjacent_gwire_ids[i]].wires
		}
		app.wire_groups[adjacent_gwire_ids[0]].inputs << inputs
		app.wire_groups[adjacent_gwire_ids[0]].outputs << outputs
		if app.wire_groups[adjacent_gwire_ids[0]].on() {
			for id_output in app.wire_groups[adjacent_gwire_ids[0]].outputs {
				mut elem := app.elements[id_output]
				if mut elem is Not {
					if elem.state {
						elem.state = false
						app.queue << id_output
					}
				}
				app.elements[id_output] = elem
			}
		}
		for i in adjacent_gwire_ids[1..] {
			app.wire_groups.delete(i)
			adjacent_gwire_ids[0] -= 1 // offset the greatest id (final one)
			for mut queued in app.queue_gwires {
				if queued >= i && queued > 0 {
					queued -= 1
				}
			}
			for wg in app.wire_groups[i..] {
				for wire_id in wg.wires {
					mut wire := app.elements[wire_id]
					if mut wire is Wire {
						wire.id_glob_wire -= 1
						app.elements[wire_id] = wire
					}
				}
			}
		}
		gwire_id = adjacent_gwire_ids[0]

		for id_wire in app.wire_groups[gwire_id].wires {
			mut elem := app.elements[id_wire]
			if mut elem is Wire {
				elem.id_glob_wire = adjacent_gwire_ids[0]
				app.elements[id_wire] = elem
			} else {
				panic('Not a wire in a wiregroup')
			}
		}
		app.wire_groups[gwire_id].wires << id
		gwire_id = gwire_id
	}

	if id == app.elements.len {
		app.elements << Wire{
			id_glob_wire: gwire_id
			destroyed: false
			in_gate: false
			x: x
			y: y
		}
	} else {
		app.elements[id] = Wire{
			id_glob_wire: gwire_id
			destroyed: false
			in_gate: false
			x: x
			y: y
		}
	}
}

fn (mut app App) line_in(start_x int, start_y int, end_x int, end_y int) ! {
	mut x := end_x - start_x
	mut y := end_y - start_y
	mut direction_x := 1
	mut direction_y := 1
	if x < 0{
		x = math.abs(x)
		direction_x = -1
	}
	if y < 0{
		y = math.abs(y)
		direction_y = -1
	}
	if x > y{
		for i in 0..x+1{
			if direction_x == 1{app.build_orientation = .east}
			else{app.build_orientation = .west}
			app.place_in(start_x+i*direction_x, start_y) or {}
		}
	}
	else{
		for i in 0..y+1{
			if direction_y == 1{app.build_orientation = .south}
			else{app.build_orientation = .north}
			app.place_in(start_x, start_y+i*direction_y) or {}
		}
	}
}
