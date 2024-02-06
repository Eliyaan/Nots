module main

import math

fn (mut app App) delete_in(x int, y int) ! {
	place_chunk_id := app.get_chunk_id_at_coords(x, y)
	place_chunk := app.chunks[place_chunk_id]
	old_id := place_chunk.tiles[math.abs(y - place_chunk.y * 16)][math.abs(x - place_chunk.x * 16)]
	if old_id >= 0 {
		app.chunks[place_chunk_id].tiles[math.abs(y - place_chunk.y * 16)][math.abs(x - place_chunk.x * 16)] = -1
		if app.debug_mode {
			println('app.delete_in(${x}, ${y})!')
		}
		app.elements[old_id].destroyed = true
		app.destroyed << old_id
		mut destroyed := app.elements[old_id]
		match mut destroyed {
			Not {
				input_pos_x, input_pos_y := input_coords_from_orientation(destroyed.orientation)
				input := app.get_tile_id_at(x + input_pos_x, y + input_pos_y)
				if input != -1 {
					mut input_elem := app.elements[input]
					match mut input_elem {
						Not {
							if input_elem.output == old_id {
								input_elem.output = -1
							}
						}
						Wire {
							i := app.wire_groups[input_elem.id_glob_wire].outputs.index(old_id)
							if i != -1 {
								app.wire_groups[input_elem.id_glob_wire].outputs.delete(i)
							} else {
								println("Very strange that the Not ${destroyed} id:${old_id} was not in the outputs of the wire input_id:${input} outputs:${app.wire_groups[input_elem.id_glob_wire].outputs}")
							}
						}
						Junction {
							mut i := 1
							mut other_side_id := app.get_tile_id_at(x + input_pos_x*i, y + input_pos_y*i)
							for other_side_id != -1 && app.elements[other_side_id] is Junction {
								other_side_id = app.get_tile_id_at(x + input_pos_x*i, y + input_pos_y*i)
								i++
							}
							if other_side_id >= 0 {
								mut elem := app.elements[other_side_id]
								match mut elem { 
									Wire {
										output_i := app.wire_groups[elem.id_glob_wire].outputs.index(old_id)
										app.wire_groups[elem.id_glob_wire].outputs.delete(output_i)
									}
									Not {
										if elem.output == old_id {
											elem.output = -1
										}
									}
									Diode {
										if elem.output == old_id {
											elem.output = -1
										}
									}
									else {}
								}
							}
						}
						Diode {
							if input_elem.output == old_id {
								input_elem.output = -1
							}
						}
						else {panic("Elem type not supported ${input_elem}")}
					}
					app.elements[input] = input_elem
				}
				output_pos_x, output_pos_y := output_coords_from_orientation(destroyed.orientation)
				if destroyed.output >= 0 && (destroyed.state || old_id in app.queue) {
					mut output_elem := app.elements[destroyed.output]
					match mut output_elem {
						Wire {
							old_wire_state := app.wire_groups[output_elem.id_glob_wire].on()
							i := app.wire_groups[output_elem.id_glob_wire].inputs.index(old_id)
							if i != -1 {
								app.wire_groups[output_elem.id_glob_wire].inputs.delete(i)
							}
							if i != -1 && old_wire_state {  // if not: it's because it just changed of state
								if !app.wire_groups[output_elem.id_glob_wire].on() {
									app.queue_gwires << output_elem.id_glob_wire
								}
							}
						}
						Not {
							output_elem.state = true
							app.elements[destroyed.output] = output_elem
							app.queue << destroyed.output
						}
						Junction {
							mut i := 1
							mut other_side_id := app.get_tile_id_at(x + output_pos_x*i, y + output_pos_y*i)
							for other_side_id != -1 && app.elements[other_side_id] is Junction {
								other_side_id = app.get_tile_id_at(x + output_pos_x*i, y + output_pos_y*i)
								i++
							}
							if other_side_id >= 0 {
								mut other_side_elem := app.elements[other_side_id]
								match mut other_side_elem { 
									Wire {
										old_wire_state := app.wire_groups[other_side_elem.id_glob_wire].on()
										inputs_i := app.wire_groups[other_side_elem.id_glob_wire].inputs.index(old_id)
										if inputs_i != -1 {
											app.wire_groups[other_side_elem.id_glob_wire].inputs.delete(inputs_i)
										}
										if inputs_i != -1 && old_wire_state {  // if not: it's because it just changed of state
											if !app.wire_groups[other_side_elem.id_glob_wire].on() {
												app.queue_gwires << other_side_elem.id_glob_wire
											}
										}
									}
									Not {
										// check ori because ori is not checked with junctions
										if destroyed.orientation == other_side_elem.orientation {
											other_side_elem.state = true
											app.elements[other_side_id] = other_side_elem
											app.queue << other_side_id
										}
									}
									Diode {
										if destroyed.orientation == other_side_elem.orientation {
											if other_side_elem.state {
												app.queue << other_side_id
											}
											other_side_elem.state = false
											app.elements[other_side_id] = other_side_elem
										}
									}
									else {}
								}
							}
						}
						Diode {
							if output_elem.state {
								app.queue << destroyed.output
							}
							output_elem.state = false
							app.elements[destroyed.output] = output_elem
						}
						else {panic("Elem type not supported ${output_elem}")}
					}
				}
			}
			Diode {
				input_pos_x, input_pos_y := input_coords_from_orientation(destroyed.orientation)
				input := app.get_tile_id_at(x + input_pos_x, y + input_pos_y)
				if input != -1 {
					mut input_elem := app.elements[input]
					match mut input_elem {
						Not {
							if input_elem.output == old_id {
								input_elem.output = -1
							}
						}
						Wire {
							i := app.wire_groups[input_elem.id_glob_wire].outputs.index(old_id)
							if i != -1 {
								app.wire_groups[input_elem.id_glob_wire].outputs.delete(i)
							} else {
								println("Very strange that the Not ${destroyed} id:${old_id} was not in the outputs of the wire input_id:${input} outputs:${app.wire_groups[input_elem.id_glob_wire].outputs}")
							}
						}
						Junction {
							mut i := 1
							mut other_side_id := app.get_tile_id_at(x + input_pos_x*i, y + input_pos_y*i)
							for other_side_id != -1 && app.elements[other_side_id] is Junction {
								other_side_id = app.get_tile_id_at(x + input_pos_x*i, y + input_pos_y*i)
								i++
							}
							if other_side_id >= 0 {
								mut elem := app.elements[other_side_id]
								match mut elem { 
									Wire {
										output_i := app.wire_groups[elem.id_glob_wire].outputs.index(old_id)
										app.wire_groups[elem.id_glob_wire].outputs.delete(output_i)
									}
									Not {
										if elem.output == old_id {
											elem.output = -1
										}
									}
									Diode {
										if elem.output == old_id {
											elem.output = -1
										}
									}
									else {}
								}
							}
						}
						Diode {
							if input_elem.output == old_id {
								input_elem.output = -1
							}
						}
						else {panic("Elem type not supported ${input_elem}")}
					}
					app.elements[input] = input_elem
				}
				output_pos_x, output_pos_y := output_coords_from_orientation(destroyed.orientation)
				if destroyed.output >= 0 && (destroyed.state || old_id in app.queue) {
					mut output_elem := app.elements[destroyed.output]
					match mut output_elem {
						Wire {
							old_wire_state := app.wire_groups[output_elem.id_glob_wire].on()
							i := app.wire_groups[output_elem.id_glob_wire].inputs.index(old_id)
							if i != -1 {
								app.wire_groups[output_elem.id_glob_wire].inputs.delete(i)
							}
							if i != -1 && old_wire_state {  // if not: it's because it just changed of state
								if !app.wire_groups[output_elem.id_glob_wire].on() {
									app.queue_gwires << output_elem.id_glob_wire
								}
							}
						}
						Not {
							output_elem.state = true
							app.elements[destroyed.output] = output_elem
							app.queue << destroyed.output
						}
						Junction {
							mut i := 1
							mut other_side_id := app.get_tile_id_at(x + output_pos_x*i, y + output_pos_y*i)
							for other_side_id != -1 && app.elements[other_side_id] is Junction {
								other_side_id = app.get_tile_id_at(x + output_pos_x*i, y + output_pos_y*i)
								i++
							}
							if other_side_id >= 0 {
								mut other_side_elem := app.elements[other_side_id]
								match mut other_side_elem { 
									Wire {
										old_wire_state := app.wire_groups[other_side_elem.id_glob_wire].on()
										inputs_i := app.wire_groups[other_side_elem.id_glob_wire].inputs.index(old_id)
										if inputs_i != -1 {
											app.wire_groups[other_side_elem.id_glob_wire].inputs.delete(inputs_i)
										}
										if inputs_i != -1 && old_wire_state {  // if not: it's because it just changed of state
											if !app.wire_groups[other_side_elem.id_glob_wire].on() {
												app.queue_gwires << other_side_elem.id_glob_wire
											}
										}
									}
									Not {
										// check ori because ori is not checked with junctions
										if destroyed.orientation == other_side_elem.orientation {
											other_side_elem.state = true
											app.elements[other_side_id] = other_side_elem
											app.queue << other_side_id
										}
									}
									Diode {
										if destroyed.orientation == other_side_elem.orientation {
											if other_side_elem.state {
												app.queue << other_side_id
											}
											other_side_elem.state = false
											app.elements[other_side_id] = other_side_elem
										}
									}
									else {}
								}
							}
						}
						Diode {
							if output_elem.state {
								app.queue << destroyed.output
							}
							output_elem.state = false
							app.elements[destroyed.output] = output_elem
						}
						else {panic("Elem type not supported ${output_elem}")}
					}
				}
			}
			Wire {
				mut to_process := []i64{}
				mut final_wires := []GlobalWire{}
				for pos in [[0, 1], [0, -1], [1, 0], [-1, 0]] {
					elem_id := app.get_tile_id_at(x + pos[0], y + pos[1])
					if elem_id >= 0 {
						mut elem := app.elements[elem_id]
						if !elem.destroyed {
							match mut elem {
								Wire {
									to_process << elem_id
								}
								Not {
									output_x, output_y := output_coords_from_orientation(elem.orientation)
									input_x, input_y := input_coords_from_orientation(elem.orientation)
									if pos[0] == output_x && pos[1] == output_y { // direction aligned with output coords direction
										if !elem.state {
											elem.state = true
											if elem_id !in app.queue {
												app.queue << elem_id
											}
										}
									} else if pos[0] == input_x && pos[1] == input_y {
										elem.output = -1
									}
								}
								Diode {
									output_x, output_y := output_coords_from_orientation(elem.orientation)
									input_x, input_y := input_coords_from_orientation(elem.orientation)
									if pos[0] == output_x && pos[1] == output_y { // direction aligned with output coords direction
										if elem.state {
											elem.state = false
											if elem_id !in app.queue {
												app.queue << elem_id
											}
										}
									} else if pos[0] == input_x && pos[1] == input_y {
										elem.output = -1
									}
								}
								Junction {
									mut i := 1
									mut other_side_id := app.get_tile_id_at(x + pos[0]*i, y + pos[1]*i)

									for other_side_id != -1 && app.elements[other_side_id] is Junction {
										other_side_id = app.get_tile_id_at(x + pos[0]*i, y + pos[1]*i)
										if other_side_id != -1 {
											mut output := app.elements[other_side_id]
											match mut output { 
												Not {
													output_x, output_y := output_coords_from_orientation(output.orientation)
													if pos[0] == output_x && pos[1] == output_y {
														if !output.state {
															output.state = true
															app.elements[other_side_id] = output
															if other_side_id !in app.queue {
																app.queue << other_side_id
															}
														}
													}
												}
												Diode {
													output_x, output_y := output_coords_from_orientation(output.orientation)
													if pos[0] == output_x && pos[1] == output_y {
														if output.state {
															output.state = false
															app.elements[other_side_id] = output
															if other_side_id !in app.queue {
																app.queue << other_side_id
															}
														}
													}
												}
												Wire{
													if other_side_id >= 0 {
														to_process << other_side_id
													}
												}
												else {}
											}
											i++
										}
									}
								}
								else {panic("Elem type not supported ${elem}")}
							}
							app.elements[elem_id] = elem
						}
					}
				}
				for element_id in to_process {
					current := app.elements[element_id]
					if final_wires == [] {
						final_wires << GlobalWire{}
						final_wires[0].wires << element_id
						for pos in [[0, 1], [0, -1], [1, 0], [-1, 0]] {
							elem_id := app.get_tile_id_at(int(current.x + pos[0]), int(current.y +
								pos[1]))
							if elem_id >= 0 {
								mut elem := app.elements[elem_id]
								if !elem.destroyed {
									match mut elem {
										Wire {
											// sure that the wire is not in a final wire
											to_process << elem_id
										}
										Not {
											output_x, output_y := output_coords_from_orientation(elem.orientation)
											input_x, input_y := input_coords_from_orientation(elem.orientation)
											if pos[0] == output_x && pos[1] == output_y {
												final_wires[0].outputs << elem_id
											} else if pos[0] == input_x && pos[1] == input_y {
												// the sorting between on / off inputs happens after
												final_wires[0].inputs << elem_id
											}
										}
										Diode {
											output_x, output_y := output_coords_from_orientation(elem.orientation)
											input_x, input_y := input_coords_from_orientation(elem.orientation)
											if pos[0] == output_x && pos[1] == output_y {
												final_wires[0].outputs << elem_id
											} else if pos[0] == input_x && pos[1] == input_y {
												// the sorting between on / off inputs happens after
												final_wires[0].inputs << elem_id
											}
										}
										Junction {
											mut i := 1
											mut other_side_id := app.get_tile_id_at(int(current.x + pos[0]*i), int(current.y + pos[1]*i))
											for other_side_id != -1 && app.elements[other_side_id] is Junction {
												other_side_id = app.get_tile_id_at(int(current.x + pos[0]*i), int(current.y + pos[1]*i))
												if other_side_id != -1 {
													mut output := app.elements[other_side_id]
													match mut output { 
														Not {
															output_x, output_y := output_coords_from_orientation(output.orientation)
															input_x, input_y := input_coords_from_orientation(output.orientation)
															if pos[0] == output_x && pos[1] == output_y {
																final_wires[0].outputs << other_side_id
															} else if pos[0] == input_x && pos[1] == input_y {
																// the sorting between on / off inputs happens after
																final_wires[0].inputs << other_side_id
															}
														}
														Diode {
															output_x, output_y := output_coords_from_orientation(output.orientation)
															input_x, input_y := input_coords_from_orientation(output.orientation)
															if pos[0] == output_x && pos[1] == output_y {
																final_wires[0].outputs << other_side_id
															} else if pos[0] == input_x && pos[1] == input_y {
																// the sorting between on / off inputs happens after
																final_wires[0].inputs << other_side_id
															}
														}
														Wire{
															if other_side_id >= 0 {
																to_process << other_side_id
															}
														}
														else {}
													}
													i++
												}
											}
										}
										else {panic("Elem type not supported ${elem}")}
									}
								}
							}
						}
					} else {
						mut id_gwires := []i64{}
						mut inputs := []i64{}
						mut outputs := []i64{}
						for pos in [[0, 1], [0, -1], [1, 0], [-1, 0]] {
							elem_id := app.get_tile_id_at(int(current.x + pos[0]), int(current.y +
								pos[1]))
							if elem_id >= 0 {
								mut elem := &app.elements[elem_id]
								if !elem.destroyed {
									match mut elem {
										Wire {
											mut id_gwire := -1
											for i, gwire in final_wires {
												if gwire.wires.index(elem_id) != -1 {
													id_gwire = i
												}
											}
											if id_gwire == -1 {
												if elem_id !in to_process {
													to_process << elem_id
												}
											} else {
												id_gwires << id_gwire
											}
										}
										Not {
											output_x, output_y := output_coords_from_orientation(elem.orientation)
											input_x, input_y := input_coords_from_orientation(elem.orientation)
											if pos[0] == output_x && pos[1] == output_y {
												outputs << elem_id
											} else if pos[0] == input_x && pos[1] == input_y {
												// the sorting between on / off inputs happens after
												inputs << elem_id
											}
										}
										Diode {
											output_x, output_y := output_coords_from_orientation(elem.orientation)
											input_x, input_y := input_coords_from_orientation(elem.orientation)
											if pos[0] == output_x && pos[1] == output_y {
												outputs << elem_id
											} else if pos[0] == input_x && pos[1] == input_y {
												// the sorting between on / off inputs happens after
												inputs << elem_id
											}
										}
										Junction {
											mut i := 1
											mut other_side_id := app.get_tile_id_at(int(current.x + pos[0]*i), int(current.y + pos[1]*i))
											for other_side_id != -1 && app.elements[other_side_id] is Junction {
												other_side_id = app.get_tile_id_at(int(current.x + pos[0]*i), int(current.y + pos[1]*i))
												if other_side_id != -1 {
													mut output := app.elements[other_side_id]
													match mut output { 
														Not {
															output_x, output_y := output_coords_from_orientation(output.orientation)
															input_x, input_y := input_coords_from_orientation(output.orientation)
															if pos[0] == output_x && pos[1] == output_y {
																outputs << other_side_id
															} else if pos[0] == input_x && pos[1] == input_y {
																// the sorting between on / off inputs happens after
																inputs << other_side_id
															}
														}
														Diode {
															output_x, output_y := output_coords_from_orientation(output.orientation)
															input_x, input_y := input_coords_from_orientation(output.orientation)
															if pos[0] == output_x && pos[1] == output_y {
																outputs << other_side_id
															} else if pos[0] == input_x && pos[1] == input_y {
																// the sorting between on / off inputs happens after
																inputs << other_side_id
															}
														}
														Wire{
															if other_side_id >= 0 {
																mut id_gwire := -1
																for id, gwire in final_wires {
																	if gwire.wires.index(other_side_id) != -1 {
																		id_gwire = id
																	}
																}
																if id_gwire == -1 {
																	if other_side_id !in to_process {
																		to_process << other_side_id
																	}
																} else {
																	id_gwires << id_gwire
																}
															}
														}
														else {}
													}
													i++
												}
											}
										}
										else {panic("Elem type not supported ${elem}")}
									}
								}
							}
						}
						mut tmp_map := map[i64]bool{}
						for k in id_gwires {
							tmp_map[k] = false
						}
						id_gwires = tmp_map.keys()
						id_gwires.sort(a > b)
						if id_gwires.len > 1 {
							for id in id_gwires[1..] {
								final_wires[id_gwires[0]].wires << final_wires[id].wires
								final_wires[id_gwires[0]].inputs << final_wires[id].inputs
								final_wires[id_gwires[0]].outputs << final_wires[id].outputs
								final_wires.delete(id)
								id_gwires[0] -= 1
							}

							final_wires[id_gwires[0]].wires << element_id
							final_wires[id_gwires[0]].inputs << inputs
							final_wires[id_gwires[0]].outputs << outputs
						} else if id_gwires.len == 1 {
							final_wires[id_gwires[0]].wires << element_id
							final_wires[id_gwires[0]].inputs << inputs
							final_wires[id_gwires[0]].outputs << outputs
						} else if id_gwires.len == 0 {
							final_wires << GlobalWire{}
							final_wires[final_wires.len - 1].wires << element_id
							final_wires[final_wires.len - 1].inputs << inputs
							final_wires[final_wires.len - 1].outputs << outputs
						}
					}
				}
				for i, mut fwire in final_wires {
					mut fwire_id := i64(-1)
					if i > 0 {
						fwire_id = app.wire_groups.len - 1 + i
					} else {
						fwire_id = destroyed.id_glob_wire
					}
					mut on_inputs := []i64{}
					for input_id in fwire.inputs {
						mut input := app.elements[input_id]
						if mut input is Not {
							if input.state {
								on_inputs << input_id
							}
						} else if mut input is Diode {
							if input.state {
								on_inputs << input_id
							}
						}
						app.elements[input_id] = input
					}
					fwire.inputs = on_inputs
					if !(fwire.on()) && app.wire_groups[destroyed.id_glob_wire].on() {
						if fwire_id !in app.queue_gwires {
							app.queue_gwires << fwire_id
						}
					}

					if fwire.on() {
						if fwire_id !in app.queue_gwires {
							app.queue_gwires << fwire_id
						}
					}
					for wire_id in fwire.wires {
						mut wire := app.elements[wire_id]
						if mut wire is Wire {
							wire.id_glob_wire = fwire_id
							app.elements[wire_id] = wire
						}
					}
				}
				if final_wires.len > 0 {
					app.wire_groups[destroyed.id_glob_wire] = final_wires[0]
					app.wire_groups << final_wires#[1..]
				} else {
					for gwire in app.wire_groups[destroyed.id_glob_wire + 1..] {
						for wire_id in gwire.wires {
							mut wire := app.elements[wire_id]
							if mut wire is Wire {
								wire.id_glob_wire -= 1
								app.elements[wire_id] = wire
							}
						}
					}
					app.wire_groups.delete(destroyed.id_glob_wire)
					mut i_queue := app.queue_gwires.index(destroyed.id_glob_wire)
					for i_queue != -1 {
						app.queue_gwires.delete(i_queue)
						i_queue = app.queue_gwires.index(destroyed.id_glob_wire)
					}
					for mut i in app.queue_gwires {
						if i > destroyed.id_glob_wire {
							i -= 1
						}
					}
				}
			}
			Junction {
				mut to_process := []i64{}
				mut final_wires := []GlobalWire{}
				mut adjacent_gwire_ids := []i64{}
				mut adjacent_wire_ids := []i64{}
				for pos in [[0, 1], [0, -1], [1, 0], [-1, 0]] {
					elem_id := app.get_tile_id_at(x + pos[0], y + pos[1])
					if elem_id >= 0 {
						mut elem := app.elements[elem_id]
						if !elem.destroyed {
							match mut elem {
								Wire {
									to_process << elem_id
									adjacent_wire_ids << elem_id
									if elem.id_glob_wire !in adjacent_gwire_ids {
										adjacent_gwire_ids << elem.id_glob_wire
										if adjacent_gwire_ids.len > 2 {
											panic("Too much adjacent wires ${adjacent_gwire_ids.len} instead of 2.")
										}
									}
								}
								Not {
									output_x, output_y := output_coords_from_orientation(elem.orientation)
									input_x, input_y := input_coords_from_orientation(elem.orientation)
									if pos[0] == output_x && pos[1] == output_y { // direction aligned with output coords direction
										if !elem.state {
											elem.state = true
											if elem_id !in app.queue {
												app.queue << elem_id
											}
										}
									} else if pos[0] == input_x && pos[1] == input_y {
										elem.output = -1
									}
								}
								Diode {
									output_x, output_y := output_coords_from_orientation(elem.orientation)
									input_x, input_y := input_coords_from_orientation(elem.orientation)
									if pos[0] == output_x && pos[1] == output_y { // direction aligned with output coords direction
										if elem.state {
											elem.state = false
											if elem_id !in app.queue {
												app.queue << elem_id
											}
										}
									} else if pos[0] == input_x && pos[1] == input_y {
										elem.output = -1
									}
								}
								Junction {
									mut i := 1
									mut other_side_id := app.get_tile_id_at(x + pos[0]*i, y + pos[1]*i)

									for other_side_id != -1 && app.elements[other_side_id] is Junction {
										other_side_id = app.get_tile_id_at(x + pos[0]*i, y + pos[1]*i)
										if other_side_id != -1 {
											mut output := app.elements[other_side_id]
											match mut output { 
												Not {
													output_x, output_y := output_coords_from_orientation(output.orientation)
													if pos[0] == output_x && pos[1] == output_y {
														if !output.state {
															output.state = true
															app.elements[other_side_id] = output
															if other_side_id !in app.queue {
																app.queue << other_side_id	
															}
														}
													}
												}
												Diode {
													output_x, output_y := output_coords_from_orientation(output.orientation)
													if pos[0] == output_x && pos[1] == output_y {
														if output.state {
															output.state = false
															app.elements[other_side_id] = output
															if other_side_id !in app.queue {
																app.queue << other_side_id	
															}
														}
													}
												}
												Wire{
													if other_side_id >= 0 {
														to_process << other_side_id
														adjacent_wire_ids << other_side_id
														if output.id_glob_wire !in adjacent_gwire_ids {
															adjacent_gwire_ids << output.id_glob_wire
															if adjacent_gwire_ids.len > 2 {
																panic("Too much adjacent wires ${adjacent_gwire_ids.len} instead of 2: ${adjacent_gwire_ids}")
															}
														}
													}
												}
												else {}
											}
											i++
										}
									}
								}
								else {panic("Elem type not supported ${elem}")}
							}
							app.elements[elem_id] = elem
						}
					}
				}
				for element_id in to_process {
					current := app.elements[element_id]
					if final_wires == [] {
						final_wires << GlobalWire{}
						final_wires[0].wires << element_id
						for pos in [[0, 1], [0, -1], [1, 0], [-1, 0]] {
							elem_id := app.get_tile_id_at(int(current.x + pos[0]), int(current.y +
								pos[1]))
							if elem_id >= 0 {
								mut elem := app.elements[elem_id]
								if !elem.destroyed {
									match mut elem {
										Wire {
											// sure that the wire is not in a final wire
											to_process << elem_id
										}
										Not {
											output_x, output_y := output_coords_from_orientation(elem.orientation)
											input_x, input_y := input_coords_from_orientation(elem.orientation)
											if pos[0] == output_x && pos[1] == output_y {
												final_wires[0].outputs << elem_id
											} else if pos[0] == input_x && pos[1] == input_y {
												// the sorting between on / off inputs happens after
												final_wires[0].inputs << elem_id
											}
										}
										Diode {
											output_x, output_y := output_coords_from_orientation(elem.orientation)
											input_x, input_y := input_coords_from_orientation(elem.orientation)
											if pos[0] == output_x && pos[1] == output_y {
												final_wires[0].outputs << elem_id
											} else if pos[0] == input_x && pos[1] == input_y {
												// the sorting between on / off inputs happens after
												final_wires[0].inputs << elem_id
											}
										}
										Junction {
											mut i := 1
											mut other_side_id := app.get_tile_id_at(int(current.x + pos[0]*i), int(current.y + pos[1]*i))
											for other_side_id != -1 && app.elements[other_side_id] is Junction {
												other_side_id = app.get_tile_id_at(int(current.x + pos[0]*i), int(current.y + pos[1]*i))
												if other_side_id != -1 {
													mut output := app.elements[other_side_id]
													match mut output { 
														Not {
															output_x, output_y := output_coords_from_orientation(output.orientation)
															input_x, input_y := input_coords_from_orientation(output.orientation)
															if pos[0] == output_x && pos[1] == output_y {
																final_wires[0].outputs << other_side_id
															} else if pos[0] == input_x && pos[1] == input_y {
																// the sorting between on / off inputs happens after
																final_wires[0].inputs << other_side_id
															}
														}
														Diode {
															output_x, output_y := output_coords_from_orientation(output.orientation)
															input_x, input_y := input_coords_from_orientation(output.orientation)
															if pos[0] == output_x && pos[1] == output_y {
																final_wires[0].outputs << other_side_id
															} else if pos[0] == input_x && pos[1] == input_y {
																// the sorting between on / off inputs happens after
																final_wires[0].inputs << other_side_id
															}
														}
														Wire{
															if other_side_id >= 0 {
																to_process << other_side_id
															}
														}
														else {}
													}
													i++
												}
											}
										}
										else {}
									}
								}
							}
						}
					} else {
						mut id_gwires := []i64{}
						mut inputs := []i64{}
						mut outputs := []i64{}
						for pos in [[0, 1], [0, -1], [1, 0], [-1, 0]] {
							elem_id := app.get_tile_id_at(int(current.x + pos[0]), int(current.y +
								pos[1]))
							if elem_id >= 0 {
								mut elem := &app.elements[elem_id]
								if !elem.destroyed {
									match mut elem {
										Wire {
											mut id_gwire := -1
											for i, gwire in final_wires {
												if gwire.wires.index(elem_id) != -1 {
													id_gwire = i
												}
											}
											if id_gwire == -1 {
												if elem_id !in to_process {
													to_process << elem_id
												}
											} else {
												id_gwires << id_gwire
											}
										}
										Not {
											output_x, output_y := output_coords_from_orientation(elem.orientation)
											input_x, input_y := input_coords_from_orientation(elem.orientation)
											if pos[0] == output_x && pos[1] == output_y {
												outputs << elem_id
											} else if pos[0] == input_x && pos[1] == input_y {
												// the sorting between on / off inputs happens after
												inputs << elem_id
											}
										}
										Diode {
											output_x, output_y := output_coords_from_orientation(elem.orientation)
											input_x, input_y := input_coords_from_orientation(elem.orientation)
											if pos[0] == output_x && pos[1] == output_y {
												outputs << elem_id
											} else if pos[0] == input_x && pos[1] == input_y {
												// the sorting between on / off inputs happens after
												inputs << elem_id
											}
										}
										Junction {
											mut i := 1
											mut other_side_id := app.get_tile_id_at(int(current.x + pos[0]*i), int(current.y + pos[1]*i))
											
											for other_side_id != -1 && app.elements[other_side_id] is Junction {
												other_side_id = app.get_tile_id_at(int(current.x + pos[0]*i), int(current.y + pos[1]*i))
												if other_side_id != -1 {
													mut output := app.elements[other_side_id]
													match mut output { 
														Not {
															output_x, output_y := output_coords_from_orientation(output.orientation)
															input_x, input_y := input_coords_from_orientation(output.orientation)
															if pos[0] == output_x && pos[1] == output_y {
																outputs << other_side_id
															} else if pos[0] == input_x && pos[1] == input_y {
																// the sorting between on / off inputs happens after
																inputs << other_side_id
															}
														}
														Diode {
															output_x, output_y := output_coords_from_orientation(output.orientation)
															input_x, input_y := input_coords_from_orientation(output.orientation)
															if pos[0] == output_x && pos[1] == output_y {
																outputs << other_side_id
															} else if pos[0] == input_x && pos[1] == input_y {
																// the sorting between on / off inputs happens after
																inputs << other_side_id
															}
														}
														Wire{
															if other_side_id >= 0 {
																mut id_gwire := -1
																for id, gwire in final_wires {
																	if gwire.wires.index(other_side_id) != -1 {
																		id_gwire = id
																	}
																}
																if id_gwire == -1 {
																	if other_side_id !in to_process {
																		to_process << other_side_id
																	}
																} else {
																	id_gwires << id_gwire
																}
															}
														}
														else {}
													}
													i++
												}
											}
										}
										else {}
									}
								}
							}
						}
						mut tmp_map := map[i64]bool{}
						for k in id_gwires {
							tmp_map[k] = false
						}
						id_gwires = tmp_map.keys()
						id_gwires.sort(a > b)
						if id_gwires.len > 1 {
							for id in id_gwires[1..] {
								final_wires[id_gwires[0]].wires << final_wires[id].wires
								final_wires[id_gwires[0]].inputs << final_wires[id].inputs
								final_wires[id_gwires[0]].outputs << final_wires[id].outputs
								final_wires.delete(id)
								id_gwires[0] -= 1
							}
							final_wires[id_gwires[0]].wires << element_id
							final_wires[id_gwires[0]].inputs << inputs
							final_wires[id_gwires[0]].outputs << outputs
						} else if id_gwires.len == 1 {
							final_wires[id_gwires[0]].wires << element_id
							final_wires[id_gwires[0]].inputs << inputs
							final_wires[id_gwires[0]].outputs << outputs
						} else if id_gwires.len == 0 {
							final_wires << GlobalWire{}
							final_wires[final_wires.len - 1].wires << element_id
							final_wires[final_wires.len - 1].inputs << inputs
							final_wires[final_wires.len - 1].outputs << outputs
						}
					}
				}
				for i, mut fwire in final_wires {
					mut fwire_id := i64(-1)
					if i >= adjacent_gwire_ids.len {
						fwire_id = app.wire_groups.len - adjacent_gwire_ids.len + i
					} else {
						fwire_id = adjacent_gwire_ids[i]
					}
					mut on_inputs := []i64{}
					for input_id in fwire.inputs {
						mut input := app.elements[input_id]
						if mut input is Not {
							if input.state {
								on_inputs << input_id
							}
						} else if mut input is Diode {
							if input.state {
								on_inputs << input_id
							}
						}
						app.elements[input_id] = input
					}
					fwire.inputs = on_inputs
					mut previous_id_gwire := i64(-1)
					for wire_id in fwire.wires {
						if wire_id in adjacent_wire_ids {
							mut previous_wire := app.elements[wire_id]
							if mut previous_wire is Wire {
								previous_id_gwire = previous_wire.id_glob_wire
								break
							} else {
								panic("Should be a wire ${previous_wire}")
							}
						}
					}
					if !(fwire.on()) && app.wire_groups[previous_id_gwire].on() {
						if fwire_id !in app.queue_gwires {
							app.queue_gwires << fwire_id
						}
					}

					if fwire.on() {
						if fwire_id !in app.queue_gwires {
							app.queue_gwires << fwire_id
						}
					}
					for wire_id in fwire.wires {
						mut wire := app.elements[wire_id]
						if mut wire is Wire {
							wire.id_glob_wire = fwire_id
							app.elements[wire_id] = wire
						}
					}
				}
				if final_wires.len > 0 {
					for i, id_adj in adjacent_gwire_ids {
						app.wire_groups[id_adj] = final_wires[i]
					}
					app.wire_groups << final_wires#[adjacent_gwire_ids.len..]
				}
			}
			else {panic("Elem type not supported ${destroyed}")}
		}
	} else {
		return error('Not in a filled space')
	}
	i_old_id_queue := app.queue.index(old_id)
	if i_old_id_queue != -1 {
		app.queue.delete(i_old_id_queue)
	}
	app.update()
}

