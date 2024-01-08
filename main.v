import gg
import gx
import math

const tile_size = 10

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

struct GlobalWire {
mut:
	state bool
	wires []i64
	inputs []i64
	outputs []i64
}

struct Wire {
mut:
	id_glob_wire i64
	destroyed bool
	in_gate bool
	x i64
	y i64
}

struct Not {
mut:
	output i64
	state bool
	orientation Orientation
	destroyed bool
	in_gate bool
	x i64
	y i64
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

	nb_updates i64 = 1
	build_selected_type Variant
	build_orientation Orientation
}


fn main() {
    mut app := &App{}
    app.gg = gg.new_context(
        fullscreen: true
        create_window: true
        window_title: '- Nots -'
        user_data: app
        bg_color: gx.white
        frame_fn: on_frame
        event_fn: on_event
        sample_count: 6
    )
	app.build_selected_type = .not
	app.build_orientation = .west
	for i in 0..100 {
		app.place_in(i, 1) or {panic(err)}
	}
	
    //lancement du programme/de la fenêtre
    app.gg.run()
}

fn on_frame(mut app App) {
	for _ in 0..app.nb_updates {
		mut new_queue := []i64{}
		for updated in app.queue {
			mut elem := &app.elements[updated]
			match mut elem {
				Not {
					if elem.output >= 0 {
						mut output := &app.elements[elem.output]
						if !output.destroyed {
							match mut output {
								Not {
									output.state = !elem.state
									new_queue << elem.output
								}
								// TODO
								else {}
							}
						}
					}
				}
				else {}
			}
		}
		for updated in app.queue_gwires {
			mut gwire := &app.wire_groups[updated]
			for output_id in gwire.outputs {
				mut output := &app.elements[output_id]
				if !output.destroyed {
					if mut output is Not{
						output.state = gwire.inputs.len == 0
						new_queue << output_id
					}
				} else {
					panic("elem detruit dans les outputs du wire")
				}
			}
		}
		app.queue = new_queue.clone()
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
								.north {
									-90
								}
								.south {
									90
								}
								.east {
									0
								}
								.west {
									180
								}
							}
							app.gg.draw_polygon_filled(f32(element.x*tile_size)+tile_size/2.0, f32(element.y*tile_size)+tile_size/2.0, tile_size/2.0, 3, rotation, color)
						}
						Wire {
							color := if app.wire_groups[element.id_glob_wire].state {gg.Color{255, 255, 0, 255}} else {gx.black}
							app.gg.draw_square_filled(f32(element.x*tile_size), f32(element.y*tile_size), tile_size, color)
						}
						else {}
					}
				}
			}
		}
	}
	app.gg.show_fps()
    app.gg.end()
}

fn on_event(e &gg.Event, mut app App){
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
        }
        .mouse_up {
            match e.mouse_button{
                .left{
					x, y := mouse_to_coords(e.mouse_x, e.mouse_y)
					app.place_in(x, y) or {println(err)}
				}
				.right {
					x, y := mouse_to_coords(e.mouse_x, e.mouse_y)
					app.delete_in(x, y) or {println(err)}
				}
                else{}
        }}
        else {}
    }
}

fn (mut app App) delete_in(x int, y int) ! {
	mut place_chunk := app.get_chunk_at_coords(x, y)
	old_id := place_chunk.tiles[math.abs(y-place_chunk.y*16)][math.abs(x-place_chunk.x*16)] 
	if old_id >= 0 {
		place_chunk.tiles[math.abs(y-place_chunk.y*16)][math.abs(x-place_chunk.x*16)] = -1
		app.elements[old_id].destroyed = true
		app.destroyed << old_id
		mut destroyed := &app.elements[old_id]
		match mut destroyed {
			Not {
				destroyed.state = false
				if destroyed.output >= 0 {
					app.queue << old_id
				}
				input := match destroyed.orientation {
					.north {
						chunk := app.get_chunk_at_coords(x, y+1)
						chunk.tiles[math.abs(y+1-chunk.y*16)][math.abs(x-chunk.x*16)]
					}
					.south {
						chunk := app.get_chunk_at_coords(x, y-1)
						chunk.tiles[math.abs(y-1-chunk.y*16)][math.abs(x-chunk.x*16)]
					}
					.east {
						chunk := app.get_chunk_at_coords(x-1, y)
						chunk.tiles[math.abs(y-chunk.y*16)][math.abs(x-1-chunk.x*16)]
					}
					.west {
						chunk := app.get_chunk_at_coords(x+1, y)
						chunk.tiles[math.abs(y-chunk.y*16)][math.abs(x+1-chunk.x*16)]
					}
				}
				if input != -1 {
					mut input_elem := &app.elements[input]
					match mut input_elem {
						Not {
							if input_elem.output == old_id {
								input_elem.output = -1
							}
						}
						else {}
					}
				}
			}
			else {}
		}
	} else {
		return error("Not in a filled space")
	}
}

