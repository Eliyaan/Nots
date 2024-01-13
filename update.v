module main 

fn (mut app App) update() {
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
							Wire {
								if elem.state {
									if updated !in app.wire_groups[output.id_glob_wire].inputs {
										if app.wire_groups[output.id_glob_wire].inputs.len == 0 {
											app.queue_gwires << output.id_glob_wire
										}
										app.wire_groups[output.id_glob_wire].inputs << updated
									}
								} else {
									mut is_in := false
									for i, input_id in app.wire_groups[output.id_glob_wire].inputs {
										if input_id == updated {
											app.wire_groups[output.id_glob_wire].inputs.delete(i)
											is_in = true
											break
										}
									}
									if app.wire_groups[output.id_glob_wire].inputs.len == 0 && is_in {
										app.queue_gwires << output.id_glob_wire
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
	mut new_queue_gwires := []i64{}
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
	app.queue_gwires = new_queue_gwires.clone()
}