fn (mut app App) delete_line_in(start_x int, start_y int, end_x int, end_y int) ! {
	mut x := end_x - start_x
	mut y := end_y - start_y
	mut direction_x := 1
	mut direction_y := 1
	if x == 0 && y == 0{
		app.delete_in(start_x, start_y) or {}
	}
	else{
		if x < 0 {
			x = math.abs(x)
			direction_x = -1
		}
		if y < 0 {
			y = math.abs(y)
			direction_y = -1
		}
		if !app.place_is_turn {
			app.delete_straight_line(start_x, start_y, x, y, direction_x, direction_y)
		} 
		else {
			app.delete_turn_line(start_x, start_y, end_x, end_y, x, y, direction_x, direction_y)
		}
	}
	//Reset
	app.mouse_down_x	= 0
	app.mouse_down_y	= 0
	app.mouse_up_x		= 0
	app.mouse_up_y		= 0
}

fn (mut app App) delete_straight_line(start_x int, start_y int, x int, y int, direction_x int, direction_y int){
	if x > y {
		for i in 0 .. x + 1 {
			if direction_x == 1 {
				app.build_orientation = .east
			} else if direction_x == -1 {
				app.build_orientation = .west
			}
			app.delete_in(start_x + i * direction_x, start_y) or {}
		}
	} else {
		for i in 0 .. y + 1 {
			if direction_y == 1 {
				app.build_orientation = .south
			} else if direction_y == -1 {
				app.build_orientation = .north
			}
			app.delete_in(start_x, start_y + i * direction_y) or {}
		}
	}
}

