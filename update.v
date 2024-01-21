module main

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
								else {}
							}
						}
					}
				}
				else {}
			}
		}
	}
	mut new_queue_gwires := []i64{}
	for updated in app.queue_gwires {
		gwire := app.wire_groups[updated]
		for output_id in gwire.outputs {
			mut output := app.elements[output_id]
			if !output.destroyed {
				if mut output is Not {
					output.state = gwire.inputs.len == 0
					if output_id !in new_queue {
						new_queue << output_id
					}
					app.elements[output_id] = output
				}
			} else {
				panic('elem detruit dans les outputs du wire')
			}
		}
	}
	app.queue = new_queue.clone()
	app.queue_gwires = new_queue_gwires.clone()
}
