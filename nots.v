module main

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
