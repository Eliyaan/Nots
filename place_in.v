module main

import math


fn (mut app App) place_in(x int, y int) ! {
	match app.build_selected_type {
		.@none{}
		.not {
			app.not_place_in(x, y)!
		}
		.wire {
			app.wire_place_in(x, y)!
		}
	}
}

fn (mut app App) not_place_in(x int, y int) ! {
	mut id := i64(0)
	if app.destroyed.len == 0 {
		id = app.elements.len
	} else { // replace the element
		id = app.destroyed[0]
		app.destroyed.delete(0)
	}
	mut place_chunk := app.get_chunk_at_coords(x, y)
	if place_chunk.tiles[math.abs(y-place_chunk.y*16)][math.abs(x-place_chunk.x*16)] < 0 {
		place_chunk.tiles[math.abs(y-place_chunk.y*16)][math.abs(x-place_chunk.x*16)] = id
	} else {
		return error("Not in an empty space")
	}
	
	output_x, output_y := output_coords_from_orientation(app.build_orientation)
	mut output := app.get_tile_id_at(x+output_x, y+output_y)

	if output != -1 {
		if app.elements[output].destroyed {
			output = -1
		} else {
			mut output_elem := &app.elements[output]
			match mut output_elem {
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
	input := app.get_tile_id_at(x+input_x, y+input_y)

	mut state := true // because a not gate without input is a not gate with off input
	if input >= 0 {
		mut elem_input := &app.elements[input]
		match mut elem_input {
			Not {
				if elem_input.orientation == app.build_orientation {
					elem_input.output = id
					state = !elem_input.state
				}
			}
			Wire {
				state = !(app.wire_groups[elem_input.id_glob_wire].inputs.len > 0)
				app.wire_groups[elem_input.id_glob_wire].outputs << id
			}
			else {}
		}
	}
	if id == app.elements.len {
		app.elements <<	Not {
			output: output
			state: state
			orientation: app.build_orientation
			destroyed: false
			in_gate: false
			x: x
			y: y
		}
	} else {
		app.elements[id] = Not {
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
	mut place_chunk := app.get_chunk_at_coords(x, y)
	if place_chunk.tiles[math.abs(y-place_chunk.y*16)][math.abs(x-place_chunk.x*16)] < 0 {
		place_chunk.tiles[math.abs(y-place_chunk.y*16)][math.abs(x-place_chunk.x*16)] = id
	} else {
		return error("Not in an empty space")
	}

	mut glob_wire_ids := []i64{}
	mut inputs := []i64{}
	mut outputs := []i64{}

	for pos in [[0, 1], [0, -1], [1, 0], [-1,0]] {
		elem_id := app.get_tile_id_at(x+pos[0], y+pos[1])
		if elem_id >= 0 {
			mut elem := &app.elements[elem_id]
			if !elem.destroyed {
				if mut elem is Wire {
					glob_wire_ids << elem.id_glob_wire
				} else if mut elem is Not {
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
			}
		}
	}

	mut glob_wire_id := i64(0)
	if glob_wire_ids.len == 0 {
		println('new glob wire')
		glob_wire_id = app.wire_groups.len
		app.wire_groups << GlobalWire {
			wires: [id]
			inputs: inputs
			outputs: outputs
		}
		if outputs.len > 0 {
			app.queue_gwires << glob_wire_id
		}
	} else if glob_wire_ids.len == 1 {
		glob_wire_id = glob_wire_ids[0]
		app.wire_groups[glob_wire_id].wires << id
		app.wire_groups[glob_wire_id].inputs << inputs
		app.wire_groups[glob_wire_id].outputs << outputs
		if app.wire_groups[glob_wire_id].inputs.len > 0 {
			if app.wire_groups[glob_wire_id].inputs.len == inputs.len {
				app.queue_gwires << glob_wire_id // update the wire as it changed of state
			} else {
				for id_output in outputs { // new outputs
					mut elem := &app.elements[id_output]
					if mut elem is Not 	{
						elem.state = false
						app.queue << id_output
					}
				}
			}
		} else {
			for id_output in outputs {
				mut elem := &app.elements[id_output]
				if mut elem is Not 	{
					if !elem.state {
						elem.state = true
						app.queue << id_output
					}					
				}
			}
		}
	} else {
		mut tmp_map := map[i64]bool{}
		for k in glob_wire_ids {
			tmp_map[k] = false
		}
		glob_wire_ids = tmp_map.keys()
		glob_wire_ids.sort(a>b)
		for i in 1..glob_wire_ids.len {
			app.wire_groups[glob_wire_ids[0]].inputs << app.wire_groups[glob_wire_ids[i]].inputs
			app.wire_groups[glob_wire_ids[0]].outputs << app.wire_groups[glob_wire_ids[i]].outputs
			app.wire_groups[glob_wire_ids[0]].wires << app.wire_groups[glob_wire_ids[i]].wires
		}
		app.wire_groups[glob_wire_ids[0]].inputs << inputs
		app.wire_groups[glob_wire_ids[0]].outputs << outputs
		if app.wire_groups[glob_wire_ids[0]].inputs.len > 0 {
			for id_output in app.wire_groups[glob_wire_ids[0]].outputs {
				mut elem := &app.elements[id_output]
				if mut elem is Not {
					if elem.state {
						elem.state = false
						app.queue << id_output
					}
				}
			}
		}
		for i in 1..glob_wire_ids.len {
			app.wire_groups.delete(glob_wire_ids[i])
			glob_wire_ids[0] -= 1  // offset the greatest
			for wg in app.wire_groups[glob_wire_ids[i]..] {
				for wire_id in wg.wires {
					mut wire := &app.elements[wire_id]
					if mut wire is Wire {
						wire.id_glob_wire = glob_wire_ids[i]
					}
				}
			}
		}
		for id_wire in app.wire_groups[glob_wire_ids[0]].wires {
			mut elem := &app.elements[id_wire]
			if mut elem is Wire {
				elem.id_glob_wire = glob_wire_ids[0]
			}else{
				panic("Not a wire in a wiregroup")
			}
		}
		app.wire_groups[glob_wire_ids[0]].wires << id
		glob_wire_id = glob_wire_ids[0]
	}

	if id == app.elements.len {
		app.elements << Wire {
			id_glob_wire: glob_wire_id
			destroyed: false
			in_gate: false
			x: x
			y: y
		}
	} else {
		app.elements[id] = Wire {
			id_glob_wire: glob_wire_id
			destroyed: false
			in_gate: false
			x: x
			y: y				
		}
	}
}