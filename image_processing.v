module main

fn load_image(path string) []Color {
	image := stbi.load(path, stbi.LoadParams{0}) or { panic('Image not found: ${path}') }
	data := &u8(image.data)
	mut output := []Color{cap: tile_size * tile_size}
	for i in 0 .. tile_size * tile_size {
		unsafe {
			output << Color{data[i * 4], data[i * 4 + 1], data[i * 4 + 2], data[i * 4 + 3]}
		}
	}
	return output
}

@[inline]
fn a_coords(y int, x int, size int) int {
	return y * size + x
}

fn rotate_img(a []Color, new_o Orientation, side_size int) []Color {
	match new_o {
		.north {
			return a
		}
		.south {
			return []Color{len: a.len, init: a[a.len - index - 1]}
		}
		.west {
			return []Color{len: a.len, init: a[(index % side_size + 1) * side_size - index / side_size - 1]}
		}
		.east {
			return []Color{len: a.len, init: a[(side_size - index % side_size - 1) * side_size +
				index / side_size]}
		}
	}
}

@[direct_array_access]
fn scale_img(a []Color, scale_goal f64, x_size int, y_size int) []Color {
	base_side_x := x_size
	base_side_y := y_size
	scaled_side_x := ceil(f64(base_side_x) * scale_goal)
	scaled_side_y := ceil(f64(base_side_y) * scale_goal)
	if scaled_side_y != base_side_y && scaled_side_x != base_side_x {
		mut new_a := []Color{len: scaled_side_y * scaled_side_x}
		for l in 0 .. scaled_side_y {
			for c in 0 .. scaled_side_x {
				// Index in the new array of the current pixel
				new_i := l * scaled_side_y + c

				// needs division (for proportionality) but only if needed :
				mut val_l := f64(l * (base_side_y - 1))
				mut val_c := f64(c * (base_side_x - 1))

				// if the division is a integer (it corresponds to an exact pixel)
				l_is_int := int(val_l) % (scaled_side_y - 1) != 0
				c_is_int := int(val_c) % (scaled_side_x - 1) != 0

				// divide
				val_l /= (scaled_side_y - 1)
				val_c /= (scaled_side_x - 1)
				int_val_l := int(val_l)
				int_val_c := int(val_c)

				// Take the right pixel values
				if l_is_int && c_is_int {
					new_a[new_i] = a[int(val_l) * base_side_x + int_val_c]
				} else if !(l_is_int || c_is_int) { // none of them
					new_a[new_i].r = u8(
						a[a_coords(int_val_l, int_val_c, base_side_x)].r * float_gap(val_c) * float_gap(val_l) +
						a[a_coords(int_val_l, ceil(val_c), base_side_x)].r * float_offset(val_c) * float_gap(val_l) +
						a[a_coords(ceil(val_l), int_val_c, base_side_x)].r * float_offset(val_l) * float_gap(val_c) +
						a[a_coords(ceil(val_l), ceil(val_c), base_side_x)].r * float_offset(val_l) * float_offset(val_c))
					new_a[new_i].g = u8(
						a[a_coords(int_val_l, int_val_c, base_side_x)].g * float_gap(val_c) * float_gap(val_l) +
						a[a_coords(int_val_l, ceil(val_c), base_side_x)].g * float_offset(val_c) * float_gap(val_l) +
						a[a_coords(ceil(val_l), int_val_c, base_side_x)].g * float_offset(val_l) * float_gap(val_c) +
						a[a_coords(ceil(val_l), ceil(val_c), base_side_x)].g * float_offset(val_l) * float_offset(val_c))
					new_a[new_i].b = u8(
						a[a_coords(int_val_l, int_val_c, base_side_x)].b * float_gap(val_c) * float_gap(val_l) +
						a[a_coords(int_val_l, ceil(val_c), base_side_x)].b * float_offset(val_c) * float_gap(val_l) +
						a[a_coords(ceil(val_l), int_val_c, base_side_x)].b * float_offset(val_l) * float_gap(val_c) +
						a[a_coords(ceil(val_l), ceil(val_c), base_side_x)].b * float_offset(val_l) * float_offset(val_c))
					new_a[new_i].a = u8(
						a[a_coords(int_val_l, int_val_c, base_side_x)].a * float_gap(val_c) * float_gap(val_l) +
						a[a_coords(int_val_l, ceil(val_c), base_side_x)].a * float_offset(val_c) * float_gap(val_l) +
						a[a_coords(ceil(val_l), int_val_c, base_side_x)].a * float_offset(val_l) * float_gap(val_c) +
						a[a_coords(ceil(val_l), ceil(val_c), base_side_x)].a * float_offset(val_l) * float_offset(val_c))
				} else if l_is_int { // exact line (not useful for squares I think but there if needed)
					new_a[new_i].r = u8(
						a[a_coords(int_val_l, int_val_c, base_side_x)].r * float_gap(val_c) +
						a[a_coords(int_val_l, ceil(val_c), base_side_x)].r * float_offset(val_c))
					new_a[new_i].g = u8(
						a[a_coords(int_val_l, int_val_c, base_side_x)].g * float_gap(val_c) +
						a[a_coords(int_val_l, ceil(val_c), base_side_x)].g * float_offset(val_c))
					new_a[new_i].b = u8(
						a[a_coords(int_val_l, int_val_c, base_side_x)].b * float_gap(val_c) +
						a[a_coords(int_val_l, ceil(val_c), base_side_x)].b * float_offset(val_c))
					new_a[new_i].a = u8(
						a[a_coords(int_val_l, int_val_c, base_side_x)].a * float_gap(val_c) +
						a[a_coords(int_val_l, ceil(val_c), base_side_x)].a * float_offset(val_c))
				} else { // exact collumn (not useful for squares I think but there if needed)
					new_a[new_i].r = u8(
						a[a_coords(int_val_l, int_val_c, base_side_x)].r * float_gap(val_l) +
						a[a_coords(ceil(val_l), int_val_c, base_side_x)].r * float_offset(val_l))
					new_a[new_i].g = u8(
						a[a_coords(int_val_l, int_val_c, base_side_x)].g * float_gap(val_l) +
						a[a_coords(ceil(val_l), int_val_c, base_side_x)].g * float_offset(val_l))
					new_a[new_i].b = u8(
						a[a_coords(int_val_l, int_val_c, base_side_x)].b * float_gap(val_l) +
						a[a_coords(ceil(val_l), int_val_c, base_side_x)].b * float_offset(val_l))
					new_a[new_i].a = u8(
						a[a_coords(int_val_l, int_val_c, base_side_x)].a * float_gap(val_l) +
						a[a_coords(ceil(val_l), int_val_c, base_side_x)].a * float_offset(val_l))
				}
			}
		}
		return new_a // needs to be cropped
	} else {
		return a
	}
}

@[inline]
fn float_offset(f f64) f64 {
	return f - int(f)
}

@[inline]
fn float_gap(f f64) f64 {
	return 1 - float_offset(f)
}

struct Color {
mut:
	r u8
	g u8
	b u8
	a u8
}

fn (c Color) u32() u32 {
	return (u32(c.a) << 24) | (u32(c.b) << 16) | (u32(c.g) << 8) | c.r
}