module main

import math



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
						Wire {
							i := app.wire_groups[input_elem.id_glob_wire].outputs.index(old_id)
							app.wire_groups[input_elem.id_glob_wire].outputs.delete(i)
						}
						else {}
					}
				}
				if destroyed.output >= 0 {
					mut output_elem := &app.elements[destroyed.output]
					match mut output_elem {
						Wire {
							if destroyed.state {
								i := app.wire_groups[output_elem.id_glob_wire].inputs.index(old_id)
								app.wire_groups[output_elem.id_glob_wire].inputs.delete(i)
								if app.wire_groups[output_elem.id_glob_wire].inputs.len == 0 {
									app.wire_groups[output_elem.id_glob_wire].state = false
									app.queue_gwires << output_elem.id_glob_wire
								}
							}
						}
						Not {
							app.queue << old_id
						}
						else {}
					}
				}
				destroyed.state = false
			}
			Wire {
				mut to_process := []i64{}
				mut final_wires := []GlobalWire{}
				for pos in [[0, 1], [0, -1], [1, 0], [-1,0]] {
					chunk := app.get_chunk_at_coords(x+pos[0], y+pos[1])
					elem_id := chunk.tiles[math.abs(y+pos[1]-chunk.y*16)][math.abs(x+pos[0]-chunk.x*16)]
					if elem_id >= 0 {
						mut elem := &app.elements[elem_id]
						if !elem.destroyed {
							match mut elem {
								Wire {
									to_process << elem_id
								}
								Not {
									// Check si alligné, si aligné si input, enlever l'output du not, si output si fil était ON update
									match pos {
										[0, 1] {
											match elem.orientation {
												.north { elem.output = -1 }
												.south { if app.wire_groups[destroyed.id_glob_wire].state { 
														app.queue << elem_id 
														elem.state = true
													} 
												}
												else {}
											}
										}
										[0, -1] {
											match elem.orientation {
												.south { elem.output = -1 }
												.north { if app.wire_groups[destroyed.id_glob_wire].state { 
														app.queue << elem_id 
														elem.state = true
													} 
												}
												else {}
											}
										}
										[1, 0] {
											match elem.orientation {
												.west { elem.output = -1 }
												.east { if app.wire_groups[destroyed.id_glob_wire].state { 
														app.queue << elem_id 
														elem.state = true
													} 
												}
												else {}
											}
										}
										[-1, 0] {
											match elem.orientation {
												.east { elem.output = -1 }
												.west { if app.wire_groups[destroyed.id_glob_wire].state { 
														app.queue << elem_id 
														elem.state = true
													} 
												}
												else {}
											}
										}
										else {}
									}
								}
								else {}
							}
						}
					}
				}
				for element_id in to_process {
					mut current := &app.elements[element_id]
					if final_wires == [] {
						final_wires << GlobalWire{}
						final_wires[0].wires << element_id
						for pos in [[0, 1], [0, -1], [1, 0], [-1,0]] {
							chunk := app.get_chunk_at_coords(int(current.x+pos[0]), int(current.y+pos[1]))
							elem_id := chunk.tiles[math.abs(int(current.y)+pos[1]-chunk.y*16)][math.abs(int(current.x)+pos[0]-chunk.x*16)]
							if elem_id >= 0 {
								mut elem := &app.elements[elem_id]
								if !elem.destroyed {
									match mut elem {
										Wire {
											to_process << elem_id
										}
										Not {
											match pos {
												[0, 1] {
													match elem.orientation {
														.north { if elem.state {final_wires[0].inputs << elem_id} }
														.south { final_wires[0].outputs << elem_id }
														else {}
													}
												}
												[0, -1] {
													match elem.orientation {
														.south { if elem.state {final_wires[0].inputs << elem_id} }
														.north { final_wires[0].outputs << elem_id }
														else {}
													}
												}
												[1, 0] {
													match elem.orientation {
														.west { if elem.state {final_wires[0].inputs << elem_id} }
														.east { final_wires[0].outputs << elem_id }
														else {}
													}
												}
												[-1, 0] {
													match elem.orientation {
														.east { if elem.state {final_wires[0].inputs << elem_id} }
														.west { final_wires[0].outputs << elem_id }
														else {}
													}
												}
												else {}
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
							chunk := app.get_chunk_at_coords(int(current.x)+pos[0], int(current.y)+pos[1])
							elem_id := chunk.tiles[math.abs(int(current.y)+pos[1]-chunk.y*16)][math.abs(int(current.x)+pos[0]-chunk.x*16)]

							if elem_id >= 0 {
								mut elem := &app.elements[elem_id]
								if !elem.destroyed {
									match mut elem {
										Wire {
											mut id_g_fil := -1
											for i, gfil in final_wires {
												if gfil.wires.index(elem_id) != -1 {
													id_g_fil = i
												}
											}
											if id_g_fil == -1 {
												if elem_id !in to_process {
													to_process << elem_id
												}
											} else {
												id_gwires << id_g_fil
											}											
										}
										Not {
											match pos {
												[0, 1] {
													match elem.orientation {
														.north { if elem.state {inputs << elem_id} }
														.south { outputs << elem_id }
														else {}
													}
												}
												[0, -1] {
													match elem.orientation {
														.south { if elem.state {inputs << elem_id} }
														.north { outputs << elem_id }
														else {}
													}
												}
												[1, 0] {
													match elem.orientation {
														.west { if elem.state {inputs << elem_id} }
														.east { outputs << elem_id }
														else {}
													}
												}
												[-1, 0] {
													match elem.orientation {
														.east { if elem.state {inputs << elem_id} }
														.west { outputs << elem_id }
														else {}
													}
												}
												else {}
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
						id_gwires.sort(a>b)
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
							final_wires[final_wires.len-1].wires << element_id
							final_wires[final_wires.len-1].inputs << inputs
							final_wires[final_wires.len-1].outputs << outputs
						}
					}
				}
				for i, mut fwire in final_wires {
					fwire.state = fwire.inputs.len > 0
					mut fwire_id := i64(-1)
					if i > 0 {
						fwire_id = app.wire_groups.len - 1 + i
					} else {
						fwire_id = destroyed.id_glob_wire
					}
					
					if !fwire.state && app.wire_groups[destroyed.id_glob_wire].state {
						// if destroyed.id_glob_wire in app.queue_gwires {
						// 	app.queue_gwires << fwire_id
						// }
						for output_id in fwire.outputs {
							mut output := &app.elements[output_id]
							if mut output is Not {
								output.state = true
							}
							app.queue << output_id
						}
					} 
					if fwire.state {
						if destroyed.id_glob_wire in app.queue_gwires {
							app.queue_gwires << fwire_id
						}
					}
					for wire_id in fwire.wires {
						mut wire := &app.elements[wire_id]
						if mut wire is Wire {
							wire.id_glob_wire = fwire_id
						}
					}
				}
				if final_wires.len > 0 {
					app.wire_groups[destroyed.id_glob_wire] = final_wires[0]
					app.wire_groups << final_wires#[1..]
					dump(app.wire_groups)
				} else {
					for gwire in app.wire_groups[destroyed.id_glob_wire+1..] {
						for wire_id in gwire.wires {
							mut wire := &app.elements[wire_id]
							if mut wire is Wire {
								wire.id_glob_wire -= 1
							}
						}
					}
					app.wire_groups.delete(destroyed.id_glob_wire)
				}
			}
			else {}
		}
	} else {
		return error("Not in a filled space")
	}
}