module main 

enum Orientation as u8 {
	north
	south
	east
	west
}

// returns the relative coordinates of the input of a not gate
fn input_coords_from_orientation(ori Orientation) (int, int) {
	return match ori {
		.north {
			0, 1
		}
		.south {
			0, -1
		}
		.east {
			-1, 0
		}
		.west {
			1, 0
		}
	}
}

// returns the relative coordinates of the output of a not gate
fn output_coords_from_orientation(ori Orientation) (int, int) {
	return match ori {
		.north {
			0, -1
		}
		.south {
			0, 1
		}
		.east {
			1, 0
		}
		.west {
			-1, 0
		}
	}
}