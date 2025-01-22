module main

import ggui

fn (mut app App) update() {
	mut new_queue := []i64{}
	for updated in app.queue {
		mut elem := app.elements[updated]
		if !elem.destroyed {
			match mut elem {
				Not {
					if elem.output >= 0 {
						mut output := app.elements[elem.output]
						if !output.destroyed {
							match mut output {
								Not {
									output.state = !elem.state
									new_queue << elem.output
									app.elements[elem.output] = output
								}
								Diode {
									output.state = elem.state
									new_queue << elem.output
									app.elements[elem.output] = output
								}
								Wire {
									if elem.state {
										if updated !in app.wire_groups[output.id_glob_wire].inputs {
											if !app.wire_groups[output.id_glob_wire].on() {
												app.queue_gwires << output.id_glob_wire
											}
											app.wire_groups[output.id_glob_wire].inputs << updated
										}
									} else {
										for i, input_id in app.wire_groups[output.id_glob_wire].inputs {
											if input_id == updated {
												app.wire_groups[output.id_glob_wire].inputs.delete(i)
												break
											}
										}
										if !app.wire_groups[output.id_glob_wire].on() {
											id_gwire_queue := app.queue_gwires.index(output.id_glob_wire)
											if id_gwire_queue == -1 {
												app.queue_gwires << output.id_glob_wire
											}
										}
									}
								}
								Junction {
									mut i := 1
									output_x, output_y := output_coords_from_orientation(elem.orientation)
									mut other_side_id := app.get_tile_id_at(int(elem.x) +
										output_x * i, int(elem.y) + output_y * i)
									for other_side_id != -1
										&& app.elements[other_side_id] is Junction {
										other_side_id = app.get_tile_id_at(int(elem.x) +
											output_x * i, int(elem.y) + output_y * i)
										if other_side_id != -1 {
											mut other_side_output := app.elements[other_side_id]
											match mut other_side_output {
												Not {
													if elem.orientation == other_side_output.orientation {
														other_side_output.state = !elem.state
														new_queue << other_side_id
														app.elements[other_side_id] = other_side_output
													}
												}
												Diode {
													if elem.orientation == other_side_output.orientation {
														other_side_output.state = elem.state
														new_queue << other_side_id
														app.elements[other_side_id] = other_side_output
													}
												}
												Wire {
													if elem.state {
														if updated !in app.wire_groups[other_side_output.id_glob_wire].inputs {
															if !app.wire_groups[other_side_output.id_glob_wire].on() {
																app.queue_gwires << other_side_output.id_glob_wire
															}
															app.wire_groups[other_side_output.id_glob_wire].inputs << updated
														}
													} else {
														for nb, input_id in app.wire_groups[other_side_output.id_glob_wire].inputs {
															if input_id == updated {
																app.wire_groups[other_side_output.id_glob_wire].inputs.delete(nb)
																break
															}
														}
														if !app.wire_groups[other_side_output.id_glob_wire].on() {
															id_gwire_queue := app.queue_gwires.index(other_side_output.id_glob_wire)
															if id_gwire_queue == -1 {
																app.queue_gwires << other_side_output.id_glob_wire
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
								else {}
							}
						}
					}
				}
				Diode {
					if elem.output >= 0 {
						mut output := app.elements[elem.output]
						if !output.destroyed {
							match mut output {
								Not {
									output.state = !elem.state
									new_queue << elem.output
									app.elements[elem.output] = output
								}
								Diode {
									output.state = elem.state
									new_queue << elem.output
									app.elements[elem.output] = output
								}
								Wire {
									if elem.state {
										if updated !in app.wire_groups[output.id_glob_wire].inputs {
											if !app.wire_groups[output.id_glob_wire].on() {
												app.queue_gwires << output.id_glob_wire
											}
											app.wire_groups[output.id_glob_wire].inputs << updated
										}
									} else {
										for i, input_id in app.wire_groups[output.id_glob_wire].inputs {
											if input_id == updated {
												app.wire_groups[output.id_glob_wire].inputs.delete(i)
												break
											}
										}
										if !app.wire_groups[output.id_glob_wire].on() {
											id_gwire_queue := app.queue_gwires.index(output.id_glob_wire)
											if id_gwire_queue == -1 {
												app.queue_gwires << output.id_glob_wire
											}
										}
									}
								}
								Junction {
									mut i := 1
									output_x, output_y := output_coords_from_orientation(elem.orientation)
									mut other_side_id := app.get_tile_id_at(int(elem.x) +
										output_x * i, int(elem.y) + output_y * i)
									for other_side_id != -1
										&& app.elements[other_side_id] is Junction {
										other_side_id = app.get_tile_id_at(int(elem.x) +
											output_x * i, int(elem.y) + output_y * i)
										if other_side_id != -1 {
											mut other_side_output := app.elements[other_side_id]
											match mut other_side_output {
												Not {
													if elem.orientation == other_side_output.orientation {
														other_side_output.state = !elem.state
														new_queue << other_side_id
														app.elements[other_side_id] = other_side_output
													}
												}
												Diode {
													if elem.orientation == other_side_output.orientation {
														other_side_output.state = elem.state
														new_queue << other_side_id
														app.elements[other_side_id] = other_side_output
													}
												}
												Wire {
													if elem.state {
														if updated !in app.wire_groups[other_side_output.id_glob_wire].inputs {
															if !app.wire_groups[other_side_output.id_glob_wire].on() {
																app.queue_gwires << other_side_output.id_glob_wire
															}
															app.wire_groups[other_side_output.id_glob_wire].inputs << updated
														}
													} else {
														for nb, input_id in app.wire_groups[other_side_output.id_glob_wire].inputs {
															if input_id == updated {
																app.wire_groups[other_side_output.id_glob_wire].inputs.delete(nb)
																break
															}
														}
														if !app.wire_groups[other_side_output.id_glob_wire].on() {
															id_gwire_queue := app.queue_gwires.index(other_side_output.id_glob_wire)
															if id_gwire_queue == -1 {
																app.queue_gwires << other_side_output.id_glob_wire
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
								else {}
							}
						}
					}
				}
				Junction {
					panic('Queued junction')
				}
				else {}
			}
		}
	}
	mut new_queue_gwires := []i64{}
	for updated in app.queue_gwires {
		if updated >= 0 {
			gwire := app.wire_groups[updated] or {
				panic('Queued inexistant GlobalWire (i: ${updated} app.wire_groups.len: ${app.wire_groups.len})')
			}
			for output_id in gwire.outputs {
				mut output := app.elements[output_id]
				if !output.destroyed {
					match mut output {
						Not {
							output.state = gwire.inputs.len == 0
							if output_id !in new_queue {
								new_queue << output_id
							}
							app.elements[output_id] = output
						}
						Diode {
							output.state = gwire.inputs.len != 0
							if output_id !in new_queue {
								new_queue << output_id
							}
							app.elements[output_id] = output
						}
						else {
							panic('Wire output not managed: ${output_id} ${output}')
						}
					}
				} else {
					panic('elem detruit dans les outputs du wire')
				}
			}
		}
	}
	app.queue = new_queue.clone()
	app.queue_gwires = new_queue_gwires.clone()
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