fn (mut app App) delete_turn_line(start_x int, start_y int, end_x int, end_y int, x int, y int, direction_x int, direction_y int){
	if x > y{
		for i in 0 .. x {
			if direction_x == 1 {
				app.build_orientation = .east
			} else if direction_x == -1 {
				app.build_orientation = .west
			}
			app.delete_in(start_x + i * direction_x, start_y) or {}
		}

		tempo := app.build_selected_type
		app.build_selected_type = .wire
		app.delete_in(end_x, start_y)  or {}
		app.build_selected_type = tempo
		if x > y{
			for i in 1 .. y + 1 {
				if direction_y == 1 {
					app.build_orientation = .south
				} else if direction_y == -1 {
					app.build_orientation = .north
				}
				app.delete_in(end_x, start_y + i * direction_y) or {}
			}
		}
	}else if x < y{
		for i in 0 .. y {
			if direction_y == 1 {
				app.build_orientation = .east
			} else if direction_y == -1 {
				app.build_orientation = .west
			}
			app.delete_in(start_x , start_y + i * direction_y) or {}
		}

		tempo := app.build_selected_type
		app.build_selected_type = .wire
		app.delete_in(start_x, end_y)  or {}
		app.build_selected_type = tempo

		for i in 1 .. x + 1 {
			if direction_x == 1 {
				app.build_orientation = .south
			} else if direction_x == -1 {
				app.build_orientation = .north
			}
			app.delete_in(start_x + i * direction_x, end_y) or {}
		}
	}
	else{app.delete_in(end_x, start_y) or {}}
}
