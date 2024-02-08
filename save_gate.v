module main

import os

fn (mut app App) save_gate(name string) {
	mut end_x := app.mouse_x - (app.viewport_x + app.screen_x/2) / ceil(tile_size * app.scale) 
	mut end_y := app.mouse_y- (app.viewport_y + app.screen_y/2) / ceil(tile_size * app.scale) 
	if app.start_creation_x > end_x {
		end_x, app.start_creation_x = app.start_creation_x, end_x
	}
	if app.start_creation_y > end_y {
		end_y, app.start_creation_y = app.start_creation_y, end_y
	}
	mut n_nots := []Not{}
	mut s_nots := []Not{}
	mut w_nots := []Not{}
	mut e_nots := []Not{}
	mut n_diodes := []Diode{}
	mut s_diodes := []Diode{}
	mut w_diodes := []Diode{}
	mut e_diodes := []Diode{}
	mut junctions := []Junction{}
	mut wires := []Wire{}
	for y in app.start_creation_y .. end_y + 1 {
		for x in app.start_creation_x .. end_x + 1 {
			id := app.get_tile_id_at(x, y)
			if id != -1 {
				mut elem := app.elements[id]
				match mut elem {
					Not {
						match elem.orientation {
							.north { n_nots << elem }
							.south { s_nots << elem }
							.west { w_nots << elem }
							.east { e_nots << elem }
						}
					}
					Diode {
						match elem.orientation {
							.north { n_diodes << elem }
							.south { s_diodes << elem }
							.west { w_diodes << elem }
							.east { e_diodes << elem }
						}
					}
					Junction { junctions << elem }
					Wire { wires << elem }
					else {panic("Elem type not supported")}
				}
			}
		}
	}
	mut buffer := []u8{}
	buffer << 0 // first working version
	if n_nots.len + s_nots.len + w_nots.len + e_nots.len > 0 {
		buffer << u8(Variant.not)
		if n_nots.len > 0 {
			buffer << u8(Orientation.north)
			buffer << u8(n_nots.len >> 24)
			buffer << u8(n_nots.len >> 16)
			buffer << u8(n_nots.len >> 8)
			buffer << u8(n_nots.len)
			for not in n_nots {
				x := not.x - app.start_creation_x
				y := not.y - app.start_creation_y
				buffer << u8(x >> 8)
				buffer << u8(x)
				buffer << u8(y >> 8)
				buffer << u8(y)
			}
		}
		if s_nots.len > 0 {
			buffer << u8(Orientation.south)
			buffer << u8(s_nots.len >> 24)
			buffer << u8(s_nots.len >> 16)
			buffer << u8(s_nots.len >> 8)
			buffer << u8(s_nots.len)
			for not in s_nots {
				x := not.x - app.start_creation_x
				y := not.y - app.start_creation_y
				buffer << u8(x >> 8)
				buffer << u8(x)
				buffer << u8(y >> 8)
				buffer << u8(y)
			}
		}
		if w_nots.len > 0 {
			buffer << u8(Orientation.west)
			buffer << u8(w_nots.len >> 24)
			buffer << u8(w_nots.len >> 16)
			buffer << u8(w_nots.len >> 8)
			buffer << u8(w_nots.len)
			for not in w_nots {
				x := not.x - app.start_creation_x
				y := not.y - app.start_creation_y
				buffer << u8(x >> 8)
				buffer << u8(x)
				buffer << u8(y >> 8)
				buffer << u8(y)
			}
		}
		if e_nots.len > 0 {
			buffer << u8(Orientation.east)
			buffer << u8(e_nots.len >> 24)
			buffer << u8(e_nots.len >> 16)
			buffer << u8(e_nots.len >> 8)
			buffer << u8(e_nots.len)
			for not in e_nots {
				x := not.x - app.start_creation_x
				y := not.y - app.start_creation_y
				buffer << u8(x >> 8)
				buffer << u8(x)
				buffer << u8(y >> 8)
				buffer << u8(y)
			}
		}
		buffer << u8(255) // end of this type
	}
	if n_diodes.len + s_diodes.len + w_diodes.len + e_diodes.len > 0 {
		buffer << u8(Variant.diode)
		if n_diodes.len > 0 {
			buffer << u8(Orientation.north)
			buffer << u8(n_diodes.len >> 24)
			buffer << u8(n_diodes.len >> 16)
			buffer << u8(n_diodes.len >> 8)
			buffer << u8(n_diodes.len)
			for diode in n_diodes {
				x := diode.x - app.start_creation_x
				y := diode.y - app.start_creation_y
				buffer << u8(x >> 8)
				buffer << u8(x)
				buffer << u8(y >> 8)
				buffer << u8(y)
			}
		}
		if s_diodes.len > 0 {
			buffer << u8(Orientation.south)
			buffer << u8(s_diodes.len >> 24)
			buffer << u8(s_diodes.len >> 16)
			buffer << u8(s_diodes.len >> 8)
			buffer << u8(s_diodes.len)
			for diode in s_diodes {
				x := diode.x - app.start_creation_x
				y := diode.y - app.start_creation_y
				buffer << u8(x >> 8)
				buffer << u8(x)
				buffer << u8(y >> 8)
				buffer << u8(y)
			}
		}
		if w_diodes.len > 0 {
			buffer << u8(Orientation.west)
			buffer << u8(w_diodes.len >> 24)
			buffer << u8(w_diodes.len >> 16)
			buffer << u8(w_diodes.len >> 8)
			buffer << u8(w_diodes.len)
			for diode in w_diodes {
				x := diode.x - app.start_creation_x
				y := diode.y - app.start_creation_y
				buffer << u8(x >> 8)
				buffer << u8(x)
				buffer << u8(y >> 8)
				buffer << u8(y)
			}
		}
		if e_diodes.len > 0 {
			buffer << u8(Orientation.east)
			buffer << u8(e_diodes.len >> 24)
			buffer << u8(e_diodes.len >> 16)
			buffer << u8(e_diodes.len >> 8)
			buffer << u8(e_diodes.len)
			for diode in e_diodes {
				x := diode.x - app.start_creation_x
				y := diode.y - app.start_creation_y
				buffer << u8(x >> 8)
				buffer << u8(x)
				buffer << u8(y >> 8)
				buffer << u8(y)
			}
		}
		buffer << u8(255) // end of this type
	}
	if junctions.len > 0 {
		buffer << u8(Variant.junction)
		buffer << u8(junctions.len >> 24)
		buffer << u8(junctions.len >> 16)
		buffer << u8(junctions.len >> 8)
		buffer << u8(junctions.len)
		for junction in junctions {
			x := junction.x - app.start_creation_x
			y := junction.y - app.start_creation_y
			buffer << u8(x >> 8)
			buffer << u8(x)
			buffer << u8(y >> 8)
			buffer << u8(y)
		}
	}
	if wires.len > 0 {
		buffer << u8(Variant.wire)
		buffer << u8(wires.len >> 24)
		buffer << u8(wires.len >> 16)
		buffer << u8(wires.len >> 8)
		buffer << u8(wires.len)
		for wire in wires {
			x := wire.x - app.start_creation_x
			y := wire.y - app.start_creation_y
			buffer << u8(x >> 8)
			buffer << u8(x)
			buffer << u8(y >> 8)
			buffer << u8(y)
		}
	}

	os.write_file_array(name, buffer) or {panic(err)}
}

