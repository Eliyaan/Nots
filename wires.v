module main

struct GlobalWire {
mut:
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