fn (mut app App) place_in(x int, y int) ! {
	match app.build_selected_type {
		.@none{}
		.not {
			mut id := i64(0)
			if app.destroyed.len == 0 {
				id = app.elements.len
			} else {
				id = app.destroyed[0]
				app.destroyed.delete(0)
				// remplacer l'element
			}
			mut place_chunk := app.get_chunk_at_coords(x, y)
			if place_chunk.tiles[math.abs(y-place_chunk.y*16)][math.abs(x-place_chunk.x*16)] < 0 {
				place_chunk.tiles[math.abs(y-place_chunk.y*16)][math.abs(x-place_chunk.x*16)] = id
			} else {
				return error("Not in an empty space")
			}
			
			mut output := match app.build_orientation {
				.north {
					chunk := app.get_chunk_at_coords(x, y-1)
					chunk.tiles[math.abs(y-1-chunk.y*16)][math.abs(x-chunk.x*16)]
				}
				.south {
					chunk := app.get_chunk_at_coords(x, y+1)
					chunk.tiles[math.abs(y+1-chunk.y*16)][math.abs(x-chunk.x*16)]
				}
				.east {
					chunk := app.get_chunk_at_coords(x+1, y)
					chunk.tiles[math.abs(y-chunk.y*16)][math.abs(x+1-chunk.x*16)]
				}
				.west {
					chunk := app.get_chunk_at_coords(x-1, y)
					chunk.tiles[math.abs(y-chunk.y*16)][math.abs(x-1-chunk.x*16)]
				}
			}
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
			
			input := match app.build_orientation {
				.north {
					chunk := app.get_chunk_at_coords(x, y+1)
					chunk.tiles[math.abs(y+1-chunk.y*16)][math.abs(x-chunk.x*16)]
				}
				.south {
					chunk := app.get_chunk_at_coords(x, y-1)
					chunk.tiles[math.abs(y-1-chunk.y*16)][math.abs(x-chunk.x*16)]
				}
				.east {
					chunk := app.get_chunk_at_coords(x-1, y)
					chunk.tiles[math.abs(y-chunk.y*16)][math.abs(x-1-chunk.x*16)]
				}
				.west {
					chunk := app.get_chunk_at_coords(x+1, y)
					chunk.tiles[math.abs(y-chunk.y*16)][math.abs(x+1-chunk.x*16)]
				}
			}
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
		.wire {
			mut id := i64(0)
			if app.destroyed.len == 0 {
				id = app.elements.len
			} else {
				id = app.destroyed[0]
				app.destroyed.delete(0)
				// remplacer l'element
			}
			mut place_chunk := app.get_chunk_at_coords(x, y)
			if place_chunk.tiles[math.abs(y-place_chunk.y*16)][math.abs(x-place_chunk.x*16)] < 0 {
				place_chunk.tiles[math.abs(y-place_chunk.y*16)][math.abs(x-place_chunk.x*16)] = id
			} else {
				return error("Not in an empty space")
			}

			mut chunk := app.get_chunk_at_coords(x-1, y)
			left := chunk.tiles[math.abs(y-chunk.y*16)][math.abs(x-1-chunk.x*16)]
			chunk = app.get_chunk_at_coords(x+1, y)
			right := chunk.tiles[math.abs(y-chunk.y*16)][math.abs(x+1-chunk.x*16)]
			chunk = app.get_chunk_at_coords(x, y-1)
			top := chunk.tiles[math.abs(y-1-chunk.y*16)][math.abs(x-chunk.x*16)]
			chunk = app.get_chunk_at_coords(x, y+1)		
			bot := chunk.tiles[math.abs(y+1-chunk.y*16)][math.abs(x-chunk.x*16)]

			mut glob_wire_ids := []i64{}
			mut inputs :=  []i64{}
			mut outputs :=  []i64{}
			if left >= 0 {
				mut left_elem := &app.elements[left]
				if !left_elem.destroyed {
					if mut left_elem is Wire {
						glob_wire_ids << left_elem.id_glob_wire
					} else if mut left_elem is Not {
						if left_elem.state {
							match left_elem.orientation {
								.east {
									inputs << left
								}
								.west {
									outputs << left
								}
								else{}
							}
						}
					}
				}
			}
			if right >= 0 {
				mut right_elem := &app.elements[right]
				if !right_elem.destroyed {
					if mut right_elem is Wire {
						glob_wire_ids << right_elem.id_glob_wire
					} else if mut right_elem is Not {
						if right_elem.state {
							match right_elem.orientation {
								.west {
									inputs << right
								}
								.east {
									outputs << right
								}
								else{}
							}
						}
					}
				}
			}
			if top >= 0 {
				mut top_elem := &app.elements[top]
				if !top_elem.destroyed {
					if mut top_elem is Wire {
						glob_wire_ids << top_elem.id_glob_wire
					} else if mut top_elem is Not {
						if top_elem.state {
							match top_elem.orientation {
								.south {
									inputs << top
								}
								.north {
									outputs << top
								}
								else{}
							}
						}
					}
				}
			}
			if bot >= 0 {
				mut bot_elem := &app.elements[bot]
				if !bot_elem.destroyed {
					if mut bot_elem is Wire {
						glob_wire_ids << bot_elem.id_glob_wire
					} else if mut bot_elem is Not {
						if bot_elem.state {
							match bot_elem.orientation {
								.north {
									inputs << bot
								} 
								.south {
									outputs << bot
								}
								else{}
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
					state: inputs.len > 0
					wires: [id]
					inputs: inputs
					outputs: outputs
				}
				if inputs.len > 0 {
					app.queue_gwires << glob_wire_id
				}
			} else if glob_wire_ids.len == 1 {
				glob_wire_id = glob_wire_ids[0]
				app.wire_groups[glob_wire_id].wires << id
				app.wire_groups[glob_wire_id].inputs << inputs
				app.wire_groups[glob_wire_id].outputs << outputs
				if app.wire_groups[glob_wire_id].inputs.len > 0 {
					app.wire_groups[glob_wire_id].state = true
					if app.wire_groups[glob_wire_id].inputs.len == inputs.len {
						app.queue_gwires << glob_wire_id // update all the wire as it changed of state
					} else {
						for id_output in outputs {
							mut elem := &app.elements[id_output]
							if mut elem is Not {
								elem.state = false
							}
						}
					}
				}
			} else {
				dump("TODO")
				// TODO FUSION glob wires
			}
			app.elements << Wire {
				id_glob_wire: glob_wire_id
				destroyed: false
				in_gate: false
				x: x
				y: y				
			}
		}
	}
}

fn (mut app App) get_chunk_at_coords(x int, y int) &Chunk {
	chunk_y := y/16
	chunk_x := x/16
	for chunk in app.chunks {
		if chunk.x == chunk_x && chunk.y == chunk_y {
			return &chunk
		}
	}
	app.chunks << Chunk{chunk_x, chunk_y, [][]i64{len:16, init:[]i64{len:16, init:-1}}}
	println("New chunk")
	return &app.chunks[app.chunks.len-1]
}

fn mouse_to_coords(x f32, y f32) (int, int) {
	return int(x)/tile_size, int(y)/tile_size
}