fn (mut app App) load_gate(name string) ! {
	start_x := app.mouse_x - (app.viewport_x + app.screen_x/2) / ceil(tile_size * app.scale) 
	start_y := app.mouse_y - (app.viewport_y + app.screen_y/2) / ceil(tile_size * app.scale)
	buffer := os.read_bytes(name) or {return error("File not found")}
	if buffer.len > 2 {
		if buffer[0] == 0 {
			mut pos := 1
			for pos != buffer.len {
				match buffer[pos] {
					0 {
						app.build_selected_type = .not
						mut loop := true
						pos += 1
						match buffer[pos] {
							0 {	app.build_orientation = .north }
							1 {	app.build_orientation = .south }
							2 {	app.build_orientation = .east }
							3 {	app.build_orientation = .west }
							255 { loop = false }
							else {panic("Should not get ${buffer[pos]}")}
						}
						for loop {
							pos += 1
							mut nb := u32(buffer[pos]) << 24
							pos += 1
							nb = u32(buffer[pos]) << 16 | nb
							pos += 1
							nb = u32(buffer[pos]) << 8 | nb
							pos += 1
							nb = buffer[pos] | nb
							for _ in 0 .. nb {
								pos += 1
								mut x := u16(buffer[pos]) << 8
								pos += 1
								x = buffer[pos] | x
								pos += 1
								mut y := u16(buffer[pos]) << 8
								pos += 1
								y = buffer[pos] | y
								app.place_in(x + start_x, y + start_y) or {}
							}
							pos += 1
							match buffer[pos] {
								0 {	app.build_orientation = .north }
								1 {	app.build_orientation = .south }
								2 {	app.build_orientation = .east }
								3 {	app.build_orientation = .west }
								255 { loop = false }
								else {panic("Should not get ${buffer[pos]}")}
							}
						}
					}
					1 {
						app.build_selected_type = .diode
						mut loop := true
						pos += 1
						match buffer[pos] {
							0 {	app.build_orientation = .north }
							1 {	app.build_orientation = .south }
							2 {	app.build_orientation = .east }
							3 {	app.build_orientation = .west }
							255 { loop = false }
							else {panic("Should not get ${buffer[pos]}")}
						}
						for loop {
							pos += 1
							mut nb := u32(buffer[pos]) << 24
							pos += 1
							nb = u32(buffer[pos]) << 16 | nb
							pos += 1
							nb = u32(buffer[pos]) << 8 | nb
							pos += 1
							nb = buffer[pos] | nb
							for _ in 0 .. nb {
								pos += 1
								mut x := u16(buffer[pos]) << 8
								pos += 1
								x = buffer[pos] | x
								pos += 1
								mut y := u16(buffer[pos]) << 8
								pos += 1
								y = buffer[pos] | y
								app.place_in(x + start_x, y + start_y) or {}
							}
							pos += 1
							match buffer[pos] {
								0 {	app.build_orientation = .north }
								1 {	app.build_orientation = .south }
								2 {	app.build_orientation = .east }
								3 {	app.build_orientation = .west }
								255 { loop = false }
								else {panic("Should not get ${buffer[pos]}")}
							}
						}
					}
					2 {
						app.build_selected_type = .wire
						pos += 1
						mut nb := u32(buffer[pos]) << 24
						pos += 1
						nb = u32(buffer[pos]) << 16 | nb
						pos += 1
						nb = u32(buffer[pos]) << 8 | nb
						pos += 1
						nb = buffer[pos] | nb
						for _ in 0 .. nb {
							pos += 1
							mut x := u16(buffer[pos]) << 8
							pos += 1
							x = buffer[pos] | x
							pos += 1
							mut y := u16(buffer[pos]) << 8
							pos += 1
							y = buffer[pos] | y
							app.place_in(x + start_x, y + start_y) or {}
						}
					}
					3 {
						app.build_selected_type = .junction
						pos += 1
						mut nb := u32(buffer[pos]) << 24
						pos += 1
						nb = u32(buffer[pos]) << 16 | nb
						pos += 1
						nb = u32(buffer[pos]) << 8 | nb
						pos += 1
						nb = buffer[pos] | nb
						for _ in 0 .. nb {
							pos += 1
							mut x := u16(buffer[pos]) << 8
							pos += 1
							x = buffer[pos] | x
							pos += 1
							mut y := u16(buffer[pos]) << 8
							pos += 1
							y = buffer[pos] | y
							app.place_in(x + start_x, y + start_y) or {}
						}
					}
					else { panic("Should not be ${buffer[pos]}") }
				}
				pos += 1
			}
		} else {
			return error("Save version not supported / Not supposed to happen")
		}
	}